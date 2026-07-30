# MarksheetGeneration Student Coscholastic Results — TC_List

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | StudentCoscholasticResults (`msh_student_coscholastic_results`) — Full CRUD with AJAX modals, toggleStatus, trash/restore/forceDelete |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\StudentCoscholasticResultController` |
| **Model** | `Modules\MarksheetGeneration\Models\StudentCoscholasticResult` (SoftDeletes, 12 fillable fields, prepareForValidation) |
| **Form Request** | `StudentCoscholasticResultRequest` (create/update with composite unique + prepareForValidation) |
| **Policy** | No explicit Policy — `Gate::authorize('tenant.msh-student-coscholastic-results.*')` |
| **Route Prefix** | `marksheet-generation.student-coscholastic-results` |
| **Blade Views** | index, create (AJAX modal), edit (AJAX modal), show, trash — 5 views |
| **DB Table** | `msh_student_coscholastic_results` — 14+ columns |
| **Relationships** | belongsTo(studentResult), belongsTo(coscholasticCategory), belongsTo(gradeScale) |
| **Fillable Fields** | student_result_id, coscholastic_category_id, grade_scale_id, grade, grade_points, is_active, remarks |

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with appropriate permission for each action |
| PC-02 | `msh_student_coscholastic_results` table migrated with correct schema |
| PC-03 | `msh_student_results` table exists (parent FK) |
| PC-04 | `msh_coscholastic_categories` table exists (category FK — Life Skills, Work Ed, etc.) |
| PC-05 | `msh_grade_scales` table exists (grade scale FK — optional) |
| PC-06 | FormRequest has `prepareForValidation()` to trim whitespace |
| PC-07 | Composite unique: `student_result_id + coscholastic_category_id` |
| PC-08 | Routes: resource + 4 extras (trashed, restore, forceDelete, toggleStatus) |
| PC-09 | `config/permissionslist.php` has `msh-student-coscholastic-results` group |
| PC-10 | Blade views follow symmetrical @can/@canany pattern |
| PC-11 | `activityLog()` helper registered |
| PC-12 | AJAX modal support for create/edit via fetch() + Swal.fire |
| PC-13 | Grade and grade_points from grade_scale_id lookup |
| PC-14 | StudentResult exists before coscholastic creation |
| PC-15 | Modal uses `x-backend.form.*` components |
| PC-16 | Cancel button: `btn-light` with `data-bs-dismiss` |
| PC-17 | Save button: `btn-primary` create, `btn-warning` update |
| PC-18 | Default is_active = true |
| PC-19 | SweetAlert confirm for delete actions |
| PC-20 | Categories: Life Skills, Work Education, Visual Arts, Performing Arts, Attitude & Values |
| PC-21 | Grade scale: A+ (9-10), A (8-9), B+ (7-8), B (6-7), C (5-6), D (below 5) |
| PC-22 | Null grade_scale_id allowed — manual grade entry |
| PC-23 | Multiple categories per student result (typically all 5) |
| PC-24 | AJAX via fetch() with X-CSRF-TOKEN header |
| PC-25 | No page reload on modal operations |

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | index(): paginate(10) with search/status filters | Controller:42 |
| DL-02 | create(): blank form (modal) | Controller:56 |
| DL-03 | store(): $request->validated() + create() + activityLog | Controller:66 |
| DL-04 | show($id): findOrFail + view | Controller:80 |
| DL-05 | edit($id): findOrFail + view (modal) | Controller:92 |
| DL-06 | update(): findOrFail + update + activityLog + redirect | Controller:104 |
| DL-07 | destroy(): deactivate + soft-delete + activityLog | Controller:132 |
| DL-08 | trashed(): onlyTrashed paginate(10) | Controller:149 |
| DL-09 | restore(): onlyTrashed + restore + reactivate + activityLog | Controller:162 |
| DL-10 | forceDelete(): withTrashed + forceDelete + activityLog | Controller:181 |
| DL-11 | toggleStatus(): validate + update + AJAX JSON response | Controller:197 |

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | Zero coscholastic results | Empty table |
| TD-02 | Single result with all fields | Complete |
| TD-03 | 11 records (paginate) | Page 1=10, Page 2=1 |
| TD-04 | Mixed active/inactive | 3 active, 2 inactive |
| TD-05 | Different categories | Life Skills, Work Ed, Visual Arts, Performing Arts, Attitude |
| TD-06 | 2 soft-deleted | 1 restored, 1 force-deleted |
| TD-07 | Valid FKs to all 3 parent tables | student_result, category, grade_scale |
| TD-08 | Grade scale lookup | grade_scale_id → grade + points |
| TD-09 | Null grade_scale_id | Manual grade entry |
| TD-10 | Duplicate composite (result + category) | Unique violation |
| TD-11 | All 5 categories per result | Complete set |
| TD-12 | AJAX create via modal | fetch() |
| TD-13 | AJAX edit via modal | Prefilled |
| TD-14 | Status toggle via AJAX | Switch |
| TD-15 | Null remarks field | Optional |
| TD-16 | Grade = A+ (max), points = 10 | Top grade |
| TD-17 | Grade = D (low), points = 4 | Bottom grade |
| TD-18 | Grade points as decimal (8.50) | Precision |
| TD-19 | Category dropdown shows names | Relation display |
| TD-20 | Grade scale dropdown shows grade + range | Select |

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK AUTO_INCREMENT | Unique | Schema |
| BC-DB-02 | student_result_id — BIGINT FK → msh_student_results.id | FK result | Schema |
| BC-DB-03 | coscholastic_category_id — BIGINT FK → msh_coscholastic_categories.id | FK category | Schema |
| BC-DB-04 | grade_scale_id — BIGINT FK → msh_grade_scales.id NULLABLE | FK grade | Schema |
| BC-DB-05 | grade — VARCHAR(10) NULLABLE | Letter grade | Schema |
| BC-DB-06 | grade_points — DECIMAL(4,2) NULLABLE | Points | Schema |
| BC-DB-07 | is_active — TINYINT(1) DEFAULT 1 | Active | Schema |
| BC-DB-08 | remarks — TEXT NULLABLE | Remarks | Schema |
| BC-DB-09 | deleted_at — TIMESTAMP NULLABLE | Soft delete | Schema |
| BC-DB-10 | created_at — TIMESTAMP | Created | Schema |
| BC-DB-11 | updated_at — TIMESTAMP | Updated | Schema |
| BC-DB-12 | msh_coscholastic_categories.id — BIGINT PK | Cat PK | Schema |
| BC-DB-13 | msh_coscholastic_categories.name — VARCHAR(255) | Cat name | Schema |
| BC-DB-14 | msh_coscholastic_categories.code — VARCHAR(50) | Cat code | Schema |
| BC-DB-15 | msh_coscholastic_categories.is_active — TINYINT(1) | Cat active | Schema |
| BC-DB-16 | msh_grade_scales.id — BIGINT PK | Grade PK | Schema |
| BC-DB-17 | msh_grade_scales.grade — VARCHAR(10) | Grade letter | Schema |
| BC-DB-18 | msh_grade_scales.min_percentage — DECIMAL(5,2) | Min pct | Schema |
| BC-DB-19 | msh_grade_scales.max_percentage — DECIMAL(5,2) | Max pct | Schema |
| BC-DB-20 | msh_grade_scales.points — DECIMAL(4,2) | Points | Schema |
| BC-DB-21 | UNIQUE(student_result_id, coscholastic_category_id) | No duplicate category | FormRequest |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | student_result_id — required, exists | FK | FormRequest |
| BC-VAL-02 | coscholastic_category_id — required, exists | FK | FormRequest |
| BC-VAL-03 | grade_scale_id — nullable, exists | Optional FK | FormRequest |
| BC-VAL-04 | grade — nullable, string, max:10 | Grade | FormRequest |
| BC-VAL-05 | grade_points — nullable, numeric, min:0, max:10 | Points | FormRequest |
| BC-VAL-06 | is_active — boolean | Toggle | FormRequest |
| BC-VAL-07 | remarks — nullable, string, max:1000 | Remarks | FormRequest |
| BC-VAL-08 | UNIQUE(student_result_id, coscholastic_category_id) | Composite | FormRequest |
| BC-VAL-09 | prepareForValidation trims whitespace | Clean | FormRequest |

### BC-AUTH: Authorization Conditions

| ID | Permission | Method | Controller |
|----|-----------|--------|------------|
| BC-AUTH-01 | tenant.msh-student-coscholastic-results.viewAny | index() | Controller:40 |
| BC-AUTH-02 | tenant.msh-student-coscholastic-results.create | create(), store() | Controller:54,64 |
| BC-AUTH-03 | tenant.msh-student-coscholastic-results.view | show() | Controller:78 |
| BC-AUTH-04 | tenant.msh-student-coscholastic-results.update | edit(), update(), toggleStatus() | Controller:90,102,195 |
| BC-AUTH-05 | tenant.msh-student-coscholastic-results.delete | destroy() | Controller:128 |
| BC-AUTH-06 | tenant.msh-student-coscholastic-results.restore | trashed(), restore() | Controller:147,160 |
| BC-AUTH-07 | tenant.msh-student-coscholastic-results.forceDelete | forceDelete() | Controller:179 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store validated data | Only validated | Controller:66 |
| BC-BIZ-02 | update validated data | Only validated | Controller:106 |
| BC-BIZ-03 | activityLog after store | Log | Controller:68 |
| BC-BIZ-04 | activityLog after update | Changes | Controller:109 |
| BC-BIZ-05 | activityLog after destroy | Trash | Controller:136 |
| BC-BIZ-06 | activityLog after restore | Restore | Controller:170 |
| BC-BIZ-07 | activityLog after forceDelete | Perm | Controller:189 |
| BC-BIZ-08 | destroy: deactivate + soft-delete | Two-step | Controller:133-135 |
| BC-BIZ-09 | restore: restore + reactivate | Two-step | Controller:165-166 |
| BC-BIZ-10 | index eager loads 3 relations | N+1 | Controller:43 |
| BC-BIZ-11 | index search filter | LIKE | Controller:45-47 |
| BC-BIZ-12 | index status filter | is_active | Controller:48-50 |
| BC-BIZ-13 | index paginate 10 | Controller:51 |
| BC-BIZ-14 | toggleStatus JSON | AJAX | Controller:203-208 |
| BC-BIZ-15 | AJAX modal CRUD | fetch() | Requirement |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | StudentCoscholasticResult → StudentResult | belongsTo | Model |
| BC-REL-02 | StudentCoscholasticResult → CoscholasticCategory | belongsTo | Model |
| BC-REL-03 | StudentCoscholasticResult → GradeScale | belongsTo | Model |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | index: Result, Category, Grade, Points, Status, Action | Table | Requirement |
| BC-REF-02 | create: AJAX modal | Modal | Requirement |
| BC-REF-03 | edit: AJAX modal prefilled | Modal | Requirement |
| BC-REF-04 | show: read-only detail cards | Detail | Requirement |
| BC-REF-05 | trash: restore/forceDelete | Trash | Requirement |

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create with all fields | Valid FKs, grade | 302, success |
| TC-P-02 | Create via AJAX modal | fetch() | AJAX success |
| TC-P-03 | Null grade_scale_id | Manual grade | Success |
| TC-P-04 | View index with eager loads | 3 relations | Category visible |
| TC-P-05 | View show | All details | Relations shown |
| TC-P-06 | Edit via AJAX modal | Prefilled | Update |
| TC-P-07 | Soft-delete | destroy() | is_active=false |
| TC-P-08 | Restore | restore() | is_active=true |
| TC-P-09 | Force-delete | forceDelete() | Gone |
| TC-P-10 | Toggle status ON | is_active=1 | JSON success |
| TC-P-11 | Toggle status OFF | is_active=0 | JSON success |
| TC-P-12 | Search by category | Partial | Filtered |
| TC-P-13 | Filter active | status=1 | Active only |
| TC-P-14 | Filter inactive | status=0 | Inactive only |
| TC-P-15 | Trash page | trashed() | Listed |
| TC-P-16 | Index page 2 | ?page=2 | Next 10 |
| TC-P-17 | Null remarks | Optional | Success |
| TC-P-18 | All 5 categories per result | Complete set | All listed |
| TC-P-19 | Grade auto-lookup from scale | grade_scale_id set | Grade+points |
| TC-P-20 | Update only grade_points | Partial | Only changed |
| TC-P-21 | Grade A+ (10 points) | Max | Success |
| TC-P-22 | Grade D (4 points) | Min | Success |
| TC-P-23 | Decimal grade_points (7.50) | Precision | Success |
| TC-P-24 | Category name in dropdown | Relation | Displayed |
| TC-P-25 | Grade scale dropdown | Select options | Shown |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without student_result_id | Required | Validation error |
| TC-N-02 | Create without category_id | Required | Validation error |
| TC-N-03 | Non-existent student_result_id | FK | Validation error |
| TC-N-04 | Non-existent category_id | FK | Validation error |
| TC-N-05 | Non-existent grade_scale_id | FK | Validation error |
| TC-N-06 | Duplicate composite (result+category) | Unique | Validation error |
| TC-N-07 | grade > 10 chars | Too long | Validation error |
| TC-N-08 | grade_points > 10 | Out of range | Validation error |
| TC-N-09 | grade_points = -1 | Negative | Validation error |
| TC-N-10 | Access without viewAny | No permission | 403 |
| TC-N-11 | Access create without create | No permission | 403 |
| TC-N-12 | Store POST without create | No permission | 403 |
| TC-N-13 | Edit without update | No permission | 403 |
| TC-N-14 | PUT update without update | No permission | 403 |
| TC-N-15 | DELETE destroy without delete | No permission | 403 |
| TC-N-16 | Access trash without restore | No permission | 403 |
| TC-N-17 | Show non-existent ID | 404 | Not found |
| TC-N-18 | Edit non-existent ID | 404 | Not found |
| TC-N-19 | Update non-existent ID | 404 | Not found |
| TC-N-20 | Destroy non-existent ID | 404 | Not found |
| TC-N-21 | Restore active (not trashed) | 404 | Not found |
| TC-N-22 | Force-delete non-existent | 404 | Not found |
| TC-N-23 | toggleStatus missing field | Required | Validation error |
| TC-N-24 | toggleStatus non-boolean | Invalid | Validation error |
| TC-N-25 | grade_points = "abc" | Non-numeric | Validation error |
| TC-N-26 | POST to show route | Method | 405 |
| TC-N-27 | Cancel modal | btn-light | Closes |
| TC-N-28 | AJAX without CSRF | Header missing | 419 |
| TC-N-29 | grade_scale_id=0 | Invalid FK | Validation error |
| TC-N-30 | Session expired | No auth | Login redirect |

### TC-D: Destructive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Drop table | Schema gone | 500 |
| TC-D-02 | Delete model class | Autoload fail | 500 |
| TC-D-03 | Delete parent StudentResult | Orphaned FK | Null |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | SQLi in search | `' OR 1=1--` | Escaped |
| TC-SQ-02 | XSS in remarks | `<script>` | Auto-escaped |
| TC-SQ-03 | Mass assignment | Extra fields | validated() |
| TC-SQ-04 | CSRF on modal | No token | 419 |
| TC-SQ-05 | Unauthorized route | No permission | 403 |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Create → index | Store → view | Present |
| TC-INT-02 | Update → show | Edit → view | Updated |
| TC-INT-03 | Soft-delete → trash | Destroy → trash | Listed |
| TC-INT-04 | Restore → index | Restore → index | Active |
| TC-INT-05 | Force-delete → gone | forceDelete → show | 404 |
| TC-INT-06 | Status toggle | Toggle twice | State back |
| TC-INT-07 | Grade scale lookup | set grade_scale_id | Grade auto-filled |
| TC-INT-08 | All categories per result | All 5 | Parent shows |

