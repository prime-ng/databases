# Prime-AI Admission Management Module — Process Flow & Screen Design

**Document ID:** ADM-PFD-V2  
**Version:** 2.0  
**Status:** Approved-for-Design Baseline  
**Date:** 2026-09-23  
**Module:** Admission Management (`Modules\Admission`)  
**Prefix:** `adm_*` (20 Tables)  
**Governed by:** `Admission_BRD_v2.md` (v2.0) & `Admission_Solution_Design_v2.md` (v2.0)  
**Realised by:** `Admission_DDL_v2.sql` (v2.0) & `Admission_Data_Dictionary_v2.md` (v2.0)  

---

## 0. Document Control & Overview

This document specifies the complete operational workflows, user journeys, and screen designs for the Prime-AI Admission Management Module. It bridges business requirements (`Admission_BRD_v2.md`), technical architecture (`Admission_Solution_Design_v2.md`), and the physical database (`Admission_DDL_v2.sql`).

Every screen specification details:
1. **Screen Identifier & Title**
2. **Purpose & Functional Objective**
3. **UI Layout, Components & Action Controls**
4. **Database Tables Covered (Primary & Secondary Mappings)**
5. **Business Rules, Constraints & Validation Logic**

---

## PART I — End-to-End Operational Process Flows

### 1. Lead Capture & Counselor Follow-up CRM Flow

```
  [Parent Enquiry] (Web / Walk-in / Campaign / Social)
         │
         ▼
  [SCR-04: Quick Lead Entry Modal]
         │
         ├───► Auto-Query: Match contact_mobile vs std_guardians.mobile_no
         │        ├── Match Found: is_sibling_lead = 1, sibling_student_id linked
         │        └── No Match: is_sibling_lead = 0
         │
         ├───► Check Duplicate: Mobile exists in current cycle?
         │        ├── Yes: Flag is_duplicate = 1, link parent lead
         │        └── No: is_duplicate = 0
         │
         ▼
  [SCR-05: Lead CRM Pipeline Grid] ──► Status: 'Assigned' to Counselor
         │
         ▼
  [SCR-06: Follow-up Drawer / Activity Modal]
         │
         ├── Scheduled: NTF reminder set (adm_follow_ups.reminder_sent = 0)
         │
         ├── Outcome Logged: 'Interested' / 'Callback' / 'Not_Interested'
         │
         └── Outcome: 'Converted' ──► Auto-Trigger: [SCR-07: Application Form Wizard]
```

---

### 2. Multi-Step Application & Verification Flow

```
  [Parent Portal / Counselor Desk]
         │
         ▼
  [SCR-07: Application Form Wizard]
         │
         ├── Step 1: Basic Demographics (Name, DOB, Gender, Religion, Caste, Mother Tongue)
         ├── Step 2: Identifiers & Health (Aadhaar [Masked], APAAR ID, Allergies)
         ├── Step 3: Prior Academic Record (School Name, Class Passed, Marks %)
         ├── Step 4: Guardian Details (Father, Mother, Local Guardian; auto-link if sibling)
         ├── Step 5: Residential Address (Address lines, City, State, PIN)
         ├── Step 6: Document Upload (Checklist validation: formats, max size)
         └── Step 7: Fee Payment & Declaration (Gateway integration / RTE Fee Waiver)
         │
         ▼ Status: 'Submitted'
  [SCR-08: Application Verification Workbench]
         │
         ├── Document Audit: Inspector marks each doc 'Verified' or 'Rejected' (Remarks required)
         ├── Physical Custody: Collect original physical documents at desk
         │
         ├── Fail Eligibility (Age / Fraud): Transition to 'Rejected' (rejection_reason saved)
         │
         └── All Mandatory Docs 'Verified': Transition to 'Verified'
```

---

### 3. Examination, Evaluation & Merit Allotment Flow

