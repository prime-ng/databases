# Assign Stops to Route — Business Requirements

## What This Screen Does

The Assign Stops to Route screen is where the Transport Manager builds the actual route map. A route in the system is just a name and a direction — like "Whitefield Morning Pickup Route" — until someone decides which stops the bus will visit and in what order. This screen is where that decision happens. For any given route, shift, and direction, the Transport Manager can list the stops in sequence, set how many minutes after departure the bus reaches each stop, and set the fare for students boarding at each stop.

Without this screen, a route would be an empty shell — just a label with no practical meaning. The bus driver would have no way of knowing which stops to visit or in what order, and the school would have no way to charge different fares for students boarding at different locations.

The screen appears in two contexts:
1. **Transport Master → Assign Stops to Route tab** — A filtered view where the Transport Manager selects a route, shift, and direction to see and manage the stops assigned to that combination.
2. **Standalone screen** — The same functionality in a full-page layout when accessed through the dedicated menu item.

---

## Default Data Load

When Mrs. Desai opens the Assign Stops to Route screen, the system first shows her three dropdown menus at the top of the page: one listing all available routes (like "Whitefield Morning Pickup Route" or "MG Road Afternoon Drop Route"), one for selecting the shift (Morning, Afternoon, or Evening), and one for choosing the direction (Pickup or Drop). The main table below these dropdowns is empty until she makes her selections.

Once she selects a specific route, shift, and direction, the system fetches the stops assigned to that combination and displays them in a table sorted by their sequence number — stop 1 appears first, stop 2 appears next, and so on.

---

## When This Screen Is Used

- **Building a New Route from Scratch** — Mrs. Desai has just created a new route called "Whitefield Morning Pickup Route" (code WHT-PK-01). The route exists as a name and a direction, but it has no stops. She opens the Assign Stops to Route screen, selects the new route, and adds 6 stops in the order the bus will visit them: Palm Meadows Main Gate, Whitefield Depot Junction, Hoodi Circle, ITPL Main Road, Brookefield, and Mahadevapura. For each stop, she enters the arrival time in minutes from the start and the per-stop fare. Without this step, the route would be empty and useless.

- **Adjusting Fare for a Specific Stop Mid-Year** — It is July, and parents from the Brookefield stop have complained that the ₹550 one-side fare is too high compared to the ₹450 charged at the previous stop (ITPL Main Road), even though the distance difference is barely 1 kilometre. Mrs. Desai opens the assignment for Whitefield Morning Pickup Route, finds the Brookefield stop (ordinal 5), and reduces the one-side fare from ₹550 to ₹480 and the both-sides fare from ₹1,000 to ₹900. The change takes effect immediately — the next student allocation at Brookefield will reflect the new fare.

- **Reordering Stops After a Route Optimisation** — The bus driver, Mr. Venkatesh, has reported that visiting Hoodi Circle before ITPL Main Road causes a 10-minute delay due to morning traffic at the Hoodi signal. He suggests swapping the order: visit ITPL Main Road first, then Hoodi Circle. Mrs. Desai opens the assignment list and changes the ordinal of ITPL Main Road from 3 to 4 and Hoodi Circle from 4 to 3. The sequence updates instantly. The next day, the route saves 8 minutes, and all students arrive on time.

- **Deleting a Stop from a Route When a Student Transfers** — Five students who used the "Koramangala" stop on the MG Road Afternoon Drop Route have transferred to a different school. The stop now has zero students allocated. Mrs. Desai opens the route assignments, finds the Koramangala stop (ordinal 6), and removes it from the route. The stop continues to exist in the Trans. Stops master list for future use, but it is no longer part of this route's sequence.

---

## Key Fields at a Glance

**Route and Stop Mapping**
Each assignment connects one route — for example, "Whitefield Morning Pickup Route" — to one bus stop — for example, "Palm Meadows Main Gate" — for a specific shift and direction. A stop like "MG Road" could appear on multiple routes (the morning pickup route and the afternoon drop route), but it can only appear once on any single route. The bus cannot visit the same stop twice on the same trip. The sequence number (ordinal) determines where the stop falls in the route: stop 1 is the first stop the bus visits, stop 2 is the second, and so on. This ordering is critical because the arrival time at each stop is calculated as minutes from the start of the route, not as a clock time.

