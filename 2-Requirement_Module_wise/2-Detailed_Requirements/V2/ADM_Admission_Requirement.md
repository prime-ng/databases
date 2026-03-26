# ADM — Admission Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Module Code:** ADM | **Scope:** Tenant | **Table Prefix:** `adm_`
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x + stancl/tenancy v3.9 + nwidart/laravel-modules v12

---

## 1. Executive Summary

The Admission module (ADM) manages the complete pre-enrollment lifecycle for Indian K-12 schools — from the first point of contact (enquiry/lead) through online/offline application, document verification, entrance assessment, merit-based selection, seat allotment, admission fee collection, digital offer letter, and final enrollment that creates verified student records in the StudentProfile module.

V2 expands the V1 specification with explicit coverage of: online payment gateway integration, sibling preference priority rules, waitlist auto-promotion, academic-year seat capacity management, withdrawal and refund workflow, and an admission analytics funnel dashboard. All features are marked 📐 Proposed (greenfield — no code exists). All tables are 📐 new.

**Overall implementation status: 0% — Greenfield / Not Started**

| Metric | Count |
|--------|-------|
| 📐 Proposed Tables | 20 |
| 📐 Proposed Controllers | 14 |
| 📐 Proposed Models | 20 |
| 📐 Proposed Services | 6 |
| 📐 Proposed Routes (web) | ~65 |
| 📐 Proposed Routes (api) | ~20 |
| 📐 Proposed UI Screens | 25 |
| Functional Requirements | 15 |

---

## 2. Module Overview

### 2.1 Business Context

Indian schools run annual admission cycles (typically January–June for the following academic year). The process involves lead generation, multi-step application, document verification, optional entrance test, quota-based merit list, seat allotment, offer letter, admission fee, and final enrollment. The ADM module replaces paper registers, automates counselor workflows, provides real-time pipeline visibility, and generates government-compliant audit trails.

### 2.2 Key Feature Groups

| # | Feature Group | V1 | V2 New/Enhanced |
|---|--------------|-----|-----------------|
| 1 | Lead Capture & Enquiry | V1 | Sibling auto-detect at enquiry stage 🆕 |
| 2 | Follow-up & CRM | V1 | Follow-up calendar heat-map 🆕 |
| 3 | Online Application | V1 | Public form with payment gateway link 🆕 |
| 4 | Document Verification | V1 | Per-document OCR flag (future) |
| 5 | Entrance Test Management | V1 | Hall ticket PDF generation 🆕 |
| 6 | Merit List & Quota | V1 | Waitlist auto-promotion trigger 🆕 |
| 7 | Seat Capacity Management | V1 | Per-class-per-cycle seat budget 🆕 |
| 8 | Offer Letter & Admission Fee | V1 | Online payment webhook confirmation 🆕 |
| 9 | Withdrawal & Refund | 📐 NEW | Withdrawal reason, refund policy config 🆕 |
| 10 | Enrollment Conversion | V1 | Sibling linking on enrollment 🆕 |
| 11 | Class Allocation | V1 | Auto-balance section strengths 🆕 |
| 12 | Promotion Wizard | V1 | Preview and dry-run before commit |
| 13 | Alumni & TC | V1 | Digital TC with QR code verification 🆕 |
| 14 | Behavior Assessment | V1 | Behavior score trend chart 🆕 |
| 15 | Admission Analytics Funnel | 📐 NEW | Enquiry → Applied → Shortlisted → Admitted 🆕 |

### 2.3 Menu Navigation Path

```
Tenant Dashboard
└── Admission
    ├── Dashboard (pipeline + funnel analytics)
    ├── Enquiries
    │   ├── All Enquiries
    │   ├── My Leads
    │   └── Follow-up Calendar
    ├── Applications
    │   ├── All Applications
    │   ├── Pending Verification
    │   └── Interview Schedule
    ├── Entrance Tests
    │   ├── Test Sessions
    │   ├── Hall Tickets
    │   └── Mark Entry
    ├── Merit & Allotment
    │   ├── Merit Lists
    │   ├── Seat Allotment
    │   ├── Waitlist
    │   └── Offer Letters
    ├── Enrollment
    │   ├── Pending Enrollment
    │   └── Enrolled Students
    ├── Withdrawals
    ├── Promotions
    │   ├── Promotion Wizard
    │   └── Promotion History
    ├── Alumni & TC
    │   ├── Alumni Register
    │   └── TC Issuance
    ├── Behavior
    │   ├── Incidents
    │   └── Reports
    └── Settings
        ├── Admission Cycles
        ├── Seat Capacity
        ├── Document Checklist
        ├── Quota Configuration
        └── Refund Policy
```

### 2.4 📐 Proposed Module Architecture

```
Modules/Admission/
├── app/Http/Controllers/
│   ├── AdmissionDashboardController.php
│   ├── EnquiryController.php
│   ├── FollowUpController.php
│   ├── ApplicationController.php
│   ├── ApplicationDocumentController.php
│   ├── EntranceTestController.php
│   ├── MeritListController.php
│   ├── AllotmentController.php
│   ├── WithdrawalController.php
│   ├── EnrollmentController.php
│   ├── PromotionController.php
│   ├── AlumniController.php
│   ├── BehaviorIncidentController.php
│   └── AdmissionAnalyticsController.php
├── app/Services/
│   ├── AdmissionPipelineService.php
│   ├── EnrollmentService.php
│   ├── MeritListService.php
│   ├── PromotionService.php
│   ├── TransferCertificateService.php
│   └── AdmissionAnalyticsService.php
├── database/migrations/
├── database/seeders/
│   ├── AdmissionDocumentChecklistSeeder.php
│   └── AdmissionQuotaSeeder.php
└── routes/
    ├── web.php
    └── api.php
```

---

## 3. Stakeholders & Roles

| Actor | Role | Key Permissions |
|-------|------|-----------------|
| Super Admin (Prime) | Platform config | Module enable/disable per tenant |
| School Admin | Full admission management | All CRUD, allotment, enrollment, settings |
| Admission Counselor | Lead and application management | Create/edit enquiries, process applications |
| Front Office Staff | Walk-in enquiry capture | Create enquiries only |
| Principal / Vice Principal | Allotment approval, merit list sign-off | Approve allotments, issue TC |
| Class Teacher | Promotion recommendations | View students, submit promotion remarks |
| Finance Staff | Fee confirmation | Mark application fee paid, confirm admission fee |
| Parent/Guardian (Public) | Submit online enquiry and application | Public form, status tracking via application number |
| System (automated) | Stage transitions, notifications, waitlist promotion | Internal service calls |

---

## 4. Functional Requirements

### FR-ADM-01: 📐 Admission Cycle & Seat Capacity Configuration
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** 📐 `adm_admission_cycles`, 📐 `adm_seat_capacity`

#### Description
School admin configures an admission cycle for each academic year — defining open/close dates, application fee, public form slug, and per-class seat capacity split across quota types. Without an active cycle no enquiries can be received.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 01.1 | Create/edit admission cycle with academic session, name, code, dates, and application fee | Cycle code unique; start_date < end_date; duplicate code rejected |
| 01.2 | Set per-class seat capacity with quota breakdown (General/Govt/Mgmt/RTE/NRI/Staff/Sibling/EWS) | Sum of quota seats <= total class strength from `sch_class_section_jnt` |
| 01.3 | Configure document checklist per cycle (optionally per class level) with mandatory/optional flags | Checklist persisted to `adm_document_checklist`; visible on public form |
| 01.4 | Configure refund policy per cycle (% refundable within N days of withdrawal) | Stored as JSON in `adm_admission_cycles.refund_policy_json` |
| 01.5 | Activate/deactivate cycle; only one cycle can be `Active` per academic session | Guard prevents dual-active; status transitions: Draft → Active → Closed → Archived |

📐 **Implementation:** `AdmissionCycleController` (settings), `AdmissionPipelineService::activateCycle()`.

---

### FR-ADM-02: 📐 Lead Capture & Enquiry Management
**Priority:** High | **Status:** ❌ Not Started
**Tables:** 📐 `adm_enquiries`, 📐 `adm_follow_ups`

#### Description
Capture initial contact details from prospective parents via online form (unauthenticated), walk-in registration, or campaign responses. Each enquiry is a pre-application lead assigned to a counselor for follow-up. Sibling of existing student is auto-detected at this stage to flag priority.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 02.1 | Record enquiry: student name, DOB, gender, parent name, mobile, email, class sought, academic year, lead source | Enquiry number ENQ-YYYY-NNNNN auto-generated; welcome SMS/email dispatched |
| 02.2 | Age eligibility validation: warn if student DOB makes them underage or overage for selected class | Configurable min/max age per class; warning shown, not hard block |
| 02.3 | Detect potential sibling: if parent mobile matches an existing `std_students` guardian record, flag as sibling lead and boost priority | `adm_enquiries.is_sibling_lead = 1`; shown as badge in enquiry list |
| 02.4 | Assign counselor manually or via auto-assign (round-robin, fewest open leads) | Auto-assign queries counselors with `ADMISSION_COUNSELOR` role; assigns least-loaded |
| 02.5 | Detect duplicate: same mobile submitted twice in same cycle — show warning, allow proceed or merge | Warning displayed; duplicate flag on `adm_enquiries.is_duplicate` |
| 02.6 | Schedule follow-up (call/meeting/email/SMS) with date-time and reminder N hours before | `adm_follow_ups` record; reminder queued via NTF module |
| 02.7 | Update lead status after each follow-up: New → Assigned → Contacted → Interested / Not_Interested / Callback / Converted | Status history implicitly tracked via `adm_follow_ups.outcome` |
| 02.8 | Convert enquiry to application — creates `adm_applications` pre-filled from enquiry data | `AdmissionPipelineService::convertToApplication()` copies fields |
| 02.9 | Public-facing enquiry form (unauthenticated, no login required) reachable via school's public URL | Route outside `auth` middleware; CSRF protected; rate-limited (10/hour per IP) |

📐 **Implementation:** `EnquiryController`, `FollowUpController`, `AdmissionPipelineService`.

---

### FR-ADM-03: 📐 Admission Application Form
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** 📐 `adm_applications`, 📐 `adm_application_documents`, 📐 `adm_application_stages`

