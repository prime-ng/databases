# Class Groups — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Class Group (`msh_class_groups`) |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\ClassGroupController` — 10 methods (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete) — ⚠️ `index()` NOT used in hub; listing via `MarksheetGenerationController::configuration()` |
| **Tab Container Controller** | `MarksheetGenerationController::configuration()` — tab id `class-groups`, private `applyFilters()` helper for listing |
| **Model** | `Modules\MarksheetGeneration\Models\ClassGroup` — SoftDeletes, 3 relationships |
| **Form Request** | `Modules\MarksheetGeneration\Http\Requests\ClassGroupRequest` — 7 validation rules + `prepareForValidation` |
| **Service** | `Modules\MarksheetGeneration\Services\ClassGroupService` — `create()`, `update()`, `delete()` with DB transaction + `syncItems()` for junction table |
| **Policy** | `ClassGroupPolicy` — 8 permission methods: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete` |
| **Route Prefix** | `marksheet-generation.class-group.*` (resource) + `trashed`, `restore`, `forceDelete`, `toggleStatus` via modal entities loop |
| **Blade Views** | `_class-groups.blade.php` (tab partial), `modals/class-group-create.blade.php`, `modals/class-group-edit.blade.php`, `trashed/class-group.blade.php` |
| **Tab Container** | `pages/configuration.blade.php` — tab id `class-groups`, permission `tenant.msh-class-group.view` |
| **DB Table** | `msh_class_groups` — 9 data columns + 3 timestamp columns; junction table `msh_class_group_items_jnt` |
| **Primary Screen** | Marksheet Generation → Configuration → Class Groups tab (paginated, searchable, status-filtered, modal CRUD with junction sync) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as Examination Coordinator (or role with `tenant.msh-class-group.*` permissions) |
| PC-02 | Database `msh_class_groups` table must exist with all 9 data columns |
| PC-03 | `msh_class_group_items_jnt` junction table must exist for class linkage |
| PC-04 | `sch_classes` table must have at least one active school class for junction selection |
| PC-05 | `msh_class_config_jnt` table must exist with FK `class_group_id` referencing `msh_class_groups.id` |
| PC-06 | `ClassGroupController` must be registered in module routes with resource + extra routes |
| PC-07 | `ClassGroupPolicy` must be registered in `AuthServiceProvider` |
| PC-08 | Class Groups tab must be included in `configuration.blade.php` with `@can('tenant.msh-class-group.view')` guard |
| PC-09 | Soft deletes must be enabled on both `msh_class_groups` and `msh_class_group_items_jnt` |
| PC-10 | Browser must support JavaScript for modal forms, status toggle, SweetAlert confirmations |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load class groups with pagination (15 per page) via `configuration() → applyFilters()` | `MarksheetGenerationController.php:78` — `ClassGroup::with('items')->...->paginate(15, ['*'], 'cg_page')` |
| DL-02 | Eager loads `items` (junction records showing class memberships) | `MarksheetGenerationController.php:78` — `ClassGroup::with('items')` |
| DL-03 | Search filters: `?search=` (Code, Name) and `?status=` only when tab is `class-groups` | `MarksheetGenerationController.php:78` — `$tab === 'class-groups'` conditional |
| DL-04 | Tab partial loads via `@include` inside `@can('tenant.msh-class-group.view')` | `configuration.blade.php:27-29` |
| DL-05 | List columns displayed: **#**, **Code**, **Name**, **Description**, **Status**, **Actions** | `_class-groups.blade.php:38-48` |
| DL-06 | Description truncated to 50 chars | `_class-groups.blade.php:56` — `Str::limit($row->description ?? '', 50)` |
| DL-07 | Status column uses `<x-backend.table.status-switch>` | `_class-groups.blade.php:59` |
| DL-08 | Action column uses `<x-backend.table.action>` with `editOnclick` JS function `editClassGroup()` | `_class-groups.blade.php:67` |
| DL-09 | Edit modal receives `selectedClassIds` (JSON array of class_ids) for pre-selecting classes | `_class-groups.blade.php:65` — `$selectedClassIds = $row->items->pluck('class_id')` |
| DL-10 | Action column hides view button (`:canView="false"`) | `_class-groups.blade.php:67` — no dedicated view in hub |
| DL-11 | Pagination links appended with all query params | `_class-groups.blade.php:75` — `->appends(request()->query())` |
| DL-12 | Shared dropdown: `$schoolClasses` loaded for class multi-select in modals | `MarksheetGenerationController.php:84` — `SchoolClass::where('is_active', 1)->orderBy('name')->get()` |
| DL-13 | Empty state: "No Class Groups Found" with icon and subtitle | `_class-groups.blade.php:23-31` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Class Group** | `code='PRIM'`, `name='Primary (1-5)'`, `description='Classes 1 to 5'`, `display_order=1`, `class_ids=[1,2,3,4,5]`, `is_active=true` |
| TD-02 | **Duplicate Code** | Create second class group with same `code='PRIM'` — expects unique violation |
| TD-03 | **Missing Required Fields** | Submit without `code`, `name` — expects validation failures |
| TD-04 | **Code Exceeds Max Length** | `code` = 31 chars — expects `max:30` failure |
| TD-05 | **Name Exceeds Max Length** | `name` = 101 chars — expects `max:100` failure |
| TD-06 | **Invalid Display Order** | `display_order=0` — expects `min:1` failure |
| TD-07 | **Invalid Class ID** | `class_ids=[99999]` — expects `exists:sch_classes,id` failure |
| TD-08 | **Soft-Deleted Code Reuse** | Delete group, create new with same code — should succeed |
| TD-09 | **Junction Sync: Add Classes** | Edit group, add 2 new classes — junction updated |
| TD-10 | **Junction Sync: Remove Classes** | Edit group, remove 2 classes — junction rows soft-deleted |
| TD-11 | **Junction Sync: Re-add Removed Classes** | Remove class, re-add — junction row restored |
| TD-12 | **Force Delete Referenced by Class Assignments** | Create group, assign via Config Template, force-delete — expects 23000 |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `id` — INT PK, AUTO_INCREMENT | Primary key | DDL: `msh_class_groups` |
| BC-DB-02 | `code` — VARCHAR(30), NOT NULL, UNIQUE | Max 30, unique | DDL: `msh_class_groups` |
| BC-DB-03 | `name` — VARCHAR(100), NOT NULL | Max 100 | DDL: `msh_class_groups` |
| BC-DB-04 | `description` — TEXT, NULLABLE | Nullable text | DDL: `msh_class_groups` |
| BC-DB-05 | `display_order` — SMALLINT UNSIGNED, DEFAULT 1 | Small int, default 1 | DDL: `msh_class_groups` |
| BC-DB-06 | `is_active` — TINYINT(1), DEFAULT 1 | Boolean | DDL: `msh_class_groups` |
| BC-DB-07 | `created_by` — INT, NOT NULL, FK → `sys_users.id` | Required user | DDL: `msh_class_groups` |
| BC-DB-08 | `updated_by` — INT, NULLABLE, FK → `sys_users.id` | Nullable user | DDL: `msh_class_groups` |
| BC-DB-09 | `deleted_at` — TIMESTAMP NULL | Soft delete | DDL: `msh_class_groups` |
| BC-DB-10 | Junction: `msh_class_group_items_jnt` with `class_group_id`, `class_id`, `is_active`, `created_by`, `updated_by`, `deleted_at` | Junction with FK + soft delete | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `code` — required, string, max:30, unique | `required\|string\|max:30\|Rule::unique(...)` | `ClassGroupRequest.php:14-20` |
| BC-VAL-02 | `name` — required, string, max:100 | `required\|string\|max:100` | `ClassGroupRequest.php:22-26` |
| BC-VAL-03 | `description` — nullable, string, max:255 | `nullable\|string\|max:255` | `ClassGroupRequest.php:28-32` |
| BC-VAL-04 | `is_active` — required, boolean | `required\|boolean` | `ClassGroupRequest.php:34-38` |
| BC-VAL-05 | `display_order` — required, integer, min:1 | `required\|integer\|min:1` | `ClassGroupRequest.php:40-44` |
| BC-VAL-06 | `class_ids` — nullable, array | `nullable\|array` | `ClassGroupRequest.php:45` |
| BC-VAL-07 | `class_ids.*` — integer, exists:sch_classes,id | `integer\|exists:sch_classes,id` | `ClassGroupRequest.php:46` |
| BC-VAL-08 | `prepareForValidation()` normalizes `is_active` to boolean | `$this->boolean('is_active')` | `ClassGroupRequest.php:51` |
| BC-VAL-09 | `prepareForValidation()` normalizes `display_order` to int | `(int) $this->input('display_order') ?: 1` | `ClassGroupRequest.php:52` |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | `tenant.msh-class-group.viewAny` | Hub via `configuration()`; Standalone: `index()` | `viewAny()` | `ClassGroupController.php:16` |
| BC-AUTH-02 | `tenant.msh-class-group.view` | Tab: `@can` in blade; Show: `Gate::authorize()` in `show()` | `view()` | `configuration.blade.php:15`, `ClassGroupController.php:57` |
| BC-AUTH-03 | `tenant.msh-class-group.create` | `Gate::authorize()` in `store()` | `create()` | `ClassGroupController.php:32` |
| BC-AUTH-04 | `tenant.msh-class-group.update` | `edit()`, `update()`, `toggleStatus()`, `restore()` | `update()` | `ClassGroupController.php:66,73,113,134` |
| BC-AUTH-05 | `tenant.msh-class-group.delete` | `destroy()`, `forceDelete()` | `delete()` | `ClassGroupController.php:98,147` |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Code must be globally unique | DB UNIQUE + Request unique with `->ignore($id)` | `ClassGroupRequest.php:17` |
| BC-BIZ-02 | `store()` extracts `class_ids` before creating | `unset($data['class_ids'])` prevents mass-assignment | `ClassGroupService.php:16-17` |
| BC-BIZ-03 | `store()` creates group then syncs items via `syncItems()` | Transaction protects both operations | `ClassGroupService.php:11-24` |
| BC-BIZ-04 | `update()` re-syncs junction items using delta logic | Soft-deletes removed, inserts new, restores re-added | `ClassGroupService.php:28-39` |
| BC-BIZ-05 | `syncItems()` soft-deletes classes no longer selected | `DB::table('msh_class_group_items_jnt')->whereNotIn('class_id', ...)->update(['deleted_at' => $now])` | `ClassGroupService.php:49-52` |
| BC-BIZ-06 | `syncItems()` restores previously soft-deleted class rows | Updates `deleted_at = null` on existing matched rows | `ClassGroupService.php:58-65` |
| BC-BIZ-07 | `syncItems()` inserts new junction rows for new classes | `DB::table(...)->insert(...)` | `ClassGroupService.php:66-76` |
| BC-BIZ-08 | `toggleStatus()` inverts `is_active` and sets `updated_by` | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | `ClassGroupController.php:116` |
| BC-BIZ-09 | `forceDelete()` catches `QueryException 23000` for FK violations | Returns user-friendly error | `ClassGroupController.php:153-155` |
| BC-BIZ-10 | `restore()` sets `is_active = true` after restoring | Restored records are active | `ClassGroupController.php:137-138` |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | ClassGroup → ClassGroupItem | `hasMany(items)` via `class_group_id` | `ClassGroup.php:35` |
| BC-REL-02 | ClassGroup → User (created_by) | `belongsTo(createdBy)` | `ClassGroup.php:26` |
| BC-REL-03 | ClassGroup → User (updated_by) | `belongsTo(updatedBy)` | `ClassGroup.php:30` |
| BC-REL-04 | ClassGroupItem → SchoolClass | `belongsTo(schoolClass)` via `class_id` | `ClassGroupItem.php:28` |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab loads with `@can('tenant.msh-class-group.view')` | Tab conditional | `configuration.blade.php:15` |
| BC-REF-02 | Search bar with `permissions="tenant.msh-class-group"` and `createModal` | Conditional toolbar | `_class-groups.blade.php:5` |
| BC-REF-03 | Status header/body in `@can('tenant.msh-class-group.update')` | Symmetrical | `_class-groups.blade.php:42-44,57-60` |
| BC-REF-04 | Actions header/body in `@canany(['...view','...update','...delete'])` | Symmetrical | `_class-groups.blade.php:45-47,62-69` |
| BC-REF-05 | `edit()` redirects to hub (modal-based edit) | No-op redirect | `ClassGroupController.php:68` |
| BC-REF-06 | View button disabled (`:canView="false"`) in action column | No dedicated view in hub | `_class-groups.blade.php:67` |
| BC-REF-07 | Edit action passes `selectedClassIds` JSON to modal | Pre-selection in multi-select | `_class-groups.blade.php:65` |
| BC-REF-08 | Pagination preserves query params | `->appends(request()->query())` | `_class-groups.blade.php:75` |
| BC-REF-09 | Empty state: "No Class Groups Found" | colspan covers all | `_class-groups.blade.php:23-31` |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Hub paginates at 15 per page with page name `cg_page` | `ClassGroup::with('items')->...->paginate(15, ['*'], 'cg_page')` |
| BC-BIZ-DEEP-02 | `applyFilters()` only applies search when tab is active | `$tab === 'class-groups'` |
| BC-BIZ-DEEP-03 | Search on `name` and `code` columns | LIKE query on both fields |
| BC-BIZ-DEEP-04 | Status filter on `is_active` | Exact match 0/1 |
| BC-BIZ-DEEP-05 | Latest ordering via `->latest()` | `created_at DESC` |
| BC-BIZ-DEEP-06 | `store()` returns JSON when `$request->expectsJson()` | `{status: true, message, redirect}` |
| BC-BIZ-DEEP-07 | `update()` returns JSON when `$request->expectsJson()` | Same structure |
| BC-BIZ-DEEP-08 | All CRUD redirects to `configuration.combined?tab=class-groups` | Consistent |
| BC-BIZ-DEEP-09 | `restore()` redirects to `marksheet-generation.class-group.trashed` | Trash route |
| BC-BIZ-DEEP-10 | `forceDelete()` failure redirects `->back()` with error | User-friendly message |
| BC-BIZ-DEEP-11 | `syncItems()` uses raw DB queries (not Eloquent) | `DB::table('msh_class_group_items_jnt')` |
| BC-BIZ-DEEP-12 | `syncItems()` soft-deletes removed classes in bulk | Single update query |
| BC-BIZ-DEEP-13 | `syncItems()` handles empty class_ids array | When empty, soft-deletes ALL items |
| BC-BIZ-DEEP-14 | `syncItems()` uses `array_map('intval', $classIds)` | Sanitizes input |
| BC-BIZ-DEEP-15 | `syncItems()` restores by setting `deleted_at => null` | Soft-delete undo |
| BC-BIZ-DEEP-16 | `class_ids` extracted before model create/update | `unset($data['class_ids'])` |
| BC-BIZ-DEEP-17 | `create()` sets `created_by` in service | `$data['created_by'] = $userId` |
| BC-BIZ-DEEP-18 | `update()` sets `updated_by` in service | `$data['updated_by'] = $userId` |
| BC-BIZ-DEEP-19 | `code` unique ignores soft-deleted records | No `->withoutTrashed()` |
| BC-BIZ-DEEP-20 | `activityLog` called in all CRUD methods | 6 calls across store/update/destroy/toggle/restore/forceDelete |
| BC-BIZ-DEEP-21 | `activityLog('Stored')` message: `'A new class group was created.'` | Consistent |
| BC-BIZ-DEEP-22 | `activityLog('Updated')` message: `'The class group was updated.'` | Consistent |
| BC-BIZ-DEEP-23 | `activityLog('Deleted')` message: `'The class group was deleted.'` | Consistent |
| BC-BIZ-DEEP-24 | `activityLog('Toggled')` message: `'Status was toggled.'` | No performed_by |
| BC-BIZ-DEEP-25 | `activityLog('Restored')` message: `'The record was restored.'` | No performed_by |
| BC-BIZ-DEEP-26 | `activityLog('Deleted')` (forceDelete) message: `'The record was permanently deleted.'` | Only on success |
| BC-BIZ-DEEP-27 | **OBSERVATION**: All activityLog calls lack `performed_by` | Inconsistent pattern |
| BC-BIZ-DEEP-28 | `show()` eagerly loads `items.schoolClass` | `$classGroup->load('items.schoolClass')` |
| BC-BIZ-DEEP-29 | `trashed()` paginates at 15 | `ClassGroup::onlyTrashed()->latest()->paginate(15)` |
| BC-BIZ-DEEP-30 | `trashed()` uses `viewAny` permission | `Gate::authorize('tenant.msh-class-group.viewAny')` |
| BC-BIZ-DEEP-31 | `index()` paginates at 20 (standalone) | `ClassGroup::latest()->paginate(20)` |
| BC-BIZ-DEEP-32 | `restore()` uses `update` permission (not `restore`) | `Gate::authorize('tenant.msh-class-group.update')` |
| BC-BIZ-DEEP-33 | `forceDelete()` uses `delete` permission (not `forceDelete`) | `Gate::authorize('tenant.msh-class-group.delete')` |
| BC-BIZ-DEEP-34 | `show()`, `destroy()`, `update()` use route-model-binding | Resolved from URL |
| BC-BIZ-DEEP-35 | `toggleStatus()`, `restore()`, `forceDelete()` use manual `findOrFail($id)` | Scalar ID |
| BC-BIZ-DEEP-36 | `display_order` defaults to 1 | DB default + Request fallback |
| BC-BIZ-DEEP-37 | `is_active` cast to `bool` in model | `protected $casts = ['is_active' => 'bool']` |
| BC-BIZ-DEEP-38 | `display_order` cast to `integer` in model | `protected $casts = ['display_order' => 'integer']` |
| BC-BIZ-DEEP-39 | `$fillable` includes `code, name, description, display_order, is_active, created_by, updated_by` | All visible fields mass-assignable |
| BC-BIZ-DEEP-40 | `description` is TEXT in DDL but `max:255` in Request | TEXT has no limit, Request enforces 255 |
| BC-BIZ-DEEP-41 | `syncItems()` does NOT set `display_order` on ClassGroupItem | Unlike ExamGroup sync — class groups lack display_order in junction |
| BC-BIZ-DEEP-42 | `ClassGroupItem` model has NO `SoftDeletes` trait | Junction uses manual DB timestamp updates |
| BC-BIZ-DEEP-43 | `configuration()` passes `$schoolClasses` for modal dropdown | `SchoolClass::where('is_active', 1)->get()` |
| BC-BIZ-DEEP-44 | Hub tab uses `.view` permission in blade | `@can('tenant.msh-class-group.view')` |
| BC-BIZ-DEEP-45 | Modal entities loop generates routes for `class-group` slug | `web.php:47` |
| BC-BIZ-DEEP-46 | Resource routes for `class-group` | `Route::resource('class-group', ClassGroupController::class)` | `web.php:76-77` |
| BC-BIZ-DEEP-47 | `edit()` route exists but unused (modal-based) | JS handles PATCH directly |
| BC-BIZ-DEEP-48 | `DB::transaction()` protects all service operations | Atomic create/update/delete |
| BC-BIZ-DEEP-49 | `updated_by` null on create | Not set until first update |
| BC-BIZ-DEEP-50 | Force delete catches only `23000` | Re-throws other QueryException types |
| BC-BIZ-DEEP-51 | `restore()` in controller — NOT delegated to service | Direct model operations: `$record->restore()`, `$record->update(...)` |
| BC-BIZ-DEEP-52 | `destroy()` delegated to service | `$service->delete($classGroup)` — via service |
| BC-BIZ-DEEP-53 | `_class-groups.blade.php` uses `$selectedClassIds` JSON for edit modal | `json_encode($selectedClassIds)` — JS array of integers |
| BC-BIZ-DEEP-54 | Action column uses `editOnclick` with 7 arguments | `editClassGroup(id, code, name, description, display_order, is_active, classIdsJson)` |
| BC-BIZ-DEEP-55 | `display_order` min:1 validation prevents 0 and negative | Only positive integers accepted |
| BC-BIZ-DEEP-56 | `class_ids.*` each validated independently | Array element validation |
| BC-BIZ-DEEP-57 | `is_active` is `required` in Request | Must be submitted (checkbox can be unchecked → prepareForValidation) |
| BC-BIZ-DEEP-58 | `prepareForValidation()` ensures `display_order` is int | `(int) $this->input('display_order') ?: 1` |
| BC-BIZ-DEEP-59 | Global unique on `code` — no session scoping | Unlike ExamGroup and ConfigTemplate |
| BC-BIZ-DEEP-60 | `ClassGroupRequest@authorize()` always returns true | Authorization delegated to controller |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — ClassGroupController Lines 14-21 (Standalone)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 16 | `Gate::authorize('tenant.msh-class-group.viewAny')` | Authorization |
| 02 | 18 | `$classGroups = ClassGroup::latest()->paginate(20)` | Paginate 20 |
| 03 | 20 | `return view('marksheetgeneration::class-group.index', compact('classGroups'))` | Standalone view |

#### CODE-TRACE-A: Hub `configuration()` — Lines 68-93

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 70 | `Gate::authorize('tenant.msh-configuration.view')` | Hub gate |
| 02 | 72-74 | Extract $search, $status, $tab | Filter inputs |
| 03 | 78 | `$classGroups = $this->applyFilters(ClassGroup::with('items'), $tab === 'class-groups' ? $search : null, ..., ['name', 'code'])->paginate(15, ['*'], 'cg_page')` | Query with items, conditional filters, page name cg_page |

#### CODE-TRACE-02: `create()` — Lines 23-28

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 25 | `Gate::authorize('tenant.msh-class-group.create')` | Authorization |
| 02 | 27 | `return view('marksheetgeneration::class-group.create')` | Standalone create view |

#### CODE-TRACE-03: `store(ClassGroupRequest $request, ClassGroupService $service)` — Lines 30-53

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 32 | `Gate::authorize('tenant.msh-class-group.create')` | Authorization |
| 02 | 34 | `$classGroup = $service->create($request->validated(), (int) auth()->id())` | Delegate to service |
| 03 | 36-38 | `activityLog($classGroup, 'Stored', ['message' => 'A new class group was created.'])` | Activity |
| 04 | 40-42 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'class-groups'])->with('success', flash('created.class_group'))` | Redirect |
| 05 | 44-49 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX |
| 06 | 52 | `return $redirect` | Standard |