**Timing Fields**
Three timing fields track the route's progress in minutes from the starting point. The arrival time is when the bus is expected to reach a stop — for example, 8 minutes after the route starts. The departure time is when the bus leaves that stop after students have boarded. The travel time is the duration from this stop to the next one, used to calculate the next arrival time. These timing fields are optional because a school may not have precise stop-level data initially; the route can operate with just the stop sequence and add timings later.

**Per-Stop Fares**
Each stop can have up to two fare amounts. The one-side fare (or pickup/drop fare) is for students who travel only in one direction — for example, they ride the bus to school in the morning but arrange their own transport back in the afternoon. The both-sides fare is for students who use the bus for both the morning pickup and the afternoon drop. Whether the one-side fare option appears at all depends on a school-level setting: if the school has decided to charge only a flat both-sides rate for all students, the one-side fare field is hidden. Another school setting controls whether a student can have different pickup and drop stops — if this is turned off, the system forces each student to use the same stop for both directions.

---

## Business Rules and Conditions

**A Stop Can Appear on a Route Only Once (BR-TPT-016)**
A stop can be part of multiple routes — for example, "MG Road" could be stop 3 on the morning pickup route and stop 2 on the afternoon drop route — but it can never appear twice on the same route with the same direction. The bus cannot visit Indiranagar Main Road twice during a single morning pickup run. The system enforces this rule automatically and will refuse to add a stop if it is already assigned to that route, shift, and direction combination.

**School Settings Affect What You See**
Two school-wide settings control what appears on the form:
- **One-side fares:** If the school has decided to charge only a flat both-sides rate to all students, the one-side fare field is hidden. The Transport Manager enters only the both-sides fare.
- **Different pickup and drop stops:** If the school does not allow students to use different stops for pickup and drop, the Student Allocation screen will force each student to use the same stop for both. This setting does not change anything on the Assign Stops screen itself, but it affects how fares are applied later.

**Restore and Permanent Delete Are Built But Cannot Be Reached (GAP)**
The system has all the code needed to restore a deleted assignment from the trash and to permanently delete old records. However, the corresponding menu options were never connected. There is no way for Mrs. Desai to reach the trash view, restore a deleted stop assignment, or permanently erase one. The code exists but has no entry point — it is like building a door but never installing a handle.

**Deletions Are Not Recorded in the Activity Log (GAP)**
When Mrs. Desai creates a new stop assignment, the system logs "Created" in the activity log. When she edits one, it logs "Updated." But when she deletes a stop from a route, the system does not record the deletion. There is no way to look back later and answer the question "Who removed the Brookefield stop from the Whitefield route and when?" The restore and permanent delete actions, had they been accessible, do have logging — but since they cannot be reached, those log entries can never be created.

---

## Workflow Steps

**Story 1 — Mrs. Desai Builds the Whitefield Morning Pickup Route from Scratch**
Mrs. Desai has created a new route called "Whitefield Morning Pickup Route" (code WHT-PK-01) for the Morning shift with Pickup direction. Now she needs to tell the bus which stops to visit and in what order. She opens the Assign Stops to Route tab, selects WHT-PK-01 from the route dropdown, picks Morning shift, and chooses Pickup direction.

She clicks "Add Assignment." A form opens where she selects the first stop — "Palm Meadows Main Gate" — from the stop dropdown. She enters ordinal 1 (the first stop), sets the arrival time as 15 minutes from route start (the time it takes to reach Palm Meadows from the depot), departure time as 17 minutes (allowing 2 minutes for boarding), and the both-sides fare as ₹1,200. She clicks Save. The stop appears in the table as the first entry.

She repeats this process for 5 more stops: Whitefield Depot Junction (ordinal 2, arrival 22 min, fare ₹1,100), Hoodi Circle (ordinal 3, arrival 28 min, fare ₹950), ITPL Main Road (ordinal 4, arrival 34 min, fare ₹750), Brookefield (ordinal 5, arrival 40 min, fare ₹550), and Mahadevapura (ordinal 6, arrival 48 min, fare ₹450). Each stop is added with its sequence number, timings, and fare. The table now shows all 6 stops in order, ready for the morning run.

**Story 2 — Mrs. Desai Adjusts the Brookefield Fare After Parent Complaints**
It is July, three months into the academic year. Mrs. Desai receives a complaint from three parents at the Brookefield stop. They point out that Brookefield is barely 1 kilometre further than ITPL Main Road, yet the fare is ₹200 more. Mrs. Desai investigates, agrees the discrepancy is unfair, and opens the Assign Stops screen. She selects WHT-PK-01, finds the Brookefield stop in the table, and clicks Edit. She reduces the one-side fare from ₹550 to ₹480 and the both-sides fare from ₹1,000 to ₹900. She clicks Save. The system updates the fare immediately. The next time a student from Brookefield is allocated to this route, the system will charge the corrected amount.

