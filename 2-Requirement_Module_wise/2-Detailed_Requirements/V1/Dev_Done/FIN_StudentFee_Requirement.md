# StudentFee Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** FIN | **Module Path:** `Modules/StudentFee`
**Module Type:** Tenant Module | **Database:** `tenant_{uuid}`
**Table Prefix:** `fin_*` (DDL uses `fee_*` prefix; models map to these tables) | **Completion:** ~50%
**RBS Reference:** Module J — Fees & Finance Management (lines 2709–2843)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

StudentFee is the **comprehensive fee management module** for Prime-AI tenant schools. It covers the complete lifecycle of school fee administration: from defining fee structures and heads, assigning fees to students, generating invoices, collecting payments via online and offline modes, managing concessions and scholarships, applying late-payment fines, and producing financial reports and receipts.

### 1.2 Module Position in the Platform

```
Tenant Scope            Module              Database
─────────────────────────────────────────────────────
Tenant (Per-School)     StudentFee (FIN)    tenant_{uuid}
Tenant (Per-School)     StudentProfile      tenant_{uuid}  (source of student data)
Tenant (Per-School)     Payment             tenant_{uuid}  (Razorpay gateway)
Tenant (Per-School)     Notification        tenant_{uuid}  (SMS/email alerts)
```

### 1.3 Module Characteristics

| Attribute            | Value                                                        |
|----------------------|--------------------------------------------------------------|
| Laravel Module       | `nwidart/laravel-modules` v12, name `StudentFee`             |
| Namespace            | `Modules\StudentFee`                                         |
| Module Code          | FIN                                                          |
| Domain               | Tenant (school-specific subdomain)                           |
| DB Connection        | `tenant` (tenant_{uuid})                                     |
| Table Prefix         | `fee_*` in DDL (models map via `$table` property)            |
| Auth                 | Spatie Permission v6.21 via `Gate::authorize()`              |
| Controllers          | 15 (1 seeder controller + 1 management hub + 13 CRUD)        |
| Models               | 23                                                           |
| Services             | 0 (all business logic inline in controllers — gap)           |
| FormRequests         | 0 (all validation inline — P0 gap)                           |
| Tests                | 24 (unit model tests only, no feature/integration tests)     |
| Payment Gateway      | Razorpay (via Payment module)                                |
| PDF Generation       | DomPDF (invoice PDF)                                         |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Fee Head Master management (tuition, transport, hostel, library, etc.)
- Fee Group Master (logical grouping of fee heads)
- Fee Structure Master (class-wise, session-wise, category-wise fee templates)
- Fee Installment scheduling (due dates, grace periods, percentage splits)
- Student Fee Assignment (per student, per academic session)
- Fee Concession Types and per-student concession application with approval workflow
- Fee Scholarship management (funds, eligibility, application, approval, disbursement)
- Fee Invoice generation (individual and bulk/batch)
- Fee Transaction recording (cash, UPI, bank transfer, online gateway)
- Fee Receipt download (DomPDF)
- Fine Rule configuration (tiered, per-day, percentage, fixed)
- Fine Transaction management and waiver processing
- Payment Gateway log and reconciliation tracking
- Fee Refund management
- Fee Defaulter history and analytics
- Fee reports (collection summary, outstanding dues)
- Dashboard (total fee, collected, outstanding, defaulters, scholarships, concessions)

### 2.2 Out of Scope

- Accounting ledger / double-entry bookkeeping (handled by Accounting module)
- Transport fee routing (handled by Transport module — fee assignment only)
- Hostel fee room assignment (handled by Hostel module — fee assignment only)
- Student Portal fee payment view (handled by StudentPortal module)
- HR/Payroll fee deductions for staff children

### 2.3 Module Dependencies

| Dependency               | Direction | Purpose                                          |
|--------------------------|-----------|--------------------------------------------------|
| StudentProfile (STD)     | Incoming  | Source of student, guardian, academic session    |
| SchoolSetup (SCH)        | Incoming  | Classes, sections, academic sessions             |
| Payment module           | Outgoing  | Razorpay gateway for online fee collection       |
| Notification module      | Outgoing  | SMS/email alerts for invoice, receipt, due dates |
| SystemConfig (SYS)       | Incoming  | RBAC roles, dropdown lookups                     |

---

## 3. Actors and User Roles

| Role                  | Access Level                                                                  |
|-----------------------|-------------------------------------------------------------------------------|
| Super Admin           | Full access to all fee operations across all tenants                          |
| School Admin          | Full access within tenant: setup, assign, invoice, collect, approve           |
| Accountant / Cashier  | Record payments, generate receipts, view reports; no structural changes       |
| Principal             | Approve concessions at Principal level; view reports                          |
| Class Teacher         | View fee status of own class students; request concessions                    |
| Student               | View own invoices and fee status via StudentPortal (read-only)                |
| Parent / Guardian     | View child's fee invoices and make payments via StudentPortal                 |

---

## 4. Functional Requirements

