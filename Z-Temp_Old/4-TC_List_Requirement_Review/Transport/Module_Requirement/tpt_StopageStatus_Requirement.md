# Stopage Status Update — Business Requirements

## What This Screen Does

The Stopage Status Update screen is a live, interactive timeline that shows every stop on a trip in the order the bus visits them. For each stop, the driver (or the Transport Manager on a desktop) can mark the bus as having Reached the stop, Left the stop, or flagged an Emergency. The first stop on the route serves as the trip's starting point — marking it as Reached also records the bus's starting odometer and fuel readings and changes the trip status from Scheduled to Ongoing. The last stop on the route serves as the trip's ending point — marking it as Left records the ending odometer and fuel readings and completes the trip.

Without this screen, there would be no way to know in real time where a school bus is, whether it is running on schedule, or whether it has encountered an emergency. Parents would not receive notifications about the bus approaching their child's stop, and the Transport Manager would have no visibility into whether drivers are following their assigned routes.

The screen appears as one tab within the Trip Management hub, loaded by the `TripMgmtController`.

---

## Default Data Load

When the user opens Trip Management and clicks the Stopage Status Update tab, the system first shows a set of filter controls: shift, route, and direction (Pickup or Drop). After the user selects these filters, the system loads all stops for the selected route in ordinal sequence, along with any existing trip stop detail records. Each stop is displayed as a card or row on a vertical timeline, colour-coded by its current status: upcoming stops in grey, the current actionable stop in blue, completed stops in green, and any stop with an emergency flag in red.

If the user is logged in as a driver, the system automatically restricts the view to only the routes assigned to that driver for the current date.

---

## When This Screen Is Used

- **Starting the Morning Trip** — Driver Venkatesh arrives at the depot at 6:45 AM and opens the Stopage Status tab on his mobile device. The system shows his assigned route with all 6 stops in order. He taps "Start Trip" on the first stop (the depot). The system asks for the starting odometer reading (1,25,340 km) and fuel level (75%). He enters both and confirms. The trip status changes from Scheduled to Ongoing. The system sends a "TripStart" notification to all parents whose children are on this route.

- **Marking a Stop as Reached** — Venkatesh arrives at the second stop — Indiranagar Main Road. He taps "Reached" on that stop. The system records the reaching time. If he arrived more than 5 minutes past the scheduled arrival time, the system sends a "Delayed" notification to parents instead of a normal "ReachedStop" notification. He opens the bus door, students board, and when everyone is seated, he taps "Leave" to mark his departure.

- **Flagging an Emergency** — At the third stop, a student reports feeling unwell and needs immediate medical attention. Venkatesh taps the "Emergency" button on that stop. The system immediately changes the stop's colour to red, creates an incident record in the Trip Incidents tab with severity MEDIUM and type "Stop Emergency," and alerts the Transport Manager through the dashboard. Venkatesh enters a brief description: "Student unwell — fever and vomiting — parents contacted."

- **Ending the Trip at School** — The bus reaches the school (the last stop on the route). Venkatesh taps "End Trip." The system asks for the ending odometer reading (1,25,890 km) and fuel level (60%). He enters both and confirms. The trip status changes from Ongoing to Completed. The system sends notifications to parents that their children have arrived at school safely.

---

## Key Fields at a Glance

**Stop Information**
Each stop on the timeline shows the stop name (e.g., "Indiranagar Main Road"), its ordinal position on the route (Stop 2 of 6), and the scheduled arrival and departure times. For completed stops, the actual reaching and leaving times are displayed alongside the scheduled times so the driver or manager can see whether the trip is running on schedule.

**Action Buttons**
The current actionable stop shows action buttons appropriate to its position:
- **First stop**: "Start Trip" — records starting odometer and fuel, changes trip to Ongoing
- **Middle stops**: "Reached" and "Leave" — marks arrival and departure timestamps
- **Last stop**: "End Trip" — records ending odometer and fuel, completes the trip
- **Any stop**: "Emergency" — creates an incident record

