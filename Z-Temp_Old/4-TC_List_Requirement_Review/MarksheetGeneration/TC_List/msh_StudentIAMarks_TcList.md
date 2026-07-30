# MarksheetGeneration Student IA Marks — TC_List

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | StudentIAMarks (`msh_student_ia_marks`) — Full CRUD with AJAX modals, toggleStatus, trash/restore/forceDelete |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\StudentIaMarkController` |
| **Model** | `Modules\MarksheetGeneration\Models\StudentIaMark` (SoftDeletes, 10 fillable fields, prepareForValidation) |
| **Form Request** | `StudentIaMarkRequest` (create/update with composite unique across 3 FKs + prepareForValidation) |
| **Policy** | No explicit Policy — `Gate::authorize('tenant.msh-student-ia-marks.*')` |
| **Route Prefix** | `marksheet-generation.student-ia-marks` |
| **Blade Views** | index, create (AJAX modal), edit (AJAX modal), show, trash — 5 views |
| **DB Table** | `msh_student_ia_marks` — 12+ columns |
| **Relationships** | belongsTo(studentResult), belongsTo(subject), belongsTo(iaType) |
| **Fillable Fields** | student_result_id, subject_id, ia_type_id, max_marks, marks_obtained, is_active, remarks |

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with appropriate permission for each action |
| PC-02 | `msh_student_ia_marks` table migrated with correct schema |
| PC-03 | `msh_student_results` table exists (parent FK) |
| PC-04 | `sub_subjects` table exists (subject FK) |
| PC-05 | `msh_ia_types` table exists (IA type FK) |
| PC-06 | FormRequest has `prepareForValidation()` to clean input |
| PC-07 | Composite unique: `student_result_id + subject_id + ia_type_id` (3-field) |
| PC-08 | Routes: resource + 4 extras (trashed, restore, forceDelete, toggleStatus) |
| PC-09 | `config/permissionslist.php` has `msh-student-ia-marks` group |
| PC-10 | Blade views follow symmetrical @can/@canany pattern |
| PC-11 | `activityLog()` helper registered |
| PC-12 | AJAX modal support for create/edit via fetch() + Swal.fire |
| PC-13 | marks_obtained must be ≤ max_marks |
| PC-14 | IA type determines max marks (theory/practical/lab/external) |
| PC-15 | StudentResult exists before IA mark creation |
| PC-16 | Modal uses `x-backend.form.*` components |
| PC-17 | Cancel button: `btn-light` with `data-bs-dismiss="modal"` |
| PC-18 | Save button: `btn-primary` for create, `btn-warning` for update |
| PC-19 | Default is_active = true |
| PC-20 | SweetAlert confirm for delete actions |
| PC-21 | 3-FK unique prevents duplicate entries for same result+subject+IA type |
| PC-22 | Multiple IA types per student result (theory IA, practical IA, lab IA) |
| PC-23 | AJAX submit via fetch() with proper CSRF token |
| PC-24 | Swal.fire toast on AJAX success/failure |
| PC-25 | No page reload on modal create/edit — DOM updates |

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
| TD-01 | Zero IA marks | Empty table |
| TD-02 | Single IA mark | 1 record all fields |
| TD-03 | 11 records (paginate) | Page 1=10, Page 2=1 |
| TD-04 | Mixed active/inactive | 3 active, 2 inactive |
| TD-05 | Different IA types | theory, practical, lab, external |
| TD-06 | 2 soft-deleted | 1 restored, 1 force-deleted |
| TD-07 | Valid FKs to all 3 parent tables | student_result, subject, ia_type |
| TD-08 | marks_obtained = max_marks | Perfect |
| TD-09 | marks_obtained = 0 | Minimum |
| TD-10 | marks_obtained > max_marks | Validation error |
| TD-11 | Duplicate 3-field composite key | Unique violation |
| TD-12 | 3 IA entries per student result | All types |
| TD-13 | AJAX create via modal | fetch() |
| TD-14 | AJAX edit via modal | Prefilled |
| TD-15 | Status toggle via AJAX | Switch |

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | id — BIGINT PK AUTO_INCREMENT | Unique | Schema |
| BC-DB-02 | student_result_id — BIGINT FK | FK to result | Schema |
| BC-DB-03 | subject_id — BIGINT FK | FK to subject | Schema |
| BC-DB-04 | ia_type_id — BIGINT FK | FK to IA type | Schema |
| BC-DB-05 | max_marks — DECIMAL(8,2) NOT NULL | Max | Schema |
| BC-DB-06 | marks_obtained — DECIMAL(8,2) NOT NULL | Scored | Schema |
| BC-DB-07 | is_active — TINYINT(1) DEFAULT 1 | Active | Schema |
| BC-DB-08 | remarks — TEXT NULLABLE | Remarks | Schema |
| BC-DB-09 | deleted_at — TIMESTAMP NULLABLE | Soft delete | Schema |
| BC-DB-10 | created_at — TIMESTAMP | Created | Schema |
| BC-DB-11 | updated_at — TIMESTAMP | Updated | Schema |
| BC-DB-12 | UNIQUE(student_result_id, subject_id, ia_type_id) | 3-field composite | FormRequest |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | student_result_id — required, exists | FK | FormRequest |
| BC-VAL-02 | subject_id — required, exists | FK | FormRequest |
| BC-VAL-03 | ia_type_id — required, exists | FK | FormRequest |
| BC-VAL-04 | max_marks — required, numeric, min:0 | Decimal | FormRequest |
| BC-VAL-05 | marks_obtained — required, numeric, min:0 | Decimal | FormRequest |
| BC-VAL-06 | marks_obtained — ≤ max_marks | Business | FormRequest |
| BC-VAL-07 | is_active — boolean | Toggle | FormRequest |
| BC-VAL-08 | remarks — nullable, string, max:1000 | Text | FormRequest |
| BC-VAL-09 | Unique composite (3 fields) | Prevention | FormRequest |
| BC-VAL-10 | prepareForValidation strips whitespace | Clean | FormRequest |

### BC-AUTH: Authorization Conditions

| ID | Permission | Method | Controller |
|----|-----------|--------|------------|
| BC-AUTH-01 | tenant.msh-student-ia-marks.viewAny | index() | Controller:40 |
| BC-AUTH-02 | tenant.msh-student-ia-marks.create | create(), store() | Controller:54,64 |
| BC-AUTH-03 | tenant.msh-student-ia-marks.view | show() | Controller:78 |
| BC-AUTH-04 | tenant.msh-student-ia-marks.update | edit(), update(), toggleStatus() | Controller:90,102,195 |
| BC-AUTH-05 | tenant.msh-student-ia-marks.delete | destroy() | Controller:128 |
| BC-AUTH-06 | tenant.msh-student-ia-marks.restore | trashed(), restore() | Controller:147,160 |
| BC-AUTH-07 | tenant.msh-student-ia-marks.forceDelete | forceDelete() | Controller:179 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store validated data | Only validated | Controller:66 |
| BC-BIZ-02 | update validated data | Only validated | Controller:106 |
| BC-BIZ-03 | activityLog after store | Log | Controller:68 |
| BC-BIZ-04 | activityLog after update | Changes | Controller:109 |
| BC-BIZ-05 | activityLog after destroy | Trash | Controller:136 |
| BC-BIZ-06 | activityLog after restore | Restore | Controller:170 |
| BC-BIZ-07 | activityLog after forceDelete | Permanent | Controller:189 |
| BC-BIZ-08 | destroy: deactivate then soft-delete | Two-step | Controller:133-135 |
| BC-BIZ-09 | restore: restore then reactivate | Two-step | Controller:165-166 |
| BC-BIZ-10 | index eager loads 3 relations | N+1 | Controller:43 |
| BC-BIZ-11 | index search filter | LIKE | Controller:45-47 |
| BC-BIZ-12 | index status filter | is_active | Controller:48-50 |
| BC-BIZ-13 | index paginate 10 | ->paginate(10) | Controller:51 |
| BC-BIZ-14 | toggleStatus JSON response | AJAX | Controller:203-208 |
| BC-BIZ-15 | AJAX modal create | fetch() | Requirement |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | StudentIaMark → StudentResult | belongsTo | Model |
| BC-REL-02 | StudentIaMark → Subject | belongsTo | Model |
| BC-REL-03 | StudentIaMark → IaType | belongsTo | Model |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | index: Result, Subject, IA Type, Max, Obtained, Status, Action | Table | Requirement |
| BC-REF-02 | create: AJAX modal | Modal | Requirement |
| BC-REF-03 | edit: AJAX modal prefilled | Modal | Requirement |
| BC-REF-04 | show: read-only detail | Detail | Requirement |
| BC-REF-05 | trash: restore/forceDelete | Trash | Requirement |

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create with all fields | Valid 3 FKs, marks | 302, success |
| TC-P-02 | Create via AJAX modal | fetch() submit | AJAX success |
| TC-P-03 | marks_obtained = max_marks | Perfect | Success |
| TC-P-04 | marks_obtained = 0 | Minimum | Success |
| TC-P-05 | View index with all eager loads | 3 relations | Subject, IA type visible |
| TC-P-06 | View show | All details | Relations shown |
| TC-P-07 | Edit via AJAX modal | Prefilled | AJAX update |
| TC-P-08 | Soft-delete | destroy() | is_active=false |
| TC-P-09 | Restore | restore() | is_active=true |
| TC-P-10 | Force-delete | forceDelete() | Gone |
| TC-P-11 | Toggle status ON | is_active=1 | JSON success |
| TC-P-12 | Toggle status OFF | is_active=0 | JSON success |
| TC-P-13 | Search by subject | Partial | Filtered |
| TC-P-14 | Filter active | status=1 | Active only |
| TC-P-15 | Filter inactive | status=0 | Inactive only |
| TC-P-16 | Trash page | trashed() | Listed |
| TC-P-17 | Index page 2 | ?page=2 | Next 10 |
| TC-P-18 | Null remarks | Optional | Success |
| TC-P-19 | Update only marks | Partial | Only changed |
| TC-P-20 | 3 IA types per result | All IA entries | Listed |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without student_result_id | Required | Validation error |
| TC-N-02 | Create without subject_id | Required | Validation error |
| TC-N-03 | Create without ia_type_id | Required | Validation error |
| TC-N-04 | Create without max_marks | Required | Validation error |
| TC-N-05 | Create without marks_obtained | Required | Validation error |
| TC-N-06 | marks_obtained > max_marks | Exceeds | Validation error |
| TC-N-07 | marks_obtained = -1 | Negative | Validation error |
| TC-N-08 | Non-existent student_result_id | FK fail | Validation error |
| TC-N-09 | Non-existent subject_id | FK fail | Validation error |
| TC-N-10 | Non-existent ia_type_id | FK fail | Validation error |
| TC-N-11 | Duplicate 3-field composite | Unique | Validation error |
| TC-N-12 | Access without viewAny | No permission | 403 |
| TC-N-13 | Access create without create | No permission | 403 |
| TC-N-14 | Store POST without create | No permission | 403 |
| TC-N-15 | Edit without update | No permission | 403 |
| TC-N-16 | PUT update without update | No permission | 403 |
| TC-N-17 | DELETE destroy without delete | No permission | 403 |
| TC-N-18 | Access trash without restore | No permission | 403 |
| TC-N-19 | Show non-existent ID | 404 | Not found |
| TC-N-20 | Edit non-existent ID | 404 | Not found |
| TC-N-21 | Update non-existent ID | 404 | Not found |
| TC-N-22 | Destroy non-existent ID | 404 | Not found |
| TC-N-23 | Restore active (not trashed) | 404 | Not found |
| TC-N-24 | Force-delete non-existent | 404 | Not found |
| TC-N-25 | toggleStatus missing field | Required | Validation error |
| TC-N-26 | toggleStatus non-boolean | Invalid | Validation error |
| TC-N-27 | marks_obtained = "abc" | Non-numeric | Validation error |
| TC-N-28 | POST to show route | Method | 405 |
| TC-N-29 | Cancel modal | btn-light | Closes |
| TC-N-30 | AJAX without CSRF token | Missing header | 419 |

### TC-D: Destructive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Drop msh_student_ia_marks | Table gone | 500 |
| TC-D-02 | Delete StudentIaMark model | Class missing | 500 |
| TC-D-03 | Delete parent StudentResult | Orphaned FK | Null relation |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | SQLi in search | `' OR 1=1--` | Escaped |
| TC-SQ-02 | XSS in remarks | `<script>` | Auto-escaped |
| TC-SQ-03 | Mass assignment | Extra fields | validated() blocks |
| TC-SQ-04 | CSRF missing on modal | No token | 419 |
| TC-SQ-05 | Unauthorized route | No permission | 403 |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Create → appears in index | Store → view | Present |
| TC-INT-02 | Update → reflected in show | Edit → view | Updated |
| TC-INT-03 | Soft-delete → appears in trash | Destroy → trash | Listed |
| TC-INT-04 | Restore → back to index | Restore → index | Active |
| TC-INT-05 | Force-delete → gone | forceDelete → show | 404 |
| TC-INT-06 | Status toggle reflected | Toggle twice | State back |
| TC-INT-07 | All IA marks summed in parent result | Multiple per result | Aggregated |

