# Template Coscholastic Components — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Template Coscholastic Components (msh_template_coscholastic_components) |
| **Controller** | Modules\MarksheetGeneration\Http\Controllers\TemplateCoscholasticComponentController — 11 methods — index() NOT called; tab listing uses MarksheetGenerationController@components() |
| **Tab Container Controller** | Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@components() — tab id coscholastic-components, private pplyFilters() |
| **Model** | Modules\MarksheetGeneration\Models\TemplateCoscholasticComponent — SoftDeletes, BaseModel, 4 relationships (incl. HasMany studentResults) |
| **Form Request** | Modules\MarksheetGeneration\Http\Requests\TemplateCoscholasticComponentRequest — 7 validation rules + prepareForValidation |
| **Policy** | TemplateCoscholasticComponentPolicy — permission prefix 	enant.msh-template-coscholastic-component.* |
| **Service** | TemplateCoscholasticComponentService — wraps create/update/delete in DB transactions |
| **Route Prefix** | marksheet-generation.template-coscholastic-component.* (resource) + 	rashed, estore, orceDelete, 	oggleStatus |
| **Blade Views** | pages/partials/components/_coscholastic-components.blade.php (tab partial) |
| **Tab Container** | pages/components.blade.php — tab id coscholastic-components, permission 	enant.msh-template-coscholastic-component.view |
| **DB Table** | msh_template_coscholastic_components — 14 columns |
| **Primary Screen** | Marksheet Generation → Components → Coscholastic Components tab (paginated, searchable, status-filtered, modal-based CRUD) |
| **Modal IDs** | #createTemplateCoscholasticComponentModal, #editTemplateCoscholasticComponentModal |
| **Paginator Name** | cc_page (15 per page) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must have 	enant.msh-template-coscholastic-component.* permissions |
| PC-02 | msh_template_coscholastic_components table must exist |
| PC-03 | msh_config_templates must have at least one active template |
| PC-04 | Controller registered in web routes |
| PC-05 | Policy registered in AuthServiceProvider |
| PC-06 | Tab included with @can('tenant.msh-template-coscholastic-component.view') guard |
| PC-07 | Soft deletes enabled |
| PC-08 | Service autowireable |
| PC-09 | Browser JavaScript enabled for modals |
| PC-10 | Behavioural Assessment (BA) module may or may not be installed (optional) |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | 15 per page via pplyFilters(), paginator cc_page | MarksheetGenerationController.php:106 |
| DL-02 | Search/status only when $tab === 'coscholastic-components' | Tab-aware |
| DL-03 | Search applies to ['name', 'code'] columns (non-empty searchableColumns) | MarksheetGenerationController.php:106 |
| DL-04 | Columns: **#**, **Config Template**, **Code**, **Name**, **Grading Scale**, **Status**, **Action** | _coscholastic-components.blade.php:37-49 |
| DL-05 | Code displayed as <span class="badge bg-light text-dark">{{ ->code }}</span> | Badge styling |
| DL-06 | Grading Scale displayed in small muted font | class="small" |
| DL-07 | Edit modal: editTemplateCoscholasticComponent(id, config_template_id, name, code, grading_scale, is_ba_linked, display_order, is_active) | 8 params |
| DL-08 | Shared dropdown: ConfigTemplate::where('is_active', 1)->get() only | No other dropdowns |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Coscholastic Component** | config_template_id=1, 
ame="Life Skills", code="LSKILLS", grading_scale="5-Point", display_order=1, is_ba_linked=0, is_active=1 |
| TD-02 | **Duplicate Code Per Template** | Same config_template_id + code — unique violation |
| TD-03 | **Code > 30 chars** | 31-char code — max:30 failure |
| TD-04 | **Name > 100 chars** | 101-char name — max:100 failure |
| TD-05 | **Grading Scale > 50 chars** | 51-char scale — max:50 failure |
| TD-06 | **Display Order < 1** | display_order=0 — min:1 failure |
| TD-07 | **BA Linked True** | is_ba_linked=1 — component auto-populates from BA module |
| TD-08 | **Force Delete with StudentCoscholasticResult FK** | Referenced by results — 23000 catch |
| TD-09 | **Code reuse across templates** | Same code "BEH" on two different templates — allowed |
| TD-10 | **Search by name or code** | ?search=LIFE or ?search=LSKILLS — matches name/code |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK | Auto-increment | DDL |
| BC-DB-02 | config_template_id — BIGINT, FK → msh_config_templates.id | Required FK | DDL |
| BC-DB-03 | 
ame — VARCHAR(100), NOT NULL | Human-readable name | DDL |
| BC-DB-04 | code — VARCHAR(30), NOT NULL | Short unique code per template | DDL |
| BC-DB-05 | display_label — VARCHAR(255), NULLABLE | DDL only, not fillable | DDL |
| BC-DB-06 | max_grade_points — DECIMAL(5,2), NULLABLE | DDL only, not fillable | DDL |
| BC-DB-07 | grading_scale — VARCHAR(50), NULLABLE | Descriptive scale label | DDL |
| BC-DB-08 | display_order — INT, NULLABLE | Display sequence | DDL |
| BC-DB-09 | is_ba_linked — TINYINT(1), DEFAULT 0 | BA module link | DDL |
| BC-DB-10 | is_active — TINYINT(1), DEFAULT 1 | Active flag | DDL |
| BC-DB-11 | created_by — BIGINT | Creator | DDL |
| BC-DB-12 | updated_by — BIGINT | Modifier | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | config_template_id — required, integer, exists | equired|integer|exists:msh_config_templates,id | Request |
| BC-VAL-02 | code — required, string, max:30, unique per config_template | equired|string|max:30|Rule::unique(...)->where('config_template_id', ...) | Request |
| BC-VAL-03 | 
ame — required, string, max:100 | equired|string|max:100 | Request |
| BC-VAL-04 | grading_scale — sometimes, string, max:50 | sometimes|string|max:50 | Request |
| BC-VAL-05 | display_order — required, integer, min:1 | equired|integer|min:1 | Request |
| BC-VAL-06 | is_ba_linked — sometimes, boolean | sometimes|boolean | Request |
| BC-VAL-07 | is_active — sometimes, boolean | sometimes|boolean | Request |
| BC-VAL-08 | prepareForValidation() defaults display_order to 1, casts booleans | $this->merge(['display_order' => ->display_order ?? 1]) | Request |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Source |
|----|-----------|-----------------|--------|
| BC-AUTH-01 | 	enant.msh-components.view | Hub: Gate::authorize(...) at MarksheetGenerationController.php:97 | Hub |
| BC-AUTH-02 | 	enant.msh-template-coscholastic-component.view | Blade: @can('...view') at components.blade.php:15,26 | Tab |
| BC-AUTH-03 | 	enant.msh-template-coscholastic-component.viewAny | index() line 17, 	rashed() line 135 | Controller |
| BC-AUTH-04 | 	enant.msh-template-coscholastic-component.create | create() line 28, store() line 37 | Controller |
| BC-AUTH-05 | 	enant.msh-template-coscholastic-component.update | edit() line 74, update() line 83, 	oggleStatus() line 123, estore() line 144 | Controller |
| BC-AUTH-06 | 	enant.msh-template-coscholastic-component.delete | destroy() line 108, orceDelete() line 157 | Controller |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store() sets created_by | $validatedData['created_by'] = auth()->id() | TemplateCoscholasticComponentController.php:40 |
| BC-BIZ-02 | store() dual response (JSON/AJAX) | $request->expectsJson() check | Lines 52-60 |
| BC-BIZ-03 | edit() redirects to hub tab | edirect()->route('...components.combined', ['tab' => 'coscholastic-components']) | Line 78 |
| BC-BIZ-04 | update() delegates to service | $service->update(, , auth()->id()) | Line 85 |
| BC-BIZ-05 | destroy() delegates to service | $service->delete(...) | Line 110 |
| BC-BIZ-06 | toggleStatus() inverts is_active | $record->update(['is_active' => !->is_active, 'updated_by' => auth()->id()]) | Line 126 |
| BC-BIZ-07 | forceDelete() catches FK 23000 | StudentCoscholasticResult references coscholastic_component_id | Lines 160-170 |
| BC-BIZ-08 | is_ba_linked is metadata only — no cascading validation | Simple boolean flag | Model/Request |
| BC-BIZ-09 | Code unique per template (not globally unique) | Same code allowed on different templates | Request unique rule |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | TemplateCoscholasticComponent → ConfigTemplate | elongsTo(configTemplate) | TemplateCoscholasticComponent.php:36-39 |
| BC-REL-02 | TemplateCoscholasticComponent → User (created_by) | elongsTo(createdBy) | TemplateCoscholasticComponent.php:41-44 |
| BC-REL-03 | TemplateCoscholasticComponent → User (updated_by) | elongsTo(updatedBy) | TemplateCoscholasticComponent.php:46-49 |
| BC-REL-04 | TemplateCoscholasticComponent → StudentCoscholasticResult | hasMany(studentResults, coscholastic_component_id) | TemplateCoscholasticComponent.php:51-54 |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab guarded by @can('tenant.msh-template-coscholastic-component.view') | Tab conditional | components.blade.php:15,26 |
| BC-REF-02 | Code displayed as badge: <span class="badge bg-light text-dark"> | Badge styling | _coscholastic-components.blade.php:56 |
| BC-REF-03 | Grading scale in small muted text: class="small" | Muted styling | _coscholastic-components.blade.php:58 |
| BC-REF-04 | Edit modal: editTemplateCoscholasticComponent(id, config_template_id, name, code, grading_scale, is_ba_linked, display_order, is_active) | 8 params | _coscholastic-components.blade.php:66 |
| BC-REF-05 | BA Linked not displayed in table (only in edit modal) | Hidden column | Blade |
| BC-REF-06 | Empty state: "No Coscholastic Components Found" with fa-star | Star icon | _coscholastic-components.blade.php:23-32 |
| BC-REF-07 | Search applies to name and code columns | ['name', 'code'] in pplyFilters() | MarksheetGenerationController.php:106 |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 15 per page with cc_page name | ->paginate(15, ['*'], 'cc_page') |
| BC-BIZ-DEEP-02 | Search filters on 
ame and code columns | pplyFilters() with ['name', 'code'] |
| BC-BIZ-DEEP-03 | is_ba_linked cast as ool | Model $casts |
| BC-BIZ-DEEP-04 | display_order cast as integer | Model $casts |
| BC-BIZ-DEEP-05 | is_active cast as ool | Model $casts |
| BC-BIZ-DEEP-06 | prepareForValidation() defaults display_order to 1 | $this->display_order ?? 1 |
| BC-BIZ-DEEP-07 | studentResults() HasMany relation blocks force delete | FK 23000 catch |
| BC-BIZ-DEEP-08 | max_grade_points and display_label are DDL orphans | Not in $fillable |
| BC-BIZ-DEEP-09 | Same code allowed on different templates | Rule::unique(...)->where('config_template_id', ...) scoped |
| BC-BIZ-DEEP-10 | BA Linked is NOT validated against BA module existence | No FK to BA tables |

