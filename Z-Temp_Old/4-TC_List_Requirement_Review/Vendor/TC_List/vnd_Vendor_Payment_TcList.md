# vnd_Vendor_Payment_TcList

## Module: Vendor → Vendor Management → Vendor Payment CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Dashboard (Tabbed Interface) — Payments Tab |
| Features | Vendor Payment Index, View, Update, Delete |
| URL(s) | `/vendor-payments`, `/vendor-payments/{vendor_payment}`, `/vendor-payments/{vendor_payment}` (PUT), `/vendor-payments/{vendor_payment}` (DELETE) |
| Controller | `Modules\Vendor\Http\Controllers\VendorPaymentController` (248 lines) |
| Model(s) | `VndPayment` (extends `BaseModel`, uses `SoftDeletes`), `VndInvoice` |
| Validation | Inline validation in `update()`: `payment_date` ⇒ required\|date, `amount` ⇒ required\|numeric\|min:0.01, `payment_mode` ⇒ required, `status` ⇒ required\|in:SUCCESS,INITIATED,FAILED |
| Permission Gates | `tenant.vendor-payment.viewAny`, `tenant.vendor-payment.view`, `tenant.vendor-payment.update`, `tenant.vendor-payment.delete` |
| Soft Deletes | Yes — `VndPayment` model uses `SoftDeletes` trait, plus manual `is_deleted` flag (dual delete tracking) |
| Events | No activity logging — no `activityLog()` calls in any controller method |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor-payment.viewAny`, `tenant.vendor-payment.view`, `tenant.vendor-payment.update`, `tenant.vendor-payment.delete`
- At least one active vendor in `vnd_vendors` (referenced by `vendor_id`)
- At least one invoice in `vnd_invoices` with `vendor_id` set (referenced by `invoice_id`)
- At least one payment mode entry in `sys_dropdown_table` (referenced by `payment_mode`)
- For index/list tests: at least one payment record with related vendor, invoice, and payment mode
- For show tests: at least one payment record with all relations loaded
- For update tests: at least one payment record linked to an invoice with `amount_paid` tracking
- For destroy tests: at least one payment record linked to an invoice for revert verification
- For filter tests: payments with different vendor_id, date_range, and status values
- For permission tests: users with and without each of the 4 permission gates

---

## 3. Default Data Load

### 3.1 Filter Data for Payments Tab (index)

The `index()` method returns:
- `vendorPayments` — Paginated VndPayment records (10 per page) with `vendor`, `invoice`, `paymentMode` relations eager-loaded, ordered by `latest()`
- `vendorsList` — All vendors (unpaginated, used for dropdown filter)

Filter parameters:
- `vendor_id` — Exact match filter on payments.vendor_id
- `date_range` — Dash-separated range string (e.g. "2024-01-01—2024-12-31") parsed via `explode('-')`, applied as `whereBetween('payment_date', [$start, $end])`
- `status` — Exact match filter on payments.status (ENUM: INITIATED/SUCCESS/FAILED)

### 3.2 show() — AJAX Detail View

- Returns JSON response with `VndPayment` loaded with `vendor`, `invoice`, `paymentMode`, `paidBy`, `reconciledBy` relations
- Used for AJAX detail popup/modal — NOT a full page view

### 3.3 update() — Payment Update with Invoice Recalculation

- Accepts PUT request with `payment_date`, `amount`, `payment_mode`, `status`, `reference_no`, `paid_by`, `reconciled`, `reconciled_by`, `reconciled_at`, `remarks`
- Wraps entire operation in `DB::transaction()`
- Fetches payment with `invoice` relation
- **Reverts** old payment amount from invoice: `$payment->invoice->amount_paid -= $payment->amount`
- Updates payment fields
- **Applies** new payment amount to invoice: `$payment->invoice->amount_paid += $payment->amount`
- Recalculates invoice status (`pending_amount = total_amount - amount_paid`) and looks up corresponding sys_dropdown for "Pending", "Partially Paid", or "Fully Paid"
- Commits transaction
- Returns JSON success response

### 3.4 destroy() — Payment Deletion with Invoice Revert

- Accepts DELETE request
- Wraps in `DB::transaction()`
- Fetches payment with `invoice` relation
- **Reverts** payment amount from invoice: `$payment->invoice->amount_paid -= $payment->amount`
- Recalculates invoice status (same logic as update)
- Deletes payment (SoftDeletes: sets `deleted_at`, PLUS manual `is_deleted` flag logic)
- Commits transaction
- Returns JSON success response

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_payments` — Vendor Payment Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) RESTRICT |
| invoice_id | INT UNSIGNED | NOT NULL | — | FK → vnd_invoices(id) RESTRICT |
| payment_date | DATE | NOT NULL | — | Payment date |
| amount | DECIMAL(14,2) | NOT NULL | — | Payment amount |
| payment_mode | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| reference_no | VARCHAR(100) | YES | NULL | Payment reference/transaction no |
| status | ENUM('INITIATED','SUCCESS','FAILED') | YES | 'SUCCESS' | Payment status |
| paid_by | INT UNSIGNED | YES | NULL | FK → sys_users(id) |
| reconciled | TINYINT(1) | YES | 0 | Reconciliation flag |
| reconciled_by | INT UNSIGNED | YES | NULL | FK → sys_users(id) |
| reconciled_at | TIMESTAMP | YES | NULL | Reconciliation timestamp |
| remarks | TEXT | YES | NULL | Payment remarks |
| is_deleted | TINYINT(1) | YES | 0 | Manual delete flag (NOT controlled by SoftDeletes) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `fk_vnd_payment_vendor` (`vendor_id`)
- KEY `fk_vnd_payment_invoice` (`invoice_id`)
- KEY `fk_vnd_payment_mode` (`payment_mode`)

**Foreign Keys:**
| Constraint | Column | References | On Delete |
|------------|--------|------------|-----------|
| fk_vnd_payment_vendor | vendor_id | vnd_vendors(id) | RESTRICT |
| fk_vnd_payment_invoice | invoice_id | vnd_invoices(id) | RESTRICT |
| fk_vnd_payment_mode | payment_mode | sys_dropdown_table(id) | RESTRICT |

