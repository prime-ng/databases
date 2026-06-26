# Stoppage Details — Requirement Document

## 1. Screen Purpose & Overview

The Stoppage Details screen provides a read-only auditing log of scheduled vs. actual arrival and departure times for all stops on completed trips. 

This console allows transport coordinators to monitor route running times, evaluate driver speed and routing compliance, and verify delays reported by drivers.

---

## 2. Common Business Use Cases

1. **Auditing Chronic Delays:** The manager reviews historical logs for Route 10 to check why a specific residential gate stop is consistently showing delays of more than 10 minutes.
2. **Parent Complaint Resolution:** Checking the exact departure timestamp of a bus when a parent claims the driver left a stop ahead of schedule.
3. **Trip Performance Reporting:** Exporting a weekly schedule compliance log for administrative review.

---

## 3. Database Schema & Data Dictionary

The auditing console pulls records directly from the `tpt_trip_stop_detail` and associated master tables:

* `tpt_trip.trip_date` (DATE): Target date of trip execution.
* `tpt_trip_stop_detail.trip_id` (INT UNSIGNED): FK to `tpt_trip`.
* `tpt_pickup_points.name` (VARCHAR(200)): Mapped stop name.
* `tpt_trip_stop_detail.ordinal` (SMALLINT UNSIGNED): Stop sequence order.
* `tpt_trip_stop_detail.sch_arrival_time` (DATETIME): Scheduled arrival timestamp.
* `tpt_trip_stop_detail.reaching_time` (TIMESTAMP): Actual arrival timestamp.
* `tpt_trip_stop_detail.sch_departure_time` (DATETIME): Scheduled departure timestamp.
* `tpt_trip_stop_detail.leaving_time` (TIMESTAMP): Actual departure timestamp.
* `tpt_trip_stop_detail.reached_flag` (TINYINT): Indicator (0 = Missed, 1 = Reached).
* `tpt_trip_stop_detail.emergency_flag` (TINYINT): Indicator (0 = Normal, 1 = Emergency).
* `tpt_trip_stop_detail.emergency_remarks` (VARCHAR(512)): Remarks explaining halts.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Filter** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | Query parameter filter. |
| **Route Filter** | Dropdown | Optional. Filters list to a specific Route. | `tpt_trip.route_id` |
| **Search Keyword** | Text Input | Optional. Filters by Stop Name or Driver Name. | Wildcard string match. |
| **Export Report** | Button | Downloads filtered audit grid as Excel/PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Variance Calculations & Mathematical Formulas
* **Arrival Variance (Minutes)**:
  $$\text{Arrival Variance} = \text{DATEDIFF\_MINUTES}(\text{sch\_arrival\_time}, \text{reaching\_time})$$
  * If $\text{Arrival Variance} > 0$, the stop is marked as "Delayed" (displayed in red).
  * If $\text{Arrival Variance} < 0$, the stop is marked as "Early" (displayed in blue).
  * If $\text{Arrival Variance} = 0$, it is "On Time".

* **Stop Dwell Time (Minutes)**:
  $$\text{Dwell Time} = \text{DATEDIFF\_MINUTES}(\text{reaching\_time}, \text{leaving\_time})$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Filter Logs by Route & Date
1. Navigate to `/transport/trip` and select the **Stoppage Details** tab.
2. Select Date: Yesterday. Select Route: `Route 10`. Click search.
3. Verify that:
   - The grid loads only stops mapped to Route 10 executed yesterday.
   - Grid headers show Scheduled Arrival, Actual Arrival, Scheduled Departure, Actual Departure, and Variance.

### Test Case 2: Verify Delay Variance Formatting
1. Locate a row in the grid where a stop was scheduled for `07:10 AM` but the driver arrived at `07:18 AM`.
2. Confirm that the Variance column displays `+8 mins` formatted in red text.
3. Locate a row where arrival was on time. Confirm Variance displays `0 mins` in neutral gray.

### Test Case 3: Review Emergency Stops
1. Filter the grid to show only rows where `emergency_flag = 1`.
2. Verify that:
   - An alert warning icon is displayed on the row.
   - Hovering over the icon displays the emergency remarks (e.g. "Road blocked by parade").

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Stoppage Details Tab**: `@stoppage-details-tab`
* **Date Filter Field**: `input[name="date_filter"]`
* **Route Filter Select**: `select[name="route_filter"]`
* **Details Grid**: `@stoppage-details-grid`
* **Variance Cell**: `@variance-cell-1` (dynamic row ID)
* **Export PDF Button**: `@export-pdf-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStoppageDetailsTest extends DuskTestCase
{
    public function testStoppageDetailsAuditGrid()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/trip')
                    ->click('@stoppage-details-tab')
                    ->waitFor('@stoppage-details-grid')
                    
                    // Apply filters
                    ->keys('input[name="date_filter"]', '05222026') // 2026-05-22
                    ->select('route_filter', '1')
                    ->pause(1000)
                    
                    // Assert variance calculations display
                    ->assertVisible('@variance-cell-1')
                    ->assertSeeIn('@variance-cell-1', 'mins')
                    
                    // Trigger PDF export
                    ->click('@export-pdf-btn');
        });
    }
}
```