### CODE-TRACE: Key Method Trace

#### CODE-TRACE-01: store(TemplateCoscholasticComponentRequest ) — Lines 35-61

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 37 | Gate::authorize('tenant.msh-template-coscholastic-component.create') | Authorization |
| 02 | 39 | $validatedData = ->validated() | Validate |
| 03 | 40 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 42 | $component = TemplateCoscholasticComponent::create() | Create |
| 05 | 44-46 | ctivityLog(, 'Stored', ['message' => 'A new template coscholastic component was created.']) | Log |
| 06 | 48-60 | Dual response: JSON for AJAX, redirect for normal | Modal |

#### CODE-TRACE-02: update(TemplateCoscholasticComponentRequest , ...) — Lines 81-104

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 83 | Gate::authorize('...update') | Authorization |
| 02 | 85 | $service->update(, , (int) auth()->id()) | Service update |
| 03 | 87-89 | ctivityLog(, 'Updated', ['message' => '...']) | Log |
| 04 | 91-103 | Redirect to hub tab or JSON response | Modal |

#### CODE-TRACE-03: orceDelete() — Lines 155-171

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 157 | Gate::authorize('...delete') | Authorization |
| 02 | 159 | $record = TemplateCoscholasticComponent::withTrashed()->findOrFail() | Find |
| 03 | 160-162 | 	ry { ->forceDelete(); activityLog(...); } | Delete + log |
| 04 | 163-167 | catch (QueryException ) { if (->getCode() === '23000') { error } } | FK 23000 |
| 05 | 170 | Success redirect | Hardcoded message |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create coscholastic component via modal with all fields | All fields via AJAX | Created, activityLog "Stored" |
| TC-P-02 | Create with BA Linked = true | is_ba_linked=1 | Component created with BA flag |
| TC-P-03 | Create with same code on different template | Code "BEH" on Template A and B | Both allowed (scoped unique) |
| TC-P-04 | Edit component name and code | Change name/values | Updated, log "Updated" |
| TC-P-05 | Toggle status active→inactive | Click status switch | JSON success |
| TC-P-06 | Toggle BA Linked from false to true | Edit toggle | is_ba_linked updated |
| TC-P-07 | Search by name | ?search=Life | Results filtered by name |
| TC-P-08 | Search by code | ?search=LSKILLS | Results filtered by code |
| TC-P-09 | Filter by active status | Select "Active" | Only active |
| TC-P-10 | Restore soft-deleted component | Trash → Restore | Restored, is_active=true |
| TC-P-11 | Force delete with no FK refs | No StudentCoscholasticResult | Permanently removed |
| TC-P-12 | Force delete with FK 23000 catch | Referenced by results | Error message |
| TC-P-13 | Change display_order for reordering | Edit order from 4 to 2 | Updated |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create empty config_template_id | Required field omitted | "required" |
| TC-N-02 | Create empty name | Required field omitted | "required" |
| TC-N-03 | Create empty code | Required field omitted | "required" |
| TC-N-04 | Duplicate code per template | Same template + code | "already been taken" |
| TC-N-05 | Code > 30 characters | 31 chars | "cannot exceed 30 characters" |
| TC-N-06 | Name > 100 characters | 101 chars | "cannot exceed 100 characters" |
| TC-N-07 | Grading scale > 50 characters | 51 chars | "cannot exceed 50 characters" |
| TC-N-08 | display_order < 1 | 0 | "must be at least 1" |
| TC-N-09 | Invalid config_template_id=99999 | Non-existent | "invalid" |
| TC-N-10 | Access without .viewAny | No permission | 403 |
| TC-N-11 | Store without .create | No permission | 403 |
| TC-N-12 | Force delete with FK 23000 | StudentCoscholasticResult refs | Error, not deleted |
| TC-N-13 | Restore non-trashed (active) record | Active record | 404 |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | Mass-assign non-fillable fields | Inject max_grade_points, display_label | Ignored |
| TC-SQ-02 | Tab hidden without .view | No permission | Tab not rendered |
| TC-SQ-03 | Add button hidden without .create | No permission | Button hidden |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | DDL orphan columns not used | max_grade_points, display_label in DDL but not fillable | No code sets them |
| TC-INT-02 | StudentCoscholasticResult FK blocks force delete | Referenced component | 23000 catch |
| TC-INT-03 | BA Linked optional — no FK validation | is_ba_linked=true with no BA module | Accepted (metadata only) |
| TC-INT-04 | Code uniqueness per template verified | Template A: code "X" ok, Template B: code "X" also ok | Both allowed |
| TC-INT-05 | Same code rejected twice on same template | Template A: "X" then "X" again | Unique violation |