**Timeline Status Colours**
The entire timeline is colour-coded for quick visual scanning:
- Grey: Upcoming stops that the bus has not yet reached
- Blue: The current stop that is actionable right now
- Green: Stops that have been completed (Reached and Left)
- Red: Stops where an emergency has been flagged

**New Stop Creation**
If a trip does not yet have stop details (because they were not prepared in advance), the system automatically creates the stop detail records on the fly when the driver performs an action. The scheduled times are copied from the route definition.

---

## Business Rules and Conditions

**Stops Must Be Processed in Order**
Only one stop is actionable at a time — the next un-reached stop in the ordinal sequence. The driver cannot skip a stop or mark stop 4 as Reached before stop 3. This ensures that the bus follows the route in the correct order.

**First Stop Starts the Trip**
When the driver marks the first stop as Reached, the system treats this as the trip start. It records the starting odometer and fuel readings (which the driver must enter) and changes the trip status from "Scheduled" to "Ongoing." The departure from the first stop is also recorded automatically — the bus has left the depot.

**Last Stop Ends the Trip**
When the driver marks the last stop as Left (or taps "End Trip"), the system records the ending odometer and fuel readings and changes the trip status from "Ongoing" to "Completed." Once completed, the trip status cannot be changed back.

**Late Stop Detection**
If the driver reaches a stop more than 5 minutes after the scheduled arrival time, the system generates a "Delayed" notification instead of a normal "ReachedStop" notification. This alert is sent through the Notification Log and can be used to inform parents that the bus is running late.

**Emergency Creates an Incident Automatically**
Tapping the Emergency button on any stop immediately creates an incident record in the Trip Incidents tab with type "Stop Emergency" (0), severity "MEDIUM," and status "OPEN." The driver's description is captured as the incident description. The stop's emergency flag is set to 1.

**Stop Details Are Auto-Created If Missing**
If the trip does not have pre-prepared stop detail records (from the Stopage Details tab), the system creates them when the driver performs the first action. It copies the scheduled arrival/departure times from the route's stop assignment (PickupPointRoute) and creates the records automatically.

---

## Workflow Steps

**Starting a Trip from the Depot**
Driver Venkatesh is at the depot with Bus KL-05. He opens the Stopage Status tab. The system shows his route with 6 stops. The first stop "School Depot" is highlighted in blue — the current actionable stop. He taps "Start Trip." A small dialog asks for the starting odometer reading and fuel level. He enters 1,25,340 km and 75%. The system records these values, sets the trip status to Ongoing, and logs the start. The first stop turns green. The second stop "Indiranagar Main Road" now turns blue as the next actionable stop.

**Completing a Trip at the School**
Venkatesh reaches the last stop "Green Valley School Main Gate." This is the final stop on the route. Instead of a "Reached" button, he sees an "End Trip" button. He taps it. The system asks for ending odometer and fuel readings. He enters 1,25,890 km and 60%. The trip status changes to Completed. All stops on the timeline are now green. The system sends arrival notifications to parents.

**Handling an Emergency Mid-Route**
At "MG Road Signal" (Stop 3 of 6), a student feels unwell. Venkatesh taps the "Emergency" button. The stop card turns red. A text box appears for him to describe the issue: "Student unwell — fever and vomiting — parents informed." He submits. An incident record is created in the Trip Incidents tab. The Transport Manager sees the red flag on the dashboard. The stop remains actionable — Venkatesh can still mark Reached and Leave after the emergency is handled.

---

## Example Scenario

Green Valley School operates 12 bus routes daily. Bus KL-05 follows the MG Road Morning Pickup route with 6 stops: School Depot (Start), Indiranagar Main Road, MG Road Signal, Church Street, Brigade Road, and Green Valley School (End).

At 6:45 AM, Driver Venkatesh opens the Stopage Status tab. The timeline shows all 6 stops in order. Stop 1 (School Depot) is blue — actionable. He taps "Start Trip," enters odometer 1,25,340 km and fuel 75%, and confirms. The trip is now Ongoing.

