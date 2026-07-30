# vnd_Report_PaymentRegister_TcList

## Module: Vendor → Reports → Payment Register

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Reports (Tabbed Interface) |
| Features | Payment Register — paginated list, summary cards, 3 charts (mode, daily trend, top vendors), filters (vendor, agreement, item) |
| URL(s) | `/vendor-reports` (with `tab=payment-register`) |
| Controller | `Modules\Vendor\Http\Controllers\VendorReportController` |
| Method | `getPaymentRegisterData()` |
| Model(s) | `VndPayment`, `Vendor`, `VndInvoice`, `Dropdown` (payment mode) |
| Validation | None (filter inputs passed via GET, date range handled in `dates()`) |
| Permission Gate | `tenant.vendor-report.viewAny` |
| Soft Deletes | Yes — `VndPayment` uses `SoftDeletes` trait; query excludes with `is_deleted = 0` |
| Pagination | 10 per page, page name `payment_page` |

---

## 2. Pre-conditions

- Required permission: `tenant.vendor-report.viewAny`
- At least one `VndPayment` record with `status = 'SUCCESS'` and `is_deleted = 0` within the selected date range
- For filter tests: related `Vendors`, `VndInvoices`, `VndAgreements`, `VndAgreementItems`, and `Dropdown` (payment_mode) records must exist
- For chart tests: multiple `VndPayment` records with varying `payment_mode` values, `payment_date` days, and `vendor_id` values
- For summary tests: mix of reconciled (`reconciled = 1`) and unreconciled (`reconciled = 0`) payments

---

## 3. Default Data Load

### 3.1 Filter Data for Payment Register

The `index()` method populates filter dropdowns before calling `getPaymentRegisterData()`:

| Filter | Source | Behaviour |
|--------|--------|-----------|
| `vendor_id` | `Vendor::active()->orderBy('vendor_name')->get()` | Independent dropdown; filters payments by `vendor_id` |
| `agreement_id` | `VndAgreement::orderByDesc('id')->when(vendor_id, ...)->get()` | Dependent on vendor_id; filters via `invoice.agreement_id` |
| `item_id` | `VndItem::active()->orderBy('item_name')->when(agreement_id/vendor_id, ...)->get()` | Dependent on agreement_id/vendor_id; filters via `invoice.agreement_item_id` |

### 3.2 AJAX Cascading Dropdowns

`getFilteredOptions()` returns JSON for dependent dropdowns:
- `?get_options=agreements&vendor_id=X` — agreements filtered by vendor
- `?get_options=items&vendor_id=X&agreement_id=Y` — items filtered by vendor or agreement

### 3.3 Payment Register Data

`getPaymentRegisterData()` returns:

| Variable | Type | Description |
|----------|------|-------------|
| `paymentRecords` | Paginated Collection | 10 per page (page name `payment_page`), eager loads `vendor`, `invoice`, `paymentMode`, ordered by `payment_date DESC` |
| `paymentSummary` | Array | 6 summary metrics (see BC-BIZ-03) |
| `paymentChartMode` | Collection | Grouped by `paymentMode.value` |
| `paymentChartDaily` | Collection | Grouped by `payment_date` day |
| `paymentChartVendor` | Collection | Top 8 vendors by total amount |

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_payments` — Payment Transactions Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| invoice_id | INT UNSIGNED | NOT NULL | — | FK → vnd_invoices(id) |
| payment_date | DATE | NOT NULL | — | Date payment was made |
| amount | DECIMAL(14,2) | NOT NULL | — | Payment amount |
| payment_mode | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) |
| reference_no | VARCHAR(100) | YES | NULL | Payment reference number |
| status | ENUM('FAILED','INITIATED','SUCCESS') | NOT NULL | 'SUCCESS' | Payment status |
| paid_by | INT UNSIGNED | YES | NULL | FK → users(id) |
| reconciled | BOOLEAN | NOT NULL | FALSE | Reconciliation flag |
| reconciled_by | INT UNSIGNED | YES | NULL | FK → users(id) |
| reconciled_at | TIMESTAMP | YES | NULL | When reconciled |
| remarks | TEXT | YES | NULL | Payment remarks |
| is_deleted | BOOLEAN | NOT NULL | FALSE | Legacy delete flag |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- FOREIGN KEY `fk_vnd_pay_vendor` (`vendor_id`) REFERENCES `vnd_vendors`(`id`)
- FOREIGN KEY `fk_vnd_pay_invoice` (`invoice_id`) REFERENCES `vnd_invoices`(`id`)
- FOREIGN KEY `fk_vnd_pay_mode` (`payment_mode`) REFERENCES `sys_dropdown_table`(`id`)

### 4.2 Key Related Tables

**`vnd_vendors`** → Referenced by `vendor_id`
**`vnd_invoices`** → Referenced by `invoice_id`; carries `agreement_id` (→ VndAgreement) and `agreement_item_id` (→ VndAgreementItem)
**`sys_dropdown_table`** → Referenced by `payment_mode`; stores mode display values

---

## 5. BC-VAL — Validation Rules

No form validation applies to the Payment Register. Filter parameters are optional GET inputs. Date range defaults to current month via the helper:

```
$from = $r->filled('from_date') ? Carbon::parse($r->from_date) : now()->startOfMonth();
$to   = $r->filled('to_date')   ? Carbon::parse($r->to_date)   : now()->endOfMonth();
```

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.vendor-report.viewAny | index() (single Gate::authorize) | None (direct Gate check) |

**index() Gate Behaviour:** Single `Gate::authorize('tenant.vendor-report.viewAny')` at method start — no fallback alternatives.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Shared Report Index | `index()` returns unified report view with 5 independent query methods (ledger, agreement, invoice, outstanding, payment), each with its own tab key |
| BC-BIZ-02 | Payment Register Query | `getPaymentRegisterData()` queries `VndPayment` with eager loads (`vendor`, `invoice`, `paymentMode`), filtered by `status = 'SUCCESS'`, `is_deleted = 0`, `payment_date BETWEEN [$from, $to]` |
| BC-BIZ-03 | Payment Summary Metrics | 6 summary values: `total_payments` (count), `total_amount` (sum), `reconciled_count` (reconciled=1), `pending_recon` (reconciled=0), `avg_payment` (sum/count, division guard), `largest_payment` (max, null coalesce) |
| BC-BIZ-04 | Payment Chart — Mode | `paymentChartMode` groups by `optional($p->paymentMode)->value ?? 'Unknown'` with count and sum amount per mode |
| BC-BIZ-05 | Payment Chart — Daily | `paymentChartDaily` groups by `payment_date->format('Y-m-d')`, only includes records with non-null `payment_date`; sorted by date key |
| BC-BIZ-06 | Payment Chart — Vendor | `paymentChartVendor` groups by `vendor_id`, maps vendor_name with fallback `?? 'Unknown'`, total amount, and count; sorted by total DESC, limited to top 8 |
| BC-BIZ-07 | Date Range Default | `dates()` helper defaults `from_date` to `now()->startOfMonth()` and `to_date` to `now()->endOfMonth()` when not provided |
| BC-BIZ-08 | Dependent Filter Dropdowns | `agreement_id` filtered by `vendor_id` via when(); `item_id` filtered by `agreement_id` or `vendor_id` via when() with nested whereHas |
| BC-BIZ-09 | Agreement/Item Filters via Invoice | `agreement_id` uses `whereHas('invoice', fn => where('agreement_id', ...))`; `item_id` uses `whereHas('invoice', fn => where('agreement_item_id', ...))` |
| BC-BIZ-10 | Pagination Appends | `paymentRecords->appends($request->query())` preserves filter query strings across pagination links |
| BC-BIZ-11 | Division-by-Zero Guard | `avg_payment` only divides when `$payments->count() > 0`, else returns `0` |
| BC-BIZ-12 | Largest Payment Fallback | `largest_payment` uses `$payments->max('amount') ?? 0` to handle empty collection |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_pay_vendor | vnd_payments.vendor_id | vnd_vendors.id | RESTRICT / NO ACTION (migration defaults) |
| fk_vnd_pay_invoice | vnd_payments.invoice_id | vnd_invoices.id | RESTRICT / NO ACTION (migration defaults) |
| fk_vnd_pay_mode | vnd_payments.payment_mode | sys_dropdown_table.id | RESTRICT / NO ACTION (migration defaults) |

**Soft Delete Query Behaviour:** The query explicitly filters `is_deleted = 0` (legacy flag) even though `SoftDeletes` is used. Soft-deleted records would have `deleted_at` set but `is_deleted` may also be set to 1.

---

## 9. Test Case Summary

### 9.1 Payment Register — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-PR-P01 | Payment Register | Positive | Payment Register tab loads with all charts and summary | 5 |
| TC-PR-P02 | Payment Register | Positive | Filter by vendor_id — single vendor | 3 |
| TC-PR-P03 | Payment Register | Positive | Filter by vendor_id — no matching payments | 3 |
| TC-PR-P04 | Payment Register | Positive | Filter by agreement_id (via invoice) | 3 |
| TC-PR-P05 | Payment Register | Positive | Filter by item_id (via invoice.agreement_item_id) | 3 |
| TC-PR-P06 | Payment Register | Positive | Filter by date range — custom from/to | 4 |
| TC-PR-P07 | Payment Register | Positive | Filter by date range — single day | 3 |
| TC-PR-P08 | Payment Register | Positive | Pagination — page 2 loads with page name payment_page | 4 |
| TC-PR-P09 | Payment Register | Positive | Summary — total_payments and total_amount correct | 3 |
| TC-PR-P10 | Payment Register | Positive | Summary — reconciled_count and pending_recon correct | 3 |
| TC-PR-P11 | Payment Register | Positive | Summary — avg_payment calculated correctly | 3 |
| TC-PR-P12 | Payment Register | Positive | Summary — largest_payment identified correctly | 3 |
| TC-PR-P13 | Payment Register | Positive | Chart — paymentChartMode groups by payment mode | 4 |
| TC-PR-P14 | Payment Register | Positive | Chart — paymentChartDaily groups by day | 4 |
| TC-PR-P15 | Payment Register | Positive | Chart — paymentChartVendor top 8 by total | 4 |
| TC-PR-P16 | Payment Register | Positive | All filters combined (vendor + agreement + item + date range) | 5 |
| TC-PR-P17 | Payment Register | Positive | Default date range (current month) when no date filters supplied | 3 |
| TC-PR-P18 | Payment Register | Positive | Cascading dropdown — agreements filtered by vendor selection | 4 |
| TC-PR-P19 | Payment Register | Positive | Cascading dropdown — items filtered by agreement selection | 4 |
| TC-PR-P20 | Payment Register | Positive | AJAX getFilteredOptions — agreements by vendor_id | 3 |
| TC-PR-P21 | Payment Register | Positive | AJAX getFilteredOptions — items by agreement_id or vendor_id | 5 |

### 9.2 Payment Register — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-PR-N01 | Payment Register | Negative | No permission — user without tenant.vendor-report.viewAny | 2 |
| TC-PR-N02 | Payment Register | Negative | No data — no SUCCESS payments in date range | 3 |
| TC-PR-N03 | Payment Register | Negative | No data — all payments have is_deleted = 1 | 3 |
| TC-PR-N04 | Payment Register | Negative | Invalid vendor_id (non-existent) | 2 |
| TC-PR-N05 | Payment Register | Negative | Invalid agreement_id (non-existent) | 2 |
| TC-PR-N06 | Payment Register | Negative | Invalid item_id (non-existent) | 2 |
| TC-PR-N07 | Payment Register | Negative | Invalid date range — from_date after to_date | 3 |
| TC-PR-N08 | Payment Register | Negative | Invalid date format — non-date string supplied | 3 |
| TC-PR-N09 | Payment Register | Negative | Future date range with no payments | 2 |
| TC-PR-N10 | Payment Register | Negative | Null payment_date in some records (filtered out by paymentChartDaily) | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-P01 | Payment Register | Review | index() — Gate::authorize + tab routing + 5 report methods | 4 |
| TC-CR-P02 | Payment Register | Review | getPaymentRegisterData() — base query conditions (status, is_deleted, date range) | 4 |
| TC-CR-P03 | Payment Register | Review | getPaymentRegisterData() — vendor/agreement/item filter logic | 4 |
| TC-CR-P04 | Payment Register | Review | paymentSummary — avg_payment division-by-zero guard | 3 |
| TC-CR-P05 | Payment Register | Review | paymentSummary — largest_payment max() null coalesce | 3 |
| TC-CR-P06 | Payment Register | Review | paymentChartMode — vendor_name fallback to 'Unknown' | 3 |
| TC-CR-P07 | Payment Register | Review | paymentChartMode — paymentMode fallback to 'Unknown' via optional() | 3 |
| TC-CR-P08 | Payment Register | Review | paymentChartDaily — null payment_date filter before groupBy | 3 |
| TC-CR-P09 | Payment Register | Review | paymentChartVendor — top 8 with sortByDesc + take(8) | 3 |
| TC-CR-P10 | Payment Register | Review | Pagination — paginate(10) with page name 'payment_page' + appends() | 4 |
| TC-CR-P11 | Payment Register | Review | Dependent dropdowns — getFilteredOptions() cascading logic | 4 |
| TC-CR-P12 | Payment Register | Review | dates() helper — default startOfMonth/endOfMonth fallback | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-P01 | Payment Register | Dependency | FK vendor_id → vnd_vendors — records must exist | 2 |
| TC-D-P02 | Payment Register | Dependency | FK invoice_id → vnd_invoices — invoice must exist for agreement/item filters | 3 |
| TC-D-P03 | Payment Register | Dependency | FK payment_mode → sys_dropdown_table — mode value display | 3 |
| TC-D-P04 | Payment Register | Dependency | Eager loading — with(['vendor','invoice','paymentMode']) confirmed | 3 |
| TC-D-P05 | Payment Register | Dependency | SoftDelete + is_deleted — record with deleted_at non-null excluded from query | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Payment Register

#### TC-PR-P01: Payment Register tab loads with all charts and summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-report.viewAny` permission navigates to `/vendor-reports?tab=payment-register` | Report view loads |
| 2 | Verify Payment Register section shows paginated payment records with columns | Payment list visible |
| 3 | Verify summary cards: total_payments, total_amount, reconciled_count, pending_recon, avg_payment, largest_payment | 6 summary values displayed |
| 4 | Verify 3 charts: paymentChartMode (by mode), paymentChartDaily (by day), paymentChartVendor (top 8) | Charts rendered |
| 5 | Verify filter dropdowns: vendor_id, agreement_id, item_id, from_date, to_date | Filters visible |

