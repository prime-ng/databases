# Trip Incidents — Business Requirements

## What This Screen Does

The Trip Incidents screen records and manages problems that happen during a trip — a sudden stop because of an emergency, a vehicle that breaks down on the road, an accident involving the bus, or a route blocked by a fallen tree or road construction. Every incident is captured with its exact time, location (latitude and longitude), and severity level so the school has a permanent record of what happened, when, and where.

Without this screen, incidents would be reported verbally or through scattered WhatsApp messages to the Transport Manager. There would be no central log, no way to track whether an incident was resolved, and no data to analyse recurring problems — like whether a particular stretch of road keeps getting blocked or whether a specific driver is involved in more incidents than others. The Trip Incidents screen turns chaos into an organised, auditable trail of every event that disrupts a school trip.

Incidents arrive in two ways. They can be created automatically when a driver presses the "Emergency" button on a stop in the Stopage Status screen — this creates a "Stop Emergency" incident with Medium severity. Or they can be created manually by an authorised person typing in the details through the Incidents tab. Either way, every incident must eventually be reviewed and resolved by someone authorised to do so.

Once an incident is resolved, it stays resolved. The system prevents anyone from marking an already-resolved incident as resolved again — no double resolution. If new information comes to light, the resolution can be reopened by an authorised person.

---

## Default Data Load

When the Transport Manager opens Trip Management and clicks the Incidents tab, the system loads recent incidents — 10 per page — showing the trip route, incident time, type of incident (with a clear label instead of a code number), severity level with a colour-coded badge (LOW in yellow, MEDIUM in orange, HIGH in red), a short description, and the current status — OPEN (red badge) or RESOLVED (green badge). A search bar at the top allows searching across the trip route, driver name, or description text. Filter dropdowns let the manager narrow the list by incident type, current status, or a date range.

---

## When This Screen Is Used

- **A Driver Presses the Emergency Button** — On the way to school, Bus KL-05 encounters a road blocked by a large tree that has fallen across the road during the night. The driver presses the "Emergency" button on the Stoppage Status screen for the current stop. The system automatically creates a "Stop Emergency" incident with Medium severity, recording the current time and the GPS coordinates of the bus. The Transport Manager sees a new OPEN incident appear in the list and immediately calls the driver to check what is happening.

- **A Vehicle Breaks Down Mid-Route** — Bus KL-07's engine overheats and the bus cannot continue. The driver calls the Transport Manager, who opens the Incidents tab and manually creates an incident: type "Vehicle Breakdown," severity "HIGH" (because children are stranded), location as described by the driver, and a description of the problem. The incident appears with an OPEN status.

- **An Accident Is Reported** — A minor collision occurs while Bus KL-03 is reversing in the school parking lot. No one is injured, but the bus has a dented bumper. The Transport Manager creates an incident of type "Accident" with "LOW" severity, noting the damage and the other vehicle involved. The incident remains OPEN until the insurance claim is processed and the repair is completed.

- **Resolving an Incident** — The Fleet Supervisor confirms that the tree has been removed from the road and Bus KL-05 has safely completed its route. They open the Stop Emergency incident, verify the details, and click Resolve. The system sets the status to RESOLVED and records who resolved it and when. A resolved incident turns green in the list.

---

## Key Fields at a Glance

**Trip Information**
Every incident is linked to a specific trip — you cannot record an incident without saying which trip it happened on. The trip's route number and vehicle details are shown alongside the incident for easy reference.

**Time and Location**
The exact time of the incident is captured down to the minute, and the GPS coordinates (latitude and longitude) are recorded for stop emergencies. For manually created incidents, the location can be entered as coordinates if known, or left as a text description in the description field. The location data is critical for the school to identify problem spots — for example, if three "Route Blocked" incidents occur at the same intersection, the Transport Manager can report it to the traffic police or find an alternative route.

**Incident Type**
Four types of incidents are recognised:
- **Stop Emergency** (Type 0) — Automatically created when the driver presses Emergency on a stop. The system assumes this is a Medium-severity incident that needs attention.
- **Vehicle Breakdown** (Type 1) — The bus or van has a mechanical or electrical failure that prevents it from completing the trip.
- **Accident** (Type 2) — Any collision or accident involving the school vehicle, regardless of severity.
- **Route Blocked** (Type 3) — The planned route is impassable due to road construction, a fallen tree, traffic, or any other obstruction.

