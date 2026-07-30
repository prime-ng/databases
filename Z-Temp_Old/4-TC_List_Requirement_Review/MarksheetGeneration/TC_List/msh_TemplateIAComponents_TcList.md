# Template IA Components — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Template IA Components (msh_template_ia_components) |
| **Controller** | Modules\MarksheetGeneration\Http\Controllers\TemplateIaComponentController — 11 methods — index() NOT called; tab listing uses MarksheetGenerationController@components() |
| **Tab Container Controller** | Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@components() — tab id ia-components, private pplyFilters() |
| **Model** | Modules\MarksheetGeneration\Models\TemplateIaComponent — SoftDeletes, BaseModel, 5 relationships (incl. HasMany studentIaMarks) |
| **Form Request** | Modules\MarksheetGeneration\Http\Requests\TemplateIaComponentRequest — 5 validation rules + prepareForValidation |
| **Policy** | TemplateIaComponentPolicy — permission prefix 	enant.msh-template-ia-component.* |
| **Service** | TemplateIaComponentService — wraps create/update/delete in DB transactions |
| **Route Prefix** | marksheet-generation.template-ia-component.* (resource) + 	rashed, estore, orceDelete, 	oggleStatus |
| **Blade Views** | pages/partials/components/_ia-components.blade.php (tab partial) |
| **Tab Container** | pages/components.blade.php — tab id ia-components, permission 	enant.msh-template-ia-component.view |
| **DB Table** | msh_template_ia_components — 12 columns |
| **Primary Screen** | Marksheet Generation → Components → IA Components tab (paginated, searchable, status-filtered, modal-based CRUD) |
| **Modal IDs** | #createTemplateIaComponentModal, #editTemplateIaComponentModal |
| **Paginator Name** | ia_page (15 per page) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must have 	enant.msh-template-ia-component.* permissions |
| PC-02 | msh_template_ia_components table must exist with all columns |
| PC-03 | msh_config_templates must have at least one active template |
| PC-04 | msh_ia_component_types must have at least one active IA type |
| PC-05 | Controller registered in web routes |
| PC-06 | Policy registered in AuthServiceProvider |
| PC-07 | Tab included with @can('tenant.msh-template-ia-component.view') guard |
| PC-08 | Soft deletes enabled |
| PC-09 | Service autowireable |
| PC-10 | Browser JavaScript enabled for modals |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | 15 per page via pplyFilters(), paginator ia_page | MarksheetGenerationController.php:105 |
| DL-02 | Search/status only when $tab === 'ia-components' | Tab-aware filtering |
| DL-03 | Columns: **#**, **Config Template**, **IA Component Type**, **Max Marks**, **Order**, **Status**, **Action** | _ia-components.blade.php:37-49 |
| DL-04 | IA Component Type displayed as raw $row->ia_component_type_id | Not eager-loaded name |
| DL-05 | display_order column displayed as "Order" | _ia-components.blade.php:58 |
| DL-06 | Shared dropdowns: ConfigTemplate::where('is_active', 1)->get(), IaComponentType::where('is_active', 1)->get() | MarksheetGenerationController.php:108,111 |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid IA Component** | config_template_id=1, ia_component_type_id=1, max_marks=20.00, display_order=1, is_active=1 |
| TD-02 | **Duplicate IA Type Per Template** | Same config_template_id + ia_component_type_id — unique violation |
| TD-03 | **Max Marks Negative** | max_marks=-10.00 — min:0 failure |
| TD-04 | **Display Order < 1** | display_order=0 — min:1 failure |
| TD-05 | **Force Delete with StudentIaMark FK** | Referenced by StudentIaMark — 23000 catch |
| TD-06 | **Max Marks >2 decimals** | max_marks=20.123 — regex failure |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK | Auto-increment | DDL |
| BC-DB-02 | config_template_id — BIGINT, FK → msh_config_templates.id | Required FK | DDL |
| BC-DB-03 | ia_component_type_id — BIGINT, FK → msh_ia_component_types.id | Required FK | DDL |
| BC-DB-04 | display_label — VARCHAR(255), NULLABLE | DDL only, not fillable | DDL |
| BC-DB-05 | max_marks — DECIMAL(8,2) | Max marks | DDL |
| BC-DB-06 | weightage_percentage — DECIMAL(5,2) | DDL only, not fillable | DDL |
| BC-DB-07 | sort_order — INT | DDL only, not fillable (vs display_order) | DDL |
| BC-DB-08 | is_active — TINYINT(1), DEFAULT 1 | Active flag | DDL |
| BC-DB-09 | created_by — BIGINT | Creator | DDL |
| BC-DB-10 | updated_by — BIGINT | Modifier | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | config_template_id — required, integer, exists | equired|integer|exists:msh_config_templates,id | Request |
| BC-VAL-02 | ia_component_type_id — required, integer, exists, unique per config_template | equired|integer|exists:msh_ia_component_types,id|Rule::unique(...)->where('config_template_id', ...) | Request |
| BC-VAL-03 | max_marks — required, numeric, min:0, 2 decimal regex | equired|numeric|min:0|regex:/^\d+(\.\d{1,2})?$/ | Request |
| BC-VAL-04 | display_order — required, integer, min:1 | equired|integer|min:1 | Request |
| BC-VAL-05 | is_active — sometimes, boolean | sometimes|boolean | Request |
| BC-VAL-06 | prepareForValidation() defaults display_order to 1 | $this->merge(['display_order' => ->display_order ?? 1]) | Request |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Source |
|----|-----------|-----------------|--------|
| BC-AUTH-01 | 	enant.msh-components.view | Hub: Gate::authorize(...) at MarksheetGenerationController.php:97 | Hub |
| BC-AUTH-02 | 	enant.msh-template-ia-component.view | Blade: @can('...view') at components.blade.php:14,23 | Tab |
| BC-AUTH-03 | 	enant.msh-template-ia-component.viewAny | index() line 18, 	rashed() line 138 | Controller |
| BC-AUTH-04 | 	enant.msh-template-ia-component.create | create() line 29, store() line 39 | Controller |
| BC-AUTH-05 | 	enant.msh-template-ia-component.update | edit() line 76, update() line 86, 	oggleStatus() line 126, estore() line 147 | Controller |
| BC-AUTH-06 | 	enant.msh-template-ia-component.delete | destroy() line 111, orceDelete() line 160 | Controller |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store() sets created_by | $validatedData['created_by'] = auth()->id() | TemplateIaComponentController.php:42 |
| BC-BIZ-02 | store() dual response (JSON/AJAX) | $request->expectsJson() check | Line 54-62 |
| BC-BIZ-03 | edit() redirects to hub tab | edirect()->route('...components.combined', ['tab' => 'ia-components']) | Line 81 |
| BC-BIZ-04 | update() delegates to service | $service->update(, , auth()->id()) | Line 88 |
| BC-BIZ-05 | destroy() delegates to service | $service->delete(...) | Line 113 |
| BC-BIZ-06 | toggleStatus() inverts is_active | $record->update(['is_active' => !->is_active, 'updated_by' => auth()->id()]) | Line 129 |
| BC-BIZ-07 | forceDelete() catches FK 23000 | StudentIaMark references ia_component_id | Lines 163-170 |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | TemplateIaComponent → ConfigTemplate | elongsTo(configTemplate) | TemplateIaComponent.php:34-37 |
| BC-REL-02 | TemplateIaComponent → IaComponentType | elongsTo(iaComponentType) | TemplateIaComponent.php:39-42 |
| BC-REL-03 | TemplateIaComponent → User (created_by) | elongsTo(createdBy) | TemplateIaComponent.php:44-47 |
| BC-REL-04 | TemplateIaComponent → User (updated_by) | elongsTo(updatedBy) | TemplateIaComponent.php:49-52 |
| BC-REL-05 | TemplateIaComponent → StudentIaMark | hasMany(studentIaMarks, ia_component_id) | TemplateIaComponent.php:54-57 |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab guarded by @can('tenant.msh-template-ia-component.view') | Tab conditional | components.blade.php:14,23 |
| BC-REF-02 | IA type as raw ID: {{ ->ia_component_type_id }} | No eager-loaded name | _ia-components.blade.php:56 |
| BC-REF-03 | display_order displayed as integer | {{ ->display_order }} | _ia-components.blade.php:58 |
| BC-REF-04 | Edit modal: editTemplateIaComponent(id, config_template_id, ia_component_type_id, max_marks, display_order, is_active) | 6 params | _ia-components.blade.php:66 |
| BC-REF-05 | Empty state: "No IA Components Found" with fa-book | Icon-centered | _ia-components.blade.php:23-32 |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 15 per page with ia_page name | ->paginate(15, ['*'], 'ia_page') |
| BC-BIZ-DEEP-02 | max_marks cast as decimal:2 | Model $casts |
| BC-BIZ-DEEP-03 | display_order cast as integer | Model $casts |
| BC-BIZ-DEEP-04 | is_active cast as ool | Model $casts |
| BC-BIZ-DEEP-05 | prepareForValidation() defaults display_order to 1 | $this->display_order ?? 1 |
| BC-BIZ-DEEP-06 | studentIaMarks() HasMany relation blocks force delete | FK 23000 catch |
| BC-BIZ-DEEP-07 | weightage_percentage and sort_order exist in DDL but not fillable | DDL orphans |
| BC-BIZ-DEEP-08 | Model uses display_order (fillable) vs DDL sort_order (not fillable) | Name mismatch between fillable and DDL |

