# Fuel Log — Requirement Document

## 1. Screen Purpose & Overview

The Fuel Log screen maintains a detailed record of fuel refills, odometer readings, and costs for each vehicle in the fleet. This data enables real-time fuel efficiency (KM/L) tracking and helps administrators identify fuel cost leakages, theft, or vehicle mechanical inefficiencies. 

All submissions are entered in a 'Pending' state and require authorized approval to be active for reporting.

---

## 2. Common Business Use Cases

1. **Logging Fuel Refill:** A driver refills a bus with 50 Liters of Diesel, costing ₹4,500, at an odometer reading of 12,050, and records it via the app.
2. **Auditing Consumption:** The transport manager checks fuel logs to find vehicles showing poor fuel economy (low KM/L).
3. **Billing Reconciliation:** Comparing fuel expenditures against monthly transport allocations to monitor financial leakages.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_vehicle_fuel` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `vehicle_id` (INT UNSIGNED): FK to `tpt_vehicle`. Mapped vehicle.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Driver who refueled the vehicle.
* `date` (DATE): Refuel date.
* `quantity` (DECIMAL(10,3)): Liters of fuel added.
* `cost` (DECIMAL(12,2)): Total cost of the refuel transaction.
* `fuel_type` (INT UNSIGNED): FK to `sys_dropdown_table` (Diesel, Petrol, CNG, Electric).
* `odometer_reading` (INT UNSIGNED): Odometer reading at refuel time.
* `remarks` (VARCHAR(512)): Explanatory remark notes.
* `status` (ENUM): Refuel verification status: 'Approved', 'Pending', 'Rejected'. Defaults to 'Pending'.
* `created_at` (TIMESTAMP): Creation timestamp.
* `updated_at` (TIMESTAMP): Last update timestamp.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Vehicle Select** | Dropdown | Required. Matches list of active vehicles (`tpt_vehicle`). | `tpt_vehicle_fuel.vehicle_id` |
| **Driver Name** | Dropdown | Optional. Matches active crew list (`tpt_personnel`). | `tpt_vehicle_fuel.driver_id` |
| **Refuel Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `tpt_vehicle_fuel.date` |
| **Fuel Quantity (L)** | Number Input | Required. Decimal $> 0.00$. | `tpt_vehicle_fuel.quantity` |
| **Total Cost** | Number Input | Required. Decimal $> 0.00$. | `tpt_vehicle_fuel.cost` |
| **Fuel Type** | Dropdown | Required. Matches options in dropdown system. | `tpt_vehicle_fuel.fuel_type` |
| **Odometer Reading** | Number Input | Required. Integer. Must be $>$ previous approved log. | `tpt_vehicle_fuel.odometer_reading` |
| **Remarks** | Text Area | Optional. Max 512 characters. | `tpt_vehicle_fuel.remarks` |

---

## 5. Business Logic & Validation Policies

### Odometer Continuity
* The input `odometer_reading` must be strictly greater than the previous approved odometer reading recorded for the vehicle:
  $$\text{odometer\_reading}_{\text{new}} > \text{odometer\_reading}_{\text{previous}}$$

### Approval Flow
* Saved records are created with `status = 'Pending'`. 
* Calculated statistics (KMPL and cost per KM) are only updated in analytics panels once the status is updated to `Approved`.

### Calculations & Mathematical Formulas
* **Fuel Efficiency (KMPL)**:
  $$\text{Fuel Efficiency} = \frac{\text{Odometer}_{\text{current}} - \text{Odometer}_{\text{previous}}}{\text{Fuel Quantity (Liters)}}$$
* **Cost Per Kilometer (CPK)**:
  $$\text{Cost Per KM} = \frac{\text{Total Cost}}{\text{Odometer}_{\text{current}} - \text{Odometer}_{\text{previous}}}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create Fuel Log (Happy Path)
1. Go to `/transport/vehicle-fuel` and click "+ Add Fuel Log".
2. Select Vehicle: `DL-2C-1234`, Driver: `John Driver`.
3. Select Fuel Type: `Diesel`.
4. Enter Fuel Quantity: `50`, Cost: `4500.00`.
5. Enter Odometer Reading: `12500` (previous approved odometer was `12000`).
6. Click Save. Confirm log is saved in `Pending` state.

### Test Case 2: Validate Odometer Continuity
1. Click "+ Add Fuel Log".
2. Select the same vehicle.
3. Enter Odometer Reading: `12400` (which is less than the `12500` entered in Test Case 1).
4. Fill all other fields and click Save.
5. Verify validation error: "Odometer reading must be greater than the last recorded reading (12500)."

### Test Case 3: Mileage Calculation Check
1. Log in as an Administrator, go to "Veh. Approval", locate the log from Test Case 1, and click **Approve**.
2. Go to Route Performance reports, filter by Vehicle `DL-2C-1234`.
3. Verify that the Fuel Efficiency shows:
   $$\text{Fuel Efficiency} = \frac{12500 - 12000}{50} = 10.00 \text{ KM/L}$$
4. Verify that the Cost Per KM shows:
   $$\text{Cost Per KM} = \frac{4500}{500} = 9.00\text{ Rs/KM}$$

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Fuel Log Tab**: `@fuel-log-tab`
* **Add Fuel Log Button**: `@add-fuel-btn`
* **Vehicle Dropdown**: `select[name="vehicle_id"]`
* **Driver Dropdown**: `select[name="driver_id"]`
* **Date Field**: `input[name="date"]`
* **Quantity Field**: `input[name="quantity"]`
* **Cost Field**: `input[name="cost"]`
* **Fuel Type Dropdown**: `select[name="fuel_type"]`
* **Odometer Field**: `input[name="odometer_reading"]`
* **Save Button**: `@save-fuel-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportFuelLogTest extends DuskTestCase
{
    public function testFuelLogCreationAndOdometerValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/vehicle-fuel')
                    ->click('@fuel-log-tab')
                    ->click('@add-fuel-btn')
                    ->select('vehicle_id', '1')
                    ->select('driver_id', '1')
                    ->type('quantity', '50')
                    ->type('cost', '4500.00')
                    ->select('fuel_type', '2') // Diesel
                    ->type('odometer_reading', '1000') // Too low
                    ->click('@save-fuel-btn')
                    ->assertSee('Odometer reading must be greater than')
                    
                    // Correcting Odometer
                    ->type('odometer_reading', '15000')
                    ->click('@save-fuel-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
