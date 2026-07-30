# vnd_Report_VendorLedger_TcList

## Module: Vendor → Reports → Vendor Ledger Summary

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Feature | Vendor Ledger Summary (Tab 1 of 5 in Vendor Reports) |
| URL(s) | `/vendor-reports` (single route renders all 5 report tabs) |
| Controller | `Modules\Vendor\Http\Controllers\VendorReportController` |
| Method | `index()` (public) → `getVendorLedgerSummaryData()` (private) |
| Model(s) | `Vendor`, `VndInvoice`, `VndPayment`, `VndAgreement`, `VndItem` |
| Validation | None — no FormRequest, no inline validation |
| Permission Gates | `tenant.vendor-report.viewAny` |
| Soft Deletes | Not directly used (queries filter `is_active` / `is_deleted` explicitly) |

---

## 2. Pre-conditions

- Required permission: `tenant.vendor-report.viewAny`
- At least one Vendor record in `vnd_vendors` with `is_active = 1`
- At least one Vendor Type in `sys_dropdown_table` (referenced by `vnd_vendors.vendor_type_id`)
- For invoice/payment computed fields: at least one `VndInvoice` with `is_active = true` and at least one `VndPayment` with `status = 'SUCCESS'` in the date range
- For `agreement_id` filter test: at least one `VndAgreement` record linked to a vendor
- For `item_id` filter (shared dropdown): at least one `VndItem` record linked via `VndAgreementItem`

---

## 3. Default Data Load

### 3.1 Shared Controller Data (index method)

The `index()` method initializes these for all 5 report tabs:

| Variable | Source | Description |
|----------|--------|-------------|
| `activeTab` | `$request->get('tab', 'vendor-ledger-summary')` | Active tab (defaults to ledger summary) |
| `fromDate` / `toDate` | `$this->dates($request)` | Default: start of month to end of month |
| `filters` | `$request->only(['vendor_id','agreement_id','item_id'])` | Filter associative array |
| `filterVendors` | `Vendor::active()->orderBy('vendor_name')->get()` | All active vendors for dropdown |
| `filterAgreements` | `VndAgreement::orderByDesc('id')` — gated by `vendor_id` | Agreement dropdown |
| `filterItems` | `VndItem::active()->orderBy('item_name')` — gated by `agreement_id` or `vendor_id` | Item dropdown |

### 3.2 `dates()` Helper

| Condition | from_date | to_date |
|-----------|-----------|---------|
| `filled('from_date')` | `Carbon::parse($r->from_date)->startOfDay()` | — |
| `!filled('from_date')` | `now()->startOfMonth()->startOfDay()` | — |
| `filled('to_date')` | — | `Carbon::parse($r->to_date)->endOfDay()` |
| `!filled('to_date')` | — | `now()->endOfMonth()->endOfDay()` |

### 3.3 `getFilteredOptions()` (AJAX endpoint)

| `get_options` value | Query | Response |
|---------------------|-------|----------|
| `agreements` | `VndAgreement::where('vendor_id', X)->orderByDesc('id')->get(['id', 'agreement_ref_no as text'])` | JSON array of `{id, text}` |
| `items` | `VndItem::active()->orderBy('item_name')` — scoped by `agreement_id` or `vendor_id` | JSON array of `{id, text}` |

### 3.4 Ledger Specific Data

| Variable | Source | Description |
|----------|--------|-------------|
| `ledgerVendors` | `Vendor::with(['vendorType','agreements'])` — paginated 10 per page, page name `ledger_page` | Vendor rows with computed fields |
| `ledgerSummary` | Aggregated from `VndInvoice` in date range | 7 summary metrics |
| `ledgerChartSpend` | Grouped by `vendorType` | Spend by vendor type |
| `ledgerChartOutstanding` | Top 5 vendors by `balance_due` | Outstanding by vendor |
| `ledgerChartMonthly` | Grouped by `Y-m` from `invoice_date` | Monthly trend |

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_vendors` — Vendor Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_name | VARCHAR(100) | NOT NULL | — | Unique vendor name |
| vendor_type_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| contact_person | VARCHAR(100) | NOT NULL | — | Contact person name |
| contact_number | VARCHAR(30) | NOT NULL | — | Contact number |
| email | VARCHAR(100) | YES | NULL | Email address |
| address | VARCHAR(512) | YES | NULL | Vendor address |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_vnd_vendor_name` (`vendor_name`)
- KEY `idx_vnd_vendor_type` (`vendor_type_id`)

### 4.2 `vnd_invoices` — Invoice Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| agreement_id | INT UNSIGNED | YES | NULL | FK → vnd_agreements(id) |
| agreement_item_id | INT UNSIGNED | YES | NULL | FK → vnd_agreement_items(id) |
| invoice_no | VARCHAR(50) | NOT NULL | — | Invoice number |
| invoice_date | DATE | NOT NULL | — | Invoice date |
| due_date | DATE | YES | NULL | Payment due date |
| net_payable | DECIMAL(15,2) | YES | 0.00 | Total invoice amount |
| amount_paid | DECIMAL(15,2) | YES | 0.00 | Amount paid |
| balance_due | DECIMAL(15,2) | YES | 0.00 | Remaining balance |
| tax_total | DECIMAL(15,2) | YES | 0.00 | Total tax |
| discount_amount | DECIMAL(15,2) | YES | 0.00 | Discount |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `idx_vnd_invoice_vendor` (`vendor_id`)
- KEY `idx_vnd_invoice_agreement` (`agreement_id`)
- KEY `idx_vnd_invoice_date` (`invoice_date`)

### 4.3 `vnd_payments` — Payment Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| invoice_id | INT UNSIGNED | YES | NULL | FK → vnd_invoices(id) |
| payment_date | DATE | NOT NULL | — | Payment date |
| amount | DECIMAL(15,2) | NOT NULL | — | Payment amount |
| status | VARCHAR(20) | NOT NULL | — | e.g. SUCCESS, FAILED, PENDING |
| payment_mode_id | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) |
| reconciled | TINYINT(1) | YES | 0 | Reconciliation flag |
| is_deleted | TINYINT(1) | YES | 0 | Soft delete flag (manual) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `idx_vnd_payment_vendor` (`vendor_id`)
- KEY `idx_vnd_payment_invoice` (`invoice_id`)
- KEY `idx_vnd_payment_date` (`payment_date`)

### 4.4 `sys_dropdown_table` — Dropdown Reference (for vendor_type / payment_mode)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| value | VARCHAR(255) | NOT NULL | — | Display value (e.g. "Individual", "Corporate") |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |

---

## 5. BC-VAL — Validation

| Aspect | Details |
|--------|---------|
| FormRequest | None — `VendorReportController` does not use a FormRequest |
| Inline Validation | None — no `$request->validate()` calls in `index()` or `getVendorLedgerSummaryData()` |
| Date Parsing | `Carbon::parse($r->from_date)` / `Carbon::parse($r->to_date)` — will throw `InvalidArgumentException` if invalid date string is passed |
| Filter Sanitization | Filters are passed directly from `$request->only(...)` with no sanitization |
| **Known Gap** | No validation that `vendor_id` / `agreement_id` / `item_id` exist — invalid IDs return empty results silently |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Model Policy |
|-----------------|-------------------|-------------|
| `tenant.vendor-report.viewAny` | `index()` via `Gate::authorize()` | Not used — direct Gate call |
| `get_vendor-ledger-summary` AJAX | No separate Gate — reuses `index()` Gate | Not used |
| `get_options` AJAX | No separate Gate — reuses `index()` Gate | Not used |

