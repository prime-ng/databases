# adm_Enquiry — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Enquiries (CRUD + Soft-Delete + Toggle Status + Follow-ups)
**DB scope:** TENANT-side (`adm_enquiries`) · **Test style:** Browser Dusk
**Primary table:** `adm_enquiries` · **Module URL prefix:** `/admission/enquiry-pipeline?tab=enquiries`
**Test file:** `adm_Enquiry_TestCas.php`
**Tab:** Enquiries (first tab of the Enquiry Pipeline page)

Controllers:
- `EnquiryController` — CRUD + trash + toggle + age validation
- `FollowUpController` — AJAX CRUD for follow-ups per enquiry
- `AdmMenuController::enquiryPipeline()` — loads enquiry & application data for the pipeline page

Routes (`adm.` prefix):
- `GET /admission/enquiry-pipeline` — pipeline page (enquiries + applications tabs)
- `GET /admission/enquiries/create` — create form
- `POST /admission/enquiries` — store
- `GET /admission/enquiries/{enquiry}` — show
- `GET /admission/enquiries/{enquiry}/edit` — edit form
- `PUT /admission/enquiries/{enquiry}` — update
- `DELETE /admission/enquiries/{enquiry}` — destroy (blocked if linked to applications)
- `POST /admission/enquiries/{id}/toggle-status` — toggle status (AJAX)
- `GET /admission/enquiries/trash/view` — trashed list
- `GET /admission/enquiries/{id}/restore` — restore
- `DELETE /admission/enquiries/{id}/force-delete` — force delete
- `GET /admission/enquiries/{enquiry}/follow-ups` — list follow-ups (JSON)
- `POST /admission/enquiries/{enquiry}/follow-ups` — store follow-up (JSON)
- `PUT /admission/enquiries/{enquiry}/follow-ups/{followUp}` — update follow-up (JSON)
- `DELETE /admission/enquiries/{enquiry}/follow-ups/{followUp}` — delete follow-up (JSON)

Views:
- `pages/enquiry-pipeline.blade.php` — pipeline page (Enquiries + Applications tabs)
- `enquiries/partials/_list.blade.php` — enquiries tab table partial
- `enquiries/partials/_enquiry-form.blade.php` — shared form partial
- `enquiries/create.blade.php` — create page
- `enquiries/edit.blade.php` — edit page
- `enquiries/show.blade.php` — detail view with follow-ups
- `enquiries/trash.blade.php` — soft-deleted enquiries

---

## 1. Business Conditions

### BC-DB — Schema (adm_enquiries)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_enquiries`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), enquiry_no (VARCHAR 30), student_name (VARCHAR 100), student_dob (DATE NULLABLE), student_gender (VARCHAR 20 NULLABLE), class_sought_id (INT UNSIGNED FK), father_name (VARCHAR 100 NULLABLE), mother_name (VARCHAR 100 NULLABLE), contact_name (VARCHAR 100), contact_mobile (VARCHAR 15), contact_email (VARCHAR 100 NULLABLE), lead_source (VARCHAR 50 NULLABLE), status (VARCHAR 30 DEFAULT 'New'), counselor_id (BIGINT UNSIGNED FK NULLABLE), is_sibling_lead (BOOLEAN DEFAULT false), sibling_student_id (BIGINT UNSIGNED FK NULLABLE), is_duplicate (BOOLEAN DEFAULT false), notes (TEXT NULLABLE), source_reference (VARCHAR 100 NULLABLE), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Table `adm_follow_ups`: id (BIGINT PK AI), enquiry_id (BIGINT UNSIGNED FK), done_by (BIGINT UNSIGNED FK), follow_up_type (VARCHAR 50), scheduled_at (DATETIME), completed_at (DATETIME NULLABLE), notes (TEXT NULLABLE), outcome (VARCHAR 50 NULLABLE), reminder_sent (BOOLEAN DEFAULT false), is_active (BOOLEAN DEFAULT true), created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | Model `Enquiry`: table `adm_enquiries`, SoftDeletes, fillable: 21 columns, casts: student_dob→date, is_sibling_lead/is_duplicate/is_active→boolean | Model |
| BC-DB-04 | Model `FollowUp`: table `adm_follow_ups`, SoftDeletes, fillable: 11 columns, casts: scheduled_at/completed_at→datetime, reminder_sent/is_active→boolean | Model |
| BC-DB-05 | Enquiry relationships: cycle() belongsTo AdmissionCycle, classSought()/schoolClass() belongsTo SchoolClass, counselor() belongsTo User, siblingStudent() belongsTo Student, followUps() hasMany FollowUp, applications() hasMany Application | Model |
| BC-DB-06 | FollowUp relationships: enquiry() belongsTo Enquiry, doneBy() belongsTo User | Model |
| BC-DB-07 | Auto-generates enquiry_no on create: ENQ-{YEAR}-{SEQ:5 digits} via boot() creating event | Model |