**Severity**
Every incident is classified as LOW, MEDIUM, or HIGH severity. This determines how urgently it needs attention. A LOW severity incident (like a minor breakdown where a replacement bus arrives quickly) can wait until the end of the day. A HIGH severity incident (like an accident with injuries) demands immediate attention from the Transport Manager and possibly the School Administrator.

**Description**
A free-text field where the person creating the incident describes what happened. For automatic incidents (Stop Emergency), the description is auto-generated: "Emergency stop triggered by driver at [stop name]." For manual incidents, the person entering the data writes a brief but complete description — for example, "Bus KL-07 engine overheated on Hosur Road near the Silk Board junction. Students transferred to replacement bus KL-09."

**Status**
Every incident starts with OPEN status. An authorised person must resolve it by reviewing the details, confirming that the situation has been dealt with, and clicking Resolve. The system records who resolved it and the exact time of resolution. A resolved incident cannot accidentally be resolved again.

---

## Business Rules and Conditions

**Stop Emergencies Are Automatic and Medium Severity**
When a driver presses the Emergency button on the Stoppage Status screen, the system creates an incident with type "Stop Emergency" (0) and severity "MEDIUM" without any manual input. The incident time is set to the current server time, and the GPS coordinates from the driver's device are captured. No one needs to fill in a form — the incident is created instantly so the Transport Manager can respond as quickly as possible. If a different severity or description is needed later, an authorised person can edit the incident manually.

**Double Resolution Is Prevented**
Once an incident has been marked as RESOLVED, the system will not allow anyone to resolve it again. The Resolve button is disabled, and a tooltip explains: "This incident has already been resolved." If an authorised person needs to reopen a resolved incident — for example, if new information comes to light — they can change the status back to OPEN manually.

**Soft Deletes Only**
When an incident is deleted, it is not erased from the database. It is moved to a Trash view where authorised users can restore it or permanently delete it. This prevents accidental loss of incident records, which may be needed for insurance claims, parent inquiries, or regulatory reporting.

**Search and Filter Capabilities**
The search box looks for matches in the trip route description and the incident description. It does not search by incident type or severity level. To find all incidents of a specific type (for example, all Accidents), the user must use the type filter dropdown. The date range filter works on the incident time — not on the creation time. So if an incident from last week was just now fully documented and saved, it still appears when filtering by last week's dates.

**Permission-Sensitive Actions**
Creating, editing, resolving, and deleting incidents each require specific permissions. A driver cannot mark an incident as resolved. A Transport Manager can do everything. A School Administrator can view incidents but cannot change anything.

---

## Workflow Steps

**Automatic Incident — Driver Presses Emergency**
It is Tuesday morning. Bus KL-05 is on its way to Green Valley School, currently at the "HAL Road" stop. The road ahead is blocked by a large tree branch that came down in last night's storm. The driver presses the "Emergency" button on the Stoppage Status screen. Instantly, a new incident is created in the system: type "Stop Emergency," severity "MEDIUM," time 07:42 AM, GPS coordinates captured from the driver's phone. The Transport Manager, Mrs. Desai, receives a notification on her screen. She opens the Incidents tab, sees the new OPEN incident, and calls the driver to assess the situation. She decides to send Bus KL-09 to pick up the students from HAL Road while KL-05 takes an alternate route.

**Manual Incident — Vehicle Breakdown**
It is Wednesday afternoon. Bus KL-07 breaks down on Hosur Road — the engine temperature light came on and the driver stopped safely. Mrs. Desai receives a call from the driver. She opens the Incidents tab, clicks Add Incident, selects "Vehicle Breakdown," sets severity to "HIGH" (students are waiting at the next stop), enters a description: "Engine overheating — bus stopped on Hosur Road near Silk Board. Driver awaiting assistance." She saves the incident. It appears in the list with an OPEN red badge.

**Resolving an Incident**
The Fleet Supervisor, Mr. Sharma, receives confirmation that the tree branch has been cleared and Bus KL-05 has completed its route. He opens the Stop Emergency incident, reads the description, verifies with Mrs. Desai that all students reached school safely, and clicks Resolve. The system sets status to RESOLVED, records Mr. Sharma as the resolver, and logs the time. The incident badge turns green.

**Searching for Recurring Problems**
Mrs. Desai wants to check if "Route Blocked" incidents happen frequently on the Bannerghatta Road route. She opens the Incidents tab, selects "Route Blocked" from the type filter, and sees three incidents in the last two months — all on the same stretch of road. She flags this for the monthly route review meeting with the drivers.

---

## Example Scenario