## 7. Detailed Test Execution Procedures

### TC-P-01: Create coscholastic with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Open create modal | Modal renders |
| 3 | Select student_result_id | Dropdown |
| 4 | Select category_id (Life Skills) | Dropdown |
| 5 | Select grade_scale_id (optional) | Dropdown |
| 6 | Enter grade: A+ | Input |
| 7 | Enter grade_points: 9.50 | Input |
| 8 | is_active default true | Checked |
| 9 | Enter remarks: "Excellent" | Text |
| 10 | Submit via fetch() | AJAX POST |
| 11 | Verify Gate::authorize | Passes |
| 12 | Verify validated() | All rules |
| 13 | Verify record created | DB |
| 14 | Verify activityLog | Logged |
| 15 | Verify Swal.fire success | Toast |

### TC-P-06: Edit via AJAX modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update | Authorized |
| 2 | Navigate to index | List |
| 3 | Click edit icon | Modal opens |
| 4 | Verify prefilled values | Correct |
| 5 | Change grade to A | Updated |
| 6 | Submit fetch() | AJAX |
| 7 | Verify JSON success | True |
| 8 | Verify DB updated | Record |
| 9 | Verify activityLog | Changed |

### TC-N-06: Duplicate composite

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: result=1, category=1 | Success |
| 2 | Open create modal | Form |
| 3 | Same result+category | Duplicate |
| 4 | Submit | Error |
| 5 | Verify unique error | Message |