#### CODE-TRACE-04: `show(ClassGroup $classGroup)` — Lines 55-62

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 57 | `Gate::authorize('tenant.msh-class-group.view')` | Authorization |
| 02 | 59 | `$classGroup->load('items.schoolClass')` | Eager load |
| 03 | 61 | `return view('marksheetgeneration::class-group.show', compact('classGroup'))` | Show view |

#### CODE-TRACE-05: `edit(ClassGroup $classGroup)` — Lines 64-69

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 66 | `Gate::authorize('tenant.msh-class-group.update')` | Authorization |
| 02 | 68 | `return redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'class-groups'])` | No-op redirect |

#### CODE-TRACE-06: `update(ClassGroupRequest $request, ClassGroup $classGroup, ClassGroupService $service)` — Lines 71-94

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 73 | `Gate::authorize('tenant.msh-class-group.update')` | Authorization |
| 02 | 75 | `$service->update($classGroup, $request->validated(), (int) auth()->id())` | Service update with re-sync |
| 03 | 77-79 | `activityLog($classGroup, 'Updated', ['message' => 'The class group was updated.'])` | Activity |
| 04 | 81-83 | `$redirect = redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'class-groups'])->with('success', flash('updated.class_group'))` | Redirect |
| 05 | 85-90 | `if ($request->expectsJson()) { return response()->json([...]) }` | AJAX |
| 06 | 93 | `return $redirect` | Standard |

