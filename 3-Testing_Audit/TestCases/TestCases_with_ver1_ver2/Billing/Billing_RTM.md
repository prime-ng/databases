# Billing (BIL) — Requirements Traceability Matrix (RTM)

**Generated:** 2026-Jul-09 (report mode) · **Module folder:** `TestCases/Billing/`
**Chain:** FRD REQ / Screen §(Source) → BC-xx → TC-P/N/D/SM/S → `test_*()` method → (defect DEV-###).
Sources: `BIL_FRD_Complete_2026-06-29.md` (17 REQ · 43 BR · 7 RPT), the 9 `Billing_v1/*.md` screen files, `Billing_DDL_v1.sql`, `Billing_Complete_Audit_2026-06-29.md`.

## REQ → Feature → Coverage

| REQ (FRD) | Requirement | Feature (artifact folder) | Screen file | Primary BC groups | Representative TC | Automated in | Status |
|-----------|-------------|---------------------------|-------------|-------------------|-------------------|--------------|--------|
| REQ-BIL-001 | Billing Cycle Mgmt (CRUD) | BillingCycle | `billing-cycles.md` | BC-DB, BC-VAL, BC-AUTH, BC-BIZ, BC-SM(is_active), BC-REF(4× RESTRICT) | TC-P (create/edit/toggle/soft-delete/restore/force), TC-N (dup short_name, months range), TC-D (RESTRICT while referenced) | `prm_BillingCycleV1/V2_TestCas.php` (13/36) | ✅ Automated · MIG-BIL-001 guarded |
| REQ-BIL-002 | Subscription view/PDF (read-only) | Subscription | `subscription.md` | BC-AUTH, BC-UIX render, BC-INT (Prime models) | TC-P (tab render, filters, AJAX panels, PDF/ZIP), TC-N (403 scoped, malformed date_range) | `prm_SubscriptionV1/V2_TestCas.php` (16/43) | ✅ Automated (read-focused) |
| REQ-BIL-003 | Invoice Generation (atomic) | Invoicing | `invoicing.md` | BC-BIZ (invoice#, qty, tax, net formulas), BC-SM (status lifecycle), BC-INT (tenant student count), BC-REF | TC-P (formulas, INV-YYYYMMDD-NNN, bill-once), TC-N (illegal status transition), TC-D (FK CASCADE/RESTRICT) | `bil_InvoicingV1/V2_TestCas.php` (14/37) | ✅ Automated · generation path skip-guarded |
| REQ-BIL-004 | Invoice Listing & Detail | Invoicing | `invoicing.md` | BC-AUTH, BC-UIX (6 query builders, filters, paginate 10) | TC-P (tab/filter/pagination/detail AJAX/empty state) | `bil_InvoicingV2_TestCas.php` | ✅ Automated |
| REQ-BIL-005 | Invoice Remarks | Invoicing | `invoicing.md` | BC-AUTH (`.remark`), BC-BIZ | TC-P (remark update), TC-N (permission) | `bil_InvoicingV2_TestCas.php` | ✅ Automated |
| REQ-BIL-006 | Individual Payment | InvoicingPayment | `invoice-payments.md` | BC-DB, BC-VAL, BC-BIZ (cumulative paid), BC-SM (status derive), BC-REF | TC-P (record payment, cumulative), TC-N (missing/format), TC-D (FK CASCADE) | `bil_InvoicingPaymentV1/V2_TestCas.php` (17/43) | ✅ Automated · BUG-BIL-010, VAL-BIL-001 |
| REQ-BIL-007 | Consolidated Payment | ConsolidatedPayment | `consolidated-payments.md` | BC-BIZ (zero-alloc skip, consolidated_amount), BC-VAL (missing array rules), BC-INT (per-invoice audit) | TC-P (multi-invoice atomic), TC-N (unvalidated arrays), TC-D (rollback) | `bil_ConsolidatedPaymentV1/V2_TestCas.php` (16/60) | ✅ Automated · SEC-BIL-002 fix verified |
| REQ-BIL-008 | Payment Reconciliation | PaymentReconciliation | `payment-reconciliation.md` | BC-BIZ (manual toggle), BC-SM (reconciled↔unreconciled), BC-AUTH (`.status`), activity-log `ToggleStatus`→`sys_activity_logs.user_id` | TC-P (toggle both directions + log), TC-N (permission), report filters | `bil_PaymentReconciliationV1/V2_TestCas.php` (14/41) | ✅ Automated |
| REQ-BIL-009 | Invoice Email (immediate + scheduled) | EmailSchedule | `email-schedule.md` | BC-SM (pending→sent/failed/cancelled), BC-BIZ (job dispatch/delay, audit `Email Scheduled`/`Notice Sent`), BC-AUTH | TC-P (send/schedule/cancel), TC-N (no validation), TC-SM (status) | `bil_EmailScheduleV1/V2_TestCas.php` (16/50) `Bus::fake()` | ✅ Automated · JOB-BIL-001 fix verified |
| REQ-BIL-010 | PDF/ZIP/Print | Subscription + Invoicing + ConsolidatedPayment + PaymentReconciliation | multiple | BC-AUTH (`.pdf`/`.print`), BC-UIX | TC-P (PDF/ZIP/print per type), BUG-BIL-005 defensive | across feature V2 suites | ✅ Automated (defensive) · sync-ZIP still open |
| REQ-BIL-011 | Audit Trail & Notes (append-only) | InvoicingAuditLog | `audit-log.md` | BC-BIZ (append-only + notes-only mutable), BC-AUTH, BC-VAL (notes), BC-DB (FK col) | TC-P (view/add-note/event-info/PDF), TC-N (append-only invariant, notes max), DATA-BIL-001 proof | `bil_InvoicingAuditLogV1/V2_TestCas.php` (16/61) | ✅ Automated · DATA-BIL-001, AUTH-BIL-002, VAL-BIL-002 |
| REQ-BIL-012..013 | Scheduler / Overdue detection | — | (in `invoicing.md` notes) | BC-SM (PENDING→OVERDUE) | documented as gap (no automated detection in source) | Invoicing V2 (documented gap) | ⚠️ Not built (future) |
| REQ-BIL-014 | Payment Gateway (Razorpay) | GatewayIntegration | `gateway-integration.md` | BC-DB (`gateway_response`), BC-S (planned HMAC/no-auth webhook) | TC current-reality (col exists, routes absent, SDK), planned = skipped stubs | `bil_GatewayIntegrationV1/V2_TestCas.php` (14/42) | ⚠️ Not implemented — planning-stage set |
| REQ-BIL-015..017 | Metering / Portal / GST | — | — | — | not started (future) | — | ⚠️ Not built (future) |

## Reports (RPT-BIL) traceability
| RPT | Report | Feature suite covering it | Status |
|-----|--------|---------------------------|--------|
| RPT-BIL-001 | Invoice PDF/ZIP | Invoicing | ✅ (temp-leak fixed; sync ZIP open) |
| RPT-BIL-002 | Subscription PDF/ZIP | Subscription | ✅ |
| RPT-BIL-003 | Consolidated print | ConsolidatedPayment | ⚠️ BUG-BIL-005 (defensive skip) |
| RPT-BIL-004 | Reconciliation report | PaymentReconciliation | ✅ |
| RPT-BIL-005 | Audit PDF | InvoicingAuditLog | ✅ (depends on DATA-BIL-001 DDL fix) |
| RPT-BIL-006/007 | (future) | — | Not started |

## Business-Rule coverage (BR-BIL) — quick map to proving suites
- BR-BIL-001 (unique cycle code) → BillingCycle V2 (duplicate short_name) ✅
- BR-BIL-002 (months 1–255) → BillingCycle V2 (range) ✅
- BR-BIL-006 (invoice# unique/format) → Invoicing V2 (INV-YYYYMMDD-NNN + retry) ✅ / BUG-BIL-015 mitigated
- BR-BIL-007..012 (qty/sub_total/tax/net/due) → Invoicing V2 (formula tests) ✅
- BR-BIL-013 (bill once) → Invoicing V2 (`bill_generated`) ✅
- BR-BIL-014/021/026 (atomic gen/payment) → Invoicing + Payment + Consolidated V2 (tx + rollback verified) ✅
- BR-BIL-020/023 (cumulative paid / status) → InvoicingPayment V2 ✅ (BR-BIL-023 caveat: BUG-BIL-010)
- BR-BIL-022 (no raw data in audit) → InvoicingPayment/AuditLog V2 (whitelist verified — SEC-BIL-011 remediated) ✅
- BR-BIL-024/025 (zero-alloc skip / totals) → ConsolidatedPayment V2 ✅
- BR-BIL-027/028 (toggle+log / reconcile filter) → PaymentReconciliation V2 ✅
- BR-BIL-029..036 (email/PDF/audit) → EmailSchedule + AuditLog V2 ✅ (BR-BIL-034 append-only, BR-BIL-030 sent/failed transitions)

## Traceability integrity
- **9/9 features:** every `Source`-tagged BC and requirement item maps to ≥1 TC; every TC maps to ≥1 V2 method; every V2 method maps back to a TC/BC (per-feature Gap Analysis + V2 Method Index).
- **136 V1 + 413 V2 methods** total; V2/V1 = 3.04× (gate ≥2× met on every feature).
- **Not-built REQs** (012/013/015/016/017) are recorded as explicit coverage gaps, not silent omissions; GatewayIntegration (014) ships a planning-stage set (current-reality assertions + skipped planned-contract stubs).
