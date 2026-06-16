# FOF — Front Office Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## 1. Executive Summary

### 1.1 Purpose

The FrontOffice module (FOF) digitizes all reception and front-desk operations in Indian K-12 schools. The school front office is the first point of contact for visitors, telephone callers, walk-in enquiries, incoming/outgoing mail, and daily administrative coordination. FOF replaces paper-based registers (visitor book, phone diary, dak register, dispatch register, notice board, key register, lost & found log) with a centralized digital system providing real-time visibility, full audit trails, and reporting.

V2 expands the V1 scope significantly: in addition to the RBS-derived features (visitor management, gate pass, email/SMS communication, complaint handling, feedback, certificate issuance), V2 adds phone call log, postal/courier management, circular management, digital notice board, appointment scheduling, student early departure tracking, lost and found register, key management register, dispatch register, visitor log linkage to VSM, emergency contact directory, and basic school calendar event management.

### 1.2 V2 Scope Overview

| Phase | Feature Group | V1 Status | V2 Status |
|-------|--------------|-----------|-----------|
| Core | Visitor Management | 📐 Proposed | 📐 Proposed |
| Core | Gate Pass (student/staff early exit) | 📐 Proposed | 📐 Proposed |
| Core | Phone Call Log | 📐 Proposed | 📐 Proposed |
| Core | Postal / Courier Register (inward + outward) | 📐 Proposed | 📐 Proposed |
| Core | Dispatch Register (outgoing letters/docs) | 📐 Proposed | 📐 Proposed |
| Core | Circular Management + NTF distribution | ❌ Not in V1 | 📐 Proposed |
| Core | Digital Notice Board | ❌ Not in V1 | 📐 Proposed |
| Core | Appointment Scheduling | ❌ Not in V1 | 📐 Proposed |
| Core | Student Early Departure (linked to ATT) | ❌ Not in V1 | 📐 Proposed |
| Core | Lost and Found Register | ❌ Not in V1 | 📐 Proposed |
| Core | Key Management Register | ❌ Not in V1 | 📐 Proposed |
| Core | Emergency Contact Directory | ❌ Not in V1 | 📐 Proposed |
| Comm | Email Communication (via NTF) | 📐 Proposed | 📐 Proposed |
| Comm | SMS Communication (via NTF) | 📐 Proposed | 📐 Proposed |
| Admin | Complaint Handling (lightweight, links CMP) | 📐 Proposed | 📐 Proposed |
| Admin | Feedback Collection | 📐 Proposed | 📐 Proposed |
| Admin | Certificate Request + Issuance | 📐 Proposed | 📐 Proposed |
| Admin | School Calendar Events (public-facing) | ❌ Not in V1 | 📐 Proposed |

### 1.3 Module Statistics (V2)

| Metric | Count |
|--------|-------|
| RBS Features (F.D*) | 8 |
| 📐 Proposed Tables | 20 |
| 📐 Proposed Controllers | 16 |
| 📐 Proposed Models | 20 |
| 📐 Proposed Services | 6 |
| 📐 Proposed Routes (web) | ~75 |
| 📐 Proposed Routes (api) | ~20 |
| 📐 Proposed UI Screens | 28 |

### 1.4 Implementation Status

All components are ❌ Not Started (Greenfield). Overall: **0% — RBS_ONLY**.

### 1.5 Implementation Prerequisites

| Dependency | Why Required |
|------------|-------------|
| SystemConfig (sys_*) | RBAC, dropdowns, media uploads, audit logs |
| SchoolSetup (sch_*) | School name/logo for certificates; class/section for circular targeting |
| StudentProfile (std_*) | Gate pass, early departure, and certificate requests linked to students |
| Attendance (ATT) | Student early departure must create an absence record in ATT |
| Notification (NTF) | Circular distribution, gate pass alerts, certificate notifications |
| Complaint (CMP) | FOF complaints may be escalated to CMP for full workflow |
| VSM (Visitor Security) | Gate security handoff — VSM records arrival at gate, FOF handles inside campus |
| GlobalMaster (glb_*) | Country/state for visitor address, ID proof types |

---

## 2. Module Overview

### 2.1 Business Purpose

The school front office handles dozens of daily operational tasks that are paper-based in most Indian schools. These manual processes create audit failures during CBSE/State Board inspections, make historical retrieval impossible, and provide no real-time visibility. The FOF module eliminates all these gaps by covering:

- **Visitor register** — every person entering campus logged digitally
- **Phone diary** — all incoming and outgoing calls logged
- **Postal/dak register** — inward mail, couriers, government notices tracked
- **Dispatch register** — all outgoing letters, legal documents, cheques logged
- **Gate pass** — students and staff leaving during school hours authorised and tracked
- **Student early departure** — parent collecting student mid-day linked to attendance
- **Circular management** — school circulars drafted, approved, distributed via NTF
- **Notice board** — digital notice board with active/expired notices
- **Appointment scheduling** — meetings with principal/teachers booked and confirmed
- **Lost and found** — unclaimed items registered; claimants matched and notified
- **Key management** — room/lab/vehicle keys issued and returned
- **Emergency contact directory** — key external contacts (hospital, police, fire, transport)
- **Certificate requests** — Bonafide, Character, TC requests with approval and PDF issuance

### 2.2 Distinction from VSM

FOF and VSM are complementary but distinct modules:

| Aspect | FOF (Front Office) | VSM (Visitor Security) |
|--------|--------------------|------------------------|
| Actor | Receptionist | Security guard at gate |
| Entry point | Reception desk inside campus | Main gate / security booth |
| Focus | Operational management, registers, circulars | Gate security, biometric, vehicle log |
| Visitor record | Full operational detail, pass issuance | Entry/exit timestamps, ID verification |
| Integration | Receives handoff from VSM for pre-registered visitors | Notifies FOF when visitor arrives at gate |

### 2.3 Key Features Summary

| # | Feature Group | Key Capability |
|---|--------------|----------------|
| 1 | Visitor Management | Digital register, photo capture, visitor pass, overstay flag |
| 2 | Gate Pass | Student/staff early exit with approval workflow |
| 3 | Student Early Departure | Mid-day parent pickup linked to ATT module |
| 4 | Phone Call Log | Incoming/outgoing phone diary with action flags |
| 5 | Postal / Courier Register | Inward/outward mail, courier tracking numbers |
| 6 | Dispatch Register | Outgoing letters, documents, cheques log |
| 7 | Circular Management | Draft → approve → distribute to parents/staff via NTF |
| 8 | Digital Notice Board | Active notices with expiry, category, audience targeting |
| 9 | Appointment Scheduling | Book principal/teacher meetings, confirmation, reminders |
| 10 | Lost and Found | Register items, match claims, disposition tracking |
| 11 | Key Management | Issue/return room, lab, vehicle keys with history |
| 12 | Emergency Contacts | School's emergency contact directory (hospital, police, etc.) |
| 13 | Certificate Request | Bonafide/Character/TC/other with approval + PDF issuance |
| 14 | Complaint Handling | Lightweight front-office complaint → CMP escalation |
| 15 | Feedback Collection | Create forms, distribute, collect responses, report |
| 16 | Email / SMS Communication | Bulk send via NTF with template support |
| 17 | School Calendar Events | Public-facing school events/open days management |

### 2.4 Menu Navigation Path

```
Tenant Dashboard
└── Front Office
    ├── Dashboard (today's snapshot)
    ├── Visitors
    │   ├── Register Visitor
    │   ├── Today's Visitors
    │   └── Visitor History
    ├── Gate Pass
    │   ├── Issue Gate Pass
    │   ├── Pending Approvals
    │   └── Gate Pass History
    ├── Early Departure
    │   ├── Log Early Departure
    │   └── Today's Departures
    ├── Phone Diary
    │   ├── Log Call
    │   └── Call Register
    ├── Postal / Courier
    │   ├── Inward Mail
    │   └── Outward Mail
    ├── Dispatch Register
    ├── Circulars
    │   ├── All Circulars
    │   ├── Draft New Circular
    │   └── Distribution Log
    ├── Notice Board
    │   ├── Active Notices
    │   └── Create Notice
    ├── Appointments
    │   ├── Today's Appointments
    │   ├── Book Appointment
    │   └── Calendar View
    ├── Lost & Found
    │   ├── Register Item
    │   └── All Items
    ├── Key Management
    │   ├── Issue Key
    │   └── Key Register
    ├── Emergency Contacts
    ├── Certificates
    │   ├── Requests Queue
    │   ├── Issue Certificate
    │   └── Issuance Log
    ├── Complaints
    ├── Feedback
    ├── Communication
    │   ├── Send Email
    │   ├── Email Templates
    │   ├── Send SMS
    │   └── SMS Logs
    └── School Events
```

---

## 3. Stakeholders & Roles

| Actor | Role | Key Permissions |
|-------|------|-----------------|
| School Admin | Full front office management | All CRUD, reports, settings, emergency contacts |
| Front Office Staff / Receptionist | Day-to-day front desk operations | Register visitors, log calls/mail, issue gate passes, process certificates, manage keys |
| Principal / Vice Principal | Approval authority, circular sign-off | Approve gate passes, approve circulars, view all complaints |
| Teacher | Issue student gate pass requests, request appointments | Create gate pass requests for own students |
| Communication Manager | Send bulk email/SMS, manage circulars | Compose and send communication, distribute circulars |
| Student | Request certificates, submit feedback, request appointments | Self-service certificate request, feedback submission |
| Parent | Visitor registration, early departure, complaint registration | Register as visitor, collect student, submit complaint/feedback |
| Security Guard (VSM actor) | Handoff pre-registered visitors to FOF | Read-only view of FOF visitor pre-registrations |
| System | Overstay flag cron, circular distribution, circular expiry | Internal scheduled tasks |

---

## 4. Functional Requirements

All FRs are 📐 Proposed (Greenfield — no existing implementation).

