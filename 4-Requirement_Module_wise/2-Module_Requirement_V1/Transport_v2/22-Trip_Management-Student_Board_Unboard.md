# Student Board Unboard — Requirement Document

## 1. Screen Purpose & Overview

The Student Board Unboard screen tracks student transit events. Utilizing companion RFID scanner payloads or manual tablet confirmations, the system logs when and where students board and unboard vehicles. 

This enables real-time student location tracking and automatic notification alerts to parents.

---

## 2. Common Business Use Cases

1. **Morning Boarding Scan:** A student scans their RFID card at the bus door. The system registers their boarding stop, trip ID, and timestamp.
2. **Afternoon Dispersal Unboarding Scan:** The student scans their RFID card when exiting the bus at their residential stop, closing their active transit tracking for the day.
3. **Emergency Manual Override:** The helper manually clocks in a student who forgot their ID card, picking their name from the active passenger roster.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_student_boarding_log` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `trip_date` (DATE): Target date of trip execution.
* `student_id` (INT UNSIGNED): FK to `tpt_students`. Mapped student identifier.
* `student_session_id` (INT UNSIGNED): FK to `std_student_academic_sessions` (or `tpt_student_session`). Academic session mapping.
* `boarding_route_id` (INT UNSIGNED): FK to `tpt_routes`. Route on which the student boarded.
* `boarding_trip_id` (INT UNSIGNED): FK to `tpt_trip`. Trip ID on which the student boarded.
* `boarding_stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Stop point where the student boarded.
* `boarding_time` (DATETIME): Timestamp of boarding event scan.
* `unboarding_route_id` (INT UNSIGNED): FK to `tpt_routes`. Route where the student unboarded.
* `unboarding_trip_id` (INT UNSIGNED): FK to `tpt_trip`. Trip ID where the student unboarded.
* `unboarding_stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Stop point where the student unboarded.
* `unboarding_time` (DATETIME): Timestamp of unboarding event scan.
* `device_id` (INT UNSIGNED): FK to `tpt_attendance_device`. Scanning terminal device.
* `created_at` (TIMESTAMP): Creation date-time.
* `updated_at` (TIMESTAMP): Update date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Student QR/RFID Scan** | Barcode / Input | Required (for device scan pings). Max 50 chars. | Scans mapped to `tpt_student_boarding_log.student_id`. |
| **Manual Selection** | Dropdown | Required (for manual overrides). Selects active passenger. | `tpt_student_boarding_log.student_id` |
| **Route Assignment** | Read-only Text | Auto-mapped based on active trip context. | `tpt_student_boarding_log.boarding_route_id` |
| **Stop Point** | Dropdown | Required. Selected stop point along active trip sequence. | `tpt_student_boarding_log.boarding_stop_id` |
| **Event Type** | Dropdown / Button | Required. Options: `Board`, `Unboard`. | Determines column write context. |

---

## 5. Business Logic & Validation Policies

### Boarding/Unboarding Log Merge
Rather than inserting separate rows for boarding and unboarding, the system consolidates a student's trip execution events for a single date into a single database row:
1. **Boarding Execution**: If no row exists in `tpt_student_boarding_log` matching `student_id` and `trip_date`:
   * Perform database `INSERT`.
   * Set `boarding_time = CURRENT_TIMESTAMP()` and populate boarding stop/trip/route fields.
2. **Unboarding Execution**: If a row already exists matching `student_id` and `trip_date`:
   * Perform database `UPDATE`.
   * Set `unboarding_time = CURRENT_TIMESTAMP()` and populate unboarding stop/trip/route fields.

### Double Scan Buffer
* To prevent double-reads from accidental card taps, the backend blocks duplicate scan payloads for the same student ID within a 15-second buffer window.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Boarding Scan (Record Insertion)
1. Open the tablet scanning interface for the active trip.
2. Enter the student RFID code: `CARD998877` (or select Bobby manually).
3. Select Stop: `Sector 22 Market Stop`. Set Event Type: `Board`. Click submit.
4. Verify:
   - Bobby displays in the passenger grid as "Boarded".
   - Check the database: A new row is inserted in `tpt_student_boarding_log` with `boarding_time` populated, and `unboarding_time` set to NULL.

### Test Case 2: Unboarding Scan (Record Update)
1. On the same tablet interface, input Bobby's RFID code: `CARD998877` again.
2. Select Stop: `School Terminal`. Set Event Type: `Unboard`. Click submit.
3. Verify:
   - Bobby displays in the passenger grid as "Unboarded/Completed".
   - Check the database: The existing row for Bobby on this date is updated, populating `unboarding_time` and `unboarding_stop_id`.

### Test Case 3: Double Scan Prevention
1. Scan card `CARD998877`. Confirm boarding is logged.
2. Immediately (within 5 seconds), scan card `CARD998877` again.
3. Verify that the app ignores the second scan, or displays a warning: "Duplicate scan ignored."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Boarding Console**: `@boarding-console`
* **RFID Scanner Input**: `input[name="rfid_payload"]` or `@rfid-input`
* **Manual Student Dropdown**: `select[name="student_id"]`
* **Stop Dropdown**: `select[name="boarding_stop_id"]`
* **Scan Event Button**: `@submit-scan-btn`
* **Passenger Status Cell**: `@status-cell-Bobby` (dynamic status display)

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportBoardingLogTest extends DuskTestCase
{
    public function testStudentBoardAndUnboardMergeLogs()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/student/bording')
                    ->click('@boarding-console')
                    
                    // Log Boarding Event
                    ->waitFor('@rfid-input')
                    ->type('rfid_payload', 'CARD998877')
                    ->select('boarding_stop_id', '1') // Sector 22
                    ->click('@submit-scan-btn')
                    ->pause(1000)
                    ->assertSeeIn('@status-cell-Bobby', 'Boarded')
                    
                    // Attempt immediate double scan (should fail/ignore)
                    ->type('rfid_payload', 'CARD998877')
                    ->click('@submit-scan-btn')
                    ->assertSee('Duplicate scan')
                    
                    // Wait for buffer and log Unboarding Event
                    ->pause(16000)
                    ->type('rfid_payload', 'CARD998877')
                    ->select('boarding_stop_id', '3') // School Terminal
                    ->click('@submit-scan-btn')
                    ->pause(1000)
                    ->assertSeeIn('@status-cell-Bobby', 'Unboarded');
        });
    }
}
```