### BC-VAL — Validation (StoreEnquiryRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required integer exists:adm_admission_cycles,id | FR |
| BC-VAL-02 | `student_name` required string max:100 | FR |
| BC-VAL-03 | `student_dob` nullable date | FR |
| BC-VAL-04 | `student_gender` nullable in:Male,Female,Transgender,Other | FR |
| BC-VAL-05 | `class_sought_id` required integer exists:sch_classes,id | FR |
| BC-VAL-06 | `father_name` nullable string max:100 | FR |
| BC-VAL-07 | `mother_name` nullable string max:100 | FR |
| BC-VAL-08 | `contact_name` required string max:100 | FR |
| BC-VAL-09 | `contact_mobile` required string max:15 | FR |
| BC-VAL-10 | `contact_email` nullable email max:100 | FR |
| BC-VAL-11 | `lead_source` nullable in:Website,Walk-in,Campaign,Referral,Social_Media,Phone,Other | FR |
| BC-VAL-12 | `counselor_id` nullable integer exists:sys_users,id | FR |
| BC-VAL-13 | `is_sibling_lead` nullable boolean | FR |
| BC-VAL-14 | `sibling_student_id` nullable integer exists:std_students,id | FR |
| BC-VAL-15 | `notes` nullable string | FR |
| BC-VAL-16 | `source_reference` nullable string max:100 | FR |
| BC-VAL-17 | Age validation: checks student_dob against cycle's age_rules_json (min_age/max_age) via withValidator | FR |

### BC-VAL-UPD — Validation (UpdateEnquiryRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-UPD-01 | `status` nullable in:New,Assigned,Contacted,Interested,Not_Interested,Callback,Converted,Duplicate | FR |
| BC-VAL-UPD-02 | Same rules as store for other fields (excluding admission_cycle_id) | FR |