**No unique constraints** — duplicate payments (same vendor, same invoice, same amount, same date) are permitted at DB level.

---

## 5. BC-VAL — Validation Rules

### 5.1 Inline Validation in update()

| Field | Rules | Error Message |
|-------|-------|---------------|
| payment_date | required, date | "The payment date field is required." / "The payment date is not a valid date." |
| amount | required, numeric, min:0.01 | "The amount field is required." / "The amount must be at least 0.01." |
| payment_mode | required | "The payment mode field is required." |
| status | required, in:SUCCESS,INITIATED,FAILED | "The status field is required." / "The selected status is invalid." |

**Note:** DDL status is `ENUM('INITIATED','SUCCESS','FAILED')`. Controller validation uses `in:SUCCESS,INITIATED,FAILED` — order differs but values match. Values are case-sensitive — lowercase values will fail validation.

**Unvalidated fields in update():**
- `reference_no`, `paid_by`, `reconciled`, `reconciled_by`, `reconciled_at`, `remarks` — passed through without validation rules
- `reconciled` no boolean validation — any value accepted
- `paid_by` / `reconciled_by` — no `exists:sys_users,id` validation

### 5.2 No FormRequest

- `update()` uses inline `$request->validate([...])` — no dedicated FormRequest class
- `index()`, `show()`, `destroy()` have no validation at all

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) |
|----------------|---------------------|
| tenant.vendor-payment.viewAny | index() — Gate::authorize |
| tenant.vendor-payment.view | show() — Gate::authorize |
| tenant.vendor-payment.update | update() — Gate::authorize |
| tenant.vendor-payment.delete | destroy() — Gate::authorize |

**No Blade @can directives** (no views returned — all JSON responses).

**Policy (expected):** `VendorPaymentPolicy` with methods: viewAny, view, update, delete — no create/restore/forceDelete methods.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Index with Eager Loading | index() loads `vendorPayments` with `vendor`, `invoice`, `paymentMode` relations eager-loaded |
| BC-BIZ-02 | Three-Part Filtering | index() applies filters: vendor_id (exact match), date_range (dash-parsed between), status (exact match) |
| BC-BIZ-03 | Default Pagination 10 | index() paginates at 10 per page with `latest()` ordering |
| BC-BIZ-04 | AJAX Detail View | show() returns JSON with 5 loaded relations (vendor, invoice, paymentMode, paidBy, reconciledBy) |
| BC-BIZ-05 | DB Transaction for Update | update() wraps all payment+invoice operations in `DB::transaction()` |
| BC-BIZ-06 | Payment Revert on Update | Before updating, old payment amount is subtracted from invoice.amount_paid |
| BC-BIZ-07 | Payment Apply on Update | After updating, new payment amount is added to invoice.amount_paid |
| BC-BIZ-08 | Invoice Status Recalculation | After amount_paid change, calculates pending_amount and maps to dropdown (Pending/Partially Paid/Fully Paid) |
| BC-BIZ-09 | DB Transaction for Delete | destroy() wraps revert + status recalc + delete in `DB::transaction()` |
| BC-BIZ-10 | Payment Revert on Delete | Before deletion, payment amount is subtracted from invoice.amount_paid |
| BC-BIZ-11 | SoftDeletes on Payment Delete | destroy() triggers SoftDeletes (sets deleted_at) |
| BC-BIZ-12 | Manual is_deleted on Destroy | destroy() also sets manual `is_deleted = 1` flag (dual delete tracking) |
| BC-BIZ-13 | JSON Responses Only | index() returns view, but update()/destroy() return JSON — no redirects, no flash messages |
| BC-BIZ-14 | No Activity Logging | No activityLog() calls in any controller method — audit trail gap |
| BC-BIZ-15 | VndInvoice boot saving Event Conflict | VndInvoice model has a boot saving event that auto-calculates balance_due. update() manually updates amount_paid and balance_due — potential double-write or conflict |
| BC-BIZ-16 | No Permission Check on reconciled/paid_by | update() validates payment_date, amount, payment_mode, status — but passes paid_by, reconciled, reconciled_by, reconciled_at through without validation. Any user with `tenant.vendor-payment.update` can modify reconciliation data |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_payment_vendor | vnd_payments.vendor_id | vnd_vendors.id | RESTRICT |
| fk_vnd_payment_invoice | vnd_payments.invoice_id | vnd_invoices.id | RESTRICT |
| fk_vnd_payment_mode | vnd_payments.payment_mode | sys_dropdown_table.id | RESTRICT |

**RESTRICT behaviour:**
- Cannot delete a vendor if payments reference it — must delete payments first
- Cannot delete an invoice if payments reference it — must delete payments first
- Cannot delete a payment mode dropdown if payments reference it — must delete/update payments first

---

## 9. Test Case Summary

