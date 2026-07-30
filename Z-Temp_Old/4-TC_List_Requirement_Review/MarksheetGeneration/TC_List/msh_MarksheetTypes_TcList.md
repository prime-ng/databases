# Marksheet Types — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Marksheet Type (`msh_marksheet_types`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\MarksheetTypeController` — 10 methods (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete) — ⚠️ `index()` NOT used in hub; listing via `MarksheetGenerationController::configuration()` |
| **Tab Container Controller** | `MarksheetGenerationController::configuration()` — tab id `marksheet-types`, private `applyFilters()` helper for listing |
| **Model** | `Modules\MarksheetGeneration\Models\MarksheetType` — SoftDeletes, 3 relationships |
| **Form Request** | `Modules\MarksheetGeneration\Http\Requests\MarksheetTypeRequest` — 5 validation rules + `prepareForValidation` |
| **Service** | `Modules\MarksheetGeneration\Services\MarksheetTypeService` — `create()`, `update()`, `delete()` with DB transaction |
| **Policy** | `MarksheetTypePolicy` — 8 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `marksheet-generation.marksheet-type.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` via modal entities loop |
| **Blade Views** | `_marksheet-types.blade.php` (tab partial), `modals/marksheet-type-create.blade.php`, `modals/marksheet-type-edit.blade.php`, `trashed/marksheet-type.blade.php` |
| **Tab Container** | `pages/configuration.blade.php` — tab id `marksheet-types`, permission `tenant.msh-marksheet-type.view` |
| **DB Table** | `msh_marksheet_types` — 10 data columns + 3 timestamp columns |
| **Primary Screen** | Marksheet Generation → Configuration → Marksheet Types tab (paginated, searchable, status-filtered, modal CRUD) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Examination Coordinator (or role with `tenant.msh-marksheet-type.*` permissions) |
| PC-02 | Database `msh_marksheet_types` table must exist with all 10 data columns |
| PC-03 | `msh_config_templates` table must exist with FK `marksheet_type_id` referencing `msh_marksheet_types.id` (ON DELETE RESTRICT) |
| PC-04 | `sys_users` table must have at least one user for `created_by` / `updated_by` FK |
| PC-05 | `MarksheetTypeController` must be registered in module routes with resource + extra routes |
| PC-06 | `MarksheetTypePolicy` must be registered in `AuthServiceProvider` |
| PC-07 | Marksheet Types tab must be included in `configuration.blade.php` with `@can('tenant.msh-marksheet-type.view')` guard |
| PC-08 | Soft deletes must be enabled on `msh_marksheet_types` (`deleted_at` column) |
| PC-09 | Browser must support JavaScript for modal forms, status toggle, SweetAlert confirmations |
| PC-10 | `MarksheetTypeService::create()` and `MarksheetTypeService::update()` must be available in service container |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load marksheet types with pagination (15 per page) via `MarksheetGenerationController::configuration() → applyFilters()` | `MarksheetGenerationController.php:76` — `MarksheetType::query()->...->paginate(15, ['*'], 'mt_page')` |
| DL-02 | Search filters: `?search=` (Code, Name) and `?status=` (1=Active, 0=Inactive) — only applied when tab is `marksheet-types` | `MarksheetGenerationController.php:76` — `$tab === 'marksheet-types'` conditional |
| DL-03 | Tab partial loads via `@include('marksheetgeneration::pages.partials.configuration._marksheet-types')` inside `@can('tenant.msh-marksheet-type.view')` | `configuration.blade.php:18-19` |
| DL-04 | List columns displayed: **#**, **Code**, **Name**, **Description**, **Status**, **Actions** | `_marksheet-types.blade.php:38-47` |
| DL-05 | Code displayed as `<span class="badge bg-light text-dark">` badge | `_marksheet-types.blade.php:54` |
| DL-06 | Description truncated to 50 chars via `Str::limit($row->description, 50)` | `_marksheet-types.blade.php:56` |
| DL-07 | Status column uses `<x-backend.table.status-switch>` component | `_marksheet-types.blade.php:59` |
| DL-08 | Action column uses `<x-backend.table.action>` with `editOnclick` for JS modal population | `_marksheet-types.blade.php:64` |
| DL-09 | Pagination links appended with all current query parameters via `->appends(request()->query())` | `_marksheet-types.blade.php:72` |
| DL-10 | Shared dropdowns loaded: `$currentAcademicSession`, `$lmsExamTypes`, `$schoolClasses`, `$marksheetTypesList`, `$examGroupsList` | `MarksheetGenerationController.php:82-86` |
| DL-11 | Empty state: "No Marksheet Types Found" with icon, title, and subtitle | `_marksheet-types.blade.php:24-31` |
| DL-12 | Modals for create/edit are loaded in `configuration.blade.php` via `@include('marksheetgeneration::modals.marksheet-type-create')` and `@include('marksheetgeneration::modals.marksheet-type-edit')` | `configuration.blade.php:37-38` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Marksheet Type** | `code='TERM1'`, `name='Term-1 Report Card'`, `description='CBSE Term-1 reporting'`, `display_order=1`, `is_active=true` |
| TD-02 | **Duplicate Code** | Create second marksheet type with same `code='TERM1'` — expects unique violation |
| TD-03 | **Missing Required Fields** | Submit with `code` empty, `name` empty — expects validation failures |
| TD-04 | **Invalid Display Order** | `display_order=0` — expects `min:1` validation failure |
| TD-05 | **Code Exceeds Max Length** | `code` = 31 chars — expects `max:30` validation failure |
| TD-06 | **Name Exceeds Max Length** | `name` = 101 chars — expects `max:100` validation failure |
| TD-07 | **Description Exceeds Max Length** | `description` = 256 chars — expects `max:255` validation failure |
| TD-08 | **Soft-Deleted Code Reuse** | Delete a marksheet type, create a new one with same `code` — should succeed (unique ignores soft-deleted) |
| TD-09 | **Invalid is_active Value** | `is_active=2` (non-boolean) — expects boolean validation failure |
| TD-10 | **Force Delete Referenced Type** | Create marksheet type, create Config Template referencing it, force-delete the type — expects `QueryException 23000` catch |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT PK, AUTO_INCREMENT | Primary key, auto-increment | DDL: `msh_marksheet_types` |
| BC-DB-02 | `code` — VARCHAR(30), NOT NULL, UNIQUE | Max 30 chars, unique, no nulls | DDL: `msh_marksheet_types` |
| BC-DB-03 | `name` — VARCHAR(100), NOT NULL | Max 100 chars, no nulls | DDL: `msh_marksheet_types` |
| BC-DB-04 | `description` — TEXT, NULLABLE | Variable length, nullable | DDL: `msh_marksheet_types` |
| BC-DB-05 | `display_order` — SMALLINT UNSIGNED, DEFAULT 1 | Small positive integer, default 1 | DDL: `msh_marksheet_types` |
| BC-DB-06 | `is_active` — TINYINT(1), DEFAULT 1 | Boolean flag, default active | DDL: `msh_marksheet_types` |
| BC-DB-07 | `created_by` — INT, NOT NULL, FK → `sys_users.id` | Required user reference | DDL: `msh_marksheet_types` |
| BC-DB-08 | `updated_by` — INT, NULLABLE, FK → `sys_users.id` | Nullable user reference | DDL: `msh_marksheet_types` |
| BC-DB-09 | `created_at` — TIMESTAMP | Auto-set on create | DDL: `msh_marksheet_types` |
| BC-DB-10 | `updated_at` — TIMESTAMP | Auto-updated | DDL: `msh_marksheet_types` |
| BC-DB-11 | `deleted_at` — TIMESTAMP, NULLABLE | Soft deletes support | DDL: `msh_marksheet_types` |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `code` — required, string, max:30, unique in `msh_marksheet_types` | `required\|string\|max:30\|Rule::unique(...)` | `MarksheetTypeRequest.php:14-20` |
| BC-VAL-02 | `name` — required, string, max:100 | `required\|string\|max:100` | `MarksheetTypeRequest.php:22-26` |
| BC-VAL-03 | `description` — nullable, string, max:255 | `nullable\|string\|max:255` | `MarksheetTypeRequest.php:28-32` |
| BC-VAL-04 | `display_order` — required, integer, min:1 | `required\|integer\|min:1` | `MarksheetTypeRequest.php:34-38` |
| BC-VAL-05 | `is_active` — required, boolean | `required\|boolean` | `MarksheetTypeRequest.php:40-44` |
| BC-VAL-06 | `prepareForValidation()` normalizes `is_active` to boolean | `$this->boolean('is_active')` | `MarksheetTypeRequest.php:48-53` |
| BC-VAL-07 | `prepareForValidation()` normalizes `display_order` to integer | `(int) $this->input('display_order')` | `MarksheetTypeRequest.php:49` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.msh-marksheet-type.viewAny` | Hub: `Gate::authorize('tenant.msh-configuration.view')` in `configuration()` for hub access; standalone: `Gate::authorize('tenant.msh-marksheet-type.viewAny')` in `index()` | `viewAny()` | `MarksheetGenerationController.php:70`, `MarksheetTypeController.php:16` |
| BC-AUTH-02 | `tenant.msh-marksheet-type.view` | Tab: `@can('tenant.msh-marksheet-type.view')` in configuration.blade.php; Show: `Gate::authorize('tenant.msh-marksheet-type.view')` in `show()` | `view()` | `configuration.blade.php:18`, `MarksheetTypeController.php:57` |
| BC-AUTH-03 | `tenant.msh-marksheet-type.create` | `Gate::authorize('tenant.msh-marksheet-type.create')` in `store()` | `create()` | `MarksheetTypeController.php:32` |
| BC-AUTH-04 | `tenant.msh-marksheet-type.update` | `Gate::authorize('tenant.msh-marksheet-type.update')` in `edit()`, `update()`, `toggleStatus()`, `restore()` | `update()` | `MarksheetTypeController.php:64,71,111,132` |
| BC-AUTH-05 | `tenant.msh-marksheet-type.delete` | `Gate::authorize('tenant.msh-marksheet-type.delete')` in `destroy()`, `forceDelete()` | `delete()` | `MarksheetTypeController.php:96,145` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Code must be unique (ignoring soft-deleted) | DB unique + Request unique with `->ignore($id)` | `MarksheetTypeRequest.php:17` |
| BC-BIZ-02 | `store()` delegates to `MarksheetTypeService::create()` within DB transaction | Service handles `created_by` setting | `MarksheetTypeController.php:34`, `MarksheetTypeService.php:10` |
| BC-BIZ-03 | `update()` delegates to `MarksheetTypeService::update()` within DB transaction | Service handles `updated_by` setting | `MarksheetTypeController.php:73`, `MarksheetTypeService.php:19` |
| BC-BIZ-04 | `destroy()` delegates to `MarksheetTypeService::delete()` which soft-deletes | `$model->delete()` within transaction | `MarksheetTypeController.php:98`, `MarksheetTypeService.php:28` |
| BC-BIZ-05 | `toggleStatus()` inverts `is_active` via `! $record->is_active` | Toggles boolean value and sets `updated_by` | `MarksheetTypeController.php:114` |
| BC-BIZ-06 | `forceDelete()` catches `QueryException 23000` for FK violations | Returns user-friendly error message | `MarksheetTypeController.php:148-155` |
| BC-BIZ-07 | `restore()` sets `is_active = true` after restoring | Restored records are active by default | `MarksheetTypeController.php:135-136` |
| BC-BIZ-08 | `restore()` uses `onlyTrashed()->findOrFail()` to locate soft-deleted records | Only finds trashed records, 404 if active | `MarksheetTypeController.php:134` |
| BC-BIZ-09 | `forceDelete()` uses `withTrashed()->findOrFail()` to find any record | Finds both active and trashed | `MarksheetTypeController.php:147` |
| BC-BIZ-10 | AJAX support via `$request->expectsJson()` in `store()` and `update()` | Returns JSON with `status`, `message`, `redirect` | `MarksheetTypeController.php:44-49,83-88` |
| BC-BIZ-11 | `activityLog()` called in every CRUD method | Consistent logging across store, update, destroy, toggleStatus, restore, forceDelete | `MarksheetTypeController.php:36-38,75-77,100-102,116,138,150` |
| BC-BIZ-12 | `flash('created.marksheet_type')` and other flash keys used | Must exist in lang file | `MarksheetTypeController.php:42` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | MarksheetType → ConfigTemplate | `hasMany(configTemplates)` via `marksheet_type_id` | `MarksheetType.php:35` |
| BC-REL-02 | MarksheetType → User (created_by) | `belongsTo(createdBy)` | `MarksheetType.php:25` |
| BC-REL-03 | MarksheetType → User (updated_by) | `belongsTo(updatedBy)` | `MarksheetType.php:29` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads in Configuration hub with `@can('tenant.msh-marksheet-type.view')` | Tab conditional + double security | `configuration.blade.php:18` |
| BC-REF-02 | Search bar with `permissions="tenant.msh-marksheet-type"` and `createModal="#createMarksheetTypeModal"` | Conditional toolbar with modal trigger | `_marksheet-types.blade.php:5` |
| BC-REF-03 | Status header and body cells both wrapped in `@can('tenant.msh-marksheet-type.update')` | Symmetrical guards prevent column shift | `_marksheet-types.blade.php:42-44,57-60` |
| BC-REF-04 | Actions header and body cells both wrapped in `@canany(['...view', '...update', '...delete'])` | Symmetrical guards | `_marksheet-types.blade.php:45-47,62-66` |
| BC-REF-05 | Action column uses `editOnclick` JS function (`editMarksheetType()`) to populate edit modal | Modal-based editing, not dedicated edit page | `_marksheet-types.blade.php:64` |
| BC-REF-06 | `edit()` redirects back to configuration hub | Modal-based editing — `edit()` is a no-op redirect | `MarksheetTypeController.php:66` |
| BC-REF-07 | Empty state colspan covers all columns | "No Marksheet Types Found" | `_marksheet-types.blade.php:23-32` |
| BC-REF-08 | Pagination uses `->appends(request()->query())` | Preserves all query params including tab | `_marksheet-types.blade.php:72` |
| BC-REF-09 | Modal includes hidden tab input to maintain tab context on reload | Create/Edit via AJAX with page reload | `configuration.blade.php:37-38` |
| BC-REF-10 | Status switch component renders toggle with JS | AJAX POST to toggleStatus route | `_marksheet-types.blade.php:59` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Hub `configuration()` paginates at 15 per page with page name `mt_page` | `MarksheetType::query()->...->paginate(15, ['*'], 'mt_page')` — unique paginator name avoids cross-tab conflicts |
| BC-BIZ-DEEP-02 | `applyFilters()` only applies search when tab is active | `$tab === 'marksheet-types'` — prevents search from filtering wrong tab's data |
| BC-BIZ-DEEP-03 | Search applies LIKE on `name` and `code` columns | `$query->orWhere('name', 'like', "%{$search}%")->orWhere('code', 'like', "%{$search}%")` — searchable columns passed as array |
| BC-BIZ-DEEP-04 | Status filter applies exact match on `is_active` | `$query->where('is_active', (int) $status)` — 1=Active, 0=Inactive |
| BC-BIZ-DEEP-05 | `applyFilters()` always applies `->latest()` order | Orders by `created_at DESC` consistently across all tabs |
| BC-BIZ-DEEP-06 | `store()` returns AJAX JSON when `$request->expectsJson()` | JSON includes `status`, `message`, `redirect` keys for modal handler |
| BC-BIZ-DEEP-07 | `store()` redirects to `marksheet-generation.configuration.combined?tab=marksheet-types` on non-AJAX | Redirects to hub with tab parameter preserved |
| BC-BIZ-DEEP-08 | `update()` returns AJAX JSON when `$request->expectsJson()` | Same JSON structure as store |
| BC-BIZ-DEEP-09 | `update()` redirects to hub with tab parameter on non-AJAX | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])` |
| BC-BIZ-DEEP-10 | `destroy()` redirects to hub with tab parameter | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])` |
| BC-BIZ-DEEP-11 | `toggleStatus()` returns JSON with `success`, `is_active`, `message` | `{success: true, is_active: bool, message: 'Status set to Active/Inactive'}` |
| BC-BIZ-DEEP-12 | `toggleStatus()` uses `MarksheetType::findOrFail($id)` — no route-model-binding | Manual ID lookup |
| BC-BIZ-DEEP-13 | `toggleStatus()` sets `updated_by` alongside `is_active` toggle | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` |
| BC-BIZ-DEEP-14 | `restore()` uses `onlyTrashed()` to find deleted records | `MarksheetType::onlyTrashed()->findOrFail($id)` — only finds soft-deleted records |
| BC-BIZ-DEEP-15 | `restore()` sets `is_active = true` after restore | `$record->update(['is_active' => true])` — restored records active by default |
| BC-BIZ-DEEP-16 | `forceDelete()` catches `QueryException` with code `23000` | Catches FK constraint violations, returns user-friendly message |
| BC-BIZ-DEEP-17 | `forceDelete()` re-throws non-23000 exceptions | `throw $e` — only 23000 is caught |
| BC-BIZ-DEEP-18 | `forceDelete()` activityLog written ONLY on success, NOT on FK failure | `activityLog()` call inside `try` block — only executes if forceDelete succeeds |
| BC-BIZ-DEEP-19 | `trashed()` paginates at 15 per page — consistent with hub | `MarksheetType::onlyTrashed()->latest()->paginate(15)` — same size as hub listing |
| BC-BIZ-DEEP-20 | `trashed()` uses `viewAny` permission | `Gate::authorize('tenant.msh-marksheet-type.viewAny')` |
| BC-BIZ-DEEP-21 | `index()` paginates at 20 per page (standalone route only) | `MarksheetType::latest()->paginate(20)` — 20 vs 15 in hub |
| BC-BIZ-DEEP-22 | `create()` redirects to standalone create view (not modal) | `view('marksheetgeneration::marksheet-type.create')` — standalone route only |
| BC-BIZ-DEEP-23 | `edit()` redirects to hub with tab parameter (modal-based edit) | Redirect, not form view — modal handles editing |
| BC-BIZ-DEEP-24 | Service layer `create()` sets `created_by` within transaction | `$data['created_by'] = $userId` before `MarksheetType::create($data)` |
| BC-BIZ-DEEP-25 | Service layer `update()` sets `updated_by` within transaction | `$data['updated_by'] = $userId` before `$model->update($data)` |
| BC-BIZ-DEEP-26 | Service layer `update()` returns `$model->fresh()` | Fresh model instance after update |
| BC-BIZ-DEEP-27 | Service layer uses `DB::transaction()` for all operations | All create/update/delete wrapped in atomic transactions |
| BC-BIZ-DEEP-28 | `activityLog()` message for store: `'A new marksheet type was created.'` | Consistent message format |
| BC-BIZ-DEEP-29 | `activityLog()` message for update: `'The marksheet type was updated.'` | Consistent message format |
| BC-BIZ-DEEP-30 | `activityLog()` message for destroy: `'The marksheet type was deleted.'` | Consistent message format |
| BC-BIZ-DEEP-31 | `activityLog()` message for toggle: `'Status was toggled.'` | No `performed_by` key passed — inconsistency noted |
| BC-BIZ-DEEP-32 | `activityLog()` message for restore: `'The record was restored.'` | No `performed_by` key passed — inconsistency |
| BC-BIZ-DEEP-33 | `activityLog()` message for forceDelete: `'The record was permanently deleted.'` | Only called on success path |
| BC-BIZ-DEEP-34 | `display_order` defaults to 1 in DB but also set via `prepareForValidation()` | `(int) $this->input('display_order') ?: 1` — fallback to 1 if empty |
| BC-BIZ-DEEP-35 | `description` is `TEXT` in DDL but validated as `max:255` in Request | DDL TEXT has no practical limit; Request enforces 255 char limit |
| BC-BIZ-DEEP-36 | Tab permission uses `.view` not `.viewAny` in `configuration.blade.php` | `@can('tenant.msh-marksheet-type.view')` — only view permission required to see the tab |
| BC-BIZ-DEEP-37 | No `authorize()` method override in `MarksheetTypeRequest` — always returns true | `authorize(): bool { return true; }` — authorization delegated to controller Gates |
| BC-BIZ-DEEP-38 | `is_active` is `required` in Request but `sometimes` in update context via `prepareForValidation` | `$this->boolean('is_active')` handles unchecked checkbox by returning false |
| BC-BIZ-DEEP-39 | `code` unique rule uses `Rule::unique('msh_marksheet_types', 'code')->ignore($id)` | Ignores current record on update; ignores soft-deleted records (no `->withoutTrashed()`) |
| BC-BIZ-DEEP-40 | `restore()` activityLog has NO `performed_by` key | Inconsistent with store/update/destroy which include `performed_by` |
| BC-BIZ-DEEP-41 | `toggleStatus()` activityLog has NO `performed_by` key | Inconsistent with store/update/destroy |
| BC-BIZ-DEEP-42 | `activityLog()` in `destroy()` has NO `performed_by` key | `activityLog($marksheetType, 'Deleted', ['message' => '...'])` — missing `performed_by` |
| BC-BIZ-DEEP-43 | `activityLog()` in `store()` has NO `performed_by` key | `activityLog($marksheetType, 'Stored', ['message' => '...'])` — missing `performed_by` |
| BC-BIZ-DEEP-44 | `activityLog()` in `update()` has NO `performed_by` key | `activityLog($marksheetType, 'Updated', ['message' => '...'])` — missing `performed_by` |
| BC-BIZ-DEEP-45 | **GAP**: All `activityLog()` calls in MarksheetTypeController lack `performed_by` key | Inconsistent with Transport Vehicle's activityLog pattern which includes `performed_by` |
| BC-BIZ-DEEP-46 | `show()` uses route-model-binding | `show(MarksheetType $marksheetType)` — resolves `$marksheetType` from URL parameter |
| BC-BIZ-DEEP-47 | `destroy()` uses route-model-binding | `destroy(MarksheetType $marksheetType, MarksheetTypeService $service)` |
| BC-BIZ-DEEP-48 | `update()` uses route-model-binding | `update(MarksheetTypeRequest $request, MarksheetType $marksheetType, MarksheetTypeService $service)` |
| BC-BIZ-DEEP-49 | `toggleStatus()` does NOT use route-model-binding | Manual `MarksheetType::findOrFail($id)` — $id is scalar |
| BC-BIZ-DEEP-50 | `restore()` does NOT use route-model-binding | Manual `MarksheetType::onlyTrashed()->findOrFail($id)` |
| BC-BIZ-DEEP-51 | `forceDelete()` does NOT use route-model-binding | Manual `MarksheetType::withTrashed()->findOrFail($id)` |
| BC-BIZ-DEEP-52 | Modal-based entities loop generates routes for all 5 config entities | `toggleStatus`, `trashed`, `restore`, `forceDelete` generated for marksheet-type slug | `web.php:45-66` |
| BC-BIZ-DEEP-53 | `ia-component-type` resource uses `only: ['store', 'show', 'update', 'destroy']` but `marksheet-type` uses full resource | Full resource includes `index`, `create`, `edit` routes | `web.php:70-71,82-84` |
| BC-BIZ-DEEP-54 | `create()` and `edit()` routes exist but are never used from hub (modal-based) | Routes available for standalone access but all operations go through modals | `MarksheetTypeController.php:23-27,62-66` |
| BC-BIZ-DEEP-55 | `edit()` redirect causes double redirect for modal operations | User clicks edit → JS opens modal → AJAX PATCH → controller calls `edit()` route → redirects to hub | Flow is: JS handles modal, not the edit route |
| BC-BIZ-DEEP-56 | `MarksheetTypeRequest@authorize()` always returns true | All authorization is in controller Gates, not in FormRequest | `MarksheetTypeRequest.php:8-10` |
| BC-BIZ-DEEP-57 | `display_order` cast to integer in model | `protected $casts = ['display_order' => 'integer']` | `MarksheetType.php:20` |
| BC-BIZ-DEEP-58 | `is_active` cast to bool in model | `protected $casts = ['is_active' => 'bool']` | `MarksheetType.php:19` |
| BC-BIZ-DEEP-59 | Unique constraint on `code` column at DB level (BC-DB-02) | DB enforces uniqueness even if Request is bypassed | DDL |
| BC-BIZ-DEEP-60 | `updated_by` in fillable but never set on create (only updated_by set on update) | On create, `updated_by` is null — only `created_by` is set via service | `MarksheetType.php:10-18` fillable |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index(Request $request)` — MarksheetTypeController Lines 14-21 (Standalone Route)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 16 | `Gate::authorize('tenant.msh-marksheet-type.viewAny')` | Authorization gate — user must have viewAny permission |
| 02 | 18 | `$marksheetTypes = MarksheetType::latest()->paginate(20)` | Paginate 20 per page with latest ordering |
| 03 | 20 | `return view('marksheetgeneration::marksheet-type.index', compact('marksheetTypes'))` | Return standalone index view |

#### CODE-TRACE-A: Hub `configuration()` — MarksheetGenerationController Lines 68-93 (Primary Tab Listing)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 70 | `Gate::authorize('tenant.msh-configuration.view')` | Authorization gate — user must have configuration hub access |
| 02 | 72-74 | `$search = $request->input('search'); $status = $request->input('status'); $tab = $request->input('tab', 'marksheet-types')` | Extract shared filter inputs with default tab = marksheet-types |
| 03 | 76 | `$marksheetTypes = $this->applyFilters(MarksheetType::query(), $tab === 'marksheet-types' ? $search : null, $tab === 'marksheet-types' ? $status : null, ['name', 'code'])->paginate(15, ['*'], 'mt_page')` | Query marksheet types with conditional search/status, paginate 15 with unique page name `mt_page` |
| 04 | 82-86 | `$currentAcademicSession = OrgAcademicSession::current(); $lmsExamTypes = ExamType::where(...); $schoolClasses = SchoolClass::where(...); $marksheetTypesList = MarksheetType::orderBy('name')->get(); $examGroupsList = ExamGroup::orderBy('name')->get()` | Load shared dropdown data for modal forms |
| 05 | 88-92 | `return view('marksheetgeneration::pages.configuration', compact(...))` | Return configuration hub view with all 5 tab datasts + shared collections |

#### CODE-TRACE-02: `create()` — MarksheetTypeController Lines 23-28

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 25 | `Gate::authorize('tenant.msh-marksheet-type.create')` | Authorization gate — create permission |
| 02 | 27 | `return view('marksheetgeneration::marksheet-type.create')` | Return create form view (standalone route only) |

#### CODE-TRACE-03: `store(MarksheetTypeRequest $request, MarksheetTypeService $service)` — Lines 30-53

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 32 | `Gate::authorize('tenant.msh-marksheet-type.create')` | Authorization gate — create permission |
| 02 | 34 | `$marksheetType = $service->create($request->validated(), (int) auth()->id())` | Delegate to service layer with validated data and user ID |
| 03 | 36-38 | `activityLog($marksheetType, 'Stored', ['message' => 'A new marksheet type was created.'])` | Activity log entry — NOTE: no `performed_by` key |
| 04 | 40-42 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])->with('success', flash('created.marksheet_type'))` | Build redirect response to hub with tab parameter |
| 05 | 44-49 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX request returns JSON with status, message, redirect URL |
| 06 | 52 | `return $redirect` | Non-AJAX returns standard redirect |

