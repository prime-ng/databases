# MarksheetGeneration Student Subject Results — TC_List

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | StudentSubjectResults (`msh_student_subject_results`) — CRUD for per-subject marks within a student result |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\StudentSubjectResultController` |
| **Model** | `Modules\MarksheetGeneration\Models\StudentSubjectResult` (SoftDeletes, 15 fillable fields) |
| **Form Request** | `StudentSubjectResultRequest` (create/update with composite unique) |
| **Policy** | No explicit Policy — uses `Gate::authorize('tenant.msh-student-subject-results.*')` |
| **Route Prefix** | `marksheet-generation.student-subject-results` |
| **Blade Views** | index, create, edit, show — 4 views (no destroy/trash/restore) |
| **DB Table** | `msh_student_subject_results` — 20+ columns with theory/practical breakdown |
| **Relationships** | belongsTo(studentResult), belongsTo(subject), belongsTo(gradeScale) |
| **Fillable Fields** | student_result_id, subject_id, grade_scale_id, max_marks, theory_max_marks, practical_max_marks, marks_obtained, theory_marks_obtained, practical_marks_obtained, percentage, grade, grade_points, is_active, remarks |
| **Soft Delete** | Yes — `deleted_at` column exists but no trash/restore/forceDelete routes |

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with appropriate permission for each action |
| PC-02 | `msh_student_subject_results` table migrated with correct schema including theory/practical columns |
| PC-03 | `msh_student_results` table exists (parent FK → student_result_id) |
| PC-04 | `sub_subjects` table exists (subject FK) with name, code, max_marks |
| PC-05 | `msh_grade_scales` table exists (grade scale FK — optional) |
| PC-06 | StudentSubjectResult model uses SoftDeletes trait |
| PC-07 | FormRequest has create/update rules for all 15 fillable fields |
| PC-08 | Composite unique: `student_result_id + subject_id` |
| PC-09 | Routes: resource (index/create/store/show/edit/update) — no destroy/trash/restore/forceDelete |
| PC-10 | `config/permissionslist.php` has `msh-student-subject-results` group |
| PC-11 | Blade views follow symmetrical @can/@canany pattern |
| PC-12 | `activityLog()` helper registered |
| PC-13 | marks_obtained must be ≤ max_marks |
| PC-14 | theory_marks + practical_marks ≤ marks_obtained or max_marks |
| PC-15 | theory_marks ≤ theory_max_marks |
| PC-16 | practical_marks ≤ practical_max_marks |
| PC-17 | StudentResult exists and is active before subject result creation |
| PC-18 | subject_id references a valid, active subject |
| PC-19 | Parent StudentResult must not be in withheld state |
| PC-20 | Percentage auto-computed via (marks_obtained/max_marks)*100 |

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | `index()`: `StudentSubjectResult::with(['studentResult','subject'])->paginate(10)` | Controller:43-51 |
| DL-02 | `create()`: blank form | Controller:56-58 |
| DL-03 | `store()`: `StudentSubjectResult::create($request->validated())` + `activityLog()` | Controller:66-71 |
| DL-04 | `show($id)`: `StudentSubjectResult::findOrFail($id)` | Controller:80-85 |
| DL-05 | `edit($id)`: `StudentSubjectResult::findOrFail($id)` | Controller:92-97 |
| DL-06 | `update()`: `findOrFail` + `update($request->validated())` + diff + `activityLog()` | Controller:106-122 |

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | Zero subject results | Empty table |
| TD-02 | Single subject result with all fields | Complete record |
| TD-03 | 11 records (paginate) | Page 1=10, Page 2=1 |
| TD-04 | Mixed active/inactive | 3 active, 2 inactive |
| TD-05 | Valid FK: student_result_id exists | Referential integrity |
| TD-06 | Valid FK: subject_id exists | Referential integrity |
| TD-07 | Valid FK: grade_scale_id exists | Optional FK |
| TD-08 | marks_obtained = max_marks | Perfect score |
| TD-09 | marks_obtained = 0 | Minimum score |
| TD-10 | marks_obtained > max_marks | Validation error |
| TD-11 | Duplicate student_result_id + subject_id | Composite unique error |
| TD-12 | Null grade_scale_id | Optional FK |
| TD-13 | Multiple subjects per student result | 6 subjects |
| TD-14 | theory_marks + practical_marks = marks_obtained | Sum matches |
| TD-15 | theory_marks > theory_max_marks | Component validation error |
| TD-16 | practical_marks > practical_max_marks | Component validation error |
| TD-17 | Percentage auto-computed when not provided | Calculated |
| TD-18 | Null theory_marks and practical_marks | Only total marks |
| TD-19 | Subject with very high max_marks (500) | Large value |
| TD-20 | Subject with decimal marks (87.50) | Decimal handling |

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `msh_student_subject_results.id` — BIGINT PK AUTO_INCREMENT | Unique ID | Schema |
| BC-DB-02 | `msh_student_subject_results.student_result_id` — BIGINT FK → msh_student_results.id | FK to parent | Schema |
| BC-DB-03 | `msh_student_subject_results.subject_id` — BIGINT FK → sub_subjects.id | FK to subject | Schema |
| BC-DB-04 | `msh_student_subject_results.grade_scale_id` — BIGINT FK → msh_grade_scales.id NULLABLE | Optional FK | Schema |
| BC-DB-05 | `msh_student_subject_results.max_marks` — DECIMAL(8,2), NOT NULL | Max marks | Schema |
| BC-DB-06 | `msh_student_subject_results.theory_max_marks` — DECIMAL(8,2), NULLABLE | Theory max | Schema |
| BC-DB-07 | `msh_student_subject_results.practical_max_marks` — DECIMAL(8,2), NULLABLE | Practical max | Schema |
| BC-DB-08 | `msh_student_subject_results.marks_obtained` — DECIMAL(8,2), NOT NULL | Marks scored | Schema |
| BC-DB-09 | `msh_student_subject_results.theory_marks_obtained` — DECIMAL(8,2), NULLABLE | Theory scored | Schema |
| BC-DB-10 | `msh_student_subject_results.practical_marks_obtained` — DECIMAL(8,2), NULLABLE | Practical scored | Schema |
| BC-DB-11 | `msh_student_subject_results.percentage` — DECIMAL(5,2), NULLABLE | (obtained/max)*100 | Schema |
| BC-DB-12 | `msh_student_subject_results.grade` — VARCHAR(10), NULLABLE | Letter grade | Schema |
| BC-DB-13 | `msh_student_subject_results.grade_points` — DECIMAL(4,2), NULLABLE | Grade points | Schema |
| BC-DB-14 | `msh_student_subject_results.is_active` — TINYINT(1), DEFAULT 1 | Active | Schema |
| BC-DB-15 | `msh_student_subject_results.remarks` — TEXT, NULLABLE | Remarks | Schema |
| BC-DB-16 | `msh_student_subject_results.deleted_at` — TIMESTAMP, NULLABLE | Soft delete | Schema |
| BC-DB-17 | `msh_student_subject_results.created_at` — TIMESTAMP | Created | Schema |
| BC-DB-18 | `msh_student_subject_results.updated_at` — TIMESTAMP | Updated | Schema |
| BC-DB-19 | `msh_student_results.id` — BIGINT PK | Parent PK | Schema |
| BC-DB-20 | `sub_subjects.id` — BIGINT PK | Subject PK | Schema |
| BC-DB-21 | `sub_subjects.name` — VARCHAR(255) | Subject name | Schema |
| BC-DB-22 | `sub_subjects.code` — VARCHAR(50) | Subject code | Schema |
| BC-DB-23 | `msh_grade_scales.id` — BIGINT PK | Grade scale PK | Schema |
| BC-DB-24 | `msh_grade_scales.grade` — VARCHAR(10) | Grade letter | Schema |
| BC-DB-25 | `msh_grade_scales.points` — DECIMAL(4,2) | Grade points | Schema |
| BC-DB-26 | UNIQUE(student_result_id, subject_id) | No duplicate per result | FormRequest |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `student_result_id` — required, integer, exists:msh_student_results,id | FK must exist | FormRequest |
| BC-VAL-02 | `subject_id` — required, integer, exists:sub_subjects,id | FK must exist | FormRequest |
| BC-VAL-03 | `grade_scale_id` — nullable, integer, exists:msh_grade_scales,id | Optional FK | FormRequest |
| BC-VAL-04 | `max_marks` — required, numeric, min:0, max:999999.99 | Decimal(8,2) | FormRequest |
| BC-VAL-05 | `marks_obtained` — required, numeric, min:0, max:999999.99 | Decimal(8,2) | FormRequest |
| BC-VAL-06 | `marks_obtained` ≤ `max_marks` | Cannot exceed max | FormRequest |
| BC-VAL-07 | `theory_marks_obtained` — nullable, numeric, min:0 | Theory | FormRequest |
| BC-VAL-08 | `practical_marks_obtained` — nullable, numeric, min:0 | Practical | FormRequest |
| BC-VAL-09 | `theory_marks_obtained` ≤ `theory_max_marks` | Component bound | Custom |
| BC-VAL-10 | `practical_marks_obtained` ≤ `practical_max_marks` | Component bound | Custom |
| BC-VAL-11 | `percentage` — nullable, numeric, min:0, max:100 | Percentage | FormRequest |
| BC-VAL-12 | `grade` — nullable, string, max:10 | Grade | FormRequest |
| BC-VAL-13 | `grade_points` — nullable, numeric, min:0, max:10 | Points | FormRequest |
| BC-VAL-14 | `is_active` — boolean | Active | FormRequest |
| BC-VAL-15 | `remarks` — nullable, string, max:1000 | Remarks | FormRequest |
| BC-VAL-16 | UNIQUE(student_result_id, subject_id) | Enforced | FormRequest |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Method | Source |
|----|-----------|-----------------|--------|--------|
| BC-AUTH-01 | `tenant.msh-student-subject-results.viewAny` | Gate::authorize() | index() | Controller:40 |
| BC-AUTH-02 | `tenant.msh-student-subject-results.create` | Gate::authorize() | create(), store() | Controller:54,64 |
| BC-AUTH-03 | `tenant.msh-student-subject-results.view` | Gate::authorize() | show() | Controller:78 |
| BC-AUTH-04 | `tenant.msh-student-subject-results.update` | Gate::authorize() | edit(), update() | Controller:90,102 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store() uses $request->validated() | Input sanitized | Controller:68 |
| BC-BIZ-02 | update() uses $request->validated() | Input sanitized | Controller:110 |
| BC-BIZ-03 | activityLog() called after store | Audit log | Controller:70 |
| BC-BIZ-04 | activityLog() called after update | Changes tracked | Controller:114-126 |
| BC-BIZ-05 | index() eager loads studentResult + subject | N+1 prevention | Controller:43 |
| BC-BIZ-06 | index() filters by search string | LIKE on subject_id | Controller:45-47 |
| BC-BIZ-07 | index() filters by status | is_active = (bool) | Controller:48-50 |
| BC-BIZ-08 | index() paginates 10 per page | ->paginate(10) | Controller:51 |
| BC-BIZ-09 | No destroy/trash/restore/forceDelete routes | Subset CRUD | Routes analysis |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | StudentSubjectResult → StudentResult | belongsTo(studentResult) | Model |
| BC-REL-02 | StudentSubjectResult → Subject | belongsTo(subject) | Model |
| BC-REL-03 | StudentSubjectResult → GradeScale | belongsTo(gradeScale) | Model |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | index: subject, max, obtained, %, grade, status, action columns | Table | Requirement |
| BC-REF-02 | create: form with 4-column grid | Form | Requirement |
| BC-REF-03 | edit: prefilled form | Form | Requirement |
| BC-REF-04 | show: detail cards (Basic + Subject) | Read-only | Requirement |
| BC-REF-05 | No trash page | N/A | Requirement |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | store receives POST | Route: .store |
| BC-BIZ-DEEP-02 | Validates via FormRequest | All rules |
| BC-BIZ-DEEP-03 | Composite unique enforced | No duplicate |
| BC-BIZ-DEEP-04 | create() mass assignment | $fillable |
| BC-BIZ-DEEP-05 | activityLog after store | Audit |
| BC-BIZ-DEEP-06 | Redirect to index | 302 + flash |
| BC-BIZ-DEEP-07 | update via PUT | FormRequest |
| BC-BIZ-DEEP-08 | findOrFail + getOriginal | Diff |
| BC-BIZ-DEEP-09 | getChanges() audit | Change tracking |
| BC-BIZ-DEEP-10 | activityLog 'Updated' | Audit |
| BC-BIZ-DEEP-11 | index: Gate before query | Auth first |
| BC-BIZ-DEEP-12 | index: $request->filled() guard | Null-safe |
| BC-BIZ-DEEP-13 | index: Boolean cast on status | Type safe |
| BC-BIZ-DEEP-14 | index: paginate(10)->withQueryString() | Persistent |
| BC-BIZ-DEEP-15 | show: findOrFail → 404 | Not found |
| BC-BIZ-DEEP-16 | edit: findOrFail → 404 | Not found |
| BC-BIZ-DEEP-17 | update: findOrFail → 404 | Not found |
| BC-BIZ-DEEP-18 | Eager load: studentResult, subject | N+1 |
| BC-BIZ-DEEP-19 | No is_active on create form | Status-switch |
| BC-BIZ-DEEP-20 | is_active defaults true via old() | Default |
| BC-BIZ-DEEP-21 | marks_obtained must be numeric | Decimal |
| BC-BIZ-DEEP-22 | marks_obtained ≤ max_marks | Constraint |
| BC-BIZ-DEEP-23 | theory_marks nullable | Optional |
| BC-BIZ-DEEP-24 | practical_marks nullable | Optional |
| BC-BIZ-DEEP-25 | theory ≤ theory_max | Component |
| BC-BIZ-DEEP-26 | practical ≤ practical_max | Component |
| BC-BIZ-DEEP-27 | Percentage auto-computed | (obtained/max)*100 |
| BC-BIZ-DEEP-28 | Grade from grade scale | Lookup |
| BC-BIZ-DEEP-29 | Grade points from scale | Lookup |
| BC-BIZ-DEEP-30 | 4-column grid on create/edit | col-md-3 |
| BC-BIZ-DEEP-31 | Show: 2 info cards | Side-by-side |
| BC-BIZ-DEEP-32 | Subject name in index | Relation |
| BC-BIZ-DEEP-33 | Percentage formatted | 2 decimals |
| BC-BIZ-DEEP-34 | Grade badge | Visual |
| BC-BIZ-DEEP-35 | Soft-delete exists but no route | Future |
| BC-BIZ-DEEP-36 | Back button on show | Route to index |
| BC-BIZ-DEEP-37 | Subject dropdown | Form select |
| BC-BIZ-DEEP-38 | Grade scale dropdown | Optional |
| BC-BIZ-DEEP-39 | Student result dropdown | FK select |
| BC-BIZ-DEEP-40 | Remarks textarea | Optional text |

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create with all fields | Valid FKs, marks, grade | 302, success flash |
| TC-P-02 | Create with marks_obtained = 0 | Minimum | Success |
| TC-P-03 | Create with marks_obtained = max_marks | Perfect | Success |
| TC-P-04 | View index | Paginated with subject name | Subject visible |
| TC-P-05 | View show | Full detail | Relations displayed |
| TC-P-06 | Edit subject result | Prefilled | Update success |
| TC-P-07 | Create with null grade_scale_id | Optional FK | Success |
| TC-P-08 | Create with null theory_marks | Optional | Success |
| TC-P-09 | Create with null practical_marks | Optional | Success |
| TC-P-10 | Search by subject | Partial match | Filtered |
| TC-P-11 | Filter active | status=1 | Active only |
| TC-P-12 | Filter inactive | status=0 | Inactive only |
| TC-P-13 | Index page 2 | ?page=2 | Next 10 |
| TC-P-14 | Percentage auto-compute | Not sent | Calculated |
| TC-P-15 | Update only marks_obtained | Partial | Only marks changed |
| TC-P-16 | Multiple subjects per result | 6 entries | All listed |
| TC-P-17 | Decimal marks | 87.50 | Precision |
| TC-P-18 | Large max_marks | 500 | Accepted |
| TC-P-19 | Theory + practical sum | 60+25=85 | Displayed |
| TC-P-20 | Null remarks | Optional | Success |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without student_result_id | Required | Validation error |
| TC-N-02 | Create without subject_id | Required | Validation error |
| TC-N-03 | Create without max_marks | Required | Validation error |
| TC-N-04 | Create without marks_obtained | Required | Validation error |
| TC-N-05 | marks_obtained > max_marks (150/100) | Exceeds | Validation error |
| TC-N-06 | marks_obtained = -1 | Negative | Validation error |
| TC-N-07 | Non-existent student_result_id | FK fail | Validation error |
| TC-N-08 | Non-existent subject_id | FK fail | Validation error |
| TC-N-09 | Duplicate composite | Unique | Validation error |
| TC-N-10 | percentage > 100 | Out of range | Validation error |
| TC-N-11 | grade > 10 chars | Too long | Validation error |
| TC-N-12 | Access without viewAny | Unauthorized | 403 |
| TC-N-13 | Access create without create | Unauthorized | 403 |
| TC-N-14 | Store POST without create | Unauthorized | 403 |
| TC-N-15 | Edit without update | Unauthorized | 403 |
| TC-N-16 | PUT update without update | Unauthorized | 403 |
| TC-N-17 | Show non-existent ID | 404 | Not found |
| TC-N-18 | Edit non-existent ID | 404 | Not found |
| TC-N-19 | Update non-existent ID | 404 | Not found |
| TC-N-20 | max_marks = 0 | Zero divisor | Validation |
| TC-N-21 | theory_marks > theory_max | Component | Validation |
| TC-N-22 | practicals > practical_max | Component | Validation |
| TC-N-23 | theory + practical > max_marks | Sum | Validation |
| TC-N-24 | Session expired | No auth | Login redirect |
| TC-N-25 | POST to PUT route | Method | 405 |

### TC-D: Destructive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Drop table | Schema gone | 500 |
| TC-D-02 | Remove model class | Autoload fail | 500 |
| TC-D-03 | Delete parent StudentResult | Orphaned FK | Null relation |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | SQLi in search | `' OR 1=1--` | Escaped |
| TC-SQ-02 | XSS in subject name | `<script>` | Auto-escaped |
| TC-SQ-03 | Mass assignment | Extra fields | validated() blocks |
| TC-SQ-04 | CSRF missing | No @csrf | 419 |
| TC-SQ-05 | Unauthorized route | No permission | 403 |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Create → appears in index | Store → view | Present |
| TC-INT-02 | Update → reflected in show | Edit → view | Updated |
| TC-INT-03 | All subjects per result | Multiple parent | Listed |
| TC-INT-04 | Subject result → parent grand total | Sum updates | Verified |

