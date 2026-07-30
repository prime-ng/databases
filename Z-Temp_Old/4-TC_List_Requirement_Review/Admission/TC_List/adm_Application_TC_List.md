# adm_Application — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Applications (CRUD + Soft-Delete + Toggle Status + FSM Workflow + Stage Audit)
**DB scope:** TENANT-side (`adm_applications`, `adm_application_stages`, `adm_application_documents`) · **Test style:** Browser Dusk
**Primary table:** `adm_applications` · **Module URL prefix:** `/admission/enquiry-pipeline?tab=applications`
**Test file:** `adm_Application_TestCas.php`
**Tab:** Applications (second tab of the Enquiry Pipeline page)

Controllers:
- `ApplicationController` — Full CRUD + trash + toggle + FSM workflow (submit, shortlist, allot, reject, stages)
- `AdmMenuController::enquiryPipeline()` — loads application + enquiry data for pipeline page

Routes (`adm.` prefix):
- `GET /admission/enquiry-pipeline` — pipeline page (applications tab)
- `GET /admission/applications/create` — create form
- `POST /admission/applications` — store
- `GET /admission/applications/{application}` — show
- `GET /admission/applications/{application}/edit` — edit form
- `PUT /admission/applications/{application}` — update
- `DELETE /admission/applications/{application}` — soft delete
- `POST /admission/applications/{id}/toggle-status` — toggle active (JSON)
- `GET /admission/applications/trash/view` — trashed list
- `GET /admission/applications/{id}/restore` — restore
- `DELETE /admission/applications/{id}/force-delete` — force delete
- `POST /admission/applications/{application}/submit` — Draft → Submitted
- `POST /admission/applications/{application}/shortlist` → Shortlisted
- `POST /admission/applications/{application}/allot` → Allotted
- `POST /admission/applications/{application}/reject` → Rejected
- `GET /admission/applications/{application}/stages` — JSON stage history

Views:
- `pages/enquiry-pipeline.blade.php` — parent page (Applications tab)
- `applications/partials/_list.blade.php` — applications tab table partial
- `applications/partials/_application-form.blade.php` — shared form (5 sections, 458 lines)
- `applications/create.blade.php` — create page
- `applications/edit.blade.php` — edit page
- `applications/show.blade.php` — detail view (8 cards, 379 lines)
- `applications/trash.blade.php` — soft-deleted list

