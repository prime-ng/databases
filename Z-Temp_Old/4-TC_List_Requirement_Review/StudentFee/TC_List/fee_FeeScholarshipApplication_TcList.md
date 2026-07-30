# fee_FeeScholarshipApplication_TcList

## Module: StudentFee → Scholarship → Fee Scholarship Application

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | StudentFee |
| Tab Group | Scholarship |
| Feature | Fee Scholarship Applications |
| URL(s) | `/student-fee/scholarship` (tab), `/student-fee/fee-scholarship-application` (index), `/student-fee/fee-scholarship-application/create` (create), `/student-fee/fee-scholarship-application` (store), `/student-fee/fee-scholarship-application/{id}` (show), `/student-fee/fee-scholarship-application/{id}/submit` (submit), `/student-fee/fee-scholarship-application/{id}/approve` (approve), `/student-fee/fee-scholarship-application/{id}/reject` (reject), `/student-fee/fee-scholarship-application/{id}/waitlist` (waitlist), `/student-fee/fee-scholarship-application/{id}/disburse` (disburse) |
| Controller | `Modules\StudentFee\Http\Controllers\FeeScholarshipApplicationController` |
| Model(s) | `Modules\StudentFee\Models\FeeScholarshipApplication` (table: `fee_scholarship_applications`), `Modules\StudentFee\Models\FeeScholarshipApprovalHistory` |
| Service | `Modules\StudentFee\Services\FeeScholarshipService` |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeScholarshipApplicationRequest` |
| Validation (Approve) | `Modules\StudentFee\Http\Requests\ApproveFeeScholarshipApplicationRequest` |
| Validation (Reject) | `Modules\StudentFee\Http\Requests\RejectFeeScholarshipApplicationRequest` |
| Permissions | `tenant.fee-scholarship-application.view`, `tenant.fee-scholarship-application.create`, `tenant.fee-scholarship-application.update`, `tenant.fee-scholarship-application.approve` |
| Resource routes | Only: `index`, `create`, `store`, `show` (no edit/update/destroy) |
| Soft Deletes | Yes (`SoftDeletes` trait on model) |
| Activity Log | Events: `Created`, `Submitted`, `Approved`, `Rejected`, `Waitlisted`, `Disbursed` |

---

## 2. Pre-conditions

- Required permissions: `tenant.fee-scholarship-application.{view,create,update,approve}`
- At least one active scholarship open for applications
- At least one student in `std_students`
- At least one academic session in `sch_org_academic_sessions_jnt`
- Tenant context must be initialized

---

## 3. Default Data Load

When the page loads via `StudentFeeManagementController@scholarship()` (GET `/student-fee/scholarship`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Applications | `FeeScholarshipApplication::with(['scholarship','student.user','academicSession'])->latest()` | Latest first | app_search(student/scholarship name), app_status | 15/page (app_page) |
| Approval Histories | `FeeScholarshipApprovalHistory::with(['application.scholarship','actionBy'])->latest('action_date')` | Latest by date | None | 15/page (hist_page) |
| Status Filters | Array of all 6 statuses | — | — | — |

For create form load:
| Data | Source | Query |
|------|--------|-------|
| Scholarships | `FeeScholarship::active()->openForApplication()->orderBy('name')` | Only active + open for apps |
| Students | `Student::with('user')->orderBy('id')` | All students |
| Academic Sessions | `AcademicSession::orderByDesc('id')` | All sessions |

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Duplicate test**: Use same (scholarship_id, student_id, academic_session_id) combination
- **Workflow test**: Chain actions: create → submit → approve → disburse
- **Rejection test**: Create → submit → reject
- **Waitlist test**: Create → submit → waitlist → approve
- **Pre-test cleanup**: Delete created applications by ID

---

## 5. Business Conditions

### 5.1 Database Schema — `fee_scholarship_applications`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | scholarship_id | INT UNSIGNED FK | NOT NULL → fee_scholarships RESTRICT |
| BC-DB-03 | student_id | INT UNSIGNED FK | NOT NULL → std_students RESTRICT |
| BC-DB-04 | academic_session_id | SMALLINT UNSIGNED FK | NOT NULL → sch_org_academic_sessions_jnt RESTRICT |
| BC-DB-05 | application_date | DATE | NOT NULL |
| BC-DB-06 | application_data | JSON | NOT NULL |
| BC-DB-07 | documents_submitted | JSON | NULLABLE |
| BC-DB-08 | current_stage | INT | NOT NULL DEFAULT 1 |
| BC-DB-09 | status | ENUM('Draft','Submitted','Under Review','Approved','Rejected','Waitlisted') | NOT NULL DEFAULT 'Draft' |
| BC-DB-10 | review_committee | JSON | NULLABLE |
| BC-DB-11 | approved_amount | DECIMAL(10,2) | NULLABLE |
| BC-DB-12 | disbursed | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-13 | disbursed_date | DATE | NULLABLE |
| BC-DB-14 | remarks | TEXT | NULLABLE |
| BC-DB-15 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | scholarship_id | required, integer, exists:fee_scholarships,id | — |
| BC-VAL-02 | student_id | required, integer, exists:std_students,id | — |
| BC-VAL-03 | academic_session_id | required, integer | — |
| BC-VAL-04 | application_date | required, date | — |
| BC-VAL-05 | application_data | nullable, string | — |
| BC-VAL-06 | remarks | nullable, string, max:1000 | — |
| BC-VAL-07 | approved_amount (approve) | required, numeric, min:0.01 | — |
| BC-VAL-08 | comments (approve) | nullable, string, max:500 | — |
| BC-VAL-09 | rejection_reason (reject) | required, string, max:500 | — |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Method | Behavior |
|-------|-----------|--------|----------|
| BC-AUTH-01 | tenant.fee-scholarship-application.view | index(), show() | Without → 403 |
| BC-AUTH-02 | tenant.fee-scholarship-application.create | create(), store() | Without → 403 |
| BC-AUTH-03 | tenant.fee-scholarship-application.update | submit() | Without → 403 |
| BC-AUTH-04 | tenant.fee-scholarship-application.approve | approve(), reject(), waitlist(), disburse() | Without → 403 |

### 5.4 Business Logic (Service Layer)

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create application | Status=Draft, current_stage=1, in DB transaction |
| BC-BIZ-02 | Duplicate (scholarship_id + student_id + session_id) | Error: "This student already has an application for this scholarship in the selected session." |
| BC-BIZ-03 | Submit Draft application | Status=Submitted, current_stage=1, approval history created |
| BC-BIZ-04 | Submit non-Draft application | DomainException: "Only Draft applications can be submitted." |
| BC-BIZ-05 | Approve Submitted/Under Review | Status=Approved, approved_amount set, fund deducted, approval history created |
| BC-BIZ-06 | Approve with amount > max_per_student | DomainException: "Amount exceeds the per-student maximum for this scholarship." |
| BC-BIZ-07 | Approve with insufficient fund | DomainException: "Insufficient available fund in this scholarship." |
| BC-BIZ-08 | Approve in invalid status | DomainException: "Application cannot be approved in its current status." |
| BC-BIZ-09 | Reject Submitted/Under Review/Waitlisted | Status=Rejected, approval history with reason |
| BC-BIZ-10 | Reject in invalid status | DomainException: "Application cannot be rejected in its current status." |
| BC-BIZ-11 | Waitlist Submitted/Under Review | Status=Waitlisted |
| BC-BIZ-12 | Waitlist in invalid status | DomainException: "Application cannot be waitlisted in its current status." |
| BC-BIZ-13 | Disburse Approved application | disbursed=true, disbursed_date set |
| BC-BIZ-14 | Disburse non-Approved | DomainException: "Only approved applications can be marked as dispersed." |
| BC-BIZ-15 | Disburse already disbursed | DomainException: "Application is already dispersed." |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | scholarship_id | fee_scholarships (id) | RESTRICT |
| BC-REF-02 | student_id | std_students (id) | RESTRICT |
| BC-REF-03 | academic_session_id | sch_org_academic_sessions_jnt (id) | RESTRICT |
| BC-REF-04 | application_id (history) | fee_scholarship_applications (id) | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Create Application as Draft | Application created with status=Draft, current_stage=1 | — | — | ⬜ |
| TC-P02 | Create Application With All Fields | application_data, remarks, academic_session all saved | — | — | ⬜ |
| TC-P03 | Show Application Details | Page loads with scholarship, student, academic session, approval histories | — | — | ⬜ |
| TC-P04 | Submit Draft Application | Status changes from Draft to Submitted; approval history created | — | — | ⬜ |
| TC-P05 | Approve Submitted Application | Status=Approved, approved_amount set, fund deducted, history created | — | — | ⬜ |
| TC-P06 | Approve With Comments | Comments recorded in approval history | — | — | ⬜ |
| TC-P07 | Reject Submitted Application | Status=Rejected, rejection_reason stored, history created | — | — | ⬜ |
| TC-P08 | Waitlist Submitted Application | Status=Waitlisted, approval history created | — | — | ⬜ |
| TC-P09 | Disburse Approved Application | disbursed=true, disbursed_date set | — | — | ⬜ |
| TC-P10 | Full Workflow: Create → Submit → Approve → Disburse | All status transitions succeed, history created at each step | — | — | ⬜ |
| TC-P11 | Reject Waitlisted Application | Can reject from Waitlisted status | — | — | ⬜ |
| TC-P12 | Approve Waitlisted Application | Can approve from Waitlisted status (fund permitting) | — | — | ⬜ |
| TC-P13 | Filter Applications By Status | Grid filters to selected status | — | — | ⬜ |
| TC-P14 | Search Applications By Student/Scholarship | Grid filters by student or scholarship name | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing `scholarship_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — Missing `student_id` | Validation error | — | — | ⬜ |
| TC-N03 | Required — Missing `academic_session_id` | Validation error | — | — | ⬜ |
| TC-N04 | Required — Missing `application_date` | Validation error | — | — | ⬜ |
| TC-N05 | Duplicate (scholarship_id + student_id + session_id) | Error: "This student already has an application for this scholarship in the selected session." | — | — | ⬜ |
| TC-N06 | Submit non-Draft (Submitted) | DomainException: "Only Draft applications can be submitted." | — | — | ⬜ |
| TC-N07 | Approve in Draft status | DomainException: "Application cannot be approved in its current status." | — | — | ⬜ |
| TC-N08 | Approve amount > max_per_student | DomainException: "Amount exceeds the per-student maximum for this scholarship." | — | — | ⬜ |
| TC-N09 | Approve with insufficient fund | DomainException: "Insufficient available fund in this scholarship." | — | — | ⬜ |
| TC-N10 | Approve without approved_amount (empty) | Validation: "The approved amount field is required." | — | — | ⬜ |
| TC-N11 | Reject without rejection_reason | Validation: "The rejection reason field is required." | — | — | ⬜ |
| TC-N12 | Reject in Draft status | DomainException: "Application cannot be rejected in its current status." | — | — | ⬜ |
| TC-N13 | Waitlist in Draft status | DomainException: "Application cannot be waitlisted in its current status." | — | — | ⬜ |
| TC-N14 | Disburse non-Approved application | DomainException: "Only approved applications can be marked as dispersed." | — | — | ⬜ |
| TC-N15 | Disburse already disbursed application | DomainException: "Application is already dispersed." | — | — | ⬜ |
| TC-N16 | Permission 403 on approve without approve permission | 403 Forbidden | — | — | ⬜ |
| TC-N17 | Guest access redirect | Redirected to /login | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Create → service uses DB transaction | All create operations wrapped in DB::transaction() | — | — | ⬜ |
| TC-D02 | B | Submit → approval history created | Action='Submit', stage=1, action_by=auth user | — | — | ⬜ |
| TC-D03 | C | Approve → fund deducted | `$scholarship->deductFund($amount)` called; available_fund decreased | — | — | ⬜ |
| TC-D04 | D | Approve → approval history with action='Approve' | History record created with approve action, stage incremented | — | — | ⬜ |
| TC-D05 | E | Reject → approval history with action='Reject' | History record created with reject action | — | — | ⬜ |
| TC-D06 | F | Waitlist → approval history with action='Waitlist' | History record created with waitlist action | — | — | ⬜ |
| TC-D07 | G | Activity logged for all workflow actions | Created, Submitted, Approved, Rejected, Waitlisted, Disbursed all logged | — | — | ⬜ |
| TC-D08 | H | Duplicate check includes soft-deleted records | `withTrashed()` used in duplicate query | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — FeeScholarshipService DI via constructor | `__construct(private readonly FeeScholarshipService $scholarshipService)` | — | — | ◌ |
| TC-CR02 | CR | P1 | Resource routes limited to index/create/store/show | No edit/update/destroy routes defined | — | — | ◌ |
| TC-CR03 | CR | P1 | Service — DomainException thrown for invalid transitions | All status transitions validated via throw_if | — | — | ◌ |
| TC-CR04 | CR | P1 | ApproveFeeScholarshipApplicationRequest — approve permission | `authorizePermission('tenant.fee-scholarship-application.approve')` | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P10: Full Workflow — Create → Submit → Approve → Disburse

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create application with valid data | Status=Draft |
| 2 | Click "Submit" button | POST to submit(); status=Submitted; approval history Submit created |
| 3 | Click "Approve" with approved_amount=20000 | POST to approve(); status=Approved; approved_amount=20000; fund deducted |
| 4 | Verify fund deducted from scholarship | available_fund decreased by 20000 |
| 5 | Verify approval history Approve created | Action='Approve', stage=2, action_by set |
| 6 | Click "Disburse" | POST to disburse(); disbursed=true; disbursed_date set |
| 7 | Verify final state | Status=Approved, disbursed=1, disbursed_date not null |

