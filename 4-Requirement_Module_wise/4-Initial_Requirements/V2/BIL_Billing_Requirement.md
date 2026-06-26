# Billing Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** BIL  |  **Module Path:** `Modules/Billing/`
**Module Type:** Prime  |  **Database:** `prime_db`
**Table Prefix:** `bil_*`  |  **Processing Mode:** FULL
**RBS Reference:** PD (Billing & Invoicing)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/BIL_Billing_Requirement.md`
**Gap Analysis:** `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/Billing_Deep_Gap_Analysis.md`
**Generation Batch:** 1/10

---

## TABLE OF CONTENTS
1. Executive Summary
2. Module Overview
3. Stakeholders & Actors
4. Functional Requirements
5. Data Model & Entity Specification
6. API & Route Specification
7. UI Screen Inventory & Field Mapping
8. Business Rules & Domain Constraints
9. Workflow & State Machine Definitions
10. Non-Functional Requirements
11. Cross-Module Dependencies
12. Test Case Reference & Coverage
13. Glossary & Terminology
14. Additional Suggestions
15. Appendices
16. V1 → V2 Delta Summary

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
The Billing module manages the complete SaaS billing lifecycle for Prime-AI school tenants. It handles invoice generation from billing schedules, payment recording (individual and consolidated), payment reconciliation, email delivery of invoices via queued jobs, and a full audit trail of all billing events. The module operates on `prime_db` (central database) and serves Super Admins managing multiple school subscriptions.

### 1.2 Module Statistics

| Metric | Count | Source |
|--------|-------|--------|
| RBS Functionalities | 14 | RBS Module V |
| RBS Tasks | 21 | RBS Module V |
| RBS Sub-Tasks | 54 | RBS Module V |
| Database Tables (bil_*) | 4 | DDL prime_db_v2.sql |
| Supporting Table (prm_billing_cycles) | 1 | BillingCycle model |
| Total Tables Managed | 5 | DDL + Models |
| Web Routes | 49 | routes/web.php |
| API Routes | 0 | routes/api.php (empty) |
| UI View Files | 27+ | resources/views/ |
| Controllers | 6 | Code (InvoicingController is stub) |
| Models | 6 | Code |
| Form Request Classes | 3 | Code |
| Jobs | 1 | SendInvoiceEmailJob |
| Mail Classes | 1 | InvoiceMail |
| Policies | 7 | Code |
| Tests (Unit) | 1 file, ~55 test cases | tests/Unit/ |
| Feature Tests | 0 | Not found |
| Total Gap Issues | 40 | Gap Analysis 2026-03-22 |
| P0 Critical Issues | 7 | Gap Analysis |
| P1 High Issues | 13 | Gap Analysis |

### 1.3 Implementation Status

| Feature Area | Status | Completion % | Gap Issues |
|-------------|--------|:---:|--------|
| Billing Cycle Master CRUD | ✅ Implemented | 95% | Minor (MDL-05) |
| Invoice Generation Engine | 🟡 Partial | 80% | SEC-02, ERR-04, FRQ-01 |
| Billing Management Dashboard | 🟡 Partial | 75% | SEC-01, SEC-03, INP-03 |
| Individual Payment Recording | 🟡 Partial | 70% | ERR-01, INP-01, INP-06 |
| Consolidated Payment | 🟡 Partial | 65% | ERR-02, INP-02, FRQ-03 |
| Payment Reconciliation | ✅ Implemented | 85% | — |
| Invoice PDF & ZIP Download | 🟡 Partial | 80% | INP-04, PERF (ZIP sync) |
| Invoice Email (Immediate + Scheduled) | 🟡 Partial | 75% | FRQ-02, LOG-02 |
| Billing Audit Log | 🟡 Partial | 70% | DB-01, MDL-01, MDL-02 |
| Policy / Authorization | ❌ Critical Gaps | 30% | POL-01, POL-02, SEC-03–09 |
| Service Layer | ❌ Not Started | 0% | SVC-01, SVC-02 |
| Usage Metering & Overage | ❌ Not Started | 0% | — |
| Payment Gateway (Razorpay) | ❌ Not Started | 0% | SEC-004 (webhook behind auth) |
| Tenant Billing Portal | ❌ Not Started | 0% | — |
| Compliance / GST Reports | ❌ Not Started | 0% | — |
| Automated Invoice Scheduler | ❌ Not Started | 0% | — |
| **Overall** | 🟡 **Partial** | **~55%** | **40 issues** |

### 1.4 V2 Key Changes vs V1
- Every confirmed gap from the 2026-03-22 deep audit is captured as a `❌` FR item with Gap Reference
- Policy conflict analysis (POL-01 through POL-06) elevated to dedicated FR items
- Service layer requirement (FR-BIL-020) added as new high-priority FR
- DB schema corrections required for 5 tables documented in Section 5
- Authorization gap FRs (FR-BIL-016 through FR-BIL-019) are new in V2
- Webhook security gap (SEC-004 — webhook behind auth middleware) documented in Section 10

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose
Prime-AI is a multi-tenant SaaS platform sold to Indian K-12 schools on subscription. Each school (tenant) is assigned a plan with a billing cycle. The Billing module's purpose is to:

1. Maintain billing cycle masters (Monthly, Quarterly, Yearly, One-Time).
2. Allow Super Admins to generate invoices for due billing schedule entries — each invoice captures the subscription period, student count (actual users cross-queried from the tenant's isolated DB via `Tenancy::initialize()`), plan rate, discounts, extra charges, and up to four configurable tax lines (CGST, SGST, IGST, or other).
3. Record payments — individually per invoice or consolidated across multiple invoices in a single transaction.
4. Toggle payment reconciliation status to track whether gateway confirmations have been matched.
5. Email invoices as PDF attachments via a queued job (`SendInvoiceEmailJob`), with optional future scheduling.
6. Maintain a billing audit log (`bil_tenant_invoicing_audit_logs`) recording every invoice lifecycle event (GENERATED, Partially Paid, Notice Sent, etc.) with JSON event detail.
7. Provide print and PDF export of invoices, subscription summaries, consolidated payments, payment reconciliation, and audit note reports.

### 2.2 Key Features Summary

| # | Feature Area | Description | RBS Ref | Status |
|---|-------------|-------------|---------|--------|
| 1 | Billing Cycle Master | CRUD for billing cycle types with soft delete and restore | F.V1.1 | ✅ Implemented |
| 2 | Invoice Generation | Generate invoices from billing schedule; auto-calculates taxes, net payable | F.V3.1 | 🟡 Partial |
| 3 | Billing Management Dashboard | Unified view with tabs: invoices, subscriptions, payments, consolidated, reconciliation, audit | F.V3.1 | 🟡 Partial |
| 4 | Individual Payment Recording | Add payment per invoice with mode, transaction ID, reconciliation flag | F.V3.2 | 🟡 Partial |
| 5 | Consolidated Payment | Record single payment across multiple invoices in one transaction | F.V3.2 | 🟡 Partial |
| 6 | Payment Reconciliation | Toggle reconciliation status per payment record | F.V3.2.2 | ✅ Implemented |
| 7 | Invoice PDF & ZIP Download | Bulk download of multiple invoices as a ZIP of DomPDF-generated PDFs | F.V6.2 | 🟡 Partial |
| 8 | Invoice Email (Immediate + Scheduled) | Queue-based email with PDF attachment | F.V3.1.2 | 🟡 Partial |
| 9 | Billing Audit Log | Per-invoice event log with action_type, JSON event_info | F.V7.1 | 🟡 Partial |
| 10 | Subscription Detail Views | Inline AJAX panels: subscription, pricing, billing schedule, module list | F.V2.1 | 🟡 Partial |
| 11 | Print Views | Print-friendly views for all data types | F.V6.2 | ✅ Implemented |
| 12 | Usage Metering & Overage | Track API calls, storage, apply overage billing | F.V4 | ❌ Not Started |
| 13 | Gateway Integration | Razorpay webhook, multi-currency, online payment | F.V5 | ❌ Not Started |
| 14 | Compliance Reports | GST reports, country-wise billing summaries | F.V7.2 | ❌ Not Started |

### 2.3 Menu Navigation Path
- **Central Admin Panel > Subscription & Billing** (`/subscription-billing`) — main entry point
- **Central Admin > Billing > Billing Management** (`/billing/billing-management`) — invoice and payment hub
- **Central Admin > Billing > Billing Cycle** (`/billing/billing-cycle`) — cycle master CRUD
- **Central Admin > Sales Plan Management > #billing tab** — redirect target after billing cycle create/update

### 2.4 Module Architecture

```
Modules/Billing/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── BillingCycleController.php          (CRUD + soft delete/restore, toggleStatus)
│   │   │   ├── BillingManagementController.php     (Invoice hub ~800+ lines — GOD controller)
│   │   │   ├── InvoicingController.php             (stub — all methods empty)
│   │   │   ├── InvoicingPaymentController.php      (individual + consolidated payments, PDF)
│   │   │   ├── SubscriptionController.php          (subscription PDF download, AJAX panels)
│   │   │   └── InvoicingAuditLogController.php     (audit note CRUD, event info, PDF)
│   │   ├── Requests/
│   │   │   ├── BillingCycleRequest.php             (clean implementation)
│   │   │   ├── StoreInvoicePaymentRequest.php      (partial — controller bypasses validation)
│   │   │   └── ConsolidatedPaymentRequest.php      (partial — missing array field rules)
│   │   └── Policies/ (7 policy classes — duplicate registrations = critical bug)
│   ├── Jobs/
│   │   └── SendInvoiceEmailJob.php                 (ShouldQueue)
│   ├── Mail/
│   │   └── InvoiceMail.php
│   ├── Models/
│   │   ├── BillingCycle.php                        (→ prm_billing_cycles)
│   │   ├── BilTenantInvoice.php                    (→ bil_tenant_invoices; DUPLICATE fillable bug)
│   │   ├── BillOrgInvoicingModulesJnt.php          (→ bil_tenant_invoicing_modules_jnt)
│   │   ├── InvoicingPayment.php                    (→ bil_tenant_invoicing_payments)
│   │   ├── InvoicingAuditLog.php                   (→ bil_tenant_invoicing_audit_logs; FK name mismatch)
│   │   └── BillTenatEmailSchedule.php              (→ bil_tenant_email_schedules; typo in class name)
│   └── Providers/
│       ├── BillingServiceProvider.php
│       ├── EventServiceProvider.php
│       └── RouteServiceProvider.php
├── database/seeders/BillingDatabaseSeeder.php      (empty)
├── resources/views/
│   ├── billing-cycle/ (create, edit, index, trash)
│   └── billing-management/ (index + 20+ partials)
├── routes/
│   ├── web.php   (stub — actual routes in app routes/web.php)
│   └── api.php   (empty)
└── tests/
    └── Unit/BillingModuleTest.php  (~55 test cases, Pest syntax, Unit only)
```

---

## 3. STAKEHOLDERS & ACTORS

| Role | Scope | Responsibilities in this Module |
|------|-------|--------------------------------|
| Super Admin | Central (prime_db) | Full access: generate invoices, record payments, send emails, manage billing cycles, view all reports |
| Prime Accountant | Central | Record payments, download PDFs, toggle reconciliation, add audit notes |
| Prime Manager | Central | View billing dashboard, view invoices and subscriptions, download reports |
| School Admin (Tenant) | Tenant | Currently no self-service portal (RBS F.V6 not implemented) |
| System (Queue Worker) | Automated | Execute `SendInvoiceEmailJob` — generates PDF and sends email to tenant |
| System (Scheduler) | Automated | (Planned) Run scheduled invoice generation via Artisan command — not yet implemented |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-BIL-001: Billing Cycle Master — Full CRUD (F.V1.1)
**RBS Reference:** F.V1.1  |  **Priority:** High  |  **Status:** ✅ Implemented
**Owner Screen:** `/billing/billing-cycle`  |  **Table:** `prm_billing_cycles`

#### Description
Manages billing cycle types used to define billing frequency. Supports MONTHLY, QUARTERLY, YEARLY, ONE_TIME with `months_count` value and `is_recurring` flag.

#### Requirements

**REQ-BIL-001.1: Create Billing Cycle**
| Attribute | Detail |
|-----------|--------|
| Actors | Super Admin |
| Preconditions | Authenticated with `prime.billing-cycle.create` permission |
| Trigger | POST `/billing/billing-cycle` |
| Input | short_name (unique, max 50), name (max 50), months_count (1-255), description (nullable), is_active (bool), is_recurring (bool) |
| Processing | Validate via BillingCycleRequest; create record; write sys_activity_logs |
| Output | Redirect to sales-plan-mgmt#billing with success flash |
| Error Handling | Unique constraint on short_name — validation error returned |

**REQ-BIL-001.2: Edit/Update Billing Cycle**
| Attribute | Detail |
|-----------|--------|
| Trigger | PUT `/billing/billing-cycle/{billingCycle}` |
| Input | Same as create; short_name unique ignoring current record |
| Processing | BillingCycleRequest validation; update; activity log |

**REQ-BIL-001.3: Soft Delete / Restore / Force Delete**
| Attribute | Detail |
|-----------|--------|
| Trigger | DELETE, GET trashed, GET restore, DELETE force-delete |
| Processing | destroy() sets is_active=false then soft-deletes; forceDelete() catches Throwable (FK violation) |

**REQ-BIL-001.4: Toggle Active Status**
| Attribute | Detail |
|-----------|--------|
| Trigger | POST `/billing/billing-cycle/{billingCycle}/toggle-status` |
| Output | JSON `{success: true, is_active: bool, message: string}` |

**Acceptance Criteria:**
- [x] ST.V1.2.2.1 — Activate plan for sale — ✅ Implemented (toggleStatus)
- [x] ST.V1.2.2.2 — Retire old plan versions — ✅ Implemented (soft delete)

**Implementation:**
| Layer | File | Method |
|-------|------|--------|
| Controller | BillingCycleController.php | index, create, store, edit, update, destroy, trashed, restore, forceDelete, toggleStatus |
| Model | BillingCycle.php | table=prm_billing_cycles; SoftDeletes |
| Request | BillingCycleRequest.php | Unique short_name with ignore on update |
| Policy | BillingCyclePolicy.php | prime.billing-cycle.* permissions |
| Views | billing-cycle/ | create, edit, index, trash |

---

### FR-BIL-002: Subscription Plan View & Download (F.V2.1)
**RBS Reference:** F.V2.1  |  **Priority:** High  |  **Status:** 🟡 Partial
**Owner Screen:** `/billing/billing-management?type=subscription_data`

#### Description
Read-only view of tenant plan assignments. Actual plan assignment and pricing live in the Prime module. Billing module provides detail panels and PDF ZIP download.

**REQ-BIL-002.1: View Subscription Data Tab**
| Attribute | Detail |
|-----------|--------|
| Trigger | GET `/billing/billing-management?type=subscription_data` |
| Processing | buildSubscriptionQuery() filters on tenantPlan.status and start_date range |
| Output | Paginated list (10 per page) |

**REQ-BIL-002.2: Subscription Detail Panels (AJAX)**
Three inline panels: subscription details, pricing details, billing schedule.
| Trigger | GET `billing/subscription-details?id=`, `billing/pricing-details?id=`, `billing/billing-details?id=` |
| Output | JSON `{html: string}` |

**REQ-BIL-002.3: Module Details Panel**
| Trigger | GET `billing/module-details?id=&type=subscription|invoice` |
| Processing | type=subscription → TenantPlanModule; type=invoice → BillOrgInvoicingModulesJnt |

**REQ-BIL-002.4: Subscription PDF ZIP Download**
| Trigger | POST `/billing/subscription` with `ids[]` |
| Processing | For each ID: DomPDF from subscription PDF view; add to ZipArchive |

**Acceptance Criteria (Not Started):**
- [ ] ST.V2.1.2.1 — Enable trial period — ❌ Not Started
- [ ] ST.V2.1.2.2 — Auto-convert trial to paid — ❌ Not Started
- [ ] ST.V2.2.1.1 — Auto-renew subscription — ❌ Not Started
- [ ] ST.V2.2.2.1 — Switch plan mid-cycle — ❌ Not Started
- [ ] ST.V2.2.2.2 — Apply prorated charges — ❌ Not Started

---

### FR-BIL-003: Invoice Generation Engine (F.V3.1.1)
**RBS Reference:** F.V3.1.1  |  **Priority:** Critical  |  **Status:** 🟡 Partial
**Owner Screen:** `/billing/billing-management` (default tab)
**Tables:** `prm_tenant_plan_billing_schedule`, `bil_tenant_invoices`, `bil_tenant_invoicing_modules_jnt`, `bil_tenant_invoicing_audit_logs`

#### Description
Core billing engine. Generates invoices for selected billing schedule records. Cross-queries tenant DB to count active students. Applies plan rate, minimum billing qty, discounts, extra charges, and up to 4 tax lines.

**REQ-BIL-003.1: Generate Invoice for Selected Schedule Records**
| Attribute | Detail |
|-----------|--------|
| Actors | Super Admin |
| Preconditions | `prime.billing-management.create` permission; schedule record not already billed |
| Trigger | POST `/billing/billing-management` with `ids[]` array of schedule IDs |
| Processing | (1) Find schedule; (2) Find TenantPlanRate for date range; (3) Tenancy::initialize() to count students; (4) billing_qty = max(min_billing_qty, total_user_qty); (5) Calculate sub_total, discount, extra_charges, tax1-4, net_payable; (6) invoice_no = `INV-YYYYMMDD-NNN`; (7) payment_due_date = invoice_date + credit_days; (8) Create bil_tenant_invoices; (9) Set schedule.bill_generated=1; (10) Insert bil_tenant_invoicing_modules_jnt rows; (11) Create GENERATED audit log |
| Output | JSON `{status: true, success_ids: [], failed_ids: [{id, reason}]}` |
| Transaction | DB::transaction wrapping full generation |

**REQ-BIL-003.2: Invoice Listing and Filtering**
| Attribute | Detail |
|-----------|--------|
| Trigger | GET `/billing/billing-management` |
| Processing | buildMainBillingQuery() on TenantPlanBillingSchedule; filters: data_type, status, invoice_status, date_range |
| Output | Paginated 10 per page |

**REQ-BIL-003.3: Invoice Details Panel (AJAX)**
| Trigger | GET `billing/invoice-details?id={invoice_id}` |
| Output | JSON `{html: string}` |

**REQ-BIL-003.4: Invoice Remarks**
| Trigger | GET `billing/invoice/remarks?id=&type=` / POST `billing/invoice/remarks/update` |

**REQ-BIL-003.5: Automated Invoice Scheduler — ❌ Not Started**
| Attribute | Detail |
|-----------|--------|
| Description | Artisan command to auto-generate invoices when billing_schedule_date = today |
| Status | ❌ Not Started — no Artisan command or scheduled job |

**Acceptance Criteria:**
- [x] ST.V3.1.1.1 — Create recurring invoice — ✅ Implemented (is_recurring flag)
- [ ] ST.V3.1.1.2 — Include addons/overage — 🟡 Partial (extra_charges field exists; no auto overage)
- [x] ST.V3.1.1.3 — Apply taxes as per region — ✅ Implemented (4 configurable tax lines)
- [ ] ST.V3.1.2.1 — Schedule monthly/annual billing — ❌ Not Started
- [ ] ST.V3.1.2.2 — Send reminders for unpaid invoices — 🟡 Partial (manual only)

---

### FR-BIL-004: Invoice Email Delivery (F.V3.1.2)
**RBS Reference:** F.V3.1.2  |  **Priority:** High  |  **Status:** 🟡 Partial
**Tables:** `bil_tenant_email_schedules`, `bil_tenant_invoicing_audit_logs`

**REQ-BIL-004.1: Immediate Email Send**
| Attribute | Detail |
|-----------|--------|
| Trigger | POST `/billing/billing-management/send-email` with `ids[]` |
| Processing | Loop ids; dispatch SendInvoiceEmailJob per ID; job generates DomPDF, sends InvoiceMail |
| Output | JSON `{status: true, message: 'Emails queued successfully!'}` |

**REQ-BIL-004.2: Scheduled Email**
| Attribute | Detail |
|-----------|--------|
| Trigger | POST `/billing/billing-management/schedule-email` with `id` and `schedule_time` |
| Processing | Create BillTenatEmailSchedule (status='pending'); dispatch SendInvoiceEmailJob with ->delay(); create 'Notice Sent' audit log |
| Output | JSON `{status: true, message: "Email scheduled for DD Mon YYYY HH:MM AM/PM"}` |

---

### FR-BIL-005: Invoice PDF & ZIP Download (F.V6.2)
**RBS Reference:** F.V6.2.1  |  **Priority:** High  |  **Status:** 🟡 Partial

**REQ-BIL-005.1: Bulk Invoice PDF ZIP Download**
| Attribute | Detail |
|-----------|--------|
| Preconditions | `prime.billing-management.pdf` permission |
| Trigger | POST `/billing/billing-management/pdfs` with `ids[]` |
| Processing | For each ID: load BilTenantInvoice; DomPDF from invoicing/pdf view; save temp file; add to ZipArchive; unlink ZIP after download |
| Output | ZIP binary response `Content-Type: application/zip` |

**REQ-BIL-005.2: Print Views**
| Trigger | GET `/billing/billing-management/print/data?type={type}` |
| Types | default (invoices), subscription_data, consolidated-payment, payment-reconcilation, invoice_payment, audit-note |

---

### FR-BIL-006: Individual Payment Recording (F.V3.2.1)
**RBS Reference:** F.V3.2.1  |  **Priority:** Critical  |  **Status:** 🟡 Partial
**Tables:** `bil_tenant_invoicing_payments`, `bil_tenant_invoices`, `bil_tenant_invoicing_audit_logs`

**REQ-BIL-006.1: Record Individual Payment**
| Attribute | Detail |
|-----------|--------|
| Preconditions | `prime.invoicing-payment.create`; invoice exists |
| Trigger | POST `/billing/invoicing-payment` |
| Input | tenant_invoice_id, date, amount_paid, currency, payment_mode, pay_mode_other, transaction_id, payment_status, payment_reconciled, gateway_resp, remarks |
| Processing | Validate via StoreInvoicePaymentRequest; create InvoicingPayment; update invoice.paid_amount += amount_paid; update invoice.status; create 'Partially Paid' audit log |
| Transaction | DB::beginTransaction / DB::commit |
| Output | JSON `{status: true, message: 'Payment saved successfully!'}` |

**REQ-BIL-006.2: Add Payment AJAX Panel**
| Trigger | GET `billing/invoicing-payment/create?id={invoice_id}` |
| Output | JSON `{html: string}` from add-payment partial |

**REQ-BIL-006.3: Payment Details Panel**
| Trigger | GET `billing/payment-details?id={invoice_id}` |
| Output | JSON `{html: string}` listing InvoicingPayment records |

**Acceptance Criteria:**
- [x] ST.V3.2.1.2 — Record offline payment (NEFT/Cash) — ✅ Implemented

---

### FR-BIL-007: Consolidated Payment (F.V3.2.1)
**RBS Reference:** F.V3.2.1  |  **Priority:** High  |  **Status:** 🟡 Partial
**Tables:** `bil_tenant_invoicing_payments`, `bil_tenant_invoices`, `bil_tenant_invoicing_audit_logs`

**REQ-BIL-007.1: Record Consolidated Payment**
| Attribute | Detail |
|-----------|--------|
| Trigger | POST `billing/consolidated-store` |
| Input | payment_dates, payment_mode, transaction_id, amount_paid (total), invoice_ids[], new_payment[invoice_id], payment_status[invoice_id] |
| Processing | Validate via ConsolidatedPaymentRequest; loop invoice_ids; skip if allocation=0; create InvoicingPayment per invoice; update paid_amount; create PAYMENT_UPDATED audit per invoice |
| Transaction | DB::beginTransaction / DB::commit |

**REQ-BIL-007.2: Consolidated Payment PDF**
| Trigger | GET `billing/download-consolidated-pdf` with filters |
| Processing | Filter BilTenantInvoice where paid_amount != net_payable_amount; DomPDF |

---

### FR-BIL-008: Payment Reconciliation (F.V3.2.2)
**RBS Reference:** F.V3.2.2  |  **Priority:** High  |  **Status:** ✅ Implemented
**Tables:** `bil_tenant_invoicing_payments`

**REQ-BIL-008.1: Toggle Reconciliation Status**
| Attribute | Detail |
|-----------|--------|
| Preconditions | `prime.billing-management.status` permission |
| Trigger | AJAX POST `billing/billing-management/{session}/toggle-status` |
| Processing | Find InvoicingPayment; toggle payment_reconciled; save; activityLog |
| Output | JSON `{success: true, data: {payment_reconciled: bool}}` |

**REQ-BIL-008.2: Reconciliation PDF Download**
| Trigger | POST `billing/download-selected-pdf` with `ids[]` |
| Processing | Load InvoicingPayment with invoice.tenant; DomPDF from payment-reconcilation/pdf |

**Acceptance Criteria:**
- [ ] ST.V3.2.2.1 — Match payment with invoice automatically — 🟡 Partial (manual toggle only)
- [ ] ST.V3.2.2.2 — Flag mismatched transactions — 🟡 Partial (reconciled=false flag; no automation)

---

### FR-BIL-009: Invoice Audit Log (F.V7.1)
**RBS Reference:** F.V7.1.1, F.V7.1.2  |  **Priority:** High  |  **Status:** 🟡 Partial
**Tables:** `bil_tenant_invoicing_audit_logs`

**REQ-BIL-009.1: View Audit Log for Invoice (AJAX)**
| Trigger | GET `billing/billing/audit-log?id={invoice_id}` |
| Output | JSON `{html: string}`; logs ordered DESC by created_at |

**REQ-BIL-009.2: Add/Update Audit Note**
| Trigger | GET `billing/audit/add-note?id=` / POST `billing/audit/add-note/update` |

**REQ-BIL-009.3: View Event Info JSON Detail**
| Trigger | GET `billing/audit/event-info?id=` via InvoicingAuditLogController::auditEventInfo() |

**REQ-BIL-009.4: Audit Log Report (PDF)**
| Trigger | GET `billing/audit/download-pdf` |
| Filters | date_range, tenant_id, performed_by, audit_status |

---

### FR-BIL-010: Usage Metering & Overage Billing (F.V4)
**RBS Reference:** F.V4.1, F.V4.2  |  **Priority:** Medium  |  **Status:** ❌ Not Started

**Acceptance Criteria (all Not Started):**
- [ ] ST.V4.1.1.1 — Monitor API calls
- [ ] ST.V4.1.1.2 — Track storage consumption
- [ ] ST.V4.1.2.1 — Notify tenant when nearing limits
- [ ] ST.V4.1.2.2 — Auto-lock premium features when exceeded
- [ ] ST.V4.2.1.1 — Multiply usage above threshold
- [ ] ST.V4.2.1.2 — Apply overage invoice line items

---

### FR-BIL-011: Payment Gateway Integration — Razorpay (F.V5)
**RBS Reference:** F.V5.1, F.V5.2  |  **Priority:** High  |  **Status:** ❌ Not Started
**Note:** `gateway_response` JSON column exists on payments table. `razorpay/razorpay` v2.9 is in composer.

**Acceptance Criteria (all Not Started):**
- [ ] ST.V5.1.1.1 — Add API keys for Razorpay
- [ ] ST.V5.1.1.2 — Set webhook URL for payment confirmation
- [ ] ST.V5.1.2.1 — Send test payment request
- [ ] ST.V5.1.2.2 — Verify webhook response
- [ ] ST.V5.2.1.1 — Configure supported currencies
- [ ] ST.V5.2.1.2 — Set exchange rate source

---

### FR-BIL-012: Tenant Billing Portal (F.V6)
**RBS Reference:** F.V6.1, F.V6.2  |  **Priority:** Medium  |  **Status:** ❌ Not Started

**Acceptance Criteria (all Not Started):**
- [ ] ST.V6.1.1.1 — Display invoices list (tenant view)
- [ ] ST.V6.1.1.2 — Filter by paid/unpaid
- [ ] ST.V6.2.1.1 — Download invoice PDF (tenant-facing)
- [ ] ST.V6.2.2.1 — Redirect to online payment gateway
- [ ] ST.V6.2.2.2 — Update payment status in system

---

### FR-BIL-013: Compliance & GST Reports (F.V7.2)
**RBS Reference:** F.V7.2.1  |  **Priority:** Medium  |  **Status:** ❌ Not Started

**Acceptance Criteria (all Not Started):**
- [ ] ST.V7.2.1.1 — GST/Tax reports
- [ ] ST.V7.2.1.2 — Country-wise billing summaries

---

### FR-BIL-014: ❌ Fix Duplicate Policy Registrations (Gap: POL-01, POL-02)
**Gap Reference:** POL-01, POL-02  |  **Priority:** P0 Critical  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
In `AppServiceProvider.php`, `BilTenantInvoice::class` is registered with TWO policies (lines 617-618): `BillingManagementPolicy` is overwritten by `InvoicingPolicy`. Similarly, `InvoicingPayment::class` is registered with FOUR policies (lines 620-623); only the last (`InvoicingPaymentPolicy`) is effective. All other policies are dead code.

Controllers call `Gate::authorize('prime.billing-management.*')` which are string abilities NOT defined in the surviving `InvoicingPolicy` — meaning all `Gate::authorize()` calls in `BillingManagementController` resolve to nothing.

#### Requirements
- Remove duplicate `Gate::policy()` registrations — one model = one policy
- Use `Gate::define()` for string-ability checks (e.g., `prime.billing-management.create`) OR redesign policy methods to match the ability strings called by controllers
- Delete or merge dead policy classes: `BillingManagementPolicy`, `ConsolidatedPaymentPolicy`, `PaymentReconciliationPolicy`, `SubscriptionPolicy`
- Verify `ConsolidatedPaymentPolicy` references non-existent `App\Models\ConsolidatedPayment` (POL-03) — fix model reference
- Verify `PaymentReconciliationPolicy` references non-existent `App\Models\PaymentReconciliation` (POL-04) — fix model reference

---

### FR-BIL-015: ❌ Fix FK Column Name Mismatch in Audit Log (Gap: DB-01, MDL-01)
**Gap Reference:** DB-01, MDL-01  |  **Priority:** P0 Critical  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
DDL defines column `tenant_invoice_id` on `bil_tenant_invoicing_audit_logs`. The `InvoicingAuditLog` model `$fillable` array uses `tenant_invoicing_id`. All controller code that inserts audit log entries uses `tenant_invoicing_id`. On a fresh DB with the correct DDL, all audit log inserts will silently fail (column not found or null constraint violation).

#### Requirements
- Align model `$fillable` to use `tenant_invoice_id` (matching DDL), OR update DDL to `tenant_invoicing_id`
- Update all controller insert calls to use the correct column name
- Add cast for `event_info` → `'array'` on InvoicingAuditLog (Gap: MDL-02)
- Add cast for `action_date` → `'datetime'` on InvoicingAuditLog (Gap: MDL-03)

---

### FR-BIL-016: ❌ Add Authorization to All Unprotected Controller Methods (Gap: SEC-01–09)
**Gap Reference:** SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06, SEC-07, SEC-08, SEC-09  |  **Priority:** P0/P1 Critical  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
Multiple controller methods have NO authorization check, allowing any authenticated user to perform billing operations or view any tenant's data.

| Gap | Controller | Method | Issue |
|-----|-----------|--------|-------|
| SEC-01 | BillingManagementController | `index()` | `Gate::any()` used incorrectly with `\|\|` operator |
| SEC-02 | BillingManagementController | `store()` | Has `Gate::authorize` but uses raw `Request` (no FormRequest) |
| SEC-03 | BillingManagementController | `subscriptionDetails()`, `invoiceDetails()`, `moduleDetails()`, `view()` | NO Gate::authorize — exposes any tenant data |
| SEC-04 | BillingManagementController | `printData()` | Partial Gate check — not all sub-paths protected |
| SEC-05 | InvoicingPaymentController | `paymentDetails()` | NO Gate::authorize |
| SEC-06 | InvoicingAuditLogController | `auditAddNote()` | NO Gate::authorize |
| SEC-07 | InvoicingAuditLogController | `auditAddNoteUpdate()` | NO Gate::authorize — anyone can update notes |
| SEC-08 | InvoicingAuditLogController | `auditEventInfo()` | NO Gate::authorize |
| SEC-09 | InvoicingAuditLogController | `downloadAuditNotePdf()` | NO Gate::authorize |

#### Requirements
- Add `Gate::authorize()` or `$this->authorize()` to each listed method before business logic
- Fix `Gate::any()` usage in `index()` — replace with `Gate::check()` or individual ability checks
- Ensure all AJAX endpoints verify authorization before returning HTML data

---

### FR-BIL-017: ❌ Add try/catch to All DB Transactions (Gap: ERR-01, ERR-02)
**Gap Reference:** ERR-01, ERR-02  |  **Priority:** P0 Critical  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
`InvoicingPaymentController::store()` (line 52) and `consolidatedStore()` (line 158) both call `DB::beginTransaction()` but have NO `try/catch` block. Any exception leaves the transaction open and never rolls back, causing data inconsistency.

#### Requirements
- Wrap `DB::beginTransaction()` in `try { ... DB::commit(); } catch (\Throwable $e) { DB::rollBack(); ... }` pattern in both methods
- Also fix `generateInvoiceForOrganization()` (Gap ERR-04): returns bare `false` on failure instead of `['status' => false, 'message' => ...]`; caller at line 611 checks `$result['status']` which throws array access on bool
- Fix `printData()` consolidated-payment path (Gap ERR-03): `$totalPayable = $recordPayment->getCollection()->sum(...)` — `->get()` returns Collection not Paginator; `getCollection()` does not exist on Collection

---

### FR-BIL-018: ❌ Fix Duplicate $fillable Fields in BilTenantInvoice (Gap: DB-07)
**Gap Reference:** DB-07  |  **Priority:** P0 Critical  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
`BilTenantInvoice.php` `$fillable` array has duplicate entries: `paid_amount`, `currency`, `status`, `credit_days`, `payment_due_date`, `is_recurring`, `auto_renew`, `remarks` each appear TWICE (lines 20-69). While Laravel silently handles duplicates, it is a latent bug risk and indicates the array was concatenated without deduplication.

#### Requirements
- Remove duplicate entries from `BilTenantInvoice::$fillable`
- Add missing standard columns to DDL (Gap: DB-02, DB-03, DB-04, DB-05, DB-06):
  - `bil_tenant_invoices`: add `created_by` column
  - `bil_tenant_invoicing_payments`: add `created_by`, `deleted_at`, `is_active` columns
  - `bil_tenant_invoicing_audit_logs`: add `updated_at`, `is_active`, `created_by`, `deleted_at` columns
  - `bil_tenant_invoicing_modules_jnt`: add `is_active`, `created_by`, `deleted_at` columns
  - `bil_tenant_email_schedules`: add `is_active`, `created_by`, `deleted_at` columns

---

### FR-BIL-019: ❌ Fix FormRequest Gaps (Gap: FRQ-01–04)
**Gap Reference:** FRQ-01, FRQ-02, FRQ-03, FRQ-04  |  **Priority:** P1 High  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
Several mutation endpoints accept raw `Request` instead of validated `FormRequest`, bypassing all input validation.

| Gap | Issue |
|-----|-------|
| FRQ-01 | `BillingManagementController::store()` uses raw `Request` — no FormRequest for invoice generation |
| FRQ-02 | `sendEmail()`, `scheduleEmail()`, `downloadPDF()` accept raw `Request` |
| FRQ-03 | `ConsolidatedPaymentRequest` missing rules for `invoice_ids[]`, `new_payment[]`, `payment_status[]` arrays |
| FRQ-04 | `StoreInvoicePaymentRequest` exists but controller accesses `$request->date` instead of `$request->validated()['date']` |

Also: `$request->all()` is stored inside audit `event_info` JSON (INP-06) — leaks all request data including potentially sensitive fields.

#### Requirements
- Create `GenerateInvoiceRequest` FormRequest for `store()` — validate `ids[]` as array of existing schedule IDs
- Create `SendEmailRequest` FormRequest — validate `ids[]`
- Create `ScheduleEmailRequest` FormRequest — validate `id`, `schedule_time` (future datetime)
- Create `DownloadPDFRequest` FormRequest — validate `ids[]`
- Add rules for `invoice_ids`, `new_payment`, `payment_status` arrays to `ConsolidatedPaymentRequest`
- Replace `$request->all()` in audit event_info with whitelisted fields only

---

### FR-BIL-020: ❌ Extract BillingService (Gap: SVC-01, SVC-02)
**Gap Reference:** SVC-01, SVC-02  |  **Priority:** P1 High  |  **Status:** ❌ Not Started
**🆕 New in V2**

#### Description
Zero service classes exist. All business logic lives in controllers. `BillingManagementController::generateInvoiceForOrganization()` is ~170 lines of complex business logic. `Tenancy::initialize()/end()` is called directly in the controller.

#### Requirements
- Create `Modules\Billing\Services\BillingService` with methods:
  - `generateInvoice(int $scheduleId): array` — extracts generateInvoiceForOrganization()
  - `recordPayment(array $data): InvoicingPayment` — extracts payment logic
  - `countTenantStudents(Tenant $tenant): int` — encapsulates Tenancy::initialize()/end() pattern
- BillingService can be injected into both the controller and the future automated scheduler Artisan command
- Tenancy context must always be enclosed: initialize → query → end (no leak risk)

---

### FR-BIL-021: ❌ Fix Razorpay Webhook Security (Gap: SEC-004)
**Gap Reference:** SEC-004 (from Gap Analysis context)  |  **Priority:** P0 Critical  |  **Status:** ❌ Not Started
**🆕 New in V2**

#### Description
When Razorpay webhook is implemented, it MUST NOT be behind `auth` middleware. Webhooks are server-to-server calls without a user session. The webhook endpoint must use HMAC signature verification instead.

#### Requirements
- Register webhook route in `routes/api.php` (NOT behind `auth` middleware)
- Verify Razorpay webhook signature using `X-Razorpay-Signature` header and `razorpay.webhook_secret` config
- On `payment.captured` event: find matching invoice by `payment_id` in gateway_response, create InvoicingPayment, update invoice.paid_amount, create audit log entry, set payment_reconciled=1
- On verification failure: return HTTP 400 (do not return 401/403 which leaks auth info)

---

### FR-BIL-022: ❌ Fix Sensitive Data Leak in Audit Log (Gap: INP-06)
**Gap Reference:** INP-06  |  **Priority:** P1 High  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
`InvoicingPaymentController::store()` line 94 logs `$request->all()` inside the `event_info` JSON column of `bil_tenant_invoicing_audit_logs`. This can store sensitive payment data (gateway credentials, full card references) in a plaintext DB column.

#### Requirements
- Replace `$request->all()` in audit log event_info with an explicit whitelist: `['amount_paid', 'payment_mode', 'payment_status', 'transaction_id', 'currency', 'payment_date']`
- Never include `gateway_response`, `pay_mode_other`, or any credential-like fields in the audit JSON

---

### FR-BIL-023: ❌ Fix Performance Issues — N+1 Queries and Missing Indexes (Gap: PERF)
**Gap Reference:** PERF (Gap Analysis Section 10)  |  **Priority:** P1/P2 High  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
`BillingManagementController::index()` loads `Tenant::get()` and `User::get()` (ALL records, no pagination, no filter) on every page load (lines 117-118). Missing database indexes on high-query columns.

#### Requirements
- Replace `Tenant::get()` with paginated or filtered query (select id, name only)
- Replace `User::get()` with filtered query or cache result
- Add DB index on `bil_tenant_invoicing_payments.tenant_invoice_id` (Gap: DB-09)
- Add DB index on `bil_tenant_invoicing_audit_logs.action_date` for range queries (Gap: DB-10)
- Move ZIP generation (synchronous) to a queued job for batch downloads > 10 invoices (Gap: PERF-ZIP)

---

### FR-BIL-024: ❌ Fix Activity Log Event Name Inconsistency (Gap: LOG-01, LOG-02)
**Gap Reference:** LOG-01, LOG-02  |  **Priority:** P3 Low  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
Multiple places call `activityLog($model, 'Store', ...)` — the event name 'Store' is inconsistent with the project standard ('Created', 'Updated', 'Deleted'). Also, `SendInvoiceEmailJob::handle()` calls `activityLog()` inside a queued job where `Auth::id()` returns null.

#### Requirements
- Standardize all `activityLog()` calls to use 'Created', 'Updated', 'Deleted' event names
- Pass `performed_by` explicitly to jobs rather than relying on `Auth::id()` in queue worker context
- Store `performed_by` user ID as a job constructor parameter on `SendInvoiceEmailJob`

---

### FR-BIL-025: ❌ Fix Class Name Typo — BillTenatEmailSchedule (Gap: MDL-04)
**Gap Reference:** MDL-04  |  **Priority:** P3 Low  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
Model class `BillTenatEmailSchedule` has a typo (`Tenat` instead of `Tenant`). Also, `tenat_id` filter field name in BillingManagementController::index() has a typo (Gap: ARCH-NAME, INP-03).

#### Requirements
- Rename class to `BillTenantEmailSchedule` and update all references
- Fix filter field name from `tenat_id` to `tenant_id` in BillingManagementController index filters

---

### FR-BIL-026: ❌ Add FK Constraint to bil_tenant_email_schedules (Gap: DB-08)
**Gap Reference:** DB-08  |  **Priority:** P2 Medium  |  **Status:** ❌ Not Fixed
**🆕 New in V2**

#### Description
DDL for `bil_tenant_email_schedules` has no FK from `invoice_id` to `bil_tenant_invoices.id`. Orphaned email schedule records can accumulate if invoices are deleted.

#### Requirements
- Add FK: `CONSTRAINT fk_emailSchedule_invoiceId FOREIGN KEY (invoice_id) REFERENCES bil_tenant_invoices(id) ON DELETE CASCADE`
- Add `SoftDeletes` trait to `BillTenantEmailSchedule` model (currently missing — violates project rule)
- Add `is_active`, `created_by`, `deleted_at` columns to `bil_tenant_email_schedules` DDL

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Entity Overview

| # | Entity | Table | Status | Purpose |
|---|--------|-------|--------|---------|
| 1 | BillingCycle | prm_billing_cycles | Existing | Billing frequency types |
| 2 | BilTenantInvoice | bil_tenant_invoices | Existing (DDL gaps) | Core invoice document |
| 3 | BillOrgInvoicingModulesJnt | bil_tenant_invoicing_modules_jnt | Existing (DDL gaps) | Modules included in invoice |
| 4 | InvoicingPayment | bil_tenant_invoicing_payments | Existing (DDL gaps) | Payment records |
| 5 | InvoicingAuditLog | bil_tenant_invoicing_audit_logs | Existing (DDL gaps + FK mismatch) | Event audit trail |
| 6 | BillTenantEmailSchedule | bil_tenant_email_schedules | Existing (DDL gaps) | Delayed email scheduling |

### 5.2 Detailed Entity Specification

#### ENTITY: prm_billing_cycles
**Model:** `Modules\Billing\Models\BillingCycle`  |  **Note:** `prm_` prefix — cross-module table managed by Billing module

| # | Column | Type | Nullable | Default | Constraints | Notes |
|---|--------|------|:---:|---------|-------------|-------|
| 1 | id | SMALLINT UNSIGNED | No | AUTO_INC | PK | |
| 2 | short_name | VARCHAR(50) | No | — | UNIQUE | MONTHLY, QUARTERLY, YEARLY, ONE_TIME |
| 3 | name | VARCHAR(50) | No | — | | Display name |
| 4 | months_count | TINYINT UNSIGNED | No | — | | Cycle length in months |
| 5 | description | VARCHAR(255) | Yes | NULL | | |
| 6 | is_recurring | TINYINT(1) | No | 1 | | |
| 7 | is_active | TINYINT(1) | No | 1 | | |
| 8 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 9 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 10 | deleted_at | TIMESTAMP | Yes | NULL | | SoftDeletes |

**Model spec:** `$casts`: months_count→integer, is_active→bool, is_recurring→bool. Relationships: hasMany TenantPlanRate, hasMany TenantPlanBillingSchedule, hasMany BilTenantInvoice, hasMany Plan.

---

#### ENTITY: bil_tenant_invoices
**Model:** `Modules\Billing\Models\BilTenantInvoice`

**DDL Gaps (from audit):** Missing `created_by` column. DDL has no `deleted_at` (model uses SoftDeletes — mismatch). Duplicate `$fillable` entries.

| # | Column | Type | Nullable | Default | Constraints | Notes |
|---|--------|------|:---:|---------|-------------|-------|
| 1 | id | INT UNSIGNED | No | AUTO_INC | PK | |
| 2 | tenant_id | INT UNSIGNED | No | — | FK→prm_tenant(id) CASCADE | |
| 3 | tenant_plan_id | INT UNSIGNED | No | — | FK→prm_tenant_plan_jnt(id) CASCADE | |
| 4 | billing_cycle_id | SMALLINT UNSIGNED | No | — | FK→prm_billing_cycles(id) RESTRICT | |
| 5 | invoice_no | VARCHAR(50) | No | — | UNIQUE | Auto: INV-YYYYMMDD-NNN |
| 6 | invoice_date | DATE | No | — | | Invoice creation date |
| 7 | billing_start_date | DATE | No | — | | Period start |
| 8 | billing_end_date | DATE | No | — | | Period end |
| 9 | min_billing_qty | INT UNSIGNED | No | 1 | | Floor for billing qty |
| 10 | total_user_qty | INT UNSIGNED | No | 1 | | Actual active students |
| 11 | plan_rate | DECIMAL(12,2) | No | — | | Rate from TenantPlanRate |
| 12 | billing_qty | INT UNSIGNED | No | 1 | | max(min_billing_qty, total_user_qty) |
| 13 | sub_total | DECIMAL(14,2) | No | 0.00 | | plan_rate × billing_qty |
| 14 | discount_percent | DECIMAL(5,2) | No | 0.00 | | |
| 15 | discount_amount | DECIMAL(12,2) | No | 0.00 | | |
| 16 | discount_remark | VARCHAR(50) | Yes | NULL | | |
| 17 | extra_charges | DECIMAL(12,2) | No | 0.00 | | Add-on charges |
| 18 | charges_remark | VARCHAR(50) | Yes | NULL | | |
| 19 | tax1_percent | DECIMAL(5,2) | No | 0.00 | | CGST or custom |
| 20 | tax1_remark | VARCHAR(50) | Yes | NULL | | e.g. "CGST" |
| 21 | tax1_amount | DECIMAL(12,2) | No | 0.00 | | |
| 22 | tax2_percent | DECIMAL(5,2) | No | 0.00 | | SGST or custom |
| 23 | tax2_remark | VARCHAR(50) | Yes | NULL | | |
| 24 | tax2_amount | DECIMAL(12,2) | No | 0.00 | | |
| 25 | tax3_percent | DECIMAL(5,2) | No | 0.00 | | IGST or custom |
| 26 | tax3_remark | VARCHAR(50) | Yes | NULL | | |
| 27 | tax3_amount | DECIMAL(12,2) | No | 0.00 | | |
| 28 | tax4_percent | DECIMAL(5,2) | No | 0.00 | | Custom tax 4 |
| 29 | tax4_remark | VARCHAR(50) | Yes | NULL | | |
| 30 | tax4_amount | DECIMAL(12,2) | No | 0.00 | | |
| 31 | total_tax_amount | DECIMAL(12,2) | No | 0.00 | | tax1+tax2+tax3+tax4 |
| 32 | net_payable_amount | DECIMAL(12,2) | No | 0.00 | | sub_total − discount + extra + taxes |
| 33 | paid_amount | DECIMAL(14,2) | No | 0.00 | | Cumulative payments |
| 34 | currency | CHAR(3) | No | 'INR' | | ISO 4217 |
| 35 | status | VARCHAR(20) | No | 'PENDING' | | Dropdown: invoice_status |
| 36 | credit_days | SMALLINT UNSIGNED | No | — | | Days until due |
| 37 | payment_due_date | DATE | No | — | | invoice_date + credit_days |
| 38 | is_recurring | TINYINT(1) | No | 1 | | |
| 39 | auto_renew | TINYINT(1) | No | 1 | | |
| 40 | remarks | TEXT | Yes | NULL | | |
| 41 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 42 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 43 | created_by | INT UNSIGNED | Yes | NULL | | **Missing from DDL — add** |
| 44 | deleted_at | TIMESTAMP | Yes | NULL | | **Missing from DDL — add** |

**Indexes:** `uq_tenantInvoices_invoiceNo` (UNIQUE on invoice_no)

**Model spec:** `$casts`: is_recurring→bool, auto_renew→bool, invoice_date/billing_start_date/billing_end_date/payment_due_date→date. Relationships: belongsTo Tenant, TenantPlan, BillingCycle; hasMany InvoicingPayment, InvoicingAuditLog.

---

#### ENTITY: bil_tenant_invoicing_modules_jnt
**Model:** `Modules\Billing\Models\BillOrgInvoicingModulesJnt`

**DDL Gaps:** Missing `is_active`, `created_by`, `deleted_at` columns. Model uses SoftDeletes but DDL lacks `deleted_at`.

| # | Column | Type | Nullable | Default | Constraints |
|---|--------|------|:---:|---------|-------------|
| 1 | id | INT UNSIGNED | No | AUTO_INC | PK |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices(id) CASCADE |
| 3 | module_id | INT UNSIGNED | Yes | NULL | FK→glb_modules(id) SET NULL |
| 4 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | |
| 5 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | |
| 6 | is_active | TINYINT(1) | No | 1 | **Missing from DDL — add** |
| 7 | created_by | INT UNSIGNED | Yes | NULL | **Missing from DDL — add** |
| 8 | deleted_at | TIMESTAMP | Yes | NULL | **Missing from DDL — add** |

**Indexes:** `uq_tenantInvModule_invId_moduleId` (UNIQUE on tenant_invoice_id, module_id)

---

#### ENTITY: bil_tenant_invoicing_payments
**Model:** `Modules\Billing\Models\InvoicingPayment`

**DDL Gaps:** Missing `created_by`, `deleted_at`, `is_active` columns. Missing index on `tenant_invoice_id`.

| # | Column | Type | Nullable | Default | Notes |
|---|--------|------|:---:|---------|-------|
| 1 | id | INT UNSIGNED | No | AUTO_INC | PK |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices(id) CASCADE; **add index** |
| 3 | payment_date | DATE | No | — | |
| 4 | transaction_id | VARCHAR(100) | Yes | NULL | Gateway/bank reference |
| 5 | mode | VARCHAR(20) | No | 'ONLINE' | Dropdown: ONLINE, BANK_TRANSFER, CASH, CHEQUE |
| 6 | mode_other | VARCHAR(20) | Yes | NULL | |
| 7 | amount_paid | DECIMAL(14,2) | No | — | Per-invoice allocation |
| 8 | consolidated_amount | DECIMAL(14,2) | Yes | NULL | Total cheque amount if consolidated |
| 9 | currency | CHAR(3) | No | 'INR' | |
| 10 | payment_status | VARCHAR(20) | No | 'SUCCESS' | Dropdown: INITIATED, SUCCESS, FAILED |
| 11 | gateway_response | JSON | Yes | NULL | Raw gateway response |
| 12 | payment_reconciled | TINYINT(1) | No | 0 | 1=reconciled |
| 13 | remarks | VARCHAR(255) | Yes | NULL | |
| 14 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | |
| 15 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | |
| 16 | is_active | TINYINT(1) | No | 1 | **Missing from DDL — add** |
| 17 | created_by | INT UNSIGNED | Yes | NULL | **Missing from DDL — add** |
| 18 | deleted_at | TIMESTAMP | Yes | NULL | **Missing from DDL — add** |

**Model spec:** `$casts`: payment_date→date, amount_paid→decimal:2, payment_reconciled→bool, gateway_response→array.

---

#### ENTITY: bil_tenant_invoicing_audit_logs
**Model:** `Modules\Billing\Models\InvoicingAuditLog`

**Critical DDL Gaps:** Missing `updated_at`, `is_active`, `created_by`, `deleted_at`. Model uses SoftDeletes but DDL lacks `deleted_at`. **FK column mismatch: DDL uses `tenant_invoice_id`, model fillable uses `tenant_invoicing_id`.**

| # | Column | Type | Nullable | Default | Notes |
|---|--------|------|:---:|---------|-------|
| 1 | id | INT UNSIGNED | No | AUTO_INC | PK |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices(id) CASCADE. **Model uses wrong name `tenant_invoicing_id`** |
| 3 | action_date | TIMESTAMP | No | — | **Add index for range queries** |
| 4 | action_type | VARCHAR(20) | No | 'PENDING' | GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed |
| 5 | performed_by | INT UNSIGNED | Yes | NULL | FK→sys_users(id) SET NULL |
| 6 | event_info | JSON | Yes | NULL | **Add cast→array in model** |
| 7 | notes | VARCHAR(500) | Yes | NULL | Updatable field |
| 8 | created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | |
| 9 | updated_at | TIMESTAMP | Yes | NULL | **Missing from DDL — add** |
| 10 | is_active | TINYINT(1) | No | 1 | **Missing from DDL — add** |
| 11 | created_by | INT UNSIGNED | Yes | NULL | **Missing from DDL — add** |
| 12 | deleted_at | TIMESTAMP | Yes | NULL | **Missing from DDL — add** |

---

#### ENTITY: bil_tenant_email_schedules
**Model:** `Modules\Billing\Models\BillTenantEmailSchedule` (typo: currently `BillTenatEmailSchedule`)

**DDL Gaps:** No FK on `invoice_id`. Missing `is_active`, `created_by`, `deleted_at`. Model lacks SoftDeletes.

| # | Column | Type | Nullable | Default | Notes |
|---|--------|------|:---:|---------|-------|
| 1 | id | INT UNSIGNED | No | AUTO_INC | PK |
| 2 | invoice_id | INT UNSIGNED | No | — | **Add FK→bil_tenant_invoices(id) CASCADE** |
| 3 | schedule_time | TIMESTAMP | No | — | Scheduled dispatch time |
| 4 | status | VARCHAR(255) | No | 'pending' | pending, sent, failed |
| 5 | created_at | TIMESTAMP | Yes | NULL | |
| 6 | updated_at | TIMESTAMP | Yes | NULL | |
| 7 | is_active | TINYINT(1) | No | 1 | **Missing from DDL — add** |
| 8 | created_by | INT UNSIGNED | Yes | NULL | **Missing from DDL — add** |
| 9 | deleted_at | TIMESTAMP | Yes | NULL | **Missing from DDL — add** |

### 5.3 Entity Relationship Summary

```
prm_billing_cycles (1)
        │
        │ hasMany
        ▼
prm_tenant_plan_billing_schedule
        │ generated_invoice_id FK
        ▼
bil_tenant_invoices ◄── FK from prm_tenant, prm_tenant_plan_jnt, prm_billing_cycles
        │
        ├──hasMany──► bil_tenant_invoicing_modules_jnt ──► glb_modules
        │
        ├──hasMany──► bil_tenant_invoicing_payments
        │                   (payment_reconciled toggle)
        │
        └──hasMany──► bil_tenant_invoicing_audit_logs ──► sys_users(performed_by)

bil_tenant_email_schedules
        └── invoice_id (no FK in current DDL — must add)
```

### 5.4 Schema Correction Plan (DDL Migrations Required)

| Migration | Table | Action | Priority |
|-----------|-------|--------|----------|
| M-01 | bil_tenant_invoices | ADD COLUMN `created_by` INT UNSIGNED NULL | P1 |
| M-02 | bil_tenant_invoices | ADD COLUMN `deleted_at` TIMESTAMP NULL (for SoftDeletes) | P1 |
| M-03 | bil_tenant_invoicing_payments | ADD COLUMNS `created_by`, `deleted_at`, `is_active` | P1 |
| M-04 | bil_tenant_invoicing_audit_logs | ADD COLUMNS `updated_at`, `is_active`, `created_by`, `deleted_at` | P1 |
| M-05 | bil_tenant_invoicing_audit_logs | RENAME COLUMN (or fix model): `tenant_invoice_id` vs `tenant_invoicing_id` | P0 |
| M-06 | bil_tenant_invoicing_audit_logs | ADD INDEX `idx_audit_actionDate` ON `action_date` | P2 |
| M-07 | bil_tenant_invoicing_payments | ADD INDEX `idx_invPayments_invoiceId` ON `tenant_invoice_id` | P2 |
| M-08 | bil_tenant_invoicing_modules_jnt | ADD COLUMNS `is_active`, `created_by`, `deleted_at` | P2 |
| M-09 | bil_tenant_email_schedules | ADD COLUMNS `is_active`, `created_by`, `deleted_at` | P2 |
| M-10 | bil_tenant_email_schedules | ADD FK `fk_emailSchedule_invoiceId` ON `invoice_id` | P2 |

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Route Summary

All routes are under `prefix('billing')->name('billing.')` with middleware `['auth', 'verified']` on the central domain. Note: route block is duplicated 3× in app `routes/web.php` for 3 central domains.

| # | Method | URI | Controller@Method | Route Name | Status |
|---|--------|-----|-------------------|------------|--------|
| 1 | GET | /billing/billing-management | BillingManagement@index | billing.billing-management.index | ✅ |
| 2 | POST | /billing/billing-management | BillingManagement@store | billing.billing-management.store | ✅ |
| 3 | GET | /billing/billing-management/create | BillingManagement@create | billing.billing-management.create | Stub |
| 4 | GET | /billing/billing-management/{id} | BillingManagement@show | billing.billing-management.show | Stub |
| 5 | GET | /billing/billing-management/{id}/edit | BillingManagement@edit | billing.billing-management.edit | Stub |
| 6 | PUT/PATCH | /billing/billing-management/{id} | BillingManagement@update | billing.billing-management.update | Stub |
| 7 | DELETE | /billing/billing-management/{id} | BillingManagement@destroy | billing.billing-management.destroy | Stub |
| 8 | GET | /billing/billing-management/trash/view | BillingManagement@trashedBillingManagement | billing.billing-management.trashed | Not implemented |
| 9 | GET | /billing/billing-management/{id}/restore | BillingManagement@restore | billing.billing-management.restore | Not implemented |
| 10 | DELETE | /billing/billing-management/{id}/force-delete | BillingManagement@forceDelete | billing.billing-management.forceDelete | Not implemented |
| 11 | POST | /billing/billing-management/{session}/toggle-status | BillingManagement@toggleStatus | billing.billing-management.toggleStatus | ✅ Reconciliation |
| 12 | GET | /billing/billing-management/view/{id} | BillingManagement@view | billing.billing-management.view | Stub |
| 13 | POST | /billing/billing-management/pdfs | BillingManagement@downloadPDF | billing.billing-management.pdfs | ✅ ZIP PDFs |
| 14 | POST | /billing/billing-management/send-email | BillingManagement@sendEmail | billing.billing-management.sendEmail | ✅ |
| 15 | POST | /billing/billing-management/schedule-email | BillingManagement@scheduleEmail | billing.billing-management.scheduleEmail | ✅ |
| 16 | GET | /billing/subscription-details | BillingManagement@subscriptionDetails | billing.billing-management.subscription.details | ✅ AJAX |
| 17 | GET | /billing/invoice-details | BillingManagement@invoiceDetails | billing.billing-management.invoice.details | ✅ AJAX |
| 18 | GET | /billing/module-details | BillingManagement@moduleDetails | billing.billing-management.module.details | ✅ AJAX |
| 19 | GET | /billing/billing-management/print/data | BillingManagement@printData | billing.billing-management.print.data | ✅ |
| 20 | GET | /billing/invoice/remarks | BillingManagement@invoiceRemarks | billing.billing-management.invoice.remarks | ✅ |
| 21 | POST | /billing/invoice/remarks/update | BillingManagement@updateInvoiceRemarks | billing.billing-management.invoice.remarks.update | ✅ |
| 22 | GET | /billing/billing/audit-log | BillingManagement@AuditLog | billing.billing-management.audit.log | ✅ AJAX |
| 23 | GET | /billing/subscription | Subscription@index | billing.subscription.index | Stub |
| 24 | POST | /billing/subscription | Subscription@store | billing.subscription.store | ✅ ZIP PDF |
| 25 | GET | /billing/billing/pricing-details | Subscription@pricingDetails | billing.pricing.details | ✅ AJAX |
| 26 | GET | /billing/billing/billing-details | Subscription@billingDetails | billing.billing.details | ✅ AJAX |
| 27 | GET | /billing/invoicing-payment | InvoicingPayment@index | billing.invoicing-payment.index | Stub |
| 28 | GET | /billing/invoicing-payment/create | InvoicingPayment@create | billing.invoicing-payment.create | ✅ AJAX form |
| 29 | POST | /billing/invoicing-payment | InvoicingPayment@store | billing.invoicing-payment.store | ✅ |
| 30 | GET | /billing/billing/payment-details | InvoicingPayment@paymentDetails | billing.payment-details | ✅ AJAX |
| 31 | POST | /billing/billing/consolidated-store | InvoicingPayment@consolidatedStore | billing.consolidated.store | ✅ |
| 32 | GET | /billing/billing/download-consolidated-pdf | InvoicingPayment@downloadConsolidatedPdf | billing.download.consolidated.pdf | ✅ |
| 33 | POST | /billing/download-selected-pdf | InvoicingPayment@downloadSelectedPdf | — | ✅ |
| 34 | GET | /billing/invoicing-audit-log | InvoicingAuditLog@index | billing.invoicing-audit-log.index | Stub |
| 35 | POST | /billing/invoicing-audit-log | InvoicingAuditLog@store | billing.invoicing-audit-log.store | Stub |
| 36 | GET | /billing/audit/add-note | InvoicingAuditLog@auditAddNote | billing.audit.add.note | ✅ |
| 37 | POST | /billing/audit/add-note/update | InvoicingAuditLog@auditAddNoteUpdate | billing.audit.add.note.update | ✅ |
| 38 | GET | /billing/audit/event-info | InvoicingAuditLog@auditEventInfo | — | ✅ |
| 39 | GET | /billing/audit/download-pdf | InvoicingAuditLog@downloadAuditNotePdf | — | ✅ |
| 40 | GET | /billing/billing-cycle | BillingCycle@index | billing.billing-cycle.index | ✅ |
| 41 | GET | /billing/billing-cycle/create | BillingCycle@create | billing.billing-cycle.create | ✅ |
| 42 | POST | /billing/billing-cycle | BillingCycle@store | billing.billing-cycle.store | ✅ |
| 43 | GET | /billing/billing-cycle/{id}/edit | BillingCycle@edit | billing.billing-cycle.edit | ✅ |
| 44 | PUT/PATCH | /billing/billing-cycle/{id} | BillingCycle@update | billing.billing-cycle.update | ✅ |
| 45 | DELETE | /billing/billing-cycle/{id} | BillingCycle@destroy | billing.billing-cycle.destroy | ✅ |
| 46 | GET | /billing/billing-cycle/trash/view | BillingCycle@trashed | billing.billing-cycle.trashed | ✅ |
| 47 | GET | /billing/billing-cycle/{id}/restore | BillingCycle@restore | billing.billing-cycle.restore | ✅ |
| 48 | DELETE | /billing/billing-cycle/{id}/force-delete | BillingCycle@forceDelete | billing.billing-cycle.forceDelete | ✅ |
| 49 | POST | /billing/billing-cycle/{billingCycle}/toggle-status | BillingCycle@toggleStatus | billing.billing-cycle.toggleStatus | ✅ |

### 6.2 Route Issues

| Issue | Severity | Details |
|-------|----------|---------|
| RT-01 | P1 | No role-based middleware on billing route group — authorization relies entirely on Gate checks inside methods |
| RT-02 | P2 | `InvoicingController` exists but not registered in routes; dead stub code |
| RT-03 | P2 | `BillingManagement@view($id)` takes raw `$id` param, not route model binding |
| RT-04 | P2 | Route block duplicated 3× in app routes/web.php — DRY violation |

### 6.3 API Routes
`Modules/Billing/routes/api.php` is empty. No REST API endpoints exist for Billing. A future Razorpay webhook endpoint must be added here (outside `auth` middleware).

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| # | Screen | File (relative to resources/views/) | Purpose | Status |
|---|--------|-------------------------------------|---------|--------|
| 1 | Billing Cycle Index | billing-cycle/index.blade.php | List cycles; toggleStatus AJAX | ✅ |
| 2 | Billing Cycle Create | billing-cycle/create.blade.php | Create form | ✅ |
| 3 | Billing Cycle Edit | billing-cycle/edit.blade.php | Edit form | ✅ |
| 4 | Billing Cycle Trash | billing-cycle/trash.blade.php | Restore / force delete | ✅ |
| 5 | Billing Management Index | billing-management/index.blade.php | Multi-tab hub via `?type` param | ✅ |
| 6 | Invoice Listing Tab | partials/invoicing/invoicing.blade.php | Generate + list invoices; checkboxes | ✅ |
| 7 | Invoice PDF Template | partials/invoicing/pdf.blade.php | DomPDF A4 invoice | ✅ |
| 8 | Invoice Print View | partials/invoicing/print.blade.php | Browser print | ✅ |
| 9 | Invoice Email Template | partials/invoicing/email.blade.php | InvoiceMail view | ✅ |
| 10 | Schedule Invoice Modal | partials/invoicing/schedule-Invoice.blade.php | Datetime picker for scheduled email | ✅ |
| 11 | Subscription Tab | partials/subscrption-details/subscription.blade.php | Subscription data view | ✅ |
| 12 | Subscription PDF | partials/subscrption-details/pdf.blade.php | DomPDF subscription summary | ✅ |
| 13 | Subscription Print | partials/subscrption-details/print.blade.php | Browser print | ✅ |
| 14 | Invoice Payment Tab | partials/invoice-payment/index.blade.php | Payment listing | ✅ |
| 15 | Invoice Payment Print | partials/invoice-payment/print.blade.php | Browser print | ✅ |
| 16 | Consolidated Payment Tab | partials/consolidated-payment/index.blade.php | Multi-invoice payment form | ✅ |
| 17 | Consolidated Payment PDF | partials/consolidated-payment/pdf.blade.php | Consolidated statement PDF | ✅ |
| 18 | Consolidated Payment Print | partials/consolidated-payment/print.blade.php | Browser print | ✅ |
| 19 | Payment Reconciliation Tab | partials/payment-reconcilation/index.blade.php | Toggle reconciliation per row | ✅ |
| 20 | Reconciliation PDF | partials/payment-reconcilation/pdf.blade.php | Selected payments PDF | ✅ |
| 21 | Reconciliation Print | partials/payment-reconcilation/print.blade.php | Browser print | ✅ |
| 22 | Audit Log Tab | partials/invoice-audit/index.blade.php | Audit event listing | ✅ |
| 23 | Audit Log PDF | partials/invoice-audit/pdf.blade.php | Filtered audit report PDF | ✅ |
| 24 | Audit Log Print | partials/invoice-audit/print.blade.php | Browser print | ✅ |
| 25 | AJAX Detail Panels (10) | partials/details/*.blade.php | subscription-details, invoice-details, pricing-details, billing-schedule, module-details, payment-details, add-payment, invoice-remarks, audit-log, audit-add-note, audit-event-info | ✅ |
| 26 | Modal Container | partials/model/details.blade.php | Generic modal wrapping AJAX content | ✅ |
| 27 | CSS / JS partials | partials/css/css.blade.php, partials/js/js.blade.php | DataTables, daterangepicker, AJAX handlers | ✅ |

**UI Issues:**
- VW-01 (P3): CSRF verification on AJAX calls must be verified across all JS fetch calls
- VW-02 (P3): PDF views should sanitize displayed data to prevent PDF injection

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| # | Rule ID | Rule | Source | Implementation |
|---|---------|------|--------|----------------|
| 1 | BR-001 | `invoice_no` must be globally unique | DDL UNIQUE | Format: `INV-YYYYMMDD-NNN` where NNN = today's count + 1 padded 3 digits |
| 2 | BR-002 | `billing_qty = max(min_billing_qty, total_user_qty)` | Code | generateInvoiceForOrganization() |
| 3 | BR-003 | `total_user_qty` is counted from tenant's isolated DB | Code | Tenancy::initialize($tenant) → Student::where('is_active','1')->count(); Tenancy::end() |
| 4 | BR-004 | `net_payable = sub_total − discount_amount + extra_charges + total_tax_amount` | Code | Calculated inline during generation |
| 5 | BR-005 | `tax_base = sub_total − discount_amount + extra_charges` | Code | Applied before tax calculation |
| 6 | BR-006 | `payment_due_date = invoice_date + credit_days` | Code | Carbon::parse($invoiceDate)->addDays($planRate->credit_days) |
| 7 | BR-007 | A billing schedule entry can only be invoiced once (`bill_generated` flag) | DDL + Code | bill_generated=0 → only these are eligible; set to 1 after generation |
| 8 | BR-008 | Invoice status stored as Dropdown ordinal value | Code | Dropdown::where('key','bil_tenant_invoices.status.invoice_status')->where('ordinal','1') |
| 9 | BR-009 | `paid_amount` is cumulative — never decremented | Code | `$invoice->paid_amount = $invoice->paid_amount + $request->amount_paid` |
| 10 | BR-010 | Consolidated payment stores total in `consolidated_amount`; per-invoice in `amount_paid` | Code | Dual fields on bil_tenant_invoicing_payments |
| 11 | BR-011 | Tenancy context must end after student count query | Code | Tenancy::end() after count; failure = tenant context leaks to subsequent requests |
| 12 | BR-012 | Audit log entries are append-only (except `notes` field) | Code | Only create() used; notes updated via dedicated update endpoint |
| 13 | BR-013 | Soft delete must deactivate before deleting | Code | BillingCycleController::destroy() sets is_active=false then calls $model->delete() |
| 14 | BR-014 | Email job attaches PDF generated from DomPDF | Code | SendInvoiceEmailJob::handle() generates PDF; InvoiceMail::build() attachData($pdf) |
| 15 | BR-015 | Currency defaults to INR | DDL | bil_tenant_invoices.currency CHAR(3) DEFAULT 'INR' |
| 16 | BR-016 | Four tax lines accommodate CGST, SGST, IGST, and custom | DDL | tax1_remark through tax4_remark store tax type labels |
| 17 | BR-017 | Invoice ZIP deletes temp ZIP file after download | Code | @unlink($zipPath); temp PDF files should also be deleted (currently not) |
| 18 | BR-018 | Razorpay webhook must NOT use session-based auth | ❌ New | Webhook endpoint must use HMAC signature verification only |
| 19 | BR-019 | `$request->all()` must never be stored in audit event_info | ❌ New | Whitelist fields only: amount_paid, payment_mode, payment_status, transaction_id |
| 20 | BR-020 | DB transactions must wrap all multi-model write operations | ❌ Not fully implemented | try/catch around DB::beginTransaction() required in payment store methods |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### 9.1 Invoice Lifecycle State Machine

```
[Billing Schedule Record Created]
          │
          ▼ bill_generated = 0
    ┌─────────────────────┐
    │  Inv. Need to       │  ← data_type filter: "Inv. Need To Generate"
    │  Generate           │
    └─────────┬───────────┘
              │ Admin selects + POST /billing/billing-management
              ▼
    generateInvoiceForOrganization()
    ├── Find TenantPlanRate for billing period
    ├── Tenancy::initialize() → count active students → Tenancy::end()
    ├── Calculate billing_qty, sub_total, taxes, net_payable
    ├── Create bil_tenant_invoices (status = PENDING)
    ├── Set prm_tenant_plan_billing_schedule.bill_generated = 1
    ├── Insert bil_tenant_invoicing_modules_jnt rows
    └── Create GENERATED audit log entry
              │
              ▼
    ┌─────────────────────┐
    │      PENDING        │  payment_due_date in future; paid_amount = 0
    └─────────┬───────────┘
              │
              ├──[partial payment recorded]──►  PARTIALLY_PAID
              │                                  paid_amount > 0 but < net_payable_amount
              │
              ├──[full payment recorded]──────►  PAID / FULLY_PAID
              │                                  paid_amount >= net_payable_amount
              │
              ├──[payment_due_date passed]────►  OVERDUE
              │                                  ❌ No automated detection yet
              │
              └──[manual cancellation]────────►  CANCELLED
                                                 ❌ No dedicated cancel endpoint yet
```

### 9.2 Payment Processing Workflow

```
Individual Payment:
  GET /billing/invoicing-payment/create?id={invoice_id}  → Load AJAX form
  POST /billing/invoicing-payment
    → StoreInvoicePaymentRequest validation
    → DB::beginTransaction()  [❌ No try/catch — must fix ERR-01]
    → Create InvoicingPayment
    → Update invoice.paid_amount += amount_paid
    → Update invoice.status
    → Create "Partially Paid" audit log
    → DB::commit()
    → JSON {status: true}

Consolidated Payment:
  GET /billing/billing-management?type=consolidated-payment  → List outstanding invoices
  POST /billing/billing/consolidated-store
    → ConsolidatedPaymentRequest validation  [❌ Missing array field rules — FRQ-03]
    → DB::beginTransaction()  [❌ No try/catch — must fix ERR-02]
    → Loop invoice_ids:
        if new_payment[id] == 0: skip
        Create InvoicingPayment (consolidated_amount = total, amount_paid = allocation)
        Update invoice.paid_amount
        Create PAYMENT_UPDATED audit log
    → DB::commit()
    → JSON {status: true}
```

### 9.3 Email Dispatch Workflow

```
Immediate Email:
  POST /send-email {ids[]}
    → Loop: SendInvoiceEmailJob::dispatch($id)
    → Queue worker:
        Load BilTenantInvoice
        Generate DomPDF
        Create InvoicingAuditLog 'Notice Sent'  [❌ Auth::id() = null in queue — LOG-02]
        Mail::to(tenant.email)->send(InvoiceMail) with PDF attachment

Scheduled Email:
  POST /schedule-email {id, schedule_time}
    → Create BillTenatEmailSchedule (status='pending')
    → Create InvoicingAuditLog 'Notice Sent'
    → SendInvoiceEmailJob::dispatch($id)->delay($scheduleAt)
```

### 9.4 Reconciliation Workflow

```
Payment recorded → payment_reconciled = 0 (default)
Accountant reviews in Reconciliation tab
Toggle: POST /billing-management/{session}/toggle-status
→ InvoicingPayment.payment_reconciled toggled (0 ↔ 1)
→ activityLog recorded
→ JSON {success: true, data: {payment_reconciled: bool}}
```

### 9.5 Authorization Decision Flow (Current State — Broken)

```
Controller method called
        │
        ├── BillingCycleController → BillingCyclePolicy → Gate::define registered? NO
        │   → Gate::authorize('prime.billing-cycle.*') resolves via Gate::policy()
        │   → BillingCyclePolicy is ONLY registration for BillingCycle model → Works
        │
        └── BillingManagementController → Gate::authorize('prime.billing-management.*')
            → Registered: Gate::policy(BilTenantInvoice, BillingManagementPolicy)  [OVERWRITTEN]
            → Registered: Gate::policy(BilTenantInvoice, InvoicingPolicy)           [WINS]
            → InvoicingPolicy has NO method 'prime.billing-management.create'
            → Gate::authorize() FAILS silently or throws 403 always
            ❌ BROKEN — fix required per FR-BIL-014
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Category | Requirement | Priority | Gap Ref |
|---|----------|-------------|----------|---------|
| NFR-01 | Security | All controller methods MUST have Gate::authorize() before business logic | P0 Critical | SEC-01–09 |
| NFR-02 | Security | Razorpay webhook endpoint must NOT be behind `auth` middleware; use HMAC verification | P0 Critical | SEC-004 |
| NFR-03 | Security | `$request->all()` must never be stored in audit log JSON fields | P1 High | INP-06 |
| NFR-04 | Security | No rate limiting on any endpoint — add throttle middleware to billing routes | P1 High | SEC-RATE |
| NFR-05 | Security | Tenancy::initialize() must always be followed by Tenancy::end() in same method | P0 Critical | BR-011 |
| NFR-06 | Data Integrity | DB::beginTransaction() must always be wrapped in try/catch with DB::rollBack() | P0 Critical | ERR-01, ERR-02 |
| NFR-07 | Data Integrity | Policy registrations — one model = one policy in AppServiceProvider | P0 Critical | POL-01, POL-02 |
| NFR-08 | Performance | Billing management index with 1000+ records must load in <3s | High | — |
| NFR-09 | Performance | `Tenant::get()` and `User::get()` must never be called without filters in index() | P1 High | PERF-N+1 |
| NFR-10 | Performance | ZIP generation for 50+ invoices must be moved to a queued job | P2 Medium | PERF-ZIP |
| NFR-11 | Performance | Add DB index on `bil_tenant_invoicing_payments.tenant_invoice_id` | P2 Medium | DB-09 |
| NFR-12 | Performance | Add DB index on `bil_tenant_invoicing_audit_logs.action_date` | P2 Medium | DB-10 |
| NFR-13 | Reliability | SendInvoiceEmailJob must implement `$tries = 3`, `$backoff`, and `failed()` method | P1 High | — |
| NFR-14 | Reliability | Invoice generation and payment recording must complete atomically (full transaction) | P0 Critical | — |
| NFR-15 | Auditability | Every billing action creates entry in `bil_tenant_invoicing_audit_logs` | High | — |
| NFR-16 | Auditability | `sys_activity_logs` (activityLog helper) called for all model mutations | Medium | LOG-01 |
| NFR-17 | Auditability | Activity log event names must be 'Created', 'Updated', 'Deleted' — not 'Store' | P3 Low | LOG-01 |
| NFR-18 | Queue | Laravel queue worker required for email delivery; must be monitored in production | High | — |
| NFR-19 | PDF Quality | DomPDF invoice must be A4 portrait, professional layout, suitable for legal use | Medium | — |
| NFR-20 | Maintainability | Route block duplicated 3× in web.php must be refactored to single group | P3 Low | RT-04 |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On

| # | Module | Code | Status | Dependency | What It Needs |
|---|--------|------|--------|------------|---------------|
| 1 | Prime | PRM | ✅ | Data | `prm_tenant`, `prm_tenant_plan_jnt`, `prm_tenant_plan_rates`, `prm_tenant_plan_billing_schedule`, `prm_tenant_plan_modules` — models from Modules\Prime |
| 2 | GlobalMaster | GLB | ✅ | Data | `glb_modules` (view in prime_db), `Dropdown` model for status/mode dropdowns |
| 3 | SchoolSetup | SCH | ✅ | Data | `PrmTenantPlan` model (imported from Modules\SchoolSetup) |
| 4 | StudentProfile | STD | ✅ | Data | `Student` model queried via Tenancy::initialize() for active student count |
| 5 | SystemConfig | SYS | ✅ | Infrastructure | `sys_activity_logs` (activityLog helper), `sys_users` (FK on audit_logs.performed_by) |
| 6 | Auth | AUTH | ✅ | Infrastructure | Laravel Auth + Spatie Permission v6.21 (`prime.billing-*` abilities) |
| 7 | Tenancy | PKG | ✅ | Infrastructure | stancl/tenancy v3.9 for Tenancy::initialize()/end() to query per-school DB |
| 8 | DomPDF | PKG | ✅ | Infrastructure | barryvdh/laravel-dompdf for PDF generation |
| 9 | Razorpay | PKG | 🟡 | Payment | razorpay/razorpay v2.9 — installed but not yet integrated |

### 11.2 Modules That Depend on This

| # | Module | What It Uses |
|---|--------|-------------|
| 1 | Prime | `bil_tenant_invoices.id` via `prm_tenant_plan_billing_schedule.generated_invoice_id` FK |
| 2 | Analytics (future) | Billing revenue data for SaaS financial dashboards |
| 3 | Tenant Portal (future) | Invoice viewing and payment initiation from school admin side |

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests

| # | File | Type | Count | Covers |
|---|------|------|-------|--------|
| 1 | `tests/Unit/BillingModuleTest.php` | Unit (Pest) | ~55 | Model structure (table, fillable, casts, SoftDeletes, relationships), controller class existence, Gate::authorize presence in BillingCycleController, known security gaps documented, policy method existence |

### 12.2 Known Issues Documented in Tests
- `BilTenantInvoice` duplicate fillable — documented as "known bug"
- `BillingManagementController::create`, `store`, `show`, `printData`, `downloadPDF`, `sendEmail` lack Gate::authorize — documented as "known security gap"
- `BillingManagementPolicy` has methods commented out — documented as "known gap"
- Zero Feature/Integration tests: no HTTP request testing (TST-01)

### 12.3 Test Coverage Summary

| Category | Required | Existing | Gap | Coverage |
|----------|---------|----------|-----|----------|
| Model structure | 6 models | 6 (Unit) | 0 | 100% |
| Controller auth | All methods | Partial assertion | Feature-level missing | 20% |
| Invoice generation logic | 6 scenarios | 0 | 6 | 0% |
| Payment recording | 4 scenarios | 0 | 4 | 0% |
| Consolidated payment | 3 scenarios | 0 | 3 | 0% |
| Email delivery | 2 scenarios | 0 | 2 | 0% |
| Reconciliation | 2 scenarios | 0 | 2 | 0% |
| Security (403 responses) | 9 scenarios | 0 | 9 | 0% |
| DB transaction rollback | 2 scenarios | 0 | 2 | 0% |
| **Overall** | **~45 scenarios** | **~10 (structure)** | **~35** | **~22%** |

### 12.4 Proposed Test Plan

| # | Test Scenario | Type | FR Ref | Priority |
|---|--------------|------|--------|----------|
| T-01 | Generate invoice: net_payable calculation accuracy | Feature | FR-BIL-003 | Critical |
| T-02 | Generate invoice: billing_qty = max(min_qty, student_count) | Feature | FR-BIL-003 | Critical |
| T-03 | Generate invoice: DB transaction rollback on missing planRate | Feature | FR-BIL-003 | High |
| T-04 | Generate invoice: invoice_no uniqueness per day format INV-YYYYMMDD-NNN | Feature | FR-BIL-003 | High |
| T-05 | Generate invoice: module junction rows created | Feature | FR-BIL-003 | Medium |
| T-06 | Generate invoice: GENERATED audit log entry created | Feature | FR-BIL-003 | Medium |
| T-07 | Generate invoice: Tenancy::end() called even on exception | Feature | BR-011 | Critical |
| T-08 | Record payment: invoice.paid_amount increments correctly | Feature | FR-BIL-006 | Critical |
| T-09 | Record payment: transaction rollback on DB exception | Feature | FR-BIL-017 | High |
| T-10 | Record payment: audit log Partially Paid entry created | Feature | FR-BIL-006 | High |
| T-11 | Consolidated payment: multiple invoices updated atomically | Feature | FR-BIL-007 | High |
| T-12 | Consolidated payment: zero-allocation invoices skipped | Feature | FR-BIL-007 | Medium |
| T-13 | Reconciliation toggle: payment_reconciled flips 0→1→0 | Feature | FR-BIL-008 | Medium |
| T-14 | Billing cycle soft delete: is_active=false before delete | Feature | FR-BIL-001 | Medium |
| T-15 | Billing cycle force delete: FK violation returns error response | Feature | FR-BIL-001 | Medium |
| T-16 | SendInvoiceEmailJob: dispatched to queue on sendEmail | Feature | FR-BIL-004 | Medium |
| T-17 | Scheduled email: BillTenantEmailSchedule record created with status=pending | Feature | FR-BIL-004 | Medium |
| T-18 | BillingManagementController::store() unauthorized access returns 403 | Feature | FR-BIL-016 | Critical |
| T-19 | subscriptionDetails() AJAX returns 403 without authorization | Feature | FR-BIL-016 | Critical |
| T-20 | paymentDetails() AJAX returns 403 without authorization | Feature | FR-BIL-016 | Critical |
| T-21 | auditAddNoteUpdate() unauthorized returns 403 | Feature | FR-BIL-016 | Critical |
| T-22 | Policy registration: only one effective policy per model | Unit | FR-BIL-014 | High |
| T-23 | InvoicingAuditLog insert uses correct column name tenant_invoice_id | Feature | FR-BIL-015 | Critical |
| T-24 | Razorpay webhook endpoint rejects invalid HMAC signature | Feature | FR-BIL-021 | High |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition |
|------|-----------|
| Invoice | SaaS billing document generated for a school tenant covering a specific billing period |
| Billing Cycle | Frequency of billing: Monthly (1 month), Quarterly (3 months), Yearly (12 months), One-Time |
| Billing Schedule | `prm_tenant_plan_billing_schedule` row — pre-generated schedule entries for a tenant's plan validity period |
| Billing Qty | Quantity used for calculation: max(min_billing_qty, total_user_qty) |
| Min Billing Qty | Minimum licenses contracted — floor for billing even if fewer students are active |
| Total User Qty | Actual count of active students in tenant DB counted during invoice generation |
| Sub Total | plan_rate × billing_qty before discounts and taxes |
| Tax Base | sub_total − discount_amount + extra_charges — amount on which taxes are calculated |
| Net Payable | Final invoice amount: sub_total − discount + extra_charges + total_tax_amount |
| Credit Days | Number of days from invoice_date until payment_due_date |
| Consolidated Payment | Single bank/NEFT transaction distributed across multiple outstanding invoices |
| Reconciliation | Confirming a recorded payment matches a bank/gateway confirmation |
| Audit Log | `bil_tenant_invoicing_audit_logs` — event-level trail (who did what on which invoice) |
| action_type | Event type on audit log: GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed |
| bill_generated | Flag on billing schedule: 0=invoice pending, 1=invoice already generated |
| Tenancy Context | stancl/tenancy tenant DB context; initialize() → query → end() always required |
| ZIP Download | Multiple invoice PDFs packaged in a ZIP archive for bulk download |
| CGST/SGST/IGST | Indian GST types: Central, State, Integrated — mapped to tax1–tax4 fields |
| GOD Controller | Anti-pattern: single controller with too many responsibilities (BillingManagementController ~800+ lines) |
| Dead Policy | Policy class registered but overwritten by a later Gate::policy() call for the same model |
| HMAC | Hash-based Message Authentication Code — used to verify Razorpay webhook authenticity |

---

## 14. ADDITIONAL SUGGESTIONS

> Section 14 contains analyst recommendations only. These are NOT sourced from the RBS, existing code, or gap analysis.

### 14.1 Feature Enhancement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Automated recurring invoice Artisan command | With 100+ tenants on monthly plans, manual generation is not scalable. Daily command checks billing_schedule_date = today and auto-generates. | Critical | Medium |
| 2 | Overdue invoice detection + automated reminder emails | No mechanism detects invoices past payment_due_date. Daily job: find invoices where payment_due_date < today AND paid_amount < net_payable_amount AND status != CANCELLED → queue reminder email + create Overdue audit entry. | High | Medium |
| 3 | Trial-period management (RBS V2.1.2) | No trial-to-paid conversion flow. Add trial_ends_at to prm_tenant_plan_jnt and a scheduled job to auto-convert and generate first invoice. | Medium | Medium |
| 4 | Academic year billing alignment | Indian schools operate April–March. Add academic_year_id linkage to billing schedule for year-wise revenue reporting. | Medium | Low |
| 5 | Multi-school trust/group billing | Many Indian schools operate under trusts (DAV, KV Sangathan) with multiple campuses. Add tenant_group concept for consolidated invoicing across group schools. | Medium | High |

### 14.2 Technical Improvement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Move ZIP generation to queued job | Synchronous ZIP for 50+ invoices risks HTTP timeout; use a queued job that notifies admin via notification when ready | High | Medium |
| 2 | Add SendInvoiceEmailJob retry + failure handling | Set `$tries = 3`, `$backoff = [60, 300]`, implement `failed()` to update BillTenantEmailSchedule.status = 'failed' | High | Low |
| 3 | Add `$tries = 3` and `failed()` to invoice generation job | When automated scheduler is built, the job should handle transient failures gracefully | Medium | Low |
| 4 | Cache dropdown lookups | Invoice status and payment mode dropdowns are queried on every page load; cache for 1 hour with cache tags | Medium | Low |
| 5 | Extract filter query builder to a dedicated QueryBuilder class | buildMainBillingQuery(), buildSubscriptionQuery(), buildAuditLogQuery() are duplicated filter logic; consolidate | Low | Low |

### 14.3 UX/UI Improvement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Real-time payment balance indicator on invoice rows | Show outstanding_balance = net_payable_amount − paid_amount inline for accountants | Medium | Low |
| 2 | Status badge with color coding | PENDING (yellow), PAID (green), OVERDUE (red), PARTIALLY_PAID (orange) for visual scanning | Medium | Low |
| 3 | Invoice preview modal before PDF generation | Allow admins to preview before generating/emailing to catch data errors | Medium | Medium |
| 4 | Persistent bulk action toolbar | Currently invoices must be individually selected; persistent toolbar showing selected count with Email/PDF/Generate buttons | Medium | Low |

### 14.4 Indian Education Domain Suggestions

| # | Requirement | Recommendation | Priority |
|---|------------|----------------|----------|
| 1 | GST compliance (18% for IT services) | Default tax templates: CGST 9% + SGST 9% for intra-state; IGST 18% for inter-state. Add GSTIN field to tenant profile and invoice PDF. | Critical |
| 2 | B2B invoice requirements under GSTN | Add seller GSTIN, buyer GSTIN (school), HSN/SAC code 998313 (software subscription), place of supply to invoice PDF | High |
| 3 | Payment source tracking | Add payment_source (School Self/State Grant/Central Grant) to bil_tenant_invoicing_payments for subsidy tracking | Low |

### 14.5 Integration Opportunities

| # | Integration | With Module | Benefit | Effort |
|---|------------|-------------|---------|--------|
| 1 | Trigger in-app notification on invoice generation | Notifications Module | School admin notified immediately on invoice generation | Medium |
| 2 | Revenue analytics in future Analytics module | Analytics (future) | MRR, churn, payment failure rates across tenants | High |
| 3 | Link billing dashboard to School Profile | SchoolSetup (SCH) | Jump from invoice to school context | Low |

---

## 15. APPENDICES

### Appendix A — Full RBS Extract (Module V)

```
Module V — SaaS Billing & Subscription (54 sub-tasks)

V1 — Subscription Plans & Pricing (10 sub-tasks)
F.V1.1 Plan Configuration
  T.V1.1.1 Create Subscription Plan
    ST.V1.1.1.1 Define plan name & description
    ST.V1.1.1.2 Set pricing (monthly/quarterly/yearly)
    ST.V1.1.1.3 Assign included modules/features
  T.V1.1.2 Plan Rules
    ST.V1.1.2.1 Define user limits
    ST.V1.1.2.2 Set storage limits
    ST.V1.1.2.3 Configure overage pricing
F.V1.2 Plan Management
  T.V1.2.1 Edit/Update Plan
    ST.V1.2.1.1 Modify pricing & limits
    ST.V1.2.1.2 Update feature list
  T.V1.2.2 Plan Activation/Deactivation
    ST.V1.2.2.1 Activate plan for sale
    ST.V1.2.2.2 Retire old plan versions

V2 — Tenant Subscription Assignment (9 sub-tasks)
F.V2.1 Subscription Purchase
  T.V2.1.1 Assign Plan to Tenant
    ST.V2.1.1.1 Select subscription plan
    ST.V2.1.1.2 Set start/end date
    ST.V2.1.1.3 Configure billing cycle
  T.V2.1.2 Trial Management
    ST.V2.1.2.1 Enable trial period
    ST.V2.1.2.2 Auto-convert trial to paid subscription
F.V2.2 Subscription Lifecycle
  T.V2.2.1 Renewal Management
    ST.V2.2.1.1 Auto-renew subscription
    ST.V2.2.1.2 Notify tenant for manual renewal
  T.V2.2.2 Upgrade/Downgrade
    ST.V2.2.2.1 Switch plan mid-cycle
    ST.V2.2.2.2 Apply prorated charges

V3 — Billing Engine (9 sub-tasks)
F.V3.1 Invoice Generation
  T.V3.1.1 Generate Invoice
    ST.V3.1.1.1 Create recurring invoice
    ST.V3.1.1.2 Include addons/overage usage
    ST.V3.1.1.3 Apply taxes as per region
  T.V3.1.2 Invoice Scheduling
    ST.V3.1.2.1 Schedule monthly/annual billing
    ST.V3.1.2.2 Send reminders for unpaid invoices
F.V3.2 Payment Processing
  T.V3.2.1 Record Payment
    ST.V3.2.1.1 Accept online payment (UPI/Card)
    ST.V3.2.1.2 Record offline payment (NEFT/Cash)
  T.V3.2.2 Auto-Reconciliation
    ST.V3.2.2.1 Match payment with invoice automatically
    ST.V3.2.2.2 Flag mismatched transactions

V4 — Metering, Usage & Overage Tracking (6 sub-tasks)
F.V4.1 Usage Monitoring
    ST.V4.1.1.1 Monitor API calls
    ST.V4.1.1.2 Track storage consumption
    ST.V4.1.2.1 Notify tenant when nearing limits
    ST.V4.1.2.2 Auto-lock premium features when exceeded
F.V4.2 Overage Billing
    ST.V4.2.1.1 Multiply usage above threshold
    ST.V4.2.1.2 Apply overage invoice line items

V5 — Payment Gateway Integration (6 sub-tasks)
    ST.V5.1.1.1 Add API keys for Razorpay
    ST.V5.1.1.2 Set webhook URL for payment confirmation
    ST.V5.1.2.1 Send test payment request
    ST.V5.1.2.2 Verify webhook response
    ST.V5.2.1.1 Configure supported currencies
    ST.V5.2.1.2 Set exchange rate source

V6 — Tenant Billing Portal (8 sub-tasks)
    ST.V6.1.1.1 Display invoices list (tenant view)
    ST.V6.1.1.2 Filter by paid/unpaid
    ST.V6.1.2.1 Show API/storage usage
    ST.V6.1.2.2 Highlight overage areas
    ST.V6.2.1.1 Download invoice PDF (tenant)
    ST.V6.2.1.2 Download payment receipt (tenant)
    ST.V6.2.2.1 Redirect to online payment gateway
    ST.V6.2.2.2 Update payment status in system

V7 — Audit & Compliance Reports (6 sub-tasks)
F.V7.1 Audit Log
    ST.V7.1.1.1 Record invoice creation
    ST.V7.1.1.2 Log payment confirmations
    ST.V7.1.2.1 Record plan upgrade/downgrade
    ST.V7.1.2.2 Maintain full audit trail
F.V7.2 Compliance Reports
    ST.V7.2.1.1 GST/Tax reports
    ST.V7.2.1.2 Country-wise billing summaries
```

### Appendix B — Gap Analysis Priority Summary (from 2026-03-22 Audit)

| Priority | Count | Key Issues | FR Reference |
|----------|:-----:|-----------|--------------|
| P0 Critical | 7 | POL-01, POL-02, DB-01/MDL-01, DB-07, SEC-01, ERR-01/ERR-02, SEC-02 | FR-BIL-014 to FR-BIL-018 |
| P1 High | 13 | SVC-01, INP-01/02/06, FRQ-01–04, SEC-05–06, TST-01, DB-02/03 | FR-BIL-019, FR-BIL-020, FR-BIL-022 |
| P2 Medium | 16 | DB-04–10, MDL-02–05, ERR-03–04, PERF issues, RT-02–04 | FR-BIL-023, FR-BIL-026 |
| P3 Low | 4 | LOG-01/02, MDL-04, VW-01/02 | FR-BIL-024, FR-BIL-025 |
| **Total** | **40** | | |

### Appendix C — Policy Registration Map (Current Broken State)

```
AppServiceProvider.php lines 617-623:

Line 617: Gate::policy(BilTenantInvoice::class, BillingManagementPolicy::class)
Line 618: Gate::policy(BilTenantInvoice::class, InvoicingPolicy::class)  ← OVERWRITES line 617
           → BillingManagementPolicy is DEAD CODE

Line 620: Gate::policy(InvoicingPayment::class, ConsolidatedPaymentPolicy::class)
Line 621: Gate::policy(InvoicingPayment::class, PaymentReconciliationPolicy::class)  ← overwrites 620
Line 622: Gate::policy(InvoicingPayment::class, SubscriptionPolicy::class)  ← overwrites 621
Line 623: Gate::policy(InvoicingPayment::class, InvoicingPaymentPolicy::class)  ← OVERWRITES all
           → ConsolidatedPaymentPolicy, PaymentReconciliationPolicy, SubscriptionPolicy are DEAD CODE

Controllers call Gate::authorize('prime.billing-management.create') etc.
InvoicingPolicy (the surviving policy for BilTenantInvoice) does NOT define these ability strings.
Result: All Gate::authorize() calls for billing-management abilities are non-functional.
```

### Appendix D — Invoice Number Format

```
Format: INV-YYYYMMDD-NNN
Example: INV-20260326-001 (first invoice on 2026-03-26)
         INV-20260326-002 (second invoice same day)

Generation logic in generateInvoiceForOrganization():
  $today = Carbon::now()->format('Ymd');
  $count = BilTenantInvoice::whereDate('invoice_date', today)->count() + 1;
  $invoiceNo = 'INV-' . $today . '-' . str_pad($count, 3, '0', STR_PAD_LEFT);
```

---

## 16. V1 → V2 DELTA SUMMARY

### 16.1 What Changed from V1 to V2

| Category | V1 | V2 | Change |
|----------|----|----|--------|
| Functional Requirements | 13 FR items (FR-BIL-001 to FR-BIL-013) | 26 FR items (FR-BIL-001 to FR-BIL-026) | +13 new FRs from gap analysis |
| Gap Coverage | Not present | All 40 gap issues mapped to FR items | New in V2 |
| Status Markers | Implemented / Partial / Not Started | ✅ / 🟡 / ❌ / 🆕 consistent throughout | Standardized |
| Policy Analysis | Mentioned briefly in Section 5.4 | Dedicated FR-BIL-014; Appendix C with full broken-state diagram | Expanded |
| Schema Corrections | Listed as "notes" in Section 5.4 | Section 5.4 Migration Plan table (M-01 to M-10) with explicit ALTER TABLE actions | Actionable |
| Authorization Gaps | Noted as "known issues" | FR-BIL-016 with full table of 9 unprotected methods | Explicit FR |
| DB Transaction Safety | Noted as concern | FR-BIL-017 with exact line references for ERR-01 and ERR-02 | Explicit FR |
| Service Layer | Noted as suggestion (Section 14) | FR-BIL-020 as formal requirement with method signatures | Promoted to FR |
| Webhook Security | Not addressed | FR-BIL-021 with HMAC verification requirement | New in V2 |
| Sensitive Data Leak | Not addressed | FR-BIL-022 with explicit whitelist requirement | New in V2 |
| Performance Issues | NFR only | FR-BIL-023 with specific N+1 queries and index requirements | Explicit FR |
| Test Plan | 18 scenarios | 24 scenarios + coverage table | Expanded |
| Business Rules | 17 rules | 20 rules (+BR-018 webhook auth, BR-019 audit whitelist, BR-020 transaction pattern) | Expanded |
| State Machine | Basic invoice lifecycle | Added Authorization Decision Flow (Section 9.5) showing broken policy chain | New diagram |

### 16.2 New FR Items Added in V2 (from Gap Analysis)

| FR | Title | Gap Source | Priority |
|----|-------|-----------|----------|
| FR-BIL-014 | Fix Duplicate Policy Registrations | POL-01, POL-02 | P0 |
| FR-BIL-015 | Fix FK Column Name Mismatch in Audit Log | DB-01, MDL-01 | P0 |
| FR-BIL-016 | Add Authorization to Unprotected Methods | SEC-01–09 | P0 |
| FR-BIL-017 | Add try/catch to DB Transactions | ERR-01, ERR-02 | P0 |
| FR-BIL-018 | Fix Duplicate $fillable + DDL Schema Corrections | DB-07, DB-02–06 | P0 |
| FR-BIL-019 | Fix FormRequest Gaps | FRQ-01–04, INP-06 | P1 |
| FR-BIL-020 | Extract BillingService | SVC-01, SVC-02 | P1 |
| FR-BIL-021 | Fix Razorpay Webhook Security | SEC-004 | P0 |
| FR-BIL-022 | Fix Sensitive Data Leak in Audit Log | INP-06 | P1 |
| FR-BIL-023 | Fix Performance Issues — N+1 + Missing Indexes | PERF, DB-09, DB-10 | P1/P2 |
| FR-BIL-024 | Fix Activity Log Event Name Inconsistency | LOG-01, LOG-02 | P3 |
| FR-BIL-025 | Fix Class Name Typo — BillTenatEmailSchedule | MDL-04, ARCH-NAME | P3 |
| FR-BIL-026 | Add FK Constraint to bil_tenant_email_schedules | DB-08 | P2 |

### 16.3 Items Preserved from V1 (Not Dropped)

All 13 V1 FR items (FR-BIL-001 through FR-BIL-013) are retained in V2 with:
- Status markers updated to reflect gap analysis findings
- Acceptance criteria updated with current implementation status
- Implementation tables preserved and expanded

---

*Document generated: 2026-03-26 | Next review: After P0 gap fixes are implemented*
*Based on: V1 Requirement (2026-03-25) + Gap Analysis (2026-03-22) + DDL prime_db_v2.sql + code inspection*
