# Route Scheduler — Business Requirements

## What This Screen Does

The Route Scheduler screen manages the daily schedule of trips — it takes the master assignments from the Driver/Vehicle Roster and creates specific schedule entries for individual dates. Each schedule entry links a date, a shift, a route, a vehicle, a driver, a helper, and whether it is a Pickup or Drop run. Once the schedule entries for a day are ready, the Transport Manager can use the "Create Trip" button to generate actual trips from those entries.

Think of it this way: the Driver/Vehicle Roster says "Driver Rajesh is assigned to Bus KL-05 on Route R-07 for the Morning Pickup shift, effective for the whole academic year." The Route Scheduler says "On Monday, October 5th, Driver Rajesh will drive Bus KL-05 on Route R-07 for the Morning Pickup shift." The roster defines the standing arrangement; the scheduler defines what actually happens on a specific date.

Without this screen, Mrs. Desai would have no way to prepare trips in advance. She would have to create each day's trips one by one on the morning of the trip, scrambling to assign drivers and vehicles at the last minute. The Route Scheduler lets her plan ahead — she can schedule a full week's worth of routes on a Sunday evening, review everything at a glance, and then create all the trips with a single click.

The screen has a "Create Trip" button that generates trips from selected schedule entries. Before creating a trip, the system checks whether a trip already exists for that date and schedule. If a trip already exists, it skips that entry instead of creating a duplicate.

---

## Default Data Load

When Mrs. Desai opens Trip Management and clicks the Route Scheduler tab, the system loads the schedule entries for today's date — 10 per page — showing the scheduled date, shift name, route name, vehicle registration number, driver name, helper name (if any), and pickup/drop type. She can change the date filter to view any other day's schedule.

A search box allows searching by route name or code, vehicle registration number, or driver name. A status filter lets her view Active or Inactive entries.

---

## When This Screen Is Used

- **Planning the Next Day's Schedule** — Every evening at 4:00 PM, Mrs. Desai opens the Route Scheduler to prepare the next day's trips. She sets the date to tomorrow, looks at the Driver/Vehicle Roster to see which drivers are assigned to which routes and vehicles, and creates schedule entries for each combination. She creates entries for all 12 buses — each with the correct driver, vehicle, route, shift, and pickup/drop type — so everything is ready for the morning.

- **Bulk-Creating Trips for the Week** — On Sunday evening, Mrs. Desai schedules all five weekdays at once. She creates schedule entries for Monday through Friday for each route, then selects all the entries for Monday and clicks "Create Trip" to generate Monday's trips. She repeats this for Tuesday through Friday. By Sunday night, all trips for the week are created and ready.

- **Adding a One-Off Trip on a Special Day** — The school has a field trip on Saturday. Mrs. Desai opens the Route Scheduler, sets the date to Saturday, creates a special schedule entry linking the field trip route, the assigned bus, and the driver, and then creates a trip from it. The Saturday trip exists alongside the regular weekday trips without affecting the normal schedule.

- **Checking Whether a Trip Has Been Created** — Mrs. Desai opens the Route Scheduler for a specific date and sees a list of all schedule entries. Next to each entry, an indicator shows whether a trip has already been created for it (green checkmark) or not (grey dash). If she accidentally clicks "Create Trip" again, the system skips entries that already have trips.

---

## Key Fields at a Glance

**Schedule Date**
The specific date for which this schedule entry is created. This is the date the trip will run. Multiple schedule entries can share the same date — for example, all 12 buses running on Monday, October 5th.

**Shift, Route, Vehicle, Driver, and Helper**
These fields copy the same structure from the Driver/Vehicle Roster. Each schedule entry defines who (driver and helper) is driving what (vehicle) where (route) and when (shift and date).

**Pickup/Drop Type**
Whether this schedule entry is for the morning Pickup run or the afternoon Drop run. A full day's schedule typically includes two entries per route — one for Pickup and one for Drop.

**Trip Indicator**
Each schedule entry shows whether a trip has already been created from it. This prevents duplicate trips from being generated when the "Create Trip" button is clicked multiple times.

---

## Business Rules and Conditions

