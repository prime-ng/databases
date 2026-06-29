# ADM — Admission Management | Complete Functional Analysis Pack
**Module:** Admission Management ("Admission Mgmt.") | **Code:** ADM | **Prefix:** `adm_` | **Layer:** Tenant (per-school)
**Date:** 2026-06-29 | **Author:** Business Analyst
**Sources read:** V2 Requirement (`ADM_Admission_Requirement.md`, 15 FR / 15 BR / 25 screens / 25 tests), canonical DDL (`Admission_DDL_v1.sql`, 20 tables / 927 lines), live application code (`Modules/Admission`: 18 controllers, 20 models, 6 services, 24 form requests, 13 policies, 84 views, 251-line web routes), Module Knowledge (`ADM_Admission.md`).

> **This single document is the source of truth for downstream gap analysis.** REQ-/BR-/RPT-/ENH-/RISK- IDs are assigned here and must never be renumbered. Business-language register is used throughout sections 1–7 and 11–18; technical register is confined to the marked technical sections (Data Dictionary technical view, Dependency Map). "Built" vs "Gap" reflects verification against the live code on 2026-06-29.

---

## Index
1. Module Overview (purpose, value, scope in/out, terminology)
2. User Roles & Access
3. Functional Requirements (REQ-ADM-001 … 021)
4. Business Rules Register (BR-ADM-001 … 022)
5. Data Requirements (business + technical data dictionary; privacy)
6. Workflows
7. Reporting & Analytics (RPT-ADM-001 … 008)
8. Future Enhancement Log (ENH-ADM-001 … 004)
9. Non-Functional Requirements (NFR-ADM-001 … 010)
10. Gap Analysis Readiness Index (coverage table + totals)
11. Requirements Traceability Matrix (RTM)
12. Requirement Conditions Catalog
13. Validation & Edge-Case Catalog
14. State Machine (FSM) Catalog
15. Cross-Module Dependency Map (technical)
16. Risk Register
17. Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks
18. User Stories (Gherkin) for P0/P1 requirements

---

## Section 1 — Module Overview

### 1.1 Purpose
The Admission Management module runs a school's entire pre-enrolment journey for each academic year: capturing prospective-student enquiries, taking full applications, verifying documents, conducting optional entrance tests and interviews, ranking applicants on a quota-aware merit list, allotting seats, issuing offer letters, collecting fees, and finally converting an accepted offer into a verified student record. It also handles year-end promotion of existing students, transfer-certificate issuance for leavers, and recording of disciplinary (behaviour) incidents.

### 1.2 Business Value
- Replaces paper admission registers and disconnected spreadsheets with one auditable pipeline.
- Gives leadership real-time visibility of the funnel (enquiry → enrolled) and seat fill against quotas.
- Enforces statutory rules (RTE/EWS reservation, NEP-2020 entrance-test restriction, age eligibility) consistently.
- Guarantees that a confirmed admission becomes a single, complete student record with no half-created data.

### 1.3 Scope

**In scope:** Admission cycle setup; seat capacity & quota configuration; document checklist configuration; enquiry/lead capture + follow-up CRM; full multi-step application; document upload & verification; interview scheduling; entrance test scheduling & mark entry; merit-list generation & ranking; seat allotment & offer letters; admission/application fee confirmation; waitlist promotion; withdrawal & refund; final enrolment conversion; year-end promotion; transfer certificate & alumni register; behaviour incidents & corrective actions; admission analytics funnel; sibling preference handling.

**Out of scope (≥3):**
1. Fee structure definition, invoice ledgers and receipt accounting — owned by StudentFee / Accounting (ADM only triggers/reads).
2. Day-to-day student records after enrolment (profile edits, attendance, exams) — owned by StudentProfile and the LMS modules.
3. Payment gateway account configuration and reconciliation — owned by Payment.
4. Cross-school / platform-level admission analytics — ADM data is isolated per school (database-per-tenant).
5. Notification template authoring and delivery channels — owned by Notification.

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Admission Cycle | A defined window during which the school accepts applications for one academic year. |
| Enquiry (Lead) | First contact from a prospective family, before a full application exists. |
| Application | The completed admission request with student, guardian, previous-school and document details. |
| Quota | A reserved seat category: General, Government, Management, RTE, NRI, Staff Ward, Sibling, EWS. |
| Merit List | A ranked list of applicants for a class+quota, scored on entrance/interview/academic components plus sibling bonus, against a cut-off. |
| Allotment / Offer | Assignment of a seat to a shortlisted applicant, communicated by an offer letter with a response deadline. |
| Enrolment | Conversion of an accepted, fee-paid offer into a verified student record. |
| Promotion Batch | A year-end operation that moves a class of students into the next academic session. |
| Transfer Certificate (TC) | The official leaving document issued to a departing student. |
| Behaviour Incident | A recorded disciplinary event with severity and an optional corrective action. |

---

## Section 2 — User Roles & Access

### 2.1 Actors
- **School Admin** — full control of all admission functions and settings.
- **Admission Counselor** — owns leads and applications; processes the pipeline.
- **Front Office Staff** — captures walk-in enquiries only.
- **Principal / Vice Principal** — signs off merit lists, approves allotments, issues TCs.
- **Class Teacher** — submits promotion recommendations/remarks; views students.
- **Finance Staff** — confirms application/admission fees; processes refunds; clears fee status for TC.
- **Parent / Guardian (Public)** — submits online enquiry/application and tracks status. *(Self-service surface is a current gap — see REQ-ADM-021.)*
- **System (automated)** — status logging, notifications, waitlist promotion. *(Automation surface partially a gap — see REQ-ADM-013.)*

### 2.2 Role–Feature Matrix (● full, ◐ partial/own-records, ○ view, — none)
| Feature | School Admin | Counselor | Front Office | Principal | Class Teacher | Finance | Parent |
|---------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Cycle / Seat / Quota / Checklist setup | ● | — | — | ○ | — | — | — |
| Enquiry capture & follow-up | ● | ● | ◐ | ○ | — | — | ◐(submit) |
| Application create/verify | ● | ● | — | ○ | — | — | ◐(submit) |
| Entrance test & marks | ● | ◐ | — | ○ | — | — | — |
| Merit list & allotment | ● | ◐ | — | ● | — | — | — |
| Offer letter & fee confirm | ● | ◐ | — | ● | — | ● | ○(own) |
| Withdrawal & refund | ● | ◐ | — | ○ | — | ● | ◐(request) |
| Enrolment conversion | ● | ◐ | — | ● | — | — | — |
| Promotion | ● | — | — | ● | ◐ | — | — |
| TC & Alumni | ● | — | — | ● | — | ○ | — |
| Behaviour incidents | ● | — | — | ● | ◐ | — | — |
| Analytics funnel | ● | ○ | — | ● | — | — | — |

*Per-school isolation: every role acts only within its own tenant database; there are no cross-school permissions.*

---

## Section 3 — Functional Requirements

> Format per requirement: ID · Priority · Tags · Description · Actors · Key Business Rules · Acceptance Criteria · Build Status.
> Priority: Core (P0) / Standard (P1) / Enhanced (P2). Tags from the controlled vocabulary.

### REQ-ADM-001 — Admission Cycle Configuration
**Priority:** Core (P0) · **Tags:** [CONFIGURATION] · **Built:** Yes (AdmissionCycleController, 289 LOC)
**Description:** The School Admin creates and manages an admission cycle per academic year — name, code, open/close dates, application fee, admission-number format, sibling bonus, age rules, refund policy, and an optional public-form slug. A cycle moves Draft → Active → Closed → Archived, and only one cycle may be Active per academic year.
**Actors:** Initiates — School Admin · Processes — System · Views — Principal.
**Business Rules:** BR-ADM-016 (one Active cycle per year), BR-ADM-017 (end date after start date).
**Acceptance Criteria:**
- A cycle cannot be saved with end date earlier than or equal to start date.
- Activating a cycle while another is Active for the same academic year is refused.
- Cycle code is unique per school.
- A cycle can be soft-deleted, listed in trash, restored, and force-deleted.