Green Valley School operates 12 buses covering routes across the city. On a typical day, each bus runs a morning pickup trip and an afternoon drop-off trip. Incidents are rare, but they do happen.

One Monday morning, two incidents occur:

First, Bus KL-03 is involved in a minor accident in the school parking lot. A parent's car backs into the front bumper of the bus while children are boarding. No one is injured. Mrs. Desai creates an incident manually: type "Accident," severity "LOW" (the bus is still drivable, just a dented bumper), description: "Bus KL-03 front bumper damaged when parent car reversed into it during boarding. No injuries. CCTV footage available." She notes the other vehicle's registration number in the description.

Second, on the same morning, the driver of Bus KL-05 presses the Emergency button because a water main burst on the planned route and the road is completely flooded. The system creates a Stop Emergency incident automatically.

Mrs. Desai handles both incidents. She arranges for KL-03 to be inspected after drop-off and sends a replacement bus for KL-05's route. By Tuesday morning, the KL-03 accident is resolved (insurance details noted), and by Tuesday afternoon, KL-05's route is confirmed clear.

Both incidents are marked as RESOLVED, and the records stay in the system for future reference.

---

## Related Screens

- **Trip Management** — Incidents are linked to trips. Opening a trip shows all incidents that occurred during that trip.
- **Stoppage Status** — The source of automatic Stop Emergency incidents. The driver's Emergency button creates an incident without any manual data entry.
- **Trip Dashboard** — The dashboard may show the number of open and resolved incidents for the current day or week.

---

## Requirements

- Table: `tpt_trip_incidents`
- Columns: `trip_id`, `incident_time`, `incident_type` (0=Stop Emergency, 1=Vehicle Breakdown, 2=Accident, 3=Route Blocked), `severity` (LOW/MEDIUM/HIGH), `latitude`, `longitude`, `description`, `status` (0=OPEN, 1=RESOLVED), `raised_by`, `raised_at`, `resolved_by`, `resolved_at`
- Automatic creation: When driver presses Emergency on a stop in Stoppage Status tab, type=0 (Stop Emergency), severity=MEDIUM
- Manual creation: Through the Incidents tab with all fields editable
- Resolution: Authorised person sets status=1, records resolved_by and resolved_at. Double resolution prevented
- Search/filter: By incident type, status, date range
- Soft deletes: Yes
- Activity logging: Present on create, update, resolve, delete
- Permissions: `tenant.trip.incident.*`

---

## Who Can Access

- **Transport Manager** — Full control. Can view all incidents, create manual incidents, edit any incident, resolve OPEN incidents, reopen RESOLVED incidents if needed, and delete incidents (soft delete). This is the primary user who manages incident response during school hours.

- **Fleet Supervisor** — Can view all incidents and resolve OPEN incidents after confirming that the situation has been dealt with. Cannot create or edit incidents (except adding resolution notes). Cannot delete incidents.

- **School Administrator** — Read-only access. Can view all incidents and use filters for reporting purposes, but cannot create, edit, resolve, or delete any records.

- **Driver** — Cannot access this screen directly. The driver's interaction is limited to pressing the Emergency button on the Stoppage Status screen, which automatically creates an incident.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When an authorised person opens the Incidents tab, the system loads all incidents linked to trips from the database — 10 per page — showing the trip route, incident type with icon, severity badge, description excerpt, and status badge. OPEN incidents appear at the top of the list regardless of date, so active issues are not buried under older resolved records.

When the Transport Manager clicks "Add Incident," a form appears with dropdown lists for selecting the trip (only trips that are currently active or recently completed), the incident type (one of four), and the severity level (LOW, MEDIUM, or HIGH). The manager fills in the description, optionally enters GPS coordinates, and clicks Save. The system validates that the trip exists, that the type and severity are valid values, and that the description is not empty. If everything is valid, the incident is saved with status OPEN, the current time is recorded as the incident time (unless overridden), and the manager's name is set as the person who raised it.

When the driver presses Emergency on the Stoppage Status screen, the system creates an incident automatically without any form. It sets the trip from the current stoppage, incident type to Stop Emergency, severity to MEDIUM, incident time to the current server time, GPS coordinates from the driver's device, and a description that reads "Emergency stop triggered by driver at [stop name]." The status is OPEN. The system records the driver's ID as the person who raised it.

When an authorised person opens a resolved incident, the Resolve button is disabled. A tooltip explains: "This incident has already been resolved." If the person needs to reopen it, they can change the status manually — but this action is logged.