### 9.1 Vendor Payment — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VP-P01 | Vendor Payment | Positive | Payments tab list loads with filters | 5 |
| TC-VP-P02 | Vendor Payment | Positive | Filter payments — by vendor_id | 3 |
| TC-VP-P03 | Vendor Payment | Positive | Filter payments — by date_range | 4 |
| TC-VP-P04 | Vendor Payment | Positive | Filter payments — by status (SUCCESS/INITIATED/FAILED) | 3 |
| TC-VP-P05 | Vendor Payment | Positive | View payment detail via AJAX (show) | 4 |
| TC-VP-P06 | Vendor Payment | Positive | Update payment — all fields changed | 8 |
| TC-VP-P07 | Vendor Payment | Positive | Update payment — only status changed | 6 |
| TC-VP-P08 | Vendor Payment | Positive | Update payment — amount increase recalculates invoice correctly | 8 |
| TC-VP-P09 | Vendor Payment | Positive | Update payment — amount decrease recalculates invoice correctly | 8 |
| TC-VP-P10 | Vendor Payment | Positive | Delete payment — reverts invoice.amount_paid and recalculates status | 7 |
| TC-VP-P11 | Vendor Payment | Positive | Update payment — status changed from SUCCESS to FAILED (invoice reverted) | 6 |
| TC-VP-P12 | Vendor Payment | Positive | Update payment — status changed from FAILED to SUCCESS (invoice applied) | 6 |
| TC-VP-P13 | Vendor Payment | Positive | Index returns vendorsList for dropdown filter | 3 |
| TC-VP-P14 | Vendor Payment | Positive | Show returns 5 eager-loaded relations in JSON | 4 |
| TC-VP-P15 | Vendor Payment | Positive | paidBy() relationship returns the User who made the payment | 4 |
| TC-VP-P16 | Vendor Payment | Positive | reconciledBy() relationship returns the User who reconciled | 4 |
| TC-VP-P17 | Vendor Payment | Positive | paymentMode() relationship returns the Dropdown for payment mode | 4 |
| TC-VP-P18 | Vendor Payment | Positive | Vendor's payments accessible through invoices chain (hasManyThrough) | 4 |
| TC-VP-P19 | Vendor Payment | Positive | Update — old payment amount reverted from invoice before applying new amount | 5 |
| TC-VP-P20 | Vendor Payment | Positive | Update — invoice status recalculated after amount_paid change | 5 |

### 9.2 Vendor Payment — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VP-N01 | Vendor Payment | Negative | Update — missing payment_date | 2 |
| TC-VP-N02 | Vendor Payment | Negative | Update — invalid payment_date format | 2 |
| TC-VP-N03 | Vendor Payment | Negative | Update — missing amount | 2 |
| TC-VP-N04 | Vendor Payment | Negative | Update — amount is non-numeric | 2 |
| TC-VP-N05 | Vendor Payment | Negative | Update — amount is 0 (below min:0.01) | 2 |
| TC-VP-N06 | Vendor Payment | Negative | Update — amount is negative | 2 |
| TC-VP-N07 | Vendor Payment | Negative | Update — missing payment_mode | 2 |
| TC-VP-N08 | Vendor Payment | Negative | Update — missing status | 2 |
| TC-VP-N09 | Vendor Payment | Negative | Update — invalid status value (not in:SUCCESS,INITIATED,FAILED) | 2 |
| TC-VP-N10 | Vendor Payment | Negative | Update — status value with wrong case ("success" not "SUCCESS") | 2 |
| TC-VP-N11 | Vendor Payment | Negative | Update — non-existent payment ID (404) | 2 |
| TC-VP-N12 | Vendor Payment | Negative | Delete — non-existent payment ID (404) | 2 |
| TC-VP-N13 | Vendor Payment | Negative | Show — non-existent payment ID (404) | 2 |
| TC-VP-N14 | Vendor Payment | Negative | Permission — index without tenant.vendor-payment.viewAny | 2 |
| TC-VP-N15 | Vendor Payment | Negative | Permission — show without tenant.vendor-payment.view | 2 |
| TC-VP-N16 | Vendor Payment | Negative | Permission — update without tenant.vendor-payment.update | 2 |
| TC-VP-N17 | Vendor Payment | Negative | Permission — delete without tenant.vendor-payment.delete | 2 |
| TC-VP-N18 | Vendor Payment | Negative | Update — vendor_id FK violation (non-existent vendor) | 2 |
| TC-VP-N19 | Vendor Payment | Negative | Update — invoice_id FK violation (non-existent invoice) | 2 |
| TC-VP-N20 | Vendor Payment | Negative | Update — payment_mode FK violation (non-existent dropdown) | 2 |
| TC-VP-N21 | Vendor Payment | Negative | Update — DECIMAL(14,2) overflow (amount > 999999999999.99) | 2 |
| TC-VP-N22 | Vendor Payment | Negative | Delete — transaction rollback on invoice update failure | 4 |
| TC-VP-N23 | Vendor Payment | Negative | Update — transaction rollback on partial failure | 4 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — Gate + eager loading + filter logic + pagination | 4 |
| TC-CR02 | Code Review | Review | show() — Gate + findOrFail + 5 relations + JSON response | 4 |
| TC-CR03 | Code Review | Review | update() — Gate + inline validation + DB transaction | 6 |
| TC-CR04 | Code Review | Review | update() — payment revert/apply logic on invoice.amount_paid | 6 |
| TC-CR05 | Code Review | Review | update() — invoice status recalculation after amount_paid change | 5 |
| TC-CR06 | Code Review | Review | destroy() — Gate + DB transaction + payment revert + invoice status recalc | 6 |
| TC-CR07 | Code Review | Review | destroy() — SoftDeletes delete() + manual is_deleted flag | 4 |
| TC-CR08 | Code Review | Review | VndPayment Model — fillable, casts, SoftDeletes, relationships | 5 |
| TC-CR09 | Code Review | Review | VndInvoice boot saving event — auto-calculates balance_due (conflict risk) | 4 |
| TC-CR10 | Code Review | Review | Unvalidated fields in update() — paid_by, reconciled, reconciled_by passed raw | 4 |
| TC-CR11 | Code Review | Review | JSON responses instead of redirects — breaks normal form submissions | 3 |
| TC-CR12 | Code Review | Review | No unique constraints on vnd_payments — duplicate payment entries possible | 2 |
| TC-CR13 | Code Review | Review | Dual delete tracking — SoftDeletes (deleted_at) + manual is_deleted flag | 3 |
| TC-CR14 | Code Review | Review | No activity logging — audit trail gap for payment operations | 2 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | FK vendor_id → vnd_vendors(id) — RESTRICT on delete | 3 |
| TC-D02 | Dependency | Dependency | FK invoice_id → vnd_invoices(id) — RESTRICT on delete | 3 |
| TC-D03 | Dependency | Dependency | FK payment_mode → sys_dropdown_table(id) — RESTRICT on delete | 3 |
| TC-D04 | Dependency | Dependency | SoftDeletes — deleted_at set on destroy, excluded from default queries | 3 |
| TC-D05 | Dependency | Dependency | VndInvoice boot saving event — auto-calculates balance_due on every save | 4 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Vendor Payment