At 6:52 AM, Venkatesh reaches Indiranagar Main Road (2 minutes early — scheduled for 6:54 AM). He taps "Reached." The system records the time and sends a "ReachedStop" notification. Students board. At 6:55 AM, he taps "Leave."

At 7:08 AM, Venkatesh reaches MG Road Signal (scheduled 7:02 AM — 6 minutes late). He taps "Reached." The system detects the 6-minute delay and sends a "Delayed" notification instead of "ReachedStop." Parents whose children board at this stop receive a "Bus is running 6 minutes late" alert.

At 7:30 AM, Venkatesh reaches Green Valley School (the last stop). The system shows "End Trip" instead of "Reached." He taps it, enters ending odometer 1,25,890 km and fuel 60%, and confirms. The trip status changes to Completed. All stops are green. Parents receive "Your child has arrived at school" notifications.

---

## Related Screens

- **Stopage Details** — The tab where stop details can be pre-prepared before the trip starts. This tab shows the same data but in a live actionable timeline format.
- **Trip Incidents** — Any emergency flagged on a stop appears here as an incident record.
- **Notification Log** — All TripStart, ReachedStop, Delayed, and ApproachingStop notifications generated during the trip are recorded here.
- **Daily Trip** — The trip status (Scheduled/Ongoing/Completed) is updated by actions performed in this screen.

---

## Requirements

- Controller actions: `TripMgmtController@tripStopTimeline()` (loads data), `TripController@stopAction()` (handles start_trip/reach/leave/end_trip/emergency)
- Model: `TptTripStopDetail` (table: `tpt_trip_stop_detail`) — SoftDeletes
- Notifications: `TptNotificationLog` records created on each action
- Trip update: `TptTrip` status updated on start and end
- Permissions: `tenant.stop-details.viewAny`, `tenant.stop-details.update`
- Activity logging: ✅ Present on stop detail creation and updates

---

## Who Can Access

- **Driver** — The primary user of this screen. Drivers use it to start trips, mark stops, and flag emergencies. They can only see routes assigned to them for the current date.

- **Transport Manager** — Can view the live status of any trip in the fleet, monitor delays, and respond to emergencies. They can also perform stop actions on behalf of a driver if needed.

- **Fleet Supervisor** — Can view live trip timelines to monitor fleet progress but cannot perform stop actions.

- **School Administrator** — Read-only access to view trip timelines for operational oversight.

Behind the scenes, each action is protected by a permission check. If an unauthorised user tries to perform an action, the system displays an "Access Denied" message.

---

## Logic Flow

When the user opens the Stopage Status Update tab, the system first checks whether the user is a driver or an admin. If the user is a driver, it automatically finds all routes assigned to that driver for today's date. If the user is an admin, it shows filter controls to select a shift, route, and direction.

Once the route is selected, the system loads all stops for that route in ordinal order from the route definition table. For each stop, it checks whether a trip stop detail record already exists in the database. If a record exists, it loads the actual reaching/leaving times, emergency flags, and current status. If no record exists yet, the stop is shown as "upcoming" with grey colour and no actual times.

The system then identifies which stop is currently actionable — this is the first stop in the sequence that has not yet been marked as Reached. That stop is highlighted in blue with action buttons visible. All stops before it are shown in green (completed). All stops after it are shown in grey (upcoming).

When the driver taps a button (Start Trip, Reached, Leave, Emergency, or End Trip), the system validates the action based on the stop's position:
- Start Trip: Only allowed on the first stop. Requires odometer and fuel input. Sets trip to Ongoing.
- Reached: Only allowed if the previous stop has been completed. Records reaching time. If late (>5 min), sets delayed flag.
- Leave: Only allowed after Reached. Records leaving time.
- End Trip: Only allowed on the last stop after it has been reached. Requires odometer and fuel input. Sets trip to Completed.
- Emergency: Allowed on any stop at any time. Creates incident record.

