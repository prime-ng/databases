# Consolidated Payment — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (Prime / central Super-Admin) |
| Feature | Consolidated Payment tab |
| DB scope | `prime_db` central — **NO tenant init** (prime-side) |
| List URL | `GET /billing/billing-management?type=consolidated-payment` |
| Store URL | `POST /billing/billing/consolidated-store` |
| PDF URL | `GET /billing/billing/download-consolidated-pdf` (consolidated); `POST /billing/payment-reconciliation/download-pdf` (selected) |
| Print URL | `GET /billing/billing-management/print/data?type=consolidated-payment` |
| Controllers | `BillingManagementController@index/printData/buildConsolidatedPaymentQuery`, `InvoicingPaymentController@consolidatedStore/downloadConsolidatedPdf/downloadSelectedPdf` |
| FormRequest | `ConsolidatedPaymentRequest` (`authorize()` = `Gate::allows('prime.invoicing-payment.create')`) |
| Models | `InvoicingPayment` (`bil_tenant_invoicing_payments`), `BilTenantInvoice`, `InvoicingAuditLog` |
| Primary table / prefix | `bil_tenant_invoicing_payments` / `bil_` |
| Soft delete | Model declares `SoftDeletes` — **DDL table has no `deleted_at`** (MIG-BIL-001) |
| Pagination | List paginate(10), oldest `payment_due_date` first |
| Activity log | `activityLog($invoice, 'Store', ...)` + `InvoicingAuditLog` rows (`action_type='PAYMENT_UPDATED'`) |
| Permissions | list `prime.consolidated-payment.viewAny`; store `prime.invoicing-payment.create`; PDF `prime.invoicing-payment.view` |

### Environment prerequisites
1. **Billing module ENABLED** in `prime_testing/modules_statuses.json` (else all routes 404).
2. `APP_ENV=testing` (bypass CSRF/419).
3. Prime tests on `http://127.0.0.1:8000`; admin `DUSK_ADMIN_EMAIL` / `DUSK_ADMIN_PASSWORD`.
4. `MAIN_PROJECT_PATH` exported (source-truth assertions read the real controller/request/model).
5. At least one `bil_tenant_invoices` row with `paid_amount < net_payable_amount` for row-level flows.

---

## 2. Business Conditions (detailed)

### Consolidated posting flow (`consolidatedStore`)
```
authorize prime.invoicing-payment.create
if (!invoice_ids || count==0) -> JSON {status:false,'No invoices selected.'}   // BEFORE transaction (SEC-BIL-002 fix)
DB::beginTransaction()
  try:
    foreach invoice_ids as invoiceId:
      receivingAmount = (float) new_payment[invoiceId] ?? 0
      if receivingAmount <= 0: continue                              // zero-allocation skip
      InvoicingPayment::create({
         consolidated_amount = (float) amount_paid,                  // TOTAL on every row
         amount_paid         = receivingAmount,                      // per-invoice allocation
         currency = 'INR', payment_status = payment_consolidated_status,
         payment_reconciled = (int) payment_reconciled })
      invoice = BilTenantInvoice::find(invoiceId); if !invoice: continue
      invoice.paid_amount = previousPaid + receivingAmount           // cumulative
      derive status (PAID / PARTIAL / PENDING via GlobalMaster Dropdown); save
      InvoicingAuditLog::create({ action_type='PAYMENT_UPDATED', performed_by=auth()->id() })  // DATA-BIL-001 FK risk
      activityLog(invoice, 'Store', ...)
    DB::commit(); return JSON {status:true,'Consolidated payment saved successfully!'}
  catch: DB::rollBack(); return JSON {status:false,'Failed...'} , 500
```

### Error messages (verbatim)
- `payment_dates.required` → "Please enter the payment date."
- `payment_dates.date` → "Please enter a valid payment date."
- `payment_mode.required` → "Please select a payment mode."
- `amount_paid.required` → "Please enter the amount paid."
- `amount_paid.numeric` → "The amount must be a valid number."
- `amount_paid.min` → "The amount cannot be less than zero."
- `payment_consolidated_status.required` → "Please select the payment status."

---

## 3. Manual Test Cases