#### Description
Parent/guardian submits a comprehensive multi-step application form (online or staff-assisted) covering student details, guardian information, previous school, health info, and document uploads. Application fee is paid before the form is formally submitted.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 03.1 | Multi-step application wizard: (1) Student details (2) Guardian details (3) Previous school (4) Document upload (5) Fee payment | Progress saved after each step as Draft; resume from last step |
| 03.2 | Student personal details: first/middle/last name, DOB, gender, religion, caste/category (General/OBC/SC/ST/EWS), nationality, mother tongue, blood group, known allergies | Mandatory fields enforced per school config |
| 03.3 | Guardian details: father name/mobile/email/occupation, mother name/mobile/email, alternate guardian (if applicable) | At least one guardian mobile mandatory |
| 03.4 | Previous school details: school name, board, class passed, marks %, TC number, reason for leaving | TC number checked for duplicates across active applications |
| 03.5 | Document upload per checklist: accepts PDF/JPG/PNG, max 5 MB per file | File stored in `sys_media`; `adm_application_documents` record created; mandatory docs flagged red if missing |
| 03.6 | Application number APP-YYYY-NNNNN auto-generated on first save | UNIQUE constraint on `adm_applications.application_no` |
| 03.7 | Aadhar number optional but unique if provided; duplicate Aadhar in same cycle shows warning | UNIQUE index on `adm_applications.aadhar_no` (nullable, partial) |
| 03.8 | Quota selection: applicant self-selects quota at application time; quota validated against `adm_seat_capacity` | If selected quota is full, applicant offered waitlist slot |
| 03.9 | Application fee: generate challan with amount, due date, payment modes (Cash/Online/DD/Cheque); mark paid on confirmation | PAY module integration: online payment via Razorpay/PayU webhook; `adm_applications.application_fee_paid = 1` on success |
| 03.10 | Submit: moves status Draft → Submitted; triggers confirmation notification to parent | Status logged to `adm_application_stages`; parent notified via NTF |
| 03.11 | Application status self-tracking: parent enters application number on public page and sees current stage | Public route `/apply/status/{application_no}`; no login required |
| 03.12 | Withdrawal: applicant can withdraw application before Allotment stage; triggers refund workflow if fee paid | `WithdrawalController::store()`; refund calculated per `adm_admission_cycles.refund_policy_json` |

📐 **Implementation:** `ApplicationController`, `ApplicationDocumentController`, `WithdrawalController`, `AdmissionPipelineService`.

---

### FR-ADM-04: 📐 Application Verification & Interview Scheduling
**Priority:** High | **Status:** ❌ Not Started
**Tables:** 📐 `adm_applications`, 📐 `adm_application_documents`, 📐 `adm_application_stages`

#### Description
Admission staff review and verify each uploaded document for authenticity, approve or return the application, and schedule interview slots for shortlisted applicants.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 04.1 | Document review: staff marks each document Verified/Rejected with remarks | Per-document status; aggregate completeness shown (e.g., "4 of 5 verified") |
| 04.2 | Application approval: all mandatory documents verified → status → `Verified`; parent notified | If any mandatory doc rejected, application cannot advance |
| 04.3 | Application rejection: admin rejects with reason; parent notified; application status → `Rejected` | Rejection reason stored; stage logged |
| 04.4 | Return for correction: status → `Draft` with staff comment; parent can re-upload documents | Stage logged as `Returned`; parent portal shows remarks |
| 04.5 | Schedule interview: date, time slot, venue/room, interviewer (staff user) | SMS/email to parent with slot details; `adm_applications.interview_scheduled_at` updated |
| 04.6 | Record interview score and overall remarks post-interview | `adm_applications.interview_score` updated; used in merit calculation |
| 04.7 | Bulk verification actions on application list: approve/reject selected applications | Bulk action triggers individual stage logs for each application |

📐 **Implementation:** `ApplicationController@verify/approve/reject/scheduleInterview`, `ApplicationDocumentController@verify`.

---

### FR-ADM-05: 📐 Entrance Test Management
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** 📐 `adm_entrance_tests`, 📐 `adm_entrance_test_candidates`

#### Description
Schools may optionally conduct entrance/aptitude tests. This feature manages test scheduling, candidate list generation, hall ticket PDF generation, mark entry, and result integration into merit list calculation. NEP 2020 compliance warning prevents entrance tests for Classes 1–2.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 05.1 | Create entrance test session: name, date, time, venue, class, subject areas (JSON), max marks | Warning if class is 1 or 2 (NEP 2020); test linked to `adm_admission_cycles` |
| 05.2 | Auto-generate candidate list from all Verified applications for the target class | `adm_entrance_test_candidates` created; roll numbers auto-assigned |
| 05.3 | Generate hall ticket PDF per candidate (DomPDF): name, application no, test details, photo | Stored in `sys_media`; emailed to parent; downloadable by applicant via public tracking page |
| 05.4 | Enter marks per candidate after test; subject-wise breakdown (JSON) | `marks_obtained` and `subject_marks_json` stored; percentage computed |
| 05.5 | Entrance test marks automatically included in merit list composite score calculation | Weighted by `criteria_json` on `adm_merit_lists` |

📐 **Implementation:** `EntranceTestController`, `MeritListService::computeCompositeScore()`.

---

### FR-ADM-06: 📐 Merit List Generation & Quota-based Seat Allotment
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** 📐 `adm_merit_lists`, 📐 `adm_merit_list_entries`, 📐 `adm_allotments`

#### Description
Generate ranked merit lists per class per quota using configurable criteria weightage (entrance test %, interview %, previous academic %). Allot seats to top-ranked candidates respecting quota limits; auto-manage waitlist with automated promotion when seats are freed.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 06.1 | Configure criteria weightage per merit list: entrance test %, interview %, previous academic % (must sum to 100) | Stored in `adm_merit_lists.criteria_json`; validation enforced |
| 06.2 | Generate merit list per cycle + class + quota; candidates sorted by composite score descending | Tied scores resolved by: earlier application date; then DOB (older first) |
| 06.3 | Merit statuses: Shortlisted (within seat count), Waitlisted (beyond seat count), Rejected (below cutoff) | Cutoff configurable per merit list; Waitlist entries rank-ordered |
| 06.4 | Publish merit list: status → Published; parent notified of result via SMS/email | Published list visible on public tracking page |
| 06.5 | Allot seat: create `adm_allotments` record for Shortlisted candidate; assign class/section; update `adm_seat_capacity.seats_allotted` | Seat capacity guard prevents over-allotment |
| 06.6 | Sibling preference: sibling-flagged applications receive +5 composite score bonus before ranking | `adm_enquiries.is_sibling_lead` and `adm_applications.is_sibling` used as boost input |
| 06.7 | Waitlist auto-promotion: when an allotted student declines or offer expires, next waitlisted candidate is automatically promoted and notified | Scheduled job checks for expired offers daily; promotes next in queue |
| 06.8 | Offer letter: generate PDF (DomPDF) with school letterhead, student name, class/section, admission number, joining date | Admission number format configured in `adm_admission_cycles`; stored in `sys_media` |
| 06.9 | Offer acceptance: parent confirms acceptance online or staff marks confirmed; deadline enforced | Offer status: Offered → Accepted / Declined / Expired |

📐 **Implementation:** `MeritListController`, `AllotmentController`, `MeritListService`, `AdmissionPipelineService::promoteWaitlisted()`.

---

### FR-ADM-07: 📐 Admission Fee & Payment Confirmation
**Priority:** High | **Status:** ❌ Not Started
**Tables:** 📐 `adm_allotments`

#### Description
After offer acceptance, an admission fee invoice is generated. Payment is confirmed either manually (cash/DD) or via online payment webhook (Razorpay/PayU). Only after fee confirmation can the applicant proceed to final enrollment.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 07.1 | Generate admission fee invoice via FIN module (`fin_invoices`) with itemized components | Components: admission fee, development fee, etc.; configurable per cycle |
| 07.2 | Manual payment: finance staff marks payment received (mode, date, receipt number) | `adm_allotments.admission_fee_paid = 1`; receipt stored |
| 07.3 | Online payment: PAY module webhook sets payment status | Webhook signature verified; idempotent (re-delivery safe) |
| 07.4 | Payment confirmation advances allotment to Enrollment Queue | `adm_allotments.status → Accepted`; applicant appears in `EnrollmentController@index` |

📐 **Implementation:** `AllotmentController@confirmFee`, `AdmissionPipelineService::confirmAdmissionFee()`.

---

### FR-ADM-08: 📐 Withdrawal & Refund Workflow
**Priority:** Medium | **Status:** ❌ Not Started — 🆕 New in V2
**Tables:** 📐 `adm_withdrawals`

#### Description
An applicant or enrolled student may withdraw. The withdrawal reason is captured, a refund eligibility is computed per the cycle's refund policy, and a refund instruction is passed to the Finance module.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 08.1 | Record withdrawal: applicant/student ID, withdrawal date, reason (personal/financial/relocation/school-change/other), remarks | `adm_withdrawals` record created; status on `adm_applications` → `Withdrawn` |
| 08.2 | Compute refund eligibility: based on days since fee payment vs `adm_admission_cycles.refund_policy_json` | e.g., "100% if < 7 days; 50% if 7–30 days; 0% thereafter" — computed at withdrawal time |
| 08.3 | Initiate refund instruction to FIN module; track refund status | `adm_withdrawals.refund_status` (Pending / Approved / Paid / Not_Eligible) |
| 08.4 | After enrollment, withdrawal also closes `std_student_academic_sessions` and disables `sys_users` account | Handled in `EnrollmentService::withdraw()` |

📐 **Implementation:** `WithdrawalController`, `AdmissionPipelineService::withdrawApplication()`.

---

### FR-ADM-09: 📐 Final Enrollment Conversion
**Priority:** Critical | **Status:** ❌ Not Started
**Tables:** 📐 `adm_allotments` | **Writes to:** `sys_users`, `std_students`, `std_student_academic_sessions`

#### Description
The critical integration point: an admission-fee-paid applicant is formally enrolled. This creates permanent records in the StudentProfile module in a single atomic DB transaction. On enrollment, sibling links are established if sibling flag was set.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 09.1 | Atomic enrollment transaction: (1) Create `sys_users` (role=Student); (2) Create `std_students`; (3) Create `std_student_academic_sessions`; (4) Update `adm_allotments.status = Enrolled`; (5) Link sibling in `std_siblings_jnt` if `is_sibling = 1` | All steps in `DB::transaction()`; partial records rolled back on failure |
| 09.2 | Class/section assignment: manual or auto-balance (assign to section with lowest current enrollment) | `EnrollmentService::autoAssignSection()` compares current enrolled count across sections |
| 09.3 | Roll number: sequential within class section for the academic session, or manually overridden | UNIQUE constraint on (`class_section_id`, `academic_session_id`, `roll_no`) |
| 09.4 | Enrollment confirmation: student login credentials sent to parent mobile/email; welcome notification dispatched | Credentials generated in `EnrollmentService`; dispatched via NTF module |
| 09.5 | Enrolled student immediately visible in Attendance, Timetable, and Fee modules | `std_student_academic_sessions.is_current = 1`; consumed by other modules' queries |
| 09.6 | Bulk enrollment: enroll multiple allotted applicants in one action from the enrollment queue | Batch endpoint; per-student success/failure report returned |
| 09.7 | Physical document receipt: staff marks each original document as physically collected | `adm_application_documents.is_physically_received = 1`; profile completeness score shown |

