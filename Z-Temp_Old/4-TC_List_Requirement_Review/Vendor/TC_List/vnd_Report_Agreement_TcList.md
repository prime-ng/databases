# vnd_Report_Agreement_TcList

## Module: Vendor → Reports → Agreement Report

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Feature | Agreement Report — Tab on Vendor Reports Dashboard |
| URL(s) | `/vendor-reports?tab=agreement-report` |
| Controller | `Modules\Vendor\Http\Controllers\VendorReportController` |
| Method | `getAgreementReportData()` |
| Model(s) | `VndAgreement`, `VndAgreementItem`, `VndInvoice`, `VndItem` |
| Permission Gate | `tenant.vendor-report.viewAny` (index), `tenant.vendor-report.agreement` (tab) |
| Pagination | 10 per page, page name `agreement_page` |

---

## 2. Pre-conditions

- Required permission: `tenant.vendor-report.viewAny` to access the report dashboard; `tenant.vendor-report.agreement` to view the Agreement tab
- At least one VndAgreement record with related vendor (VndVendor), agreement items (VndAgreementItem), and items (VndItem)
- For chart tests: agreements with varying statuses (DRAFT, ACTIVE, EXPIRED, TERMINATED), billing cycles (MONTHLY, ONE_TIME, ON_DEMAND), and multiple vendors
- For date filter tests: agreements with start_date/end_date covering various date ranges
- For invoice-based tests: VndInvoice records linked to agreement IDs with net_payable values
- For expiring-soon tests: at least one ACTIVE agreement with end_date = exactly 30 days from now

---

## 3. Default Data Load

### 3.1 Filter Dropdowns (index method)

| Dropdown | Source | Filtering |
|----------|--------|-----------|
| `filterVendors` | `Vendor::active()->orderBy('vendor_name')->get()` | All active vendors |
| `filterAgreements` | `VndAgreement::orderByDesc('id')` → `when(vendor_id)` | Filtered by vendor_id if provided |
| `filterItems` | `VndItem::active()->orderBy('item_name')` → `when(agreement_id)` / `when(vendor_id)` | Filtered by agreement_id or vendor_id |

### 3.2 Agreement Report Data (getAgreementReportData)

The method returns 6 variables:

| Variable | Type | Description |
|----------|------|-------------|
| `agreementRecords` | Paginated Collection | Paginated VndAgreement records (10/page, `agreement_page`) with vendor + agreementItems.item |
| `agreementSummary` | Array | total, active, draft, expired, terminated counts + total_value (net_payable sum from VndInvoice) |
| `agreementChartStatus` | Collection | Grouped by status: status, count, percentage |
| `agreementChartCycle` | Collection | Grouped by billing_cycle: billing_cycle, count, total_value (from invoices) |
| `agreementChartVendor` | Collection | Grouped by vendor_id, top 8 by count: vendor_name, count, total_value |
| `expiringSoon` | Collection | ACTIVE agreements with end_date ≤ 30 days from now |

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_agreements` — Agreement Table (relevant columns only)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_id | INT UNSIGNED | NOT NULL | — | FK → vnd_vendors(id) |
| agreement_ref_no | VARCHAR(100) | NOT NULL | — | Unique reference |
| start_date | DATE | YES | NULL | Agreement start |
| end_date | DATE | YES | NULL | Agreement end |
| status | VARCHAR(20) | YES | 'DRAFT' | DRAFT, ACTIVE, EXPIRED, TERMINATED |
| billing_cycle | VARCHAR(20) | YES | 'MONTHLY' | MONTHLY, ONE_TIME, ON_DEMAND |
| payment_terms_days | INT | YES | 30 | Payment terms |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

### 4.2 `vnd_invoices` — Invoices Table (for total_value)

| Column | Data Type | Nullable | Notes |
|--------|-----------|----------|-------|
| id | INT UNSIGNED | NOT NULL | Primary Key |
| agreement_id | INT UNSIGNED | YES | FK → vnd_agreements(id) |
| net_payable | DECIMAL | YES | Used for total_value sum |
| is_active | TINYINT(1) | YES | Must be true to count |

---

## 5. BC-VAL — Validation Rules

No FormRequest for this feature. Inline validation for AJAX dropdown options (`getFilteredOptions`):
- `get_options` — required (handled via `$request->has()`)
- `vendor_id` — required when type='agreements'
- `agreement_id` / `vendor_id` — used optionally when type='items'

---

## 6. BC-AUTH — Authorization

| Permission Gate | Where Used | Scope |
|----------------|-----------|-------|
| tenant.vendor-report.viewAny | `index()` — `Gate::authorize()` | Full report dashboard access |
| tenant.vendor-report.agreement | Blade `@can` directive in reports/index.blade.php | Agreement report tab visibility |

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Base Query | `VndAgreement::with(['vendor','agreementItems.item'])` — eager loads vendor and item chain |
| BC-BIZ-02 | Filter — vendor_id | `$query->where('vendor_id', $request->vendor_id)` — exact match |
| BC-BIZ-03 | Filter — agreement_id | `$query->where('id', $request->agreement_id)` — exact match |
| BC-BIZ-04 | Filter — item_id | `$query->whereHas('agreementItems', fn($q) => $q->where('item_id', $request->item_id))` — subquery on pivot |
| BC-BIZ-05 | Date Overlap Filter | 3-way OR: start_date BETWEEN range OR end_date BETWEEN range OR (start_date ≤ from AND end_date ≥ to) — any agreement overlapping the period |
| BC-BIZ-06 | Date Filter Conditional | Only applied when `$request->filled('from_date') || $request->filled('to_date')` |
| BC-BIZ-07 | Date Defaults | from = startOfMonth() if not provided, to = endOfMonth() if not provided |
| BC-BIZ-08 | Pagination | `paginate(10, ['*'], 'agreement_page')` with `->appends($request->query())` |
| BC-BIZ-09 | Base Count Clone | `$baseCountQuery = clone $query` before paginate — used for summary/charts on full filtered set |
| BC-BIZ-10 | Summary — total | `$agreements->count()` |
| BC-BIZ-11 | Summary — status counts | `active`, `draft`, `expired`, `terminated` via `->where('status', X)->count()` |
| BC-BIZ-12 | Summary — total_value | `VndInvoice::where('is_active', true)->whereIn('agreement_id', $agreementIds)->sum('net_payable')` |
| BC-BIZ-13 | Chart — Status | Grouped by status, each with count and percentage of total |
| BC-BIZ-14 | Chart — Cycle | Grouped by billing_cycle, each with count and total_value from invoices filtered by those agreement IDs |
| BC-BIZ-15 | Chart — Vendor (Top 8) | Grouped by vendor_id, sorted by count desc, take(8), with vendor_name fallback `?? 'Unknown'`, total_value from invoices |
| BC-BIZ-16 | Expiring Soon | Filters ACTIVE agreements where `$a->end_date` exists and `$a->end_date->diffInDays(now()) <= 30` |
| BC-BIZ-17 | Dropdown — Agreements Filtered | `VndAgreement::when(vendor_id, ...)` — agreements limited by selected vendor |
| BC-BIZ-18 | Dropdown — Items Filtered | Items filtered by agreement_id (via agreementItems) or fallback to vendor_id (via agreementItems.agreement) |
| BC-BIZ-19 | AJAX getOptions | Separate endpoint returning JSON for cascading dropdowns (agreements by vendor, items by agreement/vendor) |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | Notes |
|-------------|--------|-----------------|-------|
| fk_vnd_agreement_vendor | vnd_agreements.vendor_id | vnd_vendors.id | CASCADE |
| fk_vnd_agreement_item_agreement | vnd_agreement_items.agreement_id | vnd_agreements.id | Cascade |
| fk_vnd_agreement_item_item | vnd_agreement_items.item_id | vnd_items.id | Cascade |
| fk_vnd_invoice_agreement | vnd_invoices.agreement_id | vnd_agreements.id | Used for total_value |

---

## 9. Test Case Summary

### 9.1 Agreement Report — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-AGR-P01 | Agreement Report | Positive | Agreement report tab loads with all data sections | 5 |
| TC-AGR-P02 | Agreement Report | Positive | Filter — by vendor_id | 3 |
| TC-AGR-P03 | Agreement Report | Positive | Filter — by agreement_id | 3 |
| TC-AGR-P04 | Agreement Report | Positive | Filter — by item_id | 3 |
| TC-AGR-P05 | Agreement Report | Positive | Filter — by date range (start_date overlap) | 3 |
| TC-AGR-P06 | Agreement Report | Positive | Filter — by date range (end_date overlap) | 3 |
| TC-AGR-P07 | Agreement Report | Positive | Filter — by date range (covering entire range) | 3 |
| TC-AGR-P08 | Agreement Report | Positive | Filter — by date range (combined with vendor_id) | 3 |
| TC-AGR-P09 | Agreement Report | Positive | Filter — date defaults (no from_date/to_date sent) | 3 |
| TC-AGR-P10 | Agreement Report | Positive | Pagination — agreement_page name and 10 per page | 3 |
| TC-AGR-P11 | Agreement Report | Positive | Summary — total count | 3 |
| TC-AGR-P12 | Agreement Report | Positive | Summary — active count | 3 |
| TC-AGR-P13 | Agreement Report | Positive | Summary — draft count | 3 |
| TC-AGR-P14 | Agreement Report | Positive | Summary — expired count | 3 |
| TC-AGR-P15 | Agreement Report | Positive | Summary — terminated count | 3 |
| TC-AGR-P16 | Agreement Report | Positive | Summary — total_value from invoices | 3 |
| TC-AGR-P17 | Agreement Report | Positive | Chart — agreementChartStatus with percentage | 3 |
| TC-AGR-P18 | Agreement Report | Positive | Chart — agreementChartCycle with total_value | 3 |
| TC-AGR-P19 | Agreement Report | Positive | Chart — agreementChartVendor top 8 sorted by count | 3 |
| TC-AGR-P20 | Agreement Report | Positive | ExpiringSoon — ACTIVE agreement with end_date = 30 days from now | 3 |
| TC-AGR-P21 | Agreement Report | Positive | ExpiringSoon — ACTIVE agreement with end_date < 30 days from now | 3 |
| TC-AGR-P22 | Agreement Report | Positive | ExpiringSoon — agreements with non-ACTIVE status excluded even if end_date ≤ 30 | 3 |
| TC-AGR-P23 | Agreement Report | Positive | ExpiringSoon — agreements with null end_date excluded | 3 |
| TC-AGR-P24 | Agreement Report | Positive | Cascading dropdown — agreements filtered by vendor_id | 3 |
| TC-AGR-P25 | Agreement Report | Positive | Cascading dropdown — items filtered by agreement_id | 3 |
| TC-AGR-P26 | Agreement Report | Positive | Cascading dropdown — items filtered by vendor_id (fallback) | 3 |
| TC-AGR-P27 | Agreement Report | Positive | AJAX getFilteredOptions — agreements by vendor_id | 3 |
| TC-AGR-P28 | Agreement Report | Positive | AJAX getFilteredOptions — items by agreement_id or vendor_id | 5 |

### 9.2 Agreement Report — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-AGR-N01 | Agreement Report | Negative | Permission — index without tenant.vendor-report.viewAny | 2 |
| TC-AGR-N02 | Agreement Report | Negative | Permission — agreement tab without tenant.vendor-report.agreement | 2 |
| TC-AGR-N03 | Agreement Report | Negative | Filter — invalid vendor_id (non-existent) | 2 |
| TC-AGR-N04 | Agreement Report | Negative | Filter — invalid agreement_id (non-existent) | 2 |
| TC-AGR-N05 | Agreement Report | Negative | Filter — invalid item_id (non-existent) | 2 |
| TC-AGR-N06 | Agreement Report | Negative | Filter — invalid date format for from_date | 2 |
| TC-AGR-N07 | Agreement Report | Negative | Filter — invalid date format for to_date | 2 |
| TC-AGR-N08 | Agreement Report | Negative | Filter — from_date after to_date | 2 |
| TC-AGR-N09 | Agreement Report | Negative | No data — no agreements match filters | 2 |
| TC-AGR-N10 | Agreement Report | Negative | No data — no agreements in system (empty table) | 2 |
| TC-AGR-N11 | Agreement Report | Negative | Summary — no invoices linked to agreements (total_value = 0) | 2 |
| TC-AGR-N12 | Agreement Report | Negative | Chart — single vendor only (agreementChartVendor has 1 entry) | 2 |
| TC-AGR-N13 | Agreement Report | Negative | Chart — no agreements of a particular status (status chart omits that status) | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | getAgreementReportData() — base query with eager loading | 3 |
| TC-CR02 | Code Review | Review | getAgreementReportData() — 3-way date overlap logic | 4 |
| TC-CR03 | Code Review | Review | getAgreementReportData() — conditional date filter application | 3 |
| TC-CR04 | Code Review | Review | getAgreementReportData() — baseCountQuery clone before paginate | 3 |
| TC-CR05 | Code Review | Review | getAgreementReportData() — pagination with 'agreement_page' page name | 3 |
| TC-CR06 | Code Review | Review | getAgreementReportData() — summary total_value uses VndInvoice with is_active=true | 3 |
| TC-CR07 | Code Review | Review | getAgreementReportData() — agreementChartVendor uses `?? 'Unknown'` fallback | 3 |
| TC-CR08 | Code Review | Review | getAgreementReportData() — agreementChartVendor take(8) top by count | 3 |
| TC-CR09 | Code Review | Review | getAgreementReportData() — expiringSoon filter: diffInDays(now()) <= 30 | 3 |
| TC-CR10 | Code Review | Review | getAgreementReportData() — expiringSoon end_date null check before diff | 3 |
| TC-CR11 | Code Review | Review | dates() method — defaults to startOfMonth/endOfMonth when not provided | 3 |
| TC-CR12 | Code Review | Review | dates() method — Carbon::parse with startOfDay/endOfDay | 3 |
| TC-CR13 | Code Review | Review | getFilteredOptions() — agreements scoped by vendor_id | 3 |
| TC-CR14 | Code Review | Review | getFilteredOptions() — items scoped by agreement_id or vendor_id | 3 |
| TC-CR15 | Code Review | Review | index() — Gate::authorize at method start | 2 |
| TC-CR16 | Code Review | Review | index() — AJAX get_options short-circuit before data load | 3 |
| TC-CR17 | Code Review | Review | index() — array_merge of 5 report data methods | 2 |
| TC-CR18 | Code Review | Review | VndAgreement Model — status constants (DRAFT, ACTIVE, EXPIRED, TERMINATED) | 2 |
| TC-CR19 | Code Review | Review | VndAgreement Model — billing_cycle constants (MONTHLY, ONE_TIME, ON_DEMAND) | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Agreement Report

#### TC-AGR-P01: Agreement report tab loads with all data sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor-report.viewAny` and `tenant.vendor-report.agreement` permissions navigates to `/vendor-reports` | Report dashboard loads |
| 2 | Click "Agreements" tab (`tab=agreement-report`) | Agreement report section loads |
| 3 | Verify `agreementRecords` is a paginated list (10 per page) with vendor name, agreement_ref_no, status, dates | Records displayed |
| 4 | Verify `agreementSummary` shows total, active, draft, expired, terminated counts and total_value | Summary present |
| 5 | Verify `agreementChartStatus`, `agreementChartCycle`, `agreementChartVendor` charts and `expiringSoon` section are present | Charts and extras loaded |

#### TC-AGR-P02: Filter — by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific vendor from vendor dropdown | vendor_id filter applied |
| 2 | Verify agreement list only contains agreements for that vendor | Filtered by vendor |
| 3 | Verify summary/charts reflect only that vendor's data | Summary scoped |

#### TC-AGR-P03: Filter — by agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific agreement from agreement dropdown | agreement_id filter applied |
| 2 | Verify agreement list contains only that one agreement | Filtered by agreement |
| 3 | Verify summary/charts reflect only that agreement's data | Summary scoped |

#### TC-AGR-P04: Filter — by item_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a specific item from item dropdown | item_id filter applied |
| 2 | Verify agreement list only contains agreements that have that item in their agreementItems | Filtered by item |
| 3 | Verify summary/charts reflect only those agreements' data | Summary scoped |

#### TC-AGR-P05: Filter — by date range (start_date overlap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date and to_date such that an agreement's `start_date` falls within the range | Date filter applied |
| 2 | Agreement A has start_date=2026-06-15, end_date=2026-12-15. Query: from=2026-06-01, to=2026-06-30 | Agreement A included (start_date BETWEEN range) |
| 3 | Verify only agreements whose start_date, end_date, or full period overlaps the range are shown | Overlap logic works |

#### TC-AGR-P06: Filter — by date range (end_date overlap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date and to_date such that an agreement's `end_date` falls within the range | Date filter applied |
| 2 | Agreement B has start_date=2025-01-01, end_date=2026-06-15. Query: from=2026-06-01, to=2026-06-30 | Agreement B included (end_date BETWEEN range) |
| 3 | Verify only agreements meeting the overlap condition are shown | end_date overlap works |

#### TC-AGR-P07: Filter — by date range (covering entire range)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date and to_date such that an agreement's period covers the entire range | Date filter applied |
| 2 | Agreement C has start_date=2025-01-01, end_date=2027-12-31. Query: from=2026-06-01, to=2026-06-30 | Agreement C included (start_date ≤ from AND end_date ≥ to) |
| 3 | Verify the covering agreement is included | Covering logic works |

#### TC-AGR-P08: Filter — by date range (combined with vendor_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select vendor_id and a date range simultaneously | Both filters applied |
| 2 | Verify agreements must match BOTH vendor_id AND date overlap condition | Combined filtering |
| 3 | Verify summary/charts reflect combined filter scope | Scoped data |

#### TC-AGR-P09: Filter — date defaults (no from_date/to_date sent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access agreement report tab without sending from_date or to_date | Default dates applied |
| 2 | Verify `dates()` returns `now()->startOfMonth()` for from and `now()->endOfMonth()` for to | Defaults correct |
| 3 | Verify date filter is NOT applied (only from_date/to_date filled check triggers it), so all agreements shown | No date filter applied |

#### TC-AGR-P10: Pagination — agreement_page name and 10 per page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure more than 10 agreements match the filter | Pagination triggered |
| 2 | Verify URL contains `?agreement_page=2` when navigating to page 2 | Page name is agreement_page |
| 3 | Verify exactly 10 records per page (or fewer on last page) | 10 per page |

#### TC-AGR-P11: Summary — total count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply no filters | `agreementSummary.total` equals count of all agreements |
| 2 | Apply vendor_id filter | total equals count of agreements for that vendor |
| 3 | Verify total = active + draft + expired + terminated | Sum of status counts matches total |

#### TC-AGR-P12: Summary — active count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exactly N agreements with status='ACTIVE' in filtered set | Test data seeded |
| 2 | Load agreement report | agreementSummary.active = N |
| 3 | Verify count matches `$agreements->where('status', 'ACTIVE')->count()` | Count correct |

#### TC-AGR-P13: Summary — draft count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exactly N agreements with status='DRAFT' in filtered set | Test data seeded |
| 2 | Load agreement report | agreementSummary.draft = N |

#### TC-AGR-P14: Summary — expired count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exactly N agreements with status='EXPIRED' in filtered set | Test data seeded |
| 2 | Load agreement report | agreementSummary.expired = N |

#### TC-AGR-P15: Summary — terminated count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Have exactly N agreements with status='TERMINATED' in filtered set | Test data seeded |
| 2 | Load agreement report | agreementSummary.terminated = N |

#### TC-AGR-P16: Summary — total_value from invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreements A1, A2 have invoices with net_payable = 1000, 2000 (is_active=true) | Invoice data seeded |
| 2 | Load agreement report with no filters | agreementSummary.total_value = 3000 |
| 3 | Verify filter scoping: applying agreement_id filter only includes that agreement's invoices | Scoped total_value |

#### TC-AGR-P17: Chart — agreementChartStatus with percentage

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Data: 5 ACTIVE, 3 DRAFT, 1 EXPIRED, 1 TERMINATED (total 10) | Test data seeded |
| 2 | Load agreement report | Chart has 4 entries |
| 3 | Verify percentages: ACTIVE=50%, DRAFT=30%, EXPIRED=10%, TERMINATED=10% | Percentages sum to 100% |

#### TC-AGR-P18: Chart — agreementChartCycle with total_value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreements with MONTHLY billing have invoices summing to 5000; ONE_TIME summing to 3000; ON_DEMAND summing to 2000 | Invoice data seeded per cycle |
| 2 | Load agreement report | Chart has 3 entries |
| 3 | Verify MONTHLY count and 5000, ONE_TIME count and 3000, ON_DEMAND count and 2000 | Correct grouping |

#### TC-AGR-P19: Chart — agreementChartVendor top 8 sorted by count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10 vendors with varying agreement counts (V1=12, V2=8, V3=5, V4=3, V5=3, V6=2, V7=1, V8=1, V9=1, V10=1) | Test data |
| 2 | Load agreement report | Chart shows 8 vendors sorted by count desc |
| 3 | Verify V1=12 (top), V8=1 (8th), V9 and V10 excluded | Top 8 only |

#### TC-AGR-P20: ExpiringSoon — ACTIVE agreement with end_date = 30 days from now

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed an ACTIVE agreement with end_date = now()->addDays(30) | Edge case: exactly 30 days |
| 2 | Load agreement report | Agreement appears in expiringSoon |
| 3 | Verify `diffInDays(now())` = 30 satisfies `<= 30` condition | Boundary works |

#### TC-AGR-P21: ExpiringSoon — ACTIVE agreement with end_date < 30 days from now

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed an ACTIVE agreement with end_date = now()->addDays(15) | Under 30 days |
| 2 | Load agreement report | Agreement appears in expiringSoon |
| 3 | Seed another ACTIVE agreement with end_date = now()->addDays(1) | Single day remaining — also included |

#### TC-AGR-P22: ExpiringSoon — non-ACTIVE status agreements excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed a DRAFT agreement with end_date = now()->addDays(5) | Non-active, soon end |
| 2 | Seed an EXPIRED agreement with end_date = now()->addDays(5) | Non-active, soon end |
| 3 | Load agreement report — neither appears in expiringSoon | Status check enforced |

#### TC-AGR-P23: ExpiringSoon — agreements with null end_date excluded

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed an ACTIVE agreement with end_date = NULL | No end date |
| 2 | Load agreement report | Agreement NOT in expiringSoon |
| 3 | Verify `$a->end_date` null check prevents diffInDays call | Null-safe |

#### TC-AGR-P24: Cascading dropdown — agreements filtered by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX request: `GET /vendor-reports?get_options=agreements&vendor_id=5` | Request to getFilteredOptions |
| 2 | Verify response JSON contains only agreements where vendor_id=5 | Scoped options |
| 3 | Verify each option has `{id, text}` where text = agreement_ref_no | Correct format |

#### TC-AGR-P25: Cascading dropdown — items filtered by agreement_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX request: `GET /vendor-reports?get_options=items&agreement_id=10` | Request to getFilteredOptions |
| 2 | Verify response JSON contains only items linked via agreementItems where agreement_id=10 | Scoped options |

#### TC-AGR-P26: Cascading dropdown — items filtered by vendor_id (fallback)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send AJAX request: `GET /vendor-reports?get_options=items&vendor_id=5` (no agreement_id) | Fallback path |
| 2 | Verify response JSON contains items linked to vendor_id=5 via agreementItems.agreement | Vendor-scoped items |
| 3 | Verify system does NOT error when only vendor_id is provided | Fallback works |

