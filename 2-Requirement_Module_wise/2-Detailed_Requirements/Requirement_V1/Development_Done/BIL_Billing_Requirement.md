# Billing Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** BIL | **Module Path:** `Modules/Billing`
**Module Type:** Prime (Central) | **Database:** prime_db
**Table Prefix:** `bil_*` | **Processing Mode:** FULL
**RBS Reference:** Module V — SaaS Billing & Subscription

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

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
The Billing module manages the complete SaaS billing lifecycle for Prime-AI school tenants. It handles invoice generation from billing schedules, payment recording (individual and consolidated), payment reconciliation, email delivery of invoices via queued jobs, and a full audit trail of all billing events. The module operates on `prime_db` (central database) and serves Super Admins managing multiple school subscriptions.

### 1.2 Scope
**In Scope:**
- Billing cycle master management (monthly/quarterly/yearly/one-time)
- Invoice generation from `prm_tenant_plan_billing_schedule` records
- Invoice listing, filtering, PDF generation and ZIP download
- Individual and consolidated payment recording
- Payment reconciliation toggle
- Invoice email delivery (immediate and scheduled via queue)
- Billing audit log with event detail and notes
- Subscription details, pricing details, and billing schedule views
- Print views for invoices, subscriptions, payments, reconciliation, and audit logs

**Out of Scope:**
- Subscription plan creation and pricing (handled in Prime module — `prm_plans`, `prm_tenant_plan_jnt`, `prm_tenant_plan_rates`)
- Tenant onboarding and plan assignment (handled in Prime/SchoolSetup modules)
- Online payment gateway integration (Razorpay webhook handling not yet implemented)
- Multi-currency exchange rate management
- Usage metering and overage tracking (RBS V4 — not implemented)
- Automated scheduler for recurring invoice generation (no Artisan command exists yet)
- Compliance and GST reports (RBS V7.2 — not implemented)
- Student/Tenant self-service portal for payments (RBS V6 — not implemented)

### 1.3 Module Statistics

| Metric | Count | Source |
|--------|-------|--------|
| RBS Functionalities | 14 | RBS Module V |
| RBS Tasks | 21 | RBS Module V |
| RBS Sub-Tasks | 54 | RBS Module V |
| Database Tables (bil_*) | 4 | DDL prime_db_v2.sql |
| Supporting Table (prm_billing_cycles) | 1 | DDL (BillingCycle model points here) |
| Total Tables Managed | 5 | DDL + Models |
| Web Routes | 42 | routes/web.php |
| API Routes | 0 | routes/api.php (empty) |
| UI Screens / View Files | 27 | Modules/Billing/resources/views/ |
| Controllers | 5 | Code |
| Models | 5 | Code (+ BillingCycle = 6 total) |
| Form Request Classes | 3 | Code |
| Jobs | 1 | Code |
| Mail Classes | 1 | Code |
| Policies | 7 | Code |
| Tests (Unit) | 1 file, ~55 test cases | Modules/Billing/tests/Unit/ |
| Feature Tests | 0 | Not found |
| Cross-Module Dependencies | 6 | Analysis |

### 1.4 Implementation Status

| Status | Feature Count | Percentage |
|--------|--------------|------------|
| Implemented | 8 | 57% |
| Partial | 3 | 21% |
| Not Started | 3 | 22% |
| **Total** | **14** | **100%** |

**Feature-level breakdown:**
- F.V1 Plan Configuration/Management: Partial (billing cycle CRUD done; plan pricing managed in Prime module)
- F.V2 Subscription Assignment/Lifecycle: Partial (view/download done; auto-renew/trial logic not implemented)
- F.V3 Invoice Generation + Payment Processing: Implemented
- F.V4 Metering & Overage: Not Started
- F.V5 Gateway Integration: Not Started (Razorpay wired but no webhook handler)
- F.V6 Tenant Billing Portal: Not Started (admin-side done; tenant self-service missing)
- F.V7 Audit Logs: Implemented; Compliance Reports: Not Started

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
| 1 | Billing Cycle Master | CRUD for billing cycle types (monthly/quarterly/yearly) with soft delete and restore | F.V1.1 | Implemented |
| 2 | Invoice Generation | Generate invoices from billing schedule; auto-calculates billing qty, taxes, net payable | F.V3.1 | Implemented |
| 3 | Billing Management Dashboard | Unified view with tabs: invoices, subscriptions, payments, consolidated, reconciliation, audit | F.V3.1, F.V6.1 | Implemented |
| 4 | Individual Payment Recording | Add payment per invoice with mode, transaction ID, reconciliation flag | F.V3.2 | Implemented |
| 5 | Consolidated Payment | Record single payment across multiple invoices in one transaction | F.V3.2 | Implemented |
| 6 | Payment Reconciliation | Toggle reconciliation status per payment record | F.V3.2.2 | Implemented |
| 7 | Invoice PDF & ZIP Download | Bulk download of multiple invoices as a ZIP of DomPDF-generated PDFs | F.V6.2 | Implemented |
| 8 | Invoice Email (Immediate + Scheduled) | Queue-based email with PDF attachment; delayed dispatch for future scheduling | F.V3.1.2 | Implemented |
| 9 | Billing Audit Log | Per-invoice event log with action_type, JSON event_info, notes, performed_by | F.V7.1 | Implemented |
| 10 | Subscription Detail Views | Inline AJAX panels: subscription details, pricing details, billing schedule, module list | F.V2.1 | Partial |
| 11 | Print Views | Print-friendly views for invoices, subscriptions, payments, reconciliation, audit notes | F.V6.2 | Implemented |
| 12 | Usage Metering & Overage | Track API calls, storage, apply overage billing | F.V4 | Not Started |
| 13 | Gateway Integration | Razorpay webhook, multi-currency, test payment | F.V5 | Not Started |
| 14 | Compliance Reports | GST reports, country-wise billing summaries | F.V7.2 | Not Started |

### 2.3 Menu Navigation Path
From RBS and route analysis:
- **Central Admin Panel > Subscription & Billing** (`/subscription-billing`) — main entry point (PrimeController)
- **Central Admin > Billing > Billing Management** (`/billing/billing-management`) — invoice and payment hub
- **Central Admin > Billing > Billing Cycle** (`/billing/billing-cycle`) — cycle master CRUD
- **Central Admin > Sales Plan Management > #billing tab** — billing cycle redirect target after create/update

### 2.4 Module Architecture

```
Modules/Billing/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── BillingCycleController.php          (CRUD + soft delete/restore, toggleStatus)
│   │   │   ├── BillingManagementController.php     (Invoice hub: generate, print, PDF, email)
│   │   │   ├── InvoicingController.php             (stub — delegates to BillingManagement)
│   │   │   ├── InvoicingPaymentController.php      (individual + consolidated payments, PDF)
│   │   │   ├── SubscriptionController.php          (subscription PDF download, pricing/billing detail panels)
│   │   │   └── InvoicingAuditLogController.php     (audit note CRUD, event info panel, PDF)
│   │   ├── Requests/
│   │   │   ├── BillingCycleRequest.php
│   │   │   ├── StoreInvoicePaymentRequest.php
│   │   │   └── ConsolidatedPaymentRequest.php
│   │   └── Policies/ (7 policy classes)
│   ├── Jobs/
│   │   └── SendInvoiceEmailJob.php                 (ShouldQueue — PDF email dispatch)
│   ├── Mail/
│   │   └── InvoiceMail.php
│   ├── Models/
│   │   ├── BillingCycle.php                        (→ prm_billing_cycles)
│   │   ├── BilTenantInvoice.php                    (→ bil_tenant_invoices)
│   │   ├── BillOrgInvoicingModulesJnt.php          (→ bil_tenant_invoicing_modules_jnt)
│   │   ├── InvoicingPayment.php                    (→ bil_tenant_invoicing_payments)
│   │   ├── InvoicingAuditLog.php                   (→ bil_tenant_invoicing_audit_logs)
│   │   └── BillTenatEmailSchedule.php              (→ bil_tenant_email_schedules)
│   └── Providers/
│       ├── BillingServiceProvider.php
│       ├── EventServiceProvider.php
│       └── RouteServiceProvider.php
├── config/config.php
├── database/seeders/BillingDatabaseSeeder.php      (empty)
├── resources/views/
│   ├── billing-cycle/ (create, edit, index, trash)
│   ├── billing-management/
│   │   ├── index.blade.php                         (main hub)
│   │   └── partials/
│   │       ├── consolidated-payment/ (index, pdf, print)
│   │       ├── css/css.blade.php
│   │       ├── details/ (add-payment, audit-add-note, audit-event-info, audit-log,
│   │       │            billing-schedule, invoice-details, invoice-remarks,
│   │       │            module-details, payment-details, pricing-details,
│   │       │            subscription-details)
│   │       ├── invoice-audit/ (index, pdf, print)
│   │       ├── invoice-payment/ (index, print)
│   │       ├── invoicing/ (email, invoicing, pdf, print, schedule-Invoice)
│   │       ├── js/js.blade.php
│   │       ├── model/details.blade.php
│   │       ├── payment-reconcilation/ (index, pdf, print)
│   │       └── subscrption-details/ (pdf, print, subscription)
│   ├── components/layouts/master.blade.php
│   └── index.blade.php
├── routes/
│   ├── web.php   (stub — routes defined in app routes/web.php)
│   └── api.php   (empty)
└── tests/
    └── Unit/BillingModuleTest.php                  (55 test cases, Pest syntax)
```

---

## 3. STAKEHOLDERS & ACTORS

| Role | Scope | Responsibilities in this Module |
|------|-------|--------------------------------|
| Super Admin | Central (prime_db) | Full access: generate invoices, record payments, send emails, manage billing cycles, view all reports |
| Prime Accountant | Central | Record payments, download PDFs, toggle reconciliation, add audit notes |
| Prime Manager | Central | View billing dashboard, view invoices and subscriptions, download reports |
| School Admin | Tenant | Currently no self-service portal (RBS V6 not implemented) |
| System (Queue Worker) | Automated | Execute `SendInvoiceEmailJob` — generates PDF and sends email to tenant |
| System (Scheduler) | Automated | (Planned) Run scheduled invoice generation via Artisan command — not yet implemented |

---

## 4. FUNCTIONAL REQUIREMENTS

### FR-BIL-001: Plan Configuration — Billing Cycle Master (F.V1.1)
**RBS Reference:** F.V1.1
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Cycle Index `/billing/billing-cycle`
**Table(s):** `prm_billing_cycles` (managed via `BillingCycle` model in this module)

#### Description
Manages billing cycle types used to define how often a tenant is billed. Supports short codes like MONTHLY, QUARTERLY, YEARLY, ONE_TIME with a `months_count` value and `is_recurring` flag.

#### Requirements

**REQ-BIL-001.1: Create Billing Cycle**
| Attribute | Detail |
|-----------|--------|
| Description | Super Admin creates a billing cycle with short_name, name, months_count, description, is_active, is_recurring |
| Actors | Super Admin |
| Preconditions | Authenticated with `prime.billing-cycle.create` permission |
| Trigger | POST `/billing/billing-cycle` |
| Input | short_name (unique, max 50), name (max 50), months_count (1-255), description (nullable), is_active (boolean), is_recurring (boolean) |
| Processing | Validate via BillingCycleRequest; create record; write sys_activity_logs |
| Output | Redirect to sales-plan-mgmt#billing with success flash |
| Error Handling | Unique constraint on short_name — validation error returned |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V1.1.1.1 — Define plan name & description → **Status:** Implemented (name + description fields)
- [ ] ST.V1.1.1.2 — Set pricing (monthly/quarterly/yearly) — pricing is on prm_plans/prm_tenant_plan_rates, billing cycle only defines the cycle type → **Status:** Partial
- [ ] ST.V1.1.1.3 — Assign included modules/features — handled in Prime module → **Status:** Out of scope for BIL

