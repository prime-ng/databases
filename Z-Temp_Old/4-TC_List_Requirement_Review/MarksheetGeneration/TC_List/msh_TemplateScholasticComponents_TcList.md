# Template Scholastic Components — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Template Scholastic Components (msh_template_scholastic_components) |
| **Controller** | Modules\MarksheetGeneration\Http\Controllers\TemplateScholasticComponentController — 11 methods (show, create, store, edit, update, destroy, trashed, restore, forceDelete, toggleStatus) — index() NOT called; tab listing uses MarksheetGenerationController@components() |
| **Tab Container Controller** | Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@components() — tab id scholastic-components, private pplyFilters() for listing |
| **Model** | Modules\MarksheetGeneration\Models\TemplateScholasticComponent — SoftDeletes, BaseModel, 4 relationships |
| **Form Request** | Modules\MarksheetGeneration\Http\Requests\TemplateScholasticComponentRequest — 6 validation rules + prepareForValidation |
| **Policy** | TemplateScholasticComponentPolicy — permission prefix 	enant.msh-template-scholastic-component.* |
| **Service** | TemplateScholasticComponentService — wraps create/update/delete in DB transactions; calls MarksheetConfigService::validateScholasticWeightageSum() after create/update |
| **Route Prefix** | marksheet-generation.template-scholastic-component.* (resource) + 	rashed, estore, orceDelete, 	oggleStatus |
| **Blade Views** | pages/partials/components/_scholastic-components.blade.php (tab partial) |
| **Tab Container** | pages/components.blade.php — tab id scholastic-components, permission 	enant.msh-template-scholastic-component.view |
| **DB Table** | msh_template_scholastic_components — 13 columns (6 data + 7 system) |
| **Primary Screen** | Marksheet Generation → Components → Scholastic Components tab (paginated, searchable, status-filtered, modal-based CRUD) |
| **Modal IDs** | #createTemplateScholasticComponentModal, #editTemplateScholasticComponentModal |
| **Paginator Name** | sc_page (15 per page) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as role with 	enant.msh-template-scholastic-component.* permissions |
| PC-02 | Database msh_template_scholastic_components table must exist with all 13 columns |
| PC-03 | msh_config_templates table must have at least one active template record |
| PC-04 | msh_source_components table must have at least one active source component record |
| PC-05 | TemplateScholasticComponentController must be registered in web routes with full resource + extra routes |
| PC-06 | TemplateScholasticComponentPolicy must be registered in AuthServiceProvider |
| PC-07 | Scholastic Components tab must be included in components.blade.php with @can('tenant.msh-template-scholastic-component.view') guard |
| PC-08 | Soft deletes must be enabled on msh_template_scholastic_components (deleted_at column) |
| PC-09 | TemplateScholasticComponentService must be autowireable (constructor-injected) |
| PC-10 | Browser must support JavaScript for modal AJAX submission, status toggle |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load scholastic components with pagination (15 per page) via MarksheetGenerationController::components() → applyFilters() | MarksheetGenerationController.php:103 — TemplateScholasticComponent::with(['configTemplate', 'sourceComponent'])->...->paginate(15, ['*'], 'sc_page') |
| DL-02 | Search filters: ?search= and ?status= (1=Active, 0=Inactive); search applied only when tab is scholastic-components | MarksheetGenerationController.php:103 |
| DL-03 | Empty searchableColumns array [] — no column-based text search applied | MarksheetGenerationController.php:103 — pplyFilters() skips search when array empty |
| DL-04 | List columns displayed: **#**, **Config Template**, **Source Component**, **Weightage %**, **Max Marks**, **Status**, **Action** | _scholastic-components.blade.php:37-49 |
| DL-05 | Template name displayed via $row->configTemplate?->name (eager-loaded) | _scholastic-components.blade.php:55 |
| DL-06 | Source component name displayed via $row->sourceComponent?->name (eager-loaded) | _scholastic-components.blade.php:56 |
| DL-07 | Weightage displayed with % suffix: {{ ->weightage_percent }}% | _scholastic-components.blade.php:57 |
| DL-08 | Status column uses <x-backend.table.status-switch> component with url="marksheet-generation.template-scholastic-component" | _scholastic-components.blade.php:61 |
| DL-09 | Action column uses <x-backend.table.action> — editOnclick JS function populates edit modal | _scholastic-components.blade.php:66 |
| DL-10 | Pagination links use ->appends(request()->query())->links() | _scholastic-components.blade.php:74 |
| DL-11 | Empty state: "No Scholastic Components Found" with icon (bg-light circle + fa-layer-group) | _scholastic-components.blade.php:23-32 |
| DL-12 | Shared dropdowns: ConfigTemplate::where('is_active', 1)->get(), SourceComponent::where('is_active', 1)->get() loaded once in hub controller | MarksheetGenerationController.php:108-109 |
| DL-13 | Create/Edit modals loaded via @include('marksheetgeneration::modals.template-scholastic-component-create') | components.blade.php:33-40 |
| DL-14 | AJAX form handler partial _ajax-form-handler included at bottom of hub page | components.blade.php:42 |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Scholastic Component** | config_template_id=1, source_component_id=1, weightage_percent=50.00, max_marks=100.00, is_active=1 |
| TD-02 | **Duplicate Source Component Per Template** | Create second component with same config_template_id + source_component_id — expects unique violation |
| TD-03 | **Weightage > 100** | weightage_percent=150.00 — expects max:100 validation failure |
| TD-04 | **Weightage with >2 decimal places** | weightage_percent=50.123 — expects regex failure |
| TD-05 | **Invalid Config Template ID** | config_template_id=99999 — expects exists:msh_config_templates failure |
| TD-06 | **Invalid Source Component ID** | source_component_id=99999 — expects exists:msh_source_components failure |
| TD-07 | **Max Marks Null** | max_marks left empty with 
ullable rule — should succeed |
| TD-08 | **Weightage Sum Exceeds 100%** | Create two components under same template: 60% + 50% = 110% — expects service layer transaction rollback |
| TD-09 | **Force Delete with StudentSubjectResult FK** | Component referenced by StudentSubjectResult.scholastic_component_id — expects QueryException 23000 catch |
| TD-10 | **Toggle Status** | Toggle active→inactive and inactive→active — expects JSON response |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK, AUTO_INCREMENT | Unique identifier | DDL: msh_template_scholastic_components |
| BC-DB-02 | config_template_id — BIGINT, NOT NULL, FK → msh_config_templates.id | Required FK reference | DDL |
| BC-DB-03 | source_component_id — BIGINT, NOT NULL, FK → msh_source_components.id | Required FK reference | DDL |
| BC-DB-04 | display_label — VARCHAR(255), NULLABLE | DDL only, NOT in model $fillable | DDL |
| BC-DB-05 | weightage_percent — DECIMAL(5,2), NOT NULL, DEFAULT 0.00 | Contribution % to scholastic total | DDL |
| BC-DB-06 | max_marks — DECIMAL(8,2), NULLABLE | Max marks for display | DDL |
| BC-DB-07 | sort_order — INT, NULLABLE | DDL only, NOT in model $fillable | DDL |
| BC-DB-08 | is_active — TINYINT(1), NOT NULL, DEFAULT 1 | Soft-delete flag | DDL |
| BC-DB-09 | created_by — BIGINT, NULLABLE, FK → users.id | Creator user reference | DDL |
| BC-DB-10 | updated_by — BIGINT, NULLABLE, FK → users.id | Last modifier user reference | DDL |
| BC-DB-11 | created_at — TIMESTAMP, NULLABLE | Auto-managed by Eloquent | DDL |
| BC-DB-12 | updated_at — TIMESTAMP, NULLABLE | Auto-managed by Eloquent | DDL |
| BC-DB-13 | deleted_at — TIMESTAMP, NULLABLE | Soft delete timestamp | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | config_template_id — required, integer, exists:msh_config_templates,id | equired|integer|exists:msh_config_templates,id | TemplateScholasticComponentRequest |
| BC-VAL-02 | source_component_id — required, integer, exists:msh_source_components,id, unique per config_template on create | equired|integer|exists:msh_source_components,id|Rule::unique(...)->where('config_template_id', ...) | TemplateScholasticComponentRequest |
| BC-VAL-03 | weightage_percent — required, numeric, min:0, max:100, regex:/^\d+(\.\d{1,2})?$/ | equired|numeric|min:0|max:100|regex:/^\d+(\.\d{1,2})?$/ | TemplateScholasticComponentRequest |
| BC-VAL-04 | max_marks — nullable, numeric, min:0 | 
ullable|numeric|min:0 | TemplateScholasticComponentRequest |
| BC-VAL-05 | is_active — sometimes, boolean | sometimes|boolean | TemplateScholasticComponentRequest |
| BC-VAL-06 | Unique source component per template: same source_component_id cannot be mapped twice to same config_template_id on create | Rule::unique('msh_template_scholastic_components', 'source_component_id')->where('config_template_id', ->config_template_id) | TemplateScholasticComponentRequest |
| BC-VAL-07 | Error message: "The source component id has already been taken." | Custom validation message | TemplateScholasticComponentRequest |
| BC-VAL-08 | Error message: "Weightage can have at most 2 decimal places." | Custom validation message | TemplateScholasticComponentRequest |
| BC-VAL-09 | prepareForValidation() casts IDs to int, is_active to boolean | $this->merge(['is_active' => ->boolean('is_active')]) | TemplateScholasticComponentRequest |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Policy Method | Source |
|----|-----------|-----------------|---------------|--------|
| BC-AUTH-01 | 	enant.msh-components.view | Hub: Gate::authorize('tenant.msh-components.view') in MarksheetGenerationController::components() (line 97) | N/A (hub-level) | MarksheetGenerationController.php:97 |
| BC-AUTH-02 | 	enant.msh-template-scholastic-component.viewAny | Gate::authorize(...) in index() (line 18) and 	rashed() (line 138) | iewAny() | TemplateScholasticComponentController.php:18,138 |
| BC-AUTH-03 | 	enant.msh-template-scholastic-component.view | @can('...view') in blade (lines 12,17); Gate::authorize(...) in show() (line 67) | iew() | components.blade.php:12,17; TemplateScholasticComponentController.php:67 |
| BC-AUTH-04 | 	enant.msh-template-scholastic-component.create | Gate::authorize(...) in create() (line 29) and store() (line 39) | create() | TemplateScholasticComponentController.php:29,39 |
| BC-AUTH-05 | 	enant.msh-template-scholastic-component.update | Gate::authorize(...) in edit() (line 76), update() (line 86), 	oggleStatus() (line 126), estore() (line 147) | update() | TemplateScholasticComponentController.php:76,86,126,147 |
| BC-AUTH-06 | 	enant.msh-template-scholastic-component.delete | Gate::authorize(...) in destroy() (line 111) and orceDelete() (line 160) | delete() | TemplateScholasticComponentController.php:111,160 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Tab listing uses hub controller components(), not entity index() | MarksheetGenerationController::components() at line 95 executes tab query | MarksheetGenerationController.php:95-117 |
| BC-BIZ-02 | create() loads active config templates + source components | ConfigTemplate::where('is_active', 1)->get(), SourceComponent::where('is_active', 1)->get() | TemplateScholasticComponentController.php:31-32 |
| BC-BIZ-03 | store() sets created_by to auth user before create | $validatedData['created_by'] = auth()->id() | TemplateScholasticComponentController.php:42 |
| BC-BIZ-04 | store() returns JSON response for modal AJAX when $request->expectsJson() | JSON {status: true, message, redirect} | TemplateScholasticComponentController.php:54-60 |
| BC-BIZ-05 | store() redirects to show page for non-AJAX | ->route('marksheet-generation.template-scholastic-component.show', ) | TemplateScholasticComponentController.php:50-52 |
| BC-BIZ-06 | edit() redirects to components hub tab (no dedicated edit view) | edirect()->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components']) | TemplateScholasticComponentController.php:81 |
| BC-BIZ-07 | update() delegates to TemplateScholasticComponentService::update() with auth id | $service->update(, , (int) auth()->id()) | TemplateScholasticComponentController.php:88 |
| BC-BIZ-08 | update() returns JSON response for modal AJAX | JSON {status: true, message, redirect} | TemplateScholasticComponentController.php:98-104 |
| BC-BIZ-09 | update() redirects to components hub tab with tab parameter | ->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components']) | TemplateScholasticComponentController.php:94-96 |
| BC-BIZ-10 | destroy() delegates to TemplateScholasticComponentService::delete() (soft delete) | $service->delete() | TemplateScholasticComponentController.php:113 |
| BC-BIZ-11 | destroy() redirects to components hub tab | ->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components']) | TemplateScholasticComponentController.php:119-121 |
| BC-BIZ-12 | 	oggleStatus() inverts is_active and sets updated_by | $record->update(['is_active' => ! ->is_active, 'updated_by' => auth()->id()]) | TemplateScholasticComponentController.php:129 |
| BC-BIZ-13 | 	oggleStatus() returns JSON with success status and message | {success: true, is_active: bool, message: string} | TemplateScholasticComponentController.php:133 |
| BC-BIZ-14 | 	rashed() paginates onlyTrashed() at 15 per page | TemplateScholasticComponent::onlyTrashed()->latest()->paginate(15) | TemplateScholasticComponentController.php:140 |
| BC-BIZ-15 | estore() uses onlyTrashed() and sets is_active=true after restore | $record->restore(); ->update(['is_active' => true]) | TemplateScholasticComponentController.php:149-151 |
| BC-BIZ-16 | orceDelete() uses withTrashed() and catches QueryException 23000 | try/catch block; FK violation returns user-friendly error | TemplateScholasticComponentController.php:162-171 |
| BC-BIZ-17 | orceDelete() error message for FK 23000 | "Cannot delete this record because it is referenced by other records." | TemplateScholasticComponentController.php:168 |
| BC-BIZ-18 | activityLog called with message in every CRUD method | ctivityLog(, 'Stored', ['message' => '...']) | All controller methods |
| BC-BIZ-19 | Service layer wraps create/update/delete in DB transactions | TemplateScholasticComponentService uses DB::transaction() | Service class |
| BC-BIZ-20 | Weightage sum validated via MarksheetConfigService::validateScholasticWeightageSum() after create/update | Service calls $this->config->validateScholasticWeightageSum() | Service class |
| BC-BIZ-21 | Unique violation error message for duplicate source component per template | "The source component id has already been taken." | Requirement doc |
| BC-BIZ-22 | Create/Edit modals use AJAX JSON error responses (not $errors->any()) | JSON with validation errors returned on failure | Modal JS handler |


### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | TemplateScholasticComponent → ConfigTemplate | elongsTo(configTemplate) | TemplateScholasticComponent.php:33-36 |
| BC-REL-02 | TemplateScholasticComponent → SourceComponent | elongsTo(sourceComponent) | TemplateScholasticComponent.php:38-41 |
| BC-REL-03 | TemplateScholasticComponent → User (created_by) | elongsTo(createdBy) | TemplateScholasticComponent.php:43-46 |
| BC-REL-04 | TemplateScholasticComponent → User (updated_by) | elongsTo(updatedBy) | TemplateScholasticComponent.php:48-51 |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab visibility guarded by @can('tenant.msh-template-scholastic-component.view') | Tab conditional in nav-tab and @include | components.blade.php:12,17 |
| BC-REF-02 | Search bar uses createModal="#createTemplateScholasticComponentModal" | Add button opens modal | _scholastic-components.blade.php:5 |
| BC-REF-03 | Action column shown only for @canany(['...view', '...update', '...delete']) | Conditional rendering | _scholastic-components.blade.php:46,64 |
| BC-REF-04 | Status column shown only for @can('...update') | Conditional rendering | _scholastic-components.blade.php:43,59 |
| BC-REF-05 | Edit modal triggered by editTemplateScholasticComponent() JS with 6 params | editTemplateScholasticComponent(id, config_template_id, source_component_id, weightage_percent, max_marks, is_active) | _scholastic-components.blade.php:66 |
| BC-REF-06 | No standalone create/edit/show blade pages — all modal-based | Modal CRUD pattern | components.blade.php:33-40 |
| BC-REF-07 | Flash keys: created.template_scholastic_component, updated.template_scholastic_component, deleted.template_scholastic_component | Must exist in lang file | TemplateScholasticComponentController.php:52,96,121 |
| BC-REF-08 | Position # column uses $loop->iteration | Row number | _scholastic-components.blade.php:54 |
| BC-REF-09 | Pagination renders inside tab-pane, not full page | Tab scope | _scholastic-components.blade.php:74 |
| BC-REF-10 | Status switch component renders toggle with JS POST to 	oggleStatus route | AJAX POST | _scholastic-components.blade.php:61 |
| BC-REF-11 | Empty state uses custom div layout (not table colspan) | Custom empty state | _scholastic-components.blade.php:23-32 |
| BC-REF-12 | $scholasticComponents variable passed to view from hub controller | Always available | MarksheetGenerationController.php:103,113 |
| BC-REF-13 | configTemplate?->name uses null-safe operator | Handles null FK gracefully | _scholastic-components.blade.php:55 |
| BC-REF-14 | sourceComponent?->name ?? ->source_component_id fallback to raw ID | Graceful fallback | _scholastic-components.blade.php:56 |
| BC-REF-15 | :canView="false" on action component — view action disabled | View not shown for list | _scholastic-components.blade.php:66 |
| BC-REF-16 | display_label and sort_order in DDL but NOT in model $fillable | DDL-only columns (not used) | DDL vs Model |
| BC-REF-17 | edit() loads active dropdowns but redirects (data unused) | Unused dropdown loads — dead code | TemplateScholasticComponentController.php:78-79 |
| BC-REF-18 | show() loads relations explicitly via ->load() | $templateScholasticComponent->load(['configTemplate', 'sourceComponent']) | TemplateScholasticComponentController.php:69 |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 15 per page in hub listing | ->paginate(15, ['*'], 'sc_page') — 15 records per page with unique paginator name sc_page |
| BC-BIZ-DEEP-02 | withQueryString() preserves tab/search/status filter params across pagination | Pagination links include ?tab=scholastic-components, ?search=, ?status= params |
| BC-BIZ-DEEP-03 | Tab-aware filtering: search/status only applied when $tab === 'scholastic-components' | $this->applyFilters(...,  === 'scholastic-components' ?  : null, ...) |
| BC-BIZ-DEEP-04 | Empty searchableColumns array ([]) means no text search applied | pplyFilters() checks !empty() — empty array skips search clause |
| BC-BIZ-DEEP-05 | pplyFilters() applies status filter via $query->where('is_active', (int) ) | Exact match on is_active column (1 or 0) |
| BC-BIZ-DEEP-06 | pplyFilters() returns $query->latest() for ordering | Order by created_at DESC |
| BC-BIZ-DEEP-07 | store() sets created_by from auth user | $validatedData['created_by'] = auth()->id() |
| BC-BIZ-DEEP-08 | store() dual response: redirect for normal, JSON for AJAX | $request->expectsJson() check |
| BC-BIZ-DEEP-09 | edit() redirects to hub instead of rendering edit view | No standalone edit page — modal-based pattern |
| BC-BIZ-DEEP-10 | update() delegates to service, which manages transaction | $service->update(, , auth()->id()) |
| BC-BIZ-DEEP-11 | update() activityLog called AFTER service update | Log: "The template scholastic component was updated." |
| BC-BIZ-DEEP-12 | destroy() delegates to service delete() | $service->delete() — soft delete in transaction |
| BC-BIZ-DEEP-13 | destroy() activityLog logs "Deleted" | ctivityLog(, 'Deleted', ['message' => '...']) |
| BC-BIZ-DEEP-14 | toggleStatus() uses ! ->is_active to invert | Simple boolean inversion pattern |
| BC-BIZ-DEEP-15 | toggleStatus() does NOT validate weightage sum | Status toggle bypasses weightage governance |
| BC-BIZ-DEEP-16 | restore() sets is_active=true after restore | $record->restore(); ->update(['is_active' => true]) |
| BC-BIZ-DEEP-17 | restore() activityLog lacks performed_by key | Only passes message key — inconsistent with other activityLog calls |
| BC-BIZ-DEEP-18 | forceDelete() catch QueryException 23000 for FK violations | if (->getCode() === '23000') block |
| BC-BIZ-DEEP-19 | forceDelete() return edirect()->back() with error on FK violation | "Cannot delete this record because it is referenced by other records." |
| BC-BIZ-DEEP-20 | forceDelete() activityLog written BEFORE delete, not after | ctivityLog(...) placed before orceDelete() in code |
| BC-BIZ-DEEP-21 | trashed() gate uses iewAny, not estore or delete | Gate::authorize('tenant.msh-template-scholastic-component.viewAny') |
| BC-BIZ-DEEP-22 | trashed() paginates at 15 per page with default page name | onlyTrashed()->latest()->paginate(15) — no custom page name |
| BC-BIZ-DEEP-23 | No route-model-binding on estore(), orceDelete(), 	oggleStatus() | Manual indOrFail() or withTrashed()->findOrFail() |
| BC-BIZ-DEEP-24 | Route-model-binding used on show(), edit(), update(), destroy() | TemplateScholasticComponent  parameter |
| BC-BIZ-DEEP-25 | store() has NO updated_by set (only created_by) | updated_by remains null on create |
| BC-BIZ-DEEP-26 | update() sets updated_by via service layer | Service receives (int) auth()->id() |
| BC-BIZ-DEEP-27 | show() loads relations via ->load() not ->with() | Explicit lazy eager load |
| BC-BIZ-DEEP-28 | Hook controller dispatches $scholasticComponents, $examWeightages, $iaComponents, $coscholasticComponents | 4 paginated collections + 4 dropdown lists for modals | 
| BC-BIZ-DEEP-29 | Weightage sum validation via service is the ONLY business logic governance | alidateScholasticWeightageSum() called inside DB transaction |
| BC-BIZ-DEEP-30 | display_label and sort_order are DDL orphans | Columns defined in DB but not fillable, no code sets them |
| BC-BIZ-DEEP-31 | weightage_percent cast as decimal:2 in model | $casts = ['weightage_percent' => 'decimal:2'] |
| BC-BIZ-DEEP-32 | max_marks cast as decimal:2 in model | $casts = ['max_marks' => 'decimal:2'] |
| BC-BIZ-DEEP-33 | is_active cast as ool in model | $casts = ['is_active' => 'bool'] |
| BC-BIZ-DEEP-34 | Model uses BaseModel not Model | Extends App\Models\BaseModel |
| BC-BIZ-DEEP-35 | orceDelete() activityLog "Deleted" message | "The record was permanently deleted." |
| BC-BIZ-DEEP-36 | estore() success message hardcoded string (not flash()) | ->with('success', 'Record restored successfully.') — inconsistency with other flash keys |
| BC-BIZ-DEEP-37 | orceDelete() success message hardcoded string | ->with('success', 'Record permanently deleted.') — not using flash() |
| BC-BIZ-DEEP-38 | 	rashed() return view marksheetgeneration::trashed.template-scholastic-component | Dedicated trash view |
| BC-BIZ-DEEP-39 | index() paginates at 20 per page (standalone, NOT used in hub) | ->paginate(20) — standalone route uses 20, hub uses 15 |
| BC-BIZ-DEEP-40 | index() eager loads both configTemplate and sourceComponent | TemplateScholasticComponent::with(['configTemplate', 'sourceComponent']) |
| BC-BIZ-DEEP-41 | create() loads active config templates + source components | Both filtered by where('is_active', 1) |
| BC-BIZ-DEEP-42 | edit() loads same dropdowns but does NOT pass to view (redirects) | Dead code — dropdowns loaded but never used |
| BC-BIZ-DEEP-43 | Tab @can uses .view (not .viewAny) for blade visibility | @can('tenant.msh-template-scholastic-component.view') |
| BC-BIZ-DEEP-44 | @canany in action column uses .view, .update, .delete | Three separate permission checks |
| BC-BIZ-DEEP-45 | Data displayed in latest() order (by created_at DESC) | No sort_order or display_order usage |
| BC-BIZ-DEEP-46 | max_marks can be null — displayed as empty cell when null | {{ ->max_marks }} — null shows blank |
| BC-BIZ-DEEP-47 | weightage_percent displayed with % character | {{ ->weightage_percent }}% |
| BC-BIZ-DEEP-48 | No @canany around add button — uses createModal attribute on search-bar component | Component handles visibility via permissions attribute |
| BC-BIZ-DEEP-49 | Route marksheet-generation.template-scholastic-component.toggleStatus is POST/PATCH match | Route::match(['post', 'patch'], ...) |
| BC-BIZ-DEEP-50 | Route 	rashed view: 	emplate-scholastic-component/trash/view | Defined in $modalEntities loop |

