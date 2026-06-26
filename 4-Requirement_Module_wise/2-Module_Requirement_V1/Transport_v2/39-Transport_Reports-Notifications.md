# Notifications Report — Requirement Document

## 1. Screen Purpose & Overview

The Notifications Report screen compiles history logs of WhatsApp, SMS, Email, and Push alerts dispatched to parents and students during trips (e.g., "Bus started", "Approaching stop", or delay alerts). 

This helps coordinators verify notification deliverability, trace API failures, and audit communication channels.

---

## 2. Common Business Use Cases

1. **Verifying Stop Alerts Delivery:** A parent claims they never received the "Bus Approaching" alert. The manager searches the log by phone number to trace the delivery state.
2. **Auditing API Failures:** Identifying spikes in SMS/WhatsApp delivery failures to diagnose gateway downtime.
3. **Tracking Delay Communication:** Confirming that delay alerts were successfully sent during a road breakdown incident.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_notification_log` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `student_session_id` (INT UNSIGNED): FK to `std_student_academic_sessions`. Mapped student context.
* `trip_id` (INT UNSIGNED): FK to `tpt_trip`. Active trip context.
* `boarding_stop_id` (INT UNSIGNED): FK to `tpt_pickup_points`. Target stop triggering the alert.
* `notification_type` (ENUM): Alert category: 'TripStart', 'ApproachingStop', 'ReachedStop', 'Delayed', 'Cancelled'.
* `sent_time` (DATETIME): Timestamp of dispatch.
* `app_notification_status` (ENUM): 'NotRegistered', 'Sent', 'Failed'.
* `sms_notification_status` (ENUM): 'NotRegistered', 'Sent', 'Failed'.
* `email_notification_status` (ENUM): 'NotRegistered', 'Sent', 'Failed'.
* `whatsapp_notification_status` (ENUM): 'NotRegistered', 'Sent', 'Failed'.
* `created_at` (TIMESTAMP): Creation date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Date Range** | Date Range Picker | Required. Defaults to `CURRENT_DATE()`. | `sent_time` filter. |
| **Alert Type** | Dropdown | Optional. Options: `All`, `TripStart`, `ApproachingStop`, `Delayed`. | `notification_type` |
| **Status Filter** | Dropdown | Optional. Filters by `Sent` or `Failed`. | Channel status check. |
| **Search Keyword** | Text Input | Optional. Filters by Student Name or Phone Number. | Wildcard string match. |

---

## 5. Business Logic & Validation Policies

### Calculations & Mathematical Formulas
* **Deliverability Success Rate (DSR) (%)**:
  $$\text{Deliverability Success Rate} = \left( \frac{\text{Total Successfully Sent Alerts}}{\text{Total Attempted Dispatches}} \right) \times 100$$
  * *Where Successfully Sent Alerts* is the count of logs where at least one active channel (SMS, App, WhatsApp, or Email) shows status `Sent`.
  * *Where Attempted Dispatches* is the total count of logs matching the query.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Search Dispatch Logs (Happy Path)
1. Go to `/transport/transport-report` and click the **Notifications** tab.
2. Select Date Range: Today. Set Alert Type: `ApproachingStop`. Click Search.
3. Verify that:
   - The grid renders logs matching the filters.
   - Column columns show: Student, Phone, Type, Sent Time, App Status, SMS Status, WhatsApp Status, and Email Status.

### Test Case 2: Trace Delivery Failures
1. Filter the grid to show only rows where `sms_notification_status = 'Failed'`.
2. Verify that:
   - The failed status cells are highlighted in red text.
   - Re-send button triggers manual gateway retry.

### Test Case 3: Verify Success Rate Metric
1. Look at the top summary dashboard.
2. Verify that the Deliverability Success Rate calculation correctly reflects the percentage of successfully sent notifications.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Notifications Tab**: `@notifications-report-tab`
* **Date Range Field**: `input[name="date_range"]`
* **Alert Dropdown**: `select[name="notification_type"]`
* **Search Button**: `@filter-report-btn`
* **Report Grid Table**: `@notifications-grid-table`
* **Success Metric Display**: `@delivery-success-rate`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportNotificationsReportTest extends DuskTestCase
{
    public function testNotificationLogsFiltersAndRates()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/transport-report')
                    ->click('@notifications-report-tab')
                    ->waitFor('@notifications-grid-table')
                    
                    // Filter report
                    ->select('notification_type', 'ApproachingStop')
                    ->click('@filter-report-btn')
                    ->pause(1000)
                    
                    // Assert columns and delivery metric
                    ->assertSee('Bobby')
                    ->assertVisible('@delivery-success-rate');
        });
    }
}
```
