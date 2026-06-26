# Fine Reports — Requirement Document

## 1. Screen Purpose & Overview
The Fine Reports screen provides a financial collection dashboard and reporting terminal. It displays aggregates of levied penalties, waivers, collected funds, outstanding balances, and trend rates over specific date periods. The report utilizes the fine calculation ledger to render charts, analyze overdue slabs, rank top defaulters, and generate strategic collection recommendations.

---

## 2. Common Business Use Cases
1. **Auditing Monthly Fine Collections:** Running a report for the previous month to compare the total fines issued against actual cash and online receipts.
2. **Identifying Defaulter Balances:** Ranking members with the highest outstanding fine totals to suspend library privileges or send notifications.
3. **Analyzing Overdue Slab Durations:** Inspecting which overdue categories (e.g. 1-10 days vs. 45+ days) represent the majority of unpaid fines.

---

## 3. Database Schema & Data Dictionary
This report aggregates records from:
*   **Table Name**: `lib_fines` (Penalty allocations)
*   **Table Name**: `lib_fine_payments` (Collected payments)

The following database fields are queried and aggregated:

| Column / Field | Data Source Table | Aggregation / Operation | Description |
|---|---|---|---|
| `amount` | `lib_fines` | `SUM()`, `AVG()` | Total levied penalties. |
| `waived_amount` | `lib_fines` | `SUM()` | Excluded fines. |
| `amount_paid` | `lib_fine_payments` | `SUM()` | Collected payments. |
| `days_overdue` | `lib_fines` | `MAX()`, `COUNT()` | Calendar overdue duration range buckets. |
| `created_at` | `lib_fines` | Date Filter Range | Date penalty was issued. |
| `payment_date` | `lib_fine_payments` | Date Filter Range | Date payment was collected. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Start Date** | Date Picker | Yes | Standard date. Defaults to today minus 30 days. | Today - 30 Days |
| **End Date** | Date Picker | Yes | Must be a date after or equal to **Start Date**. | Today's Date |
| **Membership Type** | Dropdown | No | Filter by active memberships. | *All Memberships* |
| **Fine Type** | Dropdown | No | Filter by penalty event type (e.g. `Late Return`, `Lost Book`). | *All Types* |
| **Export Format** | Dropdown | Yes | Options: `PDF`, `Excel`, `Screen View`. | `Screen View` |

---

## 5. Business Logic & Validation Policies
1. **Executive Summary Aggregates:**
   * **Total Fines Levied:** Sum of `amount` in `lib_fines` within the period.
   * **Total Collected:** Sum of `amount_paid` in `lib_fine_payments` within the period.
   * **Total Waived:** Sum of `waived_amount` in `lib_fines` within the period.
   * **Pending Balance:**
     $$\text{Pending Balance} = \max\left(0, \text{Total Fines} - \text{Total Collected} - \text{Total Waived}\right)$$
   * **Collection Rate Percentage:**
     $$\text{Collection Rate (\%)} = \begin{cases} \left( \frac{\text{Total Collected}}{\text{Total Fines}} \right) \times 100 & \text{if Total Fines} > 0 \\ 0 & \text{otherwise} \end{cases}$$
2. **Defaulter Priority Logic:** Members with outstanding balances are ranked descending. Long-overdue accounts (> 45 days) are highlighted with recommendation alerts to mark books as lost.
3. **Overdue Slab Ranges:** Fines are bucketed into ranges by overdue days:
   * `1 - 10 days`, `11 - 20 days`, `21 - 30 days`, `31 - 45 days`, and `45+ days`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library reports section `/reports/fine-collection`.

### Scenario A: Running Dashboard Report (Happy Path)
1. Select Start Date: `2026-04-01`.
2. Select End Date: `2026-05-01`.
3. Select Export Format: `Screen View`.
4. Click **"Generate Report"**.
5. **Expected Result**: Dashboard widgets load correct calculations for Total Fines, Total Collected, and Collection Rate. Bar charts populate without rendering errors.

### Scenario B: Date Filters Validation Failures
1. Select Start Date: `2026-05-01`.
2. Select End Date: `2026-04-01` (End date is prior to start date).
3. Click **"Generate Report"**.
4. **Expected Result**: Validation fails. Error displays: *"The end date must be a date after or equal to start date."*

### Scenario C: Excel Export Delivery
1. Set valid date parameters.
2. Select Export Format: `Excel`.
3. Click **"Generate Report"**.
4. **Expected Result**: Server processes the report, triggers a file download stream, and downloads a spreadsheet containing identical summary tables.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/fine-collection`
* **Tab/Page Selector**: `@fine-report-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/fine-collection')
            ->type('start_date', '2026-04-01')
            ->type('end_date', '2026-05-01')
            ->select('export_format', 'Screen View')
            ->press('@generate-btn')
            ->waitFor('@summary-widgets')
            ->assertSee('Total Fines')
            ->assertSee('Collection Rate');
});
```

### 3. Verification of Empty State Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/fine-collection')
            ->type('start_date', '2020-01-01') // Past period with no data
            ->type('end_date', '2020-01-30')
            ->press('@generate-btn')
            ->waitForText('No records found')
            ->assertSee('0.00');
});
```
