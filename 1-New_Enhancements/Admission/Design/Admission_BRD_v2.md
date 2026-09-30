# Prime-AI Admission Management Module — Business Requirements Document (BRD)

**Document ID:** ADM-BRD-V2  
**Version:** 2.0  
**Status:** Approved-for-Design Baseline  
**Date:** 2026-09-23  
**Module:** Admission Management (`Modules\Admission`)  
**Prefix:** `adm_*` (20 Tables across 9 Architectural Layers)  
**Database Scope:** `tenant_db` (Database-per-tenant architecture; strict school data isolation, no `tenant_id` column)  
**Governed Schema:** `Admission_DDL_v2.sql`  
**Companion Documents:**  
- Solution Design: `Admission_Solution_Design_v2.md`  
- Data Dictionary: `Admission_Data_Dictionary_v2.md`  
- Process Flow & Screen Design: `Admission_Process_Flow_v2.md`  

---

## 0. Document Control

### 0.1 Position in the Document Set

| Layer | Document | Purpose & Primary Answers |
|---|---|---|
| **Business Requirements (This Document)** | **`Admission_BRD_v2.md`** | **What the school institution and stakeholders need, statutory rules, admissions policy, and acceptance criteria.** |
| Technical Architecture & Solution | `Admission_Solution_Design_v2.md` | How the system executes the rules, FSM lifecycles, cross-module transactional contracts, and algorithms. |
| Physical Data Dictionary | `Admission_Data_Dictionary_v2.md` | Exact column-level definitions, constraints, keys, nullability, and schema rules for all 20 `adm_*` tables. |
| UI/UX Process Flow & Screen Specs | `Admission_Process_Flow_v2.md` | Detailed end-to-end user workflows, wizard stages, operational journeys, and screen-by-screen UI controls. |
| Physical Schema DDL | `Admission_DDL_v2.sql` | Authoritative MySQL 8.0.16+ DDL script implementing all 20 tables, keys, and foreign constraints. |

---

### 0.2 Evolution: Why Version 2.0 Exists

Version 1.0 captured initial admission requirements but suffered from critical operational ambiguities, missing statutory mandates, and loose cross-module boundaries. Version 2.0 resolves every gap based on live school operational audits, NEP 2020 statutory mandates, and strict relational constraints.

| Change ID | Domain Area | Problem in Prior Specifications | Resolution in BRD v2.0 | Schema & Architectural Consequence |
|---|---|---|---|---|
| **C-01** | **Statutory Quotas & Fee Waivers** | Quotas (RTE, EWS, Management) had generic seat percentages without fee waiver tracking or statutory eligibility enforcement. | Mandated explicit quota configurations with configurable RTE fee waivers, seat budgets, and dedicated verification checks. | Added `adm_quota_config` and `adm_seat_capacity` with `application_fee_waiver` and `reserved_seats`. |
| **C-02** | **NEP 2020 Compliance on Testing** | Schools previously subjected nursery, LKG, UKG, and Grade 1 applicants to formal written entrance examinations, violating RTE Section 13 and NEP 2020. | Strictly prohibits entrance exams for foundational stage classes (Class Ordinal $\le 2$); only parent-child informal interactions permitted. | Validation rule `BR-ADM-011` added; warnings/blocks enforced in `adm_entrance_tests`. |
| **C-03** | **Sibling Detection & Bonus Scoring** | Sibling detection was manual and subjective, leading to missed fee discounts and disputed admissions. | Automated real-time sibling phone lookup against `std_guardians.mobile_no` with configurable merit score bonus (0–100). | `is_sibling_lead` and `sibling_student_id` in `adm_enquiries` and `adm_applications`; auto-population of parent IDs. |
| **C-04** | **Atomic Enrolment Transaction Boundary** | Moving an accepted applicant to student status was an inconsistent manual multi-screen entry across disconnected modules. | Single atomic database transaction converts `adm_allotments` into `std_students`, `std_student_profiles`, `std_student_academic_sessions`, and `std_siblings_jnt`. | Strict foreign key linkage `adm_allotments.enrolled_student_id` $\rightarrow$ `std_students.id`; guaranteed rollback on failure. |
| **C-05** | **Tiered Refund Governance** | Withdrawals were ad-hoc, causing parent grievances, delayed refunds, and untracked fee reconciliations. | Formal withdrawal lifecycle with automated tiered refund percentage calculation based on days elapsed since fee payment. | Added `adm_withdrawals` table with `refund_policy_json` evaluation and status FSM (`Pending` $\rightarrow$ `Approved` $\rightarrow$ `Paid`). |
| **C-06** | **Entrance Test Delivery Formats** | Entrance tests were assumed to be solely physical on-campus pen-and-paper exams. | Native support for both Offline (media question paper upload) and Online (portal link / CBT integration) examinations. | Added `test_type` ENUM (`Online`, `Offline`), `online_test_link`, and `offline_test_media_id` in `adm_entrance_tests`. |
| **C-07** | **Standardized Master References** | Religion, caste, nationality, and mother tongue were stored as arbitrary strings or unvalidated enums. | Fully standardized to central master dropdowns (`sys_dropdown_table`), aligning with platform profile schema. | Converted applicant demographics in `adm_applications` to foreign keys referencing `sys_dropdown_table`. |
| **C-08** | **Document Physical Custody Tracking** | Schools lacked a way to distinguish between digitally uploaded document scans and verified physical originals. | Track both digital verification and physical reception at the front desk with staff audit timestamps. | Added `is_physically_received`, `physically_received_at`, and `physically_received_by` in `adm_application_documents`. |
| **C-09** | **APAAR / ABC ID & Aadhaar Privacy** | Aadhaar was loosely handled, and Indian national student registry (APAAR ID) was completely absent. | Added `apaar_id` field; Aadhaar uniqueness restricted strictly to service-layer verification with cryptographic masking. | `apaar_id` column added to `adm_applications`; Aadhaar DB uniqueness constraint removed to prevent hard lockouts. |
| **C-10** | **Disciplinary & Conduct Transfer Integration** | Behavior incidents logged during admission trials were lost, and TC conduct certificates were arbitrary text. | Integrated behavioral tracking with negative score impacts and automatic conduct certificate generation on TC issuance. | `adm_behavior_incidents`, `adm_behavior_actions`, and `adm_transfer_certificates` with fee clearance validation. |