### BC-VAL-FU — Validation (StoreFollowUpRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-FU-01 | `follow_up_type` required in:Call,Meeting,Email,SMS,Walk-in | FR |
| BC-VAL-FU-02 | `scheduled_at` required date_format:Y-m-d H:i:s | FR |
| BC-VAL-FU-03 | `notes` nullable string | FR |
| BC-VAL-FU-04 | `outcome` nullable in:Pending,Interested,Not_Interested,Callback,Converted | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-enquiry.viewAny` | Ctrl |
| BC-AUTH-02 | create/store gate `tenant.adm-enquiry.create` | Ctrl |
| BC-AUTH-03 | show gate `tenant.adm-enquiry.view` | Ctrl |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-enquiry.update` | Ctrl |
| BC-AUTH-05 | destroy gate `tenant.adm-enquiry.delete` | Ctrl |
| BC-AUTH-06 | restore gate `tenant.adm-enquiry.restore` | Ctrl |
| BC-AUTH-07 | forceDelete gate `tenant.adm-enquiry.forceDelete` | Ctrl |
| BC-AUTH-08 | Follow-up index/CRUD gates `tenant.adm-follow-up.*` | FollowUpCtrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Pipeline page loads 2 tabs: Enquiries + Applications, via AdmMenuController::enquiryPipeline() | MenuCtrl |
| BC-BIZ-02 | Enquiry list: searches by student_name, contact_mobile, enquiry_no LIKE; filters by is_active or status | Ctrl |
| BC-BIZ-03 | Enquiry list: paginated 20 per page, ordered by id DESC | Ctrl |
| BC-BIZ-04 | Enquiry list: loads schoolClass, counselor, cycle relations; shows follow_ups_count | Ctrl |
| BC-BIZ-05 | Auto-generate enquiry_no: ENQ-{YEAR}-{SEQ:5 digits} on creating (boot method) | Model |
| BC-BIZ-06 | Store: defaults status='New', is_active=true, created_by/updated_by=auth, handles is_sibling_lead checkbox | Ctrl |
| BC-BIZ-07 | Store: accepts JSON request → returns JSON response | Ctrl |
| BC-BIZ-08 | Update: handles is_sibling_lead checkbox, sets sibling_student_id=null if unchecked | Ctrl |
| BC-BIZ-09 | Toggle: required is_active boolean, updates is_active, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-10 | Destroy: aborts 403 if enquiry has linked applications (applications()->exists()) | Ctrl |
| BC-BIZ-11 | Show: loads schoolClass, counselor, followUps (with doneBy), applications relations | Ctrl |
| BC-BIZ-12 | Follow-up: nested under enquiry; destroy aborts 404 if follow_up.enquiry_id !== enquiry.id | FollowUpCtrl |
| BC-BIZ-13 | Follow-up: updates completed_at to now() when outcome is provided | FollowUpCtrl |
| BC-BIZ-14 | Age validation: checks DOB against cycle's age_rules_json (min_age, max_age) using withValidator | StoreRequest |
| BC-BIZ-15 | Status badges color-coded in view (New=blue, Contacted=info, Visited=warning, Applied=success, Dropped=secondary) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete enquiry with linked applications → 403 abort | Ctrl |
| BC-EDG-02 | Age validation with no cycle age_rules → skipped (returns early) | StoreRequest |
| BC-EDG-03 | Auto-seq: first enquiry of year gets ENQ-{YEAR}-00001; next gets +1 | Model |
| BC-EDG-04 | Follow-up update with mismatched enquiry_id → 404 abort | FollowUpCtrl |
| BC-EDG-05 | is_sibling_lead unchecked → sibling_student_id forced to null | Ctrl |

---

## 2. Test Case List

### Screen 1: Enquiry Pipeline Tab (GET /admission/enquiry-pipeline?tab=enquiries)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P10 | Positive | View | Pipeline renders 2 tabs: Enquiries + Applications | Tabs visible | test_adm_enq_10 | Automated |
| TC-ADMENQ-P11 | Positive | View | Enquiries tab: search, status filter, table (Name, Class, Status, Active, Source, Follow-ups, Actions) | Page rendered | test_adm_enq_11 | Automated |
| TC-ADMENQ-P12 | Positive | Ctrl | Search by student_name, contact_mobile, enquiry_no | Filtered | test_adm_enq_12 | Automated |
| TC-ADMENQ-P13 | Positive | Ctrl | Filter by is_active=1/0 or by status string | Filtered | test_adm_enq_13 | Automated |
| TC-ADMENQ-P14 | Positive | Ctrl | Paginated 20 per page | Paginated | test_adm_enq_14 | Automated |
| TC-ADMENQ-P15 | Positive | View | Status badges color-coded, action buttons (View/Edit/Delete), status toggle | Elements | test_adm_enq_15 | Automated |
| TC-ADMENQ-P16 | Positive | View | Empty state "No Enquiries Yet" | Empty state | test_adm_enq_16 | Automated |