## 7. Detailed Test Execution Procedures

### TC-P-14: Create coscholastic component via modal with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Navigate to Components → Coscholastic Components tab | Tab loads |
| 3 | Click "Add" | #createTemplateCoscholasticComponentModal opens |
| 4 | Select Config Template | Template selected |
| 5 | Enter name = "Life Skills" | Human-readable name |
| 6 | Enter code = "LSKILLS" | Short code |
| 7 | Enter grading_scale = "5-Point" | Scale description |
| 8 | Set display_order = 1 | Sequence number |
| 9 | Toggle is_ba_linked = OFF | Not BA-linked |
| 10 | Ensure is_active = ON | Active |
| 11 | Click Submit | AJAX POST |
| 12 | **Verify**: Gate::authorize('...create') at line 37 passes | Authorized |
| 13 | **Verify**: Request validates all 7 fields | No errors |
| 14 | **Verify**: $validatedData['created_by'] = auth()->id() | Set |
| 15 | **Verify**: TemplateCoscholasticComponent::create() inserts | DB record |
| 16 | **Verify**: activityLog($component, 'Stored', [...]) | "A new template coscholastic component was created." |
| 17 | **Verify**: JSON success response | Modal closes |
| 18 | **Verify**: Component visible in table | Row with badge code + name |

### TC-P-15: Create with BA Linked = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_ba_linked = ON | BA linkage flag |
| 2 | Submit | POST request |
| 3 | **Verify**: is_ba_linked=1 stored | DB flag set |
| 4 | **Verify**: No BA module FK validation | Metadata only |

### TC-P-16: Create with same code on different templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create code "BEH" on Template A | Success |
| 2 | Create code "BEH" on Template B | **Allowed** — scoped unique |
| 3 | **Verify**: Both records exist | Two rows, different templates |

### TC-P-17: Edit component name and code via modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Click edit icon on row | editTemplateCoscholasticComponent(id, config_template_id, name, code, grading_scale, is_ba_linked, display_order, is_active) |
| 3 | **Verify**: Edit modal pre-filled with 8 params | All current values |
| 4 | Change name, code | Updated |
| 5 | Click Submit | PATCH via AJAX |
| 6 | **Verify**: $service->update() called | Transaction |
| 7 | **Verify**: activityLog($record, 'Updated', [...]) | "The template coscholastic component was updated." |
| 8 | **Verify**: JSON redirect to hub tab | Success |

### TC-P-18: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on active component | AJAX POST |
| 2 | **Verify**: Gate::authorize('...update') at line 123 passes | Authorized |
| 3 | **Verify**: is_active inverted from 1 to 0 | !$record->is_active |
| 4 | **Verify**: JSON {success: true, is_active: false} | Toggle OFF |

### TC-P-19: Toggle status inactive→active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click status toggle on inactive component | AJAX POST |
| 2 | **Verify**: is_active inverted from 0 to 1 | Reactivated |
| 3 | **Verify**: JSON {success: true, is_active: true} | Toggle ON |

### TC-P-20: Search by name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "Life" in search box | ?search=Life |
| 2 | Submit | GET with ?tab=coscholastic-components&search=Life |
| 3 | **Verify**: $tab check passes | Filters applied |
| 4 | **Verify**: Search applied to name column | "Life Skills" shown |
| 5 | **Verify**: OR clause on code column | Codes with "LIFE" also shown |

### TC-P-21: Search by code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "LSKILLS" in search | ?search=LSKILLS |
| 2 | Submit | Filtered by code |
| 3 | **Verify**: Only component with code LSKILLS shown | Exact match (LIKE) |

### TC-P-22: Filter by active status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Active" from filter | status=1 |
| 2 | Submit | Only active shown |

### TC-P-23: Filter by inactive status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" from filter | status=0 |
| 2 | Submit | Only inactive shown |

### TC-P-24: Restore soft-deleted component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to trash | Trashed records |
| 3 | Click "Restore" | GET to restore |
| 4 | **Verify**: onlyTrashed()->findOrFail($id) | Found |
| 5 | **Verify**: restore() + update(['is_active' => true]) | Reactivated |
| 6 | **Verify**: activityLog($record, 'Restored', [...]) | "The record was restored." |
| 7 | **Verify**: Redirect with "Record restored successfully." | Hardcoded |

### TC-P-25: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash | Trashed record |
| 2 | Click "Force Delete" | DELETE |
| 3 | **Verify**: forceDelete() succeeds | Permanently removed |
| 4 | **Verify**: activityLog($record, 'Deleted', [...]) | "The record was permanently deleted." |
| 5 | **Verify**: Redirect "Record permanently deleted." | Success |

### TC-P-26: Force delete with FK 23000 catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentCoscholasticResult refs | FK exists |
| 2 | Soft-delete → trash | In trash |
| 3 | Click "Force Delete" | DELETE |
| 4 | **Verify**: QueryException 23000 caught | Error displayed |
| 5 | **Verify**: "Cannot delete this record..." | User-friendly |
| 6 | **Verify**: Record NOT deleted | Remains |

### TC-P-27: Pagination — page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 16+ components | 2+ pages |
| 2 | Click page 2 | GET with ?tab=coscholastic-components&cc_page=2 |
| 3 | **Verify**: paginate(15, ['*'], 'cc_page') | Records 16-30 |