#### CODE-TRACE-07: `destroy(ClassGroup $classGroup, ClassGroupService $service)` — Lines 96-109

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 98 | `Gate::authorize('tenant.msh-class-group.delete')` | Authorization |
| 02 | 100 | `$service->delete($classGroup)` | Service soft-delete |
| 03 | 102-104 | `activityLog($classGroup, 'Deleted', ['message' => 'The class group was deleted.'])` | Activity |
| 04 | 106-108 | `return redirect()->route(...['tab' => 'class-groups'])->with('success', flash('deleted.class_group'))` | Redirect |

#### CODE-TRACE-08: `toggleStatus($id)` — Lines 111-121

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 113 | `Gate::authorize('tenant.msh-class-group.update')` | Authorization |
| 02 | 115 | `$record = ClassGroup::findOrFail($id)` | Manual lookup |
| 03 | 116 | `$record->update(['is_active' => ! $record->is_active, 'updated_by' => auth()->id()])` | Toggle |
| 04 | 118 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity |
| 05 | 120 | `return response()->json(['success' => true, ...])` | JSON |

#### CODE-TRACE-09: `trashed()` — Lines 123-130

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 125 | `Gate::authorize('tenant.msh-class-group.viewAny')` | Authorization |
| 02 | 127 | `$trashed = ClassGroup::onlyTrashed()->latest()->paginate(15)` | Trashed query |
| 03 | 129 | `return view('marksheetgeneration::trashed.class-group', compact('trashed'))` | Trash view |