### TC-P-10: Toggle status ON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update | Authorized |
| 2 | Navigate to index | List |
| 3 | Click status-switch (inactive) | AJAX |
| 4 | Verify JSON: success, is_active=true | Response |
| 5 | Verify badge updates | Visual |

### TC-INT-07: Grade scale lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create grade_scale (grade=A, points=9, min=80, max=100) | Exists |
| 2 | Create coscholastic with grade_scale_id | Set |
| 3 | Verify grade+points auto-populated | Filled |
| 4 | Verify scale's grade shown in show page | Displayed |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — Lines 39-53

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 40 | `Gate::authorize('tenant.msh-student-coscholastic-results.viewAny')` | Auth gate |
| 02 | 43 | `$query = StudentCoscholasticResult::with(['studentResult','category','gradeScale'])` | Eager load 3 relations |
| 03 | 45 | `->when($request->filled('search'), fn($q)=>)` | Conditional search |
| 04 | 46 | `$q->where('coscholastic_category_id','like',...)->orWhere(...)` | LIKE search |
| 05 | 48 | `->when($request->filled('status'), fn($q)=>)` | Status filter |
| 06 | 49 | `$q->where('is_active', (bool)$request->status)` | Boolean cast |
| 07 | 51 | `->latest()->paginate(10)->withQueryString()` | Paginate 10 |
| 08 | 53 | `return view(...compact('coscholasticResults'))` | Return view |

#### CODE-TRACE-02: `create()` — Lines 55-58

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 56 | `Gate::authorize('tenant.msh-student-coscholastic-results.create')` | Auth |
| 02 | 58 | `return view('...student-coscholastic-results.create')` | Modal view |

#### CODE-TRACE-03: `store(StudentCoscholasticResultRequest $request)` — Lines 60-72

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 64 | `Gate::authorize('...create')` | Auth |
| 02 | 66 | `$coscholastic = StudentCoscholasticResult::create($request->validated())` | Create |
| 03 | 68 | `activityLog(...)` | Log |
| 04 | 71 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-04: `show($id)` — Lines 74-84

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 78 | `Gate::authorize('...view')` | Auth |
| 02 | 80 | `$coscholastic = StudentCoscholasticResult::findOrFail($id)` | Find or 404 |
| 03 | 83 | `return view(...compact('coscholastic'))` | View |

#### CODE-TRACE-05: `edit($id)` — Lines 86-96

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 90 | `Gate::authorize('...update')` | Auth |
| 02 | 92 | `$coscholastic = StudentCoscholasticResult::findOrFail($id)` | Find |
| 03 | 95 | `return view(...compact('coscholastic'))` | Modal view |

#### CODE-TRACE-06: `update(StudentCoscholasticResultRequest $request, $id)` — Lines 98-126

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 104 | `Gate::authorize('...update')` | Auth |
| 02 | 106 | `$coscholastic = StudentCoscholasticResult::findOrFail($id)` | Find |
| 03 | 107 | `$original = $coscholastic->getOriginal()` | Snapshot |
| 04 | 108 | `$coscholastic->update($request->validated())` | Update |
| 05 | 111-114 | `foreach($coscholastic->getChanges()...)` | Diff |
| 06 | 112 | `if($field==='updated_at') continue` | Skip |
| 07 | 113 | `$changes[$field] = ['old'=>$original[$field],'new'=>$newValue]` | Structure |
| 08 | 116-119 | `activityLog(...'Updated'...'changes'=>$changes...)` | Audit |
| 09 | 122 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-07: `destroy($id)` — Lines 128-142

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 132 | `Gate::authorize('...delete')` | Auth |
| 02 | 134 | `$coscholastic = StudentCoscholasticResult::findOrFail($id)` | Find |
| 03 | 135 | `$coscholastic->is_active = false; $coscholastic->save()` | Deactivate |
| 04 | 136 | `$coscholastic->delete()` | Soft delete |
| 05 | 138 | `activityLog(...'Trashed'...)` | Log |
| 06 | 141 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-08: `trashed()` — Lines 144-152

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 149 | `Gate::authorize('...restore')` | Auth |
| 02 | 151 | `$coscholasticResults = StudentCoscholasticResult::onlyTrashed()->paginate(10)` | Trashed query |
| 03 | 152 | `return view(...compact('coscholasticResults'))` | View |

