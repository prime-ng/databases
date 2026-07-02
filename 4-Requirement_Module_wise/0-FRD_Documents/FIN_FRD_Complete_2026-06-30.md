# FIN — StudentFee: Complete Analysis Pack | 2026-06-30
**FRD Reference:** `FIN_FRD_2026-06-30.md` (same folder) — all REQ-/BR-/RPT-/ENH- IDs are shared.
**Module:** StudentFee (FIN) | **Prefix:** `fee_*` | **Scope:** Tenant | **Completion:** ~80–90%
**Sources:** V2 Requirement (2026-03-26) · V1 Screen Specs (15 files) · Module Knowledge (seeded 2026-06-30) · Filesystem verification

---

## Table of Contents
1. [Section A — Requirements Traceability Matrix (RTM)](#section-a--requirements-traceability-matrix-rtm)
2. [Section B — Business Rules Register + Conditions Catalog + Validation Catalog](#section-b--business-rules-register--conditions-catalog--validation-catalog)
3. [Section C — Process Flows + FSM Catalog](#section-c--process-flows--fsm-catalog)
4. [Section D — Data Dictionary + Cross-Module Dependency Map](#section-d--data-dictionary--cross-module-dependency-map)
5. [Section E — NFR Catalog + Risk Register](#section-e--nfr-catalog--risk-register)
6. [Section F — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks](#section-f--prioritization-moscow--effort-estimation--sprint-tasks)
7. [Section G — User Stories + Reporting & KPI Spec](#section-g--user-stories--reporting--kpi-spec)
8. [Section H — Requirements-vs-Code Gap Analysis](#section-h--requirements-vs-code-gap-analysis)
9. [Section I — Module Knowledge Update Summary](#section-i--module-knowledge-update-summary)

---

## Section A — Requirements Traceability Matrix (RTM)

### A.1 Master Traceability Table

| REQ-ID | Feature | Priority | Key BRs | Primary Screen(s) | Workflow(s) | Reports | Test Status | Code Status | Gap |
|---|---|---|---|---|---|---|---|---|---|
| REQ-FIN-001 | Fee Head Configuration | P0 | BR-FIN-001, 002, 003, 004 | SCR-FIN-03, SCR-FIN-04 | — | — | Unit (model) only | 95% — CRUD complete | Policy override bug (BUG-FIN-07) |
| REQ-FIN-002 | Fee Group Configuration | P0 | BR-FIN-005, 006, 007 | SCR-FIN-05 | — | — | Unit (model) only | 95% — CRUD complete | None significant |
| REQ-FIN-003 | Fee Structure Definition | P0 | BR-FIN-008, 009, 010, 011 | SCR-FIN-06, SCR-FIN-07 | — | — | Unit (model) only | 90% — CRUD complete | No DDL-level unique for session+class+category |
| REQ-FIN-004 | Installment Schedule Management | P0 | BR-FIN-012, 013, 014 | SCR-FIN-08 | — | — | Unit (model) only | 95% — CRUD complete | None |
| REQ-FIN-005 | Student Fee Assignment | P0 | BR-FIN-015, 016, 017, 018 | SCR-FIN-09, SCR-FIN-10, SCR-FIN-11 | — | — | Unit (model) only | 90% — bulk + individual built | Idempotency on duplicate run unverified in test |
| REQ-FIN-006 | Fee Invoice Generation | P0 | BR-FIN-019–026 | SCR-FIN-12, SCR-FIN-13, SCR-FIN-14, SCR-FIN-15 | WF-1 | RPT-FIN-001 | Unit (model) only | 80% | balance_amount stale (BUG-FIN-05); bulk sync only (GAP-FIN-15) |
| REQ-FIN-007 | Offline Payment Recording | P0 | BR-FIN-027–034 | SCR-FIN-18, SCR-FIN-19 | WF-1 | RPT-FIN-006, 008 | Unit (model) only | 75% | fee-transaction.store wrong controller (BUG-FIN-08); no DB::transaction verified |
| REQ-FIN-008 | Online Payment via Gateway | P1 | BR-FIN-035–039 | Student Portal | — | — | None | 40% | No webhook endpoint; no signature verification (SEC-FIN-04) |
| REQ-FIN-009 | Payment Receipt Management | P0 | BR-FIN-040, 041, 042 | SCR-FIN-20 | WF-1 | RPT-FIN-008 | Unit (model) only | 75% | Receipt not always auto-created; FeeReceiptPolicy missing (GAP-FIN-11) |
| REQ-FIN-010 | Concession Management | P0 | BR-FIN-043–050 | SCR-FIN-16, SCR-FIN-17 | WF-2 | RPT-FIN-004 | Unit (model) only | 75% | Approval notification missing (GAP-FIN-21); FeeConcessionService missing (GAP-FIN-14) |
| REQ-FIN-011 | Scholarship Management | P1 | BR-FIN-051–057 | SCR-FIN-24, SCR-FIN-25, SCR-FIN-26 | WF-3 | RPT-FIN-003 | Unit (model) only | 90% | Renewal evaluation scheduler not built |
| REQ-FIN-012 | Fine Rule Configuration | P0 | BR-FIN-058–062 | SCR-FIN-21, SCR-FIN-22 | — | — | Unit (model) only | 95% — CRUD complete | None |
| REQ-FIN-013 | Automated Fine Application | P0 | BR-FIN-063, 064, 065 | — (scheduled) | WF-4 | RPT-FIN-007 | None | 70% | Scheduler commented out (BUG-FIN-06); no notification on fine applied (GAP-FIN-28) |
| REQ-FIN-014 | Fine Waiver | P1 | BR-FIN-066–069 | SCR-FIN-23 | — | RPT-FIN-007 | Unit (model) only | 90% | Trash view is a redirect not real view (BUG-FIN-18) |
| REQ-FIN-015 | Cheque / DD Clearance | P1 | BR-FIN-070–074 | SCR-FIN-28 (proposed) | WF-5 | RPT-FIN-006 | None | 0% | No controller, no routes (GAP-FIN-10) |
| REQ-FIN-016 | Fee Refund Management | P1 | BR-FIN-075–079 | SCR-FIN-27 (proposed) | — | — | None | 0% | No controller, no routes, no policy (GAP-FIN-09) |
| REQ-FIN-017 | Name Removal and Re-Admission | P1 | BR-FIN-080–083 | SCR-FIN (proposed) | WF-4 | — | None | 50% | Fine task creates records; no UI controller; re-admission unbuilt (GAP-FIN-20) |
| REQ-FIN-018 | Fee Dashboard and Analytics | P0 | BR-FIN-084, 085 | SCR-FIN-01 | — | — | None | 70% | No CSV export; DefaulterHistoryController missing (GAP-FIN-20) |
| REQ-FIN-019 | Fee Reports and Exports | P1 | — | SCR-FIN (proposed) | — | RPT-FIN-001–008 | None | 30% | Most reports lack export/standalone page (GAP-FIN-23) |
| REQ-FIN-020 | Annual Fee Structure Rollover | P2 | BR-FIN-086, 087 | SCR-FIN (proposed) | — | — | None | 0% | Not built (GAP-FIN-26) |

### A.2 Security Compliance Traceability

| Security Requirement | REQ Reference | Status | Gap ID |
|---|---|---|---|
| Seeder route removal | REQ-FIN (all) | NOT DONE | SEC-FIN-01 |
| Faker import removal | REQ-FIN (all) | NOT DONE | SEC-FIN-02 |
| EnsureTenantHasModule middleware | REQ-FIN (all) | NOT DONE | SEC-FIN-03 |
| Razorpay webhook HMAC signature verification | REQ-FIN-008 | NOT DONE | SEC-FIN-04 |
| Gate::authorize in all controllers | REQ-FIN (all) | PARTIAL — hub missing (GAP-FIN-16) | BUG-FIN-07 |
| DB::transaction for financial writes | REQ-FIN-007 | PARTIAL | GAP (inline in some controllers) |

---

## Section B — Business Rules Register + Conditions Catalog + Validation Catalog

### B.1 Business Rules by Category

> Full register is in FRD Section 4 (87 rules). This section groups them by enforcement type for developer handoff.

#### Validation Rules (reject invalid input)

| BR-ID | Rule Summary | Enforcement Point | Entity |
|---|---|---|---|
| BR-FIN-001 | Fee Head code unique and immutable | Fee Head save | Fee Head |
| BR-FIN-005 | Fee Group code unique | Fee Group save | Fee Group |
| BR-FIN-008 | One Fee Structure per session + class + category | Fee Structure save | Fee Structure |
| BR-FIN-011 | Structure effective dates within session dates | Fee Structure save | Fee Structure |
| BR-FIN-013 | Installment number unique within structure | Installment save | Installment |
| BR-FIN-015 | One assignment per student per session | Assignment save | Assignment |
| BR-FIN-017 | Proration 0–100; fee_start_date within session | Assignment mid-year save | Assignment |
| BR-FIN-019 | Invoice number unique (INV-YYYYMM-XXXX) | Invoice create | Invoice |
| BR-FIN-020 | One active invoice per assignment+installment | Invoice create | Invoice |
| BR-FIN-023 | Paid invoice cannot be cancelled | Invoice cancel | Invoice |
| BR-FIN-024 | Cancelled invoice: no payment recording | Transaction store | Transaction |
| BR-FIN-033 | Cheque/DD: reference and bank name mandatory | Transaction store | Transaction |
| BR-FIN-040 | Receipt number unique | Receipt create | Receipt |
| BR-FIN-049 | Concession rejection: reason mandatory | Concession reject | Student Concession |
| BR-FIN-050 | Concession head/group mapping: exactly one non-null | Mapping save (DB constraint) | Concession Applicable Head |
| BR-FIN-053 | Scholarship disburse: available fund ≥ approved | Scholarship disburse | Scholarship |
| BR-FIN-061 | Fine stops at maximum fine amount | Fine task | Fine Record |
| BR-FIN-064 | Fine only if due_date + grace_days < today | Fine task | Fine Record |
| BR-FIN-067 | Partial waiver < fine amount | Waiver store | Fine Waiver |
| BR-FIN-074 | Cleared cheque cannot go to Bounced | Cheque clearance | Cheque Clearance |
| BR-FIN-075 | Refund only for refundable heads | Refund store | Refund |
| BR-FIN-086 | Rollover blocked if structure exists in target session | Rollover action | Fee Structure |

#### Calculation Rules (with formulas)

| BR-ID | Formula | Trigger |
|---|---|---|
| BR-FIN-002 | Tax Amount = Head Amount × Tax% ÷ 100 | Invoice generation |
| BR-FIN-009 | Structure Total = sum of all non-optional head amounts | Structure save |
| BR-FIN-012 | Installment Due Amount = Percentage ÷ 100 × Structure Total | Installment save |
| BR-FIN-021 | Invoice Total = Base − Concession + Fine + Tax | Invoice generation |
| BR-FIN-022 | Outstanding Balance = Total − Paid | Payment recording |
| BR-FIN-044 | Cumulative Concession = sum of approved concession amounts, each capped at its max_cap_amount | Invoice generation |
| BR-FIN-054 | Available Fund = Available Fund − Approved Amount (on disbursement) | Scholarship disburse |
| BR-FIN-058 | Per-Day Fine = fine_value × (days_overdue − grace_days) for days in [applicable_from_day, applicable_to_day] | Fine task |
| BR-FIN-059 | Flat Per Tier Fine = flat_amount applied once when overdue days enters the bracket | Fine task |
| BR-FIN-060 | Percentage-Capped Fine = min(base_amount × fine_pct ÷ 100, max_fine_amount) | Fine task |
| BR-FIN-087 | Rollover Amount = original_amount × (1 + adjustment_pct ÷ 100), rounded to 2 d.p. | Fee Rollover |

#### Workflow/Permission Rules

| BR-ID | Rule Summary | Actors |
|---|---|---|
| BR-FIN-025 | Invoice status transition: Draft→Published→PartiallyPaid→Paid→Overdue→Cancelled | System, Accountant |
| BR-FIN-031 | Financial writes in DB transaction | System (developer constraint) |
| BR-FIN-032 | Successful payment transactions immutable | System (no update/delete) |
| BR-FIN-035 | Razorpay callback: HMAC-SHA256 signature verification | System (webhook handler) |
| BR-FIN-036 | Callback idempotency: no duplicate payment for same payment_id | System (webhook handler) |
| BR-FIN-043 | Pending concession excluded from invoice calculation | System (invoice generator) |
| BR-FIN-063 | Fine task idempotent per invoice + rule + date | System (scheduled task) |
| BR-FIN-071 | Cheque bounce reverses invoice paid amount | System (bounce action) |
| BR-FIN-077 | Processed refund reduces invoice paid amount; transaction → Refunded | System (refund processor) |
| BR-FIN-080 | Name Removal created when escalation rule triggered | System (fine task) |
| BR-FIN-076 | Refund can only be initiated by Accountant or School Admin | Permission gate |

### B.2 Requirement Conditions Catalog

> Also saved at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/FIN_Conditions.md`

| Condition ID | Entity / Field | Condition (Business) | Type | Trigger | On-Violation Behaviour |
|---|---|---|---|---|---|
| BR-FIN-001 | Fee Head / Code | Code must be unique across all fee heads in the school | Validation | Fee Head save | Save rejected with "Code already exists" error |
| BR-FIN-001 | Fee Head / Code | Code is read-only after the fee head is first saved | Validation | Fee Head update | Code field is disabled; direct PUT attempt is rejected |
| BR-FIN-008 | Fee Structure / Session+Class+Category | Only one Fee Structure per session+class+category combination | Validation | Fee Structure save | Save rejected with "Structure already exists for this combination" |
| BR-FIN-011 | Fee Structure / Effective Dates | Effective date range must fall within the academic session start and end dates | Validation | Fee Structure save | Save rejected with date validation error |
| BR-FIN-010 | Fee Structure / Delete | Cannot delete a structure with active student assignments | Validation | Fee Structure delete | Delete rejected with "Active assignments exist for this structure" |
| BR-FIN-015 | Student Fee Assignment / Student+Session | One active assignment per student per session | Validation | Assignment create | Save rejected; existing assignment reference shown |
| BR-FIN-017 | Assignment / Proration | Proration percentage must be between 0 and 100 inclusive | Validation | Assignment create | Save rejected: "Proration must be 0–100" |
| BR-FIN-017 | Assignment / Fee Start Date | Fee start date must fall within the session start and end dates | Validation | Assignment create | Save rejected: "Fee start date outside academic session range" |
| BR-FIN-019 | Invoice / Invoice Number | Invoice number must be unique; format INV-YYYYMM-XXXX | Validation | Invoice create | System generates unique number; collision triggers re-generation |
| BR-FIN-020 | Invoice / Assignment+Installment | One active invoice per student assignment per installment | Validation | Invoice create | Save rejected: "Invoice already exists for this installment" |
| BR-FIN-023 | Invoice / Cancel | Cannot cancel a Paid invoice | Workflow | Cancel action | Cancel rejected: "Invoice is already paid and cannot be cancelled" |
| BR-FIN-024 | Invoice / Payment | Cannot record payment against a Cancelled invoice | Workflow | Transaction store | Save rejected: "Invoice is cancelled" |
| BR-FIN-027 | Transaction / Amount | Amount must be greater than zero | Validation | Transaction store | Save rejected: "Amount must be greater than zero" |
| BR-FIN-029 | Transaction / Overpayment | Payment exceeding outstanding balance recorded as advance credit | Workflow | Transaction store | Overpayment flag set; advance credit recorded on student account |
| BR-FIN-033 | Transaction / Cheque Reference | Reference number and bank name mandatory for Cheque and DD | Validation | Transaction store | Save rejected: "Reference and bank name are required for Cheque/DD" |
| BR-FIN-035 | Webhook / Razorpay Signature | X-Razorpay-Signature header must validate against HMAC-SHA256 of payload | Security | Webhook receipt | 400 response; no database change |
| BR-FIN-036 | Webhook / Idempotency | Payment ID must not already exist in payment gateway logs | Concurrency | Webhook receipt | 200 response (acknowledged) with no database change |
| BR-FIN-040 | Receipt / Receipt Number | Receipt number must be unique across all receipts in the school | Validation | Receipt create | System generates unique number |
| BR-FIN-043 | Concession / Approval Status | Pending concession not included in invoice concession amount | Workflow | Invoice generation | Concession excluded until status = Approved |
| BR-FIN-048 | Concession / Notification | Notification to approver sent on submission if requires_approval = true | Notification | Concession store | Warning logged if no active user holds the approver role |
| BR-FIN-049 | Concession / Rejection Reason | Rejection reason is mandatory | Validation | Concession reject | Reject action blocked: "Rejection reason is required" |
| BR-FIN-051 | Scholarship Application / Uniqueness | One application per student + scholarship fund + session | Validation | Application create | Save rejected: "You have already applied to this scholarship for this session" |
| BR-FIN-052 | Scholarship Application / Date | Applications blocked after scholarship application_end_date | Validation | Application create | Save rejected: "Applications for this scholarship are closed" |
| BR-FIN-053 | Scholarship / Fund Balance | Disbursement blocked when available fund < approved amount | Validation | Disbursement action | Action rejected: "Insufficient funds in scholarship pool" |
| BR-FIN-058 | Fine / Per-Day Calculation | Fine = fine_value × days after grace period, within applicable day range | Calculation | Fine task | Fine record created with computed amount |
| BR-FIN-061 | Fine / Maximum Cap | Fine amount stops accumulating when max_fine_amount is reached | Validation | Fine task | Fine record created for remaining allowable amount only |
| BR-FIN-063 | Fine / Idempotency | Fine task must not create duplicate records for same invoice + rule + date | Concurrency | Fine task execution | Existence check passes; insert skipped |
| BR-FIN-067 | Fine Waiver / Partial Amount | Partial waiver amount must be positive and less than the fine amount | Validation | Waiver store | Save rejected: "Partial waiver amount must be less than fine amount" |
| BR-FIN-068 | Fine Waiver / Immutability | Waiver cannot be reversed once saved | Validation | Waiver update | Update action rejected |
| BR-FIN-074 | Cheque Clearance / State Guard | Cleared cheque cannot be marked as Bounced | Workflow | Bounce action | Action rejected: "Cheque is already cleared" |
| BR-FIN-075 | Refund / Refundable Head | Refund only for fee heads where is_refundable = true | Validation | Refund store | Save rejected: "This fee head is not refundable" |
| BR-FIN-076 | Refund / Permission | Only Accountant or School Admin can initiate a refund | Permission | Refund store | 403 Forbidden |
| BR-FIN-083 | Invoice Generation / Name Removal | Student with active name removal cannot have new invoices | Validation | Invoice generate | Invoice creation blocked; admin prompted to record re-admission |
| BR-FIN-086 | Fee Rollover / Uniqueness | Rollover skips classes that already have a structure in the target session | Workflow | Rollover action | Skipped with informational message; other classes continue |

### B.3 Validation and Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty / Null | Concurrency Case | Expected Behaviour |
|---|---|---|---|---|---|---|
| Fee Head Code | "TUITION" (max 30 chars) | "TUITION" (duplicate) | 30 characters exactly | Empty string | Two users creating same code simultaneously | Second save rejected; unique constraint error returned |
| Tax Percentage | 18 (GST 18%) | -5 or 101 | 0 and 100 | Null when tax_applicable = false | — | 0 accepted (zero tax); null allowed when tax off |
| Proration Percentage | 75 | 150 | 0 (new joiner, no fee) and 100 (full fee) | Null when not mid-year | — | 0 produces zero fee for mid-year join |
| Invoice Total = Base − Concession + Fine + Tax | Base=10000, Concession=500, Fine=100, Tax=180 → Total=9780 | Negative total from excess concession | Concession = Base (zero total) | Fine = null treated as 0 | — | Negative total blocked; concession cap prevents under-zero |
| Payment Amount | 500 (partial of 10000) | 0 | 0.01 (minimum) | Null / 0 | Two payments simultaneously against same invoice | DB transaction ensures only one succeeds; second fails with balance mismatch |
| Cheque Reference | "CHQ-2026-001234" | Empty for Cheque mode | 1 character | Null when mode = Cash | — | Empty rejected if mode = Cheque or DD |
| Razorpay Signature | Valid HMAC-SHA256 signature | Truncated or forged signature | Empty string | Missing header | Replayed request with valid signature | Missing/invalid → 400; replayed → 200 with no change |
| Fine Amount (Per-Day) | 5 days × Rs.10 = Rs.50 | Negative days | 1 day overdue (min) | Invoice not yet overdue → 0 | Fine task runs twice on same day | Second run: no insert (idempotency guard passes) |
| Scholarship Disbursement | Available=5000, Approved=3000 → OK | Available=2000, Approved=3000 | Available = Approved (exact) | — | Two disbursements simultaneously depleting fund | DB transaction; second disbursement blocked on balance check |
| RTE Zero-Amount Invoice | Total = 0.00 | — | 0.00 exactly | Base=0, concession=0 | — | Invoice created successfully; "Paid" immediately |
| Concession on Cancelled Invoice | — | Apply concession to a cancelled invoice | — | — | — | Concession application rejected: invoice is cancelled |
| Refund on Non-Refundable Head | — | Refund for Tuition with is_refundable=false | — | — | — | Refund store rejected: "Head is not refundable" |

---

## Section C — Process Flows + FSM Catalog

### C.1 Process Flows

> Full workflow narratives are in FRD Section 6 (5 workflows). Below is the developer-readable summary.

#### C.1.1 Annual Fee Setup Process (Admin, start of session)
```
School Admin
  1. Define / review Fee Heads (REQ-FIN-001)
  2. Group heads into Fee Groups (REQ-FIN-002)
  3. Create Fee Structure per Class + Session + Category (REQ-FIN-003)
  4. Define Installment Schedule per Structure (REQ-FIN-004)
  5. Bulk-assign Fee Structure to all students in each class (REQ-FIN-005)
  ── [Session is now ready for billing] ──
```

#### C.1.2 Billing Cycle Process (per installment due date)
```
Accountant / School Admin
  1. Run Bulk Invoice Generation for installment (REQ-FIN-006)
  2. Publish invoices → Student Portal + email notification
  3. [ApplyFines scheduled nightly after due_date + grace_days] (REQ-FIN-013)
  4. Collect offline payments as they arrive (REQ-FIN-007)
  5. OR students pay online via Student Portal (REQ-FIN-008)
  6. Generate receipts automatically (REQ-FIN-009)
  7. For cheque/DD: track clearance lifecycle (REQ-FIN-015)
  ── [Dashboard updated in real time] ──
```

#### C.1.3 Concession and Scholarship Processing
```
Staff applies concession (REQ-FIN-010) → needs approval? → notify approver → approve → included in next invoice
Staff creates scholarship application (REQ-FIN-011) → admin reviews → approves → disburse → credit to assignment
```

### C.2 FSM Catalog

#### C.2.1 Fee Invoice Status FSM

| From State | Event / Action | Guard (Condition) | To State | Side-Effects |
|---|---|---|---|---|
| — | Invoice created (bulk or individual) | Assignment and installment valid | Draft | Invoice number auto-generated |
| Draft | Publish / bulk generate | Invoice total > 0 (or = 0 for RTE) | Published | Notification to student/parent |
| Published | First payment recorded | 0 < paid < total | Partially Paid | Receipt created; paid_amount updated |
| Published | Full payment recorded | paid ≥ total | Paid | Receipt created; FeePaymentReceived event emitted |
| Partially Paid | Remaining balance paid | paid ≥ total | Paid | Receipt created; FeePaymentReceived event emitted |
| Published | ApplyFines task, due_date + grace < today | Invoice not Paid or Cancelled | Overdue | Fine record created; parent notified |
| Partially Paid | ApplyFines task, due_date + grace < today | Invoice not Paid or Cancelled | Overdue | Fine record created on outstanding balance |
| Overdue | Further payment recorded | 0 < new total paid < total | Partially Paid | Receipt created; paid_amount updated |
| Overdue | Full payment recorded | paid ≥ total | Paid | Receipt created; FeePaymentReceived event emitted |
| Published | Admin cancel | Invoice not Paid | Cancelled | Cancellation reason + cancelled_by stored |
| Partially Paid | Admin cancel | Invoice not Paid | Cancelled | Cancellation reason + cancelled_by stored |
| Overdue | Admin cancel | Invoice not Paid | Cancelled | Cancellation reason + cancelled_by stored |

**Terminal States:** Paid, Cancelled
**Illegal Transitions (must be blocked):** Paid → any; Cancelled → any; Overdue → Draft or Published

#### C.2.2 Concession Application Status FSM

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| — | Concession applied | requires_approval = false | Applied | Included in next invoice generation |
| — | Concession submitted | requires_approval = true | Pending | Notification to approver |
| Pending | Approver approves | User holds approver role | Approved | Included in next invoice; notification to submitter |
| Pending | Approver rejects | Rejection reason entered | Rejected | Rejection reason stored; notification to submitter |
| Approved | (no further transitions) | — | Approved | — |
| Rejected | (no further transitions — must create new concession) | — | Rejected | — |

**Terminal States:** Applied, Approved, Rejected

#### C.2.3 Scholarship Application Status FSM

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| — | Application created | application_end_date not passed | Draft | — |
| Draft | Student/Staff submits | — | Submitted | — |
| Submitted | Admin marks Under Review | — | Under Review | History record created |
| Under Review | Approver approves | — | Approved | Approved amount stored; history record |
| Under Review | Approver rejects | — | Rejected | History record created |
| Under Review | Approver waitlists | — | Waitlisted | History record created |
| Approved | Admin disburses | available_fund ≥ approved_amount | Approved (disbursed=1) | Fund balance decremented; credit applied; disbursed_date set |

**Terminal States:** Rejected, Disbursed (Approved with disbursed=1)

#### C.2.4 Cheque Clearance Record Status FSM

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| — | Cheque payment recorded | Payment mode = Cheque or DD | Pending Deposit | Clearance record auto-created |
| Pending Deposit | Accountant marks deposited | — | Deposited | deposit_date set |
| Deposited | Bank clears cheque | — | Cleared | clearance_date set |
| Deposited | Bank returns cheque (bounce) | — | Bounced | Invoice paid_amount reversed; bounce charge fine; parent notified |
| Bounced | Resubmission recorded | — | Resubmitted | resubmit_date set → re-enters Deposited flow |

**Terminal State:** Cleared, (Bounced without resubmission)
**Illegal Transition:** Cleared → Bounced (blocked by guard)

#### C.2.5 Fee Refund Status FSM

| From State | Event / Action | Guard | To State | Side-Effects |
|---|---|---|---|---|
| — | Refund initiated | Accountant or Admin; head is_refundable | Pending | refund_no auto-generated |
| Pending | Approved | Approver action | Approved | approved_by, approved_at stored |
| Pending | Rejected | Approver rejects | Rejected | Rejection reason stored |
| Approved | Processed | — | Processed | Invoice paid_amount reduced; transaction → Refunded; FeeRefundProcessed event; Razorpay call if online |

**Terminal States:** Rejected, Processed
**Illegal Transition:** Processed → any

---

## Section D — Data Dictionary + Cross-Module Dependency Map

### D.1 Data Dictionary — Business View

| Business Entity | Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---|---|---|---|---|---|---|
| **Fee Head** | Head Name | Display name of the fee component | Text (100) | Yes | Free text | No |
| Fee Head | Short Code | Unique identifier code for the head | Text (30) | Yes | Uppercase letters and numbers; unique | No |
| Fee Head | Classification Type | Category grouping for the head | Dropdown | Yes | Tuition, Admission, Development, Examination, Laboratory, Library, Transport, Sports, Activity, Hostel | No |
| Fee Head | Billing Frequency | How often this fee repeats | Dropdown | Yes | One-time, Monthly, Quarterly, Half-Yearly, Yearly | No |
| Fee Head | Tax Applicable | Whether GST applies to this head | Yes/No | No | True or False | No |
| Fee Head | Tax Rate | GST percentage to apply | Decimal (2 d.p.) | If tax applicable | 0, 5, 12, 18 (standard GST slabs) | No |
| Fee Head | Is Refundable | Whether amounts paid under this head can be refunded | Yes/No | No | True or False | No |
| Fee Head | Account Code | Ledger code for mapping to the Accounting module | Text (50) | No | Must match a ledger in the school's Chart of Accounts | No |
| **Fee Structure** | Structure Name | Descriptive label for the template | Text (100) | Yes | Free text | No |
| Fee Structure | Structure Code | Short unique identifier | Text (50) | Yes | Unique | No |
| Fee Structure | Academic Session | The school year this structure applies to | Reference | Yes | Active sessions from SchoolSetup | No |
| Fee Structure | Class | The class this structure covers | Reference | Yes | Classes from SchoolSetup | No |
| Fee Structure | Student Category | Optional category variant (General, OBC, SC/ST) | Dropdown | No | Configured in system dropdowns | No |
| Fee Structure | Total Fee Amount | Computed sum of all mandatory head amounts | Currency (₹) | Auto-computed | ≥ 0 | No |
| **Installment Schedule** | Installment Name | Label for the installment (e.g., "Term 1") | Text (100) | Yes | Free text | No |
| Installment Schedule | Due Date | Date by which payment is expected | Date | Yes | Within the academic session range | No |
| Installment Schedule | Percentage Due | Portion of the annual fee for this installment | Decimal (%) | Yes | 0–100; all installments should sum to 100 | No |
| Installment Schedule | Grace Days | Days after due date before a fine applies | Integer | No | ≥ 0 (default 0) | No |
| **Student Fee Assignment** | Student | The student being assigned the fee | Reference | Yes | Active students from StudentProfile | Internal |
| Student Fee Assignment | Fee Structure | The structure this student follows | Reference | Yes | Active structures for the class+session | No |
| Student Fee Assignment | Mid-Year Joiner | Whether the student joined after session start | Yes/No | No | True or False | No |
| Student Fee Assignment | Proration Percentage | Proportion of annual fee to charge for a mid-year joiner | Decimal (%) | If mid-year | 0–100 | No |
| **Fee Invoice** | Invoice Number | Unique system-generated billing reference | Text | Auto | INV-YYYYMM-XXXX format | No |
| Fee Invoice | Base Amount | Installment amount before adjustments | Currency (₹) | Yes | ≥ 0 (0 for RTE) | No |
| Fee Invoice | Concession Amount | Total approved discounts applied | Currency (₹) | Auto | ≥ 0 | No |
| Fee Invoice | Fine Amount | Late-payment penalties accumulated | Currency (₹) | Auto | ≥ 0 | No |
| Fee Invoice | Tax Amount | GST computed on taxable heads | Currency (₹) | Auto | ≥ 0 | No |
| Fee Invoice | Total Amount | Final amount billed (base − concession + fine + tax) | Currency (₹) | Auto | ≥ 0 | No |
| Fee Invoice | Paid Amount | Cumulative payments received against this invoice | Currency (₹) | Auto | 0 to ≥ total | No |
| Fee Invoice | Outstanding Balance | Amount still owed (total − paid) | Currency (₹) | Auto-derived | ≥ 0 | No |
| Fee Invoice | Invoice Status | Current lifecycle stage | Dropdown | Auto | Draft, Published, Partially Paid, Paid, Overdue, Cancelled | No |
| **Payment Transaction** | Payment Mode | How the payment was made | Dropdown | Yes | Cash, Cheque, Demand Draft, UPI, Credit Card, Debit Card, Net Banking, Wallet | No |
| Payment Transaction | Amount | Payment amount | Currency (₹) | Yes | > 0 | No |
| Payment Transaction | Reference Number | Cheque number, UPI UTR, or card last-4 | Text (100) | Conditional | Mandatory for Cheque and DD | No |
| Payment Transaction | Collection Date | Date the payment was physically collected | Date | Yes | ≤ today | No |
| Payment Transaction | Collected By | Staff member who accepted the payment | Reference | Yes | Active users from SchoolSetup | No |
| **Fine Record** | Fine Amount | Penalty amount applied | Currency (₹) | Auto | > 0 | No |
| Fine Record | Days Late | Number of days past the due date when fine was applied | Integer | Auto | ≥ 1 | No |
| Fine Record | Waived | Whether this fine has been waived | Yes/No | No | True or False | No |
| Fine Record | Waived Amount | Amount waived (null = full waiver) | Currency (₹) | Conditional | 0 < waived ≤ fine amount; null = full waiver | No |
| **Concession Type** | Discount Type | Whether the discount is a percentage or fixed amount | Dropdown | Yes | Percentage, Fixed Amount | No |
| Concession Type | Discount Value | The percentage or amount to discount | Decimal | Yes | > 0 | No |
| Concession Type | Maximum Cap | Upper limit of the discount in Rupees | Currency (₹) | No | ≥ 0 (0 = uncapped) | No |
| Concession Type | Requires Approval | Whether this concession needs Principal/Admin approval | Yes/No | Yes | True or False | No |
| **Scholarship Fund** | Total Fund Amount | Total monetary value committed to the scholarship | Currency (₹) | Yes | > 0 | No |
| Scholarship Fund | Available Balance | Remaining undisbursed fund amount | Currency (₹) | Auto | 0 to Total Fund Amount | No |
| Scholarship Fund | Maximum Per Student | Cap on how much one student can receive | Currency (₹) | No | ≥ 0 | No |
| **Payment Gateway Log** | Gateway | The payment service used | Dropdown | Yes | Razorpay, Paytm, CCAvenue, BillDesk, Other | No |
| Payment Gateway Log | Transaction Reference | Gateway's unique transaction identifier | Text | Yes | Gateway-assigned | Sensitive |
| Payment Gateway Log | Request Payload | Full request sent to the gateway | JSON | Auto | — | Sensitive |
| Payment Gateway Log | Response Payload | Full response received from the gateway | JSON | Auto | — | Sensitive |

### D.2 Cross-Module Dependency Map

#### D.2.1 Inbound Dependencies (StudentFee reads from these modules)

| Source Module | Code | Data / Service Used | Purpose |
|---|---|---|---|
| StudentProfile | STD | Student roster, guardian list, fee-payer flag, class-section membership | Identify students for fee assignment; link guardian as payment receiver |
| SchoolSetup | SCH | Academic sessions, classes, sections, academic session date range | Scope fee structures and installments to the correct year and class |
| SystemConfig | SYS | System users (for collected_by field), RBAC roles, dropdown values (fee head types, concession categories, student categories) | Role-based access control; configurable dropdown options |
| Payment | PAY | Razorpay gateway (order creation, payment capture, refund API) | Online fee collection through the Student Portal |
| Transport | TPT | Transport fee assignment flag on a student | P3 planned: auto-assign transport fee head to transport students |

#### D.2.2 Outbound Dependencies (StudentFee feeds these modules)

| Target Module | Code | Mechanism | What StudentFee Provides |
|---|---|---|---|
| Accounting | ACC | Laravel Event `FeePaymentReceived` (D21 contract — not yet implemented) | Triggers creation of a Receipt Voucher in the double-entry ledger with head-wise breakdown using account_head_code |
| Accounting | ACC | Laravel Event `FeeRefundProcessed` (D21 contract — not yet implemented) | Triggers creation of a reversal Payment Voucher for approved refunds |
| Notification | NTF | Laravel Events for invoice generated, payment received, fine applied, concession approval, due-date reminder | Dispatches SMS, email, and WhatsApp notifications to students and parents |
| Student Portal | STP | Read API endpoints (`/api/v1/student-fee/*` — partially implemented) | Invoice list, payment initiation, receipt download for students |
| Parent Portal | PPT | Read API endpoints (planned) | Same as Student Portal for parents viewing their child's invoices |
| Predictive Analytics | PAN | `fee_defaulter_history.defaulter_score` field | AI risk score for defaulter prediction and early intervention |

#### D.2.3 D21 Event Contract (Defined in V2 Section 9.6 — Not Yet Implemented in Code)

| Event Name | Direction | Emitter | Consumer | Payload Key Fields |
|---|---|---|---|---|
| `FeePaymentReceived` | FIN → ACC | FeeTransactionController@store (after DB commit) | ACC: CreateReceiptVoucher listener | transaction_id, invoice_id, student_id, amount, payment_mode, head_breakdown[{head_id, account_head_code, amount}] |
| `FeeRefundProcessed` | FIN → ACC | FeeRefundController@process (not yet built) | ACC: CreateRefundVoucher listener | refund_id, original_transaction_id, student_id, amount, payment_mode |
| `FeeFineApplied` | FIN → NTF | ApplyFines command (fine task) | NTF: NotifyFineApplied listener | student_id, invoice_id, fine_amount, guardian contacts |
| `FeeInvoiceGenerated` | FIN → NTF | FeeInvoiceController@generateFeeInvoice | NTF: NotifyInvoiceGenerated listener | invoice_id, student_id, total_amount, due_date |
| `FeeDueReminder` | FIN → NTF | Scheduler (3 days before due_date — not yet built) | NTF: NotifyDueReminder listener | installment_id, due_date, affected_student_ids |

**Implementation Contract Requirements:**
1. `fee_head_master.account_head_code` must be populated for every head in an active structure before `FeePaymentReceived` is emitted.
2. If the Accounting listener fails, the fee transaction must NOT be rolled back — use a separate retry queue with dead-letter handling.
3. The event must carry the full head breakdown array so Accounting can post head-wise journal entries.

---

## Section E — NFR Catalog + Risk Register

### E.1 NFR Catalog

| NFR-ID | Category | Requirement | Acceptance Threshold |
|---|---|---|---|
| NFR-FIN-P-01 | Performance | Bulk invoice generation for ≤ 100 students completes synchronously | ≤ 30 seconds |
| NFR-FIN-P-02 | Performance | Fee dashboard aggregates load within target time | ≤ 2 seconds |
| NFR-FIN-P-03 | Performance | Single invoice PDF generation | ≤ 3 seconds |
| NFR-FIN-P-04 | Performance | Fee head / structure lookup response time | ≤ 500ms |
| NFR-FIN-P-05 | Performance | Master data (heads, structures, concession types) served from cache | 1-hour cache TTL; invalidated on write; 0 repeated DB reads for static config |
| NFR-FIN-S-01 | Security | EnsureTenantHasModule middleware on all StudentFee routes | 403 returned for unlicensed school; verified in integration test |
| NFR-FIN-S-02 | Security | Seeder route removed from production routes | Route does not exist in any environment other than local dev |
| NFR-FIN-S-03 | Security | Gate::authorize in every controller method | No unguarded public-facing method; audited in architecture test |
| NFR-FIN-S-04 | Security | Razorpay webhook HMAC-SHA256 signature verification | Invalid signature → 400; no DB change; verified by test |
| NFR-FIN-S-05 | Security | Webhook route exempt from auth and CSRF | No 419 errors from Razorpay; 401 errors absent |
| NFR-FIN-S-06 | Security | Financial write operations in DB transaction | No partial state on failure; verified in feature test |
| NFR-FIN-S-07 | Security | PDF download endpoints authorization | 403 for user without authorization for the student's records |
| NFR-FIN-S-08 | Security / Audit | All financial operations logged to system activity log | Every write produces an activity log entry; verified by test |
| NFR-FIN-S-09 | Security | Gateway log fields excluded from general exports | Not present in any CSV export; sensitive fields not rendered in non-admin views |
| NFR-FIN-S-10 | Security | Server-side amount for Razorpay order | Client-submitted amount never used; order amount derived from `balance_amount` |
| NFR-FIN-U-01 | Usability | Class-to-section dropdown updates dynamically | Section list refreshes within 500ms of class selection without full page reload |
| NFR-FIN-U-02 | Usability | Bulk generation progress feedback to user | Response shows: X invoices created, Y skipped, Z errors with error detail |
| NFR-FIN-U-03 | Usability | Confirmation step for destructive actions | Invoice cancel and fine waiver: confirmation modal + mandatory reason field |
| NFR-FIN-U-04 | Usability | Zero-state messages on empty lists | Dashboard sections show informational message when data is empty |
| NFR-FIN-U-05 | Usability | RTE zero-amount invoice accepted without error | Total = 0.00 invoices created successfully; no validation error |
| NFR-FIN-C-01 | Compliance | GST slab support: 0%, 5%, 12%, 18% | Tax computed correctly for all four slabs per fee head |
| NFR-FIN-C-02 | Compliance | 80G receipt: school PAN displayed on receipt where applicable | Receipt PDF includes school PAN from school profile |
| NFR-FIN-C-03 | Compliance | RTE quota: zero-fee invoices generated without error | Zero-amount invoices accepted by all billing flows |
| NFR-FIN-SC-01 | Scalability | Fine task designed for concurrent school load | Nightly task processes all overdue invoices across the tenant in one run; idempotent; 0 duplicates |
| NFR-FIN-SC-02 | Scalability | Gateway log archival policy | Logs older than 2 years flagged for archival to cold storage |
| NFR-FIN-A-01 | Availability | ApplyFines scheduled task runs nightly at 00:30 | Missed run detected via monitoring; compensatory run available on demand |

### E.2 Risk Register

| Risk-ID | Risk | Category | Likelihood | Impact | Mitigation | Owner | Early Warning |
|---|---|---|---|---|---|---|---|
| RISK-FIN-001 | Seeder route in production allows authenticated users to create test data | Security | High (route exists now) | Critical | Remove route and controller method immediately (SEC-FIN-01, SEC-FIN-02) | Developer | Any authenticated user accessing `/student-fee/seeder` |
| RISK-FIN-002 | EnsureTenantHasModule missing: unlicensed school can access fee module | Security | High (middleware absent) | High | Add middleware to RouteServiceProvider (SEC-FIN-03) | Developer | School without StudentFee licence successfully accessing fee routes |
| RISK-FIN-003 | Razorpay callback without signature verification enables fake payment injection | Security | Medium (route not yet built; risk on build without fix) | Critical | Implement HMAC-SHA256 verification on first line of webhook handler | Developer | Any payment marked as paid without a valid gateway transaction |
| RISK-FIN-004 | `balance_amount` DB column is stale after every payment | Data Integrity | High (confirmed) | High | Fix: add balance_amount update inside `updatePayment()` OR convert to MySQL GENERATED STORED column via migration | Developer | Any raw SQL query on `fee_invoices.balance_amount` returning incorrect outstanding value |
| RISK-FIN-005 | ApplyFines scheduler commented out — fines never applied automatically | Operations | High (confirmed) | High | Uncomment and verify schedule in provider; add monitoring alert for missed daily run | Developer | Overdue invoices with no fine records despite policy configuration |
| RISK-FIN-006 | `fee-transaction.store` routes to wrong controller — payments may not be recorded correctly | Bug | Medium | High | Fix route to point to `FeeTransactionController` (BUG-FIN-08) | Developer | Payment recording action produces unexpected invoice creation rather than transaction |
| RISK-FIN-007 | FeeHeadMasterPolicy overridden by duplicate Gate registration | Security | High (confirmed) | Medium | Fix duplicate policy registration in StudentFeeServiceProvider (BUG-FIN-07) | Developer | Access control for FeeHeadMaster behaves like StudentFeeManagementPolicy |
| RISK-FIN-008 | Zero feature tests for financial flows — regressions undetected | Quality | High (0 feature tests) | High | Write feature tests for invoice generation, payment recording, fine calculation, scholarship disbursement (P1) | Developer/QA | Regression in financial flow identified only in production |
| RISK-FIN-009 | Refund and Cheque Clearance controllers missing — schools cannot process refunds or manage cheques | Operations | High (confirmed 0% built) | Medium | Implement FeeRefundController and FeeChequeController as P1 sprint items | Developer | Accountant unable to mark cheques as cleared or initiate refunds |
| RISK-FIN-010 | D21 FAC event contract not emitted — Accounting module receives no fee collection hooks | Integration | High (confirmed) | Medium | Create event classes and register listeners; test end-to-end with Accounting module | Developer | Accounting module has no receipt vouchers for fee payments |
| RISK-FIN-011 | Concession approval notification absent — approvers unaware of pending concessions | Operations | High (confirmed absent) | Low | Add notification dispatch in concession store action (GAP-FIN-21) | Developer | Pending concessions accumulate without approver awareness |
| RISK-FIN-012 | Bulk invoice generation synchronous for all school sizes — timeout risk at 100+ students | Performance | Medium (300-student schools common) | Medium | Queue large batches using GenerateFeeInvoicesJob (ENH-FIN-002) | Developer | HTTP timeout errors during bulk generation for large schools |

---

## Section F — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks

### F.1 MoSCoW Prioritization

#### Must Have (Must be resolved before next production deployment)

| Item | Rationale | REQ / Gap Reference |
|---|---|---|
| Remove seeder route and Faker import | P0 security — test data can be injected into production by any authenticated user | SEC-FIN-01, SEC-FIN-02 |
| Add EnsureTenantHasModule middleware | P0 security — unlicensed schools can access fee module | SEC-FIN-03 |
| Fix fee-transaction.store routing bug | P1 bug — payment recording creates invoice instead of transaction | BUG-FIN-08 |
| Fix FeeHeadMasterPolicy override bug | P1 bug — FeeHeadMaster authorization silently uses wrong policy | BUG-FIN-07 |
| Fix balance_amount stale DB column | P1 data integrity — outstanding balance incorrect after payments | BUG-FIN-05 |
| Add Gate::authorize to hub controller | P0 — any authenticated user can access all fee management views | GAP-FIN-16 |
| Uncomment and verify ApplyFines scheduler | P1 — fines never applied automatically in current code | BUG-FIN-06 |

#### Should Have (Current sprint — high business value)

| Item | Rationale | REQ / Gap Reference |
|---|---|---|
| Implement FeeRefundController + routes | Refund lifecycle completely absent; schools cannot process refunds | GAP-FIN-09, REQ-FIN-016 |
| Implement FeeChequeController + routes | Cheque clearance completely absent; schools using cheques have no digital lifecycle management | GAP-FIN-10, REQ-FIN-015 |
| Implement D21 event classes and FAC listener | Accounting module cannot receive fee collection hooks without event implementation | GAP-FIN-13, D21 |
| Add concession approval notification | Pending concessions go unnoticed without notification | GAP-FIN-21 |
| Implement Razorpay webhook handler with signature verification | Online payments cannot complete without a verified callback endpoint | SEC-FIN-04, REQ-FIN-008 |
| Create missing policy files (Refund, Receipt, Reconciliation, DefaulterHistory) | Authorization gap for new controllers | GAP-FIN-11 |
| Write feature tests for core financial flows | Zero feature test coverage is high risk for a financial module | GAP-FIN, REQ-FIN-006, 007, 010 |

#### Could Have (Next sprint)

| Item | Rationale |
|---|---|
| Queue bulk invoice generation for 100+ students | HTTP timeout risk but not yet triggered in current school sizes |
| Implement FeeDefaulterHistoryController | Defaulter analytics records exist but have no UI view |
| Add CSV export for fee collection summary and defaulter list | Reports are available as views; export is a usability improvement |
| Add 1-hour cache for master data (fee heads, structures, concession types) | Performance improvement; not currently causing user-facing issues |
| Fee Structure Rollover | Saves annual admin work; manual recreation currently possible |

#### Won't Have (This release)

| Item | Rationale |
|---|---|
| AI-powered defaulter risk scoring (ENH-FIN-003) | Requires PAN module; lower priority than security and data integrity fixes |
| Dynamic Fee Rule Engine (ENH-FIN-005) | Long-term feature; current manual configuration meets school needs |
| Due-date reminder automated notifications | Notification module integration not complete for scheduled events |
| Transport/Hostel fee auto-integration | Transport and Hostel modules need their own integration review first |

### F.2 Effort Estimation & Sprint Task Breakdown

#### Sprint 1 — Security and Critical Bugs (Est. 3 person-days)

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| T-01 | Remove `Route::get('/seeder', ...)` from `web.php:22` | Backend | 0.25h | None | 1 |
| T-02 | Remove Faker import + `seederFunction()` method from StudentFeeController | Backend | 0.5h | T-01 | 1 |
| T-03 | Add `EnsureTenantHasModule:StudentFee` to RouteServiceProvider middleware array | Backend | 0.5h | None | 1 |
| T-04 | Add `Gate::authorize` to all 8 StudentFeeManagementController hub methods | Backend | 1h | None | 1 |
| T-05 | Fix FeeHeadMasterPolicy override: move StudentFeeManagementPolicy to a virtual model or separate gate definition | Backend | 1h | None | 1 |
| T-06 | Fix `fee-transaction.store` route: change to `FeeTransactionController::store` | Backend | 0.25h | None | 1 |
| T-07 | Fix `fee_invoices.balance_amount`: add `balance_amount` update to `FeeInvoice::updatePayment()` | Backend | 2h | None | 1 |
| T-08 | Uncomment and configure `registerCommandSchedules()` to run `fee:apply-fines` daily at 00:30 | Backend | 0.5h | None | 1 |
| T-09 | Regression test: verify seeder route returns 403/404; EnsureTenantHasModule returns 403 | Testing | 1h | T-01, T-03 | 1 |

#### Sprint 2 — Missing Controllers and Event Integration (Est. 10 person-days)

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| T-10 | Create `FeeRefundController` with index, store, approve, reject, process actions | Backend | 8h | None | 2 |
| T-11 | Create `fee-refund.*` routes in `web.php` | Backend | 1h | T-10 | 2 |
| T-12 | Create `FeeRefundPolicy` with viewAny, create, update, approve permissions | Backend | 1h | None | 2 |
| T-13 | Create `FeeRefundRequest` and `ApproveFeeRefundRequest` FormRequest classes | Backend | 1h | T-10 | 2 |
| T-14 | Create `FeeChequeController` with index, deposit, clear, bounce, resubmit actions | Backend | 6h | None | 2 |
| T-15 | Create `fee-cheque-clearance.*` routes and `FeePaymentReconciliationPolicy` | Backend | 1h | T-14 | 2 |
| T-16 | Create `FeeDefaulterHistoryController` with index and show | Backend | 3h | None | 2 |
| T-17 | Create `FeePaymentReceived` event class and `CreateReceiptVoucher` listener stub in StudentFee | Backend | 3h | None | 2 |
| T-18 | Create `FeeRefundProcessed` event class and `CreateRefundVoucher` listener stub | Backend | 2h | None | 2 |
| T-19 | Register events in `StudentFee/app/Providers/EventServiceProvider.php` | Backend | 1h | T-17, T-18 | 2 |
| T-20 | Coordinate with Accounting module team to implement FAC listener for `FeePaymentReceived` | Integration | 8h | T-17, ACC module | 2 |
| T-21 | Add concession approval notification in `FeeStudentConcessionController::store()` | Backend | 2h | None | 2 |
| T-22 | Implement Razorpay webhook handler in `routes/api.php` with HMAC-SHA256 signature check, CSRF exempt, idempotency guard | Backend | 8h | PAY module | 2 |
| T-23 | Create `FeeReceiptPolicy` and register all 4 missing policies in StudentFeeServiceProvider | Backend | 1h | None | 2 |

#### Sprint 3 — Feature Tests and Quality (Est. 8 person-days)

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| T-24 | Feature test: invoice generation flow (individual and bulk; assert unique invoice_no; idempotency) | Testing | 4h | T-07 | 3 |
| T-25 | Feature test: payment recording (partial, full, overpayment, stale balance_amount fix verified) | Testing | 4h | T-07 | 3 |
| T-26 | Feature test: fine calculation (PerDay, FlatPerTier, Percentage-Capped; idempotency; max cap) | Testing | 4h | T-08 | 3 |
| T-27 | Feature test: concession approval workflow (pending → approved → included in invoice) | Testing | 3h | T-21 | 3 |
| T-28 | Feature test: scholarship disbursement lifecycle (apply → approve → disburse; fund decrement; blocked if insufficient) | Testing | 3h | None | 3 |
| T-29 | Feature test: Razorpay webhook (valid signature → payment recorded; invalid → 400; replay → no duplicate) | Testing | 4h | T-22 | 3 |
| T-30 | Feature test: refund workflow (Pending → Approved → Processed; invoice paid_amount reduced) | Testing | 3h | T-10 | 3 |
| T-31 | Feature test: cheque bounce reversal (invoice paid_amount reduced; bounce charge fine created) | Testing | 3h | T-14 | 3 |

#### Sprint 4 — Performance, UX, and Analytics (Est. 6 person-days)

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| T-32 | Queue bulk invoice generation (> 100 students) via `GenerateFeeInvoicesJob` on `fee-invoice` queue | Backend | 4h | None | 4 |
| T-33 | Add 1-hour cache for fee_head_master, fee_structure_master, fee_concession_types lookups; invalidate on write | Backend | 3h | None | 4 |
| T-34 | Add CSV export for fee collection summary and defaulter list | Backend + Frontend | 4h | None | 4 |
| T-35 | Implement defaulter analytics screen with FeeDefaulterHistoryController@index | Frontend | 3h | T-16 | 4 |
| T-36 | Delete backup view `invoice_27_02_2026.blade.php` from production resources | Frontend | 0.25h | None | 4 |
| T-37 | Fix concession trashed redirect to show actual trash view | Frontend | 1h | None | 4 |

#### Sprint 5 — Backlog (Est. 5 person-days)

| # | Task | Type | Effort (h) | Depends On | Sprint |
|---|---|---|---|---|---|
| T-38 | Implement Annual Fee Structure Rollover (copy structures with optional amount adjustment) | Backend + Frontend | 8h | None | 5 |
| T-39 | Implement scholarship renewal evaluation scheduler (evaluate renewal_criteria at session start) | Backend | 4h | None | 5 |
| T-40 | Implement due-date reminder scheduler (FeeDueReminder event, 3 days before installment due_date) | Backend | 4h | NTF module | 5 |
| T-41 | Implement defaulter risk score recomputation job (nightly, updates defaulter_score in defaulter_history) | Backend | 4h | T-08 (scheduler pattern) | 5 |

**Total Effort Summary:**

| Sprint | Focus | Effort (person-days) |
|---|---|---|
| Sprint 1 | Security + Critical Bugs | 3 |
| Sprint 2 | Missing Controllers + Events | 10 |
| Sprint 3 | Feature Tests + Quality | 8 |
| Sprint 4 | Performance + UX + Analytics | 6 |
| Sprint 5 | Backlog Features | 5 |
| **Total** | | **32 person-days** |

---

## Section G — User Stories + Reporting & KPI Spec

### G.1 User Stories (P0 and P1 REQs)

#### US-FIN-001 | Priority: P0 | REQ ref: REQ-FIN-001
**As a** School Admin, **I want to** define and maintain a catalogue of fee components with their billing frequency, tax rates, and accounting codes, **so that** I can build accurate fee structures without re-entering component details every year.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Creating a new Fee Head
  Given I am logged in as a School Admin
  When I create a Fee Head with code "TUITION", name "Tuition Fee", frequency "Monthly", tax 18%
  Then the Fee Head is saved and appears in the list
  And it is available in fee structure configuration dropdowns

Scenario: Duplicate code rejected
  Given a Fee Head with code "TUITION" already exists
  When I try to create another Fee Head with code "TUITION"
  Then the system rejects the save with "Code already exists"

Scenario: Code immutable after save
  Given a Fee Head with code "TUITION" exists
  When I try to edit its code to "TUITION2"
  Then the code field is read-only and no change is saved

Scenario: Permission denied
  Given I am logged in as an Accountant (no create permission)
  When I navigate to the create Fee Head page
  Then I receive a 403 Forbidden response
```
**Definition of Done:** Fee Head created; code unique; frequency and tax saved correctly; activity log entry created; code field read-only after save; Accountant receives 403 on create attempt.

---

#### US-FIN-002 | Priority: P0 | REQ ref: REQ-FIN-005
**As a** School Admin, **I want to** bulk-assign the fee structure to all students in a class with one action, **so that** I don't need to assign individually for 40+ students.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Bulk assignment creates records for all active students
  Given a Fee Structure exists for Class 10A in the current session
  And Class 10A has 42 active students
  When I run bulk assignment for Class 10A
  Then 42 Student Fee Assignment records are created
  And each record links to the correct Fee Structure

Scenario: Bulk assignment is idempotent
  Given 42 assignments already exist for Class 10A in the current session
  When I run bulk assignment again for Class 10A
  Then no new records are created
  And the response shows "42 students already assigned, 0 created"

Scenario: Mid-year joiner proration
  Given a student joins Class 10A on 1 October (6 months into the 12-month session)
  When I create an individual assignment with proration 50%
  Then the stored total fee amount equals 50% of the structure total
```

---

#### US-FIN-003 | Priority: P0 | REQ ref: REQ-FIN-006
**As an** Accountant, **I want to** generate invoices for all students in the current session for the Term 2 installment, **so that** students and parents receive their billing notification.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Bulk invoice generation
  Given 200 active students have fee assignments for the current session
  When I trigger bulk invoice generation for installment "Term 2"
  Then invoices are created with status Published for all 200 students
  And each invoice has a unique INV-YYYYMM-XXXX number

Scenario: Duplicate prevention
  Given Term 2 invoices already exist for 150 students
  When I trigger bulk invoice generation again for Term 2
  Then only students without existing Term 2 invoices receive new invoices
  And the response shows "50 created, 150 skipped"

Scenario: Zero-amount invoice for RTE student
  Given an RTE student has a fee structure with base amount = 0
  When a Term 1 invoice is generated for this student
  Then the invoice is created successfully with status Published and total = ₹0
```

---

#### US-FIN-004 | Priority: P0 | REQ ref: REQ-FIN-007
**As an** Accountant, **I want to** record a cheque payment received from a parent against their child's invoice, **so that** the invoice balance is updated and a receipt is issued.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Full cheque payment recorded
  Given Student Arjun has an invoice of ₹12,000 (status: Published)
  When I record a cheque payment of ₹12,000 with reference "CHQ-001" and bank "SBI"
  Then the invoice status changes to Paid
  And a receipt with a unique receipt number is generated
  And a Cheque Clearance Record is created in Pending Deposit status

Scenario: Partial payment recorded
  Given the same invoice (₹12,000)
  When I record a cash payment of ₹5,000
  Then the invoice status changes to Partially Paid
  And the outstanding balance is ₹7,000

Scenario: Cheque payment without reference rejected
  Given a cheque payment is being recorded
  When the reference number is left blank
  Then the form returns "Reference number is required for Cheque payments"

Scenario: Payment against cancelled invoice
  Given an invoice with status Cancelled
  When I attempt to record a payment against it
  Then I receive "Invoice is cancelled; payment cannot be recorded"
```

---

#### US-FIN-005 | Priority: P0 | REQ ref: REQ-FIN-010
**As a** School Admin, **I want to** approve a sibling discount concession submitted by the Accountant, **so that** the student's next invoice reflects the discount.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Concession submitted requiring approval
  Given a concession type "Sibling 10%" requires approval
  When the Accountant applies it to a student's fee assignment
  Then the concession status is set to Pending
  And the Principal receives a notification

Scenario: Principal approves concession
  Given a concession with status Pending
  When the Principal approves it
  Then the status changes to Approved
  And the next invoice generated for the student includes the discount in concession_amount

Scenario: Pending concession excluded from invoice
  Given a concession with status Pending
  When an invoice is generated for the student
  Then the invoice's concession_amount does not include the pending concession

Scenario: Rejection requires reason
  When the Principal rejects the concession without entering a reason
  Then the rejection action is blocked with "Rejection reason is required"
```

---

#### US-FIN-006 | Priority: P0 | REQ ref: REQ-FIN-013
**As a** School Admin, **I want** the system to automatically apply late-payment fines each night, **so that** overdue invoices are penalised without manual intervention.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Fine applied to overdue invoice
  Given Invoice INV-202605-0042 is overdue by 5 days (2 days past grace period)
  And the fine rule is PerDay at ₹10/day
  When the nightly ApplyFines task runs
  Then a Fine Record of ₹30 (3 applicable days) is created for the invoice

Scenario: Fine task idempotent
  Given the same overdue invoice as above
  When the ApplyFines task runs again on the same calendar day
  Then no additional Fine Record is created

Scenario: Max fine cap respected
  Given an invoice with a fine rule capped at ₹500
  And cumulative fine already equals ₹480
  When the task runs
  Then only ₹20 is added (bringing total to ₹500 cap; no more fine after that)
```

---

#### US-FIN-007 | Priority: P1 | REQ ref: REQ-FIN-016
**As a** School Admin, **I want to** initiate and approve a refund for a student who is withdrawing mid-year, **so that** refundable fee amounts are returned and the accounting records are updated.

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Refund initiated for refundable head
  Given a student's Tuition Fee head has is_refundable = true
  When the Accountant initiates a refund of ₹5,000 referencing the original transaction
  Then a refund record is created with status Pending

Scenario: Refund for non-refundable head rejected
  Given a Development Fee head has is_refundable = false
  When the Accountant tries to initiate a refund for that head
  Then the system rejects it: "Development Fee is not eligible for refund"

Scenario: Processed refund reduces invoice paid amount
  Given an approved refund of ₹5,000 against an invoice with paid_amount ₹12,000
  When the School Admin processes the refund
  Then the invoice paid_amount becomes ₹7,000 and the original transaction status changes to Refunded
```

---

#### US-FIN-008 | Priority: P1 | REQ ref: REQ-FIN-015
**As an** Accountant, **I want to** mark a deposited cheque as bounced, **so that** the invoice outstanding balance is restored and the parent is notified.**

**Acceptance Criteria (Gherkin):**
```gherkin
Scenario: Cheque bounced — invoice reversed
  Given a cheque payment of ₹12,000 was recorded and marked Deposited
  And the invoice status is Paid
  When the Accountant marks the cheque as Bounced with reason "Insufficient funds"
  Then the invoice paid_amount decreases by ₹12,000 and the invoice returns to Published
  And a bounce charge fine is created
  And the parent receives a notification

Scenario: Cleared cheque cannot be bounced
  Given the same cheque is already marked Cleared
  When the Accountant tries to mark it Bounced
  Then the action is rejected: "Cheque is already cleared"
```

---

### G.2 Reporting & KPI Specification

#### G.2.1 Report Specifications

**RPT-FIN-001: Fee Collection Summary**
- Audience: School Admin, Accountant, Principal
- Columns: Fee Head | Total Students Billed | Total Billed (₹) | Total Collected (₹) | Total Outstanding (₹) | Collection % | Class-wise sub-totals
- Filters: Academic Session (required), Class (optional), Date Range (optional)
- Export: CSV (full data), PDF (summary totals)
- Row-count: One row per fee head per class; summary totals at bottom
- Data rule: Scoped to current tenant and selected session

**RPT-FIN-002: Defaulter List**
- Audience: School Admin, Accountant, Principal
- Columns: Student Name | Admission No. | Class | Section | Invoice No. | Due Date | Overdue Since (days) | Outstanding Amount (₹) | Last Payment Date
- Filters: Academic Session, Class, Section, Overdue Since (date), Minimum Outstanding Amount
- Sort: Outstanding Amount descending (default)
- Export: CSV, PDF
- Data rule: Only invoices with status = Overdue; no Paid or Cancelled

**RPT-FIN-006: Payment Mode-wise Collection**
- Audience: School Admin, Accountant
- Columns: Payment Mode | Count of Transactions | Total Amount (₹) | Pending Clearance (₹) [for Cheque/DD only]
- Filters: Date Range (required), Session
- Export: CSV, PDF
- Data rule: Counts and sums from fee_transactions for the selected date range; "Pending Clearance" = sum of Deposited + Resubmitted cheque amounts

#### G.2.2 KPI Catalog

| KPI | Definition / Formula | Source | Target | Cadence |
|---|---|---|---|---|
| Fee Collection Rate | Total Collected ÷ Total Billed × 100 | fee_invoices (paid_amount, total_amount) | ≥ 95% by session end | Monthly |
| Defaulter Count | Count of students with at least one Overdue invoice | fee_invoices (status = Overdue) | < 5% of enrolled students | Monthly |
| Average Days Late | Mean of days_overdue across all Overdue invoices in session | fee_fine_transactions (days_late) | < 15 days average | Monthly |
| Concession Grant Rate | Total Approved Concession Amount ÷ Total Billed × 100 | fee_student_concessions, fee_invoices | School-defined policy threshold | Annual |
| Scholarship Disbursement Rate | Total Disbursed ÷ Total Fund Available × 100 | fee_scholarships (available_fund, total_fund_amount) | ≥ 80% of fund disbursed by year-end | Annual |
| Online Payment Adoption | Count of online transactions ÷ Total transaction count × 100 | fee_transactions (payment_mode = [Razorpay modes]) | School-specific growth target | Monthly |
| Fine Waiver Rate | Total Waived Amount ÷ Total Fine Amount Applied × 100 | fee_fine_transactions (fine_amount, waived_amount) | < 10% (school policy) | Monthly |

---

## Section H — Requirements-vs-Code Gap Analysis

> This is the BA-side gap analysis (requirement coverage vs. code state). Deep code/security/performance gaps are for the Technical Auditor (Mode X).

| REQ-ID | Requirement | Code Status | Evidence | Gap |
|---|---|---|---|---|
| REQ-FIN-001 | Fee Head Configuration | DONE (95%) | FeeHeadMasterController + FeeHeadMaster model + 36 FormRequests include fee head validation | Policy override bug (BUG-FIN-07) means FeeHeadMasterPolicy silently disabled |
| REQ-FIN-002 | Fee Group Configuration | DONE (95%) | FeeGroupMasterController + junction model complete | None significant |
| REQ-FIN-003 | Fee Structure Definition | DONE (90%) | FeeStructureMasterController + detail model + 24 migrations | No DDL-level unique constraint for session+class+category (app-level only) |
| REQ-FIN-004 | Installment Schedule Management | DONE (95%) | FeeInstallmentController complete | None |
| REQ-FIN-005 | Student Fee Assignment | DONE (90%) | FeeStudentAssignmentController with bulk generate and section AJAX | Idempotency on duplicate bulk run not covered by feature test |
| REQ-FIN-006 | Invoice Generation | PARTIAL (80%) | FeeInvoiceController; PDF; bulk generation | balance_amount stale (BUG-FIN-05); bulk sync for all sizes (GAP-FIN-15); backup view exists (BUG-FIN-19) |
| REQ-FIN-007 | Offline Payment Recording | PARTIAL (75%) | FeeInvoiceController@recordPayment exists but `fee-transaction.store` route points to wrong controller (BUG-FIN-08) | Route bug means payment action may invoke wrong method; receipt auto-creation partially complete; DB::transaction consistency unverified by test |
| REQ-FIN-008 | Online Payment via Gateway | PARTIAL (40%) | FeeInvoice implements Payable contract; FeePaymentGatewayLog model exists | No webhook endpoint; no HMAC signature verification; no CSRF bypass (SEC-FIN-04) |
| REQ-FIN-009 | Payment Receipt Management | PARTIAL (75%) | FeeReceipt model; FeeTransactionController@downloadReceipt | FeeReceiptPolicy missing (GAP-FIN-11); receipt not always auto-generated on every payment path |
| REQ-FIN-010 | Concession Management | PARTIAL (75%) | FeeStudentConcessionController; approval status workflow | Approval notification absent (GAP-FIN-21); FeeConcessionService missing (GAP-FIN-14) |
| REQ-FIN-011 | Scholarship Management | DONE (90%) | FeeScholarshipController + FeeScholarshipApplicationController + FeeScholarshipService; full lifecycle | Renewal evaluation scheduler not built (scholarship.requires_renewal = 1) |
| REQ-FIN-012 | Fine Rule Configuration | DONE (95%) | FeeFineRuleController + FeeFineRule model | None |
| REQ-FIN-013 | Automated Fine Application | PARTIAL (70%) | ApplyFines command + FeeFineService registered | Scheduler commented out (BUG-FIN-06); FeeFineApplied notification event not emitted (GAP-FIN-28); name removal notification absent (GAP-FIN-29) |
| REQ-FIN-014 | Fine Waiver | DONE (90%) | FeeFineTransactionController@waive; waive route; waiver fields | Trash view is redirect not real view (BUG-FIN-18) |
| REQ-FIN-015 | Cheque/DD Clearance | NOT STARTED (0%) | FeePaymentReconciliation model + seeder exist | No controller, no routes (GAP-FIN-10) |
| REQ-FIN-016 | Fee Refund Management | NOT STARTED (0%) | FeeRefund model + seeder exist | No controller, no routes, no policy (GAP-FIN-09) |
| REQ-FIN-017 | Name Removal and Re-Admission | PARTIAL (50%) | ApplyFines creates FeeNameRemovalLog records; FeeNameRemovalLog model exists | No UI controller; re-admission workflow unbuilt; notification absent (GAP-FIN-29) |
| REQ-FIN-018 | Fee Dashboard and Analytics | PARTIAL (70%) | StudentFeeManagementController@dashboard with KPI cards; collection chart; defaulter list | No CSV export; no DefaulterHistoryController; hub methods lack Gate::authorize (GAP-FIN-16) |
| REQ-FIN-019 | Fee Reports and Exports | PARTIAL (30%) | List views exist for defaulters, scholars, concessions in dashboard controller | No standalone report pages; no CSV export implemented (GAP-FIN-23) |
| REQ-FIN-020 | Annual Fee Structure Rollover | NOT STARTED (0%) | No controller, no route, no service method | Complete gap (GAP-FIN-26) |

### H.1 Gap Severity Summary

| Severity | Count | Gap IDs / Notes |
|---|---|---|
| P0 — Security / Production Blockers | 4 | SEC-FIN-01 (seeder route), SEC-FIN-02 (Faker import), SEC-FIN-03 (EnsureTenantHasModule), SEC-FIN-04 (Razorpay signature) |
| P1 — High — Data Integrity / Missing Features | 9 | BUG-FIN-05 (balance_amount), BUG-FIN-06 (scheduler), BUG-FIN-07 (policy override), BUG-FIN-08 (route bug), GAP-FIN-09 (Refund), GAP-FIN-10 (Cheque), GAP-FIN-11 (policy files), GAP-FIN-13 (D21 events), GAP-FIN-16 (hub auth) |
| P2 — Medium — Missing but Workaroundable | 8 | GAP-FIN-14 (concession service), GAP-FIN-15 (bulk queue), GAP-FIN-20 (DefaulterHistoryController), GAP-FIN-21 (concession notification), GAP-FIN-22 (caching), GAP-FIN-23 (CSV export), GAP-FIN-24 (gateway token encryption), GAP-FIN-26 (rollover) |
| P3 — Backlog | 7 | GAP-FIN-27 (feature tests), GAP-FIN-28 (fine notification), GAP-FIN-29 (name removal notification), GAP-FIN-30 (due reminder), GAP-FIN-31 (transport integration), GAP-FIN-32 (api callback), BUG-FIN-19 (backup view) |

**Overall Completion Assessment:** ~78% — 12 of 20 requirements fully or substantially implemented; 4 P0 security gaps must be resolved before next deployment; 2 complete controller gaps (Refund, Cheque Clearance) represent the largest feature-level missing items.

---

## Section I — Module Knowledge Update Summary

Module knowledge file at `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/FIN_StudentFee.md` was seeded on 2026-06-30 with full filesystem verification and contains:

### FRD Summary (as of this Complete Analysis Pack)
- FRD File: `FIN_FRD_2026-06-30.md`
- FRD Date: 2026-06-30
- REQ Count: 20 (P0: 12, P1: 7, P2: 1)
- BR Count: 87
- Workflow Count: 5
- RPT Count: 8
- ENH Count: 5
- Complete Analysis Pack: `FIN_FRD_Complete_2026-06-30.md`

### Pending Next Steps (Updated from this analysis)
1. **P0** (Sprint 1 / This Week): Fix 4 security gaps (SEC-FIN-01 through 04) + 3 critical bugs (BUG-FIN-05, 06, 07, 08) + hub auth (GAP-FIN-16) — see Sprint 1 tasks T-01 through T-09
2. **P1** (Sprint 2 / Next 2 Weeks): Implement FeeRefundController, FeeChequeController, FeeDefaulterHistoryController; create D21 event classes; add concession approval notification; create missing policy files — T-10 through T-23
3. **P1** (Sprint 3): Write feature tests for all 6 core financial flows — T-24 through T-31
4. **P2** (Sprint 4): Queue bulk generation; master data caching; CSV export; defaulter analytics screen — T-32 through T-37
5. **P2/P3** (Sprint 5): Fee rollover; scholarship renewal scheduler; due-date reminder; defaulter risk score job — T-38 through T-41
6. **Technical Audit**: Hand off to Technical Auditor (Mode X) for 12-layer deep audit of the module — the code quality, concurrency, tenancy, and deployment-specific gaps require deeper investigation than this BA gap analysis.

### Version History Update
The module knowledge file (v1.0, 2026-06-30) is current. The FRD and Complete Analysis Pack generated in this session are v1.0. Next update trigger: when any Sprint 1–3 tasks are completed, update the module knowledge `Feature Area Status` table and `Pending Next Steps`.

---

*Complete Analysis Pack Saved: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/FIN_FRD_Complete_2026-06-30.md`*
*Requirement Conditions Catalog also at: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/5-Requirement_Conditions/FIN_Conditions.md`*
*FRD: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/4-Requirement_Module_wise/0-FRD_Documents/FIN_FRD_2026-06-30.md`*
*Module Knowledge: `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/FIN_StudentFee.md`*