---

### FR-FOF-01: Visitor Management
**Priority:** High | **Tables:** `fof_visitors`, `fof_visitor_purposes`

#### FR-FOF-01.1 Register Visitor

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff, Receptionist |
| Input | Visitor name, mobile, ID proof type + number, organization, purpose (dropdown), person/dept to meet, vehicle number (optional), accompanying persons count, photo (optional) |
| Processing | Create `fof_visitors` record; auto-set `in_time` = NOW(); status = `In`; generate pass number `VP-YYYYMMDD-NNN`; if VSM visitor arrives from gate — pre-populate from `vsm_visitors` handoff |
| Output | Visitor registered; printable visitor pass available |

Acceptance Criteria:
- Visitor name, mobile, ID proof type + number captured (required)
- Purpose from configured `fof_visitor_purposes` dropdown (required)
- Pass number auto-generated in format VP-YYYYMMDD-NNN
- Government inspection visits flagged via `is_government_visit` purpose flag
- VSM pre-registered visitor auto-populated when `vsm_visitor_id` provided

#### FR-FOF-01.2 Visitor Checkout

| Attribute | Detail |
|-----------|--------|
| Processing | Set `out_time` = NOW(); status = `Out`; if badge issued, mark returned |

Acceptance Criteria:
- Checkout records `out_time` and sets status to `Out`
- Visitors not checked out by school closing time flagged `Overstay` via scheduled command

#### FR-FOF-01.3 Visitor Pass Print

Printable A6 slip with: visitor name, pass number, purpose, in-time, valid until (end of school day), school name/logo. CSS `@media print` optimized — no PDF download required.

---

### FR-FOF-02: Gate Pass (Student / Staff Early Exit)
**Priority:** High | **Tables:** `fof_gate_passes`

#### FR-FOF-02.1 Issue Gate Pass

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff, Class Teacher |
| Input | Person type (Student/Staff), person ID, exit purpose (Medical/Personal/Official/Sports/Family_Emergency/Other), purpose details, expected return time, parent notified flag (for students) |
| Processing | Create `fof_gate_passes`; status = `Pending_Approval`; notify approval authority; if student — auto-dispatch parent notification via NTF |

Acceptance Criteria:
- Gate pass created with person type, ID, purpose, times
- Parent notification dispatched automatically for student gate passes
- A student may only have one active (Pending/Approved/Exited) gate pass at a time — duplicate blocked

#### FR-FOF-02.2 Gate Pass Approval

| Attribute | Detail |
|-----------|--------|
| Actors | Principal, Vice Principal, HOD |
| Processing | Update status to `Approved` or `Rejected`; record `approved_by`, `approved_at`, remarks; notify front desk |

Acceptance Criteria:
- Approval authority notified of pending gate pass
- Approved/Rejected decision recorded with timestamp and approver
- Approved gate pass printable as a physical slip

#### FR-FOF-02.3 Gate Pass Lifecycle Tracking

State transitions: `Pending_Approval` → `Approved` → `Exited` → `Returned`. Front desk marks Exited when person physically leaves; marks Returned when person re-enters campus.

---

### FR-FOF-03: Student Early Departure
**Priority:** High | **Tables:** `fof_early_departures`

Student early departure is distinct from gate pass — it covers a parent collecting a student mid-day (the student does not return). This event must feed the ATT module to mark the student absent for remaining periods.

#### FR-FOF-03.1 Log Early Departure

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff |
| Input | Student ID, departure time, reason (Medical/Family_Emergency/Event/Other), collecting person name, collecting person relationship, collecting person ID proof type + number, parent authorization (boolean) |
| Processing | Create `fof_early_departures`; trigger ATT integration to mark student absent for remaining periods of the day; dispatch parent confirmation notification |

Acceptance Criteria:
- Departure logged with student, time, reason, collecting person details
- ATT module notified via service call to mark student absent from departure period onwards
- Parent receives confirmation notification via NTF
- Collecting person identity captured (name + ID proof) for security audit

#### FR-FOF-03.2 Today's Early Departures Dashboard

Receptionist sees a live list of today's early departures with student name, class, departure time, collecting person, and ATT sync status.

---

### FR-FOF-04: Phone Call Log (Phone Diary)
**Priority:** Medium | **Tables:** `fof_phone_diary`

#### FR-FOF-04.1 Log Incoming Call

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff |
| Input | Caller name, caller number, caller organization (optional), person/dept called, purpose (free text), message summary, action required (boolean), action notes |
| Processing | Create `fof_phone_diary` with `call_type = Incoming`; auto-set call date/time |

#### FR-FOF-04.2 Log Outgoing Call

| Attribute | Detail |
|-----------|--------|
| Input | Called name, called number, called organization, purpose, outcome |
| Processing | Create `fof_phone_diary` with `call_type = Outgoing` |

#### FR-FOF-04.3 Call Register View

Date-filterable list of all calls; filter by type (Incoming/Outgoing); filter by action_required = true to surface pending follow-ups. Export to CSV.

---

### FR-FOF-05: Postal / Courier Register
**Priority:** Medium | **Tables:** `fof_postal_register`

Covers all physical mail and couriers received by or sent from the school. Distinct from the dispatch register (which covers letters/documents); postal register focuses on courier-tracked shipments.

#### FR-FOF-05.1 Register Inward Mail/Courier

| Attribute | Detail |
|-----------|--------|
| Input | Received date, sender name + address, document type (Letter/Courier/Parcel/Government_Notice/Cheque/Legal/Other), subject/description, courier company (optional), tracking number (optional), school department concerned, assigned staff |
| Processing | Create `fof_postal_register` with `postal_type = Inward`; auto-generate inward number `IN-YYYY-NNNN`; notify assigned staff |

#### FR-FOF-05.2 Register Outward Mail/Courier

| Attribute | Detail |
|-----------|--------|
| Input | Dispatch date, recipient name + address, document type, subject, courier company, tracking number, dispatched by |
| Processing | Create `fof_postal_register` with `postal_type = Outward`; auto-generate outward number `OUT-YYYY-NNNN` |

#### FR-FOF-05.3 Acknowledgement Recording

For inward mail: record who received/signed, date/time acknowledged. Once acknowledged, the record is locked from modification (BR-FOF-010).

---

### FR-FOF-06: Dispatch Register
**Priority:** Medium | **Tables:** `fof_dispatch_register`

Log of all outgoing letters, official documents, and legal papers sent from the school (distinct from courier — focuses on official school correspondence).

| Attribute | Detail |
|-----------|--------|
| Input | Dispatch date, dispatch number (auto: DSP-YYYY-NNNN), addressee name + address, subject, document type, mode (Hand/Post/Courier/Email), reference number, dispatched by |
| Processing | Create `fof_dispatch_register`; record copies retained (boolean) |

---

### FR-FOF-07: Circular Management
**Priority:** High | **Tables:** `fof_circulars`, `fof_circular_distributions`

School circulars are official communications issued to parents and/or staff. V2 introduces a full circular lifecycle: draft → approve → distribute.

#### FR-FOF-07.1 Draft Circular

| Attribute | Detail |
|-----------|--------|
| Actors | Communication Manager, School Admin |
| Input | Circular title, circular number (auto: CIR-YYYY-NNNN), subject, body (rich text), audience (Parents/Staff/Both/Specific_Class/Specific_Section), applicable classes/sections (optional), effective date, attachments (optional) |
| Processing | Create `fof_circulars` with `status = Draft`; support version history |

#### FR-FOF-07.2 Circular Approval

| Attribute | Detail |
|-----------|--------|
| Actors | Principal, School Admin |
| Processing | Update `fof_circulars.status` to `Approved`; record approver + timestamp |

Acceptance Criteria:
- Principal receives notification of circular pending approval
- Approved circulars cannot be edited (new version must be created)
- Rejected circulars returned to draft with rejection notes

#### FR-FOF-07.3 Circular Distribution

| Attribute | Detail |
|-----------|--------|
| Processing | On distribution trigger: resolve recipient list from audience config; dispatch via NTF email + optional SMS; create `fof_circular_distributions` records per recipient; update `fof_circulars.status = Distributed` |

Acceptance Criteria:
- Distribution resolves correct parents/staff based on audience config
- Each recipient gets NTF email notification with circular attached or linked
- Distribution log shows sent/delivered/failed counts per circular
- Circular available in parent portal (PPT) after distribution

#### FR-FOF-07.4 Circular Archive

All approved and distributed circulars accessible in a searchable archive. Staff and parents can retrieve past circulars by date range, circular number, or keyword.

---

### FR-FOF-08: Digital Notice Board
**Priority:** Medium | **Tables:** `fof_notices`

#### FR-FOF-08.1 Create Notice

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff, School Admin |
| Input | Title, content (rich text), category (Academic/Administrative/Sports/Cultural/Holiday/Emergency/Other), audience (All/Students/Staff/Parents), display from date, display until date, is_pinned (boolean), attachments (optional) |
| Processing | Create `fof_notices`; if audience includes parents — optionally push NTF notification |

#### FR-FOF-08.2 Notice Lifecycle

Active notices shown on dashboard and parent/staff portals. Notices past `display_until` automatically archived. Pinned notices always shown at top. Emergency notices bypass display dates.

---

### FR-FOF-09: Appointment Scheduling
**Priority:** Medium | **Tables:** `fof_appointments`

Parents and visitors can book appointments with the principal, vice principal, or specific staff.

#### FR-FOF-09.1 Book Appointment

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff (on behalf of visitor/parent), Parent (self-service via PPT) |
| Input | Appointment date, time slot, appointment type (Parent_Teacher_Meeting/Principal_Meeting/Grievance/Admission_Enquiry/Other), with whom (staff user), visitor/parent name, contact, purpose |
| Processing | Create `fof_appointments` with `status = Pending`; check slot availability against existing appointments; notify staff member |

