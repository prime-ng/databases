# FIN — Student Fee Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Roles](#3-stakeholders--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints & Routes](#6-api-endpoints--routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Dependencies](#11-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions](#14-suggestions)
15. [Appendices](#15-appendices)
16. [V1 to V2 Delta](#16-v1-to-v2-delta)

---

## 1. Executive Summary

The StudentFee module (module code: FIN) is the core financial operations engine for Prime-AI tenant schools. It manages the complete fee lifecycle — from defining head-wise fee structures and installment schedules, bulk-assigning fees to students, generating invoices, collecting payments (cash/cheque/online), issuing receipts, processing concessions and scholarships, applying late-payment fines, handling refunds, and producing financial reports.

**Current completion: ~80–90%.** The module has 15 controllers, 23 models, 14 policies, comprehensive views, a console command for fine application, and 24 unit tests. Critical gaps remaining are: an exposed seeder route (P0 security), missing `EnsureTenantHasModule` middleware (P0), zero FormRequest classes (P1), no Service layer (P1), missing controllers for Refund and Cheque/DD lifecycle (P1), and no integration events to the FAC (Accounting) module (D21 contract). These gaps are fully documented in this V2 specification.

**Risk Level: MEDIUM-HIGH** (per gap analysis dated 2026-03-22).

---

## 2. Module Overview

### 2.1 Purpose

StudentFee handles the full financial transaction lifecycle for a school tenant. The key domains are:

- **Configuration:** Fee heads, groups, structures, installment schedules, fine rules.
- **Assignment:** Bulk or individual assignment of fee structures to students per academic session.
- **Billing:** Invoice generation (individual and bulk), concession/scholarship application, fine calculation.
- **Collection:** Offline payment recording, Razorpay online payment, receipt generation.
- **Governance:** Refund management, cheque/DD clearance, defaulter tracking, fee reports, and dashboard.

### 2.2 Module Characteristics

| Attribute            | Value                                                             |
|----------------------|-------------------------------------------------------------------|
| Module Code          | FIN                                                               |
| Laravel Module Name  | `StudentFee` (nwidart/laravel-modules v12)                        |
| Namespace            | `Modules\StudentFee`                                              |
| Domain               | Tenant (school-specific, isolated DB)                             |
| DB Connection        | `tenant` (tenant_{uuid})                                          |
| Table Prefix         | `fee_*` (DDL uses `fee_`; module code is FIN for documentation)   |
| Route Prefix         | `student-fee`                                                     |
| Route Name Prefix    | `student-fee.`                                                    |
| Middleware           | `auth`, `verified`, `EnsureTenantHasModule` (P0 — to be added)   |
| Controllers          | 15 (14 functional + 1 seeder stub to remove)                      |
| Models               | 23                                                                |
| Policies             | 15 registered in AppServiceProvider                               |
| Services             | 0 — all logic inline in controllers (P1 gap)                      |
| FormRequests         | 0 — all validation inline (P1 gap)                                |
| Tests                | 1 Feature (ArchitectureTest) + 23 Unit (model tests)              |
| Payment Gateway      | Razorpay (via PAY module)                                         |
| PDF Generation       | DomPDF (invoice and receipt PDF)                                  |
| Completion           | ~80–90%                                                           |

### 2.3 Position in Platform

```
Platform Layer          Module                  Database
────────────────────────────────────────────────────────
Tenant Scope            StudentFee (FIN)        tenant_{uuid}  ← this module
Tenant Scope            StudentProfile (STD)    tenant_{uuid}  ← source of students
Tenant Scope            SchoolSetup (SCH)       tenant_{uuid}  ← sessions, classes
Tenant Scope            Payment (PAY)           tenant_{uuid}  ← Razorpay gateway
Tenant Scope            Finance/Accounting(FAC) tenant_{uuid}  ← D21 event consumer
Tenant Scope            Notification (NTF)      tenant_{uuid}  ← SMS/email/WhatsApp
Tenant Scope            StudentPortal (STP)     tenant_{uuid}  ← student/parent view
```

---

## 3. Stakeholders & Roles

| Role                  | Access Summary                                                                 | Key Permissions                                      |
|-----------------------|--------------------------------------------------------------------------------|------------------------------------------------------|
| Super Admin           | Full access across all tenants                                                 | All                                                  |
| School Admin          | Full access within tenant — setup, assign, invoice, collect, approve           | All tenant.fee-* permissions                         |
| Accountant / Cashier  | Record payments, generate receipts, view reports; no structural changes        | viewAny, view, create on invoices and transactions   |
| Principal             | Approve concessions and scholarships at Principal level; view reports          | fee-student-concession.approve, fee-scholarship.approve |
| Class Teacher         | View fee status of own class students                                          | fee-invoice.viewAny (own class only)                 |
| Student               | View own invoices and fee status (via StudentPortal)                           | Read-only via API                                    |
| Parent / Guardian     | View child's invoices and make online payments (via StudentPortal)             | Read-only + proceedPayment via API                   |

### 3.1 Permission Keys

| Permission Key                               | Description                                    |
|----------------------------------------------|------------------------------------------------|
| `tenant.fee-head-master.viewAny`             | List fee heads                                 |
| `tenant.fee-head-master.create`              | Create fee head                                |
| `tenant.fee-head-master.update`              | Edit fee head                                  |
| `tenant.fee-head-master.delete`              | Soft-delete fee head                           |
| `tenant.fee-group-master.viewAny`            | List fee groups                                |
| `tenant.fee-group-master.create`             | Create fee group                               |
| `tenant.fee-structure-master.viewAny`        | List fee structures                            |
| `tenant.fee-structure-master.create`         | Create fee structure                           |
| `tenant.fee-structure-master.update`         | Edit fee structure                             |
| `tenant.fee-student-assignment.viewAny`      | List student fee assignments                   |
| `tenant.fee-student-assignment.create`       | Create/assign fee to student                   |
| `tenant.fee-invoice.viewAny`                 | List invoices                                  |
| `tenant.fee-invoice.create`                  | Generate invoice                               |
| `tenant.fee-invoice.update`                  | Cancel/edit invoice                            |
| `tenant.fee-transaction.viewAny`             | List transactions                              |
| `tenant.fee-student-concession.create`       | Apply concession to student                    |
| `tenant.fee-student-concession.approve`      | Approve or reject concession                   |
| `tenant.fee-scholarship.create`              | Create scholarship fund                        |
| `tenant.fee-scholarship-application.approve` | Approve scholarship application                |
| `tenant.fee-fine-transaction.waive`          | Waive applied fine                             |
| `tenant.fee-refund.create`                   | Initiate refund (proposed)                     |
| `tenant.student-fee-management.viewAny`      | View fee dashboard and hub pages               |

### 3.2 Roles vs Permissions Matrix

| Action                            | School Admin | Accountant | Principal | Class Teacher |
|-----------------------------------|:---:|:---:|:---:|:---:|
| View dashboard                    |  Y  |  Y  |  Y  |  N  |
| Create/edit fee structures        |  Y  |  N  |  N  |  N  |
| Bulk assign fee to students       |  Y  |  Y  |  N  |  N  |
| Generate invoices (bulk/single)   |  Y  |  Y  |  N  |  N  |
| Record offline payment            |  Y  |  Y  |  N  |  N  |
| Download invoice PDF / receipt    |  Y  |  Y  |  Y  |  N  |
| Approve concessions               |  Y  |  N  |  Y  |  N  |
| Approve scholarships              |  Y  |  N  |  Y  |  N  |
| Waive fines                       |  Y  |  N  |  Y  |  N  |
| Initiate refund                   |  Y  |  N  |  N  |  N  |
| View fee reports                  |  Y  |  Y  |  Y  |  Y  |

---

## 4. Functional Requirements

Status markers: ✅ Implemented | 🟡 Partial | ❌ Not Started | 📐 Proposed (new in V2)

### FR-FIN-01: Fee Head Master

**Ref:** ST.J1.1.1.1 to ST.J1.1.2.2 | **Status:** ✅

| ID           | Requirement                                                                                          | Status |
|--------------|------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-01.1  | Create fee head with: code (unique, max 30), name (max 100), description, head_type_id (dropdown), frequency (One-time / Monthly / Quarterly / Half-Yearly / Yearly) | ✅ |
| FR-FIN-01.2  | Configure `is_refundable` flag and tax applicability (`tax_applicable`, `tax_percentage` 0–100%)     | ✅     |
| FR-FIN-01.3  | Map `account_head_code` (max 50) for ERP/FAC accounting integration — used in D21 voucher mapping   | ✅     |
| FR-FIN-01.4  | `display_order` integer for UI sort control                                                          | ✅     |
| FR-FIN-01.5  | Soft-delete, restore, force-delete, `is_active` toggle                                               | ✅     |
| FR-FIN-01.6  | Code is unique and immutable after assignment to a fee structure (enforce at application level)       | ✅     |

### FR-FIN-02: Fee Group Master

**Ref:** ST.J1.1 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-02.1  | Create fee group: code (unique), name, description, `is_mandatory` flag, `display_order`              | ✅     |
| FR-FIN-02.2  | Assign fee heads to group via `fee_group_heads_jnt`: mark each head as optional/mandatory, set `default_amount` | ✅ |
| FR-FIN-02.3  | Soft-delete, restore, force-delete, `is_active` toggle                                                | ✅     |
| FR-FIN-02.4  | Missing model: `FeeGroupHeadsJnt` model exists but `fee_concession_applicable_heads` has no model — create `FeeConcessionApplicableHead` model | 📐 |

### FR-FIN-03: Fee Structure Master

**Ref:** ST.J1.2.1.1 to ST.J1.2.2.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-03.1  | Create fee structure for: `academic_session_id` + `class_id` + optional `student_category_id` (General/OBC/SC/ST) + optional `board_type` (CBSE/ICSE/State) | ✅ |
| FR-FIN-03.2  | Unique code (max 50), name (max 100), effective date range (`effective_from`, `effective_to`)         | ✅     |
| FR-FIN-03.3  | Define head-wise amounts per structure in `fee_structure_details` (head_id, group_id, amount, is_optional, tax_included) | ✅ |
| FR-FIN-03.4  | System auto-calculates and stores `total_fee_amount` as sum of all mandatory head amounts             | ✅     |
| FR-FIN-03.5  | One fee structure per (session + class + category) combination enforced at application level           | ✅     |
| FR-FIN-03.6  | Soft-delete blocked if active student assignments exist (`BR-FIN-03`)                                 | ✅     |

### FR-FIN-04: Fee Installment Scheduling

**Ref:** ST.J1.2.2.1, ST.J1.2.2.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-04.1  | Define installment schedule per fee structure: installment number, name (e.g., "Term 1"), `due_date`, `percentage_due` | ✅ |
| FR-FIN-04.2  | `amount_due` auto-calculated from `percentage_due × total_fee_amount`                                 | ✅     |
| FR-FIN-04.3  | Configure `grace_days` per installment; fine applies only after grace period expires                   | ✅     |
| FR-FIN-04.4  | UNIQUE constraint on (`fee_structure_id`, `installment_no`)                                           | ✅     |
| FR-FIN-04.5  | CRUD, soft-delete, `is_active` toggle                                                                 | ✅     |

### FR-FIN-05: Student Fee Assignment

**Ref:** ST.J2.1.1.1 to ST.J2.2.1.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-05.1  | Bulk-assign fee structure to all active students in a class/section for current session (`generateStudentAssignment`) | ✅ |
| FR-FIN-05.2  | Individual assignment: select student → fee structure → confirm opted optional heads and groups (stored as JSON in `opted_heads`, `opted_groups`) | ✅ |
| FR-FIN-05.3  | Mid-year join support: `join_in_mid-year` flag, `fee_start_date`, `proration_percentage`              | ✅     |
| FR-FIN-05.4  | One active assignment per student per academic session (`UNIQUE uq_fee_student_session`)              | ✅     |
| FR-FIN-05.5  | `updateAssignmentStructure` endpoint for mid-year fee structure change with total_fee_amount recalculation | ✅ |
| FR-FIN-05.6  | AJAX endpoint `getSectionsByClass` for dynamic class-to-section UI filtering                          | ✅     |
| FR-FIN-05.7  | Denormalized `class_id` and `section_id` on assignment record for performance (avoids join during invoice generation) | ✅ |
| FR-FIN-05.8  | Bulk generate must be idempotent — skip students who already have an assignment for the session        | 📐     |

### FR-FIN-06: Fee Concession Management

**Ref:** ST.J4.1.1.1 to ST.J4.1.2.2 | **Status:** 🟡

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-06.1  | Create concession type: code, name, `concession_category_id` (Sibling/Merit/Staff/Financial Aid/Sports/Alumni/Other), `discount_type` (Percentage / Fixed Amount), `discount_value`, `applicable_on` (Total Fee / Specific Heads / Specific Groups), `max_cap_amount`, `requires_approval`, `approval_level_role_id` | ✅ |
| FR-FIN-06.2  | Map concession to specific heads or groups in `fee_concession_applicable_heads` (CHECK: exactly one of head_id or group_id is non-null per row) | ✅ |
| FR-FIN-06.3  | Apply concession to student assignment — creates `fee_student_concessions` record                     | ✅     |
| FR-FIN-06.4  | Approval workflow if `requires_approval = true`: Pending → Approved / Rejected; store `approved_by`, `approved_at`, `rejection_reason` | ✅ |
| FR-FIN-06.5  | Approval notification email to approver when concession is submitted (currently missing)              | 🟡     |
| FR-FIN-06.6  | Approved concession auto-applied to `concession_amount` on next invoice generation                    | ✅     |
| FR-FIN-06.7  | Multiple concessions per student assignment allowed; cumulative application subject to total-fee or head-level cap | ✅ |
| FR-FIN-06.8  | `FeeConcessionController` in route file was commented out as missing — concession application route fully restored via `FeeStudentConcessionController` | 🟡 |

### FR-FIN-07: Scholarship Management

**Ref:** ST.J9.1.1.1 to ST.J9.2.2.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-07.1  | Create scholarship fund: code (unique), name, `fund_source`, `sponsor_name`, `total_fund_amount`, `available_fund`, `eligibility_criteria` (JSON), application date range, `max_amount_per_student` | ✅ |
| FR-FIN-07.2  | `requires_renewal` flag with `renewal_criteria` JSON (min_percentage, attendance, annual_review)      | ✅     |
| FR-FIN-07.3  | Student application: select scholarship, provide `application_data` (JSON), attach `documents_submitted` (JSON) | ✅ |
| FR-FIN-07.4  | Application unique per (scholarship_id + student_id + academic_session_id)                           | ✅     |
| FR-FIN-07.5  | Status workflow: Draft → Submitted → Under Review → Approved / Rejected / Waitlisted                  | ✅     |
| FR-FIN-07.6  | Disbursement: `disburse` endpoint — sets `disbursed = 1`, `disbursed_date`, decrements `available_fund`, applies scholarship amount as credit to student fee assignment | ✅ |
| FR-FIN-07.7  | Disbursement blocked if `available_fund < approved_amount`                                            | ✅     |
| FR-FIN-07.8  | New applications blocked after `application_end_date`                                                 | ✅     |
| FR-FIN-07.9  | Full approval history in `fee_scholarship_approval_history` (stage, action, action_by, comments)      | ✅     |

### FR-FIN-08: Fee Invoice Generation

**Ref:** ST.J3.1.1.1 to ST.J3.1.2.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-08.1  | Generate invoice for individual student assignment + installment (or one-time if no installment)      | ✅     |
| FR-FIN-08.2  | Bulk invoice generation for all active assignments in current session (`generateFeeInvoice`)          | ✅     |
| FR-FIN-08.3  | Invoice number auto-generated (unique, stored in `invoice_no`)                                        | ✅     |
| FR-FIN-08.4  | Invoice fields: invoice_date, due_date, base_amount, concession_amount, fine_amount, tax_amount, total_amount, paid_amount, `balance_amount` (GENERATED column: total_amount - paid_amount) | ✅ |
| FR-FIN-08.5  | Invoice status lifecycle: Draft → Published → Partially Paid → Paid → Overdue → Cancelled            | ✅     |
| FR-FIN-08.6  | Invoice PDF download via DomPDF (`fee-invoice/{id}/pdf`)                                              | ✅     |
| FR-FIN-08.7  | Invoice email delivery (`fee-invoice/{id}/email`)                                                     | ✅     |
| FR-FIN-08.8  | Invoice WhatsApp share (`fee-invoice/{id}/whatsapp`)                                                  | ✅     |
| FR-FIN-08.9  | Invoice cancellation with `cancellation_reason` and `cancelled_by` audit trail                        | ✅     |
| FR-FIN-08.10 | Invoice web preview (`fee-invoice/{id}/invoice/view`)                                                 | ✅     |
| FR-FIN-08.11 | Bulk generation must be queued via Laravel Jobs for batches > 100 students (currently synchronous — P2) | 🟡 |
| FR-FIN-08.12 | Backup view `invoice_27_02_2026.blade.php` must be deleted from production resources                  | 📐     |

### FR-FIN-09: Fee Transaction (Payment Recording)

**Ref:** ST.J3.1.1.1, ST.J3.1.1.2, ST.J3.2.1.1 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-09.1  | Record offline payment against invoice: `payment_mode` (Cash / Cheque / DD / UPI / Credit Card / Debit Card / Net Banking / Wallet), `amount`, `payment_reference`, `bank_name`, `cheque_date`, `collected_by`, `guardian_id` (who paid) | ✅ |
| FR-FIN-09.2  | `fine_adjusted` and `concession_adjusted` fields on transaction record                                | ✅     |
| FR-FIN-09.3  | System validates: paid amount does not exceed remaining `balance_amount`; partial payment allowed      | ✅     |
| FR-FIN-09.4  | After each successful transaction: auto-update `invoice.paid_amount` and recalculate status           | ✅     |
| FR-FIN-09.5  | Receipt generated in `fee_receipts` (receipt_no, receipt_format, sent_via) after successful payment   | 🟡     |
| FR-FIN-09.6  | Receipt PDF download via DomPDF (`fee-transaction/{id}/receipt`)                                      | ✅     |
| FR-FIN-09.7  | Online payment initiated via PAY module / Razorpay (`proceedPayment` in StudentPortal)                | 🟡     |
| FR-FIN-09.8  | Gateway log stored in `fee_payment_gateway_logs` (request/response JSON, gateway_transaction_id, order_id, payment_id, status, ip_address) | ✅ |
| FR-FIN-09.9  | All financial write operations must be wrapped in `DB::transaction()` — currently inconsistent (P1)   | 🟡     |
| FR-FIN-09.10 | After successful collection: emit `StudentFeeCollected` event for FAC module to consume (D21 contract — see Section 11) | 📐 |

### FR-FIN-10: Fine Management

**Ref:** ST.J6.1.1.1 to ST.J6.2.1.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-10.1  | Define fine rule: `rule_name`, `applicable_on` (Fee Structure / Installment / Head), `applicable_id`, `fine_type` (Percentage / Fixed / Percentage+Capped), `fine_value`, `fine_calculation_mode` (PerDay / FlatPerTier), `max_fine_amount`, `grace_period_days` | ✅ |
| FR-FIN-10.2  | Tiered fine: `applicable_from_day` and `applicable_to_day` (bracket-based)                           | ✅     |
| FR-FIN-10.3  | Recurring fine: `recurring` flag, `recurring_interval_days`, `max_fine_installments` cap              | ✅     |
| FR-FIN-10.4  | `action_on_expiry`: None / Mark Defaulter / Remove Name / Suspend                                     | ✅     |
| FR-FIN-10.5  | Artisan command `ApplyFines` (nightly scheduler): calculates and creates `fee_fine_transactions` for overdue invoices; must be idempotent | ✅ |
| FR-FIN-10.6  | Fine waiver: `PUT fee-fine-transaction/{id}/waive` with `waiver_reason`, `waived_by`, `waived_at`, `waived_amount` (supports partial waiver) | ✅ |
| FR-FIN-10.7  | Fine auto-added to `invoice.fine_amount` on next invoice regeneration post-due date                   | ✅     |
| FR-FIN-10.8  | `ApplyFines` command scheduler registration must be verified in `Kernel.php` or Laravel 12 scheduler  | 🟡     |

### FR-FIN-11: Cheque / DD Clearance Management

**Ref:** ST.J3 (extension) | **Status:** ❌

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-11.1  | `fee_payment_reconciliation` table tracks cheque/DD lifecycle: Pending Deposit → Deposited → Cleared / Bounced → Resubmitted | ❌ |
| FR-FIN-11.2  | Controller and routes needed: list cheques pending deposit, mark as deposited, mark as cleared/bounced, record `bounce_charge`, `bounce_reason`, `resubmit_date` | ❌ |
| FR-FIN-11.3  | On bounce: revert `invoice.paid_amount` for the bounced transaction amount; create bounce charge fine entry | ❌ |
| FR-FIN-11.4  | Notification to parent/guardian on cheque bounce with requested payment action                        | ❌     |

### FR-FIN-12: Fee Refund Management

**Ref:** ST.J8 | **Status:** ❌

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-12.1  | Initiate refund request: `refund_no` (auto), `original_transaction_id`, `student_id`, `refund_date`, `refund_amount`, `refund_mode`, `refund_reason` | ❌ |
| FR-FIN-12.2  | Approval workflow: Pending → Approved / Rejected → Processed; store `approved_by`, `processed_by`, timestamps | ❌ |
| FR-FIN-12.3  | Only refundable heads (`fee_head_master.is_refundable = 1`) are eligible for refund                   | ❌     |
| FR-FIN-12.4  | Processed refund reduces `invoice.paid_amount` on the linked invoice and updates transaction status to `Refunded` | ❌ |
| FR-FIN-12.5  | Refund only initiable by Accountant or Admin roles                                                    | ❌     |
| FR-FIN-12.6  | Refund record linked to FAC module via D21 event `StudentFeeRefunded` (see Section 11)                | 📐     |

### FR-FIN-13: Name Removal Log

**Ref:** ST.J6.2 | **Status:** 🟡

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-13.1  | When `action_on_expiry = 'Remove Name'` triggers: create `fee_name_removal_log` record with `removal_date`, `removal_reason`, `total_due_at_removal`, `days_overdue`, `triggered_by_rule_id`, `removed_by` | 🟡 |
| FR-FIN-13.2  | Re-admission workflow: record `re_admission_date`, `re_admission_fee_paid`, `re_admission_fee_head_id`, `re_admission_transaction_id`, `re_admitted_by`, `re_activated_date` | ❌ |
| FR-FIN-13.3  | Notify principal/admin when name removal is triggered                                                 | ❌     |

### FR-FIN-14: Fee Reports & Analytics Dashboard

**Ref:** ST.J7.1.1.1 to ST.J8.2.1.2 | **Status:** ✅

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-14.1  | Dashboard: total fee (session), total collected, total outstanding, student count breakdown            | ✅     |
| FR-FIN-14.2  | Defaulter list: invoices with status = Overdue, sortable by amount and due date                       | ✅     |
| FR-FIN-14.3  | Scholar list: approved scholarship applications in current session                                    | ✅     |
| FR-FIN-14.4  | Concession list: approved concessions in current session                                              | ✅     |
| FR-FIN-14.5  | Recent transactions: last 10 successful payments                                                      | ✅     |
| FR-FIN-14.6  | Fee collection chart (month-wise): labels and amounts for chart rendering                             | ✅     |
| FR-FIN-14.7  | Drill-down: `dashboardFeeCollection` endpoint for class-wise or head-wise breakdown                   | ✅     |
| FR-FIN-14.8  | Defaulter history analytics via `fee_defaulter_history`: `defaulter_score` (0–100 AI risk score), `avg_days_late`, `missed_installments`, `name_removed` | 🟡 |
| FR-FIN-14.9  | CSV export for fee collection summary and defaulter list                                               | 📐     |
| FR-FIN-14.10 | Annual fee rollover: ability to copy fee structures from current session to new session with option to adjust amounts | 📐 |

### FR-FIN-15: Seeder Route — Security Removal

| ID           | Requirement                                                                                           | Status |
|--------------|-------------------------------------------------------------------------------------------------------|--------|
| FR-FIN-15.1  | **REMOVE** `Route::get('/seeder', [StudentFeeController::class, 'seederFunction'])` from `routes/tenant.php` immediately | ❌ P0 |
| FR-FIN-15.2  | **REMOVE** `use Faker\Factory as Faker` import from `StudentFeeController.php`                        | ❌ P0  |
| FR-FIN-15.3  | Add `EnsureTenantHasModule` middleware to the `student-fee` route group                               | ❌ P0  |
| FR-FIN-15.4  | If seeder data is needed for local development, move to a named Artisan seeder class (e.g., `FeeSeeder`) guarded by `App::environment('local')` | 📐 |

---

## 5. Data Model

### 5.1 Table Inventory (24 tables, all `fee_` prefix)

| # | Table Name                          | Purpose                                               | Key Columns                                           | Indexes / Constraints                                       |
|---|-------------------------------------|-------------------------------------------------------|-------------------------------------------------------|-------------------------------------------------------------|
| 1 | `fee_head_master`                   | Fee component definitions                             | code(UQ), name, frequency ENUM, is_refundable, tax_percentage, account_head_code | UQ code, idx_type, idx_active |
| 2 | `fee_group_master`                  | Logical groupings of fee heads                        | code(UQ), name, is_mandatory, display_order            | UQ code, idx_active            |
| 3 | `fee_group_heads_jnt`               | Head-to-group mapping                                 | group_id, head_id, is_optional, default_amount         | UQ (group_id, head_id); FK cascade |
| 4 | `fee_structure_master`              | Class+session+category fee template                   | academic_session_id, class_id, student_category_id, board_type, code(UQ), effective_from, effective_to, total_fee_amount | idx session+class, idx_active |
| 5 | `fee_structure_details`             | Head-wise amounts per structure                       | fee_structure_id, head_id, group_id, amount, is_optional, tax_included | UQ (structure_id, head_id) |
| 6 | `fee_installments`                  | Installment schedules per structure                   | fee_structure_id, installment_no, installment_name, due_date, percentage_due, amount_due, grace_days | UQ (structure_id, no) |
| 7 | `fee_fine_rules`                    | Late payment fine configuration                       | applicable_on ENUM, fine_type ENUM, fine_calculation_mode ENUM, grace_period_days, action_on_expiry ENUM | idx_applicable, idx_active |
| 8 | `fee_concession_types`              | Concession type definitions                           | code(UQ), discount_type ENUM, applicable_on ENUM, max_cap_amount, requires_approval, approval_level_role_id | idx_category |
| 9 | `fee_concession_applicable_heads`   | Concession to head/group mapping                      | concession_type_id, head_id (NULL xor group_id)        | UQ (type_id, head_id); UQ (type_id, group_id); CHECK constraint |
| 10| `fee_student_assignments`           | Per-student fee assignment for academic session        | student_id, academic_session_id, fee_structure_id, total_fee_amount, opted_heads(JSON), opted_groups(JSON), join_in_mid-year (note: hyphen in column name — backtick required), proration_percentage | UQ (student_id, session_id) |
| 11| `fee_student_concessions`           | Student concession applications + approval             | student_assignment_id, concession_type_id, approval_status ENUM, discount_amount, approved_by | idx_status |
| 12| `fee_invoices`                      | Generated invoices                                    | invoice_no(UQ), student_assignment_id, installment_id, base_amount, concession_amount, fine_amount, tax_amount, total_amount, paid_amount, balance_amount(GENERATED), status ENUM | idx_status, idx_due_date, idx_student |
| 13| `fee_transactions`                  | Master payment record                                 | transaction_no(UQ), student_id, invoice_id, guardian_id, payment_mode ENUM (Cash/Cheque/DD/UPI/Credit Card/Debit Card/Net Banking/Wallet), amount, fine_adjusted, concession_adjusted, status ENUM, collected_by | idx_student, idx_date, idx_status, idx_mode |
| 14| `fee_transaction_details`           | Head-wise transaction breakdown                       | transaction_id, head_id, amount, fine_amount, concession_amount | UQ (transaction_id, head_id) |
| 15| `fee_receipts`                      | Official receipt records                              | receipt_no(UQ), transaction_id(UQ), receipt_date, receipt_format ENUM, sent_to_parent, sent_via ENUM | idx_receipt_date |
| 16| `fee_fine_transactions`             | Applied fines per overdue invoice                     | student_id, invoice_id, fine_rule_id, fine_date, days_late, fine_amount, waived, waived_amount (partial waiver), waived_by, waiver_reason | idx_student, idx_date, idx_waived |
| 17| `fee_payment_gateway_logs`          | Online payment gateway request/response log           | gateway_name ENUM (Razorpay/Paytm/CCAvenue/BillDesk/Other), gateway_transaction_id, order_id, payment_id, request_payload(JSON), response_payload(JSON), status, ip_address | idx_gateway_trans, idx_order |
| 18| `fee_scholarships`                  | Scholarship fund definitions                          | code(UQ), fund_source, total_fund_amount, available_fund, eligibility_criteria(JSON), application dates, max_amount_per_student, requires_renewal, renewal_criteria(JSON) | idx_active, idx_dates |
| 19| `fee_scholarship_applications`      | Student scholarship applications                      | scholarship_id, student_id, academic_session_id, application_data(JSON), documents_submitted(JSON), status ENUM, approved_amount, disbursed | UQ (scholarship_id, student_id, session_id); idx_status |
| 20| `fee_scholarship_approval_history`  | Approval audit trail                                  | application_id, stage, action_by, action ENUM, comments, action_date | FK cascade on application_id |
| 21| `fee_name_removal_log`              | Students removed due to non-payment                   | student_id, academic_session_id, removal_date, total_due_at_removal, days_overdue, triggered_by_rule_id, removed_by, re_admission columns | idx_student, idx_date |
| 22| `fee_refunds`                       | Refund requests and status                            | refund_no(UQ), original_transaction_id, student_id, refund_amount, refund_mode ENUM, refund_reason, status ENUM, approved_by, processed_by | idx_student, idx_status, idx_date |
| 23| `fee_payment_reconciliation`        | Cheque/DD clearance lifecycle                         | transaction_id(UQ), cheque_no, bank_name, cheque_date, deposit_date, clearance_date, bounce_date, bounce_reason, bounce_charge, resubmit_date, status ENUM | idx_cheque_status, idx_cheque_date |
| 24| `fee_defaulter_history`             | Per-student defaulter analytics per session           | student_id, academic_session_id(UQ per student), total_fine_count, avg_days_late, missed_installments, name_removed, defaulter_score (AI risk 0–100), last_computed_at | UQ (student_id, session_id); idx_score |

### 5.2 Entity Relationship Overview

```
fee_head_master ──── fee_group_heads_jnt ──── fee_group_master
fee_head_master ──── fee_structure_details ──── fee_structure_master
fee_head_master ──── fee_concession_applicable_heads ──── fee_concession_types
fee_structure_master ──── fee_installments
fee_structure_master ──── fee_student_assignments ──── std_students
fee_student_assignments ──── fee_student_concessions ──── fee_concession_types
fee_student_assignments ──── fee_invoices ──── fee_installments
fee_invoices ──── fee_transactions ──── fee_transaction_details ──── fee_head_master
fee_transactions ──── fee_receipts
fee_transactions ──── fee_payment_gateway_logs
fee_transactions ──── fee_payment_reconciliation (cheque/DD)
fee_transactions ──── fee_refunds
fee_fine_rules ──── fee_fine_transactions ──── fee_invoices
fee_scholarships ──── fee_scholarship_applications ──── std_students
fee_scholarship_applications ──── fee_scholarship_approval_history
std_students ──── fee_defaulter_history
std_students ──── fee_name_removal_log
```

### 5.3 Notable DDL Details

- `fee_student_assignments.join_in_mid-year` — hyphen in column name is a DDL artifact; requires backtick quoting in raw SQL and explicit `$table->tinyInteger('join_in_mid-year')` in migrations.
- `fee_invoices.balance_amount` — MySQL GENERATED ALWAYS AS (`total_amount` - `paid_amount`) STORED; cannot be set via Eloquent directly.
- `fee_fine_transactions.waived_amount` — NULL means full waiver when `waived = 1`; a non-NULL value denotes partial waiver.
- `fee_scholarship_applications.academic_session_id` — SMALLINT UNSIGNED to match `sch_org_academic_sessions_jnt.id`.
- `fee_concession_applicable_heads` — CHECK constraint `chk_cah_head_or_group` ensures exactly one of `head_id` or `group_id` is non-null per row.
- `fee_defaulter_history.defaulter_score` — DECIMAL(5,2), intended for AI/predictive analytics module consumption.

### 5.4 Missing Model

| Gap                                           | Severity |
|-----------------------------------------------|----------|
| `FeeConcessionApplicableHead` model missing for `fee_concession_applicable_heads` table | P2 |

---

## 6. API Endpoints & Routes

### 6.1 Existing Web Routes (tenant.php)

| Method | Route                                                 | Controller → Method                                | Gate Permission                               | Status |
|--------|-------------------------------------------------------|----------------------------------------------------|-----------------------------------------------|--------|
| GET    | `student-fee/seeder`                                  | `StudentFeeController@seederFunction`              | **NONE — P0 REMOVE**                          | ❌ P0  |
| GET    | `student-fee/dashboard`                               | `StudentFeeManagementController@dashboard`         | `tenant.student-fee-management.viewAny`       | ✅     |
| GET    | `student-fee/configuration`                           | `StudentFeeManagementController@configuration`     | Hub view                                      | ✅     |
| GET    | `student-fee/assignment`                              | `StudentFeeManagementController@assignment`        | Hub view                                      | ✅     |
| GET    | `student-fee/billing`                                 | `StudentFeeManagementController@billing`           | Hub view                                      | ✅     |
| GET    | `student-fee/payment`                                 | `StudentFeeManagementController@payment`           | Hub view                                      | ✅     |
| GET    | `student-fee/fine-management`                         | `StudentFeeManagementController@fineManagement`    | Hub view                                      | ✅     |
| GET    | `student-fee/scholarship`                             | `StudentFeeManagementController@scholarship`       | Hub view                                      | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-head-master/{id?}`        | `FeeHeadMasterController`                          | `tenant.fee-head-master.*`                    | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-group-master/{id?}`       | `FeeGroupMasterController`                         | `tenant.fee-group-master.*`                   | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-structure-master/{id?}`   | `FeeStructureMasterController`                     | `tenant.fee-structure-master.*`               | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-installment/{id?}`        | `FeeInstallmentController`                         | `tenant.fee-installment.*`                    | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-concession-type/{id?}`    | `FeeConcessionTypeController`                      | `tenant.fee-concession-type.*`                | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-student-concession/{id?}` | `FeeStudentConcessionController`                   | `tenant.fee-student-concession.*`             | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-fine-rule/{id?}`          | `FeeFineRuleController`                            | `tenant.fee-fine-rule.*`                      | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-fine-transaction/{id?}`   | `FeeFineTransactionController`                     | `tenant.fee-fine-transaction.*`               | ✅     |
| PUT    | `student-fee/fee-fine-transaction/{id}/waive`         | `FeeFineTransactionController@waive`               | `tenant.fee-fine-transaction.waive`           | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-student-assignment/{id?}` | `FeeStudentAssignmentController`                   | `tenant.fee-student-assignment.*`             | ✅     |
| POST   | `student-fee/fee-student-assignment/generate/all`     | `FeeStudentAssignmentController@generateStudentAssignment` | Assignment create                     | ✅     |
| GET    | `student-fee/fee-student-assignment/sections/{classId}` | `FeeStudentAssignmentController@getSectionsByClass` | —                                           | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-scholarship/{id?}`        | `FeeScholarshipController`                         | `tenant.fee-scholarship.*`                    | ✅     |
| GET/POST/PUT/DELETE | `student-fee/fee-scholarship-application/{id?}` | `FeeScholarshipApplicationController`         | `tenant.fee-scholarship-application.*`        | ✅     |
| POST   | `student-fee/fee-scholarship-application/{id}/approve` | `FeeScholarshipApplicationController@approve` | `tenant.fee-scholarship-application.approve` | ✅     |
| POST   | `student-fee/fee-scholarship-application/{id}/disburse` | `FeeScholarshipApplicationController@disburse` | `tenant.fee-scholarship-application.approve` | ✅ |
| GET/POST/PUT/DELETE | `student-fee/fee-invoice/{id?}`            | `FeeInvoiceController`                             | `tenant.fee-invoice.*`                        | ✅     |
| POST   | `student-fee/fee-invoice/generate/all`                | `FeeInvoiceController@generateFeeInvoice`          | `tenant.fee-invoice.create`                   | ✅     |
| GET    | `student-fee/fee-invoice/{id}/pdf`                    | `FeeInvoiceController@downloadPdf`                 | `tenant.fee-invoice.view`                     | ✅     |
| POST   | `student-fee/fee-invoice/{id}/email`                  | `FeeInvoiceController@sendEmail`                   | `tenant.fee-invoice.view`                     | ✅     |
| GET    | `student-fee/fee-invoice/{id}/invoice/view`           | `FeeInvoiceController@viewInvoice`                 | `tenant.fee-invoice.view`                     | ✅     |
| PUT    | `student-fee/fee-invoice/{id}/cancel`                 | `FeeInvoiceController@cancel`                      | `tenant.fee-invoice.update`                   | ✅     |
| GET    | `student-fee/fee-transaction`                         | `FeeTransactionController@index`                   | `tenant.fee-transaction.viewAny`              | ✅     |
| GET    | `student-fee/fee-transaction/{id}/receipt`            | `FeeTransactionController@downloadReceipt`         | `tenant.fee-transaction.view`                 | ✅     |

### 6.2 Known Route Bugs

| Bug | File | Severity |
|-----|------|----------|
| `fee-transaction.store` points to `FeeInvoiceController::store` instead of `FeeTransactionController` | tenant.php | P2 |
| `fee-student-concession.trashed` redirects to configuration page instead of actual trash view | tenant.php | P3 |
| `EnsureTenantHasModule` middleware missing from entire `student-fee` route group | tenant.php | P0 |

### 6.3 Missing Routes to Add

| Method | Proposed Route                                    | Controller → Method                       | Purpose                          | Status |
|--------|---------------------------------------------------|-------------------------------------------|----------------------------------|--------|
| GET    | `student-fee/fee-refund`                          | `FeeRefundController@index`               | List refund requests             | 📐     |
| POST   | `student-fee/fee-refund`                          | `FeeRefundController@store`               | Initiate refund                  | 📐     |
| PUT    | `student-fee/fee-refund/{id}/approve`             | `FeeRefundController@approve`             | Approve refund                   | 📐     |
| PUT    | `student-fee/fee-refund/{id}/process`             | `FeeRefundController@process`             | Mark refund as processed         | 📐     |
| GET    | `student-fee/fee-cheque-clearance`                | `FeeChequeController@index`               | List cheques pending clearance   | 📐     |
| PUT    | `student-fee/fee-cheque-clearance/{id}/deposit`   | `FeeChequeController@markDeposited`       | Mark cheque as deposited         | 📐     |
| PUT    | `student-fee/fee-cheque-clearance/{id}/clear`     | `FeeChequeController@markCleared`         | Mark cheque as cleared           | 📐     |
| PUT    | `student-fee/fee-cheque-clearance/{id}/bounce`    | `FeeChequeController@markBounced`         | Record bounce with reason/charge | 📐     |
| GET    | `student-fee/defaulter-history`                   | `FeeDefaulterHistoryController@index`     | View defaulter analytics         | 📐     |

### 6.4 Planned API Endpoints (for StudentPortal / Mobile)

| Method | Endpoint                                       | Description                              | Status |
|--------|------------------------------------------------|------------------------------------------|--------|
| GET    | `/api/v1/student-fee/invoices`                 | List invoices for authenticated student   | 📐     |
| GET    | `/api/v1/student-fee/invoices/{id}`            | Invoice detail                           | 📐     |
| POST   | `/api/v1/student-fee/pay`                      | Initiate Razorpay order for invoice       | 📐     |
| POST   | `/api/v1/student-fee/payment-callback`         | Razorpay webhook / payment callback       | 🟡     |
| GET    | `/api/v1/student-fee/receipt/{id}`             | Download receipt PDF                     | 📐     |
| GET    | `/api/v1/student-fee/dashboard`                | Fee summary for student/parent portal     | 📐     |

---

## 7. UI Screens

| Screen ID   | Screen Name                    | Route                                     | Status |
|-------------|--------------------------------|-------------------------------------------|--------|
| SCR-FIN-01  | Fee Dashboard                  | `student-fee/dashboard`                   | ✅     |
| SCR-FIN-02  | Configuration Hub              | `student-fee/configuration`               | ✅     |
| SCR-FIN-03  | Fee Head Master — List         | `student-fee/fee-head-master`             | ✅     |
| SCR-FIN-04  | Fee Head Master — Create/Edit  | `student-fee/fee-head-master/create`      | ✅     |
| SCR-FIN-05  | Fee Group Master — List/Create | `student-fee/fee-group-master`            | ✅     |
| SCR-FIN-06  | Fee Structure Master — List    | `student-fee/fee-structure-master`        | ✅     |
| SCR-FIN-07  | Fee Structure — Create/Edit    | `student-fee/fee-structure-master/create` | ✅     |
| SCR-FIN-08  | Fee Installment — List/Create  | `student-fee/fee-installment`             | ✅     |
| SCR-FIN-09  | Assignment Hub                 | `student-fee/assignment`                  | ✅     |
| SCR-FIN-10  | Student Fee Assignment — List  | `student-fee/fee-student-assignment`      | ✅     |
| SCR-FIN-11  | Bulk Assignment Generator      | Form within SCR-FIN-09                    | ✅     |
| SCR-FIN-12  | Billing Hub                    | `student-fee/billing`                     | ✅     |
| SCR-FIN-13  | Fee Invoice — List             | `student-fee/fee-invoice`                 | ✅     |
| SCR-FIN-14  | Invoice — View (Web)           | `student-fee/fee-invoice/{id}/invoice/view` | ✅   |
| SCR-FIN-15  | Invoice PDF Download           | `student-fee/fee-invoice/{id}/pdf`        | ✅     |
| SCR-FIN-16  | Concession Type — List/Create  | `student-fee/fee-concession-type`         | ✅     |
| SCR-FIN-17  | Student Concession — List/Apply| `student-fee/fee-student-concession`      | ✅     |
| SCR-FIN-18  | Payment Hub                    | `student-fee/payment`                     | ✅     |
| SCR-FIN-19  | Transaction — List             | `student-fee/fee-transaction`             | ✅     |
| SCR-FIN-20  | Receipt Download               | `student-fee/fee-transaction/{id}/receipt`| ✅     |
| SCR-FIN-21  | Fine Management Hub            | `student-fee/fine-management`             | ✅     |
| SCR-FIN-22  | Fine Rule — List/Create        | `student-fee/fee-fine-rule`               | ✅     |
| SCR-FIN-23  | Fine Transaction — List/Waive  | `student-fee/fee-fine-transaction`        | ✅     |
| SCR-FIN-24  | Scholarship Hub                | `student-fee/scholarship`                 | ✅     |
| SCR-FIN-25  | Scholarship Fund — List/Create | `student-fee/fee-scholarship`             | ✅     |
| SCR-FIN-26  | Scholarship Application — List | `student-fee/fee-scholarship-application` | ✅     |
| SCR-FIN-27  | Refund Management — List/Create| `student-fee/fee-refund`                  | 📐     |
| SCR-FIN-28  | Cheque/DD Clearance — List     | `student-fee/fee-cheque-clearance`        | 📐     |
| SCR-FIN-29  | Defaulter History — Analytics  | `student-fee/defaulter-history`           | 📐     |

### 7.1 View Hygiene Issues

| Issue                                                                 | Severity |
|-----------------------------------------------------------------------|----------|
| `fee-invoice/invoice_27_02_2026.blade.php` — dated backup view exists in production resources | P3 |
| `fee-reciept/index.blade.php` — typo in directory name ("reciept" should be "receipt")        | P3 |

---

## 8. Business Rules

### BR-FIN-01: Fee Structure Uniqueness
- `BR-FIN-01.1` — One fee structure per (academic_session_id + class_id + student_category_id) combination. Enforced at application level; DDL does not have a unique index for this combination (application-level guard required).
- `BR-FIN-01.2` — Fee structure code is globally unique (UQ index on `fee_structure_master.code`).
- `BR-FIN-01.3` — `total_fee_amount` = sum of all non-optional head amounts in `fee_structure_details`.

### BR-FIN-02: Student Assignment
- `BR-FIN-02.1` — A student can have only ONE active fee assignment per academic session (UNIQUE `uq_fee_student_session` on `student_id + academic_session_id`).
- `BR-FIN-02.2` — Fee structure cannot be deleted if it has active student assignments linked to it.
- `BR-FIN-02.3` — Changing a student's fee structure mid-year via `updateAssignmentStructure` must recalculate `total_fee_amount`; existing invoices must be reviewed manually and revised as needed.
- `BR-FIN-02.4` — Mid-year join: `proration_percentage` must be between 0 and 100; `fee_start_date` must be within the academic session dates.

### BR-FIN-03: Invoice Lifecycle
- `BR-FIN-03.1` — Invoice status transitions: Draft → Published (manual or bulk generation) → Partially Paid (partial payment) → Paid (full payment) → Overdue (past due date without full payment) → Cancelled.
- `BR-FIN-03.2` — Cancelled invoices are immutable; no further payment can be recorded against a cancelled invoice.
- `BR-FIN-03.3` — A paid invoice is immutable; status cannot revert except via an approved refund.
- `BR-FIN-03.4` — `balance_amount` is a GENERATED column in MySQL; it cannot be set directly — it is always derived as `total_amount - paid_amount`.

### BR-FIN-04: Late Payment Penalties
- `BR-FIN-04.1` — Fine applies only after `installment.grace_days` from the installment `due_date`.
- `BR-FIN-04.2` — PerDay mode: fine = `fine_value × days_overdue` (from `applicable_from_day` to `applicable_to_day`).
- `BR-FIN-04.3` — FlatPerTier mode: fine = `fine_value` applied once when the overdue period enters that day bracket.
- `BR-FIN-04.4` — Percentage+Capped mode: fine = `(base_amount × fine_value / 100)` capped at `max_fine_amount`.
- `BR-FIN-04.5` — Once `max_fine_amount` is reached, no additional fine is applied for that invoice.
- `BR-FIN-04.6` — `ApplyFines` console command runs nightly; idempotent (checks `fine_date` to avoid duplicate entries for the same day).
- `BR-FIN-04.7` — Fine waiver supports both full waiver (`waived_amount = NULL`) and partial waiver (`waived_amount < fine_amount`).

### BR-FIN-05: Concession Rules
- `BR-FIN-05.1` — Concessions with `requires_approval = true` cannot be applied to invoice calculation until approval status is "Approved".
- `BR-FIN-05.2` — Multiple approved concessions per student assignment are cumulative.
- `BR-FIN-05.3` — Cumulative concession amount is subject to `max_cap_amount` on the concession type (head-level or total-fee cap).
- `BR-FIN-05.4` — Sibling discount eligibility: two or more students share the same `guardian_id` where `std_student_guardian_jnt.is_fee_payer = 1` in the same academic session.
- `BR-FIN-05.5` — Merit concession requires minimum percentage threshold verified against examination results (manual admin verification; no auto-check in V1).
- `BR-FIN-05.6` — Staff concession requires active staff record on file.

### BR-FIN-06: Scholarship Rules
- `BR-FIN-06.1` — `available_fund` decremented on disbursement; disbursement blocked if `available_fund < approved_amount`.
- `BR-FIN-06.2` — New applications blocked after `application_end_date`.
- `BR-FIN-06.3` — Scholarship amount applied as a credit (negative adjustment) to the student fee assignment total, reducing invoiced amount.
- `BR-FIN-06.4` — Renewal evaluation at session start: students not meeting `renewal_criteria` JSON thresholds receive auto-rejection notification.

### BR-FIN-07: Payment and Partial Payment
- `BR-FIN-07.1` — Partial payment allowed; invoice status → "Partially Paid" when `paid_amount > 0` and `paid_amount < total_amount`.
- `BR-FIN-07.2` — Invoice status → "Paid" only when `paid_amount >= total_amount`.
- `BR-FIN-07.3` — Overpayment: if `paid_amount > total_amount`, excess is recorded as advance credit against student account (for adjustment in next invoice or refund).
- `BR-FIN-07.4` — Partial payment does NOT reset due date; late fine continues to accumulate on unpaid balance.
- `BR-FIN-07.5` — All payment write operations (invoice update + transaction insert) must execute within a `DB::transaction()` block to ensure consistency.

### BR-FIN-08: Refund Policy
- `BR-FIN-08.1` — Refund can only be initiated by Accountant or School Admin.
- `BR-FIN-08.2` — Only fee heads with `is_refundable = 1` are eligible for refund.
- `BR-FIN-08.3` — Refund workflow: Pending → Approved → Processed / Rejected.
- `BR-FIN-08.4` — Processed refund reduces linked invoice `paid_amount` and updates transaction status to "Refunded".
- `BR-FIN-08.5` — Refund for online payment (Razorpay) must trigger a Razorpay refund API call.

### BR-FIN-09: Data Immutability
- `BR-FIN-09.1` — Successful payment transactions (`status = Success`) are immutable; no update or delete is permitted.
- `BR-FIN-09.2` — Fine waivers are audited with `waived_by`, `waiver_reason`, and `waived_at`; they cannot be reversed once recorded.
- `BR-FIN-09.3` — All financial operations are logged to `sys_activity_logs`.

### BR-FIN-10: Indian Compliance
- `BR-FIN-10.1` — Tax computation supports all 4 GST slabs: 0%, 5%, 12%, 18%.
- `BR-FIN-10.2` — Fee receipts include school PAN for 80G deduction claims where applicable.
- `BR-FIN-10.3` — RTE (Right to Education) quota students may have zero-amount invoices; system must support zero-amount invoice generation without error.
- `BR-FIN-10.4` — Fee Head `account_head_code` must align with the school's Chart of Accounts in the FAC module.

---

## 9. Workflows

### 9.1 Fee Collection FSM (Invoice Payment State Machine)

```
                ┌─────────────┐
                │    Draft    │ ← invoice created (bulk or individual)
                └──────┬──────┘
                       │ publish() / auto on bulk-generate
                       ▼
                ┌─────────────┐
                │  Published  │ ← sent to student/parent via notification
                └──────┬──────┘
          ┌────────────┼──────────────────┐
          │ partial     │ full payment     │ no payment + past due_date
          ▼ payment     ▼                  ▼
  ┌──────────────┐ ┌──────┐       ┌─────────────┐
  │ Partially    │ │ Paid │       │   Overdue   │ ← ApplyFines runs nightly
  │    Paid      │ └──────┘       └──────┬──────┘
  └──────┬───────┘                       │ further payment
         │ remaining balance paid         ▼
         └──────────────────────► ┌──────────────┐
                                  │    Paid      │
                                  └──────────────┘

  Any status except Paid → Cancelled (manual, with reason)
  Paid → (via approved refund) → invoice paid_amount reduced
```

**State Transition Rules:**
- Draft → Published: manual publish or auto on `generateFeeInvoice` bulk run.
- Published / Overdue → Partially Paid: first partial transaction recorded.
- Partially Paid / Published / Overdue → Paid: `paid_amount >= total_amount`.
- Published / Partially Paid / Overdue → Cancelled: manual cancellation by authorized user with reason.
- Overdue: set by nightly scheduler or by `ApplyFines` command when `due_date + grace_days < today` and status is not Paid or Cancelled.

### 9.2 Concession Approval Workflow

```
Admin/Staff applies concession
        │
        ▼
   requires_approval?
   ┌────┴────┐
   No        Yes
   │          │
   ▼          ▼
 Applied   Status = Pending
 instantly  │
            │  Notification → approver (approval_level_role_id)
            │
       ┌────┴────┐
    Approve    Reject
       │          │
       ▼          ▼
   Status =   Status = Rejected
   Approved   (rejection_reason stored)
       │
       ▼
   Auto-applied to invoice.concession_amount
   on next invoice generation
```

### 9.3 Scholarship Application Lifecycle

```
Student/Staff creates application
        │ (status = Draft)
        │
  submit() endpoint
        │ (status = Submitted)
        │
  Admin marks Under Review
        │ (status = Under Review)
        │
   ┌────┼──────┬──────────┐
Approve  Reject  Waitlist  (Request Info — back to applicant)
   │       │        │
   ▼       ▼        ▼
Approved Rejected Waitlisted
   │
   ▼
 disburse() endpoint
   - decrement available_fund
   - set disbursed = 1, disbursed_date = today
   - apply approved_amount as credit to student fee assignment
   (status remains Approved; disbursed flag separates it)
```

### 9.4 Fine Application (Nightly Scheduler)

```
ApplyFines Artisan Command (runs at 00:30 daily):
  1. Fetch all invoices WHERE status IN (Published, Partially Paid, Overdue)
     AND due_date + grace_days < today
  2. For each invoice:
     a. Fetch applicable fine_rules for the invoice's fee structure/installment/head
     b. Check if fine already applied today (idempotency guard)
     c. Calculate fine per rule (PerDay or FlatPerTier logic)
     d. Insert fee_fine_transactions record
     e. Update invoice.fine_amount += new_fine_amount
     f. If action_on_expiry = 'Mark Defaulter': update/insert fee_defaulter_history
     g. If action_on_expiry = 'Remove Name': insert fee_name_removal_log
  3. Dispatch notification to parent/guardian for each new fine applied
```

### 9.5 Cheque / DD Clearance Workflow (Proposed)

```
Cheque payment recorded in fee_transactions (status = Pending)
        │
        ▼
fee_payment_reconciliation record created (status = Pending Deposit)
        │
  Cashier marks as deposited
        │ (status = Deposited)
        │
   ┌────┴────┐
Cleared    Bounced
   │          │
   ▼          ▼
Status =   Status = Bounced
Cleared    - record bounce_reason, bounce_charge
           - revert invoice.paid_amount for this transaction
           - create bounce_charge fine entry
           - notify parent/guardian
           │
     Resubmit cheque
           │
     Status = Resubmitted → back to Deposited flow
```

### 9.6 D21 Event Contract: FAC Integration

When a fee payment is successfully recorded, FIN emits an application event that FAC (Finance/Accounting) module consumes to create the corresponding accounting voucher.

**Event Name:** `StudentFeeCollected`

**Emitted by:** `FeeTransactionController@store` (and `proceedPayment` callback) after `DB::transaction()` commits.

**Event Payload:**
```php
new StudentFeeCollected(
    tenantId: $tenantId,                     // string (tenant UUID)
    invoiceId: $invoice->id,                 // int
    transactionId: $transaction->id,         // int
    studentId: $transaction->student_id,     // int
    amount: $transaction->amount,            // Decimal
    paymentMode: $transaction->payment_mode, // string ENUM
    paymentDate: $transaction->payment_date, // datetime
    academicSessionId: $assignment->academic_session_id, // int
    headBreakdown: $transactionDetails,      // array[{head_id, account_head_code, amount}]
    collectedBy: $transaction->collected_by, // int (sys_users.id)
)
```

**FAC Listener:** `CreateReceiptVoucher` (in FAC module)
- Creates a Receipt Voucher in `acc_vouchers` (type = Receipt)
- Debits: Cash/Bank ledger (mapped from payment_mode)
- Credits: Fee Income ledger (per head using `account_head_code` → FAC account)
- Links voucher to `fee_transactions.id` via reference number

**Event Name:** `StudentFeeRefunded`

**Emitted by:** `FeeRefundController@process` after refund is marked Processed.

**FAC Listener:** `CreateRefundVoucher`
- Creates a Payment Voucher in `acc_vouchers` (type = Payment)
- Reverses the original Receipt Voucher entries.

**Contract Requirements:**
1. `fee_head_master.account_head_code` must be populated for every fee head used in an active structure.
2. FAC module must have a corresponding ledger account for each `account_head_code`.
3. If FAC listener fails, the fee transaction must NOT be rolled back — use a separate retry queue with dead-letter handling.
4. Event must carry `headBreakdown` array so FAC can post head-wise accounting entries.

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Requirement | Target | Notes |
|-------------|--------|-------|
| Bulk invoice generation | Complete in ≤ 30 seconds for ≤ 100 students | Larger batches must use queued Laravel Jobs (dispatch to `fee-invoice` queue) |
| Dashboard fee aggregation | ≤ 2 seconds | Index on `academic_session_id`, `is_active`, `status` required |
| Invoice PDF generation | ≤ 3 seconds per PDF | Cache generated PDF path in `invoice_pdf_path` for Paid invoices (24-hour TTL) |
| Fee structure list | ≤ 500ms | Paginate at 20 per page; index on session+class |
| N+1 query prevention | 0 N+1 in bulk operations | Eager load `student.assignment.structure.details` in generateStudentAssignment |

### 10.2 Security

| Requirement | Status |
|-------------|--------|
| Remove seeder route `GET /student-fee/seeder` from tenant.php | ❌ P0 — must fix before next deployment |
| Remove `use Faker\Factory as Faker` from StudentFeeController | ❌ P0 |
| Add `EnsureTenantHasModule` middleware to student-fee route group | ❌ P0 |
| Add `Gate::authorize` to `StudentFeeController` and `StudentFeeManagementController` | ❌ P0 |
| All financial write operations require CSRF (handled by web middleware group) | ✅ |
| Invoice/receipt PDF endpoints must verify requesting user's authorization for the student record | ✅ |
| Payment amount must be server-side cross-checked against invoice `balance_amount` on payment recording | 🟡 |
| Concession approval must enforce `approval_level_role_id` defined in the concession type | ✅ |
| All financial multi-table writes must use `DB::transaction()` | 🟡 P1 |

### 10.3 Audit & Compliance

- All financial transactions must be logged to `sys_activity_logs` with `causer_id`, `causer_type`, `event`, `subject_type`, `subject_id`, and `properties` (before/after state).
- Payment transactions with `status = Success` are immutable: no UPDATE or DELETE permitted at application layer.
- Fine waivers must store: waived_by, waiver_reason, waived_at, waived_amount.
- Scholarship disbursements logged in `fee_scholarship_approval_history`.
- All concession approvals logged with approver identity and timestamp.

### 10.4 Scalability

- Fee structure and head lookups must be cached (Laravel Cache, TTL 1 hour) since they rarely change.
- `fee_defaulter_history.defaulter_score` recomputed in background; nightly job should recalculate for sessions with new fine transactions.
- `fee_payment_gateway_logs` is append-only and expected to grow large; add archival policy (move records > 2 years old to cold storage or archive table).

### 10.5 Reliability

- `ApplyFines` command must be idempotent: a re-run on the same day must not create duplicate fine_transactions.
- Bulk invoice generation must be transactional per student: if one student's invoice fails, it must not fail the batch — collect errors and report post-run.
- Razorpay webhook handler must be idempotent: verify `payment_id` is not already recorded before processing.

---

## 11. Dependencies

### 11.1 Incoming Dependencies (FIN consumes these)

| Module | Code | Data / Service Used | Tables Referenced |
|--------|------|---------------------|-------------------|
| StudentProfile | STD | Student list, guardian, fee_payer flag | `std_students`, `std_guardians`, `std_student_guardian_jnt` |
| SchoolSetup | SCH | Academic sessions, classes, sections | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections` |
| SystemConfig | SYS | RBAC roles, dropdown values (fee head type, concession category, student category) | `sys_users`, `sys_roles`, `sys_dropdown_table` |
| Transport | TPT | Transport fee head integration (auto-assign transport fee to enrolled transport students) | `tpt_student_fee_detail`, `tpt_student_fee_collection` |

### 11.2 Outgoing Dependencies (FIN provides data to / emits events for)

| Module | Code | Integration Method | What FIN Provides |
|--------|------|-------------------|--------------------|
| Payment | PAY | `PaymentService::createPayment()` | Razorpay order creation for invoice payment |
| Notification | NTF | `Notification` facade / events | Invoice generated, payment received, due date reminder, fine applied, concession approval |
| StudentPortal | STP | API endpoints + read models | Invoice list, payment initiation, receipt download |
| ParentPortal | PPT | API endpoints | Same as StudentPortal for guardian view |
| Finance/Accounting | FAC | Laravel Event `StudentFeeCollected` → FAC Listener `CreateReceiptVoucher` (D21 contract — see Section 9.6) | Fee collection triggers accounting voucher creation |
| PredictiveAnalytics | PAN | `fee_defaulter_history.defaulter_score` | Defaulter risk scoring feeds ML prediction pipeline |

### 11.3 D21 Event Contract Summary

| Event | Direction | Emitter | Consumer | Trigger |
|-------|-----------|---------|----------|---------|
| `StudentFeeCollected` | FIN → FAC | `FeeTransactionController@store` | `CreateReceiptVoucher` listener | On successful offline or online payment recording |
| `StudentFeeRefunded` | FIN → FAC | `FeeRefundController@process` | `CreateRefundVoucher` listener | On refund status set to Processed |
| `FeeFineApplied` | FIN → NTF | `ApplyFines` command | Notification listener | On each new fine_transaction created |
| `FeeInvoiceGenerated` | FIN → NTF | `FeeInvoiceController@generateFeeInvoice` | Notification listener | On bulk or individual invoice generation |
| `FeeDueReminder` | FIN → NTF | Scheduler (new — 📐) | Notification listener | 3 days before each installment due_date |

### 11.4 External Service Dependencies

| Service | Purpose | Notes |
|---------|---------|-------|
| Razorpay | Online payment gateway | Integrated via PAY module; webhook endpoint must verify Razorpay signature |
| DomPDF | Invoice and receipt PDF generation | Synchronous; must be queued for bulk operations |
| SMS/Email provider | Fee reminders and receipts | Dispatched via NTF module notification queue |

---

## 12. Test Scenarios

### 12.1 Existing Tests (25 total)

| Test File | Type | Covers |
|-----------|------|--------|
| `ArchitectureTest` | Feature | Architecture compliance (no logic in models, service layer convention) |
| `FeeHeadMasterModelTest` | Unit | Model fillable, soft delete, relationships |
| `FeeGroupMasterModelTest` | Unit | Model fillable, soft delete |
| `FeeGroupHeadsJntModelTest` | Unit | Model fillable |
| `FeeStructureMasterModelTest` | Unit | Model fillable, soft delete, relationships |
| `FeeStructureDetailModelTest` | Unit | Model fillable, relationships |
| `FeeInstallmentModelTest` | Unit | Model fillable, relationships |
| `FeeFineRuleModelTest` | Unit | Model fillable, relationships |
| `FeeFineTransactionModelTest` | Unit | Model fillable, relationships |
| `FeeConcessionTypeModelTest` | Unit | Model fillable, soft delete, casts |
| `FeeStudentAssignmentModelTest` | Unit | Model fillable, JSON casts, relationships |
| `FeeStudentConcessionModelTest` | Unit | Model fillable, approval status enum |
| `FeeInvoiceModelTest` | Unit | Model fillable, status enum, relationships |
| `FeeTransactionModelTest` | Unit | Model fillable, relationships |
| `FeeTransactionDetailModelTest` | Unit | Model fillable, relationships |
| `FeeReceiptModelTest` | Unit | Model fillable |
| `FeeFineTransactionModelTest` | Unit | Model fillable, waiver fields |
| `FeePaymentGatewayLogModelTest` | Unit | Model structure |
| `FeePaymentReconciliationModelTest` | Unit | Model structure |
| `FeeScholarshipModelTest` | Unit | Model fillable, JSON casts, relationships |
| `FeeScholarshipApplicationModelTest` | Unit | Model fillable, status enum, relationships |
| `FeeScholarshipApprovalHistoryModelTest` | Unit | Model structure |
| `FeeRefundModelTest` | Unit | Model fillable |
| `FeeDefaulterHistoryModelTest` | Unit | Model structure |
| `FeeNameRemovalLogModelTest` | Unit | Model structure |

### 12.2 Required Feature Tests (Missing — P1)

| Test Scenario | Priority |
|---------------|----------|
| TS-FIN-01: Fee structure creation with head-wise amounts; verify `total_fee_amount` calculated correctly | P1 |
| TS-FIN-02: Bulk student fee assignment for a class; verify all active students receive assignment; duplicate run is idempotent | P1 |
| TS-FIN-03: Generate invoice for a student assignment; verify invoice_no uniqueness, status = Draft | P1 |
| TS-FIN-04: Record partial payment; verify invoice status → Partially Paid; verify `balance_amount` is correct | P1 |
| TS-FIN-05: Record full payment; verify invoice status → Paid; verify transaction receipt is generated | P1 |
| TS-FIN-06: Overpayment: paid_amount > total_amount; verify excess is captured as advance credit | P1 |
| TS-FIN-07: Concession requires approval: apply → Pending; approve → Approved; verify invoice concession_amount updated on next invoice generation | P1 |
| TS-FIN-08: Fine calculation: PerDay mode — invoice 5 days overdue, grace 2 days → fine for 3 days | P1 |
| TS-FIN-09: Fine calculation: FlatPerTier mode — verify single flat fine applied per tier bracket | P1 |
| TS-FIN-10: Fine waiver: full waiver — waived_amount = NULL; partial waiver — waived_amount < fine_amount | P1 |
| TS-FIN-11: Scholarship application lifecycle: Draft → Submitted → Approved → Disbursed; verify available_fund decremented | P1 |
| TS-FIN-12: Scholarship disbursement blocked when available_fund < approved_amount | P1 |
| TS-FIN-13: Invoice cancellation: verify status → Cancelled; further payment recording returns 422 | P1 |
| TS-FIN-14: Seeder route returns 404 or 403 after removal (regression test) | P0 |
| TS-FIN-15: `EnsureTenantHasModule` middleware: request without module active returns 403 | P0 |

### 12.3 Required Integration Tests (Missing — P1)

| Test Scenario | Priority |
|---------------|----------|
| TS-FIN-INT-01: Razorpay payment callback; verify invoice paid, transaction created, receipt generated, `StudentFeeCollected` event dispatched | P1 |
| TS-FIN-INT-02: `StudentFeeCollected` event received by FAC listener; verify `acc_vouchers` receipt entry created with correct debit/credit | P1 |
| TS-FIN-INT-03: `ApplyFines` command: run against overdue invoice; verify idempotency on second run | P1 |
| TS-FIN-INT-04: Bulk invoice generation for 100+ students dispatches to queue rather than running synchronously | P2 |
| TS-FIN-INT-05: Cheque bounce workflow: mark bounced → invoice paid_amount reverted, bounce charge fine created, parent notified | P2 |

---

## 13. Glossary

| Term | Definition |
|------|------------|
| Fee Head | A single component of school fees (e.g., Tuition, Transport, Hostel, Library, Sports). Defined in `fee_head_master`. |
| Fee Group | A logical bundle of fee heads (e.g., "Academic Package"). Defined in `fee_group_master`. |
| Fee Structure | A template defining amounts for all fee heads for a specific class + academic session + student category combination. |
| Fee Installment | A scheduled portion of the annual fee, due on a specific date. Each installment has a percentage of total fee and grace days. |
| Student Assignment | The record linking a student to a fee structure for an academic session. One per student per session. |
| Invoice | A billing document generated against a student's fee assignment for a specific installment (or one-time). |
| Transaction | A payment record against an invoice. May be partial or full. |
| Receipt | An official acknowledgement of a payment transaction. Generated in `fee_receipts` after successful payment. |
| Concession | A discount applied to a student's fee. May require approval. Categorized as Sibling, Merit, Staff, Financial Aid, Sports, Alumni. |
| Scholarship | A fund-backed financial aid for students. Has eligibility criteria, application workflow, and disbursement step. |
| Fine | A late payment penalty applied to overdue invoices per fine rule configuration. |
| Fine Waiver | Administrative cancellation or reduction of an applied fine. Tracked with reason and approver. |
| Defaulter | A student with one or more overdue invoices. Tracked in `fee_defaulter_history`. |
| Name Removal | An escalation action on persistent non-payment — student's name removed from class register. |
| Proration | Proportional fee reduction for mid-year joins based on remaining months of the academic session. |
| D21 Event Contract | The formal agreement between FIN and FAC modules: FIN emits `StudentFeeCollected` event; FAC creates accounting voucher in response. |
| balance_amount | GENERATED column in `fee_invoices` = `total_amount - paid_amount`. Read-only; computed by MySQL. |
| account_head_code | A code on `fee_head_master` that maps the fee head to a corresponding account ledger in the FAC module. |
| PerDay Fine | Fine calculated as `fine_value × days_overdue` from `applicable_from_day` to `applicable_to_day`. |
| FlatPerTier Fine | A fixed fine amount applied once when the overdue period enters a configured day bracket. |
| Percentage+Capped | Fine = `base_amount × fine_percentage / 100`, capped at `max_fine_amount`. |
| RTE | Right to Education quota — students in this quota may receive zero-fee or heavily discounted fee structures. |

---

## 14. Suggestions

The following improvements are proposed for V2 implementation based on code analysis, gap analysis, and architectural review.

### 14.1 P0 — Critical (Fix Before Next Deployment)

| ID | Suggestion | File / Location |
|----|------------|-----------------|
| SUG-FIN-P0-01 | **Remove seeder route** `Route::get('/seeder', ...)` from tenant.php immediately. Create `database/seeders/FeeSeeder.php` guarded by `App::environment('local')` for dev data. | `routes/tenant.php:378` |
| SUG-FIN-P0-02 | **Remove** `use Faker\Factory as Faker` from StudentFeeController; remove `seederFunction()` method entirely. | `StudentFeeController.php:27` |
| SUG-FIN-P0-03 | **Add** `EnsureTenantHasModule` middleware to the `student-fee` route group. | `routes/tenant.php:376` |
| SUG-FIN-P0-04 | **Add** `Gate::authorize` calls to `StudentFeeController` and `StudentFeeManagementController` hub methods. | Both controllers |

### 14.2 P1 — High (Current Sprint)

| ID | Suggestion | Benefit |
|----|------------|---------|
| SUG-FIN-P1-01 | **Create Service Layer**: extract `FeeInvoiceService` (invoice generation, cancellation, PDF), `FeeFineService` (fine calculation, waiver), `FeeScholarshipService` (application workflow, disbursement), `FeeConcessionService` (concession application, approval). | Controllers ≤ 100 lines; testable business logic; SRP compliance |
| SUG-FIN-P1-02 | **Create FormRequest classes** for all 14+ controllers: `StoreFeeHeadRequest`, `UpdateFeeHeadRequest`, `StoreFeeGroupRequest`, `StoreFeeStructureRequest`, `StoreFeeInstallmentRequest`, `StoreFeeInvoiceRequest`, `StoreFeeAssignmentRequest`, `StoreScholarshipRequest`, `StoreScholarshipApplicationRequest`, `StoreConcessionTypeRequest`, `StoreFineRuleRequest`, `StoreTransactionRequest`, `StoreRefundRequest`. | Consistent validation errors, reusable, testable |
| SUG-FIN-P1-03 | **Wrap all financial write operations in `DB::transaction()`**: payment recording (transaction + invoice update), invoice generation, scholarship disbursement, fine waiver. | Prevents data inconsistency on partial failures |
| SUG-FIN-P1-04 | **Implement `FeeRefundController`** with routes for initiate/approve/process lifecycle. | Closes P1 gap; supports refund workflow end-to-end |
| SUG-FIN-P1-05 | **Implement `FeeChequeController`** with routes for cheque/DD clearance lifecycle using `fee_payment_reconciliation`. | Closes P1 gap; essential for schools using cheque payments |
| SUG-FIN-P1-06 | **Add feature tests** for invoice generation, payment recording, concession approval, fine calculation, and scholarship lifecycle. | Zero feature test coverage is high risk for a financial module |
| SUG-FIN-P1-07 | **Fix permission prefix mismatch**: standardize all permissions to `tenant.fee-*` pattern and remove any inconsistency between route names (`student-fee.*`) and Gate permissions (`tenant.fee-*`). | Consistent RBAC enforcement |
| SUG-FIN-P1-08 | **Fix route bug**: `fee-transaction.store` must point to `FeeTransactionController::store` not `FeeInvoiceController::store`. | Incorrect routing causes payment recording failures |
| SUG-FIN-P1-09 | **Implement D21 Event Contract**: create `StudentFeeCollected` and `StudentFeeRefunded` events in `Modules/StudentFee/Events/`; register listeners in `StudentFeeServiceProvider`. | Enables FAC accounting integration |
| SUG-FIN-P1-10 | **Verify `ApplyFines` scheduler registration** in `app/Console/Kernel.php` (or Laravel 12 scheduler config); confirm it runs daily at 00:30. | Fine enforcement is only effective if the command actually runs |

### 14.3 P2 — Medium (Next Sprint)

| ID | Suggestion | Benefit |
|----|------------|---------|
| SUG-FIN-P2-01 | Add `SoftDeletes` to `FeeGroupHeadsJnt`, `FeeStructureDetail`, `FeeInstallment`, `FeeFineTransaction` (DDL has `deleted_at` columns). | Consistent soft-delete pattern |
| SUG-FIN-P2-02 | Create `FeeConcessionApplicableHead` model for `fee_concession_applicable_heads` table. | Missing model prevents Eloquent relationship usage |
| SUG-FIN-P2-03 | Queue bulk invoice generation (> 100 students) via `GenerateFeeInvoicesJob` on `fee-invoice` queue. | Prevents HTTP timeouts for large schools |
| SUG-FIN-P2-04 | Add CSV export for fee collection summary and defaulter list. | Accounting staff need export for external reconciliation |
| SUG-FIN-P2-05 | Add caching for `fee_head_master`, `fee_structure_master`, `fee_concession_types` (Laravel Cache, 1 hour TTL, invalidate on write). | Reduces DB load on high-frequency lookups |
| SUG-FIN-P2-06 | Register policies for `FeeReceipt`, `FeeRefund`, `FeePaymentReconciliation`, `FeeDefaulterHistory`. | Closes authorization gap for new controllers |
| SUG-FIN-P2-07 | Delete backup view `fee-invoice/invoice_27_02_2026.blade.php` from production resources. | View hygiene; reduces confusion |
| SUG-FIN-P2-08 | Fix directory typo: rename `fee-reciept/` to `fee-receipt/` in view resources. | Correctness and clarity |
| SUG-FIN-P2-09 | Implement `FeeDefaulterHistoryController` with nightly recomputation job for `defaulter_score`. | Enables defaulter analytics and feeds PAN module |
| SUG-FIN-P2-10 | Concession approval notification: on submit, notify the `approval_level_role_id` user via NTF module. | Currently missing; approval requests go unnoticed |

### 14.4 P3 — Low (Backlog)

| ID | Suggestion | Benefit |
|----|------------|---------|
| SUG-FIN-P3-01 | Fee rollover feature: copy fee structures (with optional amount adjustment %) from one academic session to the next. | Saves admin time at session start |
| SUG-FIN-P3-02 | Due date reminder notifications: 3 days before each installment due_date, send SMS/email to fee_payer guardian. | Reduces defaults proactively |
| SUG-FIN-P3-03 | Fix `fee-student-concession.trashed` redirect to show actual trash view instead of configuration page. | UX correctness |
| SUG-FIN-P3-04 | Dynamic Fee Rule Engine (J10): rule builder for attribute-based fee calculation (class, category, board) with simulation. | Long-term feature for automated fee setup |
| SUG-FIN-P3-05 | Transport/Hostel fee auto-integration (J5): when a student is assigned to a transport route or hostel room, auto-assign the corresponding fee head. | Reduces manual fee configuration |
| SUG-FIN-P3-06 | Receipt format selection: Standard / Detailed / Tax Invoice (already supported in `fee_receipts.receipt_format` ENUM). | Expose in UI |

---

## 15. Appendices

### 15.1 Controller Inventory

| Controller | File | Primary Responsibility | Lines (approx.) |
|------------|------|------------------------|-----------------|
| `StudentFeeController` | `StudentFeeController.php` | **DELETE seederFunction; stub only** | ~130 |
| `StudentFeeManagementController` | `StudentFeeManagementController.php` | Dashboard and hub navigation | ~80 |
| `FeeHeadMasterController` | `FeeHeadMasterController.php` | Fee head CRUD + toggle | ~150 |
| `FeeGroupMasterController` | `FeeGroupMasterController.php` | Fee group CRUD + toggle | ~150 |
| `FeeStructureMasterController` | `FeeStructureMasterController.php` | Fee structure CRUD + toggle | ~200 |
| `FeeInstallmentController` | `FeeInstallmentController.php` | Installment CRUD + toggle | ~130 |
| `FeeConcessionTypeController` | `FeeConcessionTypeController.php` | Concession type CRUD + toggle | ~140 |
| `FeeStudentConcessionController` | `FeeStudentConcessionController.php` | Student concession apply + approve/reject | ~160 |
| `FeeFineRuleController` | `FeeFineRuleController.php` | Fine rule CRUD + toggle | ~150 |
| `FeeFineTransactionController` | `FeeFineTransactionController.php` | Fine transaction list + waive | ~140 |
| `FeeStudentAssignmentController` | `FeeStudentAssignmentController.php` | Assignment CRUD + bulk generate + section AJAX | ~200 |
| `FeeScholarshipController` | `FeeScholarshipController.php` | Scholarship fund CRUD + toggle | ~160 |
| `FeeScholarshipApplicationController` | `FeeScholarshipApplicationController.php` | Application CRUD + submit/approve/reject/waitlist/disburse | ~250 |
| `FeeInvoiceController` | `FeeInvoiceController.php` | Invoice CRUD + bulk generate + PDF + email + cancel | ~300 |
| `FeeTransactionController` | `FeeTransactionController.php` | Transaction list + receipt download | ~100 |

### 15.2 FormRequest Specifications

**StoreFeeHeadRequest:**
```
code:           required|string|max:30|unique:fee_head_master,code
name:           required|string|max:100
head_type_id:   required|exists:sys_dropdown_table,id
frequency:      required|in:One-time,Monthly,Quarterly,Half-Yearly,Yearly
is_refundable:  nullable|boolean
tax_applicable: nullable|boolean
tax_percentage: nullable|numeric|min:0|max:100|required_if:tax_applicable,1
account_head_code: nullable|string|max:50
display_order:  nullable|integer|min:1
```

**StoreFeeStructureMasterRequest:**
```
academic_session_id:  required|exists:sch_org_academic_sessions_jnt,id
class_id:             required|exists:sch_classes,id
student_category_id:  nullable|exists:sys_dropdown_table,id
code:                 required|string|max:50|unique:fee_structure_master,code
name:                 required|string|max:100
effective_from:       required|date
effective_to:         nullable|date|after:effective_from
```

**StoreFeeInvoiceRequest:**
```
student_assignment_id: required|exists:fee_student_assignments,id
installment_id:        nullable|exists:fee_installments,id
invoice_date:          required|date
due_date:              required|date|after_or_equal:invoice_date
base_amount:           required|numeric|min:0
concession_amount:     nullable|numeric|min:0
fine_amount:           nullable|numeric|min:0
tax_amount:            nullable|numeric|min:0
status:                required|in:Draft,Published
```

**StoreTransactionRequest:**
```
invoice_id:          required|exists:fee_invoices,id
payment_date:        required|date_format:Y-m-d H:i:s
payment_mode:        required|in:Cash,Cheque,DD,UPI,Credit Card,Debit Card,Net Banking,Wallet
amount:              required|numeric|min:0.01|lte:invoice.balance_amount (custom rule)
payment_reference:   nullable|string|max:100|required_if:payment_mode,Cheque|required_if:payment_mode,DD
bank_name:           nullable|string|max:100|required_if:payment_mode,Cheque|required_if:payment_mode,DD
cheque_date:         nullable|date|required_if:payment_mode,Cheque|required_if:payment_mode,DD
guardian_id:         nullable|exists:std_guardians,id
remarks:             nullable|string|max:500
```

### 15.3 Policy Map

| Policy | Model | Registered in AppServiceProvider |
|--------|-------|-----------------------------------|
| `StudentFeeManagementPolicy` | `FeeHeadMaster` (virtual) | ✅ line ~745 |
| `FeeHeadMasterPolicy` | `FeeHeadMaster` | ✅ |
| `FeeGroupMasterPolicy` | `FeeGroupMaster` | ✅ |
| `FeeStructureMasterPolicy` | `FeeStructureMaster` | ✅ |
| `FeeInstallmentPolicy` | `FeeInstallment` | ✅ |
| `FeeConcessionTypePolicy` | `FeeConcessionType` | ✅ |
| `FeeStudentConcessionPolicy` | `FeeStudentConcession` | ✅ |
| `FeeFineRulePolicy` | `FeeFineRule` | ✅ |
| `FeeFineTransactionPolicy` | `FeeFineTransaction` | ✅ |
| `FeeStudentAssignmentPolicy` | `FeeStudentAssignment` | ✅ |
| `FeeScholarshipPolicy` | `FeeScholarship` | ✅ |
| `FeeScholarshipApplicationPolicy` | `FeeScholarshipApplication` | ✅ |
| `FeeInvoicePolicy` | `FeeInvoice` | ✅ |
| `FeeTransactionPolicy` | `FeeTransaction` | ✅ |
| `FeeMasterPolicy` | (no controller) | ✅ — P3 clean up |
| `FeeRefundPolicy` | `FeeRefund` | ❌ — needs registration |
| `FeeReceiptPolicy` | `FeeReceipt` | ❌ — needs registration |
| `FeePaymentReconciliationPolicy` | `FeePaymentReconciliation` | ❌ — needs registration |
| `FeeDefaulterHistoryPolicy` | `FeeDefaulterHistory` | ❌ — needs registration |

### 15.4 Effort Estimation

| Priority | Items | Effort (person-days) |
|----------|-------|---------------------|
| P0 — Critical (4 items) | Remove seeder route, Faker import, add EnsureTenantHasModule, add Gate::authorize | 0.5 |
| P1 — High (10 items) | Service layer, FormRequests, DB transactions, Refund controller, Cheque controller, Feature tests, Permission fix, Route bug fix, D21 events, Scheduler verify | 10 |
| P2 — Medium (10 items) | SoftDeletes fixes, missing model, queue jobs, CSV export, caching, policy registration, view cleanup, DefaulterHistory controller | 6 |
| P3 — Low (6 items) | Fee rollover, due reminders, concession redirect fix, dynamic rule engine, transport/hostel integration, receipt format UI | 5 |
| **Total** | **30 items** | **21.5 person-days** |

---

## 16. V1 to V2 Delta

| Area | V1 State | V2 Additions / Changes |
|------|----------|------------------------|
| Document scope | Basic extraction from code scan | Full FULL-mode: DDL + code + gap analysis integrated |
| Completion estimate | ~50% | Revised to ~80–90% (based on actual controller/model count) |
| Security (P0) | Listed seeder route as issue | FR-FIN-15 added as standalone functional requirement block; SUG-FIN-P0-01 to 04 with exact file locations |
| EnsureTenantHasModule | Not mentioned | Added as P0 gap in FR-FIN-15.3, Section 6.2, Section 10.2 |
| FAC Integration | Mentioned as `account_head_code` mapping only | Full D21 event contract documented: event name, payload schema, FAC listener, `StudentFeeCollected` + `StudentFeeRefunded` events (Section 9.6, Section 11.3) |
| Cheque/DD lifecycle | Mentioned as missing | FR-FIN-11 added with full table mapping; `fee_payment_reconciliation` DDL documented (note: DDL names table fee_payment_reconciliation but comment calls it fee_cheque_clearance); Workflow 9.5 added |
| Refund management | FR listed but no workflow | FR-FIN-12 expanded; Workflow referenced in BR-FIN-08; SUG-FIN-P1-04 added |
| Name removal log | Partially documented | FR-FIN-13 added with re-admission workflow columns from DDL |
| Data model | 23 tables listed | 24 tables with full column details, GENERATED column note, CHECK constraint note, DDL bug (hyphen in column name) documented |
| Workflows | None | 6 workflow FSMs added (Sections 9.1–9.6) |
| Defaulter history | Mentioned | FR-FIN-14.8 + `fee_defaulter_history.defaulter_score` for AI/PAN module; SUG-FIN-P2-09 |
| Gateway log table | Mentioned | Full DDL column list including JSON fields, multiple gateway support (Razorpay/Paytm/CCAvenue/BillDesk) |
| API endpoints | 3 planned | Section 6.4 with 6 planned API routes; Razorpay webhook idempotency requirement added |
| UI screens | Not inventoried | 29 screens inventoried (SCR-FIN-01 to SCR-FIN-29) with status markers |
| Test coverage | 24 tests listed | 25 tests (corrected); 15 feature tests + 5 integration tests specified (Section 12.2, 12.3) |
| Suggestions | Gap analysis only | 30 actionable suggestions organized by priority with file locations |
| Service layer plan | "Must be extracted" | Named services specified: FeeInvoiceService, FeeFineService, FeeScholarshipService, FeeConcessionService |
| FormRequest specs | 5 request specs | 13 FormRequests named; 4 full specs in Appendix 15.2 |
| Policy map | Not inventoried | Full policy map (19 entries) with registration status in Appendix 15.3 |
| Route bugs | 2 bugs listed | 3 route bugs documented in Section 6.2 |
| RTE quota | Mentioned in Indian compliance | Explicitly added to BR-FIN-10.3 |
| GST compliance | Mentioned | BR-FIN-10.1 to 10.4 with 80G receipt requirement |
