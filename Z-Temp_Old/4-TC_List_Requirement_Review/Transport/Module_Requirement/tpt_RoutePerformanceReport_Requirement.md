# Route Performance Report

## What This Report Shows

Mrs. Desai, the Principal of Green Valley School, uses this report to see how her school bus routes are performing daily. This report tells her which routes are running smoothly and which routes have problems like students not boarding on time or buses running late. It shows the complete picture of every route from how many students are assigned to how many actually travel and reach home. The report helps Mrs. Desai answer questions like "Are our buses running on time?" and "Are all allocated students actually using the transport?"

This report is like a health checkup for the entire transport system of Green Valley School. It gives one-screen visibility into route-wise performance so that Mrs. Desai does not have to call the transport in-charge every day for updates. She can see everything in numbers and charts at a single glance.

## Default Data Load / Filters

When Mrs. Desai opens this report, it automatically shows data for the current academic session. The system picks the latest running session by default so that she does not have to select it manually each time. The date range defaults to the current month starting from the 1st to today's date. If today is the 15th of July 2026, the system will show data from 1st July 2026 to 15th July 2026.

The report includes five main filters:

First, the Date Range filter. Mrs. Desai can change the from and to dates if she wants to see older data or a specific period like a single week or a full term.

Second, the Academic Session filter. This dropdown shows all active and past academic sessions. By default it shows the current session, but Mrs. Desai can switch to a previous session to compare how routes performed last year.

Third, the Route filter. This is a dropdown listing all active routes like "Route A - MG Road", "Route B - Lake View", "Route C - Market Square", etc. By default no specific route is selected so the report shows combined data. If Mrs. Desai selects one specific route, the report narrows down to show data for only that route.

Fourth, the Vehicle filter. This dropdown lists all active vehicles by registration and vehicle number. Mrs. Desai can filter the report to see performance data for buses assigned to a specific vehicle.

Fifth, the Shift filter. This dropdown shows all active shifts (morning/evening etc.). Mrs. Desai can filter by shift to see route performance for a specific time of day.

All filters work together. If Mrs. Desai selects a date range of July 2026, Academic Session 2025-26, and Route B, she will see only Route B's performance for July 2026.

## When This Report Is Used

Mrs. Desai uses this report every morning during the first period to check yesterday's transport performance. She also uses it at the end of every week during the Friday staff meeting to discuss transport issues. The transport in-charge Mr. Sharma checks this report daily at 10 AM after all buses return from the morning drop.

This report is also used when parents complain that their child's bus is always late. Mrs. Desai opens this report, filters by the specific route, and checks the average delay minutes. If the delay is high, she calls a meeting with the driver and conductor.

At the end of every term, Mrs. Desai uses this report to decide which routes need more buses and which routes can be merged. If a route has very low boarding compliance, she investigates whether students have left the school or if the pickup timing needs adjustment.

## Key Metrics / KPIs

The report shows four important numbers at the top as summary cards. These numbers change automatically when Mrs. Desai applies any filter.

Total Routes is the first number. It shows how many unique routes are included in the current view. If no route filter is applied, this will be the total active routes in the school. If Route B is selected, this number becomes 1.

Allocated Students is the second number. It counts how many students are assigned to the selected routes. This includes all students who have transport enabled in their profile and are linked to a route.

Boarded Count is the third number. It shows how many students actually got on the bus in the selected date range. This is counted from the boarding logs where students marked "boarded" successfully.

Avg Pickup Delay is the fourth number. This is calculated from the trip stop details. If a bus was supposed to reach a stop at 7:30 AM but actually reached at 7:45 AM, that is a 15-minute delay. The report averages all such delays across all trips in the selected date range and shows one number.

Below the KPI cards, a detail table shows route-wise breakdown with additional columns including Unboarded Count, Boarding Compliance %, Unboarding Compliance %, and Avg Delay per route.

## Charts and Visualizations

The report has three main charts that make it easy for Mrs. Desai to understand the data without reading numbers.

The first chart is a Line chart for Route Compliance Analysis. This chart has route names on the bottom and percentage values on the left side from 0 to 100%. Two lines are plotted: one line for Boarding Compliance % and one line for Unboarding Compliance %. The area below each line is filled with a subtle color. If the boarding compliance line for Route A is at 90% and the unboarding compliance line is at 85%, Mrs. Desai knows both pickup and drop-off are running well on that route. If a route's line drops low, she can spot the problem route immediately.

The second chart is a horizontal Bar chart for Route Delay Analysis. This chart has route names on the left side and delay minutes on the bottom. Each route has a single horizontal bar colored based on severity: green for 5 minutes or less, yellow for 5-15 minutes, and red for more than 15 minutes. Mrs. Desai can instantly see which routes are running late. Long red bars mean the route needs immediate attention.

The third chart is a Bar chart for Route Performance Overview. This chart has route names on the bottom side and student numbers on the left side. Each route has three bars side by side. One bar shows allocated students (green), another shows boarded students (blue), and another shows unboarded students (yellow). Mrs. Desai can switch between a Grouped view (bars side by side) and a Stacked view (bars stacked on top of each other) using toggle buttons at the top right of the chart card. When Mrs. Desai looks at this chart, she can immediately see which routes have a big gap between allocation and boarding. For example, if Route A has a tall green bar for allocated students but a short blue bar for boarded students, she knows something is wrong on Route A.

All charts update automatically when Mrs. Desai changes any filter. If she selects only Route C, all charts show only Route C's data.

## Data Sources (tables used)

This report pulls data from four different places in the system. These are like four different notebooks that the system reads from and combines together.

The first source is the Route Master table. The system calls this tpt_route. This is the main notebook where all routes are defined. It stores the route name, route code, start point, end point, total distance, and status (active or inactive). The report uses this table to know which routes exist and what to call them in the dropdown and charts.

The second source is the Student Route Allocation table. The system calls this tpt_student_route_allocation_jnt. This is the notebook that stores which student is assigned to which route for which academic session. The report counts rows from this table to get the Allocated Students number. One row means one student allocated to one route.

The third source is the Student Boarding Log table. The system calls this tpt_student_boarding_log. This is like a daily attendance register for the bus. Every time a student boards or gets off the bus, a new entry is created in this table. The report counts boarded entries and unboarded entries from this table. The report also uses the date and time from this table to filter by date range.

The fourth source is the Trip Stop Detail table. The system calls this tpt_trip_stop_detail. This notebook stores information about each stop on each trip. It records the scheduled arrival time and the actual arrival time. The report uses this table to calculate the average delay minutes by comparing scheduled time with actual time for each stop on each trip.

These four tables are joined together using the route ID and route allocation ID. The system connects them like puzzle pieces to build the complete picture.

## Permissions

This report is protected by a permission rule. The system checks whether Mrs. Desai's user account has the right permission before showing any data. The permission key is called "tenant.route-performance.viewAny". This is like a security badge. Only users who have this badge in their profile can open and view this report.

If a teacher tries to open this report but does not have the route-performance.viewAny permission, the system will show an error message saying "You do not have permission to view this report." The screen will remain blank and no data will be shown.

Permission is assigned by the school's system administrator from the user management section. Mrs. Desai has this permission by default as the Principal. The transport in-charge Mr. Sharma also has it. Class teachers do not have this permission unless specially assigned.

## Who Can Access

The following people at Green Valley School can access this report:

Mrs. Desai, the Principal, can access it because she needs to oversee all school operations including transport.

Mr. Sharma, the Transport In-charge, can access it because he manages the daily bus operations and needs to monitor route performance.

The Vice Principal can access it for backup purposes when Mrs. Desai is on leave.

The School Administrator can access it for system management and data verification.

Class teachers, parents, and students cannot access this report. It is designed for administrative and transport management use only.

## Example Scenario

It is Wednesday morning, 8th July 2026. Mrs. Desai has received three complaints in the last two days from parents of students on Route B - Lake View. The parents say the bus has been arriving 20 to 25 minutes late every morning.

Mrs. Desai opens the Route Performance Report. She sees the default data for July 2026. The total routes show 5, allocated students show 340, boarded count shows 312, and unboarded count shows 28. The average delay minutes shows 8 minutes across all routes. This looks normal overall.