### CODE-TRACE: Key Method Trace

#### CODE-TRACE-01: store(TemplateIaComponentRequest ) — Lines 37-63

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 39 | Gate::authorize('tenant.msh-template-ia-component.create') | Authorization |
| 02 | 41 | $validatedData = ->validated() | Validate |
| 03 | 42 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 44 | $component = TemplateIaComponent::create() | Create |
| 05 | 46-48 | ctivityLog(, 'Stored', ['message' => '...']) | Log |
| 06 | 50-62 | Dual response: JSON for AJAX, redirect for normal | Modal |

#### CODE-TRACE-02: orceDelete() — Lines 158-174

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 160 | Gate::authorize('...delete') | Authorization |
| 02 | 162 | $record = TemplateIaComponent::withTrashed()->findOrFail() | Find |
| 03 | 163-165 | 	ry { ->forceDelete(); activityLog(...); } | Delete + log |
| 04 | 166-170 | catch (QueryException ) { if (->getCode() === '23000') { error } } | FK 23000 catch |
| 05 | 173 | Success redirect | Hardcoded message |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create IA component via modal with all fields | All fields via AJAX | Created, activityLog "Stored" |
| TC-P-02 | Create IA component with default display_order | display_order auto=1 | Created with order=1 |
| TC-P-03 | Edit IA component max_marks via modal | Change 20 to 30 | Updated, activityLog "Updated" |
| TC-P-04 | Edit display_order for reordering | Change from 3 to 1 | Updated |
| TC-P-05 | Toggle status active→inactive | Click status switch | JSON success |
| TC-P-06 | Toggle status inactive→active | Click status switch | JSON success |
| TC-P-07 | Filter by active status | Select "Active" | Only active |
| TC-P-08 | Restore soft-deleted IA component | Trash → Restore | Restored, is_active=true |
| TC-P-09 | Force delete with no FK references | No StudentIaMark refs | Permanently removed |
| TC-P-10 | Force delete with FK 23000 catch | Has StudentIaMark refs | Error message displayed |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create empty config_template_id | Required field omitted | "required" |
| TC-N-02 | Create empty ia_component_type_id | Required field omitted | "required" |
| TC-N-03 | Duplicate IA type per template | Same pair | "already been taken" |
| TC-N-04 | max_marks negative | -10.00 | "must be a positive number" |
| TC-N-05 | max_marks >2 decimal places | 20.123 | "format is invalid" |
| TC-N-06 | display_order < 1 | 0 | "must be at least 1" |
| TC-N-07 | Invalid config_template_id=99999 | Non-existent | "invalid" |
| TC-N-08 | Invalid ia_component_type_id=99999 | Non-existent | "invalid" |
| TC-N-09 | Access without .viewAny | No permission | 403 |
| TC-N-10 | Store without .create | No permission | 403 |
| TC-N-11 | Force delete with FK 23000 | StudentIaMark refs | Error, not deleted |
| TC-N-12 | Show non-existent ID | 404 | ModelNotFoundException |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | Mass-assign non-fillable fields | Inject weightage_percentage, sort_order | Ignored |
| TC-SQ-02 | Tab hidden without .view | No permission | Tab not rendered |
| TC-SQ-03 | Add button hidden without .create | No permission | Button hidden |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | DDL orphan columns not used | weightage_percentage, sort_order, display_label in DDL but not fillable | No code sets them |
| TC-INT-02 | StudentIaMark FK blocks force delete | Referenced component | 23000 catch |
| TC-INT-03 | IaComponentType FK reference | Delete type with components | FK CASCADE/RESTRICT |

## 7. Detailed Test Execution Procedures

### TC-P-11: Create IA component with max_marks=0 (min boundary)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Select Config Template and IA Component Type | Required fields |
| 4 | Set max_marks = "0.00" | Min boundary |
| 5 | Set display_order = 1 | Default order |
| 6 | Submit | POST request |
| 7 | **Verify**: min:0 validation passes | No error |
| 8 | **Verify**: Component created with max_marks=0.00 | DB stores 0.00 |

### TC-P-12: Create IA component with display_order=99 (max)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set display_order = 99 | Large order value |
| 2 | Submit | POST request |
| 3 | **Verify**: integer|min:1 passes | No error |
| 4 | **Verify**: display_order=99 stored | DB stores 99 |

