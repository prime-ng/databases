# caf_MealCardLedgerReport — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Meal Card Ledger Report
**DB scope:** TENANT-side (`caf_meal_card_transactions`, `caf_meal_cards`)
**Module URL:** `/cafeteria/reports-page?tab=meal-card-ledger`
**Test file:** `caf_MealCardLedgerReport_TestCas.php`

Controller: `CafeteriaReportController::index()` + `getMealCardLedger()`, `getMealCardLedgerOverview()`, `exportMealCardLedger()`
View: `reports-page.tabs.meal-card-ledger`

---

## 1. Business Conditions

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `caf_meal_card_transactions`: id, meal_card_id, student_id, transaction_type (Credit/Debit/Refund/Adjustment), amount, balance_after, reference_type, created_at | Model |
| BC-DB-02 | `caf_meal_cards`: id, card_number, student_id | Model |

| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` optional integer exists (via whereHas) | FR |
| BC-VAL-02 | `from_date` optional date | FR |
| BC-VAL-03 | `to_date` optional date | FR |
| BC-VAL-04 | `tx_type` optional in:Credit,Debit,Refund,Adjustment | FR |

| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.report.viewAny` | Ctrl |

| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Overview: Credit, Debit, Refund amounts + counts, Total Txns + unique cards | View |
| BC-BIZ-02 | Bar chart "Transaction Amount by Type": Top Up, Debit, Refund | View |
| BC-BIZ-03 | Line chart "Daily Balance Trend": X=dates, Y=avg balance_after | View |
| BC-BIZ-04 | Transaction Log table: Date, Card #, Type badge, Amount, Balance, Description | View |
| BC-BIZ-05 | Transaction Log paginated 20 per page | Ctrl |
| BC-BIZ-06 | Date range filters on created_at (start 00:00:00, end 23:59:59) | Ctrl |
| BC-BIZ-07 | Student filter via whereHas mealCard → student_id match | Ctrl |
| BC-BIZ-08 | Tx type filter applies to both overview and log | Ctrl |
| BC-BIZ-09 | Export PDF button with current query params | View |
| BC-BIZ-10 | Empty state: "No transactions found." | View |

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No transactions in range → empty state | View |
| BC-EDG-02 | Filter by student with no card → empty set (whereHas mealCard) | Ctrl |
| BC-EDG-03 | Filter by Adjustment type → appears in log but not in summary cards | Ctrl |
| BC-EDG-04 | Single day with multiple transactions → avg_balance computed across all | Ctrl |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFMCL-P10 | Positive | View | Overview: Credit, Debit, Refund amounts + counts, Total Txns | KPI cards | test_caf_mcl_10 | Automated |
| TC-CAFMCL-P11 | Positive | View | Bar chart canvas present when any tx type has amount > 0 | Bar chart | test_caf_mcl_11 | Automated |
| TC-CAFMCL-P12 | Positive | View | Line chart canvas present when daily balance trend exists | Line chart | test_caf_mcl_12 | Automated |
| TC-CAFMCL-P13 | Positive | View | Transaction Log table: Date, Card #, Type badge, Amount, Balance, Description | Table | test_caf_mcl_13 | Automated |
| TC-CAFMCL-P14 | Positive | View | Transaction Log paginated (20 per page) with pagination links | Paginated | test_caf_mcl_14 | Automated |
| TC-CAFMCL-P15 | Positive | View | Export PDF button visible in Transaction Log header | PDF button | test_caf_mcl_15 | Automated |
| TC-CAFMCL-P16 | Positive | View | Filter by tx_type → only that type in log + overview | Filtered | test_caf_mcl_16 | Automated |
| TC-CAFMCL-P17 | Positive | View | Filter by date range → transactions in range only | Filtered | test_caf_mcl_17 | Automated |
| TC-CAFMCL-P18 | Positive | View | Filter by student_id → transactions for that student only | Filtered | test_caf_mcl_18 | Automated |
| TC-CAFMCL-P19 | Positive | View | No transactions → "No transactions found." empty state | Empty | test_caf_mcl_19 | Automated |
| TC-CAFMCL-P20 | Positive | Ctrl | PDF export → application/pdf | PDF | test_caf_mcl_20 | Automated |
