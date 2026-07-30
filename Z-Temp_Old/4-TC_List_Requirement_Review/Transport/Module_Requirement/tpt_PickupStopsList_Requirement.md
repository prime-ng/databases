# Pickup Stops List (Map View) — Business Requirements

## What This Screen Does

This is a Google Maps-powered visual route planning tool. Unlike the Trans. Stops tab (which shows a data table), this screen lets the Transport Manager visually explore how bus routes connect to existing stops. The user enters a start and end location, selects a shift, and the system fetches all possible driving routes from Google Maps, then matches them against registered pickup points within 1.5 km distance.

Without this screen, route planning would be entirely theoretical — the Transport Manager would have to guess whether the stops assigned to a route are actually along the bus's driving path, or manually cross-check addresses against printouts of Google Maps directions. This screen bridges the gap between the database (which has stop coordinates) and the real world (which has actual roads and traffic patterns).

This tab is rendered entirely via inline Blade view `transport::pickup_point.pickup_point` with 531 lines of inline JavaScript. There is no dedicated PHP controller for this tab — the view is included directly in `transportmaster.blade.php`.

---

## Default Data Load

When the Transport Manager opens Transport Master and clicks the Pickup Stops List tab, the screen shows a blank Google Map centred on Delhi and two text boxes — one for the starting location and one for the ending location. A dropdown menu lets the manager select which shift (Morning, Afternoon, or Evening) they want to plan for. The map is empty and the route list is empty until the manager takes action.

No data is fetched from the database until the manager types a start and end address, selects a shift, and clicks the "Find Routes" button. Only then does the system go to work: it first retrieves all the registered pickup stops for the selected shift, then asks Google Maps to calculate possible driving routes between the two addresses, and finally matches each stop against each route to see which stops fall within walking distance (1.5 kilometres) of the route path.

---

## When This Screen Is Used

- **Planning a New Bus Route for a New Residential Area** — A new housing colony has come up near Whitefield, and 15 students from that area have enrolled for the coming academic year. Mrs. Desai needs to figure out whether the school's existing bus routes can cover this colony or whether a new route is needed. She opens the Pickup Stops List, enters the colony's main gate as the starting point and the school as the destination, and views the map to see which of the existing pickup stops fall along the driving path. If at least 10 of the 15 students live near stops that are within 1.5 km of a route, she can assign them to an existing bus — otherwise, she needs to plan a new route.

- **Checking Whether All Registered Stops Are Covered by Active Routes** — Every month, Mrs. Desai runs a coverage check to make sure no student's pickup stop has been left out. She opens the Pickup Stops List, enters the farthest stop from the school as the start and the school as the end, and examines the map to see which stops appear along the route. If a stop that should be on this route does not appear on the map within 1.5 km of the driving path, it means the stop's location coordinates in the system may be wrong, or the route has changed and the stop was not reassigned.

- **Showing a Route Visual to Parents During Orientation** — During the annual parent orientation in March, a new parent asks: "Which road will the bus take to reach my child's stop?" Mrs. Desai opens the Pickup Stops List, enters the school as the start and the farthest stop on the route as the end, and displays the map on the projector. The parents can see exactly which roads the bus will travel on, where their child's stop is located, and how far the stop is from the bus route. This visual reassurance helps parents feel confident about the school's transport arrangements.

- **Investigating a Parent Complaint About Bus Detour** — A parent complains that the school bus takes a different road every day and sometimes does not come to their child's stop at all. Mrs. Desai opens the Pickup Stops List, enters the school and the parent's address, and examines the route options Google Maps suggests. She can see that one suggested route goes through a narrow lane that a school bus cannot fit through, and the alternative route bypasses the parent's street entirely. She uses this information to explain to the parent why the bus takes the route it does, and to discuss whether the stop location needs to be moved to a wider road.

---

## Workflow Steps

**Planning a New Route for a Newly Enrolled Student Cluster**
Fifteen new students have enrolled from the Suncity Apartments complex, and Mrs. Desai needs to determine the best bus route to serve them. She opens the Pickup Stops List tab and types "Suncity Apartments Main Gate, Whitefield" into the Start Location box. In the End Location box, she types "Green Valley School, Old Airport Road." She selects "Morning Shift" from the shift dropdown and clicks "Find Routes."

