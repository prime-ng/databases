# Billing (BIL) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-10 · **Chain:** Requirement/FRD/Screen §(Source) → BC → TC → `test_method()` → (optional) DEV/audit defect.
**Baseline:** `BIL_FRD_Complete_2026-06-29` (17 REQ · 43 BR · 7 RPT) + `Billing_v1/*.md` screens + `Billing_Complete_Audit_2026-06-29.md`.
Full BC↔TC↔method mapping lives in each feature's `*TcList_Require.md` and `*GAPANALYSIS_Require.md`; this is the module roll-up.

## A. Requirement-area → feature → status

| Req area (Source) | Feature | Primary BC | Representative TC | Proving method(s) | Status |
|-------------------|---------|-----------|-------------------|-------------------|--------|
| REQ-BIL-001 Billing cycles CRUD | BillingCycle | BC-DB/VAL/BIZ | TC-P/N/D full matrix | `prm_BillingCycle` `test_01`..`_53` | Covered |
| REQ-BIL Subscription viewing + toggles | Subscription | BC-AUTH/BIZ/SM/INT | render, panels, flag toggles, export | `prm_Subscription` `test_01`..`_92` | Covered (read-focused) |
| REQ-BIL Invoice generation (auto no./date) | Invoicing | BC-BIZ/BC-AUTO | invoice_no auto, invoice_date rule | `bil_Invoicing` `test_10`..`_19` | Covered |
| REQ-BIL Invoice payment posting | InvoicingPayment | BC-BIZ/VAL/SM | post payment, balance, status derive | `bil_InvoicingPayment` `test_13/14/15/92` | Covered |
| REQ-BIL Consolidated payment allocation | ConsolidatedPayment | BC-BIZ/VAL/INT | multi-invoice allocation, amount total | `bil_ConsolidatedPayment` matrix | Covered |
| REQ-BIL Payment reconciliation report | PaymentReconciliation | BC-BIZ/AUTH | buckets, filter, toggle, export | `bil_PaymentReconciliation` `test_13`..`_17` | Covered (report) |
| REQ-BIL Invoicing audit trail | InvoicingAuditLog | BC-DB/BIZ/AUTH | audit read, note add/edit, event_info | `bil_InvoicingAuditLog` `test_01`..`_91` | Covered (source-truth) |
| REQ-BIL Invoice email schedule | EmailSchedule | BC-CFG/BIZ/SM | list/show/cancel, job dispatch | `bil_EmailSchedule` `test_20`..`_23` | Covered |
| **REQ-BIL-014 Payment gateway integration** | GatewayIntegration | BC (planned) | connect/webhook/capture (planned) | `bil_GatewayIntegration` `test_01` (gap proof) + 38 skipped | **NOT IMPLEMENTED — deferred** |

## B. Business-rule / defect traceability (audit BR + DEV → proving test → status)

| Defect / BR (Source) | Sev | Feature | Proving method | Live vs Remediated |
|----------------------|:---:|---------|----------------|--------------------|
| MIG-BIL-001 SoftDeletes/timestamps vs DDL (no `deleted_at`) | P0 | BillingCycle / Invoicing / InvoicingPayment / AuditLog / Reconciliation | `test_02`/`_02`/`_02`/`_04`/`_01` | **LIVE** (schema) |
| DATA-BIL-001 audit-log FK `tenant_invoice_id` vs DDL `tenant_invoicing_id` | P0 | InvoicingAuditLog (+ Invoicing `_07`) | `bil_InvoicingAuditLog test_03` | **LIVE** (schema) |
| DATA-BIL-002 phantom `invoice_amount` in `$fillable` | P0 | Invoicing | `bil_Invoicing test_03` (regression guard) | **Remediated** (not reproduced) |
| SEC-BIL-001 payment `store()` no rollback | P0 | InvoicingPayment | `bil_InvoicingPayment test_41` | **Remediated** |
| SEC-BIL-002 `consolidatedStore()` no rollback + early return | P0 | InvoicingPayment / ConsolidatedPayment | `test_42` | **Remediated** |
| BUG-BIL-010 invoice status from request not cumulative paid (BR-BIL-023) | P1 | InvoicingPayment | `test_43/13/14/92` | **Remediated** |
| SEC-BIL-011 raw `$request->all()` into audit `event_info` (BR-BIL-022) | P1 | InvoicingPayment / AuditLog | `test_44` / `test_91` | Remediated (residual over-capture in AuditLog) |
| SEC-BIL-010 nine routed methods without gate | P1 | Subscription / AuditLog | `test_53` / `test_51` | **Remediated** (gates now present) |
| DEV-BIL-020 `forceDelete()` authorizes `.delete` not `.forceDelete` | P2 | BillingCycle | `test_53` | LIVE |
| DEV-BIL-SUB-001 `TenantPlanBillingSchedule` table plural vs DDL singular | High | Subscription | `test_03/_40/_42` | LIVE |
| DEV-BIL-SUB-002 blade `status==1` vs VARCHAR status | Med | Subscription | `test_23` | LIVE |
| DEV-BIL-R02/R03 reconcile PDF/print button-gate ≠ endpoint-gate | P2 | PaymentReconciliation | `test_52/_53` | LIVE |
| DEV-BIL-R06 payments FK targets non-existent `bil_tenant_invoicing` | P1 | PaymentReconciliation / Invoicing (`_41`) | `test_41` | LIVE (DDL) |
| DEV-BIL-ES-001 `SendInvoiceEmailJob` never persists sent/failed (BR-BIL-030) | — | EmailSchedule | `test_23` | LIVE |
| DEV-BIL-ES-002 `bil_tenant_email_schedules` absent from module DDL / no FK | — | EmailSchedule | `test_01/_42` | LIVE (DDL gap) |
| BUG-BIL-013/014 broken `@view` route / route block registered 3× | P2 | Invoicing / Reconciliation | documented (context) | LIVE |
| REQ-BIL-014 payment gateway unbuilt | Gap | GatewayIntegration | `test_01` | **NOT BUILT** |

## C. Coverage-score gaps (requirement items with 0 automated coverage)
- **Payment state-machine** transitions PARTIALLY_PAID → PAID → OVERDUE → CANCELLED: product-incomplete; enumerated as BC-SM but not fully exercisable (Invoicing SM 40%). Owner: payments implementation.
- **GatewayIntegration** entire behavioural surface: deferred (planning-stage stubs). Owner: unbuilt REQ-BIL-014.

**Legend:** *Covered* = ≥1 automated method per BC/TC in that area meeting the category gate. *LIVE* = defect reproducible against schema-correct current source. *Remediated* = audit-reported defect not reproducible in current source; a regression-guard test locks the fix.
