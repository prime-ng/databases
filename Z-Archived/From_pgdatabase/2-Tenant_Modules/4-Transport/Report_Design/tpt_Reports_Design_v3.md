# Transport Module – Consolidated Enterprise Report Specifications

This document defines **9 core Transport Reports**, each designed as an **enterprise-grade, standalone report**, following a **consistent, developer-ready format** suitable for Laravel + MySQL, BI tools, and future AI analytics.

---

## 1. Route Performance Report

### Report Title
Route Performance Report

### What this Report Covers
- Route configuration and health
- Student load and utilization
- Pickup / drop delays
- Stop density and efficiency

### Useful For
- Transport Head
- Principal
- Management

### Fields Shown in Report
- Route Name
- Route Status
- Total Stops
- Students Allocated
- Utilization Percentage
- Avg Pickup Delay (mins)
- Avg Drop Delay (mins)

### Tables Used in Report
- tpt_routes
- tpt_route_stop_mapping
- tpt_student_route_allocation
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
  r.is_active,
  COUNT(DISTINCT rs.stop_id) AS total_stops,
  COUNT(DISTINCT sa.student_id) AS students_allocated,
  ROUND(COUNT(DISTINCT sa.student_id)/SUM(v.seating_capacity)*100,2) AS utilization_pct,
  AVG(tl.pickup_delay_minutes) AS avg_pickup_delay,
  AVG(tl.drop_delay_minutes) AS avg_drop_delay
FROM tpt_routes r
LEFT JOIN tpt_route_stop_mapping rs ON rs.route_id = r.id
LEFT JOIN tpt_student_route_allocation sa ON sa.route_id = r.id
LEFT JOIN tpt_trip_logs tl ON tl.route_id = r.id
LEFT JOIN tpt_vehicles v ON v.id = sa.vehicle_id
GROUP BY r.id;
```

### Charts Details
- Bar: Students per Route
- Line: Delay Trend
- Heatmap: Stop Density

---

## 2. Student Transport Usage Report

### Report Title
Student Transport Usage Report

### What this Report Covers
- Transport allocation per student
- Attendance consistency
- Pickup/drop compliance

### Useful For
- Transport Head
- Teachers
- Parents (own child)
- Admin

### Fields Shown in Report
- Student Name
- Class / Section
- Route Name
- Stop Name
- Days Allocated
- Days Attended
- Pickup Missed Count
- Drop Missed Count

### Tables Used in Report
- students
- classes
- sections
- tpt_student_route_allocation
- tpt_student_transport_attendance

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
  COUNT(a.id) AS attendance_days,
  SUM(a.pickup_missed) AS pickup_missed,
  SUM(a.drop_missed) AS drop_missed
FROM students s
JOIN tpt_student_route_allocation sa ON sa.student_id = s.id
JOIN tpt_routes r ON r.id = sa.route_id
JOIN tpt_route_stops st ON st.id = sa.stop_id
LEFT JOIN tpt_student_transport_attendance a ON a.student_id = s.id
JOIN classes c ON c.id = sa.class_id
JOIN sections sec ON sec.id = sa.section_id
GROUP BY s.id;
```

### Charts Details
- Bar: Attendance % Buckets
- Pie: Transport vs Non-Transport Students

---

## 3. Stop & Locality Analysis Report

### Report Title
Stop & Locality Analysis Report

### What this Report Covers
- Stop-wise student demand
- Congested vs underused stops

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Stop Name
- Route Name
- Students Allocated
- Avg Pickup Delay

### Tables Used in Report
- tpt_route_stops
- tpt_student_route_allocation
- tpt_trip_logs

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
  COUNT(sa.student_id) AS students_count,
  AVG(tl.pickup_delay_minutes) AS avg_delay
FROM tpt_route_stops st
JOIN tpt_student_route_allocation sa ON sa.stop_id = st.id
JOIN tpt_routes r ON r.id = sa.route_id
LEFT JOIN tpt_trip_logs tl ON tl.stop_id = st.id
GROUP BY st.id;
```

### Charts Details
- Heatmap: Stop Density
- Bar: Top 10 Stops

---

## 4. Vehicle Efficiency & Utilization Report

### Report Title
Vehicle Efficiency & Utilization Report

### What this Report Covers
- Capacity vs usage
- Fleet efficiency

### Useful For
- Transport Head
- Management

### Fields Shown in Report
- Vehicle Number
- Seating Capacity
- Students Allocated
- Utilization %
- Cost per Km

### Tables Used in Report
- tpt_vehicles
- tpt_student_route_allocation
- tpt_fuel_logs

### Filters Required
- Vehicle
- Route
- Academic Session

### MySQL Query (Reference)
```sql
SELECT
  v.vehicle_number,
  v.seating_capacity,
  COUNT(sa.student_id) AS students_allocated,
  ROUND(COUNT(sa.student_id)/v.seating_capacity*100,2) AS utilization_pct,
  SUM(fl.cost)/SUM(fl.distance_km) AS cost_per_km
FROM tpt_vehicles v
LEFT JOIN tpt_student_route_allocation sa ON sa.vehicle_id = v.id
LEFT JOIN tpt_fuel_logs fl ON fl.vehicle_id = v.id
GROUP BY v.id;
```

### Charts Details
- Bar: Utilization %
- RAG Indicator: Vehicle Health

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