**Story 3 — Mrs. Desai Removes the Koramangala Stop from the Afternoon Drop Route**
Five students who used the Koramangala stop on the MG Road Afternoon Drop Route have transferred to a different school. The stop now has zero students allocated. Mrs. Desai opens the Assign Stops screen, selects the MG Road Afternoon Drop Route (code MGR-DR-01) with the Afternoon shift and Drop direction, and finds Koramangala at ordinal 6. She clicks Delete. The system removes the stop from the route. The Koramangala stop still exists in the Trans. Stops master list — it can be added back to any route in the future — but it is no longer part of the MG Road afternoon drop sequence.

---

## Example Scenario

It is the first week of April, and Green Valley School is preparing for the new academic year. Mrs. Desai has spent the past two weeks reviewing the stop master list and creating new routes. Now comes the critical step: assigning stops to each route in the correct sequence with accurate timings and fares.

The flagship route for this year is the "Whitefield Morning Pickup Route" (code WHT-PK-01). It will serve 42 students across 6 stops in Whitefield and surrounding areas. Mrs. Desai opens the Assign Stops to Route screen and selects WHT-PK-01, Morning shift, and Pickup direction.

She adds the stops one by one:

1. **Palm Meadows Main Gate (PLM-MG)** — Ordinal 1. Arrival: 15 minutes from depot departure (the bus leaves the depot at 6:30 AM and reaches Palm Meadows at 6:45 AM). Departure: 17 minutes (2 minutes for 12 students to board). One-side fare: ₹650. Both-sides fare: ₹1,200.

2. **Whitefield Depot Junction (WHT-DJ)** — Ordinal 2. Arrival: 22 minutes (6:52 AM). Departure: 24 minutes (2 minutes for 8 students to board). One-side fare: ₹600. Both-sides fare: ₹1,100.

3. **Hoodi Circle (HDI-CL)** — Ordinal 3. Arrival: 28 minutes (6:58 AM). Departure: 29 minutes (1 minute — only 3 students board here). One-side fare: ₹500. Both-sides fare: ₹950.

4. **ITPL Main Road (ITPL-MR)** — Ordinal 4. Arrival: 34 minutes (7:04 AM). Departure: 36 minutes (2 minutes for 7 students). One-side fare: ₹400. Both-sides fare: ₹750.

5. **Brookefield (BRK-FD)** — Ordinal 5. Arrival: 40 minutes (7:10 AM). Departure: 42 minutes (2 minutes for 8 students). One-side fare: ₹350. Both-sides fare: ₹550.

6. **Mahadevapura (MHD-PR)** — Ordinal 6. Arrival: 48 minutes (7:18 AM). Departure: 49 minutes (1 minute for 4 students). One-side fare: ₹250. Both-sides fare: ₹450. This is the last stop before the bus heads to school, arriving at the gate by 7:35 AM.

With all 6 stops assigned, Mrs. Desai reviews the table. The total route time is 48 minutes from depot to the last stop, plus approximately 17 minutes from Mahadevapura to the school — a total of about 65 minutes from depot departure to school arrival. She notes that the highest fare (₹1,200 both-sides) is at Palm Meadows, the farthest stop from the school, and the lowest fare (₹450 both-sides) is at Mahadevapura, the closest stop to the school.

The next day, bus driver Mr. Venkatesh receives the route sheet showing all 6 stops in sequence with their timings. He follows the route, and all 42 students are picked up without incident. The parents receive the fare information through the school's transport fee system, which reads the per-stop fares set here.

---

## Related Screens

- **Route Master** — The screen where routes are created with their names, codes, and directions. The routes created here appear in the Assign Stops dropdown.
- **Trans. Stops** — The master directory of all bus stops. Only stops that exist in this directory can be assigned to routes. If a stop is not in the Trans. Stops list, Mrs. Desai must add it there first before it appears in the assignment dropdown.
- **Shift Master** — The screen where school shifts (Morning, Afternoon, Evening) are configured. These shifts drive the filter on the Assign Stops screen.
- **Student Route Allocation** — The screen where individual students are assigned to specific stops on specific routes. The stop sequence and fare amounts set here directly determine what the student allocation screen shows and charges.

