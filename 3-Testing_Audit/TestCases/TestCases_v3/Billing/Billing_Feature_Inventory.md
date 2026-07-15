# Billing (BIL) — Feature Inventory

**Module:** Billing · **Code:** BIL · **App folder:** `Modules/Billing` · **DDL:** `Billing_DDL_v1.sql`
**DB scope:** **prime_db / central (Prime-layer — NOT tenant)** — every feature is tested on the central host `http://127.0.0.1:8000` and extends `BillingDuskTestCase` (`authenticateCentral` / `visitAuthenticated` / `centralUrl`), per constraint 05_ E21/E22. No tenant `initializeTenantContext` scaffolding is used anywhere in this module.
**Run resolved:** `TestCases/Billing/` (clean canonical folder) · **Generated:** 2026-Jul-10 · **Mode:** module → 9 features → report roll-up.

> **Prefix rule (verified per primary table against the DDL `CREATE TABLE`, not the registry hint):** `prm_billing_cycles` and the `prm_plans` / `prm_tenant_plan_*` family are central Prime tables → **`prm_`**; the `bil_tenant_*` family (invoices, payments, audit logs, email schedules) → **`bil_`**. Both prefixes coexist in this one central module.

## Canonical feature list (9 screens — `Billing_v1/*.md`)

| # | Screen file (`Billing_v1/`) | Feature (PascalCase) | Primary DDL table | Verified prefix | Controller | Type | Output folder |
|---|------------------------------|----------------------|-------------------|:---:|------------|------|---------------|
| 1 | `billing-cycles.md` | **BillingCycle** | `prm_billing_cycles` (DDL:105) | `prm_` | `BillingCycleController` | CRUD + soft-delete/trash | `BillingCycle/` |
| 2 | `subscription.md` | **Subscription** | `prm_tenant_plan_rates` (+ `prm_plans`, `prm_tenant_plan_jnt`/`_module_jnt`/`_billing_schedule`) | `prm_` | `SubscriptionController` | Read/view + toggles + export | `Subscription/` |
| 3 | `invoicing.md` | **Invoicing** | `bil_tenant_invoices` (DDL:4) | `bil_` | `BillingManagementController` (invoicing tab) | Auto-generate + read | `Invoicing/` |
| 4 | `invoice-payments.md` | **InvoicingPayment** | `bil_tenant_invoicing_payments` (DDL:62) | `bil_` | `InvoicingPaymentController` | Payment posting (write) | `InvoicingPayment/` |
| 5 | `consolidated-payments.md` | **ConsolidatedPayment** | `bil_tenant_invoicing_payments` (multi-invoice) | `bil_` | `InvoicingPaymentController::consolidatedStore` | Payment allocation (write) | `ConsolidatedPayment/` |
| 6 | `payment-reconciliation.md` | **PaymentReconciliation** | `bil_tenant_invoicing_payments` ⋈ `bil_tenant_invoices` | `bil_` | `BillingManagementController` (reconcile tab) | Report + manual reconcile toggle | `PaymentReconciliation/` |
| 7 | `audit-log.md` | **InvoicingAuditLog** | `bil_tenant_invoicing_audit_logs` (DDL:82) | `bil_` | `InvoicingAuditLogController` | Audit read + note add/edit | `InvoicingAuditLog/` |
| 8 | `email-schedule.md` | **EmailSchedule** | `bil_tenant_email_schedules` (model; **absent from DDL v1**) | `bil_` | `EmailScheduleController` | Schedule list/show/cancel + job | `EmailSchedule/` |
| 9 | `gateway-integration.md` | **GatewayIntegration** | *(none — not implemented)* | `bil_` | *(no controller)* | **Planning-stage** | `GatewayIntegration/` |

**Skipped non-screen doc:** `implementation-plan.md` (not a screen — excluded per conventions §2.0).

## Notes per feature
- **BillingCycle** — richest CRUD; committed reference sibling `prm_BillingCycle_TestCas.php` expanded to full matrix (53 methods).
- **Subscription** — central plan/subscription **viewing** layer; 4 AJAX detail panels, 5 flag toggles (`automatic_billing/auto_renew/is_trial/is_subscribed/is_active`), PDF/ZIP export. No dedicated Subscription model — reads the `prm_tenant_plan_*` family directly.
- **Invoicing** — auto-generation (`InvoiceGeneratorService`, `GenerateInvoicesCommand`); `invoice_no` auto, `invoice_date` = day after `billing_end_date`. `InvoicingController` is a dead unrouted stub; the live screen is `BillingManagementController`.
- **InvoicingPayment / ConsolidatedPayment** — the two payment-write paths (`store` / `consolidatedStore`) the audit flagged for transaction-integrity; current source is **remediated** (rollback + guards present).
- **PaymentReconciliation** — read/report screen + one manual reconcile toggle (event `ToggleStatus`); misspelled selectors `#payment-reconcilation-*` are real and asserted verbatim.
- **InvoicingAuditLog** — schema is P0-broken (FK column-name mismatch), so the suite is DDL/model/source-truth + render/permission driven (audit rows can't be seeded on a schema-correct DB).
- **EmailSchedule** — index/show/destroy(cancel) only; `SendInvoiceEmailJob` + `InvoiceMail`; model has **no SoftDeletes**. Table absent from `Billing_DDL_v1.sql` (authority = master `prime_db_v4.sql`).
- **GatewayIntegration** — **not built** (no table, no controller, no routes; Razorpay SDK + `config/services.php` stub present but unwired). Planning-stage suite: 1 assertive gap-proof + 38 `markTestSkipped` stubs.