### 4.1 Fee Head Master (J1 — Fee Heads)

**REF: ST.J1.1.1.1 to ST.J1.1.2.2**

- `ST.FIN.4.1.1` — Create fee head with code, name, description, type (from dropdown), frequency (One-time / Monthly / Quarterly / Half-Yearly / Yearly)
- `ST.FIN.4.1.2` — Configure refundability flag (`is_refundable`) and tax applicability with percentage
- `ST.FIN.4.1.3` — Map account head code for ERP accounting integration
- `ST.FIN.4.1.4` — Soft-delete, restore, force-delete, status toggle on fee heads
- `ST.FIN.4.1.5` — Unique code enforcement; code is immutable after assignment to a fee structure

### 4.2 Fee Group Master (J1 — Fee Groups)

- `ST.FIN.4.2.1` — Create logical group (e.g., "Academic Package", "Transport Bundle") with code, name, mandatory flag
- `ST.FIN.4.2.2` — Assign fee heads to group via junction (`fee_group_heads_jnt`); mark each as optional or mandatory, with default amount
- `ST.FIN.4.2.3` — Display order control for UI rendering

### 4.3 Fee Structure Master (J1 — Fee Templates)

**REF: ST.J1.2.1.1 to ST.J1.2.2.2**

- `ST.FIN.4.3.1` — Create fee structure for: academic session + class + optional student category (General / OBC / SC / ST) + optional board type
- `ST.FIN.4.3.2` — Define line-item amounts per fee head via `fee_structure_details`
- `ST.FIN.4.3.3` — Set effective date range (`effective_from`, `effective_to`)
- `ST.FIN.4.3.4` — System auto-calculates `total_fee_amount` as sum of all head amounts
- `ST.FIN.4.3.5` — One fee structure per (session + class + category) combination enforced at application level

### 4.4 Fee Installment Scheduling (J1 — Installment Setup)

**REF: ST.J1.2.2.1, ST.J1.2.2.2**

- `ST.FIN.4.4.1` — Define installment schedule for a fee structure: installment number, name (e.g., "Term 1"), due date, percentage of total fee
- `ST.FIN.4.4.2` — Configure grace period (days) per installment before fine applies
- `ST.FIN.4.4.3` — Calculated amount auto-populated from `percentage_due × total_fee_amount`
- `ST.FIN.4.4.4` — CRUD + soft delete + status toggle per installment

### 4.5 Student Fee Assignment (J2 — Fee Allocation)

**REF: ST.J2.1.1.1 to ST.J2.2.1.2**

- `ST.FIN.4.5.1` — Auto-assign fee structure to all students of a class/section in batch (`generateStudentAssignment` route)
- `ST.FIN.4.5.2` — Individual assignment: select student → fee structure → confirm opted optional heads
- `ST.FIN.4.5.3` — Support mid-year join: set `fee_start_date` and `proration_percentage`
- `ST.FIN.4.5.4` — Update assigned fee structure via `updateAssignmentStructure` endpoint
- `ST.FIN.4.5.5` — One active assignment per student per academic session (UNIQUE constraint)
- `ST.FIN.4.5.6` — Sections by class AJAX endpoint (`getSectionsByClass`) for dynamic UI filtering

### 4.6 Fee Concession Management (J4 — Concessions)

**REF: ST.J4.1.1.1 to ST.J4.1.2.2**

- `ST.FIN.4.6.1` — Create concession type: code, name, category (Sibling / Merit / Staff / Financial Aid / Sports), discount type (Percentage or Fixed Amount), discount value, applicable scope (Total Fee / Specific Heads / Specific Groups), max cap amount
- `ST.FIN.4.6.2` — Map concession type to applicable heads or groups via `fee_concession_applicable_heads`
- `ST.FIN.4.6.3` — Apply concession to a specific student assignment: triggers approval workflow if `requires_approval = true`
- `ST.FIN.4.6.4` — Approval lifecycle: Pending → Approved / Rejected with rejection reason and approver tracked
- `ST.FIN.4.6.5` — Approved concession auto-reduces invoice amount on next invoice generation

### 4.7 Scholarship Management (J9 — Financial Aid)

**REF: ST.J9.1.1.1 to ST.J9.2.2.2**

- `ST.FIN.4.7.1` — Create scholarship fund: code, name, fund source (Government / Trust / Corporate / School), sponsor name, total fund amount, eligibility criteria (JSON: min_percentage, family_income_max, category, class, etc.), application dates, max amount per student
- `ST.FIN.4.7.2` — Set renewal criteria JSON (min_percentage, attendance, annual_review)
- `ST.FIN.4.7.3` — Student scholarship application: student selection, scholarship selection, documents upload
- `ST.FIN.4.7.4` — Application workflow: Draft → Submitted → Under Review → Approved / Rejected / Waitlisted → Disbursed
- `ST.FIN.4.7.5` — On approval: `disburse` endpoint auto-applies scholarship amount to student's fee account
- `ST.FIN.4.7.6` — Approval history tracked in `fee_scholarship_approval_history`

