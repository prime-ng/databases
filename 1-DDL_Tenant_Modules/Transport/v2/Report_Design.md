# Transport Module - Consolidated Enterprise Report Specifications (v2)

This document defines **11 core Transport Reports**, each designed as an **enterprise-grade, standalone report**, following a **consistent, developer-ready format** suitable for Laravel + MySQL.

---

## 1. Route Performance Report

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
- Total Stops
- Allocated Students
- Boarded Students
- Unboarded Students
- Boarding Compliance %
- Unboarding Compliance %
- Avg Pickup Delay
- Avg Drop Delay

### Tables Used in Report
- tpt_routes
- tpt_pickup_points_route_jnt
- tpt_student_route_allocation_jnt
- tpt_student_boarding_log
- tpt_trip_logs

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
  COUNT(DISTINCT rs.pickup_point_id) AS total_stops,
  COUNT(DISTINCT sa.student_id) AS allocated_students,
  COUNT(DISTINCT CASE WHEN sb.event_type = 'BOARD' THEN sb.student_session_id END) AS boarded_students,
  COUNT(DISTINCT CASE WHEN sb.event_type = 'UNBOARD' THEN sb.student_session_id END) AS unboarded_students,
  ROUND(COUNT(DISTINCT CASE WHEN sb.event_type = 'BOARD' THEN sb.student_session_id END)/NULLIF(COUNT(DISTINCT sa.student_id),0)*100,2) AS boarding_pct,
  ROUND(COUNT(DISTINCT CASE WHEN sb.event_type = 'UNBOARD' THEN sb.student_session_id END)/NULLIF(COUNT(DISTINCT sa.student_id),0)*100,2) AS unboarding_pct,
  AVG(tl.pickup_delay_minutes) AS avg_pickup_delay,
  AVG(tl.drop_delay_minutes) AS avg_drop_delay
FROM tpt_route r
LEFT JOIN tpt_pickup_points_route_jnt rs ON rs.route_id = r.id
LEFT JOIN tpt_student_route_allocation_jnt sa ON sa.route_id = r.id
LEFT JOIN tpt_student_boarding_log sb ON sb.route_id = r.id AND DATE(sb.recorded_at) BETWEEN :start_date AND :end_date
LEFT JOIN tpt_trip_logs tl ON tl.route_id = r.id
GROUP BY r.id;
```

---

## 2. Student Transport Usage Report

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
- students (`std_students`)
- classes (`sch_classes`)
- sections (`sch_sections`)
- tpt_student_route_allocation_jnt
- tpt_student_boarding_log

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
  c.class_name,
  sec.section_name,
  r.name AS route_name,
  st.name AS stop_name,
  COUNT(CASE WHEN sb.event_type = 'BOARD' THEN 1 END) AS boarding_count,
  COUNT(CASE WHEN sb.event_type = 'UNBOARD' THEN 1 END) AS unboarding_count,
  CASE WHEN COUNT(CASE WHEN sb.event_type = 'BOARD' THEN 1 END)=0 THEN 1 ELSE 0 END AS missed_boarding,
  CASE WHEN COUNT(CASE WHEN sb.event_type = 'UNBOARD' THEN 1 END)=0 THEN 1 ELSE 0 END AS missed_drop
FROM std_students s
JOIN tpt_student_route_allocation_jnt sa ON sa.student_id = s.id
JOIN sch_classes c ON c.id = sa.class_id
JOIN sch_sections sec ON sec.id = sa.section_id
JOIN tpt_route r ON r.id = sa.route_id
JOIN tpt_pickup_points st ON st.id = sa.pickup_stop_id
LEFT JOIN tpt_student_boarding_log sb ON sb.student_session_id = sa.student_session_id
GROUP BY s.id;
```

---

## 3. Stop & Locality Analysis Report

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
- Academic Session