📐 **Implementation:** `EnrollmentController`, `EnrollmentService::enrollStudent()`.

---

### FR-ADM-10: 📐 Student Promotion (Year-end)
**Priority:** High | **Status:** ❌ Not Started
**Tables:** 📐 `adm_promotion_batches`, 📐 `adm_promotion_records`

#### Description
At year-end, school admin runs a promotion wizard that fetches all active students, applies pass/fail criteria from exam results, allows manual overrides, and bulk-creates new academic session records for the upcoming year.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 10.1 | Batch creation: select current session + class(es) to process; fetch all active students | `adm_promotion_batches` created; students from `std_student_academic_sessions` loaded |
| 10.2 | Apply promotion criteria: cross-reference exam results from LmsExam module; classify Promoted/Detained/Left | Configurable pass-percentage threshold per batch; exam results joined from `exm_*` tables |
| 10.3 | Manual override: admin can change individual student classification before confirming | Override reason captured in `adm_promotion_records.remarks` |
| 10.4 | Preview / dry-run: show impact (counts promoted/detained/left) before committing | No DB writes in preview mode; displayed as summary table |
| 10.5 | Confirm batch: create new `std_student_academic_sessions` for next session; set `is_current = 1`; old records `is_current = 0` | Idempotent: re-running on Confirmed batch does not duplicate records |
| 10.6 | Roll number assignment: sequential per new class section for new session, or preserve existing | `PromotionService::assignRollNumbers()` |
| 10.7 | Detention: student stays in current class; new academic session record for same class created | Detention logged; parent notified |

📐 **Implementation:** `PromotionController`, `PromotionService`.

---

### FR-ADM-11: 📐 Alumni Management & Transfer Certificate
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** 📐 `adm_transfer_certificates`

#### Description
When a student leaves (passed out from highest class, mid-year withdrawal, or migration), they are marked as Alumni. A government-format Transfer Certificate (TC) PDF is generated with QR code for verification.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 11.1 | Mark student as Alumni: exit reason, leaving date, final remarks; closes all active academic records | `std_students.current_status_id` → Alumni; `std_student_academic_sessions.session_status_id` → Left; login disabled |
| 11.2 | Verify fees cleared before TC issuance; block TC if outstanding balance exists | `TransferCertificateService` calls FIN module balance check |
| 11.3 | Generate TC PDF (DomPDF): school letterhead, admission date, leaving date, class at leaving, conduct grade, TC serial number, QR code | TC number TC-YYYY-NNN unique per school-year; QR code links to public verification endpoint |
| 11.4 | TC history log: all issued TCs searchable by student name, TC number, year | `adm_transfer_certificates` table; indexed on `tc_number` and `student_id` |
| 11.5 | Duplicate TC: flag re-issue as duplicate; reason and fee for duplicate recorded | `adm_transfer_certificates.is_duplicate = 1`; original TC reference stored |

📐 **Implementation:** `AlumniController`, `TransferCertificateService`.

---

### FR-ADM-12: 📐 Behavior Incident Management
**Priority:** Medium | **Status:** ❌ Not Started
**Tables:** 📐 `adm_behavior_incidents`, 📐 `adm_behavior_actions`

#### Description
Class teachers and disciplinary staff log behavioral incidents for enrolled students. Severity-based escalation notifies principal/parent. Corrective actions are tracked to closure. Behavior score trend is computed over time.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 12.1 | Log incident: student ID, date, type (Bullying/Cheating/Disruption/Absenteeism/Vandalism/Violence/Misconduct/Other), severity (Low/Medium/High/Critical), description, location, witnesses | `adm_behavior_incidents` record; Critical severity auto-notifies principal and parent |
| 12.2 | Repeat offender detection: flag if same student has ≥3 incidents in current term | Badge shown on student profile; alert on log screen |
| 12.3 | Corrective action: Warning / Detention / Suspension / Expulsion / Parent_Meeting / Counseling / Community_Service with start/end dates | `adm_behavior_actions` record linked to incident |
| 12.4 | Schedule parent meeting: date-time; record meeting outcome | `adm_behavior_actions.parent_meeting_date`, `.meeting_outcome` |
| 12.5 | Behavior score: each incident deducts points per severity; cumulative score shown on student profile | Score resets at start of new academic session |
| 12.6 | Behavior analytics report: repeat offenders list, incident frequency by type/day/class, trend chart per student | `AdmissionAnalyticsController@behaviorReport` |

📐 **Implementation:** `BehaviorIncidentController`, `AdmissionAnalyticsService::computeBehaviorScore()`.

---

### FR-ADM-13: 📐 Admission Analytics Funnel
**Priority:** Medium | **Status:** ❌ Not Started — 🆕 New in V2
**Tables:** Reads from all `adm_*` tables

#### Description
A dedicated analytics dashboard presenting the full admission funnel (Enquiry → Applied → Verified → Shortlisted → Allotted → Enrolled) with conversion rates, source attribution, quota fill rates, class-wise capacity utilization, and counselor performance metrics.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 13.1 | Funnel chart: count of records at each pipeline stage per cycle | Computed by `AdmissionAnalyticsService::computeFunnel()` |
| 13.2 | Lead source breakdown: pie chart of enquiries by lead source (Website/Walk-in/Campaign/Referral/Social_Media) | Useful for marketing ROI; filterable by cycle |
| 13.3 | Quota fill report: seats total vs allotted vs enrolled per class per quota type | Reads `adm_seat_capacity` vs `adm_allotments` counts |
| 13.4 | Counselor performance: enquiries assigned, converted, application-submission rate per counselor | Filterable by date range |
| 13.5 | Class-wise capacity: total seats, applications received, shortlisted, enrolled per class | Dashboard table + bar chart |
| 13.6 | Export analytics to Excel (CSV) and PDF | `fputcsv()` for CSV; DomPDF for summary PDF |

📐 **Implementation:** `AdmissionAnalyticsController`, `AdmissionAnalyticsService`.

---

### FR-ADM-14: 📐 Sibling Preference Rules
**Priority:** Medium | **Status:** ❌ Not Started — 🆕 New in V2
**Tables:** 📐 `adm_enquiries`, 📐 `adm_applications` | **Reads:** `std_students`, `std_guardians`

#### Description
Schools routinely give admission preference to siblings of existing students. The system auto-detects sibling relationship at enquiry stage and applies a configurable priority score boost in the merit list.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 14.1 | Auto-detect sibling: on enquiry save, match `contact_mobile` against `std_guardians.phone`; if match found, set `adm_enquiries.is_sibling_lead = 1` and record matched student ID | Background check; does not block save |
| 14.2 | Confirm sibling at application stage: staff verifies sibling relationship; `adm_applications.is_sibling = 1`, `sibling_student_id` set | Manual confirmation required even if auto-detected |
| 14.3 | Merit list boost: sibling applications receive +5 composite score bonus (configurable per cycle) | Boost stored in `adm_merit_lists.sibling_bonus_score`; applied before final ranking |
| 14.4 | Staff Ward preference: applications under `Staff_Ward` quota are similarly auto-detected if parent mobile matches a staff record in `sys_users` | Sets `adm_applications.is_staff_ward = 1` |

---

### FR-ADM-15: 📐 Admission Settings & Configuration
**Priority:** High | **Status:** ❌ Not Started
**Tables:** 📐 `adm_admission_cycles`, 📐 `adm_document_checklist`, 📐 `adm_quota_config`, 📐 `adm_seat_capacity`

#### Description
Configurable settings that drive all other admission features. School admin sets these once per cycle before opening admissions.

#### Requirements

| Req | Description | Acceptance Criteria |
|-----|-------------|---------------------|
| 15.1 | Admission number format: configurable template (e.g., `{YEAR}/{CLASS_CODE}/{SEQ}`) | Format validated; preview shown; applied during enrollment |
| 15.2 | Age eligibility rules per class: min and max age on cut-off date (default June 1) | Stored in `adm_admission_cycles.age_rules_json` |
| 15.3 | Document checklist: add/edit/remove checklist items; set mandatory/optional per class level | `adm_document_checklist` seeded with defaults; school can override |
| 15.4 | Quota configuration: set total seats per class per quota type | `adm_quota_config`; sum validated against class strength |
| 15.5 | Online payment: enable/disable, select gateway (Razorpay/PayU), set application fee and admission fee | Stored in cycle config; payment gateway keys in `sys_settings` |
| 15.6 | Notification templates: configure SMS/email templates for each stage notification | Routed through NTF module template system |

---

## 5. Data Model

### 5.1 📐 Entity Overview

| Table | Description | 📐 Status |
|-------|-------------|-----------|
| `adm_admission_cycles` | Annual admission cycle config | 📐 New |
| `adm_document_checklist` | Required documents per cycle/class level | 📐 New |
| `adm_quota_config` | Quota type config per class per cycle | 📐 New |
| `adm_seat_capacity` | Per-class per-quota seat budget and fill tracking | 📐 New |
| `adm_enquiries` | Raw leads/enquiries | 📐 New |
| `adm_follow_ups` | Follow-up activity log per enquiry | 📐 New |
| `adm_applications` | Full application records | 📐 New |
| `adm_application_documents` | Uploaded documents per application | 📐 New |
| `adm_application_stages` | Stage audit trail per application | 📐 New |
| `adm_entrance_tests` | Entrance test sessions | 📐 New |
| `adm_entrance_test_candidates` | Candidate marks per test | 📐 New |
| `adm_merit_lists` | Merit list per cycle + class + quota | 📐 New |
| `adm_merit_list_entries` | Individual merit entries | 📐 New |
| `adm_allotments` | Seat allotment records | 📐 New |
| `adm_withdrawals` | Withdrawal and refund tracking | 📐 New 🆕 |
| `adm_promotion_batches` | Year-end promotion batch | 📐 New |
| `adm_promotion_records` | Per-student promotion record | 📐 New |
| `adm_transfer_certificates` | TC issuance log | 📐 New |
| `adm_behavior_incidents` | Disciplinary incident log | 📐 New |
| `adm_behavior_actions` | Corrective actions per incident | 📐 New |

### 5.2 📐 Detailed Table Specifications

---