Service:
- `AdmissionPipelineService` — FSM engine enforcing status transitions + Stage audit logging

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_applications`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), enquiry_id (BIGINT UNSIGNED FK NULLABLE), application_no (VARCHAR 30), class_applied_id (INT UNSIGNED FK), quota_type (VARCHAR 30 NULLABLE), is_sibling (BOOLEAN DEFAULT FALSE), sibling_student_id FK NULLABLE, is_staff_ward (BOOLEAN DEFAULT FALSE), student_first_name (VARCHAR 50), student_middle_name (VARCHAR 50 NULLABLE), student_last_name (VARCHAR 50 NULLABLE), student_dob (DATE), student_gender, student_religion, student_caste_category, student_nationality, student_mother_tongue, aadhar_no, aadhar_no_hash (VARCHAR 64 NULLABLE), birth_cert_no, blood_group, known_allergies, prev_school_name, prev_class_passed, prev_marks_percent, prev_tc_no, father_name, father_mobile, father_email, father_occupation, mother_name, mother_mobile, mother_email, guardian_name, guardian_mobile, guardian_relation, address_line1, address_line2, city, state, pincode, application_fee_paid, application_fee_amount, application_fee_date, interview_scheduled_at, interview_venue, interview_notes, interview_score, status, rejection_reason, processed_by FK, is_active (BOOLEAN DEFAULT TRUE), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Table `adm_application_stages`: id (BIGINT PK AI), application_id (BIGINT UNSIGNED FK), from_status (VARCHAR 50), to_status (VARCHAR 50), remarks (TEXT NULLABLE), changed_by (BIGINT UNSIGNED FK), changed_at (DATETIME), is_active (BOOLEAN DEFAULT TRUE), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | Table `adm_application_documents`: id (BIGINT PK AI), application_id FK, checklist_item_id FK, media_id FK, original_filename, verification_status (VARCHAR 30 DEFAULT 'Pending'), verification_remarks TEXT NULLABLE, verified_by FK NULLABLE, verified_at DATETIME NULLABLE, is_physically_received BOOLEAN, physical_received_at DATE NULLABLE, is_active BOOLEAN, created_by, updated_by | DDL |
| BC-DB-04 | Model `Application`: table adm_applications, SoftDeletes, HasFactory, fillable 54 fields, casts (date, decimal, boolean, encrypted), boot saving() hashes aadhar_no via PiiHashHelper | Model |
| BC-DB-05 | Model `ApplicationStage`: table adm_application_stages, fillable 7 fields, belongsTo application + changedBy | Model |
| BC-DB-06 | Model `ApplicationDocument`: table adm_application_documents, fillable 12 fields, belongsTo application + checklistItem + verifiedBy | Model |
| BC-DB-07 | Application relationships: cycle(), enquiry(), classApplied()/schoolClass(), siblingStudent(), processedBy(), createdBy(), updatedBy(), documents(), stages(), entranceCandidates(), meritListEntries(), allotments(), withdrawals() | Model |
| BC-DB-08 | Accessor `getFullNameAttribute()` returns `trim("$first $middle $last")` | Model |

### BC-VAL — Validation (StoreApplicationRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required integer exists:adm_admission_cycles,id | FR |
| BC-VAL-02 | `enquiry_id` nullable integer exists:adm_enquiries,id | FR |
| BC-VAL-03 | `class_applied_id` required integer exists:sch_classes,id | FR |
| BC-VAL-04 | `status` nullable in:Draft,Submitted,Under_Review,Verified,Shortlisted,Rejected,Waitlisted,Allotted,Enrolled,Withdrawn | FR |
| BC-VAL-05 | `quota_type` nullable in:General,Government,Management,RTE,NRI,Staff_Ward,Sibling,EWS | FR |
| BC-VAL-06 | `is_sibling` nullable boolean | FR |
| BC-VAL-07 | `sibling_student_id` nullable integer exists:std_students,id | FR |
| BC-VAL-08 | `is_staff_ward` nullable boolean | FR |
| BC-VAL-09 | `student_first_name` required string max:50 | FR |
| BC-VAL-10 | `student_middle_name` nullable string max:50 | FR |
| BC-VAL-11 | `student_last_name` nullable string max:50 | FR |
| BC-VAL-12 | `student_dob` required date | FR |
| BC-VAL-13 | `student_gender` required in:Male,Female,Transgender,Prefer Not to Say | FR |
| BC-VAL-14 | `student_religion` nullable string max:50 | FR |
| BC-VAL-15 | `student_caste_category` nullable in:General,OBC,SC,ST,EWS,Other | FR |
| BC-VAL-16 | `student_nationality` nullable string max:50 | FR |
| BC-VAL-17 | `student_mother_tongue` nullable string max:50 | FR |
| BC-VAL-18 | `aadhar_no` nullable string max:20 | FR |
| BC-VAL-19 | `birth_cert_no` nullable string max:50 | FR |
| BC-VAL-20 | `blood_group` nullable in:A+,A-,B+,B-,AB+,AB-,O+,O-,Unknown | FR |
| BC-VAL-21 | `known_allergies` nullable string | FR |
| BC-VAL-22 | `prev_school_name` nullable string max:100 | FR |
| BC-VAL-23 | `prev_class_passed` nullable string max:20 | FR |
| BC-VAL-24 | `prev_marks_percent` nullable numeric min:0 max:100 | FR |
| BC-VAL-25 | `prev_tc_no` nullable string max:50 | FR |
| BC-VAL-26 | `father_name` nullable string max:100 | FR |
| BC-VAL-27 | `father_mobile` nullable string max:15 | FR |
| BC-VAL-28 | `father_email` nullable email max:100 | FR |
| BC-VAL-29 | `father_occupation` nullable string max:100 | FR |
| BC-VAL-30 | `mother_name` nullable string max:100 | FR |
| BC-VAL-31 | `mother_mobile` nullable string max:15 | FR |
| BC-VAL-32 | `mother_email` nullable email max:100 | FR |
| BC-VAL-33 | `mother_occupation` nullable string max:100 | FR |
| BC-VAL-34 | `guardian_name` nullable string max:100 | FR |
| BC-VAL-35 | `guardian_mobile` nullable string max:15 | FR |
| BC-VAL-36 | `guardian_relation` nullable string max:50 | FR |
| BC-VAL-37 | `address_line1` nullable string max:150 | FR |
| BC-VAL-38 | `address_line2` nullable string max:150 | FR |
| BC-VAL-39 | `city` nullable string max:50 | FR |
| BC-VAL-40 | `state` nullable string max:50 | FR |
| BC-VAL-41 | `pincode` nullable string max:10 | FR |
| BC-VAL-42 | `application_fee_paid` nullable boolean | FR |
| BC-VAL-43 | `application_fee_amount` nullable numeric min:0 | FR |
| BC-VAL-44 | `application_fee_date` nullable date | FR |
| BC-VAL-45 | `interview_scheduled_at` nullable date | FR |
| BC-VAL-46 | `interview_venue` nullable string max:100 | FR |
| BC-VAL-47 | `interview_notes` nullable string | FR |
| BC-VAL-48 | `interview_score` nullable numeric min:0 | FR |
| BC-VAL-49 | `rejection_reason` nullable string, required_if:status,Rejected | FR |
| BC-VAL-50 | `processed_by` nullable integer exists:sys_users,id | FR |
| BC-VAL-51 | Age validation: checks student_dob against cycle's age_rules_json via withValidator | FR |
| BC-VAL-52 | Aadhar uniqueness: checks aadhar_no_hash not already used in same cycle (hash via PiiHashHelper) | FR |

### BC-VAL-UPD — UpdateApplicationRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-UPD-01 | Same rules as store, EXCEPT admission_cycle_id is NOT included (cycle immutable on update) | FR |
| BC-VAL-UPD-02 | Aadhar uniqueness excludes own ID: `where('id', '!=', $application->id)` | FR |

### BC-AUTH — Authorization (ApplicationPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-application.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-application.create` | Policy |
| BC-AUTH-03 | show/stages gate `tenant.adm-application.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-application.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-application.delete` | Policy |
| BC-AUTH-06 | submit/shortlist/allot/reject gate `tenant.adm-application.status` | Policy |
| BC-AUTH-07 | pdf gate `tenant.adm-application.pdf` | Policy |
| BC-AUTH-08 | print gate `tenant.adm-application.print` | Policy |
| BC-AUTH-09 | export gate `tenant.adm-application.export` | Policy |
| BC-AUTH-10 | import gate `tenant.adm-application.import` | Policy |
| BC-AUTH-11 | remark gate `tenant.adm-application.remark` | Policy |
| BC-AUTH-12 | emailSchedule gate `tenant.adm-application.email-schedule` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Applications tab loaded via AdmMenuController::enquiryPipeline() alongside Enquiries tab | MenuCtrl |
| BC-BIZ-02 | Search: student_first_name, student_last_name, application_no LIKE; status filter | MenuCtrl |
| BC-BIZ-03 | Separate pagination from enquiries: uses `applications_page` query param, 20 per page | MenuCtrl |
| BC-BIZ-04 | List loads schoolClass, cycle, processedBy relations | MenuCtrl |
| BC-BIZ-05 | Store: defaults status='Draft', sets created_by/updated_by, generates application_no via DB transaction with lockForUpdate() | Ctrl |
| BC-BIZ-06 | application_no auto-format: APP-{YEAR}-{00001} (auto-incrementing, locked transaction) | Ctrl |
| BC-BIZ-07 | Boot saving(): if aadhar_no dirty, hashes via PiiHashHelper::hash() into aadhar_no_hash | Model |
| BC-BIZ-08 | Show loads 9 relations: cycle, schoolClass, processedBy, createdBy, updatedBy, enquiry, documents.checklistItem, stages.changedBy, meritListEntries.meritList, allotments | Ctrl |
| BC-BIZ-09 | Toggle: validates is_active boolean, updates, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-10 | Delete is soft, redirects back with success | Ctrl |
| BC-BIZ-11 | Trashed list ordered by deleted_at desc, eager loads schoolClass + cycle | Ctrl |

### BC-BIZ-FSM — Status Transition Workflow
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-FSM-01 | Transition map: Draft→Submitted, Submitted→Under_Review/Rejected, Under_Review→Shortlisted/Waitlisted/Rejected, Shortlisted→Allotted/Rejected/Waitlisted, Waitlisted→Shortlisted/Rejected, Allotted→Enrolled/Withdrawn, Rejected→(none), Enrolled→Withdrawn, Withdrawn→(none) | Service |
| BC-BIZ-FSM-02 | submit(): validates cycle is Active, fee paid if required, transitions Draft→Submitted | Service |
| BC-BIZ-FSM-03 | shortlist(): transitions Under_Review→Shortlisted; also Waitlisted→Shortlisted | Service |
| BC-BIZ-FSM-04 | allot(): transitions Shortlisted→Allotted | Service |
| BC-BIZ-FSM-05 | reject(): transitions any status→Rejected (rejection_reason required) | Service |
| BC-BIZ-FSM-06 | waitlist(): transitions Under_Review→Waitlisted; Shortlisted→Waitlisted | Service |
| BC-BIZ-FSM-07 | Each transition creates immutable ApplicationStage record (from_status, to_status, remarks, changed_by, changed_at) | Service |
| BC-BIZ-FSM-08 | Stages returned as JSON via stages(): loads changedBy relation | Ctrl |
| BC-BIZ-FSM-09 | Invalid transition throws DomainException, caught by controller → redirect back with error | Service |
| BC-BIZ-FSM-10 | Transition performed in DB transaction; status + stage updated atomically | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Aadhar uniqueness within cycle: same aadhar in same cycle → validation error | StoreRequest |
| BC-EDG-02 | Aadhar check (update): same aadhar, same cycle, different app → error; same app → allowed | UpdateRequest |
| BC-EDG-03 | Age validation when cycle has no age_rules_json → skipped | StoreRequest |
| BC-EDG-04 | aadhar_no saved encrypted via SafeEncrypted cast | Model |
| BC-EDG-05 | reject() without rejection_reason → validation error (required_if) | StoreRequest |
| BC-EDG-06 | Restore/forceDelete uses `withTrashed()->findOrFail($id)` (route key is `{id}` not `{application}`) | Ctrl |

