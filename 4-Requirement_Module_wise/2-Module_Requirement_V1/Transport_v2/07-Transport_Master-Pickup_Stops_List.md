# Pickup Stops List — Requirement Document

## 1. Screen Purpose & Overview

The Pickup Stops List provides a read-only tabular console of all configured pickup and drop-off stops. It enables transport managers, administrators, and coordinators to search, filter, and audit stops across neighborhoods without modifying configurations. 

This screen supports full tabular grid features, pagination, searching by keyword, and active/inactive status filtering, with options to export the data.

---

## 2. Common Business Use Cases

1. **Searching Stops by Locality:** A parent calls asking if there is a stop near "Sector 62". The manager enters "Sector 62" in the search box to check.
2. **Shift Audit:** The manager filters the stops list by "Morning Shift" to review only those stops active during the morning.
3. **Compliance Export:** Exporting the full list of active pickup points to a CSV/Excel file for routing adjustments.

---

## 3. Database Schema & Data Dictionary

The grid columns display data aggregated from the `tpt_pickup_points` and `tpt_shift` tables:

* `tpt_pickup_points.code` (VARCHAR(50)): Stop Code.
* `tpt_pickup_points.name` (VARCHAR(200)): Stop Name.
* `tpt_shift.name` (VARCHAR(100)): Linked Shift Name.
* `tpt_pickup_points.latitude` (DECIMAL(10,7)): Stop Latitude coordinate.
* `tpt_pickup_points.longitude` (DECIMAL(10,7)): Stop Longitude coordinate.
* `tpt_pickup_points.total_distance` (DECIMAL(7,2)): Distance from school (KM).
* `tpt_pickup_points.estimated_time` (INT): Travel duration from school (Minutes).
* `tpt_pickup_points.stop_type` (ENUM): 'Pickup', 'Drop', or 'Both'.
* `tpt_pickup_points.is_active` (TINYINT): Status (0 = Inactive, 1 = Active).

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Search Keyword** | Text Input | Optional. Filters by Stop Code, Name, or landmark. | Query parameter filter. |
| **Shift Filter** | Dropdown | Optional. Filters list to a specific Shift. | `tpt_pickup_points.shift_id` |
| **Status Filter** | Dropdown | Optional. Filters by `All`, `Active`, or `Inactive`. | `tpt_pickup_points.is_active` |
| **Export Button** | Button | Click to export filtered data to Excel or PDF. | Local utility generation. |

---

## 5. Business Logic & Validation Policies

### Data Filtering & Pagination
* The search query filters using SQL wildcard matches:
  $$\text{Query} = \text{WHERE } (\text{code LIKE \%Keyword\% OR name LIKE \%Keyword\%})$$
* Grid results are paginated at 15 records per page by default.
* Soft-deleted records (`deleted_at IS NOT NULL`) are omitted.

### Export Access Control
* The export functions (PDF/CSV) are only available to users with role permissions `Transport Coordinator` or `Transport Manager`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Search Verification
1. Navigate to `/transport/pickup-point` and click the "Pickup Stops List" tab.
2. In the **Search Keyword** field, enter a unique keyword (e.g., `Sector 22`).
3. Press Enter or click the search button.
4. Verify that only stops containing "Sector 22" in their code or name are listed in the grid.

### Test Case 2: Shift Filtering
1. Locate the **Shift Filter** dropdown and select `Morning Shift`.
2. Verify that the grid updates to show only stops associated with that shift.
3. Check the database to confirm that the count matches the selected shift's active stops count.

### Test Case 3: Export Grid Data
1. Filter the grid to show only "Active" status stops.
2. Click the "Export CSV" button.
3. Open the downloaded CSV file and verify that the number of rows matches the grid count exactly, and the columns contain correct GPS details.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Pickup Stops List Tab**: `@pickup-stops-list-tab`
* **Search Input Field**: `input[name="search_keyword"]` or `@search-input`
* **Shift Filter Select**: `select[name="shift_filter"]`
* **Status Filter Select**: `select[name="status_filter"]`
* **Stops Data Table**: `@stops-data-table`
* **CSV Export Button**: `@export-csv-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStopsListTest extends DuskTestCase
{
    public function testSearchAndFilterStopsGrid()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/pickup-point')
                    ->click('@pickup-stops-list-tab')
                    ->waitFor('@stops-data-table')
                    
                    // Input search keyword
                    ->type('search_keyword', 'Sector 22')
                    ->pause(1000) // Allow live reload
                    ->assertSee('Sector 22 Market Stop')
                    ->assertDontSee('Noida Metro Station')
                    
                    // Filter by Status
                    ->select('status_filter', 'Inactive')
                    ->pause(1000)
                    ->assertDontSee('Sector 22 Market Stop') // Active stop is hidden
                    
                    // Trigger CSV Export
                    ->click('@export-csv-btn');
        });
    }
}
```
