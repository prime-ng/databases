# Prime-AI Admission Management Module — Solution Design

**Document ID:** ADM-SD-V2  
**Version:** 2.0  
**Status:** Approved-for-Design Baseline  
**Date:** 2026-09-23  
**Module:** Admission Management (`Modules\Admission`)  
**Prefix:** `adm_*` (20 Tables across 9 Architectural Layers)  
**Stack:** Laravel 12 · PHP 8.3 · MySQL 8.0.16+ · stancl/tenancy v3.9 (database-per-tenant) · Blade + Alpine.js + TailwindCSS  
**Governed by:** `Admission_BRD_v2.md` (v2.0)  
**Realised by:** `Admission_DDL_v2.sql` (v2.0)  
**Companion Documents:**  
- Data Dictionary: `Admission_Data_Dictionary_v2.md`  
- Process Flow & Screen Design: `Admission_Process_Flow_v2.md`  

---

## 0. Document Control

### 0.1 Architectural Position in Document Suite

```
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                 BUSINESS LAYER: Admission_BRD_v2.md                         │
  │                 (What the school needs, statutory rules, KPIs)              │
  └──────────────────────────────────────┬──────────────────────────────────────┘
                                         ▼
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                 SOLUTION LAYER: Admission_Solution_Design_v2.md             │
  │                 (Architecture, Services, FSMs, Algorithms, Boundaries)      │
  └───────────────────┬─────────────────────────────────────┬───────────────────┘
                      ▼                                     ▼
  ┌──────────────────────────────────────┐  ┌───────────────────────────────────┐
  │  DATA LAYER:                         │  │  INTERACTION LAYER:               │
  │  Admission_Data_Dictionary_v2.md     │  │  Admission_Process_Flow_v2.md     │
  │  & Admission_DDL_v2.sql              │  │  (Screens, Wizards, Controls)     │
  └──────────────────────────────────────┘  └───────────────────────────────────┘
```

### 0.2 Design Tenets

| Tenet ID | Tenet Name | Technical Consequence & Architectural Mandate |
|---|---|---|
| **T-01** | **Structural Integrity Over Convention** | Business invariants (quota capacities, unique application numbers, cycle statuses) must be protected by database constraints, transactions, and foreign keys—not developer memory. |
| **T-02** | **Zero-Loss Atomic Boundaries** | Conversion from prospective applicant to enrolled student (`EnrollmentService`) must execute within an isolated, atomic database transaction covering `sys_users`, `std_students`, `std_student_profiles`, `std_student_academic_sessions`, and `std_siblings_jnt`. |
| **T-03** | **Immutable Auditability** | Status transitions (`adm_application_stages_log`), physical document custody events, and fee reconciliations must be append-only logs. Overwriting historical transitions is strictly prohibited. |
| **T-04** | **Configurable Policy, Deterministic Execution** | Critical institutional policies (age cut-offs, sibling bonus points, merit weightages, refund tiers) are stored as cycle-level JSON configs and evaluated deterministically by pure service functions. |
| **T-05** | **Decoupled Financial Contracts** | The Admission module triggers and tracks fee obligations (`application_fee_paid`, `admission_fee_paid`) but delegates accounting ledgers, payment gateway webhooks, and receipts to `StudentFee` and `Accounting`. |
| **T-06** | **Strict PII Protection & DPDP Compliance** | Sensitive identifiers (Aadhaar numbers) must never be used as raw database unique keys; values are encrypted at rest, masked in presentations, and validated at the service layer only. |
| **T-07** | **Idempotent Academic Batch Operations** | Large-scale annual operations (promotion batches, waitlist rollover) must be idempotent: executing a batch repeatedly against the same data produces the identical valid state without duplication. |
| **T-08** | **Proactive Scheduled Automation** | Expiring seat offers and scheduling CRM follow-up reminders must not rely on synchronous user page loads; dedicated background console jobs evaluate deadlines and dispatch events. |

---

## 1. System Architecture & Context

### 1.1 Architectural Overview
The Admission module is implemented as a self-contained domain module (`Modules\Admission`) in the Prime-AI tenant application. Each school operates within its dedicated tenant database (`tenant_db`), ensuring complete structural isolation of student data, financial transactions, and lead pipelines.