---

### TC-N: Negative Test Cases (Additional)

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-14 | Create with code > 30 chars | 31-char code | "cannot exceed 30 characters" |
| TC-N-15 | Create with name > 100 chars | 101-char name | "cannot exceed 100 characters" |
| TC-N-16 | Create with grading_scale > 50 chars | 51-char scale | "cannot exceed 50 characters" |
| TC-N-17 | Create with display_order=0 | min:1 fails | "must be at least 1" |
| TC-N-18 | Create with config_template_id="abc" | integer fails | "must be an integer" |
| TC-N-19 | Submit is_active=2 | boolean fails | "must be true or false" |
| TC-N-20 | Submit is_ba_linked=2 | boolean fails | "must be true or false" |
| TC-N-21 | Duplicate code within same template | Same template + code | "already been taken for this template" |
| TC-N-22 | Same code on different template | Different template | **Allowed** |
| TC-N-23 | Access without .viewAny | No permission | 403 |
| TC-N-24 | Store without .create | No permission | 403 |
| TC-N-25 | Access edit() without .update | No permission | 403 |
| TC-N-26 | Access destroy() without .delete | No permission | 403 |
| TC-N-27 | Restore non-trashed (active) record | onlyTrashed() empty | 404 |
| TC-N-28 | Show non-existent ID 99999 | Route-binding 404 | 404 |
| TC-N-29 | Store with empty body | All fields missing | 422 errors |
| TC-N-30 | Inject max_grade_points via mass-assignment | Not in $fillable | Ignored |

---

## 8. BC-BIZ-DEEP: Extended Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-11 | `store()` uses direct Eloquent create | `TemplateCoscholasticComponent::create($validatedData)` |
| BC-BIZ-DEEP-12 | `update()` delegates to service with transaction | `$service->update($record, $data, auth()->id())` |
| BC-BIZ-DEEP-13 | `destroy()` delegates to service soft-delete | `$service->delete($record)` |
| BC-BIZ-DEEP-14 | `index()` standalone uses 20 per page, hub uses 15 | Pagination inconsistency |
| BC-BIZ-DEEP-15 | `trashed()` uses 15 per page | Matches hub |
| BC-BIZ-DEEP-16 | `toggleStatus()` uses manual findOrFail($id) | Not route-binding |
| BC-BIZ-DEEP-17 | `toggleStatus()` inverts is_active | `!$record->is_active` |
| BC-BIZ-DEEP-18 | `restore()` uses onlyTrashed()->findOrFail() | Trash scope |
| BC-BIZ-DEEP-19 | `restore()` sets is_active=true | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-20 | `forceDelete()` uses withTrashed()->findOrFail() | Any record scope |
| BC-BIZ-DEEP-21 | `forceDelete()` catches QueryException 23000 | FK violation |
| BC-BIZ-DEEP-22 | `forceDelete()` re-throws non-23000 | `throw $e` |
| BC-BIZ-DEEP-23 | `forceDelete()` activityLog inside try | Only on success |
| BC-BIZ-DEEP-24 | `edit()` redirects to hub (no standalone view) | Modal-based pattern |
| BC-BIZ-DEEP-25 | `edit()` loads ConfigTemplates but discards (dead code) | Unused query |
| BC-BIZ-DEEP-26 | `store()` has created_by, NOT updated_by | updated_by null |
| BC-BIZ-DEEP-27 | `update()` sets updated_by via service | `(int) auth()->id()` |
| BC-BIZ-DEEP-28 | `store()` dual response: JSON vs redirect | `$request->expectsJson()` |
| BC-BIZ-DEEP-29 | `show()` loads configTemplate relation | `$record->load('configTemplate')` |
| BC-BIZ-DEEP-30 | Code displayed as badge in blade | `<span class="badge bg-light text-dark">` |
| BC-BIZ-DEEP-31 | Grading scale displayed in small muted text | `class="small"` |
| BC-BIZ-DEEP-32 | is_ba_linked NOT displayed in table (only in edit modal) | Hidden column |
| BC-BIZ-DEEP-33 | Search applies to name AND code columns | `['name', 'code']` |
| BC-BIZ-DEEP-34 | Model $casts: is_ba_linked bool, display_order int, is_active bool | Proper casting |
| BC-BIZ-DEEP-35 | Model uses BaseModel | Extends `App\Models\BaseModel` |
| BC-BIZ-DEEP-36 | Model has studentResults() HasMany | Blocks force delete |
| BC-BIZ-DEEP-37 | `trashed()` gate uses viewAny | `Gate::authorize('...viewAny')` |
| BC-BIZ-DEEP-38 | `restore()` gate uses update | `Gate::authorize('...update')` |
| BC-BIZ-DEEP-39 | `restore()` hardcoded success message | "Record restored successfully." |
| BC-BIZ-DEEP-40 | `forceDelete()` hardcoded success message | "Record permanently deleted." |
| BC-BIZ-DEEP-41 | Tab @can uses 'tenant.msh-template-coscholastic-component.view' | Tab visibility |
| BC-BIZ-DEEP-42 | Paginator name cc_page unique per tab | Prevents conflict |
| BC-BIZ-DEEP-43 | Tab-aware filtering checks $tab === 'coscholastic-components' | Scoped |
| BC-BIZ-DEEP-44 | prepareForValidation() defaults display_order to 1 | `$this->display_order ?? 1` |
| BC-BIZ-DEEP-45 | DDL has max_grade_points and display_label (not fillable) | DDL orphans |
| BC-BIZ-DEEP-46 | Code unique per template (not globally unique) | `Rule::unique(...)->where('config_template_id', ...)` |
| BC-BIZ-DEEP-47 | is_ba_linked is metadata only — no FK to BA tables | Simple boolean |
| BC-BIZ-DEEP-48 | BA Linked not validated against BA module existence | No cross-module check |
| BC-BIZ-DEEP-49 | Edit modal JS: 8 params | editTemplateCoscholasticComponent(id, config_template_id, name, code, grading_scale, is_ba_linked, display_order, is_active) |
| BC-BIZ-DEEP-50 | Empty state: "No Coscholastic Components Found" with fa-star | Custom empty state |
| BC-BIZ-DEEP-51 | Action column :canView="false" | Only edit + delete |
| BC-BIZ-DEEP-52 | studentResults() HasMany blocks force delete | FK 23000 |
| BC-BIZ-DEEP-53 | store() redirects to show page for non-AJAX | route('...show', $component) |
| BC-BIZ-DEEP-54 | destroy/update redirect to hub tab | route('...components.combined', ['tab' => 'coscholastic-components']) |
| BC-BIZ-DEEP-55 | restore/forceDelete redirect to trash | route('...template-coscholastic-component.trashed') |
| BC-BIZ-DEEP-56 | toggleStatus() hardcoded messages | "Status set to Active/Inactive" |
| BC-BIZ-DEEP-57 | activityLog 5 event types | Stored, Updated, Deleted, Toggled, Restored |
| BC-BIZ-DEEP-58 | activityLog missing performed_by on Restored | Only message key |
| BC-BIZ-DEEP-59 | findOrFail() throws ModelNotFoundException → 404 | Default Laravel |
| BC-BIZ-DEEP-60 | withQueryString() preserves tab/filter params | Correct pagination |