**REQ-BIL-001.2: Edit/Update Billing Cycle**
| Attribute | Detail |
|-----------|--------|
| Description | Modify an existing billing cycle's name, description, months_count, is_active, is_recurring |
| Actors | Super Admin |
| Preconditions | Billing cycle exists; `prime.billing-cycle.update` permission |
| Trigger | PUT `/billing/billing-cycle/{billingCycle}` |
| Input | Same as create; short_name unique ignoring current record |
| Processing | BillingCycleRequest validation; update; activity log |
| Output | Redirect to sales-plan-mgmt#billing with success flash |
| Status | Implemented |

**REQ-BIL-001.3: Soft Delete / Restore / Force Delete**
| Attribute | Detail |
|-----------|--------|
| Description | Deactivate and soft-delete a billing cycle; view trash; restore; permanently delete |
| Actors | Super Admin |
| Preconditions | `prime.billing-cycle.delete` / `prime.billing-cycle.restore` permission |
| Trigger | DELETE `/billing/billing-cycle/{id}`, GET trashed, GET restore, DELETE force-delete |
| Processing | destroy() sets is_active=false then soft-deletes; forceDelete() calls forceDelete() with try/catch |
| Error Handling | forceDelete() catches Throwable — returns error flash on FK violation |
| Status | Implemented |

**REQ-BIL-001.4: Toggle Active Status**
| Attribute | Detail |
|-----------|--------|
| Description | Toggle is_active on/off via AJAX without full page reload |
| Trigger | POST `/billing/billing-cycle/{billingCycle}/toggle-status` |
| Output | JSON `{success: true, is_active: bool, message: string}` |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V1.2.2.1 — Activate plan for sale → **Status:** Implemented (toggleStatus)
- [ ] ST.V1.2.2.2 — Retire old plan versions → **Status:** Implemented (soft delete)

**Current Implementation:**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | BillingCycleController.php | index, create, store, edit, update, destroy, trashed, restore, forceDelete, toggleStatus | Full CRUD + soft delete cycle |
| Model | BillingCycle.php | table=prm_billing_cycles | SoftDeletes; casts: months_count→int, is_active/is_recurring→bool |
| Request | BillingCycleRequest.php | rules() | Unique short_name with ignore on update |
| Policy | BillingCyclePolicy.php | 7 methods | prime.billing-cycle.* permissions |
| Views | billing-cycle/ | create, edit, index, trash | 4 blade views |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---------|------|----------|----------|
| 1 | Create billing cycle with valid data | Feature | No | High |
| 2 | Duplicate short_name rejected | Feature | No | High |
| 3 | Toggle status returns correct JSON | Feature | No | Medium |
| 4 | Soft delete sets is_active=false | Feature | No | Medium |
| 5 | Force delete with FK violation caught | Feature | No | Medium |

---

### FR-BIL-002: Subscription Plan Management (F.V1.2, F.V2)
**RBS Reference:** F.V1.2, F.V2.1, F.V2.2
**Priority:** High
**Status:** Partial
**Owner Screen:** Billing Management `/billing/billing-management?type=subscription_data`
**Table(s):** `prm_tenant_plan_jnt`, `prm_tenant_plan_rates`, `prm_tenant_plan_billing_schedule` (Prime module), `bil_tenant_invoicing_modules_jnt`

#### Description
Viewing and downloading subscription details for tenant plan assignments. The actual plan assignment and pricing configuration live in the Prime module. The Billing module provides read-only detail panels (subscription details, pricing details, billing schedule) and PDF download of subscription summaries.

#### Requirements

**REQ-BIL-002.1: View Subscription Data**
| Attribute | Detail |
|-----------|--------|
| Description | Display paginated list of TenantPlanRate records with filters: status (Active/Inactive), date_range |
| Actors | Super Admin, Prime Manager |
| Preconditions | `prime.subscription.viewAny` permission |
| Trigger | GET `/billing/billing-management?type=subscription_data` |
| Processing | buildSubscriptionQuery() filters on tenantPlan.status and start_date range |
| Output | Paginated list (10 per page) rendered in billing-management/index via resultsSub variable |
| Status | Implemented |

**REQ-BIL-002.2: Subscription Detail Panels (AJAX)**
| Attribute | Detail |
|-----------|--------|
| Description | Three inline AJAX panels loaded on-demand: subscription details, pricing details, billing schedule |
| Trigger | GET `billing/subscription-details?id=`, GET `billing/pricing-details?id=`, GET `billing/billing-details?id=` |
| Output | JSON `{html: string}` rendered in modal/panel |
| Status | Implemented |

**REQ-BIL-002.3: Module Details Panel**
| Attribute | Detail |
|-----------|--------|
| Description | Show modules included in a subscription or invoice |
| Trigger | GET `billing/module-details?id=&type=subscription|invoice` |
| Processing | type=subscription → TenantPlanModule; type=invoice → BillOrgInvoicingModulesJnt |
| Status | Implemented |

**REQ-BIL-002.4: Subscription PDF Download (ZIP)**
| Attribute | Detail |
|-----------|--------|
| Description | Bulk download subscription details as ZIP of PDFs |
| Trigger | POST `/billing/subscription` (SubscriptionController::store) with `ids[]` array |
| Processing | For each ID: load TenantPlanRate with relations, generate DomPDF, add to ZipArchive |
| Output | ZIP file download response |
| Status | Implemented |

**Acceptance Criteria (from RBS V2):**
- [ ] ST.V2.1.1.1 — Select subscription plan → **Status:** Implemented (view only; assignment in Prime)
- [ ] ST.V2.1.1.2 — Set start/end date → **Status:** Partial (visible in subscription details panel)
- [ ] ST.V2.1.1.3 — Configure billing cycle → **Status:** Partial (visible in pricing details panel)
- [ ] ST.V2.1.2.1 — Enable trial period → **Status:** Not Started
- [ ] ST.V2.1.2.2 — Auto-convert trial to paid → **Status:** Not Started
- [ ] ST.V2.2.1.1 — Auto-renew subscription → **Status:** Not Started (field exists on invoice; no automation)
- [ ] ST.V2.2.1.2 — Notify tenant for manual renewal → **Status:** Not Started
- [ ] ST.V2.2.2.1 — Switch plan mid-cycle → **Status:** Not Started
- [ ] ST.V2.2.2.2 — Apply prorated charges → **Status:** Not Started

**Current Implementation:**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | SubscriptionController.php | index, store (PDF ZIP), pricingDetails, billingDetails | No create/update/delete logic |
| Controller | BillingManagementController.php | subscriptionDetails(), moduleDetails() | AJAX panel renderers |
| Model | BillingCycle.php | tenantPlanRates(), billingSchedules() | Reads prm_* tables |

---

### FR-BIL-003: Invoice Generation (F.V3.1)
**RBS Reference:** F.V3.1.1, F.V3.1.2
**Priority:** Critical
**Status:** Implemented
**Owner Screen:** Billing Management index (default tab) `/billing/billing-management`
**Table(s):** `prm_tenant_plan_billing_schedule`, `bil_tenant_invoices`, `bil_tenant_invoicing_modules_jnt`, `bil_tenant_invoicing_audit_logs`

#### Description
The core billing engine. Generates invoices for one or multiple selected billing schedule records. Cross-queries tenant DB to count active students for usage-based billing. Applies plan rate, minimum billing qty, discounts, extra charges, and up to 4 tax lines. Creates module junction records. Logs generation event in audit log.

#### Requirements

**REQ-BIL-003.1: Generate Invoice for Selected Schedule Records**
| Attribute | Detail |
|-----------|--------|
| Description | Admin selects one or more `prm_tenant_plan_billing_schedule` records and triggers invoice generation |
| Actors | Super Admin |
| Preconditions | `prime.billing-management.create` permission; schedule record not already billed (`bill_generated=0`) |
| Trigger | POST `/billing/billing-management` with `ids[]` array of schedule IDs |
| Input | Array of `prm_tenant_plan_billing_schedule.id` values |
| Processing | For each ID: (1) Find schedule record; (2) Find matching TenantPlanRate for date range; (3) Initialize tenant DB via `Tenancy::initialize()` to count active students; (4) Calculate billing_qty = max(min_billing_qty, total_user_qty); (5) Calculate sub_total, discount_amount, extra_charges, tax1-4 amounts, total_tax_amount, net_payable; (6) Generate invoice_no as `INV-YYYYMMDD-NNN`; (7) Calculate payment_due_date = invoice_date + credit_days; (8) Create bil_tenant_invoices record; (9) Set schedule.bill_generated=1 and generated_invoice_id; (10) Insert per-module rows into bil_tenant_invoicing_modules_jnt; (11) Insert GENERATED audit log entry |
| Output | JSON `{status: true, success_ids: [], failed_ids: [{id, reason}]}` |
| Error Handling | Wrapped in DB::transaction; if planRate not found returns `{status: false}`; failed IDs returned in response |
| Status | Implemented |

**REQ-BIL-003.2: Invoice Listing and Filtering**
| Attribute | Detail |
|-----------|--------|
| Description | Paginated invoice list with filters: data_type (Inv. Need To Generate / Invoicing Done), status, invoice_status, date_range |
| Trigger | GET `/billing/billing-management` (default / no type param) |
| Processing | buildMainBillingQuery() on TenantPlanBillingSchedule with eager loads: tenantPlan.plan, tenantPlan.tenant, generatedInvoice |
| Output | Paginated 10 per page, passed as `$results` to view |
| Status | Implemented |

**REQ-BIL-003.3: Invoice Details Panel (AJAX)**
| Attribute | Detail |
|-----------|--------|
| Description | Show full invoice calculation breakdown in inline panel |
| Trigger | GET `billing/invoice-details?id={invoice_id}` |
| Output | JSON `{html: string}` from invoice-details partial |
| Status | Implemented |

**REQ-BIL-003.4: Invoice Remarks**
| Attribute | Detail |
|-----------|--------|
| Description | View and update remarks on an invoice or payment record |
| Trigger | GET `billing/invoice/remarks?id=&type=` / POST `billing/invoice/remarks/update` |
| Processing | type=payment → InvoicingPayment; else → BilTenantInvoice; update remarks; create audit log entry with action_type='Not Billed' |
| Status | Implemented |

**REQ-BIL-003.5: Invoice Scheduling (F.V3.1.2)**
| Attribute | Detail |
|-----------|--------|
| Description | Schedule monthly/annual billing run and send reminders — automated scheduler |
| Status | Not Started — no Artisan command or scheduled job exists |

**Acceptance Criteria:**
- [ ] ST.V3.1.1.1 — Create recurring invoice → **Status:** Implemented (is_recurring flag honored)
- [ ] ST.V3.1.1.2 — Include addons/overage usage → **Status:** Partial (extra_charges field exists; no automated overage calculation)
- [ ] ST.V3.1.1.3 — Apply taxes as per region → **Status:** Implemented (4 configurable tax lines, INR default)
- [ ] ST.V3.1.2.1 — Schedule monthly/annual billing → **Status:** Not Started
- [ ] ST.V3.1.2.2 — Send reminders for unpaid invoices → **Status:** Partial (email can be sent manually; no automated reminder job)

**Current Implementation:**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | BillingManagementController.php | store(), generateInvoiceForOrganization() | Core generation logic |
| Controller | BillingManagementController.php | invoiceDetails(), invoiceRemarks(), updateInvoiceRemarks() | Detail panels |
| Model | BilTenantInvoice.php | table=bil_tenant_invoices | 40+ fillable fields; SoftDeletes |
| Model | BillOrgInvoicingModulesJnt.php | table=bil_tenant_invoicing_modules_jnt | module() BelongsTo |
| Job | SendInvoiceEmailJob.php | handle() | Queued PDF email |
| Mail | InvoiceMail.php | build() | PDF attachment |

**Required Test Cases:**
| # | Scenario | Type | Existing | Priority |
|---|---------|------|----------|----------|
| 1 | Invoice generation calculates net_payable correctly | Feature | No | Critical |
| 2 | billing_qty = max(min_qty, student_count) | Feature | No | Critical |
| 3 | invoice_no format INV-YYYYMMDD-NNN unique per day | Feature | No | High |
| 4 | DB transaction rolls back on planRate not found | Feature | No | High |
| 5 | Module junction rows created per module | Feature | No | Medium |
| 6 | Audit log GENERATED entry created | Feature | No | Medium |

