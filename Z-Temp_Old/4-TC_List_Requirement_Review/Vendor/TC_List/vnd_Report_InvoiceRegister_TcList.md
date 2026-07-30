# vnd_Report_InvoiceRegister_TcList

## Module: Vendor → Reports → Invoice Register

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Feature | Invoice Register — Tab on Vendor Reports Dashboard |
| URL(s) | `/vendor-reports?tab=invoice-register` |
| Controller | `Modules\Vendor\Http\Controllers\VendorReportController` |
| Method | `getInvoiceRegisterData()` |
| Model(s) | `VndInvoice`, `Vendor`, `VndAgreement`, `VndAgreementItem` |
| Permission Gate | `tenant.vendor-report.viewAny` (index), `tenant.vendor-report.invoice` (tab) |
| Pagination | 10 per page, page name `invoice_page` |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor-report.viewAny` to access the report dashboard; `tenant.vendor-report.invoice` to view the Invoice Register tab
- At least one active VndInvoice record (`is_active = true`) within the current month (default date range: `now()->startOfMonth()` to `now()->endOfMonth()`)
- For summary tests: invoices with varied payment states — fully paid (`balance_due <= 0`), pending (`balance_due > 0 AND amount_paid = 0`), partial (`balance_due > 0 AND amount_paid > 0`), overdue (`balance_due > 0 AND due_date in past`)
- For chart tests: invoices across multiple months (for trend chart), multiple vendors (at least 8 for top-8 vendor chart)
- For filter tests: invoices linked to different vendors, agreements, and agreement items
- Related records: `VndVendor`, `VndAgreement`, `VndAgreementItem` must exist and be linked via FK

---

## 3. Default Data Load

### 3.1 Filter Dropdowns (index method)

| Dropdown | Source | Filtering |
|----------|--------|-----------|
| `filterVendors` | `Vendor::active()->orderBy('vendor_name')->get()` | All active vendors |
| `filterAgreements` | `VndAgreement::orderByDesc('id')` → `when(vendor_id)` | Filtered by vendor_id if provided |
| `filterItems` | `VndItem::active()->orderBy('item_name')` → `when(agreement_id)` → `when(vendor_id)` | Filtered by agreement_id or vendor_id |

### 3.2 Data Returned by `getInvoiceRegisterData()`

| Variable | Type | Description |
|----------|------|-------------|
| `invoiceRecords` | `LengthAwarePaginator` | Paginated (10) VndInvoice records with eager-loaded `vendor`, `agreement`, `agreementItem.item` |
| `invoiceSummary` | array | Aggregate stats: total_invoices, paid_count, pending_count, partial_count, total_amount, total_paid, total_balance, total_tax, total_discount, overdue_count, collection_rate |
| `invoiceChartTrend` | Collection | Monthly group: month (M Y format), total (net_payable sum), paid (amount_paid sum), count |
| `invoiceChartStatus` | array | Hardcoded labels: Fully Paid, Partially Paid, Unpaid, Overdue — mapped to respective counts |
| `invoiceChartVendor` | Collection | Top 8 vendors by net_payable: vendor_name, total, count |

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_invoices` — Primary Invoice Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| agreement_id | INT UNSIGNED | YES | NULL | FK → vnd_agreements(id) |
| agreement_item_id | INT UNSIGNED | YES | NULL | FK → vnd_agreement_items(id) (item_id filter maps here) |
| item_description | VARCHAR(255) | YES | NULL | Description of invoiced item |
| invoice_number | VARCHAR(50) | NOT NULL | — | Unique invoice number |
| invoice_date | DATE | YES | NULL | Date of invoice |
| billing_start_date | DATE | YES | NULL | Billing period start |
| billing_end_date | DATE | YES | NULL | Billing period end |
| fixed_charge_amt | DECIMAL(12,2) | YES | 0.00 | Fixed charge amount |
| unit_charge_amt | DECIMAL(12,2) | YES | 0.00 | Unit charge amount |
| qty_used | DECIMAL(12,2) | YES | 0.00 | Quantity used |
| unit_rate | DECIMAL(12,2) | YES | 0.00 | Rate per unit |
| min_guarantee_qty | DECIMAL(12,2) | YES | 0.00 | Minimum guarantee qty |
| tax1_percent | DECIMAL(5,2) | YES | 0.00 | Tax 1 percentage |
| tax2_percent | DECIMAL(5,2) | YES | 0.00 | Tax 2 percentage |
| tax3_percent | DECIMAL(5,2) | YES | 0.00 | Tax 3 percentage |
| tax4_percent | DECIMAL(5,2) | YES | 0.00 | Tax 4 percentage |
| sub_total | DECIMAL(14,2) | YES | 0.00 | Sub-total before tax |
| tax_total | DECIMAL(14,2) | YES | 0.00 | Total tax amount |
| other_charges | DECIMAL(14,2) | YES | 0.00 | Other charges |
| discount_amount | DECIMAL(14,2) | YES | 0.00 | Discount amount |
| net_payable | DECIMAL(14,2) | YES | 0.00 | Net payable (sub_total + tax_total + other_charges - discount_amount) |
| amount_paid | DECIMAL(14,2) | YES | 0.00 | Amount paid |
| balance_due | DECIMAL(14,2) | YES | 0.00 | Computed: net_payable - amount_paid (set via boot saving) |
| due_date | DATE | YES | NULL | Payment due date |
| status | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) (invoice status) |
| remarks | TEXT | YES | NULL | Remarks |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Deleted flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `idx_vnd_invoice_vendor` (`vendor_id`)
- KEY `idx_vnd_invoice_agreement` (`agreement_id`)
- KEY `idx_vnd_invoice_agreement_item` (`agreement_item_id`)

---

## 5. BC-VAL — Validation Rules

### 5.1 Report Validation (Controller-level)

The report is read-only; no FormRequest is used. Inline validation:

| Context | Validation | Notes |
|---------|-----------|-------|
| `dates()` method | `Carbon::parse($r->from_date)` / `Carbon::parse($r->to_date)` | Throws `InvalidArgumentException` on invalid date string; defaults to `startOfMonth()` / `endOfMonth()` if not filled |
| `index()` Gate | `Gate::authorize('tenant.vendor-report.viewAny')` | Must exist in permissions table |
| Blade `@can` | `@can('tenant.vendor-report.invoice')` | Tab visibility controlled by permission |

### 5.2 Date Processing

| Input | Processing |
|-------|-----------|
| `from_date` not provided | `now()->startOfMonth()` (start of day) |
| `to_date` not provided | `now()->endOfMonth()` (end of day) |
| `from_date` / `to_date` provided | `Carbon::parse()` → `startOfDay()` / `endOfDay()` |
| Invalid date string | `Carbon::parse()` throws exception (no try-catch — 500 error) |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Usage | Context |
|----------------|-------|---------|
| `tenant.vendor-report.viewAny` | `Gate::authorize()` in `index()` | Required to access `/vendor-reports` at all |
| `tenant.vendor-report.invoice` | `@can` directive in Blade | Controls visibility of the Invoice Register tab; if false, the tab button is hidden |

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-IR-01 | Default Date Range | If no `from_date` / `to_date` is provided, defaults to `now()->startOfMonth()` → `now()->endOfMonth()` |
| BC-BIZ-IR-02 | Query Scope | `VndInvoice::with(['vendor','agreement','agreementItem.item'])->where('is_active', true)->whereBetween('invoice_date', [$from, $to])` |
| BC-BIZ-IR-03 | Filter — vendor_id | `$query->where('vendor_id', $request->vendor_id)` |
| BC-BIZ-IR-04 | Filter — agreement_id | `$query->where('agreement_id', $request->agreement_id)` |
| BC-BIZ-IR-05 | Filter — item_id | `$query->where('agreement_item_id', $request->item_id)` — maps to agreement_item_id, not item_id |
| BC-BIZ-IR-06 | Pagination | `orderByDesc('invoice_date')->paginate(10, ['*'], 'invoice_page')` with `appends($request->query())` |
| BC-BIZ-IR-07 | Summary — paid_count | `$invoices->where('balance_due', '<=', 0)->count()` |
| BC-BIZ-IR-08 | Summary — pending_count | `$invoices->where('balance_due', '>', 0)->where('amount_paid', 0)->count()` |
| BC-BIZ-IR-09 | Summary — partial_count | `$invoices->where('balance_due', '>', 0)->where('amount_paid', '>', 0)->count()` |
| BC-BIZ-IR-10 | Summary — total_amount | `(float) $invoices->sum('net_payable')` |
| BC-BIZ-IR-11 | Summary — total_paid | `(float) $invoices->sum('amount_paid')` |
| BC-BIZ-IR-12 | Summary — total_balance | `(float) $invoices->sum('balance_due')` |
| BC-BIZ-IR-13 | Summary — total_tax | `(float) $invoices->sum('tax_total')` |
| BC-BIZ-IR-14 | Summary — total_discount | `(float) $invoices->sum('discount_amount')` |
| BC-BIZ-IR-15 | Summary — overdue_count | `$invoices->filter(fn($i) => $i->balance_due > 0 && $i->due_date && $i->due_date->isPast())->count()` |
| BC-BIZ-IR-16 | Summary — collection_rate | `$invoices->sum('net_payable') > 0 ? round(($invoices->sum('amount_paid') / $invoices->sum('net_payable')) * 100, 1) : 0` |
| BC-BIZ-IR-17 | Chart — invoiceChartTrend | Monthly group: `$i->invoice_date->format('Y-m')` → map with `format('M Y')`, sum net_payable as total, sum amount_paid as paid; null dates filtered out |
| BC-BIZ-IR-18 | Chart — invoiceChartStatus | Hardcoded array: [Fully Paid→paid_count, Partially Paid→partial_count, Unpaid→pending_count, Overdue→overdue_count] |
| BC-BIZ-IR-19 | Chart — invoiceChartVendor | `groupBy('vendor_id')` → map vendor_name, total (net_payable sum), count → `sortByDesc('total')->take(8)` |
| BC-BIZ-IR-20 | Blade Date Fallback | `$inv->invoice_date?->format('d M Y') ?? '—'` uses null-safe operator |
| BC-BIZ-IR-21 | Blade Status Badge | `balance_due <= 0` → "Paid" (green), `amount_paid > 0` → "Partial" (info), else "Unpaid" (warning); overdue badge if `due_date->isPast() && balance_due > 0` |
| BC-BIZ-IR-22 | Balance Due Computed | `VndInvoice::saving()` event computes `balance_due = net_payable - amount_paid`; also a getter accessor exists |
| BC-BIZ-IR-23 | Base Query Separate | `$baseCountQuery = clone $query` before pagination to calculate summary on the full (unpaginated) filtered result set |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_invoice_vendor | vnd_invoices.vendor_id | vnd_vendors.id | CASCADE (implied by model relationships) |
| fk_vnd_invoice_agreement | vnd_invoices.agreement_id | vnd_agreements.id | CASCADE (implied) |
| fk_vnd_invoice_agreement_item | vnd_invoices.agreement_item_id | vnd_agreement_items.id | CASCADE (implied) |
| fk_vnd_invoice_status | vnd_invoices.status | sys_dropdown_table.id | RESTRICT (implied by DB schema) |

---

## 9. Test Case Summary

### 9.1 Invoice Register — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-IR-P01 | Invoice Register | Positive | Invoice Register tab loads with default date range | 4 |
| TC-IR-P02 | Invoice Register | Positive | Stat cards display aggregated data (total, paid, pending, partial, overdue, collection) | 4 |
| TC-IR-P03 | Invoice Register | Positive | Invoice trend chart (invoiceChartTrend) renders monthly data | 4 |
| TC-IR-P04 | Invoice Register | Positive | Invoice status chart (invoiceChartStatus) renders 4 hardcoded status segments | 4 |
| TC-IR-P05 | Invoice Register | Positive | Invoice vendor chart (invoiceChartVendor) shows top 8 vendors | 4 |
| TC-IR-P06 | Invoice Register | Positive | Paginated invoice table loads with all columns | 5 |
| TC-IR-P07 | Invoice Register | Positive | Filter by vendor_id | 3 |
| TC-IR-P08 | Invoice Register | Positive | Filter by agreement_id (cascaded from vendor_id) | 4 |
| TC-IR-P09 | Invoice Register | Positive | Filter by item_id (maps to agreement_item_id) | 4 |
| TC-IR-P10 | Invoice Register | Positive | Combined filters (vendor_id + agreement_id + item_id) | 4 |
| TC-IR-P11 | Invoice Register | Positive | Date range filter returns invoices within range | 3 |
| TC-IR-P12 | Invoice Register | Positive | Invoice with null invoice_date excluded from charts but shown in table | 3 |
| TC-IR-P13 | Invoice Register | Positive | Table footer shows correct page totals for sub_total, tax, net_payable, paid, balance | 3 |
| TC-IR-P14 | Invoice Register | Positive | Overdue badge (OD) displayed for past-due invoices with balance > 0 | 3 |
| TC-IR-P15 | Invoice Register | Positive | AJAX getFilteredOptions — agreements by vendor_id | 3 |
| TC-IR-P16 | Invoice Register | Positive | AJAX getFilteredOptions — items by agreement_id or vendor_id | 5 |

### 9.2 Invoice Register — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-IR-N01 | Invoice Register | Negative | No permission — user without `tenant.vendor-report.invoice` cannot see tab | 2 |
| TC-IR-N02 | Invoice Register | Negative | No permission — user without `tenant.vendor-report.viewAny` gets 403 | 2 |
| TC-IR-N03 | Invoice Register | Negative | Invalid `from_date` format triggers Carbon parse exception | 2 |
| TC-IR-N04 | Invoice Register | Negative | Invalid `to_date` format triggers Carbon parse exception | 2 |
| TC-IR-N05 | Invoice Register | Negative | Date range with no matching invoices shows empty table | 3 |
| TC-IR-N06 | Invoice Register | Negative | Empty result — stat cards show zero values | 3 |
| TC-IR-N07 | Invoice Register | Negative | Non-existent vendor_id returns empty results | 3 |
| TC-IR-N08 | Invoice Register | Negative | Non-existent agreement_id returns empty results | 3 |
| TC-IR-N09 | Invoice Register | Negative | Non-existent item_id returns empty results | 3 |
| TC-IR-N10 | Invoice Register | Negative | Null `invoice_date` records — chart grouping filter excludes them from trend chart | 3 |
| TC-IR-N11 | Invoice Register | Negative | All invoices fully paid — pending/partial/overdue counts are zero | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-IR01 | Code Review | Review | getInvoiceRegisterData() — query chain and eager loading | 5 |
| TC-CR-IR02 | Code Review | Review | dates() method — Carbon::parse fallback and default range | 4 |
| TC-CR-IR03 | Code Review | Review | invoiceSummary — paid/pending/partial count logic | 5 |
| TC-CR-IR04 | Code Review | Review | collection_rate — division by zero guard | 3 |
| TC-CR-IR05 | Code Review | Review | invoiceChartStatus — hardcoded label array (maintenance weakness) | 3 |
| TC-CR-IR06 | Code Review | Review | invoiceChartTrend — date null guard and Y-m grouping | 4 |
| TC-CR-IR07 | Code Review | Review | invoiceChartVendor — top 8 sorting and take(8) limit | 4 |
| TC-CR-IR08 | Code Review | Review | Blade view — date formatting with null-safe operator (??) | 3 |
| TC-CR-IR09 | Code Review | Review | Filter mapping — `item_id` parameter mapped to `agreement_item_id` column | 3 |
| TC-CR-IR10 | Code Review | Review | Pagination — `invoice_page` page name consistency across controller and view | 4 |
| TC-CR-IR11 | Code Review | Review | Index method — shared filter dropdowns (vendor/agreement/item) with other reports | 4 |
| TC-CR-IR12 | Code Review | Review | Blade status badge logic — 3-state + overdue indicator | 4 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D-IR01 | Dependency | Dependency | VndInvoice `with(['vendor','agreement','agreementItem.item'])` requires all 3 FK relationships to exist | 4 |
| TC-D-IR02 | Dependency | Dependency | Item filter uses `agreement_item_id` — requires VndAgreementItem record | 3 |
| TC-D-IR03 | Dependency | Dependency | Date casting — invoice_date, due_date cast as `date` in VndInvoice model | 3 |
| TC-D-IR04 | Dependency | Dependency | Balance_due auto-computed via boot `saving()` event and accessor | 3 |
| TC-D-IR05 | Dependency | Dependency | VndInvoice `is_active` flag — all queries scope to `where('is_active', true)` | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Invoice Register

#### TC-IR-P01: Invoice Register tab loads with default date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-report.viewAny` and `tenant.vendor-report.invoice` permissions navigates to `/vendor-reports` | Vendor Reports page loads |
| 2 | Click "Invoices" tab (or navigate to `?tab=invoice-register`) | Tab switches to invoice-register |
| 3 | Verify invoice-register-pane has CSS classes `show active` | Tab pane visible |
| 4 | Verify stat cards, charts, and invoice table are all present | All sections rendered |

#### TC-IR-P02: Stat cards display aggregated data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to invoice register tab with invoices in the default month | Tab loads |
| 2 | Verify stat card "Total Invoices" (`$invoiceSummary['total_invoices']`) shows correct count | Count displayed |
| 3 | Verify "Fully Paid" card shows `$invoiceSummary['paid_count']` with progress bar | Paid count displayed |
| 4 | Verify "Overdue" card shows `$invoiceSummary['overdue_count']` with danger progress bar | Overdue count displayed |
| 5 | Verify "Collection" card shows `$invoiceSummary['collection_rate']%` | Collection rate displayed |

#### TC-IR-P03: Invoice trend chart (invoiceChartTrend) renders monthly data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With invoices spanning at least 2 different months, load invoice register | Trend chart area visible |
| 2 | Verify `invoiceTrendChart` canvas element is present | Canvas rendered |
| 3 | Verify chart data groups by `Y-m` format and displays month labels as `M Y` | Monthly grouping correct |
| 4 | Verify each month entry has `total` (net_payable sum), `paid` (amount_paid sum), and `count` | All 3 metrics present |

#### TC-IR-P04: Invoice status chart (invoiceChartStatus) renders 4 hardcoded status segments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With invoices in all 4 payment states (paid, partial, unpaid, overdue) | Status chart renders |
| 2 | Verify canvas `invoicePaymentChart` is present | Canvas rendered |
| 3 | Verify chart data has exactly 4 entries with labels: "Fully Paid", "Partially Paid", "Unpaid", "Overdue" | 4 hardcoded labels |
| 4 | Verify value mapping: Fully Paid = paid_count, Partially Paid = partial_count, Unpaid = pending_count, Overdue = overdue_count | Correct values |

#### TC-IR-P05: Invoice vendor chart (invoiceChartVendor) shows top 8 vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | With invoices from at least 8 distinct vendors, load invoice register | Vendor chart renders |
| 2 | Verify canvas `invoiceVendorChart` is present | Canvas rendered |
| 3 | Verify chart contains at most 8 vendor entries | Top 8 limit applied |
| 4 | Verify vendors sorted by total net_payable descending | Sorted correctly |

#### TC-IR-P06: Paginated invoice table loads with all columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load invoice register with at least 11 invoices | Table loads with pagination |
| 2 | Verify table header columns: #, Invoice No, Date, Vendor, Agreement, Description, Qty, Sub Total, Tax, Net Payable, Paid, Balance, Due Date, Status | All 14 columns present |
| 3 | Verify each row shows invoice_number, invoice_date formatted as `d M Y`, vendor_name, agreement_ref_no, item_description | Row data populated |
| 4 | Verify pagination links are present and clicking page 2 loads next 10 records | 10 per page |
| 5 | Verify pagination uses `invoice_page` query parameter in URL | Correct page name |

#### TC-IR-P07: Filter by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific vendor from the vendor dropdown | vendor_id filter applied |
| 2 | Click Submit (or wait for AJAX reload if auto-submit) | Page reloads with filter |
| 3 | Verify only invoices for the selected vendor are shown in the table and summary | Filtered to vendor |

#### TC-IR-P08: Filter by agreement_id (cascaded from vendor_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor first | Agreement dropdown populated for that vendor |
| 2 | Select an agreement from the cascaded agreement dropdown | agreement_id filter set |
| 3 | Submit filter | Page reloads with both filters |
| 4 | Verify only invoices for the selected vendor AND agreement are shown | Filtered correctly |

#### TC-IR-P09: Filter by item_id (maps to agreement_item_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor and/or agreement | Item dropdown cascaded |
| 2 | Select an item from the cascaded item dropdown | item_id filter set |
| 3 | Submit filter | Page reloads |
| 4 | Verify query uses `vnd_invoices.agreement_item_id = $request->item_id` (not item_id directly) | Correct column mapped |

#### TC-IR-P10: Combined filters (vendor_id + agreement_id + item_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor, agreement, and item from respective dropdowns | All 3 filters set |
| 2 | Submit filter | Page reloads |
| 3 | Verify all 3 WHERE clauses applied to query | Triple filter working |
| 4 | Verify the combination produces correct filtered results | Expected record subset |

#### TC-IR-P11: Date range filter returns invoices within range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `from_date` and `to_date` to a specific range (e.g. Jan 2026) | Date range set |
| 2 | Submit filter | Page reloads |
| 3 | Verify all displayed invoices have `invoice_date` within [from, to] | Date range enforced |

#### TC-IR-P12: Invoice with null invoice_date excluded from charts but shown in table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an invoice with `invoice_date = NULL` | Invoice exists |
| 2 | Load invoice register with date range that includes this record (no date filter) | Table shows row with "—" for date |
| 3 | Verify `invoiceChartTrend` excludes this record (null dates filtered by `$i->invoice_date !== null`) | Chart excludes null dates |
| 4 | Verify blade displays `—` via `$inv->invoice_date?->format('d M Y') ?? '—'` | Fallback displayed |

#### TC-IR-P13: Table footer shows correct page totals

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load invoice register with multiple invoices in current page | Table renders |
| 2 | Verify footer row shows "Page Totals:" label | Footer present |
| 3 | Verify footer shows correct: sub_total = total_amount - total_tax, tax = total_tax, net_payable = total_amount, paid = total_paid, balance = total_balance | All totals match summary |

#### TC-IR-P14: Overdue badge (OD) displayed for past-due invoices with balance > 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have an invoice with `due_date` in past and `balance_due > 0` | Overdue invoice exists |
| 2 | Load invoice register | Overdue invoice in table |
| 3 | Verify `OD` badge (red) appears next to due_date in the Due Date column | Badge rendered |
| 4 | Verify the status badge shows the correct payment status (Unpaid or Partial) based on amount_paid | Status badge consistent |

#### TC-IR-P15: AJAX getFilteredOptions — agreements by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements (AR-001, AR-002), Vendor Y has 1 agreement (AR-003) | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX request |
| 3 | Verify JSON response contains 2 objects each with `id` and `text` fields for AR-001 and AR-002 | Filtered correctly |

#### TC-IR-P16: AJAX getFilteredOptions — items by agreement_id or vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has item I3; Vendor V1 has agreements A1, A2 | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=items&agreement_id=A1` | Items by agreement |
| 3 | Verify JSON contains I1 and I2 only (items linked via agreementItems where agreement_id=A1) | Filtered by agreement |
| 4 | Send AJAX: `GET /vendor-reports?get_options=items&vendor_id=V1` (no agreement_id) | Items by vendor fallback |
| 5 | Verify JSON contains I1, I2, I3 (all items linked to V1's agreements via agreementItems.agreement) | Vendor-scoped fallback |

### 10.2 Negative TC Steps — Invoice Register

#### TC-IR-N01: No permission — user without `tenant.vendor-report.invoice` cannot see tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User has `tenant.vendor-report.viewAny` but NOT `tenant.vendor-report.invoice` navigates to `/vendor-reports` | Page loads |
| 2 | Verify "Invoices" tab button is NOT rendered in the tab bar | Tab hidden |

#### TC-IR-N02: No permission — user without `tenant.vendor-report.viewAny` gets 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-report.viewAny` navigates to `/vendor-reports` | Gate::authorize() fails |
| 2 | Verify 403 Forbidden response | Aborted |

#### TC-IR-N03: Invalid `from_date` format triggers Carbon parse exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `from_date` to `"not-a-date"` in the URL query | Invalid date |
| 2 | Navigate to `/vendor-reports?tab=invoice-register&from_date=not-a-date` | Carbon::parse throws InvalidArgumentException |
| 3 | Verify 500 error is thrown (no try-catch around dates()) | 500 Internal Server Error |

#### TC-IR-N04: Invalid `to_date` format triggers Carbon parse exception

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `to_date` to `"invalid"` in the URL query | Invalid date |
| 2 | Navigate to `/vendor-reports?tab=invoice-register&to_date=invalid` | Carbon::parse throws |
| 3 | Verify 500 error | 500 Internal Server Error |

#### TC-IR-N05: Date range with no matching invoices shows empty table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range to a period with no invoice data (e.g. year 2010) | No matching invoices |
| 2 | Submit filter | Page reloads |
| 3 | Verify table shows "No invoices found." in tbody | Empty state message |

#### TC-IR-N06: Empty result — stat cards show zero values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter with a date range that has no invoices | Empty result |
| 2 | Verify `total_invoices` stat card shows `0` | Zero count |
| 3 | Verify "Fully Paid", "Overdue" cards show 0 and progress bars at 0% | Zero stats |

#### TC-IR-N07: Non-existent vendor_id returns empty results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `vendor_id` to a very large non-existent ID (e.g. 99999) | No matching vendor |
| 2 | Submit filter | Page reloads |
| 3 | Verify empty invoice table with "No invoices found." | Empty result |

#### TC-IR-N08: Non-existent agreement_id returns empty results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `agreement_id` to a non-existent ID (e.g. 99999) | No matching agreement |
| 2 | Submit filter | Page reloads |
| 3 | Verify empty invoice table | Empty result |

#### TC-IR-N09: Non-existent item_id returns empty results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `item_id` to a non-existent ID (e.g. 99999) | No matching agreement_item |
| 2 | Submit filter | Page reloads |
| 3 | Verify empty invoice table | Empty result |

#### TC-IR-N10: Null `invoice_date` records excluded from trend chart

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have at least one invoice with `invoice_date = NULL` | Null date invoice exists |
| 2 | Load invoice register | Chart renders |
| 3 | Verify `invoiceChartTrend` collection does NOT include the null-date invoice (filtered by `$i->invoice_date !== null`) | Excluded from chart |
| 4 | Verify table still shows the null-date invoice with date as `—` | Present in table |

#### TC-IR-N11: All invoices fully paid — pending/partial/overdue counts are zero

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Filter to a date range where all invoices have `balance_due <= 0` | All fully paid |
| 2 | Verify `paid_count` equals `total_invoices` | All paid |
| 3 | Verify `pending_count`, `partial_count`, `overdue_count` are all 0 | Zero values |

### 10.3 Code Review TC Steps

#### TC-CR-IR01: getInvoiceRegisterData() — query chain and eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndInvoice::with(['vendor','agreement','agreementItem.item'])` | Eager loading includes 3 relations |
| 2 | Review `->where('is_active', true)->whereBetween('invoice_date', [$from, $to])` | Active + date range filter |
| 3 | Review filter chain: vendor_id, agreement_id, item_id → agreement_item_id | All 3 filters present |
| 4 | Review `clone $query` before pagination for summary calculations | Base query preserved |
| 5 | Review `orderByDesc('invoice_date')->paginate(10, ['*'], 'invoice_page')->appends($request->query())` | Pagination + appends |

#### TC-CR-IR02: dates() method — Carbon::parse fallback and default range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$from` default: `$r->filled('from_date') ? Carbon::parse($r->from_date) : now()->startOfMonth()` | Default = start of month |
| 2 | Review `$to` default: `$r->filled('to_date') ? Carbon::parse($r->to_date) : now()->endOfMonth()` | Default = end of month |
| 3 | Review `$from->startOfDay()` and `$to->endOfDay()` | Start/end of day applied |
| 4 | Note: No try-catch around Carbon::parse — invalid strings cause 500 error | Exception handling gap |

#### TC-CR-IR03: invoiceSummary — paid/pending/partial count logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `paid_count`: `$invoices->where('balance_due', '<=', 0)->count()` | <= 0 includes zero and negative balance |
| 2 | Review `pending_count`: `$invoices->where('balance_due', '>', 0)->where('amount_paid', 0)->count()` | Pending = unpaid |
| 3 | Review `partial_count`: `$invoices->where('balance_due', '>', 0)->where('amount_paid', '>', 0)->count()` | Partial = some paid |
| 4 | Review `overdue_count`: filters `balance_due > 0 && due_date && due_date->isPast()` | Overdue logic |
| 5 | Note: A single invoice cannot be both pending and partial (mutually exclusive conditions) | Correct mutual exclusion |

#### TC-CR-IR04: collection_rate — division by zero guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoices->sum('net_payable') > 0` before division | Guard present |
| 2 | Review guard: if net_payable > 0 → round(amount_paid / net_payable * 100, 1); else → 0 | Division safe |
| 3 | Note: Same guard pattern appears in `getVendorLedgerSummaryData()` (ledgerSummary.collection_rate and per-vendor collection_rate) | Consistent pattern |

#### TC-CR-IR05: invoiceChartStatus — hardcoded label array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoiceChartStatus` array — 4 entries with hardcoded label strings | Hardcoded labels |
| 2 | Review mapping: Fully Paid → paid_count, Partially Paid → partial_count, Unpaid → pending_count, Overdue → overdue_count | Correct mapping |
| 3 | Note: Labels are not translatable and not driven from DB — if status definitions change, labels must be manually updated | Maintenance weakness |

#### TC-CR-IR06: invoiceChartTrend — date null guard and Y-m grouping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->filter(fn($i) => $i->invoice_date !== null)` | Null date filter |
| 2 | Review `->groupBy(fn($i) => $i->invoice_date->format('Y-m'))` | Monthly grouping key |
| 3 | Review mapping: month=`format('M Y')`, total=sum net_payable, paid=sum amount_paid, count=group count | All 4 fields mapped |
| 4 | Review `->sortBy(fn($v, $k) => $k)` — sorts by Y-m key asc | Correct chronological order |

#### TC-CR-IR07: invoiceChartVendor — top 8 sorting and take(8) limit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->groupBy('vendor_id')` | Grouped by vendor |
| 2 | Review mapped fields: vendor_name (from first record), total (sum net_payable), count (group count) | Fields correct |
| 3 | Review `->sortByDesc('total')->take(8)->values()` | Top 8 by total descending |
| 4 | Note: `vendor_name` falls back to `'Unknown'` if vendor relation is null | Fallback present |

#### TC-CR-IR08: Blade view — date formatting with null-safe operator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `{{ $inv->invoice_date?->format('d M Y') ?? '—' }}` | Null-safe operator (PHP 8.0+) |
| 2 | Review `{{ $inv->due_date?->format('d M Y') ?? '—' }}` | Same pattern for due_date |
| 3 | Note: Requires `invoice_date` cast as `date` in model — without cast, `format()` call on null causes error | Model cast dependency |

#### TC-CR-IR09: Filter mapping — item_id parameter mapped to agreement_item_id column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($request->filled('item_id')) $query->where('agreement_item_id', $request->item_id)` | item_id → agreement_item_id |
| 2 | Verify the blade dropdown for `item_id` sends the `id` of VndItem | Dropdown sources from VndItem |
| 3 | Note: The filter cascading (vendor → agreement → item) is implemented via AJAX `getFilteredOptions()` | Cascading works |

#### TC-CR-IR10: Pagination — invoice_page page name consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller: `paginate(10, ['*'], 'invoice_page')` | Page name = invoice_page |
| 2 | Review Blade: `$invoiceRecords->links()` and `$invoiceRecords->firstItem()` | Laravel auto-links |
| 3 | Review `$invoiceRecords->total()` in badge | Total count displayed |
| 4 | Review `appends($request->query())` — preserves filter params across pages | Query params persisted |

#### TC-CR-IR11: Index method — shared filter dropdowns with other reports

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `filterVendors` — `Vendor::active()->orderBy('vendor_name')->get()` | Shared across all report tabs |
| 2 | Review `filterAgreements` — filtered by vendor_id if present | Shared |
| 3 | Review `filterItems` — filtered by agreement_id or vendor_id | Shared |
| 4 | Review `$this->getInvoiceRegisterData($request)` called within `array_merge()` with all other report data | Merged into single view |

#### TC-CR-IR12: Blade status badge logic — 3-state + overdue indicator

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `@if($inv->balance_due <= 0)` → "Paid" (green) | Fully paid |
| 2 | Review `@elseif($inv->amount_paid > 0)` → "Partial" (info) | Partially paid |
| 3 | Review `@else` → "Unpaid" (warning) | Unpaid |
| 4 | Review overdue badge: `@if($inv->due_date?->isPast() && $inv->balance_due > 0)` → "OD" red badge next to due date | Overdue indicator |

### 10.4 Dependency TC Steps

#### TC-D-IR01: VndInvoice with() eager loading requires all 3 FK relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndInvoice record has `vendor_id` pointing to valid VndVendor | Vendor relation loads |
| 2 | VndInvoice record has `agreement_id` pointing to valid VndAgreement | Agreement relation loads |
| 3 | VndInvoice record has `agreement_item_id` pointing to valid VndAgreementItem with `item` relation | AgreementItem + Item load |
| 4 | If any FK is null, eager loading returns null for that relation (null-safe operators in Blade handle gracefully) | Null-safe fallback |

#### TC-D-IR02: Item filter uses agreement_item_id — requires VndAgreementItem record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem record with `item_id = X` and `agreement_id = Y` exists | Agreement item exists |
| 2 | User selects item drop-down value = X (which is VndItem.id) | Filter parameter item_id = X |
| 3 | Controller applies `where('agreement_item_id', $request->item_id)` — this assumes VndItem.id and VndAgreementItem.agreement_item_id share the same value | Correct mapping depends on data consistency |

#### TC-D-IR03: Date casting — invoice_date, due_date cast as `date` in VndInvoice model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$casts` in VndInvoice: `'invoice_date' => 'date'`, `'due_date' => 'date'` | Date casts present |
| 2 | Verify `$inv->invoice_date->format('d M Y')` works (Carbon instance) | Date formatting works |
| 3 | Verify `$inv->due_date->isPast()` returns correct boolean due to Carbon casting | Date comparison works |

#### TC-D-IR04: Balance_due auto-computed via boot saving() event and accessor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndInvoice::boot()` static method registers saving event that sets `balance_due = net_payable - amount_paid` | Computed on save |
| 2 | Review `getBalanceDueAttribute()` accessor also computes `net_payable - amount_paid` | Computed on read |
| 3 | Note: Dual computation — might cause inconsistency if model is not saved after updating amount_paid directly in DB | Dual computation risk |

#### TC-D-IR05: VndInvoice is_active flag scoped in all queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `getInvoiceRegisterData()`: `->where('is_active', true)` | Active filter applied |
| 2 | Verify soft-deleted invoices (deleted_at NOT NULL) are also excluded via SoftDeletes trait | Soft delete also applies |
| 3 | Verify `is_deleted` legacy flag is NOT checked in this query (only is_active) | Only is_active checked |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-reports` | vendor.vendor-reports.index | index() | tenant.vendor-report.viewAny |

**Tab parameter:** `?tab=invoice-register` activates the Invoice Register pane.

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-IR-01 | invoiceChartStatus labels are hardcoded in PHP | **Low** | `['Fully Paid', 'Partially Paid', 'Unpaid', 'Overdue']` — if payment status logic changes, labels must be manually updated; not translatable |
| KI-IR-02 | No try-catch around Carbon::parse in dates() | **Medium** | Passing an invalid date string (e.g. `from_date=not-a-date`) causes an unhandled `InvalidArgumentException` leading to a 500 error |
| KI-IR-03 | item_id filter maps to agreement_item_id column | **Medium** | The dropdown sources from `VndItem` (id = item_id), but the query filters on `agreement_item_id`. This works because VndItem.id matches VndAgreementItem.agreement_item_id by convention — no explicit FK validation exists |
| KI-IR-04 | Balance_due dual computation | **Low** | `balance_due` is computed both in `boot saving()` event (on save) and via a getter accessor `getBalanceDueAttribute()` — if DB value is out of sync, the accessor takes precedence |
| KI-IR-05 | Index view merges all 5 report data sets | **Info** | All report tabs' data (ledger, agreement, invoice, outstanding, payment) are fetched on every page load regardless of active tab — performance impact with large datasets |
| KI-IR-06 | Chart data computed from full filtered set (not paginated) | **Info** | Summary and chart data are derived from `clone $baseCountQuery->get()` (all matching records), while the table shows only the current page — charts represent the full filtered set, not just the current page |

---

## 13. Feature Summary Matrix

| Feature | Method | Key Models | Pagination |
|---------|--------|------------|------------|
| Invoice Register Tab | index() + getInvoiceRegisterData() | VndInvoice, Vendor, VndAgreement, VndAgreementItem | 10 per page (`invoice_page`) |
| Stat Cards | getInvoiceRegisterData() → invoiceSummary | VndInvoice | None (full set aggregate) |
| Trend Chart | getInvoiceRegisterData() → invoiceChartTrend | VndInvoice | None (full set aggregate) |
| Status Chart | getInvoiceRegisterData() → invoiceChartStatus | VndInvoice | None (full set aggregate) |
| Top Vendor Chart | getInvoiceRegisterData() → invoiceChartVendor | VndInvoice, Vendor | None (top 8) |
| Filter: vendor_id | getInvoiceRegisterData() | VndInvoice.vendor_id | N/A |
| Filter: agreement_id | getInvoiceRegisterData() | VndInvoice.agreement_id | N/A |
| Filter: item_id | getInvoiceRegisterData() | VndInvoice.agreement_item_id | N/A |
| Filter: date_range | getInvoiceRegisterData() | VndInvoice.invoice_date | N/A |