Google Maps calculates three possible driving routes between the apartment complex and the school. The system immediately sorts them by distance — the shortest route (12.4 km) appears first in the route panel with a blue left border. Mrs. Desai clicks on this route, and the map draws a blue line showing the exact driving path. Green numbered circles appear along the route — each one represents an existing pickup stop that is within 1.5 km of the route path.

Mrs. Desai counts the stops: seven existing stops appear along this route, and five of them belong to students living in Suncity Apartments. However, two of the Suncity students live at the far end of the complex, about 2 km from the nearest existing stop — they would need to walk too far. Mrs. Desai notes that she will need to register a new pickup stop near the rear gate of the complex to serve those two students. She writes down the coordinates from Google Maps and proceeds to the Add Stop screen to create the new stop.

**Checking Route Coverage Before the New Academic Year**
In March, before the new session begins, Mrs. Desai decides to verify that all 24 registered pickup stops are actually along the bus routes they are assigned to. She picks Route 7 — the longest route covering the east side of the city — and enters its start point (the first pickup stop, "Marathalli Bridge") and its end point (the school). She clicks Find Routes and examines the map. She notices that one stop called "HAL Layout Phase 2" does not appear on the map — it is 3.2 km away from the nearest driving path. This suggests that either the stop's coordinates were entered incorrectly when the stop was registered, or the route has been modified since the stop was added. Mrs. Desai opens the stop's detail record, corrects the coordinates using the Google Maps pin, and runs the route check again — this time the stop appears within 800 metres of the route path.

**Demonstrating Route Coverage to Parents During Open House**
During the annual Open House event, a parent from the Whitefield area asks whether the school bus passes near their street. Mrs. Desai opens the Pickup Stops List on the projector screen. She enters the school as the start and the parent's residential area as the end. The map shows three alternative routes. She selects the second route — a slightly longer path (14.2 km vs 12.8 km) — because it passes closer to the parent's street. The parent can see their child's stop (a numbered green circle) within 600 metres of the route and is satisfied that the bus comes close enough. Mrs. Desai then shows the parent the stop detail: pick-up time, driver name, and bus number.

---

## Example Scenario

It is March 25th and Green Valley School is preparing for the new academic session starting in April. Mrs. Desai has received a list of 18 new students from the Bloomingdale Township — a newly developed area on the outskirts of the city. Before she can assign these students to bus routes, she needs to determine whether the school's existing Route 5 (which runs from the city centre through the eastern corridor) already covers the Bloomingdale area.

Mrs. Desai opens the Pickup Stops List tab. She types "Bloomingdale Township Main Gate, Outer Ring Road" as the Start Location and "Green Valley School, Old Airport Road" as the End Location. She selects "Morning Shift" from the dropdown and clicks "Find Routes."

Google Maps returns four possible driving routes. The system sorts them by distance and displays them in the route panel with coloured borders — Route A (Blue, 15.2 km), Route B (Red, 16.8 km), Route C (Green, 18.1 km), and Route D (Yellow, 19.5 km). Mrs. Desai clicks on Route A — the shortest option. The map draws a blue line from Bloomingdale to the school. Green numbered circles (pickup stops) appear along the route.

She examines the stops: six existing stops are within 1.5 km of Route A. She cross-references these against the list of 18 new families. Five of the six stops correspond to Bloomingdale addresses. The remaining 13 families live deeper inside the township, more than 2 km from any existing stop. Mrs. Desai clicks on one of the stops — a numbered circle near the township entrance — and the system shows the stop name ("Bloomingdale Gate"), its code ("ST-042"), and its distance from the route (400 metres).

Mrs. Desai realises that Route 5 can partially serve the Bloomingdale area, but 13 families will need either a new dedicated route or additional stops. She opens the Trans. Stops tab to register two new stops inside the township — one near the community centre and one near the rear gate — and assigns them to Route 5. After registering the new stops, she returns to the Pickup Stops List, enters the same start and end locations, and verifies that all 18 families now have a stop within 1.5 km of Route A.