## 7. Detailed Test Execution Procedures

### TC-P-01: Create IA mark with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Open create modal | Modal renders |
| 3 | Select student_result_id | Dropdown |
| 4 | Select subject_id | Dropdown |
| 5 | Select ia_type_id | Dropdown |
| 6 | Enter max_marks: 25 | Input |
| 7 | Enter marks_obtained: 20 | Input |
| 8 | is_active default true | Checked |
| 9 | Submit via fetch() | AJAX POST |
| 10 | Verify Gate::authorize | Passes |
| 11 | Verify validated() | All rules |
| 12 | Verify record created | DB |
| 13 | Verify activityLog | Logged |
| 14 | Verify Swal.fire success | Toast |

### TC-P-11: Toggle status ON via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update | Authorized |
| 2 | Navigate to index | List |
| 3 | Click status-switch (inactive record) | AJAX |
| 4 | Verify JSON: success=true, is_active=true | Response |
| 5 | Verify badge updates to active | Visual |

### TC-N-11: Duplicate 3-field composite

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: result=1, subject=1, ia_type=1 | Success |
| 2 | Open create modal | Form |
| 3 | Same result+subject+type | Duplicate |
| 4 | Submit | Validation error |
| 5 | Verify unique error shown | Message |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — Lines 39-53

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 40 | `Gate::authorize('tenant.msh-student-ia-marks.viewAny')` | Auth gate |
| 02 | 43 | `$query = StudentIaMark::with(['studentResult','subject','iaType'])` | Eager load 3 relations |
| 03 | 45 | `->when($request->filled('search'), fn($q)=>)` | Conditional search filter |
| 04 | 46 | `$q->where('subject_id','like',...)->orWhere(...)` | Multi-field LIKE search |
| 05 | 48 | `->when($request->filled('status'), fn($q)=>)` | Conditional status filter |
| 06 | 49 | `$q->where('is_active', (bool)$request->status)` | Boolean cast for type safety |
| 07 | 51 | `->latest()->paginate(10)->withQueryString()` | Paginate 10 with filter persistence |
| 08 | 53 | `return view('...student-ia-marks.index', compact('iaMarks'))` | Return view with data |