But she wants to check Route B specifically. She selects "Route B - Lake View" from the Route filter. The numbers change. Route B has 80 allocated students. Boarded count is 68, unboarded count is 12. The boarding compliance is 85%, which is lower than the school average of 92%. The average delay minutes shows 22 minutes.

Mrs. Desai now has proof that Route B is indeed running late. She calls Mr. Sharma and tells him to investigate why Route B has a 22-minute average delay. She also asks him to find out why 12 students are not boarding regularly. Maybe the bus is arriving late so parents have started dropping children directly to school. Mr. Sharma investigates and finds that the driver on Route B has been taking a different road because of construction on the usual road. He instructs the driver to take a longer but less crowded alternate route that has less traffic. By next week, the average delay for Route B comes down to 7 minutes.

## Logic Flow (how the report query works)

The system follows a step-by-step process to build this report. Here is how it works in simple language.

Step one: The system checks the permission. When Mrs. Desai clicks on the report menu, the system first looks at her user account to see if she has the route-performance.viewAny badge. If yes, the report screen opens. If no, an error message appears.

Step two: The system reads the filters. The system looks at what Mrs. Desai has selected in the three filters. It takes the date range, academic session, and route selection and stores them in memory.

Step three: The system counts Total Routes. It opens the Route Master notebook and counts all routes that are marked as active. If a specific route is selected in the filter, the count becomes 1.

Step four: The system counts Allocated Students. It opens the Student Route Allocation notebook and counts how many students are allocated to the selected routes in the selected academic session. If a specific route is selected, it only counts allocations for that route.

Step five: The system calculates Boarded Count and Unboarded Count. It opens the Student Boarding Log notebook and filters entries that fall within the selected date range and belong to the selected routes. It counts how many entries have the status "boarded" and how many have the status "unboarded". If a student has multiple entries across different dates, each entry is counted separately for each day.

Step six: The system calculates Avg Delay Minutes. It opens the Trip Stop Detail notebook and filters records for the selected routes and date range. For each record, it calculates the difference between the actual arrival time and the scheduled arrival time. If the actual time is later than scheduled time, it is a positive delay. If the actual time is earlier, it is recorded as zero delay, not negative. The system adds up all the delay minutes and divides by the total number of stops to get the average. This average is then rounded to one decimal place.

Step seven: The system calculates Boarding Compliance Percentage. It takes the Boarded Count and divides it by the Allocated Students count, then multiplies by 100. If allocated students are zero for a route, the compliance is shown as zero to avoid any calculation errors.

Step eight: The system calculates Unboarding Compliance Percentage. It takes the count of students who were successfully dropped at their correct stop and divides by the total number of students who were scheduled to get off. This is multiplied by 100 to get the percentage.

Step nine: The system prepares the chart data. For the doughnut chart, it takes the boarded percentage and unboarded percentage and creates two data points. For the bar chart, it groups data by route name with two values per route: allocated count and boarded count.

Step ten: The system prepares the data for display on the screen. All the numbers, labels, and chart data are formatted into a structure that the screen can understand. The system also calculates totals and subtotals where needed. For example, if five routes are selected, the system shows a subtotal row for each route and a grand total at the end.

Step eleven: The system sends all this calculated data to the screen. Mrs. Desai sees the six KPI numbers at the top in large bold text so they are easy to read. Below the KPIs, she sees the doughnut chart on the left side and a summary table on the right side showing route names with their individual compliance percentages. Below that, the bar chart spans the full width of the screen with all routes displayed. The charts and numbers are connected. If she hovers her mouse over a bar in the chart, a small popup appears showing the exact number.

Step twelve: The system waits for any filter change. If Mrs. Desai changes any filter, the system goes back to step two and runs the entire process again with the new filter values. This happens almost instantly because the system is optimized for speed. Mrs. Desai does not have to wait or click a refresh button. The data on the screen updates automatically within a few seconds.

Step thirteen: When Mrs. Desai is done, she can also download the report. The system offers an export option that creates a PDF or Excel file of the current view. This export contains the same data that is shown on the screen, including the KPI numbers and copies of the charts. Mrs. Desai uses this export feature when she needs to share the report with the school management board or attach it to an email. The exported file is formatted neatly with the Green Valley School logo at the top and the date and time of export at the bottom.
