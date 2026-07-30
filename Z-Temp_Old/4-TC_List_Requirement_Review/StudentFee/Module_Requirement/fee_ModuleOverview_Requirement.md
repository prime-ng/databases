# StudentFee Module — Business Requirements Overview

## Module Purpose

The **StudentFee Module** is the financial engine of the Prime Gurukul ERP — it manages the complete fee lifecycle for K-12 schools. From defining fee components (heads, groups, structures) and assigning them to students, through invoice generation and payment collection, to fine computation, scholarship disbursement, refund processing, and governance actions such as name removal for chronic defaulters.

The module encompasses **24 database tables** under the `fee_*` prefix and serves as the authoritative system of record for all student financial transactions. It handles multi-mode payments (Cash, Cheque, DD, UPI, Cards, Net Banking, Wallet), supports configurable installment schedules, tiered late-fee rules, concession/discount workflows, cheque/DD reconciliation lifecycles, scholarship fund management with approval pipelines, and defaulter analytics with risk scoring.

The module is accessed by school administrators, accounts managers, cashiers, principals, and scholarship committee members through a tabbed interface that groups features into logical zones:

- **Dashboard** — Summary KPIs, collection trends, recent transactions, defaulter alerts
- **Configuration** — Fee Heads, Fee Groups, Fee Structures, Installments, Concession Types, Student Concessions
- **Assignment** — Student Fee Assignment (individual and bulk)
- **Billing** — Fee Invoices (generate, manage, cancel, email/WhatsApp/share)
- **Payment** — Fee Transactions, Fee Receipts
- **Fine Management** — Fine Rules, Fine Transactions (with waiver workflow)
- **Scholarship** — Scholarship Definitions, Scholarship Applications (multi-stage approval)
- **Governance** — Name Removal Log (removal and re-admission tracking)
- **Fee Refund** — Refund requests with 4-stage approval workflow
- **Cheque/DD Reconciliation** — Cheque lifecycle (deposit → clear → bounce → resubmit)

---

## Default Data Load

When any tabbed screen loads, the system fetches the **current academic session** via `\Modules\Prime\Models\AcademicSession::current()`. If no active session is found, all data-loading branches return empty/zero defaults.

Each tab loads its own paginated dataset based on the feature area:

| Tab | Controller Method | Key Data Loaded | Pagination |
|-----|-------------------|----------------|------------|
| Dashboard | `dashboard()` | Summary KPIs, recent transactions (5), top defaulter invoices (5), 6-month chart, defaulter/concession/scholarship counts | Limit 5 |
| Configuration | `configuration()` | Fee Heads, Fee Groups (with heads), Fee Structures (with details), Installments, Concession Types, Student Concessions | 10 per section (named pages) |
| Assignment | `assignment()` | Student Assignments with student/class/section/structure relations, searchable by admission no/name, filterable by status | 12 |
| Billing | `billing()` | Fee Invoices with student/installment relations, searchable by invoice no/student name, filterable by status | 15 |
| Payment | `payment()` | Transactions with student/invoice/collector relations, searchable, filterable by mode/status; Receipts listing | 15 each (named pages) |
| Fine Management | `fineManagement()` | Fine rules (paginated), Fine transactions with student/invoice/rule relations, searchable, waiver filter | 10 rules, 15 transactions |
| Scholarship | `scholarship()` | Scholarships (with application counts), Applications (with scholarship/student relations), Approval histories | 15 each (named pages) |
| Governance | `governance()` | Name Removal Logs with student/session/remover relations, searchable, readmission status filter | 15 |
| Fee Refund | (dedicated resource controller) | Refund records with transaction/student relations, approval workflow | 15 |
| Cheque/DD Reconciliation | (dedicated resource controller) | Payment Reconciliation records with cheque lifecycle status | 15 |

---

## Dashboard — Fee Management Overview

The dashboard is the landing page of the StudentFee module. It aggregates key financial metrics for the current academic session:

- **Summary Cards**: Total Fee Amount (sum of assignment totals), Total Fee Collected (sum of successful transactions), Total Fee Outstanding (fee amount − collected), Total Students Count (enrolled in session), Defaulter Count (overdue invoices), Scholarship Students (approved applications), Concession Students (approved concessions)
- **Charts**: Last 6 months monthly collection trend (bar/line)
- **Tables**: Recent 5 transactions (payment_date descending), Top 5 defaulter invoices (by balance_amount descending)

**Route:** `GET /student-fee/dashboard` — `StudentFeeManagementController.dashboard()`

For the detailed class-section fee collection view:

**Route:** `GET /student-fee/dashboard/fee-collection-details` — `StudentFeeManagementController.dashboardFeeCollection()`

---

## Configuration — Fee Heads

Fee Heads define the fundamental fee components (Tuition, Transport, Hostel, Library, Sports, Examination, Laboratory, Activity, Development, Other). Each head carries:

- A unique alphabetic code (TUIT, TRAN, HOST, LIBR, SPRT, EXAM, LAB, ACTV, DEVL, OTH)
- A head type (FK to `sys_dropdown_table` — 10 predefined types)
- Frequency (One-time, Monthly, Quarterly, Half-Yearly, Yearly)
- Tax configuration (applicable flag, tax percentage — 18% for taxable heads)
- Refundable flag, account head code for ERP integration, display order
- Soft-delete support with restore and force-delete endpoints

**Routes:** `GET|POST /student-fee/fee-head-master` — `FeeHeadMasterController` (full resource + trash/restore/toggle-status)

---

## Configuration — Fee Groups

Fee Groups bundle fee heads into logical packages (Academic Package, Transport Package, Hostel Package, Activity Package). Key attributes:

- Mandatory flag — students must take this group (`is_mandatory = 1`)
- Junction table `fee_group_heads_jnt` maps heads to groups with `is_optional` flag per head and default amount
- Display order controls rendering sequence

**Routes:** `GET|POST /student-fee/fee-group-master` — `FeeGroupMasterController` (full resource + trash/restore/toggle-status)

---

## Configuration — Fee Structure Master

Fee Structures define the actual fee amount per class + academic session + student category (General/OBC/SC/ST) + board type (CBSE/ICSE/State). Key aspects:

- Links to `sch_org_academic_sessions_jnt` (SMALLINT UNSIGNED FK), `sch_classes`, and `sys_dropdown_table` (student category)
- `fee_structure_details` holds head-wise amounts with optional flag and tax-included flag
- `total_fee_amount` is a pre-calculated sum of detail line items
- Effective dating (`effective_from`/`effective_to`) supports timed fee revisions
- Unique code assigned per structure

**Routes:** `GET|POST /student-fee/fee-structure-master` — `FeeStructureMasterController` (full resource + trash/restore/toggle-status)

---

## Configuration — Fee Installments

Installments define the payment schedule for a fee structure (typically quarterly at 25% each):

- `installment_no`, `installment_name`, `due_date`, `percentage_due`, `amount_due`
- `grace_days` before fine calculation begins
- FK to `fee_structure_master` with CASCADE delete
- Unique constraint on `(fee_structure_id, installment_no)`

**Routes:** `GET|POST /student-fee/fee-installment` — `FeeInstallmentController` (full resource + trash/restore/toggle-status)

---

## Configuration — Fee Concession Types

Concession Types are discount templates (Sibling Concession, Merit Scholarship, Staff Ward, Financial Aid, Sports Quota, Alumni, Other):

- Discount type: Percentage or Fixed Amount
- Applicable on: Total Fee, Specific Heads, or Specific Groups
- `fee_concession_applicable_heads` junction maps concessions to heads or groups (mutually exclusive via CHECK constraint)
- Approval workflow with configurable `approval_level_role_id`
- Max cap amount for percentage-based concessions

**Routes:** `GET|POST /student-fee/fee-concession-type` — `FeeConcessionTypeController` (full resource + trash/restore/toggle-status)

---

## Configuration — Fee Student Concession

Applying a concession type to a specific student's fee assignment:

- Links `fee_student_assignments` to `fee_concession_types`
- Status workflow: Pending → Approved/Rejected (with rejection reason)
- `discount_amount` is the calculated amount after applying the concession rule
- Approval tracked by `approved_by` (FK to `sys_users`) and `approved_at` timestamp

**Routes:** `GET|POST /student-fee/fee-student-concession` — `FeeStudentConcessionController` (resource + trash)

---

## Assignment — Fee Student Assignment

Assigns a fee structure to individual students for an academic session:

- Supports both individual assignment (via resource controller) and bulk generation (`generateStudentAssignment`)
- Denormalized `class_id` and `section_id` for quick access — avoids joins during fee calculation and invoice generation
- `opted_heads` and `opted_groups` as JSON columns for optional head/group selections
- Mid-year join support with `join_in_mid-year`, `fee_start_date`, `proration_percentage`
- Unique constraint on `(student_id, academic_session_id)` — one assignment per student per session
- Searchable by admission number, student name; filterable by active/inactive status