#### TC-VP-P01: Payments tab list loads with filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-payment.viewAny` permission navigates to `/vendor-payments` | Index page loads |
| 2 | Verify `vendorPayments` is paginated (10 per page) with `latest()` ordering | Paginated list displayed |
| 3 | Verify `vendorsList` is passed for vendor dropdown filter | Vendor dropdown present |
| 4 | Verify filter controls: vendor_id dropdown, date_range input, status dropdown | All 3 filters visible |
| 5 | Verify each payment row shows vendor name, invoice reference, amount, payment date, status, and payment mode | All columns present |

#### TC-VP-P02: Filter payments — by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load `/vendor-payments` with existing payments from multiple vendors | List shows all payments |
| 2 | Select a specific vendor_id from dropdown | Page reloads with filter applied |
| 3 | Verify only payments with the selected vendor_id are shown in `vendorPayments` | Filtered results |

#### TC-VP-P03: Filter payments — by date_range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load `/vendor-payments` with payments across multiple dates | List shows all payments |
| 2 | Enter date range as "2024-01-01—2024-06-30" (dash-separated) | Filter applied |
| 3 | Verify `explode('-', $dateRange)` correctly parses start and end dates | Dates parsed |
| 4 | Verify only payments with `payment_date` between 2024-01-01 and 2024-06-30 are shown | Date-filtered results |

#### TC-VP-P04: Filter payments — by status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load `/vendor-payments` with payments in all 3 statuses (INITIATED, SUCCESS, FAILED) | All statuses shown |
| 2 | Select status = "SUCCESS" | Filter applied |
| 3 | Verify only payments with status = "SUCCESS" are shown | Status-filtered results |

#### TC-VP-P05: View payment detail via AJAX (show)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-payment.view` permission sends GET to `/vendor-payments/{id}` | Request succeeds |
| 2 | Verify `findOrFail($id)` returns the payment record | Record found |
| 3 | Verify JSON response includes 5 loaded relations: vendor, invoice, paymentMode, paidBy, reconciledBy | All relations present |
| 4 | Verify JSON fields: id, vendor_id, invoice_id, payment_date, amount, payment_mode, reference_no, status, paid_by, reconciled, reconciled_by, reconciled_at, remarks | All fields returned |

#### TC-VP-P06: Update payment — all fields changed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-payment.update` permission has existing payment: amount=1000.00, status=INITIATED, invoice.amount_paid=5000.00 | Initial state |
| 2 | Send PUT to `/vendor-payments/{id}` with payment_date="2024-06-15", amount=2000.00, payment_mode=valid_id, status=SUCCESS, reference_no="REF-ABC-123" | Update request |
| 3 | Verify `Gate::authorize('tenant.vendor-payment.update')` passes | Authorized |
| 4 | Verify inline validation passes: payment_date=valid date, amount=2000.00≥0.01, payment_mode=present, status=in:SUCCESS,INITIATED,FAILED | Validated |
| 5 | Inside DB transaction: old amount (1000.00) reverted from invoice.amount_paid → 5000-1000=4000 | Old amount reverted |
| 6 | New amount (2000.00) applied to invoice.amount_paid → 4000+2000=6000 | New amount applied |
| 7 | Invoice status recalculated based on pending_amount vs total_amount | Status updated |
| 8 | Verify JSON success response returned — payment record reflects all new field values | Update successful |

#### TC-VP-P07: Update payment — only status changed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Existing payment: amount=1000.00, status=FAILED, invoice.amount_paid=2000.00 (payment was NOT applied to invoice) | Initial state |
| 2 | Send PUT to `/vendor-payments/{id}` with status=SUCCESS, amount=1000.00 (unchanged), payment_date unchanged, payment_mode unchanged | Status change only |
| 3 | Old amount (1000.00) reverted from invoice.amount_paid → 2000-1000=1000 | Revert occurs |
| 4 | Same amount (1000.00) reapplied to invoice.amount_paid → 1000+1000=2000 | Re-apply occurs |
| 5 | Invoice amount_paid remains 2000.00 (revert + reapply cancel out) | Net zero effect on amount_paid |
| 6 | Payment record shows status=SUCCESS | Status updated |

#### TC-VP-P08: Update payment — amount increase recalculates invoice correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment: amount=500.00, status=SUCCESS. Invoice: total_amount=2000.00, amount_paid=500.00, pending=1500.00 (Partially Paid) | Initial state |
| 2 | Update payment amount to 1500.00 | Request |
| 3 | Old amount (500) reverted from invoice.amount_paid → 500-500=0 | Revert |
| 4 | New amount (1500) applied to invoice.amount_paid → 0+1500=1500 | Apply |
| 5 | Invoice pending_amount = 2000-1500 = 500, status remains "Partially Paid" | Recalc |
| 6 | Update total invoice amount_paid to 1500.00 via another payment simultaneously | ... |
| 7 | After second update, invoice amount_paid = 2000.00, pending = 0.00, status = "Fully Paid" | Fully Paid |
| 8 | Verify payment record shows amount=1500.00 | Updated |

#### TC-VP-P09: Update payment — amount decrease recalculates invoice correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment: amount=2000.00, status=SUCCESS. Invoice: total_amount=2000.00, amount_paid=2000.00, pending=0.00, status="Fully Paid" | Initial state |
| 2 | Update payment amount to 500.00 | Request |
| 3 | Old amount (2000) reverted from invoice.amount_paid → 2000-2000=0 | Revert |
| 4 | New amount (500) applied to invoice.amount_paid → 0+500=500 | Apply |
| 5 | Invoice pending_amount = 2000-500 = 1500, status changes to "Partially Paid" | Status demoted |
| 6 | Verify payment shows amount=500.00 | Updated |
| 7 | Invoice.amount_paid = 500.00, invoice.status = "Partially Paid" | Invoice updated |

