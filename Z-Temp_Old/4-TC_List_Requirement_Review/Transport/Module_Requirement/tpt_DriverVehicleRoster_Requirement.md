# Driver/Vehicle Roster — Business Requirements

## What This Screen Does

The Driver/Vehicle Roster screen manages which driver is assigned to which vehicle and route for a given shift. Each assignment links a driver, a vehicle, a route, and a shift together in a single record, along with an optional helper (someone who assists the driver during trips). The roster also defines whether the assignment is for the Pickup run (morning — collecting students from their stops) or the Drop run (afternoon — dropping students back home), and every assignment has a start date and an end date so the school knows exactly when the arrangement is active.

Without this screen, Mrs. Desai would have to manage driver-vehicle assignments on paper or in scattered spreadsheets. When a driver calls in sick, she would have to flip through papers to find out which vehicle that driver was assigned to, which route they were covering, and which students would be affected. When a new academic term starts and routes change, she would have to redraw the entire roster from scratch with no way to see what the previous arrangement looked like. The Driver/Vehicle Roster gives her a single, organised view of who is driving what, when, and where.

Each assignment has an effective date range — a "from" date and a "to" date. This means Mrs. Desai can set up assignments that automatically start and end on specific dates. For example, a driver covering a route for the first term only (April 1st to June 30th) can have an assignment that is valid only during those months. The system prevents overlapping assignments — you cannot have the same driver assigned to two different vehicles on the same shift and route during the same time period.

---

## Default Data Load

When Mrs. Desai opens Trip Management and clicks the Driver/Vehicle Roster tab, the system loads the most recent active assignments — 10 per page — showing the route name, vehicle registration number, driver name, helper name (if any), shift name, pickup/drop type, and effective date range. A search box at the top allows searching by route name or code, vehicle registration number, or driver name. A status filter lets her view Active, Inactive, or Trashed records.

---

## When This Screen Is Used

- **Setting Up a New Term Roster** — At the start of the new academic year in April, Mrs. Desai needs to assign 12 drivers to 12 buses across 15 routes, each running two shifts (morning pickup and afternoon drop). She opens the Driver/Vehicle Roster, clicks Add Assignment, and creates each record one by one — selecting the shift, the route, the vehicle, the driver, and whether it is a Pickup or Drop assignment. She sets the effective from date as April 1st and the effective to date as March 31st of the following year.

- **Covering for a Sick Driver** — On a Tuesday morning, Driver Rajesh calls in sick. He was assigned to Bus KL-05 on Route R-07 for the morning Pickup shift. Mrs. Desai opens the roster, finds Rajesh's assignment for KL-05/R-07, and closes it by setting the effective to date as yesterday. She then creates a new assignment assigning Driver Suresh to the same route/vehicle/shift combination, effective from today. When anyone views the roster, they see that Suresh is now the driver for KL-05 on R-07.

- **Switching a Driver to a Different Route Mid-Term** — The school adds a new pickup point on Route R-12, and Mrs. Desai decides that Driver Anita, who has been driving Route R-09, is more familiar with that area. She opens Anita's current assignment for Route R-09, sets the effective to date as this Friday, and creates a new assignment linking Anita to Route R-12 starting next Monday.

- **End-of-Term Review** — At the end of March, Mrs. Desai reviews the roster to see which assignments expired naturally and which drivers need to be reassigned for the next academic year. She filters by assignments where the effective to date has passed and uses that information to plan the new roster.

---

## Key Fields at a Glance

**Assignment Core**
Every assignment must link a shift (Morning/Afternoon/Evening), a route, a vehicle, and a driver — these four pieces of information together define who is driving which bus on which path at what time of day. The pickup/drop field further specifies whether this is the morning collection run or the afternoon return run.

**Driver and Helper**
The driver is the primary person operating the vehicle. The helper is an optional second person who assists the driver — for example, helping younger children board and alight, or managing student lists at each stop. Both drivers and helpers are selected from the same pool of school personnel.

**Effective Date Range**
Every assignment has a start date (effective from) and an end date (effective to). The assignment is considered active only on dates that fall within this range. This allows the school to plan assignments for specific terms, periods, or temporary cover arrangements without having to remember to manually end them.