#### FR-FOF-09.2 Appointment Confirmation

Staff confirms or proposes alternate slot. Parent/visitor notified of confirmation via NTF. On confirmation: `status = Confirmed`.

#### FR-FOF-09.3 Appointment Calendar View

Front office staff sees a day/week calendar of all confirmed appointments, colour-coded by type. Overdue (no-show) appointments auto-flagged.

---

### FR-FOF-10: Lost and Found Register
**Priority:** Low | **Tables:** `fof_lost_found`

#### FR-FOF-10.1 Register Found Item

| Attribute | Detail |
|-----------|--------|
| Input | Item description, category (Electronics/Clothing/Stationery/ID_Card/Money/Jewellery/Other), found date, found location, found by (name/user), photo (optional) |
| Processing | Create `fof_lost_found` with `status = Unclaimed`; auto-generate item number `LF-YYYY-NNNN` |

#### FR-FOF-10.2 Claim Item

When a person claims an item: record claimant name, contact, proof of ownership (description), claim date. Staff verifies and marks `status = Claimed`. Unclaimed items past configurable retention period (e.g., 30 days) flagged for disposal.

---

### FR-FOF-11: Key Management Register
**Priority:** Low | **Tables:** `fof_key_register`

Track physical keys for rooms, labs, vehicles, cabinets.

#### FR-FOF-11.1 Issue Key

| Attribute | Detail |
|-----------|--------|
| Input | Key label (e.g., "Science Lab A", "Staff Room"), key number/tag, issued to (staff user), purpose, issued date-time, expected return date-time |
| Processing | Create `fof_key_register` with `status = Issued`; if key already issued — block and show who currently holds it |

#### FR-FOF-11.2 Return Key

Record returned date-time; set `status = Returned`. Overdue keys (not returned by expected time) flagged in dashboard.

---

### FR-FOF-12: Emergency Contact Directory
**Priority:** Medium | **Tables:** `fof_emergency_contacts`

A managed directory of external emergency contacts for the school (hospitals, police, fire brigade, ambulance, transport providers, utility services).

| Attribute | Detail |
|-----------|--------|
| Input | Contact name, organization, contact type (Hospital/Police/Fire/Ambulance/Transport/Utility/Parent_Emergency/Other), phone numbers (primary + alternate), address, notes |
| Processing | CRUD on `fof_emergency_contacts`; visible to all front office staff and principal |

---

### FR-FOF-13: Certificate Request and Issuance
**Priority:** High | **Tables:** `fof_certificate_requests`

#### FR-FOF-13.1 Request Certificate

| Attribute | Detail |
|-----------|--------|
| Actors | Front Office Staff, Student (PPT), Parent |
| Input | Student ID/admission number, certificate type (Bonafide/Character/Fee_Paid/Study/TC_Copy/Migration/Conduct/Other), purpose, copies requested, urgent flag, applicant name + contact |
| Processing | Create `fof_certificate_requests`; status = `Pending_Approval`; request number `CERT-YYYY-NNNNN`; notify approver |

Acceptance Criteria:
- Request number auto-generated
- Urgent flag escalates approval priority
- TC_Copy and Migration requests trigger fee clearance check via StudentFee module

#### FR-FOF-13.2 Approval Workflow

Multi-stage: Front Office verifies → Principal/authority approves → Ready to issue. Each stage recorded in `stages_json` with timestamp. Rejected requests notify student/parent with reason.

#### FR-FOF-13.3 Issue Certificate

| Attribute | Detail |
|-----------|--------|
| Processing | Generate certificate PDF via DomPDF using template per cert type; store in `sys_media`; assign cert number (BON-YYYY-NNN, CHAR-YYYY-NNN per type); update status = `Issued`; record receiver name |

Acceptance Criteria:
- PDF generated with school letterhead, student details, appropriate content per type
- Certificate number unique per type per school-year
- Issuance log searchable by cert number, student, date

---

### FR-FOF-14: Complaint Handling (Front-Office Level)
**Priority:** Medium | **Tables:** `fof_complaints`

Lightweight complaint intake at the front desk. For complex escalations, FOF complaints link to the main CMP module.

#### FR-FOF-14.1 Register Complaint

| Attribute | Detail |
|-----------|--------|
| Input | Complainant name, contact, type (Academic/Facility/Staff_Behavior/Fee/Safety/Transportation/Food/Hygiene/Other), description, urgency (Normal/Urgent/Critical), assigned staff |
| Processing | Create `fof_complaints`; number `FOF-CMP-YYYY-NNNNN`; notify assigned staff |

#### FR-FOF-14.2 Resolve / Escalate

Assigned staff updates resolution status and notes. If escalated: create linked CMP module complaint (`cmp_complaint_id` FK set); FOF complaint status = `Escalated`.

---

### FR-FOF-15: Feedback Collection
**Priority:** Low | **Tables:** `fof_feedback_forms`, `fof_feedback_responses`

Create feedback forms with rating/text/MCQ questions; distribute via link/email; collect and aggregate responses. Anonymous option available. Public token-based form URL (no auth required for response submission).

---

### FR-FOF-16: Email and SMS Communication
**Priority:** Medium | **Tables:** `fof_communication_logs`, `fof_email_templates`, `fof_sms_logs`

> Integration: FOF uses NTF module's email/SMS channels for actual delivery. FOF adds the composition UI, template management, and a front-office-scoped audit log on top of NTF infrastructure.

Bulk email to Students/Staff/Parents or filtered by class/section. Email templates with `{{placeholder}}` support. SMS with character counter and multi-SMS cost warning. Per-recipient delivery status tracking via gateway webhook.

---

### FR-FOF-17: School Calendar Events
**Priority:** Low | **Tables:** `fof_school_events`

Manage public-facing school events (Open Days, Sports Day, Annual Function, PTMs, holidays). Events are visible on the parent portal and can trigger NTF notifications.

| Attribute | Detail |
|-----------|--------|
| Input | Event name, event type (Academic/Sports/Cultural/PTM/Holiday/Exam/Other), start date, end date, description, venue, target audience, is_public (visible on public website) |
| Processing | CRUD on `fof_school_events`; on publish — optional NTF blast to parents/staff |

---

## 5. Data Model

### 5.1 Entity Overview

| Table | Description | Approx. Rows/School/Year |
|-------|-------------|--------------------------|
| `fof_visitor_purposes` | Lookup: purpose of visit | 10–20 |
| `fof_visitors` | Visitor register | 2,000–15,000 |
| `fof_gate_passes` | Student/staff gate passes | 200–2,000 |
| `fof_early_departures` | Student mid-day parent pickup | 100–800 |
| `fof_phone_diary` | Incoming/outgoing call log | 1,000–5,000 |
| `fof_postal_register` | Inward/outward mail + courier | 500–3,000 |
| `fof_dispatch_register` | Official outgoing correspondence | 200–1,000 |
| `fof_circulars` | School circulars | 50–200 |
| `fof_circular_distributions` | Per-recipient distribution log | 10,000–100,000 |
| `fof_notices` | Digital notice board entries | 100–500 |
| `fof_appointments` | Principal/teacher appointments | 200–1,000 |
| `fof_lost_found` | Lost and found items | 50–300 |
| `fof_key_register` | Key issue/return log | 200–1,000 |
| `fof_emergency_contacts` | External emergency directory | 10–30 |
| `fof_communication_logs` | Bulk email/SMS audit log | 100–500 |
| `fof_email_templates` | Reusable email templates | 10–50 |
| `fof_sms_logs` | Per-recipient SMS delivery | 5,000–50,000 |
| `fof_complaints` | Front-office complaint register | 50–500 |
| `fof_feedback_forms` | Feedback form definitions | 5–20 |
| `fof_feedback_responses` | Form responses | 100–2,000 |
| `fof_certificate_requests` | Certificate request + issuance | 100–1,000 |
| `fof_school_events` | School calendar events | 30–100 |

### 5.2 Detailed Entity Specification

---

#### `fof_visitor_purposes`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `name` | VARCHAR(100) | NOT NULL | e.g., "Parent Meeting" |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE | e.g., "PARENT_MTG" |
| `is_government_visit` | TINYINT(1) | NOT NULL DEFAULT 0 | Flag for permanent retention |
| `sort_order` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

Seeded: Parent Meeting, Government Inspection, Job Interview, Delivery/Courier, Sales Visit, Alumni Visit, Emergency, Other.

---

