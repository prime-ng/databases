# Transport Reports Design – v3.1 (Transport DDL v2.2 Enhancements)

This document is an **updated version of tpt_Reports_Design_v3.md**, enhanced to align with
**Transport Module DDL v2.2**. It incorporates:

- Event-based **Student Boarding / Unboarding**
- **Transport Notifications & Alerts**
- Safety-first and audit-ready logic
- Updates to existing reports where required

The format, structure, and philosophy remain **identical** to v3.

---

## CHANGE LOG

| Version | Description |
|-------|------------|
| v3.0 | Consolidated 9 core transport reports |
| v3.1 | Added boarding/unboarding + notifications, updated 4 reports |
| v5.0 | Updated SQL Queries to align with DDL v2.2 (Dec 31st Changes) |

---

## UPDATED REPORTS (v2.2)

---

## 1. Route Performance Report (UPDATED)

### Report Title
Route Performance Report

### What this Report Covers
- Route configuration & health
- Student allocation vs actual boarding
- Unboarding compliance (safety)
- Delay & discipline indicators

### Useful For
- Transport Head
- Principal
- Management

### Fields Shown in Report
- Route Name
- Pickup / Drop
- Total Stops
- Allocated Students
- Boarded Students
- Unboarded Students
- Boarding Compliance %
- Unboarding Compliance %
- Avg Delay


### Tables Used in Report
- tpt_route
- tpt_pickup_points_route_jnt
- tpt_student_route_allocation_jnt
- tpt_student_boarding_log
- tpt_trip_stop_detail (for estimated vs actual time)

### Filters Required
- Academic Session
- Route
- Vehicle
- Shift
- Date Range

### MySQL Query (Reference)
```sql
SELECT
  r.name AS route_name,
  r.pickup_drop AS pickup_drop,
  COUNT(DISTINCT rs.pickup_point_id) AS total_stops,
  COUNT(DISTINCT sa.student_id) AS allocated_students,
  COUNT(DISTINCT CASE WHEN sb.boarding_time IS NOT NULL THEN sb.student_id END) AS boarded_students,
  COUNT(DISTINCT CASE WHEN sb.unboarding_time IS NOT NULL THEN sb.student_id END) AS unboarded_students,
  ROUND(COUNT(DISTINCT CASE WHEN sb.boarding_time IS NOT NULL THEN sb.student_id END) / NULLIF(COUNT(DISTINCT sa.student_id),0) * 100, 2) AS boarding_pct,
  ROUND(COUNT(DISTINCT CASE WHEN sb.unboarding_time IS NOT NULL THEN sb.student_id END) / NULLIF(COUNT(DISTINCT sa.student_id),0) * 100, 2) AS unboarding_pct,
  -- Approximating delay from trip stop details (Avg difference between reaching_time and sch_arrival_time)
  AVG(TIMESTAMPDIFF(MINUTE, tsd.sch_arrival_time, tsd.reaching_time)) AS avg_delay_minutes 

FROM tpt_route r
LEFT JOIN tpt_pickup_points_route_jnt rs ON rs.route_id = r.id
-- Allocations (Checking both pickup and drop routes)
LEFT JOIN tpt_student_route_allocation_jnt sa ON (sa.pickup_route_id = r.id OR sa.drop_route_id = r.id)
-- Boarding Logs
LEFT JOIN tpt_student_boarding_log sb ON (sb.boarding_route_id = r.id OR sb.unboarding_route_id = r.id) AND DATE(sb.trip_date) BETWEEN :start_date AND :end_date
-- Trip Details for Delay Calculation
LEFT JOIN tpt_trip t ON (t.route_scheduler_id IN (SELECT id FROM tpt_route_scheduler_jnt WHERE route_id = r.id))
LEFT JOIN tpt_trip_stop_detail tsd ON tsd.trip_id = t.id AND tsd.reached_flag = 1
GROUP BY r.id;
```

### Charts Details
- Bar: Allocated vs Boarded vs Unboarded
- Line: Delay Trend
- KPI: Boarding Compliance %

---

## 2. Student Transport Usage Report (UPDATED)

### Report Title
Student Transport Usage Report

### What this Report Covers
- Transport usage derived from boarding/unboarding events
- Missed pickup / missed drop detection

### Useful For
- Transport Head
- Teachers
- Parents (own child)
- Admin

### Fields Shown in Report
- Student Name
- Class / Section
- Route
- Stop
- Boarding Count
- Unboarding Count
- Missed Boarding Flag
- Missed Drop Flag