### 4.8 Fee Invoice Generation (J3 — Collection Entry)

**REF: ST.J3.1.1.1 to ST.J3.1.2.2**

- `ST.FIN.4.8.1` — Generate invoice for individual student assignment + installment
- `ST.FIN.4.8.2` — Bulk invoice generation for all active assignments in current session (`generateFeeInvoice` route)
- `ST.FIN.4.8.3` — Invoice fields: invoice number (auto-generated), invoice date, due date, base amount, concession amount, fine amount, tax amount, total amount, paid amount, status
- `ST.FIN.4.8.4` — Invoice status lifecycle: Draft → Published → Partially Paid → Paid → Overdue → Cancelled
- `ST.FIN.4.8.5` — Invoice PDF download via DomPDF (`fee-invoice/{id}/pdf`)
- `ST.FIN.4.8.6` — Invoice email delivery (`fee-invoice/{id}/email`)
- `ST.FIN.4.8.7` — Invoice WhatsApp share (`fee-invoice/{id}/whatsapp`)
- `ST.FIN.4.8.8` — Invoice cancellation with audit trail (`cancel` route)
- `ST.FIN.4.8.9` — Invoice view/preview in web (`fee-invoice/{id}/invoice/view`)

### 4.9 Fee Transaction / Payment Recording (J3 — Collection)

**REF: ST.J3.1.1.1, ST.J3.1.1.2, ST.J3.2.1.1**

- `ST.FIN.4.9.1` — Record offline payment against an invoice: payment mode (Cash / UPI / Bank Transfer / Cheque / DD), amount, transaction reference
- `ST.FIN.4.9.2` — System validates: paid amount ≤ remaining balance; partial payment allowed
- `ST.FIN.4.9.3` — Auto-update invoice `paid_amount` and status after each transaction
- `ST.FIN.4.9.4` — Receipt download (DomPDF) via `fee-transaction/{id}/receipt`
- `ST.FIN.4.9.5` — Online payment via Payment module / Razorpay (StudentPortal triggers `proceedPayment`)
- `ST.FIN.4.9.6` — Payment gateway log stored in `fee_payment_gateway_logs`; reconciliation tracked in `fee_payment_reconciliation`

### 4.10 Fine Management (J6 — Fines & Penalties)

**REF: ST.J6.1.1.1 to ST.J6.2.1.2**

- `ST.FIN.4.10.1` — Define fine rule: name, applicable on (Fee Structure / Installment / Head), fine type (Percentage / Fixed / Percentage+Capped), fine value, calculation mode (PerDay / FlatPerTier), grace period days, recurring flag
- `ST.FIN.4.10.2` — Tiered fine: `applicable_from_day` to `applicable_to_day` with max fine amount cap
- `ST.FIN.4.10.3` — Action on expiry: None / Mark Defaulter / Remove Name / Suspend
- `ST.FIN.4.10.4` — Console command `ApplyFines` (scheduled): calculates and creates `fee_fine_transactions` for overdue invoices
- `ST.FIN.4.10.5` — Fine waiver: `PUT fee-fine-transaction/{id}/waive` with reason and approver tracking
- `ST.FIN.4.10.6` — Fine auto-added to invoice `fine_amount` on next invoice generation post-due date

### 4.11 Fee Reports & Analytics (J7, J8)

**REF: ST.J7.1.1.1 to ST.J8.2.1.2**

- `ST.FIN.4.11.1` — Dashboard: total fee amount for session, total collected, total outstanding, student count
- `ST.FIN.4.11.2` — Defaulter list: invoices with status "Overdue", sortable by amount
- `ST.FIN.4.11.3` — Scholar list: approved scholarship applications in current session
- `ST.FIN.4.11.4` — Concession list: approved concessions in current session
- `ST.FIN.4.11.5` — Recent transactions: last 10 successful payment transactions
- `ST.FIN.4.11.6` — Fee collection chart (month-wise): labels and collected amounts for chart rendering
- `ST.FIN.4.11.7` — Drill-down: `dashboardFeeCollection` endpoint for class-wise or head-wise breakdown

### 4.12 Dynamic Fee Rule Engine (J10)

**REF: ST.J10.1.1.1 to ST.J10.1.2.2**

- `ST.FIN.4.12.1` — Fee rule builder: define rules based on student attributes (class, category, board) — **PENDING (not yet built)**
- `ST.FIN.4.12.2` — Rule simulation: test fee calculation for sample student profiles before batch apply — **PENDING**

---

## 5. Data Model

### 5.1 Core Tables