---

## Requirements

- **List / Filter View** — Shows a filtered table of stop assignments for a selected route, shift, and direction, sorted by sequence number
- **Add Assignment** — Form to add a stop to a route with sequence number, arrival/departure times, travel time, and fare amounts
- **Edit Assignment** — Updates the sequence number, timings, or fare for an existing stop on a route
- **Delete Assignment** — Removes a stop from the route (the stop itself remains in the Trans. Stops master list)
- **Trash / Restore / Permanent Delete** — These features exist in the system code but cannot be accessed because the menu options were never connected. Mrs. Desai cannot view deleted assignments, restore them, or permanently erase them.
- **Activity Logging** — The system records when assignments are Created and Updated, but does NOT record when they are Deleted. There is no way to trace who removed a stop from a route or when.

---

## Who Can Access

- **Transport Manager (Mrs. Desai)** — Has full control over stop assignments. She can add stops to routes in any sequence, adjust timings and fares, reorder stops, and remove stops from routes. She is the primary user of this screen, especially during the pre-season route-building period in March and April.

- **Fleet Supervisor** — Can view the stop assignments for any route and can edit operational details like timings and sequence numbers. However, they cannot add new stops to routes or delete existing assignments. This role manages day-to-day route adjustments but does not make structural changes.

- **School Administrator** — Has read-only access. They can view which stops are assigned to which routes and see the fare structure, but cannot make any changes. This is useful when the administrator needs to answer parent queries about fare amounts or stop locations.

- **Driver** — Does not have direct access to this screen. Drivers receive the final route sheet with stop sequences and timings through their trip assignment.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message.

---

## Logic Flow

When Mrs. Desai opens the Assign Stops to Route screen, the system presents her with three dropdown lists at the top of the page: one for selecting a route, one for selecting a shift, and one for selecting a direction (Pickup or Drop). These dropdowns are populated with all the active routes, shifts, and directions that have been configured in the system. Below the dropdowns, an empty table waits for data.

Mrs. Desai selects a route — for example, "Whitefield Morning Pickup Route (WHT-PK-01)" — picks the Morning shift, and chooses Pickup as the direction. The system responds by fetching all stops currently assigned to that specific combination, ordering them by their sequence number from lowest to highest, and displaying them in the table. Each row shows the stop name, its sequence number, arrival time, departure time, one-side fare, and both-sides fare.

If Mrs. Desai wants to add a new stop to the route, she clicks the "Add Assignment" button. The system loads a form that includes a dropdown of all available active stops from the Trans. Stops master list, plus empty fields for the sequence number, arrival time, departure time, travel time to the next stop, one-side fare, and both-sides fare. The system also checks two school-wide settings: if the school has disabled one-side fares, the one-side fare field is hidden; if the school allows different pickup and drop stops, a note reminds Mrs. Desai of this flexibility.

Mrs. Desai selects a stop, enters the details, and clicks Save. Before saving, the system performs several checks. It verifies that the selected stop has not already been assigned to this route with the same shift and direction — a stop cannot appear twice. It confirms that the route, shift, and stop actually exist in the system. It checks that the sequence number is a positive whole number. If any check fails, the form highlights the problem and displays an error message; Mrs. Desai must correct the issue before the save proceeds.

If all checks pass, the system creates the assignment, logs "Created" in the activity log with Mrs. Desai's name and the timestamp, and returns to the assignment table with the new stop appearing in its correct sequence position.

When Mrs. Desai clicks Edit on an existing assignment, the form opens pre-filled with the current sequence number, timings, and fares. She can adjust any of these values — for example, changing the sequence number to reorder stops, or reducing a fare after a parent complaint. She clicks Save, the system logs "Updated" in the activity log, and the table refreshes.

When Mrs. Desai clicks Delete on a stop assignment, the system removes the stop from the route immediately. However, the system does NOT record this deletion in the activity log — there is no audit trail showing who removed the stop or when. The stop itself is not deleted from the Trans. Stops master list; it simply ceases to be part of this route's sequence.

---

## Validate Before Save — What the System Checks

