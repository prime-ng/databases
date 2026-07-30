# Transport Dashboard — Business Requirements

## What This Screen Does

The Transport Dashboard is the command center for the Transport Manager. It brings together information from across the entire fleet — how many vehicles are on the road right now, how many trips are running today, which vehicles have insurance or fitness certificates expiring soon, what maintenance work is due, whether drivers have checked in for the day, how much fuel has been consumed this month, and any recent incident reports — all displayed on a single screen that updates based on the date range the manager selects.

Rather than forcing the Transport Manager to open separate screens for vehicles, trips, maintenance, and fuel, this screen gives them a single-pane-of-glass overview of the entire fleet's operational health.

Without this dashboard, the Transport Manager would have to manually piece together information from printouts, phone calls with drivers, spreadsheets tracking maintenance schedules, and separate logbooks for fuel and incidents — a fragmented process that makes it nearly impossible to spot problems before they escalate.

---

## Default Data Load

When the Transport Manager opens the dashboard, the system automatically gathers and displays seven groups of information at once. These seven groups — called the KPI summary cards, the trip trend chart, the vehicle status breakdown, the active route assignments, the maintenance alerts, the additional metrics (fuel, attendance, incidents), and the recent trips list — are all loaded from the school's database the moment the screen opens. The Transport Manager does not need to click anything or wait for individual sections to load; everything appears together.

If the Transport Manager has not selected a specific date range, the system shows information for the current month — from the 1st day to today's date. The date range affects most of the dashboard sections, but some parts (fuel totals, attendance, and incident counts) always show the current month regardless of the date range selected.

---

## When This Screen Is Used

- **Morning Briefing (7:45 AM)** — Mrs. Desai, the Transport Manager, opens the dashboard first thing every morning to see how many trips are scheduled for today, which drivers have checked in, whether any vehicle documents are expiring, and whether any buses are in the workshop. She spends about 2 minutes scanning the dashboard before the morning rush begins. If she sees a red alert, she can act immediately — calling the workshop to release a repaired bus or calling a spare driver to cover an absence.

- **Maintenance Planning (Weekly)** — Rajesh, the Fleet Supervisor, checks the dashboard every Monday morning to review the Maintenance Alerts section. He sees which vehicles have insurance or fitness certificates expiring in the next 7 days, and which vehicles have pending service requests. He plans the workshop schedule for the week based on this information, prioritising vehicles whose documents expire soonest.

- **Management Review (Monthly)** — The School Administrator or Transport Manager opens the dashboard during the monthly operations review meeting to present vehicle utilisation rates (what percentage of the fleet is actually on the road), fuel cost trends compared to the previous month, and incident statistics. These numbers go into the Principal's monthly report.

- **Emergency Response (As Needed)** — When an incident is reported — a breakdown on the highway, a minor collision, or a student injury — the dashboard's recent trips and incident metrics give Mrs. Desai immediate context. She can see which vehicle was involved, which route it was on, and the severity of past incidents involving the same driver or vehicle.

---

## Key Dashboard Widgets and Metrics

**KPI Summary Cards (4 numbers at the top)**
Four large numbers displayed across the top of the screen: the count of vehicles that are currently active and available for trips, the number of drivers on the payroll, how many trips are scheduled or running today, and how many students are enrolled in the transport service this academic year.

**Trip Trend Chart**
A daily chart showing how many trips were Scheduled, Completed, Cancelled, or are still Ongoing for each day within the selected date range. The Transport Manager can see at a glance whether trip completion rates are normal or whether there are unusual numbers of cancellations on certain days.

**Vehicle Status Breakdown**
A summary of the entire fleet showing: the total number of vehicles the school owns, how many are currently on the road running trips, how many are available for assignment (active but not on the road and not in the workshop), how many are in the workshop for maintenance, how many are out of service (retired, sold, or deactivated), and the utilisation rate — the percentage of the fleet that is actually being used for trips.

**Active Route Assignments**
Up to 10 of the most recent driver-route-vehicle combinations that are currently active. For each assignment, the system shows which route the bus is running, which shift it belongs to (Morning, Afternoon, or Evening), the vehicle registration number, the driver's name, and how many students are assigned to that route.

