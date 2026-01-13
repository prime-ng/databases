# Transport Reports Design – v6.0

This document is an **updated version of tpt_Reports_Design_v5.md**, enhanced to align with **Transport Module DDL v2.2**.

---------------------------------------------------------------------------------------------------------------------------
 - All queries use :start_date and :end_date as placeholders for the date range filter

---------------------------------------------------------------------------------------------------------------------------
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
  - Route
  - Vehicle
  - Shift
  - Date Range

  ### MySQL Query (Reference)
  ```sql
  SELECT 
    r.name AS route_name,
    r.pickup_drop,
    COUNT(DISTINCT rs.pickup_point_id) AS total_stops,
    COUNT(DISTINCT sa.student_id) AS allocated_students,
    COUNT(DISTINCT CASE WHEN sb.boarding_time IS NOT NULL THEN sb.student_id END) AS boarded_students,
    COUNT(DISTINCT CASE WHEN sb.unboarding_time IS NOT NULL THEN sb.student_id END) AS unboarded_students,
    ROUND(COUNT(DISTINCT CASE WHEN sb.boarding_time IS NOT NULL THEN sb.student_id END) / NULLIF(COUNT(DISTINCT sa.student_id),0) * 100, 2) AS boarding_compliance_pct,
    ROUND(COUNT(DISTINCT CASE WHEN sb.unboarding_time IS NOT NULL THEN sb.student_id END) / NULLIF(COUNT(DISTINCT sa.student_id),0) * 100, 2) AS unboarding_compliance_pct,
    -- Calculating Avg Delay from Trip Stop Details
    AVG(TIMESTAMPDIFF(MINUTE, tsd.sch_arrival_time, tsd.reaching_time)) AS avg_delay_minutes
  FROM tpt_route r
  LEFT JOIN tpt_pickup_points_route_jnt rs ON rs.route_id = r.id
  LEFT JOIN tpt_student_route_allocation_jnt sa ON (sa.pickup_route_id = r.id OR sa.drop_route_id = r.id)
  LEFT JOIN tpt_student_boarding_log sb ON (sb.boarding_route_id = r.id OR sb.unboarding_route_id = r.id) 
      AND sb.trip_date BETWEEN :start_date AND :end_date
  LEFT JOIN tpt_trip t ON t.route_id = r.id
  LEFT JOIN tpt_trip_stop_detail tsd ON tsd.trip_id = t.id AND tsd.reached_flag = 1
  GROUP BY r.id, r.name, r.pickup_drop;
  ```

  ### Charts Details
  - Bar: Allocated vs Boarded vs Unboarded
  - Line: Delay Trend
  - KPI: Boarding Compliance %

---------------------------------------------------------------------------------------------------------------------------
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
  - Board UnAssigned Stop Count

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
  - Class
  - Section
  - Route
  - Stop
  - Student
  - Date Range

  ### MySQL Query (Reference)
  ```sql
  SELECT 
    CONCAT(u.name) AS student_name,
    c.name AS class_name,
    sec.name AS section_name,
    r.name AS route_name,
    p.name AS stop_name,
    COUNT(sb.boarding_time) AS total_boardings,
    COUNT(sb.unboarding_time) AS total_unboardings,
    SUM(CASE WHEN sb.boarding_time IS NULL THEN 1 ELSE 0 END) AS missed_boarding_count,
    SUM(CASE WHEN sb.unboarding_time IS NULL THEN 1 ELSE 0 END) AS missed_unboarding_count,
    SUM(CASE WHEN sa.pickup_route_id != sb.boarding_route_id THEN 1 ELSE 0 END) AS boarded_unassigned_stop_count
  FROM std_student_sessions_jnt ssj
  JOIN sys_users u ON u.id = ssj.user_id
  JOIN sch_class_section_jnt csj ON csj.id = ssj.class_section_id
  JOIN sch_classes c ON c.id = csj.class_id
  JOIN sch_sections sec ON sec.id = csj.section_id
  JOIN tpt_student_route_allocation_jnt sa ON sa.student_session_id = ssj.id
  JOIN tpt_route r ON (r.id = sa.pickup_route_id OR r.id = sa.drop_route_id)
  LEFT JOIN tpt_student_boarding_log sb ON sb.student_session_id = ssj.id 
      AND sb.trip_date BETWEEN :start_date AND :end_date
  LEFT JOIN tpt_pickup_points p ON (p.id = sb.boarding_stop_id OR p.id = sb.unboarding_stop_id)
  WHERE ssj.is_current = 1
  GROUP BY ssj.id, u.name, c.name, sec.name, r.name, p.name;
  ```

  ### Charts Details
  - Bar: Boarding vs Unboarding by Student
  - Heatmap: Missed Events