### TC-N05: Duplicate Application

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create application with scholarship_id=X, student_id=Y, session_id=Z | Created as Draft |
| 2 | Create second application with same X, Y, Z | POST to store() |
| 3 | Check response | Error: "This student already has an application for this scholarship in the selected session." |

---

## 8. Known Issues

- Service error messages have spelling: "dispersed" instead of "disbursed" in two messages
- No `update` or `edit` routes exist for applications — they must be deleted and recreated
- `send()` method not used in FeeScholarshipApprovalHistory — uses `action_date` as CREATED_AT

## 9. Route Reference

| Method | URI | Name | Controller Method |
|--------|-----|------|-------------------|
| GET | `/student-fee/fee-scholarship-application` | index | index |
| GET | `/student-fee/fee-scholarship-application/create` | create | create |
| POST | `/student-fee/fee-scholarship-application` | store | store |
| GET | `/student-fee/fee-scholarship-application/{id}` | show | show |
| POST | `/student-fee/fee-scholarship-application/{id}/submit` | submit | submit |
| POST | `/student-fee/fee-scholarship-application/{id}/approve` | approve | approve |
| POST | `/student-fee/fee-scholarship-application/{id}/reject` | reject | reject |
| POST | `/student-fee/fee-scholarship-application/{id}/waitlist` | waitlist | waitlist |
| POST | `/student-fee/fee-scholarship-application/{id}/disburse` | disburse | disburse |

## 10. Execution Status

| Total TC | Passed | Failed | Blocked | Skipped | Execution Date |
|----------|--------|--------|---------|---------|----------------|
| 0 | 0 | 0 | 0 | 0 | — |