---

### FR-BIL-004: Invoice Email Delivery (F.V3.1.2)
**RBS Reference:** F.V3.1.2
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Management index (email actions)
**Table(s):** `bil_tenant_email_schedules`, `bil_tenant_invoicing_audit_logs`

#### Description
Send invoice PDFs to school tenant email immediately or at a scheduled future time via Laravel queue.

#### Requirements

**REQ-BIL-004.1: Immediate Email Send**
| Attribute | Detail |
|-----------|--------|
| Description | Dispatch SendInvoiceEmailJob immediately for one or multiple invoices |
| Actors | Super Admin |
| Preconditions | `prime.billing-management.email-schedule` permission |
| Trigger | POST `/billing/billing-management/send-email` with `ids[]` or `id` |
| Processing | Loop ids; dispatch SendInvoiceEmailJob per ID; job generates PDF via DomPDF, sends InvoiceMail to tenant email |
| Output | JSON `{status: true, message: 'Emails queued successfully!'}` |
| Status | Implemented |

**REQ-BIL-004.2: Scheduled Email**
| Attribute | Detail |
|-----------|--------|
| Description | Schedule an invoice email for a future datetime |
| Trigger | POST `/billing/billing-management/schedule-email` with `id` and `schedule_time` |
| Processing | Parse schedule_time via Carbon; create BillTenatEmailSchedule record (status='pending'); dispatch SendInvoiceEmailJob with `->delay($scheduleAt)`; create audit log 'Notice Sent' entry |
| Output | JSON `{status: true, message: "Email scheduled for DD Mon YYYY HH:MM AM/PM"}` |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V3.1.2.2 — Send reminders for unpaid invoices → **Status:** Partial (manual trigger only; no automated overdue scan)

**Current Implementation:**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | BillingManagementController.php | sendEmail(), scheduleEmail() | Immediate and delayed dispatch |
| Job | SendInvoiceEmailJob.php | handle() | ShouldQueue; generates PDF; logs audit; mails to tenant.email |
| Mail | InvoiceMail.php | build() | Subject: "Invoice - {invoice_no}"; PDF attachment |
| Model | BillTenatEmailSchedule.php | table=bil_tenant_email_schedules | No SoftDeletes; status field |

---

### FR-BIL-005: Invoice PDF Generation & Download (F.V6.2)
**RBS Reference:** F.V6.2.1
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Management index
**Table(s):** `bil_tenant_invoices`

#### Description
Generate PDF for one or multiple invoices and return as a ZIP archive download.

#### Requirements

**REQ-BIL-005.1: Bulk Invoice PDF ZIP Download**
| Attribute | Detail |
|-----------|--------|
| Description | Download selected invoice PDFs packaged in a single ZIP file |
| Actors | Super Admin, Accountant |
| Preconditions | `prime.billing-management.pdf` permission |
| Trigger | POST `/billing/billing-management/pdfs` with `ids[]` |
| Processing | For each ID: load BilTenantInvoice; generate DomPDF from invoicing/pdf view; save to temp file; add to ZipArchive; delete ZIP after reading |
| Output | ZIP binary response with `Content-Type: application/zip` |
| Status | Implemented |

**REQ-BIL-005.2: Print Views**
| Attribute | Detail |
|-----------|--------|
| Description | Browser-print-friendly views for all data types |
| Trigger | GET `/billing/billing-management/print/data?type={type}` |
| Processing | type: default (invoices), subscription_data, consolidated-payment, payment-reconcilation, invoice_payment, audit-note |
| Status | Implemented |

---

### FR-BIL-006: Payment Recording (F.V3.2.1)
**RBS Reference:** F.V3.2.1
**Priority:** Critical
**Status:** Implemented
**Owner Screen:** Billing Management — Add Payment modal
**Table(s):** `bil_tenant_invoicing_payments`, `bil_tenant_invoices`, `bil_tenant_invoicing_audit_logs`

#### Description
Record individual payments against a specific invoice. Supports online (card, UPI), bank transfer, cash, cheque, and other modes. Updates invoice paid_amount and status.

#### Requirements

**REQ-BIL-006.1: Record Individual Payment**
| Attribute | Detail |
|-----------|--------|
| Description | Add a payment entry for a specific invoice |
| Actors | Super Admin, Accountant |
| Preconditions | `prime.invoicing-payment.create`; invoice exists |
| Trigger | POST `/billing/invoicing-payment` |
| Input | tenant_invoice_id, date, amount_paid, currency, payment_mode, pay_mode_other, transaction_id, invoice_payments (status), payment_status, payment_reconciled, gateway_resp, remarks |
| Processing | Validate via StoreInvoicePaymentRequest; create InvoicingPayment; update invoice.paid_amount += amount_paid; update invoice.status; create audit log 'Partially Paid' entry with JSON event_info |
| Transaction | DB::beginTransaction / DB::commit |
| Output | JSON `{status: true, message: 'Payment saved successfully!'}` |
| Status | Implemented |

**REQ-BIL-006.2: Add Payment Modal Panel**
| Attribute | Detail |
|-----------|--------|
| Description | Load add-payment form in modal with invoice context |
| Trigger | GET `billing/invoicing-payment/create?id={invoice_id}` |
| Output | JSON `{html: string}` from add-payment partial |
| Status | Implemented |

**REQ-BIL-006.3: Payment Details Panel**
| Attribute | Detail |
|-----------|--------|
| Description | View all payments for an invoice in inline panel |
| Trigger | GET `billing/payment-details?id={invoice_id}` |
| Output | JSON `{html: string}` listing InvoicingPayment records |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V3.2.1.1 — Accept online payment (UPI/Card) → **Status:** Implemented (mode stored; no live gateway redirect)
- [ ] ST.V3.2.1.2 — Record offline payment (NEFT/Cash) → **Status:** Implemented

---

### FR-BIL-007: Consolidated Payment (F.V3.2.1)
**RBS Reference:** F.V3.2.1
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Management — Consolidated Payment tab
**Table(s):** `bil_tenant_invoicing_payments`, `bil_tenant_invoices`, `bil_tenant_invoicing_audit_logs`

#### Description
Record a single bank transfer or payment that covers multiple outstanding invoices. The `consolidated_amount` field stores the total cheque/transfer amount while `amount_paid` stores the per-invoice allocation.

#### Requirements

**REQ-BIL-007.1: Record Consolidated Payment**
| Attribute | Detail |
|-----------|--------|
| Description | One payment transaction applied across multiple invoices |
| Actors | Super Admin, Accountant |
| Preconditions | `prime.invoicing-payment.create`; at least one invoice selected |
| Trigger | POST `billing/consolidated-store` |
| Input | payment_dates, payment_mode, pay_mode_other, transaction_id, amount_paid (total), payment_consolidated_status, payment_reconciled, gateway_resp, invoice_ids[] (array), new_payment[invoice_id] (per-invoice allocations), payment_status[invoice_id] |
| Processing | Validate via ConsolidatedPaymentRequest; loop invoice_ids; skip if allocation=0; create InvoicingPayment per invoice; update invoice.paid_amount; create PAYMENT_UPDATED audit log per invoice |
| Transaction | DB::beginTransaction / DB::commit wrapping all iterations |
| Output | JSON `{status: true, message: 'Consolidated payment saved successfully!'}` |
| Status | Implemented |

**REQ-BIL-007.2: Consolidated Payment PDF**
| Attribute | Detail |
|-----------|--------|
| Description | Download consolidated payment summary as PDF |
| Trigger | GET `billing/download-consolidated-pdf` with filters |
| Processing | Filter BilTenantInvoice where paid_amount != net_payable_amount; compute totals; DomPDF |
| Status | Implemented |

---

### FR-BIL-008: Payment Reconciliation (F.V3.2.2)
**RBS Reference:** F.V3.2.2
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Management — Payment Reconciliation tab
**Table(s):** `bil_tenant_invoicing_payments`

#### Description
Toggle the `payment_reconciled` boolean flag on payment records to track whether a gateway confirmation has been matched to the recorded payment.

#### Requirements

**REQ-BIL-008.1: Toggle Reconciliation Status**
| Attribute | Detail |
|-----------|--------|
| Description | Toggle reconciliation flag for a payment record |
| Actors | Super Admin, Accountant |
| Preconditions | `prime.billing-management.status` permission |
| Trigger | AJAX call to `BillingManagementController::toggleStatus($id)` |
| Processing | Find InvoicingPayment; toggle payment_reconciled; save; activityLog; return JSON |
| Output | JSON `{success: true, message, data: {payment_reconciled: bool}}` |
| Status | Implemented |

**REQ-BIL-008.2: Reconciliation PDF Download**
| Attribute | Detail |
|-----------|--------|
| Description | Download selected payment reconciliation records as PDF |
| Trigger | POST `billing/download-selected-pdf` with `ids[]` |
| Processing | Load InvoicingPayment with invoice.tenant; DomPDF from payment-reconcilation/pdf |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V3.2.2.1 — Match payment with invoice automatically → **Status:** Partial (manual toggle; no automated matching)
- [ ] ST.V3.2.2.2 — Flag mismatched transactions → **Status:** Partial (reconciled=false is the flag; no automated detection)

---

### FR-BIL-009: Invoice Audit Log (F.V7.1)
**RBS Reference:** F.V7.1.1, F.V7.1.2
**Priority:** High
**Status:** Implemented
**Owner Screen:** Billing Management — Audit Log tab / inline audit log panel
**Table(s):** `bil_tenant_invoicing_audit_logs`

#### Description
Records every significant billing event (GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed) with timestamp, actor, notes, and JSON event_info payload. Supports adding notes to existing log entries and viewing JSON event detail.

#### Requirements

**REQ-BIL-009.1: View Audit Log for Invoice**
| Attribute | Detail |
|-----------|--------|
| Description | Display chronological audit log for a specific invoice in inline panel |
| Actors | Super Admin |
| Preconditions | `prime.billing-management.view` permission |
| Trigger | GET `billing/billing/audit-log?id={invoice_id}` |
| Output | JSON `{html: string}` from audit-log partial; logs ordered DESC by created_at |
| Status | Implemented |

**REQ-BIL-009.2: Add / Update Audit Note**
| Attribute | Detail |
|-----------|--------|
| Description | Add or update free-text notes on an existing audit log entry |
| Trigger | GET `billing/audit/add-note?id=` (load form) / POST `billing/audit/add-note/update` (save) |
| Status | Implemented |

**REQ-BIL-009.3: View Event Info JSON Detail**
| Attribute | Detail |
|-----------|--------|
| Description | Decode and display JSON event_info for a log entry in a panel |
| Trigger | Called via InvoicingAuditLogController::auditEventInfo() |
| Status | Implemented |

**REQ-BIL-009.4: Audit Log Report (PDF)**
| Attribute | Detail |
|-----------|--------|
| Description | Download filtered audit log as PDF |
| Trigger | Called via InvoicingAuditLogController::downloadAuditNotePdf() |
| Filters | date_range, tenant_id, performed_by, audit_status |
| Status | Implemented |

**Acceptance Criteria:**
- [ ] ST.V7.1.1.1 — Record invoice creation → **Status:** Implemented (GENERATED event)
- [ ] ST.V7.1.1.2 — Log payment confirmations → **Status:** Implemented (Partially Paid / PAYMENT_UPDATED)
- [ ] ST.V7.1.2.1 — Record plan upgrade/downgrade → **Status:** Not Started
- [ ] ST.V7.1.2.2 — Maintain full audit trail → **Status:** Implemented

**Current Implementation:**
| Layer | File | Method | Notes |
|-------|------|--------|-------|
| Controller | InvoicingAuditLogController.php | auditAddNote, auditAddNoteUpdate, auditEventInfo, downloadAuditNotePdf | AJAX panels + PDF |
| Controller | BillingManagementController.php | AuditLog(), buildAuditLogQuery() | Listing tab + query |
| Model | InvoicingAuditLog.php | invoice() BelongsTo, user() BelongsTo | SoftDeletes |

---

