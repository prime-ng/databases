# Stopage Details — Business Requirements

## What This Screen Does

The Stopage Details screen shows a table-based view of every stop on a trip with its scheduled and actual arrival and departure times. Unlike the interactive timeline in the Stopage Status Update tab, this screen is designed for preparation and review — it allows the Transport Manager to prepare stop details in advance by copying stops from the route definition into the trip, and to make corrections to recorded times after the trip is completed.

This screen is the administrative counterpart to the driver-facing timeline. While the driver uses the timeline to record events in real time, the Transport Manager uses this screen to ensure that all stop data is correctly populated before the trip begins, and to audit or correct stop times after the trip ends.

The screen appears as one tab within the Trip Management hub, loaded by the `TripMgmtController`.

---

## Default Data Load

When the user opens Trip Management and clicks the Stopage Details tab, the system shows a trip selection filter. After the user selects a specific trip (by date, route, and shift), the system loads all stop detail records for that trip in ordinal sequence. Each row in the table shows the stop name, scheduled arrival time, scheduled departure time, actual arrival time, actual departure time, any emergency badge, remarks, and action buttons.

If no stop details have been prepared yet for the selected trip, the table is empty and a "Prepare Stop Details" button is prominently displayed.

---

## When This Screen Is Used

- **Preparing Stop Details Before a Trip** — Before the morning trips begin, the Transport Manager selects each trip for the day and clicks "Prepare Stop Details." The system copies all stops from the route definition into the trip's stop detail records, complete with scheduled arrival and departure times calculated from the route data. This ensures that when the driver opens the Stopage Status tab, all stops are already visible with their correct scheduled times.

- **Correcting a Recorded Arrival Time** — After a trip is completed, the Transport Manager reviews the stop details and notices that the driver marked the third stop as "Reached" at 7:08 AM, but CCTV footage shows the bus actually arrived at 7:10 AM. The manager edits the actual arrival time to 7:10 AM and adds a remark: "Corrected based on CCTV review."

- **Investigating a Delay** — A parent complains that the bus was 15 minutes late at their child's stop. The Transport Manager opens the Stopage Details tab for that trip, compares the scheduled arrival time (7:02 AM) against the actual arrival time (7:17 AM), and sees that the driver marked the stop as "Delayed." The manager investigates further by checking the previous stop's departure time to understand where the delay originated.

- **Adding Emergency Remarks After the Fact** — A driver flagged an emergency at a stop but did not enter a detailed description at the time. The Transport Manager edits the stop detail and adds the full description based on a conversation with the driver.

---

## Key Fields at a Glance

**Stop Identity and Sequence**
Each row in the table represents one stop on the trip's route, displayed in ordinal sequence. The stop name (e.g., "Indiranagar Main Road") identifies the location, and the ordinal number (Stop 3 of 6) shows its position in the route.

**Scheduled vs Actual Times**
Four time columns are displayed side by side for easy comparison:
- Scheduled Arrival: The time the bus was expected to arrive (from route definition)
- Scheduled Departure: The time the bus was expected to leave
- Actual Arrival: The time the driver actually marked "Reached" (or manually corrected)
- Actual Departure: The time the driver actually marked "Leave" (or manually corrected)

This side-by-side view makes it immediately obvious whether the trip ran on schedule and where delays occurred.

**Emergency Indicators**
If an emergency was flagged at a stop, a red badge or indicator is displayed alongside the stop name. The emergency description and the time it was flagged are visible in the detail view.

**Action Buttons**
Each row shows action buttons based on the record's state:
- Edit: Allows correcting times, emergency flags, and remarks
- The "Prepare Stop Details" button at the top copies stops from the route definition

---

## Business Rules and Conditions

**Prepare Copies Stops from Route Definition**
The "Prepare Stop Details" functionality fetches all PickupPointRoute entries for the trip's route and shift combination. It converts the arrival_time and departure_time from the route definition (stored as minutes from route start, e.g., 15 minutes) into absolute datetime values (e.g., 7:15 AM) based on the trip's start time. It creates TptTripStopDetail records for each stop. If some stop records already exist for this trip, those are skipped — only missing stops are added.

**Scheduled Times Are Read-Only**
The scheduled arrival and departure times come from the route definition and cannot be edited in this screen. Only the actual times (reaching_time, leaving_time) can be modified.

**Emergency Flags Can Be Cleared**
If an emergency was flagged in error, an authorised user can clear the emergency flag and remove the red badge by editing the stop detail record.

**Change Tracking**
Every edit to a stop detail record — whether it is a time correction, emergency flag change, or remark update — is recorded in the activity log with the old and new values.