### CODE-TRACE: Line-by-Line Method Trace

> **Note**: This traces the **standalone route** /template-scholastic-component → TemplateScholasticComponentController::index(). The **primary tab listing** at /components?tab=scholastic-components goes through MarksheetGenerationController::components() → pplyFilters().

#### CODE-TRACE-01: MarksheetGenerationController::components(Request ) — Lines 95-117 (Hub Controller — Primary Tab Listing)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 97 | Gate::authorize('tenant.msh-components.view') | Hub-level authorization gate |
| 02 | 99-101 | $search = ->input('search');  = ->input('status');  = ->input('tab', 'scholastic-components') | Extract filter params + active tab, default to scholastic |
| 03 | 103 | $scholasticComponents = ->applyFilters(TemplateScholasticComponent::with(['configTemplate', 'sourceComponent']),  === 'scholastic-components' ?  : null,  === 'scholastic-components' ?  : null, [])->paginate(15, ['*'], 'sc_page') | Scholastic tab query: eager-load, tab-aware filter, 15 per page, unique paginator |
| 04 | 104 | $examWeightages = ->applyFilters(TemplateExamWeightage::with('configTemplate'),  === 'exam-weightages' ?  : null, ...)->paginate(15, ['*'], 'ew_page') | Exam weightages tab query |
| 05 | 105 | $iaComponents = ->applyFilters(TemplateIaComponent::with('configTemplate'),  === 'ia-components' ?  : null, ...)->paginate(15, ['*'], 'ia_page') | IA components tab query |
| 06 | 106 | $coscholasticComponents = ->applyFilters(TemplateCoscholasticComponent::with('configTemplate'),  === 'coscholastic-components' ?  : null, ..., ['name', 'code'])->paginate(15, ['*'], 'cc_page') | Coscholastic tab query with searchable columns name+code |
| 07 | 108-111 | $configTemplates = ConfigTemplate::where('is_active', 1)->get();  = SourceComponent::where('is_active', 1)->get();  = ExamType::where('is_active', 1)->get();  = IaComponentType::where('is_active', 1)->get() | Shared dropdowns for all tab modals |
| 08 | 113-116 | eturn view('marksheetgeneration::pages.components', compact(...)) | Return hub view with all 4 paginated collections + 4 dropdown lists |

#### CODE-TRACE-A: pplyFilters(, ?string , ?string , array ) — Lines 304-319 (Private Helper)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 306-311 | if ( && !empty()) { ->where(function() use (, ) { foreach (...) { ->orWhere(, 'like', ...); } }); } | Search filter: only applies if  is non-null AND  is non-empty |
| 02 | 314-316 | if ( !== null &&  !== '') { ->where('is_active', (int) ); } | Status filter: exact match, cast to int |
| 03 | 318 | eturn ->latest() | Always order by created_at DESC |