---

## 9. Code Trace — Complete Method Traces

#### CODE-TRACE-03: index() — Lines 15-24 (Standalone)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 17 | Gate::authorize('tenant.msh-template-coscholastic-component.viewAny') | Authorization |
| 02 | 19-21 | TemplateCoscholasticComponent::with('configTemplate')->latest()->paginate(20) | Query + 20 per page |
| 03 | 23 | return view('marksheetgeneration::template-coscholastic-component.index', compact('components')) | View |

#### CODE-TRACE-04: show(TemplateCoscholasticComponent $templateCoscholasticComponent) — Lines 63-70

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 65 | Gate::authorize('tenant.msh-template-coscholastic-component.view') | Authorization |
| 02 | 67 | $templateCoscholasticComponent->load('configTemplate') | Eager-load |
| 03 | 69 | return view(...) | Show view |

#### CODE-TRACE-05: create() — Lines 26-33

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 28 | Gate::authorize('tenant.msh-template-coscholastic-component.create') | Authorization |
| 02 | 30 | ConfigTemplate::where('is_active', true)->get() | Load templates |
| 03 | 32 | return view('marksheetgeneration::template-coscholastic-component.create', compact('configTemplates')) | View |

#### CODE-TRACE-06: store(TemplateCoscholasticComponentRequest $request) — Lines 35-61

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 37 | Gate::authorize('tenant.msh-template-coscholastic-component.create') | Authorization |
| 02 | 39 | $validatedData = $request->validated() | Validate |
| 03 | 40 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 42 | $component = TemplateCoscholasticComponent::create($validatedData) | Direct create |
| 05 | 44-46 | activityLog($component, 'Stored', ['message' => '...']) | Log |
| 06 | 48-60 | Dual response: JSON for AJAX, redirect for normal | Modal support |

#### CODE-TRACE-07: edit(TemplateCoscholasticComponent $templateCoscholasticComponent) — Lines 72-79

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 74 | Gate::authorize('tenant.msh-template-coscholastic-component.update') | Authorization |
| 02 | 76 | ConfigTemplate::where('is_active', true)->get() (dead code) | Unused |
| 03 | 78 | return redirect()->route('...components.combined', ['tab' => 'coscholastic-components']) | Redirect |

#### CODE-TRACE-08: update(TemplateCoscholasticComponentRequest $request, ..., TemplateCoscholasticComponentService $service) — Lines 81-104

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 83 | Gate::authorize('tenant.msh-template-coscholastic-component.update') | Authorization |
| 02 | 85 | $service->update($templateCoscholasticComponent, $request->validated(), (int) auth()->id()) | Service update |
| 03 | 87-89 | activityLog($templateCoscholasticComponent, 'Updated', ['message' => '...']) | Log |
| 04 | 91-103 | Dual response: redirect to hub tab or JSON | Modal |

#### CODE-TRACE-09: destroy(TemplateCoscholasticComponent $templateCoscholasticComponent, TemplateCoscholasticComponentService $service) — Lines 106-119

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 108 | Gate::authorize('tenant.msh-template-coscholastic-component.delete') | Authorization |
| 02 | 110 | $service->delete($templateCoscholasticComponent) | Soft-delete |
| 03 | 112-114 | activityLog($templateCoscholasticComponent, 'Deleted', ['message' => '...']) | Log |
| 04 | 116-118 | Redirect to hub tab with flash | Success |

#### CODE-TRACE-10: toggleStatus($id) — Lines 121-131

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 123 | Gate::authorize('tenant.msh-template-coscholastic-component.update') | Authorization |
| 02 | 125 | $record = TemplateCoscholasticComponent::findOrFail($id) | Find |
| 03 | 126 | $record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()]) | Toggle |
| 04 | 128 | activityLog($record, 'Toggled', ['message' => 'Status was toggled.']) | Log |
| 05 | 130 | return response()->json([...]) | JSON |

#### CODE-TRACE-11: trashed() — Lines 133-140

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 135 | Gate::authorize('tenant.msh-template-coscholastic-component.viewAny') | Authorization |
| 02 | 137 | TemplateCoscholasticComponent::onlyTrashed()->latest()->paginate(15) | Trashed |
| 03 | 139 | return view(...) | View |

#### CODE-TRACE-12: restore($id) — Lines 142-153

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 144 | Gate::authorize('tenant.msh-template-coscholastic-component.update') | Authorization |
| 02 | 146 | $record = TemplateCoscholasticComponent::onlyTrashed()->findOrFail($id) | Find trashed |
| 03 | 147 | $record->restore() | Restore |
| 04 | 148 | $record->update(['is_active' => true]) | Reactivate |
| 05 | 150 | activityLog($record, 'Restored', ['message' => 'The record was restored.']) | Log |
| 06 | 152 | return redirect()->route('...trashed')->with('success', 'Record restored successfully.') | Redirect |

#### CODE-TRACE-13: forceDelete($id) — Lines 155-171

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 157 | Gate::authorize('tenant.msh-template-coscholastic-component.delete') | Authorization |
| 02 | 159 | $record = TemplateCoscholasticComponent::withTrashed()->findOrFail($id) | Find any |
| 03 | 160-162 | try { forceDelete(); activityLog(...); } | Delete + log |
| 04 | 163-167 | catch (QueryException $e) { if (23000) { error } throw $e; } | FK 23000 |
| 05 | 170 | return redirect()->route('...trashed')->with('success', 'Record permanently deleted.') | Success |

---