### TC-P-13: Edit IA component via modal — change max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to IA Components tab | List displayed |
| 3 | Click edit icon on existing row | JS fires editTemplateIaComponent(id, config_template_id, ia_component_type_id, max_marks, display_order, is_active) |
| 4 | **Verify**: Edit modal opens with pre-filled values | Current data shown |
| 5 | Change max_marks from 20 to 30 | Updated input |
| 6 | Click Submit | PATCH via AJAX |
| 7 | **Verify**: Gate::authorize('...update') passes | Authorized |
| 8 | **Verify**: $service->update() called | Service transaction |
| 9 | **Verify**: activityLog($record, 'Updated', [...]) | "The template IA component was updated." |
| 10 | **Verify**: JSON response with redirect | Redirect to ?tab=ia-components |
| 11 | **Verify**: flash('updated.template_ia_component') | Success message |

### TC-P-14: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Locate active IA component status toggle | Toggle ON |
| 3 | Click toggle | AJAX POST to toggleStatus |
| 4 | **Verify**: Gate::authorize('...update') at line 126 passes | Authorized |
| 5 | **Verify**: $record = TemplateIaComponent::findOrFail($id) | Record found |
| 6 | **Verify**: update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()]) | is_active inverted |
| 7 | **Verify**: activityLog($record, 'Toggled', [...]) | "Status was toggled." |
| 8 | **Verify**: JSON {success: true, is_active: false, message: 'Status set to Inactive'} | Toggle OFF |

### TC-P-15: Toggle status inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate inactive component (is_active=0) | Toggle OFF |
| 2 | Click toggle | AJAX POST |
| 3 | **Verify**: JSON {success: true, is_active: true, message: 'Status set to Active'} | Toggle ON |

### TC-P-16: Filter by active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from status filter | status=1 |
| 2 | Submit | GET with ?tab=ia-components&status=1 |
| 3 | **Verify**: Tab-aware filter applied | Only active displayed |

### TC-P-17: Filter by inactive status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" | status=0 |
| 2 | Submit | Only inactive displayed |

### TC-P-18: Restore soft-deleted IA component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to trash | onlyTrashed() records |
| 3 | Click "Restore" | GET to restore |
| 4 | **Verify**: Gate::authorize('...update') passes | Authorized |
| 5 | **Verify**: onlyTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: $record->restore() | deleted_at = NULL |
| 7 | **Verify**: $record->update(['is_active' => true]) | Reactivated |
| 8 | **Verify**: activityLog($record, 'Restored', [...]) | "The record was restored." |
| 9 | **Verify**: Redirect with hardcoded message | "Record restored successfully." |

### TC-P-19: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .delete permission | Success |
| 2 | Navigate to trash | Trashed record |
| 3 | Click "Force Delete" | DELETE request |
| 4 | **Verify**: withTrashed()->findOrFail($id) | Record found |
| 5 | **Verify**: forceDelete() succeeds | Permanently removed |
| 6 | **Verify**: activityLog($record, 'Deleted', [...]) | "The record was permanently deleted." |
| 7 | **Verify**: Redirect "Record permanently deleted." | Success |

### TC-P-20: Force delete with FK 23000 catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentIaMark references | FK exists |
| 2 | Soft-delete component | Trashed |
| 3 | Navigate to trash | Component in trash |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: forceDelete() throws QueryException 23000 | FK violation |
| 6 | **Verify**: Catch block executes | Error displayed |
| 7 | **Verify**: "Cannot delete this record..." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Remains in DB |

### TC-P-21: Pagination — page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 16+ IA components exist | 2+ pages |
| 2 | Navigate to IA Components tab | Page 1, 15 records |
| 3 | Click page 2 | GET with ?tab=ia-components&ia_page=2 |
| 4 | **Verify**: paginate(15, ['*'], 'ia_page') | Records 16-30 |

### TC-P-22: Search filter NOT applied when tab mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?tab=scholastic-components&search=xyz | Scholastic tab active |
| 2 | Switch to IA Components | No search applied |
| 3 | **Verify**: All IA components shown | Correct |

---

### TC-N: Negative Test Cases (Additional)

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-13 | Create with max_marks=0.001 (3 decimals) | regex:/^\d+(\.\d{1,2})?$/ fails | "format is invalid" |
| TC-N-14 | Create with max_marks="abc" (non-numeric) | numeric fails | "must be a number" |
| TC-N-15 | Create with config_template_id="abc" | integer fails | "must be an integer" |
| TC-N-16 | Create with ia_component_type_id="abc" | integer fails | "must be an integer" |
| TC-N-17 | Create with display_order=0 | min:1 fails | "must be at least 1" |
| TC-N-18 | Create with display_order="abc" | integer fails | "must be an integer" |
| TC-N-19 | Submit is_active=2 (non-boolean) | boolean fails | "must be true or false" |
| TC-N-20 | Inject weightage_percentage via mass-assignment | Not in $fillable | Ignored |
| TC-N-21 | Inject sort_order via mass-assignment | Not in $fillable | Ignored |
| TC-N-22 | Access edit() without .update permission | User lacks update | 403 |
| TC-N-23 | Access store() without .create permission | User lacks create | 403 |
| TC-N-24 | Access trashed() without .viewAny | No permission | 403 |
| TC-N-25 | Access show() with non-existent ID 99999 | 404 | ModelNotFoundException |
| TC-N-26 | Restore non-trashed (active) record | onlyTrashed() returns empty | 404 |
| TC-N-27 | Store with empty body | All fields missing | 422 errors |

---

