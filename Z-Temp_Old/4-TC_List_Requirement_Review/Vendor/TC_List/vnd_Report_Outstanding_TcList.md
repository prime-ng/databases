# vnd_Report_Outstanding_TcList

## Module: Vendor → Vendor Reports → Outstanding Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Reports (Tabbed Interface: Ledger, Agreements, Invoices, Outstanding, Payments) |
| Feature | Outstanding Report — list of invoices where `net_payable - amount_paid > 0`, with aging analysis, summary, and charts |
| URL(s) | `/vendor-reports` (with `?tab=outstanding-report`) |
| Controller | `Modules\Vendor\Http\Controllers\VendorReportController` |
| Method | `getOutstandingReportData()` |
| Model(s) | `VndInvoice` (with `vendor.vendorType` relation) |
| Permission Gate | `tenant.vendor-report.viewAny` (index), `tenant.vendor-report.outstanding` (tab) |
| Pagination | 10 per page, page name `outstanding_page` |
| Date Filter | **NONE** — Outstanding report queries all-time data (no `from_date`/`to_date` used) |

---

## 2. Pre-conditions

- Required permission: `tenant.vendor-report.viewAny` (page access) + `tenant.vendor-report.outstanding` (tab visibility)
- At least one invoice record in `vnd_invoices` with `is_active = true` and `net_payable > amount_paid`
- For aging bucket tests: invoices with due_dates spanning a range that produces overdue_days values of 0, 1, 30, 31, 60, 61, 90+
- For chart tests: invoices from multiple vendors (>10 vendors) with varying balance_due
- For filter tests: invoices belonging to specific vendor, agreement, and item combinations

---

## 3. Default Data Load

### 3.1 Outstanding Report Query

The `getOutstandingReportData()` method returns:
- `outstandingRecords` — Paginated VndInvoice records with `vendor.vendorType` relation, filtered where `is_active = true` AND `net_payable - amount_paid > 0`
- `outstandingSummary` — Aggregated stats over all matching invoices
- `outstandingChartVendor` — Top 10 vendors by balance_due
- `outstandingChartAging` — Aging buckets 0–30, 31–60, 61–90 (hardcoded labels)
- `outstandingChartWeekly` — Overdue invoices grouped by week number

**Query:**
```php
VndInvoice::with(['vendor.vendorType'])
    ->where('is_active', true)
    ->whereRaw('net_payable - amount_paid > 0')
```

**Filters (optional):**
- `vendor_id` — Exact match on `vendor_id`
- `agreement_id` — Exact match on `agreement_id`
- `item_id` — Exact match on `agreement_item_id`

**NO date range filter** — this is the only report tab that does not use `$this->dates($request)`.

### 3.2 Computed Field

Each invoice is augmented with:
- `overdue_days` — `$inv->due_date ? max(0, (int) now()->startOfDay()->diffInDays($inv->due_date->startOfDay(), false) * -1) : 0`
  - If `due_date` is null: `overdue_days = 0`
  - If `due_date` is in the future (or today): `overdue_days = 0` (within due)
  - If `due_date` is in the past: positive integer = days overdue

### 3.3 Summary Fields

| Key | Type | Computation |
|-----|------|-------------|
| total_outstanding | float | sum of all `balance_due` |
| total_invoices | int | count of all outstanding invoices |
| overdue_count | int | count where `overdue_days > 0` |
| within_due_count | int | count where `overdue_days === 0` |
| overdue_30 | float | sum `balance_due` where `overdue_days` 1–30 |
| overdue_60 | float | sum `balance_due` where `overdue_days` 31–60 |
| overdue_90 | float | sum `balance_due` where `overdue_days` > 60 |
| avg_overdue_days | float | average of `overdue_days` among overdue invoices |
| largest_outstanding | float | max `balance_due` across all outstanding invoices |

### 3.4 Chart Data

**outstandingChartVendor:**
- Grouped by `vendor_id`, sorted by sum(`balance_due`) desc, top 10
- Each entry: `name`, `amount`, `invoice_count`

**outstandingChartAging:**
- Hardcoded associative array with labels `0–30 Days`, `31–60 Days`, `61–90 Days`
- Values drawn from `outstandingSummary['overdue_30']`, `['overdue_60']`, `['overdue_90']`

**outstandingChartWeekly:**
- Overdue invoices only (`overdue_days > 0`)
- Grouped by `ceil(overdue_days / 7)` → "Week N"
- Each entry: `label`, `amount` (sum balance_due), `count`

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_invoices` — Invoice Table (relevant columns for Outstanding Report)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| agreement_id | INT UNSIGNED | YES | NULL | FK → vnd_agreements(id) ON DELETE SET NULL |
| agreement_item_id | INT UNSIGNED | YES | NULL | FK → vnd_agreement_items_jnt(id) ON DELETE SET NULL |
| invoice_number | VARCHAR(50) | NOT NULL | — | Unique per vendor (uq_vnd_invoice_no) |
| invoice_date | DATE | NOT NULL | — | Invoice issue date |
| due_date | DATE | YES | NULL | Payment due date |
| net_payable | DECIMAL(12,2) | NOT NULL | — | Total invoice amount |
| amount_paid | DECIMAL(12,2) | NOT NULL | 0.00 | Amount paid so far |
| balance_due | DECIMAL(12,2) | NOT NULL | — | Computed: `net_payable - amount_paid` (also an accessor) |
| status | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) for vnd_invoices.status |
| is_active | TINYINT(1) | NOT NULL | 1 | Active flag |
| remarks | VARCHAR(512) | YES | NULL | Remarks |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_vnd_invoice_no` (`vendor_id`, `invoice_number`)
- KEY `fk_vnd_inv_vendor` (`vendor_id`)
- KEY `fk_vnd_inv_agreement` (`agreement_id`)
- KEY `fk_vnd_inv_agreement_item` (`agreement_item_id`)
- KEY `fk_vnd_inv_status` (`status`)

**Computed balance_due:**
- Defined as an accessor: `$this->net_payable - $this->amount_paid`
- Also set in `saving` model event before persist

---

## 5. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | All-time Outstanding | Query does NOT apply any `from_date`/`to_date` filter — shows all outstanding invoices regardless of date |
| BC-BIZ-02 | Outstanding = Positive Balance | Only invoices where `net_payable - amount_paid > 0` are included (via `whereRaw`) |
| BC-BIZ-03 | Active Invoices Only | `where('is_active', true)` — soft-deleted or deactivated invoices excluded |
| BC-BIZ-04 | overdue_days Computed per Invoice | Each invoice gets `overdue_days` via Carbon diff: `max(0, overdue_days)` — overdue is always >= 0 |
| BC-BIZ-05 | Null due_date = Not Overdue | If `due_date` is null, `overdue_days` is set to 0 (treated as within due) |
| BC-BIZ-06 | Aging Bucket Boundaries | overdue_30 = overdue_days 1–30, overdue_60 = 31–60, overdue_90 = > 60 |
| BC-BIZ-07 | Aging Chart Labels Hardcoded | `outstandingChartAging` labels are hardcoded strings `0–30 Days`, `31–60 Days`, `61–90 Days` — note label "61–90 Days" maps to bucket `> 60` |
| BC-BIZ-08 | Top 10 Vendor Chart | `outstandingChartVendor` sorted by amount desc, limited to 10 |
| BC-BIZ-09 | Weekly Grouping | `outstandingChartWeekly` groups overdue invoices by `ceil(overdue_days / 7)` — only invoices with overdue_days > 0 |
| BC-BIZ-10 | Pagination | `outstanding_page` pagination name; 10 per page; `appends($request->query())` preserves filters |

---

## 6. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_inv_vendor | vnd_invoices.vendor_id | vnd_vendors.id | RESTRICT |
| fk_vnd_inv_agreement | vnd_invoices.agreement_id | vnd_agreements.id | SET NULL |
| fk_vnd_inv_agreement_item | vnd_invoices.agreement_item_id | vnd_agreement_items_jnt.id | SET NULL |
| fk_vnd_inv_status | vnd_invoices.status | sys_dropdown_table.id | RESTRICT |

---

## 7. Test Case Summary

### 7.1 Outstanding Report — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-ORP01 | Outstanding Report | Positive | Outstanding tab loads with all filter elements and summary cards | 5 |
| TC-VND-ORP02 | Outstanding Report | Positive | Outstanding list displays paginated invoices with overdue_days computed | 4 |
| TC-VND-ORP03 | Outstanding Report | Positive | Filter by vendor_id | 3 |
| TC-VND-ORP04 | Outstanding Report | Positive | Filter by agreement_id | 3 |
| TC-VND-ORP05 | Outstanding Report | Positive | Filter by item_id | 3 |
| TC-VND-ORP06 | Outstanding Report | Positive | Summary — total_outstanding and total_invoices computed correctly | 3 |
| TC-VND-ORP07 | Outstanding Report | Positive | Summary — overdue_count and within_due_count correct | 3 |
| TC-VND-ORP08 | Outstanding Report | Positive | Summary — aging buckets overdue_30 (1–30 days) | 3 |
| TC-VND-ORP09 | Outstanding Report | Positive | Summary — aging buckets overdue_60 (31–60 days) | 3 |
| TC-VND-ORP10 | Outstanding Report | Positive | Summary — aging buckets overdue_90 (> 60 days) | 3 |
| TC-VND-ORP11 | Outstanding Report | Positive | Summary — avg_overdue_days and largest_outstanding computed | 3 |
| TC-VND-ORP12 | Outstanding Report | Positive | Chart — outstandingChartVendor top 10 vendors | 3 |
| TC-VND-ORP13 | Outstanding Report | Positive | Chart — outstandingChartAging hardcoded buckets (0–30, 31–60, 61–90) | 3 |
| TC-VND-ORP14 | Outstanding Report | Positive | Chart — outstandingChartWeekly grouped by week | 3 |
| TC-VND-ORP15 | Outstanding Report | Positive | Edge — overdue_days exactly 1 (minimum overdue) | 3 |
| TC-VND-ORP16 | Outstanding Report | Positive | Edge — overdue_days exactly 30 (boundary: end of 1–30 bucket) | 3 |
| TC-VND-ORP17 | Outstanding Report | Positive | Edge — overdue_days exactly 31 (boundary: start of 31–60 bucket) | 3 |
| TC-VND-ORP18 | Outstanding Report | Positive | Edge — overdue_days exactly 60 (boundary: end of 31–60 bucket) | 3 |
| TC-VND-ORP19 | Outstanding Report | Positive | Edge — overdue_days exactly 61 (boundary: start of > 60 bucket) | 3 |
| TC-VND-ORP20 | Outstanding Report | Positive | Edge — overdue_days exactly 90 (within > 60 bucket) | 3 |
| TC-VND-ORP21 | Outstanding Report | Positive | Edge — due_date = today (overdue_days = 0, within_due) | 3 |
| TC-VND-ORP22 | Outstanding Report | Positive | Edge — due_date in the future (overdue_days = 0, within_due) | 3 |
| TC-VND-ORP23 | Outstanding Report | Positive | Pagination — page navigation on outstanding_page (10 per page) | 4 |
| TC-VND-ORP24 | Outstanding Report | Positive | No date filter — invoices from any date appear regardless of invoice_date | 3 |
| TC-VND-ORP25 | Outstanding Report | Positive | AJAX getFilteredOptions — agreements by vendor_id | 3 |
| TC-VND-ORP26 | Outstanding Report | Positive | AJAX getFilteredOptions — items by agreement_id or vendor_id | 5 |

### 7.2 Outstanding Report — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-ORN01 | Outstanding Report | Negative | No outstanding data — all invoices fully paid | 3 |
| TC-VND-ORN02 | Outstanding Report | Negative | No outstanding data — all invoices deactivated (is_active=false) | 3 |
| TC-VND-ORN03 | Outstanding Report | Negative | No outstanding data — no invoices exist in system | 3 |
| TC-VND-ORN04 | Outstanding Report | Negative | Null due_date on outstanding invoice (overdue_days defaults to 0) | 3 |
| TC-VND-ORN05 | Outstanding Report | Negative | Permission — access without tenant.vendor-report.viewAny | 2 |
| TC-VND-ORN06 | Outstanding Report | Negative | Permission — tab hidden without tenant.vendor-report.outstanding | 2 |
| TC-VND-ORN07 | Outstanding Report | Negative | Filter — non-existent vendor_id (no results) | 2 |
| TC-VND-ORN08 | Outstanding Report | Negative | Filter — non-existent agreement_id (no results) | 2 |
| TC-VND-ORN09 | Outstanding Report | Negative | Filter — non-existent item_id (no results) | 2 |

### 7.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR-OR01 | Code Review | Review | overdue_days calculation logic with Carbon diff | 5 |
| TC-CR-OR02 | Code Review | Review | Hardcoded aging chart labels mismatch with bucket definitions | 3 |
| TC-CR-OR03 | Code Review | Review | No date range filter applied (contrast with other report tabs) | 3 |
| TC-CR-OR04 | Code Review | Review | Query — whereRaw vs computed balance_due accessor redundancy | 4 |
| TC-CR-OR05 | Code Review | Review | Charts — weekly grouping uses ceil division on overdue_days | 3 |
| TC-CR-OR06 | Code Review | Review | Charts — vendor chart top 10, aging chart hardcoded labels | 3 |
| TC-CR-OR07 | Code Review | Review | Data transformation duplicated on paginated + collection invoices | 4 |

---

## 8. Test Case Steps

### 8.1 Positive TC Steps — Outstanding Report

#### TC-VND-ORP01: Outstanding tab loads with all filter elements and summary cards

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-report.viewAny` and `tenant.vendor-report.outstanding` navigates to `/vendor-reports?tab=outstanding-report` | Outstanding report tab loads |
| 2 | Verify filter dropdowns present: vendor_id, agreement_id, item_id | All 3 filter controls visible |
| 3 | Verify NO from_date / to_date input fields (unlike other tabs) | Date range absent |
| 4 | Verify summary section with cards: total_outstanding, total_invoices, overdue_count, within_due_count, avg_overdue_days, largest_outstanding | All summary fields displayed |
| 5 | Verify chart containers present: outstandingChartVendor, outstandingChartAging, outstandingChartWeekly | 3 chart containers visible |

#### TC-VND-ORP02: Outstanding list displays paginated invoices with overdue_days computed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to outstanding report where multiple outstanding invoices exist (10+ records) | Tab loads |
| 2 | Verify paginated table with columns: invoice_number, vendor_name, invoice_date, due_date, net_payable, amount_paid, balance_due, overdue_days | All columns present |
| 3 | Verify each row shows overdue_days computed correctly (diff from due_date to now, 0 if within due) | overdue_days displayed |
| 4 | Verify pagination links use `outstanding_page` parameter name with 10 per page | Pagination active |

#### TC-VND-ORP03: Filter by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor from vendor_id dropdown that has outstanding invoices | Vendor selected |
| 2 | Submit filter/refresh | List filtered to that vendor |
| 3 | Verify all displayed invoices belong to the selected vendor | Filtered correctly |

#### TC-VND-ORP04: Filter by agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor (to populate agreement dropdown), then select an agreement_id | Agreement selected |
| 2 | Submit filter | List filtered |
| 3 | Verify all displayed invoices belong to the selected agreement | Filtered correctly |

#### TC-VND-ORP05: Filter by item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a vendor and/or agreement, then select an item_id | Item selected |
| 2 | Submit filter | List filtered |
| 3 | Verify all displayed invoices belong to the selected agreement_item_id | Filtered correctly |

#### TC-VND-ORP06: Summary — total_outstanding and total_invoices computed correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: 3 outstanding invoices with balance_due = 100, 200, 300 | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify total_outstanding = 600 and total_invoices = 3 | Summary correct |

#### TC-VND-ORP07: Summary — overdue_count and within_due_count correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: 2 invoices overdue (due_date in past), 1 invoice within due (due_date in future) | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_count = 2, within_due_count = 1 | Counts correct |

#### TC-VND-ORP08: Summary — aging buckets overdue_30 (1–30 days)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: invoice with overdue_days = 15, balance_due = 500 | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_30 (sum of balance_due for 1–30 days) includes this invoice's amount | Bucket correct |

#### TC-VND-ORP09: Summary — aging buckets overdue_60 (31–60 days)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: invoice with overdue_days = 45, balance_due = 700 | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_60 (sum of balance_due for 31–60 days) includes this invoice's amount | Bucket correct |

#### TC-VND-ORP10: Summary — aging buckets overdue_90 (> 60 days)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: invoice with overdue_days = 90, balance_due = 1000 | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_90 (sum of balance_due for > 60 days) includes this invoice's amount | Bucket correct |

#### TC-VND-ORP11: Summary — avg_overdue_days and largest_outstanding computed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: invoices with overdue_days 10, 20, 30 and balance_due 100, 500, 1000 | Test data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify avg_overdue_days = (10+20+30)/3 = 20, largest_outstanding = 1000 | Computed correctly |

#### TC-VND-ORP12: Chart — outstandingChartVendor top 10 vendors

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: outstanding invoices across 12 different vendors with varying balance_due amounts | Data across 12 vendors |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify chart shows top 10 vendors sorted by balance_due descending (max 10 entries) | Top 10 shown |

#### TC-VND-ORP13: Chart — outstandingChartAging hardcoded buckets

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: outstanding invoices in all 3 aging ranges | All buckets populated |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify chart displays exactly 3 buckets labeled `0–30 Days`, `31–60 Days`, `61–90 Days` with correct values | 3 buckets rendered |

#### TC-VND-ORP14: Chart — outstandingChartWeekly grouped by week

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create test data: overdue invoices spanning multiple weeks (overdue_days 7, 14, 21, 35) | Multi-week data |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify chart groups by week number (Week 1, Week 2, Week 3, Week 5) with summed balance_due | Weekly grouping correct |

#### TC-VND-ORP15: Edge — overdue_days exactly 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = yesterday (overdue_days = 1) | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice appears in overdue_count and is bucketed to overdue_30 (1–30 days) | Correct bucket |

#### TC-VND-ORP16: Edge — overdue_days exactly 30

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = 30 days ago | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice bucketed to overdue_30 (1–30 inclusive), NOT overdue_60 | Boundary correct |

#### TC-VND-ORP17: Edge — overdue_days exactly 31

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = 31 days ago | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice bucketed to overdue_60 (31–60), NOT overdue_30 | Boundary correct |

#### TC-VND-ORP18: Edge — overdue_days exactly 60

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = 60 days ago | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice bucketed to overdue_60 (31–60 inclusive), NOT overdue_90 | Boundary correct |

#### TC-VND-ORP19: Edge — overdue_days exactly 61

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = 61 days ago | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice bucketed to overdue_90 (> 60), NOT overdue_60 | Boundary correct |

#### TC-VND-ORP20: Edge — overdue_days exactly 90

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = 90 days ago | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify invoice bucketed to overdue_90 (> 60), balance_due included, and weekly chart shows Week 13 (ceil(90/7)=13) | Correct bucket + week |

#### TC-VND-ORP21: Edge — due_date = today (overdue_days = 0, within_due)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = today | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_days = 0, counted in within_due_count, NOT in overdue_count | Correct handling |

#### TC-VND-ORP22: Edge — due_date in the future (overdue_days = 0, within_due)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create invoice with due_date = tomorrow | Data created |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_days = 0 (max with negative prevents negative values), counted as within_due | Correct handling |

#### TC-VND-ORP23: Pagination — page navigation on outstanding_page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 25 outstanding invoices | 25 invoices exist |
| 2 | Navigate to outstanding report | Page 1 shows 10 records |
| 3 | Click page 2 | URL contains `outstanding_page=2`, next 10 records shown |
| 4 | Verify filter parameters persist across pages (appends) | Filters preserved in pagination links |

#### TC-VND-ORP24: No date filter — invoices from any date appear

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create outstanding invoice with invoice_date = 2 years ago | Old invoice exists |
| 2 | Create outstanding invoice with invoice_date = today | Recent invoice exists |
| 3 | Navigate to outstanding report | Both invoices appear (no date filter applied) |

#### TC-VND-ORP25: AJAX getFilteredOptions — agreements by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements (AR-001, AR-002), Vendor Y has 1 agreement (AR-003) | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX request |
| 3 | Verify JSON response contains 2 objects each with `id` and `text` fields for AR-001 and AR-002 | Filtered correctly |

#### TC-VND-ORP26: AJAX getFilteredOptions — items by agreement_id or vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has item I3; Vendor V1 has agreements A1, A2 | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=items&agreement_id=A1` | Items by agreement |
| 3 | Verify JSON contains I1 and I2 only (items linked via agreementItems where agreement_id=A1) | Filtered by agreement |
| 4 | Send AJAX: `GET /vendor-reports?get_options=items&vendor_id=V1` (no agreement_id) | Items by vendor fallback |
| 5 | Verify JSON contains I1, I2, I3 (all items linked to V1's agreements via agreementItems.agreement) | Vendor-scoped fallback |

### 8.2 Negative TC Steps — Outstanding Report

#### TC-VND-ORN01: No outstanding data — all invoices fully paid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure all invoices have net_payable = amount_paid (fully paid) | No outstanding balance |
| 2 | Navigate to outstanding report | Tab loads with empty table |
| 3 | Verify summary shows total_outstanding = 0, total_invoices = 0 | Empty state handled |

#### TC-VND-ORN02: No outstanding data — all invoices deactivated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set is_active = false on all invoices that have outstanding balance | No active outstanding invoices |
| 2 | Navigate to outstanding report | Tab loads with empty table |
| 3 | Verify query excludes is_active = false invoices | Empty state correct |

#### TC-VND-ORN03: No outstanding data — no invoices exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure vnd_invoices table is empty | No invoices |
| 2 | Navigate to outstanding report | Tab loads with empty table |
| 3 | Verify summary shows all zero/empty values gracefully | Graceful empty state |

#### TC-VND-ORN04: Null due_date on outstanding invoice

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create outstanding invoice with due_date = NULL (nullable column) | Invoice exists |
| 2 | Navigate to outstanding report | Tab loads |
| 3 | Verify overdue_days = 0 (due_date null defaults to 0), counted in within_due_count | Null handled gracefully |

#### TC-VND-ORN05: Permission — access without tenant.vendor-report.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-report.viewAny` accesses `/vendor-reports` | 403 Forbidden |
| 2 | Verify Gate::authorize() blocks access | Aborted |

#### TC-VND-ORN06: Permission — tab hidden without tenant.vendor-report.outstanding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User lacks `tenant.vendor-report.outstanding` but has `tenant.vendor-report.viewAny` | Dashboard loads |
| 2 | Navigate to `/vendor-reports` | Outstanding tab NOT visible in tab bar |
| 3 | Verify `@can('tenant.vendor-report.outstanding')` directive hides the tab | Tab hidden |

#### TC-VND-ORN07: Filter — non-existent vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set vendor_id = 99999 (non-existent) | Filter applied |
| 2 | Navigate to outstanding report with this filter | Empty result set |

#### TC-VND-ORN08: Filter — non-existent agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set agreement_id = 99999 (non-existent) | Filter applied |
| 2 | Navigate to outstanding report with this filter | Empty result set |

#### TC-VND-ORN09: Filter — non-existent item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_id = 99999 (non-existent) | Filter applied |
| 2 | Navigate to outstanding report with this filter | Empty result set |

### 8.3 Code Review TC Steps

#### TC-CR-OR01: overdue_days calculation logic with Carbon diff

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review expression: `now()->startOfDay()->diffInDays($inv->due_date->startOfDay(), false) * -1` | Uses non-absolute diff and negates |
| 2 | Review `max(0, ...)` wrapper — ensures overdue_days never negative | Clamped to 0 |
| 3 | Review null-coalescing: `$inv->due_date ? ... : 0` | Null due_date results in 0 |
| 4 | Verify `startOfDay()` on both operands ensures day-level granularity (no time-of-day skew) | Day-level diff |
| 5 | Note: `diffInDays` with `$absolute=false` returns negative when date is past, positive when future; negation flips sign | Logic verified |

#### TC-CR-OR02: Hardcoded aging chart labels mismatch with bucket definitions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `overdue_90` definition: `$i->overdue_days > 60` | Bucket is strictly > 60 |
| 2 | Review `outstandingChartAging` label: `'61–90 Days'` mapped to `overdue_90` | Label implies upper bound 90 |
| 3 | Note discrepancy: label `61–90 Days` suggests an upper bound of 90, but the filter is `> 60` (no upper bound — includes 90, 100, etc.) | **Known Issue: label misleading** |

#### TC-CR-OR03: No date range filter applied (contrast with other report tabs)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Compare `getOutstandingReportData()` with `getVendorLedgerSummaryData()` | Outstanding has NO `$this->dates($request)` call |
| 2 | Review `index()` method — `$fromDate, $toDate` extracted but never passed to `getOutstandingReportData` | Date variables unused in outstanding |
| 3 | Confirm `outstandingRecords` query has no `whereBetween('invoice_date')` clause | All-time data intentionally |

#### TC-CR-OR04: Query — whereRaw vs computed balance_due accessor redundancy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `whereRaw('net_payable - amount_paid > 0')` in query | DB-level filter |
| 2 | Review `balance_due` accessor in VndInvoice model: `$this->net_payable - $this->amount_paid` | Accessor repeats same computation |
| 3 | Review `balance_due` is also set on `saving` event | Redundant computation |
| 4 | Note: `whereRaw` is necessary because accessor cannot be used in DB query, but the logic duplication across model and query is notable | Design observation |

#### TC-CR-OR05: Charts — weekly grouping uses ceil division on overdue_days

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `ceil($i->overdue_days / 7)` for week grouping | Week 1 = overdue_days 1-7 |
| 2 | Review that weekly chart only includes overdue invoices (`$overdueInvoices`) | Non-overdue excluded |
| 3 | Note: Week N label uses raw `ceil` result — no sorting key normalization for gaps | Gaps in weeks expected (Week 1, Week 3 if no Week 2) |

#### TC-CR-OR06: Charts — vendor chart top 10, aging chart hardcoded labels

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `outstandingChartVendor`: `sortByDesc('amount')->take(10)->values()` | Top 10 vendors |
| 2 | Review `outstandingChartAging`: hardcoded associative array `['0–30 Days' => ..., '31–60 Days' => ..., '61–90 Days' => ...]` | Labels hardcoded, not dynamic |
| 3 | Review that `outstandingChartAging` uses `round($value, 2)` for values | 2 decimal rounding |

#### TC-CR-OR07: Data transformation duplicated on paginated + collection invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `outstandingRecords->getCollection()->transform(...)` | Paginated records transformed |
| 2 | Review `$outstandingInvoices = (clone $baseCountQuery)->get()->transform(...)` | Unpaginated collection separately transformed |
| 3 | Review the transform closure (setting `overdue_days`) is identical in both places | Code duplication |
| 4 | Note: Could be DRY'd up with a local scope or a reusable method | Refactoring opportunity |

---

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-reports` | vendor-reports.index | index() | tenant.vendor-report.viewAny |
| GET | `/vendor-reports?tab=outstanding-report` | vendor-reports.index (with tab) | index() → getOutstandingReportData() | tenant.vendor-report.viewAny + tenant.vendor-report.outstanding (tab visibility) |

---

## 10. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-OR01 | Hardcoded aging chart label `61–90 Days` implies upper bound 90, but bucket filter is `> 60` (unbounded) | **Medium** | Label `61–90 Days` maps to `overdue_90` which has condition `overdue_days > 60`. An invoice 200 days overdue is included in this bucket, but the label suggests it caps at 90 days. Label should either be `> 60 Days` or `61+ Days`. |
| KI-OR02 | No date range filter — all-time data always loaded | **Low** | Unlike other 4 report tabs (Ledger, Agreements, Invoices, Payments) which respect `from_date` / `to_date`, the Outstanding report is always all-time. This is likely intentional (outstanding = cumulative) but differs from user expectation if they apply a date filter expecting it to work across all tabs. |
| KI-OR03 | overdue_days logic duplicated in two transform closures | **Low** | The `transform()` for setting `overdue_days` is identical in both the paginated records and the collection used for summary/charts. Could be extracted to a reusable method or query scope. |
| KI-OR04 | `balance_due` computed in 3 places (accessor, saving event, whereRaw) | **Low** | `balance_due = net_payable - amount_paid` is defined in the model accessor, the saving boot event, AND the report query uses `whereRaw('net_payable - amount_paid > 0')`. Triple redundancy. |
| KI-OR05 | No `exists` validation on filter IDs | **Low** | If vendor_id / agreement_id / item_id filter refers to non-existent records, query runs but returns empty result with no user feedback. |