#### CODE-TRACE-09: `restore($id)` — Lines 154-174

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 162 | `Gate::authorize('...restore')` | Auth |
| 02 | 164 | `$coscholastic = StudentCoscholasticResult::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 165 | `$coscholastic->restore()` | Restore |
| 04 | 166 | `$coscholastic->is_active = true; $coscholastic->save()` | Reactivate |
| 05 | 170 | `activityLog(...'Restored'...)` | Log |
| 06 | 173 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-10: `forceDelete($id)` — Lines 176-192

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 181 | `Gate::authorize('...forceDelete')` | Auth |
| 02 | 183 | `$coscholastic = StudentCoscholasticResult::withTrashed()->findOrFail($id)` | Find any status |
| 03 | 184 | `$coscholastic->forceDelete()` | Permanent |
| 04 | 186 | `activityLog(...'Deleted'...)` | Log |
| 05 | 191 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-11: `toggleStatus(Request $request, $id)` — Lines 194-210

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 197 | `Gate::authorize('...update')` | Auth |
| 02 | 199 | `$request->validate(['is_active'=>'required|boolean'])` | Inline validate |
| 03 | 201 | `$coscholastic = StudentCoscholasticResult::findOrFail($id)` | Find |
| 04 | 202 | `$coscholastic->is_active = $request->boolean('is_active'); $coscholastic->save()` | Toggle |
| 05 | 204 | `activityLog(...'Toggled'...)` | Log |
| 06 | 207-208 | `return response()->json(['success'=>true,'is_active'=>$coscholastic->is_active,'message'=>...])` | JSON |

---

## 7. Detailed Test Execution Procedures (Continued)

### TC-P-02: Create via AJAX modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Click "Add" button | Modal opens |
| 3 | Fill form fields | Data entered |
| 4 | Click Save (btn-primary) | fetch() POST |
| 5 | Verify CSRF token in header | Present |
| 6 | Verify Gate::authorize passes | OK |
| 7 | Verify validated() processes data | All valid |
| 8 | Verify record created in DB | Exists |
| 9 | Verify activityLog | Stored event |
| 10 | Verify Swal.fire toast | Success |
| 11 | Verify modal closes | Closed |

### TC-P-07: Edit via AJAX modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update | Authorized |
| 2 | Click edit icon | Modal opens |
| 3 | Verify prefilled values | Matches DB |
| 4 | Change grade | Updated |
| 5 | Submit fetch() PUT | AJAX |
| 6 | Verify Gate::authorize | OK |
| 7 | Verify findOrFail retrieves record | Found |
| 8 | Verify getOriginal() captures old value | Snapshot |
| 9 | Verify update() persists new value | DB updated |
| 10 | Verify activityLog with changes | Logged |
| 11 | Verify Swal.fire success | Toast |

### TC-P-08: Soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with delete | Authorized |
| 2 | Click delete action | SweetAlert confirm |
| 3 | Confirm delete | DELETE submitted |
| 4 | Verify Gate::authorize passes | OK |
| 5 | Verify is_active set to false | Deactivated |
| 6 | Verify soft-delete (deleted_at set) | Trashed |
| 7 | Verify activityLog "Trashed" | Logged |
| 8 | Verify redirect with flash | 302 |
| 9 | Verify record hidden from index | Gone |
| 10 | Verify record in trash page | Visible |

### TC-P-09: Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with restore | Authorized |
| 2 | Navigate to trash | List |
| 3 | Click restore | Confirm |
| 4 | Verify Gate::authorize | OK |
| 5 | Verify onlyTrashed findOrFail | Found |
| 6 | Verify ->restore() clears deleted_at | Restored |
| 7 | Verify is_active = true | Reactivated |
| 8 | Verify activityLog "Restored" | Logged |
| 9 | Verify redirect to index | 302 |
| 10 | Verify record visible in index | Back |

### TC-P-10: Force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with forceDelete | Authorized |
| 2 | Navigate to trash | List |
| 3 | Click force-delete | Confirm |
| 4 | Verify Gate::authorize | OK |
| 5 | Verify withTrashed findOrFail | Found |
| 6 | Verify ->forceDelete() removes permanently | Gone |
| 7 | Verify activityLog "Deleted" | Logged |
| 8 | Verify redirect to trash | 302 |
| 9 | Verify record removed from trash | Gone |

### TC-INT-07: Grade scale lookup

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure grade_scale exists (A, 9pts, 80-100%) | Exists |
| 2 | Create coscholastic with grade_scale_id selected | Submitted |
| 3 | Verify grade=auto-filled, points=auto-filled | From scale |
| 4 | Verify show page displays grade from scale | Visible |

### TC-N-06: Duplicate composite

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create entry: result=1, category=1 | Success |
| 2 | Open create modal | Form |
| 3 | Select same result+category | Duplicate |
| 4 | Submit | Validation error |
| 5 | Verify "already exists" message | Shown |

---

### CODE-TRACE-HUB: `results()` Coscholastic-Results Tab — MarksheetGenerationController Lines 218-233

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 219 | `[$csrQuery, $csrClassSectionId] = $makeResultQuery('csr_class_section_id')` | Invoke closure with 'csr_class_section_id' param |
| 02 | 220 | `$csResults = $csrQuery->paginate(10, ['*'], 'csr_page')` | Paginate 10 per page, unique paginator 'csr_page' |
| 03 | 221 | `if ($csResults->isNotEmpty())` | Only batch-load if visible results exist |
| 04 | 222 | `$pairs = $csResults->map(fn($r) => [$r->schedule_id, $r->student_id])` | Extract (schedule_id, student_id) tuples |
| 05 | 223 | `$allCsrRows = StudentCoscholasticResult::with('templateComponent')` | Batch query with templateComponent eager load |
| 06 | 224-228 | `->where(function($q) use ($pairs) { ... })->orderBy('coscholastic_component_id')->get()` | Dynamic where for all pairs + order by component |
| 07 | 229 | `$grouped = $allCsrRows->groupBy(fn($r) => $r->schedule_id . '-' . $r->student_id)` | Group by composite key |
| 08 | 230-232 | `foreach ($csResults as $sr) { $sr->setRelation('coscholasticResults', $grouped->get($key, collect())) }` | Attach grouped coscholastic results via setRelation() |

### CODE-TRACE-UPDATED: Actual Controller Methods — StudentCoscholasticResultController

#### CODE-TRACE-01-UPDATED: `index()` — Lines 13-22

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 15 | `Gate::authorize('tenant.msh-student-coscholastic-result.viewAny')` | Auth gate — singular permission key |
| 02 | 17 | `StudentCoscholasticResult::with(['marksheetSchedule', 'student', 'templateCoscholasticComponent'])` | Eager load 3 relations |
| 03 | 18 | `->latest()` | Order by created_at DESC |
| 04 | 19 | `->paginate(20)` | Paginate 20 per page |
| 05 | 21 | `return view('marksheetgeneration::student-coscholastic-result.index', compact('results'))` | Return view |

#### CODE-TRACE-03-UPDATED: `store()` — Lines 31-57

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 33 | `Gate::authorize('tenant.msh-student-coscholastic-result.create')` | Auth gate |
| 02 | 35 | `$validatedData = $request->validated()` | Validate input |
| 03 | 36 | `$validatedData['created_by'] = auth()->id()` | Set audit field |
| 04 | 38 | `$result = StudentCoscholasticResult::create($validatedData)` | Create record |
| 05 | 40-42 | `activityLog($result, 'Stored', ['message' => ...])` | Log creation |
| 06 | 44-46 | `$redirect = redirect()...with('success', flash('created.student_coscholastic_result'))` | Standard redirect |
| 07 | 48-53 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response for AJAX modal |
| 08 | 56 | `return $redirect` | Fallback to standard redirect |

#### CODE-TRACE-06-UPDATED: `update()` — Lines 75-101

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 77 | `Gate::authorize('tenant.msh-student-coscholastic-result.update')` | Auth gate |
| 02 | 79 | `$validatedData = $request->validated()` | Validate input |
| 03 | 80 | `$validatedData['updated_by'] = auth()->id()` | Set audit field |
| 04 | 82 | `$studentCoscholasticResult->update($validatedData)` | Update record (NO change tracking) |
| 05 | 84-86 | `activityLog($studentCoscholasticResult, 'Updated', ['message' => ...])` | Log update |
| 06 | 88-90 | `$redirect = redirect()...with('success', flash('updated.student_coscholastic_result'))` | Standard redirect |
| 07 | 92-97 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response |
| 08 | 100 | `return $redirect` | Fallback |

#### CODE-TRACE-07-UPDATED: `destroy()` — Lines 103-116

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 105 | `Gate::authorize('tenant.msh-student-coscholastic-result.delete')` | Auth gate |
| 02 | 107 | `$studentCoscholasticResult->delete()` | Soft delete (no is_active=false) |
| 03 | 109-111 | `activityLog($studentCoscholasticResult, 'Deleted', ['message' => ...])` | Log 'Deleted' |
| 04 | 113-115 | `redirect()->route('marksheet-generation.results.combined', ['tab' => 'coscholastic-results'])->with('success', flash('deleted.student_coscholastic_result'))` | Redirect to combined results |

#### CODE-TRACE-08-UPDATED: `trashed()` — Lines 130-137

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 132 | `Gate::authorize('tenant.msh-student-coscholastic-result.viewAny')` | Auth gate |
| 02 | 134 | `StudentCoscholasticResult::onlyTrashed()->latest()->paginate(15)` | Only soft-deleted, paginate 15 |
| 03 | 136 | `return view('marksheetgeneration::trashed.student-coscholastic-result', compact('trashed'))` | Return trash view |

#### CODE-TRACE-09-UPDATED: `restore($id)` — Lines 139-150

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 141 | `Gate::authorize('tenant.msh-student-coscholastic-result.update')` | Auth gate (uses update permission) |
| 02 | 143 | `$record = StudentCoscholasticResult::onlyTrashed()->findOrFail($id)` | Find only in trash |
| 03 | 144 | `$record->restore()` | Restore soft-delete |
| 04 | 145 | `$record->update(['is_active' => true])` | Reactivate after restore |
| 05 | 147 | `activityLog($record, 'Restored', ['message' => 'The record was restored.'])` | Log restore |
| 06 | 149 | `redirect()->route('marksheet-generation.student-coscholastic-result.trashed')->with('success', ...)` | Redirect back to trash |

#### CODE-TRACE-10-UPDATED: `forceDelete($id)` — Lines 152-168

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 154 | `Gate::authorize('tenant.msh-student-coscholastic-result.delete')` | Auth gate (uses delete permission) |
| 02 | 156 | `$record = StudentCoscholasticResult::withTrashed()->findOrFail($id)` | Find any (active or trashed) |
| 03 | 157 | `try { $record->forceDelete() }` | Permanently delete |
| 04 | 158 | `activityLog($record, 'Deleted', ['message' => ...])` | Log permanent delete |
| 05 | 159-164 | `catch (QueryException $e) { if ($e->getCode() === '23000') { ... } }` | Handle FK constraint |
| 06 | 167 | `redirect()->route('...trashed')->with('success', ...)` | Success redirect |

#### CODE-TRACE-11-UPDATED: `toggleStatus($id)` — Lines 118-128

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 120 | `Gate::authorize('tenant.msh-student-coscholastic-result.update')` | Auth gate |
| 02 | 122 | `$record = StudentCoscholasticResult::findOrFail($id)` | Find record |
| 03 | 123 | `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` | Toggle is_active |
| 04 | 125 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Log toggle |
| 05 | 127 | `return response()->json(['success'=>true, 'is_active'=>$record->is_active, 'message'=>...])` | JSON response |

### Additional BC-BIZ-DEEP: Actual Controller Behavior

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-41 | Controller permission key is `tenant.msh-student-coscholastic-result.*` (singular) | `tenant.msh-student-coscholastic-result.viewAny` |
| BC-BIZ-DEEP-42 | `index()` paginates at 20 per page | `->paginate(20)` |
| BC-BIZ-DEEP-43 | `index()` eager loads 3 relations | marksheetSchedule, student, templateCoscholasticComponent |
| BC-BIZ-DEEP-44 | `store()` sets `created_by` audit field | `$validatedData['created_by'] = auth()->id()` |
| BC-BIZ-DEEP-45 | `store()` supports JSON response | `$request->expectsJson()` check |
| BC-BIZ-DEEP-46 | `update()` sets `updated_by` audit field | `$validatedData['updated_by'] = auth()->id()` |
| BC-BIZ-DEEP-47 | `update()` does NOT use getOriginal()/getChanges() | Simple activityLog without change tracking |
| BC-BIZ-DEEP-48 | `destroy()` does NOT deactivate before soft-delete | Direct ->delete() |
| BC-BIZ-DEEP-49 | `destroy()` logs 'Deleted' not 'Trashed' | activityLog action = 'Deleted' |
| BC-BIZ-DEEP-50 | `destroy()` redirects to `results.combined?tab=coscholastic-results` | Specific tab redirect |
| BC-BIZ-DEEP-51 | `trashed()` uses `viewAny` permission | Same as index() |
| BC-BIZ-DEEP-52 | `trashed()` paginates at 15 per page | `->paginate(15)` |
| BC-BIZ-DEEP-53 | `restore()` uses `update` permission | `Gate::authorize('tenant.msh-student-coscholastic-result.update')` |
| BC-BIZ-DEEP-54 | `restore()` sets is_active=true after restore | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-55 | `restore()` redirects back to trashed page | `->route('...trashed')` |
| BC-BIZ-DEEP-56 | `forceDelete()` uses `delete` permission | `Gate::authorize('tenant.msh-student-coscholastic-result.delete')` |
| BC-BIZ-DEEP-57 | `forceDelete()` catches QueryException 23000 | FK constraint handling |
| BC-BIZ-DEEP-58 | `forceDelete()` uses `withTrashed()` | Both active and trashed deletable |
| BC-BIZ-DEEP-59 | `toggleStatus()` uses `!$record->is_active` inversion | Direct boolean flip |
| BC-BIZ-DEEP-60 | `toggleStatus()` uses `update()` not separate save+set | Single query update |
| BC-BIZ-DEEP-61 | `edit()` redirects to `results.combined?tab=coscholastic-results` | No edit form — inline modal |
| BC-BIZ-DEEP-62 | `show()` eager loads 4 relations | marksheetSchedule, student, templateComponent, enteredByUser |
| BC-BIZ-DEEP-63 | `create()` returns blank modal view | No dropdown pre-population |
| BC-BIZ-DEEP-64 | `results()` hub coscholastic uses `csr_class_section_id` | Distinct filter param |
| BC-BIZ-DEEP-65 | `results()` hub coscholastic paginator name `csr_page` | 10 per page |
| BC-BIZ-DEEP-66 | `results()` hub batch query orders by coscholastic_component_id | `->orderBy('coscholastic_component_id')` |
| BC-BIZ-DEEP-67 | `results()` hub eager loads `templateComponent` only | NOT student/category/gradeScale on batch query |
| BC-BIZ-DEFAULT-68 | `results()` hub legacy alias `$coscholasticResults = $csResults` at line 237 | Backward compat |
| BC-BIZ-DEEP-69 | `results()` hub loads `$coscholasticComponents` at line 244 | `TemplateCoscholasticComponent::orderBy('name')->get()` |
| BC-BIZ-DEEP-70 | `toggleStatus()` message alternates | "Status set to Active" / "Status set to Inactive" |
| BC-BIZ-DEEP-71 | `show()` uses `->load()` after route resolution | `$studentCoscholasticResult->load([...])` |
| BC-BIZ-DEEP-72 | `store()` flash key: `created.student_coscholastic_result` | Must exist in lang file |
| BC-BIZ-DEEP-73 | `update()` flash key: `updated.student_coscholastic_result` | Must exist in lang file |
| BC-BIZ-DEEP-74 | `destroy()` flash key: `deleted.student_coscholastic_result` | Must exist in lang file |
| BC-BIZ-DEEP-75 | No `index()` search/status filter | Simple ->latest()->paginate(20) |
| BC-BIZ-DEEP-76 | `store()` activityLog message: `'A new student coscholastic result was created.'` | Hardcoded |
| BC-BIZ-DEEP-77 | `update()` activityLog message: `'The student coscholastic result was updated.'` | Hardcoded |
| BC-BIZ-DEEP-78 | `destroy()` activityLog message: `'The student coscholastic result was deleted.'` | Hardcoded |
| BC-BIZ-DEEP-79 | `toggleStatus()` activityLog message: `'Status was toggled.'` | Generic message |
| BC-BIZ-DEEP-80 | `restore()` activityLog message: `'The record was restored.'` | Generic message |
| BC-BIZ-DEEP-81 | `forceDelete()` activityLog message: `'The record was permanently deleted.'` | Specific message |
| BC-BIZ-DEEP-82 | `is_auto_from_ba` field present in DB schema but not in controller | Controller does NOT set/use this field |
| BC-BIZ-DEEP-83 | `grade` and `grade_point` stored separately | Both columns in DB, both fillable |
| BC-BIZ-DEEP-84 | `results()` hub passes 21+ variables to view | All hub variables + tab-specific data |
| BC-BIZ-DEEP-85 | `results()` hub controller line 220: `paginate(10, ['*'], 'csr_page')` | Unique paginator name |

### Additional Test Cases

#### TC-P: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-26 | Index paginates 20 per page | 25 records | Page 1 = 20, Page 2 = 5 |
| TC-P-27 | Index eager loads 3 relations | View index | marksheetSchedule, student, templateComponent visible |
| TC-P-28 | Store sets created_by audit field | Create via POST | created_by = auth()->id() |
| TC-P-29 | Store via AJAX returns JSON | expectsJson() | JSON with status=true |
| TC-P-30 | Store via standard POST returns redirect | No JSON header | 302 redirect |
| TC-P-31 | Update sets updated_by audit field | Edit via PUT | updated_by = auth()->id() |
| TC-P-32 | Update via AJAX returns JSON | expectsJson() | JSON with status=true |
| TC-P-33 | Soft-delete via destroy | Click delete | Record in trash, deleted_at set |
| TC-P-34 | Destroy redirects to results.combined | After delete | Redirect with tab=coscholastic-results |
| TC-P-35 | Trash page paginates 15 | 20 trashed | Page 1 = 15, Page 2 = 5 |
| TC-P-36 | Restore sets is_active=true | Restore from trash | is_active = true |
| TC-P-37 | Restore redirects to trash page | After restore | Back to trash listing |
| TC-P-38 | ForceDelete permanently removes | Force delete | Record gone from DB |
| TC-P-39 | ForceDelete with FK catches exception | Referenced record | User-friendly error |
| TC-P-40 | ToggleStatus inverts is_active | Toggle ON then OFF | State round-trip |
| TC-P-41 | ToggleStatus returns JSON with message | AJAX | "Status set to Active/Inactive" |
| TC-P-42 | Show loads 4 relations | View detail | All relations displayed |
| TC-P-43 | Edit redirects to combined results tab | Click edit | Redirect to results.combined?tab=coscholastic-results |
| TC-P-44 | results() hub csr_class_section_id filter | Select section | Filtered coscholastic results |
| TC-P-45 | results() hub csr_page pagination | Navigate pages | Independent pagination |
| TC-P-46 | results() hub batch query with pairs | 10 students, 5 comps each | Single batch query |
| TC-P-47 | results() hub $coscholasticResults legacy alias | Existing views | Same data as $csResults |
| TC-P-48 | Grade scale auto-lookup on show | grade_scale_id set | Grade + points displayed |
| TC-P-49 | Grade entered manually (no grade_scale_id) | Null FK | Manual grade displayed |
| TC-P-50 | All 5 coscholastic categories per result | Life Skills, Work Ed, Arts, PE, Health | Complete set visible |

#### TC-N: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-31 | Access index without viewAny | No permission | 403 |
| TC-N-32 | Access show without view | No permission | 403 |
| TC-N-33 | Access create without create | No permission | 403 |
| TC-N-34 | Store POST without create | No permission | 403 |
| TC-N-35 | Access edit without update | No permission | 403 |
| TC-N-36 | Update PUT without update | No permission | 403 |
| TC-N-37 | Delete destroy without delete | No permission | 403 |
| TC-N-38 | Access trashed without viewAny | No permission | 403 |
| TC-N-39 | Restore without update permission | No permission | 403 |
| TC-N-40 | ForceDelete without delete permission | No permission | 403 |
| TC-N-41 | ToggleStatus without update | No permission | 403 |
| TC-N-42 | Show non-existent ID | Route-model-binding | 404 |
| TC-N-43 | Edit non-existent ID | Route-model-binding | 404 (redirects to tab) |
| TC-N-44 | Update non-existent ID | Route-model-binding | 404 |
| TC-N-45 | Destroy non-existent ID | Route-model-binding | 404 |
| TC-N-46 | Restore non-trashed (active) record | onlyTrashed findOrFail | 404 |
| TC-N-47 | ForceDelete non-existent ID | withTrashed findOrFail | 404 |
| TC-N-48 | ToggleStatus non-existent ID | findOrFail | 404 |
| TC-N-49 | Store without student_id | Required | Validation error |
| TC-N-50 | Store without coscholastic_category_id | Required | Validation error |
| TC-N-51 | Store without grade | Required | Validation error |
| TC-N-52 | Grade > 10 chars | Too long | Validation error |
| TC-N-53 | grade_points = -1 | Negative | Validation error |
| TC-N-54 | grade_points = 15 | Exceeds 10 | Validation error |
| TC-N-55 | grade_points = "abc" | Non-numeric | Validation error |
| TC-N-56 | Duplicate (student_id + schedule_id + coscholastic_component_id) | 3-field unique | Validation error |
| TC-N-57 | Non-existent student_result_id FK | Invalid | Validation error |
| TC-N-58 | Non-existent coscholastic_category_id FK | Invalid | Validation error |
| TC-N-59 | Non-existent grade_scale_id FK | Invalid | Validation error |
| TC-N-60 | Remarks > 500 chars | Too long | Validation error |
| TC-N-61 | Update with no changes | Empty diff | Success (no error) |
| TC-N-62 | ForceDelete with FK constraint | Referenced | Error message, record preserved |
| TC-N-63 | Missing X-CSRF-TOKEN on AJAX modal | No header | 419 |
| TC-N-64 | AJAX expectsJson() without proper Accept header | Wrong header | HTML returned instead of JSON |
| TC-N-65 | trashed() with no soft-deleted records | Empty trash | Empty state |
| TC-N-66 | restore() on already active record | Double restore | 404 |
| TC-N-67 | ToggleStatus with non-boolean is_active in DB | Edge case | Inverted via !$record->is_active |
| TC-N-68 | Store with grade_point non-numeric | "high" string | Validation error |
| TC-N-69 | Store without is_active | Field missing | DB default 1 |
| TC-N-70 | Remarks with SQL injection attempt | `'; DROP TABLE;--` | Escaped by query builder |