**Routes:** `GET|POST /student-fee/fee-student-assignment` — `FeeStudentAssignmentController` (full resource + generate/trash/restore/toggle-status/update-structure)

---

## Billing — Fee Invoices

Invoices are the billing documents generated from student assignments and installment schedules:

- Six-status lifecycle: Draft → Published → Partially Paid → Paid → Overdue → Cancelled
- `base_amount`, `concession_amount`, `fine_amount`, `tax_amount`, `total_amount`
- `balance_amount` is a MySQL GENERATED ALWAYS column (`total_amount − paid_amount`)
- `invoice_no` is unique across the system
- Supports bulk generation (`generateFeeInvoice`), individual create/update/cancel
- Full PDF download, email, and WhatsApp sharing capabilities
- Payment recording directly on an invoice (`recordPayment`)

**Routes:** `GET|POST /student-fee/fee-invoice` — `FeeInvoiceController` (full resource + generate/trash/restore/toggle-status + preview/pdf/email/whatsapp + cancel + recordPayment)

---

## Payment — Fee Transactions

Records every payment made against an invoice:

- `transaction_no` unique across the system
- Multi-mode: Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet
- Payment reference (cheque/DD/transaction ID), bank name, cheque date
- Links to `std_students`, `fee_invoices`, `std_guardians` (payer)
- Status: Success, Pending, Failed, Refunded
- `collected_by` FK to `sys_users` (cashier/collector tracking)
- `fee_transaction_details` splits the payment across fee heads (head-wise allocation)
- List view with search by transaction no/student name, filter by payment mode and status

**Routes:** `GET /student-fee/fee-transaction` — `FeeTransactionController` (index, show, downloadReceipt)

---

## Payment — Fee Receipts

Official receipts generated after a successful transaction:

- `receipt_no` unique; one-to-one with `fee_transactions` (`transaction_id` is UNIQUE)
- Receipt formats: Standard, Detailed, Tax Invoice
- Delivery tracking: `sent_to_parent`, `sent_via` (Email/SMS/WhatsApp/Print), `sent_at`
- Receipt PDF path stored for download

**Routes:** Displayed in the Payment tab view; generated automatically on transaction recording.

---

## Fine Management — Fee Fine Rules

Configurable late-payment fine rules with tiered structure:

- Applicable on: Fee Structure, Installment, or Head level
- Fine types: Percentage, Fixed, Percentage+Capped
- `fine_calculation_mode`: PerDay (fine_value × days late) or FlatPerTier (once per tier)
- Grace period, recurring interval, max fine installments
- Action on expiry: None, Mark Defaulter, Remove Name, Suspend
- 4-tier seed data: Tier 1 (₹25/day, days 1-10, cap ₹250), Tier 2 (₹50/day, days 11-30, cap ₹1,000), Tier 3 (₹100/day, days 31-60, cap ₹3,000, Mark Defaulter), Name Removal (day 61+)

**Routes:** `GET|POST /student-fee/fee-fine-rule` — `FeeFineRuleController` (full resource + trash/restore/toggle-status)

---

## Fine Management — Fee Fine Transactions

Tracks fines actually applied to students:

- Records `days_late`, `fine_amount`, link to `fine_rule_id` and `invoice_id`
- Waiver workflow: `waived` flag, `waived_amount`, `waived_by`, `waiver_reason`, `waived_at`
- Partial waiver supported (waived_amount < fine_amount)
- List view with search by student name, filter by waived status

**Routes:** `GET|POST /student-fee/fee-fine-transaction` — `FeeFineTransactionController` (resource + trash + waive)

---

## Scholarship — Fee Scholarship

Scholarship fund definitions:

- Fund source: Government, Trust, Corporate, NGO, School Fund, Donor, Other
- `total_fund_amount` and `available_fund` for pool management
- `eligibility_criteria` as JSON (academic/financial/category criteria)
- Application window with `application_start_date` / `application_end_date`
- `max_amount_per_student`, renewal support with `renewal_criteria`
- Soft-delete support, active/inactive toggle

**Routes:** `GET|POST /student-fee/fee-scholarship` — `FeeScholarshipController` (full resource + trash/restore/toggle-status)