**No Duplicate Schedule Entries**
The system enforces four uniqueness rules to prevent duplicate schedule entries:
1. The same date, shift, and route combination cannot appear twice — you cannot schedule the same route for the same shift on the same date with different settings.
2. The same vehicle, date, and shift combination cannot appear twice — you cannot assign the same bus to two different routes on the same shift and date.
3. The same driver, date, and shift combination cannot appear twice — a driver cannot be in two places at once.
4. The same helper, date, and shift combination cannot appear twice — a helper cannot assist on two different routes simultaneously.

These four rules ensure that every schedule entry is unique across all the key dimensions.

**Trip Creation Skips Existing Trips**
When Mrs. Desai selects entries and clicks "Create Trip," the system checks each entry to see if a trip already exists for that schedule on that date. If a trip exists, the system skips that entry and moves to the next one. It does not warn or ask — it simply does not create a duplicate. This means clicking "Create Trip" multiple times is safe and will never produce duplicate trips.

**Schedule Entries Are Not Automatically Created from the Roster**
The Driver/Vehicle Roster defines standing assignments (for example, "Driver Rajesh drives Bus KL-05 on Route R-07 for the entire academic year"), but the Route Scheduler does not automatically create daily entries from these assignments. Mrs. Desai must manually create schedule entries for each day she wants trips to run. This gives her the flexibility to skip days (holidays, maintenance days) without having to cancel or modify the standing roster.

**Schedule Entries Can Be Soft-Deleted**
If a schedule entry is created for the wrong date or with the wrong details, it can be soft-deleted. The entry is hidden from the active list but retained in the system. It can be restored later if needed.

---

## Workflow Steps

**Creating a Schedule Entry for Tomorrow**
It is 4:00 PM on Sunday. Mrs. Desai opens the Route Scheduler tab and sets the date to Monday, October 5th. She clicks Add Entry. A form appears. She selects the shift (Morning), the route (R-07 — JP Nagar to School), the vehicle (KL-05 — KA-01-EX-1234), the driver (Rajesh), and optionally a helper (Suresh). She sets pickup/drop to "Pickup" and clicks Save. She repeats this for the Afternoon Drop entry for the same route, and for all other routes. By 5:00 PM, she has created 30 entries — 15 routes × 2 shifts (Pickup and Drop) — for Monday.

**Creating Trips from Schedule Entries**
Once all of Monday's schedule entries are created, Mrs. Desai selects all of them using the checkbox at the top of the list and clicks "Create Trip." The system processes each entry. For entries where no trip exists yet, it creates a trip with a "Scheduled" status. For entries that already have trips (none in this case, since this is the first time), it skips them. A confirmation message appears: "24 trips created successfully. 0 skipped."

**Editing a Schedule Entry**
Mrs. Desai notices that she assigned Driver Venkatesh to Route R-09 for Monday morning, but Venkatesh has the day off. She opens the schedule entry for R-09, changes the driver from Venkatesh to Prakash, and saves. The entry now shows Prakash as the driver. (Note: if a trip was already created from this entry, the trip still shows the original driver — changing the schedule entry does not update the trip.)

**Deleting a Schedule Entry**
The school has declared a holiday on Thursday for a local festival. Mrs. Desai opens the Route Scheduler, sets the date to Thursday, and deletes all the schedule entries for that day. No trips will be created for Thursday because there are no schedule entries to generate them from.

---

## Example Scenario

Green Valley School runs 12 buses across 15 routes, with two shifts per day (Morning Pickup and Afternoon Drop). The transport operates Monday through Friday.

On Sunday evening, Mrs. Desai plans the entire week. She opens the Route Scheduler and creates schedule entries for Monday through Friday. For Monday, she creates 30 entries (15 routes × 2 shifts). She selects all 30 and clicks "Create Trip." The system creates 30 trips with a "Scheduled" status. She repeats this for Tuesday, Wednesday, Thursday, and Friday.

On Tuesday morning, a bus breaks down. Mrs. Desai opens the Route Scheduler for Tuesday, finds the entries for the broken bus's route, and reassigns a spare bus to those entries. She does not need to regenerate trips — the trips were already created and the trip details can be updated separately.

At the end of the week, Mrs. Desai reviews the schedule. Every day had a complete set of schedule entries, and every schedule entry had a trip created from it. The system shows no gaps — every route that was supposed to run had a trip.

---

## Related Screens