#### CODE-TRACE-04: `show(MarksheetType $marksheetType)` — Lines 55-60

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 57 | `Gate::authorize('tenant.msh-marksheet-type.view')` | Authorization gate — view permission |
| 02 | 59 | `return view('marksheetgeneration::marksheet-type.show', compact('marksheetType'))` | Route-model-binding resolves $marksheetType; returns show view |

#### CODE-TRACE-05: `edit(MarksheetType $marksheetType)` — Lines 62-67

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 64 | `Gate::authorize('tenant.msh-marksheet-type.update')` | Authorization gate — update permission |
| 02 | 66 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])` | **No-op redirect**: editing is modal-based, not dedicated edit page |

#### CODE-TRACE-06: `update(MarksheetTypeRequest $request, MarksheetType $marksheetType, MarksheetTypeService $service)` — Lines 69-92

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 71 | `Gate::authorize('tenant.msh-marksheet-type.update')` | Authorization gate — update permission |
| 02 | 73 | `$service->update($marksheetType, $request->validated(), (int) auth()->id())` | Delegate to service layer with validated data and user ID |
| 03 | 75-77 | `activityLog($marksheetType, 'Updated', ['message' => 'The marksheet type was updated.'])` | Activity log entry — NOTE: no `performed_by` key |
| 04 | 79-81 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])->with('success', flash('updated.marksheet_type'))` | Build redirect to hub |
| 05 | 83-88 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX JSON response |
| 06 | 91 | `return $redirect` | Non-AJAX redirect |