#### `fof_visitors`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `pass_number` | VARCHAR(25) | NOT NULL, UNIQUE | VP-YYYYMMDD-NNN |
| `vsm_visitor_id` | BIGINT UNSIGNED | NULL | FK to vsm_visitors if pre-registered at gate |
| `visitor_name` | VARCHAR(100) | NOT NULL | |
| `visitor_mobile` | VARCHAR(15) | NOT NULL | |
| `visitor_email` | VARCHAR(100) | NULL | |
| `id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Voter_ID','PAN','Employee_ID','Other') | NULL | |
| `id_proof_number` | VARCHAR(50) | NULL | Last 4 shown in UI |
| `address` | VARCHAR(200) | NULL | |
| `organization` | VARCHAR(100) | NULL | |
| `purpose_id` | BIGINT UNSIGNED | NOT NULL, FK→fof_visitor_purposes | |
| `person_to_meet` | VARCHAR(100) | NULL | |
| `meet_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `vehicle_number` | VARCHAR(20) | NULL | |
| `accompanying_count` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `photo_media_id` | INT UNSIGNED | NULL, FK→sys_media | Optional webcam capture |
| `in_time` | DATETIME | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| `out_time` | DATETIME | NULL | |
| `status` | ENUM('In','Out','Overstay') | NOT NULL DEFAULT 'In' | |
| `notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

Indexes: `idx_fof_vis_date` on `DATE(in_time)`, `idx_fof_vis_status` on `status`, `idx_fof_vis_mobile` on `visitor_mobile`.

---

#### `fof_gate_passes`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `pass_number` | VARCHAR(25) | NOT NULL, UNIQUE | GP-YYYYMMDD-NNN |
| `person_type` | ENUM('Student','Staff') | NOT NULL | |
| `student_id` | INT UNSIGNED | NULL, FK→std_students | |
| `staff_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `purpose` | ENUM('Medical','Personal','Official','Sports','Family_Emergency','Other') | NOT NULL | |
| `purpose_details` | VARCHAR(200) | NULL | |
| `exit_time` | DATETIME | NULL | Actual exit |
| `expected_return_time` | DATETIME | NULL | |
| `actual_return_time` | DATETIME | NULL | |
| `parent_notified` | TINYINT(1) | NOT NULL DEFAULT 0 | Student passes only |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Exited','Returned','Cancelled') | NOT NULL DEFAULT 'Pending_Approval' | |
| `approved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `approved_at` | DATETIME | NULL | |
| `rejection_reason` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_early_departures`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `departure_number` | VARCHAR(25) | NOT NULL, UNIQUE | ED-YYYYMMDD-NNN |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `departure_time` | DATETIME | NOT NULL | |
| `reason` | ENUM('Medical','Family_Emergency','Event','Bereavement','Other') | NOT NULL | |
| `reason_details` | VARCHAR(200) | NULL | |
| `collecting_person_name` | VARCHAR(100) | NOT NULL | |
| `collecting_person_relation` | ENUM('Father','Mother','Guardian','Sibling','Other') | NOT NULL | |
| `collecting_id_proof_type` | ENUM('Aadhar','Driving_License','Passport','Other') | NULL | |
| `collecting_id_proof_number` | VARCHAR(50) | NULL | |
| `parent_authorized` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `att_sync_status` | ENUM('Pending','Synced','Failed') | NOT NULL DEFAULT 'Pending' | |
| `att_synced_at` | DATETIME | NULL | |
| `notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_phone_diary`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `call_type` | ENUM('Incoming','Outgoing') | NOT NULL | |
| `call_date` | DATE | NOT NULL | |
| `call_time` | TIME | NOT NULL | |
| `caller_name` | VARCHAR(100) | NOT NULL | |
| `caller_number` | VARCHAR(15) | NULL | |
| `caller_organization` | VARCHAR(100) | NULL | |
| `recipient_name` | VARCHAR(100) | NULL | Who took/made call |
| `recipient_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `purpose` | VARCHAR(200) | NOT NULL | |
| `message` | TEXT | NULL | Call summary |
| `action_required` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `action_notes` | TEXT | NULL | |
| `action_completed` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `logged_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_postal_register`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `postal_type` | ENUM('Inward','Outward') | NOT NULL | |
| `postal_number` | VARCHAR(30) | NOT NULL, UNIQUE | IN-YYYY-NNNN / OUT-YYYY-NNNN |
| `postal_date` | DATE | NOT NULL | |
| `sender_name` | VARCHAR(100) | NULL | For Inward |
| `sender_address` | VARCHAR(200) | NULL | |
| `recipient_name` | VARCHAR(100) | NULL | For Outward |
| `recipient_address` | VARCHAR(200) | NULL | |
| `document_type` | ENUM('Letter','Courier','Parcel','Government_Notice','Cheque','Legal','Other') | NOT NULL | |
| `subject` | VARCHAR(200) | NOT NULL | |
| `courier_company` | VARCHAR(100) | NULL | |
| `tracking_number` | VARCHAR(100) | NULL | |
| `department` | VARCHAR(100) | NULL | |
| `assigned_to_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `acknowledgement_by` | VARCHAR(100) | NULL | |
| `acknowledged_at` | DATETIME | NULL | Locked after this |
| `remarks` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_dispatch_register`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `dispatch_number` | VARCHAR(30) | NOT NULL, UNIQUE | DSP-YYYY-NNNN |
| `dispatch_date` | DATE | NOT NULL | |
| `addressee_name` | VARCHAR(100) | NOT NULL | |
| `addressee_address` | VARCHAR(200) | NULL | |
| `subject` | VARCHAR(200) | NOT NULL | |
| `document_type` | ENUM('Letter','Notice','Legal','Certificate','Report','Circular','Other') | NOT NULL | |
| `dispatch_mode` | ENUM('Hand','Post','Courier','Email','Fax') | NOT NULL | |
| `reference_number` | VARCHAR(100) | NULL | |
| `copy_retained` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `dispatched_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `remarks` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_circulars`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `circular_number` | VARCHAR(30) | NOT NULL, UNIQUE | CIR-YYYY-NNNN |
| `title` | VARCHAR(200) | NOT NULL | |
| `subject` | VARCHAR(300) | NOT NULL | |
| `body` | LONGTEXT | NOT NULL | Rich text HTML |
| `audience` | ENUM('Parents','Staff','Both','Specific_Class','Specific_Section') | NOT NULL | |
| `audience_filter_json` | JSON | NULL | Class/section IDs for filtered audience |
| `effective_date` | DATE | NOT NULL | |
| `expires_on` | DATE | NULL | |
| `attachment_media_id` | INT UNSIGNED | NULL, FK→sys_media | |
| `status` | ENUM('Draft','Pending_Approval','Approved','Distributed','Recalled') | NOT NULL DEFAULT 'Draft' | |
| `approved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `approved_at` | DATETIME | NULL | |
| `distributed_at` | DATETIME | NULL | |
| `distributed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_circular_distributions`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `circular_id` | BIGINT UNSIGNED | NOT NULL, FK→fof_circulars | |
| `recipient_user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `channel` | ENUM('Email','SMS','Push') | NOT NULL | |
| `status` | ENUM('Queued','Sent','Delivered','Failed') | NOT NULL DEFAULT 'Queued' | |
| `sent_at` | TIMESTAMP | NULL | |
| `delivered_at` | TIMESTAMP | NULL | |
| `read_at` | TIMESTAMP | NULL | |
| `ntf_log_id` | BIGINT UNSIGNED | NULL | FK to NTF module log |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |

---

#### `fof_notices`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `title` | VARCHAR(200) | NOT NULL | |
| `content` | LONGTEXT | NOT NULL | |
| `category` | ENUM('Academic','Administrative','Sports','Cultural','Holiday','Emergency','Other') | NOT NULL | |
| `audience` | ENUM('All','Students','Staff','Parents') | NOT NULL DEFAULT 'All' | |
| `display_from` | DATE | NOT NULL | |
| `display_until` | DATE | NULL | NULL = no expiry |
| `is_pinned` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `is_emergency` | TINYINT(1) | NOT NULL DEFAULT 0 | Bypasses display dates |
| `attachment_media_id` | INT UNSIGNED | NULL, FK→sys_media | |
| `status` | ENUM('Active','Archived') | NOT NULL DEFAULT 'Active' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_appointments`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `appointment_number` | VARCHAR(25) | NOT NULL, UNIQUE | APT-YYYYMMDD-NNN |
| `appointment_type` | ENUM('Parent_Teacher_Meeting','Principal_Meeting','Grievance','Admission_Enquiry','Other') | NOT NULL | |
| `with_user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | Staff being met |
| `visitor_name` | VARCHAR(100) | NOT NULL | |
| `visitor_mobile` | VARCHAR(15) | NOT NULL | |
| `visitor_email` | VARCHAR(100) | NULL | |
| `purpose` | VARCHAR(300) | NOT NULL | |
| `appointment_date` | DATE | NOT NULL | |
| `start_time` | TIME | NOT NULL | |
| `end_time` | TIME | NOT NULL | |
| `status` | ENUM('Pending','Confirmed','Completed','Cancelled','No_Show') | NOT NULL DEFAULT 'Pending' | |
| `confirmed_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `confirmed_at` | DATETIME | NULL | |
| `cancellation_reason` | VARCHAR(300) | NULL | |
| `notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_lost_found`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `item_number` | VARCHAR(25) | NOT NULL, UNIQUE | LF-YYYY-NNNN |
| `item_description` | VARCHAR(300) | NOT NULL | |
| `category` | ENUM('Electronics','Clothing','Stationery','ID_Card','Money','Jewellery','Books','Sports','Other') | NOT NULL | |
| `found_date` | DATE | NOT NULL | |
| `found_location` | VARCHAR(200) | NOT NULL | |
| `found_by_name` | VARCHAR(100) | NOT NULL | |
| `found_by_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `photo_media_id` | INT UNSIGNED | NULL, FK→sys_media | |
| `status` | ENUM('Unclaimed','Claimed','Disposed','Returned_to_Authority') | NOT NULL DEFAULT 'Unclaimed' | |
| `claimant_name` | VARCHAR(100) | NULL | |
| `claimant_contact` | VARCHAR(15) | NULL | |
| `claimed_date` | DATE | NULL | |
| `disposal_notes` | TEXT | NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_key_register`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `key_label` | VARCHAR(100) | NOT NULL | e.g., "Science Lab A" |
| `key_tag_number` | VARCHAR(30) | NOT NULL | Physical tag on key |
| `key_type` | ENUM('Room','Lab','Vehicle','Cabinet','Store','Other') | NOT NULL | |
| `issued_to_user_id` | BIGINT UNSIGNED | NULL, FK→sys_users | NULL = available |
| `purpose` | VARCHAR(200) | NULL | |
| `issued_at` | DATETIME | NULL | |
| `expected_return_at` | DATETIME | NULL | |
| `returned_at` | DATETIME | NULL | |
| `status` | ENUM('Available','Issued','Overdue','Lost') | NOT NULL DEFAULT 'Available' | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_emergency_contacts`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `contact_name` | VARCHAR(100) | NOT NULL | |
| `organization` | VARCHAR(150) | NULL | |
| `contact_type` | ENUM('Hospital','Police','Fire','Ambulance','Transport','Utility','Parent_Emergency','Government','Other') | NOT NULL | |
| `primary_phone` | VARCHAR(15) | NOT NULL | |
| `alternate_phone` | VARCHAR(15) | NULL | |
| `address` | VARCHAR(200) | NULL | |
| `notes` | TEXT | NULL | |
| `sort_order` | TINYINT UNSIGNED | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_certificate_requests`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `request_number` | VARCHAR(25) | NOT NULL, UNIQUE | CERT-YYYY-NNNNN |
| `student_id` | INT UNSIGNED | NOT NULL, FK→std_students | |
| `cert_type` | ENUM('Bonafide','Character','Fee_Paid','Study','TC_Copy','Migration','Conduct','Other') | NOT NULL | |
| `purpose` | VARCHAR(200) | NOT NULL | |
| `copies_requested` | TINYINT UNSIGNED | NOT NULL DEFAULT 1 | |
| `is_urgent` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `applicant_name` | VARCHAR(100) | NULL | |
| `applicant_contact` | VARCHAR(15) | NULL | |
| `stages_json` | JSON | NULL | [{stage, status, by, at, remarks}] |
| `status` | ENUM('Pending_Approval','Approved','Rejected','Issued','Cancelled') | NOT NULL DEFAULT 'Pending_Approval' | |
| `approved_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `approved_at` | DATETIME | NULL | |
| `rejection_reason` | TEXT | NULL | |
| `cert_number` | VARCHAR(30) | NULL, UNIQUE | BON-YYYY-NNN, CHAR-YYYY-NNN |
| `issued_at` | DATETIME | NULL | |
| `issued_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `issued_to` | VARCHAR(100) | NULL | Receiver name |
| `media_id` | INT UNSIGNED | NULL, FK→sys_media | PDF |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_school_events`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | BIGINT UNSIGNED | PK AI | |
| `event_name` | VARCHAR(200) | NOT NULL | |
| `event_type` | ENUM('Academic','Sports','Cultural','PTM','Holiday','Exam','Admission','Other') | NOT NULL | |
| `start_date` | DATE | NOT NULL | |
| `end_date` | DATE | NOT NULL | |
| `description` | TEXT | NULL | |
| `venue` | VARCHAR(200) | NULL | |
| `audience` | ENUM('All','Students','Staff','Parents') | NOT NULL DEFAULT 'All' | |
| `is_public` | TINYINT(1) | NOT NULL DEFAULT 0 | Show on public website |
| `notification_sent` | TINYINT(1) | NOT NULL DEFAULT 0 | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | NULL, FK→sys_users | |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | |

---

#### `fof_communication_logs`, `fof_email_templates`, `fof_sms_logs`, `fof_complaints`, `fof_feedback_forms`, `fof_feedback_responses`

These tables are carried forward from V1 unchanged. See V1 Section 5.2 for full column specifications (lines 803–937 of V1 document).

### 5.3 Entity Relationship Summary

```
fof_visitor_purposes ──< fof_visitors (purpose_id)
vsm_visitors ──────────< fof_visitors (vsm_visitor_id)
sys_media ──────────────< fof_visitors (photo_media_id)