**Auth Behaviour:** `Gate::authorize('tenant.vendor-report.viewAny')` — if the user lacks this permission, a 403 Forbidden `AuthorizationException` is thrown.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-VLR-01 | Single Route / Multi-Tab Reports | `GET /vendor-reports` → `index()` renders all 5 report tabs in a single view; active tab defaults to `vendor-ledger-summary` |
| BC-BIZ-VLR-02 | Shared Filter State | All 5 tabs share the same `from_date`, `to_date`, `vendor_id`, `agreement_id`, `item_id` filters and dropdown data |
| BC-BIZ-VLR-03 | Default Date Range | `dates()` defaults `from_date` to `now()->startOfMonth()` and `to_date` to `now()->endOfMonth()` when not provided |
| BC-BIZ-VLR-04 | Vendor Query Eager Loading | `getVendorLedgerSummaryData()` eager-loads `vendorType` and `agreements` relations via `Vendor::with()` |
| BC-BIZ-VLR-05 | Invoice Scoping — Active + Date Range | Invoice sub-query filters `vnd_invoices.is_active = true` AND `invoice_date BETWEEN from_date AND to_date` |
| BC-BIZ-VLR-06 | Payment Scoping — SUCCESS + Date Range | Payment sub-query filters `vnd_payments.status = 'SUCCESS'` AND `payment_date BETWEEN from_date AND to_date` |
| BC-BIZ-VLR-07 | Agreement Filter on Invoice Sub-Query | When `agreement_id` filter is set, the per-vendor invoice sub-query is additionally scoped `where('agreement_id', $request->agreement_id)` |
| BC-BIZ-VLR-08 | Computed Field — `total_invoices` | Count of active invoices in date range per vendor |
| BC-BIZ-VLR-09 | Computed Field — `total_invoice_amount` | Sum of `net_payable` from active invoices in date range |
| BC-BIZ-VLR-10 | Computed Field — `total_paid_amount` | Sum of `amount_paid` from active invoices in date range |
| BC-BIZ-VLR-11 | Computed Field — `total_outstanding_amount` | Sum of `balance_due` from active invoices in date range |
| BC-BIZ-VLR-12 | Computed Field — `overdue_amount` | Sum of `balance_due` where `balance_due > 0` AND `due_date IS NOT NULL` AND `due_date < now()` |
| BC-BIZ-VLR-13 | Computed Field — `collection_rate` | `(sum(amount_paid) / sum(net_payable)) * 100`, rounded to 1 decimal; returns `0` when `net_payable == 0` |
| BC-BIZ-VLR-14 | Computed Field — `last_invoice_date` | Most recent `invoice_date` from invoices in date range, formatted `d M Y`; returns `—` if no invoices |
| BC-BIZ-VLR-15 | Computed Field — `last_payment_date` | Most recent `payment_date` from SUCCESS payments in date range, formatted `d M Y`; returns `—` if no payments |
| BC-BIZ-VLR-16 | Summary — `total_vendors` | Distinct vendor count matching the vendor query (with filters applied) |
| BC-BIZ-VLR-17 | Summary — `active_vendors` | Count of vendors where `is_active = true` (from the same filtered vendor query) |
| BC-BIZ-VLR-18 | Summary — Aggregated Totals | `total_invoiced`, `total_paid`, `total_outstanding`, `total_overdue` computed from ALL invoices in date range (not per-vendor) |
| BC-BIZ-VLR-19 | Summary — `collection_rate` | Same formula as per-vendor but computed across all invoices in date range |
| BC-BIZ-VLR-20 | Chart — `ledgerChartSpend` | Grouped by `vendorType.value`; returns type, spend (sum net_payable), paid (sum amount_paid), count |
| BC-BIZ-VLR-21 | Chart — `ledgerChartOutstanding` | Top 5 vendors by `balance_due` (filtered to invoices with `balance_due > 0`), sorted descending |
| BC-BIZ-VLR-22 | Chart — `ledgerChartMonthly` | Grouped by `Y-m` from `invoice_date`; shows month label, invoiced, paid, count; sorted chronologically |
| BC-BIZ-VLR-23 | Filter — `vendor_id` | Scopes the Vendor query to `WHERE id = vendor_id` and all invoice/aggregation queries |
| BC-BIZ-VLR-24 | Filter — `agreement_id` | Scopes the Vendor query via `whereHas('agreements', id = agreement_id)`; also scopes per-vendor invoice sub-query |
| BC-BIZ-VLR-25 | Filtered Options AJAX — Dependent Dropdowns | `getFilteredOptions` returns agreements by vendor_id, items by agreement_id (or vendor_id if no agreement_id), used for cascading UI dropdowns |
| BC-BIZ-VLR-26 | Pagination — `ledger_page` | `getVendorLedgerSummaryData` paginates at 10 per page with page name `ledger_page`; `appends($request->query())` preserves query string |
| BC-BIZ-VLR-27 | Vendor Status Mapping | Per-vendor `status` field maps `is_active` boolean to "Active" / "Inactive" string |
| BC-BIZ-VLR-28 | Null Vendor Type Handling | `vendor_type` computed field uses `optional($vendor->vendorType)->value ?? 'N/A'` — handles missing/dangling FK gracefully |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_invoice_vendor | vnd_invoices.vendor_id | vnd_vendors.id | CASCADE |
| fk_vnd_invoice_agreement | vnd_invoices.agreement_id | vnd_agreements.id | SET NULL |
| fk_vnd_payment_vendor | vnd_payments.vendor_id | vnd_vendors.id | CASCADE |
| fk_vnd_payment_invoice | vnd_payments.invoice_id | vnd_invoices.id | SET NULL |
| fk_vnd_vendor_type | vnd_vendors.vendor_type_id | sys_dropdown_table.id | RESTRICT |

---

## 9. Test Case Summary

