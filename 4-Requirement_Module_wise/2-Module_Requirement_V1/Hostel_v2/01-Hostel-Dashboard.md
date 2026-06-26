# Hostel Dashboard — Business Requirements

## What This Screen Does

The Hostel Dashboard is the central monitoring screen that gives wardens and administrators a real-time overview of all hostel operations. It displays key performance indicators, occupancy statistics, attendance summaries, pending actions, incident alerts, and financial snapshots at a glance.

---

## When This Screen Is Used

- Start of shift: Warden checks occupancy, pending returns, and daily attendance
- Throughout the day: Monitor new complaints, incidents, or maintenance requests
- End of day: Review attendance completion, pending leave returns
- Management review: Monthly occupancy trends, incident statistics, fee collection status

---

## Key Metrics Displayed

**Occupancy Overview**
- Total beds / Occupied beds / Vacant beds
- Occupancy percentage by hostel and gender type
- Floor-wise and room-type-wise breakdown

**Today's Operations**
- Present / Absent / Leave student counts
- Pending returns (students who haven't checked in)
- Active visitors currently in the hostel
- Sick bay current admissions

**Pending Actions**
- Unresolved complaints (by priority)
- Open maintenance requests
- Pending leave pass approvals
- Unapproved room change requests

**Safety & Incidents**
- Incidents reported today / this week
- Open incidents requiring attention
- Escalated incidents

**Financial Summary**
- Current month mess bill status
- Outstanding fee demands
- Fee collection rate

---

## Visual Components

- **KPI Cards** — Top row showing 4-6 key numbers (Occupancy %, Today's Attendance %, Pending Returns, Open Complaints)
- **Trend Charts** — Occupancy trends (line chart), incident trends (bar chart)
- **Alerts Section** — List of critical items requiring immediate attention (overdue returns, high-priority complaints, sick bay alerts)
- **Quick Actions** — Buttons for common tasks (Mark Attendance, Record Movement, File Complaint)

---

## Business Rules

- Dashboard data must be real-time (or max 5-minute cache)
- KPI cards show current academic session data by default
- Alerts are sorted by severity: Critical → High → Medium → Low
- Wardens see only their assigned hostel data; admins see all hostels
- Date range filter available for trend charts (Today, This Week, This Month, Custom)

---

## Related Screens

- **All screens** — Dashboard aggregates data from all 39 other screens
