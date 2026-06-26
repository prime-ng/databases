# Vehicle Maintenance — Requirement Document

## 1. Screen Purpose & Overview

The Vehicle Maintenance screen tracks active workshop logs, garage entry/exit schedules, repair details, and actual expenses incurred during repairs. 

Since maintenance records represent direct financial liabilities and fleet safety adjustments, **new records cannot be manually created** on this screen. Instead, they are generated automatically when a service request is approved. Users use this screen to update repair progress, specify completion dates, and log final costs before submitting the record for manager audit.

---

## 2. Common Business Use Cases

1. **Recording Garage Check-in:** The dispatcher updates an auto-generated pending maintenance log with the garage name and actual entry date.
2. **Logging Repair Costs:** After repair completion, the operator updates the log with details (e.g. "Alternator replaced"), enters the final invoice cost of ₹4,500, sets the out-service date, and uploads the workshop bill.
3. **Recording Preventive Reminders:** Logging a next service date target based on the mechanic's recommendation.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_vehicle_maintenance` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `vehicle_service_request_id` (INT UNSIGNED): FK to `tpt_vehicle_service_request`. Parent request link.
* `maintenance_initiation_date` (DATE): Date the vehicle reached the garage.
* `maintenance_type` (VARCHAR(120)): Description of the repair type (e.g., 'Engine Overhaul').
* `cost` (DECIMAL(12,2)): Total repair cost.
* `in_service_date` (DATE): Actual start date of active repair work.
* `out_service_date` (DATE): Completion date when the vehicle left the garage.
* `workshop_details` (VARCHAR(512)): Name and contact information of the workshop.
* `next_due_date` (DATE): Recommended next service date.
* `remarks` (VARCHAR(512)): Detailed notes on repair items.
* `status` (ENUM): Audit status: 'Approved', 'Pending', 'Rejected'. Defaults to 'Pending'.
* `approved_by` (INT UNSIGNED): FK to `sys_users`. Manager who approved the maintenance.
* `approved_at` (TIMESTAMP): Time of final manager approval.
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last update date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Service Request Link** | Read-only Text | Displays the linked service request code. | `tpt_vehicle_maintenance.vehicle_service_request_id` |
| **Initiation Date** | Datepicker | Required. Defaults to service request date. | `tpt_vehicle_maintenance.maintenance_initiation_date` |
| **Maintenance Type** | Text Input | Required. Max 120 characters. | `tpt_vehicle_maintenance.maintenance_type` |
| **Maintenance Cost** | Number Input | Required. Decimal $\ge 0.00$. | `tpt_vehicle_maintenance.cost` |
| **In-Service Date** | Datepicker | Optional. Must be $\ge$ Initiation Date. | `tpt_vehicle_maintenance.in_service_date` |
| **Out-Service Date** | Datepicker | Required for completion. Must be $\ge$ In-Service Date. | `tpt_vehicle_maintenance.out_service_date` |
| **Workshop Details** | Text Area | Required. Max 512 characters. | `tpt_vehicle_maintenance.workshop_details` |
| **Next Service Due** | Datepicker | Optional. Must be a future date. | `tpt_vehicle_maintenance.next_due_date` |
| **Remarks** | Text Area | Optional. Max 512 characters. | `tpt_vehicle_maintenance.remarks` |

---

## 5. Business Logic & Validation Policies

### Edit-Only Creation Restricton
* Users cannot manually click an "Add New" button to create a maintenance record. New entries are only created via database triggers when a service request is approved:
  $$\text{tpt\_vehicle\_service\_request.request\_approval\_status} = \text{'Approved'}$$

### Date Boundaries
* The system enforces sequence continuity for dates:
  $$\text{maintenance\_initiation\_date} \le \text{in\_service\_date} \le \text{out\_service\_date}$$

### Status Locking
* Once `status = 'Approved'`, the record becomes read-only, and any further edits are locked.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Update Active Maintenance Record (Happy Path)
1. Go to `/transport/vehicle-maintenance`.
2. Locate a pending maintenance row in the grid and click "Edit".
3. Enter Maintenance Type: `Brake Pad Replacement`.
4. Enter Cost: `2500.00`.
5. Enter In-Service Date: Today. Enter Out-Service Date: Today.
6. Enter Workshop Details: `Metro Garage`.
7. Click Save. Confirm that the record updates and remains in `Pending` status.

### Test Case 2: Validate Date Order
1. Locate a pending maintenance row and click "Edit".
2. Set Initiation Date to Today, but set Out-Service Date to Yesterday (invalid).
3. Click Save.
4. Verify validation error: "Out-Service Date must be greater than or equal to Initiation Date."

### Test Case 3: Read-Only Check on Approved Logs
1. Locate a maintenance record where status is `Approved`.
2. Verify that the "Edit" button for this row is disabled or hidden.
3. Attempt to access `/transport/vehicle-maintenance/edit/{id}` directly for this record.
4. Verify that the application blocks access with an error: "Approved records cannot be modified."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Maintenance Tab**: `@maintenance-tab`
* **Edit Action Button**: `@edit-maintenance-btn-1` (dynamic row ID)
* **Maintenance Type Field**: `input[name="maintenance_type"]`
* **Cost Field**: `input[name="cost"]`
* **In-Service Date Field**: `input[name="in_service_date"]`
* **Out-Service Date Field**: `input[name="out_service_date"]`
* **Workshop Details Field**: `textarea[name="workshop_details"]`
* **Save Button**: `@save-maintenance-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportMaintenanceTest extends DuskTestCase
{
    public function testMaintenanceEditingAndValidations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/vehicle-maintenance')
                    ->click('@maintenance-tab')
                    ->waitFor('@edit-maintenance-btn-1')
                    ->click('@edit-maintenance-btn-1')
                    
                    // Input incorrect date order
                    ->type('maintenance_type', 'Alternator Swap')
                    ->type('cost', '4500.00')
                    ->keys('input[name="out_service_date"]', '05222026') // 2026-05-22
                    ->keys('input[name="in_service_date"]', '05232026') // 2026-05-23 (Invalid order)
                    ->click('@save-maintenance-btn')
                    ->assertSee('Out-Service Date must be greater than or equal to')
                    
                    // Correcting dates and saving
                    ->keys('input[name="out_service_date"]', '05242026')
                    ->type('workshop_details', 'National Auto Workshop')
                    ->click('@save-maintenance-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