#### TC-VP-P10: Delete payment — reverts invoice.amount_paid and recalculates status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-payment.delete` permission. Payment: amount=1000.00, status=SUCCESS. Invoice: total_amount=5000.00, amount_paid=3000.00, pending=2000.00 | Initial state |
| 2 | Send DELETE to `/vendor-payments/{id}` | Delete request |
| 3 | Verify `Gate::authorize('tenant.vendor-payment.delete')` passes | Authorized |
| 4 | Inside DB transaction: payment amount (1000.00) reverted from invoice.amount_paid → 3000-1000=2000 | Amount reverted |
| 5 | Invoice status recalculated: pending=5000-2000=3000 → "Partially Paid" (or "Pending" if only payment) | Status recalculated |
| 6 | Payment soft-deleted: `deleted_at` set, AND `is_deleted` set to 1 | Dual delete |
| 7 | Verify JSON success response. Payment no longer appears in index. Invoice.amount_paid reduced by 1000.00 | Delete successful |

#### TC-VP-P11: Update payment — status changed from SUCCESS to FAILED (invoice reverted)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment: amount=1000.00, status=SUCCESS. Invoice: amount_paid=4000.00 includes this payment | Initial |
| 2 | PUT with status=FAILED, same amount and other fields | Request |
| 3 | Old amount (1000) reverted from invoice.amount_paid → 4000-1000=3000 | Revert |
| 4 | Same amount (1000) reapplied to invoice.amount_paid → 3000+1000=4000 | Re-apply |
| 5 | Net effect on amount_paid = 0 (revert + apply cancel) BUT status is now FAILED | Status changes |
| 6 | Payment record shows status=FAILED | Updated |

#### TC-VP-P12: Update payment — status changed from FAILED to SUCCESS (invoice applied)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment: amount=1000.00, status=FAILED. Invoice: amount_paid=3000.00 (this payment was reverted when set to FAILED) | Initial |
| 2 | PUT with status=SUCCESS, same amount and other fields | Request |
| 3 | Old amount (1000) reverted from invoice.amount_paid → 3000-1000=2000 | Revert |
| 4 | Same amount (1000) reapplied to invoice.amount_paid → 2000+1000=3000 | Re-apply |
| 5 | Net effect on amount_paid = 0, status is now SUCCESS | Status changes |
| 6 | Payment record shows status=SUCCESS | Updated |

#### TC-VP-P13: Index returns vendorsList for dropdown filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load `/vendor-payments` | Index loads |
| 2 | Verify `vendorsList` contains all vendors (unpaginated) | All vendors returned |
| 3 | Verify vendor dropdown in filter section allows selecting a vendor_id | Dropdown functional |

#### TC-VP-P14: Show returns 5 eager-loaded relations in JSON

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-payments/{id}` for a payment with all relations populated | AJAX request |
| 2 | Verify JSON contains `vendor` object (id, vendor_name) | Vendor relation loaded |
| 3 | Verify JSON contains `invoice` object (id, invoice_no, total_amount, amount_paid) | Invoice relation loaded |
| 4 | Verify JSON contains `paymentMode` object (id, dropdown name) | Payment mode loaded |
| 5 | Verify JSON contains `paidBy` object (id, name) if paid_by is not null | PaidBy relation loaded |
| 6 | Verify JSON contains `reconciledBy` object (id, name) if reconciled_by is not null | ReconciledBy relation loaded |

#### TC-VP-P15: paidBy() relationship returns the User who made the payment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access a VndPayment record where `paid_by` is set to a valid sys_users id | Record loaded |
| 2 | Call `$payment->paidBy` relationship | Returns User model instance |
| 3 | Verify the returned User's id matches the `paid_by` column value | Correct user returned |
| 4 | Verify `paidBy` is a `belongsTo` relationship with foreign key `paid_by` targeting `User::class` | belongsTo defined |

#### TC-VP-P16: reconciledBy() relationship returns the User who reconciled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access a VndPayment record where `reconciled_by` is set to a valid sys_users id | Record loaded |
| 2 | Call `$payment->reconciledBy` relationship | Returns User model instance |
| 3 | Verify the returned User's id matches the `reconciled_by` column value | Correct user returned |
| 4 | Access a VndPayment where `reconciled_by` is NULL | Call `$payment->reconciledBy` returns null | Handles nullable FK |

#### TC-VP-P17: paymentMode() relationship returns the Dropdown for payment mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access a VndPayment record with a valid `payment_mode` FK to sys_dropdown_table | Record loaded |
| 2 | Call `$payment->paymentMode` relationship | Returns Dropdown model instance |
| 3 | Verify the returned Dropdown's id matches the `payment_mode` column value | Correct dropdown returned |
| 4 | Verify `paymentMode` is a `belongsTo` relationship targeting `Dropdown::class` with foreign key `payment_mode` | belongsTo defined |

#### TC-VP-P18: Vendor's payments accessible through invoices chain (hasManyThrough)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has Invoice INV1 with a SUCCESS payment of amount=1000.00 | Seed data |
| 2 | Access `$vendor->payments` (hasManyThrough via VndInvoice) | Returns Collection of VndPayment |
| 3 | Verify the collection contains the payment linked through INV1 | Payment accessible via chain |
| 4 | Verify each payment in the collection has a valid `invoice` relation loaded | Chain integrity maintained |

#### TC-VP-P19: Update — old payment amount reverted from invoice before applying new amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment: amount=1000.00, status=SUCCESS. Invoice: amount_paid=5000.00 | Initial state |
| 2 | Send PUT with amount=2000.00 (increase), same other fields | Update request |
| 3 | Controller reads old `$payment->amount` (1000.00) from DB before filling model | Old amount captured |
| 4 | Old amount reverted: `$payment->invoice->amount_paid -= 1000` → 5000-1000=4000 | Revert occurs before apply |
| 5 | New amount applied: `$payment->invoice->amount_paid += 2000` → 4000+2000=6000 | New amount applied after fill |

#### TC-VP-P20: Update — invoice status recalculated after amount_paid change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice: total_amount=5000.00, amount_paid=1000.00, pending=4000.00, status="Partially Paid" | Initial state |
| 2 | Update payment to make invoice.amount_paid become 5000.00 (full payment) | Full amount update |
| 3 | Controller calculates `$pendingAmount = 5000.00 - 5000.00 = 0` | pending = 0 |
| 4 | Since `$pendingAmount <= 0`, status maps to "Fully Paid" dropdown | Status recalculated |
| 5 | Verify `$invoice->invoice_status_id` equals the sys_dropdown id for "Fully Paid" | Correct status FK set |

### 10.2 Negative TC Steps — Vendor Payment

#### TC-VP-N01: Update — missing payment_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` without `payment_date` in request body | Validation error |
| 2 | Verify error: "The payment date field is required." | Error returned |

