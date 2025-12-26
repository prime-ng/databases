# Transport Module Report Designs

## ROUTE & STOP MANAGEMENT REPORTS


### 1. ROUTE MASTER REPORT

**What this Report Covers**

  - All transport routes
  - Route status & configuration
  - Planning & audit visibility

**Useful For**
  - Transport Head
  - School Admin
  - Principal

**Fields Shown**
  - Route ID
  - Route Code
  - Route Name
  - Shift Type (Morning / Evening)
  - Route Type (Pickup / Drop / Both)
  - Total Stops
  - Total Students
  - Active Status

**Tables Used**
  - tpt_routes
  - tpt_pickup_points_route_jnt

**Filters**
  - Shift Type
  - Route Type
  - Route Status


**MySQL Query (Reference)**
SELECT
    r.id            AS route_id,
    r.route_code,
    r.route_name,
    s.shift_type,
    r.route_type,
    COUNT(rs.stop_id) AS total_stops,
    COUNT(sa.student_id) AS total_students,
    r.is_active
FROM tpt_routes r
LEFT JOIN tpt_shifts s ON s.id = r.shift_id
LEFT JOIN tpt_pickup_points_route_jnt rs ON rs.route_id = r.id AND rs.shift_id = r.shift_id
LEFT JOIN tpt_student_route_allocation sa ON sa.route_id = r.id AND sa.shift_id = r.shift_id
GROUP BY r.id;

**Charts (📊)**

  - Bar Chart: Stops per Route
  - Pie Chart: Active vs Inactive Routes

---

### 2. ROUTE-WISE STOP LIST REPORT

**What this Report Covers**

  - Ordered stop list per route
  - Pickup & drop planning

**Useful For**
  - Transport Head
  - Drivers / Helpers

**Fields Shown**
  - Route Name
  - Shift Type
  - Route Type
  - Stop Sequence
  - Stop Name
  - Pickup Time
  - fare_oneside
  - fare_roundtrip
  - Drop Time
  - Total Students

**Tables Used**
  - tpt_routes
  - tpt_pickup_points_route_jnt
  - tpt_pickup_points

**Filters**
  - Route
  - Area / Locality

**MySQL Query (Reference)**
SELECT
    r.route_name,
    rs.sequence_no,
    s.stop_name,
    rs.pickup_time,
    rs.drop_time,
    rs.fare_oneside,
    rs.fare_roundtrip,
    COUNT(sa.student_id) AS total_students
FROM tpt_pickup_points_route_jnt rs
JOIN tpt_routes r ON r.id = rs.route_id
JOIN tpt_pickup_points s ON s.id = rs.stop_id
LEFT JOIN tpt_student_route_allocation sa ON sa.route_id = r.id AND sa.shift_id = r.shift_id
ORDER BY r.route_name, rs.sequence_no;

**Charts (📊)**

❌ (Tabular report is primary)

Optional Timeline Chart for pickup sequence

---

### 3. STUDENT ROUTE ALLOCATION REPORT

**What this Report Covers**
  - Which student is using which route & stop
  - Class-wise transport usage

**Useful For**
  - Transport Head
  - Teachers
  - Admin

**Fields Shown**
  - Student ID
  - Student Name
  - Class
  - Section
  - Route Name
  - Stop Name
  - Session

**Tables Used**
  - tpt_student_route_allocation
  - students
  - student_sessions
  - classes
  - sections
  - tpt_routes
  - tpt_route_stops

**Filters**
  - Academic Session
  - Class / Section
  - Route
  - Stop

**MySQL Query (Reference)**
SELECT
    s.id AS student_id,
    CONCAT(s.first_name,' ',s.last_name) AS student_name,
    c.class_name,
    sec.section_name,
    r.route_name,
    st.stop_name,
    sa.session_id
FROM tpt_student_route_allocation sa
JOIN students s ON s.id = sa.student_id
JOIN classes c ON c.id = sa.class_id
JOIN sections sec ON sec.id = sa.section_id
JOIN tpt_routes r ON r.id = sa.route_id
JOIN tpt_route_stops st ON st.id = sa.stop_id
WHERE sa.session_id = :session_id;