### REQ-ADM-002 — Seat Capacity & Quota Configuration
**Priority:** Core (P0) · **Tags:** [CONFIGURATION] · **Built:** Yes (SeatCapacityController, QuotaConfigController)
**Description:** For each cycle and class the school defines seat budgets per quota type, including RTE/EWS reserved seats and application-fee waivers. Seat capacity carries running allotted/enrolled counters used to block over-allotment.
**Actors:** Initiates — School Admin · Processes — System (counter maintenance) · Views — Principal.
**Business Rules:** BR-ADM-005 (RTE 25% / fee waiver), BR-ADM-013 (over-allotment guard), BR-ADM-018 (unique seat budget per cycle+class+quota).
**Acceptance Criteria:**
- A duplicate seat-budget row for the same cycle+class+quota is refused.
- Reserved seats cannot exceed total seats.
- The allotted/enrolled counters are visible per class+quota.

### REQ-ADM-003 — Document Checklist Configuration
**Priority:** Standard (P1) · **Tags:** [CONFIGURATION] · **Built:** Yes (DocumentChecklistController, 217 LOC)
**Description:** The School Admin defines which documents applicants must provide (mandatory or optional), accepted file formats, maximum size, and display order. System-default checklist items exist as global templates and may be overridden per cycle/class.
**Actors:** Initiates — School Admin · Views — Counselor.
**Business Rules:** BR-ADM-019 (system-default templates), BR-ADM-007 (mandatory docs gate verification).
**Acceptance Criteria:**
- A checklist item may be created with no cycle (global template) and flagged as system default.
- Mandatory flag, accepted formats and max size are configurable per item.
- Items support soft-delete/restore.

### REQ-ADM-004 — Lead / Enquiry Capture
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW] · **Built:** Yes (EnquiryController, 212 LOC)
**Description:** Staff capture a prospective student's enquiry — student and contact details, class sought, lead source and assigned counselor. Each enquiry gets an auto-generated number (ENQ-YYYY-NNNNN) and moves through a lead lifecycle. The system flags potential siblings and duplicate mobiles.
**Actors:** Initiates — Front Office / Counselor · Processes — System (numbering, sibling/duplicate detection) · Views — School Admin.
**Business Rules:** BR-ADM-001 (age warning), BR-ADM-015/020 (sibling auto-detect), BR-ADM-020b (duplicate-mobile flag), BR-ADM-021 (no enquiry without an Active cycle).
**Acceptance Criteria:**
- Saving an enquiry assigns a unique ENQ number.
- An underage DOB for the class shows a warning but does not block save.
- A contact mobile matching an existing guardian sets the sibling-lead flag.
- An enquiry can be assigned to a counselor and converted to an application.

### REQ-ADM-005 — Follow-up & CRM
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][NOTIFICATION] · **Built:** Yes (FollowUpController, 67 LOC)
**Description:** Counselors log follow-up activities (call/meeting/email/SMS/walk-in) against an enquiry, schedule the next contact, record the outcome, and receive reminders before a scheduled follow-up.
**Actors:** Initiates — Counselor · Processes — System (reminder) · Views — School Admin.
**Business Rules:** BR-ADM-022 (reminder dispatched once before scheduled time).
**Acceptance Criteria:**
- A follow-up records type, scheduled time, outcome and notes.
- Completing a follow-up updates the parent enquiry's lead status where applicable.
- A reminder is flagged as sent so it is not sent twice.

### REQ-ADM-006 — Admission Application
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW] · **Built:** Yes (ApplicationController, 227 LOC)
**Description:** A full application captures student, guardian, address, previous-school, quota and sibling/staff-ward details, with an auto-generated number (APP-YYYY-NNNNN). It may originate from an enquiry or be entered directly. The application advances through a status lifecycle, every transition being logged.
**Actors:** Initiates — Counselor / Parent · Processes — System · Views — Principal.
**Business Rules:** BR-ADM-001 (age), BR-ADM-012 (Aadhar uniqueness, service-layer), BR-ADM-003 (quota selection), BR-ADM-009b (every transition logged).
**Acceptance Criteria:**
- Submitting an application assigns a unique APP number.
- A duplicate Aadhar within the cycle shows a warning without blocking.
- Status changes are recorded with from/to status, actor and timestamp.
- An application can be soft-deleted/restored.

### REQ-ADM-007 — Document Upload & Verification
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][APPROVAL] · **Built:** Yes (within Application flow + checklist)
**Description:** Documents are uploaded against checklist items, stored privately, and individually marked Verified or Rejected (rejection requires remarks). Physical receipt of originals can be recorded. All mandatory documents must be verified before the application advances to Verified.
**Actors:** Initiates — Parent/Counselor (upload) · Processes — Counselor (verify) · Views — Principal.
**Business Rules:** BR-ADM-007 (mandatory gate), BR-ADM-007b (rejection remarks required), BR-ADM-019b (one upload per checklist item per application).
**Acceptance Criteria:**
- An application cannot move Submitted → Verified while any mandatory document is unverified.
- Rejecting a document without remarks is refused.
- Each checklist item accepts at most one active uploaded document per application.

### REQ-ADM-008 — Application Verification & Interview Scheduling
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][NOTIFICATION] · **Built:** Yes (ApplicationController actions)
**Description:** After document checks, staff schedule an interview (date/time, venue, interviewer), record interview notes and a score, and move the application to Verified/Shortlisted/Rejected.
**Actors:** Initiates — Counselor · Processes — System (notification) · Views — Principal/Parent.
**Business Rules:** BR-ADM-009b (transition logging), BR-ADM-008b (rejection reason required when Rejected).
**Acceptance Criteria:**
- An interview can be scheduled with venue and interviewer.
- Marking an application Rejected requires a rejection reason.
- The applicant is notified of an interview schedule (notification gap — see RISK-ADM-005).

### REQ-ADM-009 — Entrance Test Management
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][REPORT] · **Built:** Yes (EntranceTestController, 229 LOC)
**Description:** Staff schedule entrance tests per class, register candidates (with auto roll numbers), enter marks (overall and per subject), and set pass/fail/absent results. Tests for Classes 1–2 raise an NEP-2020 advisory warning.
**Actors:** Initiates — Counselor · Processes — System · Views — Principal.
**Business Rules:** BR-ADM-011 (NEP-2020 advisory), BR-ADM-009c (test time validity), BR-ADM-009d (one candidate row per application per test).
**Acceptance Criteria:**
- Scheduling a test for Class 1 or 2 shows a warning but is allowed.
- Test start time must be before end time.
- Marks entry computes a total and sets Pass/Fail/Absent.

### REQ-ADM-010 — Merit List Generation & Ranking
**Priority:** Core (P0) · **Tags:** [WORKFLOW][REPORT] · **Built:** Yes (MeritListController 239 LOC + MeritListService 141 LOC)
**Description:** For a cycle+class+quota, the system computes a composite score per applicant from weighted entrance, interview and academic components, applies the sibling bonus where eligible, ranks applicants, marks them Shortlisted/Waitlisted/Rejected against seat count and cut-off, and the list moves Draft → Published → Finalized.
**Actors:** Initiates — School Admin / Principal · Processes — System (scoring) · Views — Counselor.
**Business Rules:** BR-ADM-015 (sibling bonus only if staff-confirmed), BR-ADM-010c (scoring weights sum to 100), BR-ADM-010d (below cut-off → Rejected).
**Acceptance Criteria:**
- Generated entries are ranked by descending composite score.
- Sibling bonus is added only when the application is staff-confirmed as sibling.
- Applicants beyond the seat count are Waitlisted; those below cut-off are Rejected.
- A published merit list is visible to the allotment step.