### FR-BIL-010: Usage Metering & Overage Billing (F.V4)
**RBS Reference:** F.V4.1, F.V4.2
**Priority:** Medium
**Status:** Not Started
**Table(s):** None (to be designed)

#### Description
Track API call counts and storage consumption per tenant. Alert when approaching limits. Auto-lock premium features when limits exceeded. Bill overage charges via additional invoice line items.

**Acceptance Criteria:**
- [ ] ST.V4.1.1.1 — Monitor API calls → **Status:** Not Started
- [ ] ST.V4.1.1.2 — Track storage consumption → **Status:** Not Started
- [ ] ST.V4.1.2.1 — Notify tenant when nearing limits → **Status:** Not Started
- [ ] ST.V4.1.2.2 — Auto-lock premium features when exceeded → **Status:** Not Started
- [ ] ST.V4.2.1.1 — Multiply usage above threshold → **Status:** Not Started
- [ ] ST.V4.2.1.2 — Apply overage invoice line items → **Status:** Not Started

---

### FR-BIL-011: Payment Gateway Integration (F.V5)
**RBS Reference:** F.V5.1, F.V5.2
**Priority:** High
**Status:** Not Started
**Table(s):** None (to be designed; gateway_response JSON column exists on payments table)

#### Description
Configure Razorpay (and optionally Stripe/PayPal) API keys, set webhook URL, handle payment confirmation events, test payment flow, and support multi-currency with exchange rate configuration.

**Acceptance Criteria:**
- [ ] ST.V5.1.1.1 — Add API keys for Razorpay → **Status:** Not Started
- [ ] ST.V5.1.1.2 — Set webhook URL for payment confirmation → **Status:** Not Started
- [ ] ST.V5.1.2.1 — Send test payment request → **Status:** Not Started
- [ ] ST.V5.1.2.2 — Verify webhook response → **Status:** Not Started
- [ ] ST.V5.2.1.1 — Configure supported currencies → **Status:** Not Started
- [ ] ST.V5.2.1.2 — Set exchange rate source → **Status:** Not Started

---

### FR-BIL-012: Tenant Billing Portal (F.V6)
**RBS Reference:** F.V6.1, F.V6.2
**Priority:** Medium
**Status:** Not Started (admin-side views done; tenant self-service missing)

**Acceptance Criteria:**
- [ ] ST.V6.1.1.1 — Display invoices list (tenant view) → **Status:** Not Started
- [ ] ST.V6.1.1.2 — Filter by paid/unpaid → **Status:** Not Started
- [ ] ST.V6.1.2.1 — Show API/storage usage → **Status:** Not Started
- [ ] ST.V6.1.2.2 — Highlight overage areas → **Status:** Not Started
- [ ] ST.V6.2.1.1 — Download invoice PDF → **Status:** Not Started (tenant-facing; admin download done)
- [ ] ST.V6.2.1.2 — Download payment receipt → **Status:** Not Started
- [ ] ST.V6.2.2.1 — Redirect to online payment gateway → **Status:** Not Started
- [ ] ST.V6.2.2.2 — Update payment status in system → **Status:** Not Started

---

### FR-BIL-013: SaaS Compliance Reports (F.V7.2)
**RBS Reference:** F.V7.2.1
**Priority:** Medium
**Status:** Not Started

**Acceptance Criteria:**
- [ ] ST.V7.2.1.1 — GST/Tax reports → **Status:** Not Started
- [ ] ST.V7.2.1.2 — Country-wise billing summaries → **Status:** Not Started

---

## 5. DATA MODEL & ENTITY SPECIFICATION

### 5.1 Entity Overview

| # | Entity | Table | Status | Purpose | Key Columns |
|---|--------|-------|--------|---------|------------|
| 1 | BillingCycle | prm_billing_cycles | Existing | Billing frequency types | short_name, months_count, is_recurring |
| 2 | BilTenantInvoice | bil_tenant_invoices | Existing | Core invoice record | invoice_no, net_payable_amount, paid_amount, status |
| 3 | BillOrgInvoicingModulesJnt | bil_tenant_invoicing_modules_jnt | Existing | Modules included in invoice | tenant_invoice_id, module_id |
| 4 | InvoicingPayment | bil_tenant_invoicing_payments | Existing | Payment records per invoice | amount_paid, mode, payment_reconciled |
| 5 | InvoicingAuditLog | bil_tenant_invoicing_audit_logs | Existing | Event trail per invoice | action_type, event_info JSON, performed_by |
| 6 | BillTenatEmailSchedule | bil_tenant_email_schedules | Existing | Delayed email scheduling | invoice_id, schedule_time, status |

### 5.2 Detailed Entity Specification

#### ENTITY: prm_billing_cycles [Existing — managed by BillingCycle model in Billing module]
**Purpose:** Master list of billing frequency types used across plan assignments and invoices.
**Model Class:** `Modules\Billing\Models\BillingCycle`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | SMALLINT UNSIGNED | No | AUTO_INCREMENT | PK | |
| 2 | short_name | VARCHAR(50) | No | — | UNIQUE | MONTHLY, QUARTERLY, YEARLY, ONE_TIME |
| 3 | name | VARCHAR(50) | No | — | | Display name |
| 4 | months_count | TINYINT UNSIGNED | No | — | | Number of months in cycle |
| 5 | description | VARCHAR(255) | Yes | NULL | | Optional description |
| 6 | is_recurring | TINYINT(1) | No | 1 | | Whether billing repeats |
| 7 | is_active | TINYINT(1) | No | 1 | | Soft activation flag |
| 8 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 9 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 10 | deleted_at | TIMESTAMP | Yes | NULL | | SoftDeletes |

##### Foreign Keys
None (referenced BY many tables).

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `prm_billing_cycles` |
| $fillable | short_name, name, months_count, description, is_active, is_recurring |
| $casts | months_count→integer, is_active→boolean, is_recurring→boolean |
| Traits | HasFactory, SoftDeletes |
| Relationships | hasMany TenantPlanRate, hasMany TenantPlanBillingSchedule, hasMany TenantInvoice, hasMany Plan |

---

#### ENTITY: bil_tenant_invoices [Existing]
**Purpose:** Core SaaS invoice document for a tenant's subscription period. Contains all billing calculation fields inline (no separate line-item table).
**Model Class:** `Modules\Billing\Models\BilTenantInvoice`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | INT UNSIGNED | No | AUTO_INCREMENT | PK | |
| 2 | tenant_id | INT UNSIGNED | No | — | FK→prm_tenant | |
| 3 | tenant_plan_id | INT UNSIGNED | No | — | FK→prm_tenant_plan_jnt | |
| 4 | billing_cycle_id | SMALLINT UNSIGNED | No | — | FK→prm_billing_cycles | |
| 5 | invoice_no | VARCHAR(50) | No | — | UNIQUE | Auto-generated: INV-YYYYMMDD-NNN |
| 6 | invoice_date | DATE | No | — | | Invoice creation date |
| 7 | billing_start_date | DATE | No | — | | Period start |
| 8 | billing_end_date | DATE | No | — | | Period end |
| 9 | min_billing_qty | INT UNSIGNED | No | 1 | | Minimum licenses to bill |
| 10 | total_user_qty | INT UNSIGNED | No | 1 | | Actual active students counted |
| 11 | plan_rate | DECIMAL(12,2) | No | — | | Rate per cycle from TenantPlanRate |
| 12 | billing_qty | INT UNSIGNED | No | 1 | | max(min_billing_qty, total_user_qty) |
| 13 | sub_total | DECIMAL(14,2) | No | 0.00 | | plan_rate × billing_qty |
| 14 | discount_percent | DECIMAL(5,2) | No | 0.00 | | |
| 15 | discount_amount | DECIMAL(12,2) | No | 0.00 | | sub_total × (discount_percent/100) |
| 16 | discount_remark | VARCHAR(50) | Yes | NULL | | |
| 17 | extra_charges | DECIMAL(12,2) | No | 0.00 | | Add-on charges |
| 18 | charges_remark | VARCHAR(50) | Yes | NULL | | |
| 19 | tax1_percent | DECIMAL(5,2) | No | 0.00 | | CGST or custom |
| 20 | tax1_remark | VARCHAR(50) | Yes | NULL | | e.g. "CGST" |
| 21 | tax1_amount | DECIMAL(12,2) | No | 0.00 | | taxBase × (tax1_percent/100) |
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
| 32 | net_payable_amount | DECIMAL(12,2) | No | 0.00 | | sub_total - discount + extra + taxes |
| 33 | paid_amount | DECIMAL(14,2) | No | 0.00 | | Running sum of payments |
| 34 | currency | CHAR(3) | No | 'INR' | | ISO 4217 code |
| 35 | status | VARCHAR(20) | No | 'PENDING' | | FK to glb_dropdowns (invoice_status) |
| 36 | credit_days | SMALLINT UNSIGNED | No | — | | Days to calculate due date |
| 37 | payment_due_date | DATE | No | — | | invoice_date + credit_days |
| 38 | is_recurring | TINYINT(1) | No | 1 | | From billing cycle |
| 39 | auto_renew | TINYINT(1) | No | 1 | | From tenant plan |
| 40 | remarks | TEXT | Yes | NULL | | Free text remarks |
| 41 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 42 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 43 | deleted_at | TIMESTAMP | Yes | NULL | | SoftDeletes |

##### Foreign Keys
| FK Column | References | On Delete | On Update |
|-----------|-----------|-----------|-----------|
| tenant_id | prm_tenant(id) | CASCADE | — |
| tenant_plan_id | prm_tenant_plan_jnt(id) | CASCADE | — |
| billing_cycle_id | prm_billing_cycles(id) | RESTRICT | — |

##### Indexes
| Index Name | Column(s) | Type | Purpose |
|-----------|-----------|------|---------|
| uq_tenantInvoices_invoiceNo | invoice_no | UNIQUE | Prevent duplicate invoice numbers |

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `bil_tenant_invoices` |
| $fillable | 40 fields (see model; NOTE: paid_amount, currency, status, credit_days, payment_due_date, is_recurring, auto_renew, remarks are duplicated — known bug) |
| $casts | is_recurring→bool, auto_renew→bool, invoice_date/billing_start_date/billing_end_date/payment_due_date→date |
| Traits | HasFactory, SoftDeletes |
| Relationships | belongsTo Tenant, belongsTo TenantPlan, belongsTo BillingCycle, hasMany InvoicingPayment, hasMany InvoicingAuditLog, belongsTo Dropdown(status) as statusData |

---

#### ENTITY: bil_tenant_invoicing_modules_jnt [Existing]
**Purpose:** Junction table recording which modules were active on the invoice. One row per module per invoice.
**Model Class:** `Modules\Billing\Models\BillOrgInvoicingModulesJnt`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | INT UNSIGNED | No | AUTO_INCREMENT | PK | |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices (CASCADE) | |
| 3 | module_id | INT UNSIGNED | Yes | NULL | FK→glb_modules (SET NULL) | |
| 4 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 5 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 6 | deleted_at | TIMESTAMP | Yes | NULL | | SoftDeletes |

##### Foreign Keys
| FK Column | References | On Delete | On Update |
|-----------|-----------|-----------|-----------|
| tenant_invoice_id | bil_tenant_invoices(id) | CASCADE | — |
| module_id | glb_modules(id) | SET NULL | — |

##### Indexes
| Index Name | Column(s) | Type |
|-----------|-----------|------|
| uq_tenantInvModule_invId_moduleId | (tenant_invoice_id, module_id) | UNIQUE |

---

#### ENTITY: bil_tenant_invoicing_payments [Existing]
**Purpose:** Records all payment transactions against invoices. Supports individual and consolidated payments. `consolidated_amount` is set only when multiple invoices are covered by one transaction.
**Model Class:** `Modules\Billing\Models\InvoicingPayment`