#### TC-SQ: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-06 | SQLi in grade field | `A+'; DROP TABLE` | Escaped by DB |
| TC-SQ-07 | XSS in remarks | `<script>alert(1)</script>` | Blade auto-escapes |
| TC-SQ-08 | Mass assignment via AJAX | Extra fields in JSON | validated() blocks |
| TC-SQ-09 | Missing CSRF on AJAX POST | No token | 419 |
| TC-SQ-10 | Route parameter pollution | Multiple IDs | Last ID used or 404 |

#### TC-INT: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-09 | Create via AJAX → record in DB | Modal submit | Record exists |
| TC-INT-10 | Update via AJAX → DB reflects change | Modal edit | Changed value persisted |
| TC-INT-11 | Soft-delete → trash → restore → active | Full lifecycle | Correct states |
| TC-INT-12 | Force-delete → record gone | Permanent | Cannot find |
| TC-INT-13 | ToggleStatus → JSON → UI update | AJAX flow | is_active changed |
| TC-INT-14 | results() hub batch load efficiency | 10×5 | 1 batch query |
| TC-INT-15 | results() hub cross-tab pagination independence | Tab1→Tab2 | Independent pages |
| TC-INT-16 | Store → Show page with 4 relations | Create then view | All relations loaded |
| TC-INT-17 | Trash → Restore → Index visibility | Restore flow | Appears in index |
| TC-INT-18 | Force-delete FK blocked → record preserved | FK violation | Still in trash |
| TC-INT-19 | AJAX modal validation → form stays open | Bad input | Form stays, errors shown |
| TC-INT-20 | Edit redirect → results.combined tab active | Click edit | Tab=coscholastic-results |