### REQ-ADM-011 — Seat Allotment & Offer Letter
**Priority:** Core (P0) · **Tags:** [WORKFLOW][REPORT][NOTIFICATION] · **Built:** Yes (AllotmentController, 222 LOC)
**Description:** Shortlisted applicants are allotted a seat (class and optionally section), an offer letter PDF is generated with an admission number and response deadline, and the parent accepts or declines. Allotment is blocked when the quota seat budget is exhausted.
**Actors:** Initiates — Principal / School Admin · Processes — System (PDF, counters) · Views — Parent.
**Business Rules:** BR-ADM-013 (seat guard), BR-ADM-003 (admission-number format & uniqueness), BR-ADM-014 (offer expiry deadline).
**Acceptance Criteria:**
- Allotment is refused once allotted seats reach the quota budget.
- Issuing an offer generates a unique admission number and an offer-letter PDF.
- The parent can accept or decline an offer; declining frees the seat.

### REQ-ADM-012 — Admission & Application Fee Confirmation
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][INTEGRATION] · **Built:** Partial (manual confirmation only)
**Description:** The application fee (at submission) and admission fee (after allotment) are recorded as paid, with amount and date. Online payment confirmation via the Payment module is intended but the webhook is not built; today fees are confirmed manually by Finance.
**Actors:** Initiates — Finance / System · Views — Parent.
**Business Rules:** BR-ADM-006 (application fee non-refundable by default), BR-ADM-005 (fee waiver quotas), BR-ADM-002b (admission fee required before enrolment).
**Acceptance Criteria:**
- Marking a fee paid records amount and date.
- Enrolment is blocked until the admission fee is confirmed.
- Online webhook confirmation is idempotent **(gap — webhook not implemented; see RISK-ADM-002)**.

### REQ-ADM-013 — Waitlist Auto-Promotion
**Priority:** Standard (P1) · **Tags:** [SCHEDULED][WORKFLOW][NOTIFICATION] · **Built:** No (Gap)
**Description:** When an offer is declined or its deadline passes, the next waitlisted candidate should be automatically promoted to an offer and notified. A daily scheduled job should mark expired offers and trigger promotion.
**Actors:** Initiates — System (scheduler) · Views — School Admin.
**Business Rules:** BR-ADM-014 (offer expiry + auto-promotion).
**Acceptance Criteria:**
- An offer past its deadline is set to Expired automatically.
- The next waitlisted candidate is promoted and notified.
- Manual promotion remains possible meanwhile.
**Note:** No scheduled command exists today — this requirement is currently unmet.

### REQ-ADM-014 — Withdrawal & Refund
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][APPROVAL] · **Built:** Yes (WithdrawalController, 163 LOC)
**Description:** A family may withdraw before enrolment. The system records the reason, computes the refund-eligible amount from the cycle's refund policy and the time since payment, and moves the refund Not_Eligible / Pending → Approved → Paid under Finance approval.
**Actors:** Initiates — Counselor / Parent · Processes — Finance · Views — School Admin.
**Business Rules:** BR-ADM-006 (refund policy tiers), BR-ADM-014b (refund window).
**Acceptance Criteria:**
- Refund-eligible amount is computed and shown before submitting a withdrawal.
- A withdrawal with no fee paid is Not_Eligible.
- Refund advances only Pending → Approved → Paid.

### REQ-ADM-015 — Final Enrolment Conversion
**Priority:** Core (P0) · **Tags:** [WORKFLOW][INTEGRATION] · **Built:** Yes (EnrollmentController + EnrollmentService 216 LOC)
**Description:** An accepted, admission-fee-paid offer is converted, in a single all-or-nothing operation, into a portal login account, a student profile, and a current-year academic placement (class/section/roll number), linking any confirmed sibling. The allotment is then marked Enrolled. Any failure rolls everything back.
**Actors:** Initiates — School Admin / Principal · Processes — System (transactional cross-module write) · Views — Counselor.
**Business Rules:** BR-ADM-002 (atomic enrolment), BR-ADM-002b (admission fee first), BR-ADM-008 (roll number unique in class-section/year), BR-ADM-010 (one placement per student per year).
**Acceptance Criteria:**
- Enrolment is refused if the admission fee is not confirmed.
- A successful enrolment creates the login, profile and placement together.
- A failure mid-process leaves no partial records.
- Enrolling the same student twice in one academic year is refused.

### REQ-ADM-016 — Year-End Promotion
**Priority:** Core (P0) · **Tags:** [WORKFLOW] · **Built:** Yes (PromotionController 397 LOC + PromotionService 197 LOC)
**Description:** At year end, staff create a promotion batch from a source class+session to a destination class+session, review each student as Promoted/Detained/Transferred/Alumni/Left, assign new sections and roll numbers, and confirm. Confirmation appends new academic-session placements; re-running a confirmed batch is safe.
**Actors:** Initiates — School Admin / Principal · Processes — System · Views — Class Teacher.
**Business Rules:** BR-ADM-009 (append-only; old record retained), BR-ADM-009e (idempotent confirm), BR-ADM-008 (new roll numbers unique).
**Acceptance Criteria:**
- Confirming a batch creates next-year placements without altering current-year records.
- Detained students get a same-class placement in the new session.
- Re-confirming a batch does not duplicate placements.

### REQ-ADM-017 — Transfer Certificate & Alumni Register
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][REPORT] · **Built:** Yes (AlumniController 359 LOC + TransferCertificateService 154 LOC)
**Description:** For a leaving student, staff issue a Transfer Certificate (unique TC number per year) as a PDF with a QR verification code, after confirming fee clearance. Duplicate (re-issue) TCs reference the original. Alumni are listed in a filterable register.
**Actors:** Initiates — Principal · Processes — System (PDF/QR) · Views — School Admin.
**Business Rules:** BR-ADM-004 (fee-clearance gate), BR-ADM-017b (TC number unique per year), BR-ADM-017c (duplicate references original).
**Acceptance Criteria:**
- A TC cannot be issued while fees are outstanding.
- Issuing a TC produces a unique TC number and a PDF with QR code.
- A re-issued TC is flagged duplicate and references the original.

### REQ-ADM-018 — Behaviour Incident Management
**Priority:** Enhanced (P2) · **Tags:** [DATA_ENTRY][WORKFLOW][NOTIFICATION] · **Built:** Yes (AlumniController incident actions + BehaviorIncident/Action models)
**Description:** Staff record disciplinary incidents per student (type, severity, description, witnesses, score impact), take corrective actions (warning … expulsion), and resolve incidents Open → Action_Taken / Escalated → Closed. Critical incidents notify principal and parent.
**Actors:** Initiates — Class Teacher / Staff · Processes — System (notification) · Views — Principal.
**Business Rules:** BR-ADM-018b (Critical → parent+principal notified), BR-ADM-018c (score impact signed).
**Acceptance Criteria:**
- A Critical incident flags parent notification.
- A corrective action can be attached to an incident with dates.
- Score impact may be negative (a deduction).

### REQ-ADM-019 — Admission Analytics Funnel
**Priority:** Enhanced (P2) · **Tags:** [DASHBOARD][REPORT] · **Built:** Yes (AdmissionAnalyticsController 76 LOC + Service 224 LOC)
**Description:** A dashboard shows the conversion funnel (enquiry → applied → verified → shortlisted → allotted → enrolled), seat fill by quota, lead-source breakdown, and counselor performance, with export.
**Actors:** Views — School Admin / Principal.
**Business Rules:** none beyond read-only aggregation.
**Acceptance Criteria:**
- The funnel shows counts and conversion rates per stage for a chosen cycle.
- Seat fill is shown per class+quota.
- Counselor performance is listed.

### REQ-ADM-020 — Sibling Preference Rules
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][CONFIGURATION] · **Built:** Yes (within enquiry/application/merit flow)
**Description:** The system auto-detects siblings at enquiry (mobile match), lets staff confirm the sibling link on the application, and applies a configurable merit bonus only to staff-confirmed siblings.
**Actors:** Initiates — System (detect) / Counselor (confirm) · Views — School Admin.
**Business Rules:** BR-ADM-015 (bonus only when staff-confirmed), BR-ADM-020 (auto-detect on mobile match).
**Acceptance Criteria:**
- Auto-detected siblings are flagged but receive no bonus until confirmed.
- The bonus value is configurable per cycle.
- A confirmed sibling's composite score includes the bonus.