## 10. Additional Code Review Test Cases (TC-CR)

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Gate::authorize in index() | Line 17 | tenant.msh-template-coscholastic-component.viewAny |
| TC-CR-02 | Gate::authorize in create() | Line 28 | tenant.msh-template-coscholastic-component.create |
| TC-CR-03 | Gate::authorize in store() | Line 37 | tenant.msh-template-coscholastic-component.create |
| TC-CR-04 | Gate::authorize in show() | Line 65 | tenant.msh-template-coscholastic-component.view |
| TC-CR-05 | Gate::authorize in edit() | Line 74 | tenant.msh-template-coscholastic-component.update |
| TC-CR-06 | Gate::authorize in update() | Line 83 | tenant.msh-template-coscholastic-component.update |
| TC-CR-07 | Gate::authorize in destroy() | Line 108 | tenant.msh-template-coscholastic-component.delete |
| TC-CR-08 | Gate::authorize in toggleStatus() | Line 123 | tenant.msh-template-coscholastic-component.update |
| TC-CR-09 | Gate::authorize in trashed() | Line 135 | tenant.msh-template-coscholastic-component.viewAny |
| TC-CR-10 | Gate::authorize in restore() | Line 144 | tenant.msh-template-coscholastic-component.update |
| TC-CR-11 | Gate::authorize in forceDelete() | Line 157 | tenant.msh-template-coscholastic-component.delete |
| TC-CR-12 | activityLog in store() | Lines 44-46 | "A new template coscholastic component was created." |
| TC-CR-13 | activityLog in update() | Lines 87-89 | "The template coscholastic component was updated." |
| TC-CR-14 | activityLog in destroy() | Lines 112-114 | "The template coscholastic component was deleted." |
| TC-CR-15 | activityLog in toggleStatus() | Line 128 | "Status was toggled." |
| TC-CR-16 | activityLog in restore() | Line 150 | "The record was restored." |
| TC-CR-17 | activityLog in forceDelete() | Line 162 | "The record was permanently deleted." |
| TC-CR-18 | store() uses direct create NOT service | Line 42 | Direct Eloquent |
| TC-CR-19 | update() delegates to service | Line 85 | $service->update(...) |
| TC-CR-20 | destroy() delegates to service | Line 110 | $service->delete(...) |
| TC-CR-21 | store() sets created_by | Line 40 | $validatedData['created_by'] = auth()->id() |
| TC-CR-22 | restore() sets is_active=true | Line 148 | $record->update(['is_active' => true]) |
| TC-CR-23 | toggleStatus() inverts is_active | Line 126 | !$record->is_active |
| TC-CR-24 | toggleStatus() sets updated_by | Line 126 | 'updated_by' => auth()->id() |
| TC-CR-25 | studentResults() HasMany exists | Model lines 51-54 | Blocks force delete |
| TC-CR-26 | $casts: is_ba_linked bool | Model line 31 | Boolean |
| TC-CR-27 | $casts: display_order integer | Model line 32 | Integer |
| TC-CR-28 | $casts: is_active bool | Model line 33 | Boolean |
| TC-CR-29 | $fillable excludes max_grade_points, display_label | Model lines 18-28 | DDL orphans |
| TC-CR-30 | edit() redirects, no standalone view | Line 78 | Redirect to hub tab |

---

## 11. Additional Security (TC-SQ) & Integration (TC-INT) Tests

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-04 | CSRF on store() — no token | 419 | Page Expired |
| TC-SQ-05 | Mass-assign DDL orphans (max_grade_points, display_label) | Injected | Ignored |
| TC-SQ-06 | Tab hidden without .view permission | No permission | Not rendered |
| TC-SQ-07 | is_ba_linked ignores BA module absence | Set true, BA missing | Accepted (metadata only) |
| TC-INT-04 | ConfigTemplate FK restriction | Delete template with components | FK CASCADE/RESTRICT |
| TC-INT-05 | StudentCoscholasticResult FK blocks force delete | Has references | 23000 catch |
| TC-INT-06 | Transaction rollback on service failure | Update throws | No partial state |
| TC-INT-07 | Modal AJAX 422 on invalid data | Bad POST | JSON errors |
| TC-INT-08 | Code uniqueness per template verified | Same code, two templates | Both allowed |
| TC-INT-09 | Same code rejected twice on same template | Duplicate on same template | Blocked |

---

## 12. Hub Controller Components() Method Deep Trace

### CODE-TRACE-HUB-CC: MarksheetGenerationController::components() — Coscholastic Tab Dispatch

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 97 | Gate::authorize('tenant.msh-components.view') | Hub gate |
| 02 | 99-101 | $search, $status, $tab = request('tab', 'scholastic-components') | Params |
| 03 | 106 | $coscholasticComponents = $this->applyFilters(TemplateCoscholasticComponent::with('configTemplate'), $tab === 'coscholastic-components' ? $search : null, $tab === 'coscholastic-components' ? $status : null, ['name', 'code'])->paginate(15, ['*'], 'cc_page') | CC query (searchable name+code) |
| 04 | 108 | Shared dropdown: configTemplates only | Singular dropdown |
| 05 | 113-116 | return view('marksheetgeneration::pages.components', compact(...)) | Hub view |

### applyFilters() for coscholastic tab (note: searchableColumns = ['name', 'code']):

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 304 | applyFilters($query, ?string $search, ?string $status, array $searchableColumns) | Signature |
| 02 | 306-311 | if ($search && !empty($searchableColumns)) { $q->orWhere('name', 'like', "%{$search}%")->orWhere('code', 'like', "%{$search}%") } | Search on name AND code |
| 03 | 314-316 | if ($status !== null) { where('is_active', (int) $status) } | Status filter |
| 04 | 318 | return $query->latest() | Latest ordering |

---

## 13. BC-DB: Database Conditions — Complete

| ID | Column | Type | Constraints | Source |
|----|--------|------|-------------|--------|
| BC-DB-01 | id | BIGINT | PK, AUTO_INCREMENT | DDL |
| BC-DB-02 | config_template_id | BIGINT | NOT NULL, FK → msh_config_templates.id | DDL |
| BC-DB-03 | name | VARCHAR(100) | NOT NULL | DDL |
| BC-DB-04 | code | VARCHAR(30) | NOT NULL, unique per config_template | DDL |
| BC-DB-05 | display_label | VARCHAR(255) | NULLABLE (DDL orphan) | DDL |
| BC-DB-06 | max_grade_points | DECIMAL(5,2) | NULLABLE (DDL orphan) | DDL |
| BC-DB-07 | grading_scale | VARCHAR(50) | NULLABLE | DDL |
| BC-DB-08 | display_order | INT | NULLABLE | DDL |
| BC-DB-09 | is_ba_linked | TINYINT(1) | DEFAULT 0 | DDL |
| BC-DB-10 | is_active | TINYINT(1) | DEFAULT 1 | DDL |
| BC-DB-11 | created_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-12 | updated_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-13 | created_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-14 | updated_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-15 | deleted_at | TIMESTAMP | NULLABLE | DDL |

**DDL-to-Model Mapping:**

| DDL Column | In $fillable? | In $casts? | Notes |
|------------|---------------|------------|-------|
| id | No | No | PK |
| config_template_id | **Yes** | No | FK |
| name | **Yes** | No | Human-readable name |
| code | **Yes** | No | Short unique per template |
| display_label | **No** | No | DDL orphan |
| max_grade_points | **No** | No | DDL orphan |
| grading_scale | **Yes** | No | Descriptive label |
| display_order | **Yes** | integer | Casted to int |
| is_ba_linked | **Yes** | bool | Boolean flag |
| is_active | **Yes** | bool | Boolean flag |
| created_by | **Yes** | No | Set by controller |
| updated_by | **Yes** | No | Set by controller |

**GAP Analysis:** 2 DDL orphans (display_label, max_grade_points).

---

## 14. Route Map — Complete

