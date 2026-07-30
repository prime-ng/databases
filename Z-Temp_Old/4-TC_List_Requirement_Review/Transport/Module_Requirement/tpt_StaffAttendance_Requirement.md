# Staff Attendance — Requirement Document

## 1. Screen Purpose & Overview

The Staff Attendance screen manages daily clock-in and clock-out logs for transport staff (drivers and helpers). It records check-in and check-out timestamps, scan methods (QR, RFID, NFC, Manual overrides), coordinates at the moment of scan, and maps them to a summary attendance ledger. 

This tracking ensures driver availability is confirmed prior to dispatching vehicles and compiles working hours for payroll audits.

---

## 2. Common Business Use Cases

1. **Clocking In via Companion App:** A driver scans their unique QR code on the bus tablet at 06:45 AM, registering a clock-in event.
2. **Clocking Out at Shift Completion:** A helper scans out at 04:30 PM, ending their daily shift.
3. **Manager Attendance Override:** The transport coordinator manually logs attendance for a driver whose RFID card was damaged.

---

## 3. Database Schema & Data Dictionary

Attendance records are divided into summary ledgers and raw scan log records:

### Summary Table: `tpt_driver_attendance`
* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `driver_id` (INT UNSIGNED): FK to `tpt_personnel`. Crew member reference.
* `attendance_date` (DATE): Target date of attendance.
* `first_in_time` (DATETIME): Timestamp of first check-in of the day.
* `last_out_time` (DATETIME): Timestamp of last check-out of the day.
* `total_work_minutes` (INT): Total minutes worked during the day.
* `attendance_status` (INT): FK to `sys_dropdown_table` (representing 'Present', 'Absent', 'Half-Day', 'Late').
* `via_app` (TINYINT): 0 = Manual entry by manager, 1 = Scanned via companion app.

### Log Details Table: `tpt_driver_attendance_log`
* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `attendance_id` (INT UNSIGNED): FK to `tpt_driver_attendance`.
* `scan_time` (DATETIME): Timestamp of the specific scan event.
* `attendance_type` (ENUM): 'IN' or 'OUT'.
* `scan_method` (ENUM): 'QR', 'RFID', 'NFC', 'Manual'.
* `device_id` (INT UNSIGNED): FK to `tpt_attendance_device`. Logging device.
* `latitude` (DECIMAL(10,6)): GPS latitude of the scanning terminal.
* `longitude` (DECIMAL(10,6)): GPS longitude of the scanning terminal.
* `scan_status` (ENUM): 'Valid', 'Duplicate', 'Rejected'. Defaults to 'Valid'.
* `remarks` (VARCHAR(255)): Audit override comments.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Driver / Helper** | Dropdown | Required. Matches list of active personnel (`tpt_personnel`). | `tpt_driver_attendance.driver_id` |
| **Attendance Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `tpt_driver_attendance.attendance_date` |
| **Attendance Status** | Dropdown | Required. Options: `Present`, `Absent`, `Half-Day`, `Late`. | `tpt_driver_attendance.attendance_status` |
| **Check-In Time** | Timepicker | Required if status is not 'Absent'. | `tpt_driver_attendance.first_in_time` |
| **Check-Out Time** | Timepicker | Optional. Must be $\ge$ Check-In Time. | `tpt_driver_attendance.last_out_time` |
| **Scan Method** | Dropdown | Required for manual entry (sets to 'Manual'). | `tpt_driver_attendance_log.scan_method` |
| **Override Remarks** | Text Area | Required if manually modifying existing app logs. | `tpt_driver_attendance_log.remarks` |

---

## 5. Business Logic & Validation Policies

### Double Clock-In Prevention
* Only one summary record can exist per crew member per date, enforced by unique constraint index `uq_driver_day`.

### Duration Calculations
* When a check-out timestamp (`last_out_time`) is logged, the system automatically computes total working minutes:
  $$\text{total\_work\_minutes} = \text{DATEDIFF\_MINUTES}(\text{first\_in\_time}, \text{last\_out\_time})$$

### Roster Integration
* If a driver is marked "Absent" on a given date:
  $$\text{tpt\_driver\_attendance.attendance\_status} = \text{Absent}$$
  * The system blocks dispatching any daily trip (`tpt_trip`) on that date that has this driver assigned.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Manual Attendance Override (Happy Path)
1. Go to `/transport/drive-attendance` and click "+ Add Attendance Override".
2. Select Staff: `John Driver`.
3. Set Date: Today. Status: `Present`.
4. Set Check-In Time: `07:00 AM`, Check-Out Time: `04:00 PM`.
5. Enter Remarks: "Forgot card, checked manually".
6. Click Save. Confirm log is written and status displays as `Present`.

### Test Case 2: Double Attendance Block
1. Attempt to add another attendance record for `John Driver` on the exact same date as Test Case 1.
2. Click Save.
3. Verify validation error: "An attendance record already exists for this staff member on this date."

### Test Case 3: Verify Dispatch Blocking
1. Mark driver `Dave Helper` as `Absent` for today's date.
2. Go to daily trip scheduling. Attempt to dispatch a trip with Dave Helper assigned.
3. Verify that dispatch is blocked with an alert: "Cannot dispatch trip. Assigned personnel Dave Helper is marked absent."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Attendance Tab**: `@attendance-tab`
* **Override Button**: `@add-override-btn`
* **Driver Dropdown**: `select[name="driver_id"]`
* **Date Field**: `input[name="attendance_date"]`
* **Status Dropdown**: `select[name="attendance_status"]`
* **Check-In Field**: `input[name="first_in_time"]`
* **Check-Out Field**: `input[name="last_out_time"]`
* **Remarks Field**: `textarea[name="remarks"]`
* **Save Button**: `@save-attendance-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportStaffAttendanceTest extends DuskTestCase
{
    public function testAttendanceOverrideAndDoubleLogPrevention()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/drive-attendance')
                    ->click('@attendance-tab')
                    ->click('@add-override-btn')
                    ->select('driver_id', '1')
                    ->keys('input[name="attendance_date"]', '05232026') // 2026-05-23
                    ->select('attendance_status', '1') // Present
                    ->type('first_in_time', '07:00')
                    ->type('last_out_time', '16:00')
                    ->type('remarks', 'Manual verification')
                    ->click('@save-attendance-btn')
                    ->assertSee('saved successfully')
                    
                    // Attempting duplicate attendance record
                    ->click('@add-override-btn')
                    ->select('driver_id', '1')
                    ->keys('input[name="attendance_date"]', '05232026')
                    ->select('attendance_status', '1')
                    ->click('@save-attendance-btn')
                    ->assertSee('attendance record already exists');
        });
    }
}
```