#### CODE-TRACE-07: `destroy(MarksheetType $marksheetType, MarksheetTypeService $service)` — Lines 94-107

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 96 | `Gate::authorize('tenant.msh-marksheet-type.delete')` | Authorization gate — delete permission |
| 02 | 98 | `$service->delete($marksheetType)` | Service layer soft-deletes (sets deleted_at) within transaction |
| 03 | 100-102 | `activityLog($marksheetType, 'Deleted', ['message' => 'The marksheet type was deleted.'])` | Activity log entry — NOTE: no `performed_by` key |
| 04 | 104-106 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])->with('success', flash('deleted.marksheet_type'))` | Redirect to hub with tab parameter |

#### CODE-TRACE-08: `toggleStatus($id)` — Lines 109-119

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 111 | `Gate::authorize('tenant.msh-marksheet-type.update')` | Authorization gate — update permission |
| 02 | 113 | `$record = MarksheetType::findOrFail($id)` | Manual lookup — find record or 404 |
| 03 | 114 | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | Toggle is_active value and set updated_by |
| 04 | 116 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity log entry — NOTE: no `performed_by` key |
| 05 | 118 | `return response()->json(['success' => true, 'is_active' => $record->is_active, 'message' => $record->is_active ? 'Status set to Active' : 'Status set to Inactive'])` | JSON response with new status |

#### CODE-TRACE-09: `trashed()` — Lines 121-128

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 123 | `Gate::authorize('tenant.msh-marksheet-type.viewAny')` | Authorization gate — viewAny permission |
| 02 | 125 | `$trashed = MarksheetType::onlyTrashed()->latest()->paginate(15)` | Fetch only soft-deleted records, ordered by latest, paginated at 15 |
| 03 | 127 | `return view('marksheetgeneration::trashed.marksheet-type', compact('trashed'))` | Return trash view |

#### CODE-TRACE-10: `restore($id)` — Lines 130-141

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 132 | `Gate::authorize('tenant.msh-marksheet-type.update')` | Authorization gate — `update` permission (not `restore`) |
| 02 | 134 | `$record = MarksheetType::onlyTrashed()->findOrFail($id)` | Find soft-deleted record or 404 |
| 03 | 135 | `$record->restore()` | Restore (sets `deleted_at = NULL`) |
| 04 | 136 | `$record->update(['is_active' => true])` | Set is_active to true after restore |
| 05 | 138 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity log entry — NOTE: no `performed_by` key |
| 06 | 140 | `return redirect()->route('marksheet-generation.marksheet-type.trashed')->with('success', 'Record restored successfully.')` | Redirect to trash page |

#### CODE-TRACE-11: `forceDelete($id)` — Lines 143-159

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 145 | `Gate::authorize('tenant.msh-marksheet-type.delete')` | Authorization gate — `delete` permission (not `forceDelete`) |
| 02 | 147 | `$record = MarksheetType::withTrashed()->findOrFail($id)` | Find ANY record (active or trashed) or 404 |
| 03 | 148-156 | `try { $record->forceDelete(); activityLog(...); } catch (QueryException $e) { if ($e->getCode() === '23000') { ... } throw $e; }` | Attempt force delete — catch FK constraint violation 23000, re-throw others |
| 04 | 149-150 | `$record->forceDelete(); activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` | Success path: permanently delete and log |
| 05 | 152-153 | `return redirect()->back()->with('error', 'Cannot delete this record because it is referenced by other records. Remove those references first.')` | Failure path (23000): user-friendly error |
| 06 | 158 | `return redirect()->route('marksheet-generation.marksheet-type.trashed')->with('success', 'Record permanently deleted.')` | Success redirect to trash page |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create marksheet type with all fields | Fill all fields: code='TERM1', name='Term-1', description='CBSE Term', display_order=1, is_active=true | Record created, flash 'created.marksheet_type', activityLog 'Stored' |
| TC-P-02 | Create marksheet type with minimum fields | Only code and name required, is_active defaults | Record created with default display_order=1 and is_active=true |
| TC-P-03 | Create marksheet type via AJAX modal | Submit modal form with expectsJson header | JSON response `{status: true, message, redirect}` |
| TC-P-04 | Edit marksheet type name | Change name from 'Term-1' to 'Term-1 Revised' | Updated, activityLog 'Updated' |
| TC-P-05 | Edit marksheet type display_order | Change display_order from 1 to 5 | Updated, order changes in dropdown |
| TC-P-06 | Edit marksheet type via AJAX modal | Submit edit modal via PATCH with expectsJson | JSON response `{status: true, message, redirect}` |
| TC-P-07 | Toggle marksheet type active→inactive | Click status switch | AJAX response `{success: true, is_active: false, message: 'Status set to Inactive'}` |
| TC-P-08 | Toggle marksheet type inactive→active | Click status switch on inactive type | AJAX response `{success: true, is_active: true, message: 'Status set to Active'}` |
| TC-P-09 | Search marksheet types by code | Type partial code in search | Filtered results matching code LIKE |
| TC-P-10 | Search marksheet types by name | Type partial name in search | Filtered results matching name LIKE |
| TC-P-11 | Filter by active status | Select "Active" status filter | Only active marksheet types |
| TC-P-12 | Restore soft-deleted marksheet type | Delete → Trash → Restore | Record restored with is_active=true, flash 'Record restored successfully.' |
| TC-P-13 | Force delete marksheet type with no dependencies | Delete → Trash → Force Delete (no Config Templates reference it) | Record permanently deleted, flash 'Record permanently deleted.' |
| TC-P-14 | View marksheet type details | Click view action | Show page with all fields displayed |
| TC-P-15 | Create marksheet type with code at max length | code = 30 characters | Successfully created |
| TC-P-16 | Verify pagination with page name `mt_page` | Load page with more than 15 records | Second page accessible via `?mt_page=2` |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create marksheet type with empty code | Submit without code | "The code field is required." |
| TC-N-02 | Create marksheet type with empty name | Submit without name | "The name field is required." |
| TC-N-03 | Create marksheet type with duplicate code | Use existing code | "The code has already been taken." |
| TC-N-04 | Create marksheet type with code > 30 chars | code = 31 characters | "The code must not be greater than 30 characters." |
| TC-N-05 | Create marksheet type with name > 100 chars | name = 101 characters | "The name must not be greater than 100 characters." |
| TC-N-06 | Create marksheet type with display_order < 1 | display_order = 0 | "The display order must be at least 1." |
| TC-N-07 | Create marksheet type with invalid is_active | is_active = 2 (non-boolean) | "The is active field must be true or false." |
| TC-N-08 | Create marksheet type with description > 255 chars | description = 256 characters | "The description must not be greater than 255 characters." |
| TC-N-09 | Access hub without `tenant.msh-configuration.view` | User lacks hub view permission | 403 Access Denied |
| TC-N-10 | Store marksheet type without `tenant.msh-marksheet-type.create` | User lacks create permission | 403 Access Denied (Gate in store()) |
| TC-N-11 | Update marksheet type without `tenant.msh-marksheet-type.update` | User lacks update permission | 403 Access Denied |
| TC-N-12 | Delete marksheet type without `tenant.msh-marksheet-type.delete` | User lacks delete permission | 403 Access Denied |
| TC-N-13 | Toggle status without `tenant.msh-marksheet-type.update` | User lacks update permission | 403 Access Denied |
| TC-N-14 | Restore non-trashed (active) marksheet type | Call restore on active record | 404 — `onlyTrashed()->findOrFail()` returns no record |
| TC-N-15 | Force delete marksheet type referenced by Config Templates | Type has dependent Config Templates | Error: "Cannot delete this record because it is referenced by other records." |
| TC-N-16 | Show non-existent marksheet type ID | Route-model-binding on deleted ID | 404 — implicit findOrFail |
| TC-N-17 | Edit marksheet type with invalid data (AJAX) | Submit edit modal with empty code | 422 validation error, AJAX handler shows inline errors |
| TC-N-18 | Toggle status with missing ID | Send toggleStatus to non-existent ID | 404 — findOrFail throws ModelNotFoundException |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft delete marksheet type with Config Templates | Delete type referenced by Config Templates | Soft delete allowed (FK is ON DELETE RESTRICT only for forceDelete) — `$model->delete()` sets `deleted_at` without FK check |
| TC-D-02 | Force delete marksheet type with Config Templates | Permanent delete when Config Templates reference it | `QueryException 23000` caught, user-friendly error |
| TC-D-03 | Verify is_active=true after restore | Query restored record | `is_active=1`, `deleted_at=NULL` |
| TC-D-04 | Verify duplicate code allowed after soft-delete | Delete TERM1, create new TERM1 | Success — unique constraint ignores soft-deleted records |
| TC-D-05 | Verify unique code enforcement at DB level | Insert duplicate code directly via DB | DB constraint violation — 23000 |
| TC-D-06 | Verify code unique respects the `->ignore($id)` on update | Update record without changing code | Validation passes (ignores current record's code) |
| TC-D-07 | Verify updated_by null on create | Query newly created record | `updated_by` is NULL |
| TC-D-08 | Verify created_by and updated_by on update | Update record, query both fields | `created_by` unchanged, `updated_by` set to current user |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify `Gate::authorize()` in `index()` | `MarksheetTypeController.php:16` | `tenant.msh-marksheet-type.viewAny` |
| TC-CR-02 | Verify `Gate::authorize()` in `show()` | `MarksheetTypeController.php:57` | `tenant.msh-marksheet-type.view` |
| TC-CR-03 | Verify `Gate::authorize()` in `store()` | `MarksheetTypeController.php:32` | `tenant.msh-marksheet-type.create` |
| TC-CR-04 | Verify `Gate::authorize()` in `update()` | `MarksheetTypeController.php:71` | `tenant.msh-marksheet-type.update` |
| TC-CR-05 | Verify `Gate::authorize()` in `destroy()` | `MarksheetTypeController.php:96` | `tenant.msh-marksheet-type.delete` |
| TC-CR-06 | Verify `Gate::authorize()` in `toggleStatus()` | `MarksheetTypeController.php:111` | `tenant.msh-marksheet-type.update` |
| TC-CR-07 | Verify `Gate::authorize()` in `restore()` | `MarksheetTypeController.php:132` | `tenant.msh-marksheet-type.update` |
| TC-CR-08 | Verify `Gate::authorize()` in `forceDelete()` | `MarksheetTypeController.php:145` | `tenant.msh-marksheet-type.delete` |
| TC-CR-09 | Verify `Gate::authorize()` in `trashed()` | `MarksheetTypeController.php:123` | `tenant.msh-marksheet-type.viewAny` |
| TC-CR-10 | Verify `activityLog()` in `store()` | `MarksheetTypeController.php:36-38` | "A new marksheet type was created." |
| TC-CR-11 | Verify `activityLog()` in `update()` | `MarksheetTypeController.php:75-77` | "The marksheet type was updated." |
| TC-CR-12 | Verify `activityLog()` in `destroy()` | `MarksheetTypeController.php:100-102` | "The marksheet type was deleted." |
| TC-CR-13 | Verify `activityLog()` in `toggleStatus()` | `MarksheetTypeController.php:116` | "Status was toggled." |
| TC-CR-14 | Verify `activityLog()` in `restore()` | `MarksheetTypeController.php:138` | "The record was restored." |
| TC-CR-15 | Verify `activityLog()` in `forceDelete()` | `MarksheetTypeController.php:150` | "The record was permanently deleted." |
| TC-CR-16 | Verify service layer delegation in `store()` | `MarksheetTypeController.php:34` | `$service->create($request->validated(), (int) auth()->id())` |
| TC-CR-17 | Verify service layer delegation in `update()` | `MarksheetTypeController.php:73` | `$service->update($marksheetType, $request->validated(), (int) auth()->id())` |
| TC-CR-18 | Verify service layer delegation in `destroy()` | `MarksheetTypeController.php:98` | `$service->delete($marksheetType)` |
| TC-CR-19 | Verify `DB::transaction()` in MarksheetTypeService | `MarksheetTypeService.php:9,18,27` | All 3 methods wrapped in `DB::transaction()` |
| TC-CR-20 | Verify JSON response in `store()` | `MarksheetTypeController.php:44-49` | `{status: true, message, redirect}` — only when `$request->expectsJson()` |
| TC-CR-21 | Verify JSON response in `update()` | `MarksheetTypeController.php:83-88` | Same structure as store |
| TC-CR-22 | Verify `toggleStatus()` uses `findOrFail($id)` | `MarksheetTypeController.php:113` | Manual lookup (not route-model-binding) |
| TC-CR-23 | Verify `restore()` sets `is_active = true` | `MarksheetTypeController.php:136` | `$record->update(['is_active' => true])` |
| TC-CR-24 | Verify `forceDelete()` catches `QueryException 23000` | `MarksheetTypeController.php:151-155` | `$e->getCode() === '23000'` check |
| TC-CR-25 | Verify `trashed()` pagination at 15 | `MarksheetTypeController.php:125` | `onlyTrashed()->latest()->paginate(15)` |
| TC-CR-26 | Verify `prepareForValidation()` normalizations | `MarksheetTypeRequest.php:48-53` | `boolean('is_active')`, `(int) display_order` |
| TC-CR-27 | Verify `$fillable` includes all create fields | `MarksheetType.php:10-18` | `code, name, description, display_order, is_active, created_by, updated_by` |
| TC-CR-28 | Verify `$casts` for is_active and display_order | `MarksheetType.php:19-22` | `is_active => bool, display_order => integer` |
| TC-CR-29 | Verify `SoftDeletes` trait on model | `MarksheetType.php:7` | `use HasFactory, SoftDeletes;` |
| TC-CR-30 | Verify `edit()` redirects to hub | `MarksheetTypeController.php:66` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])` |
| TC-CR-31 | Verify tab uses `.view` not `.viewAny` permission | `configuration.blade.php:12` | `@can('tenant.msh-marksheet-type.view')` — **OBSERVATION**: uses view not viewAny |
| TC-CR-32 | Verify modal-based entity routes in web.php | `web.php:45-66` | `marksheet-type.*` slug in modal entities loop |
| TC-CR-33 | Verify `resource` routes for marksheet-type | `web.php:70-71` | `Route::resource('marksheet-type', MarksheetTypeController::class)` |
| TC-CR-34 | **OBSERVATION**: All `activityLog()` calls lack `performed_by` | `MarksheetTypeController.php:36-38,75-77,100-102,116,138,150` | Inconsistent with Transport Vehicle pattern |
| TC-CR-35 | Verify `configuration.blade.php` includes all tab partials | `configuration.blade.php:18-32` | 5 `@include` directives with `@can` guards |
| TC-CR-36 | Verify `configuration.blade.php` includes modal files | `configuration.blade.php:37-44` | 7 `@include` directives for modals |
| TC-CR-37 | Verify `_marksheet-types.blade.php` symmetrical @can guards | `_marksheet-types.blade.php:42-47,57-66` | th and td have matching permission wrappers |
| TC-CR-38 | Verify `configuration()` passes all required variables | `MarksheetGenerationController.php:88-92` | 10 compact variables for hub view |
| TC-CR-39 | Verify `applyFilters()` method signature | `MarksheetGenerationController.php:304-318` | `private function applyFilters($query, ?string $search, ?string $status, array $searchableColumns)` |
| TC-CR-40 | Verify `applyFilters()` adds `->latest()` always | `MarksheetGenerationController.php:318` | `return $query->latest();` — no conditional, always applied |
| TC-CR-41 | Verify `is_active` unique rule ignores soft-deleted records | `MarksheetTypeRequest.php:17` | `Rule::unique('msh_marksheet_types', 'code')->ignore($id)` — no `->withoutTrashed()` |
| TC-CR-42 | Verify `withTrashed()` in `forceDelete()` | `MarksheetTypeController.php:147` | `MarksheetType::withTrashed()->findOrFail($id)` — finds both active and trashed |

