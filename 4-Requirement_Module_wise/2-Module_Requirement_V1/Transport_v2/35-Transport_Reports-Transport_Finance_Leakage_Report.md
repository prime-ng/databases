# Transport Finance & Leakage Report — Requirement Document

## 1. Screen Purpose & Overview

The Transport Finance & Leakage Report screen compiles monthly fee collection values against total vehicle operational costs (fuel purchases and workshop maintenance). 

It acts as a primary audit tool for the school's finance directors, highlighting cost-recovery deficits and pinpointing financial leakage in fleet operations.

---

## 2. Common Business Use Cases

1. **Analyzing Route Profitability:** The director compares total student fees collected on Route 10 against the fuel and maintenance expenses recorded for Bus V-101.
2. **Identifying Operational Deficits:** Checking if monthly fleet operating costs exceed total student transport fee recoveries.
3. **Auditing Late Fine Collections:** Verifying how much late fee revenue was generated and how much was waived.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_student_fee_detail.total_amount` (DECIMAL(10,2)): Mapped billing dues.
* `tpt_student_fee_collection.paid_amount` (DECIMAL(10,2)): Collected revenues.
* `tpt_vehicle_fuel.cost` (DECIMAL(12,2)): Fuel expenditures.
* `tpt_vehicle_maintenance.cost` (DECIMAL(12,2)): Workshop maintenance bills.
* `tpt_student_fine_detail.waved_fine_amount` (DECIMAL(10,2)): Fine waivers.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Academic Session** | Dropdown | Required. Selects the target academic year session. | Query filter parameters. |
| **Billing Month** | Dropdown | Optional. Filters report to a specific calendar month. | Query filter parameters. |
| **Export Details** | Button | Downloads analysis grid as CSV/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Total Operating Cost (OC)**:
  $$\text{Total OC} = \sum (\text{tpt\_vehicle\_fuel.cost}) + \sum (\text{tpt\_vehicle\_maintenance.cost})$$

* **Total Revenue Collected (RC)**:
  $$\text{Total RC} = \sum (\text{tpt\_student\_fee\_collection.paid\_amount})$$

* **Cost-Recovery Ratio (CRR) (%)**:
  $$\text{Cost-Recovery Ratio} = \left( \frac{\text{Total Revenue Collected}}{\text{Total Operating Cost}} \right) \times 100$$
  * If $\text{CRR} < 100\%$, the route is flagged as "Deficit" (shown in red).
  * If $\text{CRR} \ge 100\%$, the route is "Surplus" (shown in green).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Financial Summary (Happy Path)
1. Go to `/transport/transport-report` and click the **Transport Finance & Leakage Report** tab.
2. Select Academic Session: `2026-2027` and Month: `May 2026`. Click Search.
3. Verify that:
   - The grid loads summary totals for each route.
   - Column columns show: Route Code, Total Fees Billed, Total Fees Collected, Fuel Cost, Maintenance Cost, Net Surplus/Deficit, and Cost-Recovery Ratio.

### Test Case 2: Verify Deficit Alert Formatting
1. Locate Route 10 in the grid.
2. Assume fees collected is ₹15,000, while fuel and maintenance costs total ₹20,000.
3. Verify that:
   - Net Surplus/Deficit displays `-₹5,000.00` in red text.
   - Cost-Recovery Ratio displays:
     $$\text{CRR} = \left( \frac{15000}{20000} \right) \times 100 = 75.00\%$$

### Test Case 3: Export Validation
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same financial metrics as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Finance Leakage Tab**: `@finance-leakage-tab`
* **Session Filter Select**: `select[name="session_filter"]`
* **Month Filter Select**: `select[name="month_filter"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@finance-grid-table`
* **Net Surplus Cell**: `@net-surplus-cell-1` (dynamic row ID)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportFinanceLeakageReportTest extends DuskTestCase
{
    public function testFinanceLeakageMetricsAndAlerts()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@finance-leakage-tab')
                    ->waitFor('@finance-grid-table')
                    
                    // Filter report
                    ->select('session_filter', '1')
                    ->select('month_filter', '2026-05-01')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert surplus/deficit display
                    ->assertVisible('@net-surplus-cell-1')
                    ->assertSeeIn('@net-surplus-cell-1', '-₹'); // Deficit warning
        });
    }
}
```