**Total Students**
A field records the expected number of students that will be picked up or dropped on this route for this shift. This helps the Transport Manager ensure the vehicle has sufficient capacity and that the driver knows how many children to expect.

---

## Business Rules and Conditions

**No Overlapping Assignments for the Same Driver/Route/Vehicle/Shift**
The system enforces a rule that prevents the same driver from being assigned to the same route, vehicle, and shift during overlapping date ranges. If Mrs. Desai tries to create an assignment for Driver Rajesh on Bus KL-05, Route R-07, Morning Shift with a date range that overlaps an existing assignment, the system blocks it and shows a warning. This prevents confusion about who is responsible for which route on which day.

**Driver and Helper Come from the Same Personnel Pool**
Both the driver and helper fields draw from the same list of registered school personnel (the drivers and staff who work in the transport department). There is no separate "helper" list — a person who is a driver on one route could be a helper on a different route.

**Pickup and Drop Are Separate Assignments**
A driver assigned to a route for the morning Pickup shift is not automatically assigned to the same route for the afternoon Drop shift. If Mrs. Desai wants the same driver to handle both pickup and drop for the same route, she must create two separate assignments — one with pickup/drop set to "Pickup" and one with it set to "Drop."

**Assignments Are Time-Bound**
An assignment that has passed its effective to date is considered expired but is not automatically deleted. It remains in the system for historical records. Mrs. Desai can view expired assignments to see who was driving what in previous terms.

**Search Scope**
The search box on this screen searches by route name or code, vehicle registration number, and driver name. It does not search by helper name, effective date range, or shift name.

---

## Workflow Steps

**Creating a New Driver/Vehicle Assignment**
It is the start of the new academic term. Mrs. Desai opens the Driver/Vehicle Roster tab and clicks Add Assignment. A form appears. She selects the shift (Morning), the route (R-07 — JP Nagar to School), the vehicle (KL-05 — KA-01-EX-1234), and the driver (Rajesh). She optionally selects a helper (Suresh). She sets pickup/drop to "Pickup," enters the expected total student count as 45, and sets the effective from date as April 1st and the effective to date as March 31st of the following year. She clicks Save. The assignment appears in the list with an active status.

**Ending an Assignment Early**
Driver Anita has been assigned to Route R-09 since April, but the school needs her on Route R-12 starting November 1st. Mrs. Desai finds Anita's assignment for Route R-09 in the roster, clicks Edit, and changes the effective to date from March 31st to October 31st. The assignment is now set to expire at the end of October. She creates a new assignment for Anita on Route R-12 starting November 1st.

**Toggling an Assignment On and Off**
Mrs. Desai needs to temporarily deactivate an assignment because the vehicle is in the workshop for a week. Rather than changing dates, she clicks the Toggle Status button on the assignment. The assignment is marked inactive and is hidden from the active list. When the vehicle returns, she toggles it back to active.

**Deleting a Mistaken Assignment**
Mrs. Desai accidentally created an assignment with the wrong route. She clicks the Delete button on the assignment. The system hides it from the main list and moves it to the Trash. From the Trash view, she can either Restore it (bringing it back with its original settings) or permanently remove it.

---

## Example Scenario

Green Valley School has 12 buses and 15 routes covering different parts of the city. The transport runs two shifts — Morning Pickup (7:00 AM to 9:00 AM) and Afternoon Drop (2:30 PM to 4:30 PM).

At the start of the academic year in April, Mrs. Desai sets up the roster. She creates 24 assignments — one for each route's morning pickup and one for each route's afternoon drop. Each assignment links a specific driver, a specific bus, and a specific route.

In June, the school adds a new route (R-16 — Sarjapur Road) with 30 students. Mrs. Desai creates two new assignments — one for the morning Pickup and one for the afternoon Drop. She assigns Bus KL-09 and Driver Venkatesh to the new route.

In September, Driver Venkatesh resigns. Mrs. Desai ends his assignments by changing their effective to dates to September 15th. She then creates new assignments assigning Driver Prakash to the same routes, vehicles, and shifts, effective September 16th.