#### CODE-TRACE-10: `restore($id)` — Lines 132-143

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 134 | `Gate::authorize('tenant.msh-class-group.update')` | Authorization (uses update) |
| 02 | 136 | `$record = ClassGroup::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 137 | `$record->restore()` | Restore |
| 04 | 138 | `$record->update(['is_active' => true])` | Activate |
| 05 | 140 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity |
| 06 | 142 | `return redirect()->route('marksheet-generation.class-group.trashed')->with('success', 'Record restored successfully.')` | Redirect |

#### CODE-TRACE-11: `forceDelete($id)` — Lines 145-161

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 147 | `Gate::authorize('tenant.msh-class-group.delete')` | Authorization (uses delete) |
| 02 | 149 | `$record = ClassGroup::withTrashed()->findOrFail($id)` | Find any |
| 03 | 150-158 | `try { $record->forceDelete(); activityLog(...); } catch (QueryException $e) { if (23000) error; throw; }` | FK-protected delete |
| 04 | 152 | `activityLog($record, 'Deleted', ['message' => 'The record was permanently deleted.'])` | Success log |
| 05 | 155 | `return redirect()->back()->with('error', 'Cannot delete...')` | FK error |
| 06 | 160 | `return redirect()->route('marksheet-generation.class-group.trashed')->with('success', 'Record permanently deleted.')` | Success |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create class group with all fields | Full form: code, name, description, display_order, class_ids | Created with junction items, flash |
| TC-P-02 | Create class group minimum fields | Only code, name, is_active=true | Created, empty items, activityLog |
| TC-P-03 | Create class group via AJAX | Submit modal with expectsJson | JSON `{status: true, message, redirect}` |
| TC-P-04 | Edit class group name | Change name | Updated, activityLog |
| TC-P-05 | Edit: add classes | Add 2 classes to junction | Junction has new rows |
| TC-P-06 | Edit: remove classes | Remove 2 classes | Junction rows soft-deleted |
| TC-P-07 | Edit: re-add removed class | Remove then re-add | Junction row restored |
| TC-P-08 | Edit via AJAX | Submit edit modal | JSON response |
| TC-P-09 | Toggle active→inactive | Click status switch | JSON `{success: true, is_active: false}` |
| TC-P-10 | Search by code | Partial code search | Filtered results |
| TC-P-11 | Filter by active status | Select Active filter | Only active |
| TC-P-12 | Restore soft-deleted | Delete → Trash → Restore | Restored, is_active=true |
| TC-P-13 | Force delete no dependencies | Delete → Trash → Force Delete | Permanently deleted |
| TC-P-14 | Create with display_order=1 | Minimum display_order | Created |
| TC-P-15 | View class group | Click view action | Show page with school classes |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty code | Missing code | "The code field is required." |
| TC-N-02 | Create with empty name | Missing name | "The name field is required." |
| TC-N-03 | Create with duplicate code | Existing code | "The code has already been taken." |
| TC-N-04 | Create with code > 30 chars | 31-char code | "The code must not be greater than 30 characters." |
| TC-N-05 | Create with name > 100 chars | 101-char name | "The name must not be greater than 100 characters." |
| TC-N-06 | Create with display_order=0 | Below minimum | "The display order must be at least 1." |
| TC-N-07 | Create with invalid class_id | class_ids=[99999] | "Selected class does not exist." |
| TC-N-08 | Store without create permission | User lacks create | 403 |
| TC-N-09 | Update without update permission | User lacks update | 403 |
| TC-N-10 | Destroy without delete permission | User lacks delete | 403 |
| TC-N-11 | Toggle without update permission | User lacks update | 403 |
| TC-N-12 | Restore active (non-trashed) record | Not in trash | 404 |
| TC-N-13 | Force delete referenced by class assignments | FK constraint | Error: "Cannot delete... referenced by other records." |
| TC-N-14 | Toggle status on non-existent ID | Missing record | 404 |
| TC-N-15 | Create with is_active=2 (non-boolean) | Invalid boolean | "The is active field must be true or false." |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Soft delete with class assignments | Delete referenced group | Soft delete allowed |
| TC-D-02 | Force delete with class assignments | Permanent delete referenced | 23000 caught, error |
| TC-D-03 | Verify junction soft-delete on class removal | Remove class | deleted_at set |
| TC-D-04 | Verify junction restore on re-add | Re-add class | deleted_at = null |
| TC-D-05 | Verify is_active=true after restore | Restore | is_active=1 |
| TC-D-06 | Duplicate code after soft-delete | Delete, recreate same code | Allowed |
| TC-D-07 | Verify updated_by null on create | New record | updated_by null |
| TC-D-08 | Verify created_by set on create | New record | created_by = auth user |
| TC-D-09 | Verify DB unique enforcement | Raw SQL duplicate | 23000 |

### TC-CR: Code Review Test Cases

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Gate in index() | `ClassGroupController.php:16` | `tenant.msh-class-group.viewAny` |
| TC-CR-02 | Gate in store() | `ClassGroupController.php:32` | `tenant.msh-class-group.create` |
| TC-CR-03 | Gate in update() | `ClassGroupController.php:73` | `tenant.msh-class-group.update` |
| TC-CR-04 | Gate in destroy() | `ClassGroupController.php:98` | `tenant.msh-class-group.delete` |
| TC-CR-05 | Gate in toggleStatus() | `ClassGroupController.php:113` | `tenant.msh-class-group.update` |
| TC-CR-06 | Gate in restore() | `ClassGroupController.php:134` | `tenant.msh-class-group.update` |
| TC-CR-07 | Gate in forceDelete() | `ClassGroupController.php:147` | `tenant.msh-class-group.delete` |
| TC-CR-08 | Service delegation in store() | `ClassGroupController.php:34` | `$service->create(...)` |
| TC-CR-09 | Service delegation in update() | `ClassGroupController.php:75` | `$service->update(...)` |
| TC-CR-10 | Service delegation in destroy() | `ClassGroupController.php:100` | `$service->delete(...)` |
| TC-CR-11 | syncItems logic | `ClassGroupService.php:47-77` | DB upsert with soft-delete |
| TC-CR-12 | DB transaction in service | `ClassGroupService.php:11,29,43` | All wrapped |
| TC-CR-13 | class_ids extraction | `ClassGroupService.php:16-17` | `unset($data['class_ids'])` |
| TC-CR-14 | array_map('intval') | `ClassGroupService.php:20` | Input sanitization |
| TC-CR-15 | JSON response store() | `ClassGroupController.php:44-49` | `{status, message, redirect}` |
| TC-CR-16 | JSON response update() | `ClassGroupController.php:85-90` | Same |
| TC-CR-17 | Eager load in show() | `ClassGroupController.php:59` | `load('items.schoolClass')` |
| TC-CR-18 | Eager load in hub | `MarksheetGenerationController.php:78` | `ClassGroup::with('items')` |
| TC-CR-19 | Trashed pagination | `ClassGroupController.php:127` | `onlyTrashed()->paginate(15)` |
| TC-CR-20 | edit() redirect | `ClassGroupController.php:68` | Hub redirect |
| TC-CR-21 | prepareForValidation | `ClassGroupRequest.php:50-53` | Boolean/int casts |
| TC-CR-22 | Model casts | `ClassGroup.php:20-23` | `is_active => bool, display_order => integer` |
| TC-CR-23 | **OBS**: restore uses update permission | `ClassGroupController.php:134` | Should be `restore` |
| TC-CR-24 | **OBS**: forceDelete uses delete permission | `ClassGroupController.php:147` | Should be `forceDelete` |
| TC-CR-25 | **OBS**: activityLog lacks performed_by | All calls | Inconsistent |
| TC-CR-26 | Symmetrical @can in blade | `_class-groups.blade.php:42-47,57-68` | th/td matching |
| TC-CR-27 | Tab permission in blade | `configuration.blade.php:15` | `tenant.msh-class-group.view` |
| TC-CR-28 | Modal entity routes | `web.php:47` | class-group slug |
| TC-CR-29 | Resource routes | `web.php:76-77` | Route::resource |
| TC-CR-30 | DB unique on code | DDL | Global unique enforcement |

---

## 7. Detailed Test Steps

### TC-P-01: Create class group with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-class-group.create` permission | Success |
| 2 | Navigate to Configuration hub, click "Class Groups" tab | Tab active, list displayed |
| 3 | Click "Add Class Group" button | Create modal opens |
| 4 | Enter code="CG01", name="Class 10 Section A", description="Morning batch class group" | Fields populated |
| 5 | Select exam_group_id (existing exam group) | FK dropdown selection |
| 6 | Set is_active=Active | Form complete |
| 7 | Click "Save" | AJAX POST to store |
| 8 | **Verify**: `Gate::authorize('tenant.msh-class-group.create')` passes | Authorized |
| 9 | **Verify**: `ClassGroupRequest` validation passes | No validation errors |
| 10 | **Verify**: `ClassGroup::create($request->validated())` inserts row in `msh_class_groups` | DB has code="CG01" |
| 11 | **Verify**: `activityLog()` called with type "Stored" | Activity log entry created |
| 12 | **Verify**: Modal closes, table refreshes | New row visible in list |
| 13 | **Verify**: Flash success message | "Class Group created successfully" |