After each action, the system creates a notification log entry and refreshes the timeline to show the updated state.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Starting Odometer (Start Trip) | Must be a valid number | "Please enter the starting odometer reading." |
| Starting Fuel (Start Trip) | Must be a valid percentage | "Please enter the fuel level." |
| Ending Odometer (End Trip) | Must be a valid number | "Please enter the ending odometer reading." |
| Ending Fuel (End Trip) | Must be a valid percentage | "Please enter the ending fuel level." |
| Emergency Description | Must be provided when flagging emergency | "Please describe the emergency." |
| Stop Action Order | Must follow the sequence — cannot skip stops | "Please complete the previous stop first." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Driver tries to skip a stop | "Please complete the previous stop first." — the action is blocked | Sequence validation |
| Driver tries to start a trip that is already Ongoing | The system prevents the action — trip status check | State validation |
| Driver tries to mark a stop after trip is Completed | The system prevents the action — trip is already ended | State validation |
| Odometer reading entered as text | "Please enter a valid number." — form blocks | Data entry error |
| Emergency flagged without description | "Please describe the emergency." — form blocks | Validation |
| Network failure during stop action | The action may not be recorded — driver may need to retry | Technical error |
| Two drivers try to act on the same stop simultaneously | The first save wins; the second gets an error | Concurrency gap |
| Driver marks Reached but forgets to mark Leave | The stop stays in "Reached" state and the next stop cannot be actioned | 🔴 Gap — no automatic leave detection |

---

## Success Scenarios — When Everything Works

**SC-001 — A Perfect On-Time Trip**
Driver Venkatesh completes all 6 stops on the MG Road route without any delays or emergencies. He starts the trip at 6:45 AM, reaches each stop within 2 minutes of the scheduled time, and ends the trip at the school at 7:30 AM. Every stop turns green. Parents receive timely notifications. The activity log records all actions. The trip shows as Completed with accurate odometer readings.

**SC-002 — Handling a Mid-Route Emergency**
A student falls ill at the third stop. Venkatesh taps Emergency, describes the situation, and the system creates an incident record. The Transport Manager sees the alert and contacts the parents. The student is attended to, and the trip continues. The incident is resolved later in the Trip Incidents tab. The stop shows a red emergency badge for audit purposes.

**SC-003 — Late Bus Detection**
Due to unexpected traffic, Venkatesh reaches the fourth stop 8 minutes late. The system detects the delay (>5 minutes), sends "Delayed" notifications to affected parents instead of "ReachedStop," and records the delay in the Notification Log. Parents are informed proactively and adjust their pickup time.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Driver Marks Reached but Forgets to Mark Leave**
Venkatesh reaches Indiranagar Main Road, taps "Reached," and students board. However, he is distracted and drives off without tapping "Leave." The stop remains in "Reached" state. The next stop (MG Road Signal) does not become actionable because the system requires the previous stop to be completed. Venkatesh arrives at MG Road Signal but cannot mark it as Reached — the system blocks him. He must scroll back and mark the previous stop as "Leave" before proceeding.

**FC-002 — Odometer Reading Skipped During Start Trip**
Venkatesh starts the trip but enters "N/A" in the odometer field because the display is dim and he cannot read it. The system accepts text in the odometer field (a validation gap) and records garbage data. Later, when the trip is approved for billing, the distance calculation produces an error because the starting odometer is not a number.

**FC-003 — Network Failure at a Critical Moment**
Venkatesh taps "End Trip" at the last stop, but the mobile network is weak at that location. The request fails silently. Venkatesh assumes the trip was completed and closes the app. The trip remains in "Ongoing" status on the server, and the Transport Manager sees a bus that never completed its route. There is no mechanism to notify the driver that the action failed.

**FC-004 — Emergency Creates Incident But No One Responds**
Venkatesh flags an emergency at a stop. The system creates an incident record in the Trip Incidents tab. However, no notification or alert is sent to the Transport Manager or the school office — the incident sits in the database with OPEN status, waiting for someone to notice it. If nobody checks the Trip Incidents tab, the emergency goes unnoticed.