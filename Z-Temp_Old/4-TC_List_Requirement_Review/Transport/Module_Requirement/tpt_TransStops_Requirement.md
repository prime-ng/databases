# Transport Stops (Pickup Points) — Business Requirements

## What This Screen Does

The Transport Stops screen is the master directory of every bus stop location that the school uses. Each stop is stored with a short code (like "IND-MR"), a full name (like "Indiranagar Main Road"), its precise map coordinates (latitude and longitude), which shift it belongs to (Morning, Afternoon, or Evening), what type of stop it is (students board here, get dropped here, or both), and how far it is from the school's bus depot. These stops are then linked to routes in the correct sequence to create the complete route map.

Without a central registry of stops, the Transport Manager would have no way to consistently refer to "the Indiranagar Main Road stop" across different routes. The same stop name might be entered differently on different route assignments, and there would be no single source of truth for a stop's map coordinates or distance from the depot.

The screen appears in one context:
1. **Transport Master → Trans. Stops tab** — A searchable, filterable list of stops displayed within the main Transport Master hub. Also provides the stop data needed by the Google Maps view on the Pickup Stops List screen.

---

## Default Data Load

When Mrs. Desai, the Transport Manager of Green Valley School, opens the Transport Master screen and clicks the "Trans. Stops" tab, the system immediately shows her the most recently added bus stops — 10 stops per page. A search box at the top lets her type a stop code like "IND-MR" or a stop name like "Indiranagar" to quickly find a specific location. A status filter lets her switch between viewing Active stops, Inactive stops, or All stops. The tab loads smoothly, without reloading the entire page.

The Trans. Stops tab is rendered as an inline tab pane within the Transport Master hub — there is no standalone full-page layout for this screen.

---

## When This Screen Is Used

- **Adding a New Stop for a New Residential Colony** — A new housing colony called "Palm Meadows" has come up on Whitefield Road, and 12 students from that colony have enrolled for the new academic year. Mrs. Desai needs to add "Palm Meadows Gate" as a new pickup stop with its map coordinates, distance from the depot, and shift timing. Without this entry, the stop does not exist in the system — it cannot be assigned to any route, no student can be allocated to it, and the bus driver would have no record of stopping there.

- **Updating Stop Coordinates After a Road Diversion** — The main road near "Indiranagar 4th Main" has been permanently closed due to metro construction. The bus can no longer stop at the old location. Mrs. Desai opens the stop record, corrects the latitude and longitude to the new stopping point 200 metres down the service road, and updates the estimated time from the depot from 12 minutes to 14 minutes to account for the detour. The Google Maps view on the Pickup Stops List screen now shows the corrected pin location.

- **Deactivating a Stop That Is No Longer in Use** — The "Old Madras Road Toll Gate" stop was used for two years while the flyover was under construction. Now the flyover is open and the bus no longer needs to stop at the toll gate. Mrs. Desai deactivates this stop so it no longer appears in route assignment dropdowns or the map view. However, the historical data — which students used that stop and which routes included it — remains intact for reporting.

- **Pre-Season Route Planning Before the Academic Year Starts** — Every March, Mrs. Desai reviews the stop master list ahead of the new academic year starting in April. She identifies which stops from last year are still valid, which new stops need to be added for newly enrolled students, and which stops should be removed because families have moved away. This annual review ensures that when route planning begins in April, the stop master list is accurate and complete.

---

## Key Fields at a Glance

**Stop Identity**
Every stop location needs a short code (like "IND-MR" for Indiranagar Main Road) that appears in dropdowns and junction tables, and a full name (like "Indiranagar Main Road Bus Stop") that is clear enough for drivers and parents to recognise. Both must be unique — you cannot have two different stops both called "MG Road" because the system (and the bus driver) would not know which one was intended.

**Location (Text Address)**
The create and edit forms include a `location` text field with Google Maps Places Autocomplete. As the user types and selects a place from the dropdown, the latitude and longitude fields are automatically populated, and the Google Maps Distance Matrix API calculates the total distance and estimated time from the user's current location (browser geolocation) to the selected stop. These auto-calculated fields are read-only.

**Map Coordinates**
Each stop can be pinned to a precise geographic location using a latitude and longitude pair — for example, latitude 12.9719 and longitude 77.6412 for the Indiranagar area. Behind the scenes, the system stores these coordinates in a special format that allows it to answer questions like "which stops are within 2 kilometres of this location?" quickly and accurately. The coordinates are used by the Pickup Stops List screen's Google Maps view to place a pin on the map for each stop.