| Method | URI | Route Name | Controller |
|--------|-----|------------|------------|
| GET | /template-coscholastic-component | template-coscholastic-component.index | index() |
| GET | /template-coscholastic-component/create | template-coscholastic-component.create | create() |
| POST | /template-coscholastic-component | template-coscholastic-component.store | store() |
| GET | /template-coscholastic-component/{id} | template-coscholastic-component.show | show() |
| GET | /template-coscholastic-component/{id}/edit | template-coscholastic-component.edit | edit() |
| PUT/PATCH | /template-coscholastic-component/{id} | template-coscholastic-component.update | update() |
| DELETE | /template-coscholastic-component/{id} | template-coscholastic-component.destroy | destroy() |
| GET | /template-coscholastic-component/trash/view | template-coscholastic-component.trashed | trashed() |
| GET | /template-coscholastic-component/{id}/restore | template-coscholastic-component.restore | restore() |
| DELETE | /template-coscholastic-component/{id}/force-delete | template-coscholastic-component.forceDelete | forceDelete() |
| POST/PATCH | /template-coscholastic-component/{id}/toggle-status | template-coscholastic-component.toggleStatus | toggleStatus() |

---

## 15. BC-AUTH: Authorization Matrix — Complete

| ID | Permission | Methods | Blade @can | Policy |
|----|-----------|---------|------------|--------|
| BC-AUTH-01 | tenant.msh-components.view | components() | N/A | N/A |
| BC-AUTH-02 | tenant.msh-template-coscholastic-component.view | show() | Tab + @include | view() |
| BC-AUTH-03 | tenant.msh-template-coscholastic-component.viewAny | index(), trashed() | N/A | viewAny() |
| BC-AUTH-04 | tenant.msh-template-coscholastic-component.create | create(), store() | Add button | create() |
| BC-AUTH-05 | tenant.msh-template-coscholastic-component.update | edit(), update(), toggleStatus(), restore() | Action + Status | update() |
| BC-AUTH-06 | tenant.msh-template-coscholastic-component.delete | destroy(), forceDelete() | Action | delete() |

---

## 16. UI Component Reference — Blade Patterns

| Element | Component / Pattern | Details |
|---------|-------------------|---------|
| Tab Container | x-backend.tab.nav-tab | `['id' => 'coscholastic-components', 'permission' => 'tenant.msh-template-coscholastic-component.view']` |
| Tab Pane | tab-pane fade | `id="coscholastic-components-pane"` |
| Search Bar | x-backend.tab.search-bar | `url="marksheet-generation.template-coscholastic-component"` |
| Code Display | `<span class="badge bg-light text-dark">{{ $row->code }}</span>` | Badge styling |
| Grading Scale | `<small class="text-muted">{{ $row->grading_scale }}</small>` | Muted small text |
| Status Switch | x-backend.table.status-switch | `url="marksheet-generation.template-coscholastic-component"` |
| Action Buttons | x-backend.table.action | `:canView="false"` (view disabled) |
| Pagination | appends(['tab' => 'coscholastic-components']) | `{{ $coscholasticComponents->appends(['tab' => 'coscholastic-components'])->links() }}` |
| Empty State | Custom div | `<i class="fa-solid fa-star"></i><p>No Coscholastic Components Found</p>` |
| Edit Modal | JS function | `editTemplateCoscholasticComponent(id, config_template_id, name, code, grading_scale, is_ba_linked, display_order, is_active)` — **8 params** |

---

## 17. Cross-Entity Comparison: Scholastic vs Exam Weightage vs IA vs Coscholastic

| Aspect | Scholastic | Exam Weightage | IA | Coscholastic |
|--------|-----------|---------------|-----|-------------|
| Searchable columns | [] | [] | [] | **['name', 'code']** |
| Weightage sum validation | **Yes** | No | N/A | N/A |
| DDL orphans | display_label, sort_order | None | display_label, weightage_percentage, sort_order | max_grade_points, display_label |
| HasMany child | StudentSubjectResult | StudentSubjectResult | StudentIaMark | StudentCoscholasticResult |
| Empty state icon | fa-layer-group | fa-balance-scale | fa-book | **fa-star** |
| Edit modal params | 6 | 6 | 6 | **8** (adds name, code, grading_scale, is_ba_linked) |
| Unique constraint | source_component_id per template | exam_type_id per template | ia_component_type_id per template | **code** per template |
| Special field | weightage_percent, max_marks | weightage_percent, max_marks | max_marks, display_order | name, code, grading_scale, is_ba_linked |
| Blade eager-load | configTemplate, sourceComponent | configTemplate | configTemplate | configTemplate |
| Tab permission prefix | .msh-template-scholastic-component | .msh-template-exam-weightage | .msh-template-ia-component | .msh-template-coscholastic-component |
| BA module linked | No | No | No | **Yes** (is_ba_linked) |

---

## 18. Validation Messages Reference

| Field | Rule | Validation Message |
|-------|------|-------------------|
| config_template_id | required | "The config template id field is required." |
| config_template_id | integer | "The config template id must be an integer." |
| config_template_id | exists:msh_config_templates,id | "Selected config template is invalid." |
| code | required | "The code field is required." |
| code | string | "The code must be a string." |
| code | max:30 | "Code cannot exceed 30 characters." |
| code | unique with where | "The code has already been taken for this template." |
| name | required | "The name field is required." |
| name | string | "The name must be a string." |
| name | max:100 | "Name cannot exceed 100 characters." |
| grading_scale | string | "The grading scale must be a string." |
| grading_scale | max:50 | "Grading scale cannot exceed 50 characters." |
| display_order | required | "The display order field is required." |
| display_order | integer | "The display order must be an integer." |
| display_order | min:1 | "The display order must be at least 1." |
| is_ba_linked | boolean | "The is ba linked field must be true or false." |
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
| 9 | Eager load CC | SELECT ... FROM msh_config_templates WHERE id IN (...) | 1 per component |
| **Total** | **Hub page load** | **~10-12 queries** | **All eager-loaded** |

---

## 20. Complete Test Execution Procedures — Coscholastic Components

### TC-P-01: Create coscholastic component via modal with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-template-coscholastic-component.create` permission | Success |
| 2 | Navigate to Marksheet Generation → Components → Coscholastic Components tab | Tab loads with $coscholasticComponents collection |
| 3 | Click "Add" button in search bar | #createTemplateCoscholasticComponentModal modal opens |
| 4 | Select Config Template from dropdown | Config template selected |
| 5 | Enter name = "Life Skills" | Name input accepted |
| 6 | Enter code = "LSKILLS" | Code input accepted |
| 7 | Enter grading_scale = "5-Point" | Scale input accepted |
| 8 | Enter display_order = "1" | Order input accepted |
| 9 | Toggle is_ba_linked OFF | Not BA-linked |
| 10 | Ensure is_active ON | Active |
| 11 | Click Submit/Save | AJAX POST to /template-coscholastic-component |
| 12 | **Verify**: Gate::authorize('...create') at line 37 passes | Authorization ok |
| 13 | **Verify**: TemplateCoscholasticComponentRequest rules pass (all 7 fields) | No validation errors |
| 14 | **Verify**: $validatedData['created_by'] = auth()->id() | created_by set |
| 15 | **Verify**: TemplateCoscholasticComponent::create() inserts row | DB has new record |
| 16 | **Verify**: activityLog($component, 'Stored', [...]) | "A new template coscholastic component was created." |
| 17 | **Verify**: JSON response {status: true, message: 'Template coscholastic component created.'} | Modal closes, success flash |
| 18 | **Verify**: Table refreshes — new component visible | Row appears with badge code, name, scale |

