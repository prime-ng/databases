# FrontOffice Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** FOF | **Module Path:** `Modules/FrontOffice` (📐 Not yet created)
**Module Type:** Tenant | **Database:** 📐 Proposed: tenant_db
**Table Prefix:** `fof_*` | **Processing Mode:** RBS_ONLY
**RBS Reference:** Module D — Front Office & Communication (31 sub-tasks, lines 2134–2202)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The FrontOffice module (FOF) digitizes the school reception and front desk operations. In Indian schools, the front office is the first point of contact for visitors, telephone callers, general walk-in enquiries, and incoming/outgoing mail. The FOF module replaces paper-based visitor registers, phone diaries, dispatch/dak registers, and notice boards with a centralized digital system that provides real-time visibility, audit trails, and reporting.

### 1.2 Scope

- **Visitor Management:** Register visitors, capture ID proof, log purpose of visit, generate visitor pass, track in/out time
- **Gate Pass:** Issue and approve gate passes for students and staff leaving campus during school hours
- **Email Communication:** Send bulk/targeted emails to students, staff, and parents with template support
- **SMS Communication:** Send SMS to selected recipients with delivery tracking
- **Complaint Handling:** Register complaints, assign to staff, track resolution
- **Feedback Collection:** Create and distribute feedback forms, collect and report responses
- **Document/Certificate Issuance:** Manage requests for certificates (Bonafide, Character, etc.), approval workflow, PDF generation, and issuance log
- Note: Phone diary, general enquiry register, dak/dispatch register, notice board, and staff movement register are **additional features** proposed beyond the strict RBS scope, based on the Indian school context described in the module brief

### 1.3 Module Statistics

| Metric | Count |
|--------|-------|
| RBS Features (F.D*) | 8 |
| RBS Tasks (T.D*) | 16 |
| RBS Sub-tasks (ST.D*) | 31 |
| 📐 Proposed Tables | 12 |
| 📐 Proposed Controllers | 10 |
| 📐 Proposed Models | 12 |
| 📐 Proposed Services | 4 |
| 📐 Proposed Routes (web) | ~50 |
| 📐 Proposed Routes (api) | ~15 |
| 📐 Proposed UI Screens | 18 |
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
| SchoolSetup (sch_*) | `sch_organizations`, `sch_classes`, `sch_sections` for gate pass context |
| StudentProfile (std_*) | Gate pass for students requires `std_students` FK |
| Notification (ntf_*) | SMS and email dispatch via existing notification infrastructure |
| GlobalMaster (glb_*) | Countries/states for visitor address fields |

> Note: The RBS D2 (Email/SMS Communication) overlaps with the Notification module (NTF). The recommended approach is for FOF to use NTF's infrastructure rather than build parallel email/SMS sending. FOF adds the front-office context (templates, bulk send, ad-hoc) on top of NTF's delivery engine.

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

The school front office (reception) handles dozens of daily operational tasks that are currently paper-based in most Indian schools:

- Every visitor must sign a physical visitor book
- Phone calls are logged in a paper phone diary
- Walk-in enquiries are recorded manually
- Outgoing letters, couriers, and documents are logged in a dispatch/dak register
- Notice board is a physical board updated by hand
- Staff leaving school premises during hours sign a movement register

These manual processes cause audit failures during government inspections, make it impossible to retrieve historical records, and create no real-time visibility. The FOF module eliminates all these gaps.

Additionally, parent-facing certificate requests (Bonafide Certificate, Character Certificate) are common front-office tasks. Schools issue dozens per week. An automated approval-to-PDF pipeline saves significant staff time.

### 2.2 Key Features Summary

| # | Feature Group | Key Capability |
|---|--------------|----------------|
| 1 | Visitor Management | Digital visitor register, photo capture, visitor pass PDF |
| 2 | Gate Pass | Student/staff gate pass with approval workflow |
| 3 | Email Communication | Targeted bulk email with templates |
| 4 | SMS Communication | SMS blast with delivery tracking |
| 5 | Complaint Handling | Register, assign, resolve complaints |
| 6 | Feedback Collection | Create forms, collect responses, generate reports |
| 7 | Certificate Request | Student certificate requests with approval stages |
| 8 | Certificate Issuance | PDF generation, issuance log, certificate number |
| 9 | Phone Diary | Incoming/outgoing call log (📐 proposed beyond RBS) |
| 10 | Dispatch Register | Mail/courier in-out log (📐 proposed beyond RBS) |
| 11 | Notice Board | Digital announcements with expiry (📐 proposed beyond RBS) |
| 12 | Staff Movement | Staff in/out during school hours (📐 proposed beyond RBS) |

### 2.3 Menu Navigation Path

```
Tenant Dashboard
└── Front Office
    ├── Dashboard (today's snapshot)
    ├── Visitors
    │   ├── Today's Visitors
    │   ├── All Visitors
    │   └── Visitor Pass
    ├── Gate Pass
    │   ├── Issue Gate Pass
    │   ├── Pending Approvals
    │   └── Gate Pass History
    ├── Phone Diary
    │   ├── Log Call
    │   └── Call Register
    ├── Communication
    │   ├── Send Email
    │   ├── Email Templates
    │   ├── Send SMS
    │   └── SMS Logs
    ├── Complaints
    │   ├── All Complaints
    │   └── My Assigned
    ├── Feedback
    │   ├── Feedback Forms
    │   └── Responses
    ├── Certificates
    │   ├── Certificate Requests
    │   ├── Issue Certificate
    │   └── Issuance Log
    ├── Dispatch Register
    │   ├── Incoming
    │   └── Outgoing
    ├── Notice Board
    │   ├── Active Notices
    │   └── Create Notice
    └── Staff Movement
```

### 2.4 📐 Proposed Module Architecture

```
Modules/FrontOffice/
├── app/Http/Controllers/
│   ├── FrontOfficeDashboardController.php
│   ├── VisitorController.php
│   ├── GatePassController.php
│   ├── PhoneDiaryController.php
│   ├── CommunicationController.php
│   ├── ComplaintController.php
│   ├── FeedbackController.php
│   ├── CertificateRequestController.php
│   ├── DispatchRegisterController.php
│   └── NoticeBoardController.php
├── app/Http/Requests/
│   ├── RegisterVisitorRequest.php
│   ├── IssueGatePassRequest.php
│   ├── SendBulkEmailRequest.php
│   ├── SendBulkSmsRequest.php
│   ├── StoreComplaintRequest.php
│   ├── StoreFeedbackFormRequest.php
│   ├── RequestCertificateRequest.php
│   └── IssueCertificateRequest.php
├── app/Models/
│   ├── Visitor.php
│   ├── VisitorPurpose.php
│   ├── GatePass.php
│   ├── PhoneDiary.php
│   ├── CommunicationLog.php
│   ├── EmailTemplate.php
│   ├── SmsLog.php
│   ├── FofComplaint.php
│   ├── FeedbackForm.php
│   ├── FeedbackResponse.php
│   ├── CertificateRequest.php
│   └── DispatchRegister.php
├── app/Services/
│   ├── VisitorService.php
│   ├── GatePassService.php
│   ├── CertificateIssuanceService.php
│   └── FrontOfficeCommunicationService.php
├── app/Policies/
│   ├── VisitorPolicy.php
│   ├── GatePassPolicy.php
│   ├── ComplaintPolicy.php
│   └── CertificateRequestPolicy.php
├── database/
│   ├── migrations/
│   └── seeders/
│       ├── VisitorPurposeSeeder.php
│       └── CertificateTypeSeeder.php
├── resources/views/
│   ├── dashboard/
│   ├── visitors/
│   ├── gate-pass/
│   ├── phone-diary/
│   ├── communication/
│   ├── complaints/
│   ├── feedback/
│   ├── certificates/
│   ├── dispatch/
│   ├── notice-board/
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
| School Admin | Full front office management | All CRUD, reports, settings |
| Front Office Staff / Receptionist | Day-to-day front desk operations | Register visitors, log calls, issue gate passes, process certificates |
| Principal / Vice Principal | Gate pass approval authority, complaint oversight | Approve gate passes, view all complaints |
| Teacher | Issue student gate pass requests, register complaints | Create gate pass requests, complaints for own students |
| Student | Request certificates, submit feedback | Self-service certificate request, feedback form submission |
| Parent | Visitor registration, complaint registration | Register as visitor, submit complaints/feedback |
| Communication Manager | Send bulk email/SMS | Compose and send communication |
| System | Automated notifications, visitor pass expiry | Internal triggers |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-FOF-001: Visitor Management (F.D1.1)
**RBS Reference:** F.D1.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_visitors`, `fof_visitor_purposes`

#### Description
Every person entering the school premises must be logged in the digital visitor register. The system captures identity, purpose, contact, and time of entry/exit, and generates a printable visitor pass slip.

#### Requirements