#### `adm_admission_cycles` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `academic_session_id` | INT UNSIGNED | NOT NULL, FK→sch_org_academic_sessions_jnt | Target academic year |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Main Admission 2026-27" |
| `cycle_code` | VARCHAR(20) | NOT NULL, UNIQUE | e.g., "ADM-2627-M" |
| `start_date` | DATE | NOT NULL | Enquiry open date |
| `end_date` | DATE | NOT NULL | Enquiry close date |
| `application_fee` | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Application processing fee |
| `admission_no_format` | VARCHAR(100) | NULL DEFAULT '{YEAR}/{SEQ}' | Admission number template |
| `sibling_bonus_score` | TINYINT UNSIGNED | NOT NULL DEFAULT 5 | Merit score bonus for siblings |
| `age_rules_json` | JSON | NULL | Min/max age per class on cut-off date |
| `refund_policy_json` | JSON | NULL | Refund % tiers by days since payment |
| `application_form_url` | VARCHAR(255) | NULL | Public form URL slug |
| `status` | ENUM('Draft','Active','Closed','Archived') | NOT NULL DEFAULT 'Draft' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

**Indexes:** `idx_adm_cycles_session` (`academic_session_id`), `idx_adm_cycles_status` (`status`)

---

#### `adm_seat_capacity` 📐 New 🆕
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL | |
| `total_seats` | SMALLINT UNSIGNED | NOT NULL | |
| `seats_allotted` | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Incremented on each allotment |
| `seats_enrolled` | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | Incremented on enrollment |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Unique:** `uq_adm_seat_cap` (`admission_cycle_id`, `class_id`, `quota_type`)

---

#### `adm_document_checklist` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NULL, FK→sch_classes | NULL = all classes |
| `document_name` | VARCHAR(100) | NOT NULL | e.g., "Birth Certificate" |
| `document_code` | VARCHAR(30) | NOT NULL | e.g., "BIRTH_CERT" |
| `is_mandatory` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `accepted_formats` | VARCHAR(100) | NOT NULL DEFAULT 'pdf,jpg,png' | |
| `max_size_kb` | INT UNSIGNED | NOT NULL DEFAULT 5120 | |
| `sort_order` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_quota_config` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL | |
| `total_seats` | SMALLINT UNSIGNED | NOT NULL | |
| `reserved_seats` | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | RTE mandated minimum |
| `application_fee_waiver` | TINYINT(1) | NOT NULL DEFAULT 0 | 1 = fee waived (e.g., RTE) |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_enquiries` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `enquiry_no` | VARCHAR(20) | NOT NULL, UNIQUE | ENQ-YYYY-NNNNN |
| `student_name` | VARCHAR(100) | NOT NULL | |
| `student_dob` | DATE | NULL | For age eligibility |
| `student_gender` | ENUM('Male','Female','Transgender','Other') | NULL | |
| `class_sought_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `father_name` | VARCHAR(100) | NULL | |
| `mother_name` | VARCHAR(100) | NULL | |
| `contact_name` | VARCHAR(100) | NOT NULL | Primary contact person |
| `contact_mobile` | VARCHAR(15) | NOT NULL | |
| `contact_email` | VARCHAR(100) | NULL | |
| `lead_source` | ENUM('Website','Walk-in','Campaign','Referral','Social_Media','Phone','Other') | NOT NULL DEFAULT 'Walk-in' | |
| `status` | ENUM('New','Assigned','Contacted','Interested','Not_Interested','Callback','Converted','Duplicate') | NOT NULL DEFAULT 'New' | |
| `counselor_id` | BIGINT UNSIGNED | NULL, FK→sys_users | Assigned counselor |
| `is_sibling_lead` | TINYINT(1) | NOT NULL DEFAULT 0 | Auto-detected sibling 🆕 |
| `sibling_student_id` | INT UNSIGNED | NULL, FK→std_students | Matched existing sibling 🆕 |
| `is_duplicate` | TINYINT(1) | NOT NULL DEFAULT 0 | 🆕 |
| `notes` | TEXT | NULL | |
| `source_reference` | VARCHAR(100) | NULL | Campaign code / referral name |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_adm_enq_cycle` (`admission_cycle_id`), `idx_adm_enq_status` (`status`), `idx_adm_enq_counselor` (`counselor_id`), `idx_adm_enq_mobile` (`contact_mobile`)

---

#### `adm_follow_ups` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `enquiry_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_enquiries | |
| `follow_up_type` | ENUM('Call','Meeting','Email','SMS','Walk-in') | NOT NULL | |
| `scheduled_at` | DATETIME | NOT NULL | |
| `completed_at` | DATETIME | NULL | |
| `outcome` | ENUM('Pending','Interested','Not_Interested','Callback','Converted') | NOT NULL DEFAULT 'Pending' | |
| `notes` | TEXT | NULL | |
| `done_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `reminder_sent` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_applications` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `enquiry_id` | BIGINT UNSIGNED | NULL, FK→adm_enquiries | Source enquiry if converted |
| `application_no` | VARCHAR(20) | NOT NULL, UNIQUE | APP-YYYY-NNNNN |
| `class_applied_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL DEFAULT 'General' | |
| `is_sibling` | TINYINT(1) | NOT NULL DEFAULT 0 | Staff-confirmed sibling 🆕 |
| `sibling_student_id` | INT UNSIGNED | NULL, FK→std_students | 🆕 |
| `is_staff_ward` | TINYINT(1) | NOT NULL DEFAULT 0 | 🆕 |
| `student_first_name` | VARCHAR(50) | NOT NULL | |
| `student_middle_name` | VARCHAR(50) | NULL | |
| `student_last_name` | VARCHAR(50) | NULL | |
| `student_dob` | DATE | NOT NULL | |
| `student_gender` | ENUM('Male','Female','Transgender','Prefer Not to Say') | NOT NULL | |
| `student_religion` | VARCHAR(50) | NULL | |
| `student_caste_category` | ENUM('General','OBC','SC','ST','EWS','Other') | NULL | |
| `student_nationality` | VARCHAR(50) | NULL DEFAULT 'Indian' | |
| `student_mother_tongue` | VARCHAR(50) | NULL | |
| `aadhar_no` | VARCHAR(20) | NULL | Nullable unique |
| `birth_cert_no` | VARCHAR(50) | NULL | |
| `prev_school_name` | VARCHAR(100) | NULL | |
| `prev_class_passed` | VARCHAR(20) | NULL | |
| `prev_marks_percent` | DECIMAL(5,2) | NULL | |
| `prev_tc_no` | VARCHAR(50) | NULL | |
| `blood_group` | ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown') | NULL | |
| `known_allergies` | TEXT | NULL | |
| `father_name` | VARCHAR(100) | NULL | |
| `father_mobile` | VARCHAR(15) | NULL | |
| `father_email` | VARCHAR(100) | NULL | |
| `father_occupation` | VARCHAR(100) | NULL | |
| `mother_name` | VARCHAR(100) | NULL | |
| `mother_mobile` | VARCHAR(15) | NULL | |
| `mother_email` | VARCHAR(100) | NULL | |
| `guardian_name` | VARCHAR(100) | NULL | |
| `guardian_mobile` | VARCHAR(15) | NULL | |
| `guardian_relation` | VARCHAR(50) | NULL | |
| `address_line1` | VARCHAR(150) | NULL | |
| `address_line2` | VARCHAR(150) | NULL | |
| `city` | VARCHAR(50) | NULL | |
| `state` | VARCHAR(50) | NULL | |
| `pincode` | VARCHAR(10) | NULL | |
| `application_fee_paid` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `application_fee_amount` | DECIMAL(10,2) | NULL | |
| `application_fee_date` | DATE | NULL | |
| `interview_scheduled_at` | DATETIME | NULL | |
| `interview_venue` | VARCHAR(100) | NULL | |
| `interview_notes` | TEXT | NULL | |
| `interview_score` | DECIMAL(5,2) | NULL | |
| `status` | ENUM('Draft','Submitted','Under_Review','Verified','Shortlisted','Rejected','Waitlisted','Allotted','Enrolled','Withdrawn') | NOT NULL DEFAULT 'Draft' | |
| `rejection_reason` | TEXT | NULL | |
| `processed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_adm_app_cycle` (`admission_cycle_id`), `idx_adm_app_status` (`status`), `idx_adm_app_class` (`class_applied_id`), `idx_adm_app_aadhar` (`aadhar_no`)

---

#### `adm_application_documents` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `checklist_item_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_document_checklist | |
| `media_id` | INT UNSIGNED | NOT NULL, FK→sys_media | Uploaded file |
| `original_filename` | VARCHAR(255) | NOT NULL | |
| `verification_status` | ENUM('Pending','Verified','Rejected') | NOT NULL DEFAULT 'Pending' | |
| `verification_remarks` | TEXT | NULL | |
| `verified_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `verified_at` | TIMESTAMP | NULL | |
| `is_physically_received` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `physical_received_at` | DATE | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Unique:** `uq_adm_doc_app_checklist` (`application_id`, `checklist_item_id`)

---

#### `adm_application_stages` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `from_status` | VARCHAR(50) | NOT NULL | |
| `to_status` | VARCHAR(50) | NOT NULL | |
| `remarks` | TEXT | NULL | |
| `changed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `changed_at` | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_entrance_tests` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `test_name` | VARCHAR(100) | NOT NULL | |
| `test_date` | DATE | NOT NULL | |
| `start_time` | TIME | NOT NULL | |
| `end_time` | TIME | NOT NULL | |
| `venue` | VARCHAR(100) | NULL | |
| `max_marks` | DECIMAL(6,2) | NOT NULL | |
| `passing_marks` | DECIMAL(6,2) | NULL | |
| `subjects_json` | JSON | NULL | Subject areas with max marks |
| `status` | ENUM('Scheduled','Completed','Cancelled') | NOT NULL DEFAULT 'Scheduled' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_entrance_test_candidates` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `entrance_test_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_entrance_tests | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `roll_no` | VARCHAR(20) | NULL | Test roll number |
| `marks_obtained` | DECIMAL(6,2) | NULL | |
| `result` | ENUM('Pass','Fail','Absent','Pending') | NOT NULL DEFAULT 'Pending' | |
| `subject_marks_json` | JSON | NULL | Per-subject breakdown |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Unique:** `uq_adm_etc_test_app` (`entrance_test_id`, `application_id`)

---

#### `adm_merit_lists` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL | |
| `generated_at` | TIMESTAMP | NULL | |
| `generated_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `status` | ENUM('Draft','Published','Finalized') | NOT NULL DEFAULT 'Draft' | |
| `criteria_json` | JSON | NULL | Weightage (test_pct, interview_pct, academic_pct) |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_merit_list_entries` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `merit_list_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_merit_lists | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `merit_rank` | SMALLINT UNSIGNED | NOT NULL | |
| `composite_score` | DECIMAL(6,2) | NULL | Final score after sibling bonus |
| `entrance_score` | DECIMAL(6,2) | NULL | |
| `interview_score` | DECIMAL(6,2) | NULL | |
| `academic_score` | DECIMAL(6,2) | NULL | |
| `sibling_bonus_applied` | TINYINT(1) | NOT NULL DEFAULT 0 | 🆕 |
| `merit_status` | ENUM('Shortlisted','Waitlisted','Rejected') | NOT NULL DEFAULT 'Shortlisted' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_allotments` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `merit_list_entry_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_merit_list_entries | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `admission_no` | VARCHAR(50) | NULL, UNIQUE | Assigned on offer letter |
| `allotted_class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `allotted_section_id` | INT UNSIGNED | NULL, FK→sch_sections | |
| `joining_date` | DATE | NULL | |
| `offer_letter_media_id` | INT UNSIGNED | NULL, FK→sys_media | |
| `offer_issued_at` | TIMESTAMP | NULL | |
| `offer_expires_at` | DATE | NULL | 🆕 Offer deadline |
| `admission_fee_paid` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `admission_fee_amount` | DECIMAL(10,2) | NULL | |
| `admission_fee_date` | DATE | NULL | |
| `status` | ENUM('Offered','Accepted','Declined','Expired','Enrolled','Withdrawn') | NOT NULL DEFAULT 'Offered' | |
| `enrolled_student_id` | INT UNSIGNED | NULL, FK→std_students | Set on enrollment |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_withdrawals` 📐 New 🆕
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `allotment_id` | BIGINT UNSIGNED | NULL, FK→adm_allotments | If withdrawn after allotment |
| `withdrawal_date` | DATE | NOT NULL | |
| `reason` | ENUM('Personal','Financial','Relocation','School_Change','Medical','Other') | NOT NULL | |
| `remarks` | TEXT | NULL | |
| `fee_paid_amount` | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Total fees paid before withdrawal |
| `refund_eligible_amount` | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Computed per refund policy |
| `refund_status` | ENUM('Not_Eligible','Pending','Approved','Paid') | NOT NULL DEFAULT 'Not_Eligible' | |
| `refund_processed_at` | DATE | NULL | |
| `processed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_promotion_batches` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `from_session_id` | INT UNSIGNED | NOT NULL, FK→sch_org_academic_sessions_jnt | |
| `to_session_id` | INT UNSIGNED | NOT NULL, FK→sch_org_academic_sessions_jnt | |
| `from_class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `to_class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `criteria_json` | JSON | NULL | Pass criteria config |
| `total_students` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `promoted_count` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `detained_count` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `status` | ENUM('Draft','Confirmed') | NOT NULL DEFAULT 'Draft' | |
| `processed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `processed_at` | TIMESTAMP | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_promotion_records` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `promotion_batch_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_promotion_batches | |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `from_class_section_id` | INT UNSIGNED | NOT NULL, FK→sch_class_section_jnt | |
| `to_class_section_id` | INT UNSIGNED | NULL, FK→sch_class_section_jnt | NULL if detained |
| `new_roll_no` | SMALLINT UNSIGNED | NULL | |
| `result` | ENUM('Promoted','Detained','Transferred','Alumni','Left') | NOT NULL | |
| `remarks` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_transfer_certificates` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `tc_number` | VARCHAR(30) | NOT NULL, UNIQUE | TC-YYYY-NNN |
| `issue_date` | DATE | NOT NULL | |
| `leaving_date` | DATE | NOT NULL | |
| `class_at_leaving` | VARCHAR(30) | NOT NULL | |
| `reason_for_leaving` | TEXT | NULL | |
| `conduct` | ENUM('Excellent','Good','Satisfactory','Poor') | NOT NULL DEFAULT 'Good' | |
| `destination_school` | VARCHAR(150) | NULL | |
| `academic_status` | VARCHAR(100) | NULL | e.g., "Promoted to Class 9" |
| `fees_cleared` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `is_duplicate` | TINYINT(1) | NOT NULL DEFAULT 0 | 🆕 |
| `original_tc_id` | BIGINT UNSIGNED | NULL, FK→adm_transfer_certificates | 🆕 Reference for duplicate |
| `media_id` | INT UNSIGNED | NULL, FK→sys_media | PDF file |
| `issued_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_behavior_incidents` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `incident_date` | DATE | NOT NULL | |
| `incident_type` | ENUM('Bullying','Cheating','Disruption','Absenteeism','Vandalism','Violence','Misconduct','Other') | NOT NULL | |
| `severity` | ENUM('Low','Medium','High','Critical') | NOT NULL | |
| `description` | TEXT | NOT NULL | |
| `location` | VARCHAR(100) | NULL | |
| `witnesses_json` | JSON | NULL | Array of witness names |
| `reported_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `parent_notified` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `parent_notified_at` | TIMESTAMP | NULL | |
| `status` | ENUM('Open','Action_Taken','Closed','Escalated') | NOT NULL DEFAULT 'Open' | |
| `behavior_score_impact` | TINYINT | NOT NULL DEFAULT 0 | Points deducted (negative) |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_behavior_actions` 📐 New
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `incident_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_behavior_incidents | |
| `action_type` | ENUM('Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service') | NOT NULL | |
| `description` | TEXT | NULL | |
| `start_date` | DATE | NULL | |
| `end_date` | DATE | NULL | |
| `parent_meeting_date` | DATETIME | NULL | |
| `meeting_outcome` | TEXT | NULL | |
| `action_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