**Charts (📊)**
  - Bar Chart: Students per Route
  - Pie Chart: Class-wise transport usage

---

### 4. VEHICLE UTILIZATION REPORT

**What this Report Covers**
  - Vehicle capacity vs actual usage
  - Under-utilized assets

**Useful For**
  - Transport Head
  - Management

**Fields Shown**
  - Vehicle Number
  - Seating Capacity
  - Students Allocated
  - Utilization %

**Tables Used**
  - tpt_vehicles
  - tpt_route_vehicle_mapping
  - tpt_student_route_allocation

**Filters**
  - Vehicle
  - Route
  - Session

**MySQL Query (Reference)**
SELECT
    v.vehicle_number,
    v.seating_capacity,
    COUNT(sa.student_id) AS allocated_students,
    ROUND(
        COUNT(sa.student_id) / v.seating_capacity * 100, 2
    ) AS utilization_percentage
FROM tpt_vehicles v
LEFT JOIN tpt_student_route_allocation sa ON sa.vehicle_id = v.id
GROUP BY v.id;

**Charts (📊)**
  - Bar Chart: Utilization % per Vehicle
  - Heatmap: Under-utilized Vehicles

---

### 5. STUDENT TRANSPORT ATTENDANCE REPORT

**What this Report Covers**
  - Daily pickup & drop attendance
  - Safety monitoring

**Useful For**
  - Transport Head
  - Principal

**Fields Shown**
  - Date
  - Student Name
  - Route
  - Stop
  - Pickup Status
  - Drop Status

**Tables Used**
  - tpt_student_transport_attendance
  - students
  - tpt_routes
  - tpt_route_stops

**Filters**
  - Date Range
  - Route
  - Student

**MySQL Query (Reference)**
SELECT
    a.attendance_date,
    CONCAT(s.first_name,' ',s.last_name) AS student_name,
    r.route_name,
    st.stop_name,
    a.pickup_status,
    a.drop_status
FROM tpt_student_transport_attendance a
JOIN students s ON s.id = a.student_id
JOIN tpt_routes r ON r.id = a.route_id
JOIN tpt_route_stops st ON st.id = a.stop_id
WHERE a.attendance_date BETWEEN :from AND :to;

**Charts (📊)**
  - Line Chart: Attendance trend over time
  - Bar Chart: Absentees per Route

---

### 6. TRANSPORT FEE vs USAGE (LEAKAGE) REPORT

**What this Report Covers**
  - Students using transport without paying fees
  - Revenue leakage detection

**Useful For**
  - Transport Head
  - Accountant
  - Management

**Fields Shown**
  - Student Name
  - Route
  - Attendance %
  - Fee Paid (Yes/No)
  - Leakage Flag

**Tables Used**
  - tpt_student_route_allocation
  - tpt_student_transport_attendance
  - fee_collections

**Filters**
  - Route
  - Session
  - Class

**MySQL Query (Reference)**
SELECT
    s.id AS student_id,
    CONCAT(s.first_name,' ',s.last_name) AS student_name,
    r.route_name,
    COUNT(a.id) AS attendance_days,
    COALESCE(SUM(fc.amount_paid),0) AS fee_paid
FROM tpt_student_route_allocation sa
JOIN students s ON s.id = sa.student_id
JOIN tpt_routes r ON r.id = sa.route_id
LEFT JOIN tpt_student_transport_attendance a
    ON a.student_id = sa.student_id
LEFT JOIN fee_collections fc
    ON fc.student_id = sa.student_id
GROUP BY s.id, r.route_name
HAVING attendance_days > 0 AND fee_paid = 0;

**Charts (📊)**
  - Pie Chart: Paid vs Unpaid Users
  - Bar Chart: Leakage by Route

---

### 7. ROUTE PROFITABILITY REPORT

**What this Report Covers**
  - Cost vs revenue per route
  - Strategic optimization

**Useful For**
  - Management

**Fields Shown**
  - Route Name
  - Fuel Cost
  - Maintenance Cost
  - Total Cost
  - Revenue
  - Profit / Loss

**Tables Used**
  - Fuel logs
  - Maintenance
  - Fee collections
  - Routes

**Filters**
  - Route
  - Month / Session

**MySQL Query (Reference)**
SELECT
    r.route_name,
    SUM(fl.fuel_cost) AS fuel_cost,
    SUM(m.cost) AS maintenance_cost,
    SUM(fc.amount_paid) AS revenue,
    SUM(fl.fuel_cost) + SUM(m.cost) - SUM(fc.amount_paid) AS profit_loss
FROM tpt_routes r
LEFT JOIN fuel_logs fl ON fl.route_id = r.id
LEFT JOIN maintenance m ON m.route_id = r.id
LEFT JOIN fee_collections fc ON fc.route_id = r.id
GROUP BY r.id;

**Charts (📊)**
  - Line Chart: Cost vs Revenue trend
  - Bar Chart: Profit/Loss per Route









### 8. STOP WISE STUDENT COUNT REPORT

**What this Report Covers**
  - Number of students per stop
  - Stop density analysis

**Useful For**
  - Transport Head
  - Management

**Tables Used**
  - tpt_student_stop_allocation
  - tpt_route_stops
  - students

**Filters**
  - Route
  - Stop
  - Academic Session

**MySQL Query (Reference)**
SELECT
    rs.stop_name,
    COUNT(sa.student_id) AS student_count
FROM tpt_student_stop_allocation sa
JOIN tpt_route_stops rs ON rs.id = sa.stop_id
GROUP BY rs.stop_name;

**Charts (📊)**
  - Bar Chart: Students per Stop

---

### 8. ROUTE STOP DETAILS REPORT

**What this Report Covers**
  - Number of students per stop
  - Stop density analysis

Useful For
  - Transport Head
  - Management

Tables Used
  - tpt_student_stop_allocation
  - tpt_route_stops
  - students

Filters
  - Route
  - Stop
  - Academic Session

**MySQL Query (Reference)**
SELECT
    rs.stop_name,
    COUNT(sa.student_id) AS student_count
FROM tpt_student_stop_allocation sa
JOIN tpt_route_stops rs ON rs.id = sa.stop_id
GROUP BY rs.stop_name;

**Charts (📊)**
  - Bar Chart: Students per Stop

---

### 9. ROUTE STOP DETAILS REPORT

**What this Report Covers**
  - Stops mapped to each route in sequence
  - Pickup & drop timings

Useful For
  - Transport Head
  - Drivers
  - Helpers
  - Admin

**Tables Used**
  - tpt_routes
  - tpt_route_stops
  - tpt_route_stop_mapping

**Filters**
  - Route
  - Stop Area

**MySQL Query (Reference)**
SELECT
    rs.stop_name,
    COUNT(sa.student_id) AS student_count
FROM tpt_student_stop_allocation sa
JOIN tpt_route_stops rs ON rs.id = sa.stop_id
GROUP BY rs.stop_name;

**Charts (📊)**
  - Bar Chart: Students per Stop

--- 











## Reports with Screen
 - Vendor Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|
 
 - Vehicle Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Stop Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Student Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Vehicle Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Vendor Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Stop Student Details
 +-----------------------------------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
| Period: [From–To]
|[Export] [Print] [PDF] [Excel] [CSV]
+------------------------------------------------------------------------------+
| Vehicle No. | Registration No. | Model | Stop | Capacity | Status   | Action
|-----------------------------------------------------|

 - Route Stop Vehicle Details
 - Route Stop Vendor Details
 - Route Stop Student Vehicle Details
 - Route Stop Student Vendor Details
 - Route Stop Student Vehicle Vendor Details

















## REPORT R1 — Route-wise Student Allocation Report

### Layout
```
+-----------------------------------------------------+
| Route: [Dropdown]  Session: [Dropdown]  Export [ ] |
+-----------------------------------------------------+
| Student ID | Student Name | Class | Stop | Status   |
|-----------------------------------------------------|
| ST-1023    | Aarav S.     | 5-A   | Stop-3 | Active |
| ST-1044    | Meera K.     | 6-B   | Stop-1 | Active |
+-----------------------------------------------------+
```