### Additional Detailed Test Execution Procedures

#### TC-P-28: Store sets created_by audit field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Submit valid coscholastic result form | POST |
| 3 | Verify Gate::authorize at line 33 | Passes |
| 4 | Verify validated() at line 35 | All rules pass |
| 5 | Verify created_by = auth()->id() at line 36 | Set |
| 6 | Verify create() at line 38 | Record in DB |
| 7 | Verify activityLog 'Stored' at line 40 | Logged |
| 8 | Verify JSON when expectsJson() or redirect | Correct response type |

#### TC-P-31: Update sets updated_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Submit edit form with changed grade | PUT |
| 3 | Verify Gate::authorize at line 77 | Passes |
| 4 | Verify validated() at line 79 | All rules pass |
| 5 | Verify updated_by = auth()->id() at line 80 | Set |
| 6 | Verify update() at line 82 | DB changed |
| 7 | Verify activityLog 'Updated' at line 84 | Logged |
| 8 | Verify JSON when expectsJson() | Correct response |

#### TC-P-35: Trash pagination at 15

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 18 records | 18 in trash |
| 2 | Login with viewAny permission | Authorized |
| 3 | Navigate to trash page | Page loads |
| 4 | Verify Gate::authorize at line 132 | Passes |
| 5 | Verify onlyTrashed()->latest()->paginate(15) at line 134 | 15 on page 1 |
| 6 | Verify page 2 shows 3 records | 3 remaining |