---

## Key Controls

| Control | Implementation | Notes |
|---------|---------------|-------|
| Start Location | Google Places Autocomplete | `componentRestrictions: { country: 'in' }` |
| End Location | Google Places Autocomplete | Same restriction |
| Shift | Blade dropdown (`$shifts`) | From TransportMasterController |
| Find Routes | JavaScript function | Async with loading state |
| Clear All | JavaScript function | Resets map and panels |
| Map | Google Maps | Default center: Delhi (28.6139, 77.2090), zoom 11 |
| Routes List | Dynamic DOM rendering | Colored left border, click to select |
| Stops Panel | Dynamic DOM rendering | Shows after route selection |

---

## Business Rules

**1.5 km Distance Threshold for Stop Matching**
A stop is considered "on route" only if it lies within 1.5 kilometres of the route's driving path. This threshold is hardcoded in the JavaScript (1500 metres in `computeDistanceBetween`). The rationale: a stop that is more than 1.5 km from the road the bus travels on is too far for a detour. However, this threshold is not configurable — a school in a rural area with sparse stops might want a larger radius, while a dense urban school might want a smaller one.

**Routes Sorted by Shortest Distance First**
When Google Maps returns multiple route alternatives, the system sorts them by total driving distance ascending. The shortest route appears first in the panel as the default selection. This assumes the Transport Manager always prefers the shortest possible route — but the shortest route might not be the safest or the most practical (e.g., it could go through narrow lanes unsuitable for a school bus).

**Color-Coded Route Visualisation**
Up to 5 routes can be displayed, each with a cycling color (Blue, Red, Green, Yellow, Purple). When a route is selected from the panel, the corresponding color polyline is drawn on the map with start (green) and end (red) markers. Stop markers are numbered circles overlaid on the route.

**India-Restricted Address Autocomplete**
The Google Places Autocomplete is restricted to India addresses only (`componentRestrictions: 'in'`). This means users cannot search for international locations — appropriate for a school transport system, but may need adjustment for international schools in India with multi-national routes.

---

## Logic Flow

When Mrs. Desai opens the Pickup Stops List tab, the system displays a blank Google Map centred on Delhi with two address fields and a shift dropdown. No data is fetched yet — the map simply waits for instructions. The two address fields are smart — they show suggestions as the manager types, and they only search for addresses within India because the school's routes are all domestic.

Mrs. Desai types the starting location and the ending location into the two address boxes. The system does nothing until she clicks the "Find Routes" button. When she clicks it, the button changes to a spinning indicator to show that work is happening in the background.

First, the system asks the database for all registered pickup stops that belong to the selected shift — for example, all morning-shift stops. It collects their names, codes, and precise location coordinates (latitude and longitude). Then, it sends a request to Google Maps, asking: "What are all the possible driving routes between these two addresses?" Google Maps responds with up to five different route options, each with its own driving path, distance, and estimated travel time.

The system immediately sorts these routes by total driving distance — the shortest route appears at the top of the list. For each route, the system checks every pickup stop against the route path: if a stop is within 1.5 kilometres of the driving route, it is considered "on route." The 1.5 km threshold is built into the system and cannot be changed by the school — a rural school with spread-out stops would need the same 1.5 km radius as a dense urban school.

Routes that have at least one matching stop are displayed in a panel on the right side of the screen, each with a coloured left border (Blue, Red, Green, Yellow, or Purple). The first route in the list is automatically selected, and the map draws its driving path in the corresponding colour — a green marker at the start, a red marker at the end, and numbered green circles at each stop location. When Mrs. Desai clicks on a numbered circle, a small information box pops up showing the stop name, code, and its distance from the route.

Below the route panel, a list shows all the stops that match the selected route. Mrs. Desai can see each stop's name, unique code, type, and distance. She can click on a different route in the panel to see its stops and path instead — the map clears the previous route and draws the newly selected one. If she wants to start over, she clicks "Clear All" to reset the map and the panels.

---

## Who Can Access