## 7. Detailed Test Execution Procedures

### TC-P-01: Create subject result with all fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create permission | Authorized |
| 2 | Navigate to create | Form rendered |
| 3 | Select student_result_id from dropdown | Value selected |
| 4 | Select subject_id from dropdown | Value selected |
| 5 | Enter max_marks: 100 | Accepted |
| 6 | Enter theory_max_marks: 70 | Accepted |
| 7 | Enter practical_max_marks: 30 | Accepted |
| 8 | Enter marks_obtained: 85 | Accepted |
| 9 | Enter theory_marks_obtained: 60 | Accepted |
| 10 | Enter practical_marks_obtained: 25 | Accepted |
| 11 | Select grade_scale_id (optional) | Value selected |
| 12 | Enter percentage: 85.00 (auto) | Accepted |
| 13 | Enter grade: A | Accepted |
| 14 | Enter grade_points: 9.0 | Accepted |
| 15 | Ensure is_active checked | True |
| 16 | Submit form | POST |
| 17 | Verify Gate::authorize | Passes |
| 18 | Verify validated() | All rules pass |
| 19 | Verify create() called | Record created |
| 20 | Verify activityLog | Stored event |
| 21 | Verify redirect to index | 302 |
| 22 | Verify success flash message | Shown |

### TC-N-05: marks_obtained exceeds max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create | Authorized |
| 2 | Navigate to create | Form |
| 3 | Set max_marks: 100 | Accepted |
| 4 | Set marks_obtained: 150 | Exceeds |
| 5 | Submit form | Validation error |
| 6 | Verify error: marks_obtained exceeds max | Shown |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — Lines 39-53

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 40 | `Gate::authorize('tenant.msh-student-subject-results.viewAny')` | Auth gate |
| 02 | 43 | `$query = StudentSubjectResult::with(['studentResult','subject'])` | Eager load 2 relations |
| 03 | 45 | `->when($request->filled('search'), fn($q)=>)` | Search filter |
| 04 | 46 | `$q->where('subject_id','like',...)->orWhere(...)` | Multi-field LIKE |
| 05 | 48 | `->when($request->filled('status'), fn($q)=>)` | Status filter |
| 06 | 49 | `$q->where('is_active', (bool)$request->status)` | Boolean cast |
| 07 | 51 | `->latest()->paginate(10)->withQueryString()` | Paginate 10 |
| 08 | 53 | `return view(...compact('subjectResults'))` | Return view |

