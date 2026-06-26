# Management Summary Report — Requirement Document

## 1. Screen Purpose & Overview

The Management Summary Report is an executive dashboard summarizing high-level operational KPIs for the entire transport network. It compiles fleet utilization percentages, crew compliance indices, student boarding completions, and financial cost-recovery balances into a single report. 

This enables board directors and school principals to audit the module's efficiency.

---

## 2. Common Business Use Cases

1. **Executive Operational Audit:** The principal reviews the monthly summary to evaluate if overall fleet utilization meets target goals.
2. **Reviewing Safety Incidents:** Checking aggregate incident numbers across the semester to evaluate safety policies.
3. **Evaluating Financial Viability:** Checking net revenue vs. fuel and maintenance expenditures in a single view.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from all core tables:

* `tpt_vehicle.id` (INT UNSIGNED): Fleet size base.
* `tpt_trip.id` (INT UNSIGNED): Executed trips.
* `tpt_student_boarding_log.id` (INT UNSIGNED): Boarding events.
* `tpt_student_fee_collection.paid_amount` (DECIMAL(10,2)): Collection base.
* `tpt_vehicle_fuel.cost` (DECIMAL(12,2)): Fuel costs.
* `tpt_vehicle_maintenance.cost` (DECIMAL(12,2)): Repair costs.
* `tpt_trip_incidents.id` (INT UNSIGNED): Total infractions.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Academic Session** | Dropdown | Required. Selects the target academic year session. | Query filter parameters. |
| **Billing Month** | Dropdown | Optional. Filters report to a specific calendar month. | Query filter parameters. |
| **Export Report** | Button | Downloads executive report as PDF/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Fleet Utilization Rate (%)**:
  $$\text{Fleet Utilization} = \left( \frac{\text{Active Rostered Vehicles}}{\text{Total Fleet Size}} \right) \times 100$$
  * *Where Active Rostered Vehicles* is the count of unique vehicles mapped in `tpt_driver_route_vehicle_jnt` during the period.

* **Incident Rate Per Trip (%)**:
  $$\text{Incident Rate} = \left( \frac{\text{Total Incidents Logged}}{\text{Total Trips Completed}} \right) \times 100$$

* **Net Operational Balance (NOB)**:
  $$\text{NOB} = \text{Revenue Collected} - (\text{Fuel Cost} + \text{Maintenance Cost})$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Executive Dashboard (Happy Path)
1. Go to `/transport/transport-report` and click the **Management Summary** tab.
2. Select Academic Session: `2026-2027`. Click Search.
3. Verify that:
   - The screen renders summary widget cards: Fleet Size, Total Completed Trips, Attendance Rate, Active Incidents, and Cost-Recovery Ratio.
   - Graphs for monthly revenue vs. costs display correct plotted lines.

### Test Case 2: Verify Net Balance Calculations
1. Collect values: Total collections = ₹100,000, Fuel = ₹40,000, Maintenance = ₹20,000.
2. Verify that:
   - Net Operational Balance displays:
     $$\text{NOB} = 100,000 - (40,000 + 20,000) = ₹40,000.00$$
   - Cost-Recovery Ratio displays `166.67%`.

### Test Case 3: Export PDF Report
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same executive KPIs as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Management Summary Tab**: `@mgmt-summary-tab`
* **Session Filter Select**: `select[name="session_filter"]`
* **Search Button**: `@filter-report-btn`
* **Executive Summary Grid**: `@summary-grid-container`
* **Fleet Utilization Card**: `@utilization-rate-card`
* **Net Balance Display**: `@net-balance-display`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportManagementSummaryTest extends DuskTestCase
{
    public function testManagementSummaryMetricsAndDashboards()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@mgmt-summary-tab')
                    ->waitFor('@summary-grid-container')
                    
                    // Filter report
                    ->select('session_filter', '1')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert KPI widget cards
                    ->assertVisible('@utilization-rate-card')
                    ->assertSeeIn('@utilization-rate-card', '%')
                    ->assertVisible('@net-balance-display');
        });
    }
}
```
