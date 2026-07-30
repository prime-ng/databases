# vnd_Vendor_Dashboard_TcList

## Module: Vendor → Vendor Dashboard

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Dashboard (Single Endpoint) |
| Features | Dashboard Data — Basic Counts, Vendor Types, Category-wise Spend, Spend Analysis Summary, Payment Status Summary (Paid/Pending/Overdue), Monthly Trend, Top 5 Vendors by Spend, Recent Invoices (5), Payment Methods Distribution, Percentage Calculations with Color Assignment |
| URL(s) | `/dashboard/data` |
| Controller | `Modules\Vendor\Http\Controllers\VendorDashboardController` |
| Model(s) | `VendorDashboard` (empty — no table, used only as type-hint import), `Vendor`, `VndAgreement`, `VndItem`, `VndInvoice`, `VndPayment`, `Dropdown` |
| Validation | None — no FormRequest; `from_date`/`to_date` parsed via `Carbon::parse()` without format validation |
| Permission Gates | `Gate::any([tenant.vendor.viewAny, tenant.vendor-item.viewAny, tenant.vendor-agreement.viewAny, tenant.vendor-invoice.viewAny, tenant.vendor-payment.viewAny, tenant.usage-log.viewAny]) \|\| abort(403)` |
| Soft Deletes | Vendors filtered by `Vendor::active()` scope (is_active = true) |
| Events | None — no activityLog calls in dashboard |

---

## 2. Pre-conditions

- Required permission: any one of the 6 dashboard permissions (`tenant.vendor.viewAny`, `tenant.vendor-item.viewAny`, `tenant.vendor-agreement.viewAny`, `tenant.vendor-invoice.viewAny`, `tenant.vendor-payment.viewAny`, `tenant.usage-log.viewAny`)
- At least one active vendor record (for basic counts) — `Vendor::active()` scope
- At least one active vendor type in `sys_dropdown_table` with key LIKE `vnd_vendors.vendor_type_id.%` (for vendor types dropdown and category fallback)
- For invoice-related sections: at least one active invoice within the date range
- For payment methods: at least one successful payment (`status=SUCCESS`, `is_deleted=false`) within the date range
- For top vendors calculation: active vendors with invoices in date range and optionally payments (for avg_payment_days)
- For monthly trend: invoices spanning multiple months within the date range

---

## 3. Default Data Load

### 3.1 Date Range Defaults

When `from_date` and `to_date` are not provided in the request:

| Parameter | Default Value | Format |
|-----------|---------------|--------|
| from_date | `Carbon::now()->startOfMonth()` | First day of current month, 00:00:00 |
| to_date | `Carbon::now()->endOfMonth()` | Last day of current month, 23:59:59 |

When values are provided, they are parsed via `Carbon::parse()` without format validation — `from_date` gets `startOfDay()`, `to_date` gets `endOfDay()`.

### 3.2 Returned JSON Structure (15 top-level keys)

