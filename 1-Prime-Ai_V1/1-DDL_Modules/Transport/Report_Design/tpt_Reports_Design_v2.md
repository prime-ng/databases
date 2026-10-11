# Transport Reports – Enhancements & Additions (DDL v2.2)

This document captures **report design updates and new reports** required after analyzing the enhanced
Transport Module DDL **v2.2**. The focus of v2.2 is on **Student Boarding / Unboarding events** and
**Transport Notifications**, improving safety, traceability, and parent communication.

---

## SECTION A — IMPACT ANALYSIS SUMMARY (v2.2)

### Newly Introduced Logical Capabilities
- Student boarding events
- Student unboarding events
- Event timestamps per stop and trip
- Transport notification events
- Delivery status and retries

---

## SECTION B — CHANGES REQUIRED IN EXISTING REPORTS

### Route Performance Report (UPDATED)
- Added boarding vs allocation comparison
- Added unboarding compliance

### Student Transport Usage Report (UPDATED)
- Attendance derived from boarding/unboarding

### Stop & Locality Analysis Report (UPDATED)
- Boarding density per stop

### Trip Execution & Discipline Report (UPDATED)
- Trip completion validated via unboarding

---

## SECTION C — NEW REPORTS (v2.2)

## Student Boarding / Unboarding Report

### Report Title
Student Boarding / Unboarding Report

### What this Report Covers
- Exact boarding and unboarding events per student
- Missed pickup and missed drop detection

### Useful For
- Transport Head
- Principal
- Parents

### Fields Shown in Report
- Student Name
- Route Name
- Stop Name
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
- Timeline: Boarding to Unboarding
- Bar: Missed Events

---

## Transport Notifications & Alerts Report

### Report Title
Transport Notifications & Alerts Report

### What this Report Covers
- Transport notifications triggered by events
- Delivery success and failures

### Useful For
- Admin
- Transport Head
- Management

### Fields Shown in Report
- Notification Type
- Trigger Event
- Student Name
- Route Name
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
- Pie: Delivery Status
- Bar: Notifications by Type

---

END OF DOCUMENT