std_students ───────────< fof_gate_passes (student_id)
sys_users ──────────────< fof_gate_passes (staff_user_id, approved_by)

std_students ───────────< fof_early_departures (student_id)

sys_users ──────────────< fof_phone_diary (recipient_user_id, logged_by)
sys_users ──────────────< fof_postal_register (assigned_to_user_id)
sys_users ──────────────< fof_dispatch_register (dispatched_by)
sys_users ──────────────< fof_appointments (with_user_id, confirmed_by)

fof_circulars ──────────< fof_circular_distributions (circular_id)
sys_media ──────────────< fof_circulars (attachment_media_id)
sys_media ──────────────< fof_notices (attachment_media_id)
sys_media ──────────────< fof_lost_found (photo_media_id)

std_students ───────────< fof_certificate_requests (student_id)
sys_users ──────────────< fof_certificate_requests (approved_by, issued_by)
sys_media ──────────────< fof_certificate_requests (media_id)

fof_email_templates ────< fof_communication_logs (template_id)
fof_communication_logs ─< fof_sms_logs (communication_log_id)
```

### 5.4 Proposed Migration Order

1. `fof_visitor_purposes`
2. `fof_visitors`
3. `fof_gate_passes`
4. `fof_early_departures`
5. `fof_phone_diary`
6. `fof_postal_register`
7. `fof_dispatch_register`
8. `fof_circulars`
9. `fof_circular_distributions`
10. `fof_notices`
11. `fof_appointments`
12. `fof_lost_found`
13. `fof_key_register`
14. `fof_emergency_contacts`
15. `fof_email_templates`
16. `fof_communication_logs`
17. `fof_sms_logs`
18. `fof_complaints`
19. `fof_feedback_forms`
20. `fof_feedback_responses`
21. `fof_certificate_requests`
22. `fof_school_events`

---

## 6. API Endpoints & Routes

### 6.1 Web Route Summary

| # | Method | URI | Controller@Method | Name |
|---|--------|-----|-------------------|------|
| 1 | GET | `/front-office` | DashboardController@index | fof.dashboard |
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
| 14 | GET | `/front-office/early-departures` | EarlyDepartureController@index | fof.early-dep.index |
| 15 | POST | `/front-office/early-departures` | EarlyDepartureController@store | fof.early-dep.store |
| 16 | GET | `/front-office/phone-diary` | PhoneDiaryController@index | fof.phone.index |
| 17 | POST | `/front-office/phone-diary` | PhoneDiaryController@store | fof.phone.store |
| 18 | PATCH | `/front-office/phone-diary/{id}` | PhoneDiaryController@update | fof.phone.update |
| 19 | GET | `/front-office/postal` | PostalRegisterController@index | fof.postal.index |
| 20 | POST | `/front-office/postal` | PostalRegisterController@store | fof.postal.store |
| 21 | PATCH | `/front-office/postal/{id}/acknowledge` | PostalRegisterController@acknowledge | fof.postal.acknowledge |
| 22 | GET | `/front-office/dispatch` | DispatchRegisterController@index | fof.dispatch.index |
| 23 | POST | `/front-office/dispatch` | DispatchRegisterController@store | fof.dispatch.store |
| 24 | GET | `/front-office/circulars` | CircularController@index | fof.circulars.index |
| 25 | GET | `/front-office/circulars/create` | CircularController@create | fof.circulars.create |
| 26 | POST | `/front-office/circulars` | CircularController@store | fof.circulars.store |
| 27 | GET | `/front-office/circulars/{id}` | CircularController@show | fof.circulars.show |
| 28 | POST | `/front-office/circulars/{id}/approve` | CircularController@approve | fof.circulars.approve |
| 29 | POST | `/front-office/circulars/{id}/distribute` | CircularController@distribute | fof.circulars.distribute |
| 30 | GET | `/front-office/notices` | NoticeBoardController@index | fof.notices.index |
| 31 | POST | `/front-office/notices` | NoticeBoardController@store | fof.notices.store |
| 32 | PATCH | `/front-office/notices/{id}` | NoticeBoardController@update | fof.notices.update |
| 33 | DELETE | `/front-office/notices/{id}` | NoticeBoardController@destroy | fof.notices.destroy |
| 34 | GET | `/front-office/appointments` | AppointmentController@index | fof.appointments.index |
| 35 | GET | `/front-office/appointments/calendar` | AppointmentController@calendar | fof.appointments.calendar |
| 36 | POST | `/front-office/appointments` | AppointmentController@store | fof.appointments.store |
| 37 | POST | `/front-office/appointments/{id}/confirm` | AppointmentController@confirm | fof.appointments.confirm |
| 38 | POST | `/front-office/appointments/{id}/cancel` | AppointmentController@cancel | fof.appointments.cancel |
| 39 | GET | `/front-office/lost-found` | LostFoundController@index | fof.lost-found.index |
| 40 | POST | `/front-office/lost-found` | LostFoundController@store | fof.lost-found.store |
| 41 | PATCH | `/front-office/lost-found/{id}/claim` | LostFoundController@claim | fof.lost-found.claim |
| 42 | GET | `/front-office/keys` | KeyRegisterController@index | fof.keys.index |
| 43 | POST | `/front-office/keys/{id}/issue` | KeyRegisterController@issue | fof.keys.issue |
| 44 | POST | `/front-office/keys/{id}/return` | KeyRegisterController@return | fof.keys.return |
| 45 | GET | `/front-office/emergency-contacts` | EmergencyContactController@index | fof.emergency.index |
| 46 | POST | `/front-office/emergency-contacts` | EmergencyContactController@store | fof.emergency.store |
| 47 | PATCH | `/front-office/emergency-contacts/{id}` | EmergencyContactController@update | fof.emergency.update |
| 48 | GET | `/front-office/certificates` | CertificateRequestController@index | fof.certs.index |
| 49 | POST | `/front-office/certificates` | CertificateRequestController@store | fof.certs.store |
| 50 | GET | `/front-office/certificates/{id}` | CertificateRequestController@show | fof.certs.show |
| 51 | POST | `/front-office/certificates/{id}/approve` | CertificateRequestController@approve | fof.certs.approve |
| 52 | POST | `/front-office/certificates/{id}/reject` | CertificateRequestController@reject | fof.certs.reject |
| 53 | POST | `/front-office/certificates/{id}/issue` | CertificateRequestController@issue | fof.certs.issue |
| 54 | GET | `/front-office/certificates/{id}/download` | CertificateRequestController@download | fof.certs.download |
| 55 | GET | `/front-office/certificates/log` | CertificateRequestController@log | fof.certs.log |
| 56 | GET | `/front-office/complaints` | ComplaintController@index | fof.complaints.index |
| 57 | POST | `/front-office/complaints` | ComplaintController@store | fof.complaints.store |
| 58 | GET | `/front-office/complaints/{id}` | ComplaintController@show | fof.complaints.show |
| 59 | PATCH | `/front-office/complaints/{id}/resolve` | ComplaintController@resolve | fof.complaints.resolve |
| 60 | POST | `/front-office/complaints/{id}/escalate` | ComplaintController@escalate | fof.complaints.escalate |
| 61 | GET | `/front-office/feedback` | FeedbackController@index | fof.feedback.index |
| 62 | POST | `/front-office/feedback` | FeedbackController@store | fof.feedback.store |
| 63 | GET | `/front-office/feedback/{id}/report` | FeedbackController@report | fof.feedback.report |
| 64 | GET | `/front-office/communication/email/compose` | CommunicationController@emailCompose | fof.comm.email.compose |
| 65 | POST | `/front-office/communication/email/send` | CommunicationController@emailSend | fof.comm.email.send |
| 66 | GET/POST | `/front-office/communication/email/templates` | CommunicationController@templates* | fof.comm.templates.* |
| 67 | POST | `/front-office/communication/sms/send` | CommunicationController@smsSend | fof.comm.sms.send |
| 68 | GET | `/front-office/communication/sms/logs` | CommunicationController@smsLogs | fof.comm.sms.logs |
| 69 | GET | `/front-office/events` | SchoolEventController@index | fof.events.index |
| 70 | POST | `/front-office/events` | SchoolEventController@store | fof.events.store |
| 71 | PATCH | `/front-office/events/{id}` | SchoolEventController@update | fof.events.update |
| — | GET | `/feedback/{token}` | FeedbackController@publicForm | fof.public.feedback |
| — | POST | `/feedback/{token}` | FeedbackController@publicSubmit | fof.public.feedback.submit |

### 6.2 API Endpoints (Sanctum)

| Method | URI | Controller@Method | Purpose |
|--------|-----|-------------------|---------|
| GET | `/api/v1/fof/dashboard` | DashboardController@apiStats | Today's counters for dashboard widget |
| GET | `/api/v1/fof/visitors/today` | VisitorController@apiToday | Live visitor count |
| POST | `/api/v1/fof/visitors/{id}/checkout` | VisitorController@apiCheckout | Quick checkout from mobile |
| GET | `/api/v1/fof/gate-passes/pending` | GatePassController@apiPending | Pending approvals list |
| POST | `/api/v1/fof/gate-passes/{id}/approve` | GatePassController@apiApprove | Mobile approval |
| GET | `/api/v1/fof/notices/active` | NoticeBoardController@apiActive | Active notices for portal |
| GET | `/api/v1/fof/circulars` | CircularController@apiList | Circulars for parent/staff portal |
| GET | `/api/v1/fof/appointments/slots` | AppointmentController@apiSlots | Available slots for booking |
| GET | `/api/v1/fof/certificates/pending` | CertificateRequestController@apiPending | Pending certificates |
| GET | `/api/v1/fof/events` | SchoolEventController@apiList | Events for portal calendar |
| GET | `/api/v1/fof/emergency-contacts` | EmergencyContactController@apiList | Emergency contacts for app |
| POST | `/api/v1/fof/early-departures` | EarlyDepartureController@apiStore | Log departure from mobile |

---

## 7. UI Screens

| # | Screen | Route | Description |
|---|--------|-------|-------------|
| 1 | FOF Dashboard | fof.dashboard | Today: visitor count, pending gate passes, pending certificates, pending approvals, active keys out, unresolved complaints |
| 2 | Visitor Registration | fof.visitors.create | Quick form: name, mobile, ID proof, purpose, person to meet; VSM pre-fill support |
| 3 | Today's Visitor List | fof.visitors.index | Real-time In/Out list; Checkout button; filter by purpose, status |
| 4 | Visitor Pass Print | fof.visitors.pass | A6 print-optimized layout; `@media print` CSS |
| 5 | Gate Pass List | fof.gate-passes.index | Tabs: Pending Approvals / Active / History; approve/reject inline |
| 6 | Issue Gate Pass | fof.gate-passes.create | Person type → student/staff search → purpose → times |
| 7 | Early Departure Log | fof.early-dep.index | Today's departures with ATT sync status badges |
| 8 | Early Departure Form | fof.early-dep.create | Student search → departure time → collecting person ID capture |
| 9 | Phone Call Log | fof.phone.index | Date filter; Incoming/Outgoing tabs; pending actions flagged |
| 10 | Postal Register | fof.postal.index | Inward/Outward tabs; acknowledge button; tracking number display |
| 11 | Dispatch Register | fof.dispatch.index | Searchable outgoing correspondence log |
| 12 | Circular List | fof.circulars.index | Status badges (Draft/Pending/Approved/Distributed); create + distribute buttons |
| 13 | Circular Editor | fof.circulars.create | Rich text editor, audience selector, attachment upload |
| 14 | Notice Board | fof.notices.index | Pinned notices at top; active/archived tabs; emergency badge |
| 15 | Appointment Calendar | fof.appointments.calendar | Day/Week view colour-coded by type |
| 16 | Book Appointment | fof.appointments.create | Staff picker → date → available slot picker |
| 17 | Lost & Found Register | fof.lost-found.index | Item list with category icons; Claim button; overdue-retention flag |
| 18 | Key Register | fof.keys.index | Key list; status badges (Available/Issued/Overdue); issue/return actions |
| 19 | Emergency Contacts | fof.emergency.index | Contact cards grouped by type; phone-link for click-to-call |
| 20 | Certificate Requests | fof.certs.index | Tabs: Pending / Approved / Issued; urgent badges |
| 21 | Certificate Issue | fof.certs.issue | PDF preview panel + receiver name input + issue confirmation |
| 22 | Issuance Log | fof.certs.log | Searchable by cert number, student, date; download PDF |
| 23 | Complaint Register | fof.complaints.index | Urgency badges; status filter; Escalate to CMP button |
| 24 | Feedback Forms | fof.feedback.index | Active/closed forms; response count badges |
| 25 | Feedback Response Form | fof.public.feedback | Public URL; no auth; anonymous support |
| 26 | Email Compose | fof.comm.email.compose | Template picker; rich text editor; recipient group selector |
| 27 | SMS Compose + Logs | fof.comm.sms.* | Char counter; multi-SMS cost indicator; delivery status table |
| 28 | School Events | fof.events.index | Calendar view of school events; public toggle |

---

## 8. Business Rules

| Rule ID | Rule | Enforcement |
|---------|------|-------------|
| BR-FOF-001 | Visitor ID proof type and number must be captured | `RegisterVisitorRequest` — required fields |
| BR-FOF-002 | Visitors not checked out by school closing time auto-flagged `Overstay` | Scheduled command `fof:flag-overstay` runs at configurable closing time |
| BR-FOF-003 | Student gate passes require parent notification before exit | `GatePassService::createPass()` dispatches NTF; front desk warned on failure |
| BR-FOF-004 | A student may only have one active gate pass at a time | Validation query in `IssueGatePassRequest` |
| BR-FOF-005 | TC_Copy and Migration certificates require no outstanding fees | `CertificateIssuanceService` checks StudentFee module before issuing |
| BR-FOF-006 | Certificate numbers are unique per type per school-year | Format per type (BON-YYYY-NNN); UNIQUE constraint on `cert_number` |
| BR-FOF-007 | Government inspection visitor records cannot be deleted | `VisitorPolicy::delete()` blocks deletion when `purpose.is_government_visit = 1` |
| BR-FOF-008 | Approved circulars cannot be edited; a new version must be created | `CircularController::update()` blocked when status is Approved or Distributed |
| BR-FOF-009 | Postal register entries are locked after acknowledgement | `PostalRegisterController::update()` blocked when `acknowledged_at` is set |
| BR-FOF-010 | Anonymous feedback responses must not store respondent user ID | `FeedbackController::publicSubmit()` enforces NULL `respondent_user_id` when `is_anonymous = 1` |
| BR-FOF-011 | SMS over 160 characters counted as multi-SMS; cost shown before send | Client-side character counter; server-side SMS unit calculation in `SendBulkSmsRequest` |
| BR-FOF-012 | Key already issued to another person cannot be re-issued without return | `KeyRegisterController::issue()` checks current status before issuing |
| BR-FOF-013 | Student early departure must sync ATT module to mark absent for remaining periods | `EarlyDepartureService::syncAttendance()` called post-store; retry on failure |
| BR-FOF-014 | Emergency notices bypass display date constraints and are always shown | `NoticeBoardController` filters include `is_emergency = 1` regardless of date |
| BR-FOF-015 | Aadhar ID proof numbers displayed with only last 4 digits visible | UI masking in Blade views; full number stored encrypted in DB per tenant policy |

---

## 9. Workflows

### 9.1 Visitor Lifecycle

```
[Walk-in arrives]
    └──(staff registers)──► [In] (pass_number assigned, in_time set)
            ├──(staff marks checkout)──► [Out] (out_time set)
            └──(closing time + no checkout)──► [Overstay] (auto cron)