### 5.3 📐 Entity Relationship Summary

```
adm_admission_cycles
    ├── adm_document_checklist (1:M)
    ├── adm_quota_config (1:M)
    ├── adm_seat_capacity (1:M) 🆕
    ├── adm_enquiries (1:M)
    │       └── adm_follow_ups (1:M)
    ├── adm_applications (1:M)
    │       ├── adm_application_documents (1:M)
    │       ├── adm_application_stages (1:M)
    │       └── adm_withdrawals (1:1) 🆕
    ├── adm_entrance_tests (1:M)
    │       └── adm_entrance_test_candidates (1:M) ←→ adm_applications
    └── adm_merit_lists (1:M)
            └── adm_merit_list_entries (1:M) ←→ adm_applications
                    └── adm_allotments (1:1)
                            └── std_students [WRITES ON ENROLLMENT]

adm_promotion_batches
    └── adm_promotion_records (1:M) ←→ std_students

std_students ←→ adm_transfer_certificates (1:M)
std_students ←→ adm_behavior_incidents (1:M)
    └── adm_behavior_actions (1:M)
```

### 5.4 📐 Migration Order

1. `adm_admission_cycles`
2. `adm_document_checklist`
3. `adm_quota_config`
4. `adm_seat_capacity` 🆕
5. `adm_enquiries`
6. `adm_follow_ups`
7. `adm_applications`
8. `adm_application_documents`
9. `adm_application_stages`
10. `adm_entrance_tests`
11. `adm_entrance_test_candidates`
12. `adm_merit_lists`
13. `adm_merit_list_entries`
14. `adm_allotments`
15. `adm_withdrawals` 🆕
16. `adm_promotion_batches`
17. `adm_promotion_records`
18. `adm_transfer_certificates`
19. `adm_behavior_incidents`
20. `adm_behavior_actions`

---

## 6. API Endpoints & Routes

### 6.1 📐 Web Routes Summary

| # | Method | URI | Controller@Method | Route Name |
|---|--------|-----|-------------------|------------|
| 1 | GET | `/admission` | AdmissionDashboardController@index | adm.dashboard |
| 2 | GET | `/admission/enquiries` | EnquiryController@index | adm.enquiries.index |
| 3 | GET | `/admission/enquiries/create` | EnquiryController@create | adm.enquiries.create |
| 4 | POST | `/admission/enquiries` | EnquiryController@store | adm.enquiries.store |
| 5 | GET | `/admission/enquiries/{id}` | EnquiryController@show | adm.enquiries.show |
| 6 | PATCH | `/admission/enquiries/{id}` | EnquiryController@update | adm.enquiries.update |
| 7 | POST | `/admission/enquiries/{id}/assign` | EnquiryController@assign | adm.enquiries.assign |
| 8 | POST | `/admission/enquiries/{id}/convert` | EnquiryController@convert | adm.enquiries.convert |
| 9 | POST | `/admission/enquiries/{id}/follow-ups` | FollowUpController@store | adm.followups.store |
| 10 | PATCH | `/admission/enquiries/{id}/follow-ups/{fid}` | FollowUpController@update | adm.followups.update |
| 11 | GET | `/admission/applications` | ApplicationController@index | adm.applications.index |
| 12 | POST | `/admission/applications` | ApplicationController@store | adm.applications.store |
| 13 | GET | `/admission/applications/{id}` | ApplicationController@show | adm.applications.show |
| 14 | PATCH | `/admission/applications/{id}` | ApplicationController@update | adm.applications.update |
| 15 | POST | `/admission/applications/{id}/submit` | ApplicationController@submit | adm.applications.submit |
| 16 | POST | `/admission/applications/{id}/verify` | ApplicationController@verify | adm.applications.verify |
| 17 | POST | `/admission/applications/{id}/approve` | ApplicationController@approve | adm.applications.approve |
| 18 | POST | `/admission/applications/{id}/reject` | ApplicationController@reject | adm.applications.reject |
| 19 | POST | `/admission/applications/{id}/schedule-interview` | ApplicationController@scheduleInterview | adm.applications.scheduleInterview |
| 20 | POST | `/admission/applications/{id}/withdraw` | WithdrawalController@store | adm.applications.withdraw |
| 21 | POST | `/admission/applications/{id}/documents` | ApplicationDocumentController@store | adm.documents.store |
| 22 | PATCH | `/admission/documents/{id}/verify` | ApplicationDocumentController@verify | adm.documents.verify |
| 23 | DELETE | `/admission/documents/{id}` | ApplicationDocumentController@destroy | adm.documents.destroy |
| 24 | GET | `/admission/entrance-tests` | EntranceTestController@index | adm.entrance-tests.index |
| 25 | POST | `/admission/entrance-tests` | EntranceTestController@store | adm.entrance-tests.store |
| 26 | POST | `/admission/entrance-tests/{id}/marks` | EntranceTestController@enterMarks | adm.entrance-tests.marks |
| 27 | GET | `/admission/merit-lists` | MeritListController@index | adm.merit-lists.index |
| 28 | POST | `/admission/merit-lists/generate` | MeritListController@generate | adm.merit-lists.generate |
| 29 | POST | `/admission/merit-lists/{id}/publish` | MeritListController@publish | adm.merit-lists.publish |
| 30 | GET | `/admission/allotments` | AllotmentController@index | adm.allotments.index |
| 31 | POST | `/admission/allotments` | AllotmentController@store | adm.allotments.store |
| 32 | POST | `/admission/allotments/{id}/offer-letter` | AllotmentController@generateOffer | adm.allotments.offer |
| 33 | POST | `/admission/allotments/{id}/confirm-fee` | AllotmentController@confirmFee | adm.allotments.confirmFee |
| 34 | GET | `/admission/enrollment` | EnrollmentController@index | adm.enrollment.index |
| 35 | POST | `/admission/enrollment/{allotment}/enroll` | EnrollmentController@enroll | adm.enrollment.enroll |
| 36 | POST | `/admission/enrollment/bulk` | EnrollmentController@bulkEnroll | adm.enrollment.bulk |
| 37 | GET | `/admission/promotions` | PromotionController@index | adm.promotions.index |
| 38 | POST | `/admission/promotions/preview` | PromotionController@preview | adm.promotions.preview |
| 39 | POST | `/admission/promotions/confirm` | PromotionController@confirm | adm.promotions.confirm |
| 40 | GET | `/admission/alumni` | AlumniController@index | adm.alumni.index |
| 41 | POST | `/admission/alumni/{id}/mark` | AlumniController@markAlumni | adm.alumni.mark |
| 42 | POST | `/admission/alumni/{id}/tc` | AlumniController@issueTc | adm.alumni.tc |
| 43 | GET | `/admission/alumni/{id}/tc/download` | AlumniController@downloadTc | adm.alumni.tc.download |
| 44 | GET | `/admission/behavior` | BehaviorIncidentController@index | adm.behavior.index |
| 45 | POST | `/admission/behavior` | BehaviorIncidentController@store | adm.behavior.store |
| 46 | POST | `/admission/behavior/{id}/action` | BehaviorIncidentController@addAction | adm.behavior.action |
| 47 | GET | `/admission/analytics` | AdmissionAnalyticsController@funnel | adm.analytics.funnel |
| P1 | GET | `/apply/{slug}` | ApplicationController@publicForm | adm.public.form |
| P2 | POST | `/apply/{slug}` | ApplicationController@publicSubmit | adm.public.submit |
| P3 | GET | `/apply/status/{app_no}` | ApplicationController@trackStatus | adm.public.track |