- **Driver/Vehicle Roster** — The roster defines the standing assignments that Mrs. Desai references when creating schedule entries. The roster does not automatically feed into the scheduler, but it provides the information she needs to create entries.
- **Daily Trip** — Trips are created from schedule entries and are managed in the Daily Trip screen. The trip status, start/end times, and other trip-specific details are handled there.
- **Shift Master** — Shifts are defined here and appear as a dropdown when creating schedule entries.
- **Route Master** — Routes are defined here and appear as a dropdown.
- **Vehicle Master** — Vehicles are defined here. Only active vehicles appear in the dropdown.

---

## Requirements

- Table: `tpt_route_scheduler_jnt`
- Columns: scheduled_date, shift_id, route_id, vehicle_id, driver_id, helper_id, pickup_drop
- Four unique constraints preventing duplicates for: (date + shift + route), (vehicle + date + shift), (driver + date + shift), (helper + date + shift)
- "Create Trip" button generates TptTrip records from selected scheduler entries
- Before creating a trip, checks if a trip already exists for that schedule entry — skips if it does
- Soft deletes supported
- Toggle status (active/inactive)

---

## Who Can Access

- **Transport Manager (Mrs. Desai)** — Full control. She can create, edit, delete, restore, and toggle status of schedule entries. She can also select entries and create trips from them.

- **Fleet Supervisor** — Can view schedule entries and edit basic fields such as the driver or vehicle on an existing entry. Cannot delete entries or create trips.

- **School Administrator** — Read-only access. Can view the schedule for any date but cannot create, edit, or delete any entries, nor create trips.

- **Driver** — Does not have access to this screen. Drivers see their assigned trips in the Daily Trip screen or are informed by Mrs. Desai directly.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When Mrs. Desai opens the Route Scheduler tab, the system loads schedule entries for today's date — 10 per page — along with each entry's linked shift, route, vehicle, driver, and helper information. The list shows the scheduled date, shift name, route name, vehicle registration number, driver name, helper name (if any), and pickup/drop type. An indicator next to each entry shows whether a trip has already been created from it.

When Mrs. Desai changes the date filter, the system reloads the list for the selected date.

When Mrs. Desai clicks "Add Entry," a form appears with dropdown lists for selecting the shift, route, vehicle, driver, helper (optional), and pickup/drop type. The scheduled date is pre-filled from the date filter but can be changed. When she clicks Save, the system checks all four uniqueness rules — if any combination of date/shift/route, vehicle/date/shift, driver/date/shift, or helper/date/shift conflicts with an existing entry, the system blocks the save and displays a message explaining which rule was violated.

When Mrs. Desai selects one or more entries and clicks "Create Trip," the system processes each selected entry one by one. For each entry, it checks whether a trip already exists for that schedule on that date. If not, it creates a new trip with a "Scheduled" status and links it to the schedule entry. If a trip already exists, it skips that entry. After processing all entries, the system shows a summary: "X trips created. Y skipped (already exist)."

When Mrs. Desai clicks Delete, the system soft-deletes the entry, hiding it from the active list but keeping it in the system for potential restoration.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Scheduled Date | Must be a valid date | "Please enter a valid date." |
| Shift | Must be selected and must exist in the system | "Please select a shift." |
| Route | Must be selected and must be an active route | "Please select a route." |
| Vehicle | Must be selected and must be an active vehicle in the fleet | "Please select a vehicle." |
| Driver | Must be selected and must be a valid staff member | "Please select a driver." |
| Helper | Optional — if provided, must be a valid staff member | "The selected helper is invalid." |
| Pickup/Drop | Must be either Pickup or Drop | "Please select whether this is a Pickup or Drop entry." |
| Uniqueness — Date + Shift + Route | No existing entry for the same date, shift, and route | "An entry already exists for this route on this date and shift." |
| Uniqueness — Vehicle + Date + Shift | No existing entry for the same vehicle on this date and shift | "This vehicle is already scheduled for a different route on this date and shift." |
| Uniqueness — Driver + Date + Shift | No existing entry for the same driver on this date and shift | "This driver is already scheduled for a different route on this date and shift." |
| Uniqueness — Helper + Date + Shift | No existing entry for the same helper on this date and shift | "This helper is already scheduled for a different route on this date and shift." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Date not entered | "Please enter a valid date." — the form does not submit | Data entry error |
| Route already scheduled for this date and shift | "An entry already exists for this route on this date and shift." — the form blocks submission | Data conflict |
| Vehicle already assigned to a different route on this date and shift | "This vehicle is already scheduled for a different route on this date and shift." — the form blocks submission | Data conflict |
| Driver already assigned to a different route on this date and shift | "This driver is already scheduled for a different route on this date and shift." — the form blocks submission | Data conflict |
| Helper already assigned to a different route on this date and shift | "This helper is already scheduled for a different route on this date and shift." — the form blocks submission | Data conflict |
| User tries to create trip without selecting any entries | "Please select at least one entry to create trips." — the button does nothing | User error |
| User tries to create trip but has no permission | System shows "Access Denied" | Permission error |
| Schedule entry was deleted and user tries to edit or create a trip from it | "Entry not found." or the entry no longer appears in the list | Data not found |
| Driver assigned to schedule entry is no longer active in the personnel system | No warning at the schedule entry level — the trip will be created with the driver as assigned | Data entry gap — no cross-check with personnel status |