### MySQL Query (Reference)
```sql
SELECT
  st.name AS stop_name,
  r.name AS route_name,
  COUNT(sb.id) AS boarding_count,
  AVG(TIME(sb.recorded_at)) AS avg_boarding_time
FROM tpt_pickup_points st
JOIN tpt_student_boarding_log sb ON sb.stop_id = st.id AND sb.event_type = 'BOARD'
JOIN tpt_route r ON r.id = sb.route_id
GROUP BY st.id;
```

---

## 4. Trip Execution & Discipline Report

### Report Title
Trip Execution & Discipline Report

### What this Report Covers
- Planned vs actual trips
- Trip completion validated via unboarding

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Trip Date
- Route
- Vehicle
- Planned Boardings
- Actual Unboardings
- Trip Safety Status

### Tables Used in Report
- tpt_trip
- tpt_student_boarding_log

### MySQL Query (Reference)
```sql
SELECT
  t.trip_date,
  r.name AS route_name,
  v.vehicle_number,
  COUNT(CASE WHEN sb.event_type = 'BOARD' THEN 1 END) AS recorded_boardings,
  COUNT(CASE WHEN sb.event_type = 'UNBOARD' THEN 1 END) AS actual_unboardings,
  CASE WHEN COUNT(CASE WHEN sb.event_type = 'BOARD' THEN 1 END) = COUNT(CASE WHEN sb.event_type = 'UNBOARD' THEN 1 END) 
       THEN 'SAFE' 
       ELSE 'RISK' 
  END AS trip_status
FROM tpt_trip t
JOIN tpt_route_scheduler_jnt sch ON sch.id = t.route_scheduler_id
JOIN tpt_route r ON r.id = sch.route_id
JOIN tpt_vehicle v ON v.id = t.vehicle_id
LEFT JOIN tpt_student_boarding_log sb ON sb.trip_id = t.id
GROUP BY t.id;
```

---

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
- Route
- Stop
- Boarding Time
- Unboarding Time
- Boarding Status
- Unboarding Status

### Tables Used in Report
- std_students
- tpt_student_boarding_log
- tpt_route
- tpt_pickup_points

### MySQL Query (Reference)
```sql
SELECT
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  r.name AS route_name,
  st.name AS stop_name,
  sb_board.recorded_at AS boarding_time,
  sb_unboard.recorded_at AS unboarding_time,
  CASE WHEN sb_board.id IS NOT NULL THEN 'Boarded' ELSE 'Missed' END AS boarding_status,
  CASE WHEN sb_unboard.id IS NOT NULL THEN 'Unboarded' ELSE 'OnBus/Missed' END AS unboarding_status
FROM std_students s
JOIN tpt_student_route_allocation_jnt sa ON sa.student_id = s.id
JOIN tpt_route r ON r.id = sa.route_id
JOIN tpt_pickup_points st ON st.id = sa.pickup_stop_id
LEFT JOIN tpt_student_boarding_log sb_board ON sb_board.student_session_id = sa.student_session_id AND sb_board.event_type = 'BOARD' AND DATE(sb_board.recorded_at) = :report_date
LEFT JOIN tpt_student_boarding_log sb_unboard ON sb_unboard.student_session_id = sa.student_session_id AND sb_unboard.event_type = 'UNBOARD' AND DATE(sb_unboard.recorded_at) = :report_date;
```

---

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

### Fields Shown in Report
- Notification Type
- Student Name
- Sent Time
- Delivery Status

### Tables Used in Report
- tpt_notification_log
- std_students
- tpt_trip
- tpt_route

### MySQL Query (Reference)
```sql
SELECT
  n.notification_type,
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  r.name AS route_name,
  n.sent_time,
  n.app_notification_status,
  n.sms_notification_status
FROM tpt_notification_log n
JOIN tpt_student_session ss ON ss.id = n.student_session_id
JOIN std_students s ON s.id = ss.student_id  -- Assuming student_session links to student
LEFT JOIN tpt_trip t ON t.id = n.trip_id
LEFT JOIN tpt_route_scheduler_jnt sch ON sch.id = t.route_scheduler_id
LEFT JOIN tpt_route r ON r.id = sch.route_id
WHERE n.sent_time BETWEEN :start_date AND :end_date;
```

---
**End of Report Design**