At the end of the academic year in March, Mrs. Desai reviews the roster to prepare for the next year. She can see every assignment that was active during the year — who drove which bus on which route for which shift — giving her a complete historical record for planning the next year's roster.

---

## Related Screens

- **Shift Master** — Each assignment is linked to a shift (Morning/Afternoon/Evening) defined in the system. Shifts are configured separately and appear as a dropdown when creating assignments.
- **Route Master** — The route linked to each assignment is managed here. The route name and code appear in the roster list.
- **Vehicle Master** — Each assignment references a vehicle from the fleet. Only active vehicles appear in the vehicle dropdown.
- **Personnel / Staff Records** — Both drivers and helpers are selected from the personnel records. A person must be registered as staff before they can be assigned as a driver or helper.
- **Route Scheduler** — The scheduler uses the driver/vehicle/route combinations defined here to create daily schedule entries.

---

## Requirements

- Table: `tpt_driver_route_vehicle_jnt`
- Columns: shift_id, route_id, vehicle_id, driver_id, helper_id, pickup_drop (Pickup/Drop), effective_from, effective_to, total_students, is_active
- Unique constraint prevents overlapping assignments for the same shift, route, vehicle, and driver during the same date range
- Search by: route name/code, vehicle registration number, driver name
- Supports toggle status (active/inactive), soft delete, restore, and force delete
- Driver and Helper both reference the same personnel pool (tpt_personnel)

---

## Who Can Access

- **Transport Manager (Mrs. Desai)** — Full control. She can create, edit, toggle status, soft delete, restore, and permanently remove assignments. She is the primary user who manages the roster day to day.

- **Fleet Supervisor** — Can view all assignments and edit basic fields such as effective dates and total students. Cannot delete or permanently remove assignments.

- **School Administrator** — Read-only access to view the roster. Cannot create, edit, or delete any assignments.

- **Driver** — Does not have access to this screen. Drivers are told their assignments by the Transport Manager directly.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When Mrs. Desai opens the Driver/Vehicle Roster tab, the system loads the most recent active assignments from the database — 10 per page — along with each assignment's linked shift, route, vehicle, driver, and helper information. The list shows the route name, vehicle registration number, driver name, helper name (if any), shift name, pickup/drop type, effective date range, and a coloured badge showing whether the assignment is Active (green) or Inactive (grey).

When Mrs. Desai clicks "Add Assignment," a form appears with dropdown lists for selecting the shift, the route (only active routes are shown), the vehicle (only active vehicles that are currently in the fleet are shown), the driver (any registered staff member can be selected), and optionally a helper. She fills in the pickup/drop type, effective from and to dates, and the total student count. When she clicks Save, the system checks for overlapping assignments — if the same driver, vehicle, route, and shift combination already has an active assignment for the same date range, the system blocks the save and displays a warning. If everything is clear, the assignment is saved with an active status.

When Mrs. Desai clicks Edit on an existing assignment, the form loads with all current values pre-filled. She can change any field. On save, the system again checks for overlaps (in case the date range was changed) and records which fields changed in the activity log.

When Mrs. Desai clicks the Toggle Status button, the system changes the assignment from active to inactive or vice versa without changing any other fields.

When Mrs. Desai clicks Delete, the system moves the assignment to the Trash. From the Trash view, she can Restore it (bringing it back to the active list) or permanently delete it.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Shift | Must be selected and must exist in the system | "Please select a shift." |
| Route | Must be selected and must be an active route | "Please select a route." |
| Vehicle | Must be selected and must be an active vehicle in the fleet | "Please select a vehicle." |
| Driver | Must be selected and must be a valid staff member | "Please select a driver." |
| Helper | Optional — if provided, must be a valid staff member | "The selected helper is invalid." |
| Pickup/Drop | Must be either Pickup or Drop | "Please select whether this is a Pickup or Drop assignment." |
| Effective From | Must be a valid date | "Please enter a valid start date." |
| Effective To | Must be a valid date that is on or after the start date | "The end date must be on or after the start date." |
| Total Students | Must be a positive whole number or zero | "Please enter a valid number of students." |
| Overlap Check | No existing active assignment for the same shift, route, vehicle, and driver with overlapping dates | "This driver is already assigned to this route, vehicle, and shift during the selected date range." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Driver not selected | "Please select a driver." — the form does not submit | Data entry error |
| Route not selected | "Please select a route." — the form does not submit | Data entry error |
| Vehicle not selected | "Please select a vehicle." — the form does not submit | Data entry error |
| Effective to date is before effective from date | "The end date must be on or after the start date." — the form blocks submission | Data entry error |
| Overlapping assignment exists | "This driver is already assigned to this route, vehicle, and shift during the selected date range." — the form blocks submission | Data conflict |
| User tries to delete without permission | System shows "Access Denied" | Permission error |
| User tries to restore an assignment that was permanently deleted | The assignment cannot be found — the system shows "Assignment not found" | Data not found |
| Helper field is set to the same person as the driver | No warning — the system saves the entry | Data entry gap — no cross-check |
| Effective from date is in the past and assignment is for a past date range | No warning — the system saves the entry even if the date range has already passed | Information only — historical entry |