| Key | Type | Source |
|-----|------|--------|
| `total_vendors` | int | `Vendor::active()->count()` |
| `total_invoices` | int | `VndInvoice::whereBetween('invoice_date', [...])->count()` |
| `total_pay_amount` | float | Sum of `amount_paid` from invoices in date range |
| `items` | int | `VndItem::active()->count()` |
| `agreements` | int | `VndAgreement::where('status', STATUS_ACTIVE)->count()` |
| `spend_analysis` | object | Aggregated from categorySpend |
| `payment_status` | object | Paid/Pending/Overdue with count, amount, percentage |
| `category_spend` | array | Per-vendor-type: amount, count, paid, due, percentage, color |
| `monthly_trend` | array | Per-month aggregations via raw SQL |
| `top_vendors` | array | Top 5 active vendors by total_amount descending |
| `recent_invoices` | array | Last 5 active invoices by invoice_date descending |
| `payment_methods` | array | Successful payments grouped by paymentMode value |
| `vendor_types` | array | All active vendor types from dropdown |
| `date_range` | object | from, to (Y-m-d), display (d M Y - d M Y) |

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_vendors` — Primary Vendor Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_name | VARCHAR(100) | NOT NULL | — | Unique vendor name |
| vendor_type_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Deleted flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

### 4.2 `vnd_invoices` — Invoice Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| invoice_number | VARCHAR(100) | NOT NULL | — | Invoice number |
| invoice_date | DATE | NOT NULL | — | Invoice date |
| due_date | DATE | YES | NULL | Due date |
| net_payable | DECIMAL(15,2) | YES | 0.00 | Net payable amount |
| amount_paid | DECIMAL(15,2) | YES | 0.00 | Amount paid |
| balance_due | DECIMAL(15,2) | YES | 0.00 | Computed: net_payable - amount_paid (set on saving) |
| status | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) (invoice status) |
| is_active | TINYINT(1) | YES | 1 | Active flag |

### 4.3 `vnd_payments` — Payment Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| invoice_id | INT UNSIGNED | NOT NULL | — | FK → vnd_invoices(id) |
| payment_date | DATE | NOT NULL | — | Payment date |
| amount | DECIMAL(15,2) | YES | 0.00 | Payment amount |
| payment_mode | INT UNSIGNED | YES | NULL | FK → sys_dropdown_table(id) (payment mode) |
| status | VARCHAR(50) | YES | NULL | Payment status (e.g., 'SUCCESS') |
| is_deleted | TINYINT(1) | YES | 0 | Soft delete flag |

### 4.4 `vnd_agreements` — Agreement Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| status | VARCHAR(50) | NOT NULL | — | Status constant (VndAgreement::STATUS_ACTIVE) |

### 4.5 `vnd_items` — Item Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| is_active | TINYINT(1) | YES | 1 | Active flag |

### 4.6 `sys_dropdown_table` — Dropdown Reference Table (Referenced)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| key | VARCHAR(255) | NOT NULL | — | Dropdown key (e.g., `vnd_vendors.vendor_type_id.1`) |
| value | VARCHAR(255) | NOT NULL | — | Display value (e.g., `Service Provider`) |
| is_active | TINYINT(1) | YES | 1 | Active flag |

---

## 5. BC-VAL — Validation Rules

### 5.1 Input Parameters

| Parameter | Type | Default | Parsing | Validation |
|-----------|------|---------|---------|------------|
| from_date | string (date) | `Carbon::now()->startOfMonth()` | `Carbon::parse($request->from_date)->startOfDay()` | **None** — no format validation; Carbon::parse will throw on invalid format |
| to_date | string (date) | `Carbon::now()->endOfMonth()` | `Carbon::parse($request->to_date)->endOfDay()` | **None** — no format validation; Carbon::parse will throw on invalid format |

**Known Gap:** No input validation on `from_date`/`to_date` format — invalid date strings cause a `Carbon\Exceptions\InvalidFormatException` (500 error).

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Access |
|----------------|-------------------|--------|
| tenant.vendor.viewAny | getDashboardData() | Grants access to ALL dashboard data |
| tenant.vendor-item.viewAny | getDashboardData() | Grants access to ALL dashboard data |
| tenant.vendor-agreement.viewAny | getDashboardData() | Grants access to ALL dashboard data |
| tenant.vendor-invoice.viewAny | getDashboardData() | Grants access to ALL dashboard data |
| tenant.vendor-payment.viewAny | getDashboardData() | Grants access to ALL dashboard data |
| tenant.usage-log.viewAny | getDashboardData() | Grants access to ALL dashboard data |

**Behaviour:** `Gate::any([...6 permissions...]) || abort(403)` — any single one of the 6 permissions grants full access to ALL dashboard data. No granular scoping per section. If none are granted, `abort(403)` is triggered.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-D01 | Multi-Permission Gate with OR abort | getDashboardData() uses `Gate::any([6 permissions]) || abort(403)` — any one grants full access |
| BC-BIZ-D02 | Date Range Defaults | When `from_date`/`to_date` not provided, defaults to start/end of current month |
| BC-BIZ-D03 | Basic Counts | `totalVendors` from `Vendor::active()`, `agreements` from `VndAgreement::where('status', STATUS_ACTIVE)`, `items` from `VndItem::active()`, `totalInvoices`/`totalPayAmount` from invoices in date range |
| BC-BIZ-D04 | Vendor Types from Dropdown | Fetches `Dropdown` where `key LIKE 'vnd_vendors.vendor_type_id.%'` and `is_active = true` |
| BC-BIZ-D05 | Category-wise Spend | Groups invoices by `vendor.vendorType.id` with fallback to `'unknown'`; computes `net_payable`/`amount_paid`/`balance_due` sums |
| BC-BIZ-D06 | Category Fallback (No Data) | If `$categorySpend` is empty AND vendor types exist, creates zero-value entries for each vendor type |
| BC-BIZ-D07 | Spend Analysis Summary | Aggregates `invoice_count`, `total_amount`, `paid_amount`, `due_amount` from `$categorySpend` collection |
| BC-BIZ-D08 | Payment Status Split — Paid | `balance_due = 0` → Paid (count + sum of net_payable) |
| BC-BIZ-D09 | Payment Status Split — Pending | `balance_due > 0` AND `due_date > now` → Pending (count + sum of balance_due) |
| BC-BIZ-D10 | Payment Status Split — Overdue | `balance_due > 0` AND `due_date <= now` → Overdue (count + sum of balance_due) |
| BC-BIZ-D11 | Monthly Trend via Raw SQL | Uses `DATE_FORMAT(invoice_date, '%Y-%m')` and `DATE_FORMAT(invoice_date, '%b %Y')` with GROUP BY and COALESCE sums — MySQL-specific |
| BC-BIZ-D12 | Top 5 Vendors | Maps ALL active vendors, computes invoice stats + avg payment days from payments, sorts by `total_amount` DESC, takes 5 |
| BC-BIZ-D13 | Average Payment Days Calculation | For each vendor, finds successful payments (`VndPayment` where `status=SUCCESS`, `is_deleted=false`), computes `payment_date - invoice_date` in days, averages |
| BC-BIZ-D14 | Recent Invoices (5) | Active invoices in date range with vendor + statusDropdown relations, ordered by `invoice_date` DESC, limited to 5 |
| BC-BIZ-D15 | Recent Invoice Status Fallback | If `statusDropdown->value` is 'Unknown', determines status manually: `balance_due=0` → 'Paid', `due_date <= now` → 'Overdue', else 'Pending' |
| BC-BIZ-D16 | Payment Methods Distribution | Successful payments grouped by `paymentMode->value`; includes `payment_count` and `total_amount` |
| BC-BIZ-D17 | Percentage Calculations | `paidPercentage = (paidAmount / totalAmount) * 100`, protected against division by zero (returns 0 if totalAmount = 0) |
| BC-BIZ-D18 | Category Colors | 20 hardcoded hex colors assigned cyclically to categories (`$colors[$index % 20]`) |
| BC-BIZ-D19 | Empty VendorDashboard Model | Model has no table (`$table` not set), no fillable fields — used only for type hint import in controller |
| BC-BIZ-D20 | Monolithic Single Method | Entire dashboard (10+ data sections) is computed in a single `getDashboardData()` method — no granular endpoints, no pagination, no caching |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_invoice_vendor | vnd_invoices.vendor_id | vnd_vendors.id | CASCADE (implied) |
| fk_vnd_payment_invoice | vnd_payments.invoice_id | vnd_invoices.id | CASCADE (implied) |
| fk_vnd_agreement_vendor | vnd_agreements.vendor_id | vnd_vendors.id | CASCADE (implied) |
| fk_vnd_item_vendor | vnd_items.vendor_id | vnd_vendors.id | CASCADE (implied) |
| fk_vnd_vendor_type | vnd_vendors.vendor_type_id | sys_dropdown_table.id | RESTRICT |
| fk_vnd_invoice_status | vnd_invoices.status | sys_dropdown_table.id | SET NULL (implied) |
| fk_vnd_payment_mode | vnd_payments.payment_mode | sys_dropdown_table.id | SET NULL (implied) |

---

## 9. Test Case Summary

### 9.1 Dashboard — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-D-P01 | Dashboard | Positive | Dashboard loads with default date range (current month) | 4 |
| TC-VND-D-P02 | Dashboard | Positive | Dashboard loads with custom from_date/to_date | 4 |
| TC-VND-D-P03 | Dashboard | Positive | Custom from_date only (to_date defaults to end of month) | 3 |
| TC-VND-D-P04 | Dashboard | Positive | Custom to_date only (from_date defaults to start of month) | 3 |
| TC-VND-D-P05 | Basic Counts | Positive | All 5 basic count fields return correct values | 3 |
| TC-VND-D-P06 | Basic Counts | Positive | Zero basic counts when no active vendors/agreements/items/invoices | 3 |
| TC-VND-D-P07 | Vendor Types | Positive | Vendor types dropdown loads all active types | 3 |
| TC-VND-D-P08 | Vendor Types | Positive | No active vendor types returns empty vendor_types array | 3 |
| TC-VND-D-P09 | Category Spend | Positive | Category-wise spend groups correctly by vendor type with sums | 5 |
| TC-VND-D-P10 | Category Spend | Positive | Category spend fallback — no invoices returns zero-value vendor type entries | 4 |
| TC-VND-D-P11 | Category Spend | Positive | Category spend fallback — no invoices AND no vendor types returns empty array | 3 |
| TC-VND-D-P12 | Spend Analysis | Positive | Spend analysis summary aggregates correctly from category spend | 3 |
| TC-VND-D-P13 | Payment Status | Positive | Paid invoices counted correctly (balance_due = 0) | 3 |
| TC-VND-D-P14 | Payment Status | Positive | Pending invoices counted correctly (balance_due > 0, due_date > now) | 3 |
| TC-VND-D-P15 | Payment Status | Positive | Overdue invoices counted correctly (balance_due > 0, due_date <= now) | 3 |
| TC-VND-D-P16 | Payment Status | Positive | All three payment statuses present simultaneously | 4 |
| TC-VND-D-P17 | Payment Status | Positive | No invoices in range — all payment status counts are 0 | 3 |
| TC-VND-D-P18 | Monthly Trend | Positive | Monthly trend groups invoices by month with correct sums | 4 |
| TC-VND-D-P19 | Monthly Trend | Positive | Empty monthly trend when no invoices in date range | 3 |
| TC-VND-D-P20 | Monthly Trend | Positive | Multiple months spanned across date range | 4 |
| TC-VND-D-P21 | Top Vendors | Positive | Top 5 vendors sorted by total_amount descending | 4 |
| TC-VND-D-P22 | Top Vendors | Positive | Top vendors includes avg_payment_days when payments exist | 4 |
| TC-VND-D-P23 | Top Vendors | Positive | Top vendors shows zero avg_payment_days when no payments exist | 3 |
| TC-VND-D-P24 | Top Vendors | Positive | Fewer than 5 active vendors returns all available | 3 |
| TC-VND-D-P25 | Top Vendors | Positive | No active vendors returns empty top_vendors array | 3 |
| TC-VND-D-P26 | Recent Invoices | Positive | Recent invoices returns 5 most recent by invoice_date DESC | 4 |
| TC-VND-D-P27 | Recent Invoices | Positive | Recent invoice status from statusDropdown when available | 3 |
| TC-VND-D-P28 | Recent Invoices | Positive | Recent invoice status fallback when statusDropdown value is 'Unknown' | 4 |
| TC-VND-D-P29 | Recent Invoices | Positive | Fewer than 5 invoices returns all available | 3 |
| TC-VND-D-P30 | Payment Methods | Positive | Payment methods distribution groups by payment mode | 4 |
| TC-VND-D-P31 | Payment Methods | Positive | No successful payments returns empty payment_methods array | 3 |
| TC-VND-D-P32 | Payment Methods | Positive | Payment method with no paymentMode relation shows as 'Unknown' | 3 |
| TC-VND-D-P33 | Percentages | Positive | Paid/pending/overdue percentages sum to 100% | 3 |
| TC-VND-D-P34 | Percentages | Positive | Zero total amount returns 0% for all statuses (no division by zero) | 3 |
| TC-VND-D-P35 | Category Colors | Positive | Each category gets a color from the 20-color array cyclically | 3 |
| TC-VND-D-P36 | Category Colors | Positive | More than 20 categories wraps around using modulo | 3 |
| TC-VND-D-P37 | Date Range | Positive | Date range in response reflects provided from_date/to_date | 3 |
| TC-VND-D-P38 | Date Range | Positive | Date range display format is 'd M Y - d M Y' | 3 |
| TC-VND-D-P39 | Auth | Positive | Any single permission grants full access to all dashboard data | 4 |
| TC-VND-D-P40 | Category Spend | Positive | Multiple invoices in same vendor type aggregate correctly | 3 |
| TC-VND-D-P41 | Category Spend | Positive | Category sorted by total_spend descending | 3 |
| TC-VND-D-P42 | Vendor Dashboard Model | Positive | Empty VendorDashboard model imports without error (used as type hint) | 2 |
| TC-VND-D-P43 | Top Vendors | Positive | Vendor type shown in top_vendors.vendor_type field | 3 |
| TC-VND-D-P44 | Recent Invoices | Positive | Recent invoices includes due_date and balance_due fields | 3 |
| TC-VND-D-P45 | Payment Methods | Positive | Payment methods sorted by total_amount descending | 3 |
| TC-VND-D-P46 | Monthly Trend | Positive | Monthly trend month_display is formatted as 'Mon YYYY' | 3 |
| TC-VND-D-P47 | Spend Analysis | Positive | spend_analysis.paid_amount + spend_analysis.due_amount = spend_analysis.total_amount (when all invoices accounted) | 3 |
| TC-VND-D-P48 | Vendor Types | Positive | Vendor types array contains id and category for each type | 3 |
| TC-VND-D-P49 | Basic Counts | Positive | Items and agreements counts are NOT date-scoped (global counts) | 3 |
| TC-VND-D-P50 | Category Spend | Positive | Category with vendor_type_id FK broken maps to 'Uncategorized' category name | 3 |

### 9.2 Dashboard — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-D-N01 | Auth | Negative | No permissions — all 6 Gate permissions missing returns 403 Forbidden | 2 |
| TC-VND-D-N02 | Date Input | Negative | Invalid from_date format (non-date string) throws 500 error | 2 |
| TC-VND-D-N03 | Date Input | Negative | Invalid to_date format (non-date string) throws 500 error | 2 |
| TC-VND-D-N04 | Date Input | Negative | from_date after to_date returns zero counts (no overlap) | 3 |
| TC-VND-D-N05 | Date Input | Negative | Empty from_date string with `$request->filled()` returning false defaults to startOfMonth | 2 |
| TC-VND-D-N06 | Date Input | Negative | Empty to_date string with `$request->filled()` returning false defaults to endOfMonth | 2 |
| TC-VND-D-N07 | Basic Counts | Negative | No active vendors — total_vendors = 0, other counts may still be non-zero | 2 |
| TC-VND-D-N08 | Category Spend | Negative | Vendor with null vendor_type_id — groupBy falls back to 'unknown' category | 3 |
| TC-VND-D-N09 | Category Spend | Negative | Invoice vendor relationship returns null — category name shows 'Uncategorized' | 3 |
| TC-VND-D-N10 | Payment Status | Negative | Invoice with balance_due = null treated as zero (paid) | 3 |
| TC-VND-D-N11 | Payment Status | Negative | Invoice with due_date = null filtered out from pending/overdue calculation | 3 |
| TC-VND-D-N12 | Payment Status | Negative | Invoice with balance_due > 0 but due_date = null — not counted as pending or overdue | 3 |
| TC-VND-D-N13 | Recent Invoices | Negative | Status dropdown value is null — falls back to manual status determination | 3 |
| TC-VND-D-N14 | Top Vendors | Negative | Vendor with invoices but vendor relation returns null for vendorType — shows 'Unknown' | 3 |
| TC-VND-D-N15 | Payment Methods | Negative | Payment with null payment_mode — grouped as 'Unknown' | 3 |
| TC-VND-D-N16 | Monthly Trend | Negative | Invoices with null invoice_date excluded from DATE_FORMAT grouping | 2 |
| TC-VND-D-N17 | Date Input | Negative | SQL injection attempt in from_date/to_date — Carbon::parse behaviour with malicious input | 2 |
| TC-VND-D-N18 | Basic Counts | Negative | Soft-deleted vendors still counted if is_active = true (Vendor::active ignores deleted_at) | 3 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-D01 | Code Review | Review | Gate::any() with 6 permissions + || abort(403) — single permission grants full dashboard access | 3 |
| TC-CR-D02 | Code Review | Review | Date defaults — Carbon::now()->startOfMonth() / endOfMonth() when not filled | 3 |
| TC-CR-D03 | Code Review | Review | No caching — entire dashboard recomputed on every request | 2 |
| TC-CR-D04 | Code Review | Review | Monolithic single method returns all 14+ top-level JSON keys — no granular endpoints | 3 |
| TC-CR-D05 | Code Review | Review | Category spend groupBy vendorType with 'unknown' fallback — may produce null category | 4 |
| TC-CR-D06 | Code Review | Review | Category fallback — $categorySpend empty AND $vendorTypes not empty → zero-value entries | 3 |
| TC-CR-D07 | Code Review | Review | Payment status split — three-way filter using balance_due + due_date comparison | 4 |
| TC-CR-D08 | Code Review | Review | Monthly trend — raw SQL DATE_FORMAT (MySQL-specific, not portable) | 3 |
| TC-CR-D09 | Code Review | Review | Top 5 vendors — maps ALL active vendors with per-vendor query (potential N+1) | 4 |
| TC-CR-D10 | Code Review | Review | Recent invoices — manual status fallback when statusDropdown value is 'Unknown' | 4 |
| TC-CR-D11 | Code Review | Review | Payment methods — groupBy paymentMode value with 'Unknown' fallback | 3 |
| TC-CR-D12 | Code Review | Review | 20 hardcoded hex colors array — assigned cyclically via modulo | 3 |
| TC-CR-D13 | Code Review | Review | Percentage calculations with division-by-zero guard | 3 |
| TC-CR-D14 | Code Review | Review | Empty VendorDashboard model — no table property, no fillable, used only as type-hint import | 3 |
| TC-CR-D15 | Code Review | Review | No input validation on from_date/to_date — Carbon::parse throws InvalidFormatException | 3 |
| TC-CR-D16 | Code Review | Review | Response JSON structure — 15 top-level keys verified | 4 |
| TC-CR-D17 | Code Review | Review | Items and agreements counts are global (not date-scoped) vs invoice counts that use date range | 3 |
| TC-CR-D18 | Code Review | Review | VndPayment query uses table-prefixed columns (vnd_payments.status, vnd_payments.is_deleted) | 3 |
| TC-CR-D19 | Code Review | Review | Recent invoices map accesses `$invoice->invoice_no` but controller builds object with `invoice_no` — potential naming mismatch | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-D-D01 | Dependency | Dependency | Vendor::active() scope — where is_active = true | 2 |
| TC-VND-D-D02 | Dependency | Dependency | VndInvoice::scopeInDateRange() — whereBetween on invoice_date | 2 |
| TC-VND-D-D03 | Dependency | Dependency | VndInvoice vendor() relationship — belongsTo Vendor | 2 |
| TC-VND-D-D04 | Dependency | Dependency | VndInvoice statusDropdown() relationship — belongsTo Dropdown | 2 |
| TC-VND-D-D05 | Dependency | Dependency | VndInvoice balanceDue accessor — net_payable - amount_paid | 2 |
| TC-VND-D-D06 | Dependency | Dependency | VndPayment invoice() relationship — belongsTo VndInvoice | 2 |
| TC-VND-D-D07 | Dependency | Dependency | VndPayment paymentMode() relationship — belongsTo Dropdown | 2 |
| TC-VND-D-D08 | Dependency | Dependency | Dropdown key pattern 'vnd_vendors.vendor_type_id.%' for vendor type filtering | 2 |
| TC-VND-D-D09 | Dependency | Dependency | VndAgreement::STATUS_ACTIVE constant existence for agreement count | 2 |
| TC-VND-D-D10 | Dependency | Dependency | VndItem::active() scope — where is_active = true | 2 |
| TC-VND-D-D11 | Dependency | Dependency | Carbon::parse() — relies on Carbon library for date parsing | 2 |
| TC-VND-D-D12 | Dependency | Dependency | VendorDashboard model used in controller import — requires the model file to exist | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Dashboard

#### TC-VND-D-P01: Dashboard loads with default date range (current month)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with any one of 6 dashboard permissions sends GET to `/dashboard/data` without from_date/to_date | 200 OK |
| 2 | Verify `date_range.from` equals first day of current month (Y-m-d) | Default from_date |
| 3 | Verify `date_range.to` equals last day of current month (Y-m-d) | Default to_date |
| 4 | Verify all 14+ top-level keys present in response JSON | Full structure |

#### TC-VND-D-P02: Dashboard loads with custom from_date/to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=2026-01-01&to_date=2026-03-31` | 200 OK |
| 2 | Verify `date_range.from` = "2026-01-01" | Custom from |
| 3 | Verify `date_range.to` = "2026-03-31" | Custom to |
| 4 | Verify all counts/scopes are within Jan 1 – Mar 31, 2026 | Date-scoped data |