**Shift and Stop Type**
Every stop is locked to a specific shift (Morning, Afternoon, or Evening) because a location that serves as a pickup point in the morning might not be used in the afternoon. The stop type determines whether students can board here (Pickup), alight here (Drop), or both (Both). This distinction is critical during student allocation — a student marked for "Pickup at Indiranagar" cannot be assigned to a stop that is configured as Drop-only.

**Distance and Estimated Time**
Two optional fields capture the distance in kilometres from the depot to this stop, and the estimated travel time in minutes from the depot. These values are used during route planning to estimate total trip duration and fuel consumption.

---

## Business Rules and Conditions

**Stop Identity Uniqueness (BR-TPT-015)**
Both the stop code and stop name must be unique across all shifts. Two stops called "IND-MR" or two stops both named "MG Road" would break route assignment and student allocation. The system enforces this rule and will refuse to save a stop if its code or name matches an existing record.

**Stop Type Determines Student Boarding Rules**
The stop type (Pickup, Drop, or Both) is not just a label — it controls which students can use this stop. When allocating a student to a route, the system must ensure that a stop marked as "Drop-only" is not selected as the student's pickup point. This validation exists in the allocation logic.

**Permission Naming Inconsistency (GAP)**
The Trans. Stops list checks for a permission named "view" instead of the standard "viewAny" that every other screen in the Transport module uses. This means a user who has been given the standard "viewAny" permission — which works perfectly for the Vehicle list, Route list, and all other screens — will see an "Access Denied" error when they try to open the Trans. Stops list. This bug was introduced when a developer copied the permission check from the view-single-record section and forgot to change it for the list view.

**Deletion Does Not Deactivate the Stop (GAP)**
When any record in the Transport module is deleted — vehicles, routes, drivers — the system always marks it as inactive AND hides it from the active list. But when a bus stop is deleted, the system only hides it from the list. It does not mark the stop as inactive in the background. This means that any report or check that looks at the active/inactive flag will still consider a deleted stop as active, creating confusion between stops that are truly active and stops that have been deleted.

---

## Workflow Steps

**Story 1 — Mrs. Desai Adds "Palm Meadows Gate" as a New Morning Pickup Stop**
It is the second week of March and Mrs. Desai has just received the list of 12 new students from the Palm Meadows colony. She opens Transport Master, clicks the Trans. Stops tab, and clicks Add Stop. She types "PLM-MG" as the stop code and "Palm Meadows Main Gate" as the stop name. She selects the Morning shift because these students will be picked up at 7:15 AM. For the stop type, she chooses "Pickup" — students will only board here; they will not be dropped here in the afternoon. In the Location field, she starts typing "Palm Meadows Main Gate, Whitefield Road" and selects the correct place from the Google Maps autocomplete dropdown. The latitude, longitude, distance from depot, and estimated travel time are automatically populated as read-only values. She clicks Save. The system confirms with a green message: "Stop created successfully." The new stop now appears in the Trans. Stops list and is immediately available for assignment to a route.

**Story 2 — Mrs. Desai Adds "Brigade Road Junction" as a Combined Pickup-and-Drop Stop**
The school has started an after-school sports programme that runs until 5:00 PM, and 8 students from Brigade Road need to be picked up in the morning and dropped back in the evening. Mrs. Desai adds a new stop called "Brigade Road Junction" with code "BRG-JCT". She selects the stop type as "Both" — this stop can be used for both morning pickup and afternoon drop. She enters the coordinates and sets the distance as 4.2 kilometres from the depot with an estimated time of 10 minutes. After saving, she notes that this stop will be assigned to the morning pickup route with ordinal 3 and to the afternoon drop route with ordinal 2.

**Story 3 — Mrs. Desai Deactivates an Old Stop That Is No Longer Needed**
The "Old Madras Road Toll Gate" stop has been empty for two months — no students have been allocated to it because the families in that area have moved. Mrs. Desai finds the stop in the list and clicks the Deactivate toggle. The stop immediately turns from green "Active" to grey "Inactive". It disappears from all route assignment dropdowns and from the Google Maps view on the Pickup Stops List screen. However, the stop record remains in the system. If a new family moves into that area next year, Mrs. Desai can reactivate it with a single click instead of recreating it from scratch.

