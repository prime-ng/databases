# Billing Module — Requirements Index

## Purpose
Master index of all requirement files for the Billing module. Each file documents the business purpose, database fields, business rules, CRUD operations, and permissions for one feature area.

---

## Tab → Requirement File Map

| Feature Area | File | Status |
|---|---|---|---|
| **Billing Cycles** | `billing-cycles.md` | ✅ Implemented (95%) |
| **Invoice Generation** | `invoicing.md` | ✅ Full — includes filter architecture (95%) |
| **Invoice Payments** | `invoice-payments.md` | 🟡 Partial — filter documented (70%) |
| **Consolidated Payments** | `consolidated-payments.md` | 🟡 Partial — filter documented (65%) |
| **Payment Reconciliation** | `payment-reconciliation.md` | ✅ Full — filter documented (90%) |
| **Invoice Audit Log** | `audit-log.md` | 🟡 Partial — filter documented (75%) |
| **Email Schedule** | `email-schedule.md` | 🟡 Partial — filter documented (80%) |
| **Subscription Views** | `subscription.md` | 🟡 Partial — filter documented (75%) |
| **Gateway Integration** | `gateway-integration.md` | ❌ Not Started (0%) |

---

## Module Statistics

| Metric | Count |
|---|---|
| Database Tables (bil_*) | 4 (plus 1 prm_* table) |
| Models | 6 |
| Controllers | 7 (1 GOD controller at 1036 lines) |
| Web Routes | 49 |
| API Routes | 0 |
| View Files | 46 |
| Policies | 8 (only 3 functional — critical bug) |
| Form Requests | 3 |
| Jobs | 1 (SendInvoiceEmailJob) |
| Mail Classes | 1 (InvoiceMail) |
| Tests | ~55 (Unit only) |

---

## Critical Issues (P0)

| ID | Issue | Area | Impact |
|---|---|---|---|
| POL-01/POL-02 | Duplicate Gate::policy registrations — 5 of 8 policies are dead code | Cross-Cutting | All `Gate::authorize()` calls for billing-management abilities are non-functional |
| DB-01/MDL-01 | FK column mismatch: model uses `tenant_invoicing_id`, DDL says `tenant_invoice_id` | Audit Log | All audit log inserts silently fail on fresh DB |
| SEC-01–09 | 9 controller methods missing authorization | Cross-Cutting | Any authenticated user can view/modify billing data |
| ERR-01/ERR-02 | DB::beginTransaction() without try/catch | Payments | Transaction leak on exception — data inconsistency |
| DB-07 | Duplicate `$fillable` fields in BilTenantInvoice (8 fields appear twice) | Invoicing | Latent bug risk |
| SEC-004 | Webhook endpoint would be behind auth middleware | Gateway | Impossible for Razorpay to call when implemented |

## High Priority Issues (P1)

| ID | Issue | Area |
|---|---|---|
| SVC-01/SVC-02 | Zero service classes — all logic in 1036-line GOD controller | Cross-Cutting |
| FRQ-01–04 | Missing FormRequest validation on 4 endpoints | Cross-Cutting |
| INP-06 | `$request->all()` stored in audit event_info — sensitive data leak | Audit Log |
| PERF | N+1 queries: `Tenant::get()` and `User::get()` unfiltered on every page load | Invoicing |
| DB-02–06 | Missing DDL columns: `created_by`, `deleted_at`, `is_active`, `updated_at` | All tables |

---

## Sprint Plan

| Sprint | Focus | Areas Involved |
|---|---|---|
| 1 | **Authorization & Policy Fix (P0)** | Cross-Cutting — fix policy registrations, add Gate::authorize to 9 methods |
| 2 | **Data Integrity (P0)** | Audit Log — fix FK column name; Invoicing — fix duplicate fillable; Payments — add try/catch |
| 3 | **Service Layer Extraction (P1)** | Cross-Cutting — extract BillingService from GOD controller |
| 4 | **FormRequest & Validation (P1)** | All areas — create missing FormRequests, fix validation gaps |
| 5 | **Infrastructure (P1/P2)** | Migrations — add missing columns, indexes, FKs; Performance — fix N+1 queries |
| 6 | **Feature Completion (P2)** | Email — auth context in queue job; Audit — casts; DDL alignment |
| 7 | **Gateway Integration** | Razorpay webhook, payment initiation, signature verification |