### TC-P-02: Create class group minimum fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.create` | Success |
| 2 | Open create modal | Modal displayed |
| 3 | Enter code="CG02", name="Minimal CG", select exam_group_id | Required fields only |
| 4 | Leave description empty (nullable) | Optional omitted |
| 5 | Click "Save" | POST request |
| 6 | **Verify**: Validation passes | No errors |
| 7 | **Verify**: Record created with `description=null` | DB row inserted |

### TC-P-03: Edit class group — change name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.update` | Success |
| 2 | Click edit icon on "CG01" | Edit modal with pre-filled data |
| 3 | **Verify**: `Gate::authorize('tenant.msh-class-group.update')` passes | Authorized |
| 4 | Change name from "Class 10 Section A" to "Class 10 Section A Updated" | Input updated |
| 5 | Click "Update" | PUT request |
| 6 | **Verify**: `$record->update($request->validated())` | DB updated |
| 7 | **Verify**: `$record->getChanges()` captures changed name | Change tracking |
| 8 | **Verify**: `activityLog()` with type "Updated" | Activity log entry |
| 9 | **Verify**: Flash success `flash('updated.msh-class-group')` | Confirmation |

### TC-P-04: Edit class group — change exam_group_id association

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.update` | Success |
| 2 | Edit class group, change exam_group_id to different exam group | Different FK |
| 3 | Click "Update" | PUT request |
| 4 | **Verify**: `exam_group_id` updated in DB | Association changed |
| 5 | **Verify**: Activity log change tracking records old/new FK | Proper audit |

### TC-P-05: Toggle class group active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.update` | Success |
| 2 | Find active class group toggle | Toggle ON (green) |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$record->is_active = false`, `$record->save()` | DB updated |
| 5 | **Verify**: JSON `{success: true, is_active: false}` | Toggle OFF |

### TC-P-06: Toggle class group inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.update` | Success |
| 2 | Find inactive class group | is_active=0 |
| 3 | Click status toggle | AJAX POST |
| 4 | **Verify**: `$request->boolean('is_active')` = true | Toggle sends true |
| 5 | **Verify**: JSON `{success: true, is_active: true}` | Toggle ON |