### 6.2 📐 API Routes Summary (REST)

| Method | URI | Description |
|--------|-----|-------------|
| GET | `/api/v1/admission/pipeline` | Funnel counts per stage |
| GET | `/api/v1/admission/enquiries` | Enquiry list (paginated) |
| POST | `/api/v1/admission/enquiries` | Create enquiry |
| GET | `/api/v1/admission/applications/{id}/status` | Application status for parent app |
| POST | `/api/v1/admission/enrollment` | Enroll applicant (programmatic) |
| GET | `/api/v1/admission/seat-availability` | Available seats per class per quota |
| POST | `/api/v1/admission/payment/webhook` | PAY module payment confirmation webhook |

### 6.3 📐 Route Group Sketch

```php
// Public routes — no auth required
Route::prefix('apply')->name('adm.public.')->group(function () {
    Route::get('/{slug}', [ApplicationController::class, 'publicForm'])->name('form');
    Route::post('/{slug}', [ApplicationController::class, 'publicSubmit'])->name('submit');
    Route::get('/status/{applicationNo}', [ApplicationController::class, 'trackStatus'])->name('track');
})->middleware(['throttle:10,1']); // rate limit: 10/min

// Authenticated tenant routes
Route::middleware(['auth', 'tenant'])->prefix('admission')->name('adm.')->group(function () {
    Route::get('/', [AdmissionDashboardController::class, 'index'])->name('dashboard');
    // ... (enquiries, applications, allotments, enrollment, promotions, alumni, behavior)
});

// API routes
Route::middleware(['auth:sanctum', 'tenant'])->prefix('api/v1/admission')->group(function () {
    // REST endpoints as above
    Route::post('/payment/webhook', [AllotmentController::class, 'paymentWebhook'])
         ->withoutMiddleware(['auth:sanctum']); // Webhook: verified by signature only
});
```

---

## 7. UI Screens

| # | Screen Name | Route | Key Elements |
|---|-------------|-------|--------------|
| 1 | Admission Dashboard | adm.dashboard | Kanban pipeline, funnel chart, seat fill meters, today's follow-ups |
| 2 | Enquiry List | adm.enquiries.index | Table: status, counselor, class, sibling badge, source; filters |
| 3 | New Enquiry (Walk-in) | adm.enquiries.create | Student name/DOB, parent contact, class sought, lead source, age warning |
| 4 | Enquiry Detail | adm.enquiries.show | Lead timeline, follow-up log, convert-to-application button |
| 5 | Public Enquiry/Application Form | adm.public.form | Multi-step wizard: student → guardian → prev school → documents → fee; mobile-responsive |
| 6 | Application Status Tracker | adm.public.track | Parent enters app no; displays current stage badge with description |
| 7 | Application List | adm.applications.index | Filters: cycle, class, quota, status; bulk approve/reject actions |
| 8 | Application Detail & Review | adm.applications.show | Full form view + document viewer + verification checkboxes + stage history |
| 9 | Interview Scheduler | — | Date/time picker, venue, interviewer dropdown; SMS preview before send |
| 10 | Entrance Test List | adm.entrance-tests.index | Sessions per cycle; hall ticket bulk download button |
| 11 | Mark Entry | adm.entrance-tests.marks | Spreadsheet-style grid; subject columns; auto-total |
| 12 | Merit List | adm.merit-lists.index | Ranked list with score breakdown columns; quota tab filter; publish button |
| 13 | Seat Allotment | adm.allotments.index | Shortlisted candidates; allot/waitlist actions; seat fill gauge |
| 14 | Offer Letter Preview | adm.allotments.offer | PDF preview with school letterhead before send; email/download buttons |
| 15 | Withdrawal Form | — | Reason dropdown, remarks; computed refund amount displayed before submit |
| 16 | Enrollment Queue | adm.enrollment.index | Admission-fee-paid applicants awaiting enrollment; bulk enroll button |
| 17 | Enrollment Confirm | adm.enrollment.enroll | Class/section (with fill count), roll number (auto-suggested), confirmation checklist |
| 18 | Promotion Wizard Step 1 | adm.promotions.index | Select session + class(es); load students button |
| 19 | Promotion Wizard Step 2 | adm.promotions.preview | Student table with Promoted/Detained/Left radio per row; summary counts |
| 20 | Promotion Wizard Step 3 | adm.promotions.confirm | Section mapping, roll number assignment; final confirm button |
| 21 | Alumni Register | adm.alumni.index | Filterable alumni table; year/class filters; TC issue button |
| 22 | TC Issuance | adm.alumni.tc | TC form with fee-clearance check; PDF preview; QR code displayed |
| 23 | Behavior Incidents | adm.behavior.index | Incident list; severity badges; add-incident button |
| 24 | Behavior Report | adm.behavior.report | Repeat offenders, frequency chart, behavior score trend per student |
| 25 | Analytics Funnel | adm.analytics.funnel | Funnel chart, source pie, quota fill table, counselor table; export buttons |

---

## 8. Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-ADM-001 | Age eligibility: configurable min/max age per class on cut-off date (default June 1) | Validation in `StoreEnquiryRequest` and `StoreApplicationRequest` |
| BR-ADM-002 | Enrollment is atomic: `sys_users` + `std_students` + `std_student_academic_sessions` created in single DB transaction | `EnrollmentService::enrollStudent()` in `DB::transaction()` |
| BR-ADM-003 | Admission number unique within school-year; format school-configurable | UNIQUE on `adm_allotments.admission_no`; also on `std_students.admission_no` |
| BR-ADM-004 | TC only after all outstanding fees cleared | `TransferCertificateService` checks FIN module balance |
| BR-ADM-005 | RTE quota: 25% of Class 1 seats reserved for EWS; RTE applicants exempt from application fee | `adm_quota_config.application_fee_waiver = 1` for RTE |
| BR-ADM-006 | Application fee is non-refundable once paid (by default); refund policy per cycle overrides | `adm_admission_cycles.refund_policy_json` configures exceptions |
| BR-ADM-007 | All mandatory documents must be uploaded before application can move Submitted → Verified | `AdmissionPipelineService::verifyApplication()` checks mandatory docs |
| BR-ADM-008 | Roll numbers unique within class section per academic session | UNIQUE on (`class_section_id`, `academic_session_id`, `roll_no`) |
| BR-ADM-009 | Promotion creates new `std_student_academic_sessions` for next year; does not modify current year records | `PromotionService` appends; old record `is_current = 0` |
| BR-ADM-010 | One enrollment per student per academic session | UNIQUE on `std_student_academic_sessions` (`student_id`, `academic_session_id`) |
| BR-ADM-011 | NEP 2020: entrance tests not allowed for Classes 1–2 | Validation warning (non-blocking) if entrance test configured for Class 1 or 2 |
| BR-ADM-012 | Aadhar number optional but unique when provided | Partial UNIQUE index on `adm_applications.aadhar_no` where NOT NULL |
| BR-ADM-013 | Seat capacity guard: allotment blocked if `seats_allotted >= total_seats` for selected quota | `MeritListService::allotSeat()` checks `adm_seat_capacity` before insert |
| BR-ADM-014 | Offer expires after N days (configurable per cycle); expired offers auto-trigger next waitlisted candidate | Scheduled job (daily) finds expired offers; calls `AdmissionPipelineService::promoteWaitlisted()` |
| BR-ADM-015 | Sibling priority: configurable bonus score applied in merit ranking; staff must confirm sibling before benefit applies | `adm_applications.is_sibling` must be `1` (staff-confirmed); auto-detect alone insufficient |

---

## 9. Workflows & State Machines

### 9.1 Application Lifecycle FSM

```
[Draft]
  │
  ├─(fee paid + submit)──────────────► [Submitted]
  │                                        │
  │                    ┌───────────────────┤
  │                    ▼                   ▼
  │              (docs OK)          (docs incomplete)
  │             [Verified]          return to [Draft]
  │                 │
  │         ┌───────┴───────────┐
  │         ▼                   ▼
  │    [Shortlisted]        [Rejected]
  │         │
  │    ┌────┴────┐
  │    ▼         ▼
  │ [Allotted] [Waitlisted]
  │    │           │
  │    │     (seat freed)──► [Allotted]
  │    │
  │ (offer accepted + adm fee paid)
  │    │
  │    ▼
  │ [Enrolled] ✅
  │
  └─(any stage before Enrolled)──► [Withdrawn]
```