```

### 9.2 Gate Pass Lifecycle

```
[Request created] → status = Pending_Approval
    ├──(authority approves)──► Approved
    │       └──(person exits gate)──► Exited
    │               └──(person re-enters)──► Returned ✅
    ├──(authority rejects)──► Rejected
    └──(cancelled by issuer)──► Cancelled
```

### 9.3 Student Early Departure Flow

```
[Parent arrives at reception]
    └──(staff logs departure)──► fof_early_departures created
            ├──► NTF notification dispatched to parent (confirmation)
            └──► ATT service called → student marked absent for remaining periods
                    ├── att_sync_status = Synced ✅
                    └── att_sync_status = Failed → retry queue + front desk alert
```

### 9.4 Circular Lifecycle

```
[Draft created] → status = Draft
    └──(submitted for approval)──► Pending_Approval
            ├──(principal approves)──► Approved
            │       └──(distribute triggered)──► Distributed
            │               └── fof_circular_distributions records created
            │               └── NTF email/SMS dispatched per recipient
            └──(principal rejects)──► Draft (with rejection notes)
```

### 9.5 Certificate Request Lifecycle

```
[Request submitted] → status = Pending_Approval
    ├──(approver approves)──► Approved
    │       └──(front desk issues)──► Issued
    │               └── cert_number assigned
    │               └── PDF generated and stored in sys_media
    ├──(approver rejects)──► Rejected (reason stored, applicant notified)
    └──(cancelled)──► Cancelled