#### TC-PR-P02: Filter by vendor_id — single vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has 5 SUCCESS payments, Vendor V2 has 3 SUCCESS payments within date range | Data seeded |
| 2 | Select Vendor V1 from vendor_id dropdown | Filter applied |
| 3 | Verify only V1's payments appear in paymentRecords (5 records), summary reflects V1 only | Filtered to V1 |

#### TC-PR-P03: Filter by vendor_id — no matching payments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V3 exists but has no SUCCESS payments within date range | No payments for V3 |
| 2 | Select Vendor V3 from vendor_id dropdown | Filter applied |
| 3 | Verify paymentRecords is empty, summary shows all zeros, charts are empty | Empty state |

#### TC-PR-P04: Filter by agreement_id (via invoice)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has invoices with payments; Agreement A2 has none | Data seeded |
| 2 | Select A1 from agreement_id dropdown | Filter applied |
| 3 | Verify only payments linked to invoices belonging to A1 are shown | Filtered |

#### TC-PR-P05: Filter by item_id (via invoice.agreement_item_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Item I1 linked to invoice with payments; Item I2 has none | Data seeded |
| 2 | Select I1 from item_id dropdown | Filter applied |
| 3 | Verify only payments linked to invoices containing I1 are shown | Filtered |

#### TC-PR-P06: Filter by date range — custom from/to

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payments exist on 2026-01-05, 2026-01-15, 2026-02-10 | Multiple dates |
| 2 | Set from_date=2026-01-01, to_date=2026-01-31 | Date range Jan 2026 |
| 3 | Verify only Jan payments (5th and 15th) are shown | Date filtered |
| 4 | Verify `whereBetween('payment_date', [...]` condition applied correctly | Correct whereBetween |