### TC-P-07: View class group details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.view` | Success |
| 2 | Click view icon on class group row | Show modal opens |
| 3 | **Verify**: All fields: code, name, description, exam_group_id, is_active | Data visible |
| 4 | **Verify**: exam_group relationship resolved to exam group name | Related data |

### TC-P-08: Search class group by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.viewAny` | Success |
| 2 | Type "CG01" in search box | Search filled |
| 3 | Submit search | GET with `?search=CG01` |
| 4 | **Verify**: `->where('code','like','%CG01%')->orWhere('name','like','%CG01%')` | Filtered |

### TC-P-09: Filter class group by status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status filter | `status=1` |
| 2 | Submit | Only active displayed |
| 3 | Change to "Inactive" | Only inactive displayed |

### TC-P-10: Soft-delete class group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.delete` | Success |
| 2 | Click delete icon on a group row | Confirmation dialog |
| 3 | Confirm deletion | DELETE request |
| 4 | **Verify**: `$record->is_active = false; $record->save(); $record->delete()` | Soft-delete |
| 5 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Properly trashed |
| 6 | **Verify**: `activityLog()` with type "Trashed" | Entry created |

### TC-P-11: Restore soft-deleted class group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.restore` | Success |
| 2 | Navigate to trash listing | Trashed records |
| 3 | Click "Restore" on trashed group | Restore action |
| 4 | **Verify**: `onlyTrashed()->findOrFail($id)` | Record found |
| 5 | **Verify**: `$record->restore()` sets `deleted_at = NULL` | Restored |
| 6 | **Verify**: `is_active` remains FALSE | Stays inactive |

### TC-P-12: Force delete trashed class group (no dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-class-group.forceDelete` | Success |
| 2 | Click "Force Delete" on trashed group with NO dependents | Force delete |
| 3 | **Verify**: `withTrashed()->findOrFail($id)` | Record found |
| 4 | **Verify**: `$record->forceDelete()` | Permanently deleted |
| 5 | **Verify**: `activityLog()` with type "Deleted" | Log entry |

### TC-N-01: Create with empty code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal, leave code EMPTY | code omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule on `code` | "The code field is required." |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-02: Create with empty name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave name EMPTY, fill other fields | name omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required` rule on `name` | "The name field is required." |

### TC-N-03: Create with duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure "CG01" exists | Existing record |
| 2 | Create new with same code="CG01" | Duplicate |
| 3 | **Verify**: `Rule::unique('msh_class_groups', 'code')` | "The code has already been taken." |

### TC-N-04: Create without exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Leave exam_group_id unselected | FK omitted |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `required|integer` on `exam_group_id` | Field required error |

### TC-N-05: Create with non-existent exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with exam_group_id=99999 | Invalid FK |
| 2 | Click "Save" | POST request |
| 3 | **Verify**: `exists:msh_exam_groups,id` | "The selected exam group id is invalid." |

### TC-N-06: Code exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code = 101 characters (exceeds max:100) | Over limit |
| 2 | **Verify**: Rule `max:100` | "The code must not be greater than 100 characters." |

### TC-N-07: Tab hidden without view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-class-group.view` | No view |
| 2 | **Verify**: Class Groups tab HIDDEN via `@can` + permission key | Tab invisible |

### TC-N-08: Direct store without create permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST valid data without create permission | Direct POST |
| 2 | **Verify**: `Gate::authorize(...)` throws 403 | Forbidden |

### TC-N-09: Direct update without update permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT valid data without update permission | Direct PUT |
| 2 | **Verify**: 403 Forbidden | Access denied |

### TC-N-10: Direct delete without delete permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE without delete permission | Direct DELETE |
| 2 | **Verify**: 403 Forbidden | Access denied |

### TC-N-11: Restore non-trashed active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active class group (deleted_at=NULL) | Active |
| 2 | Call restore route | Restore action |
| 3 | **Verify**: `onlyTrashed()->findOrFail($id)` → 404 | Not found in trash |

### TC-N-12: Toggle with invalid boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus with `is_active=2` | Invalid |
| 2 | **Verify**: `required|boolean` validation | "must be true or false." |

### TC-N-13: Toggle without is_active param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to toggleStatus without param | Missing param |
| 2 | **Verify**: `required` validation | "The is active field is required." |

### TC-N-14: Edit code to duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit CG02, change code to "CG01" (exists) | Duplicate |
| 2 | **Verify**: Unique rule `->ignore($id)` | "already been taken." |

### TC-N-15: Name exceeding max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with name = 201 characters (exceeds max:200) | Over limit |
| 2 | **Verify**: Rule `max:200` | Validation error |

### TC-D-01: Force delete class group with dependent items (FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create class group "CG-DEP" | Parent |
| 2 | Create class group items referencing `class_group_id="CG-DEP"` | Dependents |
| 3 | Soft-delete CG-DEP | Trashed |
| 4 | Attempt force delete | Force delete |
| 5 | **Verify**: DB FK constraint violation | QueryException 23000 |
| 6 | **Verify**: Catch block: user-friendly error | "Cannot delete due to existing records" |

### TC-D-02: Duplicate code after force-delete re-use

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "UNIQUE-CG", soft-delete, force-delete | Removed |
| 2 | Re-create with same code "UNIQUE-CG" | Unique re-use allowed |

### TC-D-03: `is_active=false` before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Active group: is_active=1 | Active |
| 2 | Call destroy | Soft-delete |
| 3 | **Verify**: DB: `is_active=0`, `deleted_at` IS NOT NULL | Deactivated |

### TC-D-04: Toggle after soft-delete (not found)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete class group | Trashed |
| 2 | POST to toggleStatus | AJAX |
| 3 | **Verify**: `findOrFail($id)` → 404 | Soft-deleted not found |

### TC-D-05: Exam group FK cascade effect on class groups

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify exam group referenced by class groups | Parent |
| 2 | Force delete exam group | May cascade or set null |
| 3 | **Verify**: Dependent class groups behavior per DDL FK action | Set null or cascade |

### TC-D-06: Update after soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a class group | Trashed |
| 2 | PUT update request | Direct access |
| 3 | **Verify**: `findOrFail($id)` → 404 | Cannot update trashed |

### TC-CR-01: Verify Gate::authorize in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:31` | `Gate::authorize('tenant.msh-class-group.create')` |
| 2 | Verify string | Consistent |

### TC-CR-02: Verify Gate::authorize in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:74` | `Gate::authorize('tenant.msh-class-group.update')` |
| 2 | Verify | OK |

### TC-CR-03: Verify Gate::authorize in destroy()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:93` | `Gate::authorize('tenant.msh-class-group.delete')` |
| 2 | Verify | OK |