---

## Workflow Steps

**Preparing Stop Details for the Day's Trips**
It is 6:00 AM. Mrs. Desai opens the Trip Management hub and clicks the Stopage Details tab. She selects the MG Road Morning Pickup route for today's date. The table is empty — no stop details have been prepared yet. She clicks "Prepare Stop Details." The system copies all 6 stops from the route definition into the trip's stop detail records, calculating each stop's scheduled arrival and departure times based on the route's timing data. Within seconds, all 6 stops appear in the table with their scheduled times. Mrs. Desai verifies that the times look correct. When Driver Venkatesh later opens the Stopage Status tab, all stops will already be populated and ready for action.

**Correcting a Recorded Arrival Time After the Trip**
After the trip is completed, Mrs. Desai reviews the stop details. She notices that Stop 3 (MG Road Signal) shows an actual arrival time of 7:08 AM, but the scheduled arrival was 7:02 AM — a 6-minute delay. The system already marked this as "Delayed." Mrs. Desai clicks Edit on that stop. She sees that the actual arrival time is 7:08 AM, which matches the driver's recording. She leaves it unchanged but adds a remark: "Delay due to traffic at the MG Road intersection — construction work in progress." She saves the change.

**Clearing a False Emergency Flag**
A driver accidentally tapped "Emergency" at a stop and then realised it was a false alarm. Mrs. Desai opens the stop detail, sees the red emergency badge, clicks Edit, clears the emergency flag, and adds a remark: "False alarm — driver accidentally triggered emergency button." The stop returns to normal green status, but the incident record in the Trip Incidents tab remains for audit purposes.

---

## Example Scenario

Green Valley School runs 12 morning pickup trips every day. Each trip has between 4 and 8 stops. To ensure smooth operations, the Transport Manager, Mrs. Desai, prepares stop details for all 12 trips every morning before 6:30 AM.