#### TC-PR-P07: Filter by date range — single day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Exactly 2 payments exist on 2026-03-15 | Single day |
| 2 | Set from_date=2026-03-15, to_date=2026-03-15 | Same day |
| 3 | Verify only 2026-03-15 payments appear (2 records) | Single day |

#### TC-PR-P08: Pagination — page 2 loads with page name payment_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 SUCCESS payments within date range | 12 records |
| 2 | Load report with no filters — page 1 shows first 10 | Page 1 shows 10 |
| 3 | Click page 2 or append `?payment_page=2` | Page 2 loads |
| 4 | Verify remaining 2 payments on page 2, pagination links show `payment_page` param | payment_page page name |

#### TC-PR-P09: Summary — total_payments and total_amount correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 4 payments with amounts 100, 200, 300, 400 exist within date range | Data seeded |
| 2 | Load Payment Register with no filters | All payments loaded |
| 3 | Verify `total_payments` = 4, `total_amount` = 1000.00 | Summary correct |

#### TC-PR-P10: Summary — reconciled_count and pending_recon correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 payments: 3 reconciled (reconciled=1), 2 pending (reconciled=0) | Mixed status |
| 2 | Load Payment Register | Summary computed |
| 3 | Verify `reconciled_count` = 3, `pending_recon` = 2 | Counts correct |

#### TC-PR-P11: Summary — avg_payment calculated correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 3 payments with amounts 100.00, 200.00, 300.00 | Data seeded |
| 2 | Load Payment Register | Avg computed |
| 3 | Verify `avg_payment` = 200.00 (600/3 = 200) | Average correct |

#### TC-PR-P12: Summary — largest_payment identified correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 4 payments with amounts 50, 150, 500, 200 | Data seeded |
| 2 | Load Payment Register | Largest computed |
| 3 | Verify `largest_payment` = 500.00 | Largest correct |

#### TC-PR-P13: Chart — paymentChartMode groups by payment mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 4 payments: 2 with mode "Bank Transfer" (IDs 1,2), 1 with "Cheque" (ID 3), 1 with "Cash" (ID 4) | Multiple modes |
| 2 | Load Payment Register | Chart built |
| 3 | Verify 3 groups: Bank Transfer (2 payments, sum amounts), Cheque (1), Cash (1) | Groups correct |
| 4 | Verify each point has `mode`, `count`, `amount` | Structure correct |

#### TC-PR-P14: Chart — paymentChartDaily groups by day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 payments: 2 on 2026-01-05, 1 on 2026-01-10, 2 on 2026-01-20 | Multiple days |
| 2 | Load Payment Register | Chart built |
| 3 | Verify 3 date groups with correct counts and totals | Daily groups correct |
| 4 | Verify points sorted by date ascending | Sorted correctly |

#### TC-PR-P15: Chart — paymentChartVendor top 8 by total

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payments across 10 vendors with varying totals | 10 vendors |
| 2 | Load Payment Register | Chart built |
| 3 | Verify exactly 8 vendors returned, sorted by total DESC | Top 8 |
| 4 | Verify each point has `vendor_name`, `total`, `count` | Structure correct |

#### TC-PR-P16: All filters combined (vendor + agreement + item + date range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1, Agreement A1 (belongs to V1), Item I1 (belongs to A1), with payment on 2026-02-15 | Specific combo |
| 2 | Set vendor_id=V1, agreement_id=A1, item_id=I1, from_date=2026-02-01, to_date=2026-02-28 | All filters |
| 3 | Verify only the targeted payment(s) returned | Combined filter |
| 4 | Verify summary and charts reflect only filtered data | All scoped |
| 5 | Verify agreement_id dropdown only shows A1's agreements, item_id only I1's items | Cascade works |

#### TC-PR-P17: Default date range (current month) when no date filters supplied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No from_date or to_date in request | No date params |
| 2 | Load Payment Register | dates() defaults applied |
| 3 | Verify `whereBetween('payment_date', [startOfMonth(), endOfMonth()])` condition | Current month filtered |

#### TC-PR-P18: Cascading dropdown — agreements filtered by vendor selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has agreements A1, A2; Vendor V2 has A3 | Multiple vendors |
| 2 | Select V1 in vendor dropdown | AJAX call to ?get_options=agreements&vendor_id=V1 |
| 3 | Verify agreement dropdown only lists A1 and A2 | Cascade works |
| 4 | Verify `VndAgreement::where('vendor_id', $vendorId)->get()` logic | Backend correct |

#### TC-PR-P19: Cascading dropdown — items filtered by agreement selection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has I3 | Multiple items |
| 2 | Select A1 in agreement dropdown | AJAX call with agreement_id |
| 3 | Verify item dropdown only lists I1 and I2 | Cascade works |
| 4 | Verify `whereHas('agreementItems', fn => where('agreement_id', ...))` logic | Backend correct |

#### TC-PR-P20: AJAX getFilteredOptions — agreements by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements (AR-001, AR-002), Vendor Y has 1 agreement (AR-003) | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX request |
| 3 | Verify JSON response contains 2 objects each with `id` and `text` fields for AR-001 and AR-002 | Filtered correctly |

