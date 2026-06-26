# Student Transport Allocation — Requirement Document

## 1. Screen Purpose & Overview

The Student Transport Allocation screen maps students to specific travel routes and stops. It links a student's academic session record to a pickup route/stop, a drop route/stop, and a service mode (`transport_use_type` as 'Pickup', 'Drop', or 'Both'). 

This mapping establishes the baseline monthly fare for generating monthly student transport invoices.

---

## 2. Common Business Use Cases

1. **Allocating New Student:** The registrar allocates student Bobby to Route R-10 (Pickup) starting at stop "Sector 15 Stop" and Route R-10D (Drop) ending at "Sector 15 Stop".
2. **Changing Stops:** The parent requests a stop change, updating the monthly fare rate.
3. **Suspending Service:** Temporarily deactivating a student's allocation due to long-term leave or disciplinary suspension.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_student_route_allocation_jnt` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `student_session_id` (INT UNSIGNED): FK to `std_student_academic_sessions`. Active academic year session link.
* `student_id` (INT UNSIGNED): FK to `std_students` (via session mapping). Mapped student.
* `transport_use_type` (ENUM): Service type: 'Pickup', 'Drop', 'Both'.
* `pickup_route_id` (INT UNSIGNED): FK to `tpt_route`. Mapped pickup route.
* `pickup_stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Mapped pickup stop.
* `drop_route_id` (INT UNSIGNED): FK to `tpt_route`. Mapped drop route.
* `drop_stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Mapped drop stop.
* `fare` (DECIMAL(10,2)): Monthly transport fare billed to the student.
* `effective_from` (DATE): Allocation commencement date.
* `active_status` (TINYINT): 0 = Inactive, 1 = Active. Defaults to 1.
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Last updated date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Academic Session** | Dropdown | Required. Matches active session ID. | `student_session_id` |
| **Student** | Dropdown | Required. Matches active student list. | `student_id` |
| **Allocation Mode** | Dropdown | Required. Options: `Pickup`, `Drop`, `Both`. | `transport_use_type` |
| **Pickup Route** | Dropdown | Required if Mode is `Pickup` or `Both`. | `pickup_route_id` |
| **Pickup Stop** | Dropdown | Required if Mode is `Pickup` or `Both`. Must be on route. | `pickup_stop_id` |
| **Drop Route** | Dropdown | Required if Mode is `Drop` or `Both`. | `drop_route_id` |
| **Drop Stop** | Dropdown | Required if Mode is `Drop` or `Both`. Must be on route. | `drop_stop_id` |
| **Calculated Fare** | Read-only Input | Required. Auto-computed base fare (Decimal). | `fare` |
| **Effective From** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `effective_from` |
| **Active Status** | Toggle / Checkbox| Required. Default is 1 (Active). | `active_status` |

---

## 5. Business Logic & Validation Policies

### Stop Dependency Validation
* The selected `pickup_stop_id` must be mapped to the selected `pickup_route_id` inside `tpt_pickup_points_route_jnt`.
* The selected `drop_stop_id` must be mapped to the selected `drop_route_id`.

### Active Allocation Cap
* A student can only have one active allocation mapping per calendar date to prevent billing conflicts.

### Fare Calculations
* Fares are auto-computed based on the stops configuration in `tpt_pickup_points_route_jnt`:
  * If `transport_use_type = 'Pickup'`:
    $$\text{fare} = \text{tpt\_pickup\_points\_route\_jnt.pickup\_drop\_fare}_{\text{pickup\_stop}}$$
  * If `transport_use_type = 'Drop'`:
    $$\text{fare} = \text{tpt\_pickup\_points\_route\_jnt.pickup\_drop\_fare}_{\text{drop\_stop}}$$
  * If `transport_use_type = 'Both'` and pickup/drop stop IDs are identical:
    $$\text{fare} = \text{tpt\_pickup\_points\_route\_jnt.both\_side\_fare}_{\text{stop}}$$
  * If `transport_use_type = 'Both'` and stops are different:
    $$\text{fare} = \text{pickup\_drop\_fare}_{\text{pickup\_stop}} + \text{pickup\_drop\_fare}_{\text{drop\_stop}}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Student Allocation Both-Side Same Stop (Happy Path)
1. Go to `/transport/student-allocation` and click "+ New Allocation".
2. Select Student: `Bobby`, Mode: `Both`.
3. Select Pickup Route: `Route 10 (Pickup)`, Stop: `Sector 22 Market Stop`.
4. Select Drop Route: `Route 10D (Drop)`, Stop: `Sector 22 Market Stop`.
5. Verify that:
   - **Calculated Fare** updates to both-side fare configured for Sector 22 stop (e.g. ₹1800.00).
6. Click Save. Confirm record is stored.

### Test Case 2: Validate Unmatched Route Stop
1. Click "+ New Allocation".
2. Select Route: `Route 10 (Pickup)`.
3. Attempt to select a stop that belongs to `Route 11` (or verify that it does not appear in the stop dropdown).
4. Select it (if bypass attempted) and click Save.
5. Verify validation error: "Selected stop must be mapped to the assigned route."

### Test Case 3: Verify Deactivation
1. Locate Bobby's active allocation.
2. Edit the record, toggle "Active Status" to **No**, and click Save.
3. Go to the monthly billing process. Verify that no transport invoice is generated for Bobby for the next billing cycle.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Allocation Tab**: `@allocation-tab`
* **New Allocation Button**: `@add-allocation-btn`
* **Session Dropdown**: `select[name="student_session_id"]`
* **Student Dropdown**: `select[name="student_id"]`
* **Mode Dropdown**: `select[name="transport_use_type"]`
* **Pickup Route Dropdown**: `select[name="pickup_route_id"]`
* **Pickup Stop Dropdown**: `select[name="pickup_stop_id"]`
* **Drop Route Dropdown**: `select[name="drop_route_id"]`
* **Drop Stop Dropdown**: `select[name="drop_stop_id"]`
* **Fare Field**: `input[name="fare"]`
* **Save Button**: `@save-allocation-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportAllocationTest extends DuskTestCase
{
    public function testStudentAllocationAndFareComputations()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/student-allocation')
                    ->click('@allocation-tab')
                    ->click('@add-allocation-btn')
                    ->select('student_session_id', '1')
                    ->select('student_id', '1')
                    ->select('transport_use_type', 'Both')
                    
                    // Select Routes & Stops
                    ->select('pickup_route_id', '1')
                    ->select('pickup_stop_id', '1')
                    ->select('drop_route_id', '2')
                    ->select('drop_stop_id', '1')
                    
                    // Assert fare is read-only and filled
                    ->assertAttribute('@fare-input', 'readonly', 'true')
                    ->assertValue('@fare-input', '1800.00')
                    
                    ->click('@save-allocation-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
