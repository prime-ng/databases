# Template Exam Weightages — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | Template Exam Weightages (msh_template_exam_weightages) |
| **Controller** | Modules\MarksheetGeneration\Http\Controllers\TemplateExamWeightageController — 11 methods — index() NOT called; tab listing uses MarksheetGenerationController@components() |
| **Tab Container Controller** | Modules\MarksheetGeneration\Http\Controllers\MarksheetGenerationController@components() — tab id exam-weightages, private pplyFilters() |
| **Model** | Modules\MarksheetGeneration\Models\TemplateExamWeightage — SoftDeletes, BaseModel, 4 relationships |
| **Form Request** | Modules\MarksheetGeneration\Http\Requests\TemplateExamWeightageRequest — 5 validation rules + prepareForValidation |
| **Policy** | TemplateExamWeightagePolicy — permission prefix 	enant.msh-template-exam-weightage.* |
| **Service** | TemplateExamWeightageService — wraps create/update/delete in DB transactions; NO weightage sum validation |
| **Route Prefix** | marksheet-generation.template-exam-weightage.* (resource) + 	rashed, estore, orceDelete, 	oggleStatus |
| **Blade Views** | pages/partials/components/_exam-weightages.blade.php (tab partial) |
| **Tab Container** | pages/components.blade.php — tab id exam-weightages, permission 	enant.msh-template-exam-weightage.view |
| **DB Table** | msh_template_exam_weightages — 11 columns (5 data + 6 system) |
| **Primary Screen** | Marksheet Generation → Components → Exam Weightages tab (paginated, searchable, status-filtered, modal-based CRUD) |
| **Modal IDs** | #createTemplateExamWeightageModal, #editTemplateExamWeightageModal |
| **Paginator Name** | ew_page (15 per page) |

---

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in as role with 	enant.msh-template-exam-weightage.* permissions |
| PC-02 | Database msh_template_exam_weightages table must exist with all 11 columns |
| PC-03 | msh_config_templates table must have at least one active template record |
| PC-04 | lms_exam_types table must have at least one active exam type record |
| PC-05 | TemplateExamWeightageController must be registered in web routes |
| PC-06 | TemplateExamWeightagePolicy must be registered in AuthServiceProvider |
| PC-07 | Exam Weightages tab must be in components.blade.php with @can('tenant.msh-template-exam-weightage.view') guard |
| PC-08 | Soft deletes must be enabled on msh_template_exam_weightages |
| PC-09 | TemplateExamWeightageService must be autowireable |
| PC-10 | Browser must support JavaScript for modal AJAX |

---

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | Load exam weightages with pagination (15 per page) via hub components() → applyFilters() | MarksheetGenerationController.php:104 — TemplateExamWeightage::with('configTemplate')->...->paginate(15, ['*'], 'ew_page') |
| DL-02 | Search/status filters applied only when $tab === 'exam-weightages' | MarksheetGenerationController.php:104 |
| DL-03 | Empty searchableColumns array — no text search | MarksheetGenerationController.php:104 |
| DL-04 | Columns: **#**, **Config Template**, **Exam Type**, **Weightage %**, **Max Marks**, **Status**, **Action** | _exam-weightages.blade.php:37-49 |
| DL-05 | Exam Type displayed as raw $row->exam_type_id (no eager-loaded name) | _exam-weightages.blade.php:56 |
| DL-06 | Template name via $row->configTemplate?->name | _exam-weightages.blade.php:55 |
| DL-07 | Action column uses <x-backend.table.action> with editOnclick JS | _exam-weightages.blade.php:66 |
| DL-08 | Pagination: ->appends(request()->query())->links() | _exam-weightages.blade.php:74 |
| DL-09 | Shared dropdowns: ConfigTemplate::where('is_active', 1)->get(), ExamType::where('is_active', 1)->get() | MarksheetGenerationController.php:108,110 |

---

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | **Valid Exam Weightage** | config_template_id=1, exam_type_id=1, weightage_percent=50.00, max_marks=100.00, is_active=1 |
| TD-02 | **Duplicate Exam Type Per Template** | Same config_template_id + exam_type_id — unique violation |
| TD-03 | **Weightage > 100** | weightage_percent=150.00 — max:100 failure |
| TD-04 | **Invalid Config Template ID** | config_template_id=99999 — exists failure |
| TD-05 | **Invalid Exam Type ID** | exam_type_id=99999 — exists failure |
| TD-06 | **Force Delete with FK** | StudentSubjectResult references component — 23000 catch |
| TD-07 | **No Weightage Sum Validation** | Service does NOT call sum validator (unlike scholastic) |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK, AUTO_INCREMENT | Unique identifier | DDL |
| BC-DB-02 | config_template_id — BIGINT, NOT NULL, FK → msh_config_templates.id | Required FK | DDL |
| BC-DB-03 | exam_type_id — BIGINT, NOT NULL, FK → lms_exam_types.id | Required FK | DDL |
| BC-DB-04 | weightage_percent — DECIMAL(5,2), NOT NULL, DEFAULT 0.00 | Contribution % | DDL |
| BC-DB-05 | max_marks — DECIMAL(8,2), NULLABLE | Max marks cap | DDL |
| BC-DB-06 | is_active — TINYINT(1), NOT NULL, DEFAULT 1 | Active flag | DDL |
| BC-DB-07 | created_by — BIGINT, NULLABLE, FK → users.id | Creator | DDL |
| BC-DB-08 | updated_by — BIGINT, NULLABLE, FK → users.id | Modifier | DDL |
| BC-DB-09 | created_at — TIMESTAMP, NULLABLE | Auto-managed | DDL |
| BC-DB-10 | updated_at — TIMESTAMP, NULLABLE | Auto-managed | DDL |
| BC-DB-11 | deleted_at — TIMESTAMP, NULLABLE | Soft delete | DDL |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | config_template_id — required, integer, exists:msh_config_templates,id | equired|integer|exists:msh_config_templates,id | TemplateExamWeightageRequest |
| BC-VAL-02 | exam_type_id — required, integer, exists:lms_exam_types,id, unique per config_template | equired|integer|exists:lms_exam_types,id|Rule::unique(...)->where('config_template_id', ...) | TemplateExamWeightageRequest |
| BC-VAL-03 | weightage_percent — required, numeric, min:0, max:100 | equired|numeric|min:0|max:100 | TemplateExamWeightageRequest |
| BC-VAL-04 | max_marks — nullable, numeric, min:0 | 
ullable|numeric|min:0 | TemplateExamWeightageRequest |
| BC-VAL-05 | is_active — sometimes, boolean | sometimes|boolean | TemplateExamWeightageRequest |
| BC-VAL-06 | prepareForValidation() casts IDs to int, is_active to boolean | $this->merge(['is_active' => ->boolean('is_active')]) | TemplateExamWeightageRequest |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Source |
|----|-----------|-----------------|--------|
| BC-AUTH-01 | 	enant.msh-components.view | Hub: Gate::authorize(...) at MarksheetGenerationController.php:97 | Hub controller |
| BC-AUTH-02 | 	enant.msh-template-exam-weightage.view | Blade: @can('...view') at components.blade.php:13,20 | Tab visibility |
| BC-AUTH-03 | 	enant.msh-template-exam-weightage.viewAny | Gate::authorize(...) in index() (line 17) and 	rashed() (line 135) | Controller |
| BC-AUTH-04 | 	enant.msh-template-exam-weightage.create | Gate::authorize(...) in create() (line 28) and store() (line 37) | Controller |
| BC-AUTH-05 | 	enant.msh-template-exam-weightage.update | Gate::authorize(...) in edit() (line 74), update() (line 83), 	oggleStatus() (line 123), estore() (line 144) | Controller |
| BC-AUTH-06 | 	enant.msh-template-exam-weightage.delete | Gate::authorize(...) in destroy() (line 108) and orceDelete() (line 157) | Controller |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | Tab uses hub controller components() | MarksheetGenerationController::components() line 104 | Hub |
| BC-BIZ-02 | store() sets created_by before create | $validatedData['created_by'] = auth()->id() | TemplateExamWeightageController.php:40 |
| BC-BIZ-03 | store() redirects to show page or JSON | Dual response based on $request->expectsJson() | TemplateExamWeightageController.php:48-61 |
| BC-BIZ-04 | edit() redirects to hub tab (no standalone edit form) | edirect()->route('...components.combined', ['tab' => 'exam-weightages']) | TemplateExamWeightageController.php:78 |
| BC-BIZ-05 | update() delegates to service | $service->update(, , (int) auth()->id()) | TemplateExamWeightageController.php:85 |
| BC-BIZ-06 | destroy() delegates to service | $service->delete(...) | TemplateExamWeightageController.php:110 |
| BC-BIZ-07 | toggleStatus() inverts is_active | $record->update(['is_active' => ! ->is_active, 'updated_by' => auth()->id()]) | TemplateExamWeightageController.php:126 |
| BC-BIZ-08 | forceDelete() catches QueryException 23000 | try/catch; "Cannot delete this record..." | TemplateExamWeightageController.php:160-170 |
| BC-BIZ-09 | **No weightage sum validation** in service | Unlike scholastic service, NO sum check | Service layer |
| BC-BIZ-10 | activityLog called in all CRUD + toggle | 'Stored', 'Updated', 'Deleted', 'Toggled', 'Restored' | All controller methods |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | TemplateExamWeightage → ConfigTemplate | elongsTo(configTemplate) | TemplateExamWeightage.php:34-37 |
| BC-REL-02 | TemplateExamWeightage → ExamType | elongsTo(examType) | TemplateExamWeightage.php:39-42 |
| BC-REL-03 | TemplateExamWeightage → User (created_by) | elongsTo(createdBy) | TemplateExamWeightage.php:44-47 |
| BC-REL-04 | TemplateExamWeightage → User (updated_by) | elongsTo(updatedBy) | TemplateExamWeightage.php:49-52 |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | Tab guarded by @can('tenant.msh-template-exam-weightage.view') | Tab conditional | components.blade.php:13,20 |
| BC-REF-02 | Exam Type displayed as raw ID {{ ->exam_type_id }} | No eager-loaded name | _exam-weightages.blade.php:56 |
| BC-REF-03 | Action column :canView="false" — view disabled | Only edit + delete actions | _exam-weightages.blade.php:66 |
| BC-REF-04 | Edit modal: editTemplateExamWeightage(id, config_template_id, exam_type_id, weightage_percent, max_marks, is_active) | 6 params | _exam-weightages.blade.php:66 |
| BC-REF-05 | Flash keys: created.template_exam_weightage, updated.template_exam_weightage, deleted.template_exam_weightage | Lang file keys | TemplateExamWeightageController.php |
| BC-REF-06 | Empty state: "No Exam Weightages Found" with fa-balance-scale | Icon-centered empty state | _exam-weightages.blade.php:23-32 |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | Pagination at 15 per page with ew_page name | ->paginate(15, ['*'], 'ew_page') |
| BC-BIZ-DEEP-02 | Tab-aware filtering: only when $tab === 'exam-weightages' | pplyFilters(...) scoped |
| BC-BIZ-DEEP-03 | Empty searchableColumns array — no text search applied | pplyFilters() skips search |
| BC-BIZ-DEEP-04 | Service does NOT call weightage sum validator | Key difference from scholastic service |
| BC-BIZ-DEEP-05 | weightage_percent cast as decimal:2 | Model $casts |
| BC-BIZ-DEEP-06 | max_marks cast as decimal:2 | Model $casts |
| BC-BIZ-DEEP-07 | is_active cast as ool | Model $casts |
| BC-BIZ-DEEP-08 | edit() loads ConfigTemplates but redirects — dead code | ConfigTemplate::where('is_active', true)->get() unused |
| BC-BIZ-DEEP-09 | store() has NO updated_by (only created_by) | updated_by null on create |
| BC-BIZ-DEEP-10 | update() sets updated_by via service | Service receives auth id |