#### CODE-TRACE-02: `create()` — Lines 55-58

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 56 | `Gate::authorize('tenant.msh-student-ia-marks.create')` | Authorization |
| 02 | 58 | `return view('...student-ia-marks.create')` | Return modal view |

#### CODE-TRACE-03: `store(StudentIaMarkRequest $request)` — Lines 60-72

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 64 | `Gate::authorize('tenant.msh-student-ia-marks.create')` | Authorization |
| 02 | 66 | `$iaMark = StudentIaMark::create($request->validated())` | Create record from validated data |
| 03 | 68 | `activityLog($iaMark, 'Stored', [...])` | Log creation event |
| 04 | 71 | `return redirect()->route(...)->with('success', flash('created.student-ia-marks'))` | Redirect with flash |

#### CODE-TRACE-04: `show($id)` — Lines 74-84

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 78 | `Gate::authorize('tenant.msh-student-ia-marks.view')` | Authorization |
| 02 | 80 | `$iaMark = StudentIaMark::findOrFail($id)` | Find or throw 404 |
| 03 | 83 | `return view('...student-ia-marks.show', compact('iaMark'))` | Return show view |

#### CODE-TRACE-05: `edit($id)` — Lines 86-96

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 90 | `Gate::authorize('tenant.msh-student-ia-marks.update')` | Authorization |
| 02 | 92 | `$iaMark = StudentIaMark::findOrFail($id)` | Find or throw 404 |
| 03 | 95 | `return view('...student-ia-marks.edit', compact('iaMark'))` | Return modal edit view |

#### CODE-TRACE-06: `update(StudentIaMarkRequest $request, $id)` — Lines 98-126

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 104 | `Gate::authorize('tenant.msh-student-ia-marks.update')` | Authorization |
| 02 | 106 | `$iaMark = StudentIaMark::findOrFail($id)` | Find or throw 404 |
| 03 | 107 | `$original = $iaMark->getOriginal()` | Snapshot original attributes |
| 04 | 108 | `$iaMark->update($request->validated())` | Update with validated data |
| 05 | 111-114 | `foreach($iaMark->getChanges() as $field=>$newValue)` | Compute changed attributes |
| 06 | 112 | `if($field === 'updated_at') continue` | Exclude timestamp |
| 07 | 113 | `$changes[$field] = ['old'=>$original[$field],'new'=>$newValue]` | Structure change data |
| 08 | 116-119 | `activityLog($iaMark, 'Updated', [...])` | Log update with changes |
| 09 | 122 | `return redirect()->route(...)->with('success', flash('updated.student-ia-marks'))` | Redirect |

#### CODE-TRACE-07: `destroy($id)` — Lines 128-142

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 132 | `Gate::authorize('tenant.msh-student-ia-marks.delete')` | Authorization |
| 02 | 134 | `$iaMark = StudentIaMark::findOrFail($id)` | Find or throw 404 |
| 03 | 135 | `$iaMark->is_active = false; $iaMark->save()` | Deactivate before delete |
| 04 | 136 | `$iaMark->delete()` | Soft delete |
| 05 | 138 | `activityLog($iaMark, 'Trashed', [...])` | Log soft-delete |
| 06 | 141 | `return redirect()->route(...)->with('success', flash('trashed.student-ia-marks'))` | Redirect |

#### CODE-TRACE-08: `trashed()` — Lines 144-152

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 149 | `Gate::authorize('tenant.msh-student-ia-marks.restore')` | Authorization |
| 02 | 151 | `$iaMarks = StudentIaMark::onlyTrashed()->paginate(10)` | Query only soft-deleted records |
| 03 | 152 | `return view('...student-ia-marks.trash', compact('iaMarks'))` | Return trash view |

#### CODE-TRACE-09: `restore($id)` — Lines 154-174

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 162 | `Gate::authorize('tenant.msh-student-ia-marks.restore')` | Authorization |
| 02 | 164 | `$iaMark = StudentIaMark::onlyTrashed()->findOrFail($id)` | Find only in trashed |
| 03 | 165 | `$iaMark->restore()` | Restore from soft-delete |
| 04 | 166 | `$iaMark->is_active = true; $iaMark->save()` | Reactivate after restore |
| 05 | 170 | `activityLog($iaMark, 'Restored', [...])` | Log restore event |
| 06 | 173 | `return redirect()->route(...)->with('success', flash('restored.student-ia-marks'))` | Redirect |

#### CODE-TRACE-10: `forceDelete($id)` — Lines 176-192

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 181 | `Gate::authorize('tenant.msh-student-ia-marks.forceDelete')` | Authorization |
| 02 | 183 | `$iaMark = StudentIaMark::withTrashed()->findOrFail($id)` | Find any (active or trashed) |
| 03 | 184 | `$iaMark->forceDelete()` | Permanently delete |
| 04 | 186 | `activityLog($iaMark, 'Deleted', [...])` | Log permanent delete |
| 05 | 191 | `return redirect()->route(...)->with('success', flash('force_deleted.student-ia-marks'))` | Redirect |

#### CODE-TRACE-11: `toggleStatus(Request $request, $id)` — Lines 194-210

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 197 | `Gate::authorize('tenant.msh-student-ia-marks.update')` | Authorization |
| 02 | 199 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 03 | 201 | `$iaMark = StudentIaMark::findOrFail($id)` | Find or throw 404 |
| 04 | 202 | `$iaMark->is_active = $request->boolean('is_active'); $iaMark->save()` | Toggle and persist |
| 05 | 204 | `activityLog($iaMark, 'Toggled', [...])` | Log toggle event |
| 06 | 207-208 | `return response()->json(['success'=>true, 'is_active'=>$iaMark->is_active, 'message'=>flash('status_updated.student-ia-marks')])` | JSON AJAX response |

---

## 7. Detailed Test Execution Procedures (Continued)

### TC-P-02: Create IA mark via AJAX modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Click "Add IA Mark" button | Modal opens |
| 3 | Verify form fields: student_result_id, subject_id, ia_type_id, max_marks, marks_obtained | All present |
| 4 | Fill all required fields | Data entered |
| 5 | Click Save (btn-primary) | fetch() POST |
| 6 | Verify X-CSRF-TOKEN header sent | Included |
| 7 | Verify Gate::authorize at store() line 64 | Passes |
| 8 | Verify $request->validated() processes all fields | All valid |
| 9 | Verify StudentIaMark::create() called | Record in DB |
| 10 | Verify activityLog with 'Stored' message | Event logged |
| 11 | Verify Swal.fire success toast | Shown |
| 12 | Verify modal closes | Closed |
| 13 | Verify index table refreshes (or page reloads) | Updated |

### TC-P-07: Edit IA mark via AJAX modal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Navigate to index | List |
| 3 | Click edit action button for record | Modal opens |
| 4 | Verify form prefilled with current values | matches DB |
| 5 | Change marks_obtained from 20 to 25 | Updated |
| 6 | Submit via fetch() PUT | AJAX |
| 7 | Verify Gate::authorize at update() line 104 | Passes |
| 8 | Verify findOrFail retrieves correct record | Found |
| 9 | Verify getOriginal() captures old value = 20 | Captured |
| 10 | Verify update() sets marks_obtained = 25 | Updated |
| 11 | Verify getChanges() detects marks_obtained change | [old:20, new:25] |
| 12 | Verify activityLog with 'Updated' + changes | Logged |
| 13 | Verify Swal.fire success | Toast |
| 14 | Verify modal closes | Closed |

### TC-P-08: Soft-delete IA mark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with delete permission | Authorized |
| 2 | Navigate to index | List |
| 3 | Click delete action button | SweetAlert confirmation |
| 4 | Verify confirm dialog shows "Delete this record?" | Shows |
| 5 | Click "Yes" | Form submits DELETE |
| 6 | Verify Gate::authorize at destroy() line 132 | Passes |
| 7 | Verify is_active = false before save | Deactivated |
| 8 | Verify soft-delete via ->delete() | deleted_at set |
| 9 | Verify activityLog with 'Trashed' message | Logged |
| 10 | Verify redirect to index with success flash | 302 |
| 11 | Verify record no longer in index table | Hidden |
| 12 | Verify record visible in trash page | Listed |

### TC-P-09: Restore IA mark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with restore permission | Authorized |
| 2 | Navigate to trash page | Trashed list |
| 3 | Locate the trashed record | Visible |
| 4 | Click restore action button | Confirmation |
| 5 | Confirm restore | GET restore route |
| 6 | Verify Gate::authorize('...restore') passes | OK |
| 7 | Verify onlyTrashed()->findOrFail() finds record | Found |
| 8 | Verify ->restore() sets deleted_at = null | Restored |
| 9 | Verify is_active = true after restore | Reactivated |
| 10 | Verify activityLog with 'Restored' message | Logged |
| 11 | Verify redirect to index with flash | 302 |
| 12 | Verify record visible in index (active) | Back to list |

### TC-P-10: Force-delete IA mark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with forceDelete permission | Authorized |
| 2 | Navigate to trash page | Trashed list |
| 3 | Click force-delete action button | Confirmation |
| 4 | Confirm permanent deletion | DELETE route |
| 5 | Verify Gate::authorize('...forceDelete') passes | OK |
| 6 | Verify withTrashed()->findOrFail() finds record | Found |
| 7 | Verify ->forceDelete() removes permanently | Gone from DB |
| 8 | Verify activityLog with 'Deleted' message | Logged |
| 9 | Verify redirect to trash with flash | 302 |
| 10 | Verify record gone from trash page | Removed |
| 11 | Verify show route returns 404 | Not found |

### TC-N-06: marks_obtained exceeds max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Open create modal | Form renders |
| 3 | Set max_marks: 25 | Accepted |
| 4 | Set marks_obtained: 30 | Exceeds max |
| 5 | Submit form | Validation error |
| 6 | Verify error message: "marks_obtained must not exceed max_marks" | Shown on form |

### TC-N-11: Duplicate 3-field composite (continued)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create IA mark with result=1, subject=1, ia_type=1 | Success |
| 2 | Open create modal for same combination | Form |
| 3 | Select result=1, subject=1, ia_type=1 | Duplicate |
| 4 | Submit form | Validation error |
| 5 | Verify unique composite error message | "already exists" |

### TC-N-12: Access index without viewAny permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT student-ia-marks.viewAny | No permission |
| 2 | Navigate to /student-ia-marks | Gate::authorize throws |
| 3 | Verify 403 Forbidden response | Access denied |
| 4 | Verify no DB queries executed | Gate stops before queries |

### TC-INT-01: Create → appears in index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to index | Current list |
| 2 | Note total records count | Baseline |
| 3 | Create new IA mark via modal | Success |
| 4 | Navigate to index (or page reloads) | Page refreshes |
| 5 | Verify new record appears in list | Present |
| 6 | Verify count incremented by 1 | +1 |

### TC-INT-06: Status toggle reflected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current is_active state of record | Baseline |
| 2 | Click status-switch | AJAX toggle |
| 3 | Verify JSON response | success=true |
| 4 | Verify badge changed (active ↔ inactive) | Visual |
| 5 | Click status-switch again | AJAX toggle back |
| 6 | Verify returned to original state | Same as baseline |

---

### CODE-TRACE-HUB: `results()` IA-Marks Tab — MarksheetGenerationController Lines 201-216

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 202 | `[$iamQuery, $iamClassSectionId] = $makeResultQuery('iam_class_section_id')` | Invoke closure with 'iam_class_section_id' param |
| 02 | 203 | `$iaResults = $iamQuery->paginate(10, ['*'], 'iam_page')` | Paginate 10 per page, unique paginator 'iam_page' |
| 03 | 204 | `if ($iaResults->isNotEmpty())` | Only batch-load if visible results exist |
| 04 | 205 | `$pairs = $iaResults->map(fn($r) => [$r->schedule_id, $r->student_id])` | Extract (schedule_id, student_id) tuples |
| 05 | 206 | `$allIaRows = StudentIaMark::with(['subject', 'templateIaComponent.iaComponentType'])` | Batch query with nested eager load |
| 06 | 207-211 | `->where(function($q) use ($pairs) { ... })->orderBy('subject_id')->get()` | Dynamic where for all pairs + order by subject |
| 07 | 212 | `$grouped = $allIaRows->groupBy(fn($r) => $r->schedule_id . '-' . $r->student_id)` | Group by composite key |
| 08 | 213-215 | `foreach ($iaResults as $sr) { $sr->setRelation('iaMarks', $grouped->get($key, collect())) }` | Attach grouped IA marks via setRelation() |

### CODE-TRACE-UPDATED: Actual Controller Methods — StudentIaMarkController

#### CODE-TRACE-01-UPDATED: `index()` — Lines 13-22

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 15 | `Gate::authorize('tenant.msh-student-ia-mark.viewAny')` | Auth gate — singular permission key |
| 02 | 17 | `StudentIaMark::with(['marksheetSchedule', 'student', 'subject', 'templateIaComponent'])` | Eager load 4 relations |
| 03 | 19 | `->latest()->paginate(20)` | Paginate 20 per page (NOT 10) |
| 04 | 21 | `return view('marksheetgeneration::student-ia-mark.index', compact('marks'))` | Return view with 'marks' variable |

#### CODE-TRACE-03-UPDATED: `store(StudentIaMarkRequest $request)` — Lines 31-59

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 33 | `Gate::authorize('tenant.msh-student-ia-mark.create')` | Auth gate |
| 02 | 35 | `$validatedData = $request->validated()` | Validate input |
| 03 | 36-38 | `$validatedData['created_by'] = auth()->id(); ['entered_by'] = auth()->id(); ['entered_at'] = now()` | Set audit fields |
| 04 | 40 | `$mark = StudentIaMark::create($validatedData)` | Create record |
| 05 | 42-44 | `activityLog($mark, 'Stored', ['message' => ...])` | Log creation |
| 06 | 46-48 | `$redirect = redirect()...with('success', flash('created.student_ia_mark'))` | Standard redirect |
| 07 | 50-55 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response for AJAX modal |
| 08 | 58 | `return $redirect` | Fallback to standard redirect |

#### CODE-TRACE-06-UPDATED: `update()` — Lines 77-105

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 79 | `Gate::authorize('tenant.msh-student-ia-mark.update')` | Auth gate |
| 02 | 81-84 | `$validatedData['updated_by'] = auth()->id(); ['entered_by'] = auth()->id(); ['entered_at'] = now()` | Set audit fields |
| 03 | 86 | `$studentIaMark->update($validatedData)` | Update record (NO getOriginal/getChanges) |
| 04 | 88-90 | `activityLog($studentIaMark, 'Updated', ['message' => ...])` | Log update |
| 05 | 92-94 | `$redirect = redirect()...with('success', flash('updated.student_ia_mark'))` | Standard redirect |
| 06 | 96-101 | `if ($request->expectsJson()) { return response()->json([...]) }` | JSON response for AJAX modal |
| 07 | 104 | `return $redirect` | Fallback redirect |

#### CODE-TRACE-07-UPDATED: `destroy(StudentIaMark $studentIaMark)` — Lines 107-120

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 109 | `Gate::authorize('tenant.msh-student-ia-mark.delete')` | Auth gate |
| 02 | 111 | `$studentIaMark->delete()` | Soft delete directly (no is_active=false) |
| 03 | 113-115 | `activityLog($studentIaMark, 'Deleted', ['message' => ...])` | Log 'Deleted' (not 'Trashed') |
| 04 | 117-119 | `redirect()->route('marksheet-generation.results.combined', ['tab' => 'ia-marks'])->with('success', flash('deleted.student_ia_mark'))` | Redirect to combined results tab |

#### CODE-TRACE-08-UPDATED: `trashed()` — Lines 134-141

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 136 | `Gate::authorize('tenant.msh-student-ia-mark.viewAny')` | Auth gate (same as index) |
| 02 | 138 | `StudentIaMark::onlyTrashed()->latest()->paginate(15)` | Only soft-deleted, paginate 15 |
| 03 | 140 | `return view('marksheetgeneration::trashed.student-ia-mark', compact('trashed'))` | Return trash view |

#### CODE-TRACE-09-UPDATED: `restore($id)` — Lines 143-154

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 145 | `Gate::authorize('tenant.msh-student-ia-mark.update')` | Auth gate (uses update permission) |
| 02 | 147 | `$record = StudentIaMark::onlyTrashed()->findOrFail($id)` | Find only in trash |
| 03 | 148 | `$record->restore()` | Restore soft-delete |
| 04 | 149 | `$record->update(['is_active' => true])` | Reactivate after restore |
| 05 | 151 | `activityLog($record, 'Restored', ['message' => ...])` | Log restore |
| 06 | 153 | `redirect()->route('marksheet-generation.student-ia-mark.trashed')->with('success', ...)` | Redirect back to trash |

#### CODE-TRACE-10-UPDATED: `forceDelete($id)` — Lines 156-172

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 158 | `Gate::authorize('tenant.msh-student-ia-mark.delete')` | Auth gate (uses delete permission) |
| 02 | 160 | `$record = StudentIaMark::withTrashed()->findOrFail($id)` | Find any (active or trashed) |
| 03 | 161 | `try { $record->forceDelete() }` | Permanently delete |
| 04 | 162 | `activityLog($record, 'Deleted', ['message' => ...])` | Log permanent delete |
| 05 | 163-168 | `catch (QueryException $e) { if ($e->getCode() === '23000') { ... } }` | Handle FK constraint gracefully |
| 06 | 166 | `redirect()->back()->with('error', 'Cannot delete this record because it is referenced by other records.')` | User-friendly FK error |
| 07 | 171 | `redirect()->route('marksheet-generation.student-ia-mark.trashed')->with('success', ...)` | Success redirect |

#### CODE-TRACE-11-UPDATED: `toggleStatus($id)` — Lines 122-132

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 124 | `Gate::authorize('tenant.msh-student-ia-mark.update')` | Auth gate |
| 02 | 126 | `$record = StudentIaMark::findOrFail($id)` | Find record |
| 03 | 127 | `$record->update(['is_active' => !$record->is_active, 'updated_by' => auth()->id()])` | Toggle is_active directly |
| 04 | 129 | `activityLog($record, 'Toggled', ['message' => 'Status was toggled.'])` | Log toggle |
| 05 | 131 | `return response()->json(['success'=>true, 'is_active'=>$record->is_active, 'message'=>...])` | JSON response |

### Additional BC-BIZ-DEEP: Actual Controller Behavior

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-41 | Controller permission key is `tenant.msh-student-ia-mark.*` (singular 'mark') | `tenant.msh-student-ia-mark.viewAny` etc. |
| BC-BIZ-DEEP-42 | `index()` paginates at 20 per page | `->paginate(20)` |
| BC-BIZ-DEEP-43 | `index()` eager loads 4 relations | marksheetSchedule, student, subject, templateIaComponent |
| BC-BIZ-DEEP-44 | `store()` sets 3 audit fields | created_by, entered_by, entered_at (now()) |
| BC-BIZ-DEEP-45 | `store()` supports JSON response via `$request->expectsJson()` | JSON includes status, message, redirect URL |
| BC-BIZ-DEEP-46 | `update()` sets 3 audit fields | updated_by, entered_by, entered_at (now()) |
| BC-BIZ-DEEP-47 | `update()` does NOT use getOriginal()/getChanges() | Simple activityLog without change tracking |
| BC-BIZ-DEEP-48 | `update()` supports JSON response | Same pattern as store() |
| BC-BIZ-DEEP-49 | `destroy()` does NOT deactivate before soft-delete | Direct ->delete() without is_active=false |
| BC-BIZ-DEEP-50 | `destroy()` logs 'Deleted' not 'Trashed' | activityLog action = 'Deleted' |
| BC-BIZ-DEEP-51 | `destroy()` redirects to `results.combined?tab=ia-marks` | Not to index |
| BC-BIZ-DEEP-52 | `trashed()` uses `viewAny` permission (same as index) | `Gate::authorize('tenant.msh-student-ia-mark.viewAny')` |
| BC-BIZ-DEEP-53 | `trashed()` paginates at 15 per page | `->paginate(15)` — different from index's 20 |
| BC-BIZ-DEEP-54 | `restore()` uses `update` permission | `Gate::authorize('tenant.msh-student-ia-mark.update')` |
| BC-BIZ-DEEP-55 | `restore()` sets is_active=true after restore | `$record->update(['is_active' => true])` |
| BC-BIZ-DEEP-56 | `restore()` redirects to trashed page, not index | Back to trash listing |
| BC-BIZ-DEEP-57 | `forceDelete()` uses `delete` permission | `Gate::authorize('tenant.msh-student-ia-mark.delete')` |
| BC-BIZ-DEEP-58 | `forceDelete()` catches QueryException 23000 (FK violation) | Graceful error message |
| BC-BIZ-DEEP-59 | `forceDelete()` uses `withTrashed()` to find any record | Both active and trashed can be force-deleted |
| BC-BIZ-DEEP-60 | `toggleStatus()` finds record by manual $id not route-model-binding | `StudentIaMark::findOrFail($id)` — not route-bound |
| BC-BIZ-DEEP-61 | `toggleStatus()` toggles via `!$record->is_active` | Inverts current value |
| BC-BIZ-DEEP-62 | `toggleStatus()` uses `update()` not separate save | `$record->update(['is_active' => !$record->is_active, ...])` |
| BC-BIZ-DEEP-63 | `edit()` redirects to `results.combined?tab=ia-marks` | NOT an edit form — inline edit via modal on tab page |
| BC-BIZ-DEEP-64 | `show()` eager loads 5 relations | marksheetSchedule, student, subject, templateIaComponent.iaComponentType, enteredByUser |
| BC-BIZ-DEEP-65 | `show()` uses `->load()` not `->with()` | Lazy eager load after route resolution |
| BC-BIZ-DEEP-66 | `create()` returns blank modal view | `return view('marksheetgeneration::student-ia-mark.create')` |
| BC-BIZ-DEEP-67 | `destroy()` flash uses `deleted.student_ia_mark` key | `flash('deleted.student_ia_mark')` |
| BC-BIZ-DEEP-68 | `update()` flash uses `updated.student_ia_mark` key | `flash('updated.student_ia_mark')` |
| BC-BIZ-DEEP-69 | `store()` flash uses `created.student_ia_mark` key | `flash('created.student_ia_mark')` |
| BC-BIZ-DEEP-70 | `toggleStatus()` message varies by new state | "Status set to Active" or "Status set to Inactive" |
| BC-BIZ-DEEP-71 | `results()` hub IA Marks uses `iam_class_section_id` param | Distinct from sr_/ssr_/csr_ params |
| BC-BIZ-DEEP-72 | `results()` hub IA Marks paginator name `iam_page` | Independent from other tabs |
| BC-BIZ-DEEP-73 | `results()` hub IA Marks batch query eager loads subject + iaComponentType | Nested: `templateIaComponent.iaComponentType` |
| BC-BIZ-DEEP-74 | `results()` hub IA Marks ordered by subject_id | `->orderBy('subject_id')` |
| BC-BIZ-DEEP-75 | `results()` hub legacy alias `$iaMarks = $iaResults` at line 236 | Backward compat for existing views |
| BC-BIZ-DEEP-76 | `results()` hub loads `$iaComponents` reference list at line 243 | `TemplateIaComponent::with('iaComponentType')->get()` |
| BC-BIZ-DEEP-77 | `results()` hub controller has 320 lines with all 4 tabs | Student Results, Subject Results, IA Marks, Coscholastic |
| BC-BIZ-DEEP-78 | `results()` hub returns 21 variables in compact() | `'studentResults', 'subjectResults', 'iaMarks', 'coscholasticResults', ...` |
| BC-BIZ-DEEP-79 | No search/status filters on standalone index() | Query uses only ->latest()->paginate(20) |
| BC-BIZ-DEEP-80 | All CRUD methods use `Gate::authorize()` as first executable line | Before any DB query |

### Additional Test Cases

#### TC-P: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-21 | Index paginates 20 per page | 25 records | Page 1 = 20, Page 2 = 5 |
| TC-P-22 | Index eager loads 4 relations | View index | marksheetSchedule, student, subject, templateIaComponent visible |
| TC-P-23 | Store sets created_by/entered_by/entered_at | Create via POST | All 3 audit fields set |
| TC-P-24 | Store via AJAX returns JSON | expectsJson() header | JSON with status=true, redirect URL |
| TC-P-25 | Store via standard POST returns redirect | No JSON header | Standard 302 redirect |
| TC-P-26 | Update sets updated_by/entered_by/entered_at | Edit via PUT | All 3 audit fields updated |
| TC-P-27 | Update via AJAX returns JSON | expectsJson() header | JSON with status=true |
| TC-P-28 | Soft-delete via destroy | Click delete | Record in trash, deleted_at set |
| TC-P-29 | Destroy redirects to results.combined tab | After delete | Redirect to combined results, ia-marks tab |
| TC-P-30 | Trash page paginates 15 | 20 trashed records | Page 1 = 15, Page 2 = 5 |
| TC-P-31 | Trash page uses onlyTrashed() | View trash | Only soft-deleted records shown |
| TC-P-32 | Restore sets is_active=true | Restore from trash | is_active = true |
| TC-P-33 | Restore redirects back to trash | After restore | Redirect to trashed page |
| TC-P-34 | ForceDelete permanently removes | Force delete | Record gone, 404 on show |
| TC-P-35 | ForceDelete with FK constraint catches exception | Referenced record | User-friendly error message |
| TC-P-36 | ToggleStatus inverts is_active | Toggle ON then OFF | State toggles back |
| TC-P-37 | ToggleStatus returns JSON with message | AJAX response | "Status set to Active" or "Inactive" |
| TC-P-38 | ToggleStatus uses update() method | DB check | is_active value inverted in DB |
| TC-P-39 | Show loads 5 relations | View detail | All relations displayed |
| TC-P-40 | Edit redirects to combined results tab | Click edit | Redirect to results.combined?tab=ia-marks |
| TC-P-41 | results() hub IA Marks with iam_class_section_id | Select section | Filtered results |
| TC-P-42 | results() hub IA Marks iam_page pagination | Navigate pages | Independent page state |
| TC-P-43 | results() hub IA Marks batch query with pairs | 10 visible students | Single batch query |
| TC-P-44 | results() hub $iaMarks legacy alias | Existing view | Same data as $iaResults |
| TC-P-45 | results() hub nested eager: templateIaComponent.iaComponentType | View IA marks | Component type name visible |

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
| TC-N-50 | Store without subject_id | Required | Validation error |
| TC-N-51 | Store without template_ia_component_id | Required | Validation error |
| TC-N-52 | Store without marks_obtained | Required | Validation error |
| TC-N-53 | Store without max_marks | Required | Validation error |
| TC-N-54 | marks_obtained = -5 | Negative | Validation error |
| TC-N-55 | max_marks = 0 | Zero | Validation error |
| TC-N-56 | marks_obtained > max_marks | Exceeds | Validation error |
| TC-N-57 | Duplicate (student_id+schedule_id+subject_id+template_ia_component_id) | 4-field unique | Validation error |
| TC-N-58 | Non-existent student_result_id FK | Invalid | Validation error |
| TC-N-59 | Non-existent subject_id FK | Invalid | Validation error |
| TC-N-60 | Non-existent ia_type_id FK | Invalid | Validation error |
| TC-N-61 | Update without sending any changed fields | Empty diff | Success (no changes) |
| TC-N-62 | ForceDelete with FK constraint (23000) | Referenced child | Error message, record preserved |
| TC-N-63 | ToggleStatus with invalid ID type | Non-numeric string | 404 |
| TC-N-64 | Store with non-boolean is_active | "true" string | Boolean normalization |
| TC-N-65 | Update with invalid entered_at format | Bad date | Validation error |
| TC-N-66 | Max marks as non-numeric string | "abc" | Validation error |
| TC-N-67 | Missing X-CSRF-TOKEN on AJAX modal | No header | 419 |
| TC-N-68 | AJAX expectsJson header without proper Accept | Wrong header | Returns HTML redirect instead of JSON |
| TC-N-69 | trashed() with onlyTrashed when no trashed records exist | Empty trash | Empty state displayed |
| TC-N-70 | restore() on already restored record (double restore) | Second restore after first | 404 (no longer in onlyTrashed) |

