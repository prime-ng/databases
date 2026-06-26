# Route Performance Report — Requirement Document

## 1. Screen Purpose & Overview

The Route Performance Report screen provides transport coordinators and school administrators with analytical insights into route efficiency, timing delays, passenger volumes, and run times. 

It highlights schedules that are consistently delayed, helping to optimize routes and adjust stop time buffers.

---

## 2. Common Business Use Cases

1. **Analyzing Persistent Route Delays:** The manager checks if Route 10's average delay is increasing, signaling traffic pattern adjustments.
2. **Resource Re-allocation:** Auditing total passenger volume across routes to determine if a smaller vehicle should replace a large bus on low-density runs.
3. **Driver Compliance Check:** Comparing scheduled vs. actual trip durations to audit driver speeds.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_trip.route_id` (INT UNSIGNED): FK to `tpt_route`.
* `tpt_trip.status` (VARCHAR): Filtered to 'Completed'.
* `tpt_trip_stop_detail.sch_arrival_time` (DATETIME): Scheduled stop arrival.
* `tpt_trip_stop_detail.reaching_time` (TIMESTAMP): Actual stop arrival.
* `tpt_student_route_allocation_jnt.student_id` (INT UNSIGNED): Allocated passengers.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Range** | Date Range Picker | Required. Defaults to the last 30 days. | Query filter parameters. |
| **Route Select** | Dropdown | Optional. Filters report to a specific route. | `tpt_trip.route_id` |
| **Export Report** | Button | Downloads filtered report as Excel/PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Trip Running Time (Minutes)**:
  $$\text{Running Time} = \text{DATEDIFF\_MINUTES}(\text{start\_time}, \text{end\_time})$$

* **Average Stop Delay (Minutes)**:
  $$\text{Average Delay} = \frac{\sum_{i=1}^{N} (\text{Actual Arrival Time}_i - \text{Scheduled Arrival Time}_i)}{N}$$
  * *Where $N$* is the total count of stop pings on completed trips during the filter period.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Report with Date Filters
1. Go to `/transport/transport-report` and click the **Route Performance Report** tab.
2. Select Date Range: From 30 days ago to Today. Click search.
3. Verify that:
   - The grid renders a list of active routes.
   - Column columns display: Route Code, Route Name, Total Completed Trips, Average Delay (Mins), and Passenger Capacity Load.

### Test Case 2: Verify Average Delay Calculation
1. Locate a route in the report grid.
2. Manually calculate the average arrival delay from the database logs for the selected date range.
3. Verify that the displayed value matches your calculated average.

### Test Case 3: Export Validation
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same route rows and averages as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Route Performance Tab**: `@route-performance-tab`
* **Date Range Field**: `input[name="date_range"]`
* **Route Dropdown**: `select[name="route_id"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@report-grid-table`
* **Export PDF Button**: `@export-pdf-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportRoutePerformanceTest extends DuskTestCase
{
    public function testRoutePerformanceFiltersAndExports()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@route-performance-tab')
                    ->waitFor('@report-grid-table')
                    
                    // Filter report
                    ->select('route_id', '1')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert delay statistics display
                    ->assertSee('Route 10')
                    ->assertSee('mins')
                    
                    // Trigger PDF export
                    ->click('@export-pdf-btn');
        });
    }
}
```
