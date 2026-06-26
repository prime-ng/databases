# Trip & Discipline Report — Requirement Document

## 1. Screen Purpose & Overview

The Trip & Discipline Report screen provides insights into fleet safety, driver behavior, and route compliance. 

It consolidates trip runtime logs, speeding incidents, sudden braking warnings, and general vehicle discipline events. This enables coordinators to identify unsafe driving habits and ensure student safety.

---

## 2. Common Business Use Cases

1. **Auditing Speeding Incidents:** The manager reviews a list of speed violations logged by GPS tracking terminals to reprimand drivers.
2. **Reviewing Route Adherence:** Auditing trips flagged for skipping designated stops or taking unauthorized detours.
3. **Safety Performance Appraisals:** Generating monthly safety reports for each driver in the fleet.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_trip.id` (INT UNSIGNED): Primary Key.
* `tpt_trip.driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Mapped driver.
* `tpt_trip.vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Mapped vehicle.
* `tpt_trip_incidents.incident_type` (INT UNSIGNED): Filtered by 'Speeding' or 'Discipline'.
* `tpt_trip_incidents.severity` (ENUM): 'LOW', 'MEDIUM', 'HIGH'.
* `tpt_trip_incidents.description` (VARCHAR(512)): Details of the infraction.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Range** | Date Range Picker | Required. Defaults to the last 30 days. | Query filter parameters. |
| **Driver Select** | Dropdown | Optional. Filters report to a specific driver. | `tpt_trip.driver_id` |
| **Severity Filter** | Dropdown | Optional. Options: `All`, `LOW`, `MEDIUM`, `HIGH`. | `tpt_trip_incidents.severity` |
| **Export Report** | Button | Downloads analysis grid as CSV/PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Incident Rate Per 100 KM**:
  $$\text{Incident Rate} = \left( \frac{\text{Total Incidents}}{\text{Total KM Traveled}} \right) \times 100$$
  * *Where Total KM Traveled* is:
    $$\text{Total KM} = \sum (\text{tpt\_trip.end\_odometer\_reading} - \text{tpt\_trip.start\_odometer\_reading})$$

* **Driver Safety Score (%)**:
  $$\text{Safety Score} = 100 - \left( \text{Count(LOW)} \times 1 + \text{Count(MEDIUM)} \times 5 + \text{Count(HIGH)} \times 15 \right)$$
  * The safety score is capped at a minimum value of 0.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Filter Logs by Driver (Happy Path)
1. Go to `/transport/transport-report` and click the **Trip & Discipline** tab.
2. Select Driver: `John Driver`. Click search.
3. Verify that:
   - The grid loads completed runs executed by John Driver.
   - Column columns display: Date, Trip ID, Vehicle, Total KM, Incidents Logged, and Safety Score.

### Test Case 2: Verify Safety Score Deductions
1. Manually insert one HIGH severity speeding incident and one LOW severity delay incident for John Driver.
2. Search John's report.
3. Verify that the Safety Score displays:
   $$\text{Safety Score} = 100 - (1 \times 1 + 0 \times 5 + 1 \times 15) = 84.00\%$$

### Test Case 3: Export Report
1. Click the "Export PDF" button.
2. Confirm the generated PDF document renders the same driver safety metrics as shown on the screen.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Discipline Tab**: `@discipline-tab`
* **Driver Dropdown**: `select[name="driver_filter"]`
* **Date Range Field**: `input[name="date_range"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@discipline-grid-table`
* **Safety Score Cell**: `@safety-score-cell-1` (dynamic row ID)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportTripDisciplineTest extends DuskTestCase
{
    public function testDisciplineFiltersAndScores()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@discipline-tab')
                    ->waitFor('@discipline-grid-table')
                    
                    // Filter report
                    ->select('driver_filter', '1')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns render details
                    ->assertSee('John Driver')
                    ->assertVisible('@safety-score-cell-1');
        });
    }
}
```