---

## 2. Test Case List

### Screen 1: Pipeline Applications Tab (GET /admission/enquiry-pipeline?tab=applications)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P10 | Positive | View | Applications tab renders with table (Student Name + App No, Class, Status badge, Active toggle, Counselor, Applied Date, Actions) | Rendered | test_adm_appl_10 | Automated |
| TC-ADMAPPL-P11 | Positive | View | Search by student_first_name, student_last_name, application_no | Filtered | test_adm_appl_11 | Automated |
| TC-ADMAPPL-P12 | Positive | View | Status dropdown filter with 10 status options | Filtered | test_adm_appl_12 | Automated |
| TC-ADMAPPL-P13 | Positive | View | Status badges color-coded (Draft=secondary, Submitted=primary, Verified=info, Shortlisted=warning, Enrolled=success, Rejected=danger, Withdrawn=dark) | Colors | test_adm_appl_13 | Automated |
| TC-ADMAPPL-P14 | Positive | View | Active toggle works via status-switch component | Toggled | test_adm_appl_14 | Automated |
| TC-ADMAPPL-P15 | Positive | View | Empty state when no applications | Empty | test_adm_appl_15 | Automated |
| TC-ADMAPPL-P16 | Positive | Ctrl | Applications paginated separately (applications_page query param) | Separate page | test_adm_appl_16 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P20 | Positive | View | Create form renders 5 sections: Student Personal, Parent & Guardian, Address, Application Settings & Previous Schooling, Fee & Interview | Sections | test_adm_appl_20 | Automated |
| TC-ADMAPPL-P21 | Positive | View | Dropdowns load cycles, classes, quotas (8 types), active staff, students | Dropdowns | test_adm_appl_21 | Automated |
| TC-ADMAPPL-P22 | Positive | Ctrl | Valid create: status=Draft, auto-generates APP-{YEAR}-{SEQ}, aadhar hashed | Created | test_adm_appl_22 | Automated |
| TC-ADMAPPL-P23 | Positive | Ctrl | application_no format: APP-{YEAR}-{00001} via locked transaction | Correct | test_adm_appl_23 | Automated |
| TC-ADMAPPL-P24 | Positive | Ctrl | aadhar_no encrypted at rest (SafeEncrypted cast) | Encrypted | test_adm_appl_24 | Automated |
| TC-ADMAPPL-N25 | Negative | Val | Missing student_first_name/student_dob/student_gender/class_applied_id/cycle_id → required errors | Errors | test_adm_appl_25 | Automated |
| TC-ADMAPPL-N26 | Negative | Val | Invalid gender/enum fields → in: rule rejects | Errors | test_adm_appl_26 | Automated |
| TC-ADMAPPL-N27 | Negative | Val | Duplicate aadhar in same cycle → validation error | Aadhar error | test_adm_appl_27 | Automated |
| TC-ADMAPPL-N28 | Negative | Val | Age outside cycle rules → validation error | Age error | test_adm_appl_28 | Automated |
| TC-ADMAPPL-N29 | Negative | Val | prev_marks_percent > 100 → max rule | Error | test_adm_appl_29 | Automated |