### Charts
- Bar: Students per Stop
- Pie: Class-wise distribution

### Filters
- Academic Session
- Route
- Stop
- Class / Section

### Drilldowns
- Student → Attendance History
- Stop → Student List

### Actions
- Export (CSV/PDF)
- Reassign Stop
- Suspend Transport

---

## REPORT R2 — Vehicle Utilization Report

### Layout
```
+---------------------------------------------------+
| Session: [Dropdown]  Vehicle Type: [All]         |
+---------------------------------------------------+
| Vehicle | Capacity | Allocated | Util % | Status |
|---------------------------------------------------|
| BUS-07  | 40       | 35        | 88%    | OK     |
| BUS-12  | 30       | 14        | 46%    | LOW    |
+---------------------------------------------------+
```

### Charts
- Bar: Utilization % per Vehicle
- Heatmap: Under-utilized Vehicles

### Filters
- Session
- Vehicle
- Route

### Drilldowns
- Vehicle → Route Mapping
- Vehicle → Cost Details

### Actions
- Reassign Vehicle
- Mark for Replacement

---

## REPORT R3 — Route Profitability Report

### Layout
```
+---------------------------------------------------+
| Month: [MM-YYYY]  Route: [All]                   |
+---------------------------------------------------+
| Route | Cost | Revenue | Profit/Loss | Status    |
|---------------------------------------------------|
| R-01  | 1.1L | 1.5L    | +0.4L       | PROFIT    |
| R-03  | 0.9L | 0.6L    | -0.3L       | LOSS      |
+---------------------------------------------------+
```

### Charts
- Line: Cost vs Revenue Trend
- Bar: Profit/Loss by Route

### Filters
- Month
- Route

### Drilldowns
- Route → Cost Breakdown
- Route → Student Count

### Actions
- Propose Fee Revision
- Merge Route

---

## REPORT R4 — Driver Attendance & Performance Report

### Layout
```
+---------------------------------------------------+
| Month: [MM]  Driver: [Dropdown]                  |
+---------------------------------------------------+
| Driver | Days Present | Trips | Delays | Rating  |
|---------------------------------------------------|
| DR-05  | 24           | 48    | 2      | GOOD    |
+---------------------------------------------------+
```

### Charts
- Line: Attendance Trend
- Bar: Delays per Driver

### Filters
- Month
- Driver

### Drilldowns
- Driver → Trip Logs

### Actions
- Issue Warning
- Assign Backup

---

## REPORT R5 — Transport Fee vs Usage (Leakage) Report

### Layout
```
+---------------------------------------------------+
| Session: [Dropdown]                              |
+---------------------------------------------------+
| Student | Route | Attendance % | Fee Paid | Flag |
|---------------------------------------------------|
| ST-1023 | R-03  | 91%          | NO       | LEAK |
+---------------------------------------------------+
```

### Charts
- Pie: Paid vs Unpaid Users
- Bar: Leakage by Route

### Filters
- Session
- Route
- Class

### Drilldowns
- Student → Fee Ledger
- Student → Attendance

### Actions
- Generate Demand
- Suspend Transport

---

## REPORT R6 — Vehicle Maintenance & Breakdown Report

### Layout
```
+---------------------------------------------------+
| Vehicle: [Dropdown]  Period: [From–To]           |
+---------------------------------------------------+
| Vehicle | Maintenance | Breakdowns | Cost | Risk |
|---------------------------------------------------|
| BUS-07  | 3           | 2          | 45k  | HIGH |
+---------------------------------------------------+
```

### Charts
- Line: Maintenance Cost Trend
- Bar: Breakdown Count

### Filters
- Vehicle
- Date Range

### Drilldowns
- Vehicle → Maintenance Logs

### Actions
- Schedule Maintenance
- Flag for Replacement

---

## GLOBAL REPORT FEATURES

### Export Options
- CSV
- PDF
- Excel

### Access Control
- Role-based
- Tenant-isolated

### Drilldown Consistency
- Route → Vehicle → Student
- Student → Attendance → Fee

---

END OF DELIVERABLE G
