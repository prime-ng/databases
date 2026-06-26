# Driver/Vehicle Roster — Requirement Document

## 1. Screen Purpose & Overview

The Driver/Vehicle Roster screen manages long-term mappings of routes to vehicles and crews (drivers and helpers). This roster serves as the master schedule template, which is compiled dynamically into calendar-based daily trip sheets. 

To ensure safety and resource efficiency, the screen enforces strict conflict checks to prevent vehicles or drivers from being scheduled on overlapping route assignments.

---

## 2. Common Business Use Cases

1. **Setting Up Route Assignment:** Assigning Bus V-101 and Driver John Driver to Route 10 (Pickup) for the active academic session.
2. **Reassigning Fleet:** Swapping a vehicle assignment in the roster due to permanent fleet upgrades.
3. **Validating Crew Readiness:** Reviewing assigned drivers to ensure their licenses remain active for the duration of the roster dates.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_driver_route_vehicle_jnt` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `shift_id` (INT UNSIGNED): FK to `tpt_shift`. Parent shift mapping context.
* `route_id` (INT UNSIGNED): FK to `tpt_route`. Targeted route link.
* `vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Assigned fleet vehicle.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Mapped crew driver (must have 'Driver' role).
* `helper_id` (INT UNSIGNED): FK to `tpt_personnel`. Mapped crew helper (must have 'Helper' role).
* `pickup_drop` (ENUM): Specifies 'Pickup' or 'Drop' direction context.
* `effective_from` (DATE): Roster start validity date.
* `effective_to` (DATE): Roster end validity date (can be NULL for open-ended assignments).
* `total_students` (INT): Count of allocated students (cached helper metric, defaults to 0).
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last updated date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Shift Select** | Dropdown | Required. Matches options in dropdown system. | `tpt_driver_route_vehicle_jnt.shift_id` |
| **Route Select** | Dropdown | Required. Matches active routes (`tpt_route`). | `tpt_driver_route_vehicle_jnt.route_id` |
| **Vehicle Select** | Dropdown | Required. Matches active available vehicles. | `tpt_driver_route_vehicle_jnt.vehicle_id` |
| **Primary Driver** | Dropdown | Required. Matches personnel with role `Driver`. | `tpt_driver_route_vehicle_jnt.driver_id` |
| **Primary Helper** | Dropdown | Optional. Matches personnel with role `Helper`. | `tpt_driver_route_vehicle_jnt.helper_id` |
| **Route Direction** | Read-only Text | Displays `Pickup` or `Drop` direction of selected route. | `tpt_driver_route_vehicle_jnt.pickup_drop` |
| **Start Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `tpt_driver_route_vehicle_jnt.effective_from` |
| **End Date** | Datepicker | Optional. Must be $\ge$ Start Date. | `tpt_driver_route_vehicle_jnt.effective_to` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `tpt_driver_route_vehicle_jnt.is_active` |

---

## 5. Business Logic & Validation Policies

### Crew Role Locking
* The selected `driver_id` must have `role = 'Driver'`.
* The selected `helper_id` must have `role = 'Helper'`.

### Driver License Validity Check
* The assigned driver's commercial license must be valid beyond the roster start date:
  $$\text{tpt\_personnel.license\_valid\_upto} \ge \text{effective\_from}$$

### Overlap Check & Constraint Trigger
* An active database trigger `trg_driver_route_vehicle_unique_assignment` blocks overlapping assignments for the same shift, route, vehicle, and driver. Specifically, a record is rejected if there exists a row satisfying:
  $$\text{shift\_id} = \text{shift\_id}_{\text{new}} \land \text{route\_id} = \text{route\_id}_{\text{new}} \land \text{vehicle\_id} = \text{vehicle\_id}_{\text{new}} \land \text{driver\_id} = \text{driver\_id}_{\text{new}}$$
  $$\text{AND } \left( (\text{effective\_to}_{\text{new}} \text{ IS NULL} \land (\text{effective\_to} \text{ IS NULL} \lor \text{effective\_to} \ge \text{effective\_from}_{\text{new}})) \lor (\text{effective\_to}_{\text{new}} \le \text{effective\_to} \land \text{effective\_from}_{\text{new}} \ge \text{effective\_from}) \right)$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create Roster Entry (Happy Path)
1. Go to `/transport/driver-route-vehicle` and click "+ Add Roster Entry".
2. Select Shift: Morning Shift. Select Route: Route 10 (Pickup).
3. Select Vehicle: `DL-2C-1234`. Select Driver: `John Driver`, Helper: `Dave Helper`.
4. Set Start Date: Today's date, End Date: One year from today.
5. Click Save. Confirm the mapping is registered and shows in the roster list.

### Test Case 2: Validate Expired License Block
1. Click "+ Add Roster Entry".
2. Select a Driver whose license expiry date is in the past.
3. Fill valid details for other fields and click Save.
4. Verify validation error: "Selected Driver has an expired commercial license."

### Test Case 3: Overlapping Schedule Conflict
1. Click "+ Add Roster Entry".
2. Re-enter the exact same details as Test Case 1 (same Route, Vehicle, Driver, Shift, and dates).
3. Click Save.
4. Verify that save is rejected with the message: "Overlapping assignment for the same shift, route, vehicle, and driver."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Roster Tab**: `@roster-tab`
* **New Roster Button**: `@add-roster-btn`
* **Shift Dropdown**: `select[name="shift_id"]`
* **Route Dropdown**: `select[name="route_id"]`
* **Vehicle Dropdown**: `select[name="vehicle_id"]`
* **Driver Dropdown**: `select[name="driver_id"]`
* **Helper Dropdown**: `select[name="helper_id"]`
* **Start Date Field**: `input[name="effective_from"]`
* **End Date Field**: `input[name="effective_to"]`
* **Save Button**: `@save-roster-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportRosterTest extends DuskTestCase
{
    public function testRosterOverlapsAndValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/driver-route-vehicle')
                    ->click('@roster-tab')
                    ->click('@add-roster-btn')
                    ->select('shift_id', '1')
                    ->select('route_id', '1')
                    ->select('vehicle_id', '1')
                    ->select('driver_id', '1')
                    ->keys('input[name="effective_from"]', '05232026') // 2026-05-23
                    ->click('@save-roster-btn')
                    ->assertSee('saved successfully')
                    
                    // Attempting duplicate/overlapping insert
                    ->click('@add-roster-btn')
                    ->select('shift_id', '1')
                    ->select('route_id', '1')
                    ->select('vehicle_id', '1')
                    ->select('driver_id', '1')
                    ->keys('input[name="effective_from"]', '05232026')
                    ->click('@save-roster-btn')
                    ->assertSee('Overlapping assignment');
        });
    }
}
```