| Table Name                        | Purpose                                                        | Records (Est.) |
|-----------------------------------|----------------------------------------------------------------|----------------|
| `fee_head_master`                 | Fee component definitions (Tuition, Transport, etc.)           | 10–50          |
| `fee_group_master`                | Logical groupings of fee heads                                 | 5–20           |
| `fee_group_heads_jnt`             | Head-to-group mappings                                         | 20–100         |
| `fee_structure_master`            | Class + session + category fee templates                       | 20–200         |
| `fee_structure_details`           | Head-wise amounts per structure                                | 100–1000       |
| `fee_installments`                | Installment schedules per structure                            | 50–500         |
| `fee_fine_rules`                  | Late payment fine configurations                               | 5–50           |
| `fee_concession_types`            | Concession type definitions                                    | 10–50          |
| `fee_concession_applicable_heads` | Concession-to-head/group mappings                              | 20–200         |
| `fee_student_assignments`         | Per-student fee structure for academic session (UNIQUE per session) | Students |
| `fee_student_concessions`         | Per-student concession applications and approvals              | Variable       |
| `fee_invoices`                    | Generated invoices per student assignment/installment          | High volume    |
| `fee_transactions`                | Payment records (offline and online)                           | High volume    |
| `fee_transaction_details`         | Line-item breakdown of each transaction                        | High volume    |
| `fee_fine_transactions`           | Applied fines per overdue invoice                              | Variable       |
| `fee_scholarships`                | Scholarship fund definitions                                   | 5–50           |
| `fee_scholarship_applications`    | Student scholarship applications                               | Variable       |
| `fee_scholarship_approval_history`| Approval audit trail for scholarship applications              | Variable       |
| `fee_payment_gateway_logs`        | Razorpay / other gateway request-response logs                 | High volume    |
| `fee_payment_reconciliation`      | Gateway reconciliation status per transaction                  | High volume    |
| `fee_receipts`                    | Generated receipt records                                      | High volume    |
| `fee_refunds`                     | Refund requests and status                                     | Low volume     |
| `fee_defaulter_history`           | Defaulter analytics snapshots                                  | Variable       |
| `fee_name_removal_log`            | Students whose names are removed due to non-payment            | Low volume     |

### 5.2 Key Relationships

```
fee_head_master ──── fee_group_heads_jnt ──── fee_group_master
fee_structure_master ──── fee_structure_details ──── fee_head_master
fee_structure_master ──── fee_installments
std_students ──── fee_student_assignments ──── fee_structure_master
fee_student_assignments ──── fee_student_concessions ──── fee_concession_types
fee_student_assignments ──── fee_invoices ──── fee_installments
fee_invoices ──── fee_transactions ──── fee_transaction_details
fee_fine_rules ──── fee_fine_transactions ──── fee_invoices
fee_scholarships ──── fee_scholarship_applications ──── std_students
```

### 5.3 Key Columns of Note

- `fee_student_assignments.join_in_mid-year` (TINYINT): hyphen in column name is a DDL artifact; requires backtick quoting in SQL
- `fee_student_assignments.opted_heads` (JSON): array of optional head IDs the student has opted into
- `fee_fine_rules.fine_calculation_mode` ENUM('PerDay', 'FlatPerTier'): PerDay multiplies fine_value × days overdue; FlatPerTier applies fine_value once per tier
- `fee_invoices.status` ENUM: Draft / Published / Partially Paid / Paid / Overdue / Cancelled
- `fee_scholarship_applications.status`: Draft → Submitted → Under Review → Approved / Rejected / Waitlisted → Disbursed
- All tables: `is_active`, `deleted_at`, `created_at`, `updated_at` standard columns

---

## 6. Controller & Route Inventory

### 6.1 Controllers

| Controller                         | Responsibility                                            | Routes Prefix                       |
|------------------------------------|-----------------------------------------------------------|--------------------------------------|
| `StudentFeeController`             | Seeder function (P0 SECURITY — exposed via GET route)     | `student-fee/seeder`                |
| `StudentFeeManagementController`   | Hub: dashboard, configuration, assignment, billing views  | `student-fee/dashboard`, `student-fee/configuration` |
| `FeeHeadMasterController`          | CRUD + soft delete + toggle for fee heads                 | `student-fee/fee-head-master`       |
| `FeeGroupMasterController`         | CRUD + soft delete + toggle for fee groups                | `student-fee/fee-group-master`      |
| `FeeStructureMasterController`     | CRUD + soft delete + toggle for fee structures            | `student-fee/fee-structure-master`  |
| `FeeInstallmentController`         | CRUD + soft delete + toggle for installments              | `student-fee/fee-installment`       |
| `FeeConcessionTypeController`      | CRUD + soft delete + toggle for concession types          | `student-fee/fee-concession-type`   |
| `FeeStudentConcessionController`   | Apply, approve, reject concessions per student            | `student-fee/fee-student-concession`|
| `FeeFineRuleController`            | CRUD + soft delete + toggle for fine rules                | `student-fee/fee-fine-rule`         |
| `FeeFineTransactionController`     | Fine transactions + waive endpoint                        | `student-fee/fee-fine-transaction`  |
| `FeeStudentAssignmentController`   | Assignment CRUD + bulk generate + section lookup          | `student-fee/fee-student-assignment`|
| `FeeScholarshipController`         | Scholarship fund CRUD + soft delete + toggle              | `student-fee/fee-scholarship`       |
| `FeeScholarshipApplicationController` | Application CRUD + submit/approve/reject/waitlist/disburse | `student-fee/fee-scholarship-application` |
| `FeeInvoiceController`             | Invoice CRUD + bulk generate + PDF + email + cancel       | `student-fee/fee-invoice`           |
| `FeeTransactionController`         | Read-only listing + receipt download                      | `student-fee/fee-transaction`       |

