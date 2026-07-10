# Payment Reconciliation — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (BIL) — prime_db **central** (Prime layer, no tenant init) |
| Feature / Screen | Payment Reconciliation (`Billing_v1/payment-reconciliation.md`) |
| URL | `GET /billing/billing-management?type=payment-reconcilation` (note source spelling `payment-reconcilation`, missing `i`) |
| Toggle endpoint | `POST /billing/billing-management/{session}/toggle-status` → `BillingManagementController@toggleStatus` |
| PDF endpoint | `POST /billing/payment-reconciliation/download-pdf` → `InvoicingPaymentController@downloadSelectedPdf` |
| Print endpoint | `GET /billing/billing-management/print/data?type=payment-reconcilation` |
| Controllers | `BillingManagementController` (`index`, `buildPaymentReconciliationQuery`, `toggleStatus`, `printData`), `InvoicingPaymentController` (`downloadSelectedPdf`) |
| Models | `Modules\Billing\Models\InvoicingPayment` (table `bil_tenant_invoicing_payments`), `BilTenantInvoice`, `Modules\GlobalMaster\Models\ActivityLog` (`sys_activity_logs`) |
| Validation | None on toggle (flips by current value); PDF requires non-empty `ids[]` (else 400) |
| Migrations | 0 executable migrations (DDL `Billing_DDL_v1.sql` / `prime_db_v4.sql` is schema authority) |
| CRUD type | Status toggle on existing payment + report (list / filter / PDF / print) |
| Soft delete | Model declares `SoftDeletes` but table has **no `deleted_at`** column (MIG-BIL-001) |
| Pagination | `paginate(10)` |
| Activity log | `activityLog($payment,'ToggleStatus', [...])` → `sys_activity_logs` (columns `subject_type/subject_id/user_id/event/properties`) |
| Permissions | View `prime.payment-reconciliation.viewAny` · Toggle `prime.billing-management.status` · PDF `prime.invoicing-payment.view` (UI guards `payment-reconciliation.pdf`) · Print `prime.billing-management.print` |

**Preconditions for manual runs**
1. Billing module **enabled** in `prime_testing/modules_statuses.json` (disabled module → 404 on all routes).
2. Run on central host `http://127.0.0.1:8000` (Prime tests must run on 127.0.0.1 per base class).
3. Logged in as a central super-admin (`Gate::before` resolves the dotted abilities).
4. At least one `bil_tenant_invoicing_payments` row exists (seed one against an existing `bil_tenant_invoices` row if empty).

---

## 2. Business Conditions (detailed)

### BC-BIZ-01/02/03 — Toggle behaviour + JSON + audit
- Toggle is **manual only** — no automated bank/gateway matching; flips `payment_reconciled` between 0 and 1 with **no** precondition check.
- Response JSON (verbatim):
  ```json
  {"success": true, "message": "Payment reconciliation updated successfully", "data": {"payment_reconciled": true}}
  ```
- Audit flow (every toggle):
  ```
  toggleStatus() → $payment->update(['payment_reconciled' => !current])
                 → activityLog($payment, 'ToggleStatus', {
                       message: 'Payment reconciliation status changed.',
                       previous_status: <old>, new_status: <new> })
                 → INSERT sys_activity_logs (subject_type=Modules\Billing\Models\InvoicingPayment,
                       subject_id=<id>, user_id=<auth id>, event='ToggleStatus', properties={...})
  ```

### BC-BIZ-04 / BC-EDG-02 — Three-way filter
```
payment_reconcilation_status = ''                              → all payments
payment_reconcilation_status = 'Reconciled Transactions Only'  → where payment_reconciled = 1
payment_reconcilation_status = 'Non-Reconciled Trans. Only'    → where payment_reconciled = 0
payment_reconcilation_status = <anything else>                 → falls through → all payments
date_range empty                                               → NO date filter (not today-scoped)
date_range = 'A - B'                                           → whereHas('invoice', invoice_date BETWEEN A..B)
```

### BC-VAL-03 — PDF selection guard
- Empty `ids[]` → HTTP 400 JSON `{"error": "No items selected"}`.
- Non-empty → HTTP 200, `Content-Type: application/pdf`, `Content-Disposition: attachment; filename=payment_reconciliation_<ts>.pdf`.