#### TC-SQ: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-06 | SQLi in marks_obtained | `25; DROP TABLE` | validated() rejects non-numeric |
| TC-SQ-07 | XSS in remarks | `<script>alert(1)</script>` | Blade auto-escapes |
| TC-SQ-08 | Mass assignment via AJAX | Extra fields in JSON | validated() blocks non-fillable |
| TC-SQ-09 | Missing CSRF on AJAX POST | No X-CSRF-TOKEN | 419 |
| TC-SQ-10 | Route parameter pollution | Multiple IDs | Route-model-binding uses last |

#### TC-INT: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-08 | Create via AJAX → record in DB | Modal submit | Record exists after response |
| TC-INT-09 | Update via AJAX → DB reflects change | Modal edit | Changed value persisted |
| TC-INT-10 | Soft-delete → trash visible → restore → active | Full lifecycle | State transitions correct |
| TC-INT-11 | Force-delete → record gone from DB | Permanent delete | Cannot find in DB |
| TC-INT-12 | ToggleStatus → JSON response → UI update | AJAX flow | is_active changed both in DB and UI |
| TC-INT-13 | results() hub IA Marks batch loading efficiency | 10 students × 3 IA types | 1 batch query instead of 10 |
| TC-INT-14 | results() hub cross-tab pagination independence | Tab1 page 2 → Tab2 page 1 | Each tab has unique paginator |
| TC-INT-15 | results() hub $iaMarks legacy alias works | Check view variable | Same data as $iaResults |
| TC-INT-16 | Store → Show page with all relations | Create then view | 5 relations loaded |
| TC-INT-17 | Trash → Restore → Index visibility | Restore flow | Record appears in index |
| TC-INT-18 | Force-delete blocked by FK → record preserved | FK violation | Record still in trash |
| TC-INT-19 | AJAX modal validation errors → form stays open | Bad input | Form stays, errors displayed |
| TC-INT-20 | Edit redirect to combined results tab | Click edit | Tab=ia-marks active after redirect |

### Additional Detailed Test Execution Procedures

#### TC-P-23: Store sets audit fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Submit create form with valid data | POST |
| 3 | Verify Gate::authorize at line 33 | Passes |
| 4 | Verify validated() at line 35 | All rules pass |
| 5 | Verify created_by = auth()->id() at line 36 | Set |
| 6 | Verify entered_by = auth()->id() at line 37 | Set |
| 7 | Verify entered_at = now() at line 38 | Current timestamp |
| 8 | Verify create() at line 40 | Record in DB |
| 9 | Verify activityLog 'Stored' at line 42 | Logged |
| 10 | Verify JSON response when expectsJson() | status=true |

#### TC-P-24: Store via AJAX returns JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Accept: application/json header | expectsJson() = true |
| 2 | Submit valid form data via fetch() | AJAX POST |
| 3 | Verify response status 200 | OK |
| 4 | Verify JSON body: `{"status": true, "message": "...", "redirect": "..."}` | Correct structure |
| 5 | Verify no redirect/HTML returned | JSON only |
| 6 | Verify Swal.fire called on frontend | Toast notification |

#### TC-P-35: ForceDelete with FK constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create IA mark record that has child references | Referenced |
| 2 | Navigate to trash page | Trash list |
| 3 | Click force-delete for that record | DELETE request |
| 4 | Verify Gate::authorize at line 158 | Passes |
| 5 | Verify withTrashed()->findOrFail() finds record | Found |
| 6 | Verify forceDelete() throws QueryException 23000 | FK violation |
| 7 | Verify catch block at line 163 | Executed |
| 8 | Verify error message: "Cannot delete this record because it is referenced by other records." | User-friendly |
| 9 | Verify redirect back to trash page | Back |
| 10 | Verify record still exists in trash | Not deleted |

#### TC-P-36: ToggleStatus inverts is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Find record with is_active = true | Baseline |
| 2 | POST to toggleStatus for that record | AJAX |
| 3 | Verify Gate::authorize at line 124 | Passes |
| 4 | Verify findOrFail at line 126 | Record found |
| 5 | Verify update at line 127: is_active = !true = false | Inverted |
| 6 | Verify activityLog 'Toggled' at line 129 | Logged |
| 7 | Verify JSON: is_active = false | Correct response |
| 8 | Toggle again | is_active = true |
| 9 | Verify state returns to original | Round-trip |

#### TC-N-46: Restore non-trashed record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure record is active (not trashed) | is_active=true, deleted_at=null |
| 2 | POST to restore route with this ID | GET restore request |
| 3 | Verify Gate::authorize at line 145 | Passes |
| 4 | Verify onlyTrashed()->findOrFail() at line 147 | NOT FOUND |
| 5 | Verify 404 ModelNotFoundException | Thrown |
| 6 | Verify no changes to record | State unchanged |

#### TC-P-41: results() hub IA Marks with class-section filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Results hub | Page loads |
| 2 | Click IA Marks tab | Tab activates |
| 3 | Select class-section from dropdown | ?tab=ia-marks&iam_class_section_id=X |
| 4 | Verify $makeResultQuery called with 'iam_class_section_id' | Closure invoked |
| 5 | Verify where('class_section_id', $csId) applied | Filter active |
| 6 | Verify orderByDesc('grand_total') | Sorted by marks |
| 7 | Verify paginate using 'iam_page' | Paginator name correct |
| 8 | Verify batch query runs for visible students | Single query |
| 9 | Verify grouped by schedule_id + '-' + student_id | Correct grouping |

#### TC-N-58: Non-existent student_result_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create modal | Form |
| 2 | Select student_result_id = 99999 | Non-existent |
| 3 | Fill all other required fields | Valid |
| 4 | Submit form | Validation error |
| 5 | Verify "The selected student result id is invalid." | Error shown |