---

## 7. Detailed Test Steps

### TC-P-01: Create marksheet type with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-marksheet-type.create` permission | Success |
| 2 | Navigate to Marksheet Generation → Configuration hub | Hub page with 5 tabs |
| 3 | Click "Marksheet Types" tab | Tab active, list displayed |
| 4 | Click "Add Marksheet Type" button | Create modal opens |
| 5 | Enter code="MT01", name="Primary Marksheet", description="For primary section" | Fields populated |
| 6 | Set display_order=1, is_active=Active | Form complete |
| 7 | Click "Save" | AJAX POST to store |
| 8 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.create')` passes | Authorized |
| 9 | **Verify**: `MarksheetTypeRequest` validation passes | No validation errors |
| 10 | **Verify**: `MarksheetType::create($request->validated())` inserts row in `msh_marksheet_types` | DB has code="MT01" |
| 11 | **Verify**: `activityLog()` called with type "Stored" and message | Activity log entry created |
| 12 | **Verify**: Modal closes, table refreshes | New row visible in list |
| 13 | **Verify**: Flash success message displayed | "Marksheet Type created successfully" |
| 14 | **Verify**: Sorting by display_order=1 puts it at top | Order maintained |

### TC-P-02: Create marksheet type with minimum fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.create` | Success |
| 2 | Open create modal | Modal displayed |
| 3 | Enter code="MT02", name="Minimal Type" | Only required fields |
| 4 | Leave description empty (nullable), display_order blank (nullable) | Optionals omitted |
| 5 | Click "Save" | POST request |
| 6 | **Verify**: Validation passes — nullable fields not required | No errors |
| 7 | **Verify**: Record created with is_active=1, display_order=null | DB row inserted |
| 8 | **Verify**: Flash success message | Confirmation shown |

