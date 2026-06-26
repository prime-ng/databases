# Hostel Module — Business Requirements Overview

## Module Purpose

The Hostel Module enables a school to manage the complete lifecycle of hostel operations — from setting up hostel infrastructure (buildings, floors, rooms, beds), managing student allotments and occupancy, tracking daily operations (visitors, leave, movement), handling facility management (inventory, maintenance, housekeeping, laundry, complaints), recording safety incidents and sick bay admissions, running mess and dining services, and managing fee structures and demands.

This module replaces manual register-based hostel management with a structured digital workflow, ensuring accurate occupancy tracking, timely maintenance, compliant safety protocols, transparent mess billing, and clear audit trails for all hostel transactions.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Hostel Warden / Supervisor | Daily operations: attendance, visitors, leave passes, movement, incidents, sick bay, complaints, housekeeping, laundry |
| Admin / Principal | Hostel setup, warden assignments, fee structures, reports, oversight |
| Accountant / Finance | Fee demand generation, mess billing, reconciliation |
| Students / Parents | Allotment viewing, leave applications, complaint filing (via portal) |
| Maintenance Staff | Bed maintenance, room inventory, housekeeping logs |

---

## Module Screens (Tab-wise)

The Hostel module is organized into **7 multi-tab pages** covering **40 screens**:

### 1. Dashboard (`/hostel/dashboard`)
| # | Screen | Purpose |
|---|--------|---------|
| 01 | Hostel Dashboard | Real-time occupancy, attendance, incidents, and financial summary |

### 2. Config & Setup (`/hostel/setup`)
| # | Screen | Purpose |
|---|--------|---------|
| 02 | Room Types | Define room categories (single, double, triple, dormitory) |
| 03 | Bed Types | Define bed configurations (lower bunk, upper bunk, single) |
| 04 | Status Masters | Manage dynamic status codes used across all hostel entities |
| 05 | Hostels | Register hostel buildings with facilities and capacity |
| 06 | Floors | Define floors/blocks within each hostel |
| 07 | Rooms | Configure rooms with type, capacity, and amenities |
| 08 | Beds | Manage individual beds within rooms |
| 09 | Emergency Contacts | Store hostel-level emergency numbers and contacts |
| 10 | Warden Assignments | Assign wardens to hostels and floors with roles |

### 3. Allotment & Occupancy (`/hostel/allotments`)
| # | Screen | Purpose |
|---|--------|---------|
| 11 | Room Allotments | Assign students to beds for an academic session |
| 12 | Room Reservations | Pre-allotment reservations during admission |
| 13 | Room Change Requests | Student-initiated room change workflow |
| 14 | Hostel Attendance | Daily roll-call attendance for hostel residents |

### 4. Daily Operations (`/hostel/visitors`)
| # | Screen | Purpose |
|---|--------|---------|
| 15 | Visitor Log | Register hostel visitors with in/out tracking |
| 16 | Leave Passes | Student leave application and approval workflow |
| 17 | Movement Log | Daily in/out movement register for students |
| 18 | Pending Returns | Track students who haven't returned by expected time |
| 19 | Warden Duty Roster | Daily warden shift scheduling and duty assignments |

### 5. Facility Management (`/hostel/room-inventory`)
| # | Screen | Purpose |
|---|--------|---------|
| 20 | Room Inventory | Track room items and their condition |
| 21 | Bed Maintenance | Maintenance ticket lifecycle for beds and rooms |
| 22 | Housekeeping | Daily cleaning service logs and quality tracking |
| 23 | Laundry Tickets | Student laundry submission and return tracking |
| 24 | Complaints | Hostel-internal complaint system with SLA |
| 25 | Audit Log | Before/after change audit across all hostel tables |
| 26 | Notification Log | Record of all dispatched notifications |

### 6. Safety & Incidents (`/hostel/incidents`)
| # | Screen | Purpose |
|---|--------|---------|
| 27 | Incidents | Discipline incident register and tracking |
| 28 | Incident Types | Master list of incident categories |
| 29 | Incident Warnings | Warning letter audit trail |
| 30 | Sick Bay | Sick bay admissions and discharge management |
| 31 | Sick Bay Vitals | Periodic vital signs during admission |
| 32 | Sick Bay Medications | Medication administration log |