### 9.1 Vendor Ledger Summary — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VLR-P01 | Reports Access | Positive | Page loads with default `vendor-ledger-summary` tab, no filters | 3 |
| TC-VLR-P02 | Reports Access | Positive | Page loads with explicit tab query parameter | 3 |
| TC-VLR-P03 | Default Date Range | Positive | Default from_date = start of month, to_date = end of month when not provided | 3 |
| TC-VLR-P04 | Vendor Filter | Positive | Filter by single `vendor_id` returns only that vendor in ledger | 4 |
| TC-VLR-P05 | Agreement Filter | Positive | Filter by `agreement_id` returns only vendors with that agreement | 4 |
| TC-VLR-P06 | Vendor + Agreement Combined | Positive | Both `vendor_id` and `agreement_id` applied together | 4 |
| TC-VLR-P07 | Date Range Filter | Positive | Custom `from_date` / `to_date` scopes invoice and payment data | 4 |
| TC-VLR-P08 | Pagination | Positive | Paginate ledger vendors with `ledger_page` parameter, 10 per page | 4 |
| TC-VLR-P09 | Pagination — Page 2 | Positive | `ledger_page=2` returns next 10 vendors | 4 |
| TC-VLR-P10 | Computed Field — `total_invoices` | Positive | Vendor with invoices in date range shows correct count | 4 |
| TC-VLR-P11 | Computed Field — `total_invoice_amount` | Positive | Sum of `net_payable` matches expected | 4 |
| TC-VLR-P12 | Computed Field — `total_paid_amount` | Positive | Sum of `amount_paid` matches from invoices in date range | 4 |
| TC-VLR-P13 | Computed Field — `total_outstanding_amount` | Positive | Sum of `balance_due` from invoices matches | 4 |
| TC-VLR-P14 | Computed Field — `overdue_amount` | Positive | Only invoices with `balance_due > 0` AND `due_date` in past are counted | 5 |
| TC-VLR-P15 | Computed Field — `collection_rate` | Positive | Collection rate = `(amount_paid / net_payable) * 100`, rounded to 1 decimal | 4 |
| TC-VLR-P16 | Computed Field — `last_invoice_date` | Positive | Most recent `invoice_date` formatted `d M Y` | 4 |
| TC-VLR-P17 | Computed Field — `last_payment_date` | Positive | Most recent SUCCESS `payment_date` formatted `d M Y` | 4 |
| TC-VLR-P18 | Computed Field — `total_agreements` | Positive | Count of all related agreements from eager-loaded relation | 3 |
| TC-VLR-P19 | Computed Field — `active_agreements` | Positive | Count of agreements with `status = 'ACTIVE'` | 3 |
| TC-VLR-P20 | Computed Field — `vendor_type` | Positive | `vendorType.value` displayed; falls back to `'N/A'` if null | 3 |
| TC-VLR-P21 | Computed Field — `status` | Positive | Maps `is_active=1` to "Active", `is_active=0` to "Inactive" | 3 |
| TC-VLR-P22 | Summary — `total_vendors` | Positive | Vendor count matching filtered query | 3 |
| TC-VLR-P23 | Summary — `active_vendors` | Positive | Count of vendors where `is_active = true` | 3 |
| TC-VLR-P24 | Summary — `total_invoiced` | Positive | Sum of `net_payable` across all active invoices in date range | 3 |
| TC-VLR-P25 | Summary — `total_paid` | Positive | Sum of `amount_paid` across all active invoices in date range | 3 |
| TC-VLR-P26 | Summary — `total_outstanding` | Positive | Sum of `balance_due` across all active invoices in date range | 3 |
| TC-VLR-P27 | Summary — `total_overdue` | Positive | Sum of `balance_due` where `balance_due > 0` AND `due_date` in past | 4 |
| TC-VLR-P28 | Summary — `collection_rate` | Positive | Overall collection rate across all invoices | 3 |
| TC-VLR-P29 | Chart — `ledgerChartSpend` | Positive | Grouped by vendorType with spend, paid, count | 4 |
| TC-VLR-P30 | Chart — `ledgerChartOutstanding` | Positive | Top 5 vendors by `balance_due`, sorted descending | 4 |
| TC-VLR-P31 | Chart — `ledgerChartMonthly` | Positive | Monthly group by `Y-m` with invoiced, paid, count, sorted chronologically | 4 |
| TC-VLR-P32 | AJAX — Filtered Options Agreements | Positive | `get_options=agreements&vendor_id=X` returns agreements for vendor | 3 |
| TC-VLR-P33 | AJAX — Filtered Options Items by Agreement | Positive | `get_options=items&agreement_id=X` returns items for agreement | 3 |
| TC-VLR-P34 | AJAX — Filtered Options Items by Vendor | Positive | `get_options=items&vendor_id=X` (no agreement_id) returns items for vendor | 3 |
| TC-VLR-P35 | Filter Dropdown — `filterVendors` | Positive | Dropdown contains all active vendors ordered by `vendor_name` | 2 |
| TC-VLR-P36 | Filter Dropdown — `filterAgreements` | Positive | Dropdown scoped by selected `vendor_id` via AJAX | 3 |
| TC-VLR-P37 | Filter Dropdown — `filterItems` | Positive | Dropdown scoped by selected `agreement_id` or `vendor_id` via AJAX | 3 |
| TC-VLR-P38 | Date Range — Same Day | Positive | `from_date = to_date` returns only invoices/payments on that day | 4 |
| TC-VLR-P39 | Multiple Vendors with Data | Positive | All vendors with invoices in date range appear in ledger list | 4 |
| TC-VLR-P40 | Eager Loading Verification | Positive | `vendorType` and `agreements` relations eager-loaded (no N+1 for these) | 2 |
| TC-VLR-P41 | Collection Rate — 100% | Positive | All invoices fully paid → collection_rate = 100.0 | 3 |
| TC-VLR-P42 | Collection Rate — 0% | Positive | No payments made → collection_rate = 0 | 3 |
| TC-VLR-P43 | Collection Rate — Partial | Positive | 50% paid → collection_rate = 50.0 | 4 |
| TC-VLR-P44 | Collection Rate — Rounding | Positive | Rate rounded to 1 decimal (e.g. 33.333... → 33.3) | 4 |
| TC-VLR-P45 | Overdue — Zero Balance | Positive | Invoice with `balance_due = 0` and past `due_date` NOT counted as overdue | 4 |
| TC-VLR-P46 | Overdue — No Due Date | Positive | Invoice with `balance_due > 0` but `due_date = NULL` NOT counted as overdue | 4 |
| TC-VLR-P47 | Overdue — Future Due Date | Positive | Invoice with `balance_due > 0` but future `due_date` NOT counted as overdue | 4 |
| TC-VLR-P48 | Overdue — Past Due + Balance | Positive | Invoice with `balance_due > 0` and past `due_date` IS counted as overdue | 3 |
| TC-VLR-P49 | Last Invoice Date — No Invoices | Positive | Vendor with no invoices → `last_invoice_date = '—'` | 3 |
| TC-VLR-P50 | Last Payment Date — No Payments | Positive | Vendor with no SUCCESS payments → `last_payment_date = '—'` | 3 |
| TC-VLR-P51 | last_invoice_date Format | Positive | Returns `d M Y` format (e.g. "15 Jan 2026") | 3 |
| TC-VLR-P52 | last_payment_date Format | Positive | Returns `d M Y` format (e.g. "20 Mar 2026") | 3 |
| TC-VLR-P53 | Chart Outstanding — Fewer Than 5 | Positive | Only 2 vendors with `balance_due > 0` → chart shows 2 entries | 3 |
| TC-VLR-P54 | Chart Outstanding — Exactly 5 | Positive | 5 vendors shown when available | 3 |
| TC-VLR-P55 | Chart Monthly — Empty Month | Positive | Months with no invoices do not appear in chart data | 2 |
| TC-VLR-P56 | Chart Monthly — Sorting | Positive | Months sorted chronologically ascending | 3 |
| TC-VLR-P57 | Chart Spend — Multiple Vendor Types | Positive | Each vendor type has its own entry | 4 |
| TC-VLR-P58 | AJAX — getFilteredOptions agreements | Positive | get_options=agreements&vendor_id=X returns agreements filtered by vendor | 3 |
| TC-VLR-P59 | AJAX — getFilteredOptions items | Positive | get_options=items filtered by agreement_id or vendor_id fallback | 5 |