**Maintenance Alerts**
Up to 10 alerts displayed in priority order. These alerts come from three sources: vehicles whose fitness certificate is about to expire or has already expired, vehicles whose insurance policy is about to expire or has already expired, and vehicles that have pending or approved maintenance work that has not yet been completed. Each alert is labelled as Overdue (expired already), Due Soon (expiring within 7 days), or Upcoming (expiring later but worth noting).

**Additional Metrics (3 sub-sections)**
- Fuel: The total amount of fuel purchased this month and the total cost, compared to the previous month so the manager can see whether fuel spending is going up or down.
- Driver Attendance: How many drivers are expected today, how many have checked in, and the attendance percentage.
- Incidents: How many incidents have been reported this month, how many have been resolved, and a breakdown by severity — High, Medium, or Low.

**Recent Trips**
The 10 most recent trips, showing the trip reference number, the date and time, the route name, the vehicle registration number, the driver's name, the current status of the trip, and how long the trip took (from start time to end time).

---

## Business Rules and Conditions

**Date Range Filter Scope**
When the Transport Manager selects a date range, the system applies that filter to trips, vehicle status, active routes, and maintenance alerts. However, the fuel consumption totals, driver attendance rate, and incident counts always show the current month regardless of the date range selected. This means if the manager selects last month's dates, the fuel and incident sections will still show this month's numbers, which can be confusing.

**Vehicle Availability Calculation**
The system calculates available vehicles using this logic: start with all active vehicles, subtract those currently on the road running trips, subtract those in the workshop for maintenance. What remains is the pool of available vehicles. If the math produces a negative number (which should not happen but can if the on-road and maintenance counts overlap), the system forces the result to zero to avoid showing a negative count.

**Maintenance Alert Classification**
Each compliance document alert is classified into one of three categories: Overdue — the expiry date has already passed; Due Soon — the expiry date falls within the next 7 days; or Upcoming — the expiry date is beyond 7 days but worth monitoring. For workshop maintenance alerts, the classification is simply Pending.

**Fleet Utilisation Rate**
The system calculates what percentage of the total fleet is currently on the road running trips. It is displayed as a round number. If the school has no vehicles registered, the utilisation rate shows 0%.

**Trip Status Values**
Every trip in the system has one of four statuses: Scheduled (planned but not yet started), Ongoing (currently running), Completed (finished), or Cancelled (called off). These four statuses are fixed and cannot be customised by the school.

---

## Workflow Steps

**Reviewing the Morning Fleet Status**
It is 7:45 AM at Green Valley School. Mrs. Desai logs into the system and navigates to Transport → Dashboard. The dashboard loads immediately, showing four large numbers at the top: 16 active vehicles, 12 drivers, 8 trips scheduled for today, and 320 students registered for transport. She glances at the Maintenance Alerts section on the right side and sees a red badge — Bus KL-05's insurance expires tomorrow. She clicks the alert, notes the vehicle registration number, and calls the insurance agent to process the renewal before the bus goes out in the morning. She then scans the Recent Trips list at the bottom and notices that yesterday's Trip #TRP-00042 is still showing as "Ongoing" — it should have been completed by 4 PM yesterday. She flags this for follow-up with the driver.

---

## Example Scenario

Green Valley School is in the first week of the new academic year. Mrs. Desai opens the Transport Dashboard for the first time this term to check whether the fleet is ready. The system defaults to the current month.

The four KPI cards at the top show: 16 active vehicles (all 12 buses, 2 vans, and 2 staff cars registered in the system), 12 drivers on the payroll, 0 trips so far (the school year starts next week, so no trips have been generated yet), and 280 students registered for transport services.

The Vehicle Status section shows all 16 vehicles as active, 0 on the road (no trips running yet), and a utilisation rate of 0%. The Maintenance Alerts section flags two vehicles whose fitness certificates expire within the next 30 days — Bus KL-07 (expires in 22 days) and Van VN-03 (expires in 18 days). Mrs. Desai makes a note to schedule their fitness tests before the trips begin next week.