#### CODE-TRACE-02: TemplateScholasticComponentController::index() — Lines 16-25 (Standalone Route — NOT used in hub)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 18 | Gate::authorize('tenant.msh-template-scholastic-component.viewAny') | Authorization gate |
| 02 | 20-21 | $components = TemplateScholasticComponent::with(['configTemplate', 'sourceComponent'])->latest() | Eager-load + order |
| 03 | 22 | ->paginate(20) | Paginate 20 per page (different from hub's 15) |
| 04 | 24 | eturn view('marksheetgeneration::template-scholastic-component.index', compact('components')) | Return standalone index view |

#### CODE-TRACE-03: show(TemplateScholasticComponent ) — Lines 65-72

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 67 | Gate::authorize('tenant.msh-template-scholastic-component.view') | Authorization gate |
| 02 | 69 | $templateScholasticComponent->load(['configTemplate', 'sourceComponent']) | Eager-load relations |
| 03 | 71 | eturn view('marksheetgeneration::template-scholastic-component.show', compact('templateScholasticComponent')) | Return show view |

#### CODE-TRACE-04: create() — Lines 27-35

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 29 | Gate::authorize('tenant.msh-template-scholastic-component.create') | Authorization gate |
| 02 | 31-32 | $configTemplates = ConfigTemplate::where('is_active', 1)->get();  = SourceComponent::where('is_active', 1)->get() | Load active dropdown data |
| 03 | 34 | eturn view('marksheetgeneration::template-scholastic-component.create', compact('configTemplates', 'sourceComponents')) | Return standalone create view (NOT used via hub modal) |

#### CODE-TRACE-05: store(TemplateScholasticComponentRequest ) — Lines 37-63

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 39 | Gate::authorize('tenant.msh-template-scholastic-component.create') | Authorization gate |
| 02 | 41 | $validatedData = ->validated() | Validate request |
| 03 | 42 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 44 | $component = TemplateScholasticComponent::create() | Create record (NOT via service — direct Eloquent) |
| 05 | 46-48 | ctivityLog(, 'Stored', ['message' => 'A new template scholastic component was created.']) | Activity log entry |
| 06 | 50-52 | $redirect = redirect()->route('marksheet-generation.template-scholastic-component.show', )->with('success', flash('created.template_scholastic_component')) | Build redirect response |
| 07 | 54-60 | if (->expectsJson()) { return response()->json([...]); } | JSON response for modal AJAX |
| 08 | 62 | eturn  | Normal redirect for non-AJAX |

#### CODE-TRACE-06: edit(TemplateScholasticComponent ) — Lines 74-82

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 76 | Gate::authorize('tenant.msh-template-scholastic-component.update') | Authorization gate |
| 02 | 78-79 | $configTemplates = ConfigTemplate::where('is_active', true)->get();  = SourceComponent::where('is_active', true)->get() | Load dropdowns (UNUSED — dead code) |
| 03 | 81 | eturn redirect()->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components']) | Redirect to hub tab (no dedicated edit view) |

#### CODE-TRACE-07: update(TemplateScholasticComponentRequest , TemplateScholasticComponent , TemplateScholasticComponentService ) — Lines 84-107

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 86 | Gate::authorize('tenant.msh-template-scholastic-component.update') | Authorization gate |
| 02 | 88 | $service->update(, ->validated(), (int) auth()->id()) | Service delegates update (transaction + weightage validation) |
| 03 | 90-92 | ctivityLog(, 'Updated', ['message' => 'The template scholastic component was updated.']) | Activity log entry |
| 04 | 94-96 | $redirect = redirect()->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components'])->with('success', flash('updated.template_scholastic_component')) | Redirect to hub tab |
| 05 | 98-104 | if (->expectsJson()) { return response()->json([...]); } | JSON response for modal AJAX |
| 06 | 106 | eturn  | Normal redirect |

#### CODE-TRACE-08: destroy(TemplateScholasticComponent , TemplateScholasticComponentService ) — Lines 109-122

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 111 | Gate::authorize('tenant.msh-template-scholastic-component.delete') | Authorization gate |
| 02 | 113 | $service->delete() | Service soft-delete in transaction |
| 03 | 115-117 | ctivityLog(, 'Deleted', ['message' => 'The template scholastic component was deleted.']) | Activity log entry |
| 04 | 119-121 | eturn redirect()->route('marksheet-generation.components.combined', ['tab' => 'scholastic-components'])->with('success', flash('deleted.template_scholastic_component')) | Redirect to hub tab |

#### CODE-TRACE-09: 	oggleStatus() — Lines 124-134

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 126 | Gate::authorize('tenant.msh-template-scholastic-component.update') | Authorization gate |
| 02 | 128 | $record = TemplateScholasticComponent::findOrFail() | Find record or 404 |
| 03 | 129 | $record->update(['is_active' => ! ->is_active, 'updated_by' => auth()->id()]) | Toggle is_active + set updated_by |
| 04 | 131 | ctivityLog(, 'Toggled', ['message' => 'Status was toggled.']) | Activity log entry |
| 05 | 133 | eturn response()->json(['success' => true, 'is_active' => ->is_active, 'message' => ->is_active ? 'Status set to Active' : 'Status set to Inactive']) | JSON response with status message |

#### CODE-TRACE-10: 	rashed() — Lines 136-143

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 138 | Gate::authorize('tenant.msh-template-scholastic-component.viewAny') | Authorization gate |
| 02 | 140 | $trashed = TemplateScholasticComponent::onlyTrashed()->latest()->paginate(15) | Only soft-deleted, paginated 15 |
| 03 | 142 | eturn view('marksheetgeneration::trashed.template-scholastic-component', compact('trashed')) | Return trash view |

#### CODE-TRACE-11: estore() — Lines 145-156

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 147 | Gate::authorize('tenant.msh-template-scholastic-component.update') | Authorization gate (uses update not estore) |
| 02 | 149 | $record = TemplateScholasticComponent::onlyTrashed()->findOrFail() | Find trashed record or 404 |
| 03 | 150 | $record->restore() | Restore (sets deleted_at = NULL) |
| 04 | 151 | $record->update(['is_active' => true]) | Set active after restore |
| 05 | 153 | ctivityLog(, 'Restored', ['message' => 'The record was restored.']) | Activity log entry |
| 06 | 155 | eturn redirect()->route('marksheet-generation.template-scholastic-component.trashed')->with('success', 'Record restored successfully.') | Redirect to trash page with hardcoded message |

#### CODE-TRACE-12: orceDelete() — Lines 158-174

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 160 | Gate::authorize('tenant.msh-template-scholastic-component.delete') | Authorization gate |
| 02 | 162 | $record = TemplateScholasticComponent::withTrashed()->findOrFail() | Find ANY record (active or trashed) or 404 |
| 03 | 163-165 | 	ry { ->forceDelete(); activityLog(...); } | Attempt permanent delete + log |
| 04 | 166-170 | catch (QueryException ) { if (->getCode() === '23000') { return redirect()->back()->with('error', 'Cannot delete...'); } throw ; } | FK violation catch with user-friendly error |
| 05 | 173 | eturn redirect()->route('marksheet-generation.template-scholastic-component.trashed')->with('success', 'Record permanently deleted.') | Success redirect to trash page |


---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create scholastic component via modal with all fields | Fill all fields via AJAX modal | Component created, activityLog "Stored", JSON success |
| TC-P-02 | Create scholastic component with max marks null | Leave max_marks empty (nullable) | Component created with max_marks=null |
| TC-P-03 | Create scholastic component with min weightage | weightage_percent=0.00 | Component created successfully |
| TC-P-04 | Edit scholastic component weightage via modal | Change weightage from 50% to 30% | Updated via service, weightage sum validated, activityLog "Updated" |
| TC-P-05 | Toggle status active→inactive | Click status switch | AJAX response {success:true, is_active:false} |
| TC-P-06 | Toggle status inactive→active (bidirectional) | Click status switch on inactive component | AJAX response {success:true, is_active:true} |
| TC-P-07 | Filter by active status via dropdown | Select "Active" filter | Only active components displayed |
| TC-P-08 | Restore soft-deleted component | Trash → Restore | Component restored, is_active=true, flash success |
| TC-P-09 | Force delete component with no FK references | Trash → Force Delete | Component permanently removed, flash success |
| TC-P-10 | Force delete with FK violation caught | Component has StudentSubjectResult references | Error message "Cannot delete this record..." displayed |
| TC-P-11 | Pagination — page 2 | Navigate to page 2 | 15 records per page, page param preserved |
| TC-P-12 | Create scholastic component with weightage 100% | weightage_percent=100.00 | Component created (max boundary) |
| TC-P-13 | Trashed page loads with only soft-deleted records | Navigate to trash | Only deleted_at IS NOT NULL records shown |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create with empty config_template_id | Submit without config_template | "The config template id field is required." |
| TC-N-02 | Create with empty source_component_id | Submit without source component | "The source component id field is required." |
| TC-N-03 | Create with duplicate source component per template | Same config_template + source_component pair | "The source component id has already been taken." |
| TC-N-04 | Create with weightage_percent > 100 | weightage_percent=150.00 | "The weightage percent must be between 0 and 100." |
| TC-N-05 | Create with weightage_percent negative | weightage_percent=-10.00 | "The weightage percent must be between 0 and 100." |
| TC-N-06 | Create with weightage >2 decimal places | weightage_percent=50.123 | "The weightage percent format is invalid." (regex failure) |
| TC-N-07 | Create with invalid config_template_id (99999) | Non-existent template | "Selected config template is invalid." |
| TC-N-08 | Create with invalid source_component_id (99999) | Non-existent source | "Selected source component is invalid." |
| TC-N-09 | Create with max_marks negative | max_marks=-50.00 | "Max marks must be a positive number." |
| TC-N-10 | Weightage sum exceeds 100% via multiple components | Already 60% + trying to add 50% = 110% | Service transaction rollback, save fails |
| TC-N-11 | Access index without permission | User lacks .viewAny | 403 Access Denied |
| TC-N-12 | Access create without .create permission | User lacks create | 403 Access Denied |
| TC-N-13 | Access store/POST without .create permission | User lacks create | 403 Access Denied |
| TC-N-14 | Access edit without .update permission | User lacks update | 403 Access Denied |
| TC-N-15 | Access destroy without .delete permission | User lacks delete | 403 Access Denied |
| TC-N-16 | Access toggleStatus without .update permission | User lacks update | 403 Access Denied |
| TC-N-17 | Access trashed page without .viewAny permission | User lacks viewAny | 403 Access Denied |
| TC-N-18 | Access restore without .update permission | User lacks update | 403 Access Denied |
| TC-N-19 | Access forceDelete without .delete permission | User lacks delete | 403 Access Denied |
| TC-N-20 | Show non-existent ID | /template-scholastic-component/99999 | 404 — route-model-binding findOrFail |
| TC-N-21 | Restore non-trashed (active) record | Call restore on non-deleted component | 404 — onlyTrashed()->findOrFail() returns no record |
| TC-N-22 | Force delete with FK 23000 violation | Component has student subject results | "Cannot delete this record..." error, no deletion |
| TC-N-23 | Submit is_active with non-boolean value | is_active=2 | Validation error: "The is active field must be true or false." |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | Mass assignment: inject non-fillable fields | Send display_label and sort_order in request | Not mass-assigned (not in ) |
| TC-SQ-02 | Mass assignment: inject created_by directly | Send created_by in request | Not mass-assigned (may be overwritten by controller) |
| TC-SQ-03 | Tab hidden without .view permission | User lacks .view | Tab nav item NOT rendered |
| TC-SQ-04 | Modal add button hidden without .create | User lacks .create | Add button not visible |
| TC-SQ-05 | Action column hidden without any relevant permission | User lacks view/update/delete | Action column not rendered |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Weightage sum governance — create multiple components under same template | Add 50% + 30% = 80% (ok), then add 30% = 110% (fail) | Transaction rollback on third, error returned |
| TC-INT-02 | Cascade from ConfigTemplate deletion | Delete ConfigTemplate that has components | FK cascade behavior (CASCADE or RESTRICT per migration) |
| TC-INT-03 | StudentSubjectResult FK blocks force delete | Attempt forceDelete when StudentSubjectResult references component | QueryException 23000 caught, error message displayed |

## 7. Detailed Test Execution Procedures

### TC-P-01: Create scholastic component via modal with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with 	enant.msh-template-scholastic-component.create permission | Success |
| 2 | Navigate to Marksheet Generation → Components → Scholastic Components tab | Tab loads with $scholasticComponents collection |
| 3 | Click "Add" button in search bar | #createTemplateScholasticComponentModal modal opens |
| 4 | Select Config Template from dropdown | Config template selected |
| 5 | Select Source Component from dropdown | Source component selected |
| 6 | Enter weightage_percent = "50.00" | Input accepts 50.00 |
| 7 | Enter max_marks = "100.00" | Input accepts 100.00 |
| 8 | Ensure is_active toggle is ON | Active (default) |
| 9 | Click Submit/Save | AJAX POST to /template-scholastic-component |
| 10 | **Verify**: Gate::authorize('tenant.msh-template-scholastic-component.create') at controller line 39 passes | Authorization ok |
| 11 | **Verify**: TemplateScholasticComponentRequest rules pass (all 6 fields validated) | No validation errors |
| 12 | **Verify**: $validatedData['created_by'] = auth()->id() | created_by set |
| 13 | **Verify**: TemplateScholasticComponent::create() inserts row in msh_template_scholastic_components | DB has new record |
| 14 | **Verify**: ctivityLog(, 'Stored', [...]) called | Activity log: "A new template scholastic component was created." |
| 15 | **Verify**: JSON response {status: true, message: 'Template scholastic component created.', redirect: '...'} | Modal closes, success flash |
| 16 | **Verify**: Table refreshes — new component visible in list | Row appears with template name, source component name, weightage 50%, max marks 100 |

### TC-P-02: Create scholastic component with max marks null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Fill config_template_id, source_component_id, weightage_percent=30.00 | All required fields |
| 4 | Leave max_marks EMPTY | Nullable field omitted |
| 5 | Submit | POST request |
| 6 | **Verify**: 
ullable rule on max_marks passes | No error |
| 7 | **Verify**: Component created with max_marks=null | DB row has max_marks NULL |
| 8 | **Verify**: activityLog "Stored" recorded | Log entry created |

### TC-P-03: Create scholastic component with min weightage (0%)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal, fill all required fields | Form complete |
| 3 | Set weightage_percent = "0.00" | Min boundary |
| 4 | Submit | POST request |
| 5 | **Verify**: min:0 validation passes | No error |
| 6 | **Verify**: Component created with weightage_percent=0.00 | DB stores 0.00 |

### TC-P-04: Edit scholastic component weightage via modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with 	enant.msh-template-scholastic-component.update permission | Success |
| 2 | Navigate to Components → Scholastic Components tab | List displayed |
| 3 | Click edit icon on existing component row | JS fires editTemplateScholasticComponent(id, config_template_id, source_component_id, weightage_percent, max_marks, is_active) |
| 4 | **Verify**: Edit modal opens with pre-filled values | Modal shows current data |
| 5 | Change weightage_percent from 50 to 30 | Updated input |
| 6 | Click Submit | PATCH via AJAX |
| 7 | **Verify**: Gate::authorize('...update') at line 86 passes | Authorized |
| 8 | **Verify**: $service->update() called with validated data + auth id | Service executes in transaction |
| 9 | **Verify**: MarksheetConfigService::validateScholasticWeightageSum() called | Weightage sum validated |
| 10 | **Verify**: ctivityLog(, 'Updated', [...]) | "The template scholastic component was updated." |
| 11 | **Verify**: JSON response with redirect to components tab | Redirect to ?tab=scholastic-components |
| 12 | **Verify**: Flash lash('updated.template_scholastic_component') | Success message displayed |

### TC-P-05: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Locate an active component's status toggle switch | Toggle is ON |
| 3 | Click the status toggle | AJAX POST to toggleStatus |
| 4 | **Verify**: Gate::authorize('...update') at line 126 passes | Authorized |
| 5 | **Verify**: $record = TemplateScholasticComponent::findOrFail() | Record found |
| 6 | **Verify**: $record->update(['is_active' => ! ->is_active, 'updated_by' => auth()->id()]) | is_active inverted, updated_by set |
| 7 | **Verify**: ctivityLog(, 'Toggled', [...]) | "Status was toggled." |
| 8 | **Verify**: JSON response {success: true, is_active: false, message: 'Status set to Inactive'} | Toggle now OFF |

### TC-P-06: Toggle status inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Locate an inactive component (is_active=0) | Toggle is OFF |
| 3 | Click the status toggle | AJAX POST |
| 4 | **Verify**: ! ->is_active = true (was false, now true) | is_active inverted to 1 |
| 5 | **Verify**: JSON {success: true, is_active: true, message: 'Status set to Active'} | Toggle now ON |

### TC-P-07: Filter by active status via dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .view permission | Success |
| 2 | Select "Active" from status filter dropdown | status=1 |
| 3 | Submit filter | GET with ?tab=scholastic-components&status=1 |
| 4 | **Verify**: $tab === 'scholastic-components' check passes | Filters applied to scholastic query only |
| 5 | **Verify**: $query->where('is_active', (int) 1) | Only active components |
| 6 | Select "Inactive" | ?status=0 — only inactive displayed |

### TC-P-08: Restore soft-deleted component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to trash page | onlyTrashed() records |
| 3 | Click "Restore" on a trashed component | GET to restore route |
| 4 | **Verify**: Gate::authorize('...update') at line 147 passes | Authorized |
| 5 | **Verify**: TemplateScholasticComponent::onlyTrashed()->findOrFail() | Record found in trash |
| 6 | **Verify**: $record->restore() | deleted_at = NULL |
| 7 | **Verify**: $record->update(['is_active' => true]) | Component reactivated |
| 8 | **Verify**: ctivityLog(, 'Restored', [...]) | "The record was restored." |
| 9 | **Verify**: Redirect to trash with success message | "Record restored successfully." |
| 10 | Navigate to Scholastic Components tab | Component visible (active) |

### TC-P-09: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .delete permission | Success |
| 2 | Navigate to trash page | Trashed records |
| 3 | Click "Force Delete" on component with no StudentSubjectResult | DELETE request |
| 4 | **Verify**: Gate::authorize('...delete') at line 160 passes | Authorized |
| 5 | **Verify**: TemplateScholasticComponent::withTrashed()->findOrFail() | Record found |
| 6 | **Verify**: $record->forceDelete() succeeds (no FK violation) | Record permanently removed |
| 7 | **Verify**: ctivityLog(, 'Deleted', [...]) | "The record was permanently deleted." |
| 8 | **Verify**: Redirect with success message | "Record permanently deleted." |

### TC-P-10: Force delete with FK violation (QueryException 23000)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentSubjectResult referencing it | FK exists |
| 2 | Soft-delete component first | destroy() called |
| 3 | Navigate to trash page | Component visible in trash |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: $record->forceDelete() throws QueryException with code '23000' | FK constraint violation |
| 6 | **Verify**: Catch block at line 166-169 executes | if (->getCode() === '23000') |
| 7 | **Verify**: Error message displayed: "Cannot delete this record because it is referenced by other records. Remove those references first." | User-friendly error |
| 8 | **Verify**: Record NOT deleted from DB | Still exists in msh_template_scholastic_components |

### TC-P-11: Pagination — page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 16+ components exist | At least 2 pages |
| 2 | Navigate to Scholastic Components tab | Page 1 with 15 records |
| 3 | Click page 2 pagination link | GET with ?tab=scholastic-components&sc_page=2 |
| 4 | **Verify**: ->paginate(15, ['*'], 'sc_page') returns page 2 | Records 16-30 displayed |
| 5 | **Verify**: withQueryString() preserves tab param | URL has 	ab=scholastic-components |

### TC-P-12: Create with weightage 100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal, fill required fields | Form complete |
| 3 | Set weightage_percent = "100.00" | Max boundary (100) |
| 4 | Submit | POST request |
| 5 | **Verify**: max:100 validation passes | No error |
| 6 | **Verify**: Component created with weightage_percent=100.00 | DB stores 100.00 |

### TC-N-01: Create with empty config_template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Leave config_template_id EMPTY, fill other fields | config_template_id omitted |
| 4 | Submit | POST request |
| 5 | **Verify**: equired rule on config_template_id | "The config template id field is required." |
| 6 | **Verify**: No component created | DB unchanged |

### TC-N-02: Create with empty source_component_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Leave source_component_id EMPTY | Required field omitted |
| 4 | Submit | POST request |
| 5 | **Verify**: equired rule on source_component_id | "The source component id field is required." |
| 6 | **Verify**: No component created | DB unchanged |

### TC-N-03: Create with duplicate source component per template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component exists with (config_template_id=1, source_component_id=1) | Existing record |
| 2 | Create new component with same config_template_id=1, source_component_id=1 | Duplicate pair |
| 3 | Submit | POST request |
| 4 | **Verify**: Rule::unique('msh_template_scholastic_components', 'source_component_id')->where('config_template_id', 1) | "The source component id has already been taken." |
| 5 | **Verify**: No duplicate created | DB has 1 record with that pair |

### TC-N-04: Create with weightage_percent > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Set weightage_percent = "150.00" | Exceeds max:100 |
| 3 | Submit | POST request |
| 4 | **Verify**: max:100 validation | "The weightage percent must be between 0 and 100." |
| 5 | **Verify**: No component created | DB unchanged |

### TC-N-10: Weightage sum exceeds 100% via multiple components

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure template has existing component with 60% weightage | 60% already mapped |
| 2 | Create new component under same template with 50% weightage | Total would be 110% |
| 3 | **Verify**: Service calls MarksheetConfigService::validateScholasticWeightageSum() | Validation fails |
| 4 | **Verify**: Transaction rolled back | New component NOT created |
| 5 | **Verify**: Error returned (depending on service implementation) | Save fails gracefully |

### TC-N-11: Access index without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT .viewAny permission | No viewAny |
| 2 | Direct access to /template-scholastic-component | Gate::authorize(...) throws 403 |
| 3 | **Verify**: 403 Access Denied | Forbidden |

### TC-N-22: Force delete with FK 23000 violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentSubjectResult referencing scholastic_component_id | FK reference exists |
| 2 | Soft-delete the component | Trashed |
| 3 | Navigate to trash page | Component visible |
| 4 | Click "Force Delete" | DELETE request via route |
| 5 | **Verify**: $record->forceDelete() throws QueryException 23000 | FK violation |
| 6 | **Verify**: Catch block executes | if (->getCode() === '23000') |
| 7 | **Verify**: Error: "Cannot delete this record because it is referenced by other records." | User-friendly message |
| 8 | **Verify**: Record NOT deleted | Still in DB |

### TC-N-23: Submit is_active with non-boolean value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit request with is_active=2 (non-boolean) | Invalid value |
| 2 | **Verify**: sometimes|boolean validation rule | "The is active field must be true or false." |
| 3 | **Verify**: 422 validation error | Error response |

### TC-SQ-01: Mass assignment — inject non-fillable fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit POST to store with display_label="Injected" and sort_order=99 | Fields are NOT in $fillable |
| 2 | **Verify**: TemplateScholasticComponent::create(->validated()) ignores non-fillable | DB row has NULL for these columns |
| 3 | **Verify**: $request->validated() strips unvalidated fields | Only fillable fields present |

### TC-SQ-02: Mass assignment — inject created_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit request with created_by=999 | Non-fillable may be overwritten by controller |
| 2 | **Verify**: Controller sets $validatedData['created_by'] = auth()->id() AFTER validation | Controller overwrites any injected value |

### TC-INT-01: Weightage sum governance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Component A under Template T1 with weightage=50% | Success |
| 2 | Create Component B under Template T1 with weightage=30% | Success (80% total) |
| 3 | Create Component C under Template T1 with weightage=30% | **Fail** — 80%+30%=110% > 100% |
| 4 | **Verify**: Service validates sum after each create | Third create rolls back |
| 5 | **Verify**: Only 2 components exist for Template T1 | DB has exactly 2 records |

### TC-INT-03: StudentSubjectResult FK blocks force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure StudentSubjectResult record references this component's ID | FK constraint exists |
| 2 | Soft-delete component | Trashed |
| 3 | Force delete from trash | QueryException 23000 |
| 4 | **Verify**: Catch block displays user-friendly error | Error message shown |
| 5 | **Verify**: Record NOT deleted | Remains in DB |

---
## 8. Additional Test Cases

### TC-CR: Code Review Test Cases (Scholastic Components)

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify `Gate::authorize()` in `index()` | Controller line 18 | `tenant.msh-template-scholastic-component.viewAny` |
| TC-CR-02 | Verify `Gate::authorize()` in `create()` | Controller line 29 | `tenant.msh-template-scholastic-component.create` |
| TC-CR-03 | Verify `Gate::authorize()` in `store()` | Controller line 39 | `tenant.msh-template-scholastic-component.create` |
| TC-CR-04 | Verify `Gate::authorize()` in `show()` | Controller line 67 | `tenant.msh-template-scholastic-component.view` |
| TC-CR-05 | Verify `Gate::authorize()` in `edit()` | Controller line 76 | `tenant.msh-template-scholastic-component.update` |
| TC-CR-06 | Verify `Gate::authorize()` in `update()` | Controller line 86 | `tenant.msh-template-scholastic-component.update` |
| TC-CR-07 | Verify `Gate::authorize()` in `destroy()` | Controller line 111 | `tenant.msh-template-scholastic-component.delete` |
| TC-CR-08 | Verify `Gate::authorize()` in `toggleStatus()` | Controller line 126 | `tenant.msh-template-scholastic-component.update` |
| TC-CR-09 | Verify `Gate::authorize()` in `trashed()` | Controller line 138 | `tenant.msh-template-scholastic-component.viewAny` |
| TC-CR-10 | Verify `Gate::authorize()` in `restore()` | Controller line 147 | `tenant.msh-template-scholastic-component.update` |
| TC-CR-11 | Verify `Gate::authorize()` in `forceDelete()` | Controller line 160 | `tenant.msh-template-scholastic-component.delete` |
| TC-CR-12 | Verify `activityLog()` in `store()` | Controller lines 46-48 | "A new template scholastic component was created." |
| TC-CR-13 | Verify `activityLog()` in `update()` | Controller lines 90-92 | "The template scholastic component was updated." |
| TC-CR-14 | Verify `activityLog()` in `destroy()` | Controller lines 115-117 | "The template scholastic component was deleted." |
| TC-CR-15 | Verify `activityLog()` in `toggleStatus()` | Controller line 131 | "Status was toggled." |
| TC-CR-16 | Verify `activityLog()` in `restore()` | Controller line 153 | "The record was restored." |
| TC-CR-17 | Verify `activityLog()` in `forceDelete()` success | Controller line 165 | "The record was permanently deleted." |
| TC-CR-18 | Verify `activityLog()` in `forceDelete()` — placed BEFORE delete | Controller lines 163-165 | activityLog called after forceDelete inside try block |
| TC-CR-19 | Verify `store()` uses direct `Model::create()` NOT service | Controller line 44 | `TemplateScholasticComponent::create()` — direct Eloquent |
| TC-CR-20 | Verify `update()` delegates to service layer | Controller line 88 | `$service->update(...)` — service manages transaction |
| TC-CR-21 | Verify `destroy()` delegates to service | Controller line 113 | `$service->delete(...)` — soft delete via service |
| TC-CR-22 | Verify `toggleStatus()` uses manual `findOrFail()` not route-binding | Controller line 128 | `TemplateScholasticComponent::findOrFail($id)` — manual lookup |
| TC-CR-23 | Verify `restore()` uses `onlyTrashed()->findOrFail()` | Controller line 149 | Finds only soft-deleted records |
| TC-CR-24 | Verify `forceDelete()` uses `withTrashed()->findOrFail()` | Controller line 162 | Finds ANY record (active or trashed) |
| TC-CR-25 | Verify `store()` sets `created_by` before create | Controller line 42 | `$validatedData['created_by'] = auth()->id()` |
| TC-CR-26 | Verify `restore()` sets `is_active = true` after restore | Controller line 151 | `$record->update(['is_active' => true])` |
| TC-CR-27 | Verify `toggleStatus()` inverts `is_active` with `!` operator | Controller line 129 | `! $record->is_active` — simple boolean inversion |
| TC-CR-28 | Verify `toggleStatus()` sets `updated_by` | Controller line 129 | `'updated_by' => auth()->id()` |
| TC-CR-29 | Verify `store()` dual response: redirect vs JSON | Controller lines 50-62 | `$request->expectsJson()` check |
| TC-CR-30 | Verify `update()` dual response: redirect vs JSON | Controller lines 94-106 | Same pattern as store |
| TC-CR-31 | Verify `edit()` redirects (no standalone edit view) | Controller line 81 | Redirects to `components.combined?tab=scholastic-components` |
| TC-CR-32 | Verify `forceDelete()` catches `QueryException 23000` | Controller lines 166-170 | User-friendly FK error message |
| TC-CR-33 | Verify `forceDelete()` re-throws non-23000 exceptions | Controller line 170 | `throw $e` for other QueryException codes |
| TC-CR-34 | Verify `trashed()` uses `viewAny` gate (not `restore`) | Controller line 138 | `Gate::authorize('...viewAny')` |
| TC-CR-35 | Verify `show()` eager-loads via `->load()` not `->with()` | Controller line 69 | Explicit lazy eager load |
| TC-CR-36 | Verify `index()` paginates at 20 | Controller line 22 | `->paginate(20)` — standalone route |
| TC-CR-37 | Verify hub `components()` paginates at 15 with `sc_page` | Hub Controller line 103 | `->paginate(15, ['*'], 'sc_page')` |
| TC-CR-38 | Verify `index()` eager-loads both configTemplate and sourceComponent | Controller lines 20-21 | `->with(['configTemplate', 'sourceComponent'])` |
| TC-CR-39 | Verify restore redirects to trash page | Controller line 155 | `route('...template-scholastic-component.trashed')` |
| TC-CR-40 | Verify forceDelete redirects to trash page | Controller line 173 | `route('...template-scholastic-component.trashed')` |
| TC-CR-41 | Verify store/update/destroy redirect to hub tab | Controller lines 95,119 | `route('...components.combined', ['tab' => 'scholastic-components'])` |
| TC-CR-42 | Verify `restore()` hardcoded success (not flash()) | Controller line 155 | `->with('success', 'Record restored successfully.')` — inconsistency |
| TC-CR-43 | Verify `forceDelete()` hardcoded success | Controller line 173 | `->with('success', 'Record permanently deleted.')` — inconsistency |
| TC-CR-44 | Verify `forceDelete()` activityLog only on success path | Controller line 165 | ActivityLog inside try block — not called on FK failure |
| TC-CR-45 | Verify `edit()` loads dropdowns but doesn't use them (dead code) | Controller lines 78-79 | `$configTemplates` and `$sourceComponents` loaded but never passed |
| TC-CR-46 | Verify `index()` uses `->latest()` ordering | Controller line 21 | Orders by `created_at DESC` |
| TC-CR-47 | Verify `trashed()` uses `->latest()` ordering | Controller line 140 | Same ordering as index |
| TC-CR-48 | Verify `$fillable` excludes `display_label` and `sort_order` | Model lines 17-25 | DDL orphans — columns exist in DB but not mass-assignable |
| TC-CR-49 | Verify `$casts` for `weightage_percent` as `decimal:2` | Model line 28 | Two decimal precision |
| TC-CR-50 | Verify `$casts` for `max_marks` as `decimal:2` | Model line 29 | Two decimal precision |
| TC-CR-51 | Verify `$casts` for `is_active` as `bool` | Model line 30 | Boolean casting |
| TC-CR-52 | Verify Model uses `BaseModel` not `Model` | Model line 6 | Extends `App\Models\BaseModel` |
| TC-CR-53 | Verify no `$casts` for `created_by`/`updated_by` | Model casts | Not cast — treated as integers |
| TC-CR-54 | Verify toggleStatus JSON response structure | Controller lines 133 | `{success, is_active, message}` |
| TC-CR-55 | Verify hub gate `tenant.msh-components.view` | Hub Controller line 97 | Hub-level authorization check |
| TC-CR-56 | Verify service-layer weightage sum validation exists | Service class | `MarksheetConfigService::validateScholasticWeightageSum()` called |
| TC-CR-57 | Verify `display_label` is DDL-only (not in fillable, not in blade) | DDL vs Model | Column exists but never read or written by code |
| TC-CR-58 | Verify `sort_order` is DDL-only | DDL vs Model | Column exists but never read or written by code |
| TC-CR-59 | Verify `$request->validated()` not `$request->all()` in store | Controller line 41 | Uses validated-only data |
| TC-CR-60 | Verify `activityLog()` receives `Stored` event type | Controller line 46 | Second param is `'Stored'` |

### Additional BC-BIZ-DEEP: Extended Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-51 | `store()` skips service layer entirely (direct Eloquent create) | `TemplateScholasticComponent::create()` — no transaction wrap |
| BC-BIZ-DEEP-52 | Weightage sum validation is NOT called in store() when using direct create | Only service-layer create/update calls validation — controller `store()` bypasses it |
| BC-BIZ-DEEP-53 | `store()` has NO weightage governance — GAP between direct create and service create | Direct Eloquent create in controller vs service-layer create |
| BC-BIZ-DEEP-54 | `update()` calls service update which includes weightage sum validation | Service layer ensures sum ≤ 100% |
| BC-BIZ-DEEP-55 | `destroy()` calls service delete which wraps in transaction | `$service->delete()` handles transaction internally |
| BC-BIZ-DEEP-56 | `toggleStatus()` does NOT load configTemplate or sourceComponent relations | Simple findOrFail with no eager loading |
| BC-BIZ-DEEP-57 | `toggleStatus()` response has `success`, `is_active`, `message` with hardcoded strings | Messages: "Status set to Active" / "Status set to Inactive" |
| BC-BIZ-DEEP-58 | `edit()` fully loads dropdown data that is never rendered | Dead query: 2 DB queries run, results discarded |
| BC-BIZ-DEEP-59 | `edit()` redirect does NOT set `updated_by` | Only the edit form is visited, no update occurs |
| BC-BIZ-DEEP-60 | `restore()` also updates `updated_at` via `update()` call | `update(['is_active' => true])` also touches `updated_at` |
| BC-BIZ-DEEP-61 | `restore()` does NOT set `updated_by` | Missing `updated_by` set during restore (unlike toggleStatus) |
| BC-BIZ-DEEP-62 | `forceDelete()` logs activity BEFORE checking FK | If FK exception thrown, activityLog is rolled back with transaction |
| BC-BIZ-DEEP-63 | `trashed()` uses `viewAny` permission — inconsistent with gold standard | Gold standard says `restore` gate for trash page |
| BC-BIZ-DEEP-64 | No route-model-binding on `restore`, `forceDelete`, `toggleStatus` | Manual `findOrFail` pattern for these 3 methods |
| BC-BIZ-DEEP-65 | Route-model-binding used on `show`, `edit`, `update`, `destroy` | Implicit binding via `TemplateScholasticComponent $param` |
| BC-BIZ-DEEP-66 | `show()` duplicate eager-load: route binding loads model, then ->load() adds relations | Two DB round-trips for relations |
| BC-BIZ-DEEP-67 | `created_by` is authenticated user ID (integer, FK to users.id) | No validation that user exists — trust auth system |
| BC-BIZ-DEEP-68 | `updated_by` null on create, set on update | Only `created_by` set at store time |
| BC-BIZ-DEEP-69 | No `deleted_by` column in DDL | No tracking of who soft-deleted the record |
| BC-BIZ-DEEP-70 | No `created_by`/`updated_by` eager-load in any listing | User names not displayed in table |
| BC-BIZ-DEEP-71 | `configTemplate` and `sourceComponent` FK columns are BIGINT not INT | Consistent with msh_config_templates PK type |
| BC-BIZ-DEEP-72 | `weightage_percent` DECIMAL(5,2) maxes at 999.99 | 5 digits total, 2 decimal places |
| BC-BIZ-DEEP-73 | `max_marks` DECIMAL(8,2) maxes at 999999.99 | 8 digits total, 2 decimal places |
| BC-BIZ-DEEP-74 | No check that config_template is active in Request validation | `exists:msh_config_templates,id` — any template, active or not |
| BC-BIZ-DEEP-75 | No check that source_component is active in Request validation | `exists:msh_source_components,id` — any source, active or not |
| BC-BIZ-DEEP-76 | `is_active` defaults to 1 in both DDL and Request | `sometimes|boolean` — defaults to 1 when omitted |
| BC-BIZ-DEEP-77 | AJAX POST to store uses `application/json` Accept header | `$request->expectsJson()` checks Accept header |
| BC-BIZ-DEEP-78 | Modal success reloads page or updates DOM via JS callback | JSON `redirect` key used by front-end to navigate |
| BC-BIZ-DEEP-79 | `components()` hub method loads ALL 4 tab datasets + 4 dropdowns | 8 DB queries minimum per page load |
| BC-BIZ-DEEP-80 | `searchableColumns` empty array `[]` for scholastic — no text search | `applyFilters()` skips search when array is empty |
| BC-BIZ-DEEP-81 | Hub paginator names are unique per tab (`sc_page`, `ew_page`, `ia_page`, `cc_page`) | Prevents pagination cross-talk between tabs |
| BC-BIZ-DEEP-82 | `edit()` has dead code — loaded dropdowns never reach view | `$configTemplates` and `$sourceComponents` queried but not passed |
| BC-BIZ-DEEP-83 | `restore()` hardcoded success message inconsistent with other CRUD | All other methods use `flash('key')` pattern |
| BC-BIZ-DEEP-84 | `forceDelete()` hardcoded success message inconsistent | Same inconsistency as restore |
| BC-BIZ-DEEP-85 | `index()` standalone route paginates 20 vs hub paginates 15 | Two different page sizes for same data |
| BC-BIZ-DEEP-86 | `trashed()` paginates 15 — matches hub, not standalone index | Trash uses 15, standalone index uses 20 |
| BC-BIZ-DEEP-87 | Weightage sum validation is NOT called on toggle | Only create/update triggers sum check |
| BC-BIZ-DEEP-88 | No validation that weightage sum is exactly 100% | Only checks ≤ 100%, can be less |
| BC-BIZ-DEEP-89 | `display_label` exists in DDL but model uses source_component relationship for label | Source component name used instead of display_label |
| BC-BIZ-DEEP-90 | `sort_order` in DDL but no code reads or writes it | Ordering is always by `created_at DESC` (latest()) |

### Additional Test Cases — TC-P (Positive)

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-14 | Create component with weightage=0.01 (min positive) | weightage_percent=0.01 | Created successfully |
| TC-P-15 | Create component with max_marks=999999.99 (max decimal) | max_marks=999999.99 | Created with max marks cap |
| TC-P-16 | Update component via JSON API (expectsJson) | PATCH with Accept: application/json | JSON response with redirect |
| TC-P-17 | Load components tab while another tab's search is active | ?tab=scholastic-components&search=XYZ | Filters NOT applied (tab mismatch) |
| TC-P-18 | Verify trashed page shows correct count | 10 trashed records exist | Pagination shows all 10 (within 15 limit) |
| TC-P-19 | Create component with is_active=0 initially | is_active set to 0 | Component created but inactive |
| TC-P-20 | Force delete component with no dependencies | No StudentSubjectResult FK | Successfully deleted |
| TC-P-21 | Verify hub page loads all 4 tab paginators | Scholastic, Exam Weightage, IA, Coscholastic all loaded | 4 separate paginated collections |
| TC-P-22 | Update only is_active via toggle (no other changes) | Toggle status | is_active flipped |
| TC-P-23 | Restore twice consecutively | Restore → delete again → restore again | Both restores succeed |
| TC-P-24 | Access trashed page with viewAny permission | User has .viewAny only | Page loads, only trash records shown |
| TC-P-25 | Verify activityLog message contains component ID | store() log | Log references the created component |
| TC-P-26 | Verify component created with created_by=null when auth()->id() returns null | Edge case: unauthenticated | DDL allows null, record created |

### Additional Test Cases — TC-N (Negative)

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-24 | Inject `display_label` via mass-assignment | POST with display_label="Hacked" | Ignored (not in $fillable) |
| TC-N-25 | Inject `sort_order` via mass-assignment | POST with sort_order=999 | Ignored (not in $fillable) |
| TC-N-26 | Submit weightage_percent=100.001 (3 decimals) | Regex fails | "Weightage can have at most 2 decimal places." |
| TC-N-27 | Submit max_marks=-0.01 (negative decimal) | min:0 fails | "Max marks must be a positive number." |
| TC-N-28 | Submit config_template_id="abc" (string not integer) | integer rule fails | "The config template id must be an integer." |
| TC-N-29 | Submit source_component_id=null (null required field) | Null violates required | "The source component id field is required." |
| TC-N-30 | Access show() without .view permission | User has .create but not .view | 403 Forbidden |
| TC-N-31 | Access update() without .update permission (has .delete) | User has .delete only | 403 Forbidden |
| TC-N-32 | Access destroy() without .delete permission | User has .update only | 403 Forbidden |
| TC-N-33 | Access toggleStatus() without .update permission | User has .viewAny only | 403 Forbidden |
| TC-N-34 | Attempt restore on already-active record (not in trash) | Restore ID of non-deleted record | 404 (onlyTrashed() returns nothing) |
| TC-N-35 | Attempt forceDelete on non-existent ID | ID=999999 | 404 Not Found |
| TC-N-36 | Submit store() with empty body (all fields missing) | Empty POST | 422 — all required validation errors |
| TC-N-37 | Submit update() with config_template_id changed to another template | Change owning template | Allowed? (No validation prevents changing template) |
| TC-N-38 | Submit store() with 15+ component mappings for same template | Multiple components exceeding pagination | All created (no limit enforcement per template) |
| TC-N-39 | Access any route without authentication | Not logged in | Redirect to login or 401 |

### Additional Detailed Test Execution Procedures

#### TC-P-14: Create component with weightage=0.01 (min positive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Select config_template_id, source_component_id | Required fields |
| 4 | Set weightage_percent = "0.01" | Minimum positive value |
| 5 | Submit | POST request |
| 6 | **Verify**: min:0 and regex validation pass | No error |
| 7 | **Verify**: Component created with weightage_percent=0.01 | DB stores 0.01 |

#### TC-P-20: Force delete component with no dependencies

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with delete permission | Success |
| 2 | Ensure component has NO StudentSubjectResult references | No FK dependencies |
| 3 | Soft-delete the component | destroy() called |
| 4 | Navigate to trash page | Component in trash |
| 5 | Click "Force Delete" | DELETE request |
| 6 | **Verify**: `withTrashed()->findOrFail($id)` finds record | Found |
| 7 | **Verify**: `$record->forceDelete()` succeeds | No QueryException |
| 8 | **Verify**: activityLog('Deleted') | "The record was permanently deleted." |
| 9 | **Verify**: Redirect to trash with success | "Record permanently deleted." |
| 10 | **Verify**: Record removed from DB | SELECT returns null |

#### TC-N-22: Force delete with FK 23000 (already exists — expanded)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify component with StudentSubjectResult referencing it | FK dependency exists |
| 2 | Soft-delete the component | Trashed |
| 3 | Navigate to trash | Trash page |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: `forceDelete()` throws `QueryException` with code '23000' | FK constraint violation |
| 6 | **Verify**: Catch block at line 166 executes | `if ($e->getCode() === '23000')` |
| 7 | **Verify**: Error: "Cannot delete this record because it is referenced by other records. Remove those references first." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Still in `msh_template_scholastic_components` |
| 9 | **Verify**: No activityLog written | Log only on success path |

#### TC-N-36: Submit store() with empty body

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Submit WITHOUT filling any fields | Empty POST |
| 4 | **Verify**: config_template_id — "required" | Validation error |
| 5 | **Verify**: source_component_id — "required" | Validation error |
| 6 | **Verify**: weightage_percent — "required" | Validation error |
| 7 | **Verify**: All errors returned in JSON response | 422 with error bag |
| 8 | **Verify**: No record created | DB unchanged |

#### TC-CR-22: Verify toggleStatus() manual findOrFail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus($id)` method signature | No route-model-binding |
| 2 | Check method body | `TemplateScholasticComponent::findOrFail($id)` — manual lookup |
| 3 | Confirm no `TemplateScholasticComponent $record` parameter | Not using implicit binding |
| 4 | **Verify**: Pattern matches `$id` → manual `findOrFail` | Consistent with restore/forceDelete |

#### TC-CR-42: Verify restore() hardcoded success message

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TemplateScholasticComponentController.php` | Line 155 |
| 2 | Locate `return redirect()->route(...)->with('success', ...)` | Line 155 |
| 3 | **Observe**: Message is hardcoded string `'Record restored successfully.'` | NOT using `flash('restored.template_scholastic_component')` |
| 4 | **Compare**: All other CRUD methods use `flash('key')` pattern | store/update/destroy all use flash |
| 5 | **Verify**: This is an inconsistency | Bug/gap in implementation |

#### TC-CR-60: Verify `display_label` and `sort_order` DDL orphans — cross-check with Requirement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read DDL for `msh_template_scholastic_components` | `display_label` VARCHAR(255), `sort_order` INT |
| 2 | Read Model `$fillable` array | Neither column is listed |
| 3 | Read Requirement document | "display_label (DDL only, not in model fillable)" confirmed |
| 4 | Search blade files for `display_label` or `sort_order` | Not referenced in any view |
| 5 | **Verify**: Columns are completely unused by application code | True DDL orphans |

#### TC-CR-61: Weightage sum validation — service vs controller gap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` method | Direct `Model::create()` — NO service, NO weightage validation |
| 2 | Review `update()` method | Calls `$service->update()` — weightage sum validation occurs |
| 3 | **Observation**: `store()` bypasses weightage governance | Components created via direct create have NO sum check |
| 4 | **Verify**: Weightage sum check only works when using service layer | Controllers calling service directly get validation |

#### TC-P-27: Hub page loads with all filter parameters preserved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/marksheet-generation/components?tab=scholastic-components&sc_page=2` | Tab shows page 2 |
| 2 | Click pagination link page 3 | URL has `?tab=scholastic-components&sc_page=3` |
| 3 | Switch to Exam Weightages tab | URL has `?tab=exam-weightages&ew_page=1` |
| 4 | Switch back to Scholastic Components | Returns to page 3 |

#### TC-N-40: Verify store() creates record without weightage sum check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Component A under Template T1 with weightage=60% | Success via modal |
| 2 | Create Component B under Template T1 with weightage=50% | **Succeeds** (store bypasses sum check — gap) |
| 3 | **Verify**: Template T1 now has 110% total weightage | Allowed (incorrect — validation should block) |
| 4 | **Observation**: Gap between controller store() and service create() | Service create would block this, but controller store doesn't use it |

#### TC-N-41: Attempt to set weightage_percent = 0 with regex violation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit weightage_percent = "0" (no decimal) | Passes regex (integer accepted) |
| 2 | Submit weightage_percent = "0.0" (single decimal) | Passes regex |
| 3 | Submit weightage_percent = "0." (trailing dot) | Regex fails — not digit-dot-digit pattern |
| 4 | **Verify**: `regex:/^\d+(\.\d{1,2})?$/` requires proper decimal format | 0. is rejected |