### TC-P-03: Edit marksheet type — change name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` permission | Success |
| 2 | Navigate to Marksheet Types tab | List displayed |
| 3 | Click edit icon on existing type "MT01" | Edit modal opens with pre-filled data |
| 4 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.update')` passes | Authorized |
| 5 | Change name from "Primary Marksheet" to "Primary Marksheet Updated" | Input updated |
| 6 | Click "Update" | PUT request |
| 7 | **Verify**: `$original = $record->getOriginal()` captures pre-state | Original name captured |
| 8 | **Verify**: `$record->update($request->validated())` | DB updated, name changed |
| 9 | **Verify**: `$record->getChanges()` includes `name` with old/new values | Change tracking works |
| 10 | **Verify**: `activityLog()` with type "Updated" and `changes` array | Activity log shows old/new |
| 11 | **Verify**: Modal closes, table refreshes with updated data | Name updated in list |
| 12 | **Verify**: Flash success `flash('updated.msh-marksheet-type')` | Success message |

### TC-P-04: Edit marksheet type — change status via edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` | Success |
| 2 | Edit active marksheet type, toggle is_active to inactive | Switch toggled |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `is_active` toggled to 0 in DB | Status changed |
| 5 | **Verify**: Activity log records status change | Entry created |

### TC-P-05: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` permission | Success |
| 2 | Navigate to Marksheet Types tab | List with status toggles |
| 3 | Locate an active marksheet type status toggle | Toggle is ON (green) |
| 4 | Click the status toggle switch | AJAX POST to toggleStatus |
| 5 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.update')` passes | Authorized |
| 6 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` | Inline validation ok |
| 7 | **Verify**: `$record->is_active = false`, `$record->save()` | DB updated |
| 8 | **Verify**: JSON response `{success: true, is_active: false}` | Success response |
| 9 | **Verify**: Toggle switch now OFF (grey/unchecked) | UI updated |

### TC-P-06: Toggle status inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` | Success |
| 2 | Find an inactive marksheet type | is_active=0 |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$request->boolean('is_active')` = true | Toggle sends true |
| 5 | **Verify**: `$record->is_active = true` | Set to active |
| 6 | **Verify**: JSON `{success: true, is_active: true}` | Toggle now ON |

### TC-P-07: View marksheet type details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.view` permission | Success |
| 2 | Navigate to Marksheet Types tab | List displayed |
| 3 | Click view icon on a type row | Show modal opens |
| 4 | **Verify**: All fields displayed: code, name, description, display_order, is_active, created_at | Data visible |
| 5 | **Verify**: Dates formatted via Carbon cast | Human-readable date |
| 6 | **Verify**: is_active shown as Active/Inactive badge | Status indicator |