### Screen 2: Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P30 | Positive | View | Create form: cycle, student_name, dob, gender, class, father/mother name, contact_name, mobile, email, lead_source, counselor, sibling_lead, sibling_student, notes, source_reference | All fields | test_adm_enq_30 | Automated |
| TC-ADMENQ-P31 | Positive | View | Create loads active cycles, active classes, active counselors, active students | Dropdowns loaded | test_adm_enq_31 | Automated |
| TC-ADMENQ-P32 | Positive | Ctrl | Valid create: status=New, is_active=true, auto-generates enquiry_no, logs 'Stored' | Created | test_adm_enq_32 | Automated |
| TC-ADMENQ-P33 | Positive | Ctrl | enquiry_no format: ENQ-{YEAR}-{SEQ:5 digits} | Correct format | test_adm_enq_33 | Automated |
| TC-ADMENQ-P34 | Positive | Ctrl | JSON request → JSON response {status:true, data} | JSON | test_adm_enq_34 | Automated |
| TC-ADMENQ-P35 | Positive | Ctrl | is_sibling_lead checked sets sibling, unchecked clears it | Sibling handling | test_adm_enq_35 | Automated |
| TC-ADMENQ-N36 | Negative | Val | Missing student_name/contact_name/contact_mobile/class_sought_id/cycle_id → required errors | Errors | test_adm_enq_36 | Automated |
| TC-ADMENQ-N37 | Negative | Val | Invalid lead_source/counselor_id/class_id/cycle_id → in/exists rejects | Errors | test_adm_enq_37 | Automated |
| TC-ADMENQ-N38 | Negative | Val | Invalid student_gender → in:Male,Female,Transgender,Other rejects | Error | test_adm_enq_38 | Automated |
| TC-ADMENQ-N39 | Negative | Val | Age below cycle min_age → validation error via withValidator | Age error | test_adm_enq_39 | Automated |
| TC-ADMENQ-N40 | Negative | Val | Age above cycle max_age → validation error via withValidator | Age error | test_adm_enq_40 | Automated |

### Screen 3: Show (GET /admission/enquiries/{enquiry})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P60 | Positive | View | Show: student info, contact info, cycle/class/source, sibling status, notes; status badge, duplicate badge | All fields | test_adm_enq_60 | Automated |
| TC-ADMENQ-P61 | Positive | View | Follow-ups panel: list of follow-ups with type/date/notes/outcome, Add button | Follow-ups | test_adm_enq_61 | Automated |
| TC-ADMENQ-P62 | Positive | View | Edit button (permission-gated) | Button | test_adm_enq_62 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P70 | Positive | View | Edit pre-populates form, including status dropdown | Pre-filled | test_adm_enq_70 | Automated |
| TC-ADMENQ-P71 | Positive | Ctrl | Update with status change succeeds | Updated | test_adm_enq_71 | Automated |
| TC-ADMENQ-N72 | Negative | Val | Invalid status → in:New,Assigned,...,Duplicate rejects | Error | test_adm_enq_72 | Automated |

### Screen 5: Follow-ups AJAX CRUD

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P90 | Positive | Ctrl | List follow-ups for enquiry returns JSON array | JSON list | test_adm_enq_90 | Automated |
| TC-ADMENQ-P91 | Positive | Ctrl | Create follow-up with valid data returns JSON {status:true, data} | Created | test_adm_enq_91 | Automated |
| TC-ADMENQ-P92 | Positive | Ctrl | Update follow-up with outcome sets completed_at to now | Updated | test_adm_enq_92 | Automated |
| TC-ADMENQ-P93 | Positive | Ctrl | Delete follow-up removes it, returns JSON success | Deleted | test_adm_enq_93 | Automated |
| TC-ADMENQ-N94 | Negative | Val | Follow-up missing follow_up_type/scheduled_at → required errors | Errors | test_adm_enq_94 | Automated |
| TC-ADMENQ-N95 | Negative | Val | Follow-up with mismatched enquiry_id → 404 | 404 | test_adm_enq_95 | Automated |

### Screen 6: Soft Delete Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P110 | Positive | Ctrl | Soft-delete enquiry (no linked apps), appears in trash | Trashed | test_adm_enq_110 | Automated |
| TC-ADMENQ-P111 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_enq_111 | Automated |
| TC-ADMENQ-P112 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_enq_112 | Automated |
| TC-ADMENQ-N113 | Negative | Biz | Delete enquiry with linked applications → 403 abort | 403 | test_adm_enq_113 | Automated |
| TC-ADMENQ-P120 | Positive | Ctrl | Toggle status on/off returns JSON | JSON | test_adm_enq_120 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMENQ-P140 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_enq_140 | Automated |
| TC-ADMENQ-P141 | Positive | Auth | Follow-up CRUD with correct permissions → 200 | 200 | test_adm_enq_141 | Automated |
| TC-ADMENQ-N142 | Negative | Auth | Without enquiry permissions → 403 | 403 | test_adm_enq_142 | Automated |
| TC-ADMENQ-N143 | Negative | Auth | Without follow-up permissions → 403 | 403 | test_adm_enq_143 | Automated |
