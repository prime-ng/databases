# Daily Vehicle Inspection — Requirement Document

## 1. Screen Purpose & Overview

The Daily Vehicle Inspection screen tracks pre-trip safety audits completed by drivers or inspection technicians before dispatch. It records checklist evaluations covering mechanical integrity, electrics, and safety gear. 

The primary business goal is to prevent uncertified, unsafe vehicles from carrying students. Any safety item failure automatically marks the vehicle as unavailable and logs a service request.

---

## 2. Common Business Use Cases

1. **Pre-Run Checklist Verification:** A driver inspects Bus V-101 at 6:45 AM, verifying headlights, tires, and brakes are functional before departure.
2. **Flagging a Service Hazard:** A technician detects worn brake pads, marks the Brakes checklist item as Failed, triggering a service request.
3. **Daily Run Dispatch Block:** Schedulers review daily dispatch lists; the system automatically locks the dispatch button for any vehicle lacking a 'Passed' inspection log for the current calendar date.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_daily_vehicle_inspection` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Vehicle under inspection.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Driver performing inspection.
* `inspection_date` (TIMESTAMP): Date and time of the safety inspection.
* `odometer_reading` (INT UNSIGNED): Odometer reading at inspection.
* `fuel_level_reading` (DECIMAL(6,2)): Current fuel level (in Liters or percentage).
* `tire_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `lights_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `brakes_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `engine_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `battery_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `fire_extinguisher_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `first_aid_kit_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `seat_belts_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `headlights_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `tailights_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `wipers_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `mirrors_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `steering_wheel_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `emergency_tools_condition_ok` (TINYINT): 0 = Fail, 1 = OK.
* `cleanliness_ok` (TINYINT): 0 = Fail, 1 = OK.
* `any_issues_found` (TINYINT): 0 = No, 1 = Yes.
* `issues_description` (VARCHAR(512)): Description of reported hazards.
* `remarks` (VARCHAR(512)): Explanatory remark notes.
* `inspection_status` (ENUM): 'Passed', 'Failed', 'Pending'.
* `inspected_by` (INT UNSIGNED): FK to `sys_users`. Inspector user identifier.
* `inspected_at` (TIMESTAMP): Verification timestamp.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Vehicle** | Dropdown | Required. Matches list of active vehicles (`tpt_vehicle`). | `tpt_daily_vehicle_inspection.vehicle_id` |
| **Driver** | Dropdown | Optional. Matches active crew (`tpt_personnel`). | `tpt_daily_vehicle_inspection.driver_id` |
| **Odometer** | Number Input | Required. Must be $\ge$ previous refuel log. | `tpt_daily_vehicle_inspection.odometer_reading` |
| **Tires Status** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.tire_condition_ok` |
| **Lights Status** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.lights_condition_ok` |
| **Brakes Status** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.brakes_condition_ok` |
| **Fire Extinguisher** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.fire_extinguisher_condition_ok` |
| **First Aid Kit** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.first_aid_kit_condition_ok` |
| **Seat Belts** | Toggle / Checkbox| Required. Default is 1 (OK). | `tpt_daily_vehicle_inspection.seat_belts_condition_ok` |
| **Issue Found** | Toggle / Checkbox| Required. Defaults to 0 (No). | `tpt_daily_vehicle_inspection.any_issues_found` |
| **Issue Description** | Text Area | Required if `any_issues_found = 1` or any checklist item is 0. | `tpt_daily_vehicle_inspection.issues_description` |

---

## 5. Business Logic & Validation Policies

### Critical Defect Handling
* If any of the following items are marked as Failed (0):
  $$\{\text{tire\_condition\_ok}, \text{lights\_condition\_ok}, \text{brakes\_condition\_ok}, \text{fire\_extinguisher\_condition\_ok}, \text{seat\_belts\_condition\_ok}\} \cap \{0\} \neq \emptyset$$
  * The system sets `inspection_status = 'Failed'`.
  * The mapped fleet vehicle availability status is deactivated immediately:
    $$\text{tpt\_vehicle.availability\_status} = 0$$
  * A new service record is logged in `tpt_vehicle_service_request` with status 'Pending'.

### Dispatch Lock
* Daily trips cannot be marked 'In-Transit' if the mapped vehicle has:
  $$\text{COUNT(tpt\_daily\_vehicle\_inspection.id) WHERE inspection\_date = TODAY AND status = 'Passed'} = 0$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Pass Safety Inspection (Happy Path)
1. Go to `/transport/daily-vehicle-inspection` and click "+ New Inspection".
2. Select Vehicle: `DL-2C-1234`. Enter Odometer: `12550`.
3. Set all safety toggles (Tires, Lights, Brakes, Fire Extinguisher, First Aid Kit, Seat Belts) to "OK".
4. Ensure "Issue Found" is set to "No". Click Save.
5. Confirm inspection records show status `Passed` in the listing, and vehicle availability remains `1`.

### Test Case 2: Fail Safety Inspection & Block Vehicle
1. Click "+ New Inspection".
2. Select Vehicle: `DL-2C-1234`.
3. Set Brakes toggle to "Fail".
4. Set "Issue Found" to "Yes", enter Issue Description: "Soft brake pedal".
5. Click Save.
6. Verify:
   - Inspection status shows `Failed` in the listing.
   - Go to vehicle list; verify vehicle `DL-2C-1234` availability status is changed to `Unavailable` (0).
   - Go to service logs; verify a pending service request has been created.

### Test Case 3: Validation on Issue Description
1. Click "+ New Inspection".
2. Set "Issue Found" to "Yes", but leave the "Issue Description" field blank.
3. Click Save.
4. Verify validation error: "Issue Description is required if issues are found."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Inspection Tab**: `@inspection-tab`
* **New Inspection Button**: `@new-inspection-btn`
* **Vehicle Dropdown**: `select[name="vehicle_id"]`
* **Odometer Field**: `input[name="odometer_reading"]`
* **Brakes Toggle Checkbox**: `input[name="brakes_condition_ok"]`
* **Issue Found Toggle**: `input[name="any_issues_found"]`
* **Description Field**: `textarea[name="issues_description"]`
* **Save Button**: `@save-inspection-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportInspectionTest extends DuskTestCase
{
    public function testInspectionFailureSafetyBlocks()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/daily-vehicle-inspection')
                    ->click('@inspection-tab')
                    ->click('@new-inspection-btn')
                    ->select('vehicle_id', '1')
                    ->type('odometer_reading', '12550')
                    ->uncheck('brakes_condition_ok') // Fail brakes
                    ->check('any_issues_found')
                    ->click('@save-inspection-btn')
                    // Verify description warning
                    ->assertSee('Issue Description is required')
                    
                    // Input description and save
                    ->type('issues_description', 'Brakes soft')
                    ->click('@save-inspection-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