## 8. BC-BIZ-DEEP: Extended Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-09 | `store()` uses direct Eloquent create (NOT service) | `TemplateIaComponent::create($validatedData)` |
| BC-BIZ-DEEP-10 | `update()` delegates to service with transaction | `$service->update($record, $data, auth()->id())` |
| BC-BIZ-DEEP-11 | `destroy()` delegates to service soft-delete | `$service->delete($record)` |
| BC-BIZ-DEEP-12 | No weightage sum validation (IA components don't have weightage) | Different from scholastic |
| BC-BIZ-DEEP-13 | `index()` standalone uses 20 per page, hub uses 15 | Inconsistent pagination |
| BC-BIZ-DEEP-14 | `trashed()` uses 15 per page — matches hub | Consistent with hub |
| BC-BIZ-DEEP-15 | `toggleStatus()` uses manual findOrFail($id) | Not route-model-binding |
| BC-BIZ-DEEP-16 | `toggleStatus()` inverts is_active with ! operator | `!$record->is_active` |
| BC-BIZ-DEEP-17 | `restore()` uses onlyTrashed()->findOrFail() | Trash scope |
| BC-BIZ-DEEP-18 | `restore()` sets is_active=true after restore | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-19 | `forceDelete()` uses withTrashed()->findOrFail() | Any record scope |
| BC-BIZ-DEEP-20 | `forceDelete()` catches QueryException 23000 | FK violation handling |
| BC-BIZ-DEEP-21 | `forceDelete()` re-throws non-23000 exceptions | `throw $e` |
| BC-BIZ-DEEP-22 | `forceDelete()` activityLog inside try — only on success | Log after successful delete |
| BC-BIZ-DEEP-23 | `edit()` redirects to hub (no standalone edit page) | Modal-based pattern |
| BC-BIZ-DEEP-24 | `edit()` loads dropdowns but discards them (dead code) | `ConfigTemplate::where(...)->get()` unused |
| BC-BIZ-DEEP-25 | `store()` has created_by but NOT updated_by | updated_by null on create |
| BC-BIZ-DEEP-26 | `update()` sets updated_by via service | `(int) auth()->id()` passed to service |
| BC-BIZ-DEEP-27 | `store()` dual response: JSON for modal, redirect for normal | `$request->expectsJson()` |
| BC-BIZ-DEEP-28 | `show()` loads relations via ->load() | `$record->load(['configTemplate', 'iaComponentType'])` |
| BC-BIZ-DEEP-29 | Blade displays $row->ia_component_type_id as raw ID | No eager-loaded name |
| BC-BIZ-DEEP-30 | `index()` eager-loads both configTemplate and iaComponentType | `->with(['configTemplate', 'iaComponentType'])` |
| BC-BIZ-DEEP-31 | Model $casts: max_marks decimal:2, display_order integer, is_active bool | Proper casting |
| BC-BIZ-DEEP-32 | Model uses `BaseModel` | Extends `App\Models\BaseModel` |
| BC-BIZ-DEEP-33 | Model has studentIaMarks() HasMany relation | `hasMany(StudentIaMark::class, 'ia_component_id')` |
| BC-BIZ-DEEP-34 | `trashed()` gate uses viewAny | `Gate::authorize('...viewAny')` |
| BC-BIZ-DEEP-35 | `restore()` gate uses update | `Gate::authorize('...update')` |
| BC-BIZ-DEEP-36 | `restore()` hardcoded success message | "Record restored successfully." |
| BC-BIZ-DEEP-37 | `forceDelete()` hardcoded success message | "Record permanently deleted." |
| BC-BIZ-DEEP-38 | Tab @can uses `tenant.msh-template-ia-component.view` | Tab visibility |
| BC-BIZ-DEEP-39 | Paginator name `ia_page` unique per tab | Prevents cross-tab conflict |
| BC-BIZ-DEEP-40 | Tab-aware filtering checks $tab === 'ia-components' | Scoped filters |
| BC-BIZ-DEEP-41 | prepareForValidation() defaults display_order to 1 | `$this->display_order ?? 1` |
| BC-BIZ-DEEP-42 | DDL has weightage_percentage, sort_order, display_label (not fillable) | DDL orphans |
| BC-BIZ-DEEP-43 | Model uses `display_order` (fillable) vs DDL `sort_order` (not fillable) | Name mismatch |
| BC-BIZ-DEEP-44 | No regex on max_marks? — YES, regex required | `regex:/^\d+(\.\d{1,2})?$/` |
| BC-BIZ-DEEP-45 | display_order is required|integer|min:1 | Strict validation |
| BC-BIZ-DEEP-46 | Empty searchableColumns array — no text search | Same as other IA tabs |
| BC-BIZ-DEEP-47 | Route: marksheet-generation.template-ia-component.* | Full resource |
| BC-BIZ-DEEP-48 | Edit modal JS: editTemplateIaComponent(id, config_template_id, ia_component_type_id, max_marks, display_order, is_active) | 6 params |
| BC-BIZ-DEEP-49 | Empty state: "No IA Components Found" with fa-book icon | Custom per entity |
| BC-BIZ-DEEP-50 | Action column :canView="false" | Only edit + delete |
| BC-BIZ-DEEP-51 | studentIaMarks() HasMany blocks force delete | FK 23000 catch |
| BC-BIZ-DEEP-52 | store() redirects to show page for non-AJAX | `route('...template-ia-component.show', $component)` |
| BC-BIZ-DEEP-53 | destroy/update redirect to hub tab | `route('...components.combined', ['tab' => 'ia-components'])` |
| BC-BIZ-DEEP-54 | restore/forceDelete redirect to trash | `route('...template-ia-component.trashed')` |
| BC-BIZ-DEEP-55 | toggleStatus() hardcoded messages | "Status set to Active" / "Inactive" |
| BC-BIZ-DEEP-56 | activityLog 5 event types | Stored, Updated, Deleted, Toggled, Restored |
| BC-BIZ-DEEP-57 | activityLog missing performed_by on Restored | Only message key |
| BC-BIZ-DEEP-58 | findOrFail() throws ModelNotFoundException → 404 | Default Laravel |
| BC-BIZ-DEEP-59 | Hub controller dispatches all 4 tab datasets | Single method, 4 collections |
| BC-BIZ-DEEP-60 | withQueryString() preserves tab/filter params | Pagination links correct |

---

## 9. Code Trace — Complete Method Traces

#### CODE-TRACE-03: index() — Lines 16-25 (Standalone)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 18 | Gate::authorize('tenant.msh-template-ia-component.viewAny') | Authorization |
| 02 | 20-22 | TemplateIaComponent::with(['configTemplate', 'iaComponentType'])->latest()->paginate(20) | Query + paginate 20 |
| 03 | 24 | return view('marksheetgeneration::template-ia-component.index', compact('components')) | View |

#### CODE-TRACE-04: show(TemplateIaComponent $templateIaComponent) — Lines 65-72

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 67 | Gate::authorize('tenant.msh-template-ia-component.view') | Authorization |
| 02 | 69 | $templateIaComponent->load(['configTemplate', 'iaComponentType']) | Eager-load |
| 03 | 71 | return view(...) | Return show view |

#### CODE-TRACE-05: create() — Lines 27-35

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 29 | Gate::authorize('tenant.msh-template-ia-component.create') | Authorization |
| 02 | 31-32 | ConfigTemplate::where('is_active', true)->get(); IaComponentType::where('is_active', true)->get() | Load dropdowns |
| 03 | 34 | return view('marksheetgeneration::template-ia-component.create', compact(...)) | Return view |

#### CODE-TRACE-06: store(TemplateIaComponentRequest $request) — Lines 37-63

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 39 | Gate::authorize('tenant.msh-template-ia-component.create') | Authorization |
| 02 | 41 | $validatedData = $request->validated() | Validate |
| 03 | 42 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 44 | $component = TemplateIaComponent::create($validatedData) | Create (direct) |
| 05 | 46-48 | activityLog($component, 'Stored', ['message' => '...']) | Activity log |
| 06 | 50-62 | Dual response: JSON for AJAX, redirect for normal | Modal support |

#### CODE-TRACE-07: edit(TemplateIaComponent $templateIaComponent) — Lines 74-82

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 76 | Gate::authorize('tenant.msh-template-ia-component.update') | Authorization |
| 02 | 78-79 | Load dropdowns (dead code — unused) | Discarded |
| 03 | 81 | return redirect()->route('...components.combined', ['tab' => 'ia-components']) | Redirect to hub |

#### CODE-TRACE-08: update(TemplateIaComponentRequest $request, ..., TemplateIaComponentService $service) — Lines 84-107

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 86 | Gate::authorize('tenant.msh-template-ia-component.update') | Authorization |
| 02 | 88 | $service->update($templateIaComponent, $request->validated(), (int) auth()->id()) | Service update |
| 03 | 90-92 | activityLog($templateIaComponent, 'Updated', [...]) | Activity log |
| 04 | 94-106 | Dual response: redirect to hub tab or JSON | Modal support |

#### CODE-TRACE-09: destroy(TemplateIaComponent $templateIaComponent, TemplateIaComponentService $service) — Lines 109-122

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 111 | Gate::authorize('tenant.msh-template-ia-component.delete') | Authorization |
| 02 | 113 | $service->delete($templateIaComponent) | Service soft-delete |
| 03 | 115-117 | activityLog($templateIaComponent, 'Deleted', ['message' => '...']) | Activity log |
| 04 | 119-121 | Redirect to hub tab with flash | Success |

#### CODE-TRACE-10: toggleStatus($id) — Lines 124-134

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 126 | Gate::authorize('tenant.msh-template-ia-component.update') | Authorization |
| 02 | 128 | $record = TemplateIaComponent::findOrFail($id) | Find record |
| 03 | 129 | $record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()]) | Toggle |
| 04 | 131 | activityLog($record, 'Toggled', ['message' => 'Status was toggled.']) | Activity log |
| 05 | 133 | return response()->json([...]) | JSON response |

