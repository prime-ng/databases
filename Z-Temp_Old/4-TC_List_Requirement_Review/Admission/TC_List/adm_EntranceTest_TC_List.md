# adm_EntranceTest — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Entrance Tests (CRUD + Soft-Delete + Toggle + Candidates Import + Inline Marks)
**DB scope:** TENANT-side (`adm_entrance_tests`, `adm_entrance_test_candidates`) · **Test style:** Browser Dusk
**Primary table:** `adm_entrance_tests` · **Module URL prefix:** `/admission/assessment?tab=entrance-tests`
**Test file:** `adm_EntranceTest_TestCas.php`
**Tab:** Entrance Tests (first tab of the Assessment page)

Controllers:
- `EntranceTestController` — Full CRUD + trash + toggle + importCandidates + updateMarks
- `AdmMenuController::assessment()` — loads entrance tests + merit lists data for pipeline page

Routes (`adm.` prefix):
- `GET /admission/assessment` — assessment page (entrance-tests tab default)
- `GET /admission/entrance-tests/create` — create form
- `POST /admission/entrance-tests` — store
- `GET /admission/entrance-tests/{test}` — show
- `GET /admission/entrance-tests/{test}/edit` — edit form
- `PUT /admission/entrance-tests/{test}` — update
- `DELETE /admission/entrance-tests/{test}` — soft delete
- `POST /admission/entrance-tests/{id}/toggle-status` — toggle active (JSON)
- `GET /admission/entrance-tests/trash/view` — trashed list
- `GET /admission/entrance-tests/{id}/restore` — restore
- `DELETE /admission/entrance-tests/{id}/force-delete` — force delete
- `POST /admission/entrance-tests/{test}/candidates/import` — import shortlisted apps as candidates
- `PUT /admission/entrance-tests/{test}/candidates/{candidate}/marks` — AJAX update marks + auto-result