### REQ-ADM-021 — Public Admission Portal (Online Form + Status Tracker)
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][INTEGRATION] · **Built:** No (Gap)
**Description:** A public, unauthenticated, mobile-responsive multi-step form should let parents submit an enquiry/application (with consent capture and document upload), pay online, and track status by application number. The form should be rate-limited and accessible (WCAG 2.1 AA).
**Actors:** Initiates — Parent (Public) · Processes — System · Views — Counselor.
**Business Rules:** BR-ADM-021b (rate-limit), BR-ADM-021c (parent consent required).
**Acceptance Criteria:**
- An unauthenticated parent can submit an enquiry/application via a public URL.
- The form is rate-limited per IP.
- A parent can look up current status by application number.
**Note:** No public route, no status-tracker, no rate-limiting exist today — this requirement is currently unmet.

---

## Section 4 — Business Rules Register

| BR ID | Rule (business statement) | Type | Trigger | Enforcement Point | Built |
|-------|---------------------------|------|---------|-------------------|:----:|
| BR-ADM-001 | Applicant age must fall within the class min/max on the cut-off date (default Jun 1); out-of-range shows a warning, not a block. | Validation | Enquiry/Application save | StoreEnquiryRequest, StoreApplicationRequest | Yes |
| BR-ADM-002 | Enrolment creates login + student + academic placement in one all-or-nothing operation. | Concurrency/Workflow | Enrolment confirm | EnrollmentService::enrollStudent() in DB transaction | Yes |
| BR-ADM-002b | The admission fee must be confirmed before enrolment. | Workflow | Enrolment confirm | EnrollmentController / EnrollStudentRequest | Yes |
| BR-ADM-003 | The admission number is unique per school-year and follows the cycle's configurable format. | Validation | Offer-letter issue | UNIQUE on admission number; format from cycle | Yes |
| BR-ADM-004 | A Transfer Certificate may not be issued while the student has outstanding fees. | Workflow | TC issue | TransferCertificateService (FIN balance check) | Verify |
| BR-ADM-005 | RTE/EWS quota reserves the mandated share (≈25% Class 1) and waives the application fee. | Calculation/Validation | Quota config / application fee | adm_quota_config.application_fee_waiver | Yes |
| BR-ADM-006 | The application fee is non-refundable by default; the cycle refund policy defines tiered exceptions by days since payment. | Calculation | Withdrawal | refund_policy_json + Withdrawal flow | Yes |
| BR-ADM-007 | All mandatory documents must be verified before an application advances to Verified. | Workflow | Verify transition | AdmissionPipelineService::verifyApplication() | Yes |
| BR-ADM-007b | Rejecting a document requires remarks. | Validation | Document verify | Document verification form | Yes |
| BR-ADM-008 | A roll number is unique within a class-section for an academic session. | Validation | Enrolment / Promotion | UNIQUE in std_student_academic_sessions | Yes (STD) |
| BR-ADM-008b | A rejection reason is required when an application is set Rejected. | Validation | Reject action | ApplicationController::reject | Yes |
| BR-ADM-009 | Promotion appends new academic-session placements; current-year records are retained, not modified. | Workflow | Promotion confirm | PromotionService | Yes |
| BR-ADM-009b | Every application status change is logged with from/to status, actor and timestamp. | Workflow | Any status change | adm_application_stages insert | Yes |
| BR-ADM-009c | An entrance test's start time must be before its end time. | Validation | Test save | StoreEntranceTestRequest | Yes |
| BR-ADM-009d | At most one candidate row per application per entrance test. | Validation | Candidate register | UNIQUE (entrance_test_id, application_id) | Yes |
| BR-ADM-009e | Re-confirming an already-confirmed promotion batch does not duplicate placements. | Concurrency | Promotion re-run | PromotionService firstOrCreate | Yes |
| BR-ADM-010 | One academic placement per student per academic session. | Validation | Enrolment / Promotion | UNIQUE (student_id, academic_session_id) | Yes (STD) |
| BR-ADM-010c | Merit scoring weights (entrance/interview/academic) must sum to 100. | Validation | Merit generation | MeritListService / StoreMeritListRequest | Verify |
| BR-ADM-010d | An applicant scoring below the merit cut-off is marked Rejected. | Calculation | Merit generation | MeritListService | Yes |
| BR-ADM-011 | Entrance tests for Classes 1–2 raise a non-blocking NEP-2020 advisory. | Validation | Test save | StoreEntranceTestRequest (warning) | Yes |
| BR-ADM-012 | Aadhar is optional; when provided, uniqueness is checked at the service layer (not by the database). | Validation | Application save | ApplicationService (service-layer only) | Verify |
| BR-ADM-013 | Allotment is blocked once allotted seats reach the quota's total seats. | Validation/Concurrency | Allotment | MeritListService::allotSeat() vs adm_seat_capacity | Yes |
| BR-ADM-014 | An offer expires after the configured deadline; the next waitlisted candidate is auto-promoted. | Workflow/Scheduled | Daily / decline | (scheduled job) | **No** |
| BR-ADM-014b | Refund eligibility is determined by the refund window since payment. | Calculation | Withdrawal | Withdrawal flow + refund_policy_json | Yes |
| BR-ADM-015 | The sibling merit bonus applies only to staff-confirmed siblings; auto-detection alone is insufficient. | Calculation | Merit generation | is_sibling must be staff-set | Yes |
| BR-ADM-016 | Only one Active admission cycle may exist per academic year. | Workflow | Cycle activate | AdmissionCycleController::activate | Verify |
| BR-ADM-017 | A cycle's end date must be after its start date. | Validation | Cycle save | StoreAdmissionCycleRequest | Yes |
| BR-ADM-017b | A TC number is unique per school-year. | Validation | TC issue | UNIQUE on tc_number | Yes |
| BR-ADM-017c | A duplicate (re-issued) TC references the original TC. | Workflow | TC re-issue | original_tc_id self-reference | Yes |
| BR-ADM-018 | Seat budget rows are unique per cycle+class+quota. | Validation | Seat config | UNIQUE (cycle, class, quota) | Yes |
| BR-ADM-018b | A Critical behaviour incident auto-notifies principal and parent. | Workflow/Notification | Incident save | Incident flow | Verify |
| BR-ADM-019 | System-default document checklist items exist as global templates (no cycle). | Configuration | Checklist seed/config | is_system flag, nullable cycle | Yes |
| BR-ADM-020 | A contact mobile matching an existing guardian flags the enquiry as a sibling lead. | Workflow | Enquiry save | Sibling auto-detect | Yes |
| BR-ADM-021 | An enquiry/application cannot be received without an Active admission cycle. | Validation | Enquiry/Application save | Cycle status check | Verify |
| BR-ADM-021b | The public form is rate-limited per IP. | Security | Public submit | (public route) | **No** |
| BR-ADM-022 | A follow-up reminder is dispatched at most once before the scheduled time. | Workflow/Notification | Scheduler | reminder_sent flag | Verify |

*(BR-ADM-021c parent-consent is tracked under REQ-ADM-021 acceptance criteria; not separately numbered to avoid renumbering risk.)*

---

## Section 5 — Data Requirements

### 5.1 Business entities (narrative)
The module centres on the **Application** as it travels the pipeline. An **Admission Cycle** frames each year and owns **Seat Capacity**, **Quota Config** and **Document Checklist**. **Enquiries** capture leads (with **Follow-ups**); some convert to Applications. Applications gather **Application Documents** and a **Stage** history, may sit for **Entrance Tests** (as **Test Candidates**), and are ranked into **Merit Lists** (with **Merit List Entries**). A shortlisted entry becomes an **Allotment** (offer), which on acceptance drives **Enrolment** (writing student records) or, on cancellation, a **Withdrawal** with refund. Existing students are moved by **Promotion Batches** (per-student **Promotion Records**), leave with a **Transfer Certificate**, and may accrue **Behaviour Incidents** and **Behaviour Actions**.