### 9.2 Vendor Ledger Summary — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VLR-N01 | Auth | Negative | Access without `tenant.vendor-report.viewAny` → 403 Forbidden | 2 |
| TC-VLR-N02 | Date — Invalid from_date | Negative | `from_date=invalid-date` → 500 error (Carbon parse exception) | 2 |
| TC-VLR-N03 | Date — Invalid to_date | Negative | `to_date=invalid-date` → 500 error (Carbon parse exception) | 2 |
| TC-VLR-N04 | Date — from_date after to_date | Negative | `from_date` after `to_date` → returns empty result | 3 |
| TC-VLR-N05 | Filter — Non-existent vendor_id | Negative | `vendor_id=99999` → empty ledger list | 3 |
| TC-VLR-N06 | Filter — Non-existent agreement_id | Negative | `agreement_id=99999` → empty ledger list | 3 |
| TC-VLR-N07 | Filter — Non-existent item_id | Negative | `item_id=99999` → ignored (item_id not used in ledger query) | 2 |
| TC-VLR-N08 | Empty Data — No Vendors | Negative | No vendors exist → empty ledger list, summary all zero | 3 |
| TC-VLR-N09 | Empty Data — No Invoices in Date Range | Negative | All computed fields zero, collection_rate = 0, no chart data | 4 |
| TC-VLR-N10 | Empty Data — No SUCCESS Payments | Negative | `last_payment_date = '—'`, `total_paid_amount = 0`, collection_rate = 0 | 4 |
| TC-VLR-N11 | Pagination — Negative Page | Negative | `ledger_page=-1` → defaulted to page 1 | 2 |
| TC-VLR-N12 | Pagination — Out of Range Page | Negative | `ledger_page=999` → empty page | 2 |
| TC-VLR-N13 | Pagination — Non-numeric Page | Negative | `ledger_page=abc` → defaulted to page 1 | 2 |
| TC-VLR-N14 | Date Range — No from_date | Negative | Only `to_date` provided → from_date defaults to start of month | 3 |
| TC-VLR-N15 | Date Range — No to_date | Negative | Only `from_date` provided → to_date defaults to end of month | 3 |
| TC-VLR-N16 | Filter Options — No vendor_id for agreements | Negative | `get_options=agreements` without `vendor_id` → returns empty array | 2 |
| TC-VLR-N17 | Filter Options — Invalid type | Negative | `get_options=invalid` → returns empty JSON array `[]` | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-VLR01 | Code Review | Review | `index()` — `Gate::authorize()` with single permission `tenant.vendor-report.viewAny` | 2 |
| TC-CR-VLR02 | Code Review | Review | `index()` — AJAX `get_options` handled before main view rendering | 4 |
| TC-CR-VLR03 | Code Review | Review | `dates()` — default date range logic (startOfMonth / endOfMonth) | 4 |
| TC-CR-VLR04 | Code Review | Review | `dates()` — Carbon::parse without try-catch throws on invalid input | 3 |
| TC-CR-VLR05 | Code Review | Review | `getVendorLedgerSummaryData()` — eager loading `vendorType` and `agreements` | 3 |
| TC-CR-VLR06 | Code Review | Review | `getVendorLedgerSummaryData()` — per-vendor invoice query N+1 risk | 3 |
| TC-CR-VLR07 | Code Review | Review | Per-vendor `collection_rate` — division by zero handled (returns 0) | 3 |
| TC-CR-VLR08 | Code Review | Review | Summary `collection_rate` — division by zero handled (returns 0) | 3 |
| TC-CR-VLR09 | Code Review | Review | `overdue_amount` — triple condition `balance_due > 0 && due_date !== null && due_date->isPast()` | 4 |
| TC-CR-VLR10 | Code Review | Review | `ledgerChartOutstanding` — `filter(balance_due > 0)` before groupBy, top 5 via `take(5)` | 4 |
| TC-CR-VLR11 | Code Review | Review | `ledgerChartMonthly` — `filter(invoice_date !== null)`, group by `Y-m`, sort by key | 4 |
| TC-CR-VLR12 | Code Review | Review | Pagination — uses `paginate(10, ['*'], 'ledger_page')` with distinct page name | 3 |
| TC-CR-VLR13 | Code Review | Review | Pagination — `appends($request->query())` preserves query string | 2 |
| TC-CR-VLR14 | Code Review | Review | `total_vendors` — calls `$vendorQuery->count()` after filter mutation | 3 |
| TC-CR-VLR15 | Code Review | Review | `active_vendors` — uses `$vendorQuery->clone()->where('is_active', true)->count()` (Laravel 6 may not have `clone()`) | 3 |
| TC-CR-VLR16 | Code Review | Review | `last_invoice_date` — `sortByDesc('invoice_date')->first()?->invoice_date?->format('d M Y') ?? '—'` null-safe pattern | 4 |
| TC-CR-VLR17 | Code Review | Review | `last_payment_date` — queries payments, not invoices (correctly sourced from payment query) | 3 |
| TC-CR-VLR18 | Code Review | Review | Agreement filter cascaded into per-vendor invoice sub-query (`$invQ->where('agreement_id')`) | 3 |
| TC-CR-VLR19 | Code Review | Review | No validation on any filter input — invalid IDs silently return empty | 3 |
| TC-CR-VLR20 | Code Review | Review | `getFilteredOptions` — `return response()->json([])` fallback for unknown type | 2 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-VLR01 | Dependency | Dependency | Vendor type FK → sys_dropdown_table — missing/soft-deleted type renders as 'N/A' | 3 |
| TC-D-VLR02 | Dependency | Dependency | Invoice vendor_id FK → vnd_vendors — orphaned invoice excluded if vendor deleted | 3 |
| TC-D-VLR03 | Dependency | Dependency | Payment status = 'SUCCESS' — other statuses (FAILED, PENDING) excluded from all calculations | 3 |
| TC-D-VLR04 | Dependency | Dependency | Invoice `is_active = true` — inactive invoices excluded | 3 |
| TC-D-VLR05 | Dependency | Dependency | Payment `is_deleted = 0` — deleted payments excluded | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Vendor Ledger Summary

#### TC-VLR-P01: Page loads with default vendor-ledger-summary tab, no filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-report.viewAny` navigates to `GET /vendor-reports` | Page loads, 200 OK |
| 2 | Verify `activeTab` defaults to `vendor-ledger-summary` | Ledger summary tab is active |
| 3 | Verify ledger vendor list, summary cards, and chart sections are rendered | All sections visible |

#### TC-VLR-P02: Page loads with explicit tab query parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `GET /vendor-reports?tab=vendor-ledger-summary` | Page loads with ledger summary tab |
| 2 | Verify tab query parameter is read and passed to view | Tab correctly identified |
| 3 | Verify other tabs (agreement, invoice, etc.) are also present in the rendered view | Multi-tab view intact |

