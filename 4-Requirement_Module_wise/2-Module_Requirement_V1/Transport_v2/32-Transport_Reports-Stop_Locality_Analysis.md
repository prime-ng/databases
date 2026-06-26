# Stop & Locality Analysis Report — Requirement Document

## 1. Screen Purpose & Overview

The Stop & Locality Analysis Report screen aggregates student allocations by stop points to determine passenger densities across geographic sectors. 

This helps planners identify under-served neighborhoods, optimize stop layouts, and adjust vehicle capacities to match local density.

---

## 2. Common Business Use Cases

1. **Stop Density Analysis:** The manager identifies that the "Sector 22 Market Stop" has 45 allocated students, signaling a need to schedule a larger bus or add a nearby stop to split the load.
2. **Reviewing Unused Stops:** Identifying stops with zero allocations over the past six months to remove them from active routes.
3. **Geospatial Route Balancing:** Tracing passenger clusters to redraw route boundaries.

---

## 3. Database Schema & Data Dictionary

The report aggregates data from the following tables:

* `tpt_pickup_points.id` (INT UNSIGNED): Primary Key.
* `tpt_pickup_points.name` (VARCHAR(200)): Mapped stop name.
* `tpt_pickup_points.latitude` (DECIMAL(10,7)): GPS Latitude.
* `tpt_pickup_points.longitude` (DECIMAL(10,7)): GPS Longitude.
* `tpt_student_route_allocation_jnt.pickup_stop_id` (INT UNSIGNED): Mapped allocations.
* `tpt_student_route_allocation_jnt.active_status` (TINYINT): Mapped status (must be active).

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Shift Select** | Dropdown | Required. Filters report to a specific Shift. | `tpt_pickup_points.shift_id` |
| **Min Student Count** | Number Input | Optional. Filters stops with allocated students $\ge$ Value. | Query parameter filter. |
| **Export Details** | Button | Downloads analysis grid as CSV/Excel. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Stop Passenger Density Count**:
  $$\text{Density Count} = \text{COUNT(tpt\_student\_route\_allocation\_jnt.id) WHERE pickup\_stop\_id = StopID AND active\_status = 1}$$
* **Geospatial Centroid Distance**: Used to trace proximity distances between clustered stops:
  $$\text{Distance} = \text{ST\_Distance\_Spheroid}(\text{location}_1, \text{location}_2)$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Load Density Grid (Happy Path)
1. Go to `/transport/transport-report` and click the **Stop & Locality Analysis** tab.
2. Select Shift: `Morning Shift`. Click search.
3. Verify that:
   - The grid loads stops associated with the Morning Shift.
   - Columns show Stop Code, Stop Name, Latitude/Longitude, and Total Allocated Students.

### Test Case 2: Filter by Min Student Count
1. Enter `10` in the **Min Student Count** field. Click Search.
2. Verify that:
   - Stops with 9 or fewer allocated students are removed from the grid.
   - Grid counts update instantly.

### Test Case 3: Export Validation
1. Click the "Export CSV" button.
2. Confirm the downloaded CSV file contains correct columns (Stop Code, Name, Latitude, Longitude, and Count).

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Locality Analysis Tab**: `@locality-analysis-tab`
* **Shift Select Dropdown**: `select[name="shift_filter"]`
* **Min Count Field**: `input[name="min_count"]`
* **Search Button**: `@filter-report-btn`
* **Analysis Grid Table**: `@analysis-grid-table`
* **Export CSV Button**: `@export-csv-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportLocalityAnalysisTest extends DuskTestCase
{
    public function testLocalityAnalysisFiltersAndExports()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@locality-analysis-tab')
                    ->waitFor('@analysis-grid-table')
                    
                    // Filter report
                    ->select('shift_filter', '1')
                    ->type('min_count', '10')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns render details
                    ->assertSee('Sector 22 Market Stop')
                    
                    // Trigger CSV export
                    ->click('@export-csv-btn');
        });
    }
}
```