```

### 9.6 Appointment Flow

```
[Appointment booked] → status = Pending
    ├──(staff confirms)──► Confirmed
    │       └──(visitor arrives)──► Completed
    │       └──(visitor does not show)──► No_Show (auto-flagged)
    └──(staff cancels)──► Cancelled (reason recorded)
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|----------|-------------|
| Performance | Visitor registration completes in < 1 second; visitor list loads in < 2 seconds |
| Scalability | Support 300+ visitor registrations per day per tenant |
| Security | Aadhar numbers masked in UI (last 4 digits); full numbers follow tenant encryption policy |
| Audit | Certificate issuances, circular distributions, and government visit records logged in `sys_activity_logs` |
| Print Support | Visitor pass, gate pass, and early departure slip print-optimized via CSS `@media print` (no PDF download required for slips) |
| Availability | Real-time visitor dashboard available during school hours (7AM–6PM local) |
| Localisation | Certificate templates support regional language content via `glb_translations`; interface strings via Laravel `lang/` |
| Tablet Support | Visitor registration and early departure forms usable on tablet (receptionist common device) — responsive layout required |
| ATT Integration | Early departure ATT sync must succeed or surface prominently to receptionist; silent failure not acceptable |
| NTF Dependency | Email/SMS/circular send must gracefully degrade if NTF channel is unavailable; queue retry mechanism |
| Data Retention | Government inspection visitor records: permanent retention, no deletion allowed |

---

## 11. Dependencies

### 11.1 This Module Depends On

| Module | Tables / Channels Used | Reason |
|--------|------------------------|--------|
| SystemConfig (SYS) | `sys_users`, `sys_roles`, `sys_media`, `sys_activity_logs` | Auth, staff lookup, file storage, audit |
| SchoolSetup (SCH) | `sch_organizations`, `sch_classes`, `sch_sections` | School branding for certificates; class/section for circular/comm targeting |
| StudentProfile (STD) | `std_students` | Gate pass, early departure, certificate FK |
| Attendance (ATT) | Service call | Early departure syncs absence to ATT |
| Notification (NTF) | Email + SMS channels | Circular distribution, gate pass alerts, certificate notifications |
| StudentFee (FIN) | Balance check service | Certificate issuance fee clearance (TC, Migration) |
| Complaint (CMP) | `cmp_complaints` | FOF complaint escalation linkage |
| VSM | `vsm_visitors` | Pre-registered visitor handoff to FOF reception |

### 11.2 Modules That Depend on FOF

| Module | Dependency |
|--------|-----------|
| PPT (Parent Portal) | Reads `fof_circulars`, `fof_notices`, `fof_school_events`, `fof_certificate_requests` |
| STP (Student Portal) | Reads `fof_notices`, `fof_school_events`; submits certificate requests |
| VSM | References `fof_visitors` for visitor pass status; posts arrival notifications to FOF |

### 11.3 Implementation Order Recommendation

1. SYS, SCH, STD — must be complete
2. NTF — must be complete for circular distribution
3. ATT — must be complete for early departure sync
4. **FOF Phase 1 (Core Registers):** Visitor + Gate Pass + Early Departure + Phone Diary + Postal + Dispatch
5. **FOF Phase 2 (Communication):** Circulars + Notice Board + School Events
6. **FOF Phase 3 (Certificates + Complaints):** Certificate Request/Issuance + Complaint Handling
7. **FOF Phase 4 (Support Features):** Appointments + Lost & Found + Key Management + Emergency Contacts
8. **FOF Phase 5 (Feedback + Email/SMS):** Feedback Forms + Bulk Email/SMS Communication

---

## 12. Test Scenarios

| # | Test Name | Description | Type | Priority |
|---|-----------|-------------|------|----------|
| 1 | VisitorRegistrationTest | Register visitor — pass number generated, in_time set, status = In | Feature | High |
| 2 | VisitorCheckoutTest | Checkout visitor — out_time recorded, status = Out | Feature | High |
| 3 | OverstayFlagTest | Cron runs after closing — unchecked visitors flagged Overstay | Feature | High |
| 4 | GovtVisitDeleteBlockTest | Attempt to delete government visit record — blocked by policy | Feature | High |
| 5 | VSMHandoffTest | Visitor pre-registered in VSM — FOF auto-populates details | Feature | Medium |
| 6 | GatePassCreateTest | Create student gate pass — status = Pending_Approval, parent notified | Feature | High |
| 7 | DuplicateGatePassTest | Student has active gate pass — second request blocked | Feature | High |
| 8 | GatePassApprovalTest | Approve gate pass — status = Approved, front desk notified | Feature | High |
| 9 | GatePassLifecycleTest | Full lifecycle: Pending → Approved → Exited → Returned | Feature | High |
| 10 | EarlyDepartureAttSyncTest | Early departure logged — ATT marked absent for remaining periods | Feature | High |
| 11 | EarlyDepartureAttFailTest | ATT sync fails — departure record stays; front desk alert raised | Feature | High |
| 12 | CircularDraftApproveTest | Create draft → submit → principal approves → status = Approved | Feature | High |
| 13 | CircularEditBlockTest | Edit approved circular — blocked; new version required | Feature | High |
| 14 | CircularDistributionTest | Distribute circular — NTF dispatched to correct recipients, log created | Feature | High |
| 15 | CircularAudienceFilterTest | Circular for Class 5 only — only Class 5 parents receive it | Feature | High |
| 16 | NoticeEmergencyBypassTest | Emergency notice shown regardless of display_until date | Unit | Medium |
| 17 | AppointmentDoubleBookTest | Two appointments for same staff at same time — second blocked | Feature | Medium |
| 18 | KeyDoubleIssueTest | Key already issued — re-issue blocked until returned | Feature | Medium |
| 19 | CertificateRequestTest | Request Bonafide — request number assigned, status = Pending | Feature | High |
| 20 | CertificateFeesBlockTest | Request TC_Copy with outstanding fees — blocked | Feature | High |
| 21 | CertificateIssuanceTest | Issue certificate — PDF generated, cert_number unique, status = Issued | Feature | High |
| 22 | CertificateNumberUniqueTest | Two Bonafide same year — different cert numbers | Unit | High |
| 23 | PostalAcknowledgeLockTest | Acknowledge postal record — subsequent edit blocked | Feature | Medium |
| 24 | FeedbackAnonymousTest | Anonymous form submission — respondent_user_id NULL | Feature | High |
| 25 | FeedbackPublicTokenTest | Form accessed via public token — correct form rendered without auth | Feature | Medium |
| 26 | ComplaintEscalateTest | Escalate FOF complaint — CMP complaint created, `cmp_complaint_id` set | Feature | Medium |
| 27 | BulkEmailSendTest | Send email to all parents — recipient list resolved correctly, comm log created | Feature | Medium |
| 28 | SmsMultiPartTest | SMS > 160 chars — multi-SMS count shown in UI | Unit | Medium |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Visitor Register | Official log of all persons entering school premises — required for security and CBSE/State Board inspection |
| Visitor Pass | Printed slip given to registered visitor allowing campus access |
| Gate Pass | Authorization slip for students or staff to leave campus during school hours |
| Early Departure | Student collected by parent/guardian before school day ends; distinct from gate pass (student does not return) |
| Dak Register | Traditional term for inward government mail/correspondence register (Indian government institutions) |
| Postal Register | Log of all physical mail and courier items received or sent (FOF uses `fof_postal_register`) |
| Dispatch Register | Log of all official outgoing letters, documents, cheques (`fof_dispatch_register`) |
| Circular | Official school communication issued formally (numbered, dated, distributed to parents/staff) — distinct from informal notices |
| Notice Board | Digital announcement board (replacing physical board); notices have display date range and audience |
| Phone Diary | Manual/digital log of incoming and outgoing telephone calls at front desk |
| Overstay | Visitor who entered but did not check out by school closing time |
| Bonafide Certificate | Official certificate confirming current enrollment — most commonly requested |
| Character Certificate | Certificate on student's leaving; states conduct during time at school |
| TC | Transfer Certificate — issued when student leaves; required by next school for admission |
| Migration Certificate | Allows students to move between different educational boards |
| Lost and Found | Register of unclaimed items found on premises; matched to owners and disposed if unclaimed |
| Key Register | Log of all physical key issues and returns for rooms, labs, vehicles |
| Emergency Contact Directory | School's curated list of external emergency numbers (hospital, police, fire, etc.) |

---

## 14. Suggestions

1. **Visitor Self-Registration Kiosk:** A tablet at the school entrance with a simplified form. Same `fof_visitors` backend; public-facing route without auth. Reduces front desk load for large schools.

2. **Webcam Visitor Photo Capture:** Using WebRTC in browser, capture visitor photo on registration. Store in `sys_media` via `photo_media_id`. High security value — helps staff verify identity on re-entry. Works without external hardware.

3. **WhatsApp Channel for Gate Pass:** Gate pass approvals and parent departure notifications are strong WhatsApp use cases. `fof_communication_logs` already has `WhatsApp` ENUM channel value ready. Route via NTF's WhatsApp adapter once available.

4. **Digital Circular Archive for Parents:** Distributed circulars accessible in parent portal (PPT) in a searchable archive. Parents can retrieve missed circulars by year or keyword. Eliminates "I didn't receive it" complaints.