Views:
- `pages/assessment.blade.php` — parent page (Entrance Tests tab)
- `entrance-tests/partials/_list.blade.php` — entrance tests table partial
- `entrance-tests/create.blade.php` — create page
- `entrance-tests/edit.blade.php` — edit page
- `entrance-tests/show.blade.php` — detail view with candidate marks table
- `entrance-tests/trash.blade.php` — soft-deleted list

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_entrance_tests`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), class_id (INT UNSIGNED FK), test_name (VARCHAR 100), test_date (DATE), start_time (TIME), end_time (TIME), venue (VARCHAR 100 NULLABLE), max_marks (DECIMAL 6,2), passing_marks (DECIMAL 6,2 NULLABLE), subjects_json (JSON NULLABLE), status (ENUM:Scheduled,Completed,Cancelled), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_et_cycle_class (admission_cycle_id, class_id), idx_adm_et_date (test_date), idx_adm_et_status (status) | DDL |
| BC-DB-02 | Table `adm_entrance_test_candidates`: id (BIGINT PK AI), entrance_test_id (BIGINT UNSIGNED FK), application_id (BIGINT UNSIGNED FK), roll_no (VARCHAR 20 NULLABLE), marks_obtained (DECIMAL 6,2 NULLABLE), result (ENUM:Absent,Fail,Pass,Pending), subject_marks_json (JSON NULLABLE), is_active (BOOLEAN DEFAULT true), created_by, updated_by. UNIQUE: uq_adm_etc_test_app (entrance_test_id, application_id). Indexes: idx_adm_etc_test, idx_adm_etc_app, idx_adm_etc_result | DDL |
| BC-DB-03 | Model `EntranceTest`: table adm_entrance_tests, SoftDeletes, HasFactory, fillable 15 fields, casts: test_date→date, subjects_json→array, is_active→boolean | Model |
| BC-DB-04 | Model `EntranceTestCandidate`: table adm_entrance_test_candidates, SoftDeletes, HasFactory, fillable 9 fields, casts: marks_obtained→decimal:2, subject_marks_json→array, is_active→boolean | Model |
| BC-DB-05 | EntranceTest relationships: cycle() belongsTo AdmissionCycle, schoolClass() belongsTo SchoolClass, candidates() hasMany EntranceTestCandidate | Model |
| BC-DB-06 | EntranceTestCandidate relationships: test() belongsTo EntranceTest, application() belongsTo Application | Model |

### BC-VAL — Validation (StoreEntranceTestRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required integer exists:adm_admission_cycles,id | FR |
| BC-VAL-02 | `class_id` required integer exists:sch_classes,id | FR |
| BC-VAL-03 | `test_name` required string max:100 | FR |
| BC-VAL-04 | `test_date` required date | FR |
| BC-VAL-05 | `start_time` required date_format:H:i, before:end_time | FR |
| BC-VAL-06 | `end_time` required date_format:H:i, after:start_time | FR |
| BC-VAL-07 | `venue` nullable string max:100 | FR |
| BC-VAL-08 | `max_marks` required numeric min:1 | FR |
| BC-VAL-09 | `passing_marks` nullable numeric min:0, lte:max_marks | FR |
| BC-VAL-10 | `subjects` nullable string | FR |
| BC-VAL-11 | `status` nullable in:Scheduled,Completed,Cancelled | FR |
| BC-VAL-12 | `is_active` nullable boolean | FR |

### BC-VAL-UPD — UpdateEntranceTestRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-UPD-01 | Same rules as Store (authorizes tenant.adm-entrance-test.update) | FR |

### BC-AUTH — Authorization (EntranceTestPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-entrance-test.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-entrance-test.create` | Policy |
| BC-AUTH-03 | show gate `tenant.adm-entrance-test.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-entrance-test.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-entrance-test.delete` | Policy |
| BC-AUTH-06 | importCandidates/updateMarks gate `tenant.adm-entrance-test.status` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Assessment page loads 2 tabs: Entrance Tests + Merit Lists via AdmMenuController::assessment() | MenuCtrl |
| BC-BIZ-02 | Entrance Tests list: searches by test_name LIKE, paginated 20 per page, ordered by test_date DESC | MenuCtrl |
| BC-BIZ-03 | List loads cycle and schoolClass relations | MenuCtrl |
| BC-BIZ-04 | List shows status badges: Scheduled=primary, Completed=success, Cancelled=danger | View |
| BC-BIZ-05 | Store: defaults status='Scheduled', is_active=true, subjects stored as subjects_json (comma→array) | Ctrl |
| BC-BIZ-06 | Show loads candidates with application relation (student_first_name, last_name, application_no) | Ctrl |
| BC-BIZ-07 | ImportCandidates: fetches shortlisted applications (Application::whereIn status: Shortlisted, Waitlisted) for same cycle, creates EntranceTestCandidate records with result=Pending, roll_no auto-assigned. Avoids duplicates (unique constraint entrance_test_id + application_id) | Ctrl |
| BC-BIZ-08 | UpdateMarks: saves marks_obtained (decimal), auto-calculates result: marks >= passing_marks → Pass, else → Fail. Also updates subject_marks_json if provided. Returns JSON | Ctrl |
| BC-BIZ-09 | Toggle: validates is_active boolean, updates, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-10 | Delete is soft, redirects back with success | Ctrl |
| BC-BIZ-11 | Trashed list ordered by deleted_at desc | Ctrl |
| BC-BIZ-12 | Show page "Mark as Completed" button: changes status to Completed when current status is Scheduled | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | start_time equals end_time → validation error (before/after rules) | FR |
| BC-EDG-02 | passing_marks > max_marks → validation error (lte rule) | FR |
| BC-EDG-03 | Import candidate already registered (existing entrance_test_id + application_id) → silently skipped (DB unique) | Ctrl |
| BC-EDG-04 | UpdateMarks with marks_obtained > max_marks → validation error | Ctrl |
| BC-EDG-05 | Passing marks nullable: if null, no Pass/Fail auto-calculation, result remains Pending | Model |
| BC-EDG-06 | Roll number auto-assignment on import: sequential within test | Ctrl |

---

## 2. Test Case List

