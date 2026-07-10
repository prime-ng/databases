# Billing (BIL) — Feature Inventory

**Generated:** 2026-Jul-09 15-49
**Module folder (resolved once):** `TestCases/Billing/`
**Registry row (Step 0 — `module_list.md`):** MODULE_NAME=`Billing` · CODE=`BIL` · PREFIX=`bil_` · FOLDER_NAME=`Billing` · DDL_FILE_NAME=`Billing_DDL_` (resolved file `Billing_DDL_v1.sql`)

## Layer / Scope (authoritative)
- **DB scope: `prime_db` (central / Prime-layer — NOT tenant-per-school).** Billing is the platform's SaaS-invoicing of school tenants. Core tables reference `prm_tenant`, `prm_tenant_plan_jnt`, `prm_billing_cycles`, `sys_modules`, `users`. Confirmed by the audit report (Layer row: prime_db, "central Super-Admin SaaS-invoicing module") and by the committed test chain living under `tests/Browser/Modules/Prime/Billing/`.
- **Tenancy scaffolding: NONE.** Tests use the central base chain `PrimeDuskTestCase → prm_BillingDuskTestCase_TestCas (a.k.a. BillingDuskTestCase)`, `authenticateCentral()` + `visitAuthenticated()` against `centralBaseUrl`. No `tenancy()->initialize()`. (Exception: `BillingManagementController::generateInvoiceForOrganization()` itself calls `Tenancy::initialize()` internally to count students — that is app behaviour under test, not test scaffolding.)
- **Test style: browser Dusk** (real Chrome), mirroring the committed same-module siblings — NOT HTTP feature tests. User model: `App\Models\User` (has `is_super_admin`, `emp_code`, `short_name`, `status`, `is_active`).
- **Permission convention (verbatim from source):** `prime.<entity>.<action>` (e.g. `prime.billing-cycle.viewAny`, `prime.invoicing-payment.create`, `prime.billing-management.status`). NOT `tenant.*`, NOT `hrs.*`.
- **Activity log:** two mechanisms — (a) `sys_activity_logs` via the shared `activityLog()` helper for BillingCycle + reconciliation toggle; (b) a **domain** audit trail in `bil_tenant_invoicing_audit_logs` (`action_type` values `GENERATED`, `Partially Paid`, `PAYMENT_UPDATED`, `Notice Sent`, `Not Billed`, `PENDING`) written by the controllers/job. Assert the literal `action_type` strings from source per feature.

## Prefix verification (against DDL `CREATE TABLE`)
| Feature | Primary table | DDL `CREATE TABLE` verified | File prefix |
|---|---|---|---|
| BillingCycle | `prm_billing_cycles` | ✅ line 105 | `prm_` |
| Subscription | `prm_tenant_plan_rates` (+ `prm_tenant_plan_jnt`) | ✅ line 197 / 178 | `prm_` |
| Invoicing | `bil_tenant_invoices` | ✅ line 4 | `bil_` |
| InvoicingPayment | `bil_tenant_invoicing_payments` | ✅ line 62 | `bil_` |
| ConsolidatedPayment | `bil_tenant_invoicing_payments` | ✅ line 62 | `bil_` |
| PaymentReconciliation | `bil_tenant_invoicing_payments` (`payment_reconciled`) | ✅ line 62/74 | `bil_` |
| InvoicingAuditLog | `bil_tenant_invoicing_audit_logs` | ✅ line 82 | `bil_` |
| EmailSchedule | `bil_tenant_email_schedules` (model table; NOTE: not present in `Billing_DDL_v1.sql` — see gap) | ⚠️ model-declared | `bil_` |
| GatewayIntegration | `bil_tenant_invoicing_payments` (`gateway_response`) | ✅ line 73 | `bil_` |

## Feature list (9 features — canonical from `Billing_v1/*.md`)