#### TC-VP-N02: Update — invalid payment_date format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with payment_date="not-a-date" | Validation error |
| 2 | Verify error: "The payment date is not a valid date." | Error returned |

#### TC-VP-N03: Update — missing amount

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` without `amount` | Validation error |
| 2 | Verify error: "The amount field is required." | Error returned |

#### TC-VP-N04: Update — amount is non-numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with amount="abc" | Validation error |
| 2 | Verify error: "The amount must be a number." | Error returned |

#### TC-VP-N05: Update — amount is 0 (below min:0.01)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with amount=0 | Validation error |
| 2 | Verify error: "The amount must be at least 0.01." | Error returned |

#### TC-VP-N06: Update — amount is negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with amount=-100 | Validation error |
| 2 | Verify error: "The amount must be at least 0.01." | Error returned |

#### TC-VP-N07: Update — missing payment_mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` without `payment_mode` | Validation error |
| 2 | Verify error: "The payment mode field is required." | Error returned |

#### TC-VP-N08: Update — missing status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` without `status` | Validation error |
| 2 | Verify error: "The status field is required." | Error returned |

#### TC-VP-N09: Update — invalid status value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with status="PENDING" | Not in: SUCCESS,INITIATED,FAILED |
| 2 | Verify error: "The selected status is invalid." | Error returned |

#### TC-VP-N10: Update — status value with wrong case

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/{id}` with status="success" (lowercase) | Case mismatch — "success" !== "SUCCESS" |
| 2 | Verify error: "The selected status is invalid." | Case-sensitive validation fails |

#### TC-VP-N11: Update — non-existent payment ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/vendor-payments/99999` with valid data | Payment 99999 doesn't exist |
| 2 | Verify 404 Not Found from `findOrFail(99999)` | 404 error returned |

#### TC-VP-N12: Delete — non-existent payment ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor-payments/99999` | Payment 99999 doesn't exist |
| 2 | Verify 404 Not Found from `findOrFail(99999)` | 404 error returned |

#### TC-VP-N13: Show — non-existent payment ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor-payments/99999` | Payment 99999 doesn't exist |
| 2 | Verify 404 Not Found from `findOrFail(99999)` | 404 error returned |

#### TC-VP-N14: Permission — index without tenant.vendor-payment.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-payment.viewAny` accesses `/vendor-payments` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-payment.viewAny')` fails | Gate blocks access |

#### TC-VP-N15: Permission — show without tenant.vendor-payment.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-payment.view` GETs `/vendor-payments/{id}` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-payment.view')` fails | Gate blocks access |

#### TC-VP-N16: Permission — update without tenant.vendor-payment.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-payment.update` PUTs `/vendor-payments/{id}` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-payment.update')` fails | Gate blocks access |

#### TC-VP-N17: Permission — delete without tenant.vendor-payment.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-payment.delete` DELETEs `/vendor-payments/{id}` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-payment.delete')` fails | Gate blocks access |

#### TC-VP-N18: Update — vendor_id FK violation (non-existent vendor)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Note: vendor_id is NOT in validated fields — it may or may not be mass-assignable via `$payment->update(...)` | Depends on fillable |
| 2 | If vendor_id is fillable and changed to non-existent ID, DB constraint `fk_vnd_payment_vendor` fires | FK violation |
| 3 | Verify DB throws integrity constraint violation (not caught by controller — no try-catch) | Exception bubbles up |

#### TC-VP-N19: Update — invoice_id FK violation (non-existent invoice)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | If invoice_id is changed to non-existent invoice via mass assignment | FK violation |
| 2 | Verify DB throws `SQLSTATE[23000]: Integrity constraint violation` | Exception thrown |

#### TC-VP-N20: Update — payment_mode FK violation (non-existent dropdown)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT with payment_mode=99999 (non-existent sys_dropdown_table id) | No validation for exists |
| 2 | DB `fk_vnd_payment_mode` constraint fires on update | FK violation |
| 3 | Verify error: Cannot add or update a child row — FK constraint fails | 500 error |

#### TC-VP-N21: Update — DECIMAL(14,2) overflow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT with amount=9999999999999.99 (exceeds DECIMAL(14,2) — 14 digits total, 12 integer + 2 decimal) | 15 total digits |
| 2 | DB truncation or overflow error | Possible data loss or SQL error |
| 3 | Verify amount stored is max DECIMAL(14,2) value = 999999999999.99 | Truncated silently |

#### TC-VP-N22: Delete — transaction rollback on invoice update failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE payment — invoice update fails (e.g. invoice row is locked or deleted) | Transaction in progress |
| 2 | DB::transaction() rolls back all changes | Rolled back |
| 3 | Verify payment still exists (not deleted) | Payment preserved |
| 4 | Verify invoice.amount_paid unchanged | Invoice preserved |

#### TC-VP-N23: Update — transaction rollback on partial failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT update — invoice update succeeds but payment update fails | Partial failure |
| 2 | DB::transaction() rolls back both changes | Atomic rollback |
| 3 | Verify payment unchanged | Payment preserved |
| 4 | Verify invoice.amount_paid unchanged (revert undone) | Invoice preserved |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — Gate + eager loading + filter logic + pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-payment.viewAny')` at method start | Gate present |
| 2 | Review `with(['vendor','invoice','paymentMode'])` — 3 relations eager-loaded | Eager loading |
| 3 | Review filter logic: `vendor_id` (where), `date_range` (dash-explode whereBetween), `status` (where) | 3 filters |
| 4 | Review `latest()->paginate(10)` — latest ordering + 10 per page pagination | Pagination + ordering |

