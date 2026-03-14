# Transport Module Report Designs (Deliverable G)



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