#### TC-VLR-P03: Default date range = start of month to end of month

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports` with no `from_date` or `to_date` | Page loads |
| 2 | Verify `fromDate` in view equals `now()->startOfMonth()->startOfDay()` | Default from_date applied |
| 3 | Verify `toDate` equals `now()->endOfMonth()->endOfDay()` | Default to_date applied |

#### TC-VLR-P04: Filter by single vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Vendor A from dropdown (vendor_id = X) | Filter applied |
| 2 | Request `GET /vendor-reports?vendor_id=X` | Page loads |
| 3 | Verify `ledgerVendors` contains only Vendor A | Filtered to single vendor |
| 4 | Verify summary data and charts scoped to Vendor A | All data scoped |

#### TC-VLR-P05: Filter by agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement X belongs to Vendor A | Seed data |
| 2 | Request `GET /vendor-reports?agreement_id=X` | Page loads |
| 3 | Verify only Vendor A appears in ledger list (vendor has this agreement via `whereHas`) | Filtered by agreement |
| 4 | Verify per-vendor invoice sub-query also scoped to `agreement_id = X` | Invoices scoped |

#### TC-VLR-P06: Both vendor_id and agreement_id combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has Agreement X; Vendor B also has Agreement X | Seed data |
| 2 | Request `GET /vendor-reports?vendor_id=A&agreement_id=X` | Page loads |
| 3 | Verify only Vendor A appears (vendor_id AND agreement_id intersection) | Combined filter |
| 4 | Verify per-vendor invoice query also scoped to `agreement_id = X` | Both filters applied |

#### TC-VLR-P07: Custom date range scopes invoice and payment data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `from_date=2026-01-01&to_date=2026-03-31` | Custom range |
| 2 | Request page with these dates | Page loads |
| 3 | Verify invoice query scoped to `invoice_date BETWEEN 2026-01-01 AND 2026-03-31` | Invoices in range |
| 4 | Verify payment query scoped to `payment_date BETWEEN 2026-01-01 AND 2026-03-31` | Payments in range |

#### TC-VLR-P08: Paginate ledger vendors with ledger_page parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have 12+ vendors with data | Seed data |
| 2 | Request `GET /vendor-reports` (no page param) | First 10 vendors returned |
| 3 | Verify `ledgerVendors` has 10 items | Pagination at 10 per page |
| 4 | Verify pagination links present with `ledger_page` query param | Links use correct page name |

#### TC-VLR-P09: ledger_page=2 returns next 10 vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have 12+ vendors with data | Seed data |
| 2 | Request `GET /vendor-reports?ledger_page=2` | Page 2 loads |
| 3 | Verify `ledgerVendors` contains vendors 11–12 (2 items on last page) | 2 items on page 2 |
| 4 | Verify pagination links preserved in URL | URL has `ledger_page=2` |

#### TC-VLR-P10: total_invoices computed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has 5 active invoices with `invoice_date` in date range, 2 inactive invoices | Seed data |
| 2 | Request page with matching date range | Page loads |
| 3 | Verify Vendor A's `total_invoices = 5` (active only) | Correct count |
| 4 | Verify inactive invoices excluded from count | Excluded |

#### TC-VLR-P11: total_invoice_amount computed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has 3 invoices: net_payable = 1000, 2000, 3000 | Seed data |
| 2 | All invoices within date range and active | Seeds valid |
| 3 | Verify `total_invoice_amount = 6000.00` | Sum correct |
| 4 | Ensure invoices outside date range excluded | Excluded |

#### TC-VLR-P12: total_paid_amount computed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A invoices have amount_paid = 500, 1500, 2500 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `total_paid_amount = 4500.00` | Sum correct |

#### TC-VLR-P13: total_outstanding_amount computed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A invoices have balance_due = 500, 500, 500 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `total_outstanding_amount = 1500.00` | Sum of balance_due |

#### TC-VLR-P14: overdue_amount only counts past due with balance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice A: balance_due=500, due_date=past (2024-01-01) | Overdue |
| 2 | Invoice B: balance_due=0, due_date=past (2024-01-01) | NOT counted (balance=0) |
| 3 | Invoice C: balance_due=500, due_date=NULL | NOT counted (no due date) |
| 4 | Invoice D: balance_due=500, due_date=future (2027-01-01) | NOT counted (future) |
| 5 | Verify `overdue_amount = 500.00` | Only Invoice A counted |

#### TC-VLR-P15: collection_rate = (amount_paid / net_payable) * 100

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: net_payable = 10000, amount_paid = 7500 | 75% rate |
| 2 | Request page | Page loads |
| 3 | Verify `collection_rate = 75.0` | Rounded to 1 decimal |
| 4 | Confirm formula: (7500 / 10000) * 100 = 75.0 | Correct |

#### TC-VLR-P16: last_invoice_date = most recent invoice_date in range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A invoices: 05 Jan 2026, 15 Mar 2026, 20 Feb 2026 | Seed data |
| 2 | Request page with range covering all three | Page loads |
| 3 | Verify `last_invoice_date = "15 Mar 2026"` | Most recent date |
| 4 | Verify format is `d M Y` | Format correct |

#### TC-VLR-P17: last_payment_date = most recent SUCCESS payment_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has SUCCESS payments on: 10 Jan 2026, 25 Feb 2026 | Seed data |
| 2 | Also has a FAILED payment on 01 Mar 2026 (excluded) | Excluded from query |
| 3 | Request page | Page loads |
| 4 | Verify `last_payment_date = "25 Feb 2026"` | Most recent SUCCESS date |

#### TC-VLR-P18: total_agreements from eager-loaded relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has 4 agreements (any status) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `total_agreements = 4` | Count from relation |

#### TC-VLR-P19: active_agreements count with status=ACTIVE

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has 4 agreements: 2 ACTIVE, 1 DRAFT, 1 EXPIRED | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `active_agreements = 2` | Only ACTIVE counted |

#### TC-VLR-P20: vendor_type from vendorType relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has vendor_type_id → dropdown with value "Corporate" | Seed data |
| 2 | Vendor B has vendor_type_id = NULL (no type set) | Null type |
| 3 | Verify Vendor A `vendor_type = "Corporate"` | Value from relation |
| 4 | Verify Vendor B `vendor_type = "N/A"` | Fallback for null |

#### TC-VLR-P21: status mapped from is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: is_active = 1 | Active vendor |
| 2 | Vendor B: is_active = 0 | Inactive vendor |
| 3 | Verify Vendor A `status = "Active"` | Mapped correctly |
| 4 | Verify Vendor B `status = "Inactive"` | Mapped correctly |

#### TC-VLR-P22: total_vendors summary count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 8 vendors match the vendor query (with filters) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.total_vendors = 8` | All matching vendors counted |

#### TC-VLR-P23: active_vendors summary count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Of 8 matching vendors, 6 have is_active = true | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.active_vendors = 6` | Only active counted |

#### TC-VLR-P24: total_invoiced summary = sum of net_payable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All active invoices in date range have net_payable = 50000 total | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.total_invoiced = 50000.00` | Sum correct |

#### TC-VLR-P25: total_paid summary = sum of amount_paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All active invoices have amount_paid = 35000 total | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.total_paid = 35000.00` | Sum correct |

#### TC-VLR-P26: total_outstanding summary = sum of balance_due

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All active invoices have balance_due = 15000 total | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.total_outstanding = 15000.00` | Sum of balance_due |

#### TC-VLR-P27: total_overdue summary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Overdue invoices (balance_due>0, due_date past, due_date not null) have balance_due = 8000 total | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.total_overdue = 8000.00` | Overdue sum correct |
| 4 | Verify invoices with future due date or zero balance excluded | Excluded |

#### TC-VLR-P28: summary collection_rate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Total net_payable = 50000, total amount_paid = 35000 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerSummary.collection_rate = 70.0` | (35000/50000)*100 = 70.0 |

#### TC-VLR-P29: ledgerChartSpend grouped by vendorType

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist for Corporate type (net_payable=30000) and Individual type (net_payable=20000) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify chart has 2 entries, one per vendor type | Correct groups |
| 4 | Verify each entry has type, spend, paid, count fields | Structure correct |

#### TC-VLR-P30: ledgerChartOutstanding top 5 by balance_due

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 7 vendors have invoices with balance_due > 0 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify chart has 5 entries (only top 5) | Limited to 5 |
| 4 | Verify entries sorted descending by outstanding amount | Sort order correct |

#### TC-VLR-P31: ledgerChartMonthly grouped by Y-m

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist in Jan 2026, Feb 2026, Mar 2026 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify 3 monthly entries with month label, invoiced, paid, count | Monthly breakdown |
| 4 | Verify entries sorted chronologically by month key | Sort order correct |

