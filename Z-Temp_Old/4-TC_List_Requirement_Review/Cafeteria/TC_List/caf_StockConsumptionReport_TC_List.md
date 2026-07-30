# caf_StockConsumptionReport — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Stock Consumption Report
**DB scope:** TENANT-side (`caf_consumption_logs`, `caf_stock_items`)
**Module URL:** `/cafeteria/reports-page?tab=stock-consumption`
**Test file:** `caf_StockConsumptionReport_TestCas.php`

Controller: `CafeteriaReportController::index()` + `getStockConsumption()`, `exportStockConsumption()`
View: `reports-page.tabs.stock-consumption`

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `caf_consumption_logs`: id, stock_item_id, log_date, quantity_used | Model |
| BC-DB-02 | `caf_stock_items`: id, name, unit, category, current_quantity, reorder_level | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `from_date` optional date | FR |
| BC-VAL-02 | `to_date` optional date | FR |
| BC-VAL-03 | `stock_item_id` optional integer exists | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.report.viewAny` | Ctrl |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Overview: Total Used, Items Tracked, Avg Daily, Low Stock cards | View |
| BC-BIZ-02 | Bar chart "Consumption by Item": X=item names, Y=total_used | View |
| BC-BIZ-03 | Pie chart "Consumption Distribution": shares by item | View |
| BC-BIZ-04 | Detailed Records table: Item, Unit, Total Used, No. of Entries | View |
| BC-BIZ-05 | Low Stock count uses each item's reorder_level (not hardcoded) | Ctrl |
| BC-BIZ-06 | Avg Daily when date range provided = total ÷ (end - start + 1) days | Ctrl |
| BC-BIZ-07 | Avg Daily when no date range = total ÷ distinct log_dates in result | Ctrl |
| BC-BIZ-08 | Empty state: "No consumption data." | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No consumption logs in range → empty state | View |
| BC-EDG-02 | Filter by item with zero logs → empty state | View |
| BC-EDG-03 | Item consumed once with qty=0.001 → total min precision | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSCR-P10 | Positive | View | Overview: Total Used, Items Tracked, Avg Daily, Low Stock cards | KPI cards | test_caf_scr_10 | Automated |
| TC-CAFSCR-P11 | Positive | View | Bar chart canvas present when consumption data exists | Bar chart | test_caf_scr_11 | Automated |
| TC-CAFSCR-P12 | Positive | View | Pie chart canvas present when data exists | Pie chart | test_caf_scr_12 | Automated |
| TC-CAFSCR-P13 | Positive | View | Detailed Records table: Item, Unit, Total Used, No. of Entries | Table | test_caf_scr_13 | Automated |
| TC-CAFSCR-P14 | Positive | View | Filter by date range → logs within range only | Filtered | test_caf_scr_14 | Automated |
| TC-CAFSCR-P15 | Positive | View | Filter by stock_item_id → that item only | Filtered | test_caf_scr_15 | Automated |
| TC-CAFSCR-P16 | Positive | Biz | Low Stock = items where current_qty ≤ reorder_level | Correct low stock | test_caf_scr_16 | Automated |
| TC-CAFSCR-P17 | Positive | Biz | Avg daily with date range: total / (end - start + 1) | Correct avg | test_caf_scr_17 | Automated |
| TC-CAFSCR-P18 | Positive | Biz | Avg daily without date range: total / distinct log_dates | Correct avg | test_caf_scr_18 | Automated |
| TC-CAFSCR-P19 | Positive | View | No consumption data → empty state | Empty | test_caf_scr_19 | Automated |
| TC-CAFSCR-P20 | Positive | Ctrl | PDF export → application/pdf | PDF | test_caf_scr_20 | Automated |