#### TC-VND-D-P03: Custom from_date only (to_date defaults to end of month)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=2026-06-15` | 200 OK |
| 2 | Verify `date_range.from` = "2026-06-15" | Custom from |
| 3 | Verify `date_range.to` = "2026-06-30" (end of June 2026) | Default to |

#### TC-VND-D-P04: Custom to_date only (from_date defaults to start of month)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?to_date=2026-06-15` | 200 OK |
| 2 | Verify `date_range.from` = "2026-06-01" (start of June 2026) | Default from |
| 3 | Verify `date_range.to` = "2026-06-15" | Custom to |

#### TC-VND-D-P05: All 5 basic count fields return correct values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure DB has 3 active vendors, 2 active agreements (STATUS_ACTIVE), 4 active items, and 5 active invoices in date range | Pre-condition |
| 2 | GET `/dashboard/data` with date range covering the invoices | 200 OK |
| 3 | Verify `total_vendors` = 3, `agreements` = 2, `items` = 4, `total_invoices` = 5, `total_pay_amount` = sum of amount_paid | Correct counts |

#### TC-VND-D-P06: Zero basic counts when no active records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active vendors, no active agreements, no active items | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `total_vendors` = 0, `agreements` = 0, `items` = 0, `total_invoices` = 0, `total_pay_amount` = 0 | All zeros |