#### TC-CR02: show() — Gate + findOrFail + 5 relations + JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-payment.view')` | Gate present |
| 2 | Review `VndPayment::with([...5 relations...])->findOrFail($id)` | findOrFail with 5 relations |
| 3 | Review loaded relations: vendor, invoice, paymentMode, paidBy, reconciledBy | All 5 relations |
| 4 | Review `return response()->json($vendorPayment)` — AJAX JSON response | JSON returned |

#### TC-CR03: update() — Gate + inline validation + DB transaction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-payment.update')` | Gate present |
| 2 | Review inline validation: `$request->validate([...])` with 4 required fields | Validation present |
| 3 | Review `DB::beginTransaction()` / `DB::commit()` — manual or `DB::transaction()` closure | Transaction wrapping |
| 4 | Review `$payment = VndPayment::with('invoice')->findOrFail($id)` with invoice relation | Relation loaded |
| 5 | Review `$payment->fill($request->all())` or `$payment->update(...)` — mass assignment | Payment update |
| 6 | Review `$payment->save()` within transaction | Save executed |

#### TC-CR04: update() — payment revert/apply logic on invoice.amount_paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$payment->invoice->amount_paid -= $payment->amount` — revert OLD amount from invoice | Old amount reverted |
| 2 | Review `$payment->invoice->amount_paid += $request->amount` — apply NEW amount to invoice | New amount applied |
| 3 | Verify revert happens BEFORE payment fields are updated (uses $payment->amount from DB, not request) | Correct ordering |
| 4 | Verify apply happens AFTER payment fields are set (uses $request->amount, not $payment->amount) | Correct ordering |
| 5 | Review that `$payment->invoice->save()` is called to persist amount_paid change | Invoice saved |
| 6 | Review that if status=FAILED, the amount should NOT be applied to invoice amount_paid (check if logic exists) | Status-aware logic gap |

#### TC-CR05: update() — invoice status recalculation after amount_paid change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$pendingAmount = $invoice->total_amount - $invoice->amount_paid` | Pending calc |
| 2 | Review sys_dropdown lookup: `if ($pendingAmount <= 0) → "Fully Paid"`, `elseif ($pendingAmount < $invoice->total_amount) → "Partially Paid"`, `else → "Pending"` | Status mapping |
| 3 | Review `$invoice->invoice_status_id = $dropdown->id` — status stored as FK to dropdown | Status FK set |
| 4 | Review `$invoice->balance_due = $pendingAmount` — balance_due manually set | balance_due set |
| 5 | Review potential conflict: VndInvoice boot saving event also auto-calculates balance_due — double-write risk | Event collision |

#### TC-CR06: destroy() — Gate + DB transaction + payment revert + invoice status recalc

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-payment.delete')` | Gate present |
| 2 | Review `DB::transaction()` wrapping | Transaction |
| 3 | Review `$payment = VndPayment::with('invoice')->findOrFail($id)` — invoice loaded | Relation |
| 4 | Review `$payment->invoice->amount_paid -= $payment->amount` — revert amount | Revert logic |
| 5 | Review invoice status recalculation (same as update — pending_amount → dropdown lookup) | Status recalc |
| 6 | Review `$payment->delete()` — triggers SoftDeletes | Soft delete |

#### TC-CR07: destroy() — SoftDeletes delete() + manual is_deleted flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$payment->delete()` — sets `deleted_at` via SoftDeletes trait | SoftDeletes triggered |
| 2 | Review that `delete()` marks `deleted_at` timestamp, record remains in DB | Not force-deleted |
| 3 | Review if `$payment->is_deleted = 1` and `$payment->save()` is called separately | Manual flag set |
| 4 | Note: Dual tracking means both `deleted_at` and `is_deleted` are set on delete — redundant | Dual delete |

#### TC-CR08: VndPayment Model — fillable, casts, SoftDeletes, relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` — [vendor_id, invoice_id, payment_date, amount, payment_mode, reference_no, status, paid_by, reconciled, reconciled_by, reconciled_at, remarks, is_deleted] | 13 fillable fields |
| 2 | Review `$casts` — payment_date→date, amount→decimal:2, reconciled→boolean, reconciled_at→datetime | Casts defined |
| 3 | Review `SoftDeletes` trait is used | SoftDeletes present |
| 4 | Review `invoice()` — belongsTo VndInvoice | Invoice relation |
| 5 | Review `vendor()`, `paymentMode()`, `paidBy()`, `reconciledBy()` — all belongsTo | All 5 relations |

#### TC-CR09: VndInvoice boot saving event — auto-calculates balance_due (conflict risk)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndInvoice model `boot()` method for saving event | Event hook |
| 2 | Review saving event handler: `$this->balance_due = $this->total_amount - $this->amount_paid` | Auto-calc |
| 3 | Note: VendorPaymentController update() ALSO manually sets balance_due before $invoice->save() | Double-write |
| 4 | Verify order: controller sets balance_due, then $invoice->save() triggers boot saving which OVERWRITES it | Event wins → controller's value may be overridden |

#### TC-CR10: Unvalidated fields in update() — paid_by, reconciled, reconciled_by passed raw

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review validated fields: only payment_date, amount, payment_mode, status | 4 fields validated |
| 2 | Review that `$request->all()` or `$request->except(...)` passes remaining fields to model | Raw pass-through |
| 3 | Review that `reconciled` is not validated as boolean — any value accepted | No boolean check |
| 4 | Review that `paid_by` and `reconciled_by` are not validated as `exists:sys_users,id` | No FK check |

#### TC-CR11: JSON responses instead of redirects — breaks normal form submissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review update() return: `return response()->json(['success' => true, 'message' => '...', 'data' => $payment])` | JSON response |
| 2 | Review destroy() return: `return response()->json(['success' => true, 'message' => '...'])` | JSON response |
| 3 | Note: update() and destroy() return JSON — cannot be used with standard HTML form POST (expects redirect) | No redirect |