### TC-P-08: Search marksheet type by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.view»` permission | Success |
| 2 | Navigate to Marksheet Types tab | List with search bar |
| 3 | Type "MT01" in search box | Search input filled |
| 4 | Submit search | GET with `?search=MT01` |
| 5 | **Verify**: Controller applies `->where('code','like','%MT01%')->orWhere('name','like','%MT01%')` | Query filtered |
| 6 | **Verify**: Only matching types displayed | Filtered results |
| 7 | **Verify**: Non-matching types excluded | Not in results |

### TC-P-09: Filter by active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.viewAny` | Success |
| 2 | Select "Active" from status filter | `status=1` |
| 3 | Submit filter | GET with `?status=1` |
| 4 | **Verify**: `->where('is_active', 1)` applied | Only active displayed |
| 5 | Change to "Inactive" filter | `?status=0` — only inactive displayed |
| 6 | Verify status + search work together | Combined params |

### TC-P-10: Soft-delete marksheet type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.delete` permission | Success |
| 2 | Navigate to Marksheet Types tab | List displayed |
| 3 | Click delete icon on a type row | Confirmation dialog |
| 4 | Confirm deletion | DELETE request |
| 5 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.delete')` passes | Authorized |
| 6 | **Verify**: `$record->is_active = false; $record->save(); $record->delete()` | Soft-delete executed |
| 7 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Properly trashed |
| 8 | **Verify**: `activityLog()` with type "Trashed" | Activity log entry |
| 9 | **Verify**: Row removed from active list | No longer visible |
| 10 | **Verify**: Flash success `flash('trashed.msh-marksheet-type')` | Confirmation |

### TC-P-11: Restore soft-deleted marksheet type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.restore` permission | Success |
| 2 | Navigate to trash listing via URL directly | Trashed records shown |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.restore')` passes | Authorized |
| 4 | **Verify**: `onlyTrashed()->latest()->paginate(15)` | 15 trashed per page |
| 5 | Click "Restore" on a trashed type | Restore action |
| 6 | **Verify**: `onlyTrashed()->findOrFail($id)` | Record found |
| 7 | **Verify**: `$record->restore()` sets `deleted_at = NULL` | Restored |
| 8 | **Verify**: `is_active` remains FALSE | Type stays inactive |
| 9 | **Verify**: Redirect to index + flash success | Confirmation |
| 10 | **Verify**: Restored type appears in active list (inactive status) | Visible |

### TC-P-12: Force delete trashed marksheet type (no dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.forceDelete` permission | Success |
| 2 | Navigate to trash listing | Trashed records |
| 3 | Locate a trashed type with NO dependent records | Safe to delete |
| 4 | Click "Force Delete" | Force delete action |
| 5 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.forceDelete')` passes | Authorized |
| 6 | **Verify**: `withTrashed()->findOrFail($id)` | Record found (even trashed) |
| 7 | **Verify**: `$record->forceDelete()` | Record permanently deleted |
| 8 | **Verify**: DB: 0 rows in `msh_marksheet_types` for this ID | Gone |
| 9 | **Verify**: `activityLog()` with type "Deleted" | Permanently deleted log |
| 10 | **Verify**: Redirect to index + flash `flash('force_deleted.msh-marksheet-type')` | Confirmation |

### TC-N-01: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.create` | Success |
| 2 | Open create modal, leave code EMPTY | code omitted |
| 3 | Fill name, description, display_order | Other fields filled |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `MarksheetTypeRequest` rule `required` on `code` | "The code field is required." |
| 6 | **Verify**: No record created | DB unchanged |
| 7 | **Verify**: Validation error displayed in modal | Error message visible |

### TC-N-02: Create with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.create` | Success |
| 2 | Open create modal, leave name EMPTY | name omitted |
| 3 | Fill code, description | Other fields filled |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: `required` rule on `name` | "The name field is required." |

### TC-N-03: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure type with code="MT01" exists | Existing record |
| 2 | Create new type with same code="MT01" | Duplicate |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: `Rule::unique('msh_marksheet_types', 'code')` | "The code has already been taken." |
| 5 | **Verify**: No duplicate created | DB unique maintained |

### TC-N-04: Create with code exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with code = 51 characters (exceeds max:50) | Over limit |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: Rule `max:50` on code | "The code must not be greater than 50 characters." |