She opens the Stopage Details tab and selects the first trip: MG Road Morning Pickup (Trip #TRP-00042). The table is empty. She clicks "Prepare Stop Details." The system creates 6 stop records with scheduled times:

| Stop | Scheduled Arrival | Scheduled Departure |
|------|------------------|-------------------|
| School Depot | 6:45 AM | 6:45 AM |
| Indiranagar Main Road | 6:54 AM | 6:56 AM |
| MG Road Signal | 7:02 AM | 7:04 AM |
| Church Street | 7:10 AM | 7:12 AM |
| Brigade Road | 7:18 AM | 7:20 AM |
| Green Valley School | 7:30 AM | — |

She repeats this for all 12 trips. By 6:30 AM, all stop details are ready. The drivers can now open the Stopage Status tab and see their stops pre-populated with accurate scheduled times.

After the trips are completed, Mrs. Desai reviews each trip's actual times against the schedules. For Trip #TRP-00042, she sees that all stops were on time except MG Road Signal, which had a 6-minute delay. She adds a remark about the road construction. The record is now complete and ready for the daily operations report.

---

## Related Screens

- **Stopage Status Update** — The live interactive timeline where drivers record stop events. The data prepared in this screen feeds directly into the timeline.
- **Daily Trip** — The parent trip record that these stop details belong to. Each trip's stop details are visible here.
- **Trip Incidents** — Any emergency flagged on a stop creates an incident record in this tab.

---

## Requirements

- Controller actions: `TripMgmtController@tripStopNew()` (loads data), `TripController@stopDetailsPrepare()` (prepare stops), `TripController@tripDetailsData()` (single record), `TripController@tripDetailsUpdated()` (update record)
- Model: `TptTripStopDetail` (table: `tpt_trip_stop_detail`) — SoftDeletes
- Prepare logic: Fetches PickupPointRoute entries, converts minutes to datetime, batch inserts skipping duplicates
- Permissions: `tenant.stop-details.prepare` (view), `tenant.stop-details.prepare.create` (prepare), `tenant.stop-details.prepare.edit` (edit)
- Activity logging: ✅ Present on create and update of stop details

---

## Who Can Access

- **Transport Manager** — Full access. Can prepare stop details for any trip, edit actual times and remarks, and clear emergency flags. This is the primary user of this administrative screen.

- **Fleet Supervisor** — Can view stop details and edit remarks, but cannot prepare new stop details or clear emergency flags.

- **School Administrator** — Read-only access to view scheduled vs actual times for audit and reporting.

- **Driver** — Does not use this screen. Drivers use the Stopage Status Update tab for their live timeline view.

Behind the scenes, each action is protected by a permission check.

---

## Logic Flow

When the user opens the Stopage Details tab and selects a trip, the system queries the TptTripStopDetail table for all records linked to that trip, ordered by ordinal. Each record is loaded with its related stop information (stop name, code). If no records exist, the table is empty and the "Prepare Stop Details" button appears.

When the user clicks "Prepare Stop Details," the system first fetches all PickupPointRoute entries for the trip's route and shift, ordered by ordinal. For each entry, it checks whether a TptTripStopDetail record already exists for this trip and stop combination. If a record exists, it is skipped. If not, the system converts the arrival_time and departure_time from the route definition (stored as minutes from route start, e.g., 15 means 15 minutes after the route starts) into absolute datetime values by adding the minutes to the trip's start time. All new records are created in a single database transaction to ensure atomicity — either all stops are prepared or none are.

After preparation, the table reloads showing all stop detail records with their scheduled times. The actual arrival and departure columns are empty, waiting for the driver to populate them during the trip.

When the user clicks Edit on a specific stop, a form opens showing all editable fields: actual arrival time, actual departure time, emergency flag, emergency remarks, and general remarks. The scheduled times are displayed but greyed out — they cannot be changed. After the user saves, the system validates the data, updates the record, and logs the changes in the activity log with the old and new values for each modified field.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Actual Arrival Time | Must be a valid datetime | "Please enter a valid arrival time." |
| Actual Departure Time | Must be a valid datetime | "Please enter a valid departure time." |
| Emergency Flag | Must be Yes or No | "Please select a valid emergency status." |
| Emergency Remarks | Required if emergency flag is Yes | "Please describe the emergency." |
| Remarks | Optional — free text up to 512 characters | — |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Prepare clicked but no route definition exists | "No stops found for this route. Please define stops in the Assign Stops to Route screen first." | Business rule — stops must be defined first |
| Prepare clicked but trip already has all stops | The system silently skips duplicates — no error shown | Expected behaviour |
| User tries to edit a non-existent stop detail | "Stop detail not found." — record may have been deleted | Data error |
| Invalid datetime format entered | "Please enter a valid date and time." — form blocks | Data entry error |
| User tries to edit with expired permission | "Access Denied." — system blocks the action | Permission error |
| Prepare fails due to database error | "Could not prepare stop details. Please try again." | Technical error — no partial data saved |

---

## Success Scenarios — When Everything Works

**SC-001 — Preparing Stop Details for All Morning Trips**
Mrs. Desai prepares stop details for all 12 morning trips in under 5 minutes. For each trip, she selects the route and clicks "Prepare." The system copies all stops from each route definition, calculates accurate scheduled times, and displays the completed tables. All 12 trips now have their stop details ready for the drivers.

**SC-002 — Correcting an Incorrectly Recorded Arrival Time**
After reviewing CCTV footage, Mrs. Desai realises that Bus KL-07 actually arrived at Church Street at 7:15 AM, not 7:12 AM as the driver recorded. She opens the stop detail, changes the actual arrival time to 7:15 AM, and adds a remark: "Corrected based on CCTV footage — driver recorded early." The activity log records the change. The corrected data now accurately reflects the actual trip timeline.

**SC-003 — Clearing a False Emergency Flag**
A driver accidentally pressed the Emergency button while trying to tap "Reached." Mrs. Desai opens the stop detail, clears the emergency flag, and notes "False alarm — accidental button press." The stop's red badge disappears from the timeline, but the incident record remains for audit purposes. The activity log records the correction.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Prepare Stop Details Fails Silently for Some Trips**
Mrs. Desai clicks "Prepare" for a trip, and the system shows a success message. However, due to a database constraint or timeout, only 4 of the 6 stops were actually created. The table shows 4 stops instead of 6. There is no validation to confirm that the expected number of stops matches the actual number created. Mrs. Desai does not notice the missing stops until the driver reports that two stops are missing from the timeline during the trip.

**FC-002 — Scheduled Times Incorrect After Route Timing Change**
The Transport Manager changes the arrival time for a stop in the Assign Stops to Route screen, but this change does not retroactively update already-prepared stop details in existing trips. The prepared stop details still show the old scheduled time. The driver sees one time on the route definition and a different time on the trip timeline, causing confusion.

**FC-003 — Edited Time Not Reflected in Reports**
Mrs. Desai corrects a stop's actual arrival time from 7:08 AM to 7:15 AM based on CCTV evidence. However, the corrected time is only updated in the stop detail record — the parent notification that was already sent at 7:08 AM says "Bus reached at 7:08 AM." There is no mechanism to send a correction notification to parents when stop times are edited retroactively.