# caf_DailySalesReport — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Daily Sales Report
**DB scope:** TENANT-side (`caf_orders`, `caf_order_items`, `caf_menu_items`, `caf_menu_categories`)
**Module URL:** `/cafeteria/reports-page?tab=daily-sales`
**Test file:** `caf_DailySalesReport_TestCas.php`

Controller: `CafeteriaReportController::index()` + `getDailySales()`, `exportDailySales()`
View: `reports-page.tabs.daily-sales`

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `caf_orders`: order_date, total_amount, status, meal_category_id, created_at | Model |
| BC-DB-02 | `caf_order_items`: order_id, menu_item_id, quantity, unit_price, line_total | Model |
| BC-DB-03 | `caf_menu_items`: id, name, category_id → caf_menu_categories | Model |
| BC-DB-04 | `caf_menu_categories`: id, name | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `date` optional date (single) | FR |
| BC-VAL-02 | `meal_category_id` optional integer exists | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.report.viewAny` | Ctrl |
| BC-AUTH-02 | PDF export gate `cafeteria.report.export` | Ctrl |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Default tab on page load: daily-sales | Ctrl |
| BC-BIZ-02 | Overview sub-tab: Total Revenue card (₹), Items Sold, Avg Order Value, Categories | View |
| BC-BIZ-03 | Bar chart "Sales by Category": X=category names, Y=qty_sold | View |
| BC-BIZ-04 | Line chart "Hourly Sales Trend": X=hours, Y=revenue | View |
| BC-BIZ-05 | Detailed Records table: Item, Category, Qty Sold, Unit Price, Total + total footer | View |
| BC-BIZ-06 | Orders with status=Cancelled excluded from all counts | Ctrl |
| BC-BIZ-07 | Total Revenue = sum of order_items.line_total across included orders | Ctrl |
| BC-BIZ-08 | Avg Order Value = Total Revenue ÷ distinct order count (not item count) | Ctrl |
| BC-BIZ-09 | Hourly trend grouped by order.created_at hour | Ctrl |
| BC-BIZ-10 | Empty state: "No sales data." when no orders match | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No orders for selected date → empty state, no charts | View |
| BC-EDG-02 | All orders cancelled for date → empty state (all excluded) | Ctrl |
| BC-EDG-03 | Single order with multiple items → avg = total / 1 | Ctrl |
| BC-EDG-04 | Filter by category that has no orders → empty state | View |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFDSR-P10 | Positive | View | Page loads with daily-sales tab active by default | Active tab | test_caf_dsr_10 | Automated |
| TC-CAFDSR-P11 | Positive | View | Overview: Total Revenue, Items Sold, Avg Order Value, Categories cards rendered | KPI cards | test_caf_dsr_11 | Automated |
| TC-CAFDSR-P12 | Positive | View | Bar chart canvas present when sales data exists | Bar chart | test_caf_dsr_12 | Automated |
| TC-CAFDSR-P13 | Positive | View | Line chart canvas present when hourly data exists | Line chart | test_caf_dsr_13 | Automated |
| TC-CAFDSR-P14 | Positive | View | Detailed Records table with Item, Category, Qty Sold, Unit Price, Total columns | Table | test_caf_dsr_14 | Automated |
| TC-CAFDSR-P15 | Positive | View | Table footer shows Total Revenue row | Footer | test_caf_dsr_15 | Automated |
| TC-CAFDSR-P16 | Positive | Biz | Exclude Cancelled orders: 5 orders (1 cancelled) → revenue from 4 only | Excluded | test_caf_dsr_16 | Automated |
| TC-CAFDSR-P17 | Positive | Biz | Avg Order Value = revenue / order count (not item type count) | Correct AOV | test_caf_dsr_17 | Automated |
| TC-CAFDSR-P18 | Positive | Biz | Filter by meal_category_id → only that category's items | Filtered | test_caf_dsr_18 | Automated |
| TC-CAFDSR-P19 | Positive | View | No sales data → "No sales data." empty state | Empty | test_caf_dsr_19 | Automated |
| TC-CAFDSR-P20 | Positive | Ctrl | PDF export → returns application/pdf | PDF | test_caf_dsr_20 | Automated |
