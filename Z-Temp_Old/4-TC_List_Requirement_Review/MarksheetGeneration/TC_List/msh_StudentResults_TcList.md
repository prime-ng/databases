# MarksheetGeneration Student Results — TC_List

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Marksheet Generation (MSH) |
| **Entity** | StudentResults (`msh_student_results`) — Full CRUD with withhold/declare/export/print/Pdf workflow |
| **Controller** | `Modules\MarksheetGeneration\Http\Controllers\StudentResultController` |
| **Model** | `Modules\MarksheetGeneration\Models\StudentResult` (SoftDeletes, 21 fillable fields) |
| **Form Request** | `StudentResultRequest` (create/update) + `WithholdStudentResultRequest` (withhold reason validation) |
| **Policy** | No explicit Policy — uses string-based `Gate::authorize('tenant.msh-student-results.*')` |
| **Route Prefix** | `marksheet-generation.student-results` |
| **Blade Views** | index, create, edit, show, trash — 5 views |
| **DB Table** | `msh_student_results` — 25+ columns |
| **Relationships** | belongsTo(student), belongsTo(classSection), belongsTo(schedule), hasMany(studentSubjectResults), hasMany(iaMarks), hasMany(coscholasticResults) |

## 2. Pre-conditions

| # | Pre-condition |
|---|--------------|
| PC-01 | User must be logged in with appropriate permission for each action |
| PC-02 | `msh_student_results` table migrated with correct schema |
| PC-03 | `std_students` table exists with first_name, last_name, admission_no |
| PC-04 | `sch_class_section_jnt` table exists |
| PC-05 | `msh_marksheet_schedules` table exists |
| PC-06 | `msh_subject_practical_configs` table exists |
| PC-07 | `msh_student_subject_results` table exists for sum computation |
| PC-08 | `msh_student_ia_marks` table exists for sum computation |
| PC-09 | `msh_student_coscholastic_results` table exists for sum computation |
| PC-10 | StudentResult model uses SoftDeletes trait |
| PC-11 | StudentResultRequest has create/update rules for all fields |
| PC-12 | WithholdStudentResultRequest requires withheld_reason (min:5) |
| PC-13 | Routes registered: resource + trashed/restore/forceDelete/toggleStatus/toggleWithhold |
| PC-14 | `config/permissionslist.php` has `msh-student-results` group |
| PC-15 | Blade views follow symmetrical @can/@canany pattern |
| PC-16 | `activityLog()` helper registered |
| PC-17 | Faker/lorem fields: withheld_reason, remarks |
| PC-18 | Grand total computed via StudentSubjectResult sum + StudentIaMark sum |
| PC-19 | Overall percentage, grade computed from grand_total |
| PC-20 | Status workflow: draft → computed → published → withheld/declared |

## 3. Default Data Load

| # | Data Load Rule | Source |
|---|----------------|--------|
| DL-01 | index(): paginate(10) with search/status filters | StudentResultController:42 |
| DL-02 | create(): no data — blank form | StudentResultController:56 |
| DL-03 | store(): $request->validated() + create() + activityLog | StudentResultController:66 |
| DL-04 | show($id): findOrFail + view | StudentResultController:80 |
| DL-05 | edit($id): findOrFail + view | StudentResultController:92 |
| DL-06 | update(): findOrFail + update + activityLog + redirect | StudentResultController:104 |
| DL-07 | destroy(): deactivate + delete + activityLog | StudentResultController:132 |
| DL-08 | trashed(): onlyTrashed paginate(10) | StudentResultController:149 |
| DL-09 | restore(): onlyTrashed + restore + reactivate + activityLog | StudentResultController:162 |
| DL-10 | forceDelete(): withTrashed + forceDelete + activityLog | StudentResultController:181 |
| DL-11 | toggleStatus(): validate + update is_active + AJAX | StudentResultController:197 |
| DL-12 | toggleWithhold(): validate + update is_withheld + AJAX | StudentResultController:215 |
| DL-13 | exportExcel(): Excel download | StudentResultController:243 |
| DL-14 | exportPrint(): Print view | StudentResultController:252 |
| DL-15 | downloadPdf(): PDF download | StudentResultController:261 |

## 4. Test Data Strategy

| # | Data Strategy | Details |
|---|---------------|---------|
| TD-01 | Zero results | Empty table |
| TD-02 | Single result with all fields | Complete record |
| TD-03 | 11 results (paginate 10) | Page 1 = 10, Page 2 = 1 |
| TD-04 | Mixed active/inactive | 3 active, 2 inactive |
| TD-05 | Mixed withheld | 2 withheld, 3 not |
| TD-06 | 2 soft-deleted | 1 restored, 1 force-deleted |
| TD-07 | Valid FK relationships | student, classSection, schedule |
| TD-08 | Null optional fields | withheld_reason, remarks null |
| TD-09 | Withheld with reason | 5+ char reason |
| TD-10 | Withheld without reason | Validation fails |
| TD-11 | Duplicate student_id+schedule_id | Unique composite fails |
| TD-12 | Fresh record | Just created |
| TD-13 | Immediately soft-deleted | destroy + check trashed |
| TD-14 | Restored record | check is_active=1 |
| TD-15 | Force-deleted | check gone |
| TD-16 | Student with 1/2/3/many results | Multiple per student |
| TD-17 | Schedule with many results | Compute aggregation |
| TD-18 | Results with subjectResults + iaMarks + coscholastic | Full computed record |
| TD-19 | 5 results, search by student name | Filter works |
| TD-20 | 3 active, 2 inactive, filter by status | Status filter works |

## 5. Business Conditions (BC)

### BC-DB: Database Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-DB-01 | `msh_student_results.id` — BIGINT PK AUTO_INCREMENT | Unique ID | Schema |
| BC-DB-02 | `msh_student_results.student_id` — BIGINT FK → std_students.id | FK to student | Schema |
| BC-DB-03 | `msh_student_results.class_section_id` — BIGINT FK → sch_class_section_jnt.id | FK to class-section | Schema |
| BC-DB-04 | `msh_student_results.schedule_id` — BIGINT FK → msh_marksheet_schedules.id | FK to schedule | Schema |
| BC-DB-05 | `msh_student_results.grand_total` — DECIMAL(10,2), NULLABLE | Sum of marks | Schema |
| BC-DB-06 | `msh_student_results.overall_percentage` — DECIMAL(5,2), NULLABLE | Percentage | Schema |
| BC-DB-07 | `msh_student_results.overall_grade` — VARCHAR(10), NULLABLE | Grade | Schema |
| BC-DB-08 | `msh_student_results.overall_grade_points` — DECIMAL(4,2), NULLABLE | Grade point avg | Schema |
| BC-DB-09 | `msh_student_results.is_active` — TINYINT(1), DEFAULT 1 | Active flag | Schema |
| BC-DB-10 | `msh_student_results.is_withheld` — TINYINT(1), DEFAULT 0 | Withheld flag | Schema |
| BC-DB-11 | `msh_student_results.withheld_reason` — TEXT, NULLABLE | Withheld reason | Schema |
| BC-DB-12 | `msh_student_results.remarks` — TEXT, NULLABLE | Additional remarks | Schema |
| BC-DB-13 | `msh_student_results.deleted_at` — TIMESTAMP, NULLABLE | Soft delete | Schema |
| BC-DB-14 | `msh_student_results.created_at` — TIMESTAMP | Creation timestamp | Schema |
| BC-DB-15 | `msh_student_results.updated_at` — TIMESTAMP | Update timestamp | Schema |
| BC-DB-16 | `std_students.id` — BIGINT PK | Student PK | Schema |
| BC-DB-17 | `std_students.first_name` — VARCHAR(100) | Student first name | Schema |
| BC-DB-18 | `std_students.last_name` — VARCHAR(100) | Student last name | Schema |
| BC-DB-19 | `std_students.admission_no` — VARCHAR(50) | Admission number | Schema |
| BC-DB-20 | `sch_class_section_jnt.id` — BIGINT PK | Class-section PK | Schema |
| BC-DB-21 | `sch_class_section_jnt.class_id` — BIGINT FK | FK to class | Schema |
| BC-DB-22 | `sch_class_section_jnt.section_id` — BIGINT FK | FK to section | Schema |
| BC-DB-23 | `msh_marksheet_schedules.id` — BIGINT PK | Schedule PK | Schema |
| BC-DB-24 | `msh_marksheet_schedules.name` — VARCHAR(255) | Schedule name | Schema |
| BC-DB-25 | `msh_student_results` has UNIQUE(student_id,schedule_id) composite key | Prevents duplicates | FormRequest rules |
| BC-DB-26 | DECIMAL(10,2) = max 99999999.99 | Grand total precision | Schema |
| BC-DB-27 | DECIMAL(5,2) = max 999.99 | Percentage precision | Schema |
| BC-DB-28 | DECIMAL(4,2) = max 99.99 | Grade points precision | Schema |
| BC-DB-29 | `msh_student_subject_results.student_result_id` — BIGINT FK | FK from subject results | Schema |
| BC-DB-30 | `msh_student_ia_marks.student_result_id` — BIGINT FK | FK from IA marks | Schema |
| BC-DB-31 | `msh_student_coscholastic_results.student_result_id` — BIGINT FK | FK from coscholastic | Schema |