#### TC-PR-P21: AJAX getFilteredOptions — items by agreement_id or vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has item I3; Vendor V1 has agreements A1, A2 | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=items&agreement_id=A1` | Items by agreement |
| 3 | Verify JSON contains I1 and I2 only (items linked via agreementItems where agreement_id=A1) | Filtered by agreement |
| 4 | Send AJAX: `GET /vendor-reports?get_options=items&vendor_id=V1` (no agreement_id) | Items by vendor fallback |
| 5 | Verify JSON contains I1, I2, I3 (all items linked to V1's agreements via agreementItems.agreement) | Vendor-scoped fallback |

### 10.2 Negative TC Steps — Payment Register

#### TC-PR-N01: No permission — user without tenant.vendor-report.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-report.viewAny` permission accesses `/vendor-reports` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-report.viewAny')` throws AuthorizationException | Aborted |

#### TC-PR-N02: No data — no SUCCESS payments in date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only FAILED or INITIATED payments exist in date range; no SUCCESS payments | No matching data |
| 2 | Load Payment Register | Empty state |
| 3 | Verify paymentRecords is empty collection, summary all zeros (0, 0.00), charts empty | Empty state handled |

#### TC-PR-N03: No data — all payments have is_deleted = 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payments exist with status=SUCCESS but is_deleted=1 for all | Soft-deleted |
| 2 | Load Payment Register | No records returned |
| 3 | Verify query where('is_deleted', 0) excludes all records | Empty result |

#### TC-PR-N04: Invalid vendor_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set vendor_id=99999 (no vendor with this ID) | Invalid vendor |
| 2 | Load Payment Register | Empty result (no matching payments due to vendor FK constraint) |

#### TC-PR-N05: Invalid agreement_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set agreement_id=99999 (no agreement with this ID) | Invalid agreement |
| 2 | Load Payment Register | Empty result (no invoices match this agreement_id) |

#### TC-PR-N06: Invalid item_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_id=99999 (no item with this ID) | Invalid item |
| 2 | Load Payment Register | Empty result (no invoices match this item_id) |

#### TC-PR-N07: Invalid date range — from_date after to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date=2026-06-01, to_date=2026-01-01 (from > to) | Reversed dates |
| 2 | Load Payment Register | Carbon::parse handles both dates |
| 3 | Verify `whereBetween('payment_date', [June 1, Jan 1])` returns empty (logically impossible range) | Empty result |

#### TC-PR-N08: Invalid date format — non-date string supplied

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date="not-a-date" | Invalid format |
| 2 | Load Payment Register | Carbon::parse throws an exception (500 error) |
| 3 | Verify error is not gracefully handled (no try-catch in dates() helper) | Exception bubbles up |

#### TC-PR-N09: Future date range with no payments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date=2099-01-01, to_date=2099-12-31 | Future dates |
| 2 | Load Payment Register | No payments in future |
| 3 | Verify empty paymentRecords, zero summary, empty charts | Empty state across all outputs |

#### TC-PR-N10: Null payment_date in some records (filtered out by paymentChartDaily)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a VndPayment record with payment_date=NULL | Null date record |
| 2 | Load Payment Register — record appears in paymentRecords list | Record in list |
| 3 | Verify paymentChartDaily collection excludes null-date records (due to `->filter(fn($p) => $p->payment_date !== null)` before groupBy) | Null date excluded from chart |

### 10.3 Code Review TC Steps

#### TC-CR-P01: index() — Gate::authorize + tab routing + 5 report methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-report.viewAny')` at method start | Gate present |
| 2 | Review `$activeTab = $request->get('tab', 'vendor-ledger-summary')` — ledger tab is default | Tab routing |
| 3 | Review filter inputs extracted: vendor_id, agreement_id, item_id | Filter extraction |
| 4 | Review 5 private query methods called: getVendorLedgerSummaryData, getAgreementReportData, getInvoiceRegisterData, getOutstandingReportData, getPaymentRegisterData | 5 report methods |

#### TC-CR-P02: getPaymentRegisterData() — base query conditions (status, is_deleted, date range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndPayment::with(['vendor','invoice','paymentMode'])` | Eager loading |
| 2 | Review `where('vnd_payments.status', 'SUCCESS')` | Status filter |
| 3 | Review `where('vnd_payments.is_deleted', 0)` | Deleted flag filter |
| 4 | Review `whereBetween('vnd_payments.payment_date', [$from, $to])` | Date range filter |

#### TC-CR-P03: getPaymentRegisterData() — vendor/agreement/item filter logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review vendor_id filter: `$query->where('vendor_id', $request->vendor_id)` | Direct where |
| 2 | Review agreement_id filter: `whereHas('invoice', fn => where('agreement_id', ...))` | Through invoice |
| 3 | Review item_id filter: `whereHas('invoice', fn => where('agreement_item_id', ...))` | Through invoice |
| 4 | Review all 3 filters use when-filled — optional, combinable | Conditional filters |

#### TC-CR-P04: paymentSummary — avg_payment division-by-zero guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `'avg_payment' => $payments->count() > 0 ? round(..., 2) : 0` | Division guard present |
| 2 | Verify guard prevents DivisionByZeroError when no payments exist | Safe fallback |
| 3 | Verify round() to 2 decimal places | Precision correct |

#### TC-CR-P05: paymentSummary — largest_payment max() null coalesce

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `'largest_payment' => (float) ($payments->max('amount') ?? 0)` | Null coalesce |
| 2 | Verify max() on empty collection returns null, ?? 0 casts to 0.00 | Empty-safe |
| 3 | Verify (float) cast ensures numeric type | Type safety |

#### TC-CR-P06: paymentChartVendor — vendor_name fallback to 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$first->vendor->vendor_name ?? 'Unknown'` in paymentChartVendor map | Fallback present |
| 2 | Note: vendor relation is optional — a missing/soft-deleted vendor results in 'Unknown' label | Graceful fallback |

#### TC-CR-P07: paymentChartMode — paymentMode fallback to 'Unknown' via optional()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review groupBy key: `optional($p->paymentMode)->value ?? 'Unknown'` | Fallback present |
| 2 | Verify optional() helper prevents null error on missing paymentMode relation | Null-safe |
| 3 | Note: payment_mode FK is NOT NULL in DB, but relation may fail if FK refers to deleted dropdown | Edge case |

#### TC-CR-P08: paymentChartDaily — null payment_date filter before groupBy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->filter(fn($p) => $p->payment_date !== null)` before groupBy | Null filter present |
| 2 | Verify groupBy uses `$p->payment_date->format('Y-m-d')` — would fail on null without filter | Null-safe grouping |
| 3 | Verify sortBy on key 'Y-m-d' string ensures chronological order | Date ordering |

#### TC-CR-P09: paymentChartVendor — top 8 with sortByDesc + take(8)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review groupBy('vendor_id') → map → sortByDesc('total') → take(8) | Top 8 logic |
| 2 | Verify sortByDesc sorts by total amount descending before limiting | Correct ordering |
| 3 | Verify take(8) limits output to 8 vendors | Limit correct |

#### TC-CR-P10: Pagination — paginate(10) with page name 'payment_page' + appends()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `paginate(10, ['*'], 'payment_page')` | 10 per page, payment_page |
| 2 | Review `->appends($request->query())` | Query strings preserved |
| 3 | Verify `payment_page` is unique among all 5 report paginations (ledger_page, agreement_page, invoice_page, outstanding_page, payment_page) | Page name unique |
| 4 | Verify `orderByDesc('payment_date')` before paginate ensures consistent ordering | Deterministic pagination |

#### TC-CR-P11: Dependent dropdowns — getFilteredOptions() cascading logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review agreements branch: `VndAgreement::where('vendor_id', $vendorId)->get(['id','agreement_ref_no as text'])` | Agreements by vendor |
| 2 | Review items branch with agreement_id: `whereHas('agreementItems', fn => where('agreement_id', ...))` | Items by agreement |
| 3 | Review items branch with vendor_id only: `whereHas('agreementItems.agreement', fn => where('vendor_id', ...))` | Items by vendor |
| 4 | Review fallback: returns `response()->json([])` for unknown type | Empty fallback |

#### TC-CR-P12: dates() helper — default startOfMonth/endOfMonth fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$from = $r->filled('from_date') ? Carbon::parse(...) : now()->startOfMonth()` | From default |
| 2 | Review `$to = $r->filled('to_date') ? Carbon::parse(...) : now()->endOfMonth()` | To default |
| 3 | Review `->startOfDay()` and `->endOfDay()` applied to both | Time boundary |
| 4 | Note: No try-catch — invalid date strings cause unhandled exception | Exception gap |

### 10.4 Dependency TC Steps

#### TC-D-P01: FK vendor_id → vnd_vendors — records must exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndPayment has vendor_id referencing a vnd_vendors record | FK constraint |
| 2 | Attempt to insert VndPayment with vendor_id that doesn't exist in vnd_vendors | DB foreign key violation |

#### TC-D-P02: FK invoice_id → vnd_invoices — invoice must exist for agreement/item filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndPayment has invoice_id referencing a vnd_invoices record | FK constraint |
| 2 | VndInvoice must have agreement_id and agreement_item_id for agreement/item filters to work | Chained FK |
| 3 | agreement_id filter uses whereHas('invoice') → needs VndInvoice with matching agreement_id | Dependency chain |

#### TC-D-P03: FK payment_mode → sys_dropdown_table — mode value display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndPayment has payment_mode referencing sys_dropdown_table.id | FK constraint |
| 2 | paymentChartMode groups by `$p->paymentMode->value` (Dropdown model) | Value from dropdown |
| 3 | Missing/deleted dropdown record triggers 'Unknown' fallback via optional() | Graceful fallback |

#### TC-D-P04: Eager loading — with(['vendor','invoice','paymentMode']) confirmed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review query: `VndPayment::with(['vendor', 'invoice', 'paymentMode'])` | 3 eager loads |
| 2 | Verify vendor is used for vendor_name in chart and list display | Vendor relation |
| 3 | Verify paymentMode is used for paymentChartMode grouping | Payment mode relation |

#### TC-D-P05: SoftDelete + is_deleted — record with deleted_at non-null excluded from query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndPayment uses SoftDeletes trait | SoftDelete enabled |
| 2 | Query explicitly has `where('is_deleted', 0)` — legacy flag | Legacy filter |
| 3 | Soft-deleted record (deleted_at set) also would have is_deleted=1 in standard implementation | Dual exclusion |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-reports` | vendor-reports.index | index() | tenant.vendor-report.viewAny |
| GET | `/vendor-reports?tab=payment-register` | vendor-reports.index | index() (via getPaymentRegisterData) | tenant.vendor-report.viewAny |

**AJAX endpoints (via same route with special params):**
| Method | URL | Purpose |
|--------|-----|---------|
| GET | `/vendor-reports?get_options=agreements&vendor_id=X` | Cascading agreement dropdown |
| GET | `/vendor-reports?get_options=items&vendor_id=X&agreement_id=Y` | Cascading item dropdown |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-PR-01 | dates() helper lacks try-catch — invalid date strings cause 500 error | **Medium** | `Carbon::parse($r->from_date)` throws an exception if a non-date string is supplied; no graceful error handling in the helper method |
| KI-PR-02 | No exists validation on filter IDs | **Low** | vendor_id, agreement_id, item_id filters are applied directly without validating their existence; invalid IDs silently return empty results |
| KI-PR-03 | is_deleted flag is redundant with SoftDeletes | **Low** | VndPayment uses both SoftDeletes and a legacy `is_deleted` boolean column; query uses `where('is_deleted', 0)` but SoftDeletes already handles deleted record exclusion |
| KI-PR-04 | vendor relation accessed without null check in paymentChartVendor | **Medium** | `$first->vendor->vendor_name ?? 'Unknown'` relies on optional vendor relation — if vendor is deleted/relation broken, falls back to 'Unknown' silently |
| KI-PR-05 | paymentMode relation uses `optional()` but FK is NOT NULL | **Info** | `payment_mode` is a non-nullable FK, so the relation should always exist; optional() is defensive but masks potential data integrity issues |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Payment Register Tab | index() + getPaymentRegisterData() | VndPayment, Vendor, VndInvoice, Dropdown | 10 per page (payment_page) |
| Payment Summary | getPaymentRegisterData() | VndPayment (Collection) | None (6 KPIs) |
| Payment Chart — Mode | getPaymentRegisterData() | VndPayment, Dropdown | None (grouped) |
| Payment Chart — Daily | getPaymentRegisterData() | VndPayment | None (grouped by date) |
| Payment Chart — Vendor | getPaymentRegisterData() | VndPayment, Vendor | None (top 8) |
| Cascading Dropdowns | getFilteredOptions() | VndAgreement, VndItem | None (JSON response) |
