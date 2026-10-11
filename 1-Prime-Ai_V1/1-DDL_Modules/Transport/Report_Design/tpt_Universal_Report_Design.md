# Universal Transport Report – Enterprise Specification

## Report Title
Universal Transport Performance & Analytics Report

---

## What this Report Covers
A single configurable report that provides route, student, vehicle, finance, and operational analytics.

---

## Useful For
- Transport Head
- Principal
- Accountant
- Management

---

## Fields Shown in Report
- Route Name
- Vehicle Number
- Stop Name
- Student Name
- Class / Section
- Seating Capacity
- Students Allocated
- Utilization Percentage
- Attendance Days
- Fee Paid Amount
- Delay Count
- Fuel Cost
- Maintenance Cost

---

## Tables Used in Report
- tpt_routes
- tpt_route_stops
- tpt_student_route_allocation
- tpt_student_transport_attendance
- tpt_vehicles
- tpt_fuel_logs
- tpt_vehicle_maintenance
- fee_collections
- students
- classes
- sections

---

## Filters Required
- Academic Session
- Date Range
- Route
- Stop
- Vehicle
- Class
- Section
- Student

---

## MySQL Query (Reference)

```sql
SELECT
    r.route_name,
    v.vehicle_number,
    st.stop_name,
    CONCAT(s.first_name,' ',s.last_name) AS student_name,
    c.class_name,
    sec.section_name,
    v.seating_capacity,
    COUNT(DISTINCT sa.student_id) AS students_allocated,
    ROUND(COUNT(DISTINCT a.id)/COUNT(DISTINCT sa.student_id)*100,2) AS attendance_percentage,
    COALESCE(SUM(fc.amount_paid),0) AS fee_paid,
    COUNT(DISTINCT tl.id) AS delay_count,
    COALESCE(SUM(fl.cost),0) AS fuel_cost,
    COALESCE(SUM(vm.cost),0) AS maintenance_cost
FROM tpt_routes r
LEFT JOIN tpt_student_route_allocation sa ON sa.route_id = r.id
LEFT JOIN students s ON s.id = sa.student_id
LEFT JOIN classes c ON c.id = sa.class_id
LEFT JOIN sections sec ON sec.id = sa.section_id
LEFT JOIN tpt_route_stops st ON st.id = sa.stop_id
LEFT JOIN tpt_vehicles v ON v.id = sa.vehicle_id
LEFT JOIN tpt_student_transport_attendance a ON a.student_id = s.id
LEFT JOIN fee_collections fc ON fc.student_id = s.id
LEFT JOIN tpt_trip_logs tl ON tl.route_id = r.id
LEFT JOIN tpt_fuel_logs fl ON fl.vehicle_id = v.id
LEFT JOIN tpt_vehicle_maintenance vm ON vm.vehicle_id = v.id
GROUP BY r.id, v.id, s.id;
```

---

## Charts Details
- Bar: Students per Route
- Line: Attendance Trend
- Pie: Paid vs Unpaid Users
- Heatmap: Vehicle Utilization

---

## Drilldowns
- Route → Stop → Student
- Vehicle → Cost → Logs
- Student → Attendance → Fee Ledger
