# Service Log — Requirement Document

## 1. Screen Purpose & Overview

The Service Log screen tracks vehicle service requests generated from inspection failures or manually logged by operators. Service requests document faults, mechanical anomalies, or general wear-and-tear. 

They require review and approval by an authorized manager. Approved requests trigger maintenance entries to schedule workshop repairs and keep unsafe vehicles off the road.

---

## 2. Common Business Use Cases

1. **Reviewing Auto-Generated Requests:** A manager reviews a service ticket automatically created after a driver failed a tires or brakes check during their morning inspection.
2. **Logging Mechanical Faults:** A driver notices engine overheating and files a service log linked to their daily post-run inspection.
3. **Tracking Repair Progress:** Monitoring the status of vehicles transitioning from "Due for Service" to "In-Service" and finally "Service Done".

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_vehicle_service_request` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `vehicle_inspection_id` (INT UNSIGNED): FK to `tpt_daily_vehicle_inspection`. Connects the request to a safety audit (strictly NOT NULL in database).
* `request_date` (TIMESTAMP): Date and time of the service request.
* `reason` (VARCHAR(512)): Description of reported vehicle faults.
* `Vehicle_status` (INT UNSIGNED): FK to `sys_dropdown_table` (representing 'Due for Service', 'In-Service', 'Service Done').
* `service_completion_date` (TIMESTAMP): Completion date-time of service/repair.
* `request_approval_status` (ENUM): Verification status: 'Approved', 'Pending', 'Rejected'. Defaults to 'Pending'.
* `approved_by` (INT UNSIGNED): FK to `sys_users`. Authorizing manager.
* `approved_at` (TIMESTAMP): Date and time of the manager's approval.
* `created_at` (TIMESTAMP): System creation timestamp.
* `updated_at` (TIMESTAMP): System last update timestamp.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Inspection Link** | Dropdown | Required. Matches daily safety inspection records (`tpt_daily_vehicle_inspection`). | `tpt_vehicle_service_request.vehicle_inspection_id` |
| **Request Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `tpt_vehicle_service_request.request_date` |
| **Fault Reason** | Text Input | Required. Max 512 characters. | `tpt_vehicle_service_request.reason` |
| **Vehicle Status** | Dropdown | Required. Options: `Due for Service`, `In-Service`, `Service Done`. | `tpt_vehicle_service_request.Vehicle_status` |
| **Approval Status** | Dropdown | Read-only for operators. Configured in Approval Tab. | `tpt_vehicle_service_request.request_approval_status` |

---

## 5. Business Logic & Validation Policies

### Inspection Link Mandate
* Because the database schema sets `vehicle_inspection_id` to `NOT NULL` with a foreign key constraint, the application blocks saving any service request that does not link to a valid inspection entry:
  $$\text{vehicle\_inspection\_id} \neq \text{NULL}$$
* Operators logging a manual service fault must select from the list of inspection records for that vehicle.

### Automated Maintenance Trigger
* Once `request_approval_status` is updated to `Approved` by an authorized coordinator, the system automatically inserts a row into the maintenance table:
  $$\text{INSERT INTO tpt\_vehicle\_maintenance (vehicle\_service\_request\_id, status, ...)}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create Service Request (Happy Path)
1. Go to `/transport/vehicle-service-request` and click "+ New Service Request".
2. Select an existing safety inspection record from the **Inspection Link** dropdown.
3. Enter Request Date: Today's date.
4. Enter Fault Reason: "Air conditioner compressor failure".
5. Set Vehicle Status: `Due for Service`.
6. Click Save. Confirm the request displays as `Pending` in the listing.

### Test Case 2: Validate Missing Inspection Link
1. Click "+ New Service Request".
2. Leave the **Inspection Link** dropdown empty.
3. Fill all other fields and click Save.
4. Verify validation error: "The Inspection Link field is required."

### Test Case 3: Transition to Maintenance upon Approval
1. Log in as an Administrator, go to "Veh. Approval", locate the compressor fault log from Test Case 1, and click **Approve**.
2. Go to the maintenance dashboard.
3. Verify that a new entry for the vehicle has been created in `tpt_vehicle_maintenance` with a reference linking back to this service request.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Service Request Tab**: `@service-log-tab`
* **New Request Button**: `@new-request-btn`
* **Inspection Dropdown**: `select[name="vehicle_inspection_id"]`
* **Request Date Field**: `input[name="request_date"]`
* **Reason Field**: `input[name="reason"]`
* **Vehicle Status Select**: `select[name="Vehicle_status"]`
* **Save Button**: `@save-request-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportServiceLogTest extends DuskTestCase
{
    public function testServiceLogCreationAndInspectionLinkage()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/vehicle-service-request')
                    ->click('@service-log-tab')
                    ->click('@new-request-btn')
                    // Attempt save without inspection link
                    ->type('reason', 'Engine knocking')
                    ->select('Vehicle_status', '1') // Due for Service
                    ->click('@save-request-btn')
                    ->assertSee('Inspection Link field is required')
                    
                    // Link inspection and save
                    ->select('vehicle_inspection_id', '1')
                    ->click('@save-request-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
