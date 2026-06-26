# Report: Type Analytics — Requirement Document

## 1. Screen Purpose & Overview

The **Type Analytics** report tab provides a visual analytics dashboard showing certificate request patterns, monthly issuance volumes, and volume distributions by certificate category (e.g. administrative, legal, achievement). 

The screen helps administrators review operational demand, monitor processing efficiency, and allocate staff resources for document handovers.

---

## 2. Common Business Use Cases

1. **Analyzing Peak Load Periods**: The Principal reviews a monthly trend bar chart to see during which months the school experiences high certificate volumes (e.g. admission or graduation months).
2. **Reviewing Category Distribution**: The admin checks a pie chart showing category breakdown (e.g. 60% Bonafide, 20% Character, 20% TCs) to assess request reasons.
3. **Evaluating Status Ratios**: The admin reviews the ratio of approved vs. rejected applications to check for consistency in clerk reviews.

---

## 3. Database Schema & Data Dictionary

*   **Primary Tables**: `crt_issued_certificates`, `crt_requests`
*   **Tenant Scope**: Scoped implicitly at database level (no `tenant_id` column).

The front-end renders charts using data fetched from the JSON analytics API endpoint `/certificate/reports/analytics`.

### JSON Payload Schema
The endpoint returns:
```json
{
  "monthly_trend": [
    { "month": "Jan 2026", "count": 45 },
    { "month": "Feb 2026", "count": 60 }
  ],
  "category_distribution": {
    "administrative": 120,
    "legal": 45,
    "character": 30,
    "achievement": 80,
    "identity": 150
  },
  "status_summary": {
    "pending": 5,
    "under_review": 12,
    "generated": 380,
    "issued": 350,
    "rejected": 15
  }
}
```

---

## 4. Screen Fields & Input Rules

The screen has no input forms. It features interactive chart controls:
*   **Year Filter**: Dropdown to select academic year. Defaults to current session.
*   **Reset Filter**: Button to restore default view.

---

## 5. Business Logic & Validation Policies

1. **Client-Side Rendering (Chart.js)**:
   * The page structure must load immediately, rendering empty canvas elements: `<canvas id="monthlyTrendChart"></canvas>` and `<canvas id="categoryChart"></canvas>`.
   * An AJAX request loads data from `/certificate/reports/analytics`, initializing the Chart.js objects upon response.
2. **Strict Tenant Boundaries**:
   * The underlying queries must group and count rows strictly within the current tenant database to prevent cross-tenant data leaks.
3. **Optimized Aggregations**:
   * To prevent performance degradation, the queries run group-by aggregations using indexed columns (`certificate_type_id`, `issue_date`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as Administrator.
* Ensure there are at least 10 issued certificates across different types and months.
* Navigate to `/certificate/reports/analytics`.

### Scenario A: Chart Loading & Interactive Hover
1. Open the analytics view.
2. **Expected Result**:
   * Spinner displays briefly, then charts load.
   * A bar chart showing monthly trends is rendered.
   * A pie chart showing category breakdown is rendered.
3. Hover cursor over the "Legal" slice of the pie chart.
4. **Expected Result**: A tooltip displays, showing the exact count of issued certificates (e.g. `Legal: 45`).

### Scenario B: Dynamic Year Filtering
1. Select Year: `2025` from dropdown.
2. **Expected Result**:
   * AJAX call fires.
   * Charts re-draw to show data for the 2025 academic session.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/certificate/reports/analytics`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/certificate/reports/analytics')
            ->waitFor('#monthlyTrendChart') // Wait for canvas element
            ->assertVisible('#monthlyTrendChart')
            ->assertVisible('#categoryChart')
            ->select('academic_year', '2026')
            ->waitForText('Jan 2026'); // Assert chart data label loads
});
```

### 3. API Response Integration Test Flow
```php
// Query the JSON endpoint directly to check payload structure
$response = $this->actingAs($this->adminUser)
                 ->getJson('/certificate/reports/analytics?year=2026');
                 
$response->assertStatus(200)
         ->assertJsonStructure([
             'monthly_trend' => [
                 '*' => ['month', 'count']
             ],
             'category_distribution' => [
                 'administrative', 'legal', 'character', 'achievement', 'identity'
             ],
             'status_summary' => [
                 'pending', 'under_review', 'generated', 'issued', 'rejected'
             ]
         ]);
```