#### TC-CR12: No unique constraints on vnd_payments — duplicate payment entries possible

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review vnd_payments DDL — no UNIQUE KEY on any column combination | No unique constraint |
| 2 | Review fillable fields — no application-level unique validation | No app-level check |
| 3 | Consequence: same invoice_id + same amount + same payment_date can be duplicated | Duplicates allowed |

#### TC-CR13: Dual delete tracking — SoftDeletes (deleted_at) + manual is_deleted flag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review SoftDeletes trait on VndPayment model — sets deleted_at on delete() | SoftDeletes present |
| 2 | Review is_deleted in $fillable — manual flag | Manual flag |
| 3 | Review destroy() — check if both mechanisms are triggered | Dual mechanism |

#### TC-CR14: No activity logging — audit trail gap for payment operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `activityLog(` calls | None found |
| 2 | Verify no logging on update() — no record of who changed what | No update audit |
| 3 | Verify no logging on destroy() — no record of who deleted what | No delete audit |

### 10.4 Dependency TC Steps

#### TC-D01: FK vendor_id → vnd_vendors(id) — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has 3 payments in vnd_payments | Referenced vendor |
| 2 | Attempt to delete V1 from vnd_vendors | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D02: FK invoice_id → vnd_invoices(id) — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice INV1 has 2 payments in vnd_payments | Referenced invoice |
| 2 | Attempt to delete INV1 from vnd_invoices | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D03: FK payment_mode → sys_dropdown_table(id) — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment mode PM1 is used in 1+ vnd_payments records | Referenced dropdown |
| 2 | Attempt to delete PM1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D04: SoftDeletes — deleted_at set on destroy, excluded from default queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payment deleted via destroy() | deleted_at set |
| 2 | Query VndPayment::all() — deleted payment NOT included (SoftDeletes `addGlobalScope`) | Excluded |
| 3 | Query VndPayment::withTrashed()->get() — deleted payment IS included | With trashed visible |

#### TC-D05: VndInvoice boot saving event — auto-calculates balance_due on every save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndInvoice has `static::saving(function ($invoice) { $invoice->balance_due = $invoice->total_amount - $invoice->amount_paid; })` in boot() | Saving event |
| 2 | Controller manually sets `$invoice->balance_due = $pendingAmount` before `$invoice->save()` | Manual set |
| 3 | When save() runs, boot saving event OVERWRITES balance_due with its own calculation | Event overrides |
| 4 | Verify both calculations produce same result — if not, controller intent is lost | Potential bug |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-payments` | vendor-payments.index | index() | tenant.vendor-payment.viewAny |
| GET | `/vendor-payments/{vendor_payment}` | vendor-payments.show | show() | tenant.vendor-payment.view |
| PUT | `/vendor-payments/{vendor_payment}` | vendor-payments.update | update() | tenant.vendor-payment.update |
| DELETE | `/vendor-payments/{vendor_payment}` | vendor-payments.destroy | destroy() | tenant.vendor-payment.delete |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Dual delete tracking — is_deleted in fillable PLUS SoftDeletes trait | **Low** | Model has both `is_deleted` manual flag and `SoftDeletes` deleted_at — redundant and confusing; both are set on delete |
| KI-02 | No unique constraint on vnd_payments DDL | **Medium** | No UNIQUE KEY on any column combination — same invoice can have duplicate identical payments with no application-level or DB-level prevention |
| KI-03 | update() and destroy() return JSON, not redirects | **Medium** | Controller returns `response()->json(...)` instead of `redirect()->route(...)` — breaks standard HTML form submissions; only usable via AJAX/fetch |
| KI-04 | update() manually updates invoice balance_due but VndInvoice model has boot saving event that auto-calculates balance_due | **High** | `$invoice->balance_due = $pendingAmount` set in controller, then `$invoice->save()` triggers boot saving event which recalculates and overwrites — potential double-write conflict where controller value is overridden |
| KI-05 | DDL status ENUM order differs from validation `in:` order | **Info** | DDL: `ENUM('INITIATED','SUCCESS','FAILED')`, validation: `in:SUCCESS,INITIATED,FAILED` — values match but order differs; no functional impact |
| KI-06 | No validation/permission check for reconciled/paid_by fields | **Medium** | update() validates only 4 fields (payment_date, amount, payment_mode, status) — `paid_by`, `reconciled`, `reconciled_by`, `reconciled_at`, `remarks` pass through unvalidated. Any user with `tenant.vendor-payment.update` can change reconciliation data without proper authorization |
| KI-07 | No activity logging | **Medium** | No `activityLog()` calls in any controller method — no audit trail for who created, updated, or deleted payments |
| KI-08 | No FormRequest class — inline validation in controller | **Low** | Validation rules are defined inline in `update()` method — no reusability, no separation of concerns, no `authorize()` method |
| KI-09 | is_deleted in $fillable — mass assignable | **Medium** | `is_deleted` is in the `$fillable` array — could be set via mass assignment during update, bypassing intended SoftDeletes-only delete logic |
| KI-10 | No authentication on destroy — SoftDeleted payment can still be accessed via withTrashed() | **Low** | Once soft-deleted, findOrFail will still find it (SoftDeletes only applies to default queries) — show() could potentially display deleted records if withTrashed() is used |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Payment List (Tab) | index() | VndPayment, VndVendor, VndInvoice, Dropdown | 10 per page |
| View Payment | show() | VndPayment (+5 relations) | None (AJAX) |
| Update Payment | update() | VndPayment, VndInvoice | None (JSON) |
| Delete Payment | destroy() | VndPayment, VndInvoice | None (JSON) |
| Create Payment | **NOT IMPLEMENTED** | — | — |
| Edit Payment (form) | **NOT IMPLEMENTED** | — | — |
| Restore Payment | **NOT IMPLEMENTED** | — | — |
| Force-Delete Payment | **NOT IMPLEMENTED** | — | — |