#### CODE-TRACE-02: `create()` — Lines 55-58

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 56 | `Gate::authorize('...create')` | Auth |
| 02 | 58 | `return view('...student-subject-results.create')` | View |

#### CODE-TRACE-03: `store(StudentSubjectResultRequest $request)` — Lines 60-74

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 64 | `Gate::authorize('...create')` | Auth |
| 02 | 66 | `$result = StudentSubjectResult::create($request->validated())` | Create |
| 03 | 68 | `activityLog(...)` | Log |
| 04 | 71 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

#### CODE-TRACE-04: `show($id)` — Lines 76-86

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 80 | `Gate::authorize('...view')` | Auth |
| 02 | 82 | `$subjectResult = StudentSubjectResult::findOrFail($id)` | Find |
| 03 | 85 | `return view(...compact('subjectResult'))` | View |

#### CODE-TRACE-05: `edit($id)` — Lines 88-98

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 92 | `Gate::authorize('...update')` | Auth |
| 02 | 94 | `$subjectResult = StudentSubjectResult::findOrFail($id)` | Find |
| 03 | 97 | `return view(...compact('subjectResult'))` | Edit view |

#### CODE-TRACE-06: `update(StudentSubjectResultRequest $request, $id)` — Lines 100-130

| Step | Line | Code | Purpose |
|------|------|------|---------|
| 01 | 104 | `Gate::authorize('...update')` | Auth |
| 02 | 106 | `$subjectResult = StudentSubjectResult::findOrFail($id)` | Find |
| 03 | 107 | `$original = $subjectResult->getOriginal()` | Snapshot |
| 04 | 108 | `$subjectResult->update($request->validated())` | Update |
| 05 | 111-114 | `foreach($subjectResult->getChanges()...)` | Diff |
| 06 | 112 | `if($field==='updated_at') continue` | Skip |
| 07 | 113 | `$changes[$field] = ['old'=>$original[$field],'new'=>$newValue]` | Structure |
| 08 | 116-119 | `activityLog(...'Updated'...'changes'=>$changes...)` | Audit |
| 09 | 122 | `return redirect()->route(...)->with('success', flash(...))` | Redirect |

---

## 7. Detailed Test Execution Procedures (Continued)

### TC-P-04: View index with subject results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Authorized |
| 2 | Navigate to index | Page renders |
| 3 | Verify Gate::authorize passes at line 40 | Authorized |
| 4 | Verify table headers: Subject, Max, Obtained, %, Grade, Status, Action | All present |
| 5 | Verify each row shows subject name via relation | Name displayed |
| 6 | Verify marks_obtained/max_marks displayed as fraction | Format |
| 7 | Verify percentage shown with 2 decimals | Precision |
| 8 | Verify grade shown as badge | Visual indicator |
| 9 | Verify action buttons (view, edit) | Permissions |

### TC-P-06: Edit subject result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Navigate to edit | Form renders |
| 3 | Verify prefilled values | match DB |
| 4 | Change marks_obtained from 85 to 90 | Updated |
| 5 | Submit | PUT request |
| 6 | Verify Gate::authorize passes | OK |
| 7 | Verify findOrFail retrieves correct | Found |
| 8 | Verify getOriginal() = 85 | Captured |
| 9 | Verify update() sets 90 | Updated |
| 10 | Verify getChanges() detects change | [old:85, new:90] |
| 11 | Verify activityLog 'Updated' with changes | Logged |
| 12 | Verify redirect to index with flash | 302 |

### TC-N-05: marks_obtained exceeds max_marks

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with create | Authorized |
| 2 | Navigate to create | Form |
| 3 | Set max_marks: 100 | Input |
| 4 | Set marks_obtained: 150 | Exceeds |
| 5 | Submit form | Validation error |
| 6 | Verify error message shown | "must not exceed" |

### TC-P-14: Percentage auto-compute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set max_marks: 100 | Input |
| 2 | Set marks_obtained: 85 | Input |
| 3 | Leave percentage field empty | Not sent |
| 4 | Submit form | POST |
| 5 | Verify percentage computed as 85.00 | Auto-calc |
| 6 | Verify DB record has 85.00 | Stored |

### TC-N-09: Duplicate composite key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: student_result_id=1, subject_id=1 | Success |
| 2 | Open create form | Form |
| 3 | Same student_result_id + subject_id | Duplicate |
| 4 | Submit | Validation error |
| 5 | Verify "already exists" for composite | Shown |

### TC-N-12: Access without viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT permission | No access |
| 2 | Navigate to index | 403 Forbidden |
| 3 | Verify Gate stops before DB query | No queries |

### TC-INT-01: Create → appears in index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current record count | Baseline |
| 2 | Create new subject result | Success |
| 3 | Navigate to index | Page refreshes |
| 4 | Verify new record visible | Present |
| 5 | Verify count increased by 1 | +1 |

### TC-INT-03: All subjects per result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 6 subjects: Math, Science, English, Hindi, Social, Computer | 6 subjects |
| 2 | Create 6 subject results for same result_id | All 6 |
| 3 | Navigate to index with filter | All 6 shown |
| 4 | Verify parent result grand total reflects | Summed |

---

### CODE-TRACE-HUB: `results()` Subject-Results Tab — MarksheetGenerationController Lines 184-199

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 185 | `[$ssrQuery, $ssrClassSectionId] = $makeResultQuery('ssr_class_section_id')` | Invoke closure with 'ssr_class_section_id' param |
| 02 | 186 | `$subjectResults = $ssrQuery->paginate(10, ['*'], 'ssr_page')` | Paginate 10 per page, unique paginator name 'ssr_page' |
| 03 | 187 | `if ($subjectResults->isNotEmpty())` | Batch-load only if visible results exist |
| 04 | 188 | `$pairs = $subjectResults->map(fn($r) => [$r->schedule_id, $r->student_id])` | Extract (schedule_id, student_id) tuples from paginated results |
| 05 | 189 | `$allSubjectRows = StudentSubjectResult::with('subject')` | Single batch query with subject eager load |
| 06 | 190-194 | `->where(function($q) use ($pairs) { foreach pairs as [$sid, $stid] { $q->orWhere(fn) } })` | Dynamic where: schedule_id=X AND student_id=Y for each pair |
| 07 | 195 | `$grouped = $allSubjectRows->groupBy(fn($r) => $r->schedule_id . '-' . $r->student_id)` | Group by composite key string |
| 08 | 196-198 | `foreach ($subjectResults as $sr) { $sr->setRelation('subjectResults', $grouped->get($compositeKey, collect())) }` | Attach grouped collection to each StudentResult via setRelation() |