### TC-P11 — Consolidated Payment tab renders
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as Super Admin at `http://127.0.0.1:8000/login` | Dashboard |
| 2 | Visit `/billing/billing-management?type=consolidated-payment` | Billing Management page, path `/billing/billing-management` |
| 3 | Click `#consolidated-payment-tab`; wait `#consolidated-payment-pane` | Pane visible |
| 4 | Inspect form `#consolidatedPaymentForm` | `payment_dates`, `payment_mode` (select), `pay_mode_other`, `transaction_id`, `amount_paid`, `payment_consolidated_status` (select), `#payment_reconciled` (checkbox), `gateway_resp` all present |
| 5 | Inspect footer | `#total_balance_amount`, `#total_receiving_amount`, `#payment_error` present |

### TC-P13 — Filters
| Step | Action | Expected |
|------|--------|----------|
| 1 | On the tab, inspect filter row | hidden `type=consolidated-payment`, tenant select `name="tenat_id"`, `#date_range` |
| 2 | Select a tenant + date range; submit | List reloads showing only that tenant's outstanding invoices (`paid_amount < net_payable_amount`), oldest due first |
| DB | `SELECT COUNT(*) FROM bil_tenant_invoices WHERE tenant_id=? AND paid_amount < net_payable_amount` | matches rows shown |

### TC-N01 — Submit with no invoices selected
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `consolidated-store` with payment fields but no `invoice_ids[]` | JSON `{status:false, message:'No invoices selected.'}`, HTTP 200 |
| DB | `SELECT COUNT(*) FROM bil_tenant_invoicing_payments` before/after | unchanged (guard runs before transaction) |

### TC-N02..N08 — Validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST with `invoice_ids[]=1` but omit `payment_dates` | 422 + "Please enter the payment date." |
| 2 | Omit `payment_mode` | 422 + "Please select a payment mode." |
| 3 | Omit `amount_paid` | 422 + "Please enter the amount paid." |
| 4 | Omit `payment_consolidated_status` | 422 + "Please select the payment status." |
| 5 | `amount_paid=abc` | 422 + "The amount must be a valid number." |
| 6 | `amount_paid=-5` | 422 + "The amount cannot be less than zero." |
| 7 | `payment_dates=not-a-date` | 422 + "Please enter a valid payment date." |

### TC-P03..P08 — Successful consolidated posting (requires outstanding invoices)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Select 2 outstanding invoices; enter total `amount_paid` and per-row `new_payment[id]` | totals recompute in JS |
| 2 | Set one row allocation to `0` | that row skipped on submit |
| 3 | Submit | JSON `{status:true, message:'Consolidated payment saved successfully!'}` |
| DB-1 | `SELECT consolidated_amount, amount_paid FROM bil_tenant_invoicing_payments WHERE tenant_invoice_id IN (...) ORDER BY id DESC` | each new row: `consolidated_amount` = the total; `amount_paid` = that invoice's receiving amount; `currency='INR'` |
| DB-2 | `SELECT paid_amount, status FROM bil_tenant_invoices WHERE id=?` | `paid_amount` increased by receiving amount; status = PAID/PARTIAL/PENDING per balance |
| DB-3 | zero-allocation invoice row | no new payment row, paid_amount unchanged |
| Audit | `SELECT action_type FROM bil_tenant_invoicing_audit_logs WHERE tenant_invoice_id=? ORDER BY id DESC LIMIT 1` | `PAYMENT_UPDATED` (blocked if performed_by FK unsatisfied — DATA-BIL-001) |
| Activity | activity log has event `Store` for the invoice | present |

### TC-P14 / BUG-BIL-005 — PDF & print
| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `download-consolidated-pdf` (authenticated) | HTTP 200, `Content-Type: application/pdf`, `Content-Disposition: attachment; filename=consolidated_payment_*.pdf` |
| 2 | GET `print/data?type=consolidated-payment` | HTML print view (BUG-BIL-005: historically crashed — verify no 500) |

### TC-S / Security
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `consolidated-store` unauthenticated | not 200 (302 login / 401 / 419) |
| 2 | Submit `gateway_resp=<script>alert(1)</script>` | response does not reflect raw script; stored value escaped |
| 3 | Attempt `id`/`created_at` mass assignment | ignored (not in `$fillable`) |
| 4 | GET PDF endpoint without `prime.invoicing-payment.view` | 403 |

### TC-D — Dependency / integrity
| Step | Action | Expected |
|------|--------|----------|
| 1 | Delete a `bil_tenant_invoices` parent | payment rows CASCADE (per DDL intent; note broken FK column name) |
| 2 | Audit `performed_by` user removed | audit `performed_by` set NULL |
| 3 | Overpaid invoice (`paid_amount > net_payable`) | excluded from list (`<` filter) but included in PDF (`!=` filter) — INT-BIL-CP-01 |