### Additional BC-BIZ-DEEP: Deep Business Conditions — IIA Mark Additional Scenarios

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-81 | `results()` IA Marks tab uses `$makeResultQuery` closure | Same closure pattern as other result tabs |
| BC-BIZ-DEEP-82 | IA Marks tab applies filters only when `$request->input('tab') === 'ia-marks'` | Tab-scoped filter isolation |
| BC-BIZ-DEEP-83 | Inline IA marks loaded via `StudentIaMark::whereIn('student_result_id', $ids)` | Batch WHERE IN via joined IDs |
| BC-BIZ-DEEP-84 | Standalone `toggleStatus()` toggles `is_active` only | No soft-delete toggle |
| BC-BIZ-DEEP-85 | Standalone `trashed()` uses `onlyTrashed()->latest()->paginate(10)` | Paginated 10 per page |
| BC-BIZ-DEEP-86 | Standalone `restore()` sets `is_active = true` after `restore()` | Reactivation |
| BC-BIZ-DEEP-87 | Standalone `forceDelete()` calls `forceDelete()` directly | Permanent removal |
| BC-BIZ-DEEP-88 | `StudentIaMarkRequest` validates `marks_obtained` range | Min 0, max per component |
| BC-BIZ-DEEP-89 | `StudentIaMarkRequest` validates `student_result_id` unique per ia_component_type_id | No duplicate per result+component |
| BC-BIZ-DEEP-90 | `StudentIaMarkRequest` auto-fills `organization_id` and `session_id` | Hidden fields |
| BC-BIZ-DEEP-91 | `StudentIaMarkRequest` conditional required on `is_lab_work` | Lab-specific fields |
| BC-BIZ-DEEP-92 | Standalone `create()` loads iaComponentTypes for dropdown | Reference list |
| BC-BIZ-DEEP-93 | Standalone `edit()` loads iaComponentTypes + existing marks | Pre-populated |
| BC-BIZ-DEEP-94 | StudentIaMark model has `belongsTo(StudentResult::class)` | FK relation |
| BC-BIZ-DEEP-95 | StudentIaMark model has `belongsTo(IaComponentType::class)` | Component relation |

### Additional Test Cases

#### TC-P-25 to TC-P-45: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-25 | Inline IA marks batch WHERE IN query | Results exist | Batch returns data |
| TC-P-26 | ToggleStatus from active to inactive | AJAX toggle | is_active = 0 |
| TC-P-27 | ToggleStatus from inactive to active | AJAX toggle | is_active = 1 |
| TC-P-28 | Restore soft-deleted record | Trash → Restore | Record restored, is_active = 1 |
| TC-P-29 | forceDelete permanently removes | Trash → force delete | Record gone |
| TC-P-30 | Trashed list with deleted records | Has deleted | Paginated 10 |
| TC-P-31 | Validation: marks_obtained = 0 (minimum) | Submit 0 | Accepted |
| TC-P-32 | Validation: marks_obtained = max value | Submit max | Accepted |
| TC-P-33 | Create with unique student_result_id + ia_component_type_id | New combination | Created |
| TC-P-34 | Edit with updated marks_obtained | Change value | Updated |
| TC-P-35 | Index filter by student_result_id | Select filter | Filtered |
| TC-P-36 | Index filter by ia_component_type_id | Select filter | Filtered |
| TC-P-37 | Index search by mark value | Search field | LIKE on marks |
| TC-P-38 | Show page loads all fields | View record | All fields display |
| TC-P-39 | Show page with student name display | From relation | Name + ID shown |
| TC-P-40 | Create form loads iaComponentType dropdown | Dropdown | Options populated |
| TC-P-41 | Edit form pre-selects existing ia_component_type_id | Preserved | Correct option selected |
| TC-P-42 | Index with status filter = active | is_active = 1 | Only active |
| TC-P-43 | Index with status filter = inactive | is_active = 0 | Only inactive |
| TC-P-44 | ToggleStatus JSON response structure | Check response | Success + is_active + message |
| TC-P-45 | Trash page with no records | Empty trash | Empty state |

#### TC-N-25 to TC-N-45: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-25 | ToggleStatus no permission | No update permission | 403 |
| TC-N-26 | Restore no permission | No restore permission | 403 |
| TC-N-27 | Force delete no permission | No forceDelete | 403 |
| TC-N-28 | Create duplicate student_result_id + ia_component_type_id | Same pair | Validation error |
| TC-N-29 | marks_obtained negative | -1 | Validation error |
| TC-N-30 | marks_obtained exceeds max | Max + 1 | Validation error |
| TC-N-31 | Delete already deleted record | Double delete | 404 |
| TC-N-32 | Restore non-deleted record | Active record | 404 |
| TC-N-33 | Force delete active record | Not in trash | 404 |
| TC-N-34 | Show non-existent ID | Wrong ID | 404 |
| TC-N-35 | Edit non-existent ID | Wrong ID | 404 |
| TC-N-36 | Update non-existent record | Wrong ID in PUT | 404 |
| TC-N-37 | ToggleStatus non-existent ID | Wrong ID | 404 |
| TC-N-38 | ToggleStatus missing is_active param | Not provided | Validation error |
| TC-N-39 | ToggleStatus invalid boolean | "not-a-boolean" | Validation error |
| TC-N-40 | Inline IA marks with 0 student_result_ids | isNotEmpty false | Query skipped |
| TC-N-41 | Create with missing required fields | Empty form | Validation errors |
| TC-N-42 | Trash page with all records active | No deleted | Empty state |
| TC-N-43 | forceDelete on already forceDeleted record | Double delete | 404 |
| TC-N-44 | XSS in marks_obtained field | Script tag | Escaped in view |
| TC-N-45 | SQLi in search parameter | Injection | Query builder escapes |

#### TC-SQ-09 to TC-SQ-16: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-9 | ToggleStatus CSRF bypass | No token | 419 |
| TC-SQ-10 | forceDelete without method override | GET request | 405 |
| TC-SQ-11 | Restore non-restorable (non-deleted) | Wrong state | 404 |
| TC-SQ-12 | AJAX toggleStatus with wrong content type | text/html | JSON expected |
| TC-SQ-13 | Trash page access without permission | No restore | 403 |
| TC-SQ-14 | forceDelete on ID = 0 | Edge case | 404 |
| TC-SQ-15 | Bulk DELETE by ID enumeration | Sequential IDs | Only authorized |
| TC-SQ-16 | Session expiry during AJAX toggle | Redirect | Login page returned |

#### TC-INT-21: Create IA mark → hub reflects in list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone IA marks index | Note current count |
| 2 | Open create modal | Form loads |
| 3 | Fill required fields, submit | Created |
| 4 | Navigate to Results hub → IA marks tab | Hub loads |
| 5 | Verify new IA mark visible in inline list | Reflected |

#### TC-INT-22: Delete IA mark → hub list updates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone IA marks index | Has records |
| 2 | Delete an IA mark | Soft deleted |
| 3 | Navigate to Results hub → IA marks tab | Hub loads |
| 4 | Verify deleted mark no longer in inline list | Removed |

---

*Template: tpt_Vehicle_TcList.md | Entity: StudentIAMarks | Date: 2026-07-22*