### 6.2 Route Summary

| Method   | Route                                               | Controller Method              | Gate Permission                        |
|----------|-----------------------------------------------------|--------------------------------|----------------------------------------|
| GET      | `student-fee/seeder`                               | `seederFunction`               | NONE — P0 SECURITY VULNERABILITY       |
| GET      | `student-fee/dashboard`                            | `dashboard`                    | `tenant.student-fee-management.viewAny`|
| GET      | `student-fee/configuration`                        | `configuration`                | Management hub view                    |
| GET      | `student-fee/assignment`                           | `assignment`                   | Assignment hub view                    |
| GET      | `student-fee/billing`                              | `billing`                      | Billing hub view                       |
| GET      | `student-fee/payment`                              | `payment`                      | Payment hub view                       |
| GET      | `student-fee/fine-management`                      | `fineManagement`               | Fine hub view                          |
| GET      | `student-fee/scholarship`                          | `scholarship`                  | Scholarship hub view                   |
| POST     | `student-fee/fee-student-assignment/generate/all`  | `generateStudentAssignment`    | Assignment create                      |
| POST     | `student-fee/fee-invoice/generate/all`             | `generateFeeInvoice`           | `tenant.fee-invoice.create`            |
| GET      | `student-fee/fee-invoice/{id}/pdf`                 | `downloadPdf`                  | View invoice                           |
| POST     | `student-fee/fee-invoice/{id}/email`               | `sendEmail`                    | View invoice                           |
| PUT      | `student-fee/fee-invoice/{id}/cancel`              | `cancel`                       | Update invoice                         |
| PUT      | `student-fee/fee-fine-transaction/{id}/waive`      | `waive`                        | Fine waiver                            |
| POST     | `student-fee/fee-scholarship-application/{id}/approve` | `approve`                  | Scholarship approve                    |
| POST     | `student-fee/fee-scholarship-application/{id}/disburse` | `disburse`                | Scholarship disburse                   |
| GET      | `student-fee/fee-transaction/{id}/receipt`         | `downloadReceipt`              | View receipt                           |

---

## 7. Form Request Validation Rules

**CRITICAL GAP: 0 FormRequest classes exist. All validation is inline in controllers.**

The following FormRequests need to be created:

### 7.1 StoreFeeHeadMasterRequest
```
code:           required|string|max:30|unique:fee_head_master,code
name:           required|string|max:100
head_type_id:   required|exists:sys_dropdowns,id
frequency:      required|in:One-time,Monthly,Quarterly,Half-Yearly,Yearly
is_refundable:  nullable|boolean
tax_applicable: nullable|boolean
tax_percentage: nullable|numeric|min:0|max:100
```

### 7.2 StoreFeeStructureMasterRequest
```
academic_session_id:    required|exists:sch_org_academic_sessions_jnt,id
class_id:               required|exists:sch_classes,id
student_category_id:    nullable|exists:sys_dropdowns,id
code:                   required|string|max:50|unique:fee_structure_master,code
name:                   required|string|max:100
effective_from:         required|date
effective_to:           nullable|date|after:effective_from
```

### 7.3 StoreFeeConcessionTypeRequest
```
code:                   required|string|max:50|unique:fee_concession_types,code
name:                   required|string|max:100
concession_category_id: required|exists:sys_dropdowns,id
discount_type:          required|in:Percentage,Fixed Amount
discount_value:         required|numeric|min:0
applicable_on:          required|in:Total Fee,Specific Heads,Specific Groups
requires_approval:      nullable|boolean
```

### 7.4 StoreFeeInvoiceRequest
```
student_assignment_id:  required|exists:fee_student_assignments,id
installment_id:         nullable|exists:fee_installments,id
invoice_date:           required|date
due_date:               required|date|after_or_equal:invoice_date
base_amount:            required|numeric|min:0
concession_amount:      nullable|numeric|min:0
fine_amount:            nullable|numeric|min:0
tax_amount:             nullable|numeric|min:0
status:                 required|in:Draft,Published
```

### 7.5 StoreScholarshipApplicationRequest
```
student_id:             required|exists:std_students,id
scholarship_id:         required|exists:fee_scholarships,id
applied_amount:         required|numeric|min:0.01
remarks:                nullable|string|max:500
```

---

## 8. Business Rules

### 8.1 Fee Structure Rules
- `BR.FIN.8.1.1` — A student can have only ONE active fee assignment per academic session (UNIQUE constraint on `student_id + academic_session_id` in `fee_student_assignments`)
- `BR.FIN.8.1.2` — Fee structure cannot be deleted if it has active student assignments
- `BR.FIN.8.1.3` — Changing a student's fee structure mid-year via `updateAssignmentStructure` must recalculate `total_fee_amount`; existing invoices must be reviewed and revised manually