### Known-defect error/behaviour notes
- **MIG-BIL-001 (P0):** on a schema-correct prime_db the SoftDeletes global scope makes every payment query raise `SQLSTATE[42S22] Unknown column 'deleted_at'`. If the live DB was hand-patched with `deleted_at`, queries succeed (audit degrades to P1).
- **DEV-BIL-R01 (P2):** PDF endpoint gate (`prime.invoicing-payment.view`) ≠ UI button `@can` key (`prime.payment-reconciliation.pdf`).

---

## 3. Manual Test Cases (Step / Action / Expected)

### TC-P02 — Reconciliation tab loads with filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log in as central super-admin; visit `/billing/billing-management` | Billing Management page renders (no 403/login) |
| 2 | Click the Payment Reconciliation tab (`#payment-reconcilation-tab`) | Pane `#payment-reconcilation-pane` becomes active |
| 3 | Inspect the search bar | `input[name="date_range"]` and `select[name="payment_reconcilation_status"]` present |
| 4 | Inspect the pane | A `<table>` with reconciliation columns is present |

### TC-P05 / TC-P06 — Toggle reconcile 0→1 and 1→0
| Step | Action | Expected |
|------|--------|----------|
| 1 | Note a payment id `X` and its current `payment_reconciled` | e.g. 0 (unreconciled) |
| 2 | `POST /billing/billing-management/X/toggle-status` (empty body, CSRF/auth) | HTTP 200 JSON `{success:true, message:"Payment reconciliation updated successfully", data:{payment_reconciled:true}}` |
| 3 | DB check | `SELECT payment_reconciled FROM bil_tenant_invoicing_payments WHERE id=X` → expect `1` |
| 4 | Toggle again | `data.payment_reconciled=false`; DB value → `0` |

### TC-P09/P10/P11 — Toggle writes activity log
| Step | Action | Expected |
|------|--------|----------|
| 1 | Toggle payment `X` | HTTP 200 |
| 2 | Activity-log check | `SELECT event,user_id,properties FROM sys_activity_logs WHERE subject_type='Modules\\Billing\\Models\\InvoicingPayment' AND subject_id=X ORDER BY id DESC LIMIT 1` |
| 3 | Assert row | `event='ToggleStatus'`; `user_id`=your admin id; `properties.message='Payment reconciliation status changed.'`; `previous_status`/`new_status` present and consistent |

### TC-P18/P19 — Status filter
| Step | Action | Expected |
|------|--------|----------|
| 1 | Select "Reconciled Transactions Only", Search | Only rows with `payment_reconciled=1` listed; HTTP 200 |
| 2 | Select "Non-Reconciled Trans. Only", Search | Only `payment_reconciled=0` rows; HTTP 200 |
| 3 | Clear filter, Search | All payments listed |

### TC-P21 / TC-N03 — PDF export
| Step | Action | Expected |
|------|--------|----------|
| 1 | Select ≥1 payment checkbox; click Export → PDF (`#downloadPDFMultiBtnsReconcilation`) | File downloads; `Content-Type: application/pdf` |
| 2 | Click Export with no checkbox selected | HTTP 400 JSON `{"error":"No items selected"}` (JS toast) |

### TC-N01 — Toggle missing id
| Step | Action | Expected |
|------|--------|----------|
| 1 | `POST /billing/billing-management/2147483000/toggle-status` | HTTP 404 (findOrFail) |

### TC-N05/N06 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out; visit `/billing/billing-management?type=payment-reconcilation` | Redirected to `/login` |
| 2 | Log out; `POST .../{id}/toggle-status` | 302 redirect to login (not executed) |

### TC-D01 — SoftDeletes vs DDL (MIG-BIL-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | `SHOW COLUMNS FROM bil_tenant_invoicing_payments LIKE 'deleted_at'` | If empty → P0 confirmed (model SoftDeletes has no column); if present → dev DB patched (P1) |
| 2 | Record outcome | Documented in the run report (not a hard failure) |

### TC-P16 / DEV-BIL-R01 — PDF gate mismatch
| Step | Action | Expected |
|------|--------|----------|
| 1 | Grant a user only `prime.payment-reconciliation.pdf` (not `invoicing-payment.view`) | UI shows the PDF button |
| 2 | Trigger the export endpoint | Endpoint blocks (403) — proves the gate/UI mismatch |