5. **Recurring School Events:** For events like PTM (happens every term) or weekly assembly, allow event recurrence rules (weekly/monthly/termly) to auto-generate calendar entries rather than manual creation each time.

6. **Appointment SMS Reminders:** 1-day and 1-hour before a confirmed appointment, auto-send NTF SMS reminder to the visitor/parent. Reduces no-shows significantly in Indian school context.

7. **Lost and Found Parent Notification:** When a new item is registered in Lost & Found with category `ID_Card` or `Electronics`, auto-notify all parents of that school day's attendees. Improves recovery rate.

8. **Certificate Template Engine (Premium):** Rather than hardcoded DomPDF templates, allow admin to design certificate templates (logo placement, signature, seal) via a drag-and-drop visual editor. Differentiating premium feature.

9. **Key Register RFID Support:** For schools with RFID infrastructure, integrate key tag scanning to auto-populate key tag number on issue/return. Works with the same `fof_key_register` table.

10. **FOF–VSM Two-Way Handoff:** VSM (gate security) can pre-register an expected visitor. When the visitor arrives at gate, VSM logs entry and pushes a notification to FOF dashboard ("Visitor for Principal's Office has arrived at gate"). FOF staff pulls up the pre-populated form to complete registration without re-entry.

---

## 15. Appendices

### Appendix A — RBS Module M Extract

```
Module M: Front Office & Reception
Code: M | Prefix: fro_ | Priority: P4 | Complexity: Small
Dependencies: B (Students)

Sub-modules:
  M1 — Visitor Management (visitor registration, photo, badge)
  M2 — Inquiry & Admission Inquiry (walk-in/phone inquiry, follow-up)
  M3 — Appointment Scheduling (meetings with teachers/principal)
  M4 — Gate Pass (student early dismissal, visitor exit pass)
  M5 — Courier & Postal (incoming/outgoing courier tracking) [📐]

Key Tables (RBS): fro_visitors, fro_visitor_passes, fro_inquiries,
  fro_inquiry_followups, fro_appointments, fro_gate_passes, fro_couriers

Business Rules:
  BR-M-001: Visitor badge must be returned before exit
  BR-M-002: Student gate pass requires parent/guardian verification
```

> Note: RBS uses prefix `fro_`; V2 standardizes on `fof_` per the module code assignment in the platform.

### Appendix B — V1 RBS Extract (Module D — Front Office & Communication)

```
D1 — Front Office Desk Management
  F.D1.1 — Visitor Management → FR-FOF-01
  F.D1.2 — Gate Pass → FR-FOF-02

D2 — Communication Management
  F.D2.1 — Email Communication → FR-FOF-16
  F.D2.2 — SMS Communication → FR-FOF-16

D3 — Complaint & Feedback Management
  F.D3.1 — Complaint Handling → FR-FOF-14
  F.D3.2 — Feedback Collection → FR-FOF-15

D4 — Document & Certificate Issuance
  F.D4.1 — Certificate Request → FR-FOF-13
  F.D4.2 — Certificate Issuance → FR-FOF-13
```

### Appendix C — Proposed Module File Structure

```
Modules/FrontOffice/
├── app/Http/Controllers/
│   ├── FrontOfficeDashboardController.php      [📐]
│   ├── VisitorController.php                   [📐]
│   ├── GatePassController.php                  [📐]
│   ├── EarlyDepartureController.php            [📐] NEW in V2
│   ├── PhoneDiaryController.php                [📐]
│   ├── PostalRegisterController.php            [📐] NEW in V2
│   ├── DispatchRegisterController.php          [📐]
│   ├── CircularController.php                  [📐] NEW in V2
│   ├── NoticeBoardController.php               [📐] NEW in V2
│   ├── AppointmentController.php               [📐] NEW in V2
│   ├── LostFoundController.php                 [📐] NEW in V2
│   ├── KeyRegisterController.php               [📐] NEW in V2
│   ├── EmergencyContactController.php          [📐] NEW in V2
│   ├── CertificateRequestController.php        [📐]
│   ├── ComplaintController.php                 [📐]
│   ├── FeedbackController.php                  [📐]
│   ├── CommunicationController.php             [📐]
│   └── SchoolEventController.php               [📐] NEW in V2
├── app/Http/Requests/
│   ├── RegisterVisitorRequest.php              [📐]
│   ├── IssueGatePassRequest.php                [📐]
│   ├── EarlyDepartureRequest.php               [📐] NEW
│   ├── StoreCircularRequest.php                [📐] NEW
│   ├── StoreNoticeRequest.php                  [📐] NEW
│   ├── BookAppointmentRequest.php              [📐] NEW
│   ├── IssueCertificateRequest.php             [📐]
│   ├── RequestCertificateRequest.php           [📐]
│   ├── SendBulkEmailRequest.php                [📐]
│   └── SendBulkSmsRequest.php                  [📐]
├── app/Models/
│   ├── VisitorPurpose.php, Visitor.php         [📐]
│   ├── GatePass.php                            [📐]
│   ├── EarlyDeparture.php                      [📐] NEW
│   ├── PhoneDiary.php                          [📐]
│   ├── PostalRegister.php                      [📐] NEW
│   ├── DispatchRegister.php                    [📐]
│   ├── Circular.php, CircularDistribution.php  [📐] NEW
│   ├── Notice.php                              [📐] NEW
│   ├── Appointment.php                         [📐] NEW
│   ├── LostFound.php                           [📐] NEW
│   ├── KeyRegister.php                         [📐] NEW
│   ├── EmergencyContact.php                    [📐] NEW
│   ├── CertificateRequest.php                  [📐]
│   ├── FofComplaint.php                        [📐]
│   ├── FeedbackForm.php, FeedbackResponse.php  [📐]
│   ├── CommunicationLog.php, EmailTemplate.php [📐]
│   ├── SmsLog.php                              [📐]
│   └── SchoolEvent.php                         [📐] NEW
├── app/Services/
│   ├── VisitorService.php                      [📐]
│   ├── GatePassService.php                     [📐]
│   ├── EarlyDepartureService.php               [📐] NEW
│   ├── CircularService.php                     [📐] NEW
│   ├── CertificateIssuanceService.php          [📐]
│   └── FrontOfficeCommunicationService.php     [📐]
├── app/Console/Commands/
│   └── FlagOverstayVisitorsCommand.php         [📐] fof:flag-overstay
├── app/Policies/
│   ├── VisitorPolicy.php, GatePassPolicy.php   [📐]
│   ├── CircularPolicy.php                      [📐] NEW
│   └── CertificateRequestPolicy.php            [📐]
├── database/migrations/                        [📐] 22 migration files
├── database/seeders/
│   ├── VisitorPurposeSeeder.php                [📐]
│   └── EmergencyContactSeeder.php              [📐] NEW
└── resources/views/
    ├── dashboard/, visitors/, gate-pass/
    ├── early-departure/, phone-diary/
    ├── postal/, dispatch/, circulars/
    ├── notices/, appointments/
    ├── lost-found/, keys/, emergency/
    ├── certificates/, complaints/
    ├── feedback/, communication/
    └── events/
```

---

## 16. V1 → V2 Delta

### 16.1 New Feature Groups (V2 Only)

| Feature | Tables Added | Controllers Added |
|---------|-------------|-------------------|
| Student Early Departure | `fof_early_departures` | `EarlyDepartureController` |
| Circular Management | `fof_circulars`, `fof_circular_distributions` | `CircularController` |
| Digital Notice Board | `fof_notices` | `NoticeBoardController` |
| Appointment Scheduling | `fof_appointments` | `AppointmentController` |
| Lost and Found Register | `fof_lost_found` | `LostFoundController` |
| Key Management Register | `fof_key_register` | `KeyRegisterController` |
| Emergency Contact Directory | `fof_emergency_contacts` | `EmergencyContactController` |
| School Calendar Events | `fof_school_events` | `SchoolEventController` |
| Postal Register (distinct from Dispatch) | `fof_postal_register` | `PostalRegisterController` |

### 16.2 V1 Features Carried Forward (All Unchanged in Scope)

| Feature | Status |
|---------|--------|
| Visitor Management (FR-FOF-01) | Carried forward; added `vsm_visitor_id` and `photo_media_id` columns to `fof_visitors` |
| Gate Pass (FR-FOF-02) | Carried forward unchanged |
| Phone Call Log (FR-FOF-04) | Carried forward; added `action_completed` column |
| Dispatch Register (FR-FOF-06) | Carried forward unchanged |
| Email Communication (FR-FOF-16) | Carried forward unchanged |
| SMS Communication (FR-FOF-16) | Carried forward unchanged |
| Complaint Handling (FR-FOF-14) | Carried forward; added `escalate` route |
| Feedback Collection (FR-FOF-15) | Carried forward unchanged |
| Certificate Request + Issuance (FR-FOF-13) | Carried forward unchanged |

### 16.3 V1 Scope Clarifications in V2

- **Complaint module separation:** V1 noted FOF complaints as separate from CMP. V2 adds explicit `escalate` action and route that creates a CMP complaint linked via `cmp_complaint_id`.
- **VSM integration:** V1 did not reference VSM. V2 adds `vsm_visitor_id` FK on `fof_visitors` and defines the handoff workflow.
- **ATT integration:** V1 did not include early departure. V2 adds the full early departure workflow with ATT sync and retry mechanism.
- **Postal vs Dispatch split:** V1 had a single `fof_dispatch_register` covering both inward and outward. V2 separates into `fof_postal_register` (courier/mail with tracking) and `fof_dispatch_register` (official outgoing correspondence) to match actual school register practice.
- **Table prefix:** RBS spec v2 uses `fro_` prefix in Module M. V2 standardizes on `fof_` per the module code (FOF) assignment used throughout this platform.

---

*Document generated: 2026-03-26 | Next review: at development kickoff*