#### CODE-TRACE-11: trashed() — Lines 136-143

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 138 | Gate::authorize('tenant.msh-template-ia-component.viewAny') | Authorization |
| 02 | 140 | TemplateIaComponent::onlyTrashed()->latest()->paginate(15) | Trashed query |
| 03 | 142 | return view('marksheetgeneration::trashed.template-ia-component', compact('trashed')) | View |

#### CODE-TRACE-12: restore($id) — Lines 145-156

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 147 | Gate::authorize('tenant.msh-template-ia-component.update') | Authorization |
| 02 | 149 | $record = TemplateIaComponent::onlyTrashed()->findOrFail($id) | Find trashed |
| 03 | 150 | $record->restore() | Restore |
| 04 | 151 | $record->update(['is_active' => true]) | Reactivate |
| 05 | 153 | activityLog($record, 'Restored', ['message' => 'The record was restored.']) | Activity log |
| 06 | 155 | return redirect()->route('...trashed')->with('success', 'Record restored successfully.') | Redirect |

#### CODE-TRACE-13: forceDelete($id) — Lines 158-174

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 160 | Gate::authorize('tenant.msh-template-ia-component.delete') | Authorization |
| 02 | 162 | $record = TemplateIaComponent::withTrashed()->findOrFail($id) | Find any |
| 03 | 163-165 | try { forceDelete(); activityLog(...); } | Delete + log |
| 04 | 166-170 | catch (QueryException $e) { if (23000) { error } throw $e; } | FK 23000 |
| 05 | 173 | return redirect()->route('...trashed')->with('success', 'Record permanently deleted.') | Success |

---

## 10. Additional Code Review Test Cases (TC-CR)

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Gate::authorize in index() | Line 18 | tenant.msh-template-ia-component.viewAny |
| TC-CR-02 | Gate::authorize in create() | Line 29 | tenant.msh-template-ia-component.create |
| TC-CR-03 | Gate::authorize in store() | Line 39 | tenant.msh-template-ia-component.create |
| TC-CR-04 | Gate::authorize in show() | Line 67 | tenant.msh-template-ia-component.view |
| TC-CR-05 | Gate::authorize in edit() | Line 76 | tenant.msh-template-ia-component.update |
| TC-CR-06 | Gate::authorize in update() | Line 86 | tenant.msh-template-ia-component.update |
| TC-CR-07 | Gate::authorize in destroy() | Line 111 | tenant.msh-template-ia-component.delete |
| TC-CR-08 | Gate::authorize in toggleStatus() | Line 126 | tenant.msh-template-ia-component.update |
| TC-CR-09 | Gate::authorize in trashed() | Line 138 | tenant.msh-template-ia-component.viewAny |
| TC-CR-10 | Gate::authorize in restore() | Line 147 | tenant.msh-template-ia-component.update |
| TC-CR-11 | Gate::authorize in forceDelete() | Line 160 | tenant.msh-template-ia-component.delete |
| TC-CR-12 | activityLog in store() | Lines 46-48 | "A new template IA component was created." |
| TC-CR-13 | activityLog in update() | Lines 90-92 | "The template IA component was updated." |
| TC-CR-14 | activityLog in destroy() | Lines 115-117 | "The template IA component was deleted." |
| TC-CR-15 | activityLog in toggleStatus() | Line 131 | "Status was toggled." |
| TC-CR-16 | activityLog in restore() | Line 153 | "The record was restored." |
| TC-CR-17 | activityLog in forceDelete() | Line 165 | "The record was permanently deleted." |
| TC-CR-18 | store() uses direct create NOT service | Line 44 | TemplateIaComponent::create($validatedData) |
| TC-CR-19 | update() delegates to service | Line 88 | $service->update(...) |
| TC-CR-20 | destroy() delegates to service | Line 113 | $service->delete(...) |
| TC-CR-21 | store() sets created_by | Line 42 | $validatedData['created_by'] = auth()->id() |
| TC-CR-22 | restore() sets is_active=true | Line 151 | $record->update(['is_active' => true]) |
| TC-CR-23 | toggleStatus() inverts is_active | Line 129 | !$record->is_active |
| TC-CR-24 | toggleStatus() sets updated_by | Line 129 | 'updated_by' => auth()->id() |
| TC-CR-25 | studentIaMarks() HasMany relation exists | Model line 54-57 | Blocks force delete |
| TC-CR-26 | $casts: max_marks decimal:2 | Model line 29 | Two decimal precision |
| TC-CR-27 | $casts: display_order integer | Model line 30 | Integer casting |
| TC-CR-28 | $casts: is_active bool | Model line 31 | Boolean casting |
| TC-CR-29 | $fillable excludes weightage_percentage, sort_order, display_label | Model lines 18-26 | DDL orphans |
| TC-CR-30 | edit() redirects, no standalone view | Line 81 | Redirect to hub tab |

---

## 11. Additional Security (TC-SQ) & Integration (TC-INT) Tests

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-04 | CSRF on store() — no CSRF token | 419 | Page Expired |
| TC-SQ-05 | Mass-assign DDL orphans | weightage_percentage, sort_order | Ignored |
| TC-SQ-06 | Tab hidden without .view | No permission | Not rendered |
| TC-SQ-07 | Add button hidden without .create | No permission | Hidden |
| TC-INT-04 | IaComponentType FK restriction | Delete referenced type | FK CASCADE/RESTRICT |
| TC-INT-05 | StudentIaMark FK blocks force delete | Has references | 23000 catch |
| TC-INT-06 | Transaction rollback on service failure | Update throws | No partial state |
| TC-INT-07 | Modal AJAX 422 on invalid data | Bad POST | JSON errors |
| TC-INT-08 | display_order not unique — duplicates allowed | Two components order=1 | Allowed |