---

## 1. Executive Summary & Purpose

### 1.1 Executive Summary
The **Admission Management Module (ADM)** serves as the critical front door and pipeline engine for the school. It governs the student acquisition and enrolment journey from initial lead discovery to final classroom registration, while managing lifecycle transitions including annual grade promotion, transfer certification (TC), and conduct tracking.

The module bridges public engagement (prospective parents and students) with administrative rigor (admissions committee, counselors, academic coordinators, and finance officers). By establishing unambiguous mathematical ranking criteria, transparent seat quota allocations, automated statutory compliance (RTE 25% mandate, NEP 2020 testing restrictions), and an ironclad enrollment transaction boundary, the module guarantees operational integrity and eliminates data duplication across academic sessions.

### 1.2 Core Business Objectives
1. **Pipeline Velocity & Conversion:** Accelerate lead response times through automated lead assignment, structured follow-up scheduling, and omni-channel status communications.
2. **Merit & Quota Transparency:** Enforce objective composite scoring based on transparent academic, entrance test, interview weightages, and sibling bonuses across distinct reservation quotas (General, RTE, Management, EWS, Staff Ward, Sibling, NRI).
3. **Statutory & Legal Rigor:** Ensure 100% adherence to the Right to Education (RTE) Act, National Education Policy (NEP) 2020 age cut-offs, and Digital Personal Data Protection (DPDP) standards.
4. **Zero-Leakage Financial Integration:** Enforce mandatory application fee and admission seat-acceptance fee clearance via the StudentFee / Accounting module before issuing offer letters or executing enrollment.
5. **Idempotent Academic Enrolment:** Guarantee that an applicant is converted into an active student record in a single, atomic, failure-resilient transaction without manual re-keying of profiles, guardians, or documents.
6. **Continuous Student Lifecycle Governance:** Manage post-enrolment transitions seamlessly through cohort-based year-end promotion batches and tamper-proof Transfer Certificate (TC) issuance with QR-code verification.

---

## 2. Business Context & Operating Model