### Screen 1: Assessment — Entrance Tests Tab (GET /admission/assessment?tab=entrance-tests)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P10 | Positive | View | Assessment page renders 2 tabs: Entrance Tests + Merit Lists | Tabs visible | test_adm_et_10 | Automated |
| TC-ADMET-P11 | Positive | View | Entrance Tests tab: table (Test Name, Cycle & Class, Date & Time, Venue, Status badge, Active toggle, Marks, Action) | Rendered | test_adm_et_11 | Automated |
| TC-ADMET-P12 | Positive | View | Search by test_name | Filtered | test_adm_et_12 | Automated |
| TC-ADMET-P13 | Positive | View | Status badges: Scheduled=primary, Completed=success, Cancelled=danger | Colors | test_adm_et_13 | Automated |
| TC-ADMET-P14 | Positive | View | Active toggle via status-switch component | Toggled | test_adm_et_14 | Automated |
| TC-ADMET-P15 | Positive | View | Empty state "Schedule First Test" button | Empty | test_adm_et_15 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P30 | Positive | View | Create form: Test Name, Date, Start/End Time, Venue, Max Marks, Passing Marks, Subjects (comma-separated), Admission Cycle, Class, Status, Active | All fields | test_adm_et_30 | Automated |
| TC-ADMET-P31 | Positive | View | Dropdowns load active cycles, active classes | Loaded | test_adm_et_31 | Automated |
| TC-ADMET-P32 | Positive | Ctrl | Valid create: status=Scheduled, is_active=true, subjects stored as JSON array | Created | test_adm_et_32 | Automated |
| TC-ADMET-N33 | Negative | Val | Missing test_name/test_date/max_marks/cycle_id/class_id → required errors | Errors | test_adm_et_33 | Automated |
| TC-ADMET-N34 | Negative | Val | start_time after end_time → before rule fails | Error | test_adm_et_34 | Automated |
| TC-ADMET-N35 | Negative | Val | passing_marks > max_marks → lte rule fails | Error | test_adm_et_35 | Automated |
| TC-ADMET-N36 | Negative | Val | Invalid cycle_id/class_id → exists rejects | Error | test_adm_et_36 | Automated |

### Screen 3: Show (GET /admission/entrance-tests/{test})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P50 | Positive | View | Show: Test Information card (name, class, cycle, date/time, venue, max/passing marks, subjects list) | Card | test_adm_et_50 | Automated |
| TC-ADMET-P51 | Positive | View | Status badge, Active/Inactive indicator | Badge | test_adm_et_51 | Automated |
| TC-ADMET-P52 | Positive | View | Registered Candidates table: Roll No, Application No, Student Name, Marks Obtained, Result, Update Marks action | Table | test_adm_et_52 | Automated |
| TC-ADMET-P53 | Positive | View | "Import Shortlisted" button visible | Button | test_adm_et_53 | Automated |
| TC-ADMET-P54 | Positive | View | "Mark as Completed" button (visible when status=Scheduled) | Button | test_adm_et_54 | Automated |
| TC-ADMET-P55 | Positive | View | No candidates → empty state | Empty | test_adm_et_55 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P70 | Positive | View | Edit pre-populates form with all test values | Pre-filled | test_adm_et_70 | Automated |
| TC-ADMET-P71 | Positive | Ctrl | Update changes fields, logs activity | Updated | test_adm_et_71 | Automated |

### Screen 5: Candidates — Import + Marks

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P90 | Positive | Biz | Import shortlisted apps creates candidates with result=Pending, auto roll_no | Imported | test_adm_et_90 | Automated |
| TC-ADMET-P91 | Positive | Biz | Import skips already-registered apps (unique constraint) | Skipped | test_adm_et_91 | Automated |
| TC-ADMET-P92 | Positive | Ctrl | Update marks via AJAX: saves marks_obtained, auto-calculates Pass/Fail, returns JSON | Updated | test_adm_et_92 | Automated |
| TC-ADMET-P93 | Positive | Biz | Marks >= passing_marks → result=Pass | Pass | test_adm_et_93 | Automated |
| TC-ADMET-P94 | Positive | Biz | Marks < passing_marks → result=Fail | Fail | test_adm_et_94 | Automated |
| TC-ADMET-P95 | Positive | Biz | Passing marks null → result remains Pending | Pending | test_adm_et_95 | Automated |
| TC-ADMET-N96 | Negative | Ctrl | Update marks with marks_obtained > max_marks → validation error | Error | test_adm_et_96 | Automated |

### Screen 6: Soft Delete Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P110 | Positive | Ctrl | Soft-delete test, appears in trash | Trashed | test_adm_et_110 | Automated |
| TC-ADMET-P111 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_et_111 | Automated |
| TC-ADMET-P112 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_et_112 | Automated |
| TC-ADMET-P120 | Positive | Ctrl | Toggle is_active on/off returns JSON | JSON | test_adm_et_120 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMET-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_et_200 | Automated |
| TC-ADMET-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_et_201 | Automated |
| TC-ADMET-N202 | Negative | Auth | Without create → 403 on store | 403 | test_adm_et_202 | Automated |
| TC-ADMET-N203 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_adm_et_203 | Automated |
| TC-ADMET-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_adm_et_204 | Automated |
| TC-ADMET-N205 | Negative | Auth | Without status permission → 403 on import/marks | 403 | test_adm_et_205 | Automated |