### 5.2 Privacy classification (key fields)
| Field group | Classification |
|-------------|----------------|
| Aadhar number, caste/social category, blood group, allergies, religion | **Sensitive (PII)** — restricted access; encryption required at rest (currently a gap) |
| Student/guardian names, DOB, contact mobile/email, address | **Confidential** — staff-only |
| Application/enquiry numbers, status, class, quota, merit rank | **Internal** |
| Seat budgets, quota config, cycle dates | **Internal** |
| Published merit position (to the applicant) | **Confidential** (own record only) |

### 5.3 Technical Data Dictionary (technical register — 20 `adm_*` tables, tenant_db)
| Table | Purpose | Key columns / notes |
|-------|---------|---------------------|
| `adm_admission_cycles` | Annual cycle config | `cycle_code` UNIQUE; `status` ENUM(Draft/Active/Closed/Archived); `admission_no_format` default `{YEAR}/{SEQ}`; `sibling_bonus_score`; `age_rules_json`; `refund_policy_json`; `application_form_url` slug |
| `adm_document_checklist` | Required docs | `admission_cycle_id` NULL = global template; `class_id` NULL = all; `is_mandatory`, `is_system`, `accepted_formats`, `max_size_kb` |
| `adm_quota_config` | Quota settings | `quota_type` ENUM(8); `total_seats`, `reserved_seats`, `application_fee_waiver` |
| `adm_seat_capacity` | Seat budget + counters | UNIQUE(cycle,class,quota); `seats_allotted`, `seats_enrolled` running counters |
| `adm_entrance_tests` | Test sessions | `max_marks`, `passing_marks` NULL, `subjects_json`, `status` ENUM(Scheduled/Completed/Cancelled) |
| `adm_enquiries` | Leads | `enquiry_no` UNIQUE (ENQ-YYYY-NNNNN); `status` ENUM(8); `is_sibling_lead`, `sibling_student_id`, `is_duplicate`, `counselor_id` |
| `adm_merit_lists` | Merit header | `quota_type`; `criteria_json` (weights→100); `sibling_bonus_score` (copied); `cutoff_score`; `status` ENUM(Draft/Published/Finalized) |
| `adm_follow_ups` | Follow-up log | `follow_up_type` ENUM(5); `outcome` ENUM(5); `reminder_sent` |
| `adm_applications` | Full applications | `application_no` UNIQUE (APP-YYYY-NNNNN); `status` ENUM(10); `aadhar_no` non-unique KEY (service-layer uniqueness); `is_sibling`, `is_staff_ward`; interview + fee fields |
| `adm_application_documents` | Uploaded docs | UNIQUE(application,checklist_item); `media_id`→`sys_media` (INT); `verification_status` ENUM(Pending/Verified/Rejected) |
| `adm_application_stages` | Status audit trail | free-text `from_status`/`to_status`; `changed_by` NULL=system; `changed_at` default now — immutable trail |
| `adm_entrance_test_candidates` | Candidates + marks | UNIQUE(test,application); `roll_no`; `result` ENUM(Pass/Fail/Absent/Pending); `subject_marks_json` |
| `adm_merit_list_entries` | Ranked entries | `merit_rank`; `composite_score`; component scores; `sibling_bonus_applied`; `merit_status` ENUM(Shortlisted/Waitlisted/Rejected) |
| `adm_allotments` | Offers/seats | `admission_no` nullable UNIQUE; `offer_expires_at`; `status` ENUM(Offered/Accepted/Declined/Expired/Enrolled/Withdrawn); `enrolled_student_id`→`std_students` set on enrolment |
| `adm_promotion_batches` | Year-end batches | from/to session+class; `criteria_json`; `status` ENUM(Draft/Confirmed); counters |
| `adm_withdrawals` | Withdrawal/refund | `reason` ENUM(6); `refund_eligible_amount`; `refund_status` ENUM(Not_Eligible/Pending/Approved/Paid) |
| `adm_promotion_records` | Per-student promotion | `result` ENUM(Promoted/Detained/Transferred/Alumni/Left); from/to class-section |
| `adm_transfer_certificates` | TC issuance | `tc_number` UNIQUE; `fees_cleared`; `is_duplicate`+`original_tc_id` self-ref; `media_id` PDF |
| `adm_behavior_incidents` | Disciplinary log | `incident_type` ENUM(8); `severity` ENUM(Low/Medium/High/Critical); `behavior_score_impact` **signed TINYINT**; `status` ENUM(Open/Action_Taken/Closed/Escalated) |
| `adm_behavior_actions` | Corrective actions | `action_type` ENUM(7); start/end dates; parent-meeting fields |

**Schema reconciliation note:** there is **no migration layer** — the schema is bootstrapped directly from `Admission_DDL_v1.sql`. The three-way DDL ↔ migration ↔ model reconcile therefore reduces to DDL ↔ model: model `$casts`/`$fillable` were spot-checked (e.g. `Application` casts dates/decimals/booleans, no `encrypted` cast on `aadhar_no` — confirming the encryption gap). All FK columns to `sys_users`/`std_students`/`sch_*`/`sys_media` are INT UNSIGNED; `created_by`/`updated_by` are BIGINT UNSIGNED audit columns (no FK).

---

## Section 6 — Workflows

**Workflow 1 — Lead to Application.** Trigger: enquiry captured (staff or, intended, public). Steps: capture → auto-number → sibling/duplicate flag → assign counselor → follow-ups → mark Interested → convert to Application. Exception: Not_Interested/Duplicate close the lead. Notifications: enquiry acknowledgement; follow-up reminder.

**Workflow 2 — Application to Verification.** Trigger: application submitted. Steps: fee recorded → documents uploaded → each document verified/rejected → all mandatory verified → interview scheduled → Verified/Shortlisted/Rejected. Exception: missing mandatory doc blocks Verified; rejection requires reason. Every transition logged. Notifications: status change, interview schedule (notification wiring is a gap).

**Workflow 3 — Merit, Allotment & Offer.** Trigger: verified pool for a class+quota. Steps: generate merit list (score + sibling bonus + cut-off) → publish → allot shortlisted (seat-guard) → issue offer letter (admission number, deadline) → parent accepts/declines. Exception: seat budget exhausted blocks allotment; decline frees seat; expiry should auto-promote next waitlisted (**gap — no job**). Notifications: offer letter, expiry reminder (gap).

**Workflow 4 — Enrolment Conversion.** Trigger: offer accepted + admission fee confirmed. Steps (single transaction): create login → create student profile → create current-year placement (class/section/roll) → link sibling → mark allotment Enrolled + set seat enrolled counter. Exception: any failure rolls back fully; duplicate placement refused. Notifications: welcome/enrolment confirmation.

**Workflow 5 — Year-End Promotion.** Trigger: session changeover. Steps: create batch (from/to session+class) → load students → mark Promoted/Detained/Transferred/Alumni/Left → assign sections + roll numbers → confirm (append next-year placements). Exception: detained → same-class placement; re-confirm idempotent. Notifications: none mandatory.

---

## Section 7 — Reporting & Analytics

| RPT ID | Report | Audience | Frequency | Contents | Export | Built |
|--------|--------|----------|-----------|----------|--------|:----:|
| RPT-ADM-001 | Admission Funnel / Conversion | School Admin, Principal | On-demand | Stage counts + conversion rates (enquiry→enrolled) per cycle | Screen/Excel | Yes |
| RPT-ADM-002 | Quota Seat Fill | School Admin, Principal | On-demand | Total/allotted/enrolled per class+quota; fill % | Screen/Excel | Yes |
| RPT-ADM-003 | Counselor Performance | School Admin | On-demand | Leads, conversions, follow-up completion per counselor | Screen/Excel | Yes |
| RPT-ADM-004 | Offer Letter (PDF) | Parent | Per offer | Student/seat/admission-number/deadline on letterhead | PDF | Yes |
| RPT-ADM-005 | Entrance Test Hall Ticket (PDF) | Parent | Per test | Candidate, roll no, venue, date/time | PDF | Gap |
| RPT-ADM-006 | Transfer Certificate (PDF+QR) | Parent / next school | Per TC | TC number, conduct, academic status, QR verification | PDF | Yes |
| RPT-ADM-007 | Behaviour Report | Principal, Class Teacher | On-demand | Repeat offenders, frequency, score trend per student | Screen | Yes |
| RPT-ADM-008 | Promotion History | School Admin | Per session | Batch results: promoted/detained/left counts | Screen/Excel | Yes |