#### TC-VND-D-P07: Vendor types dropdown loads all active types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sys_dropdown_table has 3 active entries with key LIKE 'vnd_vendors.vendor_type_id.%' | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `vendor_types` array has 3 entries, each with `id` and `category` | Types loaded |

#### TC-VND-D-P08: No active vendor types returns empty vendor_types array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active Dropdown entries with key LIKE 'vnd_vendors.vendor_type_id.%' | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `vendor_types` = [] | Empty array |

#### TC-VND-D-P09: Category-wise spend groups correctly by vendor type with sums

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up: Vendor A (type T1) has 2 invoices: Inv1 (net=100, paid=50), Inv2 (net=200, paid=200). Vendor B (type T2) has 1 invoice: Inv3 (net=300, paid=100). All in date range. | Pre-condition |
| 2 | GET `/dashboard/data` covering all invoices | 200 OK |
| 3 | Verify category T1: total_spend=300, invoice_count=2, paid_amount=250, due_amount=50 | T1 aggregated |
| 4 | Verify category T2: total_spend=300, invoice_count=1, paid_amount=100, due_amount=200 | T2 aggregated |
| 5 | Verify categories sorted by total_spend descending (T2 first, then T1) | Sorted |

#### TC-VND-D-P10: Category spend fallback — no invoices returns zero-value vendor type entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure active vendor types exist (e.g., T1, T2) but NO invoices in date range | Pre-condition |
| 2 | GET `/dashboard/data` with date range that has no invoices | 200 OK |
| 3 | Verify `category_spend` has entries for each vendor type with all amounts = 0 | Fallback zero entries |
| 4 | Verify each category entry has: category_id, category, total_spend=0, invoice_count=0, paid_amount=0, due_amount=0, percentage=0, color | Full structure |

#### TC-VND-D-P11: Category spend fallback — no invoices AND no vendor types returns empty array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure NO active vendor types AND NO invoices in date range | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `category_spend` = [] | Empty array |

#### TC-VND-D-P12: Spend analysis summary aggregates correctly from category spend

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Category spend has T1 (total=300, paid=250, due=50) and T2 (total=300, paid=100, due=200) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `spend_analysis.total_invoices` = 3, `total_amount` = 600, `paid_amount` = 350, `due_amount` = 250 | Correct aggregation |

#### TC-VND-D-P13: Paid invoices counted correctly (balance_due = 0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 invoices in date range: Inv1 (balance_due=0), Inv2 (balance_due=0), Inv3 (balance_due=100) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `payment_status.paid.count` = 2, `payment_status.paid.amount` = sum of net_payable for Inv1+Inv2 | Paid counted |

#### TC-VND-D-P14: Pending invoices counted correctly (balance_due > 0, due_date > now)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 invoices in date range: Inv1 (balance_due=200, due_date=future), Inv2 (balance_due=0) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `payment_status.pending.count` = 1, `payment_status.pending.amount` = 200 | Pending counted |

#### TC-VND-D-P15: Overdue invoices counted correctly (balance_due > 0, due_date <= now)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 invoices in date range: Inv1 (balance_due=150, due_date=yesterday), Inv2 (balance_due=0) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `payment_status.overdue.count` = 1, `payment_status.overdue.amount` = 150 | Overdue counted |

#### TC-VND-D-P16: All three payment statuses present simultaneously

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: InvA (balance_due=0), InvB (balance_due=100, due_date=future), InvC (balance_due=200, due_date=past) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify paid.count=1, pending.count=1, overdue.count=1 | Three statuses |
| 4 | Verify paid.amount + pending.amount + overdue.amount = total invoice amount (paid + pending + overdue balance) | Distribution correct |