---

## Success Scenarios — When Everything Works

**SC-001 — Setting Up the Annual Roster**
At the start of the academic year, Mrs. Desai creates 24 assignments covering all 12 buses and 15 routes across both morning and afternoon shifts. Each assignment has the correct effective date range of April 1st to March 31st. The system accepts all assignments without any overlap warnings. The roster is complete for the year, and every driver knows which bus and route they are assigned to.

**SC-002 — Handling a Mid-Term Driver Replacement**
Driver Rajesh puts in his resignation in September. Mrs. Desai opens his two assignments (Morning Pickup and Afternoon Drop for Route R-07), edits the effective to dates to September 30th, and creates two new assignments for the replacement driver, Suresh, effective October 1st. The roster shows a clean transition — Rajesh's assignments end on September 30th and Suresh's begin on October 1st, with no overlap or gap.

**SC-003 — Temporarily Reassigning a Vehicle**
Bus KL-05 goes into the workshop for two weeks. Mrs. Desai needs to assign a spare bus (KL-09) to Route R-07 temporarily. She opens the existing assignment for KL-05 on R-07 and changes its effective to date to today. Then she creates a new assignment linking KL-09 to Route R-07 for the next two weeks, with an effective from date of today and an effective to date two weeks later. When KL-05 returns, she ends KL-09's temporary assignment and reactivates KL-05's original assignment by extending its effective to date.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Overlapping Assignment Not Detected**
Mrs. Desai accidentally creates an assignment for Driver Anita on Route R-09 with Bus KL-03 for the Morning Pickup shift, effective April 1st to March 31st. Unbeknownst to her, Anita already has an active assignment for Route R-09 with a different bus (KL-07) for the same shift and date range. If the overlap check fails or is bypassed, the system now shows two conflicting assignments for the same driver, shift, and route. When Anita reports for duty, she does not know which bus to drive. Both buses could arrive at the same route, or neither bus arrives because each driver thought the other was covering.

**FC-002 — Assignment Not Ended When Driver Leaves**
Driver Venkatesh resigns in September. Mrs. Desai creates a new assignment for the replacement driver but forgets to end Venkatesh's original assignment. The roster now shows both Venkatesh and the new driver as active for the same route, shift, and vehicle. The system does not warn about this because the new assignment was created with the replacement driver — not the same driver — so the overlap rule is not triggered. The roster becomes misleading, showing two drivers for the same duty.

**FC-003 — Helper Cannot Be Contacted in an Emergency**
Mrs. Desai assigns a helper to a route, but the helper's contact details in the personnel records are out of date. When the driver tries to call the helper on the morning of the trip to confirm the pickup time, the phone number does not work. The system stores the helper assignment but does not verify that the helper's contact information is current. The driver ends up running the route without assistance.

**FC-004 — No Warning When Effective From Date Is in the Past**
Mrs. Desai creates an assignment with an effective from date that was two weeks ago, intending it to be active immediately. The system accepts the date without any warning. If the date was entered incorrectly (for example, two weeks in the past when it should have been two weeks in the future for the next term), the assignment becomes active immediately without anyone noticing, potentially assigning a driver to a route that is not yet ready.

---

(End of file)
