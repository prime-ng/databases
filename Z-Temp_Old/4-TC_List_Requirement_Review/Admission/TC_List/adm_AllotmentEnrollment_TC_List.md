# adm_AllotmentEnrollment — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Allotments + Enrollment + Withdrawals
**DB scope:** TENANT-side (`adm_allotments`, `adm_withdrawals`) · **Test style:** Browser Dusk
**Primary table:** `adm_allotments` · **Module URL prefix:** `/admission/allotment-enrollment`
**Test file:** `adm_AllotmentEnrollment_TestCas.php`
**Tabs:** Allotments (default), Withdrawals (second tab)

Controllers:
- `AllotmentController` — CRUD + trash + toggle + accept/decline + offerLetter PDF
- `EnrollmentController` — show (enrollment form) + store (14-step atomic enrollment)
- `WithdrawalController` — CRUD + trash + toggle + processRefund
- `AdmMenuController::allotmentEnrollment()` — loads allotments + withdrawals for the tabbed page

Routes (`adm.` prefix):
- `GET /admission/allotment-enrollment` — tabbed page (Allotments + Withdrawals tabs)
- `GET /admission/alloment/create` — create allotment form
- `POST /admission/alloment` — store allotment
- `GET /admission/alloment/{allotment}` — show allotment
- `GET /admission/alloment/{allotment}/edit` — edit allotment
- `PUT /admission/alloment/{allotment}` — update allotment
- `DELETE /admission/alloment/{allotment}` — soft delete (blocked if Enrolled)
- `POST /admission/alloment/{id}/toggle-status` — toggle active (JSON)
- `POST /admission/alloment/{allotment}/accept` — accept offer (Offered → Accepted)
- `POST /admission/alloment/{allotment}/decline` — decline offer (Offered → Declined)
- `GET /admission/alloment/{allotment}/offer-letter` — generate offer letter PDF
- `GET /admission/alloment/trash/view` — trashed allotments
- `GET /admission/alloment/{id}/restore` — restore allotment
- `DELETE /admission/alloment/{id}/force-delete` — force delete allotment
- `GET /admission/enroll/{allotment}` — enrollment form
- `POST /admission/enroll/{allotment}` — execute enrollment (14-step)
- `POST /admission/withdrawals` — store withdrawal
- `GET /admission/withdrawals/{withdrawal}` — show withdrawal
- `GET /admission/withdrawals/{withdrawal}/edit` — edit withdrawal
- `PUT /admission/withdrawals/{withdrawal}` — update withdrawal
- `DELETE /admission/withdrawals/{withdrawal}` — soft delete (blocked if refund Paid)
- `POST /admission/withdrawals/{id}/toggle-status` — toggle active (JSON)
- `POST /admission/withdrawals/{withdrawal}/process-refund` — process refund
- `GET /admission/withdrawals/trash/view` — trashed withdrawals
- `GET /admission/withdrawals/{id}/restore` — restore withdrawal
- `DELETE /admission/withdrawals/{id}/force-delete` — force delete withdrawal

