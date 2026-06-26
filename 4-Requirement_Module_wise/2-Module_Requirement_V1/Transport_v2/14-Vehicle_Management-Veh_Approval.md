# Veh. Approval (Vehicles & Maintenance Approvals) — Requirement Document

## 1. Screen Purpose & Overview

The Veh. Approval screen is an administrative interface for transport managers and coordinators. It acts as a centralized dashboard containing three separate tables to approve:
* Fuel Logs (`tpt_vehicle_fuel`)
* Service Requests (`tpt_vehicle_service_request`)
* Maintenance Completion Records (`tpt_vehicle_maintenance`)

This screen represents the operational gate that transitions maintenance tasks into final financial liability claims in the Vendor Billing ledger.

---

## 2. Common Business Use Cases

1. **Authorizing Repair Work:** The manager reviews a pending service request filed for Bus V-101. Clicking "Approve" moves the request to "Approved" and automatically schedules a maintenance entry.
2. **Reconciling Maintenance Bills:** The manager approves a completed maintenance record for a leased van, creating a pending liability in the vendor payment ledger.
3. **Approving Fuel Refills:** The manager verifies a driver's fuel slip upload against the odometer log and approves the cost transaction.

---

## 3. Database Schema & Data Dictionary

The approval actions directly update statuses in three tables:

### `tpt_vehicle_fuel`
* `status` (ENUM): Transitioned from 'Pending' to 'Approved' or 'Rejected'.

### `tpt_vehicle_service_request`
* `request_approval_status` (ENUM): Transitioned from 'Pending' to 'Approved' or 'Rejected'.
* `approved_by` (INT UNSIGNED): FK to `sys_users`. Mapped to the logged-in manager's ID.
* `approved_at` (TIMESTAMP): Set to `CURRENT_TIMESTAMP()` upon approval.

### `tpt_vehicle_maintenance`
* `status` (ENUM): Transitioned from 'Pending' to 'Approved' or 'Rejected'.
* `approved_by` (INT UNSIGNED): FK to `sys_users`. Mapped to the logged-in manager's ID.
* `approved_at` (TIMESTAMP): Set to `CURRENT_TIMESTAMP()` upon approval.

---

## 4. Screen Fields & Input Rules

The screen displays three tabular columns:

### Tab 1: Pending Fuel Logs Grid
* Columns: Vehicle, Driver, Date, Fuel Quantity, Cost, Odometer, Action buttons (Approve / Reject).

### Tab 2: Pending Service Requests Grid
* Columns: Vehicle, Inspection ID, Request Date, Fault Reason, Action buttons (Approve / Reject).

### Tab 3: Pending Maintenance Logs Grid
* Columns: Service Request ID, Garage/Workshop, Initiation Date, Cost, Action buttons (Approve / Reject).

### Common Actions Modal
* **Approval Remarks**: Optional. Text area (max 255 chars). Required if rejecting.

---

## 5. Business Logic & Validation Policies

### Service Request Approval Actions
* When a service request is approved:
  $$\text{tpt\_vehicle\_service\_request.request\_approval\_status} = \text{'Approved'}$$
  * A record is automatically created in `tpt_vehicle_maintenance` for that vehicle.
  * The vehicle's availability status is locked:
    $$\text{tpt\_vehicle.availability\_status} = 0$$

### Maintenance Approval Actions (Vendor Billing Integration)
* When a maintenance completion record is approved:
  $$\text{tpt\_vehicle\_maintenance.status} = \text{'Approved'}$$
  * The system checks the vehicle's ownership model (`tpt_vehicle.ownership_type_id`).
  * If ownership is "Leased" or "Rented":
    * Retrieve the associated `vendor_id` and the active vendor agreement (`vnd_agreements` where `status = 'Active'`).
    * Automatically create a pending invoice liability record in the vendor billing table (`vnd_vendor_bill_due_for_payment`) using the maintenance `cost` (`tpt_vehicle_maintenance.cost`).
  * The vehicle's availability status is restored:
    $$\text{tpt\_vehicle.availability\_status} = 1$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Approve Fuel Log
1. Navigate to `/transport/vehicle-mgmt` and select the **Vehicle Approval** tab.
2. Under the "Pending Fuel Logs" table, locate a pending fuel log entry (e.g., Cost ₹4500, Qty 50L).
3. Click the green checkmark "Approve" button.
4. Verify:
   - The fuel log row is removed from the pending approvals grid.
   - Check the database: `tpt_vehicle_fuel.status` is updated to `Approved`.

### Test Case 2: Reject Service Request with Remarks
1. Click the "Pending Service Requests" sub-tab.
2. Locate a service request row and click the red "Reject" button.
3. Verify that a modal opens demanding rejection remarks.
4. Leave remarks blank and click submit. Verify error: "Rejection remarks are required."
5. Enter remarks "Inspected, minor noise only, no repair needed" and click submit.
6. Verify:
   - The row is removed from the grid.
   - Check the database: `tpt_vehicle_service_request.request_approval_status` is updated to `Rejected`.

### Test Case 3: Verify Vendor Bill Creation
1. Click the "Pending Maintenance" sub-tab.
2. Locate a record for a **Leased** vehicle with cost ₹5000.
3. Click "Approve".
4. Navigate to the Vendor Billing ledger.
5. Verify that a new billing liability entry has been logged for ₹5000 linked to the corresponding vendor.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Approval Main Tab**: `@vehicle-approval-tab`
* **Fuel Tab Selector**: `@pending-fuel-tab`
* **Service Request Tab Selector**: `@pending-service-tab`
* **Maintenance Tab Selector**: `@pending-maintenance-tab`
* **Approve Action Button**: `@approve-row-btn-1` (dynamic row ID)
* **Reject Action Button**: `@reject-row-btn-1`
* **Remarks Modal Input**: `textarea[name="approval_remarks"]`
* **Submit Modal Button**: `@submit-approval-modal-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportApprovalTest extends DuskTestCase
{
    public function testManagerApprovalWorkflows()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/vehicle-mgmt')
                    ->click('@vehicle-approval-tab')
                    
                    // Approve a fuel log
                    ->click('@pending-fuel-tab')
                    ->waitFor('@approve-row-btn-1')
                    ->click('@approve-row-btn-1')
                    ->pause(1000)
                    ->assertDontSee('@approve-row-btn-1') // Row removed
                    
                    // Reject a service request with remarks
                    ->click('@pending-service-tab')
                    ->waitFor('@reject-row-btn-1')
                    ->click('@reject-row-btn-1')
                    ->waitFor('@submit-approval-modal-btn')
                    ->click('@submit-approval-modal-btn')
                    ->assertSee('Rejection remarks are required')
                    ->type('approval_remarks', 'No issue found')
                    ->click('@submit-approval-modal-btn')
                    ->pause(1000);
        });
    }
}
```
