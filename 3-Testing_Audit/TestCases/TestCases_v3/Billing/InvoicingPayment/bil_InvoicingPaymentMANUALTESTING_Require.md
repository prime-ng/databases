# Invoicing Payment — Manual Testing Specification

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | Billing (`BIL`) |
| Feature / Screen | InvoicingPayment (`Billing_v1/invoice-payments.md`) |
| DB scope | **PRIME / CENTRAL** (`prime_db`) — runs on `http://127.0.0.1:8000` |
| Index URL | `/billing/billing-management` (Invoicing-Payment tab `#invoicing-payment-tab` / pane `#invoicing-payment-pane`) |
| Endpoints | `POST /billing/invoicing-payment` (store); `GET /billing/invoicing-payment/create?id=` (add-payment form JSON); `GET /billing/payment-details?id=` (payment list JSON); `POST /billing/consolidated-store`; `GET /billing/download-consolidated-pdf` |
| Controller | `InvoicingPaymentController` (index, create, store, paymentDetails, consolidatedStore, downloadConsolidatedPdf, downloadSelectedPdf) |
| FormRequest | `StoreInvoicePaymentRequest` |
| Models | `InvoicingPayment` (`bil_tenant_invoicing_payments`), `BilTenantInvoice` (`bil_tenant_invoices`), `InvoicingAuditLog` (`bil_tenant_invoicing_audit_logs`) |
| Validation | Server-side via `StoreInvoicePaymentRequest`; JSON 422 for AJAX |
| Migrations | None in module (`prime_db` built from DDL) → **MIG-BIL-001** SoftDeletes without `deleted_at` |
| CRUD type | Create-only (record payment); no edit/delete UI wired (`update()`/`destroy()` are empty stubs) |
| Soft delete | Declared on model, **not backed by column** (MIG-BIL-001) |
| Pagination | Server-side `->links()` on the payments listing |
| Activity log | `activityLog($invoice, 'Store', ['message' => 'Invoice Payment Data Updated .'])` |

**Prerequisites:** Billing module **enabled** in `prime_testing/modules_statuses.json`; `APP_ENV=testing`; at least one row each in `prm_tenant`, `prm_tenant_plan_jnt`, `prm_billing_cycles` to seed an invoice; a super-admin login (`root@tenant.com` / `password`).

---

## 2. Business Conditions (detailed)

### Payment posting flow (`store`)
1. `Gate::authorize('prime.invoicing-payment.create')`.
2. `DB::beginTransaction()`.
3. Create `InvoicingPayment` from request fields (`tenant_invoice_id`, `payment_date`←`date`, `transaction_id`, `mode`←`payment_mode`, `mode_other`←`pay_mode_other`, `consolidated_amount`←`amount_paid`, `amount_paid`, `currency`, `payment_status`←`invoice_payments`, `gateway_response`←`gateway_resp`, `payment_reconciled` YES→1, `remarks`).
4. `paid_amount = paid_amount + amount_paid`.
5. **Server-side status derivation** (BUG-BIL-010 fixed): paid ≥ net → PAID id; paid > 0 → PARTIAL id; else PENDING id (dropdown ids resolved from `bil_tenant_invoices.status`, fallback 498).
6. Insert `InvoicingAuditLog` with **whitelisted** `event_info` (payment_id, previous_paid, amount_added, new_paid_amount, payment_mode, payment_status, payment_date, transaction_id, remarks) — no `$request->all()` (SEC-BIL-011 fixed).
7. `activityLog(...)`.
8. `DB::commit()`; return `{status:true, message:'Payment saved successfully!'}`.
9. On exception: `DB::rollBack()`; return `{status:false, message:'Failed to save payment: …'}` HTTP 500 (SEC-BIL-001 fixed).

### Error messages (verbatim)
- `Invoice is required.`
- `Selected invoice does not exist.`
- `Payment amount must be greater than zero.`

### State machine (invoice payment status)
| From | Trigger | To |
|------|---------|----|
| PENDING | 0 < paid < net | PARTIAL |
| PARTIAL | paid ≥ net | PAID |
| PENDING | paid ≥ net (single full payment) | PAID |
| any | overpayment (paid > net) | PAID (accepted by design) |

### Auto-update flow diagram
```
POST /billing/invoicing-payment
   → validate (StoreInvoicePaymentRequest)
   → BEGIN TX
       → INSERT bil_tenant_invoicing_payments
       → UPDATE bil_tenant_invoices.paid_amount += amount_paid
       → DERIVE status (paid vs net_payable_amount)  [server-side]
       → INSERT bil_tenant_invoicing_audit_logs (whitelisted event_info)
       → activityLog(Store)
   → COMMIT   (rollBack on exception)
   → JSON {status, message}
```