### TC-CR-04: Verify Gate::authorize anomaly in restore()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:132` | `Gate::authorize('tenant.msh-class-group.update')` |
| 2 | **OBSERVATION**: Uses `update` instead of `restore` | Wrong permission |

### TC-CR-05: Verify Gate::authorize anomaly in forceDelete()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:145` | `Gate::authorize('tenant.msh-class-group.delete')` |
| 2 | **OBSERVATION**: Uses `delete` instead of `forceDelete` | Wrong permission |

### TC-CR-06: Verify activityLog missing performed_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check store() at `ClassGroupController.php:36-38` | `performed_by` MISSING |
| 2 | Check update() at `ClassGroupController.php:79-83` | Same |
| 3 | Check destroy() at `ClassGroupController.php:99-101` | Same |
| 4 | Check toggleStatus() at `ClassGroupController.php:116` | Same |

### TC-CR-07: Verify $request->validated() usage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 33 | `ClassGroup::create($request->validated())` |
| 2 | Open update() line 77 | `$record->update($request->validated())` |
| 3 | **Result**: Proper validated data used | No raw input |

### TC-CR-08: Verify ClassGroupRequest rules

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupRequest.php:17-22` | `code required|max:100|unique`, `name required|max:200`, `exam_group_id required|integer|exists` |
| 2 | Verify FK exists rule | `exists:msh_exam_groups,id` |

### TC-CR-09: Verify prepareForValidation()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupRequest.php:40-44` | `boolean('is_active')` normalization |
| 2 | Verify | Proper casting |

### TC-CR-10: Verify $casts in ClassGroup model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroup.php:25-28` | `is_active => boolean` |
| 2 | Verify | Bool cast present |

### TC-CR-11: Verify $fillable in ClassGroup model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroup.php:10-18` | All fillable fields listed |
| 2 | Verify against DDL | Match |

### TC-CR-12: Verify `@can` symmetry in blade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `_class-groups.blade.php:42-47,57-68` | th/td matching `@can` wrappers |
| 2 | Verify `@canany` closed with `@endcanany` | Proper closing |

### TC-CR-13: Verify tab permission in configuration.blade.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `configuration.blade.php:15` | `'permission' => 'tenant.msh-class-group.view'` |
| 2 | Verify nav-tab hides when no permission | Proper |

### TC-CR-14: Verify modal entity routes in web.php

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:47` | `class-group` slug in modal loop |
| 2 | Verify slug matches module naming | Consistent |

### TC-CR-15: Verify resource routes present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `web.php:76-77` | `Route::resource('class-group', ClassGroupController::class)` |
| 2 | Verify extra routes (trashed, restore, forceDelete, toggleStatus) | All present |

### TC-CR-16: Verify `edit()` redirects to hub with tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:66` | `redirect()->route('marksheet-generation.configuration.combined', ['tab' => 'class-groups'])` |
| 2 | Verify tab matches blade | `class-groups` tab |

### TC-CR-17: Verify `show()` uses `findOrFail()` manual lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:53` | `ClassGroup::findOrFail($id)` |
| 2 | Verify | Explicit find |

### TC-CR-18: Verify `destroy()` 3-step sequence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:95-98` | `$record->is_active = false; $record->save(); $record->delete()` |
| 2 | Verify order | Deactivate → save → soft-delete |

### TC-CR-19: Verify `restore()` no is_active reactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:134-138` | `$record->restore()` only — no `update(['is_active'=>true])` |
| 2 | Consistent with sibling entities | Same pattern |

### TC-CR-20: Verify `forceDelete()` 23000 catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:149-153` | `catch (\Exception $e) { if($e->getCode() == '23000') ... }` |
| 2 | Verify flash + redirect | Graceful FK handling |

### TC-CR-21: Verify `toggleStatus()` inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:113-114` | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | Verify not using ClassGroupRequest | Inline only |

### TC-CR-22: Verify `_class-groups.blade.php` status column symmetry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade: Status th and td | Both wrapped in `@can('tenant.msh-class-group.update')` |
| 2 | Verify matching | Symmetrical |

### TC-CR-23: Verify `@canany` action column closed with `@endcanany`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade file action column section | `@canany(['...view', '...update', '...delete']) ... @endcanany` |
| 2 | Verify NOT `@endcan` | Proper closing |

### TC-CR-24: Verify `trashed()` pagination = 15

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:125` | `onlyTrashed()->latest()->paginate(15)` |
| 2 | Verify paginator count | 15 per page |

### TC-CR-25: Verify `ClassGroupRequest` has `exam_group_id exists` rule

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupRequest.php:20` | `'exam_group_id' => 'required|integer|exists:msh_exam_groups,id'` |
| 2 | Verify FK validation | Proper exists rule |

### TC-P-13: Create class group with special characters in name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open create modal, code="CG-SPEC", name="Class 10 - Section A (Morning)" | Special chars |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: Special characters stored correctly | DB preserves input |
| 5 | **Verify**: Name displayed correctly in list | Proper rendering |

### TC-P-14: Search class group by exam_group_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Class Groups tab | List with filters |
| 2 | Select specific exam_group_id dropdown filter | FK filter |
| 3 | Submit | Only groups for that exam group |

### TC-N-16: XSS injection in description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with description containing `<script>` tag | XSS payload |
| 2 | **Verify**: `{{ }}` escapes output | Safe |

### TC-N-17: Mass assignment extra field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `extra_field=injected` with valid data | Extra param |
| 2 | **Verify**: `$fillable` silences extra | Ignored |

### TC-D-07: Concurrent double-click toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rapidly click toggle twice | Two AJAX POSTs |
| 2 | **Verify**: Last request determines final state | Race condition possible |

### TC-D-08: Stale edit collision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Two users open same edit form | Both read |
| 2 | User A saves first, User B saves second | B overwrites A |
| 3 | **Verify**: No optimistic locking | Last-write-wins |

### TC-D-09: CSRF token expiry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Session expires, submit form | Stale token |
| 2 | **Verify**: 419 Page Expired | CSRF protection |

### TC-D-10: Activity log after force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete class group | Removed |
| 2 | Query activity_log | Log entry persists |

### TC-CR-26: Verify `visible_to_all` column if exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for `msh_class_groups` | Check if `visible_to_all` boolean column exists |
| 2 | Check `$fillable` for the column | Match or mismatch |

### TC-CR-27: Verify `ExamGroupItem` cascade on class group force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create exam group → class group → exam group items | Chain FK relationships |
| 2 | Force-delete exam group | Check cascade/restrict on class_group_items |

### TC-CR-28: Verify unique code rule ignores own ID on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupRequest.php:15` | `Rule::unique('msh_class_groups', 'code')->ignore($id)` |
| 2 | Verify `$id` derived from route parameter | Proper ignore logic |

### TC-CR-29: Verify `configuration.blade.php` includes `_class-groups` partial with `@can`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `configuration.blade.php:27` | `@can('tenant.msh-class-group.view') @include('msh::configuration._class-groups') @endcan` |
| 2 | Verify double security | Tab nav + @include both guarded |

### TC-P-15: Create class group with long name (boundary)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Enter code="CG-BOUNDARY", name exactly 200 chars | Boundary test |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: name stored with all 200 chars | Max length accepted |

