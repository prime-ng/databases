# Dashboard — Requirements

## What It Does
Real-time operational dashboard for hostel management. Displays KPI cards (total beds, occupancy, attendance, pending actions), occupancy heatmap, and quick navigation to all hostel sections.

## Database Fields
No database table. Aggregates data from all hst_* tables for real-time display.

## Business Rules

**KPIs Displayed**
| KPI | Source |
|---|---|
| Total Beds | hst_beds count |
| Occupied Beds | hst_allotments where is_alloted = 1 |
| Available Beds | Total - Occupied - Maintenance |
| Maintenance Beds | hst_beds where status = 'maintenance' |
| Today's Attendance % | hst_attendance_entries for today |
| Pending Leave Approvals | hst_leave_passes where status = 'pending' |
| Open Complaints | hst_complaints where status = 'open' |
| Pending Incidents | hst_incidents where is_escalated = 0 |
| Breached SLA Complaints | hst_complaints where sla_due_at < now |

**Data Scoping**
- Warden: sees only assigned floors (via `warden.scope` middleware)
- Chief Warden: sees entire hostel
- School Admin: sees all hostels

**Heatmap**
- Floor-wise occupancy displayed as color-coded grid
- Green = < 50%, Yellow = 50-80%, Red = > 80%

## CRUD Operations

**View** — `GET /hostel/dashboard` → renders dashboard with KPIs, charts, heatmap

**KPIs (AJAX)** — `GET /hostel/dashboard/kpis` → returns JSON with latest KPI values

**Heatmap (AJAX)** — `GET /hostel/dashboard/heatmap` → returns JSON with floor-wise occupancy data

No create/edit/delete — read-only aggregate view.

## Permissions

| Operation | Permission Key |
|---|---|
| View dashboard | `tenant.hostel.viewAny` |