#### TC-VLR-P32: AJAX get_options=agreements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements: AR-001, AR-002 | Seed data |
| 2 | Request `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX response |
| 3 | Verify JSON array with 2 objects each having `id` and `text` fields | Correct response |

#### TC-VLR-P33: AJAX get_options=items by agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement Y has 3 items via VndAgreementItem: Item A, Item B, Item C | Seed data |
| 2 | Request `GET /vendor-reports?get_options=items&agreement_id=Y` | AJAX response |
| 3 | Verify JSON array with 3 items each having `id` and `text` fields | Correct response |

#### TC-VLR-P34: AJAX get_options=items by vendor_id only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor Z has items via AgreementItems → Agreement: Item P, Item Q | Seed data |
| 2 | Request `GET /vendor-reports?get_options=items&vendor_id=Z` (no agreement_id) | AJAX response |
| 3 | Verify JSON array with items linked to vendor Z | Correct response |

#### TC-VLR-P35: filterVendors dropdown contains all active vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 active vendors exist, 1 inactive vendor | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `filterVendors` has 5 vendors ordered by `vendor_name` | All active, sorted |

#### TC-VLR-P36: filterAgreements dropdown scoped by vendor_id via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has 3 agreements, Vendor B has 2 agreements | Seed data |
| 2 | Select Vendor A in dropdown → AJAX call triggered | Agreements loaded |
| 3 | Verify only Vendor A's 3 agreements returned | Scoped correctly |

#### TC-VLR-P37: filterItems dropdown scoped by agreement/vendor via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement X has 4 items via agreementItems | Seed data |
| 2 | Select Agreement X → AJAX call with agreement_id | Items returned |
| 3 | Verify only items linked through agreement's agreementItems | Scoped correctly |

#### TC-VLR-P38: from_date = to_date (single day)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist on 15 Jan 2026 and other dates | Seed data |
| 2 | Request `GET /vendor-reports?from_date=2026-01-15&to_date=2026-01-15` | Page loads |
| 3 | Verify only invoices with invoice_date = 2026-01-15 returned | Single day filter |
| 4 | Verify payments also scoped to same single day | Payments scoped |

#### TC-VLR-P39: Multiple vendors with data all appear

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 8 vendors each have at least 1 invoice in date range | Seed data |
| 2 | Request page with no vendor filter | Page loads |
| 3 | Verify all 8 vendors appear in paginated ledger list | All vendors shown |
| 4 | Verify each vendor has computed fields populated | Individual calculations |

#### TC-VLR-P40: Eager loading avoids N+1 for vendorType and agreements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable query log | DB logging |
| 2 | Request page with 10+ vendors | 1 query: Vendor::with(['vendorType','agreements']) |
| 3 | Verify only 1 query fetches vendors with both relations | No N+1 for vendorType or agreements |

#### TC-VLR-P41: Collection rate = 100% when fully paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: net_payable = 10000, amount_paid = 10000 (all invoices fully paid) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `collection_rate = 100.0` | Full collection |

#### TC-VLR-P42: Collection rate = 0% when nothing paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: net_payable = 10000, amount_paid = 0 (no payments) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `collection_rate = 0` | Zero collection |

#### TC-VLR-P43: Collection rate = 50% when half paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: net_payable = 10000, amount_paid = 5000 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `collection_rate = 50.0` | Half collected |

#### TC-VLR-P44: Collection rate rounded to 1 decimal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A: net_payable = 3000, amount_paid = 1000 (33.333...%) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `collection_rate = 33.3` | Rounded to 1 decimal |

#### TC-VLR-P45: Overdue with balance_due = 0 is NOT counted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice with balance_due = 0, due_date in past | Fully paid, not overdue |
| 2 | Request page | Page loads |
| 3 | Verify overdue_amount does NOT include this invoice | Excluded |

#### TC-VLR-P46: Overdue with NULL due_date is NOT counted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice with balance_due = 500, due_date = NULL | No due date set |
| 2 | Request page | Page loads |
| 3 | Verify overdue_amount does NOT include this invoice | Excluded |

#### TC-VLR-P47: Overdue with future due_date is NOT counted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice with balance_due = 500, due_date in 2027 (future) | Not yet due |
| 2 | Request page | Page loads |
| 3 | Verify overdue_amount does NOT include this invoice | Excluded |

#### TC-VLR-P48: Overdue with past due_date and balance > 0 IS counted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice with balance_due = 500, due_date in 2024 (past) | Genuinely overdue |
| 2 | Request page | Page loads |
| 3 | Verify overdue_amount = 500.00 | Included |

#### TC-VLR-P49: No invoices → last_invoice_date = '—'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has zero invoices in date range | Empty invoice set |
| 2 | Request page | Page loads |
| 3 | Verify `last_invoice_date = '—'` | Dash placeholder |

#### TC-VLR-P50: No SUCCESS payments → last_payment_date = '—'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has no SUCCESS payments in date range | Empty payment set |
| 2 | Request page | Page loads |
| 3 | Verify `last_payment_date = '—'` | Dash placeholder |

#### TC-VLR-P51: last_invoice_date format d M Y

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A most recent invoice_date = 2026-01-05 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `last_invoice_date = "05 Jan 2026"` | Format d M Y |

#### TC-VLR-P52: last_payment_date format d M Y

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A most recent SUCCESS payment_date = 2026-03-20 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `last_payment_date = "20 Mar 2026"` | Format d M Y |

#### TC-VLR-P53: Chart outstanding — fewer than 5 vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only 2 vendors have invoices with balance_due > 0 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerChartOutstanding` has exactly 2 entries | 2 items only |

#### TC-VLR-P54: Chart outstanding — exactly 5 vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | 5 vendors have invoices with balance_due > 0 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerChartOutstanding` has exactly 5 entries | 5 items |

#### TC-VLR-P55: Chart monthly — months with no data omitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist in Jan 2026 and Mar 2026 but NOT in Feb 2026 | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify Feb 2026 is NOT in `ledgerChartMonthly` | Empty months excluded |

#### TC-VLR-P56: Chart monthly — sorted chronologically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist in Mar 2026, Jan 2026, Feb 2026 (out of order) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify order: Jan 2026, Feb 2026, Mar 2026 | Sorted ascending |

#### TC-VLR-P57: Chart spend — multiple vendor types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist for "Corporate", "Individual", and "Government" vendor types | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerChartSpend` has 3 entries | One per type |
| 4 | Verify each entry has correct type, spend, paid, count | Correct values |

#### TC-VLR-P58: AJAX get_options=agreements returns agreements filtered by vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements (AR-001, AR-002), Vendor Y has 1 agreement (AR-003) | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX request |
| 3 | Verify JSON response contains 2 objects each with `id` and `text` (agreement_ref_no) fields for AR-001 and AR-002 | Filtered correctly |