---

## Section 8 — Future Enhancement Log

| ENH ID | Enhancement | Rationale | Promote-to-REQ trigger |
|--------|-------------|-----------|------------------------|
| ENH-ADM-001 | Per-document OCR auto-extraction | Speed document verification | When OCR service available |
| ENH-ADM-002 | Auto-balance section strengths at enrolment | Even class sizes | On request |
| ENH-ADM-003 | Behaviour module extraction (`BEH`) | Discipline is broader than admission | On platform roadmap |
| ENH-ADM-004 | Multi-language public form (Hindi/Marathi/…) | Wider parent reach | When public portal (REQ-ADM-021) built |

---

## Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement (measurable) | Built |
|--------|----------|--------------------------|:----:|
| NFR-ADM-001 | Performance | Enrolment transaction completes < 5s | Likely |
| NFR-ADM-002 | Performance | Merit list for 1,000 applicants generates < 10s | Verify |
| NFR-ADM-003 | Scalability | Support 5,000 applications per cycle per tenant; peak Feb–May | Verify |
| NFR-ADM-004 | Security | Application documents in private storage (not public) | Verify |
| NFR-ADM-005 | Security | Aadhar encrypted at rest (AES-256) | **No (gap)** |
| NFR-ADM-006 | Security | Public form rate-limited (≤10 submissions/hr/IP) | **No (gap — no public form)** |
| NFR-ADM-007 | Data Integrity | All application transitions logged; enrolment transactional with rollback | Yes |
| NFR-ADM-008 | Availability | Payment webhook auto-retry (3 attempts), idempotent | **No (gap)** |
| NFR-ADM-009 | Accessibility | Public form WCAG 2.1 AA, keyboard-navigable | **No (gap)** |
| NFR-ADM-010 | Compliance | Parent consent captured; Aadhar access role-restricted (PDPB) | **No (gap)** |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Coverage table (downstream contract)
| Requirement ID | Feature | Priority | Tags | DDL Entity | Screen | API | Notification | Test Case |
|----------------|---------|----------|------|:----:|:----:|:----:|:----:|:----:|
| REQ-ADM-001 | Admission Cycle Config | P0 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-ADM-002 | Seat/Quota Config | P0 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-ADM-003 | Document Checklist Config | P1 | CONFIG | Yes | Yes | No | No | Yes |
| REQ-ADM-004 | Enquiry Capture | P0 | DATA_ENTRY/WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-ADM-005 | Follow-up & CRM | P1 | DATA_ENTRY/NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-ADM-006 | Application | P0 | DATA_ENTRY/WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-ADM-007 | Document Upload & Verify | P0 | DATA_ENTRY/APPROVAL | Yes | Yes | Yes | No | Yes |
| REQ-ADM-008 | Verify & Interview | P1 | WORKFLOW/NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-ADM-009 | Entrance Test | P1 | WORKFLOW/REPORT | Yes | Yes | No | No | Yes |
| REQ-ADM-010 | Merit List | P0 | WORKFLOW/REPORT | Yes | Yes | No | No | Yes |
| REQ-ADM-011 | Allotment & Offer | P0 | WORKFLOW/REPORT/NOTIFICATION | Yes | Yes | No | Yes | Yes |
| REQ-ADM-012 | Fee Confirmation | P1 | WORKFLOW/INTEGRATION | Yes | Yes | Yes | Yes | Yes |
| REQ-ADM-013 | Waitlist Auto-Promotion | P1 | SCHEDULED/WORKFLOW | Yes | No | No | Yes | Yes |
| REQ-ADM-014 | Withdrawal & Refund | P1 | WORKFLOW/APPROVAL | Yes | Yes | No | No | Yes |
| REQ-ADM-015 | Enrolment Conversion | P0 | WORKFLOW/INTEGRATION | Yes | Yes | No | Yes | Yes |
| REQ-ADM-016 | Year-End Promotion | P0 | WORKFLOW | Yes | Yes | No | No | Yes |
| REQ-ADM-017 | TC & Alumni | P1 | WORKFLOW/REPORT | Yes | Yes | No | No | Yes |
| REQ-ADM-018 | Behaviour Incident | P2 | DATA_ENTRY/WORKFLOW/NOTIFICATION | Yes | Yes | Yes | Yes | Yes |
| REQ-ADM-019 | Analytics Funnel | P2 | DASHBOARD/REPORT | Yes | Yes | Yes | No | Yes |
| REQ-ADM-020 | Sibling Preference | P1 | WORKFLOW/CONFIG | Yes | Yes | No | No | Yes |
| REQ-ADM-021 | Public Portal | P1 | DATA_ENTRY/INTEGRATION | Yes | No | Yes | Yes | Yes |

### 10.2 Business-rule coverage
22 BRs (BR-ADM-001 … 022). Built/enforced: ~17; "Verify" (needs code confirmation): BR-004, 010c, 012, 016, 018b, 021, 022; **Not built**: BR-014 (waitlist job), BR-021b (rate-limit).

### 10.3 Report coverage
8 reports (RPT-ADM-001 … 008). Built: 7; **Gap**: RPT-ADM-005 (hall ticket PDF).

### 10.4 Totals (reconciled)
- **Requirements:** 21 — P0 = 9, P1 = 9, P2 = 3.
- **Business Rules:** 22 numbered (BR-ADM-001 … 022; several carry "b/c/d/e" sub-conditions for a total of ~36 enforceable conditions).
- **Reports:** 8.
- **Workflows:** 5. **FSMs:** 5. **Enhancements:** 4. **NFRs:** 10. **Risks:** 6.
- **Major build gaps:** REQ-ADM-013 (waitlist job), REQ-ADM-021 (public portal), REQ-ADM-012 partial (payment webhook), NFR-ADM-005/006/008/009/010, RPT-ADM-005; 0 tests; 0 migrations.

---

## Section 11 — Requirements Traceability Matrix

| REQ | BR refs | Primary screen(s) | Workflow | Report | Code (controller/service) | Status |
|-----|---------|-------------------|----------|--------|---------------------------|--------|
| REQ-ADM-001 | 016,017 | Cycles | — | — | AdmissionCycleController | Built |
| REQ-ADM-002 | 005,013,018 | Seats, Quotas | — | RPT-002 | SeatCapacity/QuotaConfig | Built |
| REQ-ADM-003 | 007,019 | Checklists | — | — | DocumentChecklistController | Built |
| REQ-ADM-004 | 001,020,021 | Enquiries | WF1 | — | EnquiryController | Built |
| REQ-ADM-005 | 022 | Follow-ups | WF1 | RPT-003 | FollowUpController | Built |
| REQ-ADM-006 | 001,003,012,009b | Applications | WF2 | — | ApplicationController/AdmissionPipelineService | Built |
| REQ-ADM-007 | 007,007b,019b | Application docs | WF2 | — | ApplicationController + checklist | Built |
| REQ-ADM-008 | 008b,009b | Application detail | WF2 | — | ApplicationController | Built |
| REQ-ADM-009 | 009c,009d,011 | Entrance tests | — | RPT-005(gap) | EntranceTestController | Built |
| REQ-ADM-010 | 010c,010d,015 | Merit lists | WF3 | — | MeritListController/MeritListService | Built |
| REQ-ADM-011 | 003,013,014 | Allotments | WF3 | RPT-004 | AllotmentController | Built |
| REQ-ADM-012 | 002b,005,006 | Allotment/fee | WF3 | — | AllotmentController (manual) | Partial |
| REQ-ADM-013 | 014 | — | WF3 | — | (none) | **Gap** |
| REQ-ADM-014 | 006,014b | Withdrawals | — | — | WithdrawalController | Built |
| REQ-ADM-015 | 002,002b,008,010 | Enroll | WF4 | — | EnrollmentController/EnrollmentService | Built |
| REQ-ADM-016 | 008,009,009e | Promotions | WF5 | RPT-008 | PromotionController/PromotionService | Built |
| REQ-ADM-017 | 004,017b,017c | Alumni/TC | — | RPT-006 | AlumniController/TransferCertificateService | Built |
| REQ-ADM-018 | 018b,018c | Incidents | — | RPT-007 | AlumniController(incidents) | Built |
| REQ-ADM-019 | — | Analytics | — | RPT-001 | AdmissionAnalyticsController/Service | Built |
| REQ-ADM-020 | 015,020 | (within enquiry/app) | WF1/WF3 | — | enquiry+merit flow | Built |
| REQ-ADM-021 | 021b | (none) | WF1 | — | (none) | **Gap** |

