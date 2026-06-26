# Universal Transport Report — Requirement Document

## 1. Screen Purpose & Overview

The Universal Transport Report screen provides institution-wide aggregate analytics across all shifts, routes, and fleets. It compiles multi-year utilization trends, global carbon footprints, total transport revenue vs. operational costs, and safety records. 

This enables school administrators and board members to make strategic, data-driven decisions on long-term fleet purchases, vendor contract reviews, and policy updates.

---

## 2. Common Business Use Cases

1. **Strategic Capital Budgeting:** The school board reviews annual fleet operational costs to evaluate if they should purchase new school-owned buses or transition completely to leased vendor agreements.
2. **Environmental Impact Auditing:** Tracking total vehicle emissions indices and fuel types across years to comply with local green school mandates.
3. **Safety Policy Reviews:** Monitoring total safety incidents and speeding warnings across years to refine driver training policies.

---

## 3. Database Schema & Data Dictionary

The report aggregates data across all historical databases:

* `tpt_vehicle.vehicle_emission_class_id` (INT UNSIGNED): FK to emission standards.
* `tpt_vehicle_fuel.cost` (DECIMAL(12,2)): Historical fuel bills.
* `tpt_vehicle_maintenance.cost` (DECIMAL(12,2)): Historical repair bills.
* `tpt_student_fee_collection.paid_amount` (DECIMAL(10,2)): Historical fees.
* `tpt_trip_incidents.id` (INT UNSIGNED): Multi-year safety logs.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Start Academic Year** | Dropdown | Required. Range: past 5 years. | Query filter parameters. |
| **End Academic Year** | Dropdown | Required. Must be $\ge$ Start Academic Year. | Query filter parameters. |
| **Export Summary** | Button | Downloads global ledger as PDF/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Average Fleet Emission Index**: Shows percentage of clean-energy vehicles (CNG/Electric) in the active fleet:
  $$\text{Clean Fleet Ratio} = \left( \frac{\text{Count(CNG) + Count(Electric)}}{\text{Total Active Fleet Size}} \right) \times 100$$

* **Net Multi-Year Margin (MYM)**:
  $$\text{MYM} = \sum_{\text{Years}} (\text{Revenue Collected} - \text{Total Operating Cost})$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Multi-Year Summary (Happy Path)
1. Go to `/transport/transport-report` and click the **Universal Transport** tab.
2. Select Start Year: `2024-2025` and End Year: `2026-2027`. Click Search.
3. Verify that:
   - The screen renders summary widgets: Total Historical Revenue, Total Operating Cost, Net Margin, and Clean Fleet Ratio.
   - Charts show monthly operational trends plotted correctly.

### Test Case 2: Validate Year Range Continuity
1. Click the filters.
2. Set Start Year to `2026-2027` and End Year to `2024-2025` (invalid).
3. Click Search.
4. Verify validation error: "End Academic Year must be greater than or equal to Start Academic Year."

### Test Case 3: Verify Clean Fleet Ratio
1. Count vehicles in database: Total = 10, Diesel = 6, CNG = 3, Electric = 1.
2. Verify that:
   - The Clean Fleet Ratio displays:
     $$\text{Clean Fleet Ratio} = \left( \frac{3 + 1}{10} \right) \times 100 = 40.00\%$$

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Universal Report Tab**: `@universal-report-tab`
* **Start Year Select**: `select[name="start_year"]`
* **End Year Select**: `select[name="end_year"]`
* **Search Button**: `@filter-report-btn`
* **Report Container**: `@universal-report-container`
* **Clean Ratio Metric**: `@clean-fleet-ratio-metric`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportUniversalReportTest extends DuskTestCase
{
    public function testUniversalReportFiltersAndMetrics()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@universal-report-tab')
                    ->waitFor('@universal-report-container')
                    
                    // Filter report with invalid years
                    ->select('start_year', '2026-2027')
                    ->select('end_year', '2024-2025')
                    ->click('@filter-report-btn')
                    ->assertSee('End Academic Year must be greater than or equal to')
                    
                    // Correcting filters
                    ->select('start_year', '2024-2025')
                    ->select('end_year', '2026-2027')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns and clean ratio metric
                    ->assertVisible('@clean-fleet-ratio-metric')
                    ->assertSeeIn('@clean-fleet-ratio-metric', '%');
        });
    }
}
```