---

## Success Scenarios — When Everything Works

**SC-001 — Planning and Executing a Full Week**
On Sunday evening, Mrs. Desai opens the Route Scheduler and creates schedule entries for all five weekdays — 30 entries per day (15 routes × 2 shifts). She selects all entries for Monday and clicks "Create Trip." The system creates 30 trips. She repeats for Tuesday through Friday, creating 150 trips for the week. Every route for every day has a trip ready. Monday morning, drivers open their trip list and see their assigned routes. The week runs smoothly.

**SC-002 — Handling a Late Change**
On Wednesday morning, Mrs. Desai realises that Driver Anita will be absent on Thursday. She opens the Route Scheduler for Thursday, finds Anita's entries, and changes the driver to Suresh. The schedule entries are updated. Since trips were already created from these entries, they still show the original driver. Mrs. Desai opens the Daily Trip screen and updates the driver on the corresponding trips. Both the schedule and the trips now correctly show Suresh as the driver for Thursday.

**SC-003 — Safe Duplicate Trip Prevention**
Mrs. Desai selects Monday's entries and clicks "Create Trip" — 30 trips are created. A few minutes later, she accidentally selects the same entries and clicks "Create Trip" again. The system checks each entry, sees that trips already exist, and displays "0 trips created. 30 skipped (already exist)." No duplicate trips are created.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Schedule Entry Created for the Wrong Date**
Mrs. Desai intends to create schedule entries for Monday but accidentally sets the date to Sunday. She creates all 30 entries for Sunday. On Monday morning, she opens the scheduler and sees no entries. She realises her mistake and must manually delete all 30 Sunday entries and recreate them for Monday. If she had already created trips from the Sunday entries, those trips would be for the wrong date and would need to be deleted or left as abandoned records.

**FC-002 — Trip Created but Schedule Entry Edited Later**
Mrs. Desai creates trips from Monday's schedule entries. Later, she edits one of the schedule entries — changing the vehicle from KL-05 to KL-09. The schedule entry now shows KL-09, but the trip that was already created still shows KL-05. When the driver checks the trip, they see KL-05, but the schedule shows KL-09. The mismatch causes confusion. The system does not automatically update trips when schedule entries are changed.

**FC-003 — Driver Changed in Schedule Without Updating the Trip**
Mrs. Desai changes the driver on a schedule entry from Rajesh to Suresh, thinking this will automatically update the trip. It does not. On the day of the trip, Rajesh (the original driver from the trip) reports for duty, but Suresh (the new driver from the schedule entry) also shows up thinking he is assigned. Two drivers arrive for the same trip. Mrs. Desai must manually update the driver on the trip itself.

**FC-004 — No Warning When Creating Trips on a Holiday**
The school calendar shows a holiday on Thursday, but Mrs. Desai does not realise it when she plans the week. She creates schedule entries for Thursday and creates trips from them. The system does not check against the school calendar. On Thursday morning, no students show up, but the buses are running. The fuel and driver time are wasted. The system should ideally warn when trips are being created on dates marked as holidays in the school calendar, but it does not.

---

(End of file)