#### TC-P-39: ForceDelete FK constraint handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create coscholastic result with child dependency | Referenced |
| 2 | Navigate to trash → force-delete | DELETE |
| 3 | Verify Gate::authorize at line 154 | Passes |
| 4 | Verify withTrashed()->findOrFail() at line 156 | Found |
| 5 | Verify forceDelete() throws QueryException 23000 | FK violation |
| 6 | Verify catch block at line 159-164 | Executed |
| 7 | Verify error message shown | "Cannot delete...referenced by other records" |
| 8 | Verify record still exists in trash | Preserved |

#### TC-P-40: ToggleStatus round-trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find record with is_active = true | Baseline |
| 2 | POST toggleStatus | AJAX |
| 3 | Verify Gate::authorize at line 120 | Passes |
| 4 | Verify findOrFail at line 122 | Found |
| 5 | Verify update: !true = false at line 123 | Inverted |
| 6 | Verify JSON: is_active = false, message = "Status set to Inactive" | Correct |
| 7 | Toggle again | is_active = true |
| 8 | Verify message = "Status set to Active" | Alternating |

#### TC-P-44: results() hub csr_class_section_id filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Results hub → Coscholastic tab | Tab loads |
| 2 | Select class-section from dropdown | Filter applied |
| 3 | Verify $makeResultQuery with 'csr_class_section_id' | Closure invoked |
| 4 | Verify where('class_section_id', $csId) | Filter active |
| 5 | Verify paginate(10, ['*'], 'csr_page') at line 220 | Correct |
| 6 | Verify batch query for visible students at line 221-228 | Single query |
| 7 | Verify legacy alias at line 237 | $coscholasticResults = $csResults |