### 8.2 Late Payment Penalties
- `BR.FIN.8.2.1` — Fine applies only after `installment.grace_days` from due date
- `BR.FIN.8.2.2` — PerDay fine = `fine_value × days_overdue` (from day `applicable_from_day` to `applicable_to_day`)
- `BR.FIN.8.2.3` — FlatPerTier fine = `fine_value` applied once when entering that tier bracket
- `BR.FIN.8.2.4` — Percentage+Capped fine = `(base_amount × fine_value / 100)` capped at `max_fine_amount`
- `BR.FIN.8.2.5` — Max fine cap: `max_fine_amount` field on rule; once reached, no additional fine applied
- `BR.FIN.8.2.6` — `ApplyFines` console command runs nightly via scheduler; idempotent (checks if fine already applied for the date)

### 8.3 Concession Eligibility Criteria
- `BR.FIN.8.3.1` — Sibling discount: applicable when two or more children from the same family are enrolled simultaneously; school admin must verify and manually apply
- `BR.FIN.8.3.2` — Merit concession: requires minimum percentage threshold verified against exam results
- `BR.FIN.8.3.3` — Staff concession: requires active staff relationship on record
- `BR.FIN.8.3.4` — Concessions requiring approval cannot be applied to invoice until status is "Approved"
- `BR.FIN.8.3.5` — Multiple concessions per student assignment are allowed; system applies all approved concessions cumulatively but subject to head-level or total-fee cap

### 8.4 Partial Payment Handling
- `BR.FIN.8.4.1` — Partial payment is allowed; invoice status changes to "Partially Paid" when `paid_amount > 0` and `paid_amount < total_amount`
- `BR.FIN.8.4.2` — Invoice status changes to "Paid" only when `paid_amount >= total_amount`
- `BR.FIN.8.4.3` — Overpayment: if `paid_amount > total_amount`, excess is recorded as an advance credit against the student account (refund or adjust in next invoice)
- `BR.FIN.8.4.4` — Partial payment does NOT reset the due date; fine continues to accumulate on unpaid balance

### 8.5 Refund Policy
- `BR.FIN.8.5.1` — Refund can only be initiated by authorized roles (Accountant, Admin)
- `BR.FIN.8.5.2` — Only refundable fee heads (`is_refundable = 1`) are eligible for refund
- `BR.FIN.8.5.3` — Refund request is created in `fee_refunds` table with status Pending → Approved → Processed
- `BR.FIN.8.5.4` — Processed refund reduces `paid_amount` on the linked invoice

### 8.6 Sibling Discount Business Logic
- `BR.FIN.8.6.1` — Guardian junction table (`std_student_guardian_jnt.is_fee_payer`) identifies fee-paying parent
- `BR.FIN.8.6.2` — Two students with the same `guardian_id` (fee_payer) in the same academic session qualify for sibling discount
- `BR.FIN.8.6.3` — Discount percentage or amount defined in concession type with category = "Sibling"

### 8.7 Scholarship Business Rules
- `BR.FIN.8.7.1` — Available fund (`available_fund`) is decremented on disbursement; disbursement blocked if insufficient fund remains
- `BR.FIN.8.7.2` — If `application_end_date` has passed, new applications are blocked
- `BR.FIN.8.7.3` — Scholarship amount is applied as a negative adjustment (credit) to the student's fee assignment total
- `BR.FIN.8.7.4` — Renewal criteria JSON is evaluated at session start for continuing students; non-compliance triggers rejection

---

## 9. Permission & Authorization Model

### 9.1 Gate Permissions Required

| Permission Key                              | Description                             |
|---------------------------------------------|-----------------------------------------|
| `tenant.student-fee-management.viewAny`     | View fee dashboard and hub pages        |
| `tenant.fee-head-master.viewAny`            | List fee heads                          |
| `tenant.fee-head-master.create`             | Create fee head                         |
| `tenant.fee-head-master.update`             | Edit fee head                           |
| `tenant.fee-head-master.delete`             | Delete fee head                         |
| `tenant.fee-structure-master.viewAny`       | List fee structures                     |
| `tenant.fee-structure-master.create`        | Create fee structure                    |
| `tenant.fee-invoice.view`                   | View individual invoice                 |
| `tenant.fee-invoice.create`                 | Generate invoice                        |
| `tenant.fee-invoice.update`                 | Edit/cancel invoice                     |
| `tenant.fee-transaction.view`               | View transactions and receipts          |
| `tenant.fee-scholarship.create`             | Create scholarship fund                 |
| `tenant.fee-scholarship-application.approve`| Approve scholarship applications        |

### 9.2 Roles vs Permissions Matrix

