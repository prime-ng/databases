# Vehicle Master — Requirement Document

## 1. Screen Purpose & Overview

The Vehicle screen is the master register for all fleet assets utilized by the school. It enables the onboarding, tracking, and compliance management of both school-owned and third-party vendor-leased/rented vehicles. 

A primary objective of this screen is to maintain active legal compliance certificates (fitness, insurance, pollution, and fire extinguisher) and to toggle a vehicle's availability status. This ensures that only certified, road-worthy vehicles are scheduled for daily trips.

---

## 2. Common Business Use Cases

1. **Onboarding a New Leased Bus:** The administrator registers a new vehicle supplied by a third-party vendor, logging its seating capacity and linking it to the vendor's agreement.
2. **Compliance Expiry Alerts:** The system flags vehicles whose pollution (PUC) or fitness certificates are within 15 days of expiration, alerting the manager to renew them.
3. **Maintenance Availability Toggle:** When a vehicle suffers a breakdown, its status is changed to "Unavailable", which automatically prevents it from being rostered.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_vehicle` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `vehicle_no` (VARCHAR(20)): Unique Manufacturer VIN/Chassis code.
* `registration_no` (VARCHAR(30)): Unique government license registration number.
* `model` (VARCHAR(50)): Vehicle model.
* `manufacturer` (VARCHAR(50)): Vehicle manufacturer.
* `vehicle_type_id` (INT UNSIGNED): FK to `sys_dropdown_table` (values like 'BUS', 'VAN', 'CAR').
* `fuel_type_id` (INT UNSIGNED): FK to `sys_dropdown_table` (values like 'Diesel', 'Petrol', 'CNG', 'Electric').
* `capacity` (INT UNSIGNED): Seating capacity, defaults to 40.
* `max_capacity` (INT UNSIGNED): Maximum capacity including standing, defaults to 40.
* `ownership_type_id` (INT UNSIGNED): FK to `sys_dropdown_table` (values like 'Owned', 'Leased', 'Rented').
* `vendor_id` (INT UNSIGNED): FK to `vnd_vendors` table.
* `fitness_valid_upto` (DATE): Fitness certificate expiration date.
* `insurance_valid_upto` (DATE): Insurance validity date.
* `pollution_valid_upto` (DATE): Pollution certificate validity date.
* `vehicle_emission_class_id` (INT UNSIGNED): FK to `sys_dropdown_table` (values like 'BS IV', 'BS V', 'BS VI').
* `fire_extinguisher_valid_upto` (DATE): Fire safety expiry date.
* `gps_device_id` (VARCHAR(50)): Hardware GPS terminal identifier code.
* `availability_status` (TINYINT): 0 = Not Available, 1 = Available.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active (Soft delete indicator).
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Vehicle Number (VIN)** | Text Input | Required. Max 20 chars. Must be unique. | `tpt_vehicle.vehicle_no` |
| **Registration Number** | Text Input | Required. Max 30 chars. Must be unique. | `tpt_vehicle.registration_no` |
| **Vehicle Model** | Text Input | Optional. Max 50 chars. | `tpt_vehicle.model` |
| **Manufacturer** | Text Input | Optional. Max 50 chars. | `tpt_vehicle.manufacturer` |
| **Vehicle Type** | Dropdown | Required. Matches options in dropdown system. | `tpt_vehicle.vehicle_type_id` |
| **Fuel Type** | Dropdown | Required. Matches options in dropdown system. | `tpt_vehicle.fuel_type_id` |
| **Seating Capacity** | Number Input | Required. Integer. Must be $> 0$. | `tpt_vehicle.capacity` |
| **Max Capacity** | Number Input | Required. Integer. Must be $\ge$ Seating Capacity. | `tpt_vehicle.max_capacity` |
| **Ownership Type** | Dropdown | Required. Matches options in dropdown system. | `tpt_vehicle.ownership_type_id` |
| **Vendor Link** | Dropdown | Required if Ownership Type is 'Leased' or 'Rented'. | `tpt_vehicle.vendor_id` |
| **Fitness Valid Upto** | Datepicker | Required. Must be a future date. | `tpt_vehicle.fitness_valid_upto` |
| **Insurance Valid Upto** | Datepicker | Required. Must be a future date. | `tpt_vehicle.insurance_valid_upto` |
| **Pollution Valid Upto** | Datepicker | Required. Must be a future date. | `tpt_vehicle.pollution_valid_upto` |
| **Fire Extinguisher Upto**| Datepicker | Required. Must be a future date. | `tpt_vehicle.fire_extinguisher_valid_upto` |
| **GPS Device ID** | Text Input | Optional. Max 50 chars. | `tpt_vehicle.gps_device_id` |
| **Availability Status** | Toggle / Checkbox| Required. Default is 1 (Available). | `tpt_vehicle.availability_status` |

---

## 5. Business Logic & Validation Policies

### Unique Constraints
* Duplicate entries in `registration_no` and `vehicle_no` are blocked by a composite unique key constraint `uq_vehicle_regNo_vehicleNo`.

### Vendor Agreement Integration
* If the vehicle's `ownership_type_id` is set to 'Leased' or 'Rented', a valid `vendor_id` must be selected. 

### Calculations & Mathematical Formulas
* **Compliance Alert Index**: The system monitors certificate validities. If the current date is within 15 days of any expiration:
  $$\text{Days Remaining} = \text{Expiry Date} - \text{CURRENT\_DATE()}$$
  * If $\text{Days Remaining} \le 0$, the vehicle's compliance status is marked as 'Expired'.
  * If $0 < \text{Days Remaining} \le 15$, the compliance status is flagged as 'Expiring Soon'.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create New Vehicle (Happy Path)
1. Go to `/transport/vehicle` and click "+ Add Vehicle".
2. Enter VIN: `VIN9876543210ABCDEF`, Reg No: `DL-2C-1234`.
3. Select Type: `Bus`, Fuel: `CNG`, Ownership: `Owned`.
4. Enter Seating Capacity: `40`, Max Capacity: `50`.
5. Enter future dates for Fitness, Insurance, Pollution, and Fire Extinguisher.
6. Click Save. Confirm that the vehicle is successfully saved and shows in the list.

### Test Case 2: Validate Capacities Rule
1. Go to "+ Add Vehicle".
2. Set Seating Capacity to `50` and Max Capacity to `45`.
3. Fill other fields with valid data and click Save.
4. Verify that validation errors are displayed: "Max Capacity must be greater than or equal to Seating Capacity".

### Test Case 3: Unique Constraints Check
1. Go to "+ Add Vehicle".
2. Enter the same Registration Number as created in Test Case 1 (`DL-2C-1234`).
3. Fill all other fields and click Save.
4. Verify that saving fails with the message "Registration Number already exists".

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Vehicle Master Tab**: `@vehicle-master-tab`
* **Add Vehicle Button**: `@add-new-vehicle-btn`
* **Vehicle Number Field**: `input[name="vehicle_no"]`
* **Registration Number Field**: `input[name="registration_no"]`
* **Capacity Field**: `input[name="capacity"]`
* **Max Capacity Field**: `input[name="max_capacity"]`
* **Save Button**: `@save-vehicle-btn`
* **Alert Message**: `@vehicle-alert`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportVehicleTest extends DuskTestCase
{
    public function testVehicleCreationAndValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/vehicle')
                    ->click('@vehicle-master-tab')
                    ->click('@add-new-vehicle-btn')
                    ->type('vehicle_no', 'VIN9876543210ABCDEF')
                    ->type('registration_no', 'DL-2C-1234')
                    ->select('vehicle_type_id', '1') // Bus
                    ->select('fuel_type_id', '3') // CNG
                    ->type('capacity', '40')
                    ->type('max_capacity', '30') // Invalid capacity constraint
                    ->click('@save-vehicle-btn')
                    ->assertSee('Max Capacity must be greater than or equal to Seating Capacity')
                    
                    // Correcting Max Capacity
                    ->type('max_capacity', '50')
                    ->click('@save-vehicle-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