### BC-VAL: Validation Conditions

| ID | Condition | Rule | Source |
|----|-----------|------|--------|
| BC-VAL-01 | `student_id` — required, integer, exists:std_students,id | FK must exist | StudentResultRequest |
| BC-VAL-02 | `class_section_id` — required, integer, exists:sch_class_section_jnt,id | FK must exist | StudentResultRequest |
| BC-VAL-03 | `schedule_id` — required, integer, exists:msh_marksheet_schedules,id | FK must exist | StudentResultRequest |
| BC-VAL-04 | `grand_total` — nullable, numeric, min:0, max:99999999.99 | Decimal(10,2) | StudentResultRequest |
| BC-VAL-05 | `overall_percentage` — nullable, numeric, min:0, max:100 | Decimal(5,2) | StudentResultRequest |
| BC-VAL-06 | `overall_grade` — nullable, string, max:10 | Grade string | StudentResultRequest |
| BC-VAL-07 | `overall_grade_points` — nullable, numeric, min:0, max:10 | Grade points | StudentResultRequest |
| BC-VAL-08 | `is_active` — boolean | Toggle | StudentResultRequest |
| BC-VAL-09 | `is_withheld` — boolean | Toggle | StudentResultRequest |
| BC-VAL-10 | `withheld_reason` — nullable, string, max:500 | Reason text | StudentResultRequest |
| BC-VAL-11 | `remarks` — nullable, string, max:1000 | Remarks text | StudentResultRequest |
| BC-VAL-12 | `student_id + schedule_id` — unique composite | Prevents duplicate | StudentResultRequest: unique rule |
| BC-VAL-13 | Create=true vs Update — unique rule ignores current record | Conditional unique | StudentResultRequest |
| BC-VAL-14 | `withheld_reason` — required if is_withheld=1 | Conditional required | WithholdStudentResultRequest |
| BC-VAL-15 | `withheld_reason` — min:5 characters | Minimum length | WithholdStudentResultRequest |
| BC-VAL-16 | `toggleStatus` validates `is_active` required+boolean | JSON validation | StudentResultController:199 |

### BC-AUTH: Authorization Conditions

| ID | Permission | Controller Gate | Method | Source |
|----|-----------|-----------------|--------|--------|
| BC-AUTH-01 | `tenant.msh-student-results.viewAny` | `Gate::authorize()` | index() | StudentResultController:40 |
| BC-AUTH-02 | `tenant.msh-student-results.create` | `Gate::authorize()` | create(), store() | SRController:54,64 |
| BC-AUTH-03 | `tenant.msh-student-results.view` | `Gate::authorize()` | show() | SRController:78 |
| BC-AUTH-04 | `tenant.msh-student-results.update` | `Gate::authorize()` | edit(), update(), toggleStatus(), toggleWithhold() | SRController:90,102,195,213 |
| BC-AUTH-05 | `tenant.msh-student-results.delete` | `Gate::authorize()` | destroy() | SRController:128 |
| BC-AUTH-06 | `tenant.msh-student-results.restore` | `Gate::authorize()` | trashed(), restore() | SRController:147,160 |
| BC-AUTH-07 | `tenant.msh-student-results.forceDelete` | `Gate::authorize()` | forceDelete() | SRController:179 |
| BC-AUTH-08 | `tenant.msh-student-results.export` | `Gate::authorize()` | exportExcel(), exportPrint(), downloadPdf() | SRController:241,250,259 |

### BC-BIZ: Business Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-BIZ-01 | store() uses $request->validated() | Only validated data | SRController:66 |
| BC-BIZ-02 | update() uses $request->validated() | Only validated data | SRController:106 |
| BC-BIZ-03 | activityLog() called after store | Log entry created | SRController:68 |
| BC-BIZ-04 | activityLog() called after update | Log entry with changes | SRController:109-120 |
| BC-BIZ-05 | activityLog() called after destroy | Trash logged | SRController:136 |
| BC-BIZ-06 | activityLog() called after restore | Restore logged | SRController:170 |
| BC-BIZ-07 | activityLog() called after forceDelete | Permanent delete logged | SRController:189 |
| BC-BIZ-08 | destroy() also deactivates | is_active=false before soft-delete | SRController:133 |
| BC-BIZ-09 | restore() also reactivates | is_active=true after restore | SRController:168 |
| BC-BIZ-10 | destroy() calls soft-delete | deleted_at set | SRController:135 |
| BC-BIZ-11 | index() filters by search string | LIKE search | SRController:45-47 |
| BC-BIZ-12 | index() filters by status | is_active filter | SRController:48-50 |
| BC-BIZ-13 | index() paginates 10 per page | ->paginate(10) | SRController:51 |
| BC-BIZ-14 | index() eager loads student + classSection | N+1 prevention | SRController:43 |
| BC-BIZ-15 | export/print routes | CSV/PDF generation | SRController:243,252,261 |
| BC-BIZ-16 | toggleStatus returns JSON | AJAX response | SRController:203-208 |
| BC-BIZ-17 | toggleWithhold returns JSON | AJAX response | SRController:226-232 |
| BC-BIZ-18 | Status workflow: draft → computed → published | Withheld is toggle | Requirement |
| BC-BIZ-19 | Grand total = sum of subject marks | Computation | Requirement |
| BC-BIZ-20 | Percentage = (grand_total/total_marks)*100 | Computation | Requirement |

### BC-REL: Relationship Conditions

| ID | Relationship | Type | Source |
|----|-------------|------|--------|
| BC-REL-01 | StudentResult → Student | belongsTo(student) | StudentResult.php:38-41 |
| BC-REL-02 | StudentResult → ClassSection | belongsTo(classSection) | StudentResult.php:43-46 |
| BC-REL-03 | StudentResult → MarksheetSchedule | belongsTo(schedule) | StudentResult.php:48-51 |
| BC-REL-04 | StudentResult → StudentSubjectResult | hasMany(subjectResults) | StudentResult.php:80-83 |
| BC-REL-05 | StudentResult → StudentIaMark | hasMany(iaMarks) | StudentResult.php:85-88 |
| BC-REL-06 | StudentResult → StudentCoscholasticResult | hasMany(coscholasticResults) | StudentResult.php:91-94 |
| BC-REL-07 | Student → StudentResult (inverse) | hasMany | Student model |
| BC-REL-08 | MarksheetSchedule → StudentResult (inverse) | hasMany | MarksheetSchedule model |

### BC-REF: Reference & UI Conditions

| ID | Condition | Expected | Source |
|----|-----------|----------|--------|
| BC-REF-01 | index view: table with Name, Admission, Schedule, %, Grade, Status, Action columns | Full table | Requirement |
| BC-REF-02 | create view: form with all fields + status-switch | Form layout | Requirement |
| BC-REF-03 | edit view: prefilled form + status-switch | Form layout | Requirement |
| BC-REF-04 | show view: detail cards (Basic Info + Additional) | Read-only | Requirement |
| BC-REF-05 | trash view: trashed records with restore/forceDelete | Trash table | Requirement |
| BC-REF-06 | Status switch component on index | x-backend.table.status-switch | Requirement |
| BC-REF-07 | Action component on index/detail | x-backend.table.action | Requirement |
| BC-REF-08 | Search bar with text filter + status dropdown | Search bar | Requirement |
| BC-REF-09 | Symmetrical @can on th/td for Status column | @can('...update') | Requirement |
| BC-REF-10 | Symmetrical @canany on th/td for Action column | @canany([view,update,delete]) | Requirement |
| BC-REF-11 | Breadcrumb with :links="[]" | Central config | Requirement |
| BC-REF-12 | Pagination centered, shows 10 records | ->links() | Requirement |
| BC-REF-13 | Responsive table container | div.table-responsive | Requirement |
| BC-REF-14 | Withhold switch in show/edit views | Toggle | Requirement |
| BC-REF-15 | Export/Print buttons visible with permission | @can('...export') | Requirement |

### BC-BIZ-DEEP: Deep Business Conditions

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-01 | store receives POST to /student-results | Route: marksheet-generation.student-results.store |
| BC-BIZ-DEEP-02 | Store validates via StudentResultRequest | All rules enforced |
| BC-BIZ-DEEP-03 | Unique composite: student_id + schedule_id | Prevents duplicates |
| BC-BIZ-DEEP-04 | Create passes validated data to Model::create() | Mass assignment |
| BC-BIZ-DEEP-05 | activityLog called after create with 'Stored' message | Log entry |
| BC-BIZ-DEEP-06 | Redirect to index with flash('created') | Success message |
| BC-BIZ-DEEP-07 | update validates via StudentResultRequest | PUT request |
| BC-BIZ-DEEP-08 | update finds existing record + original attributes | Diff tracking |
| BC-BIZ-DEEP-09 | Changes computed via getChanges() diff | Attribute audit |
| BC-BIZ-DEEP-10 | updated_at excluded from changes feed | Always excluded |
| BC-BIZ-DEEP-11 | activityLog 'Updated' with changes array | Audit trail |
| BC-BIZ-DEEP-12 | destroy: is_active=false + save before soft-delete | Two-step |
| BC-BIZ-DEEP-13 | destroy: calls ->delete() after save | Soft-delete |
| BC-BIZ-DEEP-14 | activityLog 'Trashed' after delete | Audit |
| BC-BIZ-DEEP-15 | trashed: onlyTrashed paginate | Excludes active |
| BC-BIZ-DEEP-16 | restore: onlyTrashed findOrFail | Strict |
| BC-BIZ-DEEP-17 | restore: is_active=true after restore | Reactivation |
| BC-BIZ-DEEP-18 | forceDelete: withTrashed findOrFail | Strict |
| BC-BIZ-DEEP-19 | forceDelete: calls ->forceDelete() | Permanent |
| BC-BIZ-DEEP-20 | toggleStatus: validates is_active required+boolean | JSON |
| BC-BIZ-DEEP-21 | toggleStatus: findOrFail + update + save | Atomic |
| BC-BIZ-DEEP-22 | toggleStatus returns JSON: success, is_active, message | AJAX compatible |
| BC-BIZ-DEEP-23 | toggleWithhold: validates is_withheld boolean + withheld_reason string|nullable | JSON |
| BC-BIZ-DEEP-24 | toggleWithhold: findOrFail + update both fields | Atomic |
| BC-BIZ-DEEP-25 | toggleWithhold returns JSON: success, is_withheld, message | AJAX compatible |
| BC-BIZ-DEEP-26 | index: Gate before query | Authorization first |
| BC-BIZ-DEEP-27 | index: $request->filled('search') guards LIKE | Safe null |
| BC-BIZ-DEEP-28 | index: where('is_active',(bool)$request->status) | Type cast |
| BC-BIZ-DEEP-29 | index: ->paginate(10)->withQueryString() | Preserves filters |
| BC-BIZ-DEEP-30 | show: findOrFail throws ModelNotFoundException | 404 |
| BC-BIZ-DEEP-31 | edit: findOrFail throws ModelNotFoundException | 404 |
| BC-BIZ-DEEP-32 | update: findOrFail throws ModelNotFoundException | 404 |
| BC-BIZ-DEEP-33 | destroy: findOrFail throws ModelNotFoundException | 404 |
| BC-BIZ-DEEP-34 | restore target: onlyTrashed findOrFail | Not found if active |
| BC-BIZ-DEEP-35 | forceDelete target: withTrashed findOrFail | Finds any (active/trashed) |
| BC-BIZ-DEEP-36 | index eager loads: student, classSection | Two relations |
| BC-BIZ-DEEP-37 | Blade: `{{ $result->student?->first_name }}` | Null-safe |
| BC-BIZ-DEEP-38 | Blade: `{{ $result->student?->admission_no }}` | Null-safe |
| BC-BIZ-DEEP-39 | Blade: `{{ $result->classSection?->class?->name }}` | Null-safe deep |
| BC-BIZ-DEEP-40 | Blade: `{{ $result->classSection?->section?->name }}` | Null-safe deep |
| BC-BIZ-DEEP-41 | Index: student name display with ID below | Pattern CRUD-UI Sec 7h |
| BC-BIZ-DEEP-42 | action component: view, edit, delete permissions | Symmetrical gating |
| BC-BIZ-DEEP-43 | status-switch component: used for is_active toggle | AJAX toggle |
| BC-BIZ-DEEP-44 | exportExcel: implements Excel download | File response |
| BC-BIZ-DEEP-45 | exportPrint: print-friendly view | Printable |
| BC-BIZ-DEEP-46 | downloadPdf: PDF generation | PDF download |
| BC-BIZ-DEEP-47 | index search searches student first_name/last_name + admission_no | Multi-field search |
| BC-BIZ-DEEP-48 | status filter: '1' = active, '0' = inactive, '' = all | Three-state |
| BC-BIZ-DEEP-49 | create view: blank form with all fields | Fresh input |
| BC-BIZ-DEEP-50 | edit view: old() fallback + $record values | Repopulation |
| BC-BIZ-DEEP-51 | store: redirect on success, @if($errors) on failure | Standard pattern |
| BC-BIZ-DEEP-52 | update: redirect on success, @if($errors) on failure | Standard pattern |
| BC-BIZ-DEEP-53 | destroy: redirect to index | Post-delete flow |
| BC-BIZ-DEEP-54 | restore: redirect to index | Post-restore flow |
| BC-BIZ-DEEP-55 | forceDelete: redirect to index | Post-permanent flow |
| BC-BIZ-DEEP-56 | toggleStatus: no page reload | AJAX response |
| BC-BIZ-DEEP-57 | toggleWithhold: no page reload | AJAX response |
| BC-BIZ-DEEP-58 | index pagination: only shown if ->hasPages() | Conditional |
| BC-BIZ-DEEP-59 | 4-column grid on create/edit forms | col-md-3 |
| BC-BIZ-DEEP-60 | Show has two info cards side-by-side | col-md-6 + col-md-6 |
| BC-BIZ-DEEP-61 | Withheld badge shown when is_withheld=1 | Visual indicator |
| BC-BIZ-DEEP-62 | Remarks displayed in show view | Read-only |
| BC-BIZ-DEEP-63 | Back button on show view | Route to index |
| BC-BIZ-DEEP-64 | No is_active column on create form | Status-switch only |
| BC-BIZ-DEEP-65 | is_active defaults to true via old('is_active',true) | New records active |
| BC-BIZ-DEEP-66 | Soft-deleted records excluded from index | ->onlyTrashed for trash |
| BC-BIZ-DEEP-67 | Export permissions separate from CRUD | Gate('...export') |
| BC-BIZ-DEEP-68 | Withhold toggle separate from Status toggle | Different AJAX routes |
| BC-BIZ-DEEP-69 | student_id expects existing student record | Referential integrity |
| BC-BIZ-DEEP-70 | schedule_id expects existing schedule | Referential integrity |
| BC-BIZ-DEEP-71 | class_section_id expects existing class-section | Referential integrity |
| BC-BIZ-DEEP-72 | Grand total nullable: allow null grade until computed | Workflow state |
| BC-BIZ-DEEP-73 | Percentage nullable: not computed yet | Workflow state |
| BC-BIZ-DEEP-74 | Grade nullable: not computed yet | Workflow state |
| BC-BIZ-DEEP-75 | Grade points nullable: not computed yet | Workflow state |
| BC-BIZ-DEEP-76 | Withheld reason only shown when is_withheld=1 | Conditional display |
| BC-BIZ-DEEP-77 | Student name: first + last concatenated | Full name |
| BC-BIZ-DEEP-78 | Admission no displayed alongside student name | Dual display |
| BC-BIZ-DEEP-79 | Schedule name shown in index | Relation via schedule_id |
| BC-BIZ-DEEP-80 | Created at formatted in show view | d M Y, h:i A format |

### CODE-TRACE: Line-by-Line Method Trace

#### CODE-TRACE-01: `index()` — Lines 39-53

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 40 | `Gate::authorize('tenant.msh-student-results.viewAny')` | Auth gate |
| 02 | 43 | `$query = StudentResult::with(['student','classSection'])` | Query builder + eager loads |
| 03 | 45 | `->when($request->filled('search'), fn($q)=>)` | Conditional filter |
| 04 | 46 | `$q->where('student_id', 'like', "%{$request->search}%")` | Search student_id |
| 05 | 47 | `->orWhere('schedule_id','like',...)->orWhere('...','like',...)` | Full search |
| 06 | 48 | `->when($request->filled('status'), fn($q)=>)` | Conditional status filter |
| 07 | 49 | `$q->where('is_active', (bool) $request->status)` | Boolean cast |
| 08 | 51 | `->latest()->paginate(10)->withQueryString()` | Paginate 10 |
| 09 | 53 | `return view(...compact('results'))` | Return view |

#### CODE-TRACE-02: `create()` — Lines 55-58

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 56 | `Gate::authorize('tenant.msh-student-results.create')` | Auth gate |
| 02 | 58 | `return view('marksheetgeneration::student-results.create')` | Return view |

#### CODE-TRACE-03: `store(StudentResultRequest $request)` — Lines 60-72

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 64 | `Gate::authorize('tenant.msh-student-results.create')` | Auth gate |
| 02 | 66 | `$result = StudentResult::create($request->validated())` | Create record |
| 03 | 68 | `activityLog($result, 'Stored', ['message'=>...,'performed_by'=>...])` | Log creation |
| 04 | 71 | `return redirect()->route(...)->with('success',flash(...))` | Redirect with flash |

#### CODE-TRACE-04: `show($id)` — Lines 74-84

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 78 | `Gate::authorize('tenant.msh-student-results.view')` | Auth gate |
| 02 | 80 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 03 | 83 | `return view(...compact('result'))` | Return view |

#### CODE-TRACE-05: `edit($id)` — Lines 86-96

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 90 | `Gate::authorize('tenant.msh-student-results.update')` | Auth gate |
| 02 | 92 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 03 | 95 | `return view(...compact('result'))` | Return view |