The Fuel section shows ₹0 for the current month (no trips yet) and ₹12,500 for the previous month from practice runs and staff transport. Driver attendance shows all 12 drivers present at the morning roll call. The Incidents section shows 0 for the month — a clean start to the year.

Mrs. Desai is satisfied. She closes the dashboard and proceeds to the Trip Management screen to start generating trips for the first week of school.

---

## Related Screens

- **Vehicle Master** — Where the Transport Manager manages vehicle compliance documents and expiry dates that appear in the maintenance alerts section
- **Driver-Route-Vehicle Assignment** — Where the active route assignments visible on the dashboard are created and managed
- **Trip Management** — Where scheduled, ongoing, and completed trips are created and tracked — this data powers the chart and recent trips list
- **Driver Attendance** — Where the attendance rate shown on the dashboard is recorded each day
- **Vehicle Fuel Log** — Where fuel purchases and costs are recorded — this data feeds the fuel metrics section
- **Vehicle Service & Maintenance** — Where service requests and maintenance records are managed — this data appears in the maintenance alerts

---

## Requirements

- The dashboard loads seven data groups from the system's database when opened: KPI counts, trip chart, vehicle status, active routes, maintenance alerts, additional metrics (fuel/attendance/incidents), and recent trips
- The dashboard can be filtered by date range; without a range, it defaults to the current month
- The dashboard is a read-only screen — no data entry or form submission occurs here
- A dedicated permission setting controls who can view the dashboard
- Activity logging is not implemented for this screen — no record is created when someone views it

---

## Who Can Access

- **Transport Manager** — Has full access to the dashboard. This is the primary user who checks the dashboard daily for morning briefings, maintenance planning, and operational oversight. Mrs. Desai from Green Valley School uses this screen every morning.
- **Fleet Supervisor** — Can view the dashboard to check maintenance alerts, vehicle status, and driver attendance. Rajesh, the workshop in-charge, uses this screen every Monday to plan the week's maintenance schedule.
- **School Administrator** — Has access to view the dashboard during monthly review meetings. They look at utilisation rates, fuel cost trends, and incident statistics for the Principal's report.
- **Principal or Vice Principal** — Can view the dashboard selectively during management reviews, typically through the administrator's login.
- **Driver** — Does not have access to the dashboard. Drivers interact with the system only through their assigned trips and attendance scanning.

Behind the scenes, each person's access is controlled by a permission setting configured for their user account. If someone tries to view the dashboard without the necessary permission, the system displays an "Access Denied" message and does not load any data.

---

## Logic Flow

When Mrs. Desai opens the Transport Dashboard, the system immediately begins gathering data from across the fleet. It starts by checking whether Mrs. Desai has the right to view this screen — if she does not, the process stops immediately and she sees an "Access Denied" message. If she has permission, the system notes the date range she has selected (or defaults to the current month if she has not chosen one).

The system then runs seven data-gathering operations in sequence. First, it counts four key numbers: how many vehicles are active in the fleet, how many drivers are on the payroll, how many trips fall within the selected date range, and how many students are currently registered for transport. These four numbers become the KPI cards at the top of the dashboard.

Next, the system builds the trip trend chart. It looks at every single day within the selected date range and, for each day, counts how many trips were Scheduled, Completed, Cancelled, or are still Ongoing. For a 30-day range, this means examining 120 individual data points (30 days times 4 statuses).

Then the system calculates the vehicle status breakdown. It counts the total fleet size, determines how many vehicles are currently on the road (those that have trips running right now), how many are in the workshop for maintenance, and how many are out of service. Using these numbers, it calculates the available vehicle pool and the utilisation rate.

For the active route assignments, the system looks at the most recent 10 driver-route-vehicle combinations that are effective within the selected date range, and shows each with the route name, shift, vehicle registration, driver name, and student count.

The maintenance alerts are gathered next. The system examines every vehicle in the fleet for compliance document expiry dates — fitness certificates, insurance policies, pollution certificates, and fire extinguisher certificates. It identifies which documents are overdue (already expired), due soon (expiring within 7 days), or upcoming. It also checks for any pending maintenance work that has not been completed. The system returns the top 10 alerts combined from all these checks.

