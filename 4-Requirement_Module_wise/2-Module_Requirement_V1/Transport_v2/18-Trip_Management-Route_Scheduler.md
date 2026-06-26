# Route Scheduler — Requirement Document

## 1. Screen Purpose & Overview

The Route Scheduler screen translates long-term driver-vehicle rosters (`tpt_driver_route_vehicle_jnt`) into specific daily execution schedules (`tpt_route_scheduler_jnt`). It enables administrators to generate tomorrow's daily trip sheets in bulk, applying calendar exclusions (holidays) and flagging maintenance blocks automatically.

---

## 2. Common Business Use Cases

1. **Daily Trip Generation:** The coordinator selects a future date (e.g., tomorrow) and triggers the bulk schedule generator to copy roster mappings into daily schedules.
2. **Scheduling Exclusions:** Adjusting daily trip schedules when a route is closed due to localized weather alerts.
3. **Emergency Crew Reassignment:** Swapping a driver on a specific scheduled date because of a sick leave.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_route_scheduler_jnt` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `scheduled_date` (DATE): Target date of the scheduled operations run.
* `shift_id` (INT UNSIGNED): FK to `tpt_shift`. Links the schedule to an operational shift.
* `route_id` (INT UNSIGNED): FK to `tpt_route`. Targeted travel route.
* `vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Fleet vehicle assigned to the run.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Driver assigned to the run.
* `helper_id` (INT UNSIGNED): FK to `tpt_personnel`. Helper assigned to the run (optional).
* `pickup_drop` (ENUM): Specifies 'Pickup' or 'Drop' direction context.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last updated date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Scheduled Date** | Datepicker | Required. Must be $\ge$ `CURRENT_DATE()`. | `tpt_route_scheduler_jnt.scheduled_date` |
| **Shift Select** | Dropdown | Required. Matches list of active shifts (`tpt_shift`). | `tpt_route_scheduler_jnt.shift_id` |
| **Route Select** | Dropdown | Required. Matches list of active routes (`tpt_route`). | `tpt_route_scheduler_jnt.route_id` |
| **Vehicle Select** | Dropdown | Required. Matches active, available vehicles (`tpt_vehicle`).| `tpt_route_scheduler_jnt.vehicle_id` |
| **Driver Select** | Dropdown | Required. Matches checked-in, active drivers. | `tpt_route_scheduler_jnt.driver_id` |
| **Helper Select** | Dropdown | Optional. Matches active helpers. | `tpt_route_scheduler_jnt.helper_id` |
| **Route Direction** | Read-only Text | Auto-populates based on the selected route. | `tpt_route_scheduler_jnt.pickup_drop` |

---

## 5. Business Logic & Validation Policies

### Double-Booking Unique Constraints
The database enforces four distinct unique constraints to guarantee operational validity:
1. **Route Uniqueness**: A route can only be scheduled once per shift/date/direction:
   $$\text{uq\_route\_scheduler\_schedDate\_shift\_route}(\text{scheduled\_date}, \text{shift\_id}, \text{route\_id}, \text{pickup\_drop})$$
2. **Vehicle Uniqueness**: A vehicle can only run once per shift/date/direction:
   $$\text{uq\_route\_scheduler\_vehicle\_schedDate\_shift}(\text{vehicle\_id}, \text{scheduled\_date}, \text{shift\_id}, \text{pickup\_drop})$$
3. **Driver Uniqueness**: A driver can only drive once per shift/date/direction:
   $$\text{uq\_route\_scheduler\_driver\_schedDate\_shift}(\text{driver\_id}, \text{scheduled\_date}, \text{shift\_id}, \text{pickup\_drop})$$
4. **Helper Uniqueness**: A helper can only assist once per shift/date/direction:
   $$\text{uq\_route\_scheduler\_helper\_schedDate\_shift}(\text{helper\_id}, \text{scheduled\_date}, \text{shift\_id}, \text{pickup\_drop})$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Generate Daily Schedule (Happy Path)
1. Go to `/transport/route-scheduler` and click "+ New Schedule Entry".
2. Select Date: Tomorrow. Select Shift: Morning Shift.
3. Select Route: Route 10, Vehicle: Bus V-101, Driver: John Driver.
4. Click Save. Confirm the schedule row displays in the upcoming runs calendar.

### Test Case 2: Double-Booking Vehicle Block
1. Click "+ New Schedule Entry".
2. Enter the same Date and Shift as Test Case 1.
3. Select a different Route (Route 11), but select the SAME Vehicle (Bus V-101) and click Save.
4. Verify that save fails with message: "Vehicle is already assigned to another route on this date/shift."

### Test Case 3: Double-Booking Driver Block
1. Click "+ New Schedule Entry".
2. Enter the same Date and Shift as Test Case 1.
3. Select a different Route (Route 11) and different Vehicle (Bus V-102), but select the SAME Driver (John Driver) and click Save.
4. Verify that save fails with message: "Driver is already assigned to another route on this date/shift."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Scheduler Tab**: `@scheduler-tab`
* **Generate Button**: `@generate-schedule-btn`
* **Date Field**: `input[name="scheduled_date"]`
* **Shift Select**: `select[name="shift_id"]`
* **Route Select**: `select[name="route_id"]`
* **Vehicle Select**: `select[name="vehicle_id"]`
* **Driver Select**: `select[name="driver_id"]`
* **Save Button**: `@save-schedule-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportRouteSchedulerTest extends DuskTestCase
{
    public function testSchedulerConflictLocks()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/route-scheduler')
                    ->click('@scheduler-tab')
                    ->click('@generate-schedule-btn')
                    ->keys('input[name="scheduled_date"]', '05242026') // Tomorrow
                    ->select('shift_id', '1')
                    ->select('route_id', '1')
                    ->select('vehicle_id', '1')
                    ->select('driver_id', '1')
                    ->click('@save-schedule-btn')
                    ->assertSee('saved successfully')
                    
                    // Trigger vehicle conflict check
                    ->click('@generate-schedule-btn')
                    ->keys('input[name="scheduled_date"]', '05242026')
                    ->select('shift_id', '1')
                    ->select('route_id', '2') // Different route
                    ->select('vehicle_id', '1') // Same vehicle
                    ->select('driver_id', '2') // Different driver
                    ->click('@save-schedule-btn')
                    ->assertSee('Vehicle is already assigned');
        });
    }
}
```