### TC-N-05: Create with name exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with name = 101 characters (exceeds max:100) | Over limit |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: Rule `max:100` on name | Validation error |

### TC-N-06: Access tab without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.view` permission | No view |
| 2 | Navigate to Configuration hub | Hub page loads |
| 3 | **Verify**: Marksheet Types tab is HIDDEN via `@can('tenant.msh-marksheet-type.view')` | Tab not visible |
| 4 | Direct URL: `/marksheet-generation/configuration?tab=marksheet-types` | **Verify**: Tab nav hidden by `permission` key in nav-tab component |
| 5 | **Verify**: `@can` block prevents `@include` of body | Content not rendered |

### TC-N-07: Direct access to store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.create` | No create |
| 2 | POST valid data to store endpoint | Direct POST |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.create')` throws 403 | 403 Forbidden |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-08: Direct access to update without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.update` | No update |
| 2 | PUT valid data to update endpoint | Direct PUT |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.update')` throws 403 | 403 Forbidden |

### TC-N-09: Direct access to delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.delete` | No delete |
| 2 | DELETE to destroy endpoint | Direct DELETE |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.delete')` throws 403 | 403 Forbidden |

### TC-N-10: Access trash without restore permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.restore` | No restore |
| 2 | Navigate to trash URL | Direct access |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.restore')` at `MarksheetTypeController.php:123` throws 403 | 403 Forbidden |

### TC-N-11: Access forceDelete without forceDelete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.msh-marksheet-type.forceDelete` | No forceDelete |
| 2 | POST to forceDelete endpoint | Direct access |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.forceDelete')` throws 403 | 403 Forbidden |

### TC-N-12: Restore non-trashed (active) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure type exists with `deleted_at=NULL` (active) | Active record |
| 2 | Call restore on this active record | Restore route |
| 3 | **Verify**: `Gate::authorize('tenant.msh-marksheet-type.restore')` passes | Authorized |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` | Active record NOT found (deleted_at IS NULL) |
| 5 | **Verify**: `findOrFail()` throws ModelNotFoundException | 404 error |

### TC-N-13: Toggle status with invalid is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` | Success |
| 2 | POST to toggleStatus with `is_active=2` (non-boolean) | Invalid value |
| 3 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` | "The is active field must be true or false." |
| 4 | **Verify**: 422 JSON validation error response | Error details |

### TC-N-14: Toggle status without is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.update` | Success |
| 2 | POST to toggleStatus WITHOUT is_active param | Missing param |
| 3 | **Verify**: `required|boolean` validation | "The is active field is required." |

### TC-N-15: Edit with code changed to duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure types "MT01" and "MT02" exist | Two distinct types |
| 2 | Edit "MT02", change code from "MT02" to "MT01" | Duplicate code |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `Rule::unique('msh_marksheet_types', 'code')->ignore($id)` | Unique violation — ignores own ID but catches other |
| 5 | **Verify**: "The code has already been taken." | Conflict error |

### TC-D-01: Force delete type with dependent exam groups (FK dependency)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create marksheet type "MT-DEP" | Parent record |
| 2 | Create exam group referencing marksheet_type_id="MT-DEP" | Dependent record in `msh_exam_groups` |
| 3 | Soft-delete the marksheet type "MT-DEP" | `is_active=0`, `deleted_at` set |
| 4 | Navigate to trash, attempt force delete | Force delete action |
| 5 | **Verify**: `forceDelete()` called on record | `$record->forceDelete()` |
| 6 | **Verify**: DB foreign key constraint — `msh_exam_groups.marksheet_type_id` references `msh_marksheet_types.id` | FK constraint prevents delete |
| 7 | **Verify**: `QueryException` with code `23000` | Integrity constraint violation |
| 8 | **Verify**: Catch block: `if ($e->getCode() == '23000')` | Catches FK violation |
| 9 | **Verify**: Flash error "Cannot delete due to existing records" | User-friendly error |
| 10 | **Verify**: Record remains in trash | Delete prevented |

### TC-D-02: Duplicate code after force-delete (unique re-use)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create type with code="UNIQUE01" | Record exists |
| 2 | Soft-delete (destroy) | Trashed |
| 3 | Force-delete | Permanently removed |
| 4 | Create new type with same code="UNIQUE01" | Unique rule does NOT check force-deleted records |
| 5 | **Verify**: New record created successfully with code="UNIQUE01" | DB allows re-use |

### TC-D-03: `is_active=false` set before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note type state: is_active=1, deleted_at=NULL | Active |
| 2 | Call destroy | Soft-delete |
| 3 | DB check: `SELECT is_active, deleted_at FROM msh_marksheet_types WHERE id=X` | `is_active=0`, `deleted_at` IS NOT NULL |
| 4 | **Verify**: Destroy set `is_active=false` BEFORE `delete()` | Code path: `is_active=false → save() → delete()` |
| 5 | **Verify**: Restored type will be inactive | Consistent state |

### TC-D-04: Toggle status after soft-delete (record not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a marksheet type | Trashed |
| 2 | Try to toggle its status via toggleStatus route | AJAX POST |
| 3 | **Verify**: `MarksheetType::findOrFail($id)` | `findOrFail()` excludes soft-deleted (no `withTrashed()`) |
| 4 | **Verify**: `ModelNotFoundException` → 404 | Cannot toggle trashed record |

### TC-D-05: Update after soft-delete (record not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a marksheet type | Trashed |
| 2 | Attempt to update via edit form | PUT request |
| 3 | **Verify**: `MarksheetType::findOrFail($id)` | Soft-deleted not found |
| 4 | **Verify**: 404 error | Record not found |

### TC-D-06: `activityLog()` called after forceDelete (logs for deleted record)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force delete a trashed marksheet type | Permanently removed |
| 2 | Check activity log table | Log entry exists referencing the now-deleted record |
| 3 | **Verify**: Log type "Deleted", message contains `forceDelete` flash | Activity recorded before record removal |
| 4 | **Verify**: Polymorphic relationship may show null model after deletion | Activity remains even though model gone |

### TC-CR-01: Verify `Gate::authorize('tenant.msh-marksheet-type.create')` in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:31` | `Gate::authorize('tenant.msh-marksheet-type.create')` |
| 2 | Verify permission string matches `permissionslist.php` | Consistent |

### TC-CR-02: Verify `Gate::authorize('tenant.msh-marksheet-type.update')` in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:74` | `Gate::authorize('tenant.msh-marksheet-type.update')` |
| 2 | Compare with existing module pattern | Consistent |

### TC-CR-03: Verify `Gate::authorize('tenant.msh-marksheet-type.delete')` in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:93` | `Gate::authorize('tenant.msh-marksheet-type.delete')` |
| 2 | Verify destroy() correctly gated | Authorized |

### TC-CR-04: Verify `Gate::authorize('tenant.msh-marksheet-type.restore')` in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:130` | `Gate::authorize('tenant.msh-marksheet-type.restore')` |
| 2 | **OBSERVATION**: Permission uses `restore` — correct | Consistent |

### TC-CR-05: Verify `Gate::authorize('tenant.msh-marksheet-type.forceDelete')` in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:145` | `Gate::authorize('tenant.msh-marksheet-type.forceDelete')` |
| 2 | Verify policy has matching method | Consistent |

### TC-CR-06: Verify `activityLog()` call in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:36-38` | `activityLog($record, 'Stored', ['message' => '...'])` |
| 2 | **OBSERVATION**: `performed_by` key MISSING | Inconsistent with reference |

### TC-CR-07: Verify `activityLog()` call in update() with change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:79-83` | `foreach ($record->getChanges() ...)` change tracking loop |
| 2 | Verify `$original = $record->getOriginal()` captured before update | Pre-state captured |
| 3 | Verify `updated_at` excluded from changes | `if ($field === 'updated_at') continue` |
| 4 | **OBSERVATION**: `performed_by` key MISSING | Inconsistent |

### TC-CR-08: Verify `activityLog()` call in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:99-101` | `activityLog($record, 'Trashed', ['message' => '...'])` |
| 2 | **OBSERVATION**: `performed_by` key MISSING | Inconsistent |

### TC-CR-09: Verify `activityLog()` call in toggleStatus()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:117` | `activityLog($record, 'Toggled', ['message' => '...'])` |
| 2 | **OBSERVATION**: `performed_by` key MISSING | Inconsistent |

### TC-CR-10: Verify `$request->validated()` used (not raw input)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 33 | `MarksheetType::create($request->validated())` |
| 2 | Open update() line 77 | `$record->update($request->validated())` |
| 3 | **Result**: Both use validated data | No raw `$request->input()` used |

### TC-CR-11: Verify `prepareForValidation()` normalizations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeRequest.php:48-53` | `$this->merge(['is_active' => $this->boolean('is_active')])` |
| 2 | Verify `boolean('is_active')` converts string to boolean | "0"/"1" → false/true |
| 3 | Verify `(int) display_order` conversion | String "1" → int 1 |