##### Columns
| # | Column | Data Type | Nullable | Default | Constraints | Business Rule |
|---|--------|-----------|----------|---------|-------------|--------------|
| 1 | id | INT UNSIGNED | No | AUTO_INCREMENT | PK | |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices (CASCADE) | |
| 3 | payment_date | DATE | No | — | | |
| 4 | transaction_id | VARCHAR(100) | Yes | NULL | | Gateway/bank reference |
| 5 | mode | VARCHAR(20) | No | 'ONLINE' | | Dropdown: ONLINE, BANK_TRANSFER, CASH, CHEQUE |
| 6 | mode_other | VARCHAR(20) | Yes | NULL | | If mode not in standard list |
| 7 | amount_paid | DECIMAL(14,2) | No | — | | Per-invoice allocation |
| 8 | consolidated_amount | DECIMAL(14,2) | Yes | NULL | | Total cheque/transfer amount if consolidated |
| 9 | currency | CHAR(3) | No | 'INR' | | |
| 10 | payment_status | VARCHAR(20) | No | 'SUCCESS' | | Dropdown: INITIATED, SUCCESS, FAILED |
| 11 | gateway_response | JSON | Yes | NULL | | Raw gateway response payload |
| 12 | payment_reconciled | TINYINT(1) | No | 0 | | 1=reconciled, 0=pending |
| 13 | remarks | VARCHAR(255) | Yes | NULL | | |
| 14 | created_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP | | |
| 15 | updated_at | TIMESTAMP | Yes | CURRENT_TIMESTAMP ON UPDATE | | |
| 16 | deleted_at | TIMESTAMP | Yes | NULL | | SoftDeletes |

##### Model Specification
| Attribute | Value |
|-----------|-------|
| $table | `bil_tenant_invoicing_payments` |
| $casts | payment_date→date, amount_paid→decimal:2, payment_reconciled→boolean, gateway_response→array |
| Relationships | belongsTo BilTenantInvoice, belongsTo Dropdown(mode) as paymentModeData, belongsTo Dropdown(payment_status) as paymentStatusData |

---

#### ENTITY: bil_tenant_invoicing_audit_logs [Existing]
**Purpose:** Immutable (append-only) audit trail. One row per billing event. Notes can be updated post-creation via auditAddNoteUpdate.
**Model Class:** `Modules\Billing\Models\InvoicingAuditLog`

##### Columns
| # | Column | Data Type | Nullable | Default | Business Rule |
|---|--------|-----------|----------|---------|--------------|
| 1 | id | INT UNSIGNED | No | AUTO_INCREMENT | |
| 2 | tenant_invoice_id | INT UNSIGNED | No | — | FK→bil_tenant_invoices (CASCADE) — NOTE: column name in DDL is `tenant_invoice_id` but model fillable uses `tenant_invoicing_id` — mapping inconsistency |
| 3 | action_date | TIMESTAMP | No | — | |
| 4 | action_type | VARCHAR(20) | No | 'PENDING' | GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed |
| 5 | performed_by | INT UNSIGNED | Yes | NULL | FK→sys_users (SET NULL) |
| 6 | event_info | JSON | Yes | NULL | Structured event data (payment amounts, statuses) |
| 7 | notes | VARCHAR(500) | Yes | NULL | Free-text note, updatable |
| 8 | created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | No updated_at in DDL |

**Important:** DDL column is `tenant_invoice_id` but model fillable has `tenant_invoicing_id`. The FK constraint and actual DB column must be verified.

---

#### ENTITY: bil_tenant_email_schedules [Existing]
**Purpose:** Tracks scheduled invoice email dispatch. Created when admin schedules a delayed email; status updated when job processes.
**Model Class:** `Modules\Billing\Models\BillTenatEmailSchedule`

##### Columns
| # | Column | Data Type | Nullable | Default |
|---|--------|-----------|----------|---------|
| 1 | id | INT UNSIGNED | No | AUTO_INCREMENT |
| 2 | invoice_id | INT UNSIGNED | No | — |
| 3 | schedule_time | TIMESTAMP | No | — |
| 4 | status | VARCHAR(255) | No | 'pending' |
| 5 | created_at | TIMESTAMP | Yes | NULL |
| 6 | updated_at | TIMESTAMP | Yes | NULL |

**Note:** No FK constraint on invoice_id in DDL. No SoftDeletes on this model. No relationship defined back to BilTenantInvoice.

### 5.3 Entity Relationship Summary

```
prm_billing_cycles (1)───────────────┐
        │                            │
        │ hasMany                    │ FK
        ▼                            │
prm_tenant_plan_billing_schedule ────┤
        │ generated_invoice_id FK    │
        ▼                            │
bil_tenant_invoices ◄────────────────┘
        │ PK
        │
        ├──hasMany──► bil_tenant_invoicing_modules_jnt ──► glb_modules
        │
        ├──hasMany──► bil_tenant_invoicing_payments
        │                   (payment_reconciled toggle)
        │
        └──hasMany──► bil_tenant_invoicing_audit_logs ──► sys_users

bil_tenant_email_schedules (standalone, no FK enforced)
```

### 5.4 Schema Reconciliation Notes

| # | Issue | Source | Details | Resolution Needed |
|---|-------|--------|---------|-------------------|
| 1 | Column name mismatch | DDL vs Model | DDL: `tenant_invoice_id` on audit_logs; Model fillable: `tenant_invoicing_id` | Verify DB column; align model fillable |
| 2 | Duplicate fillable fields | BilTenantInvoice model | paid_amount, currency, status, credit_days, payment_due_date, is_recurring, auto_renew, remarks appear twice in $fillable array | Remove duplicates from $fillable |
| 3 | No FK on email_schedules.invoice_id | DDL | Missing FK constraint | Add FK or accept loose coupling |
| 4 | status column type mismatch | DDL vs Model | DDL: `status VARCHAR(20)` with default 'PENDING'; code uses Dropdown ID (integer) | Clarify: VARCHAR stores dropdown key or integer ID? |
| 5 | audit_logs missing updated_at | DDL | DDL has no `updated_at` column; model uses SoftDeletes implying it | Add deleted_at to DDL; document that notes are updated via raw save |
| 6 | forceDelete permission uses 'delete' | Code | BillingCycleController::forceDelete() uses `prime.billing-cycle.delete` instead of dedicated `forceDelete` permission | Create separate forceDelete permission or document as intentional |
| 7 | BillingManagementController::store() lacks Gate::authorize | Code | store() method has no Gate check at method level; only create() does | Add Gate::authorize('prime.billing-management.create') |
| 8 | printData() lacks Gate::authorize | Code | No authorization on printData() method | Add Gate::authorize('prime.billing-management.print') |

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Route Summary
All routes are under `prefix('billing')->name('billing.')` middleware `['auth', 'verified']`.

| # | Method | URI | Controller@Method | Route Name | Notes |
|---|--------|-----|-------------------|------------|-------|
| 1 | GET | /billing/billing-management | BillingManagementController@index | billing.billing-management.index | Multi-tab hub |
| 2 | POST | /billing/billing-management | BillingManagementController@store | billing.billing-management.store | Invoice generation |
| 3 | GET | /billing/billing-management/create | BillingManagementController@create | billing.billing-management.create | Create form (stub) |
| 4 | GET | /billing/billing-management/{id} | BillingManagementController@show | billing.billing-management.show | (stub) |
| 5 | GET | /billing/billing-management/{id}/edit | BillingManagementController@edit | billing.billing-management.edit | (stub) |
| 6 | PUT/PATCH | /billing/billing-management/{id} | BillingManagementController@update | billing.billing-management.update | (stub) |
| 7 | DELETE | /billing/billing-management/{id} | BillingManagementController@destroy | billing.billing-management.destroy | (stub) |
| 8 | GET | /billing/billing-management/trash/view | BillingManagementController@trashedBillingManagement | billing.billing-management.trashed | Not implemented |
| 9 | GET | /billing/billing-management/{id}/restore | BillingManagementController@restore | billing.billing-management.restore | Not implemented |
| 10 | DELETE | /billing/billing-management/{id}/force-delete | BillingManagementController@forceDelete | billing.billing-management.forceDelete | Not implemented |
| 11 | POST | /billing/billing-management/{session}/toggle-status | BillingManagementController@toggleStatus | billing.billing-management.toggleStatus | Reconciliation toggle |
| 12 | GET | /billing/billing-management/view/{id} | BillingManagementController@view | billing.billing-management.view | Not implemented |
| 13 | POST | /billing/billing-management/pdfs | BillingManagementController@downloadPDF | billing.billing-management.pdfs | ZIP of PDFs |
| 14 | POST | /billing/billing-management/send-email | BillingManagementController@sendEmail | billing.billing-management.sendEmail | Immediate queue |
| 15 | POST | /billing/billing-management/schedule-email | BillingManagementController@scheduleEmail | billing.billing-management.scheduleEmail | Delayed queue |
| 16 | GET | /billing/subscription-details | BillingManagementController@subscriptionDetails | billing.billing-management.subscription.details | AJAX panel |
| 17 | GET | /billing/invoice-details | BillingManagementController@invoiceDetails | billing.billing-management.invoice.details | AJAX panel |
| 18 | GET | /billing/module-details | BillingManagementController@moduleDetails | billing.billing-management.module.details | AJAX panel |
| 19 | GET | /billing/billing-management/print/data | BillingManagementController@printData | billing.billing-management.print.data | Print view |
| 20 | GET | /billing/invoice/remarks | BillingManagementController@invoiceRemarks | billing.billing-management.invoice.remarks | AJAX form |
| 21 | POST | /billing/invoice/remarks/update | BillingManagementController@updateInvoiceRemarks | billing.billing-management.invoice.remarks.update | Save remarks |
| 22 | GET | /billing/billing/audit-log | BillingManagementController@AuditLog | billing.billing-management.audit.log | AJAX log panel |
| 23 | GET | /billing/subscription | SubscriptionController@index | billing.subscription.index | (stub) |
| 24 | POST | /billing/subscription | SubscriptionController@store | billing.subscription.store | ZIP PDF download |
| 25 | GET | /billing/billing/pricing-details | SubscriptionController@pricingDetails | billing.pricing.details | AJAX panel |
| 26 | GET | /billing/billing/billing-details | SubscriptionController@billingDetails | billing.billing.details | AJAX panel |
| 27 | GET | /billing/invoicing-payment | InvoicingPaymentController@index | billing.invoicing-payment.index | (stub) |
| 28 | GET | /billing/invoicing-payment/create | InvoicingPaymentController@create | billing.invoicing-payment.create | AJAX payment form |
| 29 | POST | /billing/invoicing-payment | InvoicingPaymentController@store | billing.invoicing-payment.store | Record payment |
| 30 | GET | /billing/billing/payment-details | InvoicingPaymentController@paymentDetails | billing.payment-details | AJAX panel |
| 31 | POST | /billing/billing/consolidated-store | InvoicingPaymentController@consolidatedStore | billing.consolidated.store | Consolidated payment |
| 32 | GET | /billing/billing/download-consolidated-pdf | InvoicingPaymentController@downloadConsolidatedPdf | billing.download.consolidated.pdf | PDF download |
| 33 | POST | /billing/download-selected-pdf | InvoicingPaymentController@downloadSelectedPdf | — | Reconciliation PDF |
| 34 | GET | /billing/invoicing-audit-log | InvoicingAuditLogController@index | billing.invoicing-audit-log.index | (stub) |
| 35 | POST | /billing/invoicing-audit-log | InvoicingAuditLogController@store | billing.invoicing-audit-log.store | (stub) |
| 36 | GET | /billing/audit/add-note | InvoicingAuditLogController@auditAddNote | billing.audit.add.note | AJAX form |
| 37 | POST | /billing/audit/add-note/update | InvoicingAuditLogController@auditAddNoteUpdate | billing.audit.add.note.update | Save note |
| 38 | GET | /billing/audit/event-info | InvoicingAuditLogController@auditEventInfo | — | AJAX JSON panel |
| 39 | GET | /billing/audit/download-pdf | InvoicingAuditLogController@downloadAuditNotePdf | — | Audit PDF |
| 40 | GET | /billing/billing-cycle | BillingCycleController@index | billing.billing-cycle.index | Cycle list |
| 41 | GET | /billing/billing-cycle/create | BillingCycleController@create | billing.billing-cycle.create | Create form |
| 42 | POST | /billing/billing-cycle | BillingCycleController@store | billing.billing-cycle.store | Create cycle |
| 43 | GET | /billing/billing-cycle/{id}/edit | BillingCycleController@edit | billing.billing-cycle.edit | Edit form |
| 44 | PUT/PATCH | /billing/billing-cycle/{id} | BillingCycleController@update | billing.billing-cycle.update | Update cycle |
| 45 | DELETE | /billing/billing-cycle/{id} | BillingCycleController@destroy | billing.billing-cycle.destroy | Soft delete |
| 46 | GET | /billing/billing-cycle/trash/view | BillingCycleController@trashed | billing.billing-cycle.trashed | Trash list |
| 47 | GET | /billing/billing-cycle/{id}/restore | BillingCycleController@restore | billing.billing-cycle.restore | Restore |
| 48 | DELETE | /billing/billing-cycle/{id}/force-delete | BillingCycleController@forceDelete | billing.billing-cycle.forceDelete | Permanent delete |
| 49 | POST | /billing/billing-cycle/{billingCycle}/toggle-status | BillingCycleController@toggleStatus | billing.billing-cycle.toggleStatus | Status toggle |