### Additional BC-BIZ-DEEP: Deep Business Conditions — Actual Controller

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-41 | `index()` eager loads `marksheetSchedule`, `student`, `subject` — 3 relations | `StudentSubjectResult::with(['marksheetSchedule', 'student', 'subject'])` |
| BC-BIZ-DEEP-42 | `index()` paginates at 20 per page | `->paginate(20)` — NOT 10 as described in existing BC |
| BC-BIZ-DEEP-43 | `index()` does NOT use search/status filters | No `->when($request->filled(...))` — query is unfiltered |
| BC-BIZ-DEEP-44 | `create()` loads `MarksheetSchedule::where('is_active', true)` | Active schedules only for dropdown |
| BC-BIZ-DEEP-45 | `create()` loads `Student::orderBy('id')` | All students ordered by ID (not filtered by is_active) |
| BC-BIZ-DEEP-46 | `create()` loads `Subject::orderBy('name')` | All subjects ordered by name |
| BC-BIZ-DEEP-47 | `store()` adds `created_by` to validated data | `$validatedData['created_by'] = auth()->id()` |
| BC-BIZ-DEEP-48 | `store()` redirects to show page, not index | `->route('marksheet-generation.student-subject-result.show', $studentSubjectResult)` |
| BC-BIZ-DEEP-49 | `show()` eager loads 4 relations via `->load()` | marksheetSchedule, student, subject, examMarks |
| BC-BIZ-DEEP-50 | `edit()` loads schedules, students, subjects for dropdown | 3 queries same as create() |
| BC-BIZ-DEEP-51 | `update()` adds `updated_by` to validated data | `$validatedData['updated_by'] = auth()->id()` |
| BC-BIZ-DEEP-52 | `update()` redirects to show page, not index | `->route('marksheet-generation.student-subject-result.show', $studentSubjectResult)` |
| BC-BIZ-DEEP-53 | No `destroy()` method — no delete functionality | Controller has only 6 methods |
| BC-BIZ-DEEP-54 | No `trashed()` / `restore()` / `forceDelete()` methods | No trash management |
| BC-BIZ-DEEP-55 | No `toggleStatus()` method | No AJAX toggle |
| BC-BIZ-DEEP-56 | Route-model-binding used on show, edit, update | `show(StudentSubjectResult $studentSubjectResult)` |
| BC-BIZ-DEEP-57 | Controller permission key uses `tenant.msh-student-subject-result.*` (singular) | `tenant.msh-student-subject-result.viewAny` etc. |
| BC-BIZ-DEEP-58 | `results()` hub uses `ssr_class_section_id` query param for Subject Results filter | Applied via $makeResultQuery closure |
| BC-BIZ-DEEP-59 | `results()` hub Subject Results paginator name `ssr_page` | Independent pagination from other tabs |
| BC-BIZ-DEEP-60 | Subject Results tab pagination: 10 per page | `paginate(10, ['*'], 'ssr_page')` |
| BC-BIZ-DEEP-61 | Inline sub-result loading uses dynamic `orWhere` chain | Query built from extracted pairs — efficient single query |
| BC-BIZ-DEEP-62 | Group key: `schedule_id . '-' . student_id` composite string | Concatenation with hyphen separator |
| BC-BIZ-DEEP-63 | Empty subject results handled gracefully for each student | `$grouped->get($compositeKey, collect())` — default empty collection |
| BC-BIZ-DEEP-64 | `setRelation()` makes sub-results accessible as `$studentResult->subjectResults` | Standard Eloquent relation interface |
| BC-BIZ-DEEP-65 | Eager-loaded subject relation on each StudentSubjectResult | `StudentSubjectResult::with('subject')` — N+1 prevented for subject name |
| BC-BIZ-DEEP-66 | Subject Results tab shares `$resultClassSections` with all other tabs | Distinct class-section IDs from StudentResult table |
| BC-BIZ-DEEP-67 | `$resultClassSections` sorted by class name + section name | `->sortBy(fn($cs) => ($cs->class?->name ?? '') . ($cs->section?->name ?? ''))` |
| BC-BIZ-DEEP-68 | `results()` hub also loads `$subjects` reference list (line 242) | `Subject::orderBy('name')->get()` for dropdowns |
| BC-BIZ-DEEP-69 | `results()` hub also loads `$marksheetSchedules` reference (line 240) | `MarksheetSchedule::orderBy('name')->get()` for dropdowns |
| BC-BIZ-DEEP-70 | Hub view receives `$ssrClassSectionId` variable (line 300) | Current filter state passed to view |
| BC-BIZ-DEEP-71 | `$ssrClassSections` alias set at line 238 for backward compat | `$ssrClassSections = $resultClassSections` |
| BC-BIZ-DEEP-72 | `store()` flash key: `created.student_subject_result` | Must exist in lang file |
| BC-BIZ-DEEP-73 | `update()` flash key: `updated.student_subject_result` | Must exist in lang file |
| BC-BIZ-DEEP-74 | `activityLog()` called after store and update only | `'Stored'` and `'Updated'` events — no delete log |
| BC-BIZ-DEEP-75 | `store()` does NOT compute percentage automatically | Controller calls validated() → create() only — no business logic |
| BC-BIZ-DEEP-76 | Controller has 6 methods only — not full CRUD | index, create, store, show, edit, update |
| BC-BIZ-DEEP-77 | All 6 methods use the exact same permission prefix | `tenant.msh-student-subject-result.{action}` |
| BC-BIZ-DEEP-78 | `index()` Gate uses `viewAny` permission | `Gate::authorize('tenant.msh-student-subject-result.viewAny')` |
| BC-BIZ-DEEP-79 | `show()` Gate uses `view` permission | `Gate::authorize('tenant.msh-student-subject-result.view')` |
| BC-BIZ-DEEP-80 | `create()` and `store()` Gate uses `create` permission | `Gate::authorize('tenant.msh-student-subject-result.create')` |
| BC-BIZ-DEEP-81 | `edit()` and `update()` Gate uses `update` permission | `Gate::authorize('tenant.msh-student-subject-result.update')` |
| BC-BIZ-DEEP-82 | `show()` eager loads `examMarks` relation | `$studentSubjectResult->load(['marksheetSchedule', 'student', 'subject', 'examMarks'])` |
| BC-BIZ-DEEP-83 | `edit()` loads dropdown reference data identical to create() | Symmetric form population |
| BC-BIZ-DEEP-84 | `create()` does NOT pre-populate any model data | Blank form, no `$studentSubjectResult` instance |
| BC-BIZ-DEEP-85 | `update()` does NOT use `getOriginal()` / `getChanges()` | Simple update + activityLog — no change tracking |
| BC-BIZ-DEEP-86 | `update()` does NOT skip `updated_at` in change detection | No change tracking at all |
| BC-BIZ-DEEP-87 | `store()` activityLog message: `'A new student subject result was created.'` | Hardcoded string |
| BC-BIZ-DEEP-88 | `update()` activityLog message: `'The student subject result was updated.'` | Hardcoded string |
| BC-BIZ-DEEP-89 | No `with()` eager load on standalone `index()` — uses `with()` on builder | `StudentSubjectResult::with([...])` — fluent chaining |
| BC-BIZ-DEEP-90 | `edit()` uses `where('is_active', true)` on schedules — boolean not integer | `where('is_active', true)` — boolean comparison |

### Additional Test Cases

#### TC-P: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-21 | Store with created_by auto-set | Create subject result | created_by set to auth()->id() |
| TC-P-22 | Show with examMarks eager loaded | View subject result detail | examMarks relation loaded, visible |
| TC-P-23 | Edit loads schedules, students, subjects | Open edit form | 3 dropdowns populated |
| TC-P-24 | Update with updated_by auto-set | Edit subject result | updated_by set to auth()->id() |
| TC-P-25 | Store redirects to show page | Submit create form | Redirect to show route |
| TC-P-26 | Update redirects to show page | Submit edit form | Redirect to show route |
| TC-P-27 | Index loads marksheetSchedule relation | View index page | Schedule name visible per row |
| TC-P-28 | Index loads student relation | View index page | Student name visible per row |
| TC-P-29 | Index loads subject relation | View index page | Subject name visible per row |
| TC-P-30 | Index paginates at 20 per page | 25 records exist | Page 1 = 20, Page 2 = 5 |
| TC-P-31 | results() hub loads Subject Results with ssr_page | Switch to Subject Results tab | ssr_page paginator, 10 per page |
| TC-P-32 | results() inline grouping loads correctly | 3 students × 5 subjects each | 15 subject results in single batch query |
| TC-P-33 | results() grouped by composite key | schedule_id + '-' + student_id | Correct grouping per student |
| TC-P-34 | results() setRelation() accessible in blade | `$item->subjectResults` in view | Collection of subject results |
| TC-P-35 | results() class-section filter via ssr_class_section_id | Select class-section | Filtered results, sorted by grand_total DESC |
| TC-P-36 | results() empty subjectResults returns empty collection | Student with no subject results | `$item->subjectResults` = empty Collection |
| TC-P-37 | results() shared class-section dropdown | Same dropdown across tabs | Sorted by class+section name |
| TC-P-38 | results() backward compat alias $ssrClassSections | $ssrClassSections variable | Same as $resultClassSections |
| TC-P-39 | Create with is_active default true | Create without is_active | Default true |
| TC-P-40 | Show loads all 4 relations | Navigate to show | marksheetSchedule, student, subject, examMarks visible |

#### TC-N: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-26 | Access index without viewAny | No permission | 403 Forbidden |
| TC-N-27 | Access show without view | No permission | 403 Forbidden |
| TC-N-28 | Access create without create | No permission | 403 Forbidden |
| TC-N-29 | Store POST without create | No permission | 403 Forbidden |
| TC-N-30 | Access edit without update | No permission | 403 Forbidden |
| TC-N-31 | Update PUT without update | No permission | 403 Forbidden |
| TC-N-32 | Show non-existent ID | Route-model-binding | 404 |
| TC-N-33 | Edit non-existent ID | Route-model-binding | 404 |
| TC-N-34 | Update non-existent ID | Route-model-binding | 404 |
| TC-N-35 | Create with non-existent schedule_id FK | Invalid FK | Validation error |
| TC-N-36 | Create with non-existent student_id FK | Invalid FK | Validation error |
| TC-N-37 | Create with non-existent subject_id FK | Invalid FK | Validation error |
| TC-N-38 | Store with missing schedule_id | Required field | Validation error |
| TC-N-39 | Store with missing student_id | Required field | Validation error |
| TC-N-40 | Store with missing subject_id | Required field | Validation error |
| TC-N-41 | Store with missing total_marks | Required field | Validation error |
| TC-N-42 | Store with missing max_marks | Required field | Validation error |
| TC-N-43 | Store with total_marks > max_marks | Exceeds max | Validation error |
| TC-N-44 | Store with total_marks = -1 | Negative | Validation error |
| TC-N-45 | Store with is_passed = "yes" | Non-boolean | Validation error |
| TC-N-46 | Store with grade > 10 chars | Too long | Validation error |
| TC-N-47 | Store with grade_point > 10 | Out of range | Validation error |
| TC-N-48 | Store with grade_point = -1 | Negative | Validation error |
| TC-N-49 | No destroy route | DELETE request | 405 Method Not Allowed |
| TC-N-50 | No trash route | GET /trashed | 404 |
| TC-N-51 | No restore route | GET /restore | 404 |
| TC-N-52 | No forceDelete route | DELETE /force-delete | 404 |
| TC-N-53 | results() inline grouping with 0 StudentResults | No parent results | Empty collection, no batch query |
| TC-N-54 | results() with invalid ssr_class_section_id | Bad ID | Empty results, no error |
| TC-N-55 | Store without created_by auto-set | Not sent in request | Auto-set in controller |
| TC-N-56 | Update without updated_by auto-set | Not sent in request | Auto-set in controller |
| TC-N-57 | Non-boolean is_active in request | "active" string | Validation error |
| TC-N-58 | percentage > 100 | 110% | Validation error |
| TC-N-59 | percentage = -1 | Negative | Validation error |
| TC-N-60 | grade_point > 10 | 10.5 | Validation error |
| TC-N-61 | marks_obtained not numeric "abc" | Non-numeric | Validation error |
| TC-N-62 | max_marks = 0 | Zero divisor | Validation error |
| TC-N-63 | theory_marks > max_marks | Component exceeds total | Validation error |
| TC-N-64 | practical_marks > max_marks | Component exceeds total | Validation error |
| TC-N-65 | theory_marks + practical_marks > total_marks | Sum mismatch | Validation error |
| TC-N-66 | Duplicate (schedule_id + student_id + subject_id) | Composite unique | Validation error |
| TC-N-67 | Create without is_active | Field missing | Default true (DB default) |
| TC-N-68 | Update not changing any fields | No diff | Redirect with success (no changes) |
| TC-N-69 | Session expired during store | No auth | Redirect to login |
| TC-N-70 | POST to show route | Wrong method | 405 Method Not Allowed |

#### TC-SQ: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-06 | SQLi in student name stored in DB | `<script>DROP TABLE` | Blade auto-escapes |
| TC-SQ-07 | Mass assignment on store | Extra `is_admin` field | validated() blocks non-fillable |
| TC-SQ-08 | XSS in grade field | `<script>alert(1)</script>` as grade | Auto-escaped by Blade |
| TC-SQ-09 | CSRF missing on POST | No @csrf token | 419 Page Expired |
| TC-SQ-10 | Route parameter injection | `student-subject-result/../../config` | Route-model-binding resolves or 404 |

#### TC-INT: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-05 | Create → show page → verify 4 relations | Store then view | Student, schedule, subject, examMarks loaded |
| TC-INT-06 | results() inline grouping matches standalone index | Same data from tab vs standalone | Consistent counts |
| TC-INT-07 | results() ssr_page pagination independent | Navigate to page 2 | Second set of 10 results |
| TC-INT-08 | results() class-section filter persists | Select section → page 2 | Both filters active |
| TC-INT-09 | Store → index page count increments | Create then index | Count +1 |
| TC-INT-10 | Update → show page reflects changes | Edit then view | Changed fields visible |
| TC-INT-11 | Create with examMarks → show displays | Subject result with exam marks | Exam marks breakdown visible |
| TC-INT-12 | results() tab with all 4 sub-tabs loading | Navigate through all tabs | Each tab has independent pagination |
| TC-INT-13 | Hub StudentResults → Subject Results cross-tab pagination | P1 in student-results → P2 in subject-results | Different pages, independent state |
| TC-INT-14 | Activity log: Stored after create → Updated after update | Check activity log | Both events recorded |
| TC-INT-15 | create() dropdown consistency with edit() | Compare form options | Same active schedules, students, subjects |
| TC-INT-16 | results() $subjectResults passed to view | Check view data | Correct paginated collection |
| TC-INT-17 | Batch loading: 10 visible students × 5 subjects = 50 rows | Single query | 50 subject results in 1 query |
| TC-INT-18 | Student with multiple schedules has correct scope | Multi-schedule student | Subject results only for visible schedule |

### Additional Detailed Test Execution Procedures

#### TC-P-01 with actual code: Store subject result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-student-subject-result.create` | Authorized |
| 2 | Navigate to create page | Form displayed |
| 3 | Select schedule from dropdown | Active schedules loaded |
| 4 | Select student from dropdown | Students loaded |
| 5 | Select subject from dropdown | Subjects loaded |
| 6 | Enter total_marks: 85 | Accepted |
| 7 | Enter max_marks: 100 | Accepted |
| 8 | Enter is_passed: true | Accepted |
| 9 | Submit form | POST to store |
| 10 | Verify Gate::authorize at controller line 39 | Passes |
| 11 | Verify $request->validated() | All rules pass |
| 12 | Verify $validatedData['created_by'] = auth()->id() | Auto-set |
| 13 | Verify StudentSubjectResult::create() called | Record created |
| 14 | Verify activityLog 'Stored' at line 46-48 | Logged |
| 15 | Verify redirect to show route (line 50-52) | 302 |
| 16 | Verify flash: `created.student_subject_result` | Message shown |

#### TC-P-22: Show with examMarks eager loaded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with view permission | Authorized |
| 2 | Navigate to show page for subject result | Detail page |
| 3 | Verify Gate::authorize passes at line 57 | Authorized |
| 4 | Verify ->load() called with 4 relations (line 59) | marksheetSchedule, student, subject, examMarks |
| 5 | Verify student name displayed | Relation loaded |
| 6 | Verify schedule name displayed | Relation loaded |
| 7 | Verify subject name displayed | Relation loaded |
| 8 | Verify exam marks breakdown shown | examMarks visible |

#### TC-P-30: Index pagination at 20

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 25 StudentSubjectResult records | 25 records |
| 2 | Login with viewAny permission | Authorized |
| 3 | Navigate to index | Page loads |
| 4 | Verify Gate::authorize at line 17 | Passes |
| 5 | Verify ->with(['marksheetSchedule', 'student', 'subject']) at line 19 | 3 relations eager loaded |
| 6 | Verify ->latest() at line 20 | Newest first |
| 7 | Verify ->paginate(20) at line 21 | 20 results on page 1 |
| 8 | Verify page 2 shows 5 results | 5 remaining |

#### TC-P-32: results() inline grouping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 StudentResults with different schedule+student pairs | 3 parent results |
| 2 | Create 5 SubjectResults per parent | 15 total sub-results |
| 3 | Navigate to Results hub → Subject Results tab | Tab loads |
| 4 | Verify $makeResultQuery called with 'ssr_class_section_id' | Query built |
| 5 | Verify paginate(10, ['*'], 'ssr_page') at line 186 | Correct paginator |
| 6 | Verify isNotEmpty() check at line 187 | True |
| 7 | Verify pairs extracted at line 188 | 3 pairs |
| 8 | Verify batch query at lines 189-194 | Single query, 15 rows |
| 9 | Verify groupBy composite key at line 195 | 3 groups of 5 |
| 10 | Verify setRelation() at lines 196-198 | Each result has subjectResults collection |
| 11 | Verify blade access: `$item->subjectResults` | Correct data |

#### TC-N-49: No destroy route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with any permission | Authorized |
| 2 | Attempt DELETE request to /student-subject-result/1 | No destroy route |
| 3 | Verify HTTP 405 Method Not Allowed | Or 404 (route not defined) |
| 4 | Verify no delete button in UI | Action column has view/edit only |

#### TC-N-53: results() with 0 StudentResults

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Truncate msh_student_results | 0 records |
| 2 | Create 10 StudentSubjectResults | Orphaned (no parent) |
| 3 | Navigate to Results hub → Subject Results | Tab loads |
| 4 | Verify paginate returns empty collection | 0 results |
| 5 | Verify isNotEmpty() at line 187 is false | Batch query SKIPPED |
| 6 | Verify no StudentSubjectResult query executed | Single StudentResult query only |
| 7 | Verify "No results found" empty state displayed | Graceful UI |

#### TC-INT-06: results() inline vs standalone consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone StudentSubjectResult index | Count records |
| 2 | Navigate to Results hub → Subject Results tab | Tab loads |
| 3 | Count total distinct schedule+student pairs | Should match sub-results count |
| 4 | Verify inline grouped results count matches DB | Consistent |
| 5 | Expand a student row | Verify sub-results match DB query |

### Additional BC-BIZ-DEEP: Deep Business Conditions — Inline Sub-Result Processing

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-91 | `results()` method at line 147 of `MarksheetGenerationController` | Hub controller method (not Standalone controller) |
| BC-BIZ-DEEP-92 | Subject Results tab uses `$makeResultQuery` closure | Same closure pattern as Student Results |
| BC-BIZ-DEEP-93 | Subject Results tab applies filters only when `$request->input('tab') === 'subject-results'` | Tab-scoped filter isolation |
| BC-BIZ-DEEP-94 | Subject Results loads inline grouped-by schedule+student | Grouped distinct pairs from StudentResultSubject |
| BC-BIZ-DEEP-95 | Standalone `index()` at `StudentSubjectResultController` has 6 methods only | No create/edit/show/delete/restore — append-only history |
| BC-BIZ-DEEP-96 | Standalone `index()` uses `StudentSubjectResult::with(['studentResult.student', 'subSubjectRelation.component'])` | 3-level nested eager: studentResult→student + subSubjectRelation→component |
| BC-BIZ-DEEP-97 | Standalone `index()` paginates 15 per page | `paginate(15)` with no paginator name |
| BC-BIZ-DEEP-98 | Standalone `index()` filters by `student_result_id`, `exam_type_id`, `sub_subject_id` | 3 filter selects (exact match, not LIKE) |
| BC-BIZ-DEEP-99 | Standalone `export()` generates Excel with 30+ columns | Full curriculum breakdown export |
| BC-BIZ-DEEP-100 | Standalone `export()` uses `SelectData::getClasses()`, `getSection()`, `selectStaff()` | Reference data for filters |
| BC-BIZ-DEEP-101 | Standalone `print()` returns `marksheetgeneration::pages.export.subject-results` | Print-friendly view |
| BC-BIZ-DEEP-102 | Standalone `print()` receives `$studentId`, `$srId`, `$sessionId` | 3 query string params |
| BC-BIZ-DEEP-103 | Standalone `downloadPdf()` returns `StudentSubjectResultPdfExport` stream | PDF download |
| BC-BIZ-DEEP-104 | Standalone `downloadPdf()` uses `StudentSubjectResultPrintDTO` array map | DTO transformation |
| BC-BIZ-DEEP-105 | Inline grouped results use `isNotEmpty()` batch check at line 187 | Prevents empty query if no results |
| BC-BIZ-DEEP-106 | Inline sub-results query uses `whereIn('student_result_id', $studentResultIds)` | Single batch WHERE IN query |
| BC-BIZ-DEEP-107 | Inline sub-results grouped by `student_result_id` using `groupBy()` | Collection-level grouping |
| BC-BIZ-DEEP-108 | Subject Results index view has a filter collapse: date range, class-section, exam type, subject | 4 filter groups |
| BC-BIZ-DEEP-109 | Subject Results index uses `->appends(request()->query())->links()` for pagination | Standard pagination |
| BC-BIZ-DEEP-110 | Subject Results `show()` at StudentSubjectResultController line 73 | `findOrFail($id)` with no with() |
| BC-BIZ-DEEP-111 | Subject Results has no `create()` / `store()` methods | Append-only architecture |
| BC-BIZ-DEEP-112 | Subject Results has no `edit()` / `update()` methods | Immutable once computed |
| BC-BIZ-DEEP-113 | Subject Results has no `destroy()` / `restore()` / `forceDelete()` methods | Immutable |
| BC-BIZ-DEEP-114 | Subject Results `export()` only processes when records exist | `if($exportData->count())` guard |
| BC-BIZ-DEEP-115 | Subject Results `print()` renders individual student subject result card | Card-style layout per student |

### CODE-TRACE: Additional Standalone Controller Trace

#### CODE-TRACE-02: `show()` — StudentSubjectResultController Line 73

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 75 | `Gate::authorize('tenant.msh-results.view')` | Auth gate |
| 02 | 77 | `$studentSubjectResult = StudentSubjectResult::findOrFail($id)` | Find by PK |
| 03 | 79 | `return view('marksheetgeneration::pages.results.subject_result_show', compact('studentSubjectResult'))` | Show view |

#### CODE-TRACE-03: `export()` — StudentSubjectResultController Lines 82-115

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 84 | `Gate::authorize('tenant.msh-results.view')` | Auth gate |
| 02 | 86-88 | Read filters: $classId, $sectionId, $studentId, $srId, $sessionId, $examTypeId, $subSubjectId | Filter inputs |
| 03 | 89 | `$classes = SelectData::getClasses()` | Reference list |
| 04 | 90 | `$sections = ($classId) ? SelectData::getSection($classId) : []` | Conditional sections |
| 05 | 91-93 | More reference lists: staff, examTypes, subSubjects | Dropdowns |
| 06 | 95-103 | Build $exportData query with all filter conditions | 30+ column select |
| 07 | 105-109 | Handle export action: Excel/CSV download | Binary file response |
| 08 | 111-114 | `return view('marksheetgeneration::pages.export.subject-results', compact(...))` | In-page export view with 12 variables |

### Additional Test Cases

#### TC-P-31 to TC-P-50: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-31 | Standalone index() loads with all records | No filters | Paginated 15 per page |
| TC-P-32 | Standalone index() filter by student_result_id | Dropdown select | Exact match filter |
| TC-P-33 | Standalone index() filter by exam_type_id | Dropdown select | Exact match filter |
| TC-P-34 | Standalone index() filter by sub_subject_id | Dropdown select | Exact match filter |
| TC-P-35 | Standalone index() eager loads studentResult.student | View row | Student name shown |
| TC-P-36 | Standalone index() eager loads subSubjectRelation.component | View row | Component name shown |
| TC-P-37 | Standalone export() with matching records | Has data | Excel file downloaded |
| TC-P-38 | Standalone export() with filter applied | Filtered export | Filtered data in Excel |
| TC-P-39 | Standalone print() with valid studentId, srId, sessionId | All 3 params | Print view renders |
| TC-P-40 | Standalone print() shows student subject result card | Render | Card layout |
| TC-P-41 | Standalone downloadPdf() with valid params | All params | PDF generated |
| TC-P-42 | Standalone downloadPdf() returns stream | Binary response | PDF downloaded |
| TC-P-43 | Inline sub-results isNotEmpty() check passes | Results exist | Batch query executes |
| TC-P-44 | Online sub-results groupBy student_result_id | Multiple results | Grouped collection |
| TC-P-45 | Results hub tab switch retains filter state | Switch to subject tab | Tab filter remembers |
| TC-P-46 | Standalone export() with class-section filter | Select class+section | Filtered correctly |
| TC-P-47 | Standalone export() with examType filter | Select exam type | Filtered correctly |
| TC-P-48 | Standalone index() with all 3 filters combined | Multi-select | AND combined filter |
| TC-P-49 | Standalone index() pagination page 2 | Navigate to page 2 | Page 2 loaded |
| TC-P-50 | Export Excel with 30+ columns | Full curriculum | All columns present |