### TC-CR-12: Verify `$fillable` matches DDL columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetType.php:10-18` | `['code', 'name', 'description', 'display_order', 'is_active', 'created_by', 'updated_by']` |
| 2 | Cross-check with migration DDL | All fillable columns exist in DB |

### TC-CR-13: Verify `$casts` for boolean/integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetType.php:19-22` | `'is_active' => 'boolean'`, `'display_order' => 'integer'` |
| 2 | Verify cast types match usage | `is_active` toggles use boolean logic |

### TC-CR-14: Verify `SoftDeletes` trait present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetType.php:7` | `use HasFactory, SoftDeletes;` |
| 2 | Verify `deleted_at` column in DDL | Migration includes `softDeletes()` |

### TC-CR-15: Verify `toggleStatus()` inline validation rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:113-114` | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | Verify no custom FormRequest used for toggle | Inline validation (not MarksheetTypeRequest) |

### TC-CR-16: Verify `edit()` redirects to hub with tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:66` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'marksheet-types'])` |
| 2 | Verify tab param | `marksheet-types` tab |

### TC-CR-17: Verify `show()` uses `findOrFail()`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:53` | `MarksheetType::findOrFail($id)` |
| 2 | Verify manual lookup (no route-model-binding) | Explicit find |

### TC-CR-18: Verify `destroy()` 3-step sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:95-98` | `$record->is_active = false; $record->save(); $record->delete()` |
| 2 | Verify order | Deactivate → persist → soft-delete |

### TC-CR-19: Verify `restore()` does not reactivate is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:131-136` | `$record->restore()` — no `is_active=true` assignment |
| 2 | Compare with ConfigTemplate which sets is_active=true | Entity-specific behavior |

### TC-CR-20: Verify `@can('tenant.msh-marksheet-type.view')` tab permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `configuration.blade.php:12` | `'permission' => 'tenant.msh-marksheet-type.view'` |
| 2 | **OBSERVATION**: Uses `.view` instead of `.viewAny` | Inconsistent with standard pattern |

### TC-CR-21: Verify `_marksheet-types.blade.php` has `@canany` for action column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade: th(42-47) and td(57-66) | `@canany(['tenant.msh-marksheet-type.view', '...update', '...delete'])` |
| 2 | Verify closed with `@endcanany` | Proper closing |

### TC-CR-22: Verify `forceDelete()` catches QueryException 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:151-155` | `catch (\Exception $e) { if($e->getCode() == '23000') ... }` |
| 2 | Verify flash message | "Cannot delete due to existing records" |
| 3 | Verify redirect back to trash | Stays on trash page |

### TC-CR-23: Verify `trashed()` pagination = 15

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:125` | `onlyTrashed()->latest()->paginate(15)` |
| 2 | Verify paginator count | 15 per page (not default 10) |

### TC-CR-24: Verify `Gate::authorize()` in `trashed()` uses correct permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:123` | `Gate::authorize('tenant.msh-marksheet-type.restore')` |
| 2 | Verify string | Uses restore (correct for trash page access) |

### TC-CR-25: Verify `Gate::authorize()` in `toggleStatus()` uses update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetTypeController.php:111` | `Gate::authorize('tenant.msh-marksheet-type.update')` |
| 2 | **Note**: Status toggle reuses update permission | No dedicated status permission |

### TC-P-13: Create marksheet type with display_order=0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-marksheet-type.create` | Success |
| 2 | Open create modal, code="MT-ZERO", name="Zero Order Type" | Fields populated |
| 3 | Set display_order=0 | Zero value entered |
| 4 | Click "Save" | POST request |
| 5 | **Verify**: display_order=0 stored as integer 0 | Not treated as null |
| 6 | **Verify**: Sorting: 0 appears before positive values | Correct order |

### TC-P-14: Search by name (partial match)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search "Primary" | GET with `?search=Primary` |
| 2 | **Verify**: Controller WHERE `name LIKE '%Primary%'` | Matching results |
| 3 | **Verify**: Both code and name searchable | OR condition |

### TC-N-16: Description exceeding column max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with description = 501 chars | Over varchar(500) limit |
| 2 | **Verify**: DB truncation or error per DDL | Handled at DB level |

### TC-N-17: XSS injection attempt in name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with name = `<img src=x onerror=alert(1)>` | XSS payload |
| 2 | **Verify**: Blade auto-escapes via `{{ }}` | Rendered as text |

### TC-N-18: Mass assignment of non-fillable field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `is_admin=1` in addition to valid fields | Extra param |
| 2 | **Verify**: `$fillable` guard prevents assignment | Extra field silently ignored |

### TC-D-07: Concurrent double-click on status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click status toggle twice | Two AJAX POSTs |
| 2 | **Verify**: Final state = `is_active` of last request | Race condition possible |

### TC-D-08: Stale edit data (mid-air collision)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens edit modal | Reads current data |
| 2 | User B updates same record | Competing write |
| 3 | User A submits update | Overwrites User B's data (last-write-wins) |
| 4 | **Verify**: No optimistic locking | Potential data loss |

### TC-D-09: Session expiry during create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Wait for session to expire after login | Session timeout |
| 2 | Submit create form | POST request |
| 3 | **Verify**: CSRF token mismatch | 419 Page Expired |

### TC-D-10: Verify activityLog persists after force-delete (polymorphic null)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a marksheet type | Permanently removed |
| 2 | Query activity_log table for type "Deleted" with subject_type=MarksheetType | Log entry exists |
| 3 | **Verify**: subject_id references now-deleted ID | Activity preserved even without model |

### TC-P-13: Show page with all FK relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open show for marksheet type | Detail page |
| 2 | **Verify**: `$record->load(['appliesTo', 'academicSession'])` | Both relations loaded |
| 3 | **Verify**: applies_to name rendered | Session name also shown |

### TC-P-14: Create with description exactly 500 chars (max)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST description = string of exactly 500 characters | Max limit |
| 2 | **Verify**: `max:500` validation passes | Description stored |
| 3 | **Verify**: Read back from DB | Exactly 500 chars |

### TC-P-15: Update only name, keep other fields unchanged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for marksheet type | Form pre-filled |
| 2 | Change name only | Single field modified |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `$changes` shows only name field changed | Minimal audit |
| 5 | **Verify**: `updated_at` excluded from changes | Not in audit log |

### TC-N-19: Create with applies_to exceeding 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST applies_to = string of 101 characters | Over varchar(100) |
| 2 | **Verify**: `max:100` validation fails | Field error |

### TC-N-20: Edit to empty name (required)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit name to empty string | Blank |
| 2 | **Verify**: `required` validation on update | "The name field is required." |

### TC-N-21: Mass assignment of is_admin field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST extra field is_admin=1 | Non-fillable |
| 2 | **Verify**: `$fillable` guard | Silently ignored |

### TC-D-11: Transaction rollback on service layer failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mock DB::rollback() during store | Transaction failure |
| 2 | **Verify**: `DB::beginTransaction()` called first | Transaction started |
| 3 | **Verify**: On exception, `DB::rollBack()` and flash error | Rollback + error message |

### TC-D-12: Verify restore does NOT set is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete marksheet type | deleted_at set, is_active=0 |
| 2 | Restore from trash | Restore executed |
| 3 | **Verify**: `$record->restore()` clears deleted_at | Survives |
| 4 | **Verify**: is_active remains 0 (NOT set to 1) | Inactive after restore |

### BC-BIZ-DEEP-55: MarksheetType has DB transaction wrap in service

| # | Condition | Expected Behavior |
|---|-----------|------------------|
| BC-BIZ-DEEP-55 | `store()` wraps `create()` in `DB::transaction()` | Atomic create |
| BC-BIZ-DEEP-56 | `applies_to` relation value is a text name, not FK ID | Descriptive text stored |
| BC-BIZ-DEEP-57 | `description` is nullable — form allows empty | Optional field |
| BC-BIZ-DEEP-58 | `destroy()` does NOT set is_active=false before soft-delete | Only `$record->delete()` |
| BC-BIZ-DEEP-59 | `forceDelete()` catch block displays user-friendly 23000 message | FK constraint protected |
| BC-BIZ-DEEP-60 | Flash key `flash('created.marksheet-type')` used — check lang file | Must exist |
| BC-BIZ-DEEP-61 | No `export` or `print` methods on MarksheetTypeController | Standard CRUD only |

### CODE-TRACE-HUB: `marksheetTypesQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~240 | `private function marksheetTypesQuery(Request $request): Builder` | Private query helper for marksheet-types hub tab |
| 02 | ~241 | `$query = MarksheetType::with(['appliesTo', 'academicSession'])` | Eager load both FK relations |
| 03 | ~243 | `if ($request->input('tab') === 'marksheet-types')` | Only apply filters when tab active |
| 04 | ~244 | `->when($request->filled('search'), fn ($q) => $q->where('name', 'like', "%{$request->search}%"))` | Search on name |
| 05 | ~245 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 06 | ~247 | `return $query->latest()` | Always order by latest |
| 07 | Hub | `paginate(15, ['*'], 'marksheet_types_page')` | Unique paginator for this tab |