When the manager clicks Delete on an incident, the system does not erase it. It hides it from the main list and moves it to a Trash view. From the Trash, the manager can either Restore the incident (bringing it back with its original status) or permanently delete it.

---

## Validate Before Save

| Field | What the System Checks | Error Message If Wrong |
|-------|----------------------|------------------------|
| Trip | Must be selected and must exist | "Please select a trip." |
| Incident Type | Must be selected from the configured options | "Please select an incident type." |
| Severity | Must be LOW, MEDIUM, or HIGH | "Please select a severity level." |
| Description | Must not be empty | "Please enter a description of the incident." |
| Latitude / Longitude | Optional — if provided, must be valid coordinates | "Please enter valid GPS coordinates." |
| Status | Must be OPEN or RESOLVED | "The status is invalid." |
| Resolved By / Resolved At | Can only be set when status changes to RESOLVED | "Cannot set resolution details without resolving the incident." |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Trip not selected | "Please select a trip." — the form does not submit | Data entry error |
| Incident type not selected | "Please select an incident type." — the form blocks submission | Data entry error |
| Description is missing | "Please enter a description of the incident." — the form blocks submission | Data entry error |
| User tries to create an incident without permission | System shows "Access Denied" | Permission error |
| User tries to resolve an already-resolved incident | The Resolve button is disabled with a tooltip: "This incident has already been resolved." | Workflow error |
| GPS coordinates are not numbers | "Please enter valid GPS coordinates." — the form blocks submission | Data entry error |
| User tries to edit a resolved incident's status to something invalid | "The status is invalid." — the form blocks submission | Data entry error |
| The emergency button creates an incident but the network drops | The system attempts to save the incident locally; if it cannot reach the server, the driver sees "Could not create emergency incident. Please try again." | Network error — driver may need to notify manually |

---

## Success Scenarios — When Everything Works

**SC-001 — Emergency Incident Handled Quickly**
Bus KL-05 encounters a blocked road. The driver presses Emergency. An incident is created automatically. Mrs. Desai sees the OPEN incident within seconds, calls the driver, and arranges a replacement bus. The original bus takes an alternate route. Within 30 minutes, the incident is resolved. The record stays in the system for the monthly safety review.

**SC-002 — Manual Breakdown Incident and Resolution**
Bus KL-07 breaks down on Hosur Road. Mrs. Desai creates a Vehicle Breakdown incident with HIGH severity. The Fleet Supervisor arranges a tow truck and a replacement bus. The broken-down bus is repaired by evening. The next day, the Fleet Supervisor resolves the incident after confirming the bus is back in service. The record serves as documentation for the repair cost and downtime.

**SC-003 — Route Blocked Pattern Identified**
Mrs. Desai notices that "Route Blocked" incidents have occurred three times on Bannerghatta Road near the same construction site. She filters the incident list by type and date range, identifies the pattern, and changes the route for all buses that use that stretch of road. The recurring problem is solved without any further incidents.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Emergency Incident Missed by Transport Manager**
A driver presses the Emergency button, and the incident is created successfully. However, Mrs. Desai is in a meeting and does not see the notification for 45 minutes. By the time she calls the driver, the students have been waiting for nearly an hour. The system does not have an escalation mechanism — if an OPEN incident of HIGH severity is not resolved within a set time, there is no automatic notification to a backup person like the Fleet Supervisor or School Administrator.

**FC-002 — Incident Description Too Vague**
A driver reports a breakdown, and Mrs. Desai creates an incident with the description "Bus broke down." Later, when the Fleet Supervisor tries to resolve it, they do not know where the bus was, what the problem was, or whether a replacement was sent. The incident stays OPEN until someone calls the driver again to get more details. The system does not enforce a minimum level of detail in the description field.

**FC-003 — Accident Incident Cannot Be Edited After Escalation**
An accident incident is created with LOW severity, but later investigation reveals injuries and the need for an insurance claim. The Transport Manager needs to change the severity from LOW to HIGH and add more details. The system allows editing, but there is no version history — the original severity and description are lost. If a parent or regulator later asks what was originally reported, there is no way to see the first version.

**FC-004 — GPS Coordinates Not Available for Manually Created Incidents**
When an incident is created manually (not through the Emergency button), the GPS coordinates are optional. If the person creating the incident does not enter them, the incident has no location data. Later, when Mrs. Desai wants to see a map of all incidents on a particular route, the manually created incidents without coordinates appear as dots at the school's location by default — giving a misleading picture of where incidents actually occur.