#### CODE-TRACE-06: `update(StudentResultRequest $request, $id)` — Lines 98-126

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 104 | `Gate::authorize('tenant.msh-student-results.update')` | Auth gate |
| 02 | 106 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 03 | 107 | `$original = $result->getOriginal()` | Snapshot for diff |
| 04 | 108 | `$result->update($request->validated())` | Update record |
| 05 | 111-114 | `foreach($result->getChanges() as $field=>$newValue)` | Compute changes |
| 06 | 112 | `if($field==='updated_at') continue` | Skip timestamp |
| 07 | 113 | `$changes[$field] = ['old'=>$original[$field],'new'=>$newValue]` | Change structure |
| 08 | 116-119 | `activityLog($result,'Updated',['message'=>...,'changes'=>$changes,...])` | Log update |
| 09 | 122 | `return redirect()->route(...)->with('success',flash(...))` | Redirect |

#### CODE-TRACE-07: `destroy($id)` — Lines 128-142

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 132 | `Gate::authorize('tenant.msh-student-results.delete')` | Auth gate |
| 02 | 134 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 03 | 135 | `$result->is_active = false; $result->save()` | Deactivate |
| 04 | 136 | `$result->delete()` | Soft delete |
| 05 | 138 | `activityLog(...'Trashed'...)` | Log trash |
| 06 | 141 | `return redirect()->route(...)->with('success',flash(...))` | Redirect |

#### CODE-TRACE-08: `trashed()` — Lines 144-152

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 149 | `Gate::authorize('tenant.msh-student-results.restore')` | Auth gate |
| 02 | 151 | `$results = StudentResult::onlyTrashed()->paginate(10)` | Trashed records |
| 03 | 152 | `return view(...compact('results'))` | Return view |

#### CODE-TRACE-09: `restore($id)` — Lines 154-174

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 162 | `Gate::authorize('tenant.msh-student-results.restore')` | Auth gate |
| 02 | 164 | `$result = StudentResult::onlyTrashed()->findOrFail($id)` | Find trashed |
| 03 | 165 | `$result->restore()` | Restore from soft-delete |
| 04 | 166 | `$result->is_active = true; $result->save()` | Reactivate |
| 05 | 168 | `activityLog(...'Restored'...)` | Log restore |
| 06 | 171 | `return redirect()->route(...)->with('success',flash(...))` | Redirect |

#### CODE-TRACE-10: `forceDelete($id)` — Lines 176-192

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 181 | `Gate::authorize('tenant.msh-student-results.forceDelete')` | Auth gate |
| 02 | 183 | `$result = StudentResult::withTrashed()->findOrFail($id)` | Find any status |
| 03 | 184 | `$result->forceDelete()` | Permanent delete |
| 04 | 186 | `activityLog(...'Deleted'...)` | Log permanent |
| 05 | 189 | `return redirect()->route(...)->with('success',flash(...))` | Redirect |

#### CODE-TRACE-11: `toggleStatus(Request $request, $id)` — Lines 194-210

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 197 | `Gate::authorize('tenant.msh-student-results.update')` | Auth gate |
| 02 | 199 | `$request->validate(['is_active'=>'required|boolean'])` | Inline validation |
| 03 | 201 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 04 | 202 | `$result->is_active = $request->boolean('is_active'); $result->save()` | Toggle |
| 05 | 204 | `activityLog(...'Toggled'...)` | Log toggle |
| 06 | 207-208 | `return response()->json(['success'=>true,'is_active'=>$result->is_active,'message'=>...])` | JSON response |

#### CODE-TRACE-12: `toggleWithhold(Request $request, $id)` — Lines 212-234

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 215 | `Gate::authorize('tenant.msh-student-results.update')` | Auth gate |
| 02 | 217 | `$request->validate(['is_withheld'=>'required|boolean','withheld_reason'=>'nullable|string'])` | Validation |
| 03 | 219 | `$result = StudentResult::findOrFail($id)` | Find or 404 |
| 04 | 220-221 | `$result->is_withheld = $request->boolean('is_withheld'); $result->withheld_reason = $request->input('withheld_reason')` | Set fields |
| 05 | 222 | `$result->save()` | Save |
| 06 | 226-227 | `return response()->json(['success'=>true,'is_withheld'=>$result->is_withheld,'message'=>...])` | JSON response |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Create result with all fields | Valid student_id, schedule_id, class_section_id, active | 302 redirect to index, success flash |
| TC-P-02 | Create result with is_active=false | Created inactive | 302 redirect, success flash |
| TC-P-03 | View index with results | Paginated list | 10 per page, student name visible |
| TC-P-04 | View show page | Full detail | All fields, student relation, links |
| TC-P-05 | Edit result | Prefilled form | Update success, activityLog |
| TC-P-06 | Soft-delete result | destroy() call | is_active=false, trashed |
| TC-P-07 | Restore result | restore() call | is_active=true, active |
| TC-P-08 | Force-delete result | Permanently removed | Gone from DB |
| TC-P-09 | Toggle status to inactive | is_active=0 | AJAX success, false |
| TC-P-10 | Toggle status to active | is_active=1 | AJAX success, true |
| TC-P-11 | Toggle withhold ON | is_withheld=1, reason="..." | JSON success |
| TC-P-12 | Toggle withhold OFF | is_withheld=0 | JSON success |
| TC-P-13 | Search by student name | Partial match | Filtered results |
| TC-P-14 | Filter by active status | status=1 | Only active |
| TC-P-15 | Filter by inactive status | status=0 | Only inactive |
| TC-P-16 | Index page 2 | ?page=2 | Records 11-20 |
| TC-P-17 | Trash page with results | trashed() | Deleted records listed |
| TC-P-18 | Create with grand_total=0 | Minimum value | Success |
| TC-P-19 | Create with grand_total=99999999.99 | Max decimal(10,2) | Success |
| TC-P-20 | Create with overall_percentage=100 | Max percentage | Success |
| TC-P-21 | Update only remarks | Partial update | Only remarks changed |
| TC-P-22 | Update all fields | Full update | All changes tracked in activityLog |
| TC-P-23 | Create with optional fields null | withheld_reason=null, remarks=null | Success |
| TC-P-24 | Search by admission_no | Exact match | Single result |
| TC-P-25 | Search by schedule_id | Exact match | Filtered results |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Create without student_id | Missing required | Validation error |
| TC-N-02 | Create without schedule_id | Missing required | Validation error |
| TC-N-03 | Create with non-existent student_id | FK violation | Validation error |
| TC-N-04 | Create with non-existent schedule_id | FK violation | Validation error |
| TC-N-05 | Create with grand_total = -1 | Out of range | Validation error |
| TC-N-06 | Create with grand_total > 99999999.99 | Overflow | Validation error |
| TC-N-07 | Create with overall_percentage = 101 | Out of range | Validation error |
| TC-N-08 | Create with overall_percentage = -1 | Negative | Validation error |
| TC-N-09 | Create with duplicate student_id+schedule_id | Composite unique | Validation error |
| TC-N-10 | Create with overall_grade > 10 chars | Too long | Validation error |
| TC-N-11 | Update with duplicate student_id+schedule_id (excl. self) | Unique violation | Validation error |
| TC-N-12 | Access index without viewAny permission | Unauthorized | 403 Forbidden |
| TC-N-13 | Access create without create permission | Unauthorized | 403 Forbidden |
| TC-N-14 | POST store without create permission | Unauthorized | 403 Forbidden |
| TC-N-15 | Access edit without update permission | Unauthorized | 403 Forbidden |
| TC-N-16 | PUT update without update permission | Unauthorized | 403 Forbidden |
| TC-N-17 | DELETE destroy without delete permission | Unauthorized | 403 Forbidden |
| TC-N-18 | Access trash without restore permission | Unauthorized | 403 Forbidden |
| TC-N-19 | show non-existent ID | Not found | 404 |
| TC-N-20 | edit non-existent ID | Not found | 404 |
| TC-N-21 | update non-existent ID | Not found | 404 |
| TC-N-22 | destroy non-existent ID | Not found | 404 |
| TC-N-23 | restore active (non-trashed) record | Not in trash | 404 |
| TC-N-24 | forceDelete active record | Not via onlyTrashed | 200 (withTrashed works) |
| TC-N-25 | Create with is_withheld=1 but withheld_reason empty | Conditional required | Validation error |
| TC-N-26 | Create with withheld_reason < 5 chars | Too short | Validation error |
| TC-N-27 | toggleStatus with missing is_active | Required field | Validation error |
| TC-N-28 | toggleStatus with non-boolean is_active | Invalid | Validation error |
| TC-N-29 | Access index with invalid query params | XSS attempt | Sanitized |
| TC-N-30 | POST to show route | Method mismatch | 405 |

### TC-SQ: Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-01 | SQLi in search field | `' OR 1=1--` | Escaped by LIKE |
| TC-SQ-02 | XSS in student name | `<script>alert(1)</script>` | Blade auto-escapes |
| TC-SQ-03 | Mass assignment attempt | Extra fields in POST | Guarded by validated() |
| TC-SQ-04 | CSRF without token | Missing @csrf | 419 Page Expired |
| TC-SQ-05 | Unauthorized route access | No permission | 403 |