### TC-P-10: Restore soft-deleted coscholastic component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to trash page | onlyTrashed() records |
| 3 | Click "Restore" on a trashed component | GET to restore route |
| 4 | **Verify**: Gate::authorize('...update') at line 144 passes | Authorized |
| 5 | **Verify**: onlyTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: $record->restore() | deleted_at = NULL |
| 7 | **Verify**: $record->update(['is_active' => true]) | Component reactivated |
| 8 | **Verify**: activityLog($record, 'Restored', [...]) | "The record was restored." |
| 9 | **Verify**: Redirect to trash with "Record restored successfully." | Hardcoded message |
| 10 | Navigate to Coscholastic Components tab | Component visible (active) |

### TC-P-11: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .delete permission | Success |
| 2 | Navigate to trash page | Trashed records |
| 3 | Click "Force Delete" on component with no StudentCoscholasticResult | DELETE request |
| 4 | **Verify**: Gate::authorize('...delete') at line 157 passes | Authorized |
| 5 | **Verify**: withTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: forceDelete() succeeds (no FK violation) | Record permanently removed |
| 7 | **Verify**: activityLog($record, 'Deleted', [...]) | "The record was permanently deleted." |
| 8 | **Verify**: Redirect to trash with "Record permanently deleted." | Success |

### TC-P-12: Force delete with FK 23000 catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component has StudentCoscholasticResult referencing coscholastic_component_id | FK exists |
| 2 | Soft-delete component | Trashed |
| 3 | Navigate to trash | Component visible |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: forceDelete() throws QueryException '23000' | FK violation |
| 6 | **Verify**: Catch block at line 163-167 executes | if ($e->getCode() === '23000') |
| 7 | **Verify**: "Cannot delete this record because it is referenced by other records." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Still in DB |

### TC-N-01: Create with empty config_template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal, leave config_template_id empty | Required omitted |
| 3 | Submit | POST |
| 4 | **Verify**: required rule | "The config template id field is required." |
| 5 | **Verify**: No record created | DB unchanged |

### TC-N-04: Duplicate code per template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure component exists with code "LSKILLS" on Template T1 | Existing |
| 2 | Create new with same config_template_id=T1, code="LSKILLS" | Duplicate |
| 3 | Submit | POST |
| 4 | **Verify**: Rule::unique('msh_template_coscholastic_components', 'code')->where('config_template_id', T1) | "The code has already been taken for this template." |
| 5 | **Verify**: No duplicate created | DB has 1 record with that code+templat |

### TC-N-05: Code > 30 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set code = "ABCDEFGHIJKLMNOPQRSTUVWXYZ12345" (31 chars) | Exceeds 30 |
| 2 | Submit | POST |
| 3 | **Verify**: max:30 validation | "Code cannot exceed 30 characters." |
| 4 | **Verify**: No record created | DB unchanged |

### TC-N-06: Name > 100 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name to 101-char string | Exceeds 100 |
| 2 | Submit | POST |
| 3 | **Verify**: max:100 validation | "Name cannot exceed 100 characters." |
| 4 | **Verify**: No record created | DB unchanged |

---

## 21. Service Layer Analysis — TemplateCoscholasticComponentService

| Method | Parameters | Transaction | Description |
|--------|-----------|-------------|-------------|
| create() | TemplateCoscholasticComponentRequest $data | DB::transaction() | Creates record |
| update() | TemplateCoscholasticComponent $record, array $data, int $userId | DB::transaction() | Sets updated_by, updates |
| delete() | TemplateCoscholasticComponent $record | DB::transaction() | Soft-deletes |

### Controller vs Service Responsibility Split

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
| GAP-01 | DDL has `max_grade_points` but not in $fillable | DDL orphan | Column never used |
| GAP-02 | DDL has `display_label` but not in $fillable | DDL orphan | Column never used |
| GAP-03 | `is_ba_linked` has no FK validation against BA module | Metadata only | No integrity check |
| GAP-04 | `edit()` loads ConfigTemplates but discards them | Dead code | Extra DB query |
| GAP-05 | `store()` uses direct create (not service create method) | Inconsistency | Service create() exists but not called |
| GAP-06 | `restore()` uses hardcoded message not flash() | Inconsistency | All other CRUD methods use flash() |
| GAP-07 | `forceDelete()` uses hardcoded message not flash() | Inconsistency | Same pattern as restore |
| GAP-08 | `index()` paginates 20, hub paginates 15 | Pagination mismatch | Different page sizes |
| GAP-09 | `trashed()` uses viewAny gate | Permission pattern | Gold standard: use restore gate |

---

## 23. File Change Log

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | Initial | Full TC_List with Feature Info, Pre-conditions, Data Load, Tests | TC Team |
| 1.1 | Expansion | Added complete CODE-TRACE (13 traces), BC-BIZ-DEEP 60+ entries, additional TC-P/TC-N, TC-CR, TC-SQ, TC-INT, execution procedures, route map, DDL-to-model mapping, cross-entity comparison, validation reference, query analysis, service analysis, known gaps | TC Team |

---

## 24. Model-DDL Gap Analysis — Detailed

| # | DDL Column | DDL Type | In $fillable? | In $casts? | Notes |
|---|------------|----------|---------------|------------|-------|
| 1 | id | BIGINT PK | No | No | Auto-increment PK |
| 2 | config_template_id | BIGINT FK | **Yes** | No | FK to msh_config_templates |
| 3 | name | VARCHAR(100) | **Yes** | No | Human-readable name |
| 4 | code | VARCHAR(30) | **Yes** | No | Short code, unique per template |
| 5 | display_label | VARCHAR(255) | **No** | No | DDL orphan |
| 6 | max_grade_points | DECIMAL(5,2) | **No** | No | DDL orphan |
| 7 | grading_scale | VARCHAR(50) | **Yes** | No | Descriptive scale |
| 8 | display_order | INT | **Yes** | **integer** | Display sequence |
| 9 | is_ba_linked | TINYINT(1) | **Yes** | **bool** | BA module flag |
| 10 | is_active | TINYINT(1) | **Yes** | **bool** | Active flag |
| 11 | created_by | BIGINT FK | **Yes** | No | Creator |
| 12 | updated_by | BIGINT FK | **Yes** | No | Last modifier |
| 13 | created_at | TIMESTAMP | No | No | Auto |
| 14 | updated_at | TIMESTAMP | No | No | Auto |
| 15 | deleted_at | TIMESTAMP | No | No | SoftDeletes |

### Key Findings

1. **2 DDL orphans**: max_grade_points, display_label — exist in DB but application never reads/writes them
2. **is_ba_linked is unique** to Coscholastic — no other entity has this BA integration flag
3. **No weightage/marks columns** — coscholastic components are qualitative, not quantitative
4. **grading_scale is descriptive only** — no FK to a grading scale master table

