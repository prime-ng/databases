# Transport Dashboard — Requirement Document

## 1. Screen Purpose & Overview

The Transport Dashboard acts as the primary real-time monitoring terminal for the institution's transport operations. It consolidates data from vehicles, trips, staff attendance, safety incidents, and billing systems into a single centralized console. 

The dashboard enables transport coordinators and managers to:
* Monitor active vehicle availability and maintenance status.
* Check daily driver and helper attendance.
* Track active trips, schedule delays, and unresolved road incidents.
* Monitor financial metrics including fuel log costs, maintenance bills, and student fee collections.
* View live boarding ratios of students using RFID/QR scanners.

---

## 2. Common Business Use Cases

1. **Morning Run Readiness Check:** At 6:30 AM, the coordinator opens the dashboard to check if all active vehicles are marked "Available" and that all scheduled drivers have clocked in via their devices.
2. **Safety Incident Resolution:** The operator detects a sudden warning indicator on the "Active Incidents" widget. They click to inspect and locate a route delay due to a minor vehicle breakdown, allowing them to dispatch a backup vehicle.
3. **Student Boarding Tracking:** During school departure, the principal monitors the "Student Boarding Ratio" to verify that all students assigned to the afternoon shift have boarded their respective buses.
4. **Operations Cost Audit:** At the end of the month, the administrator compares total fuel log costs and service expenses against total transport fee collections to determine financial leakage.

---

## 3. Database Schema & Data Dictionary

The dashboard aggregates metrics from the following core tables:

### `tpt_vehicle`
* `availability_status` (TINYINT): 0 = Not Available, 1 = Available.
* `is_active` (TINYINT): 0 = Inactive, 1 = Active.

### `tpt_trip`
* `trip_date` (DATE): Target date of the trip.
* `status` (VARCHAR): Current trip status ('Scheduled', 'In-Transit', 'Completed', 'Cancelled').

### `tpt_driver_attendance`
* `attendance_date` (DATE): Date of driver attendance check-in.
* `attendance_status` (INT): FK to `sys_dropdown_table` (representing 'Present', 'Absent', 'Half-Day', 'Late').

### `tpt_trip_incidents`
* `resolved_at` (TIMESTAMP): NULL if unresolved, otherwise contains resolution date-time.

### `tpt_student_boarding_log`
* `trip_date` (DATE): Date of the boarding log.
* `boarding_time` (DATETIME): Time the student checked in.
* `unboarding_time` (DATETIME): Time the student checked out.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Refresh Interval** | Dropdown | Required. Options: `10s`, `30s`, `60s`, `Manual`. Default: `30s`. | Session-based configuration. |
| **Date Filter** | Datepicker | Optional. Defaults to `CURRENT_DATE()`. | System date parameters. |
| **Active Vehicles Widget** | Card Metric | Read-only. Displays count of available vehicles. | `COUNT(tpt_vehicle.id) WHERE availability_status = 1 AND is_active = 1` |
| **Active Trips Widget** | Card Metric | Read-only. Displays count of active runs. | `COUNT(tpt_trip.id) WHERE trip_date = DateFilter AND status = 'In-Transit'` |
| **Checked-In Personnel Widget** | Card Metric | Read-only. Displays count of checked-in staff. | `COUNT(tpt_driver_attendance.id) WHERE attendance_date = DateFilter AND attendance_status = 'Present'` |
| **Active Incidents Widget** | Card Metric | Read-only. Displays count of unresolved incidents. | `COUNT(tpt_trip_incidents.id) WHERE resolved_at IS NULL` |
| **Student Boarding Chart** | Bar/Donut Chart | Read-only. Renders count of boarded vs. total allocated students. | Aggregates from `tpt_student_boarding_log` and `tpt_student_route_allocation_jnt`. |

---

## 5. Business Logic & Validation Policies

### Dashboard Auto-Refresh
The screen must automatically fetch fresh metrics via AJAX requests at the interval specified by the **Refresh Interval** setting. Changing the dropdown resets the interval timer immediately.

### Calculations & Mathematical Formulas
* **Personnel Attendance Rate (%)**:
  $$\text{Attendance Rate} = \left( \frac{\text{Present Personnel}}{\text{Total Configured Active Personnel}} \right) \times 100$$
  * *Where Present Personnel* is the count of personnel with a check-in status of 'Present' on `DateFilter` in `tpt_driver_attendance`.
  * *Where Total Configured Active Personnel* is the total count of staff records in `tpt_personnel` with `is_active = 1` and `deleted_at IS NULL`.

* **Student Boarding Completion Rate (%)**:
  $$\text{Boarding Rate} = \left( \frac{\text{Boarded Students}}{\text{Total Allocated Students}} \right) \times 100$$
  * *Where Boarded Students* is the count of records in `tpt_student_boarding_log` with a non-null `boarding_time` for the selected date.
  * *Where Total Allocated Students* is the count of active allocations in `tpt_student_route_allocation_jnt` for the active session.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Initial Load & Metric Validation
1. Log in as a Transport Manager and navigate to `/transport/transport-master`.
2. Verify that the Dashboard tab is active.
3. Confirm that "Active Vehicles" displays the correct number of vehicles that have `availability_status = 1` in the database.
4. Verify that "Active Trips" matches the count of daily trips currently set to `In-Transit`.

### Test Case 2: Auto-Refresh Interval Adjustments
1. Select the `10s` option from the **Refresh Interval** dropdown.
2. Open the browser dev tools (Network tab) and monitor for AJAX requests.
3. Verify that requests to fetch updated dashboard metrics are dispatched exactly every 10 seconds.
4. Select `Manual` from the dropdown and verify that auto-polling stops. Click the manual refresh button to trigger an update.

### Test Case 3: Live Incident Drills
1. Create an incident record in the database where `resolved_at IS NULL`.
2. Confirm the "Active Incidents Widget" count increments.
3. Click the widget. Verify that a modal opens showing the incident ID, vehicle registration, driver name, severity, and description.
4. Close the modal, mark the incident as resolved, and verify the count updates to reflect the change.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Dashboard Tab**: `@transport-dashboard-tab`
* **Refresh Interval Dropdown**: `select[name="refresh_interval"]` or `@refresh-interval`
* **Manual Refresh Button**: `@manual-refresh-btn`
* **Active Vehicles Metric**: `@active-vehicles-count`
* **Active Trips Metric**: `@active-trips-count`
* **Checked-In Staff Metric**: `@checked-in-staff-count`
* **Active Incidents Metric**: `@active-incidents-count`
* **Incident Drilldown Modal**: `@incident-drilldown-modal`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportDashboardTest extends DuskTestCase
{
    /**
     * Test the loading, selectors, and interactive refresh configurations of the dashboard.
     */
    public function testDashboardRendersMetricsAndDrilldowns()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-master')
                    ->click('@transport-dashboard-tab')
                    ->waitFor('@active-vehicles-count')
                    ->assertSeeIn('@active-vehicles-count', 'Available')
                    ->assertVisible('@active-trips-count')
                    ->assertVisible('@checked-in-staff-count')
                    
                    // Modify auto refresh rate
                    ->select('@refresh-interval', '10s')
                    ->pause(11000) // wait for refresh cycle
                    
                    // Test manual refresh
                    ->click('@manual-refresh-btn')
                    ->pause(1000)
                    
                    // Click incidents widget and verify modal
                    ->click('@active-incidents-count')
                    ->waitFor('@incident-drilldown-modal')
                    ->assertSee('Incident Details')
                    ->click('@close-modal-btn');
        });
    }
}
```
