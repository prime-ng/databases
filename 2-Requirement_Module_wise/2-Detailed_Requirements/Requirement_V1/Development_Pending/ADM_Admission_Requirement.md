# Admission Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** ADM | **Module Path:** `Modules/Admission` (📐 Not yet created)
**Module Type:** Tenant | **Database:** 📐 Proposed: tenant_db
**Table Prefix:** `adm_*` | **Processing Mode:** RBS_ONLY
**RBS Reference:** Module C — Admissions & Student Lifecycle (56 sub-tasks, lines 2013–2133)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The Admission module (ADM) manages the complete pre-enrollment lifecycle for Indian K-12 schools — from the first point of contact (enquiry/lead) through online/offline application, document verification, entrance assessment, merit-based selection, seat allotment, admission fee collection, and final enrollment that creates a verified `std_students` record. It is the gateway into the Student Profile module and acts as the source of truth for every new student's origin data.

### 1.2 Scope

- Public-facing online enquiry and application portal (no login required for initial enquiry)
- Internal admission desk workflows for school staff
- Government/management quota seat tracking
- Document checklist, upload, and verification
- Entrance test scheduling and result recording
- Merit list generation and seat allotment
- Allotment letter and offer letter PDF generation (DomPDF)
- Admission fee invoice integration with StudentFee module
- Final enrollment trigger that creates `sys_users` + `std_students` + `std_student_academic_sessions`
- Student promotion (class-to-class, year-over-year)
- Alumni and Transfer Certificate management
- Behavior assessment (disciplinary incident log)

> Sections C6 (Syllabus Management) and C7 (Behavior Assessment) in the RBS are mapped to ADM in the document hierarchy but are logically separate sub-domains. This document covers them as ADM sub-features pending extraction into standalone modules.

### 1.3 Module Statistics

| Metric | Count |
|--------|-------|
| RBS Features (F.C*) | 14 |
| RBS Tasks (T.C*) | 28 |
| RBS Sub-tasks (ST.C*) | 56 |
| 📐 Proposed Tables | 18 |
| 📐 Proposed Controllers | 12 |
| 📐 Proposed Models | 18 |
| 📐 Proposed Services | 5 |
| 📐 Proposed Routes (web) | ~65 |
| 📐 Proposed Routes (api) | ~30 |
| 📐 Proposed UI Screens | 22 |
| Existing Controllers | 0 |
| Existing Models | 0 |
| Existing Tests | 0 |

### 1.4 Implementation Status

| Component | Status |
|-----------|--------|
| Module scaffold | ❌ Not Started |
| Database migrations | ❌ Not Started |
| Models | ❌ Not Started |
| Controllers | ❌ Not Started |
| Services | ❌ Not Started |
| Views/UI | ❌ Not Started |
| API endpoints | ❌ Not Started |
| Tests | ❌ Not Started |
| Seeders | ❌ Not Started |

**Overall: 0% — Greenfield / Not Started**

### 1.5 Implementation Prerequisites

| Dependency | Why Required |
|------------|-------------|
| SystemConfig (sys_*) | RBAC, dropdowns, media uploads, audit logs |
| SchoolSetup (sch_*) | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt` |
| StudentProfile (std_*) | Final enrollment writes `std_students` + `std_student_academic_sessions` |
| StudentFee (fin_*) | Admission fee invoice and payment confirmation |
| Notification (ntf_*) | SMS/Email alerts to parents at each stage |
| GlobalMaster (glb_*) | Countries, states, boards, languages for application form |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian schools conduct annual admission cycles (typically January–June for the following academic year). The admission process involves:

- **Lead generation:** parents enquire via school website, walk-in, or campaigns
- **Application:** parents fill a detailed form and pay an application fee
- **Screening:** school staff verify documents, conduct interviews or entrance tests
- **Selection:** merit list published, seats allotted under government/management quota
- **Offer:** allotment letter issued, admission fee collected
- **Enrollment:** student formally joins — user account created, roll number assigned
- **Post-enrollment:** class promotions each year; alumni and TC management on exit

The ADM module eliminates paper-based registers, reduces counselor workload, provides real-time admission pipeline visibility, and ensures audit-trail compliance for government inspections.

### 2.2 Key Features Summary

| # | Feature Group | Key Capability |
|---|--------------|----------------|
| 1 | Lead & Enquiry | Capture, assign, follow-up, convert |
| 2 | Application | Online/offline form, documents, application fee |
| 3 | Verification | Document check, interview scheduling |
| 4 | Entrance Test | Schedule, conduct, record marks |
| 5 | Merit & Allotment | Quota-based merit list, seat allotment |
| 6 | Offer & Fee | Offer letter PDF, admission fee invoice |
| 7 | Enrollment | Create student account, assign class/section, ID card |
| 8 | Student Profile | Personal details, address, emergency contacts, health |
| 9 | Student Documents | Upload TC/marksheets, verification status |
| 10 | Promotion | Year-end bulk promotion, new roll numbers |
| 11 | Alumni & TC | Mark alumni, issue Transfer Certificate PDF |
| 12 | Behavior | Incident log, corrective action, parent meeting |
| 13 | Curriculum Config | Board mapping, subject codes (pending Syllabus module) |

### 2.3 Menu Navigation Path

```
Tenant Dashboard
└── Admission
    ├── Dashboard (pipeline overview)
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
    │   └── Mark Entry
    ├── Allotment
    │   ├── Merit Lists
    │   ├── Seat Allotment
    │   └── Offer Letters
    ├── Enrollment
    │   ├── Pending Enrollment
    │   └── Enrolled Students
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
        ├── Document Checklist
        ├── Quota Configuration
        └── Fee Structure
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
│   ├── EnrollmentController.php
│   ├── PromotionController.php
│   ├── AlumniController.php
│   └── BehaviorIncidentController.php
├── app/Http/Requests/
│   ├── StoreEnquiryRequest.php
│   ├── StoreApplicationRequest.php
│   ├── UploadDocumentRequest.php
│   ├── StoreEntranceTestRequest.php
│   ├── StoreAllotmentRequest.php
│   ├── EnrollStudentRequest.php
│   ├── PromoteStudentsRequest.php
│   ├── IssueTcRequest.php
│   └── StoreIncidentRequest.php
├── app/Models/
│   ├── AdmissionCycle.php
│   ├── Enquiry.php
│   ├── FollowUp.php
│   ├── Application.php
│   ├── ApplicationDocument.php
│   ├── ApplicationStage.php
│   ├── EntranceTest.php
│   ├── EntranceTestCandidate.php
│   ├── MeritList.php
│   ├── MeritListEntry.php
│   ├── Allotment.php
│   ├── AllotmentClassJnt.php
│   ├── PromotionBatch.php
│   ├── PromotionRecord.php
│   ├── AlumniRecord.php
│   ├── TransferCertificate.php
│   ├── BehaviorIncident.php
│   └── BehaviorAction.php
├── app/Services/
│   ├── AdmissionPipelineService.php
│   ├── EnrollmentService.php
│   ├── MeritListService.php
│   ├── PromotionService.php
│   └── TransferCertificateService.php
├── app/Policies/
│   ├── EnquiryPolicy.php
│   ├── ApplicationPolicy.php
│   ├── AllotmentPolicy.php
│   ├── EnrollmentPolicy.php
│   └── PromotionPolicy.php
├── database/
│   ├── migrations/
│   └── seeders/
│       ├── AdmissionDocumentChecklistSeeder.php
│       └── AdmissionQuotaSeeder.php
├── resources/views/
│   ├── dashboard/
│   ├── enquiries/
│   ├── applications/
│   ├── entrance-tests/
│   ├── allotment/
│   ├── enrollment/
│   ├── promotions/
│   ├── alumni/
│   ├── behavior/
│   └── partials/
├── routes/
│   ├── web.php
│   └── api.php
└── tests/
    ├── Feature/
    └── Unit/
```

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role | Key Permissions |
|-------|------|-----------------|
| Super Admin (Prime) | Platform config | Module enable/disable |
| School Admin | Full admission management | All CRUD, allotment, enrollment |
| Admission Counselor | Lead and application management | Create enquiries, process applications |
| Front Office Staff | Walk-in enquiry capture | Create enquiries only |
| Principal / Vice Principal | Allotment approval, merit list sign-off | Approve allotments |
| Class Teacher | Promotion recommendations | View students, submit promotion remarks |
| Parent/Guardian (Public) | Submit online enquiry and application | Public form, status tracking |
| System (automated) | Stage transitions, notifications | Internal service calls |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-ADM-001: Lead Capture (F.C1.1)
**RBS Reference:** F.C1.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_enquiries`, `adm_admission_cycles`

#### Description
Capture initial contact details from prospective parents/students through online forms, walk-in registration, or campaign responses. Each enquiry is a pre-application lead that must be assigned to a counselor for follow-up.

#### Requirements