#### TC-N-46: Restore active record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure record is active (deleted_at = null) | Active |
| 2 | POST to restore route | GET restore |
| 3 | Verify Gate::authorize at line 141 | Passes |
| 4 | Verify onlyTrashed()->findOrFail() at line 143 | NOT FOUND |
| 5 | Verify 404 thrown | ModelNotFoundException |
| 6 | Verify no state change | Record remains active |

### Additional BC-BIZ-DEEP: Deep Business Conditions — Coscholastic Additional

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-81 | `results()` Coscholastic tab uses `$makeResultQuery` closure | Same closure as other tabs |
| BC-BIZ-DEEP-82 | Coscholastic tab filters apply only when `$request->input('tab') === 'coscholastic-results'` | Tab-scoped isolation |
| BC-BIZ-DEEP-83 | Inline coscholastic loads via `StudentCoscholasticResult::whereIn('student_result_id', $ids)` | Batch WHERE IN |
| BC-BIZ-DEEP-84 | Standalone `index()` paginates 15 per page | `paginate(15)` |
| BC-BIZ-DEEP-85 | Standalone `index()` uses `with(['studentResult.student', 'coscholasticSkill.skillCategory'])` | 3-level eager load |
| BC-BIZ-DEEP-86 | Standalone `trashed()` paginates 10 per page | `onlyTrashed()->latest()->paginate(10)` |
| BC-BIZ-DEEP-87 | Standalone `toggleStatus()` sets `is_active` on AJAX | Boolean toggle |
| BC-BIZ-DEEP-88 | `StudentCoscholasticResultRequest` validates `grade` in allowed values | A+, A, B+, B, C, D |
| BC-BIZ-DEEP-89 | `StudentCoscholasticResultRequest` validates `student_result_id` unique per skill | No duplicate result+skill |
| BC-BIZ-DEEP-90 | Coscholastic table `coscholastic_skills` has `skill_category_id` FK | Category grouping |
| BC-BIZ-DEEP-91 | `StudentCoscholasticResult` model has `belongsTo(CoscholasticSkill::class)` | Skill relation |
| BC-BIZ-DEEP-92 | `StudentCoscholasticResult` model has `belongsTo(StudentResult::class)` | Parent result relation |
| BC-BIZ-DEEP-93 | Standalone `show()` renders grade with badge color | Color-coded grade |
| BC-BIZ-DEEP-94 | Standalone `create()` loads coscholastic skill categories grouped | Grouped by cateogry |
| BC-BIZ-DEEP-95 | Standalone `create()` loads student results for dropdown | Active results only |

### Additional Test Cases

#### TC-P-25 to TC-P-45: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-25 | Inline coscholastic batch WHERE IN | Has results | Batch query executes |
| TC-P-26 | Standalone index loading coscholastic skills with category | Eager load | Skill + category shown |
| TC-P-27 | Standalone create loads skills grouped by category | Grouped | Dropdown organized |
| TC-P-28 | Show displays grade with badge | Grade = A+ | Green badge shown |
| TC-P-29 | ToggleStatus from active to inactive | AJAX | is_active = 0 |
| TC-P-30 | Restore soft-deleted record | Trash → restore | Reactivated |
| TC-P-31 | ForceDelete permanently removes | Trash → force delete | Record gone |
| TC-P-32 | Create with valid grade | Submit form | Created |
| TC-P-33 | Edit coscholastic grade | Update grade | Updated |
| TC-P-34 | Index filter by skill category | Select filter | Filtered |
| TC-P-35 | Index search by grade value | Search | Like match |
| TC-P-36 | Show page with student name | Relation loaded | Name + ID shown |
| TC-P-37 | Trash page with deleted records | Has data | Paginated 10 |
| TC-P-38 | Validation: grade on boundary | A+ → A | Accepted |
| TC-P-39 | Create with unique student_result + coscholastic_skill_id | New pair | Created |
| TC-P-40 | Edit form pre-selects existing skill | Preserved | Correct option |

#### TC-N-25 to TC-N-45: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-25 | Create duplicate student_result + coscholastic_skill_id | Duplicate | Validation error |
| TC-N-26 | Grade value not in allowed list | "Z" | Validation error |
| TC-N-27 | Grade value empty | Required | Validation error |
| TC-N-28 | Inline batch with 0 student_result_ids | No data | isNotEmpty false, query skipped |
| TC-N-29 | ToggleStatus with no permission | No update | 403 |
| TC-N-30 | Restore non-deleted record | Active | 404 |
| TC-N-31 | ForceDelete on active record | Not trash | 404 |
| TC-N-32 | ToggleStatus on non-existent ID | Wrong ID | 404 |
| TC-N-33 | Show non-existent ID | Wrong ID | 404 |
| TC-N-34 | Edit non-existent ID | Wrong ID | 404 |
| TC-N-35 | Delete already deleted record | Double delete | 404 |
| TC-N-36 | Trash page with all active records | No deleted | Empty state |
| TC-N-37 | Index with invalid skill_category filter | Wrong ID | Empty results |
| TC-N-38 | XSS in grade search | Script tag | Escaped |
| TC-N-39 | SQLi in search parameter | Injection | Query builder |
| TC-N-40 | Grade A submitted as lowercase "a" | Case mismatch | Case-insensitive? |
| TC-N-41 | Grade with whitespace | " A+" | Trim handling |
| TC-N-42 | Missing student_result_id | Required field | Validation error |
| TC-N-43 | Missing coscholastic_skill_id | Required field | Validation error |
| TC-N-44 | ToggleStatus missing is_active param | Not in body | Validation error |
| TC-N-45 | forceDelete on ID 0 | Edge case | 404 |

#### TC-INT-10 to TC-INT-19: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-10 | Coscholastic create → index shows | Round trip | Record visible |
| TC-INT-11 | Coscholastic toggleStatus → dashboard KPI reflects | State change | Dashboard updated |
| TC-INT-12 | Inline hub count matches standalone count | Cross-page | Consistent |
| TC-INT-13 | Delete → trashed list shows | Soft delete | In trash |
| TC-INT-14 | Restore → index shows active | Reactivated | Active list |
| TC-INT-15 | Filter on hub tab → same filter on standalone page | Consistency | Same results |
| TC-INT-16 | Create StudentResult → coscholastic available for that result | Parent created | Parent in dropdown |
| TC-INT-17 | Grade badge in show matches color map | Visual check | Correct color |
| TC-INT-18 | Show page from inline hub click-through | Deep link | Correct detail |
| TC-INT-19 | Multiple coscholastic results per student result | Multi-skill | All displayed |

#### TC-INT-20: Create coscholastic → hub inline list reflects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone coscholastic index | Note count |
| 2 | Open create form | Form loads |
| 3 | Select student result + skill + grade | Valid input |
| 4 | Submit | Created |
| 5 | Navigate to Results hub → Coscholastic tab | Hub loads |
| 6 | Expand corresponding student row | New grade visible |

#### TC-INT-21: Delete coscholastic → hub list removes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone coscholastic index | With records |
| 2 | Delete a coscholastic record | Soft deleted |
| 3 | Navigate to Results hub → Coscholastic tab | Hub loads |
| 4 | Verify deleted record absent from inline list | Removed |

---

*Template: tpt_Vehicle_TcList.md | Entity: StudentCoscholasticResults | Date: 2026-07-22*