---

## Scholarship — Fee Scholarship Application

Student applications for scholarships with multi-stage approval:

- Status workflow: Draft → Submitted → Under Review → Approved → Rejected → Waitlisted
- `application_data` JSON stores student responses to eligibility criteria
- `documents_submitted` JSON tracks uploaded documents
- `current_stage` and `review_committee` JSON for multi-level review
- Approval endpoints: submit, approve, reject, waitlist, disburse
- `disbursed` flag and `disbursed_date` track fund utilization
- Auto-deducts from `available_fund` on approval
- Approval history tracked in `fee_scholarship_approval_history`

**Routes:** `GET|POST /student-fee/fee-scholarship-application` — `FeeScholarshipApplicationController` (index/create/store/show + submit/approve/reject/waitlist/disburse)

---

## Governance — Name Removal Log

Chronic defaulter governance — tracks removal of student names from the rolls:

- Records `removal_date`, `removal_reason`, `total_due_at_removal`, `days_overdue`
- Triggered by fine rule action on expiry (action_on_expiry = 'Remove Name')
- Re-admission workflow: `re_admission_date`, `re_admission_fee_paid`, `re_admitted_by`, `re_activated_date`
- Dual FK tracking: `removed_by` and `re_admitted_by` (both FK to `sys_users`)
- Dashboard stats: total removals, currently removed, re-admitted, total due at removal, avg days overdue

**Routes:** `GET /student-fee/governance` — `StudentFeeManagementController.governance()` (list + stats)

---

## Fee Refund

Manages refund requests when payments are reversed or students withdraw:

- 4-stage status workflow: Pending → Approved → Processed → Rejected
- Refund modes: Cash, Cheque, Bank Transfer, Original Mode
- Links to original transaction, student, approver, and processor
- Separate approve, reject, and process endpoints

**Routes:** `GET|POST /student-fee/fee-refund` — `FeeRefundController` (resource + approve/reject/process)

---

## Cheque/DD Reconciliation

Tracks the full cheque and demand draft lifecycle:

- Status workflow: Pending Deposit → Deposited → Cleared → Bounced → Resubmitted
- Records cheque no, bank name, cheque date, deposit date, clearance date, bounce date
- Bounce details: bounce_reason, bounce_charge
- Separate endpoints for deposit, clear, bounce, and resubmit actions

**Routes:** `GET|POST /student-fee/fee-cheque` — `FeeChequeController` (resource + deposit/clear/bounce/resubmit)

---

## Payment Gateway Logs

Logs all online payment gateway transactions for audit and reconciliation:

- Gateways: Razorpay, Paytm, CCAvenue, BillDesk, Other
- Full request/response payload capture (JSON)
- Gateway transaction ID, order ID, payment ID for reconciliation
- IP address and user agent for fraud analysis

**Routes:** (Logged automatically during payment processing; no dedicated UI)

---

## Defaulter History

Per-student-per-session aggregation for defaulter pattern analysis and AI prediction:

- `total_fine_count`, `total_fine_amount`, `total_waived_amount`
- `max_days_late`, `avg_days_late`, `missed_installments`
- `name_removed`, `re_admitted` flags
- `defaulter_score` computed risk score (0–100) for AI analytics
- `last_computed_at` tracks recency of aggregation

**Routes:** (Populated by `fee:apply-fines` console command; no dedicated UI)

---

## Requirements