---

## 12. Hub Controller Components() Method Deep Trace

### CODE-TRACE-HUB-IA: MarksheetGenerationController::components() — IA Tab Dispatch

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 97 | Gate::authorize('tenant.msh-components.view') | Hub gate |
| 02 | 99-101 | $search, $status, $tab = request('tab', 'scholastic-components') | Params |
| 03 | 105 | $iaComponents = $this->applyFilters(TemplateIaComponent::with('configTemplate'), $tab === 'ia-components' ? $search : null, $tab === 'ia-components' ? $status : null, [])->paginate(15, ['*'], 'ia_page') | IA query |
| 04 | 108-111 | Shared dropdowns: configTemplates, sourceComponents, examTypes, iaComponentTypes | Dropdowns |
| 05 | 113-116 | return view('marksheetgeneration::pages.components', compact(...)) | Hub view |

### applyFilters() for IA tab:

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 304 | applyFilters($query, ?string $search, ?string $status, array $searchableColumns) | Signature |
| 02 | 306-311 | if ($search && !empty($searchableColumns)) { search } | Search (IA has empty [], skips) |
| 03 | 314-316 | if ($status !== null) { where('is_active', (int) $status) } | Status filter |
| 04 | 318 | return $query->latest() | Latest ordering |

---

## 13. BC-DB: Database Conditions — Complete

| ID | Column | Type | Constraints | Source |
|----|--------|------|-------------|--------|
| BC-DB-01 | id | BIGINT | PK, AUTO_INCREMENT | DDL |
| BC-DB-02 | config_template_id | BIGINT | NOT NULL, FK → msh_config_templates.id | DDL |
| BC-DB-03 | ia_component_type_id | BIGINT | NOT NULL, FK → msh_ia_component_types.id | DDL |
| BC-DB-04 | display_label | VARCHAR(255) | NULLABLE (DDL orphan) | DDL |
| BC-DB-05 | max_marks | DECIMAL(8,2) | NOT NULL | DDL |
| BC-DB-06 | weightage_percentage | DECIMAL(5,2) | NULLABLE (DDL orphan) | DDL |
| BC-DB-07 | sort_order | INT | NULLABLE (DDL orphan) | DDL |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | DDL |
| BC-DB-09 | created_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-10 | updated_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-11 | created_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-12 | updated_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-13 | deleted_at | TIMESTAMP | NULLABLE | DDL |

**DDL-to-Model Mapping:**

| DDL Column | In $fillable? | In $casts? | Notes |
|------------|---------------|------------|-------|
| id | No | No | PK |
| config_template_id | **Yes** | No | FK |
| ia_component_type_id | **Yes** | No | FK |
| display_label | **No** | No | DDL orphan |
| max_marks | **Yes** | decimal:2 | 2 decimal precision |
| weightage_percentage | **No** | No | DDL orphan |
| sort_order | **No** | No | DDL orphan (vs fillable display_order) |
| is_active | **Yes** | bool | Boolean |
| created_by | **Yes** | No | Set by controller |
| updated_by | **Yes** | No | Set by controller |

**GAP Analysis:** 3 DDL orphans (display_label, weightage_percentage, sort_order) and 1 naming mismatch (DDL sort_order vs model fillable display_order).

---

## 14. Route Map — Complete

| Method | URI | Route Name | Controller |
|--------|-----|------------|------------|
| GET | /template-ia-component | template-ia-component.index | index() |
| GET | /template-ia-component/create | template-ia-component.create | create() |
| POST | /template-ia-component | template-ia-component.store | store() |
| GET | /template-ia-component/{id} | template-ia-component.show | show() |
| GET | /template-ia-component/{id}/edit | template-ia-component.edit | edit() |
| PUT/PATCH | /template-ia-component/{id} | template-ia-component.update | update() |
| DELETE | /template-ia-component/{id} | template-ia-component.destroy | destroy() |
| GET | /template-ia-component/trash/view | template-ia-component.trashed | trashed() |
| GET | /template-ia-component/{id}/restore | template-ia-component.restore | restore() |
| DELETE | /template-ia-component/{id}/force-delete | template-ia-component.forceDelete | forceDelete() |
| POST/PATCH | /template-ia-component/{id}/toggle-status | template-ia-component.toggleStatus | toggleStatus() |

---

## 15. BC-AUTH: Authorization Matrix — Complete

| ID | Permission | Methods | Blade @can | Policy |
|----|-----------|---------|------------|--------|
| BC-AUTH-01 | tenant.msh-components.view | components() | N/A | N/A |
| BC-AUTH-02 | tenant.msh-template-ia-component.view | show() | Tab + @include | view() |
| BC-AUTH-03 | tenant.msh-template-ia-component.viewAny | index(), trashed() | N/A | viewAny() |
| BC-AUTH-04 | tenant.msh-template-ia-component.create | create(), store() | Add button | create() |
| BC-AUTH-05 | tenant.msh-template-ia-component.update | edit(), update(), toggleStatus(), restore() | Action + Status | update() |
| BC-AUTH-06 | tenant.msh-template-ia-component.delete | destroy(), forceDelete() | Action | delete() |

---

## 16. UI Component Reference — Blade Patterns

| Element | Component / Pattern | Details |
|---------|-------------------|---------|
| Tab Container | x-backend.tab.nav-tab | `['id' => 'ia-components', 'permission' => 'tenant.msh-template-ia-component.view']` |
| Tab Pane | tab-pane fade | `id="ia-components-pane"` |
| Search Bar | x-backend.tab.search-bar | `url="marksheet-generation.template-ia-component"` |
| Status Switch | x-backend.table.status-switch | `url="marksheet-generation.template-ia-component"` |
| Action Buttons | x-backend.table.action | `:canView="false"` (view disabled) |
| Pagination | appends(['tab' => 'ia-components']) | `{{ $iaComponents->appends(['tab' => 'ia-components'])->links() }}` |
| Empty State | Custom div | `<i class="fa-solid fa-book"></i><p>No IA Components Found</p>` |
| Edit Modal | JS function | `editTemplateIaComponent(id, config_template_id, ia_component_type_id, max_marks, display_order, is_active)` — 6 params |

---

## 17. Cross-Entity Comparison: Scholastic vs IA vs Exam Weightage vs Coscholastic

