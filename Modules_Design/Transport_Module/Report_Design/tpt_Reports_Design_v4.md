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
- tpt_student_boarding_events
- tpt_student_unboarding_events
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
  r.route_name,
  COUNT(DISTINCT rs.pickup_point_id) AS total_stops,
  COUNT(DISTINCT sa.student_id) AS allocated_students,
  COUNT(DISTINCT sb.student_id) AS boarded_students,
  COUNT(DISTINCT ue.student_id) AS unboarded_students,
  ROUND(COUNT(DISTINCT be.student_id)/COUNT(DISTINCT sa.student_id)*100,2) AS boarding_pct,
  ROUND(COUNT(DISTINCT ue.student_id)/COUNT(DISTINCT sa.student_id)*100,2) AS unboarding_pct,
  AVG(tl.pickup_delay_minutes) AS avg_pickup_delay,
  AVG(tl.drop_delay_minutes) AS avg_drop_delay
FROM tpt_routes r
LEFT JOIN tpt_pickup_points_route_jnt rs ON rs.route_id = r.id
LEFT JOIN tpt_student_route_allocation_jnt sa ON sa.route_id = r.id
LEFT JOIN tpt_student_boarding_events sb ON sb.route_id = r.id
LEFT JOIN tpt_student_unboarding_events ue ON ue.route_id = r.id
LEFT JOIN tpt_trip_logs tl ON tl.route_id = r.id
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
- students
- classes
- sections
- tpt_student_route_allocation
- tpt_student_boarding_events
- tpt_student_unboarding_events

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
  r.route_name,
  st.stop_name,
  COUNT(be.id) AS boarding_count,
  COUNT(ue.id) AS unboarding_count,
  CASE WHEN COUNT(be.id)=0 THEN 1 ELSE 0 END AS missed_boarding,
  CASE WHEN COUNT(ue.id)=0 THEN 1 ELSE 0 END AS missed_drop
FROM students s
JOIN tpt_student_route_allocation sa ON sa.student_id = s.id
JOIN classes c ON c.id = sa.class_id
JOIN sections sec ON sec.id = sa.section_id
JOIN tpt_routes r ON r.id = sa.route_id
JOIN tpt_route_stops st ON st.id = sa.stop_id
LEFT JOIN tpt_student_boarding_events be ON be.student_id = s.id
LEFT JOIN tpt_student_unboarding_events ue ON ue.student_id = s.id
GROUP BY s.id;
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
- tpt_route_stops
- tpt_student_boarding_events
- tpt_routes

### Filters Required
- Route
- Stop
- Locality
- Academic Session

### MySQL Query (Reference)
```sql
SELECT
  st.stop_name,
  r.route_name,
  COUNT(be.id) AS boarding_count,
  AVG(TIME(be.boarding_time)) AS avg_boarding_time
FROM tpt_route_stops st
JOIN tpt_student_boarding_events be ON be.stop_id = st.id
JOIN tpt_routes r ON r.id = be.route_id
GROUP BY st.id;
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
- tpt_trips
- tpt_student_boarding_events
- tpt_student_unboarding_events

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
  COUNT(be.id) AS expected_boardings,
  COUNT(ue.id) AS actual_unboardings,
  CASE WHEN COUNT(be.id)=COUNT(ue.id) THEN 'SAFE' ELSE 'RISK' END AS trip_status
FROM tpt_trips t
JOIN tpt_routes r ON r.id = t.route_id
JOIN tpt_vehicles v ON v.id = t.vehicle_id
LEFT JOIN tpt_student_boarding_events be ON be.trip_id = t.id
LEFT JOIN tpt_student_unboarding_events ue ON ue.trip_id = t.id
GROUP BY t.id;
```

### Charts Details
- KPI: Safe vs Risk Trips
- Bar: Trip Completion Status

---

## NEW REPORTS (v2.2)

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
- Route
- Stop
- Boarding Time
- Unboarding Time
- Boarding Status
- Unboarding Status

### Tables Used in Report
- students
- tpt_student_boarding_events
- tpt_student_unboarding_events
- tpt_routes
- tpt_route_stops

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
  r.route_name,
  st.stop_name,
  be.boarding_time,
  ue.unboarding_time,
  be.status AS boarding_status,
  ue.status AS unboarding_status
FROM students s
JOIN tpt_student_boarding_events be ON be.student_id = s.id
LEFT JOIN tpt_student_unboarding_events ue ON ue.student_id = s.id
JOIN tpt_routes r ON r.id = be.route_id
JOIN tpt_route_stops st ON st.id = be.stop_id;
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
- Trigger Event
- Student Name
- Route
- Sent Time
- Delivery Status
- Retry Count

### Tables Used in Report
- tpt_transport_notifications
- tpt_notification_logs
- students
- tpt_routes

### Filters Required
- Date Range
- Notification Type
- Delivery Status
- Route
- Student

### MySQL Query (Reference)
```sql
SELECT
  n.notification_type,
  n.trigger_event,
  CONCAT(s.first_name,' ',s.last_name) AS student_name,
  r.route_name,
  nl.sent_at,
  nl.delivery_status,
  nl.retry_count
FROM tpt_transport_notifications n
JOIN tpt_notification_logs nl ON nl.notification_id = n.id
JOIN students s ON s.id = n.student_id
JOIN tpt_routes r ON r.id = n.route_id;
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
