# Daily Trip — Business Requirements

## What This Screen Does

The Daily Trip screen is the heart of the transport module — it lists every trip that runs on any given day and tracks its progress from start to finish. Each trip shows the date, route, vehicle, driver, helper, start and end times, odometer readings before and after the trip, fuel readings before and after the trip, and the current status. A trip can be Scheduled (ready to run), Ongoing (currently running), Completed (finished), or Cancelled (called off).

This is the screen that Mrs. Desai, the Transport Manager, opens every morning to see which trips are scheduled for the day, which ones are running, and which ones have been completed. It is also the screen where she can approve completed trips, update remarks, and make bulk changes to start times, end times, vehicles, and drivers across multiple trips at once.

Without this screen, Mrs. Desai would have no central view of the day's operations. She would not know which buses have left, which routes are running late, or which trips have been completed. The Daily Trip screen gives her real-time visibility into the entire fleet's movement on any given day.

Each trip is linked to a route schedule entry, which means trips are created from the Route Scheduler and then managed here. Once a trip is created, it follows a strict status path: it starts as Scheduled, can be changed to Ongoing when the bus departs, and then to Completed when the bus returns. Once Completed or Cancelled, the trip cannot be moved back to an earlier status.

When a trip is created, the system performs important compliance checks — it verifies that the driver's driving licence is still valid on the trip date and that the vehicle's fitness certificate and insurance are also valid on that date. If any of these are expired, the trip cannot be created and an error message explains exactly what is wrong.

---

## Default Data Load

When Mrs. Desai opens Trip Management and clicks the Daily Trip tab, the system loads today's trips — 10 per page — showing the trip date, route name, vehicle registration number, driver name, helper name (if any), start time, end time, and a coloured status badge. Trips with a Scheduled status appear in blue, Ongoing in yellow, Completed in green, and Cancelled in red.

A search box at the top allows searching by route name or code, vehicle registration number, or driver name. A status filter dropdown lets her view trips by any status. A date filter lets her look at trips from other dates.

---

## When This Screen Is Used

- **Morning Roll Call — Checking Today's Trips** — Every morning at 6:30 AM, Mrs. Desai opens the Daily Trip screen to see all trips scheduled for the day. She confirms that every route has a trip, every trip has a driver, and every driver has a vehicle. If a trip is missing a driver (because of a late change), she assigns one before the buses roll out.

- **Starting a Trip — Marking as Ongoing** — At 7:00 AM, Bus KL-05 departs from school for the morning pickup run. Mrs. Desai opens the Daily Trip, finds the trip for KL-05 on Route R-07, and changes its status from Scheduled to Ongoing. She records the start time (7:00 AM) and the starting odometer reading (1,25,340 km). The trip is now marked as running.

- **Completing a Trip — Marking as Completed** — At 9:15 AM, Bus KL-05 returns to school after dropping off all students. Mrs. Desai finds the trip, changes its status from Ongoing to Completed, records the end time (9:15 AM) and the ending odometer reading (1,25,890 km). The trip is now marked as completed.

- **Cancelling a Trip** — Bus KL-07 has a mechanical issue and cannot run its afternoon Drop route. Mrs. Desai opens the Daily Trip, finds the trip for KL-07, and changes its status to Cancelled. She adds a remark: "Vehicle breakdown — bus in workshop." The trip is cancelled and cannot be changed back.

- **Bulk Updating Trips** — The school has decided that all afternoon Drop trips should start at 2:45 PM instead of 2:30 PM. Mrs. Desai selects all the afternoon Drop trips, clicks Bulk Update, and changes the start time to 2:45 PM. All selected trips are updated at once.

- **Bulk Approving Completed Trips** — At the end of the week, Mrs. Desai reviews all completed trips. She selects all trips that were completed successfully, clicks Approve, and confirms. The trips are marked as approved. If a trip had an issue, she selects it separately and leaves it unapproved.

---

## Key Fields at a Glance

**Trip Identification**
Every trip is linked to a route schedule entry, which ties it to a specific date, shift, route, vehicle, driver, and helper. The trip date is the actual date the trip runs.