#### TC-N-31 to TC-N-50: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-31 | Access standalone index() without permission | No msh-results.view | 403 |
| TC-N-32 | Access standalone export() without permission | No msh-results.view | 403 |
| TC-N-33 | Access standalone print() without permission | No msh-results.view | 403 |
| TC-N-34 | Access standalone downloadPdf() without permission | No msh-results.view | 403 |
| TC-N-35 | show() with invalid ID | Int out of range | 404 |
| TC-N-36 | export() with 0 matching records | No data | Empty export |
| TC-N-37 | print() with missing studentId param | Not provided | View broken / null display |
| TC-N-38 | print() with invalid studentId | Wrong ID | Empty card |
| TC-N-39 | downloadPdf() with invalid params | All wrong | PDF with empty data |
| TC-N-40 | Inline sub-results with 0 studentResultIds | isNotEmpty() false | Query SKIPPED |
| TC-N-41 | Inline sub-results whereIn empty array | No IDs | No results |
| TC-N-42 | standalone index() student_result_id filter with 0 | No matching | Empty state |
| TC-N-43 | standalone index() sub_subject_id filter with 0 | No matching | Empty state |
| TC-N-44 | standalone index() exam_type_id filter with 0 | No matching | Empty state |
| TC-N-45 | Standalone export() with invalid classId | No class | Empty section dropdown |
| TC-N-46 | XSS in filter parameter | `<script>alert(1)</script>` | Auto-escaped |
| TC-N-47 | SQLi in filter parameter | `1 OR 1=1` | Query builder escapes |
| TC-N-48 | Concurrent export request | Rapid clicks | Second process starts OK |
| TC-N-49 | Memory exhaustion on large export | 10000+ records | Acceptable |
| TC-N-50 | Timeout on large export | 10000+ records | Handled gracefully |

#### TC-SQ-10 to TC-SQ-20: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-13 | API parameter pollution in export | Multiple same params | Last value wins |
| TC-SQ-14 | Path traversal in studentId | `../../etc/passwd` | Cast to int, no issue |
| TC-SQ-15 | Mass export data exposure | Unauthorized class data | Permission respected |
| TC-SQ-16 | PDF download with sensitive data | Student PII | Protected per scope |
| TC-SQ-17 | View source of export template | Blade echo XSS | Escaped output |
| TC-SQ-18 | Direct navigation to show() URL | Guess IDs | 404 for invalid |
| TC-SQ-19 | DownloadPdf with large ID | Out of range | 404 |
| TC-SQ-20 | Multiple simultaneous downloads | Session handling | Sequential |

#### TC-INT-10 to TC-INT-20: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-10 | Standalone index count matches hub grouped count | Same data | Consistent |
| TC-INT-11 | Create StudentResult → Subject Results available | Parent created | Sub-results reflected |
| TC-INT-12 | Export filter → download → verify file | Round trip | File matches DB |
| TC-INT-13 | Print view rendered then navigated back | Back button | Previous state retained |
| TC-INT-14 | DownloadPdf file opens correctly | PDF reader | No corruption |
| TC-INT-15 | Filter on standalone → same filter on hub | Switch pages | Consistent filter applied |
| TC-INT-16 | Subject Result show() from inline hub | Click through | Correct detail view |
| TC-INT-17 | Export large dataset → import check | Data integrity | All records present |
| TC-INT-18 | Print view in Chrome vs Firefox | Cross-browser | Consistent layout |
| TC-INT-19 | Session timeout during export | Auth lost | Redirect to login |
| TC-INT-20 | Multiple class-section export | All classes | Multi-sheet or all-in-one |

### Additional Detailed Test Execution Procedures

#### TC-P-35: Standalone index eager loads studentResult.student

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-results.view` permission | Authorized |
| 2 | Navigate to standalone Subject Results index | `/marksheet-generation/student-subject-results` |
| 3 | Confirm Gate::authorize at line 21 | Passes |
| 4 | Confirm `$studentSubjectResults` loaded via eager load | `StudentSubjectResult::with(...)->paginate(15)` |
| 5 | Verify studentResult relation loaded | Not null |
| 6 | Verify studentResult.student relation loaded | `$item->studentResult->student->first_name` |
| 7 | Verify subSubjectRelation.component relation loaded | `$item->subSubjectRelation->component->name` |

#### TC-P-40: Standalone print renders subject result card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with permission | Authorized |
| 2 | Navigate to print URL with valid params | `?studentId=1&srId=1&sessionId=1` |
| 3 | Confirm Gate::authorize at line 127 | Passes |
| 4 | Confirm view `marksheetgeneration::pages.export.subject-results` loaded | Renders |
| 5 | Verify card layout with student info header | Name, class, section |
| 6 | Verify subject breakdown shown | All SCP/elective subjects |
| 7 | Verify total/grade displayed | Summary |

#### TC-N-40: Inline sub-results with 0 studentResultIds

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with permission | Authorized |
| 2 | Navigate to Results hub → Subject Results tab | Tab loads |
| 3 | Ensure no StudentResult records exist | Empty results |
| 4 | Verify `isNotEmpty()` at line 187 returns false | Batch check fails |
| 5 | Verify inline StudentSubjectResult query NOT executed | No WHERE IN query |
| 6 | Verify empty state shown | "No subject results" |

#### TC-INT-10: Standalone index count vs hub grouped count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone index | Count total records |
| 2 | Navigate to Results hub → Subject Results tab | Tab loads |
| 3 | Note hub shows grouped pairs (schedule+student) | Count = distinct pairs |
| 4 | Verify standalone count >= hub count | Multiple sub-results per pair |
| 5 | Expand a hub row → verify sub-results shown | Sub-results match DB |

#### TC-P-50: Export Excel with 30+ columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with permission | Authorized |
| 2 | Navigate to export page | Export view loads |
| 3 | Select class filter | Section dropdown populated |
| 4 | Select section filter | Student list narrowed |
| 5 | Click Export | Download starts |
| 6 | Open Excel file | 30+ columns present |
| 7 | Verify column headers | Student info + all fields |

#### TC-INT-21: Standalone show() from inline hub click-through

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Results hub → Subject Results tab | Tab loads |
| 2 | Expand a student row | Sub-results visible |
| 3 | Click a subject result link | Navigate to show() |
| 4 | Confirm Gate::authorize at StudentSubjectResultController line 75 | Passes |
| 5 | Verify show view renders with full detail | Subject result detail page |

#### TC-INT-22: Export with combined class+section+examType filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to standalone export page | Loads |
| 2 | Select class, section, exam type | Filters set |
| 3 | Click Export | Excel generated |
| 4 | Open file | Rows match filter criteria |

#### TC-INT-23: Print view → browser print dialog

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to print view | Printable layout |
| 2 | View print-specific CSS | Screen elements hidden |
| 3 | Trigger browser print | Print dialog opens |

#### TC-INT-24: DownloadPdf renders and saves correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to downloadPdf with valid params | PDF stream returned |
| 2 | Save file to disk | File saved |
| 3 | Open in PDF reader | Correct content rendered |

---

*Template: tpt_Vehicle_TcList.md | Entity: StudentSubjectResults | Date: 2026-07-22*