### TC-INT: Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-01 | Create result → appears in index | Store then view | Present on page 1 |
| TC-INT-02 | Update result → changes in show | Edit then view | Updated fields |
| TC-INT-03 | Soft-delete → appears in trash | Destroy then trash page | Listed in trash |
| TC-INT-04 | Restore → disappears from trash, appears in index | Restore flow | Back to active |
| TC-INT-05 | Force-delete → disappears completely | Force delete | 404 on show |
| TC-INT-06 | Status toggle → reflected in index | Toggle twice | State changed back |
| TC-INT-07 | Withhold toggle → badge changes in show | Toggle twice | Withhold indicator |
| TC-INT-08 | Search + pagination | Search term + page 2 | Filtered across pages |

---

## 7. Detailed Test Execution Procedures

### TC-P-01: Create result with all valid fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with tenant.msh-student-results.create | Authorized |
| 2 | Navigate to create page | Form displayed |
| 3 | Select student from dropdown | Student loaded |
| 4 | Select schedule from dropdown | Schedule loaded |
| 5 | Select class-section from dropdown | Class-section loaded |
| 6 | Enter grand_total: 850.50 | Accepted |
| 7 | Enter overall_percentage: 85.05 | Accepted |
| 8 | Enter overall_grade: A+ | Accepted |
| 9 | Enter overall_grade_points: 9.50 | Accepted |
| 10 | Ensure is_active checked | Default true |
| 11 | Submit form | POST to store |
| 12 | Verify Gate::authorize passes | 200 |
| 13 | Verify validated() | All rules pass |
| 14 | Verify redirect to index | 302 |
| 15 | Verify success flash | Message shown |
| 16 | Verify activityLog called | Log entry |
| 17 | Verify record in DB | Created |

### TC-P-10: Toggle status to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Navigate to index | Results list |
| 3 | Click status-switch for inactive result | AJAX call |
| 4 | Verify Gate::authorize('update') | Passes |
| 5 | Verify JSON response success=true, is_active=true | Correct |
| 6 | Verify badge changed visually | Active class |

### TC-N-09: Duplicate composite key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create result with student_id=1, schedule_id=1 | Success |
| 2 | Navigate to create | Form |
| 3 | Select same student+schedule | Duplicate |
| 4 | Submit form | Validation error |
| 5 | Verify "already exists" message | Shown |

### TC-P-13: Search by student name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Authorized |
| 2 | Enter search term "John" in search box | Input |
| 3 | Submit search | GET with ?search=John |
| 4 | Verify Gate::authorize passes | 200 |
| 5 | Verify filtered results | Only John's results |
| 6 | Verify pagination preserved | withQueryString |

### TC-N-19: Show non-existent ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with view permission | Authorized |
| 2 | Navigate to /student-results/99999 | Non-existent ID |
| 3 | Gate::authorize passes | Checked first |
| 4 | findOrFail(99999) throws ModelNotFoundException | 404 |
| 5 | Verify 404 page | Shown |

### TC-P-03: View index with results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with viewAny permission | Authorized |
| 2 | Navigate to index | Page renders |
| 3 | Verify Gate::authorize at line 40 | Passes |
| 4 | Verify table headers: Student, Admission, Schedule, %, Grade, Status, Action | All present |
| 5 | Verify each row shows student name with admission below | Pattern Sec 7h |
| 6 | Verify schedule name via relation | Displayed |
| 7 | Verify percentage and grade shown | Calculated fields |
| 8 | Verify action buttons based on permissions | view/edit/delete |

### TC-P-05: Edit result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Navigate to edit for record | Form renders |
| 3 | Verify form prefilled with current values | Match DB |
| 4 | Change grand_total from 850 to 900 | Updated |
| 5 | Submit form | PUT request |
| 6 | Verify Gate::authorize at line 104 | Passes |
| 7 | Verify findOrFail retrieves record | Found |
| 8 | Verify getOriginal() captures old values | Snapshot |
| 9 | Verify update() persists new value | Updated |
| 10 | Verify getChanges() detects grand_total change | [old:850, new:900] |
| 11 | Verify activityLog 'Updated' with changes array | Logged |
| 12 | Verify redirect to index with flash | 302 + message |

### TC-P-07: Restore result

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with restore permission | Authorized |
| 2 | Navigate to trash page | Trashed list |
| 3 | Locate record | Visible |
| 4 | Click restore action | Confirm |
| 5 | Verify Gate::authorize('...restore') | Passes |
| 6 | Verify onlyTrashed()->findOrFail() finds | Found |
| 7 | Verify ->restore() sets deleted_at=null | Restored |
| 8 | Verify is_active = true | Reactivated |
| 9 | Verify activityLog 'Restored' | Logged |
| 10 | Verify redirect to index | 302 |
| 11 | Verify record visible in index | Back to active |

### TC-P-11: Toggle withhold ON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with update permission | Authorized |
| 2 | Navigate to show page for result | Detail |
| 3 | Click withhold toggle | AJAX call |
| 4 | Verify Gate::authorize('...update') | Passes |
| 5 | Verify is_withheld set to true | Updated |
| 6 | Verify withheld_reason saved | Text stored |
| 7 | Verify JSON response: success=true, is_withheld=true | Correct |
| 8 | Verify withheld badge shown | Visual |

### TC-N-09: Duplicate composite key

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create result: student_id=1, schedule_id=1 | Success |
| 2 | Navigate to create | Form |
| 3 | Select same student+schedule | Duplicate |
| 4 | Submit form | Validation error |
| 5 | Verify "already exists" for student_id+schedule_id | Error shown |

### TC-N-12: Access index without viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT student-results.viewAny | No permission |
| 2 | Navigate to /student-results | 403 Forbidden |
| 3 | Verify Gate::authorize stops at line 40 | Before queries |
| 4 | Verify no DB queries executed | Clean |

### TC-N-25: Create with is_withheld=1 no reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form |
| 2 | Set is_withheld = true | Checked |
| 3 | Leave withheld_reason empty | Missing |
| 4 | Submit form | Validation error |
| 5 | Verify "withheld_reason required when is_withheld=1" | Error shown |

### TC-INT-01: Create result → appears in index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note current record count | Baseline |
| 2 | Create new StudentResult | Success |
| 3 | Navigate to index | Page |
| 4 | Verify new record visible | Present |
| 5 | Verify count increased by 1 | +1 |

### TC-INT-03: Soft-delete → appears in trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note record in index | Active |
| 2 | Soft-delete record | Success |
| 3 | Verify record gone from index | Hidden |
| 4 | Navigate to trash page | Trash list |
| 5 | Verify record listed in trash | Visible |
| 6 | Verify is_active=false, deleted_at set | State correct |

---

### CODE-TRACE-HUB: `results()` Student-Results Tab — MarksheetGenerationController Lines 147-301

#### 1. `$makeResultQuery` Closure (Lines 162-178)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 162 | `$makeResultQuery = function (string $csParam) use ($request, $search, $tab)` | Closure definition — captures $request, $search, $tab from outer scope |
| 02 | 164 | `StudentResult::with(['student', 'classSection.class', 'classSection.section'])` | Nested eager load (3 levels) for N+1 prevention |
| 03 | 165-171 | `if ($search) { $q->whereHas('student', fn($sq) => $sq->where(...)->orWhere(...)) }` | Student search via whereHas on first_name, last_name, admission_no — uses LIKE |
| 04 | 172-173 | `if ($csId) { $q->where('class_section_id', $csId)->orderByDesc('grand_total') }` | Class-section filter + sort by grand_total DESC |
| 05 | 174-175 | `else { $q->orderBy('class_section_id')->orderByDesc('grand_total') }` | Global sort: class_section_id ASC then grand_total DESC |
| 06 | 177 | `return [$q, $csId];` | Returns [QueryBuilder, classSectionId] tuple |

#### 2. Student Results Query (Lines 180-182)

| Step | Line(s) | Code | Purpose |
|------|---------|------|---------|
| 01 | 181 | `[$srQuery, $srClassSectionId] = $makeResultQuery('sr_class_section_id')` | Invoke closure with param name 'sr_class_section_id' |
| 02 | 182 | `$studentResults = $srQuery->paginate(15, ['*'], 'sr_page')` | Paginate 15 per page, unique paginator name 'sr_page' |
| 03 | 236 | `$marksheetSchedules = MarksheetSchedule::orderBy('name')->get()` | Reference list for schedule dropdown |
| 04 | 241 | `$students = Student::where('is_active', 1)->orderBy('id')->get()` | Reference list for student dropdown |
| 05 | 295-301 | `return view(...compact(..., 'studentResults', ...))` | Pass all variables to combined results view |

