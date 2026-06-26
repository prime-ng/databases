# Acquisition Reports — Requirement Document

## 1. Screen Purpose & Overview
The Acquisition Reports screen functions as a collection development dashboard. It displays aggregates of book copy acquisitions, budget YTD spending, remaining allocations, predictive demand forecasts, and replacement recommendations. The report integrates standard catalog tables with predictive analysis database views to identify subject gaps, forecast copy needs, and optimize purchasing budgets.

---

## 2. Common Business Use Cases
1. **Auditing Annual Budget Spending:** Reviewing total spent YTD versus the annual library budget to ensure category-wise spending limits are respected.
2. **Predictive Purchase Planning:** Auditing the predictive demand forecast widgets to check titles that are predicted to experience high demand in the next quarter.
3. **Evaluating Replacement Priorities:** Identifying copies marked as lost, withdrawn, or severely damaged to order replacement copies.

---

## 3. Database Schema & Data Dictionary
This report aggregates records from standard tables and predictive analysis database views:
*   **Table Name**: `lib_book_copies` (Acquisition details)
*   **Table Name**: `lib_books_master` (Title details)
*   **Database View**: `lib_view_predictive_demand` (Demand forecasts)
*   **Database View**: `lib_view_collection_performance` (Usage statistics)

The following database fields are queried and aggregated:

| Column / Field | Data Source Table / View | Aggregation / Operation | Description |
|---|---|---|---|
| `purchase_price` | `lib_book_copies` | `SUM()`, `AVG()` | Monetary cost of acquired copies. |
| `purchase_date` | `lib_book_copies` | Date Filter / Year Range | Date copy was acquired. |
| `predicted_next_3_months`| `lib_view_predictive_demand`| Value Evaluation | Forecasted copy checkout volume. |
| `confidence_score` | `lib_view_predictive_demand`| Value Evaluation | Probability percentage of forecast accuracy. |
| `collection_utilization_rate`| `lib_view_collection_performance`| `AVG()` | Percentage of copies actively circulated. |
| `turnover_rate` | `lib_view_collection_performance`| `AVG()` | Ratio of issues to copy counts. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Start Date** | Date Picker | Yes | Standard date. Defaults to today minus 90 days. | Today - 90 Days |
| **End Date** | Date Picker | Yes | Must be a date after or equal to **Start Date**. | Today's Date |
| **Category Scope** | Dropdown | No | Filter by active subject categories. | *All Categories* |
| **Vendor Filter** | Dropdown | No | Filter by active supplier vendor profiles. | *All Vendors* |
| **Export Format** | Dropdown | Yes | Options: `PDF`, `Excel`, `Screen View`. | `Screen View` |

---

## 5. Business Logic & Validation Policies
1. **Budget Summary Aggregates:**
   * **Total Spent YTD:** Sum of `purchase_price` in `lib_book_copies` where purchase date is within the current calendar year.
   * **Remaining Budget:**
     $$\text{Remaining Budget} = \text{Annual Budget Setting} - \text{Total Spent YTD}$$
   * **Spent Percentage:**
     $$\text{Spent (\%) } = \left( \frac{\text{Total Spent YTD}}{\text{Annual Budget Setting}} \right) \times 100$$
2. **Subject Gap Analysis Formula:** Estimates the number of new copies to acquire per category based on active reservations and usage thresholds:
   $$\text{Recommended Titles} = \text{Current Count} + \text{High Demand Delta} + \text{Reservations Delta} + \text{Usage Bump}$$
   $$\text{Gap} = \text{Recommended Titles} - \text{Current Title Count}$$
3. **Replacement Trigger Logic:** Copies are flagged for replacement if status is `'lost'`, `'withdrawn'`, or `'damaged'`, or if the purchase age exceeds 8 years (depreciation threshold).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/reports/acquisition`.

### Scenario A: Running Acquisition Report (Happy Path)
1. Select Start Date: `2026-01-01`.
2. Select End Date: `2026-05-23`.
3. Keep Export Format: `Screen View`.
4. Click **"Generate Report"**.
5. **Expected Result**: Page loads correctly, displaying widgets for Spent YTD, Remaining Budget, and average copy price. Predictive demand list and gap analysis tables populate with correct category and cost estimates.

### Scenario B: Date Ordering Errors
1. Select Start Date: `2026-05-20`.
2. Select End Date: `2026-05-10` (Prior date).
3. Click **"Generate Report"**.
4. **Expected Result**: System blocks the generation and displays error message: *"The end date must be a date after or equal to start date."*

### Scenario C: Fallback Check on Database View Failures
1. Mock a database failure or drop the views `lib_view_predictive_demand` and `lib_view_collection_performance`.
2. Generate the report.
3. **Expected Result**: The system falls back gracefully to standard table queries, displaying basic acquisition summary metrics without throwing a PHP exception.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/acquisition`
* **Tab/Page Selector**: `@acquisition-report-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/acquisition')
            ->type('start_date', '2026-01-01')
            ->type('end_date', '2026-05-23')
            ->press('@generate-btn')
            ->waitFor('@budget-widgets')
            ->assertSee('Spent YTD')
            ->assertSee('Remaining Budget');
});
```

### 3. Verification of Gap Analysis Grid Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/acquisition')
            ->press('@generate-btn')
            ->waitFor('@gap-analysis-table')
            ->assertSee('Acquisition Cost Estimate')
            ->assertSee('Recommended Copies');
});
```