### CODE-TRACE: Key Method Trace

#### CODE-TRACE-01: store(TemplateExamWeightageRequest ) — Lines 35-61

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 37 | Gate::authorize('tenant.msh-template-exam-weightage.create') | Authorization |
| 02 | 39 | $validatedData = ->validated() | Validate |
| 03 | 40 | $validatedData['created_by'] = auth()->id() | Set creator |
| 04 | 42 | $weightage = TemplateExamWeightage::create() | Create (NOT via service) |
| 05 | 44-46 | ctivityLog(, 'Stored', ['message' => '...']) | Activity log |
| 06 | 48-61 | Dual response: JSON for AJAX, redirect for normal | Modal support |

#### CODE-TRACE-02: update(TemplateExamWeightageRequest , ...) — Lines 81-104

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 83 | Gate::authorize('...update') | Authorization |
| 02 | 85 | $service->update(, , (int) auth()->id()) | Service update (NO sum validation) |
| 03 | 87-89 | ctivityLog(, 'Updated', [...]) | Activity log |
| 04 | 91-103 | Redirect to hub tab or JSON response | Modal support |

#### CODE-TRACE-03: orceDelete() — Lines 155-171

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 157 | Gate::authorize('...delete') | Authorization |
| 02 | 159 | $record = TemplateExamWeightage::withTrashed()->findOrFail() | Find any record |
| 03 | 160-162 | 	ry { ->forceDelete(); activityLog(...); } | Delete + log |
| 04 | 163-167 | catch (QueryException ) { if (->getCode() === '23000') { error... } } | FK 23000 catch |
| 05 | 170 | Redirect to trash with success | Hardcoded message |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create exam weightage via modal with all fields | Fill all fields via AJAX | Created, activityLog "Stored", JSON success |
| TC-P-02 | Create exam weightage with max_marks null | Leave max_marks empty | Created with max_marks=null |
| TC-P-03 | Edit exam weightage weightage_percent | Change 50% to 30% | Updated via service, activityLog "Updated" |
| TC-P-04 | Toggle status active→inactive | Click status switch | JSON {success:true, is_active:false} |
| TC-P-05 | Toggle status inactive→active | Click status switch | JSON {success:true, is_active:true} |
| TC-P-06 | Filter by active status | Select "Active" | Only active components |
| TC-P-07 | Restore soft-deleted weightage | Trash → Restore | Restored, is_active=true |
| TC-P-08 | Force delete with no FK | Trash → Force Delete | Permanently removed |
| TC-P-09 | Force delete with FK 23000 catch | Has StudentSubjectResult ref | Error message displayed |
| TC-P-10 | Pagination page 2 | Navigate to page 2 | 15 per page, ew_page preserved |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create empty config_template_id | Required field omitted | "The config template id field is required." |
| TC-N-02 | Create empty exam_type_id | Required field omitted | "The exam type id field is required." |
| TC-N-03 | Duplicate exam type per template | Same config_template + exam_type | "has already been taken for this template." |
| TC-N-04 | weightage_percent > 100 | 150.00 | "must be between 0 and 100." |
| TC-N-05 | weightage_percent negative | -10.00 | "must be between 0 and 100." |
| TC-N-06 | Invalid config_template_id=99999 | Non-existent | "invalid" |
| TC-N-07 | Invalid exam_type_id=99999 | Non-existent | "invalid" |
| TC-N-08 | max_marks negative | -50.00 | "must be a positive number." |
| TC-N-09 | Access without .viewAny | No permission | 403 |
| TC-N-10 | Store without .create | No permission | 403 |
| TC-N-11 | Show non-existent ID 99999 | 404 | ModelNotFoundException |
| TC-N-12 | Force delete with FK 23000 | Referenced by results | Error, not deleted |
| TC-N-13 | Toggle without .update | No permission | 403 |
| TC-N-14 | Restore non-trashed record | Active record | 404 |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | Mass-assign non-fillable fields | Inject extra fields | Ignored by Eloquent |
| TC-SQ-02 | Tab hidden without .view permission | No tab permission | Tab not rendered |
| TC-SQ-03 | Action column hidden | No view/update/delete | Column not rendered |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | No weightage sum validation (diff from scholastic) | Create 50%+60%=110% | **Allowed** (no sum check) |
| TC-INT-02 | ExamType FK restriction | Delete lms_exam_types entry | FK restriction per DDL |
| TC-INT-03 | StudentSubjectResult FK block force delete | Referenced component | QueryException 23000 caught |

## 7. Detailed Test Execution Procedures

### TC-P-11: Create exam weightage with exact boundary weightage=0%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Select Config Template | Config template selected |
| 4 | Select Exam Type | Exam type selected |
| 5 | Set weightage_percent = "0.00" | Min boundary (0) |
| 6 | Submit | POST request |
| 7 | **Verify**: min:0 validation passes | No error |
| 8 | **Verify**: Component created with weightage_percent=0.00 | DB stores 0.00 |

### TC-P-12: Create exam weightage with exact boundary weightage=100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Select Config Template and Exam Type | Required fields |
| 4 | Set weightage_percent = "100.00" | Max boundary (100) |
| 5 | Submit | POST request |
| 6 | **Verify**: max:100 validation passes | No error |
| 7 | **Verify**: Component created with weightage_percent=100.00 | DB stores 100.00 |

### TC-P-13: Edit exam weightage via modal — change weightage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to Components → Exam Weightages tab | List displayed |
| 3 | Click edit icon on existing row | JS fires editTemplateExamWeightage(id, config_template_id, exam_type_id, weightage_percent, max_marks, is_active) |
| 4 | **Verify**: Edit modal opens with pre-filled values | Modal shows current data |
| 5 | Change weightage_percent from 50 to 30 | Updated input |
| 6 | Click Submit | PATCH via AJAX |
| 7 | **Verify**: Gate::authorize('...update') at line 83 passes | Authorized |
| 8 | **Verify**: $service->update() called with validated data + auth id | Service executes in transaction |
| 9 | **Verify**: activityLog($record, 'Updated', [...]) | "The template exam weightage was updated." |
| 10 | **Verify**: JSON response with redirect to components tab | Redirect to ?tab=exam-weightages |
| 11 | **Verify**: flash('updated.template_exam_weightage') | Success message displayed |

### TC-P-14: Toggle status active→inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Locate an active weightage's status toggle | Toggle is ON |
| 3 | Click the toggle | AJAX POST to toggleStatus |
| 4 | **Verify**: Gate::authorize('...update') at line 123 passes | Authorized |
| 5 | **Verify**: $record = TemplateExamWeightage::findOrFail($id) | Record found |
| 6 | **Verify**: $record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()]) | is_active inverted, updated_by set |
| 7 | **Verify**: activityLog($record, 'Toggled', ['message' => 'Status was toggled.']) | Activity log entry |
| 8 | **Verify**: JSON {success: true, is_active: false, message: 'Status set to Inactive'} | Toggle now OFF |

### TC-P-15: Toggle status inactive→active (bidirectional)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Locate inactive weightage (is_active=0) | Toggle OFF |
| 3 | Click toggle | AJAX POST |
| 4 | **Verify**: !$record->is_active = true (was false) | is_active inverted |
| 5 | **Verify**: JSON {success: true, is_active: true, message: 'Status set to Active'} | Toggle now ON |

### TC-P-16: Filter by active status via dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .view permission | Success |
| 2 | Select "Active" from status filter dropdown | status=1 |
| 3 | Submit filter | GET with ?tab=exam-weightages&status=1 |
| 4 | **Verify**: $tab === 'exam-weightages' check passes | Filters applied |
| 5 | **Verify**: $query->where('is_active', (int) 1) | Only active records |

### TC-P-17: Filter by inactive status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select "Inactive" from status filter | status=0 |
| 2 | Submit filter | GET with ?tab=exam-weightages&status=0 |
| 3 | **Verify**: Only inactive (is_active=0) records shown | Inactive only |

### TC-P-18: Restore soft-deleted exam weightage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to trash page | onlyTrashed() records |
| 3 | Click "Restore" on a trashed weightage | GET to restore route |
| 4 | **Verify**: Gate::authorize('...update') at line 144 passes | Authorized |
| 5 | **Verify**: TemplateExamWeightage::onlyTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: $record->restore() | deleted_at = NULL |
| 7 | **Verify**: $record->update(['is_active' => true]) | Component reactivated |
| 8 | **Verify**: activityLog($record, 'Restored', ['message' => 'The record was restored.']) | Activity log |
| 9 | **Verify**: Redirect with "Record restored successfully." | Hardcoded message |

### TC-P-19: Force delete with no FK references

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .delete permission | Success |
| 2 | Navigate to trash | Trashed weightage with no FK refs |
| 3 | Click "Force Delete" | DELETE request |
| 4 | **Verify**: Gate::authorize('...delete') at line 157 passes | Authorized |
| 5 | **Verify**: withTrashed()->findOrFail($id) | Record found |
| 6 | **Verify**: forceDelete() succeeds | Record removed |
| 7 | **Verify**: activityLog($record, 'Deleted', [...]) | "The record was permanently deleted." |
| 8 | **Verify**: Redirect "Record permanently deleted." | Success |

### TC-P-20: Force delete with FK 23000 catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure weightage has StudentSubjectResult reference | FK exists |
| 2 | Soft-delete weightage | destroy() called |
| 3 | Navigate to trash | In trash |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: forceDelete() throws QueryException '23000' | FK violation |
| 6 | **Verify**: Catch block at lines 163-167 executes | Error displayed |
| 7 | **Verify**: "Cannot delete this record because it is referenced by other records." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Still in DB |

### TC-P-21: Pagination — page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 16+ exam weightages exist | 2+ pages |
| 2 | Navigate to Exam Weightages tab | Page 1 with 15 records |
| 3 | Click page 2 | GET with ?tab=exam-weightages&ew_page=2 |
| 4 | **Verify**: paginate(15, ['*'], 'ew_page') page 2 | Records 16-30 |

### TC-P-22: Pagination with tab parameter preserved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click page 2 link | URL has ?tab=exam-weightages&ew_page=2 |
| 2 | **Verify**: ->appends(['tab' => 'exam-weightages']) | Tab param preserved |

### TC-P-23: Search filter NOT applied when tab is not exam-weightages

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate with ?tab=scholastic-components&search=test | Scholastic tab active |
| 2 | Switch to Exam Weightages tab | search NOT applied (tab mismatch) |
| 3 | **Verify**: All exam weightages shown | No filter |

### TC-P-24: Create weightage with max_marks=0 (min boundary)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set max_marks = "0.00" | Min boundary |
| 2 | Submit | POST request |
| 3 | **Verify**: min:0 validation passes | No error |
| 4 | **Verify**: max_marks=0.00 stored | DB stores 0.00 |

---

### TC-N: Negative Test Cases (Additional)

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-15 | Create with weightage_percent=100.001 (3 decimals) | Regex not applied (no regex rule) | Accepted — unlike scholastic, NO regex rule on weightage |
| TC-N-16 | Create with weightage_percent=0 (no decimal) | min:0 passes | Accepted (integer 0 is numeric) |
| TC-N-17 | Submit max_marks="abc" (non-numeric) | numeric rule fails | "The max marks must be a number." |
| TC-N-18 | Submit config_template_id="abc" (string) | integer rule fails | "The config template id must be an integer." |
| TC-N-19 | Submit exam_type_id=null (null required) | required rule fails | "The exam type id field is required." |
| TC-N-20 | Submit is_active=2 (non-boolean) | boolean rule fails | "The is active field must be true or false." |
| TC-N-21 | Inject non-fillable fields via mass-assignment | POST with extra fields | Ignored by Eloquent |
| TC-N-22 | Inject created_by=999 in request | Controller overwrites with auth()->id() | auth()->id() takes precedence |
| TC-N-23 | Access edit() without .update (user has .viewAny) | User lacks update | 403 Forbidden |
| TC-N-24 | Access index() without .viewAny | No permission | 403 Forbidden |
| TC-N-25 | Access trashed() without .viewAny | No permission | 403 Forbidden |
| TC-N-26 | Access show() with non-existent ID | Route-model-binding 404 | 404 Not Found |
| TC-N-27 | Attempt restore on non-trashed (active) record | onlyTrashed() returns empty | 404 Not Found |
| TC-N-28 | Submit store() with empty body (all fields missing) | Empty POST | 422 with all validation errors |
| TC-N-29 | Access any route without authentication | Not logged in | Redirect to login |
| TC-N-30 | Attempt toggleStatus on deleted (trashed) record | findOrFail() only finds non-deleted | 404 |

--- 

## 8. Additional BC-BIZ-DEEP: Extended Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-11 | `store()` uses direct Eloquent create (NOT service layer) | `TemplateExamWeightage::create($validatedData)` — no transaction wrap |
| BC-BIZ-DEEP-12 | `update()` delegates to service which runs in transaction | `$service->update()` wraps in DB::transaction() |
| BC-BIZ-DEEP-13 | `destroy()` delegates to service soft-delete in transaction | `$service->delete()` wraps in DB::transaction() |
| BC-BIZ-DEEP-14 | No weightage sum validation in ExamWeightageService (unlike Scholastic) | Service does NOT call any sum validator |
| BC-BIZ-DEEP-15 | 50%+60%=110% allowed for exam weightages (no sum governance) | Different from Scholastic — sum not enforced |
| BC-BIZ-DEEP-16 | `index()` standalone uses 20 per page, hub uses 15 per page | Inconsistent pagination |
| BC-BIZ-DEEP-17 | `trashed()` uses 15 per page — matches hub, not standalone | Trash uses 15 |
| BC-BIZ-DEEP-18 | `toggleStatus()` uses manual `findOrFail($id)` not route-binding | `$id` parameter with explicit lookup |
| BC-BIZ-DEEP-19 | `toggleStatus()` inverts `is_active` with `!$record->is_active` | Simple boolean negation |
| BC-BIZ-DEEP-20 | `toggleStatus()` sets `updated_by` to auth()->id() | `['updated_by' => auth()->id()]` |
| BC-BIZ-DEEP-21 | `restore()` uses `onlyTrashed()->findOrFail()` | Only finds soft-deleted records |
| BC-BIZ-DEEP-22 | `restore()` sets `is_active=true` after restore | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-23 | `forceDelete()` uses `withTrashed()->findOrFail()` | Finds any record (active or trashed) |
| BC-BIZ-DEEP-24 | `forceDelete()` catches QueryException 23000 | FK violation => user-friendly message |
| BC-BIZ-DEEP-25 | `forceDelete()` re-throws non-23000 exceptions | `throw $e` for other codes |
| BC-BIZ-DEEP-26 | `forceDelete()` activityLog inside try block — only on success | `activityLog()` after `forceDelete()` in try |
| BC-BIZ-DEEP-27 | `edit()` redirects to hub tab (no standalone edit page) | No edit view — modal-based pattern |
| BC-BIZ-DEEP-28 | `edit()` loads ConfigTemplates but discards them — dead code | `ConfigTemplate::where('is_active', true)->get()` unused |
| BC-BIZ-DEEP-29 | `store()` has `created_by` set but NOT `updated_by` | `updated_by` null on create |
| BC-BIZ-DEEP-30 | `update()` sets `updated_by` via service layer | `$service->update($record, $data, (int) auth()->id())` |
| BC-BIZ-DEEP-31 | `store()` dual response: JSON for modal, redirect for normal | `$request->expectsJson()` branching |
| BC-BIZ-DEEP-32 | `show()` loads relations via `->load()` not `->with()` | `$record->load(['configTemplate', 'examType'])` |
| BC-BIZ-DEEP-33 | No `searchableColumns` for exam weightages — empty array `[]` | Tab has no text search |
| BC-BIZ-DEEP-34 | Blade displays `$row->exam_type_id` as raw ID (not name) | No eager-loaded exam type name in table |
| BC-BIZ-DEEP-35 | `examType` relation exists but NOT used in hub listing | Only `configTemplate` eagerly loaded |
| BC-BIZ-DEEP-36 | `index()` eager-loads both configTemplate and examType | `->with(['configTemplate', 'examType'])` |
| BC-BIZ-DEEP-37 | `$casts` — weightage_percent and max_marks as decimal:2 | Two decimal precision |
| BC-BIZ-DEEP-38 | `$casts` — is_active as bool | Boolean casting |
| BC-BIZ-DEEP-39 | Model uses `BaseModel` not `Model` | Extends `App\Models\BaseModel` |
| BC-BIZ-DEEP-40 | `trashed()` gate uses `viewAny` (not restore) | `Gate::authorize('...viewAny')` — same pattern as scholastic |
| BC-BIZ-DEEP-41 | `restore()` gate uses `update` (not restore) | `Gate::authorize('...update')` |
| BC-BIZ-DEEP-42 | `restore()` hardcoded success ("Record restored successfully.") | Not using flash() — same inconsistency as scholastic |
| BC-BIZ-DEEP-43 | `forceDelete()` hardcoded success ("Record permanently deleted.") | Not using flash() |
| BC-BIZ-DEEP-44 | Hub gate `tenant.msh-components.view` at controller level | Single hub gate for all tabs |
| BC-BIZ-DEEP-45 | Tab @can uses `tenant.msh-template-exam-weightage.view` | Tab visibility guard |
| BC-BIZ-DEEP-46 | search-bar component handles Add button visibility via `createModal` attribute | No explicit @can for add in blade |
| BC-BIZ-DEEP-47 | Paginator name `ew_page` unique per tab | Prevents cross-tab pagination |
| BC-BIZ-DEEP-48 | Tab-aware filtering checks `$request->input('tab') === 'exam-weightages'` | Filters scoped per active tab |
| BC-BIZ-DEEP-49 | `prepareForValidation()` casts IDs to int, is_active to boolean | Normalization in FormRequest |
| BC-BIZ-DEEP-50 | No `display_label` column in exam weightages DDL | Simpler DDL than scholastic (5 data columns) |
| BC-BIZ-DEEP-51 | No regex decimal validation on weightage_percent (unlike scholastic) | Different validation rules between similar entities |
| BC-BIZ-DEEP-52 | Route: marksheet-generation.template-exam-weightage.toggleStatus | POST/PATCH match route |
| BC-BIZ-DEEP-53 | No `sort_order` or `display_order` in exam weightages | Ordering always by created_at DESC |
| BC-BIZ-DEEP-54 | `configTemplate` relation uses `config_template_id` FK | Standard belongsTo pattern |
| BC-BIZ-DEEP-55 | `examType` relation uses `exam_type_id` FK → lms_exam_types | Cross-module relationship |
| BC-BIZ-DEEP-56 | No `sourceComponent` relation (different from scholastic) | Entity uses exam_type_id instead |
| BC-BIZ-DEEP-57 | Empty state: "No Exam Weightages Found" with fa-balance-scale icon | Custom empty state per entity |
| BC-BIZ-DEEP-58 | Action column :canView="false" — only edit + delete in modal | View action disabled |
| BC-BIZ-DEEP-59 | Edit modal JS function accepts 6 parameters | editTemplateExamWeightage(id, config_template_id, exam_type_id, weightage_percent, max_marks, is_active) |
| BC-BIZ-DEEP-60 | Route prefix: marksheet-generation.template-exam-weightage.* | Full resource + 4 extra routes |
| BC-BIZ-DEEP-61 | Shared dropdowns: ConfigTemplate + ExamType — loaded in hub controller | 2 dropdown collections for modal forms |
| BC-BIZ-DEEP-62 | Exam Type dropdown populated from lms_exam_types (cross-module) | Depends on LmsExam module |
| BC-BIZ-DEEP-63 | ConfigTemplate dropdown filtered by is_active=1 | Only active templates shown |
| BC-BIZ-DEEP-64 | store() redirects to show page for non-AJAX | `route('...template-exam-weightage.show', $weightage)` |
| BC-BIZ-DEEP-65 | destroy(), update() redirect to hub tab | `route('...components.combined', ['tab' => 'exam-weightages'])` |
| BC-BIZ-DEEP-66 | restore(), forceDelete() redirect to trash page | `route('...template-exam-weightage.trashed')` |
| BC-BIZ-DEEP-67 | toggleStatus() returns hardcoded message strings | "Status set to Active" / "Status set to Inactive" |
| BC-BIZ-DEEP-68 | activityLog messages vary by method: 'Stored', 'Updated', 'Deleted', 'Toggled', 'Restored' | 5 distinct event types |
| BC-BIZ-DEEP-69 | activityLog 'Restored' event missing `performed_by` key | Only 'message' key passed |
| BC-BIZ-DEEP-70 | activityLog 'Stored' event passes only 'message' key | No `performed_by` either — same gap |
| BC-BIZ-DEEP-71 | `findOrFail()` throws ModelNotFoundException — results in 404 | Laravel default exception handling |
| BC-BIZ-DEEP-72 | Hub controller dispatches all 4 tab datasets in single method | `components()` returns 4 paginated collections |
| BC-BIZ-DEEP-73 | Exam weightages use `ew_page` paginator name | Unique name avoids conflict with other tabs |
| BC-BIZ-DEEP-74 | `withQueryString()` on hub query preserves tab and filter params | Pagination links include current query params |
| BC-BIZ-DEEP-75 | Exam type FK: lms_exam_types — cross-module dependency | If LmsExam module disabled, feature breaks |
| BC-BIZ-DEEP-76 | No validation that exam_type belongs to same academic session | Simple FK exists check only |
| BC-BIZ-DEEP-77 | Blade action column uses @canany(['...view', '...update', '...delete']) | 3-permission OR condition |
| BC-BIZ-DEEP-78 | Blade status column uses @can('...update') | Only visible to users with update permission |
| BC-BIZ-DEEP-79 | Modal create form does NOT include max_marks validation error display | Errors may not be visible in modal context |
| BC-BIZ-DEEP-80 | No file uploads or media library interaction | Pure data entity — simpler than Vehicle |

---

## 9. Additional Test Cases — Code Review (TC-CR)

| ID | Test Case | Source | Expected Result |
|----|-----------|--------|-----------------|
| TC-CR-01 | Verify Gate::authorize() in index() | Line 17 | tenant.msh-template-exam-weightage.viewAny |
| TC-CR-02 | Verify Gate::authorize() in create() | Line 28 | tenant.msh-template-exam-weightage.create |
| TC-CR-03 | Verify Gate::authorize() in store() | Line 37 | tenant.msh-template-exam-weightage.create |
| TC-CR-04 | Verify Gate::authorize() in show() | Line 65 | tenant.msh-template-exam-weightage.view |
| TC-CR-05 | Verify Gate::authorize() in edit() | Line 74 | tenant.msh-template-exam-weightage.update |
| TC-CR-06 | Verify Gate::authorize() in update() | Line 83 | tenant.msh-template-exam-weightage.update |
| TC-CR-07 | Verify Gate::authorize() in destroy() | Line 108 | tenant.msh-template-exam-weightage.delete |
| TC-CR-08 | Verify Gate::authorize() in toggleStatus() | Line 123 | tenant.msh-template-exam-weightage.update |
| TC-CR-09 | Verify Gate::authorize() in trashed() | Line 135 | tenant.msh-template-exam-weightage.viewAny |
| TC-CR-10 | Verify Gate::authorize() in restore() | Line 144 | tenant.msh-template-exam-weightage.update |
| TC-CR-11 | Verify Gate::authorize() in forceDelete() | Line 157 | tenant.msh-template-exam-weightage.delete |
| TC-CR-12 | Verify activityLog() in store() | Lines 44-46 | "A new template exam weightage was created." |
| TC-CR-13 | Verify activityLog() in update() | Lines 87-89 | "The template exam weightage was updated." |
| TC-CR-14 | Verify activityLog() in destroy() | Lines 112-114 | "The template exam weightage was deleted." |
| TC-CR-15 | Verify activityLog() in toggleStatus() | Line 128 | "Status was toggled." |
| TC-CR-16 | Verify activityLog() in restore() | Line 150 | "The record was restored." |
| TC-CR-17 | Verify activityLog() in forceDelete() | Line 162 | "The record was permanently deleted." |
| TC-CR-18 | Verify store() uses direct create NOT service | Line 42 | TemplateExamWeightage::create($validatedData) |
| TC-CR-19 | Verify update() delegates to service | Line 85 | $service->update($templateExamWeightage, ...) |
| TC-CR-20 | Verify destroy() delegates to service | Line 110 | $service->delete($templateExamWeightage) |
| TC-CR-21 | Verify store() sets created_by | Line 40 | $validatedData['created_by'] = auth()->id() |
| TC-CR-22 | Verify restore() sets is_active=true | Line 148 | $record->update(['is_active' => true]) |
| TC-CR-23 | Verify toggleStatus() inverts is_active with ! | Line 126 | ! $record->is_active |
| TC-CR-24 | Verify toggleStatus() sets updated_by | Line 126 | 'updated_by' => auth()->id() |
| TC-CR-25 | Verify No weightage sum validation | Service | Unlike scholastic, NO sum check |
| TC-CR-26 | Verify $casts — weightage_percent decimal:2 | Model line 29 | Two decimal precision |
| TC-CR-27 | Verify $casts — max_marks decimal:2 | Model line 30 | Two decimal precision |
| TC-CR-28 | Verify $casts — is_active bool | Model line 31 | Boolean casting |
| TC-CR-29 | Verify $fillable has 7 fields | Model lines 18-26 | All data columns + audit fields |
| TC-CR-30 | Verify edit() redirects (no standalone view) | Line 78 | Redirect to components.combined?tab=exam-weightages |

---

## 10. Code Trace — Complete Method Traces

#### CODE-TRACE-03: `index()` — Lines 15-24 (Standalone Route — NOT used in hub)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 17 | `Gate::authorize('tenant.msh-template-exam-weightage.viewAny')` | Authorization gate |
| 02 | 19-21 | `TemplateExamWeightage::with(['configTemplate', 'examType'])->latest()` | Eager-load + order |
| 03 | 21 | `->paginate(20)` | Paginate 20 per page |
| 04 | 23 | `return view('marksheetgeneration::template-exam-weightage.index', compact('weightages'))` | Return standalone view |

#### CODE-TRACE-04: `show(TemplateExamWeightage $templateExamWeightage)` — Lines 63-70

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 65 | `Gate::authorize('tenant.msh-template-exam-weightage.view')` | Authorization |
| 02 | 67 | `$templateExamWeightage->load(['configTemplate', 'examType'])` | Eager-load |
| 03 | 69 | `return view('marksheetgeneration::template-exam-weightage.show', compact('templateExamWeightage'))` | Return view |

#### CODE-TRACE-05: `create()` — Lines 26-33

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 28 | `Gate::authorize('tenant.msh-template-exam-weightage.create')` | Authorization |
| 02 | 30 | `ConfigTemplate::where('is_active', true)->get()` | Load active templates |
| 03 | 32 | `return view('marksheetgeneration::template-exam-weightage.create', compact('configTemplates'))` | Return view |

#### CODE-TRACE-06: `store(TemplateExamWeightageRequest $request)` — Lines 35-61

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 37 | `Gate::authorize('tenant.msh-template-exam-weightage.create')` | Authorization |
| 02 | 39 | `$validatedData = $request->validated()` | Validate |
| 03 | 40 | `$validatedData['created_by'] = auth()->id()` | Set creator |
| 04 | 42 | `$weightage = TemplateExamWeightage::create($validatedData)` | Create (direct, no service) |
| 05 | 44-46 | `activityLog($weightage, 'Stored', ['message' => 'A new template exam weightage was created.'])` | Activity log |
| 06 | 48-52 | Build redirect response to show page | `redirect()->route('...show', $weightage)->with('success', flash('...'))` |
| 07 | 54-60 | `if ($request->expectsJson())` → JSON response | Modal AJAX support |
| 08 | 62 | `return $redirect` | Normal redirect |

#### CODE-TRACE-07: `edit(TemplateExamWeightage $templateExamWeightage)` — Lines 72-79

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 74 | `Gate::authorize('tenant.msh-template-exam-weightage.update')` | Authorization |
| 02 | 76 | `ConfigTemplate::where('is_active', true)->get()` | Load data (UNUSED — dead code) |
| 03 | 78 | `return redirect()->route('marksheet-generation.components.combined', ['tab' => 'exam-weightages'])` | Redirect to hub tab |

#### CODE-TRACE-08: `update(TemplateExamWeightageRequest $request, TemplateExamWeightage $templateExamWeightage, TemplateExamWeightageService $service)` — Lines 81-104

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 83 | `Gate::authorize('tenant.msh-template-exam-weightage.update')` | Authorization |
| 02 | 85 | `$service->update($templateExamWeightage, $request->validated(), (int) auth()->id())` | Service delegates (transaction) |
| 03 | 87-89 | `activityLog($templateExamWeightage, 'Updated', ['message' => 'The template exam weightage was updated.'])` | Activity log |
| 04 | 91-103 | Dual response: redirect to hub tab or JSON | Modal support |

#### CODE-TRACE-09: `destroy(TemplateExamWeightage $templateExamWeightage, TemplateExamWeightageService $service)` — Lines 106-119

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 108 | `Gate::authorize('tenant.msh-template-exam-weightage.delete')` | Authorization |
| 02 | 110 | `$service->delete($templateExamWeightage)` | Service soft-delete |
| 03 | 112-114 | `activityLog($templateExamWeightage, 'Deleted', ['message' => 'The template exam weightage was deleted.'])` | Activity log |
| 04 | 116-118 | `return redirect()->route('...components.combined', ['tab' => 'exam-weightages'])->with('success', flash('deleted.template_exam_weightage'))` | Redirect to hub tab |

#### CODE-TRACE-10: `toggleStatus($id)` — Lines 121-131

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 123 | `Gate::authorize('tenant.msh-template-exam-weightage.update')` | Authorization |
| 02 | 125 | `$record = TemplateExamWeightage::findOrFail($id)` | Find record |
| 03 | 126 | `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` | Toggle + set updater |
| 04 | 128 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Activity log |
| 05 | 130 | `return response()->json(['success' => true, 'is_active' => $record->is_active, 'message' => ...])` | JSON response |

#### CODE-TRACE-11: `trashed()` — Lines 133-140

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 135 | `Gate::authorize('tenant.msh-template-exam-weightage.viewAny')` | Authorization |
| 02 | 137 | `TemplateExamWeightage::onlyTrashed()->latest()->paginate(15)` | Fetch trashed, paginated 15 |
| 03 | 139 | `return view('marksheetgeneration::trashed.template-exam-weightage', compact('trashed'))` | Return trash view |

#### CODE-TRACE-12: `restore($id)` — Lines 142-153

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 144 | `Gate::authorize('tenant.msh-template-exam-weightage.update')` | Authorization |
| 02 | 146 | `$record = TemplateExamWeightage::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 147 | `$record->restore()` | Restore soft-delete |
| 04 | 148 | `$record->update(['is_active' => true])` | Reactivate |
| 05 | 150 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Activity log |
| 06 | 152 | `return redirect()->route('...template-exam-weightage.trashed')->with('success', 'Record restored successfully.')` | Redirect to trash |

#### CODE-TRACE-13: `forceDelete($id)` — Lines 155-171

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 157 | `Gate::authorize('tenant.msh-template-exam-weightage.delete')` | Authorization |
| 02 | 159 | `$record = TemplateExamWeightage::withTrashed()->findOrFail($id)` | Find any record |
| 03 | 160-162 | `try { $record->forceDelete(); activityLog(...); }` | Delete + log |
| 04 | 163-167 | `catch (QueryException $e) { if ($e->getCode() === '23000') { error } throw $e; }` | FK 23000 catch |
| 05 | 170 | `return redirect()->route('...template-exam-weightage.trashed')->with('success', 'Record permanently deleted.')` | Success redirect |

---

## 11. Security Test Cases (TC-SQ) — Additional

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-04 | CSRF protection on store() | POST without CSRF token | 419 Page Expired |
| TC-SQ-05 | Mass assignment: inject `is_active` via non-boolean | Send is_active="xyz" | sometimes|boolean catches |
| TC-SQ-06 | Tab hidden when user lacks tenant.msh-components.view | No hub permission | Hub page shows 403 |
| TC-SQ-07 | Direct URL access to standalone index without permission | /template-exam-weightage | Gate throws 403 |

## 12. Integration Test Cases (TC-INT) — Additional

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-04 | ExamType FK — delete lms_exam_types entry that has exam weightage | FK constraint | RESTRICT or CASCADE per migration |
| TC-INT-05 | ConfigTemplate FK — delete template that has exam weightages | FK constraint | CASCADE or RESTRICT per migration |
| TC-INT-06 | Service layer transaction rollback on exception | force delete throws | No partial state persisted |
| TC-INT-07 | Modal AJAX form submission with invalid data returns 422 | Invalid POST via modal | JSON error response with validation messages |
| TC-INT-08 | Hub page loads all tabs simultaneously — verify no N+1 | 4 tabs loaded in one request | Each tab's eager loading efficient |

---

## 13. Detailed Test Execution Procedures (Continued)

### TC-P-01: Create exam weightage via modal with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.msh-template-exam-weightage.create` permission | Success |
| 2 | Navigate to Marksheet Generation → Components → Exam Weightages tab | Tab loads with $examWeightages collection |
| 3 | Click "Add" button in search bar | #createTemplateExamWeightageModal modal opens |
| 4 | Select Config Template from dropdown | Config template selected |
| 5 | Select Exam Type from dropdown | Exam type selected |
| 6 | Enter weightage_percent = "50.00" | Input accepts 50.00 |
| 7 | Enter max_marks = "100.00" | Input accepts 100.00 |
| 8 | Ensure is_active toggle is ON | Active (default) |
| 9 | Click Submit/Save | AJAX POST to /template-exam-weightage |
| 10 | **Verify**: Gate::authorize('...create') at line 37 passes | Authorization ok |
| 11 | **Verify**: TemplateExamWeightageRequest rules pass (all 5 fields validated) | No validation errors |
| 12 | **Verify**: $validatedData['created_by'] = auth()->id() | created_by set |
| 13 | **Verify**: TemplateExamWeightage::create() inserts row | DB has new record |
| 14 | **Verify**: activityLog($weightage, 'Stored', [...]) | "A new template exam weightage was created." |
| 15 | **Verify**: JSON response {status: true, message: 'Template exam weightage created.', redirect: '...'} | Modal closes, success flash |
| 16 | **Verify**: Table refreshes — new weightage visible | Row appears with template name, exam type, weightage 50% |

### TC-P-10: Pagination page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 16+ exam weightages exist | At least 2 pages |
| 2 | Navigate to Exam Weightages tab | Page 1 with 15 records |
| 3 | Click page 2 pagination link | GET with ?tab=exam-weightages&ew_page=2 |
| 4 | **Verify**: ->paginate(15, ['*'], 'ew_page') returns page 2 | Records 16-30 displayed |

### TC-N-01: Create with empty config_template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Open Add modal | Modal displayed |
| 3 | Leave config_template_id EMPTY | Required field omitted |
| 4 | Submit | POST request |
| 5 | **Verify**: required rule on config_template_id | "The config template id field is required." |
| 6 | **Verify**: No record created | DB unchanged |

### TC-N-03: Duplicate exam type per template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure weightage exists with (config_template_id=1, exam_type_id=1) | Existing record |
| 2 | Create new weightage with same config_template_id=1, exam_type_id=1 | Duplicate pair |
| 3 | Submit | POST request |
| 4 | **Verify**: Rule::unique('msh_template_exam_weightages', 'exam_type_id')->where('config_template_id', 1) | "The exam type id has already been taken for this template." |
| 5 | **Verify**: No duplicate created | DB has 1 record with that pair |

### TC-N-04: weightage_percent > 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Success |
| 2 | Set weightage_percent = "150.00" | Exceeds max:100 |
| 3 | Submit | POST request |
| 4 | **Verify**: max:100 validation | "The weightage percent must be between 0 and 100." |
| 5 | **Verify**: No record created | DB unchanged |

### TC-N-12: Force delete with FK 23000

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure weightage has StudentSubjectResult referencing it | FK exists |
| 2 | Soft-delete weightage | destroy() called |
| 3 | Navigate to trash page | Weightage visible |
| 4 | Click "Force Delete" | DELETE request |
| 5 | **Verify**: forceDelete() throws QueryException 23000 | FK violation |
| 6 | **Verify**: Catch block executes | if ($e->getCode() === '23000') |
| 7 | **Verify**: "Cannot delete this record because it is referenced by other records." | User-friendly error |
| 8 | **Verify**: Record NOT deleted | Still in DB |

### TC-N-14: Restore non-trashed (active) record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with .update permission | Success |
| 2 | Navigate to /template-exam-weightage/{id}/restore for an ACTIVE record | Record not in trash |
| 3 | **Verify**: onlyTrashed()->findOrFail($id) throws ModelNotFoundException | 404 returned |
| 4 | **Verify**: Record remains unchanged | Still active in DB |

### TC-SQ-01: Mass-assign non-fillable fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit POST to store with injected extra fields | Extra fields not in $fillable |
| 2 | **Verify**: TemplateExamWeightage::create($request->validated()) ignores extra | Only fillable fields persisted |
| 3 | **Verify**: DB row has no injected values | Extra columns NULL |

### TC-INT-01: No weightage sum validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Weightage A under Template T1 with weightage=50% | Success |
| 2 | Create Weightage B under Template T1 with weightage=60% | **Success** (no sum check — difference from Scholastic) |
| 3 | **Verify**: Template T1 has 110% total weightage | Allowed (no governance at this layer) |
| 4 | **Verify**: Unlike Scholastic, no validateScholasticWeightageSum() called | Weightage sum not enforced |

### TC-CR-18: Verify store() uses direct create NOT service

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TemplateExamWeightageController.php | Line 42 |
| 2 | Locate store() method body | TemplateExamWeightage::create($validatedData) |
| 3 | **Verify**: NO service layer involvement | Direct Eloquent create |
| 4 | **Observe**: Unlike update() which uses $service->update(), store() is direct | Consistency gap between store and update |

### TC-CR-25: Verify No weightage sum validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TemplateExamWeightageService | Service class |
| 2 | Search for "validate" or "sum" references | None found |
| 3 | **Verify**: No call to MarksheetConfigService::validate...() | Key difference from TemplateScholasticComponentService |
| 4 | **Document**: Exam weightages have NO sum governance | Unlike scholastic components |

---

## 14. Test Procedure — Weightage Sum Cross-Entity Comparison

### TC-INT-01EX: Verify exam weightage sum is NOT validated (difference from scholastic)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TemplateExamWeightageService | Lines for create()/update() |
| 2 | Open TemplateScholasticComponentService | Lines for create()/update() |
| 3 | **Compare**: Scholastic service calls `MarksheetConfigService::validateScholasticWeightageSum()` | Sum checked |
| 4 | **Compare**: Exam weightage service calls NO sum validator | Sum NOT checked |
| 5 | **Observation**: Exam weightages can total >100% without error | Known architectural gap |

### TC-INT-02EX: Verify hub gate pattern for tab access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open MarksheetGenerationController::components() | Line 97 |
| 2 | **Verify**: Single hub gate `tenant.msh-components.view` | One gate for all tabs |
| 3 | **Verify**: Each tab partial has `@can('...view')` double guard | Tab nav + body |
| 4 | **Verify**: User with ANY one tab permission can access hub | Gate::any() pattern |

### TC-INT-03EX: Verify forceDelete try/catch pattern across all 4 entities

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare forceDelete() in all 4 controllers | Identical pattern |
| 2 | **Verify**: withTrashed()->findOrFail() → try { forceDelete(); activityLog() } catch (QueryException) | Same in all 4 |
| 3 | **Verify**: 23000 check + user-friendly message | Standardized |
| 4 | **Verify**: re-throw for non-23000 | throw $e |

### TC-INT-04EX: Verify restore() hardcoded message pattern across all 4 entities

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare restore() in all 4 controllers | Hardcoded message in all |
| 2 | **Verify**: None use flash('key') pattern | Inconsistency across all entities |
| 3 | **Verify**: Same hardcoded string "Record restored successfully." | Standardized inconsistency |

### TC-INT-05EX: Verify all 4 entities handle toggleStatus identically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare toggleStatus() in all 4 controllers | Gate('...update') → findOrFail → update(['is_active' => !, 'updated_by' => auth()->id()]) → activityLog → JSON |
| 2 | **Verify**: JSON response structure identical | {success, is_active, message} |
| 3 | **Verify**: Hardcoded messages match | "Status set to Active" / "Status set to Inactive" |

---

## 15. Hub Controller Components() Method Deep Trace

### CODE-TRACE-HUB: MarksheetGenerationController::components() — Full Hub Dispatch

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 97 | `Gate::authorize('tenant.msh-components.view')` | Hub-level gate |
| 02 | 99-101 | `$search`, `$status`, `$tab = request('tab', 'scholastic-components')` | Extract filter params |
| 03 | 103 | `$scholasticComponents = $this->applyFilters(TemplateScholasticComponent::with(['configTemplate','sourceComponent']), $tab === 'scholastic-components' ? $search : null, $tab === 'scholastic-components' ? $status : null, [])->paginate(15, ['*'], 'sc_page')` | Scholastic tab query |
| 04 | 104 | `$examWeightages = $this->applyFilters(TemplateExamWeightage::with('configTemplate'), $tab === 'exam-weightages' ? $search : null, $tab === 'exam-weightages' ? $status : null, [])->paginate(15, ['*'], 'ew_page')` | Exam weightages tab query |
| 05 | 105 | `$iaComponents = $this->applyFilters(TemplateIaComponent::with('configTemplate'), $tab === 'ia-components' ? $search : null, $tab === 'ia-components' ? $status : null, [])->paginate(15, ['*'], 'ia_page')` | IA tab query |
| 06 | 106 | `$coscholasticComponents = $this->applyFilters(TemplateCoscholasticComponent::with('configTemplate'), $tab === 'coscholastic-components' ? $search : null, $tab === 'coscholastic-components' ? $status : null, ['name', 'code'])->paginate(15, ['*'], 'cc_page')` | Coscholastic tab query (with searchable name+code) |
| 07 | 108-111 | `$configTemplates = ConfigTemplate::where('is_active', 1)->get(); $sourceComponents = SourceComponent::where('is_active', 1)->get(); $examTypes = ExamType::where('is_active', 1)->get(); $iaComponentTypes = IaComponentType::where('is_active', 1)->get()` | Shared dropdowns for all modals |
| 08 | 113-116 | `return view('marksheetgeneration::pages.components', compact('scholasticComponents', 'examWeightages', 'iaComponents', 'coscholasticComponents', 'configTemplates', 'sourceComponents', 'examTypes', 'iaComponentTypes'))` | Return hub view with all 4 collections + 4 dropdowns |

### CODE-TRACE-applyFilters: MarksheetGenerationController::applyFilters() — Shared Filter Helper

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 304 | `private function applyFilters($query, ?string $search, ?string $status, array $searchableColumns)` | Method signature |
| 02 | 306-311 | `if ($search && !empty($searchableColumns)) { $query->where(function($q) use ($search, $searchableColumns) { foreach ($searchableColumns as $column) { $q->orWhere($column, 'like', "%{$search}%"); } }); }` | Search filter (only if columns defined) |
| 03 | 314-316 | `if ($status !== null && $status !== '') { $query->where('is_active', (int) $status); }` | Status filter (exact match) |
| 04 | 318 | `return $query->latest()` | Always order by latest |

---

## 16. BC-DB: Database Conditions — Complete Reference

| ID | Column | Type | Constraints | Source |
|----|--------|------|-------------|--------|
| BC-DB-01 | id | BIGINT | PK, AUTO_INCREMENT | DDL |
| BC-DB-02 | config_template_id | BIGINT | NOT NULL, FK → msh_config_templates.id | DDL |
| BC-DB-03 | exam_type_id | BIGINT | NOT NULL, FK → lms_exam_types.id | DDL |
| BC-DB-04 | weightage_percent | DECIMAL(5,2) | NOT NULL, DEFAULT 0.00 | DDL |
| BC-DB-05 | max_marks | DECIMAL(8,2) | NULLABLE | DDL |
| BC-DB-06 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 | DDL |
| BC-DB-07 | created_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-08 | updated_by | BIGINT | NULLABLE, FK → users.id | DDL |
| BC-DB-09 | created_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-10 | updated_at | TIMESTAMP | NULLABLE | DDL |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE | DDL |

**DDL-to-Model Mapping:**

| DDL Column | In $fillable? | In $casts? | Notes |
|------------|---------------|------------|-------|
| id | No (PK) | No | Auto-increment |
| config_template_id | **Yes** | No | FK |
| exam_type_id | **Yes** | No | FK to lms_exam_types |
| weightage_percent | **Yes** | decimal:2 | Cast ensures 2 decimals |
| max_marks | **Yes** | decimal:2 | Nullable |
| is_active | **Yes** | bool | Boolean flag |
| created_by | **Yes** | No | Set by controller |
| updated_by | **Yes** | No | Set by controller |
| created_at | No | No | Auto-managed |
| updated_at | No | No | Auto-managed |
| deleted_at | No | No | SoftDeletes trait |

---

## 17. BC-AUTH: Authorization Matrix — Complete

| ID | Permission | Methods Gated | Blade @can | Policy Method |
|----|-----------|---------------|------------|---------------|
| BC-AUTH-01 | tenant.msh-components.view | components() hub | N/A | N/A |
| BC-AUTH-02 | tenant.msh-template-exam-weightage.view | show() | Tab visibility + @include | view() |
| BC-AUTH-03 | tenant.msh-template-exam-weightage.viewAny | index(), trashed() | N/A | viewAny() |
| BC-AUTH-04 | tenant.msh-template-exam-weightage.create | create(), store() | Add button | create() |
| BC-AUTH-05 | tenant.msh-template-exam-weightage.update | edit(), update(), toggleStatus(), restore() | Action + Status | update() |
| BC-AUTH-06 | tenant.msh-template-exam-weightage.delete | destroy(), forceDelete() | Action | delete() |

---

## 18. Route Map — Complete

| Method | URI | Route Name | Controller Method |
|--------|-----|------------|-------------------|
| GET | /template-exam-weightage | template-exam-weightage.index | index() |
| GET | /template-exam-weightage/create | template-exam-weightage.create | create() |
| POST | /template-exam-weightage | template-exam-weightage.store | store() |
| GET | /template-exam-weightage/{id} | template-exam-weightage.show | show() |
| GET | /template-exam-weightage/{id}/edit | template-exam-weightage.edit | edit() |
| PUT/PATCH | /template-exam-weightage/{id} | template-exam-weightage.update | update() |
| DELETE | /template-exam-weightage/{id} | template-exam-weightage.destroy | destroy() |
| GET | /template-exam-weightage/trash/view | template-exam-weightage.trashed | trashed() |
| GET | /template-exam-weightage/{id}/restore | template-exam-weightage.restore | restore() |
| DELETE | /template-exam-weightage/{id}/force-delete | template-exam-weightage.forceDelete | forceDelete() |
| POST/PATCH | /template-exam-weightage/{id}/toggle-status | template-exam-weightage.toggleStatus | toggleStatus() |

---

## 19. UI Component Reference — Blade Patterns

| Element | Component / Pattern | Blade Code |
|---------|-------------------|------------|
| Tab Container | x-backend.tab.nav-tab | `['id' => 'exam-weightages', 'label' => 'Exam Weightages', 'icon' => 'fa-solid fa-weight-scale', 'permission' => 'tenant.msh-template-exam-weightage.view']` |
| Tab Partial Wrapper | tab-pane fade | `<div class="tab-pane fade p-4 bg-white rounded shadow-sm" id="exam-weightages-pane">` |
| Search Bar | x-backend.tab.search-bar | `url="marksheet-generation.template-exam-weightage"` |
| Status Switch | x-backend.table.status-switch | `url="marksheet-generation.template-exam-weightage" :model="$row" permission="tenant.msh-template-exam-weightage.update"` |
| Action Buttons | x-backend.table.action | `:id="$row->id" url="marksheet-generation.template-exam-weightage" :view-permission="'...view'" :edit-permission="'...update'" :delete-permission="'...delete'"` |
| Pagination | appends(['tab' => 'exam-weightages']) | `{{ $examWeightages->appends(['tab' => 'exam-weightages'])->links() }}` |
| Empty State | Custom div | `<div class="text-center py-5">...<i class="fa-solid fa-balance-scale"></i>...<p>No Exam Weightages Found</p>...` |
| Edit Modal Trigger | JS function | `editTemplateExamWeightage(id, config_template_id, exam_type_id, weightage_percent, max_marks, is_active)` |

---

## 20. Validation Messages Reference

| Field | Rule | Validation Message |
|-------|------|-------------------|
| config_template_id | required | "The config template id field is required." |
| config_template_id | integer | "The config template id must be an integer." |
| config_template_id | exists:msh_config_templates,id | "Selected config template is invalid." |
| exam_type_id | required | "The exam type id field is required." |
| exam_type_id | integer | "The exam type id must be an integer." |
| exam_type_id | exists:lms_exam_types,id | "Selected exam type is invalid." |
| exam_type_id | unique with where | "The exam type id has already been taken for this template." |
| weightage_percent | required | "The weightage percent field is required." |
| weightage_percent | numeric | "The weightage percent must be a number." |
| weightage_percent | min:0 | "The weightage percent must be at least 0." |
| weightage_percent | max:100 | "The weightage percent must not exceed 100." |
| max_marks | numeric | "The max marks must be a number." |
| max_marks | min:0 | "The max marks must be at least 0." |
| is_active | boolean | "The is active field must be true or false." |

---

## 21. Load Order and Query Performance Analysis

| Query # | Location | SQL Operation | Expected Rows |
|---------|----------|--------------|---------------|
| 1 | Hub controller line 103 | SELECT ... FROM msh_template_scholastic_components ... | 15 + pagination |
| 2 | Hub controller line 104 | SELECT ... FROM msh_template_exam_weightages ... | 15 + pagination |
| 3 | Hub controller line 105 | SELECT ... FROM msh_template_ia_components ... | 15 + pagination |
| 4 | Hub controller line 106 | SELECT ... FROM msh_template_coscholastic_components ... | 15 + pagination |
| 5 | Hub controller line 108 | SELECT ... FROM msh_config_templates WHERE is_active = 1 | All active templates |
| 6 | Hub controller line 109 | SELECT ... FROM msh_source_components WHERE is_active = 1 | All active sources |
| 7 | Hub controller line 110 | SELECT ... FROM lms_exam_types WHERE is_active = 1 | All active exam types |
| 8 | Hub controller line 111 | SELECT ... FROM msh_ia_component_types WHERE is_active = 1 | All active types |
| 9-12 | Eager loading | Relations (configTemplate, sourceComponent, etc.) | 1 query per relation per tab |
| **Total** | **Hub page load** | **~12-16 queries** | **N+1 risk minimal due to eager-loading** |

---

## 22. File Change Log for This Document

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | Initial | Full TC_List with Feature Info, Pre-conditions, Data Load, Tests | TC Team |
| 1.1 | Expansion | Added CODE-TRACE for all 11 methods, BC-BIZ-DEEP 60+ entries, additional TC-P/TC-N, TC-CR, TC-SQ, TC-INT, execution procedures, route map, UI reference, validation reference, query analysis | TC Team |