*Test column omitted: 0 tests exist for any REQ — uniform critical gap.*

---

## Section 12 — Requirement Conditions Catalog
*(Consolidated, deduplicated; keyed to BR IDs. Canonical copy may also be placed at `5-Requirement_Conditions/Admission_Conditions.md`; this section is authoritative.)*

| Condition (=BR) | Entity/Field | Condition (business) | Type | On-Violation Behaviour |
|-----------------|--------------|----------------------|------|------------------------|
| BR-ADM-001 | Enquiry/Application DOB | Age within class min/max on cut-off | Validation | Warn, allow |
| BR-ADM-003 | Allotment admission_no | Unique per school-year, formatted | Validation | Block, error |
| BR-ADM-007 | Application status | Mandatory docs verified before Verified | Workflow | Block transition |
| BR-ADM-008b | Application rejection | Reason required when Rejected | Validation | Block, error |
| BR-ADM-009c | Entrance test times | start < end | Validation | Block, error |
| BR-ADM-009d | Test candidate | One per application per test | Validation | Block, error |
| BR-ADM-010c | Merit criteria_json | Weights sum to 100 | Validation | Block, error |
| BR-ADM-012 | Application aadhar_no | Unique when provided (service) | Validation | Warn |
| BR-ADM-013 | Allotment vs seat budget | allotted < total | Validation | Block, error |
| BR-ADM-014 | Allotment offer_expires_at | Auto-expire + promote | Workflow/Scheduled | (unmet) |
| BR-ADM-016 | Cycle activate | One Active per year | Workflow | Block, error |
| BR-ADM-017 | Cycle dates | end > start | Validation | Block, error |
| BR-ADM-017b | TC tc_number | Unique per year | Validation | Block, error |
| BR-ADM-018 | Seat budget | Unique per cycle+class+quota | Validation | Block, error |
| BR-ADM-002b | Enrolment | Admission fee confirmed first | Workflow | Block, error |
| BR-ADM-010(STD) | Academic placement | One per student per session | Validation | Block (DB unique) |

---

## Section 13 — Validation & Edge-Case Catalog

| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency | Expected |
|------------|-------|---------|----------|------------|-------------|----------|
| Cycle dates | start<end | end≤start | end=start+1d | dates null | two admins activate cycles same year | reject overlap (BR-016) |
| Seat allotment | allotted<total | allotted=total | last seat | total=0 | two allotments race last seat | guard must be atomic on counter (BR-013) |
| Aadhar | unique provided | duplicate in cycle | very long | null (allowed) | same Aadhar two sessions | warn only (BR-012) |
| Merit weights | sum=100 | sum=90 | 100 exactly | null criteria | — | reject if ≠100 (BR-010c) |
| Mandatory docs | all verified | one pending | last doc | none uploaded | — | block Verified (BR-007) |
| Enrolment | fee paid, new student | fee unpaid | — | missing class/section | re-enrol same year | block; rollback on failure (BR-002/002b/010) |
| Roll number | unique in section/year | duplicate | first/last roll | null | concurrent promotion | reject duplicate (BR-008) |
| Offer expiry | within window | past deadline | exactly deadline | null deadline | — | should auto-expire (BR-014 — **unmet**) |
| TC issue | fees cleared | fees outstanding | zero balance | no student | — | block if outstanding (BR-004) |
| Refund | within window | beyond window | exact window day | no fee paid | — | compute tier / Not_Eligible (BR-006/014b) |

---

## Section 14 — State Machine (FSM) Catalog

**FSM 1 — Application** (driven by `adm_applications.status` ENUM; transitions logged to `adm_application_stages`).
| From | Event | Guard | To | Side-effect |
|------|-------|-------|----|-------------|
| Draft | submit | app fee handling | Submitted | stage row |
| Submitted | verify | all mandatory docs verified | Verified | stage row |
| Submitted | docs incomplete | — | Draft | stage row |
| Verified | shortlist | — | Shortlisted | stage row |
| Verified | reject | reason given | Rejected | stage row |
| Shortlisted | allot | seat available | Allotted | allotment created |
| Shortlisted | waitlist | seat full | Waitlisted | merit entry waitlisted |
| Waitlisted | seat freed | — | Allotted | promotion |
| Allotted | enrol | offer accepted + adm fee | Enrolled | student created |
| any pre-Enrolled | withdraw | — | Withdrawn | withdrawal record |
Terminal: Enrolled, Rejected, Withdrawn. Illegal: Draft→Enrolled directly (blocked).

**FSM 2 — Allotment Offer** (`adm_allotments.status`): Offered → Accepted / Declined / Expired; Accepted → Enrolled / Withdrawn. Declined/Expired free the seat (Expired requires the missing job).

**FSM 3 — Enquiry Lead** (`adm_enquiries.status`): New → Assigned → Contacted → {Interested → Converted | Not_Interested | Callback → Contacted | Duplicate}.

**FSM 4 — Withdrawal/Refund** (`adm_withdrawals.refund_status`): Not_Eligible / Pending → Approved → Paid.

**FSM 5 — Promotion Batch** (`adm_promotion_batches.status`): Draft → Confirmed (idempotent). Per-student outcome ENUM: Promoted/Detained/Transferred/Alumni/Left.

---

## Section 15 — Cross-Module Dependency Map (technical register)

