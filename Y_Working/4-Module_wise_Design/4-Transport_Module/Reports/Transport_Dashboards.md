# Transport Module Dashboards (Deliverable E)

This document contains **developer-ready ASCII dashboard designs** for the School ERP **Transport Module**.
Stack: **Laravel (PHP) + MySQL**

---

## DASHBOARD E1 — TRANSPORT HEAD DASHBOARD

### KPIs
```
+---------+-----------+-----------+------------+---------------+
| Routes  | Vehicles  | Avg Util% | Delay Trips| Leakage Alerts|
+---------+-----------+-----------+------------+---------------+
|   24    |    18     |   78%     |     3      |      6        |
+---------+-----------+-----------+------------+---------------+
```

### Route Utilization
```
R-01 ████████████ 92%
R-02 █████████ 81%
R-03 ██████ 58%
R-04 ██████████ 88%
```

Actions:
- Reassign Vehicle
- Merge / Split Route
- Change Stop Order

Filters:
- Session, Route, Vehicle, Shift

Drilldowns:
- Route → Vehicle → Students
- Route → Stops → Attendance

---

## DASHBOARD E2 — PRINCIPAL / MANAGEMENT DASHBOARD

### Strategic KPIs
```
+-----------+-----------+-----------+-------------+
| Students  | Cost(M)   | Revenue(M)| Profit/Loss |
+-----------+-----------+-----------+-------------+
|  1,240    | ₹4.2 L    | ₹4.8 L    | +₹0.6 L     |
+-----------+-----------+-----------+-------------+
```

### Route Profitability
```
Route   Cost    Revenue   Status
R-01   1.1L     1.5L      PROFIT
R-03   0.9L     0.6L      LOSS
```

Actions:
- Approve Route Change
- Approve Fee Revision

---

## DASHBOARD E3 — ACCOUNTANT DASHBOARD

### Finance KPIs
```
+-----------+-----------+-----------+-------------+
| Assigned  | Collected | Pending   | Leak Cases  |
+-----------+-----------+-----------+-------------+
| ₹5.1 L    | ₹4.6 L    | ₹0.5 L    | 14          |
+-----------+-----------+-----------+-------------+
```

Actions:
- Generate Demand
- Block Transport
- Export Audit

---

## DASHBOARD E4 — DRIVER DASHBOARD

```
Route: R-05
Vehicle: BUS-12
Stops: 14
Start: 06:45 AM
```

Actions:
- Mark Attendance
- Report Delay

---

## DASHBOARD E5 — PARENT / STUDENT DASHBOARD

```
Route: R-03
Stop: Shivalik Colony
Vehicle: BUS-07
Pickup: ✔
Drop ETA: 2:35 PM
```

---

## DASHBOARD E6 — PARENT DASHBOARD (LIVE GPS — FUTURE)

```
🚌 Live Bus Location
ETA: 7 mins
Your Stop Highlighted
```

Privacy:
- Own child only
- Own stop only

---

## Global Filters
- Academic Session
- Date Range
- Route
- Vehicle
- Shift

## Global Drilldowns
- Route → Vehicle → Students
- Route → Cost → Fuel / Maintenance

---

END OF DELIVERABLE E