**REQ-FOF-001.1: Register Visitor (T.D1.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Front desk staff registers an incoming visitor with their details, purpose, and the person/department they are visiting |
| Actors | Front Office Staff, Receptionist |
| Preconditions | Front office staff is logged in |
| Input | Visitor name, mobile number, ID proof type (Aadhar/DL/Passport/Voter ID), ID number, address (optional), purpose of visit (from dropdown), person/department to meet, vehicle number (optional), accompanying persons count |
| Processing | Create `fof_visitors` record; auto-set `in_time` = current timestamp; set status = `In`; generate visitor pass number (VP-YYYYMMDD-NNN) |
| Output | Visitor record saved; visitor pass printable from browser |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D1.1.1.1 — Capture visitor name and contact (mobile/phone) → Status: ❌
- [ ] ST.D1.1.1.2 — Log purpose of visit from configured purpose list → Status: ❌
- [ ] ST.D1.1.1.3 — Capture in-time (auto) and out-time (manual at exit) → Status: ❌
- [ ] Visitor pass number auto-generated in format VP-YYYYMMDD-NNN → Status: ❌
- [ ] Visitor list shows all currently-in visitors in real time → Status: ❌
- [ ] Government inspection visits flagged separately → Status: ❌

**REQ-FOF-001.2: Visitor Pass (T.D1.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Generate and print a visitor pass slip for the registered visitor |
| Actors | Front Office Staff |
| Preconditions | Visitor registered |
| Input | No additional input — uses registered visitor data |
| Processing | Render visitor pass HTML/PDF with visitor name, pass number, purpose, in-time, valid until (e.g., end of school day), school name/logo |
| Output | Printable visitor pass PDF (A6/half-page format) |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D1.1.2.1 — Generate visitor pass with name, purpose, pass number, in-time, valid until → Status: ❌
- [ ] ST.D1.1.2.2 — Print visitor pass slip from browser (print-optimized layout) → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | VisitorController | index, create, store, show, checkout, pass | Visitor CRUD + checkout |
| Service | VisitorService | register, generatePass, checkout, todayStats | Business logic |
| FormRequest | RegisterVisitorRequest | rules() | Required fields validation |
| Policy | VisitorPolicy | viewAny, create, update | Authorization |
| View | visitors/index.blade.php | — | Today's visitor list with live checkout |
| View | visitors/create.blade.php | — | Walk-in registration form |
| View | visitors/pass.blade.php | — | Print-optimized visitor pass |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Register visitor — record created, in-time set, pass number generated | Feature | High |
| 2 | Check out visitor — out-time recorded, status set to Out | Feature | High |
| 3 | Visitor pass PDF renders with correct data | Feature | Medium |
| 4 | Today's visitor count matches registrations for the day | Unit | Medium |

---

### FR-FOF-002: Gate Pass (F.D1.2)
**RBS Reference:** F.D1.2
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_gate_passes`

#### Description
Students or staff who need to leave school premises during school hours require a gate pass. The pass is created at the front desk (or by a teacher for students), requires authority approval, and is tracked for audit purposes.

#### Requirements

**REQ-FOF-002.1: Issue Gate Pass (T.D1.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Create a gate pass for a student or staff member with the reason for exit and expected return time |
| Actors | Front Office Staff, Class Teacher |
| Preconditions | Student record exists in `std_students`; staff record exists |
| Input | Person type (Student/Staff), person ID, exit purpose (from dropdown: Medical/Personal/Official/Sports/Other), exit time, expected return time, parent/guardian notified (boolean for students) |
| Processing | Create `fof_gate_passes` record; set status = `Pending_Approval`; notify approval authority |
| Output | Gate pass record created; approval request sent to authority |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D1.2.1.1 — Create gate pass for student or staff with person type, ID, and exit purpose → Status: ❌
- [ ] ST.D1.2.1.2 — Capture exit purpose from configured list → Status: ❌
- [ ] For student gate passes — parent notification dispatched automatically → Status: ❌

**REQ-FOF-002.2: Gate Pass Approval (T.D1.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Designated authority (Principal, VP, HOD) reviews the gate pass request and approves or rejects it |
| Actors | Principal, Vice Principal, HOD |
| Preconditions | Gate pass in Pending_Approval status |
| Input | Decision (Approved/Rejected), remarks |
| Processing | Update `fof_gate_passes.status`; set `approved_by`, `approved_at`; if approved — notify front desk to let person out |
| Output | Gate pass status updated; front desk notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D1.2.2.1 — Approval authority receives notification of pending gate pass → Status: ❌
- [ ] ST.D1.2.2.2 — Approved/Rejected decision recorded with timestamp and authority name → Status: ❌
- [ ] Approved gate pass printable as a physical slip → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | GatePassController | index, create, store, approve, reject, markReturned | Gate pass lifecycle |
| Service | GatePassService | createPass, sendApprovalRequest, approvePass, markReturned | Business logic |
| FormRequest | IssueGatePassRequest | rules() | Person ID validation |
| Policy | GatePassPolicy | create, approve | Role-based authorization |
| View | gate-pass/index.blade.php | — | Pending/approved/history list |
| View | gate-pass/create.blade.php | — | Gate pass form |

---

### FR-FOF-003: Email Communication (F.D2.1)
**RBS Reference:** F.D2.1
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_communication_logs`, `fof_email_templates`

#### Description
Front office staff can compose and send bulk or targeted emails to students, staff, or parents. Email templates can be created and saved for reuse (e.g., holiday notices, event announcements).

> **Integration Note:** This feature should use the existing Notification module's email channel (`ntf_*`) for actual delivery. FOF adds the composition UI and templates on top of NTF infrastructure. `fof_communication_logs` acts as a front-office audit log separate from NTF delivery logs.

#### Requirements

**REQ-FOF-003.1: Send Email (T.D2.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Compose an email and send to one or more recipient groups |
| Actors | Communication Manager, School Admin, Front Office Staff |
| Preconditions | NTF email channel is configured and active |
| Input | Subject, body (rich text), recipient type (Students/Staff/Parents/Specific), recipient filter (class, section, all), attachments (optional) |
| Processing | Resolve recipient list from recipient type + filter; dispatch via NTF module; log in `fof_communication_logs` |
| Output | Email dispatched; log entry created with recipient count |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D2.1.1.1 — Select recipients by type (Students/Staff/Parents) and filter by class/section/all → Status: ❌
- [ ] ST.D2.1.1.2 — Attach documents (PDF, Word) up to 10MB total → Status: ❌
- [ ] Recipient count shown before send for confirmation → Status: ❌
- [ ] Communication log records sender, subject, recipient count, sent-at timestamp → Status: ❌

**REQ-FOF-003.2: Email Templates (T.D2.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Create reusable email templates with placeholder support |
| Actors | Communication Manager, School Admin |
| Preconditions | None |
| Input | Template name, subject template, body template (with {{student_name}}, {{class}}, {{date}} placeholders) |
| Processing | Save to `fof_email_templates`; validate placeholder syntax |
| Output | Template saved; available in email compose form |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D2.1.2.1 — Create email template with name, subject, and rich-text body → Status: ❌
- [ ] ST.D2.1.2.2 — Template saved and available for selection in compose screen → Status: ❌
- [ ] Template placeholders ({{student_name}}, {{date}}) resolved at send time → Status: ❌

---

### FR-FOF-004: SMS Communication (F.D2.2)
**RBS Reference:** F.D2.2
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_sms_logs`

#### Requirements

**REQ-FOF-004.1: Send SMS (T.D2.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Compose and send a bulk SMS to selected recipients using the configured SMS gateway |
| Actors | Communication Manager, School Admin |
| Preconditions | SMS provider configured in NTF channel settings |
| Input | Message text (max 160 chars per SMS, multi-SMS supported), recipient type and filter |
| Processing | Resolve recipient mobile numbers; dispatch via NTF SMS channel; log in `fof_sms_logs` |
| Output | SMS dispatched; delivery status tracked via webhook |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D2.2.1.1 — Compose SMS message with character counter → Status: ❌
- [ ] ST.D2.2.1.2 — Select recipients by type (Students/Staff/Parents) and filter → Status: ❌
- [ ] SMS count (number of messages × recipients) shown before send → Status: ❌

**REQ-FOF-004.2: SMS Logs (T.D2.2.2)**

**Acceptance Criteria:**
- [ ] ST.D2.2.2.1 — Track delivery status per recipient (Sent/Delivered/Failed) via gateway callback → Status: ❌
- [ ] ST.D2.2.2.2 — Download SMS delivery report as CSV/Excel → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | CommunicationController | emailIndex, emailCompose, emailSend, smsIndex, smsCompose, smsSend, smsLogs | All comms |
| Service | FrontOfficeCommunicationService | sendBulkEmail, sendBulkSms, resolveRecipients, logCommunication | Dispatch + logging |
| FormRequest | SendBulkEmailRequest | rules() | Validation |
| FormRequest | SendBulkSmsRequest | rules() | Character count, recipient validation |
| View | communication/email-compose.blade.php | — | Email composer with template picker |
| View | communication/sms-compose.blade.php | — | SMS composer with char counter |
| View | communication/sms-logs.blade.php | — | Delivery status log |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Send email to all parents — recipient list resolved correctly | Feature | High |
| 2 | Email template placeholder resolved to actual student name at send time | Unit | Medium |
| 3 | SMS character count exceeds 160 — multi-SMS count shown | Unit | Medium |
| 4 | SMS delivery log updated on gateway webhook callback | Feature | Medium |

---

### FR-FOF-005: Complaint Handling (F.D3.1)
**RBS Reference:** F.D3.1
**Priority:** 🟡 Medium
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_complaints`

> **Note:** The main Complaint module (CMP) already exists in the tenant_db schema (`cmp_*`). The FOF complaint feature covers front-office-registered complaints (walk-in, phone) as a separate lighter-weight workflow. For complex escalations, FOF complaints should be linkable to CMP entries.

#### Requirements

**REQ-FOF-005.1: Register Complaint (T.D3.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Register a complaint received at the front desk from a parent, student, or visitor |
| Actors | Front Office Staff |
| Preconditions | None (complaints can be anonymous) |
| Input | Complainant name, contact, complaint type (Academic/Facility/Staff Behavior/Fee/Safety/Other), description, urgency (Normal/Urgent/Critical), assigned to (staff user) |
| Processing | Create `fof_complaints` record; auto-generate complaint number (CMP-YYYY-NNNNN); notify assigned staff |
| Output | Complaint registered; assigned staff notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D3.1.1.1 — Enter complainant details and complaint description → Status: ❌
- [ ] ST.D3.1.1.2 — Assign complaint to a staff member for resolution → Status: ❌
- [ ] Complaint number auto-generated; acknowledgment slippable for complainant → Status: ❌

**REQ-FOF-005.2: Complaint Resolution (T.D3.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Assigned staff updates resolution status and adds resolution notes |
| Actors | Assigned Staff, School Admin |
| Preconditions | Complaint assigned |
| Input | Status (In_Progress/Resolved/Escalated), resolution notes, resolution date |
| Processing | Update `fof_complaints.status`; log status change with timestamp |
| Output | Complaint status updated; complainant optionally notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D3.1.2.1 — Update resolution status (In Progress/Resolved/Escalated) with notes → Status: ❌
- [ ] ST.D3.1.2.2 — Add resolution notes and date; complainant notified on resolution → Status: ❌

---

### FR-FOF-006: Feedback Collection (F.D3.2)
**RBS Reference:** F.D3.2
**Priority:** 🟢 Low
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_feedback_forms`, `fof_feedback_responses`

#### Requirements

**REQ-FOF-006.1: Collect Feedback (T.D3.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Create feedback forms and distribute them to target groups; collect and aggregate responses |
| Actors | School Admin, Front Office Staff |
| Preconditions | None |
| Input | Form title, description, questions (text/rating/multiple choice), target audience, open/close dates |
| Processing | Create `fof_feedback_forms` with questions stored as `questions_json`; distribute via link/email/SMS; collect `fof_feedback_responses` |
| Output | Responses collected; summary report with ratings and text responses |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D3.2.1.1 — Create feedback form with title and questions (rating scale, text, MCQ) → Status: ❌
- [ ] ST.D3.2.1.2 — Collect responses; view aggregated report (average ratings, response count) → Status: ❌
- [ ] Anonymous feedback option available → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | FeedbackController | index, create, store, show, respond, report | Form + response management |
| View | feedback/create.blade.php | — | Form builder |
| View | feedback/respond.blade.php | — | Respondent form (public link) |
| View | feedback/report.blade.php | — | Aggregated response report |

---

### FR-FOF-007: Certificate Request (F.D4.1)
**RBS Reference:** F.D4.1
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_certificate_requests`

#### Description
Students and parents frequently request official certificates from the front office — Bonafide Certificate, Character Certificate, Fee Paid Certificate, Study Certificate, etc. The FOF module manages the request-to-issuance workflow with an approval stage.

#### Requirements

**REQ-FOF-007.1: Request Certificate (T.D4.1.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Student or parent submits a certificate request at the front desk or online |
| Actors | Front Office Staff, Student (self-service), Parent |
| Preconditions | Student must be enrolled (`std_students` record exists) |
| Input | Student ID (or admission number), certificate type (Bonafide/Character/Fee_Paid/Study/TC_Copy/Other), purpose of certificate, number of copies, urgent (boolean), applicant contact |
| Processing | Create `fof_certificate_requests` record; set status = `Pending_Approval`; generate request number (CERT-YYYY-NNNNN); notify approver |
| Output | Request record created; acknowledgment slip available |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D4.1.1.1 — Student or parent submits certificate request at front desk or online → Status: ❌
- [ ] ST.D4.1.1.2 — Select certificate type from configured list (Bonafide, Character, Fee Paid, etc.) → Status: ❌
- [ ] Request number auto-generated; acknowledgment slip printable → Status: ❌
- [ ] Urgent flag escalates approval priority → Status: ❌

**REQ-FOF-007.2: Approval Workflow (T.D4.1.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Multi-stage approval: Front Office verifies → Principal/authority approves → Issue |
| Actors | Front Office Staff, Principal |
| Preconditions | Certificate request in Pending_Approval |
| Input | Decision (Approved/Rejected), remarks, conditions if any |
| Processing | Update `fof_certificate_requests.status`; log stage in `certificate_stages_json`; notify student/parent |
| Output | Status updated; student notified |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D4.1.2.1 — Send approval request to configured authority → Status: ❌
- [ ] ST.D4.1.2.2 — Track approval stages with timestamps → Status: ❌

---

### FR-FOF-008: Certificate Issuance (F.D4.2)
**RBS Reference:** F.D4.2
**Priority:** 🔴 High
**Status:** ❌ Not Started
**Table(s):** 📐 Proposed: `fof_certificate_requests` (status update)

#### Requirements

**REQ-FOF-008.1: Issue Certificate (T.D4.2.1)**

| Attribute | Detail |
|-----------|--------|
| Description | Generate the certificate PDF and record handover to the student/parent |
| Actors | Front Office Staff |
| Preconditions | Certificate request in Approved status |
| Input | Issue date, receiver name (may differ from student), receiver signature collected (checkbox) |
| Processing | Generate certificate PDF via DomPDF using pre-configured template per certificate type; store in `sys_media`; update `fof_certificate_requests.status` = Issued |
| Output | Certificate PDF downloadable/printable; issuance record logged |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D4.2.1.1 — Generate certificate PDF with school letterhead, student name, class, and appropriate content per certificate type → Status: ❌
- [ ] ST.D4.2.1.2 — Print and record physical handover with receiver name → Status: ❌

**REQ-FOF-008.2: Record Issuance (T.D4.2.2)**

| Attribute | Detail |
|-----------|--------|
| Description | Log certificate issuance for audit — certificate number, issue date, receiver |
| Actors | Front Office Staff |
| Preconditions | Certificate issued |
| Input | Certificate number (auto-generated), issue date, receiver details |
| Processing | Finalize `fof_certificate_requests` with `cert_number`, `issued_at`, `issued_to`, `media_id` |
| Output | Issuance log updated; searchable by certificate number |
| Status | ❌ Not Started |

**Acceptance Criteria:**
- [ ] ST.D4.2.2.1 — Log unique certificate number (e.g., BON-YYYY-NNN) in issuance register → Status: ❌
- [ ] ST.D4.2.2.2 — Issuance date and time stored; searchable in issuance log → Status: ❌

**📐 Proposed Implementation:**

| Layer | Proposed File | Proposed Method | Responsibility |
|-------|--------------|-----------------|----------------|
| Controller | CertificateRequestController | index, create, store, approve, reject, issue, download, log | Full certificate lifecycle |
| Service | CertificateIssuanceService | generatePdf, assignCertNumber, recordIssuance | PDF + issuance logic |
| FormRequest | RequestCertificateRequest | rules() | Student ID, cert type validation |
| FormRequest | IssueCertificateRequest | rules() | Issue date, receiver validation |
| Policy | CertificateRequestPolicy | create, approve, issue | Role-based authorization |
| View | certificates/index.blade.php | — | Request queue |
| View | certificates/create.blade.php | — | New request form |
| View | certificates/issue.blade.php | — | Issue confirmation + PDF preview |
| View | certificates/log.blade.php | — | Issuance history with search |

**Required Test Cases:**

| # | Scenario | Type | Priority |
|---|----------|------|----------|
| 1 | Request certificate — record created, request number assigned | Feature | High |
| 2 | Approve certificate — status updated to Approved, applicant notified | Feature | High |
| 3 | Issue Bonafide certificate — PDF generated with student name, class, school letterhead | Feature | High |
| 4 | Certificate number is unique per type per school-year | Unit | High |
| 5 | Reject certificate request — rejection reason stored, applicant notified | Feature | Medium |

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 📐 Proposed Entity Overview

| Table | Description | Approx. Rows/School/Year |
|-------|-------------|--------------------------|
| `fof_visitor_purposes` | Lookup: purpose of visit | 10–20 |
| `fof_visitors` | Visitor register | 2,000–15,000 |
| `fof_gate_passes` | Student/staff gate passes | 200–2,000 |
| `fof_phone_diary` | Incoming/outgoing call log | 1,000–5,000 |
| `fof_communication_logs` | Bulk email/SMS log | 100–500 |
| `fof_email_templates` | Reusable email templates | 10–50 |
| `fof_sms_logs` | Per-recipient SMS delivery log | 5,000–50,000 |
| `fof_complaints` | Front-office complaint register | 50–500 |
| `fof_feedback_forms` | Feedback form definitions | 5–20 |
| `fof_feedback_responses` | Responses per form | 100–2,000 |
| `fof_certificate_requests` | Certificate request + issuance log | 100–1,000 |
| `fof_dispatch_register` | Mail/courier in-out log | 200–2,000 |

### 5.2 📐 Detailed Entity Specification

---

#### `fof_visitor_purposes`
Lookup table for purpose of visit — seeded with common values, school-configurable.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Parent Meeting", "Government Inspection", "Delivery" |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE | e.g., "PARENT_MTG", "GOVT_INSPECT" |
| `is_government_visit` | TINYINT(1) | NOT NULL DEFAULT 0 | Flag for special handling |
| `sort_order` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Seeded values:** Parent Meeting, Government Inspection, Job Interview, Delivery/Courier, Sales Visit, Religious/Cultural Visit, Alumni Visit, Emergency, Other

---

#### `fof_visitors`
Daily visitor register.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `pass_number` | VARCHAR(25) | NOT NULL, UNIQUE | VP-YYYYMMDD-NNN |
| `visitor_name` | VARCHAR(100) | NOT NULL | |
| `visitor_mobile` | VARCHAR(15) | NOT NULL | |
| `visitor_email` | VARCHAR(100) | NULL | |
| `id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other') | NULL | |
| `id_proof_number` | VARCHAR(50) | NULL | |
| `address` | VARCHAR(200) | NULL | |
| `organization` | VARCHAR(100) | NULL | Visitor's company/institution |
| `purpose_id` | BIGINT UNSIGNED | NOT NULL, FK→fof_visitor_purposes | |
| `person_to_meet` | VARCHAR(100) | NULL | Name of person/dept to visit |
| `meet_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | If meeting a specific user |
| `vehicle_number` | VARCHAR(20) | NULL | |
| `accompanying_count` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | Additional persons |
| `in_time` | DATETIME | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| `out_time` | DATETIME | NULL | |
| `status` | ENUM('In','Out','Overstay') | NOT NULL DEFAULT 'In' | |
| `notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | Front desk staff |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_fof_vis_date` (`DATE(in_time)`), `idx_fof_vis_status` (`status`), `idx_fof_vis_mobile` (`visitor_mobile`)

---

#### `fof_gate_passes`
Student and staff gate passes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `pass_number` | VARCHAR(25) | NOT NULL, UNIQUE | GP-YYYYMMDD-NNN |
| `person_type` | ENUM('Student','Staff') | NOT NULL | |
| `student_id` | INT UNSIGNED | NULL, FK→std_students | Populated if Student |
| `staff_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | Populated if Staff |
| `purpose` | ENUM('Medical','Personal','Official','Sports','Family_Emergency','Other') | NOT NULL | |
| `purpose_details` | VARCHAR(200) | NULL | |
| `exit_time` | DATETIME | NULL | Actual exit time |
| `expected_return_time` | DATETIME | NULL | |
| `actual_return_time` | DATETIME | NULL | |
| `parent_notified` | TINYINT(1) | NOT NULL DEFAULT 0 | For student passes |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled') | NOT NULL DEFAULT 'Pending_Approval' | |
| `approved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `approved_at` | DATETIME | NULL | |
| `rejection_reason` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_fof_gp_date` (`DATE(created_at)`), `idx_fof_gp_student` (`student_id`), `idx_fof_gp_status` (`status`)

---

#### `fof_phone_diary`
Incoming and outgoing phone call log.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `call_type` | ENUM('Incoming','Outgoing') | NOT NULL | |
| `call_date` | DATE | NOT NULL | |
| `call_time` | TIME | NOT NULL | |
| `caller_name` | VARCHAR(100) | NOT NULL | |
| `caller_number` | VARCHAR(15) | NULL | |
| `caller_organization` | VARCHAR(100) | NULL | |
| `recipient_name` | VARCHAR(100) | NULL | Who took/made the call |
| `recipient_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `purpose` | VARCHAR(200) | NOT NULL | |
| `message` | TEXT | NULL | Summary of call |
| `action_required` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `action_notes` | TEXT | NULL | |
| `logged_by` | BIGINT UNSIGNED | NULL, FK→sys_users | Front desk staff |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

**Indexes:** `idx_fof_pd_date` (`call_date`), `idx_fof_pd_type` (`call_type`)

---

#### `fof_communication_logs`
Audit log for bulk email/SMS sent from FOF.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `channel` | ENUM('Email','SMS','WhatsApp') | NOT NULL | |
| `subject` | VARCHAR(255) | NULL | For email |
| `message` | TEXT | NOT NULL | |
| `template_id` | BIGINT UNSIGNED | NULL, FK→fof_email_templates | |
| `recipient_type` | ENUM('All_Students','All_Staff','All_Parents','Specific_Class','Specific_Section','Custom') | NOT NULL | |
| `recipient_filter_json` | JSON | NULL | Class IDs, section IDs for filtered sends |
| `total_recipients` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `sent_count` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `failed_count` | INT UNSIGNED | NOT NULL DEFAULT 0 | |
| `sent_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `sent_at` | TIMESTAMP | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_email_templates`
Reusable email templates for front office communications.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `name` | VARCHAR(100) | NOT NULL | Template name |
| `category` | ENUM('Holiday','Event','Notice','Fee_Reminder','Certificate','Admission','Other') | NOT NULL DEFAULT 'Other' | |
| `subject_template` | VARCHAR(255) | NOT NULL | May contain {{placeholders}} |
| `body_template` | LONGTEXT | NOT NULL | HTML/rich text with {{placeholders}} |
| `placeholders_json` | JSON | NULL | Documentation of available placeholders |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_sms_logs`
Per-recipient SMS delivery records.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `communication_log_id` | BIGINT UNSIGNED | NOT NULL, FK→fof_communication_logs | Parent bulk send |
| `recipient_mobile` | VARCHAR(15) | NOT NULL | |
| `recipient_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `message` | TEXT | NOT NULL | Resolved message |
| `gateway_message_id` | VARCHAR(100) | NULL | From SMS provider |
| `status` | ENUM('Queued','Sent','Delivered','Failed','Rejected') | NOT NULL DEFAULT 'Queued' | |
| `status_updated_at` | TIMESTAMP | NULL | |
| `error_message` | VARCHAR(255) | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_complaints`
Front-office complaint register.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `complaint_number` | VARCHAR(20) | NOT NULL, UNIQUE | FOF-CMP-YYYY-NNNNN |
| `complainant_name` | VARCHAR(100) | NOT NULL | |
| `complainant_mobile` | VARCHAR(15) | NULL | |
| `complainant_email` | VARCHAR(100) | NULL | |
| `complainant_type` | ENUM('Parent','Student','Staff','Visitor','Anonymous') | NOT NULL DEFAULT 'Parent' | |
| `complaint_type` | ENUM('Academic','Facility','Staff_Behavior','Fee','Safety','Transportation','Food','Hygiene','Other') | NOT NULL | |
| `description` | TEXT | NOT NULL | |
| `urgency` | ENUM('Normal','Urgent','Critical') | NOT NULL DEFAULT 'Normal' | |
| `assigned_to` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `status` | ENUM('Open','In_Progress','Resolved','Escalated','Closed') | NOT NULL DEFAULT 'Open' | |
| `resolution_notes` | TEXT | NULL | |
| `resolved_at` | DATETIME | NULL | |
| `resolved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `cmp_complaint_id` | BIGINT UNSIGNED | NULL | FK to cmp_complaints if escalated |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_feedback_forms`
Feedback form definitions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `title` | VARCHAR(150) | NOT NULL | |
| `description` | TEXT | NULL | |
| `target_audience` | ENUM('Parents','Students','Staff','All','Custom') | NOT NULL DEFAULT 'All' | |
| `questions_json` | JSON | NOT NULL | Array of {id, type, text, options[], required} |
| `opens_at` | DATETIME | NULL | |
| `closes_at` | DATETIME | NULL | |
| `is_anonymous` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `access_link` | VARCHAR(100) | NULL, UNIQUE | Short URL token |
| `status` | ENUM('Draft','Active','Closed') | NOT NULL DEFAULT 'Draft' | |
| `response_count` | INT UNSIGNED | NOT NULL DEFAULT 0 | Denormalized counter |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_feedback_responses`
Individual form responses.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `form_id` | BIGINT UNSIGNED | NOT NULL, FK→fof_feedback_forms | |
| `respondent_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | NULL if anonymous |
| `respondent_name` | VARCHAR(100) | NULL | If not anonymous |
| `answers_json` | JSON | NOT NULL | Array of {question_id, answer} |
| `submitted_at` | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| `ip_address` | VARCHAR(45) | NULL | For deduplication |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_certificate_requests`
Certificate request + issuance log (combined table).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `request_number` | VARCHAR(25) | NOT NULL, UNIQUE | CERT-YYYY-NNNNN |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `cert_type` | ENUM('Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other') | NOT NULL | |
| `purpose` | VARCHAR(200) | NOT NULL | Why certificate is needed |
| `copies_requested` | TINYINT UNSIGNED | NOT NULL DEFAULT 1 | |
| `is_urgent` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `applicant_name` | VARCHAR(100) | NULL | If different from student |
| `applicant_contact` | VARCHAR(15) | NULL | |
| `stages_json` | JSON | NULL | Array of {stage, status, by, at, remarks} |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Issued','Cancelled') | NOT NULL DEFAULT 'Pending_Approval' | |
| `approved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `approved_at` | DATETIME | NULL | |
| `rejection_reason` | TEXT | NULL | |
| `cert_number` | VARCHAR(30) | NULL, UNIQUE | BON-YYYY-NNN, CHAR-YYYY-NNN, etc. |
| `issued_at` | DATETIME | NULL | |
| `issued_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `issued_to` | VARCHAR(100) | NULL | Receiver name |
| `media_id` | INT UNSIGNED | NULL, FK→sys_media | PDF file |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_dispatch_register`
Incoming and outgoing mail/courier/document register.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `dispatch_type` | ENUM('Incoming','Outgoing') | NOT NULL | |
| `dispatch_date` | DATE | NOT NULL | |
| `dispatch_number` | VARCHAR(30) | NOT NULL, UNIQUE | IN-YYYY-NNNN or OUT-YYYY-NNNN |
| `sender_name` | VARCHAR(100) | NULL | For incoming |
| `sender_address` | VARCHAR(200) | NULL | |
| `recipient_name` | VARCHAR(100) | NULL | For outgoing |
| `recipient_address` | VARCHAR(200) | NULL | |
| `subject` | VARCHAR(200) | NOT NULL | |
| `document_type` | ENUM('Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other') | NOT NULL | |
| `courier_company` | VARCHAR(100) | NULL | |
| `tracking_number` | VARCHAR(100) | NULL | |
| `department` | VARCHAR(100) | NULL | School dept concerned |
| `assigned_to_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | Staff to handle |
| `acknowledgement_by` | VARCHAR(100) | NULL | Who received/signed |
| `acknowledged_at` | DATETIME | NULL | |
| `remarks` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

### 5.3 📐 Entity Relationship Summary

```
fof_visitor_purposes
    └── fof_visitors (M:1)

sys_users ←─── fof_visitors (meet_user_id)
std_students ←─ fof_gate_passes (student_id)
sys_users ←─── fof_gate_passes (staff_user_id, approved_by)

fof_email_templates
    └── fof_communication_logs (template_id)
            └── fof_sms_logs (communication_log_id)

sys_users ←─── fof_complaints (assigned_to, resolved_by)

fof_feedback_forms
    └── fof_feedback_responses (form_id)

std_students ←─ fof_certificate_requests (student_id)
sys_users ←─── fof_certificate_requests (approved_by, issued_by)
sys_media ←─── fof_certificate_requests (media_id)
```

### 5.5 📐 Proposed Migration Order

1. `fof_visitor_purposes`
2. `fof_visitors`
3. `fof_gate_passes`
4. `fof_phone_diary`
5. `fof_email_templates`
6. `fof_communication_logs`
7. `fof_sms_logs`
8. `fof_complaints`
9. `fof_feedback_forms`
10. `fof_feedback_responses`
11. `fof_certificate_requests`
12. `fof_dispatch_register`

---

## 6. 📐 API & ROUTE SPECIFICATION

### 6.1 Proposed Route Summary

| # | Method | URI | Controller@Method | Name |
|---|--------|-----|-------------------|------|
| 1 | GET | `/front-office` | FrontOfficeDashboardController@index | fof.dashboard |
| 2 | GET | `/front-office/visitors` | VisitorController@index | fof.visitors.index |
| 3 | GET | `/front-office/visitors/create` | VisitorController@create | fof.visitors.create |
| 4 | POST | `/front-office/visitors` | VisitorController@store | fof.visitors.store |
| 5 | GET | `/front-office/visitors/{id}` | VisitorController@show | fof.visitors.show |
| 6 | POST | `/front-office/visitors/{id}/checkout` | VisitorController@checkout | fof.visitors.checkout |
| 7 | GET | `/front-office/visitors/{id}/pass` | VisitorController@pass | fof.visitors.pass |
| 8 | GET | `/front-office/gate-passes` | GatePassController@index | fof.gate-passes.index |
| 9 | GET | `/front-office/gate-passes/create` | GatePassController@create | fof.gate-passes.create |
| 10 | POST | `/front-office/gate-passes` | GatePassController@store | fof.gate-passes.store |
| 11 | POST | `/front-office/gate-passes/{id}/approve` | GatePassController@approve | fof.gate-passes.approve |
| 12 | POST | `/front-office/gate-passes/{id}/reject` | GatePassController@reject | fof.gate-passes.reject |
| 13 | POST | `/front-office/gate-passes/{id}/returned` | GatePassController@markReturned | fof.gate-passes.returned |
| 14 | GET | `/front-office/phone-diary` | PhoneDiaryController@index | fof.phone.index |
| 15 | POST | `/front-office/phone-diary` | PhoneDiaryController@store | fof.phone.store |
| 16 | PATCH | `/front-office/phone-diary/{id}` | PhoneDiaryController@update | fof.phone.update |
| 17 | GET | `/front-office/communication/email` | CommunicationController@emailIndex | fof.comm.email.index |
| 18 | GET | `/front-office/communication/email/compose` | CommunicationController@emailCompose | fof.comm.email.compose |
| 19 | POST | `/front-office/communication/email/send` | CommunicationController@emailSend | fof.comm.email.send |
| 20 | GET | `/front-office/communication/email/templates` | CommunicationController@templateIndex | fof.comm.templates.index |
| 21 | POST | `/front-office/communication/email/templates` | CommunicationController@templateStore | fof.comm.templates.store |
| 22 | PATCH | `/front-office/communication/email/templates/{id}` | CommunicationController@templateUpdate | fof.comm.templates.update |
| 23 | GET | `/front-office/communication/sms` | CommunicationController@smsIndex | fof.comm.sms.index |
| 24 | POST | `/front-office/communication/sms/send` | CommunicationController@smsSend | fof.comm.sms.send |
| 25 | GET | `/front-office/communication/sms/logs` | CommunicationController@smsLogs | fof.comm.sms.logs |
| 26 | GET | `/front-office/complaints` | ComplaintController@index | fof.complaints.index |
| 27 | POST | `/front-office/complaints` | ComplaintController@store | fof.complaints.store |
| 28 | GET | `/front-office/complaints/{id}` | ComplaintController@show | fof.complaints.show |
| 29 | PATCH | `/front-office/complaints/{id}/resolve` | ComplaintController@resolve | fof.complaints.resolve |
| 30 | GET | `/front-office/feedback` | FeedbackController@index | fof.feedback.index |
| 31 | POST | `/front-office/feedback` | FeedbackController@store | fof.feedback.store |
| 32 | GET | `/front-office/feedback/{id}` | FeedbackController@show | fof.feedback.show |
| 33 | GET | `/front-office/feedback/{id}/report` | FeedbackController@report | fof.feedback.report |
| 34 | GET | `/front-office/certificates` | CertificateRequestController@index | fof.certs.index |
| 35 | POST | `/front-office/certificates` | CertificateRequestController@store | fof.certs.store |
| 36 | GET | `/front-office/certificates/{id}` | CertificateRequestController@show | fof.certs.show |
| 37 | POST | `/front-office/certificates/{id}/approve` | CertificateRequestController@approve | fof.certs.approve |
| 38 | POST | `/front-office/certificates/{id}/reject` | CertificateRequestController@reject | fof.certs.reject |
| 39 | POST | `/front-office/certificates/{id}/issue` | CertificateRequestController@issue | fof.certs.issue |
| 40 | GET | `/front-office/certificates/{id}/download` | CertificateRequestController@download | fof.certs.download |
| 41 | GET | `/front-office/certificates/log` | CertificateRequestController@log | fof.certs.log |
| 42 | GET | `/front-office/dispatch` | DispatchRegisterController@index | fof.dispatch.index |
| 43 | POST | `/front-office/dispatch` | DispatchRegisterController@store | fof.dispatch.store |
| 44 | PATCH | `/front-office/dispatch/{id}` | DispatchRegisterController@update | fof.dispatch.update |
| — | — | **Public Routes** | — | — |
| P1 | GET | `/feedback/{token}` | FeedbackController@publicForm | fof.public.feedback |
| P2 | POST | `/feedback/{token}` | FeedbackController@publicSubmit | fof.public.feedback.submit |

### 6.3 Proposed Route Group Structure

```php
// Public routes — no auth required
Route::prefix('feedback')->name('fof.public.')->group(function () {
    Route::get('/{token}', [FeedbackController::class, 'publicForm'])->name('feedback');
    Route::post('/{token}', [FeedbackController::class, 'publicSubmit'])->name('feedback.submit');
});

// Authenticated tenant routes
Route::middleware(['auth', 'tenant'])->prefix('front-office')->name('fof.')->group(function () {
    Route::get('/', [FrontOfficeDashboardController::class, 'index'])->name('dashboard');

    // Visitors
    Route::prefix('visitors')->name('visitors.')->group(function () {
        Route::get('/', [VisitorController::class, 'index'])->name('index');
        Route::get('/create', [VisitorController::class, 'create'])->name('create');
        Route::post('/', [VisitorController::class, 'store'])->name('store');
        Route::get('/{id}', [VisitorController::class, 'show'])->name('show');
        Route::post('/{id}/checkout', [VisitorController::class, 'checkout'])->name('checkout');
        Route::get('/{id}/pass', [VisitorController::class, 'pass'])->name('pass');
    });

    // Gate Passes
    Route::prefix('gate-passes')->name('gate-passes.')->group(function () {
        Route::get('/', [GatePassController::class, 'index'])->name('index');
        Route::get('/create', [GatePassController::class, 'create'])->name('create');
        Route::post('/', [GatePassController::class, 'store'])->name('store');
        Route::post('/{id}/approve', [GatePassController::class, 'approve'])->name('approve');
        Route::post('/{id}/reject', [GatePassController::class, 'reject'])->name('reject');
        Route::post('/{id}/returned', [GatePassController::class, 'markReturned'])->name('returned');
    });

    // Phone Diary
    Route::resource('phone-diary', PhoneDiaryController::class)->only(['index', 'store', 'update']);

    // Communication
    Route::prefix('communication')->name('comm.')->group(function () {
        Route::get('/email', [CommunicationController::class, 'emailIndex'])->name('email.index');
        Route::get('/email/compose', [CommunicationController::class, 'emailCompose'])->name('email.compose');
        Route::post('/email/send', [CommunicationController::class, 'emailSend'])->name('email.send');
        Route::resource('/email/templates', EmailTemplateController::class)->only(['index', 'store', 'update', 'destroy']);
        Route::get('/sms', [CommunicationController::class, 'smsIndex'])->name('sms.index');
        Route::post('/sms/send', [CommunicationController::class, 'smsSend'])->name('sms.send');
        Route::get('/sms/logs', [CommunicationController::class, 'smsLogs'])->name('sms.logs');
    });

    // Complaints
    Route::resource('complaints', ComplaintController::class)->only(['index', 'store', 'show']);
    Route::patch('complaints/{id}/resolve', [ComplaintController::class, 'resolve'])->name('complaints.resolve');

    // Feedback
    Route::resource('feedback', FeedbackController::class)->only(['index', 'store', 'show']);
    Route::get('feedback/{id}/report', [FeedbackController::class, 'report'])->name('feedback.report');

    // Certificates
    Route::prefix('certificates')->name('certs.')->group(function () {
        Route::get('/', [CertificateRequestController::class, 'index'])->name('index');
        Route::post('/', [CertificateRequestController::class, 'store'])->name('store');
        Route::get('/log', [CertificateRequestController::class, 'log'])->name('log');
        Route::get('/{id}', [CertificateRequestController::class, 'show'])->name('show');
        Route::post('/{id}/approve', [CertificateRequestController::class, 'approve'])->name('approve');
        Route::post('/{id}/reject', [CertificateRequestController::class, 'reject'])->name('reject');
        Route::post('/{id}/issue', [CertificateRequestController::class, 'issue'])->name('issue');
        Route::get('/{id}/download', [CertificateRequestController::class, 'download'])->name('download');
    });

    // Dispatch Register
    Route::resource('dispatch', DispatchRegisterController::class)->only(['index', 'store', 'update']);
});

// API routes
Route::middleware(['auth:sanctum', 'tenant'])->prefix('api/v1/front-office')->name('api.fof.')->group(function () {
    Route::get('/visitors/today', [VisitorController::class, 'apiTodayCount'])->name('visitors.today');
    Route::get('/gate-passes/pending', [GatePassController::class, 'apiPending'])->name('gate-passes.pending');
    Route::get('/certificates/pending', [CertificateRequestController::class, 'apiPending'])->name('certs.pending');
    Route::post('/visitors/{id}/checkout', [VisitorController::class, 'apiCheckout'])->name('visitors.checkout');
});
```

---

## 7. 📐 UI Screen Inventory & Field Mapping

| # | Screen Name | Route | Description |
|---|-------------|-------|-------------|
| 1 | Front Office Dashboard | fof.dashboard | Today's stats: visitor count, pending gate passes, pending certificates, unresolved complaints |
| 2 | Visitor Registration | fof.visitors.create | Quick registration form: name, mobile, ID proof, purpose, person to meet |
| 3 | Today's Visitor List | fof.visitors.index | Real-time list with In/Out status; Checkout button; filter by purpose |
| 4 | Visitor Detail / Pass | fof.visitors.show | Full visitor detail + printable pass button |
| 5 | Visitor Pass Print | fof.visitors.pass | A6 print-optimized layout with pass number, name, purpose, validity |
| 6 | Gate Pass List | fof.gate-passes.index | Pending approvals tab + history tab |
| 7 | Issue Gate Pass | fof.gate-passes.create | Person type selector → student/staff search → purpose → times |
| 8 | Phone Call Log | fof.phone.index | Date-filterable call register with incoming/outgoing tabs |
| 9 | Email Compose | fof.comm.email.compose | Rich text editor, template picker, recipient group selector |
| 10 | Email Templates | fof.comm.templates.index | Template list with category filter, create/edit |
| 11 | SMS Compose | fof.comm.sms.index | Message textarea with char counter, recipient selector |
| 12 | SMS Delivery Logs | fof.comm.sms.logs | Per-recipient delivery status table with download |
| 13 | Complaint Register | fof.complaints.index | Complaint list with urgency badges, status filter |
| 14 | Complaint Detail | fof.complaints.show | Full complaint view with resolution timeline |
| 15 | Feedback Forms | fof.feedback.index | Active/closed forms list with response counts |
| 16 | Feedback Form Response | fof.public.feedback | Public form for respondents (no auth) |
| 17 | Certificate Requests | fof.certs.index | Pending approvals + issuance queue + history |
| 18 | Certificate Issuance | fof.certs.issue | Confirm issue, enter receiver, PDF preview before printing |

---

## 8. Business Rules & Domain Constraints

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-001 | Every visitor must show ID proof — ID type and number must be captured | `RegisterVisitorRequest` — `id_proof_type` and `id_proof_number` required |
| BR-FOF-002 | Visitors who have not checked out by school closing time are automatically flagged as `Overstay` | Scheduled command (daily cron) updates `fof_visitors.status` = `Overstay` where `out_time` IS NULL and `in_time` < today's closing time |
| BR-FOF-003 | Student gate passes require parent notification before the student can exit | `GatePassService::createPass()` sets `parent_notified` flag and dispatches notification; front desk warned if notification fails |
| BR-FOF-004 | A student can only have one active (Pending/Approved/Exited) gate pass at a time | Validation query in `IssueGatePassRequest` |
| BR-FOF-005 | Certificate issuance requires all outstanding fees to be cleared (except Study/Bonafide for active students) | `CertificateIssuanceService` checks with StudentFee module for TC_Copy and Migration certificates |
| BR-FOF-006 | Certificate numbers must be unique per type per school-year | Unique format per type (BON-YYYY-NNN, CHAR-YYYY-NNN, etc.); UNIQUE constraint on `fof_certificate_requests.cert_number` |
| BR-FOF-007 | Government inspection visits must be flagged and logged separately; cannot be deleted | `fof_visitor_purposes.is_government_visit = 1`; delete blocked in `VisitorPolicy` |
| BR-FOF-008 | SMS messages that exceed 160 characters are sent as multi-SMS; recipient is charged for multiple units | Character count UI warning; gateway handles multi-SMS splitting |
| BR-FOF-009 | Feedback forms marked anonymous must not store respondent user ID | `FeedbackController::publicSubmit()` checks `fof_feedback_forms.is_anonymous`; if true, `respondent_user_id` left NULL |
| BR-FOF-010 | Dispatch register entries cannot be modified after acknowledgement is recorded | `DispatchRegisterController::update()` blocked if `acknowledged_at` is set |

---

## 9. Workflow & State Machine Definitions

### 9.1 Visitor State Machine

```
[Registered] (in_time set, status = In)
    └──(front desk marks exit)──► [Out] (out_time set) ✅
    └──(closing time + no checkout)──► [Overstay] (auto via cron)
```

### 9.2 Gate Pass State Machine

```
[Pending_Approval]
    ├──(authority approves)──► [Approved]
    │       └──(student/staff exits)──► [Exited]
    │               └──(returns to campus)──► [Returned] ✅
    └──(authority rejects)──► [Rejected]
    └──(cancelled by issuer)──► [Cancelled]
```

### 9.3 Certificate Request State Machine

```
[Pending_Approval]
    ├──(approver approves)──► [Approved]
    │       └──(front desk issues)──► [Issued] ✅ (cert_number + PDF generated)
    └──(approver rejects)──► [Rejected]
    └──(cancelled)──► [Cancelled]
```

### 9.4 Complaint State Machine

```
[Open] ──(assigned)──► same status
    └──(staff updates)──► [In_Progress]
            ├──► [Resolved] ✅
            └──► [Escalated] ──(linked to CMP module)──► CMP workflow
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Visitor registration must complete in < 1 second; today's visitor list must load in < 2 seconds |
| Scalability | Support up to 300 visitor registrations per day per tenant |
| Security | ID proof numbers stored in DB are not encrypted by default; Aadhar-type IDs should be masked in UI (show last 4 digits only) |
| Audit | All certificate issuances logged in `sys_activity_logs`; government inspection visits permanently retained |
| Print Support | Visitor pass and gate pass print layouts must be browser-print friendly (CSS @media print) without requiring PDF download |
| Availability | Real-time visitor dashboard must be available during school hours (7AM–5PM) |
| Localisation | Certificate templates must support school's regional language (via `glb_translations`) |
| Mobile Responsiveness | Front desk registration forms must be usable on tablets (receptionist commonly uses a tablet) |

---

## 11. Cross-Module Dependencies

### 11.1 This Module Depends On

| Module | Tables Used | Reason |
|--------|-------------|--------|
| SystemConfig | `sys_users`, `sys_roles`, `sys_media`, `sys_activity_logs` | Auth, staff lookup for gate pass, certificate PDF storage, audit |
| SchoolSetup | `sch_organizations`, `sch_classes`, `sch_sections` | School name/logo for certificates; class/section for communication filters |
| StudentProfile | `std_students` | Gate pass and certificate requests linked to students |
| Notification (NTF) | Email/SMS channels | All outbound communications dispatched via NTF |
| StudentFee | Fee balance check | Certificate issuance (TC_Copy, Migration) requires no outstanding dues |
| Complaint (CMP) | `cmp_complaints` | FOF complaints escalated to CMP module for full workflow |

### 11.2 Modules That Depend on FOF

| Module | Dependency |
|--------|-----------|
| None critical | FOF is primarily a standalone operational module |
| Notification | FOF is a major consumer of NTF channels |

### 11.3 📐 Implementation Order Recommendation

1. SystemConfig (auth, RBAC) — must be done
2. SchoolSetup — must be done
3. StudentProfile — must be done (for gate passes and certificate student lookup)
4. Notification module — must be done (for email/SMS dispatch)
5. **FOF Phase 1:** Visitor Management + Gate Pass (highest daily volume)
6. **FOF Phase 2:** Certificate Requests + Issuance (high priority for parents)
7. **FOF Phase 3:** Complaint Handling + Feedback
8. **FOF Phase 4:** Email/SMS Communication (depends on NTF being stable)
9. **FOF Phase 5:** Phone Diary + Dispatch Register (lower priority, operational registers)

---

## 12. 📐 Proposed Test Plan

| # | Test Name | Description | Type | Priority |
|---|-----------|-------------|------|----------|
| 1 | VisitorRegistrationTest | Register visitor — pass number generated, in_time set, status = In | Feature | High |
| 2 | VisitorCheckoutTest | Check out visitor — out_time recorded, status = Out | Feature | High |
| 3 | VisitorPassPdfTest | Visitor pass renders with correct name, purpose, pass number, validity | Feature | Medium |
| 4 | OverstayFlagTest | Cron runs after closing time — unchecked visitors flagged Overstay | Feature | Medium |
| 5 | GatePassCreateTest | Create gate pass for student — pass created, status = Pending_Approval | Feature | High |
| 6 | DuplicateGatePassTest | Student already has active gate pass — second request blocked | Feature | High |
| 7 | GatePassApprovalTest | Approve gate pass — status = Approved, front desk notified | Feature | High |
| 8 | StudentGatePassParentNotifyTest | Parent notification dispatched when student gate pass created | Feature | High |
| 9 | CertificateRequestTest | Request Bonafide certificate — request number generated, status = Pending | Feature | High |
| 10 | CertificateApprovalTest | Approve certificate — status = Approved, applicant notified | Feature | High |
| 11 | CertificateIssuanceTest | Issue certificate — PDF generated, cert_number unique, status = Issued | Feature | High |
| 12 | CertificateWithFeesTest | Request TC_Copy with outstanding fees — blocked | Feature | High |
| 13 | CertificateNumberUniqueTest | Two Bonafide certificates same year — different cert numbers | Unit | High |
| 14 | BulkEmailSendTest | Send email to all parents — recipient list resolved, comm log created | Feature | Medium |
| 15 | SmsCharCountTest | SMS over 160 chars — multi-SMS count shown | Unit | Medium |
| 16 | FeedbackAnonymousTest | Anonymous form submission — respondent_user_id stays NULL | Feature | High |
| 17 | FeedbackTokenTest | Form accessed via token — correct form rendered | Feature | Medium |
| 18 | ComplaintRegistrationTest | Register complaint — complaint number generated, assigned staff notified | Feature | Medium |
| 19 | ComplaintResolutionTest | Resolve complaint — status updated, complainant notified | Feature | Medium |
| 20 | GovtVisitDeleteBlockTest | Attempt to delete government inspection visitor record — blocked by policy | Feature | High |

---

## 13. Glossary & Terminology

| Term | Definition |
|------|-----------|
| Visitor Register | Official log of all persons entering school premises — required for security and government audit |
| Visitor Pass | A printed slip given to registered visitors allowing them access to school premises |
| Gate Pass | Authorization slip for students or staff to leave school premises during school hours |
| Dak Register | Traditional term for incoming/outgoing mail/correspondence register (used in Indian government institutions) |
| Dispatch Register | Log of all documents, letters, and couriers sent from or received by the school |
| Phone Diary | Manual/digital log of incoming and outgoing telephone calls at the school front desk |
| Bonafide Certificate | Official certificate confirming a student is currently enrolled at the school — most commonly requested |
| Character Certificate | Certificate issued on a student's leaving, stating their conduct/character during their time at school |
| TC | Transfer Certificate — issued when a student leaves; required by the next school for admission |
| Migration Certificate | Certificate allowing students to move between different educational boards |
| Overstay | A visitor who entered the premises but has not checked out by school closing time |
| Front Desk | The reception area of the school — the FOF module's primary user is the front desk staff |

---

## 14. Additional Suggestions

> The following are analyst recommendations beyond the current RBS scope:

1. **Kiosk Mode for Visitor Registration:** A self-registration kiosk (tablet at school entrance) where visitors can enter their own details, reducing front desk load. The same `fof_visitors` backend would be used with a simplified public-facing form.

2. **RFID/Barcode ID Card Scan:** For student gate passes, support scanning the student's ID card (RFID/Barcode as defined in `std_students.student_id_card_type`) to auto-populate student details rather than manual search.

3. **WhatsApp Integration:** Gate pass approvals and visitor checkout reminders are excellent use cases for WhatsApp messages (via WhatsApp Business API). The `fof_communication_logs` table already has a `WhatsApp` channel ENUM value ready.

4. **Digital Notice Board Screen:** Many schools display a rotating digital notice board on a large screen at the entrance. A `fof_notices` table (not in current RBS) could drive a public display URL that cycles through active notices.

5. **Visitor Photo Capture:** Using the device camera (WebRTC in browser), capture a visitor photo on registration. Store as media. High value for security — helps staff verify identity on re-entry.

6. **Certificate Template Engine:** Rather than hardcoding certificate PDFs, allow school admin to design certificate templates (with drag-and-drop logo, signature, seal placement). This is a premium feature that significantly differentiates the product.

7. **Integration with Complaint Module (CMP):** The FOF complaint feature is intentionally lightweight. Build an "Escalate to Full CMP" button that migrates the FOF complaint to the CMP module's full workflow with SLA tracking.

---

## 15. Appendices

### Appendix A — Full RBS Extract (Module D)

```
Module D — Front Office & Communication (31 sub-tasks)

D1 — Front Office Desk Management (9 sub-tasks)
  F.D1.1 — Visitor Management
    T.D1.1.1 — Register Visitor
      ST.D1.1.1.1 Capture visitor name & contact
      ST.D1.1.1.2 Log purpose of visit
      ST.D1.1.1.3 Capture in/out time
    T.D1.1.2 — Visitor Pass
      ST.D1.1.2.1 Generate visitor pass
      ST.D1.1.2.2 Print visitor slip
  F.D1.2 — Gate Pass
    T.D1.2.1 — Issue Gate Pass
      ST.D1.2.1.1 Create gate pass for students/staff
      ST.D1.2.1.2 Capture exit purpose
    T.D1.2.2 — Gate Pass Approval
      ST.D1.2.2.1 Send approval request to authority
      ST.D1.2.2.2 Record approval/rejection

D2 — Communication Management (8 sub-tasks)
  F.D2.1 — Email Communication
    T.D2.1.1 — Send Email
      ST.D2.1.1.1 Select recipients (Students/Staff/Parents)
      ST.D2.1.1.2 Attach documents
    T.D2.1.2 — Email Templates
      ST.D2.1.2.1 Create email templates
      ST.D2.1.2.2 Save templates for reuse
  F.D2.2 — SMS Communication
    T.D2.2.1 — Send SMS
      ST.D2.2.1.1 Compose SMS message
      ST.D2.2.1.2 Select recipients
    T.D2.2.2 — SMS Logs
      ST.D2.2.2.1 Track delivery reports
      ST.D2.2.2.2 Download SMS report

D3 — Complaint & Feedback Management (6 sub-tasks)
  F.D3.1 — Complaint Handling
    T.D3.1.1 — Register Complaint
      ST.D3.1.1.1 Enter complaint details
      ST.D3.1.1.2 Assign complaint to staff
    T.D3.1.2 — Complaint Resolution
      ST.D3.1.2.1 Update resolution status
      ST.D3.1.2.2 Add resolution notes
  F.D3.2 — Feedback Collection
    T.D3.2.1 — Collect Feedback
      ST.D3.2.1.1 Create feedback form
      ST.D3.2.1.2 Collect responses

D4 — Document & Certificate Issuance (8 sub-tasks)
  F.D4.1 — Certificate Request
    T.D4.1.1 — Request Certificate
      ST.D4.1.1.1 Student submits request
      ST.D4.1.1.2 Select certificate type
    T.D4.1.2 — Approval Workflow
      ST.D4.1.2.1 Send request for approval
      ST.D4.1.2.2 Track approval stages
  F.D4.2 — Certificate Issuance
    T.D4.2.1 — Issue Certificate
      ST.D4.2.1.1 Generate certificate PDF
      ST.D4.2.1.2 Print & handover certificate
    T.D4.2.2 — Record Issuance
      ST.D4.2.2.1 Log certificate number
      ST.D4.2.2.2 Store issuance date
```

### Appendix B — Proposed Route Table

See Section 6.1 for the full route table (44 web routes + 4 API routes + 2 public routes).

### Appendix C — Proposed File List

```
Modules/FrontOffice/
├── app/Http/Controllers/
│   ├── FrontOfficeDashboardController.php   [📐 Proposed]
│   ├── VisitorController.php                [📐 Proposed]
│   ├── GatePassController.php               [📐 Proposed]
│   ├── PhoneDiaryController.php             [📐 Proposed]
│   ├── CommunicationController.php          [📐 Proposed]
│   ├── ComplaintController.php              [📐 Proposed]
│   ├── FeedbackController.php               [📐 Proposed]
│   ├── CertificateRequestController.php     [📐 Proposed]
│   └── DispatchRegisterController.php       [📐 Proposed]
├── app/Http/Requests/
│   ├── RegisterVisitorRequest.php           [📐 Proposed]
│   ├── IssueGatePassRequest.php             [📐 Proposed]
│   ├── SendBulkEmailRequest.php             [📐 Proposed]
│   ├── SendBulkSmsRequest.php               [📐 Proposed]
│   ├── StoreComplaintRequest.php            [📐 Proposed]
│   ├── StoreFeedbackFormRequest.php         [📐 Proposed]
│   ├── RequestCertificateRequest.php        [📐 Proposed]
│   └── IssueCertificateRequest.php          [📐 Proposed]
├── app/Models/
│   ├── VisitorPurpose.php                   [📐 Proposed]
│   ├── Visitor.php                          [📐 Proposed]
│   ├── GatePass.php                         [📐 Proposed]
│   ├── PhoneDiary.php                       [📐 Proposed]
│   ├── CommunicationLog.php                 [📐 Proposed]
│   ├── EmailTemplate.php                    [📐 Proposed]
│   ├── SmsLog.php                           [📐 Proposed]
│   ├── FofComplaint.php                     [📐 Proposed]
│   ├── FeedbackForm.php                     [📐 Proposed]
│   ├── FeedbackResponse.php                 [📐 Proposed]
│   ├── CertificateRequest.php               [📐 Proposed]
│   └── DispatchRegister.php                 [📐 Proposed]
├── app/Services/
│   ├── VisitorService.php                   [📐 Proposed]
│   ├── GatePassService.php                  [📐 Proposed]
│   ├── CertificateIssuanceService.php       [📐 Proposed]
│   └── FrontOfficeCommunicationService.php  [📐 Proposed]
├── app/Policies/
│   ├── VisitorPolicy.php                    [📐 Proposed]
│   ├── GatePassPolicy.php                   [📐 Proposed]
│   ├── ComplaintPolicy.php                  [📐 Proposed]
│   └── CertificateRequestPolicy.php         [📐 Proposed]
├── database/migrations/                     [📐 12 migrations]
├── database/seeders/
│   ├── VisitorPurposeSeeder.php             [📐 Proposed]
│   └── CertificateTypeSeeder.php            [📐 Proposed]
├── resources/views/
│   ├── dashboard/index.blade.php            [📐 Proposed]
│   ├── visitors/index.blade.php             [📐 Proposed]
│   ├── visitors/create.blade.php            [📐 Proposed]
│   ├── visitors/show.blade.php              [📐 Proposed]
│   ├── visitors/pass.blade.php              [📐 Proposed]
│   ├── gate-pass/index.blade.php            [📐 Proposed]
│   ├── gate-pass/create.blade.php           [📐 Proposed]
│   ├── phone-diary/index.blade.php          [📐 Proposed]
│   ├── communication/email-compose.blade.php [📐 Proposed]
│   ├── communication/templates.blade.php    [📐 Proposed]
│   ├── communication/sms-compose.blade.php  [📐 Proposed]
│   ├── communication/sms-logs.blade.php     [📐 Proposed]
│   ├── complaints/index.blade.php           [📐 Proposed]
│   ├── complaints/show.blade.php            [📐 Proposed]
│   ├── feedback/index.blade.php             [📐 Proposed]
│   ├── feedback/create.blade.php            [📐 Proposed]
│   ├── feedback/respond.blade.php           [📐 Proposed]
│   ├── feedback/report.blade.php            [📐 Proposed]
│   ├── certificates/index.blade.php         [📐 Proposed]
│   ├── certificates/create.blade.php        [📐 Proposed]
│   ├── certificates/issue.blade.php         [📐 Proposed]
│   ├── certificates/log.blade.php           [📐 Proposed]
│   ├── dispatch/index.blade.php             [📐 Proposed]
│   └── partials/
│       ├── _visitor-pass.blade.php          [📐 Proposed]
│       └── _gate-pass-slip.blade.php        [📐 Proposed]
├── routes/
│   ├── web.php                              [📐 Proposed]
│   └── api.php                              [📐 Proposed]
└── tests/
    ├── Feature/
    │   ├── VisitorTest.php                  [📐 Proposed]
    │   ├── GatePassTest.php                 [📐 Proposed]
    │   ├── CertificateTest.php              [📐 Proposed]
    │   ├── ComplaintTest.php                [📐 Proposed]
    │   └── FeedbackTest.php                 [📐 Proposed]
    └── Unit/
        ├── CertificateNumberTest.php        [📐 Proposed]
        └── SmsCharCountTest.php             [📐 Proposed]
```

---

*Document generated by Claude Code (Automated Extraction) on 2026-03-25. All items marked 📐 are proposed and have not been implemented.*