---------------------------------------------------------------------------------------------------------------------------
## 3. Route-wise Stop Analysis Report

  ### Report Title
  Route-wise Stop Analysis Report

  ### What this Report Covers
  - Boarding density per stop
  - Congestion & peak risk analysis

  ### Useful For
  - Transport Head
  - Management

  ### Fields Shown in Report
  - Route
  - Stop Name
  - Boarding Count
  - Allocated Student Count
  - Scheduled Boarding duration (Avg)
  - Actual Boarding duration (Avg)
  - Boarding Duration Variance
  - Avarage arrival Delay

  ### Tables Used in Report
  - tpt_pickup_points
  - tpt_student_boarding_log
  - tpt_route

  ### Filters Required
  - Route
  - Stop
  - Date Range

  ### MySQL Query (Reference)
  ```sql
  SELECT 
    r.name AS route_name,
    p.name AS stop_name,
    COUNT(sb.id) AS boarding_count,
    COUNT(DISTINCT sa.student_id) AS allocated_students,
    SEC_TO_TIME(AVG(TIME_TO_SEC(TIMEDIFF(tsd.sch_departure_time, tsd.sch_arrival_time)))) AS avg_scheduled_boarding_time,
    SEC_TO_TIME(AVG(TIME_TO_SEC(TIMEDIFF(tsd.leaving_time, tsd.reaching_time)))) AS avg_actual_boarding_time,
    SEC_TO_TIME(
        AVG(TIME_TO_SEC(TIMEDIFF(tsd.leaving_time, tsd.reaching_time))) - 
        AVG(TIME_TO_SEC(TIMEDIFF(tsd.sch_departure_time, tsd.sch_arrival_time)))
    ) AS boarding_duration_variance
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, tsd.sch_arrival_time, tsd.reaching_time)), 1) AS avg_arrival_delay_mins
  FROM tpt_route r
  JOIN tpt_pickup_points_route_jnt ppr ON ppr.route_id = r.id
  JOIN tpt_pickup_points p ON p.id = ppr.pickup_point_id
  LEFT JOIN tpt_trip_stop_detail tsd ON tsd.stop_id = p.id AND tsd.reached_flag = 1
  LEFT JOIN tpt_student_boarding_log sb ON sb.boarding_stop_id = p.id 
      AND sb.trip_date BETWEEN :start_date AND :end_date
  LEFT JOIN tpt_student_route_allocation_jnt sa ON (sa.pickup_stop_id = p.id)
  GROUP BY p.id, p.name, r.name;
  ```

  ### Charts Details
  - Heatmap: Boarding Density
  - Bar: Top Congested Stops

---------------------------------------------------------------------------------------------------------------------------
## 4. Trip Execution & Discipline Report

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
- Route + Trip Type(P/D)
- Vehicle
- Driver
- Planned Boardings (from Allocation)
- Actual Boardings
- Actual Unboardings
- Trip Safety Status

### Tables Used in Report
- tpt_trip
- tpt_route
- tpt_vehicle
- tpt_student_boarding_log

### Filters Required
- Route
- Vehicle
- Driver
- Date Range

### MySQL Query (Reference)
```sql
SELECT
  t.trip_date,
  r.name AS route_name,
  CASE WHEN r.pickup_drop IS 'Pickup' THEN 'P' ELSE 'D' END AS trip_type,
  v.vehicle_no AS vehicle_number,
  d.name AS driver_name,
  COUNT(DISTINCT sa.student_id) AS planned_boardings,
  COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) AS actual_boardings,
  COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) AS actual_unboardings,
  -- If Boarding > Unboarding, it's a Risk (Student left on bus)
  CASE 
    WHEN COUNT(CASE WHEN sb.boarding_time IS NOT NULL THEN 1 END) = COUNT(CASE WHEN sb.unboarding_time IS NOT NULL THEN 1 END) 
    THEN 'SAFE' 
    ELSE 'RISK' 
  END AS trip_status
FROM tpt_trip t
JOIN tpt_route r ON r.id = t.route_id
JOIN tpt_vehicle v ON v.id = t.vehicle_id
LEFT JOIN tpt_driver d ON d.id = t.driver_id
LEFT JOIN tpt_student_boarding_log sb ON (sb.boarding_trip_id = t.id OR sb.unboarding_trip_id = t.id)
LEFT JOIN tpt_student_route_allocation_jnt sa ON sa.pickup_route_id = r.id OR sa.drop_route_id = r.id
GROUP BY t.trip_date, r.name, v.vehicle_no, d.name;
```

### Charts Details
- KPI: Safe vs Risk Trips
- Bar: Trip Completion Status

---------------------------------------------------------------------------------------------------------------------------
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
  - Attendance Days
  - Trips Handled
  - Delay Incidents

  ### Tables Used in Report
  - tpt_personnel
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
    p.name AS staff_name,
    p.role,
    COUNT(DISTINCT att.attendance_date) AS attendance_days,
    COUNT(DISTINCT t.id) AS trips_handled,
    COUNT(i.id) AS incidents_reported
  FROM tpt_personnel p
  LEFT JOIN tpt_driver_attendance att ON att.driver_id = p.id 
      AND att.attendance_date BETWEEN :start_date AND :end_date
  LEFT JOIN tpt_trip t ON t.driver_id = p.id AND t.trip_date BETWEEN :start_date AND :end_date
  LEFT JOIN tpt_trip_incident i ON i.trip_id = t.id
  GROUP BY p.id, p.name, p.role;
  ```

  ### Charts Details
  - Line: Attendance Trend
  - Bar: Trips per Staff

---------------------------------------------------------------------------------------------------------------------------
## 6. Trip Execution & Discipline Report
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


  ### Charts Details
  - Pie: Paid vs Unpaid
  - Bar: Leakage by Route

---------------------------------------------------------------------------------------------------------------------------
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

  ### Filters Required
  - Vehicle
  - Date Range

  ### MySQL Query (Reference)


  ### Charts Details
  - Line: Cost Trend
  - Bar: Breakdown Frequency

---------------------------------------------------------------------------------------------------------------------------
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

  ### MySQL Query 

  ### Charts Details
  - KPI Tiles
  - Trend Lines

---------------------------------------------------------------------------------------------------------------------------
## 10. Student Boarding / Unboarding Report

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


  ### Charts Details
  - Timeline: Boarding → Unboarding
  - Alert Count: Missed Events

---------------------------------------------------------------------------------------------------------------------------
## 11. Transport Notifications & Alerts Report

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


  ### Charts Details
  - Pie: Delivered vs Failed
  - Bar: Notifications by Type
  - Line: Alerts Trend


---

END OF DOCUMENT


---