The additional metrics — fuel consumption, driver attendance, and incident counts — are compiled next. The fuel section totals all fuel purchases for the current month and compares them to the previous month. The attendance section counts how many drivers were expected today versus how many checked in. The incidents section counts how many incidents were reported this month, broken down by severity level.

Finally, the system fetches the 10 most recent trips across the entire fleet, ordered by date and time, and displays them with their route, vehicle, driver, and duration details.

All seven groups of data are combined and displayed on the dashboard at once. Mrs. Desai sees the complete picture of her fleet's operational health without having to navigate through multiple screens.

---

## Validate Before Save

Not applicable — The Transport Dashboard is a read-only screen that displays information from across the fleet. No data is entered or submitted from this screen, so there are no validation rules to check.

---

## What Can Go Wrong

| Problem | What the User Sees | What Type of Issue |
|---------|-------------------|-------------------|
| User selects an invalid date (for example, typing "ABC" or entering the 32nd day of a month) | The system shows a generic error message and the dashboard may fail to load entirely | Data format error — no user-friendly handling in place |
| User selects a date range with no data (for example, a past year when the school had no fleet) | The dashboard loads but all sections show 0 or remain empty — no trips, no vehicles, no alerts. No message explains why | Silent empty state — confusing for new users |
| No academic session is configured for the current period | The system returns 0 students, 0 trips, and empty charts without indicating that the academic session is missing | Configuration gap — silent failure |
| User tries to view the dashboard without permission | The system displays a blank "Access Denied" page | Permission error — system blocks access |
| The dashboard takes too long to load (more than 5 to 10 seconds) when a large date range is selected | The user sees a loading indicator that eventually resolves, but the experience is noticeably slow | Performance issue — too many calculations for wide date ranges |
| The fuel section shows different numbers from what the manager expects | The manager may be looking at a past date range, not realising that fuel totals always show the current month regardless of the date filter | 🔴 Gap — date filter does not apply to all sections, which can mislead users |
| A vehicle shows as "Available" on the dashboard but it should actually be in the workshop | The system calculates available vehicles based on trip records, but if a vehicle is in the workshop and still has an active trip record from yesterday that was not closed, it may not be counted correctly | 🔴 Gap — overlapping data sources can produce inaccurate availability counts |

---

## Success Scenarios — When Everything Works

**SC-001 — Morning Fleet Overview at Green Valley School**
Mrs. Desai opens the Transport Dashboard at 7:45 AM on a Tuesday. The date range defaults to the current month. The KPI cards show: 16 active vehicles, 12 drivers on duty, 8 trips scheduled for today, and 320 students enrolled in transport. The Trip Trend Chart shows that over the past week, an average of 7 trips per day have been completed with only 1 cancellation all week — a 98% completion rate. The Vehicle Status section shows utilisation at 62% (10 vehicles on the road, 4 available, 2 in maintenance). Two maintenance alerts are flagged: one insurance renewal due in 3 days (Bus KL-05) and one pending service (Van VN-02). Driver attendance shows 11 of 12 drivers present (91%), and the missing driver has already called in sick. Mrs. Desai calls the spare driver to cover the absent driver's route. Within 5 minutes of opening the dashboard, she has a complete picture of the day's operations and has already taken action on the one issue that needed attention.

**SC-002 — End-of-Month Management Review**
The School Administrator opens the dashboard during the monthly operations meeting with the Principal. Using the date range filter, she selects the past 30 days. The Trip Trend Chart shows that 210 trips were completed this month with only 3 cancellations (all due to vehicle breakdowns that were resolved the same day). The utilisation rate averaged 68%, up from 62% last month — indicating the fleet is being used more efficiently. Fuel costs totalled ₹1,85,000 for the month, a 5% increase over last month, which the Administrator attributes to the new route added for the Whitefield residential colony. Incident reports show 2 minor incidents (both low severity — a side mirror scratch and a late arrival) with both resolved. The Principal is satisfied with the report and approves the budget for two new buses next quarter.