| Field / What You Enter | What the System Checks | Error Message If Wrong |
|------------------------|----------------------|------------------------|
| **Route** — the route you are assigning stops to | Must select a valid route that exists in the system | "Please select a valid route." |
| **Shift** — Morning, Afternoon, or Evening | Must select a valid shift | "Please select a valid shift." |
| **Direction** — whether this is a Pickup route or a Drop route | Must be either Pickup or Drop | "Please select a valid direction." |
| **Stop** — the bus stop you are adding to the route | Must select a valid stop that exists in the Trans. Stops master list and must not already be assigned to this route with the same shift and direction | "This stop is already assigned to this route." |
| **Sequence Number (Ordinal)** — the order in which the bus visits this stop | Must be a positive whole number (1, 2, 3, etc.) | "The sequence number must be a positive number." |
| **Arrival Time** — minutes from the start of the route when the bus reaches this stop | Optional — if provided, must be a whole number | "Arrival time must be a valid number." |
| **Departure Time** — minutes from the start when the bus leaves this stop | Optional — if provided, must be a whole number | "Departure time must be a valid number." |
| **Travel Time to Next Stop** — minutes from this stop to the next one | Optional — if provided, must be a whole number | "Travel time must be a valid number." |
| **One-Side Fare** — fare for students travelling only one direction | Optional — if provided, must be a valid amount. Hidden entirely if the school does not offer one-side fares | "One-side fare must be a valid amount." |
| **Both-Sides Fare** — fare for students travelling both directions | Optional — if provided, must be a valid amount | "Both-sides fare must be a valid amount." |

If any of these checks fail, the form does not submit. The problem fields are highlighted in red, and the corresponding error message appears next to each field. Mrs. Desai must correct all errors before the system allows the save to proceed.

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Stop already assigned to this route (e.g., Mrs. Desai tries to add "Palm Meadows" to the Whitefield route a second time) | "This stop is already assigned to this route." — the form blocks submission | Data entry error — prevented before saving |
| Invalid route selected | "Please select a valid route." — the form does not submit | Missing or invalid selection — prevented before saving |
| Invalid shift selected | "Please select a valid shift." — the form blocks submission | Missing or invalid selection — prevented before saving |
| Sequence number is zero or negative | "The sequence number must be a positive number." — the form blocks submission | Data entry error — prevented before saving |
| Fare amount contains letters or symbols (e.g., "five hundred" instead of "500") | "One-side fare must be a valid amount." or "Both-sides fare must be a valid amount." — the form blocks submission | Data entry error — prevented before saving |
| User tries to add an assignment without the correct permission | The system displays a blank "Forbidden" page when they click Add Assignment | Permission error — system blocks the action |
| Stop deleted from route but deletion not logged | The assignment disappears from the table, but the activity log shows no record of the deletion. Mrs. Desai cannot later check who removed the stop or when it was removed. | 🔴 Gap — missing audit trail |
| Restore and permanent delete features exist in code but are unreachable | There is no Trash view, no Restore button, and no Permanent Delete option anywhere on the screen. If Mrs. Desai accidentally deletes a stop from a route, she cannot undo it. She must recreate the assignment from scratch. | 🔴 Gap — features built but not connected |
| Two people try to edit the same assignment simultaneously | There is no locking mechanism. If Mrs. Desai and the Fleet Supervisor both open the same assignment at the same time and save, the last save overwrites the first without warning. The earlier changes are silently lost. | 🔴 Gap — no conflict prevention |

---

## Success Scenarios — When Everything Works

**SC-001 — Mrs. Desai Builds the Whitefield Morning Pickup Route with 6 Stops**
Mrs. Desai creates a new route assignment with 6 stops in sequence: Palm Meadows Main Gate (ordinal 1, arrival 15 min, fare ₹1,200 both-sides), Whitefield Depot Junction (ordinal 2, 22 min, ₹1,100), Hoodi Circle (ordinal 3, 28 min, ₹950), ITPL Main Road (ordinal 4, 34 min, ₹750), Brookefield (ordinal 5, 40 min, ₹550), and Mahadevapura (ordinal 6, 48 min, ₹450). The system accepts all 6 assignments, logs each creation in the activity log, and displays the complete table sorted by sequence number. The total route time is 48 minutes from depot to the last stop. Mrs. Desai prints the route sheet for bus driver Mr. Venkatesh, who follows the sequence and picks up all 42 students without incident.

**SC-002 — Mrs. Desai Corrects the Brookefield Fare After Parent Feedback**
The parents of 3 students at the Brookefield stop complain that the ₹550 one-side fare is too high compared to ₹350 at the previous stop (ITPL Main Road), even though the distance difference is only 1 kilometre. Mrs. Desai opens the Whitefield route, finds Brookefield at ordinal 5, and edits the one-side fare from ₹550 to ₹480 and the both-sides fare from ₹1,000 to ₹900. She saves. The system logs "Updated" in the activity log. The next time a student from Brookefield is allocated, the system charges the corrected fare. The parents are satisfied with the adjustment.