Service:
- `EnrollmentService::enrollStudent()` — 14-step atomic cross-module enrollment
- `EnrollmentService::generateAdmissionNo()` — admission number generation
- `AdmissionPipelineService::allot()` — application status → Allotted

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_allotments`: id (BIGINT PK AI), merit_list_entry_id (BIGINT UNSIGNED FK), application_id (BIGINT UNSIGNED FK), admission_no (VARCHAR 50 NULL UNIQUE), allotted_class_id (INT UNSIGNED FK), allotted_section_id (INT UNSIGNED FK NULL), joining_date (DATE NULL), offer_letter_media_id FK NULL, offer_issued_at TIMESTAMP NULL, offer_expires_at DATE NULL, admission_fee_paid BOOLEAN DEFAULT false, admission_fee_amount DECIMAL 10,2 NULL, admission_fee_date DATE NULL, status ENUM(Offered,Accepted,Declined,Expired,Enrolled,Withdrawn) DEFAULT Offered, enrolled_student_id INT UNSIGNED FK NULL, is_active, created_by, updated_by, timestamps, softDeletes. Indexes: uq_admission_no (unique nullable), idx status, idx offer_expires_at | DDL/DDL |
| BC-DB-02 | Table `adm_withdrawals`: id (BIGINT PK AI), application_id (BIGINT UNSIGNED FK), allotment_id (BIGINT UNSIGNED FK NULL), withdrawal_date (DATE), reason ENUM(Personal,Financial,Relocation,School_Change,Medical,Other), remarks TEXT NULL, fee_paid_amount DECIMAL 10,2, refund_eligible_amount DECIMAL 10,2, refund_status ENUM(Not_Eligible,Pending,Approved,Paid) DEFAULT Not_Eligible, refund_processed_at DATE NULL, processed_by FK NULL, is_active, created_by, updated_by, timestamps, softDeletes | DDL |
| BC-DB-03 | Model `Allotment`: table adm_allotments, SoftDeletes, HasFactory, fillable 17 fields, casts: joining_date/offer_expires_at/admission_fee_date→date, offer_issued_at→datetime, admission_fee_amount→decimal:2, admission_fee_paid/is_active→boolean. Accessor: getAllotmentNoAttribute() → 'ALT-00001' | Model |
| BC-DB-04 | Model `Withdrawal`: table adm_withdrawals, SoftDeletes, HasFactory, fillable 12 fields, casts: withdrawal_date/refund_processed_at→date, fee_paid_amount/refund_eligible_amount→decimal:2, is_active→boolean | Model |
| BC-DB-05 | Allotment relationships: meritListEntry() belongsTo, application() belongsTo, allottedClass() belongsTo SchoolClass, allottedSection() belongsTo Section, enrolledStudent() belongsTo Student, withdrawal() hasOne | Model |
| BC-DB-06 | Withdrawal relationships: application() belongsTo, allotment() belongsTo, processedBy() belongsTo User | Model |

### BC-VAL — Validation (StoreAllotmentRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `application_id` required integer exists:adm_applications,id | FR |
| BC-VAL-02 | `merit_list_entry_id` required integer exists:adm_merit_list_entries,id | FR |
| BC-VAL-03 | `allotted_class_id` required integer exists:sch_classes,id | FR |
| BC-VAL-04 | `allotted_section_id` nullable integer exists:sch_sections,id | FR |
| BC-VAL-05 | `admission_no` nullable unique:adm_allotments | FR |
| BC-VAL-06 | `status` required in:Offered,Accepted,Declined,Expired,Enrolled | FR |
| BC-VAL-07 | `offer_expires_at` nullable date | FR |
| BC-VAL-08 | `joining_date` nullable date | FR |
| BC-VAL-09 | `admission_fee_amount` nullable numeric min:0 | FR |
| BC-VAL-10 | `admission_fee_paid` nullable boolean | FR |
| BC-VAL-11 | `admission_fee_date` nullable date | FR |

### BC-VAL-UPD — UpdateAllotmentRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-UPD-01 | Same as store, admission_no unique excludes own ID via Rule::unique()->ignore(route('allotment')) | FR |

### BC-VAL-ENROLL — EnrollStudentRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-ENROLL-01 | `confirm` required accepted | FR |

### BC-VAL-WD — StoreWithdrawalRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-WD-01 | `application_id` required integer exists:adm_applications,id | FR |
| BC-VAL-WD-02 | `allotment_id` nullable integer exists:adm_allotments,id | FR |
| BC-VAL-WD-03 | `withdrawal_date` required date | FR |
| BC-VAL-WD-04 | `reason` required in:Personal,Financial,Relocation,School_Change,Medical,Other | FR |
| BC-VAL-WD-05 | `remarks` nullable string | FR |
| BC-VAL-WD-06 | `fee_paid_amount` nullable numeric min:0 | FR |
| BC-VAL-WD-07 | `refund_eligible_amount` nullable numeric min:0 | FR |
| BC-VAL-WD-08 | `refund_status` nullable in:Not_Eligible,Pending,Approved,Paid | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Allotment index/trashed gate `tenant.adm-allotment.viewAny` | Policy |
| BC-AUTH-02 | Allotment create/store gate `tenant.adm-allotment.create` | Policy |
| BC-AUTH-03 | Allotment show gate `tenant.adm-allotment.view` | Policy |
| BC-AUTH-04 | Allotment edit/update/toggleStatus gate `tenant.adm-allotment.update` | Policy |
| BC-AUTH-05 | Allotment destroy/restore/forceDelete gate `tenant.adm-allotment.delete` | Policy |
| BC-AUTH-06 | Allotment accept/decline/offerLetter gate `tenant.adm-allotment.status` | Policy |
| BC-AUTH-07 | Enrollment show/store gate `tenant.adm-enrollment.create` | Policy |
| BC-AUTH-08 | Withdrawal CRUD gates `tenant.adm-withdrawal.*` | Policy |

### BC-BIZ — Business Logic (Allotments)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Tabbed page loads Allotments (default) + Withdrawals tabs via AdmMenuController::allotmentEnrollment() | MenuCtrl |
| BC-BIZ-02 | Allotments list: search by student name (first/last) or application_no, filter by is_active, paginated 20, ordered by id desc | MenuCtrl |
| BC-BIZ-03 | List loads application, allottedClass, allottedSection relations | MenuCtrl |
| BC-BIZ-04 | Store: locks seat capacity row (lockForUpdate), increments seats_allotted, generates admission_no via EnrollmentService::generateAdmissionNo() | Ctrl |
| BC-BIZ-05 | Destroy blocked if allotment status is 'Enrolled' → redirect back with error | Ctrl |
| BC-BIZ-06 | accept(): transitions status Offered → Accepted | Ctrl |
| BC-BIZ-07 | decline(): transitions status Offered → Declined, decrements seats_allotted | Ctrl |
| BC-BIZ-08 | offerLetter(): generates PDF via DomPDF, stores offer_letter_media_id, sets offer_issued_at | Ctrl |
| BC-BIZ-09 | Status badges: Offered=primary, Accepted=info, Declined=danger, Expired=warning, Enrolled=success, Withdrawn=secondary | View |

### BC-BIZ-ENROLL — Enrollment (EnrollmentService::enrollStudent)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-ENROLL-01 | Guard: allotment must be 'Accepted' or throws DomainException | Service |
| BC-BIZ-ENROLL-02 | Guard: admission_fee_paid must be true, else throws DomainException | Service |
| BC-BIZ-ENROLL-03 | Guard: enrolled_student_id must be null (not already enrolled) | Service |
| BC-BIZ-ENROLL-04 | Generates admission_no via generateAdmissionNo() if not already set | Service |
| BC-BIZ-ENROLL-05 | **CROSS-MODULE**: Creates sys_users record (portal login, password = admission_no) | Service |
| BC-BIZ-ENROLL-06 | **CROSS-MODULE**: Creates std_students record with full name, DOB, gender, etc. | Service |
| BC-BIZ-ENROLL-07 | **CROSS-MODULE**: Creates std_student_academic_sessions for current session | Service |
| BC-BIZ-ENROLL-08 | **CROSS-MODULE**: Creates std_siblings_jnt if application.is_sibling = true | Service |
| BC-BIZ-ENROLL-09 | Updates allotment: sets enrolled_student_id, status = 'Enrolled' | Service |
| BC-BIZ-ENROLL-10 | Transitions application status to 'Enrolled' via AdmissionPipelineService | Service |
| BC-BIZ-ENROLL-11 | Updates merit_list_entry status to 'Enrolled' | Service |
| BC-BIZ-ENROLL-12 | Increments seats_enrolled on adm_seat_capacity | Service |
| BC-BIZ-ENROLL-13 | Appends ApplicationStage audit log | Service |
| BC-BIZ-ENROLL-14 | All steps in single DB transaction | Service |
| BC-BIZ-ENROLL-15 | generateAdmissionNo(): format {YEAR}/{SEQ}, checks both adm_allotments + std_students for sequence | Service |

### BC-BIZ-WD — Withdrawals
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-WD-01 | Withdrawals list: search by student name / application_no, filter by is_active | MenuCtrl |
| BC-BIZ-WD-02 | Store: transitions application to 'Withdrawn' via AdmissionPipelineService | Ctrl |
| BC-BIZ-WD-03 | Destroy blocked if refund_status is 'Paid' → redirect back with error | Ctrl |
| BC-BIZ-WD-04 | processRefund(): sets refund_status = 'Paid', refund_processed_at = now, processed_by = auth user | Ctrl |
| BC-BIZ-WD-05 | Refund status badges: Not_Eligible=secondary, Pending=warning, Approved=info, Paid=success | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete Enrolled allotment → blocked (error) | Ctrl |
| BC-EDG-02 | Decline already-declined allotment → allowed (idempotent, status unchanged if not Offered) | Ctrl |
| BC-EDG-03 | Enroll non-Accepted allotment → DomainException | Service |
| BC-EDG-04 | Enroll without fee paid → DomainException | Service |
| BC-EDG-05 | Enroll already-enrolled allotment → DomainException (enrolled_student_id not null) | Service |
| BC-EDG-06 | Delete withdrawal with Paid refund → blocked (error) | Ctrl |
| BC-EDG-07 | Seat capacity lock: concurrent store() with lockForUpdate prevents oversubscription | Ctrl |
| BC-EDG-08 | admission_no uniqueness: generated number checked against both adm_allotments and std_students | Service |
| BC-EDG-09 | Withdrawal without allotment_id (pre-allotment) → allowed | Ctrl |

---

## 2. Test Case List

### Screen 1: Allotment-Enrollment Page — Allotments Tab (GET /admission/allotment-enrollment)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P10 | Positive | View | Page renders 2 tabs: Allotments + Withdrawals | Tabs visible | test_adm_ae_10 | Automated |
| TC-ADMAE-P11 | Positive | View | Allotments table: Student Name, Allotted Class, Section, Status badge, Active toggle, Expires, Action | Rendered | test_adm_ae_11 | Automated |
| TC-ADMAE-P12 | Positive | View | Search by student name / application_no, filter by is_active | Filtered | test_adm_ae_12 | Automated |
| TC-ADMAE-P13 | Positive | View | Status badges: Offered=primary, Accepted=info, Declined=danger, Expired=warning, Enrolled=success, Withdrawn=secondary | Colors | test_adm_ae_13 | Automated |
| TC-ADMAE-P14 | Positive | View | Create button visible (permission-gated) | Button | test_adm_ae_14 | Automated |

### Screen 2: Allotment Create + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P30 | Positive | View | Create form: Application select, Merit List Entry, Class/Section, Status, Offer Expiry, Admission No, Joining Date, Fee fields | Fields | test_adm_ae_30 | Automated |
| TC-ADMAE-P31 | Positive | View | Dropdowns load applications, merit list entries, classes, sections | Loaded | test_adm_ae_31 | Automated |
| TC-ADMAE-P32 | Positive | Biz | Store locks seat_capacity row, increments seats_allotted, generates admission_no | Created | test_adm_ae_32 | Automated |
| TC-ADMAE-P33 | Positive | Biz | Concurrent store with lockForUpdate prevents oversubscription | Locked | test_adm_ae_33 | Automated |
| TC-ADMAE-P34 | Positive | Biz | admission_no format {YEAR}/{SEQ} via EnrollmentService::generateAdmissionNo() | Correct | test_adm_ae_34 | Automated |
| TC-ADMAE-N35 | Negative | Val | Missing application_id/merit_list_entry_id/class_id → required errors | Errors | test_adm_ae_35 | Automated |
| TC-ADMAE-N36 | Negative | Val | Duplicate admission_no → unique error | Error | test_adm_ae_36 | Automated |

### Screen 3: Allotment Show (GET /admission/alloment/{allotment})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P50 | Positive | View | Show page: status badge, student info, admission_no, class, section, offer dates, fee details | All fields | test_adm_ae_50 | Automated |
| TC-ADMAE-P51 | Positive | View | Action panel: Edit, Accept/Decline Offer, Proceed to Enrollment, View Offer Letter, Back | Buttons | test_adm_ae_51 | Automated |
| TC-ADMAE-P52 | Positive | View | Enrolled student info when enrolled_student_id set | Student info | test_adm_ae_52 | Automated |

### Screen 4: Allotment Accept / Decline / Offer Letter

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P70 | Positive | Biz | Accept: Offered → Accepted | Accepted | test_adm_ae_70 | Automated |
| TC-ADMAE-P71 | Positive | Biz | Decline: Offered → Declined, decrements seats_allotted | Declined | test_adm_ae_71 | Automated |
| TC-ADMAE-P72 | Positive | Ctrl | Offer Letter: generates PDF via DomPDF, stores media_id, sets offer_issued_at | PDF generated | test_adm_ae_72 | Automated |
| TC-ADMAE-N73 | Negative | Biz | Decline already-Declined → allowed (no-op) | No error | test_adm_ae_73 | Automated |

### Screen 5: Enrollment (GET/POST /admission/enroll/{allotment})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P90 | Positive | View | Enrollment form pre-filled with application data, confirmation checkbox | Form | test_adm_ae_90 | Automated |
| TC-ADMAE-P91 | Positive | View | Read-only class/section display, allotment sidebar | Read-only | test_adm_ae_91 | Automated |
| TC-ADMAE-P92 | Positive | Service | 14-step atomic enrollment: creates user, student, academic session, siblings, updates allotment/app/merit/seat | Enrolled | test_adm_ae_92 | Automated |
| TC-ADMAE-P93 | Positive | Service | sys_users created with password = admission_no | User | test_adm_ae_93 | Automated |
| TC-ADMAE-P94 | Positive | Service | std_students record created with full name, DOB, gender, guardian, address | Student | test_adm_ae_94 | Automated |
| TC-ADMAE-P95 | Positive | Service | std_student_academic_sessions created | Session | test_adm_ae_95 | Automated |
| TC-ADMAE-P96 | Positive | Service | std_siblings_jnt created if is_sibling=true | Sibling link | test_adm_ae_96 | Automated |
| TC-ADMAE-P97 | Positive | Service | seats_enrolled incremented on adm_seat_capacity | Count | test_adm_ae_97 | Automated |
| TC-ADMAE-P98 | Positive | Service | ApplicationStage appended for Enrolled transition | Audit | test_adm_ae_98 | Automated |
| TC-ADMAE-N99 | Negative | Service | Enroll non-Accepted allotment → DomainException | Error | test_adm_ae_99 | Automated |
| TC-ADMAE-N100 | Negative | Service | Enroll without admission_fee_paid → DomainException | Error | test_adm_ae_100 | Automated |
| TC-ADMAE-N101 | Negative | Service | Enroll already-enrolled allotment → DomainException | Error | test_adm_ae_101 | Automated |

### Screen 6: Allotment Soft Delete + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P110 | Positive | Ctrl | Soft-delete allotment (not Enrolled), appears in trash | Trashed | test_adm_ae_110 | Automated |
| TC-ADMAE-P111 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_ae_111 | Automated |
| TC-ADMAE-P112 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_ae_112 | Automated |
| TC-ADMAE-N113 | Negative | Biz | Delete Enrolled allotment → blocked (error) | Blocked | test_adm_ae_113 | Automated |
| TC-ADMAE-P120 | Positive | Ctrl | Toggle is_active on/off returns JSON | JSON | test_adm_ae_120 | Automated |

### Screen 7: Withdrawals Tab (GET /admission/allotment-enrollment?tab=withdrawals)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P140 | Positive | View | Withdrawals tab: table with search, reason, refund amt, refund status, processed by, active, action | Rendered | test_adm_ae_140 | Automated |
| TC-ADMAE-P141 | Positive | View | Create Withdrawal modal opens | Modal | test_adm_ae_141 | Automated |
| TC-ADMAE-P142 | Positive | View | Refund status badges: Not_Eligible=secondary, Pending=warning, Approved=info, Paid=success | Colors | test_adm_ae_142 | Automated |

### Screen 8: Withdrawal Store (Modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P160 | Positive | Ctrl | Store: transitions application to Withdrawn, records withdrawal | Created | test_adm_ae_160 | Automated |
| TC-ADMAE-P161 | Positive | View | Modal fields: application, allotment, date, reason, remarks, fee/refund amounts, refund status | Fields | test_adm_ae_161 | Automated |
| TC-ADMAE-N162 | Negative | Val | Missing application_id/withdrawal_date/reason → required errors | Errors | test_adm_ae_162 | Automated |

### Screen 9: Withdrawal Show + Refund Processing

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P180 | Positive | View | Withdrawal show: refund status, student info, fee/refund details, reason, remarks | All fields | test_adm_ae_180 | Automated |
| TC-ADMAE-P181 | Positive | View | Action panel: Edit, Process Refund, Back | Buttons | test_adm_ae_181 | Automated |
| TC-ADMAE-P182 | Positive | Biz | processRefund: status=Paid, refund_processed_at=now, processed_by=auth | Processed | test_adm_ae_182 | Automated |

### Screen 10: Withdrawal Soft Delete + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P200 | Positive | Ctrl | Soft-delete withdrawal (refund not Paid), appears in trash | Trashed | test_adm_ae_200 | Automated |
| TC-ADMAE-P201 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_ae_201 | Automated |
| TC-ADMAE-P202 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_ae_202 | Automated |
| TC-ADMAE-N203 | Negative | Biz | Delete withdrawal with Paid refund → blocked (error) | Blocked | test_adm_ae_203 | Automated |
| TC-ADMAE-P210 | Positive | Ctrl | Toggle withdrawal is_active on/off returns JSON | JSON | test_adm_ae_210 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAE-P220 | Positive | Auth | Allotment CRUD with correct permissions → 200 | 200 | test_adm_ae_220 | Automated |
| TC-ADMAE-P221 | Positive | Auth | Enrollment with enrollment.create permission → success | 200 | test_adm_ae_221 | Automated |
| TC-ADMAE-P222 | Positive | Auth | Withdrawal CRUD with correct permissions → 200 | 200 | test_adm_ae_222 | Automated |
| TC-ADMAE-N223 | Negative | Auth | Without alloment viewAny → 403 on tab | 403 | test_adm_ae_223 | Automated |
| TC-ADMAE-N224 | Negative | Auth | Without enrollment.create → 403 on enroll | 403 | test_adm_ae_224 | Automated |
| TC-ADMAE-N225 | Negative | Auth | Without withdrawal create → 403 on withdrawal store | 403 | test_adm_ae_225 | Automated |