| # | Screen file | Feature (PascalCase) | Primary table | Controller | Model | Prefix | Type | Committed sibling to mirror | Output folder |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `billing-cycles.md` | **BillingCycle** | `prm_billing_cycles` | `BillingCycleController` | `BillingCycle` | `prm_` | Full CRUD + soft-delete + toggle | `Prime/Billing/BillingCycle/prm_BillingCycle_TestCas.php` | `Billing/BillingCycle/` |
| 2 | `subscription.md` | **Subscription** | `prm_tenant_plan_rates` | `SubscriptionController` (+ `BillingManagementController::buildSubscriptionQuery/subscriptionDetails/pricingDetails/billingDetails`) | Prime `TenantPlanRate`/`TenantPlan` (read) | `prm_` | Read-only / report + AJAX panels + PDF/ZIP | `Prime/Billing/Subscription/prm_SubscriptionTab_TestCas.php` | `Billing/Subscription/` |
| 3 | `invoicing.md` | **Invoicing** | `bil_tenant_invoices` | `BillingManagementController` (index/store/generateInvoiceForOrganization/invoiceDetails/invoiceRemarks/printData) | `BilTenantInvoice` | `bil_` | Composite: generate engine + list/filter + detail AJAX + remarks + PDF | `Prime/Billing/Invoicing/prm_InvoicingTab_TestCas.php` | `Billing/Invoicing/` |
| 4 | `invoice-payments.md` | **InvoicingPayment** | `bil_tenant_invoicing_payments` | `InvoicingPaymentController` (create/store/paymentDetails) | `InvoicingPayment` | `bil_` | Create + cumulative-paid + status calc + report | `Prime/Billing/InvoicingPayment/prm_InvoicingPaymentTab_TestCas.php` | `Billing/InvoicingPayment/` |
| 5 | `consolidated-payments.md` | **ConsolidatedPayment** | `bil_tenant_invoicing_payments` | `InvoicingPaymentController::consolidatedStore/downloadConsolidatedPdf/downloadSelectedPdf` (+ `BillingManagementController::buildConsolidatedPaymentQuery`) | `InvoicingPayment` | `bil_` | Multi-invoice atomic payment + report | `Prime/Billing/ConsolidatedPayment/prm_ConsolidatedPaymentTab_TestCas.php` | `Billing/ConsolidatedPayment/` |
| 6 | `payment-reconciliation.md` | **PaymentReconciliation** | `bil_tenant_invoicing_payments` (`payment_reconciled`) | `BillingManagementController::toggleStatus` (+ `buildPaymentReconciliationQuery`) | `InvoicingPayment` | `bil_` | Toggle + report/PDF | `Prime/Billing/PaymentReconciliation/prm_PaymentReconciliationTab_TestCas.php` | `Billing/PaymentReconciliation/` |
| 7 | `audit-log.md` | **InvoicingAuditLog** | `bil_tenant_invoicing_audit_logs` | `InvoicingAuditLogController` (+ `BillingManagementController::AuditLog`) | `InvoicingAuditLog` | `bil_` | Append-only + notes update + event-info + PDF | `Prime/Billing/InvoicingAudit/prm_InvoicingAuditTab_TestCas.php` | `Billing/InvoicingAuditLog/` |
| 8 | `email-schedule.md` | **EmailSchedule** | `bil_tenant_email_schedules` | `EmailScheduleController` (index/show/destroy) + `BillingManagementController::sendEmail/scheduleEmail` + `SendInvoiceEmailJob` | `BillTenantEmailSchedule` | `bil_` | List/show/cancel + queued-email job | (none — closest: EmailSchedule via BillingManagement tabs) | `Billing/EmailSchedule/` |
| 9 | `gateway-integration.md` | **GatewayIntegration** | `bil_tenant_invoicing_payments` (`gateway_response`) | (none routed — planned; Razorpay SDK only) | `InvoicingPayment` (`gateway_response`) | `bil_` | **Planned / not implemented** — lighter, gap-focused artifact set | (none) | `Billing/GatewayIntegration/` |

**Skipped (non-screen docs):** `implementation-plan.md` (planning doc, not a screen).