**SC-003 — Mrs. Desai Reorders Stops to Optimise the Route**
Bus driver Mr. Venkatesh reports that visiting Hoodi Circle before ITPL Main Road adds 10 minutes to the route because of morning traffic at the Hoodi signal. Mrs. Desai opens the assignment list and changes Hoodi Circle's sequence number from 3 to 4 and ITPL Main Road's from 4 to 3. The table updates instantly to show the new order. The next day, the route saves 8 minutes, and all 42 students arrive at school by 7:35 AM instead of 7:43 AM.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Stop Deleted from Route with No Audit Trail**
Mrs. Desai notices that the "Koramangala" stop has disappeared from the MG Road Afternoon Drop Route. She does not remember deleting it, and neither does the Fleet Supervisor. She checks the activity log to find out who removed it and when, but there is no record of the deletion. The system logs creations and updates but not deletions. Mrs. Desai has no way to determine what happened. She must recreate the assignment, but she is unsure of the original sequence number and fare amounts, so she has to guess or ask the drivers what the previous settings were.

**FC-002 — No Way to Restore an Accidentally Deleted Stop Assignment**
The Fleet Supervisor, Mr. Sharma, is experimenting with the route configuration and accidentally deletes the "Palm Meadows Main Gate" stop from the Whitefield Morning Pickup Route. The stop vanishes from the assignment table. Mr. Sharma immediately realises his mistake and looks for an Undo button or a Trash view where he can restore the deleted assignment. Neither exists. He has to call Mrs. Desai, who must recreate the entire assignment — including the sequence number, arrival time (15 minutes), departure time (17 minutes), one-side fare (₹650), and both-sides fare (₹1,200) — from memory. If she gets any detail wrong, the route sheet will be incorrect and the bus driver may arrive at the wrong time or charge the wrong fare.

**FC-003 — Silent Overwrite When Two Users Edit the Same Assignment**
Mrs. Desai is editing the Brookefield stop's fare from her office while Mr. Sharma, the Fleet Supervisor, is simultaneously editing the same stop's arrival time from the depot. Mrs. Desai saves first — the fare updates to ₹480. Mr. Sharma saves two minutes later — his save overwrites Mrs. Desai's changes, reverting the fare back to ₹550 and updating only the arrival time. Neither user receives any warning that someone else was editing the same record. Mrs. Desai does not discover the problem until a parent calls two weeks later asking why the corrected fare was never applied.

**FC-004 — Route Assignment Count Does Not Match Student Allocations**
Mrs. Desai removes the "Hoodi Circle" stop from the Whitefield Morning Pickup Route because she believes no students use it anymore. However, 3 students are still actively allocated to this stop. The system does not check for existing student allocations before allowing the removal. The next morning, the route sheet does not include Hoodi Circle. The 3 students are waiting at the stop, but the bus does not arrive. The school receives angry calls from parents, and Mrs. Desai must urgently add the stop back to the route and arrange a late pickup.

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `tpt_route` | FK Table | Routes that stops are assigned to |
| `tpt_shift` | FK Table | Shifts used for filtering |
| `tpt_pickup_points` | FK Table | Stops available for assignment |
| `tpt_student_route_allocation_jnt` | Child Table | Student allocations referencing these assignments |

---

## Table: `tpt_pickup_points_route_jnt`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| shift_id | INT UNSIGNED NOT NULL FK | → `tpt_shift.id` CASCADE |
| route_id | INT UNSIGNED NOT NULL FK | → `tpt_route.id` CASCADE |
| pickup_drop | ENUM('Pickup','Drop') | Direction |
| pickup_point_id | INT UNSIGNED NOT NULL FK | → `tpt_pickup_points.id` CASCADE |
| ordinal | SMALLINT UNSIGNED DEFAULT 1 | Sequence |
| total_distance | DECIMAL(7,2) NULL | Km |
| arrival_time | INT NULL | Minutes from start |
| departure_time | INT NULL | Minutes from start |
| estimated_time | INT NULL | Minutes |
| pickup_drop_fare | DECIMAL(10,2) NULL | One-side fare |
| both_side_fare | DECIMAL(10,2) NULL | Both-sides fare |