```
  [SCR-09: Verified Applicants Pool]
         │
         ├── Class Ordinal <= 2? ──► [NEP 2020 Check: No entrance exam; skip to Interview / Direct Merit]
         │
         └── Class Ordinal > 2: ──► [SCR-10: Entrance Test Scheduler]
                                          │
                                          ▼ Assign Roll Numbers
                                   [SCR-11: Candidate Mark Entry]
                                          │
                                          ▼ Record Marks & Result (Pass/Fail/Absent)
  [SCR-12: Merit List Compilation Engine]
         │
         ├── Input Weightages: Entrance % + Interview % + Academic % = 100%
         ├── Add Sibling Bonus: +5 points if is_sibling == 1
         ├── Compute Composite Score: min(100, Weighted Sum + Bonus)
         ├── Sort Deterministically: Score DESC, Test DESC, Acad DESC, DOB ASC (Older wins)
         │
         ├── Below Cut-Off: Status = 'Rejected'
         ├── Within Quota Capacity: Status = 'Shortlisted'
         └── Beyond Quota Capacity: Status = 'Waitlisted'
         │
         ▼ Publish Merit List
  [SCR-13: Seat Allotment & Offer Issuance]
         │
         ├── Reserve Seat in adm_seat_capacity (increment seats_allotted)
         ├── Assign Provisional admission_no (Format: DPS/{YEAR}/{SEQ})
         ├── Generate Offer Letter PDF with Verifiable QR Code (sys_media)
         └── Set offer_expires_at deadline
```

---

### 4. Enrolment, Withdrawal & Promotion Flow

```
  [SCR-14: Seat Acceptance & Fee Settlement]
         │
         ├── Offer Expired / Declined: Decrement seats_allotted, promote next waitlisted candidate
         │
         └── Parent Accepts & Pays Admission Fee:
                  │
                  ▼ admission_fee_paid = 1 confirmed
  [SCR-15: Final Enrolment Desk] ──► Select Section (sch_sections)
         │
         ▼ TRIGGER ATOMIC ENROLMENT TRANSACTION (EnrollmentService)
         │
         ├── 1. Create sys_users accounts (Student & Parents)
         ├── 2. Create std_students master record
         ├── 3. Create std_student_profiles extended record
         ├── 4. Create std_student_academic_sessions (Section assigned)
         ├── 5. Create std_siblings_jnt (if sibling confirmed)
         ├── 6. Update adm_allotments (status = 'Enrolled', enrolled_student_id set)
         ├── 7. Update adm_applications (status = 'Enrolled')
         ├── 8. Increment adm_seat_capacity.seats_enrolled
         └── 9. Dispatch Welcome Pack & Notification
         │
  [Post-Enrolment Transitions]
         │
         ├── Post-Admission Withdrawal: [SCR-16: Withdrawal Desk]
         │        └── Evaluate adm_admission_cycles.refund_policy_json ──► Finance Refund
         │
         ├── Year-End Cohort Transition: [SCR-17: Promotion Batch Desk]
         │        └── Staged records ──► Idempotent commit to target academic session
         │
         └── Student Departure: [SCR-18: Transfer Certificate Desk]
                  └── Audit StudentFee Dues ──► If cleared, issue QR-coded statutory TC
```

---

## PART II — Screen Specifications (SCR-01 to SCR-25)

### Module 1: Configuration & Setup Screens

#### SCR-01: Admission Cycle Setup & Master Management
- **Purpose & Objective:** Configure annual admission cycles, public form slugs, date boundaries, application fees, age rules, and refund policies.
- **UI Layout & Components:**
  - **Header Bar:** "Academic Year" selector, "Create Admission Cycle" action button.
  - **Data Grid:** Cycle Code, Cycle Name, Academic Session, Open Date, Close Date, Application Fee, Status Badge (`Draft`, `Open`, `Closed`, `Archived`), Active Toggle.
  - **Slide-Over Modal:** Multi-tab setup form:
    - *General Tab:* Session FK, Name, Cycle Code, Start/End Dates, Application Fee, Admission Number Format (`DPS/{YEAR}/{SEQ}`).
    - *Age Eligibility Tab:* Statutory Cut-off Date, Table of classes with Min/Max allowed ages (auto-populates `age_rules_json`).
    - *Refund Policy Tab:* Tiered refund grid: Days elapsed threshold vs Refund % (auto-populates `refund_policy_json`).
    - *Portal Config Tab:* Public URL slug preview (`/apply/admission-2026-27`), active toggle.