| Aspect | Scholastic | Exam Weightage | IA | Coscholastic |
|--------|-----------|---------------|-----|-------------|
| Searchable columns | [] (none) | [] (none) | [] (none) | ['name', 'code'] |
| Weightage sum validation | **Yes** | **No** | N/A | N/A |
| DDL orphans | display_label, sort_order | None | display_label, weightage_percentage, sort_order | max_grade_points, display_label |
| Naming mismatch | None | None | DDL sort_order vs fillable display_order | None |
| HasMany child | StudentSubjectResult | StudentSubjectResult | StudentIaMark | StudentCoscholasticResult |
| Empty state icon | fa-layer-group | fa-balance-scale | fa-book | fa-star |
| Special fields | weightage_percent, max_marks | weightage_percent, max_marks | max_marks, display_order | name, code, grading_scale, is_ba_linked |
| Blade eager-load | configTemplate, sourceComponent | configTemplate | configTemplate | configTemplate |
| Tab permission prefix | .msh-template-scholastic-component | .msh-template-exam-weightage | .msh-template-ia-component | .msh-template-coscholastic-component |

---

## 18. Validation Messages Reference

| Field | Rule | Validation Message |
|-------|------|-------------------|
| config_template_id | required | "The config template id field is required." |
| config_template_id | integer | "The config template id must be an integer." |
| config_template_id | exists:msh_config_templates,id | "Selected config template is invalid." |
| ia_component_type_id | required | "The ia component type id field is required." |
| ia_component_type_id | integer | "The ia component type id must be an integer." |
| ia_component_type_id | exists:msh_ia_component_types,id | "Selected IA component type is invalid." |
| ia_component_type_id | unique with where | "The ia component type id has already been taken for this template." |
| max_marks | required | "The max marks field is required." |
| max_marks | numeric | "The max marks must be a number." |
| max_marks | min:0 | "The max marks must be a positive number." |
| max_marks | regex | "The max marks format is invalid." (max 2 decimals) |
| display_order | required | "The display order field is required." |
| display_order | integer | "The display order must be an integer." |
| display_order | min:1 | "The display order must be at least 1." |
| is_active | boolean | "The is active field must be true or false." |

---

## 19. Load Order and Query Performance Analysis

| Query # | Location | SQL Operation | Expected Rows |
|---------|----------|--------------|---------------|
| 1 | Hub line 103 | SELECT ... FROM msh_template_scholastic_components | 15 |
| 2 | Hub line 104 | SELECT ... FROM msh_template_exam_weightages | 15 |
| 3 | Hub line 105 | SELECT ... FROM msh_template_ia_components | 15 |
| 4 | Hub line 106 | SELECT ... FROM msh_template_coscholastic_components | 15 |
| 5 | Hub line 108 | SELECT ... FROM msh_config_templates WHERE is_active=1 | All active |
| 6 | Hub line 109 | SELECT ... FROM msh_source_components WHERE is_active=1 | All active |
| 7 | Hub line 110 | SELECT ... FROM lms_exam_types WHERE is_active=1 | All active |
| 8 | Hub line 111 | SELECT ... FROM msh_ia_component_types WHERE is_active=1 | All active |
| 9 | Eager load IA | SELECT ... FROM msh_config_templates WHERE id IN (...) | 1 per component |
| **Total** | **Hub page load** | **~10-12 queries** | **All eager-loaded** |

---

## 20. Complete Test Execution Procedures — IA Components

### TC-P-01: Create IA component via modal with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-template-ia-component.create` permission | Success |
| 2 | Navigate to Marksheet Generation → Components → IA Components tab | Tab loads with $iaComponents collection |
| 3 | Click "Add" button in search bar | #createTemplateIaComponentModal modal opens |
| 4 | Select Config Template from dropdown | Config template selected |
| 5 | Select IA Component Type from dropdown | IA type selected |
| 6 | Enter max_marks = "20.00" | Input accepts 20.00 |
| 7 | Enter display_order = "1" | Input accepts 1 |
| 8 | Ensure is_active toggle is ON | Active (default) |
| 9 | Click Submit/Save | AJAX POST to /template-ia-component |
| 10 | **Verify**: Gate::authorize('...create') at line 39 passes | Authorization ok |
| 11 | **Verify**: TemplateIaComponentRequest rules pass (all 5 fields validated) | No validation errors |
| 12 | **Verify**: $validatedData['created_by'] = auth()->id() | created_by set |
| 13 | **Verify**: TemplateIaComponent::create() inserts row | DB has new record |
| 14 | **Verify**: activityLog($component, 'Stored', [...]) | "A new template IA component was created." |
| 15 | **Verify**: JSON response {status: true, message: 'Template IA component created.', redirect: '...'} | Modal closes, success flash |
| 16 | **Verify**: Table refreshes — new component visible | Row appears with template, IA type, max marks 20, order 1 |

### TC-P-02: Create IA component with default display_order (auto=1)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open Add modal, fill required fields | Form complete |
| 2 | Leave display_order EMPTY | prepareForValidation() defaults to 1 |
| 3 | Submit | POST request |
| 4 | **Verify**: display_order defaulted to 1 | $this->merge(['display_order' => $this->display_order ?? 1]) |
| 5 | **Verify**: Component created with display_order=1 | DB stores 1 |

### TC-P-09: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .delete permission | Success |
| 2 | Navigate to trash page | Trashed records |
| 3 | Click "Force Delete" on component with no StudentIaMark | DELETE request |
| 4 | **Verify**: Gate::authorize('...delete') at line 160 passes | Authorized |
| 5 | **Verify**: withTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: forceDelete() succeeds (no FK violation) | Record permanently removed |
| 7 | **Verify**: activityLog($record, 'Deleted', [...]) | "The record was permanently deleted." |
| 8 | **Verify**: Redirect with "Record permanently deleted." | Success |

### TC-P-10: Force delete with FK 23000 catch (StudentIaMark reference)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentIaMark referencing ia_component_id | FK exists |
| 2 | Soft-delete component | destroy() called, now trashed |
| 3 | Navigate to trash page | Component in trash |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: forceDelete() throws QueryException with code '23000' | FK constraint violation |
| 6 | **Verify**: Catch block at line 166-170 executes | if ($e->getCode() === '23000') |
| 7 | **Verify**: "Cannot delete this record because it is referenced by other records. Remove those references first." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Remains in msh_template_ia_components |

### TC-N-01: Create with empty config_template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal, leave config_template_id empty | Required field omitted |
| 3 | Submit | POST request |
| 4 | **Verify**: required rule on config_template_id | "The config template id field is required." |
| 5 | **Verify**: No component created | DB unchanged |

### TC-N-03: Duplicate IA type per template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component exists with (config_template_id=1, ia_component_type_id=1) | Existing record |
| 2 | Create new with same config_template_id=1, ia_component_type_id=1 | Duplicate pair |
| 3 | Submit | POST request |
| 4 | **Verify**: Rule::unique('msh_template_ia_components', 'ia_component_type_id')->where('config_template_id', 1) | "The ia component type id has already been taken for this template." |
| 5 | **Verify**: No duplicate created | DB has 1 record |