The architecture comprises three operational tiers:
1. **Public Self-Service Tier:** Unauthenticated public-facing routes (`/apply/{slug}`, `/status/{app_no}`) allowing prospective parents to enquire, submit multi-step applications, upload verification documents, and pay fees via secure gateway integrations.
2. **Administrative Core Tier:** Authenticated controller and service layer (`Modules\Admission\Services`) handling CRM interactions, document audits, exam scheduling, merit compilation, and seat allocations.
3. **Cross-Module Integration Tier:** Service contracts binding the admission lifecycle to `StudentMaster` (enrolment handoff), `StudentFee` (fee settlements), `Accounting` (fee vouchers & refunds), `SysMedia` (document blobs), and `Notification` (SMS/Email alerts).

### 1.2 System Context Diagram

```
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                          PUBLIC & EXTERNAL ACTORS                           │
   │           [Prospective Parents]       [Payment Gateway (Razorpay/Stripe)]   │
   └──────────────────────┬──────────────────────────────────┬───────────────────┘
                          │ HTTP Public Routes               │ Webhook Callback
                          ▼                                  ▼
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │                        PRIME-AI TENANT APPLICATION                          │
   │                                                                             │
   │   ┌─────────────────────────────────────────────────────────────────────┐   │
   │   │                     MODULES \ ADMISSION                             │   │
   │   │                                                                     │   │
   │   │   Controllers:                                                      │   │
   │   │   EnquiryController · ApplicationController · MeritListController   │   │
   │   │   AllotmentController · EnrollmentController · PromotionController  │   │
   │   │                                                                     │   │
   │   │   Domain Services:                                                  │   │
   │   │   ├── AdmissionPipelineService (Lead & Application FSM)             │   │
   │   │   ├── MeritListService (Scoring, Ranking, Quota Allotment)          │   │
   │   │   ├── EnrollmentService (Atomic Student Conversion)                 │   │
   │   │   ├── PromotionService (Cohort Transition & Section Reallocation)   │   │
   │   │   ├── TransferCertificateService (Dues Audit & PDF Issuance)        │   │
   │   │   └── AdmissionAnalyticsService (Funnel KPIs & Occupancy)           │   │
   │   │                                                                     │   │
   │   │   Physical Schema (20 Tables):                                      │   │
   │   │   adm_admission_cycles · adm_quota_config · adm_seat_capacity       │   │
   │   │   adm_enquiries · adm_follow_ups · adm_applications                 │   │
   │   │   adm_application_documents · adm_merit_lists · adm_allotments     │   │
   │   │   adm_promotion_batches · adm_withdrawals · adm_transfer_certs      │   │
   │   └───────────────────────────────┬─────────────────────────────────────┘   │
   │                                   │                                         │
   │               CROSS-MODULE TRANSACTION CONTRACTS                            │
   │                                   ▼                                         │
   │   ┌─────────────────────────────────────────────────────────────────────┐   │
   │   │  CORE APPLICATION MODULES (TENANT DB)                               │   │
   │   │  ├── Modules\Student: std_students · std_student_profiles           │   │
   │   │  ├── Modules\StudentFee: fee_transactions · fee_receipts            │   │
   │   │  ├── Modules\Accounting: acc_vouchers (Refunds & Fee Journal)       │   │
   │   │  ├── Modules\System: sys_users · sys_media · sys_dropdown_table     │   │
   │   │  └── Modules\Notification: NTF Dispatch Outbox                      │   │
   │   └─────────────────────────────────────────────────────────────────────┘   │
   └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Domain Sub-Modules & Service Layer Architecture

The business logic of the Admission module is partitioned across six dedicated domain services. Domain controllers are lightweight, delegating all transactional operations to services.

```
Modules\Admission\Services
├── AdmissionPipelineService.php      // Lead capture, FSM transitions, KYC verification
├── MeritListService.php              // Composite score calculation, ranking, tie-breaking
├── EnrollmentService.php             // Atomic conversion from applicant to student
├── PromotionService.php              // Year-end student academic batch transitions
├── TransferCertificateService.php   // Financial dues clearance & secure TC generation
└── AdmissionAnalyticsService.php     // Funnel metrics, conversion velocities, seat capacity
```

### 2.1 Service Specifications & Responsibilities

#### 1. `AdmissionPipelineService`
- **Class:** `Modules\Admission\Services\AdmissionPipelineService`
- **Primary Methods:**
  - `createLead(array $data): AdmEnquiry`: Validates input, generates `enquiry_no`, executes sibling detection query against `std_guardians.mobile_no`, and flags duplicate leads.
  - `convertLeadToApplication(int $enquiryId): AdmApplication`: Converts an enquiry into a formal application, transferring demographic details and maintaining linkage via `enquiry_id`.
  - `transitionStatus(AdmApplication $app, string $toStatus, ?string $remarks, ?int $userId): bool`: Validates FSM transition legality, updates application status, and appends an immutable record to `adm_application_stages_log`.
  - `verifyDocument(int $appDocId, string $status, ?string $remarks, int $verifierId): bool`: Updates document status, sets verification timestamps, and evaluates whether all mandatory checklist items are verified.

#### 2. `MeritListService`
- **Class:** `Modules\Admission\Services\MeritListService`
- **Primary Methods:**
  - `compileMeritList(int $cycleId, int $classId, string $quota): AdmMeritList`: Fetches verified candidates, evaluates weighted composite scores, applies sibling bonus, sorts deterministically using tie-breakers, and sets merit statuses (`Shortlisted`, `Waitlisted`, `Rejected`).
  - `calculateCompositeScore(AdmApplication $app, AdmMeritList $list): float`: Computes the weighted percentage score:
    $$\text{Score} = \left(\frac{T_{\text{obtained}}}{T_{\text{max}}} \times W_t\right) + \left(\frac{I_{\text{obtained}}}{I_{\text{max}}} \times W_i\right) + (A_{\text{pct}} \times W_a) + S_{\text{bonus}}$$
  - `allotSeat(int $meritListEntryId): AdmAllotment`: Validates seat availability in `adm_seat_capacity`, creates allotment record, increments `seats_allotted`, generates provisional admission number, and renders offer letter PDF.
  - `promoteWaitlist(int $cycleId, int $classId, string $quota): ?AdmAllotment`: Triggered when an offer expires or declines; selects the highest-ranking `Waitlisted` candidate and issues an allotment.

#### 3. `EnrollmentService`
- **Class:** `Modules\Admission\Services\EnrollmentService`
- **Primary Methods:**
  - `enrollStudent(int $allotmentId, int $sectionId, int $processedBy): StdStudent`: Executes the single atomic enrolment transaction:
    1. Validates `admission_fee_paid = 1` and `allotment.status = 'Accepted'`.
    2. Generates user credentials in `sys_users` for student and parents.
    3. Writes student master in `std_students`.
    4. Writes detailed demographics into `std_student_profiles`.
    5. Writes section enrollment into `std_student_academic_sessions`.
    6. Writes sibling link into `std_siblings_jnt` if `is_sibling = 1`.
    7. Updates `adm_allotments` (`status = 'Enrolled'`, `enrolled_student_id = std_students.id`).
    8. Updates `adm_applications` (`status = 'Enrolled'`).
    9. Increments `adm_seat_capacity.seats_enrolled`.
    10. Emits `StudentEnrolledEvent` for notification and welcome pack dispatch.

#### 4. `PromotionService`
- **Class:** `Modules\Admission\Services\PromotionService`
- **Primary Methods:**
  - `generateBatch(int $fromSession, int $toSession, int $fromClass, int $toClass, array $criteria): AdmPromotionBatch`: Identifies active students in source session/class, evaluates pass/detain criteria, and stages rows in `adm_promotion_records`.
  - `confirmBatch(int $batchId, int $userId): bool`: Idempotently commits student movements into `std_student_academic_sessions` for the target session, assigns sequential roll numbers, and updates batch counts.

#### 5. `TransferCertificateService`
- **Class:** `Modules\Admission\Services\TransferCertificateService`
- **Primary Methods:**
  - `checkDuesClearance(int $studentId): array`: Queries StudentFee ledgers to verify outstanding dues; returns boolean `cleared` status and outstanding itemization.
  - `issueTC(int $studentId, array $tcData, int $issuedBy): AdmTransferCertificate`: Enforces fee clearance rule (`BR-ADM-004`), generates sequential `tc_number`, creates TC record, renders PDF with cryptographic QR code stored in `sys_media`, and updates `std_students.status = 'Transferred'`.

#### 6. `AdmissionAnalyticsService`
- **Class:** `Modules\Admission\Services\AdmissionAnalyticsService`
- **Primary Methods:**
  - `getFunnelMetrics(int $cycleId): array`: Computes counts and conversion drop-offs across funnel stages.
  - `getSeatCapacityDashboard(int $cycleId): array`: Computes budgeted vs allotted vs enrolled seats and vacancy percentages by class and quota.
  - `getLeadChannelROI(int $cycleId): array`: Evaluates cost and conversion efficiency per marketing lead source.

---

## 3. Finite State Machine (FSM) Lifecycle Specifications

The Admission module enforces rigorous, legally compliant state transitions across all core entities. Illegal transitions trigger database rollbacks and domain exceptions.

### 3.1 Application Lifecycle State Machine (`adm_applications.status`)

```
   ┌──────────┐
   │  Draft   │
   └────┬─────┘
        │ Parent submits form
        ▼
   ┌──────────┐
   │Submitted │◄────────────────┐
   └────┬─────┘                 │ Resubmission after KYC rejection
        │ Counselor starts audit│
        ▼                       │
 ┌──────────────┐               │
 │ Under_Review ├───────────────┘
 └──────┬───────┘
        │ Mandatory KYC documents verified
        ▼
   ┌──────────┐      Entrance Exam / Interview
   │ Verified ├─────────────────────────┐
   └────┬─────┘                         │
        │ Failed cut-off                │ Passed cut-off & ranked
        ▼                               ▼
  ┌───────────┐                  ┌─────────────┐
  │ Rejected  │                  │ Shortlisted ├───────────────────┐
  └───────────┘                  └──────┬──────┘                   │
                                        │ Allocated within capacity│
                                        ▼                          ▼
                                 ┌──────────────┐           ┌──────────────┐
                                 │   Allotted   │           │  Waitlisted  │
                                 └──────┬───────┘           └──────────────┘
                                        │ Fee paid & section assigned
                                        ▼
                                 ┌──────────────┐
                                 │   Enrolled   │ (Terminal State)
                                 └──────────────┘
```

#### Application State Transition Matrix

| From State | Allowed Target State | Triggering Event / User Action | Pre-Conditions & Invariants |
|---|---|---|---|
| `Draft` | `Submitted` | Parent submits completed online form. | Mandatory fields complete; application fee paid or waived. |
| `Submitted` | `Under_Review` | Counselor opens and claims application. | Counselor assigned; stage log updated. |
| `Under_Review` | `Verified` | Document verification officer signs off KYC. | All mandatory checklist items have status `Verified`. |
| `Under_Review` | `Submitted` | Officer requests document re-upload. | Specific documents rejected with remarks. |
| `Under_Review` | `Rejected` | Application fails core eligibility (e.g., age). | Rejection reason recorded in `rejection_reason`. |
| `Verified` | `Shortlisted` | Merit list generation compiles composite score. | Candidate score $\ge$ merit cut-off; rank $\le$ quota seats. |
| `Verified` | `Waitlisted` | Merit list generation compiles composite score. | Candidate score $\ge$ merit cut-off; rank $>$ quota seats. |
| `Verified` | `Rejected` | Candidate fails entrance or falls below cut-off. | Candidate score $<$ merit cut-off. |
| `Shortlisted` | `Allotted` | Admissions board issues seat allotment offer. | Seat capacity available; offer letter generated. |
| `Waitlisted` | `Allotted` | Waitlist promotion triggered by expired offer. | Vacancy created in quota seat capacity. |
| `Allotted` | `Enrolled` | Final enrolment transaction executed. | `admission_fee_paid = 1`; section assigned. |
| `Allotted` | `Withdrawn` | Parent declines offer or withdraws post-offer. | Withdrawal recorded in `adm_withdrawals`. |
| `Enrolled` | `Withdrawn` | Student departs post-enrolment. | Withdrawal recorded; refund policy evaluated. |

---

### 3.2 Allotment Lifecycle State Machine (`adm_allotments.status`)

```
   ┌──────────┐
   │ Offered  │
   └────┬─────┘
        │
        ├────────────────────────┬────────────────────────┐
        │ Parent accepts offer   │ Parent declines offer  │ Deadline passes
        ▼                        ▼                        ▼
   ┌──────────┐             ┌──────────┐             ┌──────────┐
   │ Accepted │             │ Declined │             │ Expired  │
   └────┬─────┘             └──────────┘             └──────────┘
        │
        ├────────────────────────┐
        │ Fee paid & enrolled    │ Parent cancels
        ▼                        ▼
   ┌──────────┐             ┌───────────┐
   │ Enrolled │             │ Withdrawn │
   └──────────┘             └───────────┘
```

#### Allotment State Transition Invariants
- `Offered` $\rightarrow$ `Accepted`: Requires parent confirmation via portal or written consent.
- `Offered` $\rightarrow$ `Expired`: Automated transition executed by `adm:expire-offers` when `CURDATE() > offer_expires_at`. Decrements `seats_allotted` by 1.
- `Accepted` $\rightarrow$ `Enrolled`: Requires `admission_fee_paid = 1`. Sets `enrolled_student_id`.
- `Declined` / `Expired` / `Withdrawn`: Re-releases seat capacity back to quota pool for waitlist reallocation.

---

### 3.3 Admission Cycle State Machine (`adm_admission_cycles.status`)

```
   ┌─────────┐      Publish cycle
   │  Draft  ├─────────────────────────►  ┌────────┐
   └─────────┘                            │  Open  │
                                          └───┬────┘
                                              │ Close cycle
                                              ▼
   ┌──────────┐      Archive cycle        ┌────────┐
   │ Archived │◄──────────────────────────┤ Closed │
   └──────────┘                           └────────┘
```

- Invariant: Only one cycle can have `status = 'Open'` and `active_flag = 1` per `academic_session_id`.
- When transitioning to `Closed` or `Archived`, the system automatically sets `active_flag = 0`.

---

## 4. Algorithmic & Mathematical Calculation Engines

### 4.1 Age Eligibility Engine
The age eligibility engine verifies whether an applicant meets the minimum and maximum age criteria as of the cycle's statutory cut-off date (`age_cut_off_date`), complying with NEP 2020 guidelines.

#### Age Calculation Formula
$$\text{Age in Years} = \frac{\text{DateDiff}(\text{age\_cut\_off\_date}, \text{student\_dob})}{365.25}$$

#### Validation Algorithm
Let $C_{\text{id}}$ be the class ID sought. The cycle configuration stores:
$$\text{age\_rules\_json} = \{ C_1: \{\text{min}: Y_{\text{min}}, \text{max}: Y_{\text{max}}\}, \dots \}$$
$$\text{Eligible} = \begin{cases} 
\text{True}, & \text{if } Y_{\text{min}} \le \text{Age in Years} \le Y_{\text{max}} \\ 
\text{False}, & \text{otherwise} 
\end{cases}$$

---

### 4.2 Weighted Merit Composite Scoring & Tie-Breaker Algorithm

#### Mathematical Formulation
Each merit list defines percentage weightages satisfying the unit sum constraint:
$$W_{\text{test}} + W_{\text{interview}} + W_{\text{academic}} = 100.00\%$$

For each verified applicant:
1. **Entrance Test Score Component ($S_t$):**
   $$S_t = \begin{cases} 
   \left(\frac{\text{marks\_obtained}}{\text{max\_marks}}\right) \times W_{\text{test}}, & \text{if entrance test configured} \\ 
   0, & \text{otherwise} 
   \end{cases}$$
2. **Interview Score Component ($S_i$):**
   $$S_i = \begin{cases} 
   \left(\frac{\text{interview\_score}}{100}\right) \times W_{\text{interview}}, & \text{if interview conducted} \\ 
   0, & \text{otherwise} 
   \end{cases}$$
3. **Prior Academic Score Component ($S_a$):**
   $$S_a = \left(\frac{\text{prev\_marks\_percent}}{100}\right) \times W_{\text{academic}}$$
4. **Sibling Bonus Component ($B_s$):**
   $$B_s = \begin{cases} 
   \text{sibling\_bonus\_score}, & \text{if } \text{is\_sibling} = 1 \\ 
   0, & \text{otherwise} 
   \end{cases}$$

#### Total Composite Score Calculation
$$\text{Composite Score} = \min\left(100.00, S_t + S_i + S_a + B_s\right)$$

#### Deterministic Tie-Breaking Logic
When two or more candidates achieve identical composite scores, rankings are assigned deterministically:
$$\text{Rank Order} = \text{OrderBy}\left( \text{Composite Score } \mathbf{DESC},\; S_t \mathbf{DESC},\; S_a \mathbf{DESC},\; \text{student\_dob } \mathbf{ASC} \right)$$
*(Rule: Higher test score wins; if equal, higher prior academics wins; if still equal, the older applicant wins).*

---

### 4.3 Tiered Withdrawal Fee Refund Calculation Engine

Refund eligibility is computed deterministically using piecewise step functions defined in `adm_admission_cycles.refund_policy_json`.

#### Policy Structure
$$\text{refund\_policy\_json} = \{ D_1: R_1,\; D_2: R_2,\; \dots,\; D_n: R_n \}$$
*(Where $D_k$ represents elapsed calendar days threshold, and $R_k$ is the refund percentage).*  
*Example:* `{"7": 100, "15": 80, "30": 50, "999": 0}`

#### Evaluation Algorithm
$$\Delta D = \text{DateDiff}(\text{withdrawal\_date}, \text{admission\_fee\_date})$$
$$\text{Refund Percentage } (R_{\text{eff}}) = R_k \quad \text{for the smallest } D_k \ge \Delta D$$
$$\text{Eligible Refund Amount} = \text{fee\_paid\_amount} \times \left(\frac{R_{\text{eff}}}{100}\right)$$

---

## 5. Cross-Module Transactional Integration Contracts

### 5.1 Enrolment Transaction Boundary Contract (`Modules\Student`)

The conversion from applicant to enrolled student represents the most critical cross-module boundary. To prevent partial writes, this operation is executed within an atomic database transaction.

```
   ┌─────────────────────────────────────────────────────────────────────────────┐
   │               EnrollmentService::enrollStudent() TRANSACTION                │
   │                                                                             │
   │  1. DB::beginTransaction()                                                  │
   │  2. Verify: Allotment status == 'Accepted' && admission_fee_paid == 1       │
   │  3. Insert: sys_users (Student Account & Credentials)                       │
   │  4. Insert: sys_users (Parent Accounts if not existing)                     │
   │  5. Insert: std_students (admission_no, user_id, status = 'Active')         │
   │  6. Insert: std_student_profiles (demographics, Aadhaar, blood group, etc.) │
   │  7. Insert: std_student_academic_sessions (session_id, class_id, section_id)│
   │  8. Insert: std_siblings_jnt (if is_sibling == 1)                           │
   │  9. Update: adm_allotments (status = 'Enrolled', enrolled_student_id)       │
   │ 10. Update: adm_applications (status = 'Enrolled')                          │
   │ 11. Update: adm_seat_capacity (increment seats_enrolled)                    │
   │ 12. DB::commit()                                                            │
   │ 13. Dispatch: StudentEnrolledEvent (Async notifications & welcome pack)     │
   └─────────────────────────────────────────────────────────────────────────────┘
```

#### Field Mapping Contract: Application to Student Master

| Source Table & Column (`adm_*`) | Target Table & Column | Transformation / Rule |
|---|---|---|
| `adm_allotments.admission_no` | `std_students.admission_no` | Direct transfer (primary institutional ID). |
| `adm_applications.student_first_name` | `std_students.first_name` | Direct string copy. |
| `adm_applications.student_last_name` | `std_students.last_name` | Direct string copy. |
| `adm_applications.student_dob` | `std_students.dob` | Date value. |
| `adm_applications.student_gender` | `std_students.gender` | Direct ENUM mapping. |
| `adm_applications.student_religion_id` | `std_student_profiles.religion_id` | Direct FK reference to `sys_dropdown_table`. |
| `adm_applications.student_caste_category_id` | `std_student_profiles.caste_category_id` | Direct FK reference to `sys_dropdown_table`. |
| `adm_applications.aadhar_no` | `std_student_profiles.aadhar_no` | Encrypted at rest (AES-256). |
| `adm_applications.apaar_id` | `std_student_profiles.apaar_id` | National Academic Bank ID. |
| `adm_allotments.allotted_class_id` | `std_student_academic_sessions.class_id` | Foreign key to `sch_classes`. |
| `adm_allotments.allotted_section_id` | `std_student_academic_sessions.section_id` | Foreign key to `sch_sections`. |

---

### 5.2 StudentFee & Accounting Integration Contract (`Modules\StudentFee` & `Modules\Accounting`)

1. **Application Fee Collection:**
   - Public online payments trigger payment gateway webhooks into `fee_payment_gateway_logs`.
   - On success, `fee_transactions` and `fee_receipts` records are generated.
   - The application updates: `application_fee_paid = 1`, `application_fee_amount = txn.amount`, `fee_transactions_id = txn.id`, `fee_receipts_id = receipt.id`.
   - Accounting event emitted: Credit `Application Fee Income`, Debit `Bank Ledger`.
2. **Admission Fee Settlement:**
   - Seat acceptance requires full payment of the admission fee.
   - Upon confirmation, `adm_allotments` updates: `admission_fee_paid = 1`, `admission_fee_amount = txn.amount`, `admission_fee_date = CURDATE()`.
3. **Withdrawal Refund Disbursement:**
   - Approving an `adm_withdrawals` row with `refund_eligible_amount > 0` generates an unposted Payment Voucher in Accounting.
   - When Finance issues the payout, the voucher is posted and `adm_withdrawals.refund_status` transitions to `Paid`.

---

### 5.3 System Media Integration Contract (`Modules\System\Media`)

All binary files (document proofs, test papers, offer letters, Transfer Certificates) are stored using Prime-AI's centralized `sys_media` engine.

- **Checklist Proof Uploads:** Uploaded candidate files are saved to private storage. The media record is created in `sys_media`, and `adm_application_documents.media_id` stores the foreign key reference.
- **Offer Letters:** Generated offer letter PDFs store their file metadata in `sys_media` and reference `adm_allotments.offer_letter_media_id`.
- **Transfer Certificates:** Final signed TC PDFs link via `adm_transfer_certificates.media_id`.

---

## 6. Scheduled Console Commands & Background Workers

| Command Signature | Schedule Frequency | Execution Logic & Responsibilities |
|---|---|---|
| `adm:expire-offers` | **Daily at 00:01 AM** | Queries `adm_allotments` where `status = 'Offered'` and `offer_expires_at < CURDATE()`. Transitions status to `Expired`, decrements `adm_seat_capacity.seats_allotted`, and calls `MeritListService::promoteWaitlist()`. |
| `adm:send-followup-reminders` | **Daily at 08:00 AM** | Queries `adm_follow_ups` where `scheduled_at` is today and `reminder_sent = 0`. Dispatches counselor push notifications / SMS and marks `reminder_sent = 1`. |
| `adm:process-promotion-batch` | **On Demand (Queued)** | Processes staged promotion records in `adm_promotion_batches` asynchronously for large cohorts ($>100$ students), isolating session allocation transactions. |
| `adm:purge-stale-drafts` | **Weekly (Sunday 02:00 AM)** | Flags or archives incomplete draft applications older than 90 days from closed admission cycles. |

---

## 7. Security, Privacy & Statutory Compliance

### 7.1 Digital Personal Data Protection (DPDP) & Aadhaar Governance
- **Aadhaar Privacy Mandate:** Aadhaar numbers are never stored in plaintext. They are encrypted using Laravel's application cipher (`AES-256-CBC`) at rest.
- **UI Masking:** In all counselor views, student dashboards, and print formats, Aadhaar digits are masked: `XXXXXXXX1234`.
- **Service Layer Uniqueness:** Uniqueness is checked via SHA-256 blind hashing at the service layer to avoid plaintext index scans and prevent hard collisions with incomplete drafts.

### 7.2 Right to Education (RTE) Statutory Compliance
- **Quota Safeguard:** Entry-level classes enforce a hard 25% minimum capacity reservation for the `RTE` quota.
- **Fee Exemption:** Applications under `RTE` or `EWS` quotas automatically bypass application fee checks (`application_fee_waiver = 1`).

### 7.3 National Education Policy (NEP) 2020 Compliance
- **Early Childhood Screening Prohibition:** NEP 2020 and RTE Section 13 prohibit formal written examinations or screening interviews for early childhood admissions.
- **System Enforcement:** The system automatically disables entrance test scheduling (`adm_entrance_tests`) for foundational classes (Class Ordinal $\le 2$).
