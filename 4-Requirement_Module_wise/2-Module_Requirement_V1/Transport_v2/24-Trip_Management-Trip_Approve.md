# Trip Approve — Requirement Document

## 1. Screen Purpose & Overview

The Trip Approve screen serves as an end-of-day auditing inbox for completed trips. Managers and coordinators review run details (including starting/ending odometer readings, safety logs, and passenger boarding ratios) and approve them. 

Approving a trip locks all operational data from further modification and initiates automated logs to update the Vendor Management module for contract lease calculations.

---

## 2. Common Business Use Cases

1. **Reviewing Completed Runs:** The manager reviews the mileage variance and student passenger count for yesterday's routes before approving the logs.
2. **Flagging Odometer Discrepancies:** The manager flags a trip showing an abnormal mileage run, placing it in a "Pending Audit" state.
3. **Triggering Vendor Bill Logs:** Approving a trip completed by a vendor-leased vehicle to automatically log billing units (mileage or runs).

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_trip` table (and trigger inserts into `vnd_usage_logs`):

### Target Columns in `tpt_trip`
* `id` (INT UNSIGNED): Primary Key.
* `approved` (TINYINT): Mapped as approval checkbox (0 = Pending, 1 = Approved).
* `approved_by` (INT UNSIGNED): FK to `sys_users` (logged-in manager user ID).
* `approved_at` (TIMESTAMP): Set to `CURRENT_TIMESTAMP()` upon confirmation.
* `remarks` (VARCHAR(512)): Audit comments or rejection reasons.

### Settings Mapped from `sch_settings`
* `trip_usage_needs_to_be_updated_into_vendor_usage_log` (TINYINT): Boolean setting (`0` or `1`).

---

## 4. Screen Fields & Input Rules

The screen presents a list grid of completed trips awaiting manager review:

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Approval Action** | Button | Required to trigger action. Options: `Approve`, `Reject`. | `tpt_trip.approved` |
| **Remarks / Audit Notes** | Text Area | Required if selecting `Reject` (Rejects reset status to 'Scheduled'). | `tpt_trip.remarks` |
| **Date Range Filter** | Datepicker | Optional. Filters completed trips list. | Query filter parameter. |

---

## 5. Business Logic & Validation Policies

### Vendor Integration Workflow
Upon trip approval (`tpt_trip.approved = 1`):
1. The system checks the global system settings table:
   $$\text{trip\_usage\_needs\_to\_be\_updated\_into\_vendor\_usage\_log} == 1$$
2. If true, and the vehicle's ownership model is Leased or Rented:
   * Retrieve the active agreement item (`vnd_agreement_items_jnt`) for the vehicle and route.
   * Determine the contract billing unit:
     * If billing unit is `Trip`:
       $$\text{quantity\_used} = 1$$
     * If billing unit is `KM` (mileage):
       $$\text{quantity\_used} = \text{end\_odometer\_reading} - \text{start\_odometer\_reading}$$
   * Create an automated entry in the Vendor Usage Log:
     $$\text{INSERT INTO vnd\_usage\_logs (vendor\_id, agreement\_item\_id, quantity\_used, remarks)}$$

### Data Locking
* Once a trip is approved, all stop arrival times, passenger logs, and odometer details are frozen. Direct SQL updates are blocked.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Approve Completed Trip & Verify Vendor Sync (Happy Path)
1. Go to `/transport/trip` and select the **Trip Approve** tab.
2. Locate a completed trip run on a **Leased** vehicle (e.g. Bus V-101, Start Odometer `12000`, End `12025`).
3. Click "Approve". Enter remarks: "Run completed on time, mileage matches GPS." Click Save.
4. Verify:
   - The trip status updates to `Approved`.
   - Go to the Vendor Usage Logs grid (`vnd_usage_logs`).
   - Confirm that a new entry has been recorded for `25.00` units (if contract is billed per KM) or `1.00` unit (if billed per trip).

### Test Case 2: Reject Trip for Odometer Correction
1. Select a completed trip with a duplicate or incorrect odometer log.
2. Click "Reject".
3. Verify that saving fails without remarks: "Remarks are required for audit rejection."
4. Input remarks: "Ending odometer reading is incorrect. Recalibrate and edit log." Click Submit.
5. Verify the trip status resets to `Scheduled` or `In-Transit`, allowing the driver to re-submit correct odometer values.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Trip Approve Tab**: `@trip-approve-tab`
* **Approve Row Button**: `@approve-trip-btn-1` (dynamic row ID)
* **Reject Row Button**: `@reject-trip-btn-1`
* **Remarks Modal Input**: `textarea[name="remarks"]`
* **Submit Audit Button**: `@submit-audit-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportTripApproveTest extends DuskTestCase
{
    public function testTripAuditAndVendorSyncTrigger()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/trip')
                    ->click('@trip-approve-tab')
                    ->waitFor('@approve-trip-btn-1')
                    
                    // Reject without remarks
                    ->click('@reject-trip-btn-1')
                    ->waitFor('@submit-audit-btn')
                    ->click('@submit-audit-btn')
                    ->assertSee('Remarks are required for audit rejection')
                    ->type('remarks', 'Need mileage correction')
                    ->click('@submit-audit-btn')
                    ->pause(1000)
                    
                    // Approve completed trip
                    ->waitFor('@approve-trip-btn-2')
                    ->click('@approve-trip-btn-2')
                    ->waitFor('@submit-audit-btn')
                    ->type('remarks', 'Logs confirmed')
                    ->click('@submit-audit-btn')
                    ->pause(1000)
                    ->assertDontSee('@approve-trip-btn-2'); // Row approved and removed
        });
    }
}
```
