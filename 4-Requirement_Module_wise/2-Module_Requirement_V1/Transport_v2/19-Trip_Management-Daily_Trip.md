# Daily Trip — Requirement Document

## 1. Screen Purpose & Overview

The Daily Trip screen serves as the operational execution terminal for crew members to start, execute, and complete daily scheduled routes. It logs actual starting/ending odometer readings, start/end timestamps, and fuel gauge readings. 

This captured data establishes the baseline for total mileage, fuel efficiency calculations, and vendor usage records.

---

## 2. Common Business Use Cases

1. **Starting a Scheduled Run:** At 07:00 AM, the driver logs in, selects today's scheduled Morning run, records the starting odometer reading, and clicks "Start Trip".
2. **Completing a Run:** Upon arrival at school, the driver enters the final odometer reading and clicks "Complete Trip".
3. **Emergency Cancellation:** Logging an unexpected run cancellation due to extreme weather conditions.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_trip` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `trip_date` (DATE): Target date of trip execution.
* `route_scheduler_id` (INT UNSIGNED): FK to `tpt_route_scheduler_jnt`. Connects the trip to a daily schedule slot.
* `route_id` (INT UNSIGNED): FK to `tpt_route`. Travel route.
* `vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Vehicle utilized.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Driver executing the trip.
* `helper_id` (INT UNSIGNED): FK to `tpt_personnel`. Helper assisting (optional).
* `start_time` (DATETIME): Actual start timestamp of trip.
* `end_time` (DATETIME): Actual completion timestamp of trip.
* `start_odometer_reading` (DECIMAL(11,2)): Mileage reading at trip start.
* `end_odometer_reading` (DECIMAL(11,2)): Mileage reading at trip completion.
* `start_fuel_reading` (DECIMAL(8,3)): Fuel tank level/reading at start.
* `end_fuel_reading` (DECIMAL(8,3)): Fuel tank level/reading at completion.
* `status` (VARCHAR(20)): Trip status ('Scheduled', 'In-Transit', 'Completed', 'Cancelled'). Defaults to 'Scheduled'.
* `approved` (TINYINT): Manager verification status (0 = Pending, 1 = Approved).
* `approved_by` (INT UNSIGNED): FK to `sys_users` or manager.
* `approved_at` (TIMESTAMP): Date-time of manager's verification.
* `remarks` (VARCHAR(512)): Operational notes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Scheduler Link** | Dropdown | Required. Matches today's active scheduler items. | `tpt_trip.route_scheduler_id` |
| **Start Odometer** | Number Input | Required on Start. Must match vehicle's last end odometer. | `tpt_trip.start_odometer_reading` |
| **Start Fuel Reading** | Number Input | Required on Start. Decimal $> 0.00$. | `tpt_trip.start_fuel_reading` |
| **Start Time** | Read-only Text | Auto-captured on click. | `tpt_trip.start_time` |
| **End Odometer** | Number Input | Required on End. Must be $>$ Start Odometer. | `tpt_trip.end_odometer_reading` |
| **End Fuel Reading** | Number Input | Required on End. Decimal $\ge 0.00$. | `tpt_trip.end_fuel_reading` |
| **End Time** | Read-only Text | Auto-captured on click. | `tpt_trip.end_time` |
| **Remarks** | Text Area | Optional. Max 512 characters. | `tpt_trip.remarks` |

---

## 5. Business Logic & Validation Policies

### State Transitions
* Initial state is `Scheduled`. 
* Clicking **Start Trip** sets:
  $$\text{status} = \text{'In-Transit'} \quad \land \quad \text{start\_time} = \text{CURRENT\_TIMESTAMP()}$$
* Clicking **Complete Trip** sets:
  $$\text{status} = \text{'Completed'} \quad \land \quad \text{end\_time} = \text{CURRENT\_TIMESTAMP()}$$

### Odometer Validation
* The start odometer reading must match the previous end odometer reading recorded for the vehicle. Discrepancies within a 5-kilometer boundary are allowed but flag a warning; larger variances fail validation:
  $$\text{Variance} = |\text{start\_odometer\_reading} - \text{last\_end\_odometer}| \le 5$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Execute and Complete Trip (Happy Path)
1. Log in to the driver companion application.
2. Under "Today's Schedule", locate the morning intake run and click **Start Trip**.
3. Enter Start Odometer: `12000.00` (which matches the last trip's end odometer).
4. Enter Start Fuel Reading: `80.00` (Liters). Click Submit.
5. Verify the trip status updates to `In-Transit`.
6. Upon arriving at the school, click **Complete Trip**.
7. Enter End Odometer: `12025.00` and End Fuel Reading: `75.00`. Click Submit.
8. Verify the trip status updates to `Completed` and is saved.

### Test Case 2: Block Out-of-Sequence Odometers
1. Select another scheduled run on the same vehicle.
2. Enter Start Odometer: `11900.00` (which is less than the completed end reading of `12025.00`).
3. Click Submit.
4. Verify validation error: "Start odometer reading cannot be less than the last completed reading (12025.00)."

### Test Case 3: Block Multi-Transit Vehicle
1. Attempt to start a trip on Bus V-101 while another trip on the same vehicle is currently in an `In-Transit` state.
2. Click Submit.
3. Verify that starting fails with the message: "Vehicle is currently executing an active trip. Complete the current run first."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Daily Trip Tab**: `@daily-trip-tab`
* **Start Trip Button**: `@start-trip-btn-1` (dynamic row ID)
* **Start Odometer Field**: `input[name="start_odometer_reading"]`
* **Start Fuel Field**: `input[name="start_fuel_reading"]`
* **Confirm Start Button**: `@confirm-start-btn`
* **Complete Trip Button**: `@complete-trip-btn-1`
* **End Odometer Field**: `input[name="end_odometer_reading"]`
* **End Fuel Field**: `input[name="end_fuel_reading"]`
* **Confirm Complete Button**: `@confirm-complete-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportDailyTripTest extends DuskTestCase
{
    public function testDailyTripExecutionWorkflow()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/trip')
                    ->click('@daily-trip-tab')
                    ->waitFor('@start-trip-btn-1')
                    
                    // Start Trip
                    ->click('@start-trip-btn-1')
                    ->waitFor('@confirm-start-btn')
                    ->type('start_odometer_reading', '12025.00')
                    ->type('start_fuel_reading', '80.00')
                    ->click('@confirm-start-btn')
                    ->pause(1000)
                    ->assertSee('In-Transit')
                    
                    // Complete Trip
                    ->click('@complete-trip-btn-1')
                    ->waitFor('@confirm-complete-btn')
                    ->type('end_odometer_reading', '12010.00') // Invalid: less than start
                    ->type('end_fuel_reading', '75.00')
                    ->click('@confirm-complete-btn')
                    ->assertSee('End odometer must be greater than start odometer')
                    
                    // Correcting end odometer
                    ->type('end_odometer_reading', '12050.00')
                    ->click('@confirm-complete-btn')
                    ->pause(1000)
                    ->assertSee('Completed');
        });
    }
}
```