#### TC-VND-D-P17: No invoices in range — all payment status counts are 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range to a period with no invoices | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `payment_status.paid.count` = 0, `pending.count` = 0, `overdue.count` = 0, all amounts = 0 | Zero statuses |

#### TC-VND-D-P18: Monthly trend groups invoices by month with correct sums

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Inv1 (Jan 2026, net=100, paid=50), Inv2 (Jan 2026, net=200, paid=200), Inv3 (Feb 2026, net=300, paid=100) | Pre-condition |
| 2 | GET `/dashboard/data` with date range covering Jan–Feb 2026 | 200 OK |
| 3 | Verify Jan entry: invoice_count=2, total_amount=300, paid_amount=250, due_amount=50 | January correct |
| 4 | Verify Feb entry: invoice_count=1, total_amount=300, paid_amount=100, due_amount=200 | February correct |

#### TC-VND-D-P19: Empty monthly trend when no invoices in date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set date range with no invoices | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `monthly_trend` = [] | Empty array |

#### TC-VND-D-P20: Multiple months spanned across date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoices in 3 consecutive months within the date range | Pre-condition |
| 2 | GET `/dashboard/data` with 3-month date range | 200 OK |
| 3 | Verify monthly_trend has 3 entries, each with month, month_display, and aggregated sums | 3 months |
| 4 | Verify entries ordered by month ascending | Sorted chronologically |

#### TC-VND-D-P21: Top 5 vendors sorted by total_amount descending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 vendors with invoices: V1 (total=500), V2 (total=400), V3 (total=300), V4 (total=200), V5 (total=100) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify top_vendors array has 5 entries | 5 vendors |
| 4 | Verify vendors ordered by total_amount DESC (500, 400, 300, 200, 100) | Correct order |

#### TC-VND-D-P22: Top vendors includes avg_payment_days when payments exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has invoices with successful payments: payment 10 days after invoice, payment 20 days after invoice | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify V1 in top_vendors has avg_payment_days = 15 (rounded average of 10 and 20) | Avg calculated |

#### TC-VND-D-P23: Top vendors shows zero avg_payment_days when no payments exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has invoices but no successful payments | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify V1 has avg_payment_days = 0 | Zero when no payments |

#### TC-VND-D-P24: Fewer than 5 active vendors returns all available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure only 2 active vendors with invoices exist | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify top_vendors has 2 entries | All vendors returned |

#### TC-VND-D-P25: No active vendors returns empty top_vendors array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active vendors exist | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify top_vendors = [] | Empty array |

#### TC-VND-D-P26: Recent invoices returns 5 most recent by invoice_date DESC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 7 invoices with dates: Jan 1–7, 2026 | Pre-condition |
| 2 | GET `/dashboard/data` covering all of Jan 2026 | 200 OK |
| 3 | Verify recent_invoices has 5 entries | Limited to 5 |
| 4 | Verify invoices ordered by invoice_date DESC (Jan 7, Jan 6, Jan 5, Jan 4, Jan 3) | Most recent first |

#### TC-VND-D-P27: Recent invoice status from statusDropdown when available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with statusDropdown pointing to 'Partially Paid' dropdown entry | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify recent_invoices[0].status = 'Partially Paid' (from dropdown value) | Dropdown status used |

#### TC-VND-D-P28: Recent invoice status fallback when statusDropdown value is 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create InvA (balance_due=0, statusDropdown value='Unknown') → fallback 'Paid' | Pre-condition |
| 2 | Create InvB (balance_due=100, due_date=yesterday, statusDropdown value='Unknown') → fallback 'Overdue' | Pre-condition |
| 3 | Create InvC (balance_due=100, due_date=tomorrow, statusDropdown value='Unknown') → fallback 'Pending' | Pre-condition |
| 4 | GET `/dashboard/data` and verify each invoice.status shows the correct fallback | Fallback applied |

#### TC-VND-D-P29: Fewer than 5 invoices returns all available

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 invoices in date range | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify recent_invoices has 3 entries | All returned |

#### TC-VND-D-P30: Payment methods distribution groups by payment mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create successful payments: 2 by 'Bank Transfer' (total=500), 3 by 'Cheque' (total=300) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify 'Bank Transfer' entry: payment_count=2, total_amount=500 | Bank Transfer aggregated |
| 4 | Verify 'Cheque' entry: payment_count=3, total_amount=300 | Cheque aggregated |

#### TC-VND-D-P31: No successful payments returns empty payment_methods array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no VndPayment records with status='SUCCESS' AND is_deleted=false in date range | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `payment_methods` = [] | Empty array |

#### TC-VND-D-P32: Payment method with no paymentMode relation shows as 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a successful payment with payment_mode = null (or pointing to non-existent dropdown) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify one entry with payment_method = 'Unknown' | Unknown method fallback |

#### TC-VND-D-P33: Paid/pending/overdue percentages sum to 100%

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set up invoices: paid_amount=250, pending_amount=150, overdue_amount=100 (total=500) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify paid.percentage=50, pending.percentage=30, overdue.percentage=20 — sum = 100% | Percentages sum to 100 |

#### TC-VND-D-P34: Zero total amount returns 0% for all statuses (no division by zero)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no invoices in date range (total_amount=0) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify paid.percentage=0, pending.percentage=0, overdue.percentage=0 | No division by zero |

#### TC-VND-D-P35: Each category gets a color from the 20-color array cyclically

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 vendor types with category spend data | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify category_spend[0].color = '#4e73df' (first color), [1] = '#1cc88a' (second), [2] = '#36b9cc' (third) | Colors assigned in order |

#### TC-VND-D-P36: More than 20 categories wraps around using modulo

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 22 vendor types with data | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify category_spend[20].color = '#4e73df' (index 20 % 20 = 0 — wraps to first color), [21].color = '#1cc88a' (index 21 % 20 = 1) | Modulo wrap |

#### TC-VND-D-P37: Date range in response reflects provided from_date/to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/dashboard/data?from_date=2026-07-01&to_date=2026-07-31` | 200 OK |
| 2 | Verify `date_range.from` = "2026-07-01" | From matches |
| 3 | Verify `date_range.to` = "2026-07-31" | To matches |

#### TC-VND-D-P38: Date range display format is 'd M Y - d M Y'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/dashboard/data?from_date=2026-07-01&to_date=2026-07-31` | 200 OK |
| 2 | Verify `date_range.display` = "01 Jul 2026 - 31 Jul 2026" | Display format correct |
| 3 | Repeat for different dates and verify format consistency | Format consistent |

#### TC-VND-D-P39: Any single permission grants full access to all dashboard data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with ONLY `tenant.vendor.viewAny` permission (no others) accesses `/dashboard/data` | 200 OK with full data |
| 2 | User with ONLY `tenant.vendor-invoice.viewAny` permission accesses `/dashboard/data` | 200 OK with full data |
| 3 | User with ONLY `tenant.vendor-payment.viewAny` permission accesses `/dashboard/data` | 200 OK with full data |
| 4 | User with ONLY `tenant.usage-log.viewAny` permission accesses `/dashboard/data` | 200 OK with full data |

#### TC-VND-D-P40: Multiple invoices in same vendor type aggregate correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 (type T1) has 3 invoices: net=100, 200, 300; paid=50, 100, 150; due=50, 100, 150 | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify T1 category: total_spend=600, invoice_count=3, paid_amount=300, due_amount=300 | Aggregated correctly |

#### TC-VND-D-P41: Category sorted by total_spend descending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create: T1 (total=100), T2 (total=500), T3 (total=300) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify category order: T2 (500), T3 (300), T1 (100) | Descending order |

#### TC-VND-D-P42: Empty VendorDashboard model imports without error (used as type hint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VendorDashboard model file — no `$table` property, `$fillable = []` | Empty model |
| 2 | Review VendorDashboardController import: `use Modules\Vendor\Models\VendorDashboard;` | Imported for type hint, not functionally used |

#### TC-VND-D-P43: Vendor type shown in top_vendors.vendor_type field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor V1 has vendorType with value='Service Provider' | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify top_vendors entry for V1 has vendor_type = 'Service Provider' | Vendor type displayed |

#### TC-VND-D-P44: Recent invoices includes due_date and balance_due fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has due_date=2026-07-15, balance_due=250.50 | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify recent_invoice entry has due_date and balance_due fields with correct values | Full fields |

#### TC-VND-D-P45: Payment methods sorted by total_amount descending

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Payments: BT (total=500), CH (total=1000), UPI (total=300) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify payment_methods order: CH (1000), BT (500), UPI (300) | Descending sort |

#### TC-VND-D-P46: Monthly trend month_display is formatted as 'Mon YYYY'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice dated 2026-01-15 exists | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify monthly_trend[0].month = "2026-01" and month_display = "Jan 2026" | Format correct |

#### TC-VND-D-P47: spend_analysis sum consistency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Category spend: T1 (total=300, paid=200, due=100), T2 (total=500, paid=300, due=200) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify paid_amount (500) + due_amount (300) = total_amount (800) | Sum consistent |

#### TC-VND-D-P48: Vendor types array contains id and category for each type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Sys_dropdown has entry id=5, value='Consultant' with key 'vnd_vendors.vendor_type_id.5' | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify vendor_types array contains entry with `id=5` and `category='Consultant'` | Structured correctly |

#### TC-VND-D-P49: Items and agreements counts are NOT date-scoped (global counts)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Items table has 5 active items, Agreements has 3 active agreements (regardless of date range) | Pre-condition |
| 2 | GET `/dashboard/data` with any date range | 200 OK |
| 3 | Verify `items` = 5 and `agreements` = 3 regardless of date range params | Global counts |

#### TC-VND-D-P50: Category with broken vendor_type_id FK maps to 'Uncategorized' category name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice belongs to a vendor whose vendor_type_id points to a non-existent dropdown record | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify category_spend entry for broken FK has `category_id = null` and `category = 'Uncategorized'` | FK fallback |

### 10.2 Negative TC Steps — Dashboard

#### TC-VND-D-N01: No permissions — all 6 Gate permissions missing returns 403 Forbidden

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without any of the 6 dashboard permissions sends GET to `/dashboard/data` | 403 Forbidden |
| 2 | Verify `Gate::any([...])` fails and `abort(403)` is triggered | Aborted |

#### TC-VND-D-N02: Invalid from_date format throws 500 error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=not-a-date` | 500 Internal Server Error |
| 2 | Verify Carbon\Exceptions\InvalidFormatException is thrown from Carbon::parse() | Invalid format exception |

#### TC-VND-D-N03: Invalid to_date format throws 500 error

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?to_date=invalid-date-string` | 500 Internal Server Error |
| 2 | Verify Carbon\Exceptions\InvalidFormatException is thrown | Invalid format exception |

#### TC-VND-D-N04: from_date after to_date returns zero counts (no overlap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=2026-12-31&to_date=2026-01-01` | 200 OK |
| 2 | Verify `total_invoices` = 0 (no invoices can exist in inverted range) | Zero invoice count |
| 3 | Verify all date-scoped sections return zero/empty data | Date-scoped empty |

#### TC-VND-D-N05: Empty from_date string defaults to startOfMonth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=&to_date=2026-07-31` | 200 OK |
| 2 | Verify `$request->filled('from_date')` returns false for empty string | Not filled |
| 3 | Verify `date_range.from` = first day of current month (default) | Default applied |

#### TC-VND-D-N06: Empty to_date string defaults to endOfMonth

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=2026-07-01&to_date=` | 200 OK |
| 2 | Verify `$request->filled('to_date')` returns false for empty string | Not filled |
| 3 | Verify `date_range.to` = last day of current month (default) | Default applied |

#### TC-VND-D-N07: No active vendors but other records exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no active vendors (Vendor::active() returns 0), but active invoices, agreements, items exist | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify `total_vendors` = 0, but `agreements` and `items` may be > 0 | Vendor count zero only |

#### TC-VND-D-N08: Vendor with null vendor_type_id — groupBy falls back to 'unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice belongs to vendor with vendor_type_id = null | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify a category entry where category_id = null (from 'unknown' group) | Unknown category fallback |

#### TC-VND-D-N09: Invoice vendor relationship returns null — category name shows 'Uncategorized'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Invoice has vendor_id pointing to non-existent or deleted vendor (vendor() returns null) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify category entry with category = 'Uncategorized' | Uncategorized fallback |

#### TC-VND-D-N10: Invoice with balance_due = null treated as zero (paid)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with balance_due = null (or net_payable - amount_paid = 0) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify null-treated-as-zero invoice counted in paid status (balance_due == 0 check) | Counted as paid |

#### TC-VND-D-N11: Invoice with due_date = null filtered out from pending/overdue

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with balance_due > 0 but due_date = null | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify invoice NOT counted in pending or overdue (due_date null fails `$invoice->due_date->gt(Carbon::now())` and `lte()` checks) | Excluded from both |

#### TC-VND-D-N12: Invoice with balance_due > 0 but due_date = null — not counted as pending or overdue

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with balance_due=500, due_date=null | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify it is excluded from both pending_count and overdue_count (due_date null check fails) | Not counted |

#### TC-VND-D-N13: Status dropdown value is null — falls back to manual status determination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with status = null (no statusDropdown relation) | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify recent invoice.status is determined by balance_due/due_date fallback logic | Manual fallback |

#### TC-VND-D-N14: Vendor with invoices but vendorType relation returns null — shows 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor has no vendorType relation (vendor_type_id null or FK broken) but has invoices | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify top_vendors entry shows vendor_type = 'Unknown' | Unknown type fallback |

#### TC-VND-D-N15: Payment with null payment_mode — grouped as 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create successful payment with payment_mode = null | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify payment_methods contains entry with payment_method = 'Unknown' | Unknown method |

#### TC-VND-D-N16: Invoices with null invoice_date excluded from DATE_FORMAT

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with invoice_date = null | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify null-date invoice not included in monthly_trend (DATE_FORMAT(null) returns null, excluded by GROUP BY) | Excluded |

#### TC-VND-D-N17: Malformed date input via from_date/to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/dashboard/data?from_date=2026-13-01` (invalid month 13) | 500 error from Carbon::parse |
| 2 | Send GET to `/dashboard/data?to_date=2026-00-01` (invalid month 0) | 500 error from Carbon::parse |

#### TC-VND-D-N18: Soft-deleted vendors still counted if is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor is soft-deleted (deleted_at not null) but is_active = 1 | Pre-condition |
| 2 | GET `/dashboard/data` | 200 OK |
| 3 | Verify this vendor IS counted in total_vendors (Vendor::active() scope checks is_active, not deleted_at) | Counted despite soft-delete |

### 10.3 Code Review TC Steps — Dashboard

#### TC-CR-D01: Gate::any() with 6 permissions + || abort(403)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::any([...6 permissions...])` at start of getDashboardData() | Gate present with 6 permissions |
| 2 | Verify `|| abort(403)` — any single permission grants full access, none = 403 | OR abort pattern |
| 3 | Note: No granular scoping — any one permission exposes ALL dashboard sections | No granularity |

#### TC-CR-D02: Date defaults — Carbon::now()->startOfMonth() / endOfMonth()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$request->filled('from_date')` check — empty/unset defaults to `Carbon::now()->startOfMonth()` | Default from |
| 2 | Review `$request->filled('to_date')` check — empty/unset defaults to `Carbon::now()->endOfMonth()` | Default to |
| 3 | Verify `Carbon::parse()` is called without try-catch — invalid dates throw unhandled exception | No validation |

#### TC-CR-D03: No caching — entire dashboard recomputed on every request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review getDashboardData() for any cache/store/remember calls | No caching |
| 2 | Every request re-queries: Vendor counts, invoices, payments, dropdowns → DB queries repeated | Full recompute |

#### TC-CR-D04: Monolithic single method returns all 15 top-level JSON keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review method length — 400+ lines, single method | Monolithic |
| 2 | Verify no pagination — all sections load full dataset (no limit except top_vendors=5, recent_invoices=5) | No pagination |
| 3 | Verify response returns 15 top-level keys (total_vendors, total_invoices, total_pay_amount, items, agreements, spend_analysis, payment_status, category_spend, monthly_trend, top_vendors, recent_invoices, payment_methods, vendor_types, date_range) | Full structure |

#### TC-CR-D05: Category spend groupBy vendorType with 'unknown' fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$invoice->vendor->vendorType->id ?? 'unknown'` — null coalescing on chained relation | FK fallback |
| 2 | Review `$vendorType ? $vendorType->value : 'Uncategorized'` — if vendorType null, shows 'Uncategorized' | Category name fallback |
| 3 | Review `$typeId === 'unknown' ? null : $typeId` — category_id set to null for unknown groups | ID null for unknown |
| 4 | Verify no explicit check that `$invoice->vendor` is not null — potential NPE if vendor deleted | Missing null check |

#### TC-CR-D06: Category fallback — $categorySpend empty AND $vendorTypes not empty → zero-value entries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review condition: `if ($categorySpend->isEmpty() && $vendorTypes->isNotEmpty())` | Fallback trigger |
| 2 | Verify fallback creates object with total_spend=0, invoice_count=0, paid=0, due=0 | Zero values |
| 3 | Verify fallback only triggers when BOTH conditions met — empty spend + existing types | Combined condition |

#### TC-CR-D07: Payment status split — three-way filter using balance_due + due_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review paid filter: `->where('balance_due', 0)` | Paid = zero balance |
| 2 | Review pending filter: `balance_due > 0` AND `due_date->gt(Carbon::now())` | Pending = future due |
| 3 | Review overdue filter: `balance_due > 0` AND `due_date->lte(Carbon::now())` | Overdue = past due |
| 4 | Note: `due_date->gt()` and `->lte()` will throw if due_date is null — only reaches filter if balance_due > 0 already | Null safety gap |

#### TC-CR-D08: Monthly trend — raw SQL DATE_FORMAT (MySQL-specific)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `DATE_FORMAT(invoice_date, '%Y-%m')` — MySQL-specific function | DB-specific SQL |
| 2 | Review `groupByRaw` with same expression | Raw grouping |
| 3 | Note: Not portable to PostgreSQL/SQLite — would break if DB driver changes | Portability issue |

#### TC-CR-D09: Top 5 vendors — maps ALL active vendors with per-vendor query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Vendor::with(['vendorType'])->where('is_active', true)->get()` — loads ALL active vendors | Full vendor load |
| 2 | Review per-vendor `$vendor->invoices()...get()` inside map → N+1 query pattern | N+1 for invoices |
| 3 | Review per-vendor `VndPayment::whereHas('invoice', ...)...get()` inside map → another query per vendor | N+1 for payments |
| 4 | Note: With 100 active vendors, this makes 1 + 100 + 100 = 201 queries | Performance concern |

#### TC-CR-D10: Recent invoices — manual status fallback when statusDropdown value is 'Unknown'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$status === 'Unknown'` check after statusDropdown value read | Fallback trigger |
| 2 | Review fallback: `balance_due == 0` → 'Paid', `due_date->isPast()` → 'Overdue', else 'Pending' | Three-way fallback |
| 3 | Verify `due_date->isPast()` does not handle null due_date — could throw | Null due_date risk |

#### TC-CR-D11: Payment methods — groupBy paymentMode value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$payment->paymentMode ? $payment->paymentMode->value : 'Unknown'` | Group key with fallback |
| 2 | Review `groupBy()` on collection, then `map()` to build result objects | Collection grouping |
| 3 | Note: Could also use DB GROUP BY for efficiency | Collection in-memory |

#### TC-CR-D12: 20 hardcoded hex colors array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review colors array — 20 hardcoded hex values | Hardcoded |
| 2 | Review `$colors[$index % count($colors)]` — cyclic assignment via modulo | Cyclic |
| 3 | Note: Not configurable — no config/DB source for colors | Not configurable |

#### TC-CR-D13: Percentage calculations with division-by-zero guard

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$totalAmount > 0 ? round(($paidAmount / $totalAmount) * 100, 1) : 0` | Guarded |
| 2 | Verify same guard for pendingPercentage and overduePercentage | All three guarded |
| 3 | Verify category percentage also guarded: `$totalAmount > 0 ? round(($item->total_spend / $totalAmount) * 100, 1) : 0` | Category also guarded |

#### TC-CR-D14: Empty VendorDashboard model — no table, no fillable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VendorDashboard.php` — no `$table` property set | No DB table |
| 2 | Review `$fillable = []` — empty | No mass-assignable fields |
| 3 | Note: Model imported with `use Modules\Vendor\Models\VendorDashboard;` in controller but never instantiated — only used as type hint | Unused import |

#### TC-CR-D15: No input validation on from_date/to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review request — no FormRequest, no inline validation for date parameters | No validation |
| 2 | Review `Carbon::parse($request->from_date)` — will throw InvalidFormatException on bad input | Unhandled exception |
| 3 | Note: No try-catch wrapping — 500 error returned to client for bad dates | No graceful error handling |

#### TC-CR-D16: Response JSON structure — 15 top-level keys verified

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review response()->json([...]) — count top-level keys | 15 keys |
| 2 | Verify each key's data type matches: int for counts, object for spend_analysis/payment_status/date_range, array for category_spend/monthly_trend/top_vendors/recent_invoices/payment_methods/vendor_types | Types correct |
| 3 | Verify nested structures: payment_status has paid/pending/overdue each with count, amount, percentage | Nested correct |

#### TC-CR-D17: Items and agreements global counts vs invoice date-scoped counts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndItem::active()->count()` — no date filter | Global count |
| 2 | Review `VndAgreement::where('status', STATUS_ACTIVE)->count()` — no date filter | Global count |
| 3 | Review `VndInvoice::whereBetween('invoice_date', [...])` — date-scoped | Scoped count |

#### TC-CR-D18: VndPayment query uses table-prefixed columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->where('vnd_payments.status', 'SUCCESS')` — table prefix to avoid ambiguity | Table-prefixed |
| 2 | Review `->where('vnd_payments.is_deleted', false)` — table prefix | Table-prefixed |
| 3 | Note: This is required because the WHERE clause joins through invoice table | Ambiguity resolution |