- **Transport Manager** — Has full access to the Pickup Stops List. Mrs. Desai can open the map, search for routes, view stop coverage, and analyse route feasibility. This is a read-only visualisation tool — there is no way to create, edit, or assign stops directly from this screen. The Transport Manager uses this screen primarily for planning and analysis before making changes in the Stops or Routes screens.

- **Fleet Supervisor** — Can view the map and see all routes and stops, but their access is needed mainly for verification purposes — for example, confirming that a stop's coordinates are correct when Mrs. Desai spots a discrepancy during route analysis.

- **School Administrator** — Has view-only access. They can open the map and see the routes and stops, which is useful during parent meetings when they need to show a route visual on a projector.

- **Driver** — Does not have access to this screen. Drivers use the Trip Assignment screen to see their assigned route and stops for the day.

Behind the scenes, access is controlled by a single permission check. If the user does not have the required permission, the Pickup Stops List tab does not appear in their Transport Master view.

---

## Requirements

- **No controller** — Tab is inline Blade view, no dedicated controller
- Data sourced from `PickupPointController@getPickupPointsByShift()`
- Permission: `tenant.trans-stops-list.viewAny`
- API key: `config('transport.google_maps_api_key')` (Google Maps JavaScript API)
- Libraries required: `places`, `geometry`

---

## Key Gaps

| Issue | Details | Severity |
|-------|---------|----------|
| 531 lines of map code mixed into the page | The Google Maps logic is written directly inside the page instead of in a separate file — difficult for developers to update or fix | 🟡 Medium |
| Stop matching happens on the user's computer | The system checks which stops are near a route inside the web browser, not on the server. If the school has 5,000+ stops, this could slow down or freeze the browser | 🟡 Medium |
| No ability to save or assign from this screen | This is a view-only map — the Transport Manager cannot create new stops, edit existing ones, or assign them to routes directly from this screen | Informational |
| Requires a working Google Maps key | The screen will not work at all without a valid Google Maps API key — no map, no route search, no stop matching | 🔴 High |

---

## Error Handling — What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| Google Maps API key is missing or invalid | The map shows a grey empty area with a "Google Maps API error" message. The address fields do not suggest any addresses, and clicking "Find Routes" does nothing | Configuration error — the school's IT team must register for a Google Maps API key and enter it in the system settings |
| User enters a start or end location that Google Maps does not recognise | The address field shows no suggestions, or Google Maps returns "No route found" between the two locations. The route panel stays empty | Data entry error — the manager may have misspelled the address or entered a non-existent location |
| User clicks Find Routes but no shift is selected | The button may appear to do nothing, or the system may use a default shift without informing the manager | ⚠️ Gap — no clear feedback that a shift must be selected |
| No pickup stops are registered for the selected shift | The system fetches stops but returns an empty list. Google Maps calculates the routes, but the stop panel shows zero matching stops because there are no stops to match against. The manager sees a blank map with no numbered circles | Data setup issue — the manager must first register stops in the Trans. Stops screen and assign them to a shift |
| A stop is registered but its coordinates are wrong (e.g., placed in the wrong city) | The stop may not appear within 1.5 km of any route, even though it should be on the route. The stop's numbered circle could appear far away from the actual driving path, confusing the manager | Data entry error — the person who registered the stop may have entered incorrect latitude/longitude coordinates |
| Internet connection drops while the map is loading | The map may show only partially, or route data may not load. The "Find Routes" button may spin indefinitely without completing | Network error — the system does not show a "Connection lost, please try again" message |
| Google Maps returns only 1 route instead of multiple alternatives | The route panel shows only one option. The manager cannot compare alternatives to find the best route for the bus | ⚠️ Gap — the number of alternative routes depends on Google Maps availability and is outside the school's control |
| Browser is outdated and does not support Google Maps JavaScript | The map area is blank or shows a "Please upgrade your browser" message. The Pickup Stops List tab is unusable | Technical limitation — the user must open the screen in a modern browser like Chrome or Firefox |

---

## Success Scenarios — When Everything Works