**Inbound (ADM reads):**
| Source | Data/Entity | Why |
|--------|-------------|-----|
| SystemConfig | `sys_users`, `sys_roles`, `sys_media`, `sys_settings`, `sys_activity_logs` | auth, RBAC, file storage, audit |
| SchoolSetup | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_org_academic_sessions_jnt` | class/section/session context |
| StudentProfile | `std_students`, `std_guardians`, `std_siblings_jnt`, `std_student_academic_sessions` | sibling detect; read on promotion |
| StudentFee | `fin_invoices`, `fin_fee_structures` | fee/refund/TC clearance |
| GlobalMaster | `glb_countries`, `glb_states`, `glb_boards` | address/board dropdowns |
| LmsExam | `exm_*` results | promotion criteria |

**Outbound (ADM writes / feeds):**
| Target | Mechanism | What |
|--------|-----------|------|
| StudentProfile | direct write in `EnrollmentService` transaction | `sys_users`, `std_students`, `std_student_academic_sessions`, `std_siblings_jnt` |
| StudentFee / Accounting | (intended) fee/refund trigger | application + admission fee, refund |
| Payment | (intended) webhook | online fee confirmation — **not wired** |
| Notification | inline dispatch (no events) | stage transitions, offer, reminders — **not event-driven** |
| Attendance / Timetable / ParentPortal | downstream consumers | rely on enrolled placements |

**Integration risk:** the cross-module write in `EnrollmentService::enrollStudent()` couples ADM directly to StudentProfile models (`Modules\StudentProfile\Models\Student`, `StudentAcademicSession`) inside a single DB transaction guarded by `Schema::hasTable` for the sibling junction — correct but tightly coupled and untested.

---

## Section 16 — Risk Register

| Risk ID | Risk | Cat | L | I | Mitigation | Owner |
|---------|------|-----|---|---|-----------|-------|
| RISK-ADM-001 | Enrolment cross-module transaction leaves partial/orphaned records on failure | Data integrity | M | H | Integration tests for rollback; wrap all writes in one transaction (done) | Backend |
| RISK-ADM-002 | No payment webhook → fees mis-marked / manual errors / no idempotency | Integration | M | H | Build idempotent webhook with signature verification | Backend |
| RISK-ADM-003 | Waitlist never auto-promotes (no job) → seats stranded, parents not promoted | Workflow | H | M | Implement `adm:expire-offers` daily command | Backend |
| RISK-ADM-004 | Aadhar/PII stored in clear → PDPB/privacy exposure | Security/Compliance | M | H | Encrypt at rest; restrict access by role | Security |
| RISK-ADM-005 | Notifications not event-driven → missed/duplicate parent alerts | Reliability | M | M | Introduce events/listeners; central NTF dispatch | Backend |
| RISK-ADM-006 | Zero automated tests on scoring, FSM and enrolment | Quality | H | H | Add Pest tests for the 25 specified scenarios | QA |

---

## Section 17 — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks

### 17.1 MoSCoW
- **Must (P0):** REQ-001,002,004,006,007,010,011,015,016 — all built; harden with tests.
- **Should (P1):** REQ-003,005,008,009,012,013,014,017,020,021 — 012/013/021 have build gaps.
- **Could (P2):** REQ-018,019 (+020 polish).
- **Won't (this release):** ENH-001 (OCR), ENH-003 (BEH extraction).

### 17.2 Effort & Sprint Tasks (gap-closing focus)
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------:|-----------|--------|
| 1 | `adm:expire-offers` daily command + waitlist promotion (REQ-013, BR-014) | Backend | 12 | AdmissionPipelineService | S1 |
| 2 | Payment webhook (idempotent, signed) for app/admission fee (REQ-012) | Integration | 16 | PAY module | S1 |
| 3 | Aadhar encryption (cast/service) + role-restricted access (NFR-005/010) | Security | 10 | — | S1 |
| 4 | Public admission portal: online form + status tracker + consent + rate-limit (REQ-021) | Frontend+Backend | 40 | cycle slug | S2 |
| 5 | Hall ticket PDF (RPT-005) | Backend | 6 | EntranceTest | S2 |
| 6 | Tenant migrations for all 20 tables | Schema | 14 | DDL | S2 |
| 7 | Pest tests: enrolment rollback, merit scoring, application FSM, promotion idempotency, refund compute (25 scenarios) | Testing | 40 | all services | S2–S3 |
| 8 | Convert NTF dispatch to events/listeners (RISK-005) | Backend | 12 | NTF | S3 |
| 9 | Verify/finish: BR-004 FIN check, BR-010c weights, BR-012 service uniqueness, BR-016 one-active, BR-018b critical-notify | Backend | 10 | — | S3 |
| 10 | Finish or remove stub `AdmissionController` apiResource | Backend | 3 | — | S3 |

---

## Section 18 — User Stories (Gherkin) — P0/P1

**US-ADM-001 (REQ-ADM-001, P0)** — As a School Admin, I want to configure an admission cycle so the school can accept applications for a year.
- Scenario happy: Given no Active cycle for 2026-27, When I create and activate a cycle with valid dates, Then it becomes Active.
- Scenario boundary: Given a cycle with end date = start date, When I save, Then it is rejected.
- Scenario permission: Given a Counselor, When they open cycle settings, Then access is refused.
- DoD: unique code; one Active/year; soft-delete works; audit logged.

**US-ADM-004 (REQ-ADM-004, P0)** — As Front Office, I want to capture a walk-in enquiry so the lead enters the funnel.
- Happy: Given an Active cycle, When I save a valid enquiry, Then an ENQ number is assigned.
- Boundary: Given an underage DOB, When I save, Then a warning shows but the enquiry saves.
- Empty-state: Given no Active cycle, When I try to capture, Then I am told no cycle is open.
- DoD: sibling-lead flag set on mobile match; duplicate flag set; year-scoped.

**US-ADM-006 (REQ-ADM-006, P0)** — As a Counselor, I want to submit a full application so it can be processed.
- Happy: When I submit a complete application, Then an APP number is assigned and status = Submitted.
- Exception: Given a duplicate Aadhar in the cycle, Then a warning shows without blocking.
- DoD: every status change logged to the stage trail.

**US-ADM-007 (REQ-ADM-007, P0)** — As a Counselor, I want mandatory documents verified before an application is Verified.
- Happy: When all mandatory docs are verified, Then I can move the application to Verified.
- Exception: Given one mandatory doc pending, When I try to verify, Then it is blocked.
- Permission: A document rejected without remarks is refused.

**US-ADM-010 (REQ-ADM-010, P0)** — As a Principal, I want a ranked merit list so seats go to top applicants.
- Happy: When I generate a list, Then entries are ranked by composite score with sibling bonus applied only to confirmed siblings.
- Boundary: Given weights summing ≠100, Then generation is rejected.
- DoD: below-cutoff → Rejected; beyond seats → Waitlisted.

**US-ADM-011 (REQ-ADM-011, P0)** — As a Principal, I want to allot seats and issue offers within the quota budget.
- Happy: When I allot a shortlisted applicant with seats free, Then an admission number and offer PDF are generated.
- Boundary: Given the quota budget is full, When I allot, Then it is blocked.
- DoD: parent accept/decline supported; decline frees the seat.

**US-ADM-015 (REQ-ADM-015, P0)** — As a School Admin, I want enrolment to create the student record atomically.
- Happy: Given an accepted, fee-paid offer, When I enrol, Then login + profile + placement are created together and the allotment is Enrolled.
- Exception: Given a failure mid-process, Then no partial records remain.
- Boundary: Enrolling the same student twice in one year is refused.

**US-ADM-016 (REQ-ADM-016, P0)** — As a Principal, I want to promote a class at year end.
- Happy: When I confirm a batch, Then next-year placements are created and current-year records are untouched.
- Boundary: Re-confirming does not duplicate placements.
- DoD: detained students placed in same class for the new session.

**US-ADM-013 (REQ-ADM-013, P1)** — As the System, I want to expire stale offers and promote the next waitlisted candidate.
- Happy: Given an offer past its deadline, When the daily job runs, Then it is Expired and the next waitlisted is promoted and notified.
- Note: currently unmet (no job).

**US-ADM-021 (REQ-ADM-021, P1)** — As a Parent, I want to apply online and track my status.
- Happy: When I submit the public form with consent, Then an application is created and I get an application number.
- Boundary: Given more than the allowed submissions/hour from my IP, Then further submissions are throttled.
- Lookup: When I enter my application number, Then I see my current stage.
- Note: currently unmet (no public surface).

**US-ADM-014 (REQ-ADM-014, P1)** — As Finance, I want refunds computed by policy.
- Happy: Given a withdrawal 3 days after payment under a 7-day 100% tier, Then 100% is shown eligible.
- Boundary: Beyond the window → Not_Eligible.
- DoD: refund advances only Pending → Approved → Paid.

**US-ADM-017 (REQ-ADM-017, P1)** — As a Principal, I want to issue a TC only when fees are cleared.
- Happy: Given fees cleared, When I issue, Then a unique TC number and PDF (with QR) are produced.
- Exception: Given outstanding fees, Then issuance is blocked.
- DoD: re-issue references the original TC.

---

*End of ADM Complete Analysis Pack — 2026-06-29. 21 REQ / 22 BR (~36 conditions) / 8 RPT / 5 workflows / 5 FSM / 10 NFR / 6 RISK. IDs are frozen for downstream audit reuse.*
</content>
