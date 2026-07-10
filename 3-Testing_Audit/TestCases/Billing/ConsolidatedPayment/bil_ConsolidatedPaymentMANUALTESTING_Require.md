# Consolidated Payment — Manual Testing Specification (`bil_`)

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (BIL) — **Prime / Central** (`prime_db`) |
| Feature / Screen | Consolidated Payment (Billing Management → Consolidated Payment tab) |
| Page URL | `GET /billing/billing-management` (tab `#consolidated-payment-tab`, filter `?type=consolidated-payment`) |
| Store endpoint | `POST` route `billing.consolidated.store` → actual path `/billing/billing/consolidated-store` (DEV-BIL-003) |
| PDF endpoint | `GET` route `billing.download.consolidated.pdf` |
| Controller | `Modules\Billing\Http\Controllers\InvoicingPaymentController::consolidatedStore()` |
| Models | `InvoicingPayment` (`bil_tenant_invoicing_payments`), `BilTenantInvoice` (`bil_tenant_invoices`), `InvoicingAuditLog` (`bil_tenant_invoicing_audit_logs`) |
| Validation | `ConsolidatedPaymentRequest` (thin — array inputs unvalidated, DEV-BIL-002) |
| Migrations | None (schema from `prime_db_v4.sql` / `Billing_DDL_v1.sql`) |
| CRUD type | Create-only (multi-invoice payment posting); no edit/delete UI on this tab |
| Soft delete | Model declares `SoftDeletes` but DDL omits `deleted_at`/`updated_at` (DEV-BIL-004) |
| Pagination | 10/page on the outstanding-invoice list (`$recordPayment->links()`) |
| Activity log | Central `Modules\Prime\Models\ActivityLog`, event literal **`Store`**; plus `bil_tenant_invoicing_audit_logs` row `action_type='PAYMENT_UPDATED'` |
| Auth | Route middleware `auth,verified`; store gate `prime.invoicing-payment.create`; super-admin `Gate::before` bypass |

**Environment prerequisites:** (1) Billing module ENABLED in `prime_testing/modules_statuses.json` (else 404 — E19). (2) Central host `127.0.0.1:8000` (E21). (3) `APP_ENV=testing` (CSRF bypass, E20). (4) A super-admin user resolvable by `BillingDuskTestCase::resolveAdminUser()`. (5) DB writes to payments require `updated_at` to exist (DEV-BIL-004) — otherwise write-path tests self-skip.

---

## 2. Business Conditions (detailed)

### Consolidated payment flow (`consolidatedStore`)

```
POST billing.consolidated.store
  │
  ├─ Gate::authorize('prime.invoicing-payment.create')
  ├─ ConsolidatedPaymentRequest validates: payment_dates, payment_mode, amount_paid, payment_consolidated_status
  │      (invoice_ids / new_payment / payment_status are NOT validated — DEV-BIL-002)
  │
  ├─ SAFETY GUARD (before tx): if empty invoice_ids → return {status:false,'No invoices selected.'} (HTTP 200)   ← DEV-BIL-001 remediation
  │
  └─ DB::beginTransaction()
        try:
          foreach invoice_ids as invoiceId:
             receiving = (float) new_payment[invoiceId]
             if receiving <= 0: continue                                   ← BR-BIL-024 zero-alloc skip
             payment = InvoicingPayment::create({ amount_paid=receiving, consolidated_amount=amount_paid(total), ... })   ← BR-BIL-025
             invoice = BilTenantInvoice::find(invoiceId)
             if !invoice: continue                                         ← DEV-BIL-006 orphan payment already created
             invoice.paid_amount = previousPaid + receiving               ← BR-BIL-020 add-only (overpayment uncapped, DEV-BIL-007b)
             status = derive(paid_amount vs net_payable_amount)           ← BR-BIL-023 server-side (BUG-BIL-010 fixed)
             invoice.save()
             InvoicingAuditLog::create({ action_type='PAYMENT_UPDATED', performed_by=auth()->id(), event_info=json })
             activityLog(invoice, 'Store', {...})
          DB::commit(); return {status:true,'Consolidated payment saved successfully!'}
        catch: DB::rollBack(); return {status:false, 500}                  ← DEV-BIL-001 remediation
```

### Error messages (verbatim from `ConsolidatedPaymentRequest::messages()`)

| Field | Trigger | Message |
|-------|---------|---------|
| `payment_dates` | missing | Please enter the payment date. |
| `payment_dates` | invalid | Please enter a valid payment date. |
| `payment_mode` | missing | Please select a payment mode. |
| `amount_paid` | missing | Please enter the amount paid. |
| `amount_paid` | non-numeric | The amount must be a valid number. |
| `amount_paid` | negative | The amount cannot be less than zero. |
| `payment_consolidated_status` | missing | Please select the payment status. |

---

## 3. Test Cases (Step / Action / Expected)