**SC-001 — Transport Manager Plans a New Route for a New Residential Area**
Mrs. Desai enters the Bloomingdale Township gate as the start and the school as the end, selects Morning Shift, and clicks Find Routes. Google Maps returns four route options. The shortest route (15.2 km) is selected by default. The map draws the route in blue, and six numbered green circles appear — each representing an existing stop within 1.5 km of the route. Mrs. Desai clicks on each circle to see stop details and confirms that five of the six stops serve Bloomingdale families. She notes that the remaining families need a new stop and proceeds to register it in the Trans. Stops screen. The map view has saved her at least two hours of manual cross-checking against printed maps.

**SC-002 — Monthly Coverage Check Reveals a Stop with Wrong Coordinates**
Mrs. Desai runs her monthly coverage check for Route 7. She enters the start (Marathalli Bridge) and end (school) and examines the map. She notices that the "HAL Layout Phase 2" stop appears 3.2 km away from the route path — clearly incorrect. She opens the stop record, corrects the coordinates using the Google Maps pin, and re-runs the route check. The stop now appears within 800 metres of the route. The coverage issue is resolved in 10 minutes instead of requiring a physical site visit.

**SC-003 — Parent Orientation Session Uses Live Route Map**
During the March Open House, a parent from Whitefield asks whether the bus passes their street. Mrs. Desai opens the Pickup Stops List on the projector, enters the school and the parent's residential area, and displays three route options. She selects Route 2 (14.2 km) because it passes closest to the parent's street. The parent sees their child's stop — a numbered green circle 600 metres from the route — and the pick-up time displayed in the info popup. The parent is satisfied and proceeds to complete the transport registration.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Google Maps API Key Not Configured — Screen Is Completely Unusable**
The school's IT department has recently migrated the system to a new server but forgot to configure the Google Maps API key in the new environment. When Mrs. Desai opens the Pickup Stops List tab, the map area is grey and shows a Google Maps error. The address fields do not suggest any addresses as she types. The "Find Routes" button appears to work (cursor changes, button depresses) but nothing happens when clicked. The entire screen is useless until the IT team adds the API key. Mrs. Desai has to fall back to manual route planning using printed Google Maps directions for two weeks, adding approximately 5 hours of extra work per week.

**FC-002 — Stop Coordinates Entered Incorrectly — Route Coverage Appears Incomplete**
A new clerk registered 12 new pickup stops last week but accidentally entered the wrong latitude and longitude for three of them — the coordinates point to locations 5 to 10 km away from the actual addresses. When Mrs. Desai runs a coverage check, these three stops do not appear anywhere near any route on the map. She assumes the stops have not been registered yet and creates duplicate records. The system now has six stops (three correct, three incorrect duplicates) for the same three locations. Two weeks later, when the bus drivers pick up students, they find that two buses are assigned to the same stop because of the duplicate records. The confusion takes an entire day to resolve, and Mrs. Desai has to delete the duplicate stops and correct the original coordinates.

**FC-003 — Browser Freezes When Checking a Route with 3,000+ Stops**
Green Valley School has accumulated 3,200 pickup stops over five years. Mrs. Desai needs to check whether a proposed new route covers the central area. She enters the start and end locations and clicks Find Routes. The browser freezes for 45 seconds because the system is trying to match 3,200 stops against each route inside her web browser — the calculations are too heavy for her office computer. The browser eventually becomes responsive again, but Mrs. Desai cannot tell whether the route check completed or failed. She refreshes the page and tries again with a smaller area by using a nearby landmark as the start point instead, getting only 400 stops within that region. She completes her analysis in pieces rather than all at once.

**FC-004 — Internet Disruption During Route Search — No Error Message Shown**
Mrs. Desai is in a meeting with the school principal and needs to show a proposed route on the map. She opens the Pickup Stops List, enters the locations, and clicks Find Routes. The school's internet connection is slow due to a fiber cut in the area. The button shows a spinning indicator for over a minute. Mrs. Desai is not sure whether the system is still working or if the request has failed. She clicks the button again, causing a second request to be sent. Eventually, two sets of routes appear on the map, overlapping each other. The map becomes cluttered and hard to read. Mrs. Desai has to click Clear All and start over. The system does not show any "Connection lost" or "Request timed out" message to help her understand what went wrong.