### Additional BC-BIZ-DEEP: Deep Business Conditions — Special Workflow Methods

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| BC-BIZ-DEEP-81 | `withhold()` uses `WithholdStudentResultRequest` — validates `withheld_reason` as string | `$request->validated()['withheld_reason']` passed to `$this->review->withhold()` |
| BC-BIZ-DEEP-82 | `withhold()` calls `StudentResultReviewService::withhold()` with (result, auth()->id(), reason) | Service handles state transition to `withheld` status |
| BC-BIZ-DEEP-83 | `withhold()` catches `DomainException` from ReviewService | Redirects back to show() with error message |
| BC-BIZ-DEEP-84 | `withhold()` logs activity with `'Withheld'` action, includes reason in log | `activityLog($studentResult, 'Withheld', ['message' => ..., 'reason' => ...])` |
| BC-BIZ-DEEP-85 | `withhold()` Gate uses `tenant.msh-student-result.withhold` | Permission checked before any service call |
| BC-BIZ-DEEP-86 | `declare()` calls `StudentResultReviewService::declare()` with (result, auth()->id()) | Service handles state transition to `published` status, sets `declared_at` |
| BC-BIZ-DEEP-87 | `declare()` catches `DomainException` from ReviewService | Redirects back with error message |
| BC-BIZ-DEEP-88 | `declare()` logs activity with `'Declared'` action | `activityLog($studentResult, 'Declared', ['message' => 'Student result declared.'])` |
| BC-BIZ-DEEP-89 | `declare()` Gate uses `tenant.msh-student-result.declare` | Separate permission from update/withhold |
| BC-BIZ-DEEP-90 | `export()` uses `Excel::download()` with `StudentResultExport` class | Downloads `student_result_{$studentResult->id}.xlsx` |
| BC-BIZ-DEEP-91 | `export()` Gate uses `tenant.msh-student-result.export` | Export-specific permission |
| BC-BIZ-DEEP-92 | `export()` passes `(int) $studentResult->id` to `StudentResultExport` constructor | Exporter receives integer ID, not model |
| BC-BIZ-DEEP-93 | `print()` renders template `MARKSHEET_PRINT` via `Template::render()` | Template facade with subjectId, classId, sessionId, studentId params |
| BC-BIZ-DEEP-94 | `print()` catches `DomainException` from `Template::render()` | Redirects to show page with "Cannot print: {error}" |
| BC-BIZ-DEEP-95 | `print()` Gate uses `tenant.msh-student-result.print` | Print-specific permission |
| BC-BIZ-DEEP-96 | `downloadPdf()` renders `MARKSHEET_PRINT` template first | Same template rendering as print() |
| BC-BIZ-DEEP-97 | `downloadPdf()` redirects to print route with `?download=1&auto=1` | Uses browser-side html2pdf.js (NOT DomPDF) |
| BC-BIZ-DEEP-98 | `downloadPdf()` Gate uses `tenant.msh-student-result.print` | Same permission as print() |
| BC-BIZ-DEEP-99 | `show()` loads 7 relations via `$studentResult->load()` | marksheetSchedule, student, classSection.class/section, subjectResults.subject, coscholasticResults.templateComponent |
| BC-BIZ-DEEP-100 | `show()` scopes subjectResults relation to current schedule | `$studentResult->subjectResults->where('schedule_id', $studentResult->schedule_id)` |
| BC-BIZ-DEEP-101 | `show()` scopes coscholasticResults relation to current schedule | `$studentResult->coscholasticResults->where('schedule_id', $studentResult->schedule_id)` |
| BC-BIZ-DEEP-102 | `show()` loads `StudentSubjectExamMark` grouped by subject_id | Independent query with ->groupBy('subject_id') |
| BC-BIZ-DEEP-103 | `show()` loads `StudentIaMark` grouped by subject_id | Independent query with ->groupBy('subject_id') |
| BC-BIZ-DEEP-104 | `show()` loads `StudentAttendance` for the student+schedule | Single record ->first() |
| BC-BIZ-DEEP-105 | `show()` passes 4 variables to view: `compact('studentResult', 'examMarks', 'iaMarks', 'attendance')` | View receives full data for marksheet rendering |
| BC-BIZ-DEEP-106 | `store()` adds `created_by` and `updated_by` to validated data | `$validatedData['created_by'] = auth()->id(); $validatedData['updated_by'] = auth()->id()` |
| BC-BIZ-DEEP-107 | `store()` redirects to show page, not index | `->route('marksheet-generation.student-result.show', $studentResult)` |
| BC-BIZ-DEEP-108 | `update()` adds `updated_by` to validated data | `$validatedData['updated_by'] = auth()->id()` |
| BC-BIZ-DEEP-109 | `update()` redirects to show page, not index | `->route('marksheet-generation.student-result.show', $studentResult)` |
| BC-BIZ-DEEP-110 | `destroy()` does NOT deactivate before soft-delete | Direct `$studentResult->delete()` — no `is_active = false` step |
| BC-BIZ-DEEP-111 | `destroy()` does NOT use `getOriginal()`/`getChanges()` | No change tracking in destroy |
| BC-BIZ-DEEP-112 | `destroy()` logs `'Deleted'` activity (not 'Trashed') | `activityLog($studentResult, 'Deleted', [message => 'The student result was deleted.'])` |
| BC-BIZ-DEEP-113 | No `trashed()` / `restore()` / `forceDelete()` methods on controller | Only resource methods + special workflow methods |
| BC-BIZ-DEEP-114 | No `toggleStatus()` method on controller | Status management via withhold/declare only |
| BC-BIZ-DEEP-115 | `index()` redirects to `results.combined` tab | `redirect()->route('marksheet-generation.results.combined', ['tab' => 'student-results'])` |
| BC-BIZ-DEEP-116 | `edit()` loads schedules with `whereNull('deleted_at')` | Filters out soft-deleted schedules from dropdown |
| BC-BIZ-DEEP-117 | `print()` returns view with `$html` (rendered template) and `$studentResult` | View `marksheetgeneration::student-result.print` receives pre-rendered HTML |
| BC-BIZ-DEEP-118 | `preparePdfTemplateHtml()` private method for DomPDF layout adjustment | Parses DOM, adjusts card dimensions, localizes image sources, applies DejaVu Sans font |
| BC-BIZ-DEEP-119 | `preparePdfTemplateHtml()` measures `.certificate-card` dimensions via CSS | Extracts width/height in px, converts to pt (×0.75) |
| BC-BIZ-DEEP-120 | `normalizePdfCardFont()` replaces font-family with 'DejaVu Sans' | Required for Hindi/UTF-8 character support in DomPDF |
| BC-BIZ-DEEP-121 | `localizePdfImageSources()` converts URL paths to local filesystem paths | Handles `public-*/`, `storage/` prefixes |
| BC-BIZ-DEEP-122 | `adjustDynamicMarksTableLayout()` shifts sibling elements below `.tpl-dynamic-marks` table | Compensates for dynamic table height growth in DomPDF |
| BC-BIZ-DEEP-123 | `show()` receives `$studentResult` via route-model-binding | `show(StudentResult $studentResult)` — auto resolved |
| BC-BIZ-DEEP-124 | `create()` loads active schedules, students, classSections for dropdown selects | 3 independent queries for form reference data |
| BC-BIZ-DEEP-125 | `create()` uses `where('is_active', 1)` on schedules, students, classSections | Only active records in dropdown |
| BC-BIZ-DEEP-126 | `edit()` uses same dropdown loading as `create()` | Symmetrical form population |
| BC-BIZ-DEEP-127 | `withhold()` uses route-model-binding | `withhold(WithholdStudentResultRequest $request, StudentResult $studentResult)` |
| BC-BIZ-DEEP-128 | `declare()` uses route-model-binding | `declare(StudentResult $studentResult)` |
| BC-BIZ-DEEP-129 | `export()` uses route-model-binding | `export(StudentResult $studentResult)` |
| BC-BIZ-DEEP-130 | `print()` uses route-model-binding | `print(StudentResult $studentResult)` |
| BC-BIZ-DEEP-131 | `downloadPdf()` uses route-model-binding | `downloadPdf(StudentResult $studentResult)` |
| BC-BIZ-DEEP-132 | `preparePdfTemplateHtml()` handles empty HTML gracefully | Returns fallback dimensions if HTML is empty |
| BC-BIZ-DEEP-133 | `preparePdfTemplateHtml()` handles missing `.certificate-card` class gracefully | Falls back to default 711×786pt page |
| BC-BIZ-DEEP-134 | `preparePdfTemplateHtml()` uses `libxml_use_internal_errors(true)` | Suppresses HTML parsing warnings |
| BC-BIZ-DEEP-135 | `preparePdfTemplateHtml()` returns min of fallback or computed dimensions | `max($pageWidthPt, $fallbackWidthPt)` |
| BC-BIZ-DEEP-136 | `adjustDynamicMarksTableLayout()` calculates estimated table height | `(headerCount × 32px) + (rowCount × 29px) + 12px padding` |
| BC-BIZ-DEEP-137 | `adjustDynamicMarksTableLayout()` shifts only elements BELOW the table | Only elements with `top > tableTop` are shifted |
| BC-BIZ-DEEP-138 | `parseInlineStyle()` splits on `;` then `:` | Returns associative array of CSS properties |
| BC-BIZ-DEEP-139 | `buildInlineStyle()` reconstructs CSS from associative array | `property: value;` format |
| BC-BIZ-DEEP-140 | `extractPxValue()` regex extracts first number | Returns float or null |
| BC-BIZ-DEEP-141 | `formatPxValue()` rounds to 2 decimals, strips trailing zeros | Clean px string output |
| BC-BIZ-DEEP-142 | `resolvePdfLocalImagePath()` handles 3 URL formats | `public-/`, `storage/`, and relative paths |
| BC-BIZ-DEEP-143 | Gate order: `index()` checks view before redirect | `Gate::authorize('tenant.msh-student-result.view')` then redirect |
| BC-BIZ-DEEP-144 | `results()` main hub uses `Gate::authorize('tenant.msh-results.view')` at line 149 | Single gate for entire combined results page |
| BC-BIZ-DEEP-145 | `store()` flash key: `created.student_result` | Must exist in lang file |
| BC-BIZ-DEEP-146 | `update()` flash key: `updated.student_result` | Must exist in lang file |
| BC-BIZ-DEEP-147 | `destroy()` uses hardcoded success message, not flash() | `with('success', 'Student result deleted.')` — inconsistent with store/update |
| BC-BIZ-DEEP-148 | `withhold()` uses hardcoded success message | `with('success', 'Result withheld.')` |
| BC-BIZ-DEEP-149 | `declare()` uses hardcoded success message | `with('success', 'Result declared.')` |
| BC-BIZ-DEEP-150 | `preparePdfTemplateHtml()` is private — not callable from routes | Internal helper only for DomPDF pipeline |
| BC-BIZ-DEEP-151 | `printStudentMarksheet()` is empty method placeholder | No implementation — dead code |
| BC-BIZ-DEEP-152 | `StudentResultController` uses constructor DI for `StudentResultReviewService` | `private readonly StudentResultReviewService $review` — Laravel auto-resolves |
| BC-BIZ-DEEP-153 | Withhold flow: Gate → Request validation → Service withold → activityLog → redirect | Full 5-step pipeline |
| BC-BIZ-DEEP-154 | Declare flow: Gate → Service declare → activityLog → redirect | 4-step pipeline (no request validation needed) |
| BC-BIZ-DEEP-155 | Export flow: Gate → Excel::download with exporter | Returns file download response, not redirect |
| BC-BIZ-DEEP-156 | Print flow: Gate → Template::render → return view with HTML | Returns Blade view with pre-rendered template |
| BC-BIZ-DEEP-157 | PDF flow: Gate → Template::render → redirect to print page with params | 2-step: render, then redirect to browser-based PDF generation |
| BC-BIZ-DEEP-158 | `results()` tab param `sr_class_section_id` drives class-section filter | Only applied when non-null, otherwise shows all |
| BC-BIZ-DEEP-159 | Distinct class-section IDs computed from StudentResult table | `StudentResult::distinct()->pluck('class_section_id')` — only sections with results |
| BC-BIZ-DEEP-160 | Class-section dropdown sorted by class name + section name | `->sortBy(fn($cs) => ($cs->class?->name ?? '') . ($cs->section?->name ?? ''))` |