- **Database Tables Covered:**
  - `adm_admission_cycles` (Primary)
  - `sch_org_academic_sessions_jnt` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-003`: Only one cycle may have `status = 'Open'` and `active_flag = 1` per academic session (`uq_adm_cyc_active`).
  - `end_date` must be strictly $> \text{start\_date}$.
  - Setting status to `Closed` or `Archived` automatically updates `active_flag = 0`.

---

#### SCR-02: Document Checklist Configuration
- **Purpose & Objective:** Manage mandatory and optional KYC document requirements per cycle and grade level.
- **UI Layout & Components:**
  - **Filters:** Admission Cycle selector, Class selector.
  - **Checklist Table:** Document Name, Code (`BIRTH_CERT`, `PREV_TC`), Mandatory Flag, Accepted Formats (`pdf,jpg,png`), Max File Size (KB), Sort Order, Active Status.
  - **Action Controls:** "Add Requirement", "Import System Defaults", "Reorder".
  - **Modal Form:** Document Name, Code, Class Applicability (`All Classes` or specific Class), Mandatory checkbox, file types, max size.
- **Database Tables Covered:**
  - `adm_document_checklist` (Primary)
  - `adm_admission_cycles` (Secondary)
  - `sch_classes` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-007`: Mandatory checklist documents block application verification until uploaded and approved.
  - System default rows (`is_system = 1`) cannot have their programmatic `document_code` modified.

---

#### SCR-03: Class Quota & Seat Budgeting Matrix
- **Purpose & Objective:** Configure seat allocations across reservation quotas and view real-time occupancy.
- **UI Layout & Components:**
  - **Header Bar:** Cycle selector, Class filter, "Export Seat Matrix".
  - **Interactive Matrix Grid:**
    - Rows: Classes (Nursery through Class 12).
    - Columns: Total Seats, General, RTE (25%), Management, EWS, Staff Ward, Sibling, NRI.
    - Cell Controls: Click-to-edit seat numbers, waiver flags, and reservation minimums.
  - **Live Summary Widget:** Total School Capacity, Total Allotted, Total Enrolled, Available Vacancy %.
- **Database Tables Covered:**
  - `adm_quota_config` (Primary)
  - `adm_seat_capacity` (Primary)
  - `adm_admission_cycles` (Secondary)
  - `sch_classes` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-005`: Entry-level classes must reserve $\ge 25\%$ seats for `RTE` quota with `application_fee_waiver = 1`.
  - Unique composite constraint `(admission_cycle_id, class_id, quota_type)` prevents duplicate seat budgets.

---

### Module 2: Lead CRM & Outreach Screens

#### SCR-04: Quick Enquiry Entry (Front Desk & Webhook Modal)
- **Purpose & Objective:** Rapidly capture walk-in or telephone leads with instant real-time sibling phone lookup.
- **UI Layout & Components:**
  - **Form Fields:** Student Name, Date of Birth, Gender, Class Sought, Contact Name, Contact Mobile Number, Contact Email, Lead Source (`Walk-in`, `Phone`, `Website`, `Social_Media`), Counselor Assignment.
  - **Real-Time Sibling Banner:** Dynamically renders when mobile number matches `std_guardians.mobile_no`, displaying existing sibling name, current class, and admission number.
  - **Duplicate Alert:** Warning card if mobile already exists in current cycle.
- **Database Tables Covered:**
  - `adm_enquiries` (Primary)
  - `std_guardians` (Secondary - Lookup)
  - `std_students` (Secondary - Lookup)
- **Business Rules & Validation Logic:**
  - `BR-ADM-006`: Auto-generates unique sequence `ENQ-YYYY-NNNNN`.
  - `BR-ADM-010`: Real-time sibling lookup sets `is_sibling_lead = 1` and links `sibling_student_id`.

---

#### SCR-05: Lead CRM Pipeline Grid
- **Purpose & Objective:** Comprehensive CRM dashboard for admission counselors to filter, assign, and track leads.
- **UI Layout & Components:**
  - **KPI Cards:** Total Leads, Today's Follow-ups, Overdue Follow-ups, Conversion Rate %.
  - **Kanban / Table Toggle View:**
    - Columns: `New`, `Assigned`, `Contacted`, `Interested`, `Callback`, `Converted`, `Not_Interested`.
    - Lead Card: Lead Number, Student Name, Class, Sibling Badge, Lead Source, Assigned Counselor Avatar, Next Follow-up Date.
  - **Bulk Action Bar:** "Reassign Counselor", "Send Bulk SMS", "Export Leads".
- **Database Tables Covered:**
  - `adm_enquiries` (Primary)
  - `adm_follow_ups` (Secondary)
  - `sys_users` (Secondary)
- **Business Rules & Validation Logic:**
  - Counselors can view assigned leads; administrators view all leads across tenant.

---

#### SCR-06: Follow-up Scheduling & Activity Drawer
- **Purpose & Objective:** Schedule and document parent communications, phone calls, campus visits, and counseling outcomes.
- **UI Layout & Components:**
  - **Slide-Over Drawer:** Triggered by selecting an enquiry row.
  - **Top Panel:** Lead summary, contact details, quick-call / quick-WhatsApp buttons.
  - **Schedule New Activity Form:** Follow-up Type (`Call`, `Meeting`, `Email`, `SMS`, `Walk-in`), Scheduled Date/Time, Reminder Checkbox.
  - **Log Activity Outcome Form:** Outcome (`Pending`, `Interested`, `Not_Interested`, `Callback`, `Converted`), Staff Notes.
  - **Timeline:** Chronological activity feed showing all historical touchpoints with staff avatars.
- **Database Tables Covered:**
  - `adm_follow_ups` (Primary)
  - `adm_enquiries` (Secondary)
- **Business Rules & Validation Logic:**
  - `outcome = 'Converted'` prompts instant application creation and marks enquiry converted.
  - Historical notes are append-only; editing past entries is disallowed.

---

### Module 3: Application Form & KYC Verification Screens

#### SCR-07: Multi-Step Application Form Wizard
- **Purpose & Objective:** Complete admission application wizard used by parents (public portal) and counselors (desk entry).
- **UI Layout & Components:**
  - **Horizontal Step Tracker:** 1) Student Info $\rightarrow$ 2) Health & KYC $\rightarrow$ 3) Prior Academics $\rightarrow$ 4) Guardians $\rightarrow$ 5) Address $\rightarrow$ 6) Documents $\rightarrow$ 7) Payment.
  - **Step Panels:**
    - *Step 1:* Student Name, DOB, Gender, Religion, Caste, Nationality, Mother Tongue.
    - *Step 2:* Masked Aadhaar, APAAR ID, Birth Cert No, Blood Group, Allergies.
    - *Step 3:* Prior School, Class Passed, Marks %, Prior TC No.
    - *Step 4:* Father, Mother, Guardian inputs (names, mobiles, emails, occupations). Auto-filled if sibling confirmed.
    - *Step 5:* Address Line 1/2, City, State, PIN.
    - *Step 6:* File dropzones for each checklist requirement with format/size validation.
    - *Step 7:* Fee breakdown, Online Payment Gateway button / RTE Waiver Notice.
  - **Action Footer:** "Save Draft", "Previous Step", "Next Step", "Final Submit".
- **Database Tables Covered:**
  - `adm_applications` (Primary)
  - `adm_application_documents` (Secondary)
  - `adm_document_checklist` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-001`: Student DOB validated against cycle age rules for class.
  - `BR-ADM-009`: Aadhaar masked in UI; service validation prevents duplicate live enrolments.

---

#### SCR-08: Application Verification & KYC Workbench
- **Purpose & Objective:** Admissions office workbench to audit applicant data, inspect uploaded document proofs, and record physical original custody.
- **UI Layout & Components:**
  - **Split-Screen Layout:**
    - *Left Panel (Data Audit):* Applicant summary, age validation indicator, prior marks, guardian details.
    - *Right Panel (Document Inspector):* Interactive PDF/Image viewer with zoom, rotate, and full-screen controls.
  - **Document Approval Grid:** Checklist Item, Uploaded File Link, Verification Status Buttons (`Verified`, `Rejected`), Remarks Input, "Physical Copy Collected" Toggle.
  - **Decision Action Bar:** "Request Document Re-upload", "Reject Application", "Approve & Mark Verified".
- **Database Tables Covered:**
  - `adm_applications` (Primary)
  - `adm_application_documents` (Primary)
  - `adm_application_stages_log` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-007`: Application cannot transition to `Verified` while any mandatory document is `Pending` or `Rejected`.
  - Rejecting a document requires entering `verification_remarks`.

---

#### SCR-09: Application Pipeline & Stage Management Grid
- **Purpose & Objective:** Manage the status lifecycle of all applications across admission stages.
- **UI Layout & Components:**
  - **Filters:** Admission Cycle, Class, Quota, Stage (`Draft`, `Submitted`, `Under_Review`, `Verified`, `Shortlisted`, `Allotted`, `Enrolled`), Sibling Flag.
  - **Data Grid:** App Number, Student Name, Class, Quota, Sibling Badge, Fee Paid Badge, Current Status Badge, Days in Stage, Action Dropdown.
  - **Slide-Over Stage Log:** Click status badge to view complete historical timeline from `adm_application_stages_log`.
- **Database Tables Covered:**
  - `adm_applications` (Primary)
  - `adm_application_stages_log` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-016`: Application status transitions strictly follow legal FSM rules.
  - `BR-ADM-019`: Every status update automatically appends to `adm_application_stages_log`.

---

### Module 4: Entrance Examination & Evaluation Screens

#### SCR-10: Entrance Test Scheduler & Roll Number Generator
- **Purpose & Objective:** Configure test dates, timings, venues, and generate examination roll numbers for verified applicants.
- **UI Layout & Components:**
  - **Header Bar:** Cycle selector, Class filter, "Schedule New Test".
  - **Schedule Grid:** Test Name, Class, Date, Start/End Time, Venue, Mode (`Online`, `Offline`), Max Marks, Pass Marks, Registered Candidates Count.
  - **Modal Form:** Name, Class, Date, Time, Venue, Test Mode selector.
    - If `Online`: Enter CBT test portal link.
    - If `Offline`: File upload for question paper PDF (`sys_media`).
  - **Candidate Assignment Panel:** Multi-select verified candidates, click "Assign Candidates & Generate Roll Numbers" (`ROLL-{CLASS}-{SEQ}`).
- **Database Tables Covered:**
  - `adm_entrance_tests` (Primary)
  - `adm_entrance_test_candidates` (Secondary)
  - `adm_applications` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-011`: Entrance test creation is blocked for foundational classes (Class Ordinal $\le 2$) per NEP 2020.
  - `test_date` must be within admission cycle start and end dates.

---

#### SCR-11: Candidate Mark Entry & Attendance Grid
- **Purpose & Objective:** Input test attendance, marks obtained, and subject-wise score breakdowns.
- **UI Layout & Components:**
  - **Filters:** Test Session selector, Subject selector.
  - **Fast-Entry Data Grid:** Roll Number, Student Name, Application No, Attendance Status (`Present`, `Absent`), Total Marks (Auto-summed), Subject 1 Score, Subject 2 Score, Evaluated Result (`Pass`, `Fail`, `Pending`).
  - **Action Controls:** "Auto-Calculate Pass/Fail", "Save Draft", "Finalize & Lock Marks", "Import Marks Excel".
- **Database Tables Covered:**
  - `adm_entrance_test_candidates` (Primary)
  - `adm_entrance_tests` (Secondary)
- **Business Rules & Validation Logic:**
  - Total marks obtained cannot exceed `max_marks`.
  - Finalizing marks transitions candidates with marks $\ge \text{passing\_marks}$ to `Pass`, others to `Fail`.

---

#### SCR-12: Interview Scheduling & Scoring Modal
- **Purpose & Objective:** Schedule oral interactions/interviews and record evaluator remarks and scores.
- **UI Layout & Components:**
  - **Interview Calendar:** Weekly schedule view showing booked slots.
  - **Candidate Modal:** Candidate details, Interview Date/Time, Venue, Interviewer Assignment, Interview Notes, Score (0–100).
- **Database Tables Covered:**
  - `adm_applications` (Primary)
- **Business Rules & Validation Logic:**
  - Score captured in `adm_applications.interview_score` for composite ranking.

---

### Module 5: Merit Lists & Seat Allotment Screens

#### SCR-13: Algorithmic Merit List Compilation & Publishing Desk
- **Purpose & Objective:** Configure criteria weightages, compute composite scores, evaluate cut-offs, and publish rankings.
- **UI Layout & Components:**
  - **Setup Header:** Cycle, Class, and Quota selectors.
  - **Weightage Configuration Bar:**
    - Entrance Test % (e.g., 50%) + Interview % (e.g., 20%) + Prior Academic % (e.g., 30%) = Total 100%.
    - Sibling Bonus Points input (default 5).
    - Cut-off Score input (e.g., 50.00).
  - **Action Button:** "Compile Merit Ranking" (triggers `MeritListService`).
  - **Ranked Candidate Grid:** Rank, Application No, Student Name, Entrance Score, Interview Score, Academic Score, Sibling Bonus (+5), Composite Score, Merit Status (`Shortlisted`, `Waitlisted`, `Rejected`).
  - **Publication Actions:** "Save Draft", "Publish Merit List" (visible to parents), "Finalize Rankings".
- **Database Tables Covered:**
  - `adm_merit_lists` (Primary)
  - `adm_merit_list_entries` (Primary)
  - `adm_applications` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-008`: Weightages must sum to exactly 100.00%.
  - `BR-ADM-015`: Sibling bonus applied only if `is_sibling = 1`.
  - `BR-ADM-025`: Deterministic tie-breaking: Test Score $\rightarrow$ Prior Academics $\rightarrow$ Date of Birth.

---

#### SCR-14: Seat Allotment & Provisional Offer Letter Desk
- **Purpose & Objective:** Issue formal seat allotments, generate PDF offer letters, set response deadlines, and manage waitlists.
- **UI Layout & Components:**
  - **Top Metrics:** Total Quota Seats, Seats Allotted, Available Vacancies, Active Offers Pending Response.
  - **Allotment Table:** Rank, Application No, Student Name, Quota, Assigned Admission No, Joining Date, Offer Deadline, Offer Letter Download Link, Status (`Offered`, `Accepted`, `Declined`, `Expired`, `Enrolled`), Action Menu.
  - **Bulk Actions:** "Issue Offer Letters to Shortlisted", "Promote Next Waitlisted", "Extend Deadline".
  - **PDF Preview Modal:** View generated offer letter with student details, fee payment instructions, and QR verification code.
- **Database Tables Covered:**
  - `adm_allotments` (Primary)
  - `adm_seat_capacity` (Primary)
  - `adm_merit_list_entries` (Secondary)
  - `sys_media` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-013`: Allotments cannot exceed `total_seats` without administrator override.
  - `BR-ADM-014`: Daily console job `adm:expire-offers` automatically marks expired offers and triggers waitlist promotion.

---

#### SCR-15: Final Enrolment Desk & Section Allocation
- **Purpose & Objective:** Convert accepted, fee-paid seat allotments into permanent student records in `std_students`.
- **UI Layout & Components:**
  - **Ready-for-Enrolment Queue:** Displays allotments where `status = 'Accepted'` and `admission_fee_paid = 1`.
  - **Enrolment Drawer:**
    - Student & Guardian summary.
    - Fee Payment Verification badge (Transaction ID & Receipt No).
    - Section Selector (`sch_sections` dropdown).
    - Expected Joining Date picker.
  - **Action Control:** "Complete Enrolment & Create Student Record" (invokes `EnrollmentService::enrollStudent()`).
  - **Success Modal:** Confirms generated Student ID, assigned section, and portal login credentials for student and parents.
- **Database Tables Covered:**
  - `adm_allotments` (Primary)
  - `std_students` (Target)
  - `std_student_profiles` (Target)
  - `std_student_academic_sessions` (Target)
  - `std_siblings_jnt` (Target)
  - `sys_users` (Target)
  - `adm_seat_capacity` (Counter)
- **Business Rules & Validation Logic:**
  - `BR-ADM-002`: Admission fee clearance is a mandatory prerequisite (`admission_fee_paid = 1`).
  - Enrolment is executed within an atomic database transaction.

---

### Module 6: Post-Admission, Academic Transitions & Leavers

#### SCR-16: Post-Admission Withdrawal & Refund Desk
- **Purpose & Objective:** Process admission cancellation requests, calculate statutory fee refunds via cycle policy, and track disbursements.
- **UI Layout & Components:**
  - **Withdrawal Initiation Form:** Student / Applicant Search, Withdrawal Date, Reason (`Relocation`, `Financial`, `School_Change`, etc.), Remarks.
  - **Refund Computation Card:**
    - Total Fees Paid: ₹26,500.00
    - Days Elapsed Since Payment: 8 Days
    - Matched Refund Tier: $\le 15$ Days (80% Refund)
    - Calculated Refundable Amount: ₹21,200.00
    - Non-Refundable Processing Charge: ₹5,300.00
  - **Approval Workflow:** "Approve Refund", "Reject Refund", "Mark Refund Disbursed".
- **Database Tables Covered:**
  - `adm_withdrawals` (Primary)
  - `adm_allotments` (Secondary)
  - `adm_admission_cycles` (Secondary)
  - `adm_seat_capacity` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-018`: Refund calculated deterministically using piecewise JSON policy.
  - Approving withdrawal decrements `seats_allotted` or `seats_enrolled` in `adm_seat_capacity`.

---

#### SCR-17: Cohort-Based Year-End Promotion Batch Desk
- **Purpose & Objective:** Manage end-of-year class-to-class academic cohort transitions.
- **UI Layout & Components:**
  - **Batch Header Panel:** Source Session, Target Next Session, Source Class, Target Promoted Class, Pass Criteria % (default 33%).
  - **Student Staging Grid:** Student Admission No, Student Name, Current Section, Exam Result % (from Exam module), Promotion Decision (`Promoted`, `Detained`, `Transferred`, `Alumni`, `Left`), Target Section Dropdown, New Roll Number.
  - **Bulk Action Bar:** "Auto-Evaluate from Exam Results", "Assign Alphabetical Roll Numbers", "Confirm & Commit Promotion Batch".
- **Database Tables Covered:**
  - `adm_promotion_batches` (Primary)
  - `adm_promotion_records` (Primary)
  - `std_students` (Secondary)
  - `std_student_academic_sessions` (Target)
- **Business Rules & Validation Logic:**
  - `BR-ADM-012`: Confirming a promotion batch is idempotent (`updateOrCreate`).
  - `BR-ADM-022`: Promoted students receive sequential roll numbers sorted alphabetically by last name.

---

#### SCR-18: Transfer Certificate (TC) Issuance & Verification Desk
- **Purpose & Objective:** Issue official Transfer Certificates, audit financial clearance, and manage duplicate re-issuances.
- **UI Layout & Components:**
  - **Student Search & Dues Check Panel:** Select student; system queries StudentFee module in real-time.
    - If dues exist: Render red blocking banner showing outstanding balance; disable TC generation.
    - If dues cleared: Render green clearance badge (`fees_cleared = 1`).
  - **TC Details Form:** Leaving Date, Class at Leaving, Reason for Leaving, Conduct Grade (`Excellent`, `Good`, `Satisfactory`, `Poor`), Destination School, Academic Status.
  - **Issuance Actions:** "Generate TC PDF", "Print Certificate", "Issue Duplicate Copy" (links `original_tc_id`).
  - **Public Verification QR Code:** Embedded on PDF, resolving to `/verify-tc/{tc_number}`.