### TC-N-04: max_marks negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set max_marks = "-10.00" | Negative value |
| 2 | Submit | POST |
| 3 | **Verify**: min:0 validation | "The max marks must be a positive number." |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-05: max_marks >2 decimal places

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set max_marks = "20.123" | 3 decimal places |
| 2 | Submit | POST |
| 3 | **Verify**: regex validation | "The max marks format is invalid." |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-06: display_order < 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set display_order = "0" | Below minimum |
| 2 | Submit | POST |
| 3 | **Verify**: min:1 validation | "The display order must be at least 1." |
| 4 | **Verify**: No record created | DB unchanged |

---

## 21. Service Layer Analysis — TemplateIaComponentService

### Service Method Signatures

| Method | Parameters | Transaction | Description |
|--------|-----------|-------------|-------------|
| create() | TemplateIaComponentRequest $data | DB::transaction() | Creates record, no sum validation |
| update() | TemplateIaComponent $record, array $data, int $userId | DB::transaction() | Sets updated_by, updates, no sum validation |
| delete() | TemplateIaComponent $record | DB::transaction() | Soft-deletes record |

### Service vs Controller Responsibility

| Operation | Controller | Service |
|-----------|-----------|---------|
| Authorization | Gate::authorize() | None |
| Validation | Request::validated() | None |
| created_by | Sets before calling service | Receives completed data |
| Persistence | Calls service | DB::transaction() + Eloquent |
| Logging | activityLog() after service | None |
| Response | Returns redirect/JSON | None |

---

## 22. Known Gaps and Observations

| # | Gap | Type | Impact |
|---|-----|------|--------|
| GAP-01 | DDL has `weightage_percentage` but model fillable does not include it | DDL orphan | Column never used |
| GAP-02 | DDL has `sort_order` but model uses `display_order` (different name) | Naming mismatch | Confusion — which one is authoritative? |
| GAP-03 | DDL has `display_label` but not in fillable | DDL orphan | Column never used |
| GAP-04 | `edit()` loads IaComponentTypes but discards them | Dead code | 1 extra DB query per edit |
| GAP-05 | `store()` uses direct create (no service layer) | Architectural inconsistency | Service has create() method but controller doesn't call it |
| GAP-06 | `restore()` uses hardcoded message not flash() | Inconsistency | All other CRUD methods use flash() |
| GAP-07 | `forceDelete()` uses hardcoded message not flash() | Inconsistency | Same as restore |
| GAP-08 | `index()` paginates 20, hub paginates 15 | Pagination inconsistency | Different page sizes for same data |
| GAP-09 | `trashed()` uses viewAny gate (not restore) | Permission pattern | Gold standard says restore for trash |
| GAP-10 | Blade displays raw ia_component_type_id (not name) | UX issue | Users see numeric ID not type name |

---

## 23. File Change Log

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | Initial | Full TC_List with Feature Info, Pre-conditions, Data Load, Tests | TC Team |
| 1.1 | Expansion | Added complete CODE-TRACE (13 traces), BC-BIZ-DEEP 60+ entries, additional TC-P/TC-N, TC-CR, TC-SQ, TC-INT, execution procedures, route map, DDL-to-model mapping, cross-entity comparison, validation reference, query analysis, service analysis, known gaps | TC Team |

---

## 24. Model-DDL Gap Analysis — Detailed

### DDL Columns vs Model $fillable

| # | DDL Column | DDL Type | In $fillable? | In $casts? | Notes |
|---|------------|----------|---------------|------------|-------|
| 1 | id | BIGINT PK | No | No | Auto-increment PK |
| 2 | config_template_id | BIGINT FK | **Yes** | No | FK to msh_config_templates |
| 3 | ia_component_type_id | BIGINT FK | **Yes** | No | FK to msh_ia_component_types |
| 4 | display_label | VARCHAR(255) | **No** | No | DDL orphan — not used by code |
| 5 | max_marks | DECIMAL(8,2) | **Yes** | **decimal:2** | Properly mapped |
| 6 | weightage_percentage | DECIMAL(5,2) | **No** | No | DDL orphan — not used by code |
| 7 | sort_order | INT | **No** | No | DDL orphan — not used by code (display_order used instead) |
| 8 | is_active | TINYINT(1) | **Yes** | **bool** | Properly mapped |
| 9 | created_by | BIGINT FK | **Yes** | No | Set by controller |
| 10 | updated_by | BIGINT FK | **Yes** | No | Set by controller |
| 11 | created_at | TIMESTAMP | No | No | Auto-managed |
| 12 | updated_at | TIMESTAMP | No | No | Auto-managed |
| 13 | deleted_at | TIMESTAMP | No | No | SoftDeletes trait |

### Key Findings

1. **3 DDL orphans**: display_label, weightage_percentage, sort_order — columns exist in database but application code never reads or writes them
2. **Naming mismatch**: DDL has `sort_order` but model's fillable uses `display_order` — which field does the application actually use? The blade reads `$row->display_order`, confirming `display_order` is the active field
3. **Architectural question**: Are `weightage_percentage` and `sort_order` legacy columns from a previous version? Or intended for future use? This should be confirmed with the product team
4. **display_label** exists in DDL but the blade renders `$row->iaComponentType?->name` or raw ID — display_label is completely bypassed

---

## 25. Request Validation Rules — Detailed Reference

| Field | Create (POST) Rules | Update (PUT/PATCH) Rules |
|-------|-------------------|--------------------------|
| config_template_id | required, integer, exists:msh_config_templates,id | Same |
| ia_component_type_id | required, integer, exists:msh_ia_component_types,id, Rule::unique('msh_template_ia_components', 'ia_component_type_id')->where('config_template_id', $this->config_template_id) | Same + ->ignore($this->route('template_ia_component')) |
| max_marks | required, numeric, min:0, regex:/^\d+(\.\d{1,2})?$/ | Same |
| display_order | required, integer, min:1 | Same |
| is_active | sometimes, boolean | Same |
| created_by | NOT IN REQUEST — set by controller: `$validatedData['created_by'] = auth()->id()` | NOT IN REQUEST — set by service |
| updated_by | NOT SET (null on create) | Set by service from auth()->id() |

### prepareForValidation() Logic

```
$this->merge([
    'config_template_id' => (int) $this->config_template_id,
    'ia_component_type_id' => (int) $this->ia_component_type_id,
    'display_order' => $this->display_order ?? 1,
    'is_active' => $this->boolean('is_active'),
]);
```

### authorize() Method

```
public function authorize(): bool
{
    if ($this->isMethod('POST')) {
        return Gate::allows('tenant.msh-template-ia-component.create');
    }
    return Gate::allows('tenant.msh-template-ia-component.update');
}
```

---

## 26. Policy Methods — Complete Reference

| Method | Permission String | Controller Methods Guarded |
|--------|-------------------|---------------------------|
| viewAny() | tenant.msh-template-ia-component.viewAny | index(), trashed() |
| view() | tenant.msh-template-ia-component.view | show() |
| create() | tenant.msh-template-ia-component.create | create(), store() |
| update() | tenant.msh-template-ia-component.update | edit(), update(), toggleStatus(), restore() |
| delete() | tenant.msh-template-ia-component.delete | destroy(), forceDelete() |