### Additional Test Cases

#### TC-P: Additional Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-26 | Withhold result with valid reason | POST withhold with "Pending disciplinary review" | Status→withheld, activityLog 'Withheld', flash "Result withheld." |
| TC-P-27 | Declare result from computed status | POST declare on computed result | Status→published, declared_at set, flash "Result declared." |
| TC-P-28 | Export result to Excel | Click export button | File download `student_result_{id}.xlsx` |
| TC-P-29 | Print marksheet via Template render | Click print button | Print view with rendered MARKSHEET_PRINT HTML |
| TC-P-30 | Download PDF via html2pdf.js | Click PDF download | Redirect to print page with ?download=1&auto=1 |
| TC-P-31 | Show result with all relations loaded | Click view on result | 7 relations loaded: schedule, student, classSection, subjectResults, coscholasticResults, examMarks, iaMarks, attendance |
| TC-P-32 | Show exam marks grouped by subject | Expand exam marks section | StudentSubjectExamMark records grouped by subject_id |
| TC-P-33 | Show IA marks grouped by subject | Expand IA marks section | StudentIaMark records grouped by subject_id |
| TC-P-34 | Show student attendance record | Attendance section visible | Single StudentAttendance record displayed |
| TC-P-35 | create() loads schedules, students, classSections | Open create form | 3 dropdowns populated with active records |
| TC-P-36 | Store adds created_by/updated_by | Create new result via POST | created_by and updated_by set to auth()->id() |
| TC-P-37 | Update adds updated_by | Edit existing result via PUT | updated_by set to auth()->id() |
| TC-P-38 | results() combined page loads with sr_page pagination | Navigate to Results hub | sr_page=2 shows next 15 results |
| TC-P-39 | results() class-section dropdown sorted alphabetically | Open dropdown | Class 10A before Class 9B |
| TC-P-40 | results() distinct class-sections only from results | Create result for new section | Only sections with results appear in dropdown |
| TC-P-41 | show() scopes subjectResults to current schedule | View result with multi-schedule | Only this schedule's subject results shown |
| TC-P-42 | show() scopes coscholasticResults to current schedule | View result with multi-schedule | Only this schedule's coscholastic results shown |
| TC-P-43 | Withhold then Declare (restore flow) | Withhold → Declare | Result published with declared_at |
| TC-P-44 | Prepare PDF template with certificate-card | Generate PDF HTML | Card dimensions extracted, DejaVu Sans applied |
| TC-P-45 | Prepare PDF with missing certificate-card class | Generate without card | Falls back to default page dimensions |
| TC-P-46 | PDF image source localization | Image from storage/ | URL rewritten to local filesystem path |
| TC-P-47 | Dynamic marks table layout adjustment | Multi-row marks table | Sibling elements shifted below table |
| TC-P-48 | parseInlineStyle and buildInlineStyle round-trip | CSS → array → CSS | Original properties preserved |
| TC-P-49 | extractPxValue with multiple formats | 100px, 100.5px, 100 | All return correct float |
| TC-P-50 | formatPxValue with integer rounding | 100.00 → "100px", 100.50 → "100.5px" | Clean output formats |

#### TC-N: Additional Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-31 | Withhold with empty reason | POST withhold without withheld_reason | WithholdStudentResultRequest validation fails |
| TC-N-32 | Withhold with reason < 5 chars | POST withhold with "No" | WithholdStudentResultRequest min:5 validation fails |
| TC-N-33 | Withhold without `tenant.msh-student-result.withhold` | No permission | 403 Forbidden |
| TC-N-34 | Declare without `tenant.msh-student-result.declare` | No permission | 403 Forbidden |
| TC-N-35 | Export without `tenant.msh-student-result.export` | No permission | 403 Forbidden |
| TC-N-36 | Print without `tenant.msh-student-result.print` | No permission | 403 Forbidden |
| TC-N-37 | downloadPdf without `tenant.msh-student-result.print` | No permission | 403 Forbidden |
| TC-N-38 | Withhold on invalid state (DomainException) | Service throws DomainException | Redirect to show with error message |
| TC-N-39 | Declare on invalid state (DomainException) | Service throws DomainException | Redirect to show with error message |
| TC-N-40 | Print with template rendering failure | Template::render throws DomainException | Redirect with "Cannot print: {error}" |
| TC-N-41 | downloadPdf with template rendering failure | Template::render throws DomainException | Redirect with "Cannot generate PDF: {error}" |
| TC-N-42 | Show non-existent student result | Route-model-binding on bad ID | 404 ModelNotFoundException |
| TC-N-43 | Edit non-existent student result | Route-model-binding on bad ID | 404 ModelNotFoundException |
| TC-N-44 | Update non-existent student result | Route-model-binding on bad ID | 404 ModelNotFoundException |
| TC-N-45 | Destroy non-existent student result | Route-model-binding on bad ID | 404 ModelNotFoundException |
| TC-N-46 | index() accessed without view permission | No tenant.msh-student-result.view | 403 before redirect |
| TC-N-47 | results() combined page without msh-results.view | No permission | 403 at MarksheetGenerationController:149 |
| TC-N-48 | show() without view permission | No tenant.msh-student-result.view | 403 before load() |
| TC-N-49 | create() without create permission | No tenant.msh-student-result.create | 403 before column |
| TC-N-50 | store() without create permission | No create permission | 403 before create |
| TC-N-51 | edit() without update permission | No update permission | 403 before column |
| TC-N-52 | update() without update permission | No update permission | 403 before update |
| TC-N-53 | destroy() without delete permission | No delete permission | 403 before delete |
| TC-N-54 | Print template rendering empty HTML | Template returns empty string | preparePdfTemplateHtml returns fallback dimensions |
| TC-N-55 | PDF with no .tpl-dynamic-marks table | Template has no marks table | adjustDynamicMarksTableLayout returns early |
| TC-N-56 | DomPDF with missing DejaVu Sans font | Server has no DejaVu Sans | Font fallback applied by normalizePdfCardFont |
| TC-N-57 | Image source with invalid URL | src="https://invalid.example/img.jpg" | resolvePdfLocalImagePath returns null, original URL preserved |
| TC-N-58 | Image src is data: URI | src="data:image/png;base64,..." | localizePdfImageSources skips data URIs |
| TC-N-59 | XPath card not found | No element with certificate-card class | preparePdfTemplateHtml returns fallback |
| TC-N-60 | create() with non-existent student_id FK | Student ID 99999 | StudentResultRequest validation error |
| TC-N-61 | create() with non-existent schedule_id FK | Schedule ID 99999 | StudentResultRequest validation error |
| TC-N-62 | create() with non-existent class_section_id FK | ClassSection ID 99999 | StudentResultRequest validation error |
| TC-N-63 | destroy() hardcoded message inconsistency | Delete result | Flash "Student result deleted." — NOT using flash() helper |
| TC-N-64 | printStudentMarksheet() is empty | Call to undefined route | 404 or no-op |
| TC-N-65 | index() redirect loop | Direct access to /student-result | Redirect to combined results tab |
| TC-N-66 | Withhold on already withheld result | Withhold again | DomainException: invalid state transition |
| TC-N-67 | Declare on already published result | Declare again | DomainException: invalid state transition |
| TC-N-68 | Withhold reason with SQL injection | `'; DROP TABLE students;--` | Escaped by query builder |
| TC-N-69 | edit() select with deleted_at schedules | Soft-deleted schedule in list | whereNull('deleted_at') filters out |
| TC-N-70 | results() with invalid tab param | ?tab=invalid | Falls back to 'student-results' default |

