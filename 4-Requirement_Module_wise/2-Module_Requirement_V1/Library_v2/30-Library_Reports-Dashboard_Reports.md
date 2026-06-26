# Dashboard Reports — Requirement Document

## 1. Screen Purpose & Overview
The Dashboard Reports screen serves as the central executive cockpit for the library module. It displays high-level key performance indicators (KPIs) summarizing daily operations (circulation volumes, collection health, budget usage, fine collections, and waitlist fulfillment) and integrates student-level behavior analytics (such as reading goals, consistency ratings, and reading genre diversity indexes).

---

## 2. Common Business Use Cases
1. **Executive Operational Audit:** Checking the library's collection turnover rate and budget utilization metrics.
2. **Reviewing Student Reading Goals:** Auditing student YTD reading progress to target low-engagement members with recommendations.
3. **Assessing Genre Diversity:** Checking which academic classes or student cohorts exhibit balanced reading profiles using the Shannon diversity metric.

---

## 3. Database Schema & Data Dictionary
This dashboard compiles data from standard tables and behavior analytics logs:
*   **Table Name**: `lib_reading_behavior_analytics` (Student reading behavior logs)
*   **Table Name**: `lib_transactions` (Operational checkouts)
*   **Table Name**: `lib_book_copies` (Inventory asset tracking)
*   **Table Name**: `lib_fines` (Penalty allocations)

The following database fields are queried and aggregated:

| Column Name | Data Source Table | Data Type | Description / Key Details |
|---|---|---|---|
| `academic_year` | `lib_reading_behavior_analytics` | `varchar(20)` | Target scholastic calendar period. |
| `total_books_read`| `lib_reading_behavior_analytics` | `integer` | Total books checked back and completed. |
| `reading_consistency_score`| `lib_reading_behavior_analytics`| `decimal(5,2)`| Consistency score based on checkout patterns. |
| `genre_diversity_index`| `lib_reading_behavior_analytics` | `decimal(5,2)`| Shannon diversity score based on read genres. |
| `status` | `lib_transactions` | `enum` | Checkout state (Issued, Returned, Overdue). |
| `purchase_price` | `lib_book_copies` | `decimal(10,2)`| Copy value (used for budget KPIs). |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Academic Year** | Dropdown | Yes | Select active scholastic year (e.g. `2025-2026`). | Current Academic Year |
| **Student Class** | Dropdown | No | Filter by class/grade (e.g. Class 1 to 10). | *All Classes* |
| **Active KPI Filter** | Tab Controls | No | Toggle view: *Operations*, *Reading behavior*. | *Operations* |

---

## 5. Business Logic & Validation Policies
1. **Shannon Diversity Index Formula:** The genre diversity index is calculated by a background cron job using the Shannon entropy equation:
   $$H' = - \sum_{i=1}^{S} p_i \ln p_i$$
   *(Where $p_i$ is the proportion of total books checked out by the member in genre $i$ over the academic year, and $S$ is the total number of genres available).*
   * **Result Interpretation:** Values $\ge 1.50$ indicate high diversity (balanced reading).
2. **Collection Turnover Ratio:**
   $$\text{Turnover Ratio} = \frac{\text{Total Checkouts in Year}}{\text{Total Physical Copies}}$$
3. **Cron Update Policy:** Reading behavior metrics are calculated via an overnight background worker job to prevent real-time database locks on large transaction tables. The dashboard displays the time of the last sync: `last_calculated_at`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library dashboard `/reports/dashboard`.

### Scenario A: Loading Operational KPIs (Happy Path)
1. Open the dashboard page.
2. Select Academic Year: `2025-2026`.
3. Select Class: `All Classes`.
4. Click **"Apply Filters"**.
5. **Expected Result**: KPI cards populate for Collection Utilization, Member Engagement, Turnover Rate, and Budget spent.

### Scenario B: Shannon Genre Diversity Verification
1. Click the **Reading Behavior Analytics** tab on the dashboard.
2. View the student ranking table.
3. Locate a student who has read 10 books across 5 different genres.
4. Verify that their `genre_diversity_index` displays as a value between `1.0` and `2.3` and is classified as "Highly Diverse" or "Balanced".
5. **Expected Result**: The Shannon Index calculations are correctly displayed and color-coded.

### Scenario C: Class Filter Empty State
1. Select a class with no active members (e.g., `Class 12` if vacant).
2. Click **"Apply Filters"**.
3. **Expected Result**: Dashboard KPIs display `0` values or blank indicators. No database syntax errors are thrown.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/reports/dashboard`
* **Tab/Page Selector**: `@dashboard-container`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/dashboard')
            ->select('academic_year', '2025-2026')
            ->press('@apply-filters-btn')
            ->waitFor('@kpi-widget-utilization')
            ->assertSee('Collection Utilization')
            ->assertSee('%');
});
```

### 3. Diversity Tab Verification Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/reports/dashboard')
            ->click('@reading-analytics-tab')
            ->waitFor('@student-diversity-table')
            ->assertSee('Genre Diversity')
            ->assertSee('Consistency Score');
});
```