#### TC-VLR-P59: AJAX get_options=items filtered by agreement_id or vendor_id fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has item I3; Vendor V1 has agreements A1, A2 | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=items&agreement_id=A1` | Items by agreement |
| 3 | Verify JSON contains I1 and I2 only (items linked via agreementItems where agreement_id=A1) | Filtered by agreement |
| 4 | Send AJAX: `GET /vendor-reports?get_options=items&vendor_id=V1` (no agreement_id) | Items by vendor fallback |
| 5 | Verify JSON contains I1, I2, I3 (all items linked to V1's agreements via agreementItems.agreement) | Vendor-scoped fallback |

### 10.2 Negative TC Steps — Vendor Ledger Summary

#### TC-VLR-N01: Access without tenant.vendor-report.viewAny → 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-report.viewAny` permission navigates to `GET /vendor-reports` | 403 Forbidden |
| 2 | Verify `Gate::authorize('tenant.vendor-report.viewAny')` throws AuthorizationException | Aborted |

#### TC-VLR-N02: Invalid from_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?from_date=not-a-date` | 500 error |
| 2 | Verify `Carbon\Exceptions\InvalidFormatException` or `InvalidArgumentException` thrown | Exception bubbles up (no try-catch) |

#### TC-VLR-N03: Invalid to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?to_date=abc-def-ghi` | 500 error |
| 2 | Verify Carbon parse exception | Exception bubbles up |

#### TC-VLR-N04: from_date after to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?from_date=2026-06-01&to_date=2026-01-01` | Page loads (no error) |
| 2 | Verify `from_date > to_date` → no invoices satisfy `BETWEEN` | Empty invoice set |
| 3 | Verify `ledgerVendors` shows vendors but all computed fields are zero/empty | Graceful empty result |

#### TC-VLR-N05: Non-existent vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?vendor_id=99999` | Page loads |
| 2 | Verify `ledgerVendors` is empty (no vendor with id=99999) | Empty result |
| 3 | Verify summary all zeros and charts empty | Graceful empty |

#### TC-VLR-N06: Non-existent agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?agreement_id=99999` | Page loads |
| 2 | Verify `ledgerVendors` is empty (`whereHas` finds no vendor) | Empty result |
| 3 | Verify no error thrown — empty paginated collection returned | Graceful handling |

#### TC-VLR-N07: Non-existent item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?item_id=99999` | Page loads (item_id is unused in ledger query) |
| 2 | Verify `item_id` filter is ignored by `getVendorLedgerSummaryData` | No impact on query |

#### TC-VLR-N08: No vendors exist → empty data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No vendor records exist in `vnd_vendors` | Empty DB |
| 2 | Request page | Page loads |
| 3 | Verify `ledgerVendors` is empty, summary all zeros, charts empty | Graceful empty state |

#### TC-VLR-N09: No invoices in date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendors exist but no invoices with `invoice_date` in range | Empty invoice set |
| 2 | Request page with valid but empty date range | Page loads |
| 3 | Verify per-vendor: total_invoices=0, total_invoice_amount=0, total_paid=0, total_outstanding=0, overdue_amount=0, collection_rate=0, last_invoice_date='—', last_payment_date='—' | Zero values |
| 4 | Verify summary all zero, charts empty arrays | Empty state |

#### TC-VLR-N10: No SUCCESS payments → zero paid data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoices exist but no payments with status = 'SUCCESS' | No payments |
| 2 | Request page | Page loads |
| 3 | Verify `total_paid_amount = 0`, `last_payment_date = '—'` | Zero paid |
| 4 | Verify `collection_rate = 0` | No collection |

#### TC-VLR-N11: Negative ledger_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?ledger_page=-1` | Page loads |
| 2 | Verify Laravel defaults negative page to page 1 | Page 1 returned |

#### TC-VLR-N12: Out of range ledger_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Only 3 pages of data exist | Seed data |
| 2 | Request `GET /vendor-reports?ledger_page=999` | Page loads |
| 3 | Verify `ledgerVendors` is empty (page beyond last) | Empty page |

#### TC-VLR-N13: Non-numeric ledger_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?ledger_page=abc` | Page loads |
| 2 | Verify Laravel defaults invalid page to page 1 | Page 1 returned |

#### TC-VLR-N14: Only to_date provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?to_date=2026-06-30` (no from_date) | Page loads |
| 2 | Verify `fromDate` defaults to `now()->startOfMonth()` | Default from_date applied |
| 3 | Verify data includes invoices from start of month to 2026-06-30 | Semi-default range |

#### TC-VLR-N15: Only from_date provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?from_date=2026-01-01` (no to_date) | Page loads |
| 2 | Verify `toDate` defaults to `now()->endOfMonth()` | Default to_date applied |
| 3 | Verify data includes invoices from 2026-01-01 to end of current month | Semi-default range |

#### TC-VLR-N16: AJAX get_options=agreements without vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?get_options=agreements` (no vendor_id) | AJAX response |
| 2 | Verify `VndAgreement::where('vendor_id', null)` returns empty `$options` | Empty array |

#### TC-VLR-N17: AJAX get_options with invalid type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request `GET /vendor-reports?get_options=invalid_type` | AJAX response |
| 2 | Verify returns `response()->json([])` — empty JSON array | Default fallback |

### 10.3 Code Review TC Steps

#### TC-CR-VLR01: index() — Gate::authorize with tenant.vendor-report.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-report.viewAny')` at top of `index()` | Gate present |
| 2 | Note: Uses `Gate::authorize` (throws exception) not `Gate::any` | Single permission gate |

#### TC-CR-VLR02: index() — AJAX get_options handled before view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($request->ajax() && $request->has('get_options'))` at method start | AJAX early return |
| 2 | Review `getFilteredOptions()` called and returned as JSON | JSON response |
| 3 | Review no Gate check inside `getFilteredOptions()` — relies on index() Gate | Gate applied at entry |
| 4 | Review three branches: agreements, items, and fallback `[]` | All branches handled |

#### TC-CR-VLR03: dates() — default date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$from = $r->filled('from_date') ? Carbon::parse(...) : now()->startOfMonth()` | Default from |
| 2 | Review `$to = $r->filled('to_date') ? Carbon::parse(...) : now()->endOfMonth()` | Default to |
| 3 | Review `[$from->startOfDay(), $to->endOfDay()]` — start/end of day applied | Day boundaries |
| 4 | Note: `startOfDay()`/`endOfDay()` called AFTER the ternary — applies to defaults and parsed values | Boundary handling |

#### TC-CR-VLR04: dates() — no try-catch around Carbon::parse

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Carbon::parse($r->from_date)` without try-catch block | No error handling |
| 2 | Review `Carbon::parse($r->to_date)` without try-catch block | No error handling |
| 3 | Note: Invalid date strings will throw `InvalidArgumentException` → 500 error | Vulnerability |

#### TC-CR-VLR05: getVendorLedgerSummaryData() — eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Vendor::with(['vendorType', 'agreements'])` | 2 relations eager-loaded |
| 2 | Verify no `->get()` call before `paginate()` — relations loaded correctly | Proper eager loading |
| 3 | Note: `vendorType` and `agreements` are the ONLY eager-loaded relations | Limited eager load |

#### TC-CR-VLR06: getVendorLedgerSummaryData() — per-vendor N+1 risk

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review per-vendor `$vendor->invoices()->where(...)->get()` inside `transform()` | Per-vendor invoice query |
| 2 | Review per-vendor `$vendor->payments()->where(...)->get()` inside `transform()` | Per-vendor payment query |
| 3 | Note: Each vendor triggers 2 additional DB queries (invoices + payments) — potential N+1 for 10 vendors = 1 + 10 + 10 = 21 queries | N+1 pattern |

#### TC-CR-VLR07: Per-vendor collection_rate — division by zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoices->sum('net_payable') > 0 ? round(($invoices->sum('amount_paid') / $invoices->sum('net_payable')) * 100, 1) : 0` | Guard condition |
| 2 | Verify 0 returned when `net_payable` is 0 (no invoices) | Division by zero prevented |
| 3 | Note: `sum('net_payable')` is called twice — could be optimized | Redundant sum call |

#### TC-CR-VLR08: Summary collection_rate — division by zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review same pattern: `$allInvoices->sum('net_payable') > 0 ? round(...) : 0` | Guard condition |
| 2 | Verify returns 0 when no invoices in date range | Zero handled |
| 3 | Note: Identical formula to per-vendor rate but computed from different data source | Correct but duplicated |

#### TC-CR-VLR09: overdue_amount triple condition

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$i->balance_due > 0` in filter | Condition 1: has balance |
| 2 | Review `$i->due_date` (implicit not-null check) | Condition 2: has due date |
| 3 | Review `$i->due_date->isPast()` | Condition 3: due date in past |
| 4 | Verify all 3 conditions are AND-ed for overdue calculation | Triple AND |

#### TC-CR-VLR10: ledgerChartOutstanding — top 5 sorting

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$allInvoices->filter(fn($i) => $i->balance_due > 0)` | Filter to positive balance |
| 2 | Review `->groupBy('vendor_id')` → map with sum of balance_due | Group by vendor |
| 3 | Review `->sortByDesc('outstanding')` | Sort descending |
| 4 | Review `->take(5)` | Limit to 5 |

#### TC-CR-VLR11: ledgerChartMonthly — null invoice_date handled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->filter(fn($i) => $i->invoice_date !== null)` | Null date filtered out |
| 2 | Review `->groupBy(fn($i) => $i->invoice_date->format('Y-m'))` | Group by year-month |
| 3 | Review month label: `$first->invoice_date->format('M Y')` | Label format |
| 4 | Review `->sortBy(fn($v, $k) => $k)` — sort by key (Y-m string) | Chronological sort |

#### TC-CR-VLR12: Pagination with distinct page name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->paginate(10, ['*'], 'ledger_page')` | 10 per page, page name 'ledger_page' |
| 2 | Review `->appends($request->query())` | Query string preserved |
| 3 | Note: Other report tabs use different page names (agreement_page, invoice_page, outstanding_page, payment_page) | No page name collision |

#### TC-CR-VLR13: Pagination query string preserved

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$ledgerVendors = $vendorQuery->paginate(...)->appends($request->query())` | Query string appended |
| 2 | Verify filters (vendor_id, agreement_id, from_date, to_date) are preserved in pagination links | Filter preservation |

#### TC-CR-VLR14: total_vendors count after filter mutation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$vendorQuery->count()` for `total_vendors` | Counts filtered query |
| 2 | Note: `$vendorQuery` has already been mutated by `where()` and `whereHas()` calls | Correctly includes filters |

#### TC-CR-VLR15: active_vendors — clone() method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$vendorQuery->clone()->where('is_active', true)->count()` | Clone builder |
| 2 | Note: `clone()` method was added in Laravel 6.x — ensures original query not modified | Framework version dependent |

#### TC-CR-VLR16: last_invoice_date — null-safe pattern

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoices->sortByDesc('invoice_date')->first()` | Most recent invoice |
| 2 | Review `?->invoice_date?->format('d M Y')` — null-safe operator | Null-safe on invoice and invoice_date |
| 3 | Review `?? '—'` — null coalescing fallback | Dash fallback |
| 4 | Note: Uses PHP 8 null-safe operator (`?->`) | PHP 8+ required |

#### TC-CR-VLR17: last_payment_date sourced from payment query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$payments->sortByDesc('payment_date')->first()?->payment_date?->format(...) ?? '—'` | From payment query |
| 2 | Verify payment query filters `status = 'SUCCESS'` and date range | Correct source |
| 3 | Note: Not derived from invoices — correct, since payments is the authoritative source | Separate query |

#### TC-CR-VLR18: Agreement filter cascaded to per-vendor invoice sub-query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($request->filled('agreement_id')) $invQ->where('agreement_id', $request->agreement_id)` | Agreement scoped on invoices |
| 2 | Note: This is INSIDE the per-vendor `transform()` — filters only this vendor's invoices | Cascaded filter |

#### TC-CR-VLR19: No validation on filter inputs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getVendorLedgerSummaryData()` — no `$request->validate()` | No validation |
| 2 | Review `getFilteredOptions()` — no validation | No validation |
| 3 | Note: Invalid/non-existent IDs silently return empty results — no error feedback to user | UX gap |

#### TC-CR-VLR20: getFilteredOptions fallback for unknown type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($type === 'agreements') { ... }` branch | Agreements handled |
| 2 | Review `if ($type === 'items') { ... }` branch | Items handled |
| 3 | Review `return response()->json([])` at end | Fallback empty JSON |

### 10.4 Dependency TC Steps

#### TC-D-VLR01: Vendor type missing → displayed as 'N/A'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has `vendor_type_id` pointing to a deleted/non-existent dropdown ID | Orphaned FK |
| 2 | Request page | Page loads |
| 3 | Verify Vendor A's `vendor_type = "N/A"` via `optional($vendor->vendorType)->value ?? 'N/A'` | Graceful fallback |

#### TC-D-VLR02: Orphaned invoice excluded if vendor missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice exists with `vendor_id` pointing to a deleted vendor | Orphaned invoice |
| 2 | Request page | Page loads |
| 3 | Verify total_invoiced/summary does NOT include the orphaned invoice | Excluded via JOIN/Eager load |

#### TC-D-VLR03: Non-SUCCESS payments excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has: 1 SUCCESS payment (1000), 1 FAILED payment (500), 1 PENDING payment (300) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify only SUCCESS payment counted in `total_paid_amount` and `last_payment_date` | Only SUCCESS included |

#### TC-D-VLR04: Inactive invoices excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has: 2 active invoices (net_payable=5000), 1 inactive invoice (is_active=0, net_payable=2000) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify only active invoices (net_payable=5000) counted in totals | Inactive excluded |

#### TC-D-VLR05: Deleted payments excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has: 1 SUCCESS payment with is_deleted=0 (1000), 1 SUCCESS payment with is_deleted=1 (500) | Seed data |
| 2 | Request page | Page loads |
| 3 | Verify only non-deleted payment (1000) counted | Deleted excluded |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-reports` | vendor.vendor-reports.index | index() | tenant.vendor-report.viewAny |
| GET | `/vendor-reports?get_options=...` | (same route, AJAX) | getFilteredOptions() | tenant.vendor-report.viewAny (via index) |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-VLR-01 | No FormRequest or inline validation | **Medium** | No validation on any filters (vendor_id, agreement_id, date); invalid dates throw 500 error via Carbon; invalid IDs silently return empty |
| KI-VLR-02 | N+1 query pattern in per-vendor transform | **Medium** | Each vendor in the collection triggers 2 additional queries (invoices, payments) → for 10 vendors: 1 (vendors) + 10 (invoices) + 10 (payments) = 21 queries |
| KI-VLR-03 | `clone()` method on Query Builder | **Low** | `$vendorQuery->clone()` requires Laravel 6+ — may not be available in older versions |
| KI-VLR-04 | No sort order for ledger vendors | **Low** | `$vendorQuery` does not apply `orderBy()` — results may be in unpredictable order (defaults to PK order) |
| KI-VLR-05 | `sum('net_payable')` called twice in collection_rate | **Low** | Both the guard condition and the calculation call `sum()` separately — micro-optimization opportunity |
| KI-VLR-06 | `appends($request->query())` includes `tab` parameter | **Info** | Pagination links preserve the `tab` query parameter, but ledger pagination stays within the same tab |
| KI-VLR-07 | `item_id` filter accepted but unused | **Info** | The `item_id` filter is passed in shared `$filters` but `getVendorLedgerSummaryData()` never uses it — it only affects other report tabs |
| KI-VLR-08 | `filterAgreements` query not scoped to active only | **Info** | Unlike `filterVendors` (uses `active()`) and `filterItems` (uses `active()`), `filterAgreements` returns all agreements regardless of status |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Vendor Ledger Summary | `index()` → `getVendorLedgerSummaryData()` | Vendor, VndInvoice, VndPayment | 10 per page (`ledger_page`) |
| Filtered Options (AJAX) | `getFilteredOptions()` | VndAgreement, VndItem | None (JSON) |
| Shared Filter State | `index()` | Vendor, VndAgreement, VndItem | None (full lists) |