#### TC-SQ: Additional Security Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-SQ-06 | Withhold reason XSS | `<script>alert('xss')</script>` in withheld_reason | Blade auto-escapes output |
| TC-SQ-07 | Withhold overflow | 10,000 char withheld_reason | WithholdStudentResultRequest max validation |
| TC-SQ-08 | Route parameter injection | `/student-result/../../config` | Route-model-binding resolves to valid ID or 404 |
| TC-SQ-09 | Mass assignment on store | Extra fields in POST body | Only $fillable fields accepted via validated() |
| TC-SQ-10 | PDF download path traversal | ?download=../../etc/passwd | download param checked as integer, no traversal |

#### TC-INT: Additional Integration Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-INT-09 | Create → show page displays | Store → redirect to show | All relations loaded: schedule, student, classSection |
| TC-INT-10 | Withhold → status change reflected | Withhold → view show | Badge shows "Withheld", reason visible |
| TC-INT-11 | Declare → timestamp set | Declare → view show | declared_at timestamp visible |
| TC-INT-12 | Export file download | Export → response | Content-Type application/vnd.openxmlformats |
| TC-INT-13 | Print view renders template | Print → template | MARKSHEET_PRINT HTML rendered inside Blade |
| TC-INT-14 | results() class-section filter persists across tabs | Select section → switch tabs | Filter param name changes per tab |
| TC-INT-15 | results() pagination independent per tab | Tab1 page 2 → Tab2 page 1 | Each tab has unique paginator name |
| TC-INT-16 | show() examMarks + iaMarks + attendance loaded | View combined detail | All 3 extra queries executed |
| TC-INT-17 | withhold → declare → export → print → PDF full flow | Complete lifecycle | All 5 workflow actions execute in sequence |
| TC-INT-18 | preparePdfTemplateHtml → DomPDF rendering | Full PDF pipeline | HTML parsed, card sized, images localized |
| TC-INT-19 | Student result with sub-results cascade | subjectResults + coscholasticResults | Both scoped to same schedule_id |
| TC-INT-20 | results() hub + standalone CRUD consistency | Same data from both entry points | Schema and counts match |

### Additional Detailed Test Execution Procedures

#### TC-P-26: Withhold result with valid reason

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-student-result.withhold` permission | Authorized |
| 2 | Navigate to show page for a computed result | Detail page |
| 3 | Click "Withhold" button | Form/modal appears |
| 4 | Enter withheld_reason: "Pending disciplinary committee decision" | At least 5 chars |
| 5 | Submit POST to `/student-result/{id}/withhold` | Request sent |
| 6 | Verify Gate::authorize('tenant.msh-student-result.withhold') at controller line 230 | Passes |
| 7 | Verify WithholdStudentResultRequest validates withheld_reason | Required, string |
| 8 | Verify $this->review->withhold() called with (result, auth()->id(), reason) | Service invoked |
| 9 | Verify StudentResultReviewService::withhold() transitions status to 'withheld' | State changed |
| 10 | Verify activityLog($studentResult, 'Withheld', ...) | Log entry with reason |
| 11 | Verify redirect to show page | 302 |
| 12 | Verify success flash: "Result withheld." | Message shown |
| 13 | Verify show page shows "Withheld" badge | Visual indicator |
| 14 | Verify withheld_reason visible on show page | Reason displayed |

#### TC-P-27: Declare result from computed status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-student-result.declare` permission | Authorized |
| 2 | Navigate to show page for a computed result | Detail page |
| 3 | Click "Declare" button | Confirmation |
| 4 | Submit POST to `/student-result/{id}/declare` | Request sent |
| 5 | Verify Gate::authorize('tenant.msh-student-result.declare') at controller line 256 | Passes |
| 6 | Verify $this->review->declare() called with (result, auth()->id()) | Service invoked |
| 7 | Verify status transitions to 'published' | State changed |
| 8 | Verify declared_at timestamp set | Current timestamp |
| 9 | Verify activityLog($studentResult, 'Declared', ...) | Log entry |
| 10 | Verify redirect to show page | 302 |
| 11 | Verify success flash: "Result declared." | Message shown |

#### TC-P-28: Export to Excel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-student-result.export` permission | Authorized |
| 2 | Navigate to show page | Detail page |
| 3 | Click "Export" button | GET request |
| 4 | Verify Gate::authorize('tenant.msh-student-result.export') at line 172 | Passes |
| 5 | Verify Excel::download called with new StudentResultExport(id) | Exporter instantiated |
| 6 | Verify file download response | Content-Disposition: attachment |
| 7 | Verify filename: `student_result_{id}.xlsx` | Correct filename |
| 8 | Verify Excel file opens correctly | Valid xlsx format |

#### TC-P-29: Print marksheet

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.msh-student-result.print` permission | Authorized |
| 2 | Navigate to show page | Detail page |
| 3 | Click "Print" button | GET /student-result/{id}/print |
| 4 | Verify Gate::authorize at line 182 | Passes |
| 5 | Verify Template::render('MARKSHEET_PRINT', ...) called | subjectId, classId, sessionId, studentId |
| 6 | Verify try/catch for DomainException | Exception caught |
| 7 | Verify print view returned | marksheetgeneration::student-result.print |
| 8 | Verify $html contains rendered template | Pre-rendered HTML visible |
| 9 | Verify print layout applied | Print-friendly CSS |

#### TC-P-31: Show with all relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with view permission | Authorized |
| 2 | Navigate to show page for result with full data | Detail page |
| 3 | Verify load() called with 6 relations (line 71-78) | All loaded |
| 4 | Verify subjectResults filtered by schedule_id (line 82-85) | Scoped collection |
| 5 | Verify coscholasticResults filtered (line 86-89) | Scoped collection |
| 6 | Verify examMarks query executed (line 91-95) | Grouped by subject_id |
| 7 | Verify iaMarks query executed (line 97-101) | Grouped by subject_id |
| 8 | Verify attendance query executed (line 103-105) | Single record or null |
| 9 | Verify view receives compact('studentResult', 'examMarks', 'iaMarks', 'attendance') | 4 variables |

#### TC-N-33: Withhold without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login WITHOUT `tenant.msh-student-result.withhold` | No permission |
| 2 | Navigate to show page | Detail page visible |
| 3 | Attempt POST to `/student-result/{id}/withhold` | Submit |
| 4 | Verify Gate::authorize at line 230 throws | AuthorizationException |
| 5 | Verify 403 Forbidden response | Access denied |
| 6 | Verify no state change | Status unchanged |
| 7 | Verify no activityLog entry | No Withheld log |

#### TC-N-38: Withhold on invalid state

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up result in 'published' state | Published |
| 2 | Login with withhold permission | Authorized |
| 3 | POST withhold with valid reason | Request sent |
| 4 | StudentResultReviewService::withhold() throws DomainException | Invalid transition |
| 5 | Controller catches DomainException at line 238 | Caught |
| 6 | Redirect to show with error message | "Cannot withhold: {details}" |
| 7 | Verify no state change | Still published |

#### TC-INT-17: Complete workflow lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create student result via store() | Result in 'draft' or 'computed' state |
| 2 | Withhold result with reason | Status→withheld, reason stored |
| 3 | Declare result (restore from withheld) | Status→published, declared_at set |
| 4 | Export to Excel | File download |
| 5 | Print marksheet | Printable view |
| 6 | Download PDF | Redirect to print with ?download=1&auto=1 |
| 7 | Verify activityLog entries: Stored, Withheld, Declared | All 3 logged |
| 8 | Verify show page reflects all state changes | Correct badges |

---

*Template: tpt_Vehicle_TcList.md | Entity: StudentResults | Date: 2026-07-22*
