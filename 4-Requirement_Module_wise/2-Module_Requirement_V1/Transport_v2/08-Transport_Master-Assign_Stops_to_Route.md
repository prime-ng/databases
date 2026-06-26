# Assign Stops to Route — Requirement Document

## 1. Screen Purpose & Overview

The Assign Stops to Route screen defines the sequence of stops along a travel path. It links static pickup/drop-off points to a specific route, orders them sequentially using ordinals, specifies scheduled arrival/departure times, and configures financial fares (one-way vs. both-side) for student fee billing.

---

## 2. Common Business Use Cases

1. **Sequencing a Route:** The coordinator assigns Route 10 to stop at Sector 15 first (Ordinal 1), then Sector 22 (Ordinal 2), planning the travel order.
2. **Configuring Fares:** Setting monthly transport fares for students boarding at a specific stop on Route 10.
3. **Trip Time Audits:** Specifying expected arrival and departure times at each stop to compare against actual vehicle dispatch records.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_pickup_points_route_jnt` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `shift_id` (INT UNSIGNED): FK to `tpt_shift`. Links the junction record to a specific shift.
* `route_id` (INT UNSIGNED): FK to `tpt_route`. Indicates the parent route.
* `pickup_drop` (ENUM): Specifies 'Pickup' or 'Drop' direction context.
* `pickup_point_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Identifies the stop.
* `ordinal` (SMALLINT UNSIGNED): Sequence order of the stop on the route (1, 2, 3, etc.).
* `total_distance` (DECIMAL(7,2)): Distance from the start terminal to this stop (KM).
* `arrival_time` (INT): Expected arrival time at stop, stored as minutes from midnight.
* `departure_time` (INT): Expected departure time from stop, stored as minutes from midnight.
* `estimated_time` (INT): Estimated travel duration from the previous stop (Minutes).
* `pickup_drop_fare` (DECIMAL(10,2)): One-way fare for student boarding/unboarding at this stop.
* `both_side_fare` (DECIMAL(10,2)): Round-trip fare if the student uses the stop for both pickup and drop.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Shift Select** | Dropdown | Required. Matches options in dropdown system. | `tpt_pickup_points_route_jnt.shift_id` |
| **Route Select** | Dropdown | Required. Matches options in dropdown system. | `tpt_pickup_points_route_jnt.route_id` |
| **Route Type** | Read-only Text | Displays `Pickup` or `Drop` direction of selected route. | `tpt_pickup_points_route_jnt.pickup_drop` |
| **Stop Select** | Dropdown | Required. Matches active stops list (`tpt_pickup_points`). | `tpt_pickup_points_route_jnt.pickup_point_id` |
| **Ordinal Order** | Number Input | Required. Positive integer. Must be unique per route. | `tpt_pickup_points_route_jnt.ordinal` |
| **Arrival Time** | Timepicker | Required. Estimated arrival time. | `tpt_pickup_points_route_jnt.arrival_time` |
| **Departure Time** | Timepicker | Required. Must be $\ge$ Arrival Time. | `tpt_pickup_points_route_jnt.departure_time` |
| **One-Side Fare** | Number Input | Required. Decimal $\ge 0.00$. | `tpt_pickup_points_route_jnt.pickup_drop_fare` |
| **Both-Side Fare** | Number Input | Required. Decimal $\ge$ One-Side Fare. | `tpt_pickup_points_route_jnt.both_side_fare` |

---

## 5. Business Logic & Validation Policies

### Unique Constraints
* A stop can only be assigned once per route direction, guarded by `uq_pickupPointRoute_route_pickupPoint`.

### Sequence Consistency
* The ordinal numbers must form a continuous sequence starting at 1. Gap checks are run on save.
* The expected timings must align with the route direction:
  $$\text{departure\_time} \ge \text{arrival\_time}$$

### Financial Fare Rules
* Round-trip rates must not be less than single journey fares:
  $$\text{both\_side\_fare} \ge \text{pickup\_drop\_fare}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Assign Stop to Route (Happy Path)
1. Go to `/transport/pickup-point-route` and click "+ Assign Stop".
2. Select Route: `Route 10 - Sector 15 Pickup` (this auto-populates Shift as `Morning Shift` and Type as `Pickup`).
3. Select Stop: `Sector 22 Market Stop`.
4. Set Ordinal: `1`.
5. Enter Arrival Time: `07:15 AM`, Departure Time: `07:20 AM` (arrival = 435 minutes from midnight, departure = 440).
6. Set One-Side Fare: `1000.00`, Both-Side Fare: `1800.00`.
7. Click Save. Confirm stop is assigned and displays in sequence grid.

### Test Case 2: Validate Fare Boundaries
1. Click "+ Assign Stop".
2. Set One-Side Fare: `1200.00` and Both-Side Fare: `1000.00` (invalid).
3. Fill valid details for other fields and click Save.
4. Verify validation error: "Both-Side Fare must be greater than or equal to One-Side Fare."

### Test Case 3: Verify Ordinal Uniqueness
1. Click "+ Assign Stop".
2. Select the same route as Test Case 1.
3. Select a different stop, but enter Ordinal: `1` (which is already assigned).
4. Click Save.
5. Verify validation error: "Ordinal Sequence 1 is already assigned to this Route."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Assign Stops Tab**: `@assign-stops-tab`
* **Assign New Button**: `@assign-stop-btn`
* **Route Dropdown**: `select[name="route_id"]`
* **Stop Dropdown**: `select[name="pickup_point_id"]`
* **Ordinal Field**: `input[name="ordinal"]`
* **Arrival Time Field**: `input[name="arrival_time"]`
* **Departure Time Field**: `input[name="departure_time"]`
* **One-Side Fare Field**: `input[name="pickup_drop_fare"]`
* **Both-Side Fare Field**: `input[name="both_side_fare"]`
* **Save Button**: `@save-assignment-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportAssignStopsTest extends DuskTestCase
{
    public function testAssignStopToRouteValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/pickup-point-route')
                    ->click('@assign-stops-tab')
                    ->click('@assign-stop-btn')
                    ->select('route_id', '1')
                    ->select('pickup_point_id', '2')
                    ->type('ordinal', '1')
                    ->type('arrival_time', '07:15')
                    ->type('departure_time', '07:20')
                    ->type('pickup_drop_fare', '1200.00')
                    ->type('both_side_fare', '1000.00') // Invalid
                    ->click('@save-assignment-btn')
                    ->assertSee('Both-Side Fare must be greater than or equal to One-Side Fare')
                    
                    // Correcting values
                    ->type('both_side_fare', '2000.00')
                    ->click('@save-assignment-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