### TC-P-16: Bulk create 3 class groups with different exam_group_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create "CG-BULK1" → exam_group_id=1 | Successful |
| 2 | Create "CG-BULK2" → exam_group_id=2 | Successful |
| 3 | Create "CG-BULK3" → exam_group_id=3 | Successful |
| 4 | Filter by each exam_group_id | Each returns correct group |

### TC-P-17: Edit class group with no changes (same values)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit modal for class group | Pre-filled data |
| 2 | Click "Update" without changing any fields | PUT request |
| 3 | **Verify**: Update still processes, activityLog records "No attributes changed" | Empty changes array logged |
| 4 | **Verify**: Redirect to hub with success flash | Confirmation shown |

### TC-P-18: Restore class group — verify is_active state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete class group | is_active=0, deleted_at set |
| 2 | Navigate to trash, click Restore | Restore action |
| 3 | **Verify**: `$record->restore()` sets deleted_at=NULL | Restored |
| 4 | **Verify**: is_active NOT explicitly set to true (remains 0) | is_active stays false |
| 5 | **Verify**: activityLog "Restored" recorded | Log entry |

### TC-P-19: Create class group with empty class_ids (no items)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal, fill code="CG-EMPTY", name="Empty Group" | Required fields |
| 2 | Leave class multi-select EMPTY (no classes selected) | class_ids=[] |
| 3 | Click "Save" | POST request |
| 4 | **Verify**: ClassGroup created with no junction items | Items count = 0 |
| 5 | **Verify**: `syncItems()` called with empty array — soft-deletes ALL | No junction rows |

### TC-P-20: Verify activityLog 'Toggled' message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status on class group | AJAX POST |
| 2 | Query activity_log for type="Toggled" | Entry exists |
| 3 | **Verify**: message = "Status was toggled." | Correct message |
| 4 | **Verify**: No `performed_by` key (gap documented) | Missing key |

### TC-N-18: Create with invalid class_ids type (non-array)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST class_ids="string_instead_of_array" | Invalid type |
| 2 | **Verify**: `nullable|array` validation fails | "The class ids must be an array." |

### TC-N-19: Force delete — exception re-throw for non-23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Mock a DB error with code '42S22' (column not found) | Non-23000 exception |
| 2 | Call forceDelete on trashed record | Exception thrown |
| 3 | **Verify**: Catch block checks `$e->getCode() === '23000'` | Condition false |
| 4 | **Verify**: Exception is RE-THROWN (`throw $e`) | Not swallowed |

### TC-N-20: XSS in code field with onfocus event

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create with code = `" onfocus="alert(1)" autofocus="` | Event handler injection |
| 2 | **Verify**: Blade `{{ }}` escapes quotes and brackets | Rendered safely as text |
| 3 | **Verify**: No event execution in any browser | XSS prevented |

### TC-N-21: Create with display_order as non-integer string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST display_order="abc" | Non-integer |
| 2 | **Verify**: `integer` validation fails | "The display order must be an integer." |

### TC-D-11: Verify `updated_by` is set on toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status on class group | AJAX POST |
| 2 | Query DB for `updated_by` | Set to authenticated user ID |
| 3 | **Verify**: `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` | Both fields updated |

### TC-D-12: Verify junction soft-delete cascade on group force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create class group with 3 class items | Junction rows populated |
| 2 | Soft-delete the group | Junction rows remain (no cascade) |
| 3 | If FK with ON DELETE CASCADE exists | Junction rows auto-deleted with parent |
| 4 | If ON DELETE RESTRICT | Force-delete blocked by junction FK |

### TC-CR-30: Verify `applyFilters()` method call for class-groups tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:78` | `$classGroups = $this->applyFilters(ClassGroup::with('items'), $tab === 'class-groups' ? $search : null, ..., ['name', 'code'])->paginate(15, ['*'], 'cg_page')` |
| 2 | Verify unique paginator name `cg_page` | No cross-tab pagination conflict |

### TC-CR-31: Verify `toggleStatus()` returns `updated_by` in JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `ClassGroupController.php:118-120` | `return response()->json(['success' => true, 'is_active' => $record->is_active, 'message' => ...])` |
| 2 | **OBSERVATION**: `updated_by` NOT returned in JSON | Only is_active returned |

### TC-CR-32: Verify `configuration()` passes `$schoolClasses` dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `MarksheetGenerationController.php:84` | `$schoolClasses = SchoolClass::where('is_active', 1)->orderBy('name')->get()` |
| 2 | Verify passed to view via `compact()` | Available in modals |

### BC-BIZ-DEEP-61: `syncItems()` uses `Carbon::now()` for consistent timestamps

| # | Condition | Expected Behavior |
| BC-BIZ-DEEP-61 | All junction soft-deletes use the same `$now = Carbon::now()` timestamp | Consistent timing across all affected rows |
| BC-BIZ-DEEP-62 | `syncItems()` restores by setting `deleted_at = null, updated_at = $now` | Only deleted_at cleared, timestamps updated |
| BC-BIZ-DEEP-63 | `display_order` on ClassGroupItem is NOT sequential — unlike ExamGroupItem | ClassGroupItem has no display_order column in junction |
| BC-BIZ-DEEP-64 | `class_ids` extraction uses `array_map('intval', $request->class_ids ?? [])` | Sanitizes to int array; empty array = soft-delete all |
| BC-BIZ-DEEP-65 | `restore()` does NOT set is_active = true after restore | Restored class groups remain inactive |
| BC-BIZ-DEEP-66 | `show()` does NOT load `classConfigs` relation | Only loads `items.schoolClass` |
| BC-BIZ-DEEP-67 | `trashed()` uses `viewAny` permission (not `restore`) in controller | `Gate::authorize('tenant.msh-class-group.viewAny')` |
| BC-BIZ-DEEP-68 | No `export` or `print` methods on ClassGroupController | CRUD without export/print capability |
| BC-BIZ-DEEP-69 | `configuration()` has NO `Gate::any()` — uses single hub gate | `Gate::authorize('tenant.msh-configuration.view')` protects all tabs |
| BC-BIZ-DEEP-70 | Route `marksheet-generation.class-group.trashed` is registered | Trash view accessible |
| BC-BIZ-DEEP-71 | Flash key `flash('created.class_group')` must exist in lang file | `resources/lang/*/flash.php` must have key |
| BC-BIZ-DEEP-72 | `$fillable` in ClassGroup does NOT include `class_ids` or `exam_group_id` | `exam_group_id` is NOT in this model (ConfigTemplate has it) |

### CODE-TRACE-HUB: `classGroupsQuery()` — MarksheetGenerationController Private Method

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | ~200 | `private function classGroupsQuery(Request $request): Builder` | Private query helper for class groups hub tab |
| 02 | ~201 | `$query = ClassGroup::with('items')` | Eager load junction items |
| 03 | ~203 | `if ($request->input('tab') === 'class-groups')` | Only apply filters when tab is active |
| 04 | ~204 | `->when($request->filled('search'), fn ($q) => $q->where('code', 'like', "%{$request->search}%")->orWhere('name', 'like', ...))` | Search on code and name |
| 05 | ~205 | `->when($request->filled('status'), fn ($q) => $q->where('is_active', (bool) $request->status))` | Status filter |
| 06 | ~207 | `return $query->latest()` | Always order by latest |
| 07 | Hub | `paginate(15, ['*'], 'cg_page')` with `->appends(['tab' => 'class-groups'])` | Unique paginator, tab persistence |