### Screen 3: Show (GET /admission/applications/{application})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P40 | Positive | View | Show page renders 8 cards: Student, Parent & Guardian, Address, Settings, Previous Schooling, Interview, System Info, Stage History | 8 cards | test_adm_appl_40 | Automated |
| TC-ADMAPPL-P41 | Positive | View | Full name displayed (first + middle + last) | Full name | test_adm_appl_41 | Automated |
| TC-ADMAPPL-P42 | Positive | View | Stage History card shows audit trail with changed_by user | Audit | test_adm_appl_42 | Automated |
| TC-ADMAPPL-P43 | Positive | View | Edit and Back buttons visible (permission-gated) | Buttons | test_adm_appl_43 | Automated |
| TC-ADMAPPL-P44 | Positive | View | Status badge at top, all fields populated | Fields | test_adm_appl_44 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P60 | Positive | View | Edit pre-populates form with all application data | Pre-filled | test_adm_appl_60 | Automated |
| TC-ADMAPPL-P61 | Positive | Ctrl | Update changes fields, aadhar re-hashed if changed | Updated | test_adm_appl_61 | Automated |
| TC-ADMAPPL-N62 | Negative | Val | Duplicate aadhar (other app, same cycle) → validation error | Error | test_adm_appl_62 | Automated |
| TC-ADMAPPL-P63 | Positive | Val | Same aadhar, same app, same cycle → allowed (self-exclusion) | Allowed | test_adm_appl_63 | Automated |

### Screen 5: FSM Workflow

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P80 | Positive | Biz | Submit Draft → Submitted: creates stage, transitions status | Submitted | test_adm_appl_80 | Automated |
| TC-ADMAPPL-P81 | Positive | Biz | Shortlist Under_Review → Shortlisted: stage created | Shortlisted | test_adm_appl_81 | Automated |
| TC-ADMAPPL-P82 | Positive | Biz | Allot Shortlisted → Allotted: stage created | Allotted | test_adm_appl_82 | Automated |
| TC-ADMAPPL-P83 | Positive | Biz | Reject any status → Rejected: requires rejection_reason | Rejected | test_adm_appl_83 | Automated |
| TC-ADMAPPL-P84 | Positive | Biz | Full pipeline: Draft → Submitted → Under_Review → Shortlisted → Allotted → Enrolled | Pipeline | test_adm_appl_84 | Automated |
| TC-ADMAPPL-N85 | Negative | Biz | Draft directly to Shortlisted (skip Submitted) → DomainException | Error | test_adm_appl_85 | Automated |
| TC-ADMAPPL-N86 | Negative | Biz | Rejected → any other status → DomainException | Error | test_adm_appl_86 | Automated |
| TC-ADMAPPL-P87 | Positive | Ctrl | Stages endpoint returns JSON with changedBy data | JSON | test_adm_appl_87 | Automated |

### Screen 6: Soft Delete Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P100 | Positive | Ctrl | Soft-delete application, appears in trash | Trashed | test_adm_appl_100 | Automated |
| TC-ADMAPPL-P101 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_appl_101 | Automated |
| TC-ADMAPPL-P102 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_appl_102 | Automated |
| TC-ADMAPPL-P110 | Positive | Ctrl | Toggle is_active on/off returns JSON | JSON | test_adm_appl_110 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAPPL-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_appl_200 | Automated |
| TC-ADMAPPL-P201 | Positive | Auth | FSM workflow with status permission → success | 200 | test_adm_appl_201 | Automated |
| TC-ADMAPPL-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_appl_202 | Automated |
| TC-ADMAPPL-N203 | Negative | Auth | Without create → 403 on store | 403 | test_adm_appl_203 | Automated |
| TC-ADMAPPL-N204 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_adm_appl_204 | Automated |
| TC-ADMAPPL-N205 | Negative | Auth | Without delete → 403 on destroy | 403 | test_adm_appl_205 | Automated |
| TC-ADMAPPL-N206 | Negative | Auth | Without status permission → 403 on submit/shortlist/allot/reject | 403 | test_adm_appl_206 | Automated |