### TC-P04 — Consolidated Payment tab loads
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin, visit `/billing/billing-management` | Page 200, no login/403 banner |
| 2 | Click `#consolidated-payment-tab` | `#consolidated-payment-pane` visible |
| 3 | Inspect | Header form `#consolidatedPaymentForm` + outstanding table present |

### TC-P05 — Header form fields present
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open tab | `payment_dates`, `payment_mode`, `pay_mode_other`, `transaction_id`, `amount_paid`, `payment_consolidated_status`, `#payment_reconciled`, `gateway_resp` all present |

### TC-P10 — Record a consolidated payment (positive)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Ensure an outstanding invoice (`paid_amount < net_payable_amount`) exists | Row shown with a positive Balance |
| 2 | POST valid header + `invoice_ids=[id]`, `new_payment[id]=alloc(>0)`, `payment_status[id]` | HTTP 200 `{status:true}` |
| 3 | DB check: `SELECT * FROM bil_tenant_invoicing_payments WHERE tenant_invoice_id=id ORDER BY id DESC LIMIT 1` | New row: `amount_paid=alloc`, `consolidated_amount=total` |
| 4 | DB check: `SELECT paid_amount FROM bil_tenant_invoices WHERE id=id` | `= previousPaid + alloc` |
| 5 | DB check: `SELECT action_type FROM bil_tenant_invoicing_audit_logs WHERE tenant_invoice_id=id ORDER BY id DESC LIMIT 1` | `PAYMENT_UPDATED`, `performed_by = admin id` |
| 6 | Activity-log check | Central `ActivityLog` event = `Store`, subject_type = `Modules\Billing\Models\BilTenantInvoice` |

### TC-N01 — Empty selection soft failure (DEV-BIL-001)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST valid header fields, omit `invoice_ids` | HTTP 200, JSON `{status:false,'No invoices selected.'}` — **no transaction opened** |
| 2 | DB check payments count | Unchanged |

### TC-N02..N08 — Validation matrix
| TC | Payload change | Expected |
|----|----------------|----------|
| TC-N02 | `payment_dates=null` | 422, "Please enter the payment date." |
| TC-N03 | `payment_dates='not-a-date'` | 422, "Please enter a valid payment date." |
| TC-N04 | `payment_mode=null` | 422, "Please select a payment mode." |
| TC-N05 | `amount_paid=null` | 422, "Please enter the amount paid." |
| TC-N06 | `amount_paid='abc'` | 422, "The amount must be a valid number." |
| TC-N07 | `amount_paid=-5` | 422, "The amount cannot be less than zero." |
| TC-N08 | `payment_consolidated_status=null` | 422, "Please select the payment status." |

### TC-N09 — Array inputs unvalidated (DEV-BIL-002)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST valid header + `invoice_ids=['not-an-id']`, `new_payment=['not-an-id'=>'garbage']` | Response is NOT 422 for those keys (request ignores them) |
| 2 | Interpretation | Documents the validation gap — allocation/status arrays are trusted raw |

### TC-N10/N11 — Guest access
| Step | Action | Expected |
|------|--------|----------|
| 1 | Logged out, visit `/billing/billing-management` | Redirect to `/login` |
| 2 | Logged out, POST consolidated-store | 401/403/302/419 (rejected), no payment created |

### TC-SM (status derivation)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Allocate less than balance | Invoice status derived `PARTIAL` |
| 2 | Allocate up to balance | Invoice status derived `PAID` |
| 3 | Allocate 0 | Invoice skipped, no payment row, no status change |

### TC-D01 — Orphan payment (DEV-BIL-006)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST with `invoice_ids=[bogus]`, `new_payment[bogus]>0` | Payment row created BEFORE invoice lookup; `find()` null → `continue` |
| 2 | DB check | An `InvoicingPayment` row references a non-existent invoice (integrity leak) |

### TC-D02 — Soft-delete guard (DEV-BIL-004)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Check `deleted_at` on `bil_tenant_invoicing_payments` / `_audit_logs` | If absent, `withTrashed()`/`forceDelete()` would throw 42S22 — document, do not add trait |

### TC-D03/D04 — Over-allocation (DEV-BIL-007)
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `amount_paid=1000` but `new_payment` allocations sum to `50` | Accepted — no reconciliation |
| 2 | Allocate more than the balance | `paid_amount` exceeds `net_payable_amount` — not blocked |

### TC-T01 / TC-S01 / TC-S02
| TC | Action | Expected |
|----|--------|----------|
| TC-T01 | Run in central context | `tenancy()->initialized === false`; base URL on `127.0.0.1` |
| TC-S01 | POST `transaction_id='<script>alert(1)</script>'` | Stored raw at rest (Blade escapes on output) |
| TC-S02 | POST non-existent invoice id with zero allocation | No orphan payment row; no fatal |