#### TC-CR-D19: Recent invoices map accesses `$invoice->invoice_no`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review map: `'invoice_no' => $invoice->invoice_no` | Property access |
| 2 | Verify VndInvoice model attribute: `invoice_number` (not `invoice_no`) — the object was built in map with `invoice_no` key from `$invoice->invoice_number` | Correct: first map creates object with 'invoice_no', second map reads it |
| 3 | Note: Two-step map — first map creates stdClass with `invoice_no` property, second map reads from that object | Two-step transformation |

### 10.4 Dependency TC Steps — Dashboard

#### TC-VND-D-D01: Vendor::active() scope — where is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Vendor model for `scopeActive()` | Scope exists |
| 2 | Verify `scopeActive()` returns `$query->where('is_active', true)` | Filter by is_active |

#### TC-VND-D-D02: VndInvoice::scopeInDateRange() — whereBetween on invoice_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndInvoice model for `scopeInDateRange()` | Scope exists |
| 2 | Verify scope uses `whereBetween('invoice_date', [$startDate, $endDate])` | Date range filter |

#### TC-VND-D-D03: VndInvoice vendor() relationship — belongsTo Vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndInvoice model for `vendor()` method | Relationship exists |
| 2 | Verify `belongsTo(Vendor::class, 'vendor_id')` | FK correctly mapped |

#### TC-VND-D-D04: VndInvoice statusDropdown() relationship — belongsTo Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndInvoice model for `statusDropdown()` method | Relationship exists |
| 2 | Verify `belongsTo(Dropdown::class, 'status')` | FK mapped to sys_dropdown_table |

#### TC-VND-D-D05: VndInvoice balanceDue accessor — net_payable - amount_paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndInvoice model for `getBalanceDueAttribute()` accessor | Accessor exists |
| 2 | Verify returns `$this->net_payable - $this->amount_paid` | Computed value |
| 3 | Note: `balance_due` is also set in `saving()` boot event (DB column) | Both DB + accessor |

#### TC-VND-D-D06: VndPayment invoice() relationship — belongsTo VndInvoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndPayment model for `invoice()` method | Relationship exists |
| 2 | Verify `belongsTo(VndInvoice::class, 'invoice_id')` | FK correctly mapped |

#### TC-VND-D-D07: VndPayment paymentMode() relationship — belongsTo Dropdown

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndPayment model for `paymentMode()` method | Relationship exists |
| 2 | Verify `belongsTo(Dropdown::class, 'payment_mode')` | FK mapped to sys_dropdown_table |

#### TC-VND-D-D08: Dropdown key pattern 'vnd_vendors.vendor_type_id.%' for vendor type filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Dropdown query: `where('key', 'like', 'vnd_vendors.vendor_type_id.%')` | Key pattern used |
| 2 | Verify `where('is_active', true)` — only active types | Active filter |

#### TC-VND-D-D09: VndAgreement::STATUS_ACTIVE constant existence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndAgreement model for `STATUS_ACTIVE` constant | Constant exists |
| 2 | Verify constant value used in `where('status', VndAgreement::STATUS_ACTIVE)` | Correct usage |

#### TC-VND-D-D10: VndItem::active() scope — where is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review VndItem model for `scopeActive()` | Scope exists |
| 2 | Verify returns `$query->where('is_active', true)` | Active filter |

#### TC-VND-D-D11: Carbon::parse() — relies on Carbon library for date parsing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `use Carbon\Carbon;` import in controller | Imported |
| 2 | Verify `Carbon::parse($request->from_date)` used without format parameter — accepts many formats | Flexible parsing |

#### TC-VND-D-D12: VendorDashboard model file exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `Modules/Vendor/app/Models/VendorDashboard.php` exists | File exists |
| 2 | Verify class extends `BaseModel` and uses `HasFactory` trait | Class structure |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/dashboard/data` | dashboard.data | `VendorDashboardController@getDashboardData` | Any of 6 dashboard permissions via `Gate::any()` |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-D01 | Empty VendorDashboard model with no table — only used as type hint import | **Low** | Model has no `$table` property, `$fillable = []`. Imported in controller with `use Modules\Vendor\Models\VendorDashboard;` but never instantiated — dead import |
| KI-D02 | Single monolithic method returns ALL data — no pagination, no granular endpoints | **High** | 400+ line `getDashboardData()` computes all 10+ sections in one method; no way to fetch individual sections; no pagination |
| KI-D03 | No caching — entire dashboard recomputed on every request | **High** | Every HTTP request re-queries all counts, invoices, payments, dropdowns — performance degrades with data volume |
| KI-D04 | Default date range is current month — no data for months without invoices returns zeros | **Info** | When no invoices exist in current month, all date-scoped sections return zero/empty data (by design) |
| KI-D05 | Gate::any with OR abort(403) — any single permission grants full access to ALL dashboard data | **Medium** | No granular scoping: tenant.vendor.viewAny and tenant.usage-log.viewAny both expose identical full dashboard |
| KI-D06 | Category spend groups by vendorType ID with 'unknown' fallback — may produce null category if vendor_type_id FK is broken | **Medium** | Missing explicit null check on `$invoice->vendor` and `$invoice->vendor->vendorType` chain — could produce unexpected null entries |
| KI-D07 | 20 hardcoded colors array — not configurable | **Low** | Color array defined inline in controller method; no DB/config source for customization |
| KI-D08 | No input validation on from_date/to_date format — Carbon::parse throws unhandled InvalidFormatException | **Medium** | Invalid date strings produce 500 error with no user-friendly message |
| KI-D09 | Monthly trend uses raw SQL DATE_FORMAT — MySQL-specific | **Low** | `DATE_FORMAT(invoice_date, '%Y-%m')` is MySQL-specific; not portable to PostgreSQL/SQLite |
| KI-D10 | Top 5 vendors iterates ALL active vendors with per-vendor queries (N+1 pattern) | **Medium** | For 100 active vendors: 1 query for vendors + 100 for invoices + 100 for payments = 201 queries |
| KI-D11 | Category fallback only triggers when $categorySpend is empty AND vendorTypes exist — silent empty category_spend if both empty | **Info** | If no invoices AND no vendor types, `category_spend` returns `[]` with no fallback entries |
| KI-D12 | Items and agreements counts are NOT date-scoped — users may expect them to match the date range | **Info** | `items` and `agreements` in response are global counts, while `total_invoices` is date-scoped — potential confusion |

---

## 13. Feature Summary Matrix

| Feature | Controller Method | Key Models | Data Source |
|---------|-------------------|------------|-------------|
| Basic Counts | getDashboardData() | Vendor, VndAgreement, VndItem, VndInvoice | Active scopes + whereBetween |
| Vendor Types | getDashboardData() | Dropdown | key LIKE pattern + is_active |
| Category-wise Spend | getDashboardData() | VndInvoice, Vendor, Dropdown | groupBy vendor.vendorType + sums |
| Spend Analysis Summary | getDashboardData() | (aggregated from categorySpend) | Sum of invoice_count, total, paid, due |
| Payment Status Summary | getDashboardData() | VndInvoice, Dropdown | balance_due + due_date split |
| Monthly Trend | getDashboardData() | VndInvoice | Raw SQL DATE_FORMAT + GROUP BY |
| Top 5 Vendors | getDashboardData() | Vendor, VndInvoice, VndPayment | Map all active + sort + take 5 |
| Recent Invoices | getDashboardData() | VndInvoice, Vendor, Dropdown | Order DESC + limit 5 |
| Payment Methods Distribution | getDashboardData() | VndPayment, Dropdown | groupBy paymentMode value |
| Percentage Calculations | getDashboardData() | (computed) | paid/pending/overdue / total |

---