### 9.2 Enquiry Lead FSM

```
[New]
  └─(assigned)──► [Assigned]
       └─(first contact)──► [Contacted]
              ├──► [Interested] ──(form started)──► [Converted] ✅
              ├──► [Not_Interested] (closed)
              ├──► [Callback] ──(rescheduled)──► [Contacted]
              └──► [Duplicate] (merged/closed)
```

### 9.3 Allotment Offer FSM

```
[Offered]
  ├─(accepted by parent)──────────────────► [Accepted]
  │       └─(admission fee paid)──► moves to enrollment queue
  ├─(parent declines)────────────────────► [Declined]
  │       └─(seat freed → next waitlisted promoted)
  └─(offer_expires_at passed, no response)─► [Expired]
          └─(scheduled job → next waitlisted promoted)
```

### 9.4 Promotion Batch FSM

```
[Draft]
  └─(admin reviews, optionally edits)──► [Confirmed] ✅
       (std_student_academic_sessions records created for new session)
```

### 9.5 Withdrawal & Refund FSM

```
[Not_Eligible] — default if fee not paid
[Pending]       — fee was paid; refund computation done
  ├──► [Approved]   — finance approves refund
  │       └──► [Paid]   — refund disbursed
  └──► [Not_Eligible] — beyond refund window
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Public enquiry form < 2s page load; enrollment transaction < 5s; merit list generation for 1,000 applicants < 10s |
| Scalability | Support 5,000 applications per cycle per tenant; support concurrent peak during admission season (Feb–May) |
| Security | Application documents stored in private storage (not publicly accessible); Aadhar numbers encrypted at rest (AES-256); public form rate-limited (10 submissions/hour/IP) |
| Availability | Admission portal 99.9% uptime during peak months; auto-retry on payment webhook delivery failure (3 attempts) |
| Data Integrity | All application status transitions logged in `adm_application_stages`; enrollment is transactional with rollback on failure |
| Accessibility | Public form WCAG 2.1 AA compliant; Bootstrap 5 responsive layout; keyboard-navigable multi-step wizard |
| Audit | All enrollment, TC issuance, and promotion actions recorded in `sys_activity_logs` |
| Localisation | Application form supports English and regional language (Hindi, Marathi, etc.) via `glb_translations` |
| Payment | Online payment webhook must be idempotent (safe to replay duplicate webhook events) |
| GDPR/PDPB | Parent consent checkbox on public form; Aadhar data access restricted to authorized roles only |

---

## 11. Dependencies

### 11.1 Modules This Module Depends On

| Module | Tables / Events Used | Reason |
|--------|---------------------|--------|
| SystemConfig | `sys_users`, `sys_roles`, `sys_media`, `sys_dropdown_table`, `sys_activity_logs`, `sys_settings` | Auth, RBAC, file uploads, dropdowns, audit, payment keys |
| SchoolSetup | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt`, `sch_organizations` | Class/section selection; session for enrollment and promotion |
| StudentProfile | `std_students`, `std_student_academic_sessions`, `std_guardians`, `std_siblings_jnt` | Enrollment writes here; sibling link; promotion updates here |
| StudentFee (FIN) | `fin_invoices`, `fin_fee_structures` | Application fee and admission fee invoice generation |
| Payment (PAY) | Webhook events, payment intent creation | Online fee payment for application and admission fee |
| Notification (NTF) | Event-driven SMS/email dispatch | Stage transition notifications to parents at each key step |
| GlobalMaster (GLB) | `glb_countries`, `glb_states`, `glb_boards` | Address dropdowns, board for previous school info |
| LmsExam (EXM) | `exm_*` result tables | Promotion criteria: cross-reference pass/fail from exam results |

### 11.2 Modules That Depend on ADM

| Module | Dependency |
|--------|-----------|
| StudentProfile | Reads enrollment data seeded by ADM; student record source of truth starts here |
| Attendance | Requires enrolled students from `std_student_academic_sessions` with `is_current = 1` |
| StudentFee | Student fee assignments depend on enrolled student records from ADM |
| LmsExam | Exam results feed back into ADM promotion criteria |
| Timetable | Class strength counts depend on enrolled student count per class section |
| ParentPortal | Parent account creation triggered on enrollment by ADM |

### 11.3 📐 Phased Implementation Order

| Phase | Scope | Prerequisites |
|-------|-------|---------------|
| Phase 1 | Cycle config + Enquiry + Follow-up + Application + Documents | SystemConfig, SchoolSetup, GLB done |
| Phase 2 | Document verification + Interview + Entrance Test + Merit List + Seat Allotment | Phase 1 done |
| Phase 3 | Offer Letter + Admission Fee + Online Payment webhook | PAY module available; Phase 2 done |
| Phase 4 | Enrollment conversion (writes std_students) + Sibling linking | STD module ready; Phase 3 done |
| Phase 5 | Withdrawal + Refund workflow | FIN module available; Phase 4 done |
| Phase 6 | Promotion Wizard + Alumni + TC | LmsExam results available; Phase 4 done |
| Phase 7 | Behavior Incidents + Analytics Funnel | Phase 4 done |

---

## 12. Test Scenarios

| # | Test Name | Description | Type | Priority |
|---|-----------|-------------|------|----------|
| 1 | EnquiryCreationTest | Valid enquiry → ENQ number assigned, notification dispatched | Feature | Critical |
| 2 | AgeEligibilityWarningTest | DOB underage for Class 1 → warning shown, submission not blocked | Feature | High |
| 3 | SiblingAutoDetectTest | Enquiry mobile matches existing guardian → `is_sibling_lead = 1` set | Feature | High |
| 4 | DuplicateMobileEnquiryTest | Same mobile submitted twice in same cycle → duplicate warning shown | Feature | Medium |
| 5 | PublicFormSubmissionTest | Unauthenticated user submits enquiry via public URL → record created | Feature | Critical |
| 6 | ApplicationNumberGenerationTest | Submit application → APP-YYYY-NNNNN format, unique | Unit | High |
| 7 | DuplicateAadharTest | Two applications same Aadhar in same cycle → validation warning | Feature | High |
| 8 | DocumentUploadTest | Upload PDF document against checklist → sys_media stored, adm_application_documents created | Feature | High |
| 9 | ApplicationStatusTransitionTest | Each stage change → `adm_application_stages` record logged | Feature | High |
| 10 | MandatoryDocumentBlockTest | Application cannot advance to Verified if mandatory doc missing | Feature | High |
| 11 | MeritListGenerationTest | Generate merit list → entries ranked by composite score; sibling bonus applied | Unit | High |
| 12 | QuotaSeatCapacityGuardTest | Allot beyond quota seats → error returned | Feature | Critical |
| 13 | WaitlistAutoPromotionTest | Allotted student declines → next waitlisted promoted, notified | Feature | High |
| 14 | OfferExpiryJobTest | offer_expires_at passed → scheduled job sets Expired, promotes next waitlisted | Feature | Medium |
| 15 | EnrollmentAtomicTest | Enrollment success → sys_users + std_students + std_student_academic_sessions all created | Feature | Critical |
| 16 | EnrollmentRollbackTest | DB error mid-enrollment transaction → no partial records persisted | Feature | Critical |
| 17 | DuplicateEnrollmentTest | Enroll same student twice in same session → unique constraint violation | Feature | High |
| 18 | AutoSectionBalanceTest | Auto-assign section picks section with lowest current enrollment | Unit | Medium |
| 19 | WithdrawalRefundComputeTest | Withdraw 3 days after fee payment → 100% refund eligible per policy | Unit | Medium |
| 20 | BulkPromotionTest | Promote 50 students → all get new `std_student_academic_sessions` for next year | Feature | High |
| 21 | DetainedStudentTest | Detained student stays in current class; new session record same class | Feature | High |
| 22 | TransferCertificateTest | Issue TC → PDF generated, TC number unique per year | Feature | Medium |
| 23 | TCOutstandingFeeBlockTest | Issue TC with outstanding fee balance → blocked with error | Feature | High |
| 24 | BehaviorIncidentCriticalTest | Critical incident logged → principal notification auto-dispatched | Feature | Medium |
| 25 | PaymentWebhookIdempotencyTest | Same webhook delivered twice → fee marked paid only once | Feature | High |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Admission Cycle | A defined period during which the school accepts applications for a specific academic year |
| Application Fee | Non-refundable processing fee paid when submitting an admission application (configurable exception via refund policy) |
| Admission Fee | Fee paid after seat allotment to confirm the student's place (separate from application fee) |
| Allotment | Official assignment of a seat in a class/section to a shortlisted applicant |
| Counselor | School staff responsible for managing leads and guiding parents through the admission process |
| Merit List | Ranked list of applicants generated based on configurable criteria (entrance test, interview, academic history) |
| Quota | Reserved category of seats — General, Government, Management, RTE, NRI, Staff Ward, Sibling, EWS |
| TC (Transfer Certificate) | Official document issued when a student leaves; required for admission to another school |
| Alumni | A student who has passed out of the highest class or voluntarily left the school |
| Promotion | Year-end process of moving eligible students to the next class for the upcoming academic session |
| Detention | Retaining a student in the same class due to failure to meet promotion criteria |
| RTE | Right to Education Act (2009): mandates 25% reservation for EWS students in Classes 1–8 in private unaided schools |
| NEP 2020 | National Education Policy 2020: governs curriculum norms; prohibits formal entrance tests for foundational stage (Classes 1–2) |
| APAAR ID | Academic Bank of Credits Automated Permanent Academic Account Registry — national student ID under NEP 2020 |
| EWS | Economically Weaker Section — income-based category for fee concession and quota eligibility |
| Sibling Preference | Priority given to applicants whose sibling already studies in the school |
| Waitlist | Reserve list of applicants ranked below the allotment cut-off; automatically promoted when seats are freed |

---

## 14. Suggestions

The following are analyst recommendations outside the current RBS scope that would significantly enhance ADM:

1. **Online Payment Gateway Integration:** Application fee and admission fee should support Razorpay/PayU integration so parents can pay online. The V2 data model accommodates this via `adm_admission_cycles` payment config and the webhook route. This reduces front-office load by ~60%.

2. **UDISE-compatible Export:** Indian schools must submit admission data to state education departments annually. A PDF/Excel export in UDISE (Unified District Information System for Education) format would be a high-value, compliance-critical addition.

