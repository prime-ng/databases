# Trip Incidents — Requirement Document

## 1. Screen Purpose & Overview

The Trip Incidents screen logs and manages operational exceptions occurring during daily runs, including breakdowns, accidents, route delays, and speed violations. It provides a real-time ledger for coordinators to dispatch emergency support, notify parents, and maintain safety audit records.

---

## 2. Common Business Use Cases

1. **Logging Engine Breakdown:** A driver logs that Bus V-101 has suffered an engine overheating breakdown at Sector 22, requiring a backup dispatch.
2. **Reporting Traffic Delays:** The companion app logs a route delay due to heavy congestion, updating the estimated time for subsequent stops.
3. **Accident Report Trigger:** The driver reports a minor collision, triggering high-severity emergency alerts to parents and school managers.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_trip_incidents` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `trip_id` (INT UNSIGNED): FK to `tpt_trip`. Active trip where incident occurred.
* `incident_time` (TIMESTAMP): Date and time the incident occurred.
* `incident_type` (INT UNSIGNED): FK to `sys_dropdown_table` (representing 'Breakdown', 'Accident', 'Speeding', 'Delay').
* `severity` (ENUM): Hazard severity flag: 'LOW', 'MEDIUM', 'HIGH'. Defaults to 'MEDIUM'.
* `latitude` (DECIMAL(10,7)): GPS latitude coordinate where incident occurred.
* `longitude` (DECIMAL(10,7)): GPS longitude coordinate where incident occurred.
* `description` (VARCHAR(512)): Narrative detailing the event.
* `status` (INT UNSIGNED): FK to `sys_dropdown_table` (representing 'Open', 'In-Progress', 'Resolved').
* `raised_by` (INT UNSIGNED): FK to `sys_users`. Mapped to driver/helper who filed the log.
* `raised_at` (TIMESTAMP): Timestamp of incident entry.
* `resolved_at` (TIMESTAMP): Timestamp of resolution check-off (NULL if open).
* `resolved_by` (INT UNSIGNED): FK to `sys_users`. Coordinator who resolved the incident.
* `created_at` (TIMESTAMP): System creation timestamp.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Trip Reference** | Dropdown | Required. Matches list of active trips (`tpt_trip`). | `tpt_trip_incidents.trip_id` |
| **Incident Type** | Dropdown | Required. Matches dropdown system codes. | `tpt_trip_incidents.incident_type` |
| **Severity** | Radio / Buttons | Required. Options: `LOW`, `MEDIUM`, `HIGH`. | `tpt_trip_incidents.severity` |
| **GPS Latitude** | Text / Decimal | Optional. Mapped automatically on mobile scans. | `tpt_trip_incidents.latitude` |
| **GPS Longitude** | Text / Decimal | Optional. Mapped automatically on mobile scans. | `tpt_trip_incidents.longitude` |
| **Incident Details** | Text Area | Required. Max 512 characters. | `tpt_trip_incidents.description` |
| **Resolution Status** | Dropdown | Optional. Defaults to 'Open'. | `tpt_trip_incidents.status` |

---

## 5. Business Logic & Validation Policies

### High-Severity Notifications
* If `severity` is set to `HIGH` (e.g. Accidents or severe breakdowns), the system triggers notification actions to dispatch SMS, push pings, and email alerts immediately:
  $$\text{IF } \text{severity} = \text{'HIGH'} \implies \text{DispatchEmergencyAlerts()}$$

### Resolution Restrictons
* When updating status to 'Resolved', the coordinator must enter a resolution description in the remarks field, setting:
  $$\text{resolved\_at} = \text{CURRENT\_TIMESTAMP()} \quad \land \quad \text{resolved\_by} = \text{Auth::user()->id}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Create Low-Severity Incident (Happy Path)
1. Go to `/transport/trip-management` and click the "Trip Incidents" tab. Click "+ Log Incident".
2. Select active Trip ID, select Incident Type: `Delay`.
3. Set Severity: `LOW`.
4. Enter Incident Details: "Heavy rain, vehicle moving slowly".
5. Click Save. Confirm incident displays as `Open` in the incident board.

### Test Case 2: Emergency High-Severity Alert Check
1. Click "+ Log Incident". Select active Trip.
2. Select Incident Type: `Accident`.
3. Set Severity: `HIGH`.
4. Enter Details: "Minor collision at main circle". Click Save.
5. Verify:
   - Check the notifications log (`tpt_notification_log`). Confirm emergency alerts have been dispatched to administrators and parents.
   - Dashboard reflects a critical incident warning.

### Test Case 3: Resolve Incident Validation
1. Locate the active incident logged in Test Case 1. Click "Resolve".
2. Attempt to resolve leaving the remarks field blank.
3. Verify that the update fails with an error: "Action Taken description is required to resolve an incident."

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Incidents Tab**: `@trip-incidents-tab`
* **Log Incident Button**: `@add-incident-btn`
* **Trip Dropdown**: `select[name="trip_id"]`
* **Incident Type Dropdown**: `select[name="incident_type"]`
* **Severity Radio (HIGH)**: `input[value="HIGH"]`
* **Description Field**: `textarea[name="description"]`
* **Save Button**: `@save-incident-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportTripIncidentsTest extends DuskTestCase
{
    public function testIncidentReportingAndSeverityAlerts()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/trip-management')
                    ->click('@trip-incidents-tab')
                    ->click('@add-incident-btn')
                    ->select('trip_id', '1')
                    ->select('incident_type', '1') // Breakdown
                    ->click('input[value="HIGH"]') // High severity
                    ->type('description', 'Radiator burst, engine smoking')
                    ->click('@save-incident-btn')
                    ->assertSee('saved successfully')
                    
                    // Verify dashboard count update
                    ->visit('/transport/transport-master')
                    ->click('@transport-dashboard-tab')
                    ->assertSeeIn('@active-incidents-count', '1');
        });
    }
}
```