---

## Example Scenario

Green Valley School runs 12 bus routes covering the city of Bengaluru. Every year in March, Mrs. Desai reviews the stop master list to prepare for the new academic session starting in April.

This year, a new residential colony called Palm Meadows has come up on Whitefield Road. Mrs. Desai has received the names and addresses of 12 newly enrolled students who live there. None of the existing 47 stops in the system covers this area, so she needs to create a new stop.

Mrs. Desai opens the Trans. Stops tab and clicks "Add Stop." She enters:

- **Stop Code:** PLM-MG (an abbreviation she creates using the colony name and location)
- **Stop Name:** Palm Meadows Main Gate
- **Shift:** Morning (these students will travel to school in the morning shift)
- **Stop Type:** Pickup (students will only board here; they will be dropped at a different location in the afternoon)
- **Latitude:** 12.9719 (she found this by right-clicking on Google Maps at the exact gate location)
- **Longitude:** 77.6412 (the corresponding map coordinate)
- **Distance from Depot:** 6.8 kilometres (the distance from the school's bus depot to this stop)
- **Estimated Time from Depot:** 15 minutes (how long the bus takes to reach this stop from the depot in light morning traffic)

She clicks Save. The system creates the stop and displays a green confirmation: "Stop created successfully."

Now Mrs. Desai switches to the "Assign Stops to Route" tab. She selects the "Whitefield Morning Pickup Route" (route code WHT-PK-01), chooses the Morning shift and Pickup direction, and adds Palm Meadows Main Gate as the first stop (ordinal 1) with an arrival time of 15 minutes (matching the estimated time from depot). She sets the one-side fare at ₹650 and the both-sides fare at ₹1,200 for this stop — the distance from Palm Meadows to the school is longer than from other stops, so the fare is higher than the standard ₹500.

Over the next week, all 12 Palm Meadows students will be allocated to this stop through the Student Route Allocation screen. The bus driver, Mr. Venkatesh, will receive the updated route sheet showing the new stop at ordinal 1.

Meanwhile, at the other end of the city, the "Old Madras Road Toll Gate" stop has had zero students for eight weeks. Mrs. Desai opens that record, checks the allocation list to confirm no students are assigned, and deactivates the stop. The stop turns inactive and disappears from all dropdowns. The historical record remains — if a family moves back to that area next year, she can reactivate it in one click instead of re-entering all the coordinates.

---

## Related Screens

- **Pickup Stops List (Map View)** — Visual map display of stops using Google Maps.
- **Assign Stops to Route** — Where stops are linked to routes in sequence.
- **Route Master** — Routes that these stops are assigned to.

---

## Requirements

- **List View:** Shows all stops with search and filter — accessible from the Transport Master tab or as a standalone page
- **Add Stop:** Form to create a new stop with code, name, shift, stop type, coordinates, distance, and estimated time
- **Edit Stop:** Updates any existing stop field
- **Delete Stop:** Moves a stop to the Trash (does not permanently erase)
- **Restore Stop:** Brings a stop back from the Trash
- **Permanent Delete:** Completely removes a stop from the system (for test entries only)
- **Toggle Status:** Switches a stop between Active and Inactive with a single click
- **Map Data:** Provides stop coordinates to the Google Maps view on the Pickup Stops List screen
- **Activity Logging:** Records when stops are Created, Updated, Deleted, Restored, or Toggled — however, the logging uses inconsistent labels (sometimes "Created", sometimes "Stored")

---

## Who Can Access

- **Transport Manager (Mrs. Desai)** — Has full control over all bus stops. She can add new stops, edit existing stop names and coordinates, deactivate stops that are no longer in use, reactivate previously deactivated stops, and permanently remove test entries. This is the primary role that works with this screen on a daily basis, especially during the pre-season route planning in March and April.

- **Fleet Supervisor** — Can view all stops and edit operational details like distance, estimated time, and shift linkage. However, they cannot delete or permanently remove any stop record. This role typically belongs to the depot in-charge who manages day-to-day route operations but does not make strategic decisions about which stops to add or retire.

- **School Administrator** — Has read-only access. They can view the complete list of stops with their codes, names, shift assignments, and coordinates, but cannot make any changes. This is useful when the administrator needs to answer a parent's question about which stops are near their home.

- **Driver** — Does not have direct access to this screen. Drivers see stop information through the trip sheets and route assignments generated from this data.

Behind the scenes, each action is protected by a permission check. If a user tries to perform an action they are not authorised for, the system displays an "Access Denied" message. However, there is an important inconsistency: the permission setting that controls who can view the stop list uses the name "view" instead of the standard "viewAny" convention used throughout the rest of the Transport module. This means a user who has been given the general "viewAny" permission — which works for every other screen — will still see an "Access Denied" message when they try to open the Trans. Stops list. This is a known issue caused by a copy-paste error during development.

---

## Logic Flow

When Mrs. Desai opens the Transport Master screen and clicks the Trans. Stops tab, the system immediately fetches the most recently created bus stops from its records — 10 at a time — and displays them in a table sorted by the date they were added. At the top of the table, a search box lets her type a stop code such as "IND-MR" or a stop name like "Indiranagar" to narrow down the list. Next to the search box, a status dropdown lets her choose to see only active stops, only inactive stops, or all stops together. Every time she types a search term or changes the status filter, the table reloads to show only matching results while keeping her on the same page.

When Mrs. Desai clicks the "Add Stop" button, the system prepares a blank entry form. It fills the Shift dropdown with the school's configured shifts (Morning, Afternoon, Evening) and presents empty fields for the stop code, stop name, map coordinates, distance from depot, and estimated travel time. Mrs. Desai fills in all the required fields and clicks Save.

Before saving the new stop, the system performs a series of checks. It confirms that the stop code she entered — for example, "PLM-MG" — has not already been used by another stop. It also checks that the stop name — "Palm Meadows Main Gate" — does not match any existing stop name. It verifies that she has selected a valid shift and a valid stop type (Pickup, Drop, or Both). If she entered latitude and longitude coordinates, it checks that they are proper numbers. If any of these checks fail, the system highlights the problematic fields in red, displays a clear error message next to each, and refuses to save — Mrs. Desai must correct the mistakes and try again.

If all checks pass, the system creates the new stop record, records the action in the activity log with Mrs. Desai's name and the current timestamp using the phrase "Created", and then returns her to the stop list with a green confirmation message at the top of the page. The new stop now appears in the list and can be assigned to routes.

When Mrs. Desai clicks Edit on an existing stop, the form opens with all the current values pre-filled. She can change any field — for example, updating the coordinates if the stopping location has shifted, or correcting the distance from the depot. She clicks Save, the system logs the change as "Updated" in the activity log, and the list refreshes with the updated information.

When Mrs. Desai clicks Delete on a stop, the system removes it from the active list by marking it as "deleted" in the background. However, importantly, the system does NOT also mark the stop as inactive — it simply hides it from the list. This is different from how every other record in the Transport module works, where deletion also sets the active flag to "No." The stopped record moves to the Trash folder, where Mrs. Desai can either restore it (which brings it back to the active list) or permanently erase it (which removes it from the database completely).

When Mrs. Desai uses the status toggle switch next to a stop in the list — for example, turning a stop from Active to Inactive — the system sends a quick background update. The toggle moves to its new position, the stop's active status changes, and the activity log records "Status Toggled." The page does not reload; the change happens instantly.

Separately, when the Pickup Stops List screen loads its Google Maps view, it sends a request asking for all active stops belonging to a specific shift — for example, "give me all morning shift stops." The system gathers every active stop for that shift, packages up each stop's name, code, latitude, longitude, and full coordinate information, and sends it back in a structured format. The map then places a pin on the map for each stop, allowing Mrs. Desai and the drivers to see all stops visually.

---

## Validate Before Save — What the System Checks

| Field / What You Enter | What the System Checks | Error Message If Wrong |
|------------------------|----------------------|------------------------|
| **Stop Code** — a short abbreviation like "IND-MR" or "PLM-MG" | Must be provided, maximum 50 characters, must not match any existing stop code | "The code has already been taken." |
| **Stop Name** — the full name like "Indiranagar Main Road" or "Palm Meadows Main Gate" | Must be provided, maximum 200 characters, must not match any existing stop name | "The name has already been taken." |
| **Shift** — whether this stop is for Morning, Afternoon, or Evening | Must select one of the available shifts in the system | "Please select a valid shift." |
| **Stop Type** — whether students board here (Pickup), get dropped here (Drop), or both (Both) | Must be one of: Pickup, Drop, or Both | "Please select a valid stop type." |
| **Latitude** — the north-south map coordinate (e.g., 12.9719) | Optional — if provided, must be a valid number | "Latitude must be a valid number." |
| **Longitude** — the east-west map coordinate (e.g., 77.6412) | Optional — if provided, must be a valid number | "Longitude must be a valid number." |
| **Distance from Depot** — how far this stop is from the bus depot in kilometres | Optional — if provided, must be a valid number | "Distance must be a valid number." |
| **Estimated Time from Depot** — how many minutes the bus takes to reach this stop | Optional — if provided, must be a whole number | "Estimated time must be a valid number." |
| **Active Status** — whether this stop is currently active or deactivated | Must be Yes or No | "The active status must be yes or no." |

If any of these checks fail, the form does not submit. The problem fields are highlighted in red, and the corresponding error message appears next to each field. Mrs. Desai must correct all errors before the system allows the save to proceed.

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Stop code already exists (e.g., "IND-MR" was typed by mistake for a second stop) | "The code has already been taken." — the form does not submit until a unique code is entered | Data entry error — prevented before saving |
| Stop name already exists (e.g., "MG Road" was entered but that name already belongs to a different stop) | "The name has already been taken." — the form does not submit | Data entry error — prevented before saving |
| No shift selected | "Please select a valid shift." — the form blocks submission | Missing selection — prevented before saving |
| Invalid stop type entered | "Please select a valid stop type." — the form blocks submission | Data entry error — prevented before saving |
| Latitude or longitude is not a proper number (e.g., letters typed instead of decimal coordinates) | "Latitude must be a valid number." or "Longitude must be a valid number." — the form blocks submission | Data entry error — prevented before saving |
| User tries to view the stop list without the correct permission | The system displays a blank "Forbidden" page with HTTP 403 error | Permission error — system blocks the action |
| User tries to add a stop without the correct permission | The system displays a blank "Forbidden" page when they click Add Stop | Permission error — system blocks the action |
| Stop deleted but still linked to active student allocations | The deletion succeeds silently — the system does not check whether students are currently allocated to this stop. Those student records still reference the stop in the database, potentially causing reports to show incomplete data or allocation errors. | 🔴 Gap — missing safety check |
| Permission naming inconsistency means users with "viewAny" permission cannot see the stop list | A user granted the standard "viewAny" permission (which works for every other screen) sees an "Access Denied" error when they try to open the Trans. Stops list. This happens because the system checks for a permission called "view" instead of the standard "viewAny." | 🔴 Gap — copy-paste bug in permission name |
| Soft-deleted stop still shows as active in the database | When a stop is deleted, the system removes it from the active list but does NOT mark it as inactive in the database. If any background report or query checks the "is active" flag, the deleted stop will still appear as active — creating confusion between truly active stops and deleted stops. | 🔴 Gap — missing status toggle during deletion |

---

## Success Scenarios — When Everything Works

**SC-001 — Mrs. Desai Adds a New Stop for the Palm Meadows Colony**
Mrs. Desai creates a new stop called "Palm Meadows Main Gate" (code PLM-MG) for the Morning shift, with stop type Pickup, coordinates 12.9719 / 77.6412, distance 6.8 km from depot, and estimated time 15 minutes. The system accepts the record and displays a green confirmation: "Stop created successfully." The new stop appears in the Trans. Stops list with a green "Active" badge. The activity log records "Created" with Mrs. Desai's name and the current time. Mrs. Desai immediately switches to the Assign Stops to Route tab and adds this stop to the Whitefield Morning Pickup Route as the first stop (ordinal 1) with a one-side fare of ₹650 and both-sides fare of ₹1,200.

**SC-002 — Mrs. Desai Corrects Map Coordinates After a Road Closure**
The Indiranagar 4th Main stop has been affected by metro construction. Mrs. Desai opens the stop record (code IND-4M), changes the latitude from 12.9781 to 12.9795 and the longitude from 77.6388 to 77.6402 — shifting the stop 200 metres down the service road. She also updates the estimated time from depot from 12 minutes to 14 minutes to account for the detour. She clicks Save. The system logs "Updated" in the activity log. When she opens the Pickup Stops List Google Maps view, the pin for Indiranagar 4th Main now shows at the corrected location. The next morning, bus driver Mr. Venkatesh follows the updated route sheet and picks up all 8 students at the new location without confusion.

**SC-003 — Mrs. Desai Deactivates an Obsolete Stop**
The "Old Madras Road Toll Gate" stop has had zero student allocations for two months. Mrs. Desai navigates to the stop record, checks the allocation count (it shows 0 students), and clicks the status toggle to deactivate it. The toggle switches from green to grey, and a message says "Stop deactivated successfully." The stop immediately disappears from the route assignment dropdowns and the Google Maps view. In the activity log, the system records "Status Toggled" with Mrs. Desai's name. Three months later, when a new family moves near that area, Mrs. Desai finds the stop in the Trash list, clicks Restore, and the stop reappears with all its original coordinates and settings intact — saving her the effort of re-entering everything from scratch.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Stop Deleted While Students Are Still Allocated to It**
Mrs. Desai deletes the "MG Road Bus Stop" because she thinks it is no longer needed. However, 5 students are still actively allocated to this stop for their daily pickup. The system does not check whether any students are currently assigned to the stop before deleting it — the deletion succeeds silently. The next morning, when the driver loads the route sheet, the MG Road stop is missing from the route. The 5 students are left waiting at the stop, and the school receives angry phone calls from their parents. The student records still reference a stop that no longer exists, causing confusion in the allocation reports and making it difficult for Mrs. Desai to figure out which students need to be re-allocated to a different stop.

**FC-002 — Permission Bug Prevents the Fleet Supervisor from Viewing Stops**
The Fleet Supervisor, Mr. Sharma, has been granted the standard "viewAny" permission that works for every other screen in the Transport module. However, when he clicks the Trans. Stops tab, the system shows him a blank "Forbidden" page instead of the stop list. This happens because the Trans. Stops screen checks for a permission named "view" instead of the standard "viewAny" that every other screen uses. Mr. Sharma calls Mrs. Desai in frustration, and she has to manually assign the "view" permission to his account — a workaround that should not be necessary. This bug affects any user who has been granted the standard permission set, causing unnecessary support requests and confused users.

**FC-003 — Deleted Stop Still Shows as Active in Background Reports**
Mrs. Desai deletes the "Old Airport Road" stop. The stop disappears from the active list, and everything looks normal. However, when the school's management runs a year-end report titled "All Active Stops Used This Year," the deleted "Old Airport Road" stop appears in the report as active — because the deletion process did not mark the stop as inactive in the underlying records. The report incorrectly shows 32 active stops when there are actually only 31. Mrs. Desai has to manually cross-check the report against the current list to identify the discrepancy, wasting her time and eroding trust in the system's reporting accuracy.

**FC-004 — Stop Restored But Cannot Be Found in Active Lists**
Mrs. Desai finds the "Palm Meadows Main Gate" stop in the Trash folder and restores it, expecting it to reappear in the active stop list. However, the restored stop does not show up in the list — it remains invisible. This happens because the system's restore function brings the record back from the trash but does not turn the active status back on. Mrs. Desai must manually toggle the status switch to make the stop visible again. If she does not know about this extra step, she may assume the restoration failed and recreate the stop from scratch — creating a duplicate record that will later cause confusion.

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `tpt_shift` | FK Table | `shift_id` → CASCADE |
| `tpt_pickup_points_route_jnt` | Child Table | Junction referencing pickup_point_id → CASCADE |
| `tpt_student_route_allocation_jnt` | Child Table | Student stop allocations |

**Table:** `tpt_pickup_points`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| shift_id | INT UNSIGNED NOT NULL FK | → `tpt_shift.id` CASCADE |
| code | VARCHAR(50) NOT NULL UNIQUE | Stop code |
| name | VARCHAR(200) NOT NULL UNIQUE | Stop name |
| latitude | DECIMAL(10,7) NULL | Latitude |
| longitude | DECIMAL(10,7) NULL | Longitude |
| location | POINT SRID 4326 NOT NULL | Spatial point |
| total_distance | DECIMAL(7,2) NULL | Km from depot |
| estimated_time | INT NULL | Minutes from depot |
| stop_type | ENUM('Pickup','Drop','Both') | Default Both |
| is_active | TINYINT(1) DEFAULT 1 | — |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
| SPATIAL INDEX | `(location)` | Geospatial index |