3. **Sibling Discount Auto-trigger:** When enrollment creates the sibling link in `std_siblings_jnt`, automatically notify the FIN module to apply the configured sibling fee discount on the enrolled student's fee structure.

4. **Interview Slot Calendar View:** The interview scheduling screen would benefit from a week-view calendar (similar to Timetable module's slot picker) showing available rooms and interviewer free slots, preventing double-booking.

5. **Hall Ticket Bulk Print:** After entrance test candidate list is generated, a bulk DomPDF hall ticket generation job (queued) would eliminate manual effort for large batches.

6. **APAAR ID Capture:** NEP 2020 mandates APAAR ID for all students. Add `apaar_id` to `adm_applications` and propagate to `std_students` on enrollment to future-proof compliance.

7. **Behavior Module Separation:** The behavior assessment features (Section FR-ADM-12) are logically distinct from the admission funnel. Consider extracting them into a standalone `BEH` (Behavioral Assessment) module in a future iteration to keep ADM focused on the admission pipeline and reduce module complexity.

8. **CRM Integration Hooks:** For large school groups managing multiple campuses, expose admission pipeline data via API so external CRM tools (e.g., Salesforce, Zoho) can pull enquiry and conversion data for group-level reporting.

---

## 15. Appendices

### Appendix A — RBS Module C Reference (ADM scope)

```
Module C — Admissions & Student Lifecycle (56 sub-tasks)

C1 — Enquiry & Lead Management
  F.C1.1 — Lead Capture | T.C1.1.1 Record Enquiry | T.C1.1.2 Lead Assignment
  F.C1.2 — Lead Follow-up | T.C1.2.1 Follow-up Scheduling | T.C1.2.2 Lead Status

C2 — Application Management
  F.C2.1 — Application Form | T.C2.1.1 Create Application | T.C2.1.2 Application Fees
  F.C2.2 — Application Processing | T.C2.2.1 Verification | T.C2.2.2 Interview Scheduling

C3 — Admission Management
  F.C3.1 — Admission Offer | T.C3.1.1 Offer Letter | T.C3.1.2 Admission Fee Collection
  F.C3.2 — Finalize Admission | T.C3.2.1 Complete Enrollment | T.C3.2.2 Document Submission

C4 — Student Profile & Records
  F.C4.1 — Student Profile | T.C4.1.1 Create Profile | T.C4.1.2 Maintain Records
  F.C4.2 — Student Documents | T.C4.2.1 Upload Documents | T.C4.2.2 Document Verification

C5 — Student Promotion & Alumni
  F.C5.1 — Promotion Processing | T.C5.1.1 Generate Promotion List | T.C5.1.2 Assign New Class
  F.C5.2 — Alumni Management | T.C5.2.1 Mark as Alumni | T.C5.2.2 Issue Transfer Certificate

C6 — Syllabus Management — [Deferred to SLB module]

C7 — Behavior Assessment
  F.C7.1 — Incident Management | T.C7.1.1 Record Incident | T.C7.1.2 Action & Follow-up
  F.C7.2 — Behavior Analytics | T.C7.2.1 Generate Reports
```

### Appendix B — V2 New Tables Summary

| Table | Why Added in V2 |
|-------|----------------|
| `adm_seat_capacity` | Explicit per-class per-quota seat budget tracking with live fill counters; V1 only had `adm_quota_config.total_seats` without real-time tracking |
| `adm_withdrawals` | Withdrawal and refund workflow was missing in V1; needed for complete admission lifecycle and FIN integration |

### Appendix C — 📐 Proposed File List (Module Scaffold)

```
Modules/Admission/
├── app/Http/Controllers/
│   ├── AdmissionDashboardController.php     [📐 Proposed]
│   ├── EnquiryController.php                [📐 Proposed]
│   ├── FollowUpController.php               [📐 Proposed]
│   ├── ApplicationController.php            [📐 Proposed]
│   ├── ApplicationDocumentController.php    [📐 Proposed]
│   ├── EntranceTestController.php           [📐 Proposed]
│   ├── MeritListController.php              [📐 Proposed]
│   ├── AllotmentController.php              [📐 Proposed]
│   ├── WithdrawalController.php             [📐 Proposed] 🆕
│   ├── EnrollmentController.php             [📐 Proposed]
│   ├── PromotionController.php              [📐 Proposed]
│   ├── AlumniController.php                 [📐 Proposed]
│   ├── BehaviorIncidentController.php       [📐 Proposed]
│   └── AdmissionAnalyticsController.php     [📐 Proposed] 🆕
├── app/Http/Requests/
│   ├── StoreEnquiryRequest.php              [📐 Proposed]
│   ├── StoreApplicationRequest.php          [📐 Proposed]
│   ├── UploadDocumentRequest.php            [📐 Proposed]
│   ├── StoreEntranceTestRequest.php         [📐 Proposed]
│   ├── StoreAllotmentRequest.php            [📐 Proposed]
│   ├── StoreWithdrawalRequest.php           [📐 Proposed] 🆕
│   ├── EnrollStudentRequest.php             [📐 Proposed]
│   ├── PromoteStudentsRequest.php           [📐 Proposed]
│   ├── IssueTcRequest.php                   [📐 Proposed]
│   └── StoreIncidentRequest.php             [📐 Proposed]
├── app/Models/
│   ├── AdmissionCycle.php                   [📐 Proposed]
│   ├── SeatCapacity.php                     [📐 Proposed] 🆕
│   ├── DocumentChecklist.php                [📐 Proposed]
│   ├── QuotaConfig.php                      [📐 Proposed]
│   ├── Enquiry.php                          [📐 Proposed]
│   ├── FollowUp.php                         [📐 Proposed]
│   ├── Application.php                      [📐 Proposed]
│   ├── ApplicationDocument.php              [📐 Proposed]
│   ├── ApplicationStage.php                 [📐 Proposed]
│   ├── EntranceTest.php                     [📐 Proposed]
│   ├── EntranceTestCandidate.php            [📐 Proposed]
│   ├── MeritList.php                        [📐 Proposed]
│   ├── MeritListEntry.php                   [📐 Proposed]
│   ├── Allotment.php                        [📐 Proposed]
│   ├── Withdrawal.php                       [📐 Proposed] 🆕
│   ├── PromotionBatch.php                   [📐 Proposed]
│   ├── PromotionRecord.php                  [📐 Proposed]
│   ├── TransferCertificate.php              [📐 Proposed]
│   ├── BehaviorIncident.php                 [📐 Proposed]
│   └── BehaviorAction.php                   [📐 Proposed]
├── app/Services/
│   ├── AdmissionPipelineService.php         [📐 Proposed]
│   ├── EnrollmentService.php                [📐 Proposed]
│   ├── MeritListService.php                 [📐 Proposed]
│   ├── PromotionService.php                 [📐 Proposed]
│   ├── TransferCertificateService.php       [📐 Proposed]
│   └── AdmissionAnalyticsService.php        [📐 Proposed] 🆕
├── app/Jobs/
│   └── PromoteExpiredOffersJob.php          [📐 Proposed] 🆕
├── app/Policies/
│   ├── EnquiryPolicy.php                    [📐 Proposed]
│   ├── ApplicationPolicy.php                [📐 Proposed]
│   ├── AllotmentPolicy.php                  [📐 Proposed]
│   └── EnrollmentPolicy.php                 [📐 Proposed]
├── database/migrations/                     [📐 20 migrations]
├── database/seeders/
│   ├── AdmissionDocumentChecklistSeeder.php [📐 Proposed]
│   └── AdmissionQuotaSeeder.php             [📐 Proposed]
├── resources/views/
│   ├── dashboard/
│   ├── enquiries/
│   ├── applications/
│   ├── entrance-tests/
│   ├── allotment/
│   ├── withdrawal/                          [📐 New 🆕]
│   ├── enrollment/
│   ├── promotions/
│   ├── alumni/
│   ├── behavior/
│   ├── analytics/                           [📐 New 🆕]
│   └── partials/
└── routes/
    ├── web.php
    └── api.php
```

---

## 16. V1 → V2 Delta

| Change Type | Item | Details |
|-------------|------|---------|
| 🆕 New Table | `adm_seat_capacity` | Explicit per-class per-quota seat budget with live fill counters; replaces static `adm_quota_config.total_seats` for runtime tracking |
| 🆕 New Table | `adm_withdrawals` | Full withdrawal and refund workflow not present in V1 |
| 🆕 New FR | FR-ADM-08: Withdrawal & Refund | Withdrawal reason, refund policy JSON, refund status lifecycle |
| 🆕 New FR | FR-ADM-13: Admission Analytics Funnel | Funnel conversion chart, lead source breakdown, quota fill, counselor metrics |
| 🆕 New FR | FR-ADM-14: Sibling Preference Rules | Auto-detect sibling at enquiry stage; bonus score in merit ranking; staff_ward auto-detect |
| 🆕 New Columns | `adm_enquiries` | `is_sibling_lead`, `sibling_student_id`, `is_duplicate` |
| 🆕 New Columns | `adm_applications` | `is_sibling`, `sibling_student_id`, `is_staff_ward` |
| 🆕 New Columns | `adm_allotments` | `offer_expires_at`, `Withdrawn` status enum value |
| 🆕 New Columns | `adm_admission_cycles` | `admission_no_format`, `sibling_bonus_score`, `age_rules_json`, `refund_policy_json` |
| 🆕 New Columns | `adm_merit_list_entries` | `sibling_bonus_applied` |
| 🆕 New Columns | `adm_transfer_certificates` | `is_duplicate`, `original_tc_id` |
| 🆕 New FR Enhancement | FR-ADM-06.7 | Waitlist auto-promotion via `PromoteExpiredOffersJob` |
| 🆕 New FR Enhancement | FR-ADM-09.2 | Auto-balance section assignment during enrollment |
| 🆕 New FR Enhancement | FR-ADM-07.3 | Online payment webhook route (PAY module integration) |
| 🆕 New FR Enhancement | FR-ADM-05.3 | Hall ticket PDF generation for entrance tests |
| 🆕 New UI Screen | Admission Analytics Funnel | Screen #25 — not present in V1 |
| 🆕 New UI Screen | Withdrawal Form | Screen #15 — not present in V1 |
| Enhanced | FR-ADM-01 | Seat capacity configuration separated from quota config into `adm_seat_capacity` |
| Enhanced | FR-ADM-11 | TC now includes QR code for digital verification; duplicate TC tracking added |
| Scoped out | Behavior Module | Behavior features flagged for extraction into standalone `BEH` module in future iteration (still included in V2 as `adm_behavior_*`) |
| Removed from scope | C6 Syllabus | Syllabus features deferred to SLB module; not duplicated here |
