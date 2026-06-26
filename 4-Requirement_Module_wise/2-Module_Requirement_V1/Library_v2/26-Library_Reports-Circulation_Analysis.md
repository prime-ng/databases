# Circulation Analysis — Requirement Document

## 1. Screen Purpose & Overview
The Circulation Analysis screen displays a dashboard and reporting terminal that tracks the movement velocity of library resources. By analyzing issues, returns, and renewal transactions, it helps librarians monitor checkout traffic, identify popular bibliography categories, review borrowing durations, and schedule staff during peak service hours.

---

## 2. Common Business Use Cases
1. **Analyzing Peak Check-in/Check-out Hours:** Auditing hourly traffic charts to allocate student helpers or library staff during high-demand blocks (e.g. 12:00 PM peak).
2. **Identifying High-Demand Categories:** Inspecting turnover rates by category to direct budget allocation for book acquisitions.
3. **Tracking Reader Segment Activity:** Verifying which member segments (e.g., student vs. faculty membership types) exhibit the highest checkout volumes.

---

## 3. Database Schema & Data Dictionary
This report aggregates records from:
*   **Table Name**: `lib_transactions` (Issue/return logs)
*   **Table Name**: `lib_book_copies` (Physical items)
*   **Table Name**: `lib_books_master` (Titles metadata)
*   **Table Name**: `lib_categories` (Subject taxonomy)

The following database fields are queried and aggregated:

| Column / Field | Data Source Table | Aggregation / Operation | Description |
|---|---|---|---|
| `issue_date` | `lib_transactions` | Date Filter / Hourly Group | Timestamp of borrow event. |
| `return_date` | `lib_transactions` | `COUNT()`, Date Diff | Timestamp of return event. |
| `is_renewed` | `lib_transactions` | `COUNT()` where `1` | Count of renewals. |
| `category_id` | `lib_books_master` | Group By | Subject classification links. |
| `membership_type_id` | `lib_members` | Group By | Scopes borrower profiles. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Start Date** | Date Picker | Yes | Standard date. Defaults to today minus 30 days. | Today - 30 Days |
| **End Date** | Date Picker | Yes | Must be $\ge$ **Start Date**. | Today's Date |
| **Category Scope** | Dropdown | No | Filter by active library categories. | *All Categories* |
| **Membership Type** | Dropdown | No | Filter by active membership types. | *All Memberships* |
| **Export Format** | Dropdown | Yes | Options: `PDF`, `Excel`, `Screen View`. | `Screen View` |

---

## 5. Business Logic & Validation Policies
1. **Average Loan Duration Formula:** Calculated in Carbon days for all checkouts returned in the range:
   $$\text{Avg Loan Days} = \frac{\sum_{i=1}^{n} (\text{Return Date}_i - \text{Issue Date}_i)}{n}$$
2. **Category Turnover & Utilization Ratios:**
   * **Category Turnover Rate:** Measures how frequently catalog copies are borrowed:
     $$\text{Turnover Rate} = \frac{\text{Total Category Issues}}{\text{Total Copies in Category}}$$
   * **Category Utilization Percentage:**
     $$\text{Utilization (\%)} = \left( \frac{\text{Total Category Issues}}{\text{Total Copies in Category}} \right) \times 100$$
3. **Hourly & Peak Day Patterns:** Transactions are grouped by hour-of-day ($[8..20]$) and weekday formats to determine structural peak traffic indicators.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library reports section `/reports/circulation`.

### Scenario A: Running Circulation Report (Happy Path)
1. Select Start Date: `2026-05-01`.
2. Select End Date: `2026-05-23`.
3. Keep Export Format: `Screen View`.
4. Click **"Generate Report"**.
5. **Expected Result**: Report sections render correctly, showing Total Issues, Returns, Renewals, Average Loan Days, Top Circulating Books list, and Hourly patterns in interactive charts.

### Scenario B: Period Fallback Verification
1. Open the page and leave the Start and End date pickers blank.
2. Click **"Generate Report"**.
3. **Expected Result**: System falls back automatically, setting the range to the last 30 days, loading the corresponding transaction aggregates.

### Scenario C: PDF Export Generation
1. Choose valid date bounds.
2. Select Export Format: `PDF`.
3. Click **"Generate Report"**.
4. **Expected Result**: A print-optimized PDF containing circulation stats is downloaded.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/circulation`
* **Tab/Page Selector**: `@circulation-report-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/circulation')
            ->type('start_date', '2026-05-01')
            ->type('end_date', '2026-05-23')
            ->press('@generate-btn')
            ->waitFor('@circulation-charts')
            ->assertSee('Total Issues')
            ->assertSee('Average Loan Days');
});
```

### 3. Utilization Grid Verification Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/circulation')
            ->press('@generate-btn')
            ->waitFor('@category-table')
            // Assert that Category column headers are visible
            ->assertSee('Turnover Rate')
            ->assertSee('Utilization');
});
```