```
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                          PROSPECTIVE STUDENT FUNNEL                         │
   │                                                                             │
   │  [Lead / Walk-in / Web] ──► adm_enquiries ──► adm_follow_ups                │
   │                                   │                                         │
   │                                   ▼ (Converted)                             │
   │                           adm_applications                                  │
   │                                   │                                         │
   │                ┌──────────────────┴──────────────────┐                      │
   │                ▼                                     ▼                      │
   │      adm_application_documents             adm_entrance_tests               │
   │      (Verification & KYC)                  (Testing & Evaluation)           │
   │                │                                     │                      │
   │                └──────────────────┬──────────────────┘                      │
   │                                   ▼                                         │
   │                           adm_merit_lists                                   │
   │                                   │                                         │
   │                                   ▼                                         │
   │                            adm_allotments (Seat Offer & Fee Clearance)       │
   │                                   │                                         │
   └───────────────────────────────────┼─────────────────────────────────────────┘
                                       │
                        ATOMIC ENROLLMENT TRANSACTION
                                       │
                                       ▼
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                       CORE STUDENT & TENANT MASTER DB                       │
   │                                                                             │
   │   sys_users  ◄───►  std_students  ◄───►  std_student_profiles               │
   │                           │                                                 │
   │                           ├───► std_student_academic_sessions               │
   │                           └───► std_siblings_jnt                            │
   │                                                                             │
   │   Annual Promotion: adm_promotion_batches ──► adm_promotion_records         │
   │   Departure / TC:   adm_transfer_certificates (Fee Clearance Validated)     │
   │   Discipline:       adm_behavior_incidents ──► adm_behavior_actions         │
   └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Stakeholder Roles & Access Control Matrix

The module enforces strict role-based access control (RBAC) across tenant administrative boundaries. No cross-tenant data access is permitted.

| Functional Role | Permissions & Operational Scope | Key Responsibilities & Actions |
|---|---|---|
| **School Administrator** | **Full Administrative Access (CRUD on all `adm_*` entities)** | Creates admission cycles, configures seat quotas, defines document checklists, approves merit cut-offs, overrides system locks. |
| **Admission Counselor** | **Operational CRM & Application Processing** | Logs enquiries, conducts follow-up calls/meetings, reviews application submissions, schedules interviews, logs interview notes. |
| **Document Verification Officer** | **KYC & Document Verification** | Inspects uploaded digital documents, verifies physical originals at front desk, marks verification status (`Verified`/`Rejected`). |
| **Entrance Test Coordinator** | **Examination & Mark Entry** | Schedules entrance tests, assigns roll numbers, uploads test papers / sets test links, inputs candidate scores and subject breakdowns. |
| **Principal / Admissions Director** | **Approval, Merit Publication & TC Issuance** | Publishes merit lists, approves seat allotments, signs offer letters, authorizes fee refunds, issues Transfer Certificates. |
| **Finance Officer** | **Fee Verification & Refund Accounting** | Reconciles application and admission fee payments via `fee_transactions`, clears fee dues for TC leavers, executes approved refund disbursements. |
| **Class Teacher** | **Promotion Evaluation & Disciplinary Reporting** | Reviews class promotion batches, inputs student academic remarks, reports behavioral incidents, logs classroom corrective actions. |
| **Parent / Applicant (Public)** | **Self-Service Lead / Application Portal** | Submits enquiry, fills online admission wizard, uploads KYC documents, tracks application status, pays fees online, downloads offer letters. |

---

## 4. Canonical Vocabulary & Glossary

| Business Term | Authoritative Specification & Operational Definition |
|---|---|
| **Admission Cycle** | An administrative and temporal container (`adm_admission_cycles`) governing all admission activities for a targeted academic session (`sch_org_academic_sessions_jnt`). Exactly one cycle can be active (`status = 'Open'`, `active_flag = 1`) per academic year. |
| **Enquiry (Lead)** | The earliest recorded interest (`adm_enquiries`) by a prospective student or parent. Contains basic demographic and contact details prior to formal application submission. |
| **Follow-up** | A structured CRM touchpoint (`adm_follow_ups`) scheduled by an admission counselor (Call, Meeting, Email, SMS, Walk-in) with tracked outcomes. |
| **Application** | A formal, legally binding submission (`adm_applications`) containing student biographical, guardian, prior academic, and address data, tied to an admission cycle and class. |
| **Reservation Quota** | A mandated seat allocation category (`adm_quota_config`): `General`, `Government`, `Management`, `RTE`, `NRI`, `Staff_Ward`, `Sibling`, or `EWS`. |
| **Document Checklist** | Cycle- and class-specific document requirements (`adm_document_checklist`) dictating mandatory certificates (Birth Certificate, Aadhaar, Prior TC, Report Card). |
| **Merit List** | A mathematically calculated ranking (`adm_merit_lists`) of verified applicants for a class and quota based on academic, test, and interview weightages plus sibling bonus. |
| **Composite Score** | The final normalized score (0–100) generated for an applicant: $\text{Score} = (\text{Test} \times W_t) + (\text{Interview} \times W_i) + (\text{Academic} \times W_a) + \text{Sibling Bonus}$. |
| **Allotment (Offer)** | A provisional seat offer (`adm_allotments`) extended to a shortlisted applicant, carrying a formal admission number and an offer expiration deadline. |
| **Enrolment** | The irrevocable atomic transaction that converts an accepted, fee-paid allotment into an active student record in `std_students` and assigns an academic section. |
| **Promotion Batch** | An end-of-year batch operation (`adm_promotion_batches`) transitioning an entire cohort of students from a source session/class to a target session/class. |
| **Transfer Certificate (TC)** | An official statutory school-leaving credential (`adm_transfer_certificates`) certifying completion, conduct, and clearance of all financial liabilities. |
| **Behavior Incident** | A recorded disciplinary infraction (`adm_behavior_incidents`) carrying a negative score impact and linking to formal corrective actions (`adm_behavior_actions`). |

---

## 5. Functional Requirements Register

### 5.1 Sub-Module 1: Configuration & Setup (ADM-CFG)

#### REQ-ADM-001: Annual Admission Cycle Lifecycle Governance
- **Business Need:** The institution requires a strict container to manage annual admissions, control public application dates, specify application fees, and enforce age cut-offs.
- **Detailed Specification:**
  1. The system shall permit the School Administrator to create an admission cycle linked to a single academic session (`sch_org_academic_sessions_jnt`).
  2. The cycle code (`cycle_code`) must be unique across the tenant (e.g., `ADM-2026-27-M`).
  3. The system shall enforce date sanity: `end_date` must be strictly greater than `start_date`.
  4. The cycle shall support a 4-state lifecycle: `Draft` $\rightarrow$ `Open` $\rightarrow$ `Closed` $\rightarrow$ `Archived`.
  5. Only one cycle may have `status = 'Open'` and `active_flag = 1` for a given `academic_session_id`.
  6. The cycle defines global parameters: `application_fee`, `admission_no_format` (default `{YEAR}/{SEQ}`), `sibling_bonus_score` (default 5 points), `age_cut_off_date`, `age_rules_json`, and `refund_policy_json`.
- **Acceptance Criteria:**
  - `AC-ADM-001.1`: Attempting to set a cycle to `Open` when another cycle for the same academic session is already `Open` raises a validation error.
  - `AC-ADM-001.2`: Setting cycle status to `Closed` or `Archived` automatically updates `active_flag = 0`.
  - `AC-ADM-001.3`: The public URL slug `/apply/{application_form_url}` renders an active form only when the cycle is `Open` and current date is within `[start_date, end_date]`.

#### REQ-ADM-002: Class Quota Configuration & Seat Budgeting
- **Business Need:** Schools must budget seat capacities across diverse quotas (General, RTE, Management, etc.) and enforce reservation mandates (e.g., RTE 25%).
- **Detailed Specification:**
  1. For each class within an admission cycle, administrators must configure quota seat distributions via `adm_quota_config` and `adm_seat_capacity`.
  2. Supported quotas: `General`, `Government`, `Management`, `RTE`, `NRI`, `Staff_Ward`, `Sibling`, `EWS`.
  3. The system shall maintain real-time running counters: `total_seats`, `seats_allotted`, and `seats_enrolled`.
  4. For quotas flagged with `application_fee_waiver = 1` (e.g., RTE, EWS), the public application portal must bypass the payment gateway and mark fee as waived.
  5. The system shall disallow allotment beyond `total_seats` unless an explicit administrative over-allocation override is logged.
- **Acceptance Criteria:**
  - `AC-ADM-002.1`: Unique constraint `(admission_cycle_id, class_id, quota_type)` prevents duplicate seat budgets.
  - `AC-ADM-002.2`: `seats_allotted` increments upon offer letter issuance; `seats_enrolled` increments upon final enrolment.
  - `AC-ADM-002.3`: If an allotment expires or is declined, `seats_allotted` decrements by 1 automatically.

#### REQ-ADM-003: Dynamic Document Checklist Templates
- **Business Need:** Document compliance varies by grade level (e.g., prior TC is required for Class 5 but prohibited for Nursery).
- **Detailed Specification:**
  1. The system shall allow administrators to define document requirements globally (`admission_cycle_id IS NULL`, `is_system = 1`) or per cycle and class.
  2. Each checklist item defines: `document_name`, `document_code` (e.g., `BIRTH_CERT`, `PREV_TC`), `is_mandatory` (1/0), `accepted_formats` (e.g., `pdf,jpg,png`), and `max_size_kb` (default 5120 KB).
  3. Mandatory checklist documents must be uploaded and verified before an application can transition to `Verified`.
- **Acceptance Criteria:**
  - `AC-ADM-003.1`: File uploads exceeding `max_size_kb` or with unlisted MIME extensions are rejected at client and server.
  - `AC-ADM-003.2`: Applications missing any mandatory document cannot be marked `Verified`.

---

### 5.2 Sub-Module 2: Enquiry & CRM Pipeline (ADM-CRM)

#### REQ-ADM-004: Omni-Channel Lead Capture & Automatic Sibling Detection
- **Business Need:** Front office and marketing capture leads from walk-ins, website forms, and social media; duplicate leads must be flagged, and siblings must be recognized immediately.
- **Detailed Specification:**
  1. Leads captured via `adm_enquiries` receive an auto-generated unique identifier: `ENQ-YYYY-NNNNN`.
  2. Mandatory fields: `student_name`, `class_sought_id`, `contact_name`, `contact_mobile`, `lead_source`.
  3. **Automated Sibling Detection:** Upon mobile number entry, the system queries `std_guardians.mobile_no` in the tenant DB. If a match is found:
     - Set `is_sibling_lead = 1`.
     - Link `sibling_student_id = std_students.id`.
     - Flag visual indicator on the counselor dashboard.
  4. **Duplicate Lead Detection:** If `contact_mobile` matches an existing enquiry within the same `admission_cycle_id`, the new lead is flagged with `is_duplicate = 1` and links to the parent lead.
  5. Support lead assignment to an `Admission Counselor` (`sys_users.id`).
- **Acceptance Criteria:**
  - `AC-ADM-004.1`: Mobile number lookup executes via debounced AJAX within $\le 300\text{ ms}$.
  - `AC-ADM-004.2`: Duplicate enquiries do not skew funnel analytics metrics.

#### REQ-ADM-005: Multi-Touch Follow-up Scheduling & Outcome Logging
- **Business Need:** Counselors must maintain disciplined outreach to maximize inquiry-to-application conversion.
- **Detailed Specification:**
  1. Counselors log follow-up tasks (`adm_follow_ups`) against an enquiry: `Call`, `Meeting`, `Email`, `SMS`, `Walk-in`.
  2. Each record captures `scheduled_at`, `completed_at`, `done_by`, `outcome` (`Pending`, `Interested`, `Not_Interested`, `Callback`, `Converted`), and `notes`.
  3. Overdue follow-ups (`scheduled_at < NOW()` and `completed_at IS NULL`) highlight in red on counselor dashboards.
  4. When an outcome is marked `Converted`, the system prompts the counselor to generate a formal application, pre-populating all demographic data.
- **Acceptance Criteria:**
  - `AC-ADM-005.1`: When an enquiry converts, its status updates to `Converted` and `adm_applications.enquiry_id` is set.
  - `AC-ADM-005.2`: Follow-up history is immutable; notes cannot be overwritten once saved.

---

### 5.3 Sub-Module 3: Application Pipeline & Verification (ADM-APP)

#### REQ-ADM-006: Multi-Step Application Wizard & National ID Handling
- **Business Need:** Parents and staff require a structured, step-by-step wizard to collect extensive biographical, prior academic, and medical data.
- **Detailed Specification:**
  1. The application form (`adm_applications`) generates an auto-sequenced number: `APP-YYYY-NNNNN`.
  2. Multi-step sections:
     - **Step 1 — Basic Demographics:** Student name, DOB, gender, blood group, religion, caste category, mother tongue, nationality (FKs to `sys_dropdown_table`).
     - **Step 2 — Identifiers & Health:** Aadhaar number (optional, masked), APAAR ID / ABC ID, birth certificate number, known allergies.
     - **Step 3 — Previous Academic Record:** Previous school name, class passed, marks %, previous TC number.
     - **Step 4 — Guardian Information:** Father, Mother, and Local Guardian details (names, mobiles, emails, occupations, education). If sibling detected, pre-link `father_user_id` and `mother_user_id`.
     - **Step 5 — Residential Address:** Address lines, city, state (FKs to `glb_cities`, `glb_states`), PIN code.
     - **Step 6 — Document Upload:** Digital document attachments conforming to `adm_document_checklist`.
     - **Step 7 — Fee Payment & Declaration:** Application fee settlement and parent declaration.
  3. **Aadhaar Privacy Mandate:** Aadhaar uniqueness is validated at the service layer only; no database-level UNIQUE constraint exists to avoid hard collisions with masked or placeholder numbers. Aadhaar values must be masked in UI (`XXXXXXXX1234`).
- **Acceptance Criteria:**
  - `AC-ADM-006.1`: Progress auto-saves as `Draft` until final submission.
  - `AC-ADM-006.2`: Age validation (`BR-ADM-001`) verifies that student age on `age_cut_off_date` matches `age_rules_json` for `class_applied_id`.

#### REQ-ADM-007: Application Document Verification & Physical Custody
- **Business Need:** Admissions staff must verify digital document authenticity and track custody of physical original documents submitted at the school.
- **Detailed Specification:**
  1. Documents uploaded to `adm_application_documents` link to `sys_media.id`.
  2. Verification officers review documents and assign status: `Pending`, `Verified`, or `Rejected`.
  3. Marking a document `Rejected` strictly requires entering `verification_remarks`, which triggers an automated notification to the parent requesting re-upload.
  4. Front desk staff can record collection of physical originals: `is_physically_received = 1`, `physically_received_at = CURDATE()`, and `physically_received_by = sys_users.id`.
- **Acceptance Criteria:**
  - `AC-ADM-007.1`: Application cannot be moved to `Verified` status while any mandatory document has status `Pending` or `Rejected`.
  - `AC-ADM-007.2`: Unique constraint `(application_id, checklist_item_id)` prevents duplicate active uploads for the same requirement.

#### REQ-ADM-008: Immutable Application Stage Audit Log
- **Business Need:** Legal compliance and parent transparency require an unalterable history of every application status change.
- **Detailed Specification:**
  1. Any status change in `adm_applications` triggers an insert into `adm_application_stages_log`.
  2. Captured data: `application_id`, `from_status`, `to_status`, `remarks`, `changed_by`, `changed_at`.
  3. Transitions executed by automated scheduled tasks (e.g., offer expiration) record `changed_by = NULL`.
- **Acceptance Criteria:**
  - `AC-ADM-008.1`: `adm_application_stages_log` is insert-only; UPDATE and DELETE queries are blocked.
  - `AC-ADM-008.2`: Timeline component on application view renders complete audit trail in chronological order.

---

### 5.4 Sub-Module 4: Entrance Test & Evaluation (ADM-TST)

#### REQ-ADM-009: Entrance Test Scheduling & Candidate Management
- **Business Need:** For classes requiring entrance assessments, the school needs to schedule exam sessions, support both offline and online testing, and allocate candidates.
- **Detailed Specification:**
  1. Tests are configured via `adm_entrance_tests`: `test_name`, `test_date`, `start_time`, `end_time`, `venue`, `max_marks`, `passing_marks`, and `subjects_json`.
  2. Supported delivery modes (`test_type`):
     - **Offline:** Campus venue allocated, optional paper upload via `offline_test_media_id`.
     - **Online:** Virtual testing portal URL provided via `online_test_link`.
  3. Verified applicants are assigned to test sessions via `adm_entrance_test_candidates`, receiving an auto-generated examination `roll_no`.
  4. Candidate results: `marks_obtained`, `result` (`Pass`, `Fail`, `Absent`, `Pending`), and `subject_marks_json`.
- **Acceptance Criteria:**
  - `AC-ADM-009.1`: The system emits a blocking validation rule (`BR-ADM-011`) if an entrance test is created for Class Ordinal $\le 2$ (Nursery, LKG, UKG, Class 1), complying with NEP 2020.
  - `AC-ADM-009.2`: Candidate mark entry validates that `marks_obtained` $\le$ `max_marks`.

---

### 5.5 Sub-Module 5: Merit List & Seat Allotment (ADM-MRT)

#### REQ-ADM-010: Algorithmic Merit List Compilation & Sibling Bonus
- **Business Need:** The admissions board requires an automated, unbiased ranking algorithm that compiles composite scores according to weighted institutional criteria.
- **Detailed Specification:**
  1. Merit lists (`adm_merit_lists`) are generated per cycle, class, and quota.
  2. Scoring criteria configuration: `additional_criteria_json` defines percentage weightages for Entrance Test (`test_percentge`), Interview (`interview_percentge`), and Prior Academic Score (`academic_percentge`).
  3. The sum of configured weightage percentages must equal exactly 100%.
  4. **Sibling Bonus Rule:** Confirmed sibling applicants (`adm_applications.is_sibling = 1`) receive an additional score bonus (`sibling_bonus_score`, default 5 points), capped at maximum 100 points total.
  5. The system computes composite scores and populates `adm_merit_list_entries`:
     $$\text{Composite Score} = \min\left(100, \left(\frac{\text{Test Score}}{\text{Test Max}} \times W_t\right) + \left(\frac{\text{Int Score}}{\text{Int Max}} \times W_i\right) + (\text{Acad } \% \times W_a) + \text{Sibling Bonus}\right)$$
  6. Applicants are ranked in descending order of composite score. Tie-breaking rules:
     - 1st Tie-breaker: Higher Entrance Test Score.
     - 2nd Tie-breaker: Higher Prior Academic Percentage.
     - 3rd Tie-breaker: Older applicant by date of birth.
  7. Entries falling below `cutoff_score` are automatically marked `Rejected`. Entries within available quota capacity are marked `Shortlisted`; remainder are marked `Waitlisted`.
- **Acceptance Criteria:**
  - `AC-ADM-010.1`: Attempting to generate merit list with weights not summing to 100% throws an exception.
  - `AC-ADM-010.2`: Merit list status lifecycle obeys `Draft` $\rightarrow$ `Published` $\rightarrow$ `Finalized`.

#### REQ-ADM-011: Seat Allotment & Provisional Offer Letter Issuance
- **Business Need:** Shortlisted applicants must be issued formal, verifiable seat offers with defined expiration deadlines.
- **Detailed Specification:**
  1. Generating an allotment (`adm_allotments`) links to `adm_merit_list_entries` and reserves a seat in `adm_seat_capacity` (`seats_allotted` increments).
  2. The system assigns a provisional `admission_no` using the cycle pattern (e.g., `2026/0142`).
  3. System renders an official Offer Letter PDF stored in `sys_media` (`offer_letter_media_id`), featuring a verifiable QR code pointing to the verification portal.
  4. Offer carries an explicit deadline (`offer_expires_at`).
  5. Allotment lifecycle: `Offered` $\rightarrow$ `Accepted` $\rightarrow$ `Enrolled` (or `Declined`, `Expired`, `Withdrawn`).
- **Acceptance Criteria:**
  - `AC-ADM-011.1`: `admission_no` is unique across all non-null allotments.
  - `AC-ADM-011.2`: A scheduled console job (`adm:expire-offers`) evaluates expired offers daily, transitions status to `Expired`, decrements `seats_allotted`, and triggers waitlist promotion.

---

### 5.6 Sub-Module 6: Enrolment, Withdrawal & Refunds (ADM-ENR)

#### REQ-ADM-012: The Atomic Enrolment Transaction Boundary
- **Business Need:** Converting an admitted applicant to an enrolled student must be 100% failure-resilient, preventing orphaned user accounts or partial student records.
- **Detailed Specification:**
  1. Final enrolment is executed via `EnrollmentService::enrollStudent()` only when:
     - `adm_allotments.status = 'Accepted'`.
     - `adm_allotments.admission_fee_paid = 1` (verified via `fee_transactions`).
     - `allotted_section_id` is assigned.
  2. The transaction executes the following operations atomically in a single database transaction:
     - Create user account in `sys_users` (role: Student, credentials generated).
     - If parents do not exist, create parent accounts in `sys_users` (role: Parent).
     - Insert master student record into `std_students` with `admission_no` and `enrollment_date`.
     - Insert extended biographical and health data into `std_student_profiles`.
     - Insert academic session and section assignment into `std_student_academic_sessions`.
     - If sibling link exists, insert relationship row into `std_siblings_jnt`.
     - Update `adm_allotments`: set `status = 'Enrolled'`, set `enrolled_student_id = std_students.id`.
     - Update `adm_applications`: set `status = 'Enrolled'`.
     - Increment `adm_seat_capacity.seats_enrolled` by 1.
  3. If any step fails, the entire transaction rolls back completely, emitting an error alert.
- **Acceptance Criteria:**
  - `AC-ADM-012.1`: Database foreign key `fk_adm_allot_enrolled_student_id` is set upon completion.
  - `AC-ADM-012.2`: Any unhandled exception leaves zero orphaned rows in `sys_users` or `std_students`.

#### REQ-ADM-013: Post-Admission Withdrawal & Tiered Fee Refunds
- **Business Need:** When an admitted student withdraws, the school must record the reason and compute statutory fee refunds based on published policy.
- **Detailed Specification:**
  1. Withdrawals (`adm_withdrawals`) capture: `application_id`, `allotment_id`, `withdrawal_date`, `reason` (`Personal`, `Financial`, `Relocation`, `School_Change`, `Medical`, `Other`), and `remarks`.
  2. Total fees paid are captured from `fee_transactions_id` (`fee_paid_amount`).
  3. The system parses `adm_admission_cycles.refund_policy_json` (e.g., `{"7": 100, "15": 80, "30": 50, "999": 0}`) and determines eligible refund percentage based on days elapsed between `admission_fee_date` and `withdrawal_date`.
  4. Refund lifecycle: `Not_Eligible` / `Pending` $\rightarrow$ `Approved` $\rightarrow$ `Paid`.
  5. Approving a withdrawal frees the seat in `adm_seat_capacity` (`seats_allotted` or `seats_enrolled` decrements).
- **Acceptance Criteria:**
  - `AC-ADM-013.1`: Withdrawing after 10 days against a policy offering 80% within 15 days correctly calculates `refund_eligible_amount = fee_paid_amount * 0.80`.
  - `AC-ADM-013.2`: Approved refund triggers a payment disbursement voucher request in Accounting.

---

### 5.7 Sub-Module 7: Academic Transitions & Discipline (ADM-TRN)

#### REQ-ADM-014: Cohort-Based Year-End Promotion Engine
- **Business Need:** At the conclusion of an academic year, entire cohorts of students must be promoted, detained, or marked as graduated alumni.
- **Detailed Specification:**
  1. Promotion batches (`adm_promotion_batches`) define: `from_session_id`, `to_session_id`, `from_class_id`, `to_class_id`, and `criteria_json` (e.g., `{"min_pass_pct": 33}`).
  2. Student records are staged in `adm_promotion_records`: `student_id`, `from_class_section_id`, `to_class_section_id`, `new_roll_no`, `result` (`Promoted`, `Detained`, `Transferred`, `Alumni`, `Left`).
  3. Batch execution lifecycle: `Draft` $\rightarrow$ `Confirmed`.
  4. Upon confirmation by the Principal:
     - For `Promoted`: Creates new row in `std_student_academic_sessions` for target session/class/section.
     - For `Detained`: Creates row in `std_student_academic_sessions` retaining the current class.
     - For `Alumni` / `Left`: Updates `std_students.status = 'Alumni'` or `'Withdrawn'`.
  5. Re-running promotion is strictly idempotent: existing session enrollment rows are detected and updated rather than duplicated.
- **Acceptance Criteria:**
  - `AC-ADM-014.1`: Confirmation updates `promoted_count` and `detained_count` on batch header.
  - `AC-ADM-014.2`: Batch processing is asynchronous for classes with $>100$ students.

#### REQ-ADM-015: Transfer Certificate (TC) Issuance & Financial Clearance
- **Business Need:** Issuing a statutory Transfer Certificate requires strict clearance of school dues, conduct verification, and counterfeit prevention.
- **Detailed Specification:**
  1. TC issuance (`adm_transfer_certificates`) requires: `student_id`, `issue_date`, `leaving_date`, `class_at_leaving`, `reason_for_leaving`, `conduct` (`Excellent`, `Good`, `Satisfactory`, `Poor`), and `destination_school`.
  2. **Mandatory Dues Clearance (`BR-ADM-004`):** The system queries the StudentFee / Accounting module. If any outstanding balance exists:
     - Block TC generation.
     - Require Finance Officer override or receipt creation.
     - Set `fees_cleared = 1` only when ledger balance is zero.
  3. The system generates a tamper-evident TC PDF with a cryptographically signed QR code stored in `sys_media` (`media_id`).
  4. Duplicate TCs can be re-issued (`is_duplicate = 1`), referencing `original_tc_id`.
  5. Upon TC issuance, the student's status in `std_students` transitions to `Transferred`.
- **Acceptance Criteria:**
  - `AC-ADM-015.1`: System blocks TC generation if `fees_cleared = 0`.
  - `AC-ADM-015.2`: Scanning the QR code on the physical TC navigates to public verification URL showing student leaving metadata.

#### REQ-ADM-016: Student Disciplinary Incidents & Corrective Actions
- **Business Need:** Schools need a structured, confidential mechanism to log student behavioral infractions, evaluate conduct impacts, and record corrective measures.
- **Detailed Specification:**
  1. Incidents are logged via `adm_behavior_incidents`: `student_id`, `incident_date`, `incident_type` (`Bullying`, `Cheating`, `Disruption`, `Absenteeism`, `Vandalism`, `Violence`, `Misconduct`, `Other`), `severity` (`Low`, `Medium`, `High`, `Critical`), `description`, `location`, `witnesses_json`.
  2. **Behavior Score Impact:** Each incident records a signed integer deduction (`behavior_score_impact`, e.g., -5, -15).
  3. **Critical Severity Protocol:** Incidents marked `Critical` automatically dispatch urgent notification alerts to the Principal and Parents (`parent_notified = 1`).
  4. Corrective actions are tracked in `adm_behavior_actions`: `action_type` (`Warning`, `Detention`, `Suspension`, `Expulsion`, `Parent_Meeting`, `Counseling`, `Community_Service`), date ranges, and parent meeting outcomes.
- **Acceptance Criteria:**
  - `AC-ADM-016.1`: `behavior_score_impact` is stored as a signed `TINYINT` (allowing negative values).
  - `AC-ADM-016.2`: Active suspensions flag a warning indicator on class attendance registers.

---

## 6. Business Rules Register

| Rule ID | Domain Area | Authoritative Rule Specification | Enforcement Mechanism |
|---|---|---|---|
| **BR-ADM-001** | Eligibility | **Age Cut-off Rule:** Student age on `age_cut_off_date` must strictly fall within `[min_age, max_age]` defined in `adm_admission_cycles.age_rules_json` for the requested class. | Application Form Validator & API Request Guard. |
| **BR-ADM-002** | Enrolment | **Admission Fee Prerequisite:** No applicant may be enrolled (`status = 'Enrolled'`) unless `adm_allotments.admission_fee_paid = 1` is confirmed by payment gateway or finance receipt. | `EnrollmentService::enrollStudent()` DB Transaction Guard. |
| **BR-ADM-003** | Cycle | **Single Active Cycle Constraint:** Only one admission cycle may have `status = 'Open'` and `active_flag = 1` per academic session. | Database Unique Index `uq_adm_cyc_active`. |
| **BR-ADM-004** | Clearance | **TC Fee Clearance Prerequisite:** Transfer Certificate cannot be generated or printed if the student has pending fee dues in the StudentFee ledger (`fees_cleared` must equal 1). | `TransferCertificateService::issueTC()` Validation Guard. |
| **BR-ADM-005** | RTE Quota | **RTE Seat Reservation Mandate:** For entry-level classes, minimum 25% of total capacity must be allocated to `RTE` quota with `application_fee_waiver = 1`. | Quota Configuration Validator & Advisory Warning. |
| **BR-ADM-006** | CRM | **Unique Enquiry Sequencing:** Enquiry numbers must follow tenant-wide sequential pattern `ENQ-YYYY-NNNNN`. | Database Unique Key `uq_adm_enq_no` & Key Generator. |
| **BR-ADM-007** | Verification | **Mandatory Document Requirement:** An application cannot transition to `Verified` status while any mandatory checklist item remains un-uploaded or in `Rejected` status. | `AdmissionPipelineService::verifyApplication()` Guard. |
| **BR-ADM-008** | Scoring | **Merit Weightage Parity:** The sum of `test_percentge`, `interview_percentge`, and `academic_percentge` in `adm_merit_lists` must equal exactly 100.00%. | Model Pre-Save Hook & Form Request Validation. |
| **BR-ADM-009** | Identity | **Aadhaar Privacy & Masking:** Aadhaar number is never validated with DB-level UNIQUE constraint; duplicates emit administrative review warnings, and UI displays masked digits only. | Service Layer KYC Rule & Blade Sanitization. |
| **BR-ADM-010** | Lead Matching | **Sibling Auto-Detection:** Entering a guardian mobile number matching `std_guardians.mobile_no` automatically flags the record as a sibling lead and captures the existing student ID. | Real-Time Ajax CRM Lookup & Sibling Service. |
| **BR-ADM-011** | Testing | **NEP 2020 Early Childhood Testing Ban:** Entrance tests are strictly prohibited for foundational classes (Class Ordinal $\le 2$). The system rejects creation of test schedules for these classes. | `adm_entrance_tests` Save Guard (`test_date` reject). |
| **BR-ADM-012** | Promotion | **Idempotent Promotion Execution:** Executing a promotion batch multiple times must not generate duplicate academic session records for the same student. | `PromotionService::confirmBatch()` using `updateOrCreate()`. |
| **BR-ADM-013** | Capacity | **Seat Capacity Budget Invariance:** Total allotted seats (`seats_allotted`) cannot exceed `total_seats` in `adm_seat_capacity` without explicit super-admin override. | `MeritListService::allotSeat()` DB Lock Guard. |
| **BR-ADM-014** | Expiration | **Offer Letter Expiry & Auto-Release:** Unaccepted seat offers past `offer_expires_at` automatically expire, decrementing `seats_allotted` and promoting the next waitlisted applicant. | Daily Scheduled Console Command `adm:expire-offers`. |
| **BR-ADM-015** | Merit Bonus | **Sibling Merit Bonus Eligibility:** Sibling bonus score points may only be applied to composite score calculation if `is_sibling = 1` has been formally verified by admissions staff. | `MeritListService::calculateScores()` Rule. |
| **BR-ADM-016** | FSM | **Application Status Immutability:** An application marked `Enrolled` or `Withdrawn` cannot transition back to `Draft` or `Submitted`. | `ApplicationStateMachine` Enforcement Guard. |
| **BR-ADM-017** | Document | **Unique Upload Per Checklist Item:** An application can have only one active uploaded media document per checklist requirement. | Database Unique Key `uq_adm_doc_app_checklist`. |
| **BR-ADM-018** | Refund | **Tiered Refund Policy Evaluation:** Refund amounts on withdrawal must be computed strictly via the cycle's JSON policy based on calendar days elapsed since fee payment. | `WithdrawalService::calculateRefund()`. |
| **BR-ADM-019** | Audit | **Stage Transition Logging:** Every status change of an application must produce an immutable audit row in `adm_application_stages_log`. | Database Trigger / Eloquent Saved Model Observer. |
| **BR-ADM-020** | Duplicate TC | **Duplicate TC Linkage:** Any re-issued Transfer Certificate must be explicitly flagged with `is_duplicate = 1` and link to `original_tc_id`. | TC Issuance Controller Validation. |
| **BR-ADM-021** | Discipline | **Critical Incident Parent Alert:** Disciplinary incidents with `severity = 'Critical'` must trigger immediate outbox notifications to parents and principal. | `BehaviorIncidentService` Post-Save Event. |
| **BR-ADM-022** | Roll Number | **Promotion Roll Number Assignment:** Promoted students assigned to a section must have sequential roll numbers sorted alphabetically by student last name. | `PromotionService::assignRollNumbers()`. |
| **BR-ADM-023** | Public URL | **Application Form Slug Uniqueness:** Each admission cycle public form URL slug must be globally unique across tenant cycles. | Form Request Unique Validation on `cycle_code`. |
| **BR-ADM-024** | Physical KYC | **Physical Document Custody Audit:** Physical document collection must record receiving staff ID and timestamp; originals cannot be marked returned while active. | Front Office KYC Form Request. |
| **BR-ADM-025** | Tie-Breaker | **Deterministic Merit Tie-Breaking:** Ties in merit ranking must resolve strictly in order: 1) Test Score, 2) Prior Academics, 3) Date of Birth (Older applicant wins). | `MeritListService` SQL Order-By Clause. |

---

## 7. Reports & Analytics Register

| Report ID | Report Title | Target Audience | Primary Metrics & Analytical Value |
|---|---|---|---|
| **RPT-ADM-001** | **Admission Funnel Conversion** | Leadership, Principal | Conversion counts and drop-off % across funnel stages: Enquiry $\rightarrow$ Application $\rightarrow$ Verified $\rightarrow$ Shortlisted $\rightarrow$ Allotted $\rightarrow$ Enrolled. |
| **RPT-ADM-002** | **Lead Source Performance** | Marketing, Admin | Total leads, qualified leads, and conversion rates segmented by channel (Website, Walk-in, Social Media, Campaigns, Referrals). |
| **RPT-ADM-003** | **Class & Quota Seat Occupancy** | Admissions Director | Real-time seat budget utilization: Total Seats, Reserved Seats, Allotted Seats, Enrolled Seats, and Vacancy % across all quotas. |
| **RPT-ADM-004** | **Entrance Exam & Merit Register** | Academic Board | Complete distribution of entrance scores, cut-off thresholds, subject averages, and final composite rankings. |
| **RPT-ADM-005** | **Application Fee Reconciliation** | Finance Manager | Reconciled audit of application fees collected vs waived (RTE/EWS) vs pending across payment gateways and cash counters. |
| **RPT-ADM-006** | **Withdrawal & Refund Audit** | Finance Manager | Detailed log of post-admission cancellations, stated reasons, refund eligibility %, total refunded amounts, and processing turnaround days. |
| **RPT-ADM-007** | **Sibling Admissions Summary** | Admissions Director | Breakdown of sibling leads identified, verified sibling bonus points awarded, and total sibling admissions completed. |
| **RPT-ADM-008** | **Statutory RTE Compliance** | Management, Auditor | State audit report proving adherence to 25% RTE seat reservation, fee waivers granted, and verification documents archived. |

---

## 8. Non-Functional Requirements (NFR)

| NFR ID | Attribute | Non-Functional Specification & Performance Standard |
|---|---|---|
| **NFR-ADM-001** | **Tenant Data Isolation** | All admission data resides strictly within the individual school's `tenant_db`. No cross-tenant database querying or leaking is architecturally possible. |
| **NFR-ADM-002** | **High Concurrency Scalability** | Public enquiry and application forms must sustain $\ge 500$ concurrent user submissions during peak admission opening days without response degradation. |
| **NFR-ADM-003** | **Enrolment Transaction Atomicity** | Enrolment conversion must execute within an all-or-nothing database transaction boundary ($\le 1.5\text{ seconds}$ execution time). |
| **NFR-ADM-004** | **PII & Data Privacy Compliance** | Adheres to the Digital Personal Data Protection (DPDP) Act. Aadhaar numbers must be encrypted at rest (AES-256) and masked in UI. |
| **NFR-ADM-005** | **Document Storage Security** | All uploaded KYC certificates and PDF offer letters store in secure object storage with expiring signed URLs; direct public URL traversal is blocked. |
| **NFR-ADM-006** | **Search & Lookup Latency** | Enquiry search by mobile number, applicant lookup by name, and dashboard KPI queries must respond in $\le 200\text{ ms}$. |
| **NFR-ADM-007** | **Audit Trail Immutability** | Stage transition logs (`adm_application_stages_log`) and fee reconciliation logs must be permanently append-only with strict database-level write locks. |
| **NFR-ADM-008** | **Mobile Responsiveness** | The public parent admission portal and counselor mobile CRM views must be 100% responsive across mobile, tablet, and desktop breakpoints. |
| **NFR-ADM-009** | **Asynchronous Export Performance** | Large reports ($>5,000$ rows) and batch TC generation must run via queued background jobs with download notifications. |
| **NFR-ADM-010** | **Disaster Recovery RPO/RTO** | Database transactions guarantee a Recovery Point Objective (RPO) of zero data loss for confirmed fee payments and an RTO of $<15\text{ minutes}$. |

---

## 9. Product Decisions Register

| Decision ID | Technical / Business Dilemma | Decided Alternative & Rationale | Impact on Architecture & Schema |
|---|---|---|---|
| **DEC-ADM-001** | Should Aadhaar number have a database UNIQUE constraint? | **No DB Unique Constraint; Service-Layer Validation Only.** Parents often enter dummy values (`000000000000`) or share numbers among minor twins during initial enquiry. Hard DB unique constraints cause catastrophic submission errors. | Removed `uq_adm_app_aadhar` from DB schema; added service validation rule `BR-ADM-009`. |
| **DEC-ADM-002** | How should admission numbers be generated? | **Configurable Format String per Cycle.** Different schools use distinct numbering schemes (e.g., `DPS/2026/0142`, `26-0045`). | Stored `admission_no_format` in `adm_admission_cycles` (default `{YEAR}/{SEQ}`). |
| **DEC-ADM-003** | Can an entrance test be scheduled for Kindergarten or Grade 1? | **Strictly Prohibited per NEP 2020 & RTE Section 13.** Standardized tests traumatize young children and violate statutory screening bans. | System enforces `BR-ADM-011`, raising blocking exceptions for Class Ordinal $\le 2$. |
| **DEC-ADM-004** | Should Quota Config and Seat Capacity remain separate or merge? | **Retained as Distinct Tables with Layer 2 Separation.** `adm_quota_config` defines policy rules (fee waiver, reservation rules); `adm_seat_capacity` acts as the operational counter cache. | Preserved both tables in DDL v2.0 with clean FK relationships. |
| **DEC-ADM-005** | How should multi-channel test links and question papers be handled? | **Hybrid Enum & Media Link.** Tests can be Online or Offline. | Added `test_type` ENUM (`Online`, `Offline`), `online_test_link`, and `offline_test_media_id` in `adm_entrance_tests`. |
| **DEC-ADM-006** | Should student demographics use enums or master dropdown IDs? | **Master Dropdown IDs (`sys_dropdown_table`).** School boards mandate state-specific caste categories, minority religions, and linguistic classifications that cannot be hardcoded into MySQL ENUMs. | Converted religion, caste, nationality, and mother tongue in `adm_applications` to FKs referencing `sys_dropdown_table`. |
| **DEC-ADM-007** | What occurs when a seat offer deadline passes without payment? | **Automated Expiration & Waitlist Reallocation.** Holding seats indefinitely stalls the admission pipeline and hurts school revenue. | Created `adm:expire-offers` console scheduler to expire allotments and auto-advance waitlisted candidates. |
| **DEC-ADM-008** | Where does the boundary lie between Admission and StudentProfile? | **Irrevocable Handoff at Enrolment Event.** Once `adm_allotments` transitions to `Enrolled`, core data is pushed into `std_students` and all future student updates occur in StudentProfile module. | Clear separation enforced: Admission owns the pre-enrolment pipeline; StudentProfile owns the enrolled student. |