**Timings and Readings**
The start time records when the trip began (when the bus departed), and the end time records when the trip finished (when the bus returned). The starting odometer reading is the odometer value at departure, and the ending odometer reading is the value at return. Similarly, the starting fuel reading and ending fuel reading track how much fuel was in the tank at the start and end of the trip. These readings help the school calculate distance travelled and fuel consumed for each trip.

**Status**
The status tracks where the trip is in its lifecycle. A trip starts as Scheduled, moves to Ongoing, and then to Completed. It can also be Cancelled at any point before completion. Once Completed or Cancelled, the status cannot be changed.

**Approval**
After a trip is completed, it can be approved by an authorised person. Approval marks the trip as verified and final. Once approved, the trip's details are considered locked for reporting purposes (though the approval can be reversed if needed).

**Remarks**
A free-text field where Mrs. Desai can add notes about the trip — for example, "Bus was 10 minutes late due to traffic" or "Driver reported a strange noise from the engine."

---

## Business Rules and Conditions

**Status Transitions Are Strictly Enforced**
A trip follows a one-way path: Scheduled → Ongoing → Completed. Once a trip reaches Completed, it cannot go back to Ongoing or Scheduled. Similarly, once a trip is Cancelled, it cannot be changed to any other status. The system enforces this rule — if Mrs. Desai tries to change a Completed trip back to Ongoing, the system blocks it and displays a message.

