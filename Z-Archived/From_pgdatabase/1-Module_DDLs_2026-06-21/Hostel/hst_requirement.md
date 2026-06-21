# Hostel Module — Requirements Overview

**Module:** Hostel Management | **Laravel Module:** `Modules/Hostel/` | **Prefix:** `hst_`
**Database:** tenant_db (dedicated per tenant) | **Route:** `/hostel/*`

## Module Overview

Residential schools (boarding schools) in India house 50–2,000 students on campus. The Hostel module manages the complete boarding lifecycle — from infrastructure (buildings, floors, rooms, beds) to daily operations (attendance, leave passes, mess, incidents, sick bay, fee integration).

**Core Principle:** The module is warden-centric — every warden sees only their assigned floors/students. Hostel fee computation is pushed to the StudentFee module via service-to-service calls.

## Requirements by Tab/Table

| # | File | Table(s) | Sidebar Menu Group |
|---|------|----------|-------------------|
| 1 | `Requirements/dashboard.md` | — | Dashboard |
| 2 | `Requirements/hostel-setup.md` | — (overview page) | Config & Setup |
| 3 | `Requirements/room-types.md` | `hst_room_types` | Config & Setup / Room Types |
| 4 | `Requirements/bed-types.md` | `hst_bed_types` | Config & Setup / Bed Types |
| 5 | `Requirements/status-masters.md` | `hst_dynamic_status_masters` | Config & Setup / Status Masters |
| 6 | `Requirements/hostels.md` | `hst_hostels` | Config & Setup / Hostels |
| 7 | `Requirements/floors.md` | `hst_floors` | Config & Setup / Floors |
| 8 | `Requirements/rooms.md` | `hst_rooms` | Config & Setup / Rooms |
| 9 | `Requirements/beds.md` | `hst_beds` | Config & Setup / Beds |
| 10 | `Requirements/emergency-contacts.md` | `hst_emergency_contacts` | Config & Setup / Emergency Contacts |
| 11 | `Requirements/warden-assignments.md` | `hst_warden_assignments` | Config & Setup / Warden Assignments |
| 12 | `Requirements/allotments.md` | `hst_allotments` | Allotment & Occupancy |
| 13 | `Requirements/room-reservations.md` | `hst_room_reservations` | Allotment & Occupancy |
| 14 | `Requirements/room-change-requests.md` | `hst_room_change_requests` | Allotment & Occupancy |
| 15 | `Requirements/attendance.md` | `hst_attendance` | Allotment & Occupancy |
| 16 | `Requirements/attendance-entries.md` | `hst_attendance_entries` | Allotment & Occupancy (sub-tab) |
| 17 | `Requirements/visitors.md` | `hst_visitor_log`, `hst_visitor_media` | Daily Operations / Gate |
| 18 | `Requirements/leave-passes.md` | `hst_leave_passes` | Daily Operations |
| 19 | `Requirements/movement-log.md` | `hst_movement_log` | Daily Operations |
| 20 | `Requirements/sick-bay.md` | `hst_sick_bay_log` | Daily Operations / Safety |
| 21 | `Requirements/warden-duty-roster.md` | `hst_warden_duty_roster` | Daily Operations |
| 22 | `Requirements/room-inventory.md` | `hst_room_inventory` | Facility Mgmt |
| 23 | `Requirements/bed-maintenance.md` | `hst_bed_maintenance_log` | Facility Mgmt |
| 24 | `Requirements/housekeeping.md` | `hst_housekeeping_log` | Facility Mgmt |
| 25 | `Requirements/laundry.md` | `hst_laundry_tickets` | Facility Mgmt |
| 26 | `Requirements/complaints.md` | `hst_complaints` | Facility Mgmt |
| 27 | `Requirements/audit-log.md` | `hst_audit_log` | Facility Mgmt |
| 28 | `Requirements/notification-log.md` | `hst_notification_log` | Facility Mgmt |
| 29 | `Requirements/incidents.md` | `hst_incidents`, `hst_incident_media` | Safety & Incidents |
| 30 | `Requirements/incident-types.md` | `hst_incident_types` | Safety & Incidents |
| 31 | `Requirements/incident-warnings.md` | `hst_incident_warnings` | Safety & Incidents |
| 32 | `Requirements/sick-bay-vitals.md` | `hst_sick_bay_vitals` | Safety & Incidents |
| 33 | `Requirements/sick-bay-medications.md` | `hst_sick_bay_medications` | Safety & Incidents |
| 34 | `Requirements/mess-menus.md` | `hst_mess_weekly_menus` | Mess & Dining |
| 35 | `Requirements/mess-attendance.md` | `hst_mess_attendance` | Mess & Dining |
| 36 | `Requirements/mess-opt-outs.md` | `hst_mess_opt_outs` | Mess & Dining |
| 37 | `Requirements/mess-bills.md` | `hst_mess_bills` | Mess & Dining |
| 38 | `Requirements/special-diets.md` | `hst_special_diets` | Mess & Dining |
| 39 | `Requirements/fee-structures.md` | `hst_fee_structures` | Staff & Finance |
| 40 | `Requirements/fee-demands.md` | `hst_fee_demands` | Staff & Finance |
| 41 | `Requirements/reports.md` | — (aggregate views) | Reports & Analytics |

## Key Integrations

| Module | Integration |
|---|---|
| StudentProfile | Student data, guardian info |
| SchoolSetup | Academic sessions |
| StudentFee | Fee demand push, defaulter data |
| Notification | Parent alerts (absent, leave approval, sick bay admission, late return) |
| HPC | Hospital referral linkage |
| Complaint | School-wide vs hostel-internal distinction |

## Stakeholders

| Role | Primary Actions |
|---|---|
| School Admin / Principal | Full hostel access, policy configuration, incident escalation |
| Chief Warden | Full hostel operations, approve/reject leave passes, incident escalation |
| Block Warden | Block/floor-level attendance, leave approval, incident recording |
| Mess Supervisor | Meal plan setup, weekly menu, mess attendance |
| Accountant | Hostel fee review, prorated calculations, defaulter report |
| Sick Bay Staff | Admission, treatment, discharge |
| Student (Portal) | View allotment, apply for leave pass, view mess menu |
| Parent (Portal) | View leave pass status, receive alerts, view attendance |

## Role Permissions

| Role | Access |
|---|---|
| School Admin | Full access |
| Chief Warden | Full hostel-wide operations |
| Block/Floor Warden | Scoped to assigned floors only |
| Accountant | Fee structures, reports |
| Mess Supervisor | Menu, diets, mess attendance only |
| Medical Staff | Sick bay only |