**SC-003 — Incident Response Coordination**
At 10:30 AM, Mrs. Desai receives a call that Bus KL-07 has broken down on the highway with 35 students on board. She immediately opens the dashboard and checks the Recent Trips section. She finds the trip for Bus KL-07 — it is still showing as "Ongoing" and started at 7:30 AM. She notes the driver's name (Ramesh), the route (Route A-12, Whitefield to School), and the last known location. Using the information on the dashboard, she dispatches the nearest available bus (Bus KL-03, which the dashboard shows as "Available") to pick up the students. She then checks the Incidents section to see if there is already an incident report filed for this breakdown — there is not, so she proceeds to the Incident Reporting screen to log it. The dashboard gave her all the information she needed within 30 seconds to coordinate the rescue.

---

## Failure Scenarios — What Could Go Wrong

**FC-001 — Empty Dashboard with No Explanation**
It is the first day of the new academic year. The school has registered all its vehicles and drivers, but no trips have been created yet. Mrs. Desai opens the dashboard and sees: 16 active vehicles, 12 drivers, 0 trips, and 320 students. The chart is blank — no data points at all. The vehicle status shows 0 on the road, utilisation 0%. The recent trips list is empty. No message tells her "Trips have not been generated for this period" or "Create trips in the Trip Management screen to see data here." Mrs. Desai is confused — she wonders if the system is broken. She has to call the system administrator to confirm that the dashboard is working correctly and that the empty state is because trips have not been created yet.

**FC-002 — Dashboard Loads Slowly with Large Date Range**
The Principal asks Mrs. Desai for a year-end report covering all 12 months of the academic year. Mrs. Desai selects a date range from April to March (365 days). The dashboard takes more than 20 seconds to load. The trip chart alone has to process 365 days across 4 trip statuses — nearly 1,500 individual calculations. During this time, Mrs. Desai cannot use the system. She worries the system has frozen or crashed. When the dashboard finally loads, the Principal has already moved on to the next agenda item. The slow performance makes the system look unreliable during a management presentation.

**FC-003 — Conflicting Vehicle Availability Numbers**
The dashboard shows a utilisation rate that does not match reality. It reports 12 vehicles on the road, but Mrs. Desai knows she only sent out 10 buses this morning. The discrepancy happens because the system counts a vehicle as "on the road" if it still has a trip record from yesterday that was not properly closed. Additionally, the "Available" count shows zero even though Mrs. Desai knows two buses are sitting idle in the parking lot — they are being double-counted in both the "on the road" and "in maintenance" categories. Mrs. Desai cannot trust the numbers on the dashboard and has to cross-check against her manual logbook, defeating the purpose of having a digital dashboard.

**FC-004 — Fuel and Attendance Metrics Show Wrong Time Period**
Mrs. Desai selects last month's date range (June 1 to June 30) to review June's operations. The trip chart and vehicle status correctly show June data. But the Fuel section shows July's fuel consumption (the current month), and the Incident section also shows July's incidents. Mrs. Desai compiles her June report with the wrong fuel and incident numbers. She discovers the error only when the Principal compares her report against the accounts department's fuel records and finds a mismatch of ₹23,000. This erodes trust in the system's reporting accuracy and takes 2 hours to redo the report.

---

## Other Modules and Tables This Screen Relies On

| Dependency | What It Provides |
|-----------|-----------------|
| Vehicle Records | Vehicle counts, status information, fitness and insurance expiry dates |
| Personnel Records | Active driver count |
| Shift Records | Shift names shown alongside active routes |
| Route Records | Route names shown alongside active routes |
| Trip Records | Trip numbers, chart data, on-road vehicle count, recent trips list |
| Driver-Route-Vehicle Assignments | Active route assignments shown on the dashboard |
| Student Route Allocations | Transport student count |
| Vehicle Maintenance Records | Maintenance alerts |
| Vehicle Service Requests | Link to maintenance records for alert lookup |
| Vehicle Fuel Log | Fuel consumption and cost data |
| Driver Attendance Records | Today's driver attendance rate |
| Trip Incident Records | Incident counts by severity level |
| Daily Vehicle Inspection Records | Inspection data linked to maintenance lookup |