**Compliance Checks on Trip Creation**
When a trip is created (either individually or through the Route Scheduler's "Create Trip" button), the system checks three things:
1. The driver's driving licence must be valid on the trip date — the licence expiry date must be on or after the trip date.
2. The vehicle's fitness certificate must be valid on the trip date.
3. The vehicle's insurance must be valid on the trip date.
If any of these checks fail, the trip is not created and the system shows an error message explaining exactly which check failed. For example: "Trip cannot be created. The driving licence for Driver Rajesh expired on September 30th, 2025, which is before the trip date of October 15th, 2025."

**Trip Date Must Be Unique per Route Schedule Entry**
A route schedule entry can have only one trip for its date. If a trip already exists for a schedule entry, creating another trip for the same entry is blocked. This is the same rule that the Route Scheduler's "Create Trip" button uses to skip entries that already have trips.

**Trip Details Can Be Edited After Creation**
Once a trip is created, Mrs. Desai can edit the start time, end time, odometer readings, fuel readings, driver, vehicle, and remarks. Changing the driver or vehicle on a trip does not change the schedule entry — they are independent.

**Bulk Operations**
Mrs. Desai can select multiple trips and perform bulk updates to start times, end times, vehicles, and drivers. She can also bulk approve or unapprove trips. When bulk approving, she selects the trips, clicks Approve, and confirms. The system updates all selected trips at once.

**Inline Remarks**
The remarks field can be updated directly from the list without opening the trip details — Mrs. Desai can click on the remarks cell, type her note, and save it inline.

---

## Workflow Steps

**A Typical Trip Lifecycle — Morning Pickup**
It is Monday morning. Mrs. Desai opens the Daily Trip screen and sees all of today's trips with a Scheduled status. At 6:55 AM, Driver Rajesh starts Bus KL-05. Mrs. Desai finds the trip for KL-05 on Route R-07, clicks Start Trip, and enters the start time (6:55 AM) and starting odometer reading (1,25,340 km). The trip status changes to Ongoing. At 8:45 AM, KL-05 returns to school after completing the pickup route. Mrs. Desai finds the trip, clicks Complete Trip, and enters the end time (8:45 AM) and ending odometer reading (1,25,890 km). The trip status changes to Completed. Later that day, Mrs. Desai reviews the completed trip and approves it.

**Handling a Cancellation Due to Breakdown**
Bus KL-07's morning Pickup trip is Scheduled for 7:00 AM. At 6:30 AM, the mechanic reports that KL-07 has a flat tyre and will not be ready in time. Mrs. Desai opens the Daily Trip, finds the KL-07 trip, and changes its status to Cancelled with the remark "Flat tyre — bus in workshop." The trip is now Cancelled and will not appear in the active trips list. Mrs. Desai must arrange an alternative — either using a spare bus or combining KL-07's route with another bus.

**Bulk Updating Start Times for Afternoon Drop**
The school has changed the afternoon dismissal time from 2:30 PM to 3:00 PM. All afternoon Drop trips need to start at 3:00 PM instead of 2:30 PM. Mrs. Desai filters the Daily Trip by shift (Afternoon), selects all trips, clicks Bulk Update, changes the start time to 3:00 PM, and clicks Save. All selected trips now show a start time of 3:00 PM.

**Adding a Remark to a Trip**
After the morning pickup, Driver Anita reports that there was heavy traffic on Hosur Road and the bus arrived 15 minutes late. Mrs. Desai opens the trip for Anita's route, clicks on the remarks field, and types "Heavy traffic on Hosur Road — arrived 15 minutes late." The remark is saved inline without opening the full edit form.

**Approving Completed Trips at End of Day**
At 5:00 PM, Mrs. Desai reviews the day's completed trips. She selects all trips that ran without issues and clicks Approve. The system marks them as approved. She notices that one trip (Bus KL-09, Route R-12) has no ending odometer reading recorded. She leaves that trip unapproved and asks the driver for the reading the next day.

---

## Example Scenario

Green Valley School operates 12 buses across 15 routes, with two shifts per day (Morning Pickup and Afternoon Drop). The Daily Trip screen is the command centre for the entire transport operation.

On Monday, October 5th, the system shows 30 trips — 15 for the morning Pickup shift and 15 for the afternoon Drop shift. All are Scheduled.

- 6:55 AM — Mrs. Desai starts the first trip (KL-05, Route R-07). Status changes to Ongoing.
- 7:00 AM to 8:45 AM — One by one, all 15 morning trips are started. Buses depart and return.
- 8:45 AM to 9:30 AM — All 15 morning trips are completed. Mrs. Desai records end times and odometer readings.
- 2:30 PM to 4:30 PM — The same process repeats for the afternoon Drop trips.
- 5:00 PM — Mrs. Desai reviews all completed trips. 28 trips are completed without issues. 2 trips are marked as having minor delays. She approves the 28 clean trips. The 2 with delays are left unapproved pending review.

At the end of the day, Mrs. Desai can see a complete picture of the day's operations — which buses ran, which routes were covered, how long each trip took, and how much distance was covered.

---

## Related Screens

- **Route Scheduler** — Trips are created from schedule entries. The Route Scheduler is where Mrs. Desai prepares the daily schedule before creating trips.
- **Driver/Vehicle Roster** — The roster defines the standing driver-vehicle-route assignments used to create schedule entries and trips.
- **Vehicle Master** — Vehicle details such as fitness certificate and insurance expiry dates are referenced during compliance checks when trips are created.
- **Personnel / Staff Records** — Driver details such as driving licence expiry are referenced during compliance checks.
- **Fuel Log** — Fuel readings from trips can be cross-referenced with fuel log entries to verify consumption.

---

## Requirements

- Table: `tpt_trip`
- Columns: trip_date, route_scheduler_id, route_id, vehicle_id, driver_id, helper_id, start_time, end_time, start_odometer_reading, end_odometer_reading, start_fuel_reading, end_fuel_reading, status, approved (0/1), approved_by, approved_at, remarks
- Status state machine: Scheduled → Ongoing, Ongoing → Completed, Completed → (locked), Cancelled → (locked)
- Compliance checks on create: driver licence must be valid, vehicle fitness and insurance must be valid on trip_date
- Trip date unique per route_scheduler_id
- Bulk update: start/end times, vehicle, driver
- Bulk approve / unapprove
- Inline remarks editing
- Soft deletes supported

---

## Who Can Access

- **Transport Manager (Mrs. Desai)** — Full control. She can create trips, change status (following the allowed transitions), edit all fields, perform bulk updates, approve/unapprove trips, soft-delete, restore, and permanently delete trips.

- **Fleet Supervisor** — Can view all trips and update basic fields such as start/end times and odometer readings. Can change trip status from Scheduled to Ongoing and Ongoing to Completed. Cannot approve trips, delete trips, or perform bulk operations.

- **School Administrator** — Read-only access. Can view the list of trips, filter by date and status, and see all trip details. Cannot create, edit, approve, or delete any trips.

- **Driver** — Can view their assigned trips for the day. Can see the route, vehicle, and scheduled times. Cannot edit any fields or change status.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When Mrs. Desai opens the Daily Trip tab, the system loads today's trips from the database — 10 per page — along with each trip's linked route, vehicle, driver, and helper information. The list shows the trip date, route name, vehicle registration number, driver name, helper name (if any), start time, end time, status badge, and approval badge.

When Mrs. Desai changes the date filter, the system reloads trips for the selected date.

When Mrs. Desai opens a trip to change its status from Scheduled to Ongoing, a form appears asking for the start time and starting odometer reading (optional). She enters the values and saves. The system checks that the current status is Scheduled — if it is not (for example, if someone else already changed it to Ongoing), the system shows an error. If the status is correct, it changes the trip to Ongoing and records the start time and odometer reading.

When Mrs. Desai changes the status from Ongoing to Completed, a similar form appears for the end time and ending odometer reading. The same status check is performed.

When Mrs. Desai clicks Cancel, a confirmation dialog appears: "Are you sure you want to cancel this trip? This action cannot be undone." She confirms, enters an optional remark explaining why, and the trip status changes to Cancelled. The trip is now locked and cannot be changed to any other status.

When Mrs. Desai selects multiple trips and clicks Bulk Update, a form appears with editable fields for start time, end time, vehicle, and driver. She changes the fields she wants to update and saves. The system updates all selected trips, but only for the fields that were changed — fields left blank are not overwritten.

When a trip is created (either through the Route Scheduler or individually), the system performs compliance checks. It looks up the driver's driving licence expiry date from the personnel records and compares it against the trip date. It looks up the vehicle's fitness certificate and insurance expiry dates from the vehicle records. If any of these dates are before the trip date, the system prevents the trip from being created and shows an error message: "Trip cannot be created. [Driver name]'s driving licence expired on [date]. Please renew before scheduling trips after this date." or "Trip cannot be created. [Vehicle]'s insurance expired on [date]. Please renew before scheduling trips after this date."

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Trip Date | Must be a valid date | "Please enter a valid trip date." |
| Route Schedule | Must be linked to a valid schedule entry | "Please select a valid schedule entry." |
| Vehicle | Must be selected and must be an active vehicle | "Please select a vehicle." |
| Driver | Must be selected and must be a valid staff member | "Please select a driver." |
| Driver Licence Validity | Driver's driving licence must be valid on the trip date | "Trip cannot be created. [Driver]'s driving licence expired on [date]." |
| Vehicle Fitness Validity | Vehicle's fitness certificate must be valid on the trip date | "Trip cannot be created. [Vehicle]'s fitness certificate expired on [date]." |
| Vehicle Insurance Validity | Vehicle's insurance must be valid on the trip date | "Trip cannot be created. [Vehicle]'s insurance expired on [date]." |
| Unique Trip per Schedule | No existing trip for the same route schedule entry and date | "A trip already exists for this schedule entry." |
| Start Time (when starting trip) | Must be a valid time | "Please enter a valid start time." |
| End Time (when completing trip) | Must be a valid time, must be after start time | "End time must be after start time." |
| Status Transition | Scheduled → Ongoing or Ongoing → Completed only | "Trip status cannot be changed from [current] to [new]." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Attempting to change Completed trip to Scheduled | "Trip status cannot be changed from Completed to Scheduled." — the action is blocked | Status violation |
| Attempting to change Cancelled trip to Ongoing | "Trip status cannot be changed from Cancelled to Ongoing." — the action is blocked | Status violation |
| Driver's licence expired | "Trip cannot be created. Driver Rajesh's driving licence expired on June 30th, 2025." — the trip is not created | Compliance failure |
| Vehicle's insurance expired | "Trip cannot be created. Vehicle KL-05's insurance expired on March 15th, 2025." — the trip is not created | Compliance failure |
| Vehicle's fitness certificate expired | "Trip cannot be created. Vehicle KL-05's fitness certificate expired on August 20th, 2025." — the trip is not created | Compliance failure |
| Route schedule entry not found | "The selected schedule entry was not found." | Data integrity error |
| Bulk update with no trips selected | "Please select at least one trip to update." | User error |
| User tries to approve without permission | System shows "Access Denied" | Permission error |
| End time entered before start time | "End time must be after start time." — the form blocks submission | Data entry error |
| Trip already exists for this schedule entry | "A trip already exists for this schedule entry." — the trip is not created | Duplicate prevention |

---

## Success Scenarios — When Everything Works

**SC-001 — A Full Day of Smooth Operations**
On Monday, October 5th, 30 trips are created from the Route Scheduler. All compliance checks pass — every driver's licence is valid, every vehicle's fitness and insurance are current. Mrs. Desai starts all 15 morning trips between 6:55 AM and 7:10 AM, each one changing from Scheduled to Ongoing. All 15 trips complete between 8:45 AM and 9:30 AM, changing from Ongoing to Completed. The afternoon Drop trips start at 2:30 PM and complete by 4:30 PM. At 5:00 PM, Mrs. Desai approves all 30 trips. The day's operations are fully recorded and verified.

**SC-002 — Compliance Check Prevents an Invalid Trip**
On November 1st, a new trip is being created for Route R-15. The system checks the assigned driver's licence and finds that it expired on October 15th. The system blocks the trip creation and shows: "Trip cannot be created. Driver Venkatesh's driving licence expired on October 15th, 2025." Mrs. Desai assigns a different driver whose licence is valid, and the trip is created successfully. Without this check, an unlicensed driver would have been on the road.

**SC-003 — Bulk Approving a Week's Trips**
At the end of the week, Mrs. Desai has 150 completed trips (30 per day × 5 days). She filters by status "Completed" and selects all trips that ran without issues — 148 out of 150. She clicks Bulk Approve and confirms. The 148 trips are marked as approved. The remaining 2 trips (one with a missing odometer reading and one with a delay report) remain unapproved for further review.

**SC-004 — Correcting a Trip After Completion**
Mrs. Desai notices that the ending odometer reading for Bus KL-09's morning trip was entered as 1,26,000 km but should have been 1,26,500 km. She opens the completed trip, corrects the odometer reading, and saves. The system accepts the change even though the trip is Completed — trip details (readings, times, remarks) can be edited after completion. Only the status is locked.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Compliance Check Missed When Trip Is Created from Scheduler**
Mrs. Desai uses the Route Scheduler's "Create Trip" button to generate trips for Monday. The system should check driver licence and vehicle fitness/insurance for every trip being created. If the compliance check is not implemented or is bypassed, a trip could be created with a driver whose licence expired last week. On Monday morning, the driver takes the bus out, and the school is operating a vehicle with an unlicensed driver — a legal and safety violation.

**FC-002 — Status Changed by Two People Simultaneously**
Mrs. Desai opens the Daily Trip screen and starts Trip KL-05 — the status changes to Ongoing. At the same moment, the Fleet Supervisor (who also has permission to start trips) opens the same trip and starts it. Both actions succeed because the system does not check whether the status has already been changed. The trip ends up with two start times recorded, and the activity log shows two "Started" events. The driver is confused but the trip proceeds. The duplicate start event creates confusion in the audit trail.

**FC-003 — Trip Approved Without Verifying Odometer Readings**
Mrs. Desai bulk-approves all completed trips at the end of the day without checking whether all required readings were filled in. One trip (Bus KL-09) has no ending odometer reading. The trip is approved despite missing critical data. When the monthly mileage report is run, KL-09's data is incomplete, and the school cannot calculate fuel efficiency for that bus on that day. The system does not require odometer readings before approval.

**FC-004 — Bulk Update Accidentally Overwrites Correct Data**
Mrs. Desai selects all morning trips and uses Bulk Update to change the driver. She intends to change only one trip (where the driver is absent) but forgets to deselect the other trips. All 15 morning trips now show the same driver. On the morning of the trip, 15 drivers show up for 15 different routes, but the system shows the same driver for all of them. Mass confusion ensues. The bulk update form should ideally show a preview of changes before saving, but it does not.

**FC-005 — Trip Cancelled Without Notifying Affected Parties**
Bus KL-07's afternoon Drop trip is cancelled due to a breakdown. Mrs. Desai changes the status to Cancelled and adds a remark. However, the system does not automatically notify the parents of students who ride KL-07, the school office, or the driver. Parents wait at the pickup stops for a bus that never arrives. The school receives several angry phone calls before Mrs. Desai can manually call the affected families.

---

(End of file)