| Permission                                | School Admin | Accountant | Principal | Class Teacher |
|-------------------------------------------|:---:|:---:|:---:|:---:|
| View dashboard                            |  Y  |  Y  |  Y  |  N  |
| Create/edit fee structures                |  Y  |  N  |  N  |  N  |
| Assign fee to students                    |  Y  |  Y  |  N  |  N  |
| Generate invoices                         |  Y  |  Y  |  N  |  N  |
| Record payments                           |  Y  |  Y  |  N  |  N  |
| Approve concessions                       |  Y  |  N  |  Y  |  N  |
| Approve scholarships                      |  Y  |  N  |  Y  |  N  |
| Waive fines                               |  Y  |  N  |  Y  |  N  |
| View reports                              |  Y  |  Y  |  Y  |  Y  |

---

## 10. Tests Inventory

### 10.1 Existing Tests (24 Unit Model Tests)

| Test File                               | Type   | Coverage                                           |
|-----------------------------------------|--------|----------------------------------------------------|
| `FeeConcessionTypeModelTest`            | Unit   | Model fillable, soft delete, casts                 |
| `FeeDefaulterHistoryModelTest`          | Unit   | Model structure                                    |
| `FeeFineRuleModelTest`                  | Unit   | Model fillable, relationships                      |
| `FeeFineTransactionModelTest`           | Unit   | Model fillable, relationships                      |
| `FeeGroupHeadsJntModelTest`             | Unit   | Model fillable                                     |
| `FeeGroupMasterModelTest`               | Unit   | Model fillable, soft delete                        |
| `FeeHeadMasterModelTest`                | Unit   | Model fillable, soft delete, relationships         |
| `FeeInstallmentModelTest`               | Unit   | Model fillable, relationships                      |
| `FeeInvoiceModelTest`                   | Unit   | Model fillable, status enum, relationships         |
| `FeeNameRemovalLogModelTest`            | Unit   | Model structure                                    |
| `FeePaymentGatewayLogModelTest`         | Unit   | Model structure                                    |
| `FeePaymentReconciliationModelTest`     | Unit   | Model structure                                    |
| `FeeReceiptModelTest`                   | Unit   | Model fillable                                     |
| `FeeRefundModelTest`                    | Unit   | Model fillable                                     |
| `FeeScholarshipApplicationModelTest`    | Unit   | Model fillable, status enum, relationships         |
| `FeeScholarshipApprovalHistoryModelTest`| Unit   | Model structure                                    |
| `FeeScholarshipModelTest`              | Unit   | Model fillable, JSON casts, relationships          |
| `FeeStructureDetailModelTest`          | Unit   | Model fillable, relationships                      |
| `FeeStructureMasterModelTest`          | Unit   | Model fillable, soft delete, relationships         |
| `FeeStudentAssignmentModelTest`        | Unit   | Model fillable, JSON casts, relationships          |
| `FeeStudentConcessionModelTest`        | Unit   | Model fillable, approval status enum               |
| `FeeTransactionDetailModelTest`        | Unit   | Model fillable, relationships                      |
| `FeeTransactionModelTest`              | Unit   | Model fillable, relationships                      |
| `ArchitectureTest` (Feature)           | Feature| Architecture compliance (no logic in models, etc.) |

### 10.2 Tests Missing (High Priority)

- Feature tests for invoice generation workflow (individual + bulk)
- Feature tests for payment recording and partial payment
- Feature tests for concession approval workflow
- Feature tests for fine calculation and waiver
- Feature tests for scholarship application lifecycle
- Integration test: StudentPortal fee payment via Razorpay

---

## 11. Known Issues & Technical Debt

### 11.1 P0 — Critical Security Issues

| Issue                                 | Severity | Detail                                                                                             |
|---------------------------------------|----------|----------------------------------------------------------------------------------------------------|
| **Exposed seeder route**              | P0       | `GET /student-fee/seeder` is registered in `tenant.php` with `auth` middleware only. Any authenticated user can trigger mass data seeding. Must be removed or protected by an environment check (`App::environment('local')`) immediately. |

### 11.2 P1 — High-Priority Issues

| Issue                                  | Severity | Detail                                                                                                          |
|----------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| **0 FormRequest classes**              | P1       | All 15 controllers use inline `$request->validate()`; this prevents reusability, makes testing harder, and creates inconsistent error response formats. Must be extracted to FormRequest classes. |
| **0 Service classes**                  | P1       | All business logic (invoice calculation, fine computation, disbursement) is inline in controllers. Complex logic in FeeInvoiceController and FeeScholarshipApplicationController exceeds 200 lines per method. Requires extraction to `FeeInvoiceService`, `FeeScholarshipService`, `FeeFineService`. |
| **No cheque/DD lifecycle controller**  | P1       | `fee_cheque_clearance` table exists in DDL v4 but no controller or route manages cheque bounce / clearance status updates. |
| **No refund controller**               | P1       | `FeeRefund` model exists but no controller or route is wired for refund initiation or processing.               |

### 11.3 P2 — Medium Priority