### 7. Mess & Dining (`/hostel/mess/menus`)
| # | Screen | Purpose |
|---|--------|---------|
| 33 | Mess Weekly Menus | Weekly meal schedule planning |
| 34 | Mess Attendance | Per-meal attendance tracking |
| 35 | Mess Opt Outs | Student meal opt-out requests |
| 36 | Special Diets | Dietary requirement tracking (diabetic, Jain, etc.) |
| 37 | Mess Bills | Monthly mess bill computation per student |

### 8. Staff & Finance (`/hostel/fee-structures`)
| # | Screen | Purpose |
|---|--------|---------|
| 38 | Fee Structures | Hostel fee rate configuration |
| 39 | Fee Demands | Fee charge audit and reconciliation |

### 9. Reports (`/hostel/reports`)
| # | Screen | Purpose |
|---|--------|---------|
| 40 | Reports | Cross-module hostel reports and analytics |

---

## Core Business Flow

```
Hostel Setup (Buildings → Floors → Rooms → Beds)
       ↓
Warden Assignment (Wardens assigned to hostels/floors)
       ↓
Student Allotment (Students assigned to beds for session)
       ↓
Daily Operations:
  ├── Attendance (Daily roll-call)
  ├── Movement Log (In/out tracking)
  ├── Leave Passes (Leave applications)
  ├── Visitor Log (Visitor registration)
  └── Warden Duty Roster (Shift scheduling)
       ↓
Facility Management:
  ├── Room Inventory (Item condition tracking)
  ├── Bed Maintenance (Repair tickets)
  ├── Housekeeping (Cleaning logs)
  ├── Laundry (Wash/return tracking)
  └── Complaints (Issue reporting with SLA)
       ↓
Safety & Incidents:
  ├── Incidents & Warnings (Discipline management)
  └── Sick Bay (Medical admissions & vitals)
       ↓
Mess & Dining:
  ├── Weekly Menus (Meal planning)
  ├── Attendance + Opt-Outs (Per-meal tracking)
  └── Bills (Monthly computation)
       ↓
Fee Management:
  ├── Fee Structures (Rate configuration)
  └── Fee Demands (Charge audit)
       ↓
Reports & Dashboard (Cross-module analytics)
```

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `hst_room_types` | Room category master |
| `hst_bed_types` | Bed configuration master |
| `hst_dynamic_status_masters` | Generic status codes across module |
| `hst_hostels` | Hostel building master |
| `hst_floors` | Floor/block definitions |
| `hst_rooms` | Room configurations |
| `hst_beds` | Individual bed records |
| `hst_emergency_contacts` | Emergency contact numbers |
| `hst_warden_assignments` | Warden role assignments |
| `hst_allotments` | Student bed allotments |
| `hst_room_reservations` | Pre-allotment reservations |
| `hst_room_change_requests` | Room change workflow |
| `hst_attendance` | Roll-call session headers |
| `hst_attendance_entries` | Per-student attendance entries |
| `hst_visitor_log` | Visitor register |
| `hst_visitor_media` | Visitor photo/documents |
| `hst_leave_passes` | Student leave applications |
| `hst_movement_log` | In/out movement register |
| `hst_warden_duty_roster` | Warden shift scheduling |
| `hst_room_inventory` | Room item inventory |
| `hst_bed_maintenance_log` | Maintenance tickets |
| `hst_housekeeping_log` | Cleaning service logs |
| `hst_laundry_tickets` | Laundry submission/return |
| `hst_complaints` | Complaint system |
| `hst_audit_log` | Change audit trail |
| `hst_notification_log` | Notification dispatch log |
| `hst_incidents` | Discipline incidents |
| `hst_incident_media` | Incident attachments |
| `hst_incident_types` | Incident categories |
| `hst_incident_warnings` | Warning letters |
| `hst_sick_bay_log` | Sick bay admissions |
| `hst_sick_bay_vitals` | Vital sign readings |
| `hst_sick_bay_medications` | Medication logs |
| `hst_mess_weekly_menus` | Weekly meal schedules |
| `hst_mess_attendance` | Per-meal attendance |
| `hst_mess_opt_outs` | Meal opt-out requests |
| `hst_mess_bills` | Monthly mess bills |
| `hst_special_diets` | Dietary requirements |
| `hst_fee_structures` | Fee rate configuration |
| `hst_fee_demands` | Fee charge records |