- The system MUST provide a tabbed dashboard interface aggregating key financial metrics (total fee, collected, outstanding, student count, defaulter count, scholarship count, concession count) for the current academic session
- The system MUST support full CRUD operations (with soft-delete, restore, force-delete, and toggle-status) on Fee Heads, Fee Groups, Fee Structures, Fee Installments, Fee Concession Types, Fee Scholarships, Fee Student Assignments, Fee Invoices, and Fee Fine Rules
- The system MUST enforce authorization via the `tenant.student-fee-management.viewAny` gate on all management screens and dedicated gates on resource controllers
- The system MUST generate unique invoice numbers, transaction numbers, and receipt numbers across the entire school tenant
- The system MUST calculate invoice `balance_amount` as a MySQL GENERATED ALWAYS column (`total_amount` − `paid_amount`) for real-time balance computation
- The system MUST support bulk generation of student fee assignments (by class/section) and bulk generation of invoices (by assignment), with appropriate validation and error handling
- The system MUST implement a tiered fine calculation engine (`fee:apply-fines` Artisan command) with PerDay and FlatPerTier modes, grace periods, recurring intervals, max caps, and configurable actions on expiry (Mark Defaulter / Remove Name / Suspend)
- The system MUST provide a scholarship workflow with multi-stage approval (Submit → Approve/Reject/Waitlist → Disburse), automatic fund pool deduction on approval, and full approval history audit trail
- The system MUST track the cheque/DD reconciliation lifecycle (Pending Deposit → Deposited → Cleared → Bounced → Resubmitted) with separate state-transition endpoints
- The system MUST support four-stage refund processing (Pending → Approved → Processed → Rejected) with separate approve, reject, and process endpoints
- The system MUST maintain a Name Removal Log for chronic defaulters with full re-admission tracking, including re-admission fee collection and dual-actor audit (removed_by / re_admitted_by)
- The system MUST aggregate per-student-per-session defaulter analytics (fine count, days late, missed installments, name removal status, computed risk score) in the `fee_defaulter_history` table for reporting and AI prediction

---

## Dependencies

### Primary Tables

The StudentFee module owns and operates the following `fee_*` tables:

| Table Name | Description | Module Area |
|-----------|-------------|-------------|
| `fee_head_master` | Core fee components (Tuition, Transport, Hostel, etc.) with frequency, tax, refundable flags | Configuration |
| `fee_group_master` | Logical grouping of fee heads into packages | Configuration |
| `fee_group_heads_jnt` | Junction mapping fee heads to groups with optional flag and default amount | Configuration |
| `fee_structure_master` | Fee structure definition per class + session + category + board | Configuration |
| `fee_structure_details` | Line items of fee structure (head-wise amounts with optional flag) | Configuration |
| `fee_installments` | Installment schedules for fee structures (due date, percentage, amount, grace days) | Configuration |
| `fee_fine_rules` | Late payment fine rule definitions with tiered structure | Fine Management |
| `fee_concession_types` | Concession/discount type definitions (percentage or fixed amount) | Configuration |
| `fee_concession_applicable_heads` | Maps concessions to specific heads or groups (mutually exclusive) | Configuration |
| `fee_student_assignments` | Fee structure assigned to individual students with opted heads/groups and proration | Assignment |
| `fee_student_concessions` | Concessions applied to specific student assignments with approval workflow | Configuration |
| `fee_invoices` | Generated invoices with 6-status lifecycle and generated balance column | Billing |
| `fee_transactions` | Master payment transaction records with multi-mode payment info | Payment |
| `fee_transaction_details` | Head-wise split of transaction amounts with fine and concession adjustment | Payment |
| `fee_receipts` | Official receipts linked one-to-one with transactions | Payment |
| `fee_fine_transactions` | Applied fine records with waiver workflow | Fine Management |
| `fee_payment_gateway_logs` | Online payment gateway request/response audit log | Payment |
| `fee_scholarships` | Scholarship/fund definitions with eligibility criteria and fund pool | Scholarship |
| `fee_scholarship_applications` | Student applications for scholarships with multi-stage approval | Scholarship |
| `fee_scholarship_approval_history` | Audit trail of scholarship approval workflow actions | Scholarship |
| `fee_name_removal_log` | Governance log for student name removal due to non-payment | Governance |
| `fee_refunds` | Refund request tracking with 4-stage approval workflow | Refund |
| `fee_payment_reconciliation` | Cheque/DD lifecycle tracking (deposit, clearance, bounce, resubmit) | Reconciliation |
| `fee_defaulter_history` | Per-student-per-session defaulter analytics with risk score | Governance |

### External Module Dependencies

| Module | Nature of Dependency |
|--------|---------------------|
| **Student Core** | Required — Provides `std_students` table for student identity, admission number, and user linkage |
| **Student Guardian** | Required — Provides `std_guardians` table for fee payer information (guardian who pays the fee) |
| **School Setup** | Required — Provides `sch_classes`, `sch_sections` for class-section references; `sch_org_academic_sessions_jnt` for academic session FK |
| **System Core** | Required — Provides `sys_users` for cashier/collector/approver tracking; `sys_dropdown_table` for head types, concession categories, and other lookup values |
| **Student Profile** | Required — Provides `StudentAcademicSession` model for counting enrolled students per session |
| **Prime Core** | Required — Provides `AcademicSession::current()` for resolving the active academic session across all tabbed views |