**REQ-ADM-001.1: Record Enquiry (T.C1.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Front office staff or parent captures enquiry with student and parent contact details, class sought, and lead source |
| Actors | Front Office Staff, Admission Counselor, Parent (public form) |
| Preconditions | Active admission cycle must exist; target class must exist in `sch_classes` |
| Input | Student name, DOB (for age eligibility check), parent name, mobile, email, class sought, academic year, lead source (Website/Walk-in/Campaign/Referral/Social Media) |
| Processing | Validate age eligibility (e.g., min 6 years for Class 1); auto-generate enquiry number (ENQ-YYYY-NNNNN); set status = `New`; trigger welcome SMS/email via Notification module |
| Output | `adm_enquiries` record created; confirmation shown/sent to parent |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C1.1.1.1 — Capture student name, DOB, gender and parent/guardian name, mobile, email → Status: ❌
- [ ] ST.C1.1.1.2 — Select academic year and class sought from active classes → Status: ❌
- [ ] ST.C1.1.1.3 — Assign lead source from dropdown (Website, Walk-in, Campaign, Referral, Social Media) → Status: ❌
- [ ] Age eligibility validation fires on DOB entry — warns if student is underage for selected class → Status: ❌
- [ ] Enquiry number auto-generated in format ENQ-YYYY-NNNNN → Status: ❌
- [ ] Welcome notification dispatched to parent mobile/email → Status: ❌

**REQ-ADM-001.2: Lead Assignment (T.C1.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Assign enquiry to a specific admission counselor or auto-assign using round-robin availability |
| Actors | School Admin, Admission Counselor |
| Preconditions | Enquiry record exists; counselors must have the `Admission Counselor` role |
| Input | Counselor user ID (manual) or auto-assign flag |
| Processing | Manual: update `counselor_id` on `adm_enquiries`; Auto: query counselors with fewest open leads in current cycle, assign to least-loaded |
| Output | Enquiry updated with counselor; counselor notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C1.1.2.1 — Manually assign counselor from active counselor list → Status: ❌
- [ ] ST.C1.1.2.2 — Auto-assign selects counselor with fewest open leads in current cycle → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | EnquiryController | index, create, store, show, edit, update | Enquiry CRUD |
| Service | AdmissionPipelineService | createEnquiry, assignCounselor, autoAssign | Business logic |
| FormRequest | StoreEnquiryRequest | rules() | Validation incl. age eligibility |
| Policy | EnquiryPolicy | viewAny, create, update, delete | Authorization |
| View | enquiries/index.blade.php | — | Enquiry list with pipeline status |
| View | enquiries/create.blade.php | — | Walk-in enquiry form |
| View | enquiries/public.blade.php | — | Public-facing online form (unauthenticated) |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Create enquiry with valid data — record saved, enquiry number generated | Feature | High |
| 2 | Age below minimum for selected class — validation error returned | Feature | High |
| 3 | Auto-assign distributes leads evenly across counselors | Feature | Medium |
| 4 | Duplicate mobile number enquiry in same cycle — warning shown | Feature | Medium |
| 5 | Public form submission creates enquiry without authentication | Feature | High |

---

### FR-ADM-002: Lead Follow-up (F.C1.2)
**RBS Reference:** F.C1.2
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_follow_ups`

#### Description
Counselors schedule and record follow-up calls or meetings with enquired parents, set reminders, and update lead status to track pipeline conversion.

#### Requirements

**REQ-ADM-002.1: Follow-up Scheduling (T.C1.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Schedule a follow-up call or meeting for an enquiry with a specific date/time and reminder |
| Actors | Admission Counselor |
| Preconditions | Enquiry exists and is assigned to counselor |
| Input | Follow-up type (Call/Meeting/Email), scheduled datetime, notes |
| Processing | Create `adm_follow_ups` record; schedule reminder notification N hours before (configurable); link to enquiry |
| Output | Follow-up record created; reminder queued |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C1.2.1.1 — Schedule follow-up call or meeting with date/time → Status: ❌
- [ ] ST.C1.2.1.2 — Set reminder (e.g., 1 hour before) — notification fires via Notification module → Status: ❌

**REQ-ADM-002.2: Lead Status Tracking (T.C1.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Update lead status after each follow-up interaction |
| Actors | Admission Counselor |
| Preconditions | Follow-up completed |
| Input | Status (Interested/Not Interested/Callback Required/Converted), notes |
| Processing | Update `adm_enquiries.status`; if status = Converted, enable "Create Application" action |
| Output | Status updated; pipeline dashboard reflects change |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C1.2.2.1 — Mark lead as Interested, Not Interested, Callback Required, or Converted → Status: ❌
- [ ] ST.C1.2.2.2 — Convert to Application creates `adm_applications` record pre-filled from enquiry data → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | FollowUpController | store, update, destroy | Follow-up CRUD |
| Service | AdmissionPipelineService | scheduleFollowUp, markOutcome, convertToApplication | Follow-up logic |
| FormRequest | StoreFollowUpRequest | rules() | Validation |
| View | enquiries/show.blade.php | — | Enquiry detail + follow-up timeline |

---

### FR-ADM-003: Application Form (F.C2.1)
**RBS Reference:** F.C2.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_applications`, `adm_application_documents`

#### Description
Parent/guardian fills a comprehensive admission application form (online or assisted by staff) including student details, parent/guardian information, previous school details, and document uploads. Application fee challan is generated and payment verified before the application proceeds.

#### Requirements

**REQ-ADM-003.1: Create Application (T.C2.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Comprehensive application form capturing all details needed for admission decision |
| Actors | Parent (online), Admission Counselor (assisted), Front Office Staff |
| Preconditions | Enquiry exists OR new application created directly; active admission cycle |
| Input | Student: name, DOB, gender, nationality, religion, caste/category, mother tongue, previous school name, class passed, marks/grade, TC number. Parent: father name, mother name, mobile, email, occupation, income, address. Guardian (if different). Documents: upload birth certificate, TC, marksheets, Aadhar, photos |
| Processing | Generate application number (APP-YYYY-NNNNN); link to enquiry if exists; set status = `Draft`; calculate age eligibility; check duplicate Aadhar/TC number across active applications |
| Output | `adm_applications` record; document records in `adm_application_documents` |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C2.1.1.1 — Fill student personal details including caste/category and previous school info → Status: ❌
- [ ] ST.C2.1.1.2 — Fill father, mother, guardian details with contact information → Status: ❌
- [ ] ST.C2.1.1.3 — Upload required documents per configured checklist (birth cert, TC, photo, Aadhar) → Status: ❌
- [ ] Application number auto-generated in format APP-YYYY-NNNNN → Status: ❌
- [ ] Duplicate Aadhar / TC number detection across active cycle applications → Status: ❌
- [ ] Application auto-links to source enquiry when converted → Status: ❌

**REQ-ADM-003.2: Application Fees (T.C2.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Generate an application fee challan and mark the application as pending fee payment until payment is confirmed |
| Actors | Admission Counselor, Finance Staff |
| Preconditions | Application in Draft status |
| Input | Fee amount (from admission cycle config), payment mode (Cash/Online/DD/Cheque) |
| Processing | Create fee invoice via StudentFee module (or standalone if StudentFee not yet available); update `adm_applications.application_fee_paid = true` on confirmation; application status → `Submitted` |
| Output | Challan PDF; application status updated |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C2.1.2.1 — Generate application fee challan with amount, due date, payment modes → Status: ❌
- [ ] ST.C2.1.2.2 — Verify payment (manual cash or online payment webhook) and update status → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | ApplicationController | index, create, store, show, edit, update, submit | Application CRUD |
| Controller | ApplicationDocumentController | store, destroy, verify | Document upload/verify |
| Service | AdmissionPipelineService | createApplication, generateChallan, confirmPayment | Business logic |
| FormRequest | StoreApplicationRequest | rules() | Full validation with conditional rules |
| FormRequest | UploadDocumentRequest | rules() | File type/size validation |
| Policy | ApplicationPolicy | viewAny, create, update, verify | Authorization |
| View | applications/create.blade.php | — | Multi-step application form wizard |
| View | applications/documents.blade.php | — | Document upload checklist |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Submit complete application — number generated, status = Submitted | Feature | High |
| 2 | Upload oversized file — validation error | Feature | High |
| 3 | Duplicate Aadhar in same cycle — warning returned | Feature | High |
| 4 | Generate application fee challan — correct amount from cycle config | Feature | High |
| 5 | Convert enquiry to application — fields pre-populated | Feature | Medium |

---

### FR-ADM-004: Application Processing (F.C2.2)
**RBS Reference:** F.C2.2
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_application_stages`

#### Description
Staff verify uploaded documents for authenticity, approve or reject the application, and schedule interview slots for shortlisted applicants.

#### Requirements

**REQ-ADM-004.1: Verification (T.C2.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Admission staff reviews each uploaded document, marks it verified/rejected with remarks, and decides to approve or reject the overall application |
| Actors | Admission Counselor, School Admin |
| Preconditions | Application in Submitted status with documents uploaded |
| Input | Per-document: verified (boolean), remarks. Overall: Approve/Reject with reason |
| Processing | Update `adm_application_documents.is_verified`; update `adm_applications.status` to Verified/Rejected; log stage in `adm_application_stages`; notify parent |
| Output | Document verification status updated; application status changed; parent notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C2.2.1.1 — Verify or reject each document individually with remarks → Status: ❌
- [ ] ST.C2.2.1.2 — Approve or reject application with reason; parent notified via SMS/email → Status: ❌

**REQ-ADM-004.2: Interview Scheduling (T.C2.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Schedule an interview slot for verified applicants and notify parents |
| Actors | Admission Counselor, School Admin |
| Preconditions | Application status = Verified |
| Input | Interview date, time slot, venue/room, interviewer (staff user) |
| Processing | Update `adm_applications` with interview datetime; trigger SMS/email with slot details |
| Output | Interview schedule confirmed; parent notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C2.2.2.1 — Schedule interview slot with date, time, venue, and interviewer → Status: ❌
- [ ] ST.C2.2.2.2 — Parent/guardian notified via SMS and email with slot details → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | ApplicationController | verify, approve, reject, scheduleInterview | Status transitions |
| Service | AdmissionPipelineService | verifyApplication, scheduleInterview | Logic + notifications |
| View | applications/verify.blade.php | — | Document review checklist |
| View | applications/schedule.blade.php | — | Interview slot picker |

---

### FR-ADM-005: Admission Offer (F.C3.1)
**RBS Reference:** F.C3.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_allotments`

#### Description
After merit list generation, selected applicants receive an offer — an allotment letter is issued, a unique admission number is assigned, and joining date is confirmed.

#### Requirements

**REQ-ADM-005.1: Generate Offer Letter (T.C3.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Issue offer letter PDF to allotted applicants with admission number, class allotted, and joining date |
| Actors | School Admin, Principal |
| Preconditions | Allotment record exists; applicant has been shortlisted |
| Input | Joining date, any conditional requirements |
| Processing | Auto-generate admission number in school-defined format (e.g., SCH-YYYY-NNNN); generate offer letter PDF via DomPDF; store in `sys_media`; update `adm_allotments` |
| Output | Offer letter PDF downloadable/emailable to parent |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C3.1.1.1 — Assign unique admission number in configured format → Status: ❌
- [ ] ST.C3.1.1.2 — Set joining date; generate offer letter PDF with school letterhead → Status: ❌

**REQ-ADM-005.2: Admission Fee Collection (T.C3.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Generate admission fee invoice for accepted students and confirm payment before enrollment proceeds |
| Actors | Finance Staff, Admission Counselor |
| Preconditions | Allotment confirmed; offer letter issued |
| Input | Fee components (admission fee, development fee, etc.), due date, payment mode |
| Processing | Create fee invoice via StudentFee/fin module; update `adm_allotments.admission_fee_paid` on payment confirmation |
| Output | Invoice PDF; payment status tracked |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C3.1.2.1 — Generate admission fee invoice with itemized fee components → Status: ❌
- [ ] ST.C3.1.2.2 — Confirm payment (cash/online) and update allotment payment status → Status: ❌

---

### FR-ADM-006: Finalize Admission / Enrollment (F.C3.2)
**RBS Reference:** F.C3.2
**Priority:** 🔴 High (Critical)
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_allotment_classes_jnt` | **Writes to:** `sys_users`, `std_students`, `std_student_academic_sessions`

#### Description
Final step: the paid-and-confirmed applicant is enrolled. This is the critical integration point that creates the permanent student records in the StudentProfile module.

#### Requirements

**REQ-ADM-006.1: Complete Enrollment (T.C3.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Create `sys_users` + `std_students` + `std_student_academic_sessions` from admission application data |
| Actors | School Admin, Enrollment Officer |
| Preconditions | Allotment confirmed; admission fee paid; documents collected |
| Input | Final class/section assignment, roll number (or auto-generate), user credentials (username/password) |
| Processing | DB transaction: (1) Create `sys_users` with student name, email, role=Student; (2) Create `std_students` with admission number, DOB, gender, from `adm_applications`; (3) Create `std_student_academic_sessions` with class_section_id, roll_no, status=Active; (4) Update `adm_applications.status` = Enrolled; (5) Trigger orientation notification |
| Output | Student record created; login credentials sent to parent; student appears in class lists |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C3.2.1.1 — Assign class and section; generate roll number (sequential within class section) → Status: ❌
- [ ] ST.C3.2.1.2 — Trigger student ID card generation (barcode/QR) → Status: ❌
- [ ] Enrollment is atomic — all three tables created in a single DB transaction → Status: ❌
- [ ] On enrollment failure, no partial records left behind → Status: ❌
- [ ] Enrolled student immediately visible in class attendance and fee modules → Status: ❌

**REQ-ADM-006.2: Document Submission (T.C3.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Collect original physical documents, mark as received, and update mandatory field completeness |
| Actors | Front Office Staff |
| Preconditions | Enrollment complete |
| Input | Document received status (checkbox per document type), remarks |
| Processing | Update `adm_application_documents.is_physically_received`; flag profile as incomplete if mandatory documents missing |
| Output | Document receipt status updated |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C3.2.2.1 — Mark each document as physically collected with date → Status: ❌
- [ ] ST.C3.2.2.2 — Profile completeness score shown; alert if mandatory documents missing → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | EnrollmentController | index, show, enroll, bulkEnroll | Enrollment actions |
| Service | EnrollmentService | enrollStudent, createUserAccount, assignClassSection, generateRollNumber | Atomic enrollment transaction |
| FormRequest | EnrollStudentRequest | rules() | Validate class/section/roll uniqueness |
| Policy | EnrollmentPolicy | create | Only Admin/Enrollment Officer |
| View | enrollment/index.blade.php | — | Pending enrollment queue |
| View | enrollment/confirm.blade.php | — | Pre-enrollment confirmation checklist |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Enroll student — sys_users, std_students, std_student_academic_sessions created atomically | Feature | Critical |
| 2 | Enrollment with duplicate roll number in same class section — validation error | Feature | High |
| 3 | Enrollment transaction failure — no partial records persisted | Feature | Critical |
| 4 | Enrolled student visible in class list immediately | Feature | High |

---

### FR-ADM-007: Student Profile via Admission (F.C4.1)
**RBS Reference:** F.C4.1
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Note:** Core profile data is owned by the StudentProfile module (`std_students`). The ADM module captures profile data during application and transfers it on enrollment. Post-enrollment edits are handled by StudentProfile.

#### Requirements

**REQ-ADM-007.1: Profile Data Captured in Application (T.C4.1.1)**

**Acceptance Criteria:**
- [ ] ST.C4.1.1.1 — `adm_applications` captures full personal details (name, DOB, gender, religion, caste, nationality) → Status: ❌
- [ ] ST.C4.1.1.2 — Address (current and permanent) and emergency contact stored in application → Status: ❌

**REQ-ADM-007.2: Caste/Category and Health Information (T.C4.1.2)**

**Acceptance Criteria:**
- [ ] ST.C4.1.2.1 — Caste/category (General/SC/ST/OBC/EWS) captured; government quota eligibility derived → Status: ❌
- [ ] ST.C4.1.2.2 — Basic health information (blood group, known allergies) captured in application → Status: ❌

---

### FR-ADM-008: Student Documents (F.C4.2)
**RBS Reference:** F.C4.2
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_application_documents`, `adm_document_checklist`

#### Requirements

**REQ-ADM-008.1: Document Upload (T.C4.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Applicant or staff uploads required documents against a configurable checklist |
| Actors | Parent (online), Front Office Staff |
| Preconditions | Application exists; document checklist configured for the class level |
| Input | Document type (from checklist), file (PDF/JPG/PNG, max 5MB) |
| Processing | Save to `sys_media`; create `adm_application_documents` record linking document type, application, and media ID |
| Output | Document stored and listed in application document panel |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C4.2.1.1 — Upload Transfer Certificate and previous class marksheets → Status: ❌
- [ ] ST.C4.2.1.2 — Upload medical certificate / fitness certificate → Status: ❌
- [ ] File size validation (max 5MB per file); accepted formats: PDF, JPG, PNG → Status: ❌
- [ ] Document checklist shows required/optional status per document type → Status: ❌

**REQ-ADM-008.2: Document Verification (T.C4.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Staff reviews each uploaded document and marks verified/rejected |
| Actors | Admission Counselor |
| Preconditions | Documents uploaded |
| Input | Verification status (Verified/Rejected/Pending), remarks |
| Processing | Update `adm_application_documents.verification_status`; aggregate to application overall status |
| Output | Document status updated |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C4.2.2.1 — Mark document as authentic/verified with timestamp → Status: ❌
- [ ] ST.C4.2.2.2 — Update verification status; show pending verification badge on application list → Status: ❌

---

### FR-ADM-009: Promotion Processing (F.C5.1)
**RBS Reference:** F.C5.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_promotion_batches`, `adm_promotion_records`

#### Description
At year-end, school admin promotes eligible students to the next class. Bulk promotion wizard fetches all active students, applies criteria (pass/fail from exam results), and assigns them to new class sections for the upcoming academic session.

#### Requirements

**REQ-ADM-009.1: Generate Promotion List (T.C5.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Pull all active students for a class, cross-reference exam results, and classify as Promoted/Detained/Lateral Transfer |
| Actors | School Admin, Principal |
| Preconditions | Academic session results finalized in LmsExam module; upcoming session exists in `sch_org_academic_sessions_jnt` |
| Input | Current academic session, class(es) to process, promotion criteria (pass percentage threshold) |
| Processing | Query `std_student_academic_sessions` for current session; join with exam results; classify each student; create `adm_promotion_batches` record |
| Output | Promotion list with student-wise classification |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C5.1.1.1 — Fetch all active students for selected class(es) → Status: ❌
- [ ] ST.C5.1.1.2 — Apply promotion criteria (pass percentage from exam module); flag detained students → Status: ❌

**REQ-ADM-009.2: Assign New Class (T.C5.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Bulk-assign promoted students to next year's class sections and generate new roll numbers |
| Actors | School Admin |
| Preconditions | Promotion list reviewed and approved; new academic session classes configured |
| Input | Class section mapping for promoted batch, roll number generation mode (sequential/manual) |
| Processing | For each promoted student: create new `std_student_academic_sessions` record for next year; set `is_current = 1`; old record `is_current = 0`; generate roll numbers |
| Output | Students promoted to new class; old session closed |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C5.1.2.1 — Bulk assign promoted students to next year's class sections → Status: ❌
- [ ] ST.C5.1.2.2 — Generate new sequential roll numbers per class section for new session → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | PromotionController | index, create, store, preview, confirm | Promotion wizard |
| Service | PromotionService | generateList, applyFilters, bulkPromote, assignRollNumbers | Promotion logic |
| FormRequest | PromoteStudentsRequest | rules() | Validate session, class mapping |
| View | promotions/wizard.blade.php | — | Step-by-step promotion wizard |
| View | promotions/preview.blade.php | — | Review before commit |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Bulk promotion — all students get new academic session records | Feature | High |
| 2 | Detained student excluded from promotion batch | Feature | High |
| 3 | Roll numbers sequential and unique per class section | Unit | High |
| 4 | Promotion is idempotent — re-running does not duplicate records | Feature | Medium |

---

### FR-ADM-010: Alumni Management (F.C5.2)
**RBS Reference:** F.C5.2
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_transfer_certificates`

#### Requirements

**REQ-ADM-010.1: Mark as Alumni (T.C5.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | When a student passes out of the highest class or voluntarily leaves, mark them as Alumni and close active academic records |
| Actors | School Admin |
| Preconditions | Student in final class or leaving mid-year |
| Input | Exit reason, leaving date, final remarks |
| Processing | Update `std_students.current_status_id` = Alumni; update `std_student_academic_sessions.session_status_id` = Alumni/Left; disable login |
| Output | Student appears in alumni register; class slot freed |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C5.2.1.1 — Move student to alumni register with exit date and reason → Status: ❌
- [ ] ST.C5.2.1.2 — Close all active academic session records; student excluded from attendance/fee modules → Status: ❌

**REQ-ADM-010.2: Issue Transfer Certificate (T.C5.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Generate a Transfer Certificate (TC) PDF in government-prescribed format when a student leaves |
| Actors | School Admin, Principal |
| Preconditions | Student marked for leaving or alumni |
| Input | TC issue date, destination school (optional), reason, conduct remarks |
| Processing | Generate TC number (TC-YYYY-NNN); generate PDF using DomPDF with school letterhead; store in `sys_media`; create `adm_transfer_certificates` record |
| Output | TC PDF downloadable; TC number logged for future verification |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C5.2.2.1 — Generate TC with all government-required fields (admission date, leaving date, class at leaving, conduct) → Status: ❌
- [ ] ST.C5.2.2.2 — TC issue history logged; TC number unique per school-year → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | AlumniController | index, markAlumni, issueTc, downloadTc | Alumni and TC |
| Service | TransferCertificateService | generate, getNextNumber, renderPdf | TC PDF generation |
| FormRequest | IssueTcRequest | rules() | TC field validation |
| View | alumni/index.blade.php | — | Alumni register |
| View | alumni/tc-preview.blade.php | — | TC PDF preview |

---

### FR-ADM-011: Entrance Test Management
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_entrance_tests`, `adm_entrance_test_candidates`

#### Description
Some schools conduct entrance/aptitude tests for admission. This feature manages test session scheduling, candidate list generation, mark entry, and result integration into merit list calculation.

**Acceptance Criteria:**
- [ ] Create entrance test session with date, time, venue, subject areas, max marks → Status: ❌
- [ ] Auto-generate candidate list from verified applications for the target class → Status: ❌
- [ ] Enter marks per candidate after test; compute total/percentage → Status: ❌
- [ ] Entrance test marks fed into merit list calculation → Status: ❌

---

### FR-ADM-012: Merit List & Seat Allotment
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_merit_lists`, `adm_merit_list_entries`, `adm_allotments`

#### Description
Generate merit lists based on configurable criteria (marks, interview score, quota), manage government/management quota seats, and allot seats to selected applicants.

**Acceptance Criteria:**
- [ ] Configure quota types: Government Quota, Management Quota, RTE (Right to Education), NRI, Staff Ward → Status: ❌
- [ ] Generate merit list sorted by composite score (entrance test + interview) within each quota → Status: ❌
- [ ] Allot seat to applicant — update `adm_allotments` with class/section, quota type → Status: ❌
- [ ] Waitlist management — automatically promote waitlisted candidates when allotted candidates decline → Status: ❌
- [ ] Seat capacity validation against `sch_class_section_jnt.strength` → Status: ❌

---

### FR-ADM-013: Behavior Assessment (F.C7)
**RBS Reference:** F.C7.1, F.C7.2
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `adm_behavior_incidents`, `adm_behavior_actions`

#### Requirements

**REQ-ADM-013.1: Record Disciplinary Incident (T.C7.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Log a disciplinary incident for a student with type, severity, and description |
| Actors | Class Teacher, Dean of Students, School Admin |
| Preconditions | Student is enrolled (`std_students` record exists) |
| Input | Student ID, incident type (Bullying/Cheating/Disruption/Absenteeism/Vandalism/Other), severity (Low/Medium/High/Critical), description, date of incident, reported by |
| Processing | Create `adm_behavior_incidents`; assign severity score; check for repeat offender flag |
| Output | Incident logged; notification sent to parent if severity >= Medium |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.C7.1.1.1 — Log incident with type (Bullying, Cheating, Disruption, etc.) → Status: ❌
- [ ] ST.C7.1.1.2 — Assign severity level (Low/Medium/High/Critical); Critical auto-notifies principal → Status: ❌

**REQ-ADM-013.2: Action & Follow-up (T.C7.1.2)**

**Acceptance Criteria:**
- [ ] ST.C7.1.2.1 — Define corrective action (Warning/Detention/Suspension/Expulsion) with duration → Status: ❌
- [ ] ST.C7.1.2.2 — Schedule parent meeting; log meeting outcome and action taken → Status: ❌

**REQ-ADM-013.3: Behavior Analytics (T.C7.2.1)**

**Acceptance Criteria:**
- [ ] ST.C7.2.1.1 — Report: repeat offenders list, incident frequency by type/day/class → Status: ❌
- [ ] ST.C7.2.1.2 — Behavior score trend over time per student → Status: ❌

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 📐 Proposed Entity Overview

| Table | Description | Approx. Rows/School/Year |
|-------|-------------|--------------------------|
| `adm_admission_cycles` | Annual admission cycle config | 1–5 |
| `adm_document_checklist` | Required documents per cycle/class level | 20–50 |
| `adm_quota_config` | Quota type config (Govt/Mgmt/RTE etc.) | 5–10 |
| `adm_enquiries` | Raw leads/enquiries | 200–2000 |
| `adm_follow_ups` | Follow-up log per enquiry | 500–5000 |
| `adm_applications` | Full application records | 100–1000 |
| `adm_application_documents` | Uploaded documents per application | 500–5000 |
| `adm_application_stages` | Stage audit trail per application | 500–4000 |
| `adm_entrance_tests` | Test sessions | 1–10 |
| `adm_entrance_test_candidates` | Candidate marks per test | 50–500 |
| `adm_merit_lists` | Merit list per cycle + class + quota | 10–50 |
| `adm_merit_list_entries` | Individual merit entries | 100–1000 |
| `adm_allotments` | Seat allotments | 100–500 |
| `adm_allotment_classes_jnt` | Class+section per allotment | 100–500 |
| `adm_promotion_batches` | Year-end promotion batch | 1–10 |
| `adm_promotion_records` | Per-student promotion record | 500–5000 |
| `adm_transfer_certificates` | TC issuance log | 20–200 |
| `adm_behavior_incidents` | Disciplinary incident log | 50–500 |
| `adm_behavior_actions` | Actions per incident | 50–500 |

### 5.2 📐 Detailed Entity Specification

---

#### `adm_admission_cycles`
Annual admission cycle — each school year has one or more cycles (e.g., Main Cycle, Late Admission).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `academic_session_id` | INT UNSIGNED | NOT NULL, FK→sch_org_academic_sessions_jnt | Target academic year |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Main Admission 2026-27" |
| `cycle_code` | VARCHAR(20) | NOT NULL, UNIQUE | e.g., "ADM-2627-M" |
| `start_date` | DATE | NOT NULL | Enquiry open date |
| `end_date` | DATE | NOT NULL | Enquiry close date |
| `application_fee` | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Application processing fee |
| `application_form_url` | VARCHAR(255) | NULL | Public form URL slug |
| `status` | ENUM('Draft','Active','Closed','Archived') | NOT NULL DEFAULT 'Draft' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

**Indexes:** `idx_adm_cycles_session` (`academic_session_id`), `idx_adm_cycles_status` (`status`)

---

#### `adm_document_checklist`
Configurable per cycle and class level.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NULL, FK→sch_classes | NULL = applies to all classes |
| `document_name` | VARCHAR(100) | NOT NULL | e.g., "Birth Certificate" |
| `document_code` | VARCHAR(30) | NOT NULL | e.g., "BIRTH_CERT" |
| `is_mandatory` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `accepted_formats` | VARCHAR(100) | NOT NULL DEFAULT 'pdf,jpg,png' | |
| `max_size_kb` | INT UNSIGNED | NOT NULL DEFAULT 5120 | Max file size in KB |
| `sort_order` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_quota_config`
Quota type configuration per admission cycle.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL | |
| `total_seats` | SMALLINT UNSIGNED | NOT NULL | |
| `reserved_seats` | SMALLINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_enquiries`
Primary lead/enquiry record.

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
| `notes` | TEXT | NULL | |
| `source_reference` | VARCHAR(100) | NULL | Campaign code / referral name |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_adm_enq_cycle` (`admission_cycle_id`), `idx_adm_enq_status` (`status`), `idx_adm_enq_counselor` (`counselor_id`), `idx_adm_enq_mobile` (`contact_mobile`)

---

#### `adm_follow_ups`
Follow-up activity log for each enquiry.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `enquiry_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_enquiries | |
| `follow_up_type` | ENUM('Call','Meeting','Email','SMS','Walk-in') | NOT NULL | |
| `scheduled_at` | DATETIME | NOT NULL | |
| `completed_at` | DATETIME | NULL | |
| `outcome` | ENUM('Pending','Interested','Not_Interested','Callback','Converted') | NOT NULL DEFAULT 'Pending' | |
| `notes` | TEXT | NULL | |
| `done_by` | BIGINT UNSIGNED | NULL, FK→sys_users | Counselor |
| `reminder_sent` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_applications`
Full admission application record.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `enquiry_id` | BIGINT UNSIGNED | NULL, FK→adm_enquiries | Source enquiry if converted |
| `application_no` | VARCHAR(20) | NOT NULL, UNIQUE | APP-YYYY-NNNNN |
| `class_applied_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL DEFAULT 'General' | |
| `student_first_name` | VARCHAR(50) | NOT NULL | |
| `student_middle_name` | VARCHAR(50) | NULL | |
| `student_last_name` | VARCHAR(50) | NULL | |
| `student_dob` | DATE | NOT NULL | |
| `student_gender` | ENUM('Male','Female','Transgender','Prefer Not to Say') | NOT NULL | |
| `student_religion` | VARCHAR(50) | NULL | |
| `student_caste_category` | ENUM('General','OBC','SC','ST','EWS','Other') | NULL | |
| `student_nationality` | VARCHAR(50) | NULL DEFAULT 'Indian' | |
| `student_mother_tongue` | VARCHAR(50) | NULL | |
| `aadhar_no` | VARCHAR(20) | NULL | |
| `birth_cert_no` | VARCHAR(50) | NULL | |
| `prev_school_name` | VARCHAR(100) | NULL | |
| `prev_class_passed` | VARCHAR(20) | NULL | e.g., "Class 4" |
| `prev_marks_percent` | DECIMAL(5,2) | NULL | |
| `prev_tc_no` | VARCHAR(50) | NULL | Transfer Certificate number |
| `blood_group` | ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown') | NULL | |
| `known_allergies` | TEXT | NULL | |
| `father_name` | VARCHAR(100) | NULL | |
| `father_mobile` | VARCHAR(15) | NULL | |
| `father_email` | VARCHAR(100) | NULL | |
| `father_occupation` | VARCHAR(100) | NULL | |
| `mother_name` | VARCHAR(100) | NULL | |
| `mother_mobile` | VARCHAR(15) | NULL | |
| `mother_email` | VARCHAR(100) | NULL | |
| `guardian_name` | VARCHAR(100) | NULL | If different from parents |
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

#### `adm_application_documents`
Documents per application.

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

#### `adm_application_stages`
Audit trail of status transitions per application.

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

#### `adm_entrance_tests`
Entrance test sessions.

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
| `subjects_json` | JSON | NULL | Array of subject areas with marks |
| `status` | ENUM('Scheduled','Completed','Cancelled') | NOT NULL DEFAULT 'Scheduled' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_entrance_test_candidates`
Marks per candidate per test.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `entrance_test_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_entrance_tests | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `roll_no` | VARCHAR(20) | NULL | Test roll number |
| `marks_obtained` | DECIMAL(6,2) | NULL | |
| `percentage` | DECIMAL(5,2) | GENERATED ALWAYS AS (marks_obtained / test.max_marks * 100) | Computed |
| `result` | ENUM('Pass','Fail','Absent','Pending') | NOT NULL DEFAULT 'Pending' | |
| `subject_marks_json` | JSON | NULL | Per-subject breakdown |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Unique:** `uq_adm_etc_test_app` (`entrance_test_id`, `application_id`)

---

#### `adm_merit_lists`
Merit list per cycle, class, and quota.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `admission_cycle_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_admission_cycles | |
| `class_id` | INT UNSIGNED | NOT NULL, FK→sch_classes | |
| `quota_type` | ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS') | NOT NULL | |
| `generated_at` | TIMESTAMP | NULL | |
| `generated_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `status` | ENUM('Draft','Published','Finalized') | NOT NULL DEFAULT 'Draft' | |
| `criteria_json` | JSON | NULL | Weightage config (test%, interview%, academic%) |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_merit_list_entries`
Individual entries in a merit list.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `merit_list_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_merit_lists | |
| `application_id` | BIGINT UNSIGNED | NOT NULL, FK→adm_applications | |
| `merit_rank` | SMALLINT UNSIGNED | NOT NULL | |
| `composite_score` | DECIMAL(6,2) | NULL | |
| `entrance_score` | DECIMAL(6,2) | NULL | |
| `interview_score` | DECIMAL(6,2) | NULL | |
| `academic_score` | DECIMAL(6,2) | NULL | |
| `merit_status` | ENUM('Shortlisted','Waitlisted','Rejected') | NOT NULL DEFAULT 'Shortlisted' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_allotments`
Seat allotment records for shortlisted candidates.

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
| `admission_fee_paid` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `admission_fee_amount` | DECIMAL(10,2) | NULL | |
| `admission_fee_date` | DATE | NULL | |
| `status` | ENUM('Offered','Accepted','Declined','Expired','Enrolled') | NOT NULL DEFAULT 'Offered' | |
| `enrolled_student_id` | INT UNSIGNED | NULL, FK→std_students | Set on enrollment |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_promotion_batches`
Year-end promotion processing batch.

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

#### `adm_promotion_records`
Per-student result within a promotion batch.

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

#### `adm_transfer_certificates`
Transfer Certificate issuance log.

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
| `media_id` | INT UNSIGNED | NULL, FK→sys_media | PDF file |
| `issued_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_behavior_incidents`
Disciplinary incident log.

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
| `behavior_score_impact` | TINYINT | NOT NULL DEFAULT 0 | Negative points deducted |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `adm_behavior_actions`
Corrective actions per incident.

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
    ├── adm_enquiries (1:M)
    │       └── adm_follow_ups (1:M)
    ├── adm_applications (1:M)
    │       ├── adm_application_documents (1:M)
    │       └── adm_application_stages (1:M)
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

### 5.5 📐 Proposed Migration Order

1. `adm_admission_cycles`
2. `adm_document_checklist`
3. `adm_quota_config`
4. `adm_enquiries`
5. `adm_follow_ups`
6. `adm_applications`
7. `adm_application_documents`
8. `adm_application_stages`
9. `adm_entrance_tests`
10. `adm_entrance_test_candidates`
11. `adm_merit_lists`
12. `adm_merit_list_entries`
13. `adm_allotments`
14. `adm_promotion_batches`
15. `adm_promotion_records`
16. `adm_transfer_certificates`
17. `adm_behavior_incidents`
18. `adm_behavior_actions`

---

## 6. 📐 API & ROUTE SPECIFICATION

### 6.1 Proposed Route Summary

| # | Method | URI | Controller@Method | Name |
|---|--------|-----|-------------------|------|
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
| 12 | GET | `/admission/applications/create` | ApplicationController@create | adm.applications.create |
| 13 | POST | `/admission/applications` | ApplicationController@store | adm.applications.store |
| 14 | GET | `/admission/applications/{id}` | ApplicationController@show | adm.applications.show |
| 15 | PATCH | `/admission/applications/{id}` | ApplicationController@update | adm.applications.update |
| 16 | POST | `/admission/applications/{id}/submit` | ApplicationController@submit | adm.applications.submit |
| 17 | POST | `/admission/applications/{id}/verify` | ApplicationController@verify | adm.applications.verify |
| 18 | POST | `/admission/applications/{id}/approve` | ApplicationController@approve | adm.applications.approve |
| 19 | POST | `/admission/applications/{id}/reject` | ApplicationController@reject | adm.applications.reject |
| 20 | POST | `/admission/applications/{id}/schedule-interview` | ApplicationController@scheduleInterview | adm.applications.scheduleInterview |
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
| 36 | GET | `/admission/promotions` | PromotionController@index | adm.promotions.index |
| 37 | POST | `/admission/promotions/preview` | PromotionController@preview | adm.promotions.preview |
| 38 | POST | `/admission/promotions/confirm` | PromotionController@confirm | adm.promotions.confirm |
| 39 | GET | `/admission/alumni` | AlumniController@index | adm.alumni.index |
| 40 | POST | `/admission/alumni/{id}/mark` | AlumniController@markAlumni | adm.alumni.mark |
| 41 | POST | `/admission/alumni/{id}/tc` | AlumniController@issueTc | adm.alumni.tc |
| 42 | GET | `/admission/alumni/{id}/tc/download` | AlumniController@downloadTc | adm.alumni.tc.download |
| 43 | GET | `/admission/behavior` | BehaviorIncidentController@index | adm.behavior.index |
| 44 | POST | `/admission/behavior` | BehaviorIncidentController@store | adm.behavior.store |
| 45 | POST | `/admission/behavior/{id}/action` | BehaviorIncidentController@addAction | adm.behavior.action |
| 46 | GET | `/admission/behavior/reports` | BehaviorIncidentController@report | adm.behavior.report |
| — | — | **Public Routes (unauthenticated)** | — | — |
| P1 | GET | `/apply/{slug}` | ApplicationController@publicForm | adm.public.form |
| P2 | POST | `/apply/{slug}` | ApplicationController@publicSubmit | adm.public.submit |
| P3 | GET | `/apply/status/{app_no}` | ApplicationController@trackStatus | adm.public.track |

### 6.3 Proposed Route Group Structure

```php
// Public routes — no auth required
Route::prefix('apply')->name('adm.public.')->group(function () {
    Route::get('/{slug}', [ApplicationController::class, 'publicForm'])->name('form');
    Route::post('/{slug}', [ApplicationController::class, 'publicSubmit'])->name('submit');
    Route::get('/status/{applicationNo}', [ApplicationController::class, 'trackStatus'])->name('track');
});

// Authenticated tenant routes
Route::middleware(['auth', 'tenant'])->prefix('admission')->name('adm.')->group(function () {
    Route::get('/', [AdmissionDashboardController::class, 'index'])->name('dashboard');

    Route::prefix('enquiries')->name('enquiries.')->group(function () {
        Route::get('/', [EnquiryController::class, 'index'])->name('index');
        Route::get('/create', [EnquiryController::class, 'create'])->name('create');
        Route::post('/', [EnquiryController::class, 'store'])->name('store');
        Route::get('/{id}', [EnquiryController::class, 'show'])->name('show');
        Route::patch('/{id}', [EnquiryController::class, 'update'])->name('update');
        Route::post('/{id}/assign', [EnquiryController::class, 'assign'])->name('assign');
        Route::post('/{id}/convert', [EnquiryController::class, 'convert'])->name('convert');
        Route::post('/{id}/follow-ups', [FollowUpController::class, 'store'])->name('followups.store');
    });

    Route::resource('applications', ApplicationController::class)->except(['create']);
    Route::post('applications/{id}/submit', [ApplicationController::class, 'submit']);
    Route::post('applications/{id}/verify', [ApplicationController::class, 'verify']);
    Route::post('applications/{id}/approve', [ApplicationController::class, 'approve']);
    Route::post('applications/{id}/reject', [ApplicationController::class, 'reject']);
    Route::post('applications/{id}/schedule-interview', [ApplicationController::class, 'scheduleInterview']);
    Route::post('applications/{id}/documents', [ApplicationDocumentController::class, 'store']);
    Route::patch('documents/{id}/verify', [ApplicationDocumentController::class, 'verify']);
    Route::delete('documents/{id}', [ApplicationDocumentController::class, 'destroy']);

    Route::resource('entrance-tests', EntranceTestController::class);
    Route::post('entrance-tests/{id}/marks', [EntranceTestController::class, 'enterMarks']);

    Route::get('merit-lists', [MeritListController::class, 'index'])->name('merit-lists.index');
    Route::post('merit-lists/generate', [MeritListController::class, 'generate']);
    Route::post('merit-lists/{id}/publish', [MeritListController::class, 'publish']);

    Route::resource('allotments', AllotmentController::class);
    Route::post('allotments/{id}/offer-letter', [AllotmentController::class, 'generateOffer']);
    Route::post('allotments/{id}/confirm-fee', [AllotmentController::class, 'confirmFee']);

    Route::get('enrollment', [EnrollmentController::class, 'index'])->name('enrollment.index');
    Route::post('enrollment/{allotment}/enroll', [EnrollmentController::class, 'enroll']);

    Route::prefix('promotions')->name('promotions.')->group(function () {
        Route::get('/', [PromotionController::class, 'index'])->name('index');
        Route::post('/preview', [PromotionController::class, 'preview'])->name('preview');
        Route::post('/confirm', [PromotionController::class, 'confirm'])->name('confirm');
    });

    Route::prefix('alumni')->name('alumni.')->group(function () {
        Route::get('/', [AlumniController::class, 'index'])->name('index');
        Route::post('/{id}/mark', [AlumniController::class, 'markAlumni'])->name('mark');
        Route::post('/{id}/tc', [AlumniController::class, 'issueTc'])->name('tc');
        Route::get('/{id}/tc/download', [AlumniController::class, 'downloadTc'])->name('tc.download');
    });

    Route::prefix('behavior')->name('behavior.')->group(function () {
        Route::get('/', [BehaviorIncidentController::class, 'index'])->name('index');
        Route::post('/', [BehaviorIncidentController::class, 'store'])->name('store');
        Route::post('/{id}/action', [BehaviorIncidentController::class, 'addAction'])->name('action');
        Route::get('/reports', [BehaviorIncidentController::class, 'report'])->name('report');
    });
});

// API routes
Route::middleware(['auth:sanctum', 'tenant'])->prefix('api/v1/admission')->name('api.adm.')->group(function () {
    Route::get('/pipeline', [AdmissionDashboardController::class, 'apiPipeline'])->name('pipeline');
    Route::get('/enquiries', [EnquiryController::class, 'apiIndex'])->name('enquiries');
    Route::post('/enquiries', [EnquiryController::class, 'apiStore'])->name('enquiries.store');
    Route::get('/applications/{id}/status', [ApplicationController::class, 'apiStatus'])->name('applications.status');
    Route::post('/enrollment', [EnrollmentController::class, 'apiEnroll'])->name('enrollment');
});
```

---

## 7. 📐 UI Screen Inventory & Field Mapping

| # | Screen Name | Route | Description |
|---|-------------|-------|-------------|
| 1 | Admission Dashboard | adm.dashboard | Pipeline Kanban: Enquiries → Applications → Verified → Allotted → Enrolled |
| 2 | Enquiry List | adm.enquiries.index | Filterable table with status, counselor, class columns |
| 3 | New Enquiry Form | adm.enquiries.create | Walk-in form: student name, DOB, parent contact, class sought, lead source |
| 4 | Enquiry Detail | adm.enquiries.show | Lead timeline, follow-up log, convert to application button |
| 5 | Public Enquiry / Application Form | adm.public.form | Multi-step form: student details → parent details → document upload → fee |
| 6 | Application Status Tracker | adm.public.track | Parent enters application number; sees current stage |
| 7 | Application List | adm.applications.index | Table with filters: cycle, class, quota, status |
| 8 | Application Detail / Review | adm.applications.show | Full application view with document viewer, verification checkboxes |
| 9 | Interview Scheduler | adm.applications.scheduleInterview | Date/time picker with venue and interviewer fields |
| 10 | Entrance Test List | adm.entrance-tests.index | Test sessions per cycle |
| 11 | Entrance Test Mark Entry | adm.entrance-tests.marks | Spreadsheet-style mark entry per candidate |
| 12 | Merit List | adm.merit-lists.index | Ranked list with composite score breakdown, quota filter |
| 13 | Allotment List | adm.allotments.index | Allotted students with offer letter status |
| 14 | Offer Letter Preview | adm.allotments.offer | PDF preview with school letterhead before download |
| 15 | Enrollment Queue | adm.enrollment.index | Paid-and-ready applicants pending final enrollment |
| 16 | Enrollment Confirm | adm.enrollment.enroll | Assign class/section/roll number; confirm enrollment |
| 17 | Promotion Wizard — Step 1 | adm.promotions.index | Select current session + class |
| 18 | Promotion Wizard — Step 2 | adm.promotions.preview | Review list of students with promotion status |
| 19 | Promotion Wizard — Step 3 | adm.promotions.confirm | Confirm + assign sections + set roll numbers |
| 20 | Alumni Register | adm.alumni.index | Filterable alumni list |
| 21 | Transfer Certificate Issuance | adm.alumni.tc | TC form with PDF preview |
| 22 | Behavior Incidents | adm.behavior.index | Incident list with severity badges; add incident button |

---

## 8. Business Rules & Domain Constraints

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-ADM-001 | Age eligibility: minimum 6 years completed by June 1 for Class 1 admission | Validation in `StoreEnquiryRequest` and `StoreApplicationRequest`; age computed from DOB |
| BR-ADM-002 | Enrollment is atomic — all three tables (sys_users, std_students, std_student_academic_sessions) must be created in a single DB transaction | `EnrollmentService::enrollStudent()` wrapped in `DB::transaction()` |
| BR-ADM-003 | Admission number must be unique across the school — format is school-configurable | UNIQUE constraint on `adm_allotments.admission_no`; also on `std_students.admission_no` |
| BR-ADM-004 | TC can only be issued after all outstanding fees are cleared | `TransferCertificateService` checks `fin_fee_payments` balance before allowing TC generation |
| BR-ADM-005 | RTE quota: schools covered by Right to Education Act (2009) must reserve 25% of Class 1 seats for economically weaker sections | `adm_quota_config` enforces seat reservation; RTE applications bypass application fee |
| BR-ADM-006 | Application fee is non-refundable once paid | Business rule documented in offer letter; no automated refund trigger |
| BR-ADM-007 | Document checklist completion is mandatory before application can move from Submitted → Verified | `AdmissionPipelineService::verifyApplication()` checks all mandatory documents are uploaded |
| BR-ADM-008 | Roll numbers must be unique within a class section for the same academic session | UNIQUE constraint on (`class_section_id`, `academic_session_id`, `roll_no`) in `std_student_academic_sessions` |
| BR-ADM-009 | Promotion processing must not overwrite the current year's academic session records — it creates new records for the next session | `PromotionService` creates new `std_student_academic_sessions` with `is_current = 1`; old record set to `is_current = 0` |
| BR-ADM-010 | A student can only be enrolled once per academic session (no duplicate enrollment) | UNIQUE constraint `uq_std_acad_sess_student_session` on `std_student_academic_sessions` |
| BR-ADM-011 | NEP 2020 compliance: foundational stage (Classes 1–2, ages 5–7) admission criteria cannot include formal written tests | Validation warning if entrance test is configured for Classes 1–2 |
| BR-ADM-012 | Aadhar number is optional but unique if provided | UNIQUE KEY on `adm_applications.aadhar_no` (nullable); UNIQUE KEY on `std_students.aadhar_id` |

---

## 9. Workflow & State Machine Definitions

### 9.1 Admission Application State Machine

```
[Draft] ──(submit + fee paid)──► [Submitted]
    ├──(document verified, all OK)──► [Verified]
    │       ├──(shortlisted in merit list)──► [Shortlisted]
    │       │       ├──(seat allotted)──► [Allotted]
    │       │       │       ├──(offer accepted + admission fee paid + enrolled)──► [Enrolled] ✅
    │       │       │       └──(declined or expired)──► [Withdrawn]
    │       │       └──(waitlisted)──► [Waitlisted] ──(seat freed)──► [Allotted]
    │       └──(rejected in merit)──► [Rejected]
    └──(documents insufficient)──► [Rejected] / returned to Draft for correction
```

### 9.2 Enquiry Lead State Machine

```
[New] ──(counselor assigned)──► [Assigned]
    └──(first contact made)──► [Contacted]
            ├──► [Interested] ──(form initiated)──► [Converted] ✅
            ├──► [Not_Interested] (closed)
            └──► [Callback] ──(scheduled)──► [Contacted]
```

### 9.3 Promotion State Machine

```
[Draft] (batch created, student list loaded)
    └──(admin reviews, optionally edits)──► [Confirmed] ✅
         (std_student_academic_sessions records created for new session)
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Public enquiry form must load in < 2 seconds; enrollment transaction must complete in < 5 seconds |
| Scalability | Support up to 5,000 applications per admission cycle per tenant |
| Security | Application documents stored in private S3/local storage, not publicly accessible; Aadhar numbers encrypted at rest using AES-256 |
| Availability | Admission portal must be available 99.9% during peak months (February–May) |
| Data Integrity | All status transitions logged in `adm_application_stages` for audit compliance |
| Accessibility | Public form WCAG 2.1 AA compliant; mobile-responsive Bootstrap 5 layout |
| Audit | All enrollment actions recorded in `sys_activity_logs` |
| Localisation | Application form supports English and regional language (Hindi/Marathi/etc.) via `glb_translations` |

---

## 11. Cross-Module Dependencies

### 11.1 This Module Depends On

| Module | Tables Used | Reason |
|--------|-------------|--------|
| SystemConfig | `sys_users`, `sys_roles`, `sys_media`, `sys_dropdown_table`, `sys_activity_logs` | Auth, RBAC, file uploads, status dropdowns, audit |
| SchoolSetup | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt`, `sch_organizations` | Class/section for applications; session for enrollment and promotion |
| StudentProfile | `std_students`, `std_student_academic_sessions` | Enrollment writes here; promotion updates here |
| StudentFee | `fin_fee_structures`, `fin_invoices` | Application fee and admission fee invoice generation |
| Notification | Event-driven notifications | SMS/email at enquiry, verification, allotment, enrollment stages |
| GlobalMaster | `glb_countries`, `glb_states`, `glb_boards` | Address dropdowns, board for previous school |

### 11.2 Modules That Depend on ADM

| Module | Dependency |
|--------|-----------|
| StudentProfile | Reads enrollment data seeded by ADM enrollment |
| Attendance | Requires enrolled students from `std_student_academic_sessions` |
| StudentFee | Student fee structures depend on enrolled student records |
| LmsExam | Exam results feed back into ADM promotion criteria |
| Timetable | Class strength counts depend on enrolled student counts |

### 11.3 📐 Implementation Order Recommendation

1. SystemConfig (auth, RBAC, dropdowns) — must be done
2. SchoolSetup (classes, sections, academic sessions) — must be done
3. GlobalMaster (countries, states) — must be done
4. **ADM Phase 1:** Enquiry + Application + Documents (no payment integration)
5. **ADM Phase 2:** Merit List + Allotment + Offer Letter
6. StudentFee — for fee integration
7. **ADM Phase 3:** Enrollment (writes std_students)
8. **ADM Phase 4:** Promotion + Alumni + TC
9. **ADM Phase 5:** Behavior incidents
10. LmsExam — for promotion criteria from exam results

---

## 12. 📐 Proposed Test Plan

| # | Test Name | Description | Type | Priority |
|---|-----------|-------------|------|----------|
| 1 | EnquiryCreationTest | Create enquiry with valid data → record created, ENQ number assigned | Feature | Critical |
| 2 | AgeEligibilityValidationTest | DOB that makes student underage for Class 1 → validation error | Feature | High |
| 3 | DuplicateAadharTest | Second application with same Aadhar in same cycle → warning shown | Feature | High |
| 4 | ApplicationDocumentUploadTest | Upload PDF document against checklist → media stored, document record created | Feature | High |
| 5 | ApplicationStatusTransitionTest | Each status transition creates `adm_application_stages` record | Feature | High |
| 6 | MeritListGenerationTest | Generate merit list → entries ranked correctly by composite score | Unit | High |
| 7 | QuotaSeatCapacityTest | Allot more students than quota seats → error returned | Feature | High |
| 8 | EnrollmentAtomicTest | Enrollment success → sys_users + std_students + std_student_academic_sessions all created | Feature | Critical |
| 9 | EnrollmentRollbackTest | Enrollment with DB error mid-transaction → no partial records created | Feature | Critical |
| 10 | DuplicateEnrollmentTest | Enroll same student twice in same session → unique constraint violation | Feature | High |
| 11 | PromotionBulkTest | Bulk promote 50 students → all get new academic session records | Feature | High |
| 12 | DetainedStudentExclusionTest | Detained student stays in current class after promotion batch | Feature | High |
| 13 | TransferCertificateTest | Issue TC → PDF generated with correct fields, TC number unique | Feature | Medium |
| 14 | TCWithOutstandingFeeTest | Issue TC when fees are outstanding → blocked with error | Feature | High |
| 15 | BehaviorIncidentSeverityTest | Critical incident → principal notification dispatched automatically | Feature | Medium |
| 16 | RollNumberUniquenessTest | Roll number must be unique per class section per session | Unit | High |
| 17 | PublicFormSubmissionTest | Unauthenticated user submits application via public URL → application created | Feature | High |
| 18 | ApplicationFeeChallnanTest | Application fee challan generated with correct amount from cycle config | Feature | Medium |
| 19 | OfferLetterPdfTest | Offer letter PDF rendered with school letterhead and correct student data | Feature | Medium |
| 20 | AutoAssignCounselorTest | Auto-assign distributes new leads evenly across counselors | Unit | Medium |

---

## 13. Glossary & Terminology

| Term | Definition |
|------|-----------|
| Admission Cycle | A defined period during which the school accepts applications for a specific academic year |
| Application Fee | Non-refundable processing fee paid when submitting an admission application |
| Admission Fee | Fee paid after seat allotment to confirm the student's place |
| Allotment | Official assignment of a seat in a class/section to a shortlisted applicant |
| Counselor | School staff responsible for managing leads and guiding parents through the admission process |
| Merit List | Ranked list of applicants generated based on entrance test, interview, and academic performance |
| Quota | Reserved category of seats (Government, Management, RTE, NRI, Staff Ward, etc.) |
| Transfer Certificate (TC) | Official document issued by a school when a student leaves, required for admission to another school |
| Alumni | A student who has passed out of the highest class or left the school |
| Promotion | Year-end process of moving students to the next class for the upcoming academic session |
| RTE | Right to Education Act (2009) — mandates 25% reservation for EWS students in Classes 1–8 in private schools |
| NEP 2020 | National Education Policy 2020 — governs curriculum and assessment norms |
| APAAR ID | Academic Bank of Credits ID — national student identifier under NEP 2020 |
| EWS | Economically Weaker Section — income-based category for fee concession and quota |

---

## 14. Additional Suggestions

> The following are analyst recommendations that are outside the current RBS scope but would significantly enhance the module:

1. **Online Payment Gateway Integration:** Application fee and admission fee should support Razorpay/PayU integration so parents can pay online. Currently the RBS assumes manual cash/challan. This would reduce front-office load significantly.

2. **Sibling Preference Algorithm:** Schools frequently give preference to siblings of existing students. Implement a sibling detection step (same parent mobile/email as existing `std_students`) with automatic priority score boost.

3. **Wait-list Auto-promotion:** When an allotted student declines or their offer expires, automatically promote the next waitlisted candidate and send them an offer — this eliminates manual intervention.

4. **Interview Slot Calendar View:** The interview scheduling screen would benefit from a week-view calendar showing available slots, rooms, and interviewer availability — similar to the Timetable module's slot picker.

5. **Government Report Export:** Indian schools must submit admission data to state education departments. A PDF/Excel export in government-prescribed format (UDISE-compatible) would be a high-value addition.

6. **ID Card Generation:** After enrollment, auto-trigger ID card PDF generation (already available in HPC module context via DomPDF) to reduce manual effort.

7. **Behavior Module Separation:** The Behavior Assessment features (C7) are logically distinct from Admission. Consider extracting them into a standalone `BEH` module in a future iteration to keep ADM focused on the admission funnel.

---

## 15. Appendices

### Appendix A — Full RBS Extract (Module C)

```
Module C — Admissions & Student Lifecycle (56 sub-tasks)

C1 — Enquiry & Lead Management (9 sub-tasks)
  F.C1.1 — Lead Capture
    T.C1.1.1 — Record Enquiry
      ST.C1.1.1.1 Capture student & parent contact details
      ST.C1.1.1.2 Select academic year & class sought
      ST.C1.1.1.3 Assign lead source (Website, Walk-in, Campaign)
    T.C1.1.2 — Lead Assignment
      ST.C1.1.2.1 Assign counselor
      ST.C1.1.2.2 Auto-assign based on availability
  F.C1.2 — Lead Follow-up
    T.C1.2.1 — Follow-up Scheduling
      ST.C1.2.1.1 Schedule call/meeting
      ST.C1.2.1.2 Set follow-up reminder
    T.C1.2.2 — Lead Status Tracking
      ST.C1.2.2.1 Mark as Interested/Not Interested
      ST.C1.2.2.2 Convert to Application

C2 — Application Management (9 sub-tasks)
  F.C2.1 — Application Form
    T.C2.1.1 — Create Application
      ST.C2.1.1.1 Fill student details
      ST.C2.1.1.2 Fill parent/guardian info
      ST.C2.1.1.3 Upload documents
    T.C2.1.2 — Application Fees
      ST.C2.1.2.1 Generate application fee challan
      ST.C2.1.2.2 Verify fee payment
  F.C2.2 — Application Processing
    T.C2.2.1 — Verification
      ST.C2.2.1.1 Verify uploaded documents
      ST.C2.2.1.2 Approve/Reject application
    T.C2.2.2 — Interview Scheduling
      ST.C2.2.2.1 Schedule interview slot
      ST.C2.2.2.2 Notify parents via SMS/Email

C3 — Admission Management (8 sub-tasks)
  F.C3.1 — Admission Offer
    T.C3.1.1 — Generate Offer Letter
      ST.C3.1.1.1 Assign admission number
      ST.C3.1.1.2 Set joining date
    T.C3.1.2 — Admission Fee Collection
      ST.C3.1.2.1 Generate admission fee invoice
      ST.C3.1.2.2 Confirm payment
  F.C3.2 — Finalize Admission
    T.C3.2.1 — Complete Enrollment
      ST.C3.2.1.1 Assign class/section
      ST.C3.2.1.2 Generate student ID card
    T.C3.2.2 — Document Submission
      ST.C3.2.2.1 Collect physical documents
      ST.C3.2.2.2 Update mandatory fields

C4 — Student Profile & Record Management (8 sub-tasks)
  F.C4.1 — Student Profile
    T.C4.1.1 — Create Student Profile
      ST.C4.1.1.1 Store personal details
      ST.C4.1.1.2 Store address & emergency contacts
    T.C4.1.2 — Maintain Records
      ST.C4.1.2.1 Track caste/category
      ST.C4.1.2.2 Update health information
  F.C4.2 — Student Documents
    T.C4.2.1 — Upload Documents
      ST.C4.2.1.1 Upload TC/Marksheets
      ST.C4.2.1.2 Upload medical certificate
    T.C4.2.2 — Document Verification
      ST.C4.2.2.1 Approve authenticity
      ST.C4.2.2.2 Update verification status

C5 — Student Promotion & Alumni (8 sub-tasks)
  F.C5.1 — Promotion Processing
    T.C5.1.1 — Generate Promotion List
      ST.C5.1.1.1 Fetch eligible students
      ST.C5.1.1.2 Apply promotion criteria
    T.C5.1.2 — Assign New Class
      ST.C5.1.2.1 Bulk assign promoted class
      ST.C5.1.2.2 Generate new session roll numbers
  F.C5.2 — Alumni Management
    T.C5.2.1 — Mark as Alumni
      ST.C5.2.1.1 Move student to alumni list
      ST.C5.2.1.2 Close active academic records
    T.C5.2.2 — Issue Transfer Certificate
      ST.C5.2.2.1 Generate TC with details
      ST.C5.2.2.2 Track TC issue history

C6 — Syllabus Management (8 sub-tasks)
  [Deferred to Syllabus module — see slb_* tables in existing schema]

C7 — Behavior Assessment (6 sub-tasks)
  F.C7.1 — Incident Management
    T.C7.1.1 — Record Disciplinary Incident
      ST.C7.1.1.1 Log incident type (Bullying, Cheating, Disruption)
      ST.C7.1.1.2 Assign severity level (Low, Medium, High, Critical)
    T.C7.1.2 — Action & Follow-up
      ST.C7.1.2.1 Define corrective actions (Warning, Detention, Suspension)
      ST.C7.1.2.2 Schedule parent meetings and log outcomes
  F.C7.2 — Behavior Analytics
    T.C7.2.1 — Generate Behavior Reports
      ST.C7.2.1.1 Identify patterns (repeat offenders, time/day trends)
      ST.C7.2.1.2 Track improvement over time with behavior scores
```

### Appendix B — Proposed Route Table

See Section 6.1 for the full route table (46 web routes + 5 API routes + 3 public routes).

### Appendix C — Proposed File List

```
Modules/Admission/
├── app/Http/Controllers/
│   ├── AdmissionDashboardController.php     [📐 Proposed]
│   ├── EnquiryController.php                [📐 Proposed]
│   ├── FollowUpController.php               [📐 Proposed]
│   ├── ApplicationController.php           [📐 Proposed]
│   ├── ApplicationDocumentController.php   [📐 Proposed]
│   ├── EntranceTestController.php          [📐 Proposed]
│   ├── MeritListController.php             [📐 Proposed]
│   ├── AllotmentController.php             [📐 Proposed]
│   ├── EnrollmentController.php            [📐 Proposed]
│   ├── PromotionController.php             [📐 Proposed]
│   ├── AlumniController.php                [📐 Proposed]
│   └── BehaviorIncidentController.php      [📐 Proposed]
├── app/Http/Requests/
│   ├── StoreEnquiryRequest.php             [📐 Proposed]
│   ├── StoreApplicationRequest.php         [📐 Proposed]
│   ├── UploadDocumentRequest.php           [📐 Proposed]
│   ├── StoreEntranceTestRequest.php        [📐 Proposed]
│   ├── StoreAllotmentRequest.php           [📐 Proposed]
│   ├── EnrollStudentRequest.php            [📐 Proposed]
│   ├── PromoteStudentsRequest.php          [📐 Proposed]
│   ├── IssueTcRequest.php                  [📐 Proposed]
│   └── StoreIncidentRequest.php            [📐 Proposed]
├── app/Models/
│   ├── AdmissionCycle.php                  [📐 Proposed]
│   ├── DocumentChecklist.php               [📐 Proposed]
│   ├── QuotaConfig.php                     [📐 Proposed]
│   ├── Enquiry.php                         [📐 Proposed]
│   ├── FollowUp.php                        [📐 Proposed]
│   ├── Application.php                     [📐 Proposed]
│   ├── ApplicationDocument.php             [📐 Proposed]
│   ├── ApplicationStage.php                [📐 Proposed]
│   ├── EntranceTest.php                    [📐 Proposed]
│   ├── EntranceTestCandidate.php           [📐 Proposed]
│   ├── MeritList.php                       [📐 Proposed]
│   ├── MeritListEntry.php                  [📐 Proposed]
│   ├── Allotment.php                       [📐 Proposed]
│   ├── PromotionBatch.php                  [📐 Proposed]
│   ├── PromotionRecord.php                 [📐 Proposed]
│   ├── TransferCertificate.php             [📐 Proposed]
│   ├── BehaviorIncident.php                [📐 Proposed]
│   └── BehaviorAction.php                  [📐 Proposed]
├── app/Services/
│   ├── AdmissionPipelineService.php        [📐 Proposed]
│   ├── EnrollmentService.php               [📐 Proposed]
│   ├── MeritListService.php                [📐 Proposed]
│   ├── PromotionService.php                [📐 Proposed]
│   └── TransferCertificateService.php      [📐 Proposed]
├── app/Policies/
│   ├── EnquiryPolicy.php                   [📐 Proposed]
│   ├── ApplicationPolicy.php               [📐 Proposed]
│   ├── AllotmentPolicy.php                 [📐 Proposed]
│   ├── EnrollmentPolicy.php                [📐 Proposed]
│   └── PromotionPolicy.php                 [📐 Proposed]
├── database/migrations/                    [📐 18 migrations]
├── database/seeders/
│   ├── AdmissionDocumentChecklistSeeder.php [📐 Proposed]
│   └── AdmissionQuotaSeeder.php            [📐 Proposed]
├── resources/views/
│   ├── dashboard/index.blade.php           [📐 Proposed]
│   ├── enquiries/index.blade.php           [📐 Proposed]
│   ├── enquiries/create.blade.php          [📐 Proposed]
│   ├── enquiries/show.blade.php            [📐 Proposed]
│   ├── enquiries/public.blade.php          [📐 Proposed]
│   ├── applications/index.blade.php        [📐 Proposed]
│   ├── applications/create.blade.php       [📐 Proposed]
│   ├── applications/show.blade.php         [📐 Proposed]
│   ├── applications/verify.blade.php       [📐 Proposed]
│   ├── applications/schedule.blade.php     [📐 Proposed]
│   ├── applications/status-track.blade.php [📐 Proposed]
│   ├── entrance-tests/index.blade.php      [📐 Proposed]
│   ├── entrance-tests/marks.blade.php      [📐 Proposed]
│   ├── allotment/index.blade.php           [📐 Proposed]
│   ├── allotment/offer-letter.blade.php    [📐 Proposed]
│   ├── enrollment/index.blade.php          [📐 Proposed]
│   ├── enrollment/confirm.blade.php        [📐 Proposed]
│   ├── promotions/wizard.blade.php         [📐 Proposed]
│   ├── promotions/preview.blade.php        [📐 Proposed]
│   ├── alumni/index.blade.php              [📐 Proposed]
│   ├── alumni/tc-preview.blade.php         [📐 Proposed]
│   ├── behavior/index.blade.php            [📐 Proposed]
│   ├── behavior/reports.blade.php          [📐 Proposed]
│   └── partials/
│       ├── _pipeline-card.blade.php        [📐 Proposed]
│       └── _document-checklist.blade.php   [📐 Proposed]
├── routes/
│   ├── web.php                             [📐 Proposed]
│   └── api.php                             [📐 Proposed]
└── tests/
    ├── Feature/
    │   ├── EnquiryTest.php                 [📐 Proposed]
    │   ├── ApplicationTest.php             [📐 Proposed]
    │   ├── DocumentTest.php                [📐 Proposed]
    │   ├── MeritListTest.php               [📐 Proposed]
    │   ├── EnrollmentTest.php              [📐 Proposed]
    │   ├── PromotionTest.php               [📐 Proposed]
    │   └── TransferCertificateTest.php     [📐 Proposed]
    └── Unit/
        ├── AgeEligibilityTest.php          [📐 Proposed]
        ├── MeritRankingTest.php            [📐 Proposed]
        └── RollNumberTest.php              [📐 Proposed]
```

---

*Document generated by Claude Code (Automated Extraction) on 2026-03-25. All items marked 📐 are proposed and have not been implemented.*