#### TC-AGR-P27: AJAX getFilteredOptions — agreements by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor X has 2 agreements (AR-001, AR-002), Vendor Y has 1 agreement (AR-003) | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=agreements&vendor_id=X` | AJAX request |
| 3 | Verify JSON response contains 2 objects each with `id` and `text` fields for AR-001 and AR-002 | Filtered correctly |

#### TC-AGR-P28: AJAX getFilteredOptions — items by agreement_id or vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreement A1 has items I1, I2; Agreement A2 has item I3; Vendor V1 has agreements A1, A2 | Seed data |
| 2 | Send AJAX: `GET /vendor-reports?get_options=items&agreement_id=A1` | Items by agreement |
| 3 | Verify JSON contains I1 and I2 only (items linked via agreementItems where agreement_id=A1) | Filtered by agreement |
| 4 | Send AJAX: `GET /vendor-reports?get_options=items&vendor_id=V1` (no agreement_id) | Items by vendor fallback |
| 5 | Verify JSON contains I1, I2, I3 (all items linked to V1's agreements via agreementItems.agreement) | Vendor-scoped fallback |

### 10.2 Negative TC Steps — Agreement Report

#### TC-AGR-N01: Permission — index without tenant.vendor-report.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor-report.viewAny` accesses `/vendor-reports` | 403 Forbidden |
| 2 | Verify `Gate::authorize()` throws AuthorizationException | Aborted |

#### TC-AGR-N02: Permission — agreement tab without tenant.vendor-report.agreement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User has `tenant.vendor-report.viewAny` but NOT `tenant.vendor-report.agreement` | Can access dashboard |
| 2 | Navigate to `/vendor-reports?tab=agreement-report` | Tab section hidden (Blade @can) |
| 3 | Verify Agreements tab button is not rendered in the UI | Tab not visible |

#### TC-AGR-N03: Filter — invalid vendor_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set vendor_id = 99999 (non-existent) | Invalid filter |
| 2 | Load agreement report | No agreements returned (empty agreementRecords) |
| 3 | Verify summary: total=0, all status counts=0, total_value=0 | Empty summary |

#### TC-AGR-N04: Filter — invalid agreement_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set agreement_id = 99999 (non-existent) | Invalid filter |
| 2 | Load agreement report | No agreements returned |
| 3 | Verify empty paginated result | Empty records |

#### TC-AGR-N05: Filter — invalid item_id (non-existent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set item_id = 99999 (non-existent) | Invalid filter |
| 2 | Load agreement report | No agreements returned (whereHas finds no matches) |
| 3 | Verify empty result set | Empty records |

#### TC-AGR-N06: Filter — invalid date format for from_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date = "not-a-date" | Invalid date format |
| 2 | Load agreement report | `Carbon::parse()` throws an exception |
| 3 | Verify 500 error returned | Exception not caught |

#### TC-AGR-N07: Filter — invalid date format for to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set to_date = "invalid" | Invalid date format |
| 2 | Load agreement report | 500 error from Carbon::parse |

#### TC-AGR-N08: Filter — from_date after to_date

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set from_date = 2026-12-31, to_date = 2026-01-01 | Inverted range |
| 2 | Load agreement report | Date filter applied with inverted range |
| 3 | Verify result set — may return empty since start/end BETWEEN inverted range finds nothing | No overlap with inverted range (likely empty) |

#### TC-AGR-N09: No data — no agreements match filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply filters that don't match any agreements (e.g., date range far in the past) | No matching data |
| 2 | Verify agreementRecords is empty collection | Empty paginated set |
| 3 | Verify all chart collections are empty (status, cycle, vendor charts have 0 entries) | Empty charts |

#### TC-AGR-N10: No data — no agreements in system (empty table)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Truncate vnd_agreements table (test isolation) | No agreements |
| 2 | Load agreement report (no filters) | agreementRecords empty |
| 3 | Verify summary: total=0, total_value=0, expiringSoon empty | Zero counts |

#### TC-AGR-N11: Summary — no invoices linked to agreements (total_value = 0)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Agreements exist but no VndInvoice records reference them | No invoice data |
| 2 | Load agreement report | agreementSummary.total_value = 0.0 |
| 3 | Verify chart cycles show total_value = 0, chart vendor shows total_value = 0 | Zero invoice values |

#### TC-AGR-N12: Chart — single vendor only (agreementChartVendor has 1 entry)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All agreements in filtered set belong to the same vendor | Single vendor |
| 2 | Load agreement report | agreementChartVendor has exactly 1 entry |
| 3 | Verify vendor_name, count, and total_value for that single vendor | Single entry correct |

#### TC-AGR-N13: Chart — no agreements of a particular status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Test data includes only ACTIVE and DRAFT agreements (no EXPIRED or TERMINATED) | Missing statuses |
| 2 | Load agreement report | agreementChartStatus has only 2 entries |
| 3 | Verify percentages: ACTIVE and DRAFT sum to 100%, no EXPIRED/TERMINATED entries | Partial status chart |

### 10.3 Code Review TC Steps

#### TC-CR01: getAgreementReportData() — base query with eager loading

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndAgreement::with(['vendor','agreementItems.item'])` | Eager loads vendor + items chain |
| 2 | Review `vendor` relationship — belongsTo Vendor | Vendor data accessible |
| 3 | Review `agreementItems.item` — nested eager load for item details via pivot | Item data accessible |

#### TC-CR02: getAgreementReportData() — 3-way date overlap logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review first OR: `whereBetween('start_date', [$from, $to])` | Agreements starting within range |
| 2 | Review second OR: `orWhereBetween('end_date', [$from, $to])` | Agreements ending within range |
| 3 | Review third OR: `orWhere(fn($r) => $r->where('start_date', '<=', $from)->where('end_date', '>=', $to))` | Agreements covering entire range |
| 4 | Verify all three are grouped in `where(function(...))` to prevent OR leaking to other filters (vendor_id, etc.) | Proper grouping |

#### TC-CR03: getAgreementReportData() — conditional date filter application

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($request->filled('from_date') || $request->filled('to_date'))` | Condition check |
| 2 | Verify date filter block is completely skipped when neither is provided | No date filter applied |
| 3 | Verify `$from` and `$to` are still calculated via `dates()` but not used in query if condition false | Defaults unused |

#### TC-CR04: getAgreementReportData() — baseCountQuery clone before paginate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$baseCountQuery = clone $query;` before `paginate()` on line 211 | Clone made |
| 2 | Review `$agreements = $baseCountQuery->get();` — fetches ALL matching records (unpaginated) | Full set for summary |
| 3 | Review summary/charts use `$agreements` (unpaginated set), while `agreementRecords` uses paginated subset | Correct variable usage |

#### TC-CR05: getAgreementReportData() — pagination with 'agreement_page' page name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `paginate(10, ['*'], 'agreement_page')` | 10 per page, custom page name |
| 2 | Review `->appends($request->query())` — preserves query params across pages | Query appended |
| 3 | Verify page name `agreement_page` is unique across the 5 report tabs to avoid conflict | No page name collision |

#### TC-CR06: getAgreementReportData() — summary total_value uses VndInvoice with is_active=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `VndInvoice::where('is_active', true)->whereIn('agreement_id', $agreementIds)->sum('net_payable')` | Invoice query |
| 2 | Verify `$agreementIds` comes from `$agreements->pluck('id')` (the unfiltered-by-invoice set) | Correct ID list |
| 3 | Verify only `is_active = true` invoices are included in total_value | Active invoices only |

#### TC-CR07: getAgreementReportData() — agreementChartVendor uses `?? 'Unknown'` fallback

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `vendor_name => $first->vendor->vendor_name ?? 'Unknown'` | Null coalescing |
| 2 | Check if vendor relationship could be null (agreement without a vendor) | Edge case handled |
| 3 | Verify fallback 'Unknown' is used when vendor is null | Fallback present |

#### TC-CR08: getAgreementReportData() — agreementChartVendor take(8) top by count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `->sortByDesc('count')->take(8)->values()` | Top 8 logic |
| 2 | Verify the collection is grouped by 'vendor_id' before sorting | Grouped by vendor |
| 3 | Verify total_value sums invoices per vendor group | Value per vendor |

#### TC-CR09: getAgreementReportData() — expiringSoon filter: diffInDays(now()) <= 30

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$a->end_date->diffInDays(now()) <= 30` | 30-day threshold |
| 2 | Verify `diffInDays()` returns absolute difference (positive integer) | Absolute diff |
| 3 | Verify boundary: exactly 30 days is included (`<= 30`) | Inclusive boundary |

#### TC-CR10: getAgreementReportData() — expiringSoon end_date null check before diff

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$a->end_date && $a->end_date->diffInDays(now()) <= 30` | Null check first |
| 2 | Verify `$a->status === 'ACTIVE'` check precedes end_date check | Status check first |
| 3 | Verify no error occurs when end_date is null (short-circuit evaluation) | Null-safe |

#### TC-CR11: dates() method — defaults to startOfMonth/endOfMonth when not provided

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$from = $r->filled('from_date') ? Carbon::parse($r->from_date) : now()->startOfMonth()` | Default from |
| 2 | Review `$to = $r->filled('to_date') ? Carbon::parse($r->to_date) : now()->endOfMonth()` | Default to |
| 3 | Verify defaults are start of current month and end of current month | Correct defaults |

#### TC-CR12: dates() method — Carbon::parse with startOfDay/endOfDay

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `return [$from->startOfDay(), $to->endOfDay()]` | Time normalization |
| 2 | Verify from_date is set to 00:00:00 of that day | Start of day |
| 3 | Verify to_date is set to 23:59:59 of that day | End of day |

#### TC-CR13: getFilteredOptions() — agreements scoped by vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review type='agreements' handler: `VndAgreement::where('vendor_id', $vendorId)->orderByDesc('id')` | Scoped query |
| 2 | Review returned fields: `['id', 'agreement_ref_no as text']` | Select2-compatible format |
| 3 | Verify empty array returned if no agreements match vendor_id | Graceful empty |

#### TC-CR14: getFilteredOptions() — items scoped by agreement_id or vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review agreement_id path: `whereHas('agreementItems', fn($q) => $q->where('agreement_id', $agreementId))` | Scoped by agreement |
| 2 | Review vendor_id fallback path: `whereHas('agreementItems.agreement', fn($q) => $q->where('vendor_id', $vendorId))` | Fallback by vendor |
| 3 | Verify both paths return `['id', 'item_name as text']` format | Consistent format |

#### TC-CR15: index() — Gate::authorize at method start

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor-report.viewAny');` as first line of index() | Gate check present |
| 2 | Verify no other permissions are checked before data loading | Single gate |

#### TC-CR16: index() — AJAX get_options short-circuit before data load

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `if ($request->ajax() && $request->has('get_options')) return $this->getFilteredOptions($request)` | Early return |
| 2 | Verify full report data is NOT loaded for AJAX cascading requests | Performance optimization |
| 3 | Verify response format is JSON | JSON response |

#### TC-CR17: index() — array_merge of 5 report data methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `return view(... array_merge(compact(...), $this->getVendorLedgerSummaryData(...), $this->getAgreementReportData(...), ...))` | 5 methods merged |
| 2 | Verify no variable name collisions across the 5 methods (e.g., duplicate compact keys) | Unique variable names |
| 3 | Verify all 5 query methods are always called, regardless of activeTab | All loaded |

#### TC-CR18: VndAgreement Model — status constants

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `STATUS_DRAFT = 'DRAFT'` | Draft constant |
| 2 | Review `STATUS_ACTIVE = 'ACTIVE'` | Active constant |
| 3 | Review `STATUS_EXPIRED = 'EXPIRED'` and `STATUS_TERMINATED = 'TERMINATED'` | Expired and Terminated constants |

#### TC-CR19: VndAgreement Model — billing_cycle constants

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `BILLING_MONTHLY = 'MONTHLY'` | Monthly constant |
| 2 | Review `BILLING_ONE_TIME = 'ONE_TIME'` | One-time constant |
| 3 | Review `BILLING_ON_DEMAND = 'ON_DEMAND'` | On-demand constant |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor-reports` | vendor.vendor-reports.index | index() | tenant.vendor-report.viewAny |
| GET (AJAX) | `/vendor-reports?get_options=agreements&vendor_id=X` | — | getFilteredOptions() | tenant.vendor-report.viewAny |
| GET (AJAX) | `/vendor-reports?get_options=items&vendor_id=X&agreement_id=Y` | — | getFilteredOptions() | tenant.vendor-report.viewAny |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Date filter bypass on invalid date format | **Medium** | `Carbon::parse()` throws exception on invalid date with no try-catch — results in 500 error |
| KI-02 | No date validation on input | **Low** | No validation rule ensures from_date/to_date are valid date strings before Carbon::parse |
| KI-03 | BaseCountQuery clone captures all filters correctly | **Info** | `$baseCountQuery = clone $query;` is placed after all filter conditions but before paginate — correct |
| KI-04 | expiringSoon uses `diffInDays(now())` not `diffInDays(now(), false)` | **Low** | `diffInDays()` defaults to absolute comparison; if end_date is in past, it still shows as positive diff (though status=ACTIVE filter should prevent past dates) |
| KI-05 | agreementChartVendor has no null vendor check | **Low** | Uses `$first->vendor->vendor_name ?? 'Unknown'` — handles null vendor but null vendor on a foreign key that should always exist |
| KI-06 | No pagination on dropdown options | **Info** | Agreement and Item dropdowns return all matching records without pagination |
| KI-07 | All 5 report data methods always execute | **Info** | `getVendorLedgerSummaryData`, `getAgreementReportData`, `getInvoiceRegisterData`, `getOutstandingReportData`, `getPaymentRegisterData` all run on every request regardless of activeTab — potential performance concern |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Agreement Report | index() + getAgreementReportData() | VndAgreement, VndAgreementItem, VndInvoice | 10 per page (`agreement_page`) |
| Cascading Dropdown — Agreements | getFilteredOptions('agreements') | VndAgreement | None (full list) |
| Cascading Dropdown — Items | getFilteredOptions('items') | VndItem | None (full list) |