| Issue                               | Detail                                                                              |
|-------------------------------------|-------------------------------------------------------------------------------------|
| No feature tests                    | Only 24 unit model tests exist; zero feature tests covering HTTP request flows      |
| Dynamic fee rule engine missing     | J10 (Dynamic Fee Structure Engine) — not implemented; no routes or controllers      |
| Missing hostel/transport fee assign | J5 integration with Hostel and Transport modules for auto-fee assignment not wired  |
| `fin_*` vs `fee_*` prefix mismatch  | DDL uses `fee_*`; module code uses `FIN`; documentation should clarify the mapping  |

---

## 12. API Endpoints

Currently, no dedicated API endpoints exist for StudentFee. All routes are web routes under `auth` + `verified` middleware.

**Planned (missing):**

| Method | Endpoint                             | Description                    |
|--------|--------------------------------------|--------------------------------|
| GET    | `/api/v1/student-fee/invoices`       | Student invoice list (for portal) |
| POST   | `/api/v1/student-fee/pay`            | Initiate online payment        |
| GET    | `/api/v1/student-fee/receipt/{id}`   | Download receipt               |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Bulk invoice generation for large schools (1000+ students) must complete within 30 seconds; recommend queuing via Laravel Jobs for batches >100
- Dashboard fee aggregation queries must use indexed columns: `academic_session_id`, `is_active`, `status`
- Invoice PDF generation should be cached for 24 hours if invoice status = "Paid" (no further changes)

### 13.2 Security

- Remove seeder route from production routes (P0 fix)
- All financial write operations must require CSRF protection (already handled by web middleware group)
- Receipt and invoice PDF endpoints must verify the requesting user has authorization to access the student's records
- Concession approval must enforce role-based approval levels defined in `approval_level_role_id`

### 13.3 Audit & Compliance

- All payment transactions must be immutable after status = "Success"; no update or delete allowed
- Fine waivers must log: waived by, reason, waived at timestamp
- Scholarship disbursements must log full approval history in `fee_scholarship_approval_history`
- All financial operations must be logged to `sys_activity_logs`

### 13.4 Indian Compliance

- Tax computation must support all 4 GST slabs (0%, 5%, 12%, 18%)
- Fee receipts must include school PAN, tax head details for 80G deduction where applicable
- RTE quota students may have zero or reduced fee; system must support zero-amount invoices

---

## 14. Integration Points

| Module              | Integration Method         | Data Flow                                              |
|---------------------|----------------------------|--------------------------------------------------------|
| StudentProfile (STD)| Eloquent relationships      | `Student`, `Guardian`, `StudentAcademicSession` models |
| SchoolSetup (SCH)   | Eloquent relationships      | `ClassSection`, `AcademicSession`, `SchoolClass`       |
| Payment module      | `PaymentService::createPayment()` | Razorpay order creation and webhook processing    |
| Notification module | `Notification` facade       | Invoice generated, payment received, due reminder      |
| Accounting module   | `account_head_code` mapping | Fee head maps to ledger account for accounting entries |
| SystemConfig (SYS)  | `sys_dropdowns` table       | Fee head type, concession category, student category   |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status by Feature Area

| Feature Area                     | Status   | Notes                                            |
|----------------------------------|----------|--------------------------------------------------|
| Fee Head / Group / Structure CRUD| Done     | CRUD complete, no service layer                  |
| Fee Installment Management       | Done     | CRUD complete                                    |
| Student Fee Assignment           | Done     | Including bulk generate                          |
| Concession Types                 | Done     | CRUD complete                                    |
| Student Concession Application   | Partial  | CRUD done; approval email notification missing   |
| Fine Rules                       | Done     | CRUD complete                                    |
| Fine Transactions                | Done     | Including waiver endpoint                        |
| ApplyFines Command               | Done     | Console command exists; scheduler registration unclear |
| Invoice Generation (individual)  | Done     | Including PDF, email, WhatsApp, cancel           |
| Invoice Generation (bulk)        | Done     | `generateFeeInvoice` endpoint                    |
| Payment Recording (offline)      | Done     | Via `FeeTransactionController`                   |
| Payment Recording (online/Razorpay) | Partial | Triggered from StudentPortal; callback handling needs verification |
| Scholarship Fund Management      | Done     | CRUD complete                                    |
| Scholarship Application Workflow | Done     | 5-step status transitions with endpoints         |
| Cheque/DD Clearance Lifecycle    | Missing  | DDL table exists; no controller/route            |
| Fee Refund Management            | Missing  | Model exists; no controller/route                |
| Dynamic Fee Rule Engine (J10)    | Missing  | Not started                                      |
| Transport/Hostel Fee Integration | Missing  | J5 not implemented                               |
| FormRequests (all)               | Missing  | P1 — must create for all write operations        |
| Service Layer                    | Missing  | P1 — extract FeeInvoiceService, FeeFineService   |
| Feature Tests                    | Missing  | P1 — zero feature tests currently                |
| Seeder Route Removal             | URGENT   | P0 — remove `GET /student-fee/seeder` from routes |