### Tables Used in Report
- std_students
- std_student_sessions_jnt
- sch_classes
- sch_sections
- sch_class_section_jnt
- tpt_student_route_allocation_jnt
- tpt_student_boarding_log
- tpt_route
- tpt_pickup_points

### Filters Required
- Academic Session
- Class
- Section
- Route
- Stop
- Student

### MySQL Query (Reference)
```sql
SELECT
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  c.name AS class_name,
  sec.name AS section_name,
  COALESCE(r_pickup.name, r_drop.name) AS route_name,
  COALESCE(st_pickup.name, st_drop.name) AS stop_name,
  
  COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) AS boarding_count,
  COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) AS unboarding_count,
  
  -- Logic: If allocated but no boarding time found for a trip date
  CASE WHEN COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) = 0 THEN 1 ELSE 0 END AS missed_boarding,
  CASE WHEN COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) = 0 THEN 1 ELSE 0 END AS missed_drop

FROM std_students s
JOIN std_student_sessions_jnt ssj ON ssj.student_id = s.id AND ssj.is_current = 1
JOIN sch_class_section_jnt csj ON csj.id = ssj.class_section_id
JOIN sch_classes c ON c.id = csj.class_id
JOIN sch_sections sec ON sec.id = csj.section_id

-- Route Allocation
JOIN tpt_student_route_allocation_jnt sa ON sa.student_session_id = ssj.id
LEFT JOIN tpt_route r_pickup ON r_pickup.id = sa.pickup_route_id
LEFT JOIN tpt_route r_drop ON r_drop.id = sa.drop_route_id
LEFT JOIN tpt_pickup_points st_pickup ON st_pickup.id = sa.pickup_stop_id
LEFT JOIN tpt_pickup_points st_drop ON st_drop.id = sa.drop_stop_id

-- Boarding Logs
LEFT JOIN tpt_student_boarding_log sb ON sb.student_session_id = ssj.id AND DATE(sb.trip_date) BETWEEN :start_date AND :end_date

GROUP BY s.id, r_pickup.name, st_pickup.name;
```

### Charts Details
- Bar: Boarding vs Unboarding by Student
- Heatmap: Missed Events

---

## 3. Stop & Locality Analysis Report (UPDATED)

### Report Title
Stop & Locality Analysis Report

### What this Report Covers
- Boarding density per stop
- Congestion & peak risk analysis

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Stop Name
- Route
- Boarding Count
- Avg Boarding Time
- Congestion Flag

### Tables Used in Report
- tpt_pickup_points
- tpt_student_boarding_log
- tpt_route

### Filters Required
- Route
- Stop
- Locality
- Academic Session

### MySQL Query (Reference)
```sql
SELECT
  st.name AS stop_name,
  r.name AS route_name,
  COUNT(sb.id) AS boarding_count,
  AVG(TIME(sb.boarding_time)) AS avg_boarding_time
FROM tpt_pickup_points st
-- Join boarding logs on boarding_stop_id
JOIN tpt_student_boarding_log sb ON sb.boarding_stop_id = st.id
LEFT JOIN tpt_route r ON r.id = sb.boarding_route_id
WHERE sb.trip_date BETWEEN :start_date AND :end_date
GROUP BY st.id, r.id;
```

### Charts Details
- Heatmap: Boarding Density
- Bar: Top Congested Stops

---

## 4. Trip Execution & Discipline Report (UPDATED)

### Report Title
Trip Execution & Discipline Report

### What this Report Covers
- Planned vs actual trips
- Trip completion validated via unboarding
- Safety Validation (Boarding count == Unboarding count)

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Trip Date
- Route
- Vehicle
- Planned Boardings (from Allocation)
- Actual Boardings
- Actual Unboardings
- Trip Safety Status

### Tables Used in Report
- tpt_trip
- tpt_route
- tpt_vehicle
- tpt_student_boarding_log

### MySQL Query (Reference)
```sql
SELECT
  t.trip_date,
  r.name AS route_name,
  v.vehicle_no AS vehicle_number,
  
  -- Count boarded vs unboarded for this trip
  COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) AS actual_boardings,
  COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) AS actual_unboardings,
  
  -- If Boarding > Unboarding, it's a Risk (Student left on bus)
  CASE 
    WHEN COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) = COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) 
    THEN 'SAFE' 
    ELSE 'RISK' 
  END AS trip_status

FROM tpt_trip t
JOIN tpt_route_scheduler_jnt sch ON sch.id = t.route_scheduler_id
JOIN tpt_route r ON r.id = sch.route_id
JOIN tpt_vehicle v ON v.id = t.vehicle_id
LEFT JOIN tpt_student_boarding_log sb ON (sb.boarding_trip_id = t.id OR sb.unboarding_trip_id = t.id)
GROUP BY t.id;
```

### Charts Details
- KPI: Safe vs Risk Trips
- Bar: Trip Completion Status

---

## 5. Driver & Attendant Performance Report

### Report Title
Driver & Attendant Performance Report

### What this Report Covers
- Attendance reliability
- Trip handling efficiency

### Useful For
- Transport Head
- Principal

### Fields Shown in Report
- Staff Name
- Role (Driver/Attendant)
- Attendance %
- Trips Handled
- Delay Incidents

### Tables Used in Report
- tpt_drivers
- tpt_attendants
- tpt_driver_attendance
- tpt_trip_logs

### Filters Required
- Staff
- Role
- Route
- Date Range

### MySQL Query (Reference)
```sql
SELECT
  d.name,
  'Driver' AS role,
  COUNT(a.id) AS attendance_days,
  COUNT(tl.id) AS trips_handled,
  SUM(tl.delay_flag) AS delays
FROM tpt_drivers d
LEFT JOIN tpt_driver_attendance a ON a.driver_id = d.id
LEFT JOIN tpt_trip_logs tl ON tl.driver_id = d.id
GROUP BY d.id;
```

### Charts Details
- Line: Attendance Trend
- Bar: Trips per Staff

---

## 6. Trip Execution & Discipline Report

### Report Title
Trip Execution & Discipline Report

### What this Report Covers
- Planned vs actual trips
- Delays and deviations

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Date
- Route
- Vehicle
- Planned Trips
- Completed Trips
- Delayed Trips

### Tables Used in Report
- tpt_trips
- tpt_trip_logs

### Filters Required
- Date Range
- Route
- Vehicle

### MySQL Query (Reference)
```sql
SELECT
  t.trip_date,
  r.route_name,
  v.vehicle_number,
  COUNT(t.id) AS planned_trips,
  SUM(tl.completed_flag) AS completed_trips,
  SUM(tl.delay_flag) AS delayed_trips
FROM tpt_trips t
JOIN tpt_routes r ON r.id = t.route_id
JOIN tpt_vehicles v ON v.id = t.vehicle_id
LEFT JOIN tpt_trip_logs tl ON tl.trip_id = t.id
GROUP BY t.trip_date, r.id, v.id;
```

### Charts Details
- Line: On-Time vs Delayed Trips
- Bar: Delay Count per Route

---

## 7. Transport Finance & Leakage Report

### Report Title
Transport Finance & Leakage Report

### What this Report Covers
- Fee assignment vs collection
- Transport misuse detection

### Useful For
- Accountant
- Transport Head
- Management

### Fields Shown in Report
- Student Name
- Route
- Attendance Days
- Fee Assigned
- Fee Collected
- Leakage Flag

### Tables Used in Report
- tpt_student_route_allocation
- tpt_student_transport_attendance
- fee_collections

### Filters Required
- Academic Session
- Class
- Route
- Student

### MySQL Query (Reference)
```sql
SELECT
  s.id,
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  r.route_name,
  COUNT(a.id) AS attendance_days,
  COALESCE(SUM(fc.amount_paid),0) AS fee_collected
FROM students s
JOIN tpt_student_route_allocation sa ON sa.student_id = s.id
JOIN tpt_routes r ON r.id = sa.route_id
LEFT JOIN tpt_student_transport_attendance a ON a.student_id = s.id
LEFT JOIN fee_collections fc ON fc.student_id = s.id
GROUP BY s.id, r.route_name
HAVING attendance_days > 0 AND fee_collected = 0;
```

### Charts Details
- Pie: Paid vs Unpaid
- Bar: Leakage by Route

---

## 8. Cost & Maintenance Analytics Report

### Report Title
Cost & Maintenance Analytics Report

### What this Report Covers
- Fuel cost trends
- Maintenance and breakdown risk

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Vehicle
- Fuel Cost
- Maintenance Cost
- Breakdown Count

### Tables Used in Report
- tpt_fuel_logs
- tpt_vehicle_maintenance
- tpt_vehicle_breakdowns

### Filters Required
- Vehicle
- Date Range

### MySQL Query (Reference)
```sql
SELECT
  v.vehicle_number,
  SUM(fl.cost) AS fuel_cost,
  SUM(vm.cost) AS maintenance_cost,
  COUNT(b.id) AS breakdowns
FROM tpt_vehicles v
LEFT JOIN tpt_fuel_logs fl ON fl.vehicle_id = v.id
LEFT JOIN tpt_vehicle_maintenance vm ON vm.vehicle_id = v.id
LEFT JOIN tpt_vehicle_breakdowns b ON b.vehicle_id = v.id
GROUP BY v.id;
```

### Charts Details
- Line: Cost Trend
- Bar: Breakdown Frequency

---

## 9. Management Summary Dashboard

### Report Title
Management Summary Dashboard

### What this Report Covers
- High-level KPIs only (non-operational)

### Useful For
- Management
- Trustees

### Fields Shown in Report
- Total Routes
- Avg Utilization %
- Monthly Profit/Loss
- Active Leakage Cases

### Tables Used in Report
- Aggregated views / materialized views

### Filters Required
- Academic Session
- Month

### MySQL Query (Reference)
```sql
SELECT
  COUNT(DISTINCT route_id) AS total_routes,
  AVG(utilization_pct) AS avg_utilization,
  SUM(profit_loss) AS monthly_pl,
  SUM(leakage_flag) AS active_leakages
FROM mv_tpt_route_profitability;
```

### Charts Details
- KPI Tiles
- Trend Lines


---

## 10. Student Boarding / Unboarding Report (NEW)

### Report Title
Student Boarding / Unboarding Report

### What this Report Covers
- Exact boarding & unboarding timestamps
- Missed pickup / drop safety audit

### Useful For
- Transport Head
- Principal
- Parents (own child)
- Safety Officer

### Fields Shown in Report
- Student Name
- Trip Date
- Route
- Boarding Stop & Time
- Unboarding Stop & Time
- Boarding Status
- Unboarding Status

### Tables Used in Report
- std_students
- tpt_student_boarding_log
- tpt_route
- tpt_pickup_points

### Filters Required
- Academic Session
- Date Range
- Route
- Stop
- Student

### MySQL Query (Reference)
```sql
SELECT
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  sb.trip_date,
  r.name AS route_name,
  
  st_board.name AS boarding_stop_name,
  sb.boarding_time,
  
  st_unboard.name AS unboarding_stop_name,
  sb.unboarding_time,
  
  CASE WHEN sb.boarding_time IS NOT NULL THEN 'Boarded' ELSE 'Skipped' END AS boarding_status,
  CASE WHEN sb.unboarding_time IS NOT NULL THEN 'Unboarded' ELSE 'OnBus/Missed' END AS unboarding_status

FROM tpt_student_boarding_log sb
JOIN std_students s ON s.id = sb.student_id
LEFT JOIN tpt_route r ON r.id = sb.boarding_route_id
LEFT JOIN tpt_pickup_points st_board ON st_board.id = sb.boarding_stop_id
LEFT JOIN tpt_pickup_points st_unboard ON st_unboard.id = sb.unboarding_stop_id
WHERE sb.trip_date BETWEEN :start_date AND :end_date;
```

### Charts Details
- Timeline: Boarding → Unboarding
- Alert Count: Missed Events

---

## 11. Transport Notifications & Alerts Report (NEW)

### Report Title
Transport Notifications & Alerts Report

### What this Report Covers
- All transport notifications
- Delivery success/failure
- Retry & SLA compliance

### Useful For
- Transport Head
- Admin
- Management
- Support Team

### Fields Shown in Report
- Notification Type
- Student Name
- Trip ID
- Sent Time
- App Delivery Status
- SMS Delivery Status

### Tables Used in Report
- tpt_notification_log
- std_students
- std_student_sessions_jnt
- tpt_trip

### Filters Required
- Date Range
- Notification Type
- Delivery Status
- Student

### MySQL Query (Reference)
```sql
SELECT
  nl.notification_type,
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  nl.trip_id,
  nl.sent_time,
  nl.app_notification_status,
  nl.sms_notification_status

FROM tpt_notification_log nl
LEFT JOIN std_student_sessions_jnt ssj ON ssj.id = nl.student_session_id
LEFT JOIN std_students s ON s.id = ssj.student_id
WHERE nl.sent_time BETWEEN :start_date AND :end_date;
```

### Charts Details
- Pie: Delivered vs Failed
- Bar: Notifications by Type
- Line: Alerts Trend

---

## FINAL REPORT COUNT (v3.1)

| Category | Count |
|--------|------|
| Core Reports | 9 |
| Updated Reports | 4 |
| New Reports | 2 |
| **Total Reports** | **11** |

---

END OF DOCUMENT