---

## 3. Manual Test Cases

### TC-P03 — Record a partial payment
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed invoice: net=1000, paid=0, status=PENDING | Row in `bil_tenant_invoices` |
| 2 | POST `/billing/invoicing-payment` amount_paid=400, mode=CASH, invoice_payments=PARTIAL | 200 `{status:true, message:'Payment saved successfully!'}` |
| 3 | DB check payments | `SELECT amount_paid FROM bil_tenant_invoicing_payments WHERE transaction_id=? → 400.00` |
| 4 | DB check invoice | `SELECT paid_amount FROM bil_tenant_invoices WHERE id=? → 400.00` |
| 5 | DB check status | status ≠ PENDING (PARTIAL) |
| 6 | Activity log | `sys/global activity` row with event `Store` for the invoice |

### TC-P04 — Status derived PAID (client says PENDING)
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Seed invoice net=500 paid=0 | — |
| 2 | POST amount_paid=500, invoice_payments=PENDING | 200 success |
| 3 | DB check | paid_amount=500.00; status ≠ PENDING (server derives PAID) |

### TC-P05 — Status derived PARTIAL
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed net=1000 paid=0 | — |
| 2 | POST amount_paid=250 | 200 |
| 3 | DB | paid=250 < net; status PARTIAL |

### BC-EDG overpayment — Overpayment accepted
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed net=100 paid=0 | — |
| 2 | POST amount_paid=999.99, invoice_payments=PAID | 200 `{status:true}` |
| 3 | DB | paid_amount(999.99) > net_payable(100); invoice PAID (accepted) |

### TC-N01 — Required-field validation
| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as super-admin | — |
| 2 | POST `/billing/invoicing-payment` empty body (JSON) | 422 with errors on tenant_invoice_id, date, amount_paid, currency, payment_mode, invoice_payments, payment_status |

### TC-N02 — amount_paid = 0
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST amount_paid=0 | 422; `errors.amount_paid` contains "Payment amount must be greater than zero." |

### TC-N04 — Non-existent invoice
| Step | Action | Expected |
|------|--------|----------|
| 1 | POST tenant_invoice_id=999999999 | 422; `errors.tenant_invoice_id` contains "Selected invoice does not exist." |

### TC-N08 — Guest blocked
| Step | Action | Expected |
|------|--------|----------|
| 1 | Log out | — |
| 2 | GET index / `/billing/billing-management` | Redirect to `/login` (302) or 401/403 |

### TC-N09 — Limited user forbidden
| Step | Action | Expected |
|------|--------|----------|
| 1 | Create user is_super_admin=0, no billing abilities | — |
| 2 | POST store as that user | 403 |

### TC-N11 / TC-S02 — Client-forced PAID rejected
| Step | Action | Expected |
|------|--------|----------|
| 1 | Seed net=1000 paid=0 | — |
| 2 | POST amount_paid=1, invoice_payments=PAID, payment_status=PAID | 200 |
| 3 | DB | paid(1) < net(1000); status ≠ PAID (server derivation wins) |

### TC-D06 — MIG-BIL-001 (SoftDeletes vs deleted_at)
| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspect model | `InvoicingPayment` uses `SoftDeletes` |
| 2 | `SELECT` column | `bil_tenant_invoicing_payments` has **no** `deleted_at` → defect confirmed (any `find()`/`delete()` throws SQLSTATE 42S22 on a schema-correct DB) |

### TC-D02/03/04/05 — Remediation proofs (source inspection)
| TC | Check |
|----|-------|
| TC-D02 | `store()` body contains `DB::beginTransaction`, `catch(`, `DB::rollBack`, `DB::commit` |
| TC-D03 | `consolidatedStore()` "No invoices selected" guard appears **before** `DB::beginTransaction` |
| TC-D04 | `store()` derives status via `paid_amount >= $invoice->net_payable_amount` |
| TC-D05 | `store()` body does **not** contain `$request->all()`; carries `'payment_id'` whitelist |

### TC-UX03 — Payment-details empty state
| Step | Action | Expected |
|------|--------|----------|
| 1 | Open payment-details for an invoice with no payments | "No payment records found." shown |

### TC-S03 — Injection-shaped filter
| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit `/billing/billing-management?type=invoice_payment&payment_status=' OR '1'='1` | Page renders; no `SQLSTATE` leaked |
