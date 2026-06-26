# Cost Maintenance Report — Requirement Document

## 1. Screen Purpose & Overview

The Cost Maintenance Report screen provides an audit console tracking cumulative maintenance costs, garage durations, parts replacement expenses, and upcoming service schedules for each vehicle in the fleet. 

This enables fleet managers to identify vehicles with high upkeep costs and schedule timely maintenance.

---

## 2. Common Business Use Cases

1. **Analyzing High Upkeep Vehicles:** The manager checks which buses have total maintenance costs exceeding ₹50,000 in the current year.
2. **Monitoring Service Windows:** Checking how many days vehicles spent under repair at the workshop, impacting route availability.
3. **Auditing Service Reminders:** Reviewing upcoming maintenance deadlines to prevent safety lapses.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_vehicle_maintenance.id` (INT UNSIGNED): Primary Key.
* `tpt_vehicle_maintenance.cost` (DECIMAL(12,2)): Actual repair cost.
* `tpt_vehicle_maintenance.maintenance_initiation_date` (DATE): Repair start.
* `tpt_vehicle_maintenance.out_service_date` (DATE): Repair completion.
* `tpt_vehicle_maintenance.next_due_date` (DATE): Upcoming service reminder.
* `tpt_vehicle.registration_no` (VARCHAR(30)): Vehicle identifier.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Range** | Date Range Picker | Required. Defaults to the last 30 days. | Query filter parameters. |
| **Vehicle Select** | Dropdown | Optional. Filters report to a specific vehicle. | `tpt_vehicle_maintenance.vehicle_id` |
| **Export Details** | Button | Downloads analysis grid as CSV/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Total Repair Duration (Days)**:
  $$\text{Total Days} = \sum (\text{DATEDIFF\_DAYS}(\text{maintenance\_initiation\_date}, \text{out\_service\_date}))$$

* **Total Fleet Upkeep Cost**:
  $$\text{Total Upkeep} = \sum (\text{tpt\_vehicle\_maintenance.cost}) + \sum (\text{tpt\_vehicle\_fuel.cost})$$

* **Upcoming Service Status**:
  $$\text{Days to Service} = \text{next\_due\_date} - \text{CURRENT\_DATE()}$$
  * If $\text{Days to Service} \le 7$, flag as "Service Overdue/Soon" (displayed in orange).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Filter Maintenance Costs (Happy Path)
1. Go to `/transport/transport-report` and click the **Cost Maintenance** tab.
2. Select Date Range: Last 6 months. Click search.
3. Verify that:
   - The grid loads maintenance totals for each vehicle.
   - Column columns show: Registration No, Total Repairs Completed, Total Repair Cost, Total Workshop Days, and Next Due Date.

### Test Case 2: Verify Service Reminders
1. Manually set a vehicle's `next_due_date` to 4 days from today in the database.
2. Search the vehicle's report on screen.
3. Verify that the Next Due Date column displays a warning badge indicating "Due Soon".

### Test Case 3: Export Validation
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same repair columns and costs as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Cost Maintenance Tab**: `@cost-maintenance-tab`
* **Vehicle Filter Select**: `select[name="vehicle_filter"]`
* **Date Range Field**: `input[name="date_range"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@maintenance-report-table`
* **Repair Cost Cell**: `@repair-cost-cell-1` (dynamic row ID)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportCostMaintenanceTest extends DuskTestCase
{
    public function testMaintenanceCostsFiltersAndAlerts()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@cost-maintenance-tab')
                    ->waitFor('@maintenance-report-table')
                    
                    // Filter report
                    ->select('vehicle_filter', '1')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns render details
                    ->assertSee('DL-2C-1234')
                    ->assertVisible('@repair-cost-cell-1');
        });
    }
}
```