**Note:** The route block is duplicated 3× in routes/web.php (for 3 central domains). The module's own `Modules/Billing/routes/web.php` is a stub.

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

| # | Screen | File Path (relative to Modules/Billing/resources/views/) | Purpose | Key Fields/Features | Status |
|---|--------|----------------------------------------------------------|---------|---------------------|--------|
| 1 | Billing Cycle Index | billing-cycle/index.blade.php | List billing cycles with toggleStatus AJAX | DataTable, is_active toggle | Implemented |
| 2 | Billing Cycle Create | billing-cycle/create.blade.php | Create new billing cycle | short_name, name, months_count, is_active, is_recurring | Implemented |
| 3 | Billing Cycle Edit | billing-cycle/edit.blade.php | Edit existing cycle | Same fields as create | Implemented |
| 4 | Billing Cycle Trash | billing-cycle/trash.blade.php | View soft-deleted cycles; restore/force delete | Restore button, Force Delete button | Implemented |
| 5 | Billing Management Index | billing-management/index.blade.php | Main hub with tabbed interface for all billing views | Tab switcher via ?type param | Implemented |
| 6 | Invoice Listing (default tab) | partials/invoicing/invoicing.blade.php | Invoice generation table with checkboxes | Filters: data_type, status, invoice_status, date_range; Generate Invoice button | Implemented |
| 7 | Invoice PDF View | partials/invoicing/pdf.blade.php | DomPDF template for invoice | All invoice fields, tax breakdown, tenant details | Implemented |
| 8 | Invoice Print View | partials/invoicing/print.blade.php | Browser print template | Same as PDF | Implemented |
| 9 | Invoice Email Template | partials/invoicing/email.blade.php | Mailable view for InvoiceMail | Invoice summary, PDF attachment message | Implemented |
| 10 | Schedule Invoice Modal | partials/invoicing/schedule-Invoice.blade.php | Datetime picker for scheduled email | schedule_time input | Implemented |
| 11 | Subscription Details view | partials/subscrption-details/subscription.blade.php | Subscription data tab | Filters: status, date_range | Implemented |
| 12 | Subscription PDF | partials/subscrption-details/pdf.blade.php | PDF of subscription summary | TenantPlanRate with tenant/plan/billingCycle | Implemented |
| 13 | Subscription Print | partials/subscrption-details/print.blade.php | Print view | Same as PDF | Implemented |
| 14 | Invoice Payment Tab | partials/invoice-payment/index.blade.php | Invoice payment listing | Filters: payment_status, date_range | Implemented |
| 15 | Invoice Payment Print | partials/invoice-payment/print.blade.php | Print view for payments | Payment records | Implemented |
| 16 | Consolidated Payment Tab | partials/consolidated-payment/index.blade.php | Multi-invoice payment form | invoice_ids[], new_payment[], payment_status[] per invoice | Implemented |
| 17 | Consolidated Payment PDF | partials/consolidated-payment/pdf.blade.php | PDF for consolidated statement | totalPayable, totalPaid, totalBalance | Implemented |
| 18 | Consolidated Payment Print | partials/consolidated-payment/print.blade.php | Print view | Same as PDF | Implemented |
| 19 | Payment Reconciliation Tab | partials/payment-reconcilation/index.blade.php | Reconciliation toggle list | payment_reconciled toggle per row | Implemented |
| 20 | Reconciliation PDF | partials/payment-reconcilation/pdf.blade.php | PDF for reconciliation report | Selected payments | Implemented |
| 21 | Reconciliation Print | partials/payment-reconcilation/print.blade.php | Print view | | Implemented |
| 22 | Invoice Audit Log Tab | partials/invoice-audit/index.blade.php | Audit event listing | Filters: date_range, tenant, performed_by, audit_status | Implemented |
| 23 | Audit Log PDF | partials/invoice-audit/pdf.blade.php | PDF for audit report | All audit log fields | Implemented |
| 24 | Audit Log Print | partials/invoice-audit/print.blade.php | Print view | | Implemented |
| 25 | Detail Panels (AJAX) | partials/details/*.blade.php | 10 inline AJAX panels | subscription-details, invoice-details, pricing-details, billing-schedule, module-details, payment-details, add-payment, invoice-remarks, audit-log, audit-add-note, audit-event-info | Implemented |
| 26 | Model Details | partials/model/details.blade.php | Generic modal detail container | Wraps AJAX panel content | Implemented |
| 27 | Module CSS/JS | partials/css/css.blade.php, partials/js/js.blade.php | Included styles and scripts | DataTables, date range picker, AJAX handlers | Implemented |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| # | Rule | Source | Implementation |
|---|------|--------|----------------|
| BR-001 | invoice_no must be globally unique | DDL UNIQUE constraint | INV-YYYYMMDD-NNN format; NNN = today's invoice count + 1 padded to 3 digits |
| BR-002 | billing_qty = max(min_billing_qty, total_user_qty) | Code | generateInvoiceForOrganization() — line: `$billingQty = max($planRate->min_billing_qty, $totalUserQty)` |
| BR-003 | total_user_qty is counted from tenant's isolated DB | Code | Tenancy::initialize($tenant) → Student::where('is_active','1')→count(); Tenancy::end() |
| BR-004 | net_payable = sub_total - discount + extra_charges + total_tax | Code | Calculated inline; no stored formula |
| BR-005 | tax base = sub_total - discount_amount + extra_charges | Code | `$taxBase = ($subTotal - $discountAmount + $extraCharges)` |
| BR-006 | payment_due_date = invoice_date + credit_days | Code | `Carbon::parse($invoiceDate)->addDays($planRate->credit_days)` |
| BR-007 | A billing schedule entry can only be invoiced once | DDL + Code | `bill_generated` flag; `generated_invoice_id` FK; code checks existing invoice before generation (implicit via transaction) |
| BR-008 | invoice status is stored as Dropdown ID (integer FK) | Code | `Dropdown::where('key','bil_tenant_invoices.status.invoice_status')->where('ordinal','1')->first()` — first ordinal is default status |
| BR-009 | paid_amount is cumulative — never decremented | Code | `$invoice->paid_amount = $invoice->paid_amount + $request->amount_paid` — additive only |
| BR-010 | Consolidated payment stores total in consolidated_amount; per-invoice in amount_paid | Code | Dual fields on bil_tenant_invoicing_payments |
| BR-011 | Billing module reads tenant DB in prime context | Code | Stancl\Tenancy Tenancy::initialize() call during invoice generation — must end tenancy after |
| BR-012 | Audit log entries are append-only | Code | Only InvoicingAuditLog::create() used; no update except notes field |
| BR-013 | Soft delete deactivates before deleting | Code | BillingCycleController::destroy() sets is_active=false then calls $model->delete() |
| BR-014 | Email job attaches PDF generated from DomPDF | Code | SendInvoiceEmailJob::handle() generates PDF; InvoiceMail::build() attachData($pdfContent) |
| BR-015 | Currency defaults to INR | DDL | bil_tenant_invoices.currency CHAR(3) DEFAULT 'INR'; hardcoded 'INR' in consolidatedStore |
| BR-016 | Four tax lines accommodate CGST, SGST, IGST, and custom | DDL | tax1_remark through tax4_remark store tax type labels |
| BR-017 | Invoice ZIP download deletes temp files after reading | Code | @unlink($zipPath); temp PDF files not explicitly deleted (minor memory issue) |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

### 9.1 Invoice Lifecycle

```
[Billing Schedule Record Created]
          │
          ▼
    bill_generated = 0
    (Inv. Need To Generate)
          │
          │ Admin selects + POST /billing/billing-management
          ▼
    generateInvoiceForOrganization()
    → Create bil_tenant_invoices (status = first Dropdown ordinal for invoice_status)
    → Set bill_generated = 1, generated_invoice_id = invoice.id
    → Create GENERATED audit log entry
          │
          ▼
    Invoice Status (from glb_dropdowns):
          │
          ├─► PENDING — newly generated; payment_due_date in future
          │
          ├─► PARTIALLY_PAID — some payment received; paid_amount < net_payable_amount
          │         (via InvoicingPaymentController::store)
          │
          ├─► PAID / FULLY_PAID — paid_amount >= net_payable_amount
          │
          ├─► OVERDUE — payment_due_date passed; no full payment (no automated detection yet)
          │
          └─► CANCELLED — manual status update (no dedicated cancel endpoint yet)
```

### 9.2 Payment Processing Workflow

```
[Admin Opens Invoice]
        │
        ├─► Individual Payment:
        │   GET /billing/invoicing-payment/create?id={invoice_id}
        │   → Load add-payment AJAX panel
        │   POST /billing/invoicing-payment
        │   → Validate StoreInvoicePaymentRequest
        │   → DB::transaction { create InvoicingPayment; update invoice.paid_amount; create audit log }
        │   → Response JSON {status: true}
        │
        └─► Consolidated Payment:
            GET /billing/billing-management?type=consolidated-payment
            → List outstanding invoices (paid_amount != net_payable_amount)
            POST /billing/billing/consolidated-store
            → Validate ConsolidatedPaymentRequest
            → DB::transaction { loop invoices: create InvoicingPayment per invoice; update each invoice.paid_amount; create PAYMENT_UPDATED audit per invoice }
            → Response JSON {status: true}
```

### 9.3 Email Dispatch Workflow

```
Admin selects invoices
        │
        ├─► Immediate: POST /send-email {ids[]}
        │   → Loop: SendInvoiceEmailJob::dispatch($id)
        │   → Queue worker picks up job
        │   → Load BilTenantInvoice; generate DomPDF; create InvoicingAuditLog 'Notice Sent'
        │   → Mail::to(tenant.email)->send(InvoiceMail) with PDF attachment
        │
        └─► Scheduled: POST /schedule-email {id, schedule_time}
            → Create BillTenatEmailSchedule (status='pending')
            → Create InvoicingAuditLog 'Notice Sent'
            → SendInvoiceEmailJob::dispatch($id)->delay($scheduleAt)
            → Queue worker picks up at scheduled time
```

### 9.4 Reconciliation Workflow

```
Payment recorded (payment_reconciled = 0 by default)
        │
        ▼
Accountant reviews payment in Reconciliation tab
        │
        ▼
Toggle: POST /billing-management/{session}/toggle-status (routes to toggleStatus($id))
        │
        ▼
InvoicingPayment.payment_reconciled toggled (0 ↔ 1)
activityLog recorded
        │
        ▼
payment_reconciled = 1 (Reconciled)
```

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| # | Category | Requirement | Priority |
|---|----------|-------------|----------|
| 1 | Performance | Billing management index with 1000+ schedule records loads in <3s | High |
| 2 | Performance | ZIP generation for 50 invoices completes within 30s (PHP max_execution_time) | High |
| 3 | Performance | Consolidated payment query should use DB index on payment_due_date | Medium |
| 4 | Security | All controller methods must have Gate::authorize() or Gate::any() before business logic | Critical |
| 5 | Security | printData() method must have authorization (currently missing) | Critical |
| 6 | Security | BillingManagementController::store() must have explicit Gate::authorize | Critical |
| 7 | Security | Tenancy::initialize() must always be followed by Tenancy::end() to prevent tenant context leakage | Critical |
| 8 | Security | gateway_response JSON stored raw — ensure no sensitive keys logged | Medium |
| 9 | Reliability | DB::transaction wraps all invoice generation and payment recording | High |
| 10 | Reliability | SendInvoiceEmailJob should implement retry logic ($tries > 1) and failed job logging | High |
| 11 | Auditability | Every billing action creates an entry in bil_tenant_invoicing_audit_logs | High |
| 12 | Auditability | sys_activity_logs (global activityLog helper) called for all model mutations | Medium |
| 13 | Data Integrity | BillTenatEmailSchedule.invoice_id should have FK constraint enforced | Medium |
| 14 | Scalability | Invoice generation should support batch sizes of 100+ records without memory issues | Medium |
| 15 | Maintainability | Duplicate fillable fields in BilTenantInvoice should be cleaned up | Low |
| 16 | Queue | Laravel queue worker required for email delivery; must be monitored in production | High |
| 17 | PDF Quality | DomPDF rendered invoices must be A4 portrait with professional layout for legal use | Medium |

---

## 11. CROSS-MODULE DEPENDENCIES

### 11.1 This Module Depends On

| # | Module | MODULE_CODE | Status | Dependency Type | What It Needs |
|---|--------|-------------|--------|----------------|---------------|
| 1 | Prime | PRM | Implemented | Data | `prm_tenant`, `prm_tenant_plan_jnt`, `prm_tenant_plan_rates`, `prm_tenant_plan_billing_schedule`, `TenantPlanRate`, `TenantPlanBillingSchedule`, `TenantPlanModule`, `Tenant` models |
| 2 | GlobalMaster | GLB | Implemented | Data | `glb_modules` (via view in prime_db), `Dropdown` model for invoice status and payment mode values, `Module` model |
| 3 | SchoolSetup | SCH | Implemented | Data | `PrmTenantPlan` model (imported from Modules\SchoolSetup) |
| 4 | StudentProfile | STD | Implemented | Data | `Student` model — queried via Tenancy::initialize() to count active students per billing period |
| 5 | SystemConfig | SYS | Implemented | Infrastructure | `sys_activity_logs` (activityLog helper), `sys_users` (FK on audit_logs.performed_by), `User` model |
| 6 | Auth | AUTH | Implemented | Infrastructure | Laravel Auth, Spatie Gate permissions (`prime.billing-*`) |

### 11.2 Modules That Depend on This

| # | Module | What It Uses |
|---|--------|-------------|
| 1 | Prime Module | `bil_tenant_invoices.id` referenced via `prm_tenant_plan_billing_schedule.generated_invoice_id` FK |
| 2 | (Future) Analytics/Reports | Billing revenue data for SaaS financial dashboards |
| 3 | (Future) Tenant Portal | Invoice viewing and payment initiation from school admin side |

---

## 12. TEST CASE REFERENCE & COVERAGE

### 12.1 Existing Tests

| # | Test File | Type | Test Count | Covers |
|---|-----------|------|------------|--------|
| 1 | `Modules/Billing/tests/Unit/BillingModuleTest.php` | Unit (Pest) | ~55 | Model structure (table names, fillable, casts, SoftDeletes, relationships), Controller class existence, Gate::authorize presence in BillingCycleController, known security gaps in BillingManagementController (documented as known issues), Policy method existence, File existence checks |

### 12.2 Known Gaps Documented in Tests
The existing test file explicitly documents several known issues:
- `BilTenantInvoice` has duplicate fillable fields (documented as "known bug")
- `BillingManagementController::create`, `store`, `show`, `printData`, `downloadPDF`, `sendEmail` lack `Gate::authorize` (documented as "known security gap")
- `BillingManagementPolicy` has 6 methods commented out (documented as "known gap")
- `SchedulerController` — referenced in test but not part of Billing module; may be a leftover reference

### 12.3 Proposed Test Plan (Gaps)

| # | Test Scenario | Type | Feature Ref | Priority |
|---|--------------|------|-------------|----------|
| 1 | Generate invoice: net_payable calculation accuracy | Feature | FR-BIL-003 | Critical |
| 2 | Generate invoice: billing_qty = max(min_qty, student_count) | Feature | FR-BIL-003 | Critical |
| 3 | Generate invoice: DB transaction rollback on missing planRate | Feature | FR-BIL-003 | High |
| 4 | Generate invoice: invoice_no uniqueness per day | Feature | FR-BIL-003 | High |
| 5 | Generate invoice: module junction rows created | Feature | FR-BIL-003 | Medium |
| 6 | Generate invoice: GENERATED audit log entry created | Feature | FR-BIL-003 | Medium |
| 7 | Record payment: invoice.paid_amount increments correctly | Feature | FR-BIL-006 | Critical |
| 8 | Record payment: audit log Partially Paid entry created | Feature | FR-BIL-006 | High |
| 9 | Consolidated payment: multiple invoices updated in one transaction | Feature | FR-BIL-007 | High |
| 10 | Consolidated payment: zero-allocation invoices skipped | Feature | FR-BIL-007 | Medium |
| 11 | Reconciliation toggle: payment_reconciled flips 0→1→0 | Feature | FR-BIL-008 | Medium |
| 12 | Billing cycle soft delete: is_active=false before delete | Feature | FR-BIL-001 | Medium |
| 13 | Billing cycle force delete: FK violation returns error response | Feature | FR-BIL-001 | Medium |
| 14 | SendInvoiceEmailJob: dispatched to queue on sendEmail | Feature | FR-BIL-004 | Medium |
| 15 | Scheduled email: BillTenatEmailSchedule record created | Feature | FR-BIL-004 | Medium |
| 16 | BillingManagementController::store() unauthorized access returns 403 | Feature | Security | Critical |
| 17 | printData() unauthorized access returns 403 | Feature | Security | Critical |
| 18 | Tenant context ends after student count query | Feature | BR-011 | Critical |

### 12.4 Coverage Summary

| Category | Required | Existing | Gap | Coverage % |
|----------|---------|----------|-----|------------|
| Model structure | 6 models | 6 models (Unit) | 0 | 100% |
| Controller auth | All methods | Partial (Unit assertion only) | Feature-level missing | 20% |
| Invoice generation logic | 6 scenarios | 0 | 6 | 0% |
| Payment recording | 4 scenarios | 0 | 4 | 0% |
| Email delivery | 2 scenarios | 0 | 2 | 0% |
| Reconciliation | 2 scenarios | 0 | 2 | 0% |
| Security (403 responses) | 8 scenarios | 0 | 8 | 0% |
| **Overall** | **~40 scenarios** | **~10 (structure)** | **~30** | **~25%** |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition |
|------|-----------|
| Invoice | SaaS billing document generated for a school tenant covering a specific billing period |
| Billing Cycle | Frequency of billing: Monthly (1 month), Quarterly (3 months), Yearly (12 months), One-Time |
| Billing Schedule | `prm_tenant_plan_billing_schedule` row — pre-generated schedule entries for a tenant's plan validity period |
| Billing Qty | The quantity used for invoice calculation: max(min_billing_qty, total_user_qty) |
| Min Billing Qty | Minimum number of licenses contracted (floor for billing even if fewer students) |
| Total User Qty | Actual count of active students in the tenant DB during the billing period |
| Net Payable | Final invoice amount after discounts, extra charges, and all taxes |
| Tax Base | `sub_total - discount_amount + extra_charges` — amount on which taxes are applied |
| Credit Days | Number of days from invoice date until payment is due |
| Consolidated Payment | Single bank/NEFT transaction distributed across multiple outstanding invoices |
| Reconciliation | Process of confirming that a recorded payment matches a bank/gateway confirmation |
| Audit Log | `bil_tenant_invoicing_audit_logs` — event-level trail recording who did what on which invoice |
| action_type | ENUM-like VARCHAR on audit log: GENERATED, Partially Paid, Notice Sent, PAYMENT_UPDATED, Not Billed |
| bill_generated | Flag on billing schedule row indicating an invoice has been generated (0=pending, 1=done) |
| Tenancy Context | Stancl Tenancy tenant DB context; must be initialized and ended when querying per-school data |
| ZIP Download | Multiple invoice PDFs packaged in a ZIP archive for bulk download |
| CGST/SGST/IGST | Indian GST tax types: Central GST, State GST, Integrated GST — mapped to tax1-4 fields |

---

## 14. ADDITIONAL SUGGESTIONS

> These are analyst recommendations and are NOT sourced from the RBS or existing code.

### 14.1 Feature Enhancement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Implement automated recurring invoice scheduler as an Artisan command | Currently all invoice generation is manual. With 100+ tenants on monthly plans, Super Admins cannot manually generate invoices each month. A scheduled command running daily to check billing_schedule_date = today and generate invoices automatically is critical for scale. | Critical | Medium |
| 2 | Build overdue invoice detection and automated reminder emails | No mechanism to detect invoices past payment_due_date or send automated reminders. Implement a daily job: find invoices where payment_due_date < today AND paid_amount < net_payable_amount AND status != CANCELLED, then queue reminder emails and create 'Overdue' audit log entries. | High | Medium |
| 3 | Add Razorpay webhook endpoint for payment confirmation | The `gateway_response` JSON column exists but there is no webhook handler. Implement POST `/api/billing/razorpay/webhook` to receive Razorpay payment.captured events, auto-create InvoicingPayment, and mark payment_reconciled=1 automatically. | High | High |
| 4 | Implement tenant self-service billing portal (RBS V6) | School admins cannot currently view their invoices or make online payments. Add tenant-context routes in routes/tenant.php for invoice listing, PDF download, and Razorpay payment initiation. | Medium | High |
| 5 | Add trial-period management (RBS V2.1.2) | No trial-to-paid conversion flow exists. Add trial_ends_at to prm_tenant_plan_jnt and a scheduled job to auto-convert and generate first invoice. | Medium | Medium |

### 14.2 Technical Improvement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Fix BilTenantInvoice duplicate $fillable fields | paid_amount, currency, status, credit_days, payment_due_date, is_recurring, auto_renew, remarks appear twice. While Laravel silently handles this, it is misleading and a latent bug risk. | Low | Low |
| 2 | Add Gate::authorize to BillingManagementController::store(), printData(), downloadPDF(), sendEmail() | These methods operate without authorization checks creating security gaps. The existing unit tests document this as "known" — it must be fixed. | Critical | Low |
| 3 | Add FK constraint on bil_tenant_email_schedules.invoice_id | Orphaned email schedule records can accumulate if invoices are deleted. Add FK with ON DELETE CASCADE. | Medium | Low |
| 4 | Extract generateInvoiceForOrganization() into a BillingService class | The method is 150+ lines of business logic in the controller. Move to `Modules\Billing\Services\BillingService::generateInvoice()` for testability and reuse by the future automated scheduler. | Medium | Medium |
| 5 | Add SendInvoiceEmailJob retry and failure handling | `$tries` is not set (defaults to 1). Failed email jobs silently disappear. Add `$tries = 3`, `$backoff = [60, 300]`, and implement `failed()` method to update BillTenatEmailSchedule.status = 'failed'. | High | Low |
| 6 | Clean up temp PDF files in ZIP generation | BillingManagementController::downloadPDF() and SubscriptionController::store() create temp PDF files via file_put_contents() but do not delete them after adding to the ZIP. Use `register_shutdown_function()` or collect paths and unlink after ZIP close. | Medium | Low |
| 7 | Align audit_logs column name | DDL column is `tenant_invoice_id`; model fillable has `tenant_invoicing_id`. One of these is wrong — verify and fix to prevent silent null inserts. | High | Low |
| 8 | Move Billing route blocks (duplicated 3× in web.php) to a reusable group | The billing route block appears identically 3 times in routes/web.php for each central domain. Extract to a shared group or use Route::domain() pattern properly. | Low | Low |

### 14.3 UX/UI Improvement Suggestions

| # | Suggestion | Rationale | Impact | Effort |
|---|-----------|-----------|--------|--------|
| 1 | Add real-time payment balance indicator on invoice rows | Show outstanding_balance = net_payable_amount - paid_amount inline so accountants can see at a glance how much is still due without opening a detail panel. | Medium | Low |
| 2 | Add status badge with color coding on invoice list | PENDING (yellow), PAID (green), OVERDUE (red), PARTIALLY_PAID (orange) — visual differentiation speeds up workflow. | Medium | Low |
| 3 | Implement invoice preview modal before PDF generation | Allow admins to preview the invoice in a modal before generating/emailing to catch data errors (wrong student count, wrong rate) without downloading a PDF. | Medium | Medium |
| 4 | Add bulk action toolbar for common operations | Currently invoices must be individually selected for email/PDF. A persistent toolbar showing selected count with Email, PDF, and Generate buttons improves batch workflow. | Medium | Low |

### 14.4 Integration Opportunities

| # | Integration | With Module | Benefit | Effort |
|---|------------|-------------|---------|--------|
| 1 | Link billing dashboard to School Profile | SCH | Super Admin can jump from an invoice to the school's profile page for context | Low |
| 2 | Trigger billing notification to tenant on invoice generation | Notifications Module | Automated in-app notification when invoice is generated eliminates need for manual email | Medium |
| 3 | Revenue analytics in Analytics module | Analytics (future) | Monthly recurring revenue (MRR), churn, payment failure rates across all tenants | High |
| 4 | HR/Payroll cost alignment | HR & Payroll (future) | Compare SaaS revenue per tenant against operational cost to compute per-tenant profitability | High |

### 14.5 Indian Education Domain Suggestions

| # | NEP/Domain Requirement | How Billing Module Can Address It | Priority |
|---|----------------------|----------------------------------|----------|
| 1 | GST compliance for software subscriptions (18% GST for IT services in India) | Implement tax1=CGST 9%, tax2=SGST 9% for intra-state OR tax1=IGST 18% for inter-state as default templates. Add GSTIN field to tenant profile and billing. | Critical |
| 2 | B2B invoice requirements under GSTN | Add seller GSTIN, buyer GSTIN (school), HSN/SAC code (998313 for software subscription services), place of supply to invoice PDF for GST compliance | High |
| 3 | Academic year billing alignment | Indian schools operate April–March. Billing periods should align with academic year. Add academic_year_id linkage to billing schedule for easy year-wise revenue reporting. | Medium |
| 4 | State Education Department grants | Some government schools receive IT grants. Add payment_source (School Self/State Grant/Central Grant) field to payments for subsidy tracking. | Low |
| 5 | Multi-school trust/group billing | Many Indian schools are operated by trusts (e.g., DAV, KV Sangathan) with multiple campuses. Add tenant_group concept for consolidated invoicing across group schools. | Medium |

---

## 15. APPENDICES

### Appendix A — Full RBS Extract (Module V)

```
## Module V — SaaS Billing & Subscription (54 sub-tasks)

### V1 — Subscription Plans & Pricing (10 sub-tasks)

F.V1.1 — Plan Configuration
- T.V1.1.1 — Create Subscription Plan
  - ST.V1.1.1.1 Define plan name & description
  - ST.V1.1.1.2 Set pricing (monthly/quarterly/yearly)
  - ST.V1.1.1.3 Assign included modules/features
- T.V1.1.2 — Plan Rules
  - ST.V1.1.2.1 Define user limits
  - ST.V1.1.2.2 Set storage limits
  - ST.V1.1.2.3 Configure overage pricing
F.V1.2 — Plan Management
- T.V1.2.1 — Edit/Update Plan
  - ST.V1.2.1.1 Modify pricing & limits
  - ST.V1.2.1.2 Update feature list
- T.V1.2.2 — Plan Activation/Deactivation
  - ST.V1.2.2.1 Activate plan for sale
  - ST.V1.2.2.2 Retire old plan versions

### V2 — Tenant Subscription Assignment (9 sub-tasks)

F.V2.1 — Subscription Purchase
- T.V2.1.1 — Assign Plan to Tenant
  - ST.V2.1.1.1 Select subscription plan
  - ST.V2.1.1.2 Set start/end date
  - ST.V2.1.1.3 Configure billing cycle
- T.V2.1.2 — Trial Management
  - ST.V2.1.2.1 Enable trial period
  - ST.V2.1.2.2 Auto-convert trial to paid subscription
F.V2.2 — Subscription Lifecycle
- T.V2.2.1 — Renewal Management
  - ST.V2.2.1.1 Auto-renew subscription
  - ST.V2.2.1.2 Notify tenant for manual renewal
- T.V2.2.2 — Upgrade/Downgrade
  - ST.V2.2.2.1 Switch plan mid-cycle
  - ST.V2.2.2.2 Apply prorated charges

### V3 — Billing Engine (9 sub-tasks)

F.V3.1 — Invoice Generation
- T.V3.1.1 — Generate Invoice
  - ST.V3.1.1.1 Create recurring invoice
  - ST.V3.1.1.2 Include addons/overage usage
  - ST.V3.1.1.3 Apply taxes as per region
- T.V3.1.2 — Invoice Scheduling
  - ST.V3.1.2.1 Schedule monthly/annual billing
  - ST.V3.1.2.2 Send reminders for unpaid invoices
F.V3.2 — Payment Processing
- T.V3.2.1 — Record Payment
  - ST.V3.2.1.1 Accept online payment (UPI/Card)
  - ST.V3.2.1.2 Record offline payment (NEFT/Cash)
- T.V3.2.2 — Auto-Reconciliation
  - ST.V3.2.2.1 Match payment with invoice automatically
  - ST.V3.2.2.2 Flag mismatched transactions

### V4 — Metering, Usage & Overage Tracking (6 sub-tasks)

F.V4.1 — Usage Monitoring
- T.V4.1.1 — Track Resource Usage
  - ST.V4.1.1.1 Monitor API calls
  - ST.V4.1.1.2 Track storage consumption
- T.V4.1.2 — Overage Alerts
  - ST.V4.1.2.1 Notify tenant when nearing limits
  - ST.V4.1.2.2 Auto-lock premium features when exceeded
F.V4.2 — Overage Billing
- T.V4.2.1 — Calculate Overage Charges
  - ST.V4.2.1.1 Multiply usage above threshold
  - ST.V4.2.1.2 Apply overage invoice line items

### V5 — Payment Gateways & Integrations (6 sub-tasks)

F.V5.1 — Gateway Setup
- T.V5.1.1 — Configure Gateway
  - ST.V5.1.1.1 Add API keys for Razorpay/Stripe/PayPal
  - ST.V5.1.1.2 Set webhook URL for payment confirmation
- T.V5.1.2 — Gateway Testing
  - ST.V5.1.2.1 Send test payment request
  - ST.V5.1.2.2 Verify webhook response
F.V5.2 — Multi-Currency Support
- T.V5.2.1 — Enable Currencies
  - ST.V5.2.1.1 Configure supported currencies
  - ST.V5.2.1.2 Set exchange rate source

### V6 — Tenant Billing Portal (8 sub-tasks)

F.V6.1 — Billing Dashboard
- T.V6.1.1 — View Billing History
  - ST.V6.1.1.1 Display invoices list
  - ST.V6.1.1.2 Filter by paid/unpaid
- T.V6.1.2 — View Usage Summary
  - ST.V6.1.2.1 Show API/storage usage
  - ST.V6.1.2.2 Highlight overage areas
F.V6.2 — Self-Service Payments
- T.V6.2.1 — Download Invoice
  - ST.V6.2.1.1 Download invoice PDF
  - ST.V6.2.1.2 Download payment receipt
- T.V6.2.2 — Make Online Payment
  - ST.V6.2.2.1 Redirect to online payment gateway
  - ST.V6.2.2.2 Update payment status in system

### V7 — SaaS Compliance & Audit (6 sub-tasks)

F.V7.1 — Audit Logs
- T.V7.1.1 — Track Billing Events
  - ST.V7.1.1.1 Record invoice creation
  - ST.V7.1.1.2 Log payment confirmations
- T.V7.1.2 — Track Subscription Updates
  - ST.V7.1.2.1 Record plan upgrade/downgrade
  - ST.V7.1.2.2 Maintain full audit trail
F.V7.2 — Compliance Reports
- T.V7.2.1 — Generate Compliance Report
  - ST.V7.2.1.1 GST/Tax reports
  - ST.V7.2.1.2 Country-wise billing summaries
```

### Appendix B — Complete Route Table
See Section 6.1 — all 49 route entries documented there.

### Appendix C — Complete Code Inventory

```
Modules/Billing/
├── app/Http/Controllers/
│   ├── BillingCycleController.php          (199 lines)
│   ├── BillingManagementController.php     (977 lines)
│   ├── InvoicingController.php             (69 lines — stub)
│   ├── InvoicingPaymentController.php      (328 lines)
│   ├── InvoicingAuditLogController.php     (146 lines)
│   └── SubscriptionController.php         (154 lines)
├── app/Http/Requests/
│   ├── BillingCycleRequest.php             (79 lines)
│   ├── ConsolidatedPaymentRequest.php      (76 lines)
│   └── StoreInvoicePaymentRequest.php      (100 lines)
├── app/Jobs/
│   └── SendInvoiceEmailJob.php             (53 lines)
├── app/Mail/
│   └── InvoiceMail.php                     (33 lines)
├── app/Models/
│   ├── BillingCycle.php                    (55 lines — table: prm_billing_cycles)
│   ├── BilTenantInvoice.php                (118 lines — table: bil_tenant_invoices)
│   ├── BillOrgInvoicingModulesJnt.php      (31 lines — table: bil_tenant_invoicing_modules_jnt)
│   ├── BillTenatEmailSchedule.php          (19 lines — table: bil_tenant_email_schedules)
│   ├── InvoicingAuditLog.php               (40 lines — table: bil_tenant_invoicing_audit_logs)
│   └── InvoicingPayment.php                (60 lines — table: bil_tenant_invoicing_payments)
├── app/Policies/
│   ├── BillingCyclePolicy.php
│   ├── BillingManagementPolicy.php
│   ├── ConsolidatedPaymentPolicy.php
│   ├── InvoicingAuditLogPolicy.php
│   ├── InvoicingPaymentPolicy.php
│   ├── InvoicingPolicy.php
│   └── PaymentReconciliationPolicy.php
│   └── SubscriptionPolicy.php
├── app/Providers/
│   ├── BillingServiceProvider.php
│   ├── EventServiceProvider.php
│   └── RouteServiceProvider.php
├── config/config.php
├── database/seeders/BillingDatabaseSeeder.php  (empty)
├── resources/views/                            (27 blade files — see Section 7)
├── routes/
│   ├── web.php                                 (stub)
│   └── api.php                                 (empty)
└── tests/
    └── Unit/BillingModuleTest.php              (~315 lines, ~55 test cases, Pest syntax)
```

### Appendix D — Test Listing

| File | Path | Type | Framework | Count |
|------|------|------|-----------|-------|
| BillingModuleTest.php | `Modules/Billing/tests/Unit/BillingModuleTest.php` | Unit | Pest | ~55 test cases |

**Test groups in BillingModuleTest.php:**
- `BillingCycle Model` — 5 tests (table, SoftDeletes, fillable, casts, relationships)
- `BilTenantInvoice Model` — 6 tests (table, SoftDeletes, fillable, known duplicate bug, casts, relationships)
- `InvoicingPayment Model` — 5 tests
- `InvoicingAuditLog Model` — 4 tests
- `BillOrgInvoicingModulesJnt Model` — 3 tests
- `BillTenatEmailSchedule Model` — 3 tests
- `BillingCycleController — Authorization` — ~12 tests
- `BillingManagementController — Authorization (CRITICAL)` — 8 tests (documents known security gaps)
- `SchedulerController — Authorization (ZERO AUTH)` — 7 tests (external reference, not part of Billing module)
- `Billing Architecture — All Classes Exist` — ~15 tests (controllers, models, requests, job, mail)
- `Billing Policies` — 5 tests
- `Billing Files — Existence` — 2 tests

**No Feature tests exist.** All tests are structural/architectural unit tests using reflection.
```