## Known source defects to carry into every feature's Gap Analysis / Validation Report
From `Billing_Complete_Audit_2026-06-29.md` (Health 37/100, Deploy NO-GO):
- **MIG-BIL-001 (P0)** — every model declares `SoftDeletes`+default timestamps but the DDL tables lack `deleted_at`/`updated_at` → CRUD throws `SQLSTATE 42S22` on a schema-correct prime_db. (The live dev DB appears hand-patched — the committed `prm_BillingCycle` test asserts `deleted_at` exists and fails fast if not.)
- **DATA-BIL-001 (P0)** — audit-log model/inserts use `tenant_invoicing_id`; DDL column is `tenant_invoice_id`. (InvoicingAuditLog + all 6 insert sites.)
- **DATA-BIL-002 (P0)** — `BilTenantInvoice::$fillable` has phantom `invoice_amount` + a duplicated 8-field block.
- **SEC-BIL-001/002 (P0)** — payment `store()`/`consolidatedStore()` open `DB::beginTransaction()` with no rollback; consolidated has an early `return` inside the open transaction.
- **BUG-BIL-010 (P1)** — invoice status taken from request input, not derived from cumulative paid (BR-BIL-023).
- **BUG-BIL-015 (P1)** — invoice-number generation is not concurrency-safe (count+1 race).
- **BUG-BIL-011 (P1)** — `generateInvoiceForOrganization()` returns bool `false` but `store()` reads it as an array.
- **SEC-BIL-010 (P1)** — 9 routed methods have no `Gate::authorize` (incl. `auditAddNoteUpdate` write).
- **SEC-BIL-011 (P1)** — raw `$request->all()` persisted into audit `event_info` (BR-BIL-022).
- **SEC-BIL-005 (P1)** — `Tenancy::initialize()/end()` without try/finally in invoice generation.
- **BUG-BIL-005 (P2)** — consolidated-payment print crashes (`getCollection()`/`isNotEmpty()` on non-Collection/float).
- **BUG-BIL-013 (P2)** — broken `billing-management.view` route → no `view()` method.
- **BUG-BIL-014 (P2)** — central billing route block registered 3×.
- **VAL-BIL-001 (P2)** — thin validation + `authorize()=true` on both payment FormRequests.
- **JOB-BIL-001 (P2)** — `SendInvoiceEmailJob` no `$tries/$backoff/$timeout/failed()`; `auth()->id()` null on worker.
- **DEAD-BIL-001 (P2)** — dead policies + last-wins duplicate `Gate::policy` registration; policies import non-existent `App\Models\ConsolidatedPayment`/`PaymentReconciliation`.
- **DEAD-BIL (P3)** — `InvoicingController` is an unrouted empty Gate-only stub (prefix `prime.invoicing.*` exists but never reachable).

## DDL gaps flagged (Billing_DDL_v1.sql defects to note, not invent around)
- Typos/mismatches in the DDL itself: `bil_tenant_invoicing_modules_jnt` UNIQUE + FK reference the non-existent `tenant_invoicing_id`/`bil_tenant_invoice`; `bil_tenant_invoicing_payments.payment_status` has malformed `NOT NULL VARCHAR(20)` ordering; `bil_tenant_invoicing_audit_logs.tenant_invoicing_id` vs the app/requirement `tenant_invoice_id`; `prm_plans` trailing comma after last constraint; `prm_tenant_plan_jnt.current_flag` GENERATED references old `org_id`; `prm_tenant_plan_rates` FK references old `organization_plan_id`.
- `bil_tenant_email_schedules` (the EmailSchedule model's table) is **not defined** in `Billing_DDL_v1.sql` (only referenced narratively). Feature 8 must Schema::hasTable-guard and document this as a DDL gap.
- Requirement-desired columns absent from DDL across tables: `is_active`, `created_by`, `deleted_at`, `updated_at` (audit) — these are the MIG-BIL-001 / DATA-BIL-003 class.
