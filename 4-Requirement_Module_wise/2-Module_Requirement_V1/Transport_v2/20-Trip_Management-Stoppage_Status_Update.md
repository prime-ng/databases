# Stoppage Status Update — Requirement Document

## 1. Screen Purpose & Overview

The Stoppage Status Update screen tracks real-time stop arrivals, departures, and delays during active trip execution. Using GPS proximity triggers or manual companion app confirmation, the screen logs arrival and departure timestamps. 

This enables parent notifications and provides administrators with trip compliance data.

---

## 2. Common Business Use Cases

1. **Logging Stop Arrival:** The companion app automatically registers that Bus V-101 arrived at stop "Sector 15" at 07:15 AM based on GPS coordinates.
2. **Manual Departure Logging:** The helper manually logs a departure timestamp once all students have boarded and doors are secured.
3. **Emergency stop Halt:** Logging an emergency stop delay due to road barriers.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_trip_stop_detail` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `trip_id` (INT UNSIGNED): FK to `tpt_trip`. Mapped active trip.
* `stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Target stop.
* `pickup_drop` (ENUM): Specifies 'Pickup' or 'Drop' context.
* `ordinal` (SMALLINT UNSIGNED): Sequence order of stop along this trip route.
* `sch_arrival_time` (DATETIME): Scheduled arrival timestamp.
* `sch_departure_time` (DATETIME): Scheduled departure timestamp.
* `reached_flag` (TINYINT): 0 = Not Reached, 1 = Reached. Defaults to 0.
* `reaching_time` (TIMESTAMP): Actual arrival timestamp.
* `leaving_time` (TIMESTAMP): Actual departure timestamp.
* `emergency_flag` (TINYINT): 0 = No, 1 = Yes. Defaults to 0.
* `emergency_time` (TIMESTAMP): Timestamp of emergency log.
* `emergency_remarks` (VARCHAR(512)): Remarks for emergency halts.
* `updated_by` (INT UNSIGNED): FK to `tpt_personnel`. The crew member logging the update.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Trip Reference** | Read-only Text | Auto-populated. Mapped active trip ID. | `tpt_trip_stop_detail.trip_id` |
| **Stop Name** | Read-only Text | Displays stop label and landmark. | `tpt_trip_stop_detail.stop_id` |
| **Scheduled Arrival** | Read-only Text | Displays expected arrival timestamp. | `tpt_trip_stop_detail.sch_arrival_time` |
| **Actual Arrival** | Button / Time | Auto-captured on click. Stored on arrival check. | `tpt_trip_stop_detail.reaching_time` |
| **Actual Departure** | Button / Time | Auto-captured. Must be $\ge$ Actual Arrival. | `tpt_trip_stop_detail.leaving_time` |
| **Emergency Halt** | Toggle | Required. Defaults to 0 (No). | `tpt_trip_stop_detail.emergency_flag` |
| **Emergency Notes** | Text Area | Required if `emergency_flag = 1`. | `tpt_trip_stop_detail.emergency_remarks` |

---

## 5. Business Logic & Validation Policies

### Sequence Enforcement
* Stoppage status updates must be logged sequentially. The system blocks updating Stop $N$ until Stop $N-1$ is marked as Reached:
  $$\text{reached\_flag}_{N-1} = 1$$

### GPS Proximity Trigger
* If GPS is active on the companion app, the device dispatches a background HTTP request to set `reached_flag = 1` and `reaching_time = NOW()` when the vehicle enters the stop's coordinates within a 50-meter buffer:
  $$\text{Distance}(\text{vehicle\_gps}, \text{tpt\_pickup\_points.location}) \le 50\text{ meters}$$

### Travel Time Validation
* Departure timestamps must be equal to or greater than arrival timestamps:
  $$\text{leaving\_time} \ge \text{reaching\_time}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Sequential Stop Arrival Logging (Happy Path)
1. Open the companion app. Locate the active trip route.
2. Select Stop 1 (Ordinal 1) and click **Mark Arrived**.
3. Verify that:
   - `reached_flag` updates to 1.
   - `reaching_time` is set to the current timestamp.
4. Click **Mark Departed**. Verify `leaving_time` is set.
5. Attempt to select Stop 2 (Ordinal 2) and click **Mark Arrived**. Confirm it updates successfully.

### Test Case 2: Out of Sequence Block
1. Open the active trip stop checklist.
2. Attempt to select Stop 3 (Ordinal 3) and click **Mark Arrived** while Stop 2 (Ordinal 2) is still marked as Not Reached.
3. Verify that the app blocks selection with the message: "You must arrive at the previous stop (Stop 2) first."

### Test Case 3: Emergency Delay Override
1. Select Stop 2 (Ordinal 2).
2. Toggle "Emergency Halt" to **Yes**.
3. Attempt to save without entering remarks. Verify warning: "Emergency Remarks are required."
4. Input remarks "Tire puncture, changing tire" and click save.
5. Verify in the monitoring console that the stop is flagged in orange showing "Emergency Halt".

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Stop List Container**: `@stop-list-container`
* **Arrived Button (Stop 1)**: `@arrived-btn-1`
* **Departed Button (Stop 1)**: `@departed-btn-1`
* **Arrived Button (Stop 2)**: `@arrived-btn-2`
* **Emergency Toggle (Stop 2)**: `input[name="emergency_flag_2"]`
* **Emergency Remarks Field**: `textarea[name="emergency_remarks"]`
* **Save Emergency Button**: `@save-emergency-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStoppageUpdateTest extends DuskTestCase
{
    public function testStopArrivalSequenceAndEmergencies()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/trip')
                    ->click('@stop-list-container')
                    
                    // Log Stop 1 Arrival
                    ->waitFor('@arrived-btn-1')
                    ->click('@arrived-btn-1')
                    ->pause(1000)
                    ->assertDontSee('@arrived-btn-1') // Changes to departed state
                    
                    // Try to log Stop 3 out of sequence
                    ->click('@arrived-btn-3')
                    ->assertSee('You must arrive at the previous stop first')
                    
                    // Log Emergency on Stop 2
                    ->click('@arrived-btn-2')
                    ->check('emergency_flag_2')
                    ->click('@save-emergency-btn')
                    ->assertSee('Emergency Remarks are required')
                    ->type('emergency_remarks', 'Road blockade')
                    ->click('@save-emergency-btn')
                    ->pause(1000);
        });
    }
}
```