- **Database Tables Covered:**
  - `adm_transfer_certificates` (Primary)
  - `std_students` (Secondary)
  - `sys_media` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-004`: TC generation strictly blocked if financial ledger has un-cleared dues.
  - `BR-ADM-020`: Re-issued TCs are marked `is_duplicate = 1` and reference `original_tc_id`.
  - Student status in `std_students` updates to `Transferred`.

---

#### SCR-19: Student Disciplinary Incidents & Conduct Register
- **Purpose & Objective:** Log behavioral infractions, assign severity, calculate conduct score impacts, and record corrective actions.
- **UI Layout & Components:**
  - **Incident Entry Form:** Student Search, Incident Date, Incident Type (`Bullying`, `Cheating`, `Disruption`, `Violence`, etc.), Severity (`Low`, `Medium`, `High`, `Critical`), Description, Campus Location, Witnesses Tag Input, Score Deduction (e.g., -5, -15).
  - **Corrective Action Section:** Action Type (`Warning`, `Detention`, `Suspension`, `Parent_Meeting`), Start/End Dates, Parent Meeting Date/Time, Meeting Outcome Notes.
  - **Incident Register Grid:** Date, Student Name, Class, Type, Severity Badge, Status (`Open`, `Action_Taken`, `Closed`, `Escalated`), Score Impact, Parent Notified Badge.
- **Database Tables Covered:**
  - `adm_behavior_incidents` (Primary)
  - `adm_behavior_actions` (Secondary)
  - `std_students` (Secondary)
- **Business Rules & Validation Logic:**
  - `BR-ADM-021`: `severity = 'Critical'` triggers immediate automated notifications to principal and parents.
  - `behavior_score_impact` is stored as a signed `TINYINT`.

---

### Module 7: Analytics & Public Portal Screens

#### SCR-20: Executive Admission Funnel Dashboard
- **Purpose & Objective:** Visual executive overview of conversion velocities and drop-offs across funnel stages.
- **UI Layout & Components:**
  - **Metric Cards:** Total Enquiries, Conversion Rate %, Total Allotted, Total Enrolled, Fee Revenue Collected.
  - **Funnel Drop-Off Chart:** Horizontal funnel visualization: Enquiries (100%) $\rightarrow$ Applications (68%) $\rightarrow$ Verified (54%) $\rightarrow$ Shortlisted (32%) $\rightarrow$ Allotted (28%) $\rightarrow$ Enrolled (24%).
  - **Channel Performance Chart:** Conversion breakdown by lead source (Website vs Walk-in vs Campaigns).
- **Database Tables Covered:**
  - Reads across `adm_enquiries`, `adm_applications`, `adm_allotments`, `adm_seat_capacity`.

---

#### SCR-21: Class & Quota Seat Occupancy Heatmap
- **Purpose & Objective:** Real-time seat budget utilization and vacancy tracking across classes and quotas.
- **UI Layout & Components:**
  - **Occupancy Heatmap Matrix:** Visual colored cells showing % fill by class and quota.
  - **Filter Controls:** Cycle selector, Grade Level band (Primary, Middle, Senior).
  - **Drilldown Modal:** Click any cell to view the list of allotted and enrolled students.
- **Database Tables Covered:**
  - `adm_seat_capacity` (Primary)
  - `sch_classes` (Secondary)

---

#### SCR-22: Application Fee Reconciliation Ledger
- **Purpose & Objective:** Audit application fees collected, fee waivers granted, and gateway settlement logs.
- **UI Layout & Components:**
  - **Filters:** Date Range, Payment Method (Gateway, Cash, Waived), Quota Type.
  - **Reconciliation Table:** Application No, Student Name, Quota, Fee Status (`Paid`, `Waived`), Transaction Reference, Gateway Log ID, Amount.
- **Database Tables Covered:**
  - `adm_applications` (Primary)
  - `fee_transactions` (Secondary)

---

#### SCR-23: Sibling Admissions & Bonus Report
- **Purpose & Objective:** Audit sibling leads detected, sibling bonus scores awarded, and successful enrolments.
- **UI Layout & Components:**
  - **Data Grid:** Application No, Applicant Name, Enrolled Sibling Name, Sibling Admission No, Shared Parent Name, Contact Phone, Bonus Points Applied, Enrolment Status.
- **Database Tables Covered:**
  - `adm_applications` (Primary)
  - `adm_merit_list_entries` (Secondary)
  - `std_students` (Secondary)

---

#### SCR-24: Statutory RTE 25% Compliance Report
- **Purpose & Objective:** Official report proving compliance with Right to Education (RTE) Section 12(1)(c) mandates.
- **UI Layout & Components:**
  - **Statutory Audit Table:** Class Name, Total Class Strength, RTE 25% Seat Quota, Total RTE Applications, Total RTE Verified, Total RTE Enrolled, Fee Waivers Granted (₹), Document Archive Links.
  - **Export Action:** "Download Government Audit PDF".
- **Database Tables Covered:**
  - `adm_quota_config` (Primary)
  - `adm_seat_capacity` (Primary)
  - `adm_applications` (Secondary)

---

#### SCR-25: Public Parent Admission Portal & Status Tracker
- **Purpose & Objective:** Responsive public-facing self-service interface for parents.
- **UI Layout & Components:**
  - **Welcome & Form Selector:** School branding, active cycle banner, class sought selector.
  - **Public Wizard:** Responsive multi-step entry identical to SCR-07 with instant draft saving.
  - **Application Status Tracker:** Enter Application No and Mobile to check live status badge, download offer letters, upload requested documents, or initiate fee payments.
- **Database Tables Covered:**
  - `adm_admission_cycles` (Primary)
  - `adm_applications` (Primary)
  - `adm_allotments` (Secondary)
  - `adm_application_documents` (Secondary)
