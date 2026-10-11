# HST Hostel Management — Table Summary
**Module:** HST | **Version:** 1.0 | **Date:** 2026-03-27
**DDL File:** `HST_DDL_v1.sql` | **Tables:** 21

---

## Table Inventory

| # | Table Name | Layer | Description | Rows (est.) |
|---|-----------|-------|-------------|-------------|
| 1 | `hst_hostels` | L1 | Hostel building master — name, capacity, gender type, warden-in-charge | Low (1–10) |
| 2 | `hst_floors` | L2 | Floors within a hostel — floor number, capacity, gender override | Low |
| 3 | `hst_warden_assignments` | L2 | Warden-to-floor mapping — scope (block/floor), effective dates | Low |
| 4 | `hst_rooms` | L3 | Rooms within a floor — room number, type (dormitory/private/semi-private/suite), capacity, current occupancy | Medium |
| 5 | `hst_beds` | L4 | Individual beds within a room — bed code, position label, status (available/occupied/reserved/maintenance) | Medium |
| 6 | `hst_fee_structures` | L4 | Fee plan per room type per academic term — monthly rate, admission fee, security deposit, billing cycle | Low |
| 7 | `hst_mess_weekly_menus` | L4 | Weekly mess menu — day of week, meal type, menu items JSON, academic term scope | Low |
| 8 | `hst_room_inventory` | L4 | Inventory items assigned to a room — item name, quantity, condition, last inspection date | Medium |
| 9 | `hst_allotments` | L5 | Student-to-bed allocation record — status FSM (active/vacated/transferred/suspended), generated columns for double-allotment prevention | High |
| 10 | `hst_special_diets` | L5 | Student dietary preferences and medical diet requirements — linked to allotment, approved by | Low |
| 11 | `hst_visitor_log` | L5 | Visitor entry/exit log — visitor name, relationship, student, in/out timestamps, purpose | High |
| 12 | `hst_movement_log` | L5 | Student movement tracking — in/out timestamps, purpose (leave/outing/emergency/medical/other) | High |
| 13 | `hst_attendance` | L6 | Daily attendance header per hostel — date, session, present/absent/leave/late counts (denormalized) | High |
| 14 | `hst_incidents` | L6 | Incident reports — type, severity, involved student(s), resolution status FSM | Medium |
| 15 | `hst_mess_attendance` | L6 | Mess meal attendance per student per meal — status (present/absent/leave/special) | High |
| 16 | `hst_complaints` | L6 | Complaint log — category, priority, SLA deadline, status FSM, escalation flag | Medium |
| 17 | `hst_sick_bay_log` | L6 | Sick bay admission/discharge — symptoms, diagnosis, nurse/doctor notes, HPC soft reference | Low |
| 18 | `hst_attendance_entries` | L7 | Per-student attendance line items under an attendance header — status (present/absent/late/leave/sick_bay) | High |
| 19 | `hst_room_change_requests` | L7 | Student-initiated room/bed change requests — reason, status FSM (pending/approved/rejected/completed) | Low |
| 20 | `hst_leave_passes` | L7 | Leave pass requests — departure/return dates, type (home/medical/emergency/other), status FSM, parent contact | Medium |
| 21 | `hst_incident_media` | L8 | Media attachments for incidents — polymorphic-style FK to sys_media | Low |

---

## Dependency Layers

```
L1: hst_hostels
L2: hst_floors, hst_warden_assignments
L3: hst_rooms
L4: hst_beds, hst_fee_structures, hst_mess_weekly_menus, hst_room_inventory
L5: hst_allotments, hst_special_diets, hst_visitor_log, hst_movement_log
L6: hst_attendance, hst_incidents, hst_mess_attendance, hst_complaints, hst_sick_bay_log
L7: hst_attendance_entries, hst_room_change_requests, hst_leave_passes
L8: hst_incident_media
```

---

## Audit Columns (All Tables)

Every HST table carries the standard audit trail:

| Column | Type | Notes |
|--------|------|-------|
| `is_active` | TINYINT(1) DEFAULT 1 | Soft-delete flag |
| `created_by` | INT UNSIGNED NULL | FK → sys_users.id |
| `updated_by` | INT UNSIGNED NULL | FK → sys_users.id |
| `created_at` | TIMESTAMP NULL DEFAULT NULL | |
| `updated_at` | TIMESTAMP NULL DEFAULT NULL | |
| `deleted_at` | TIMESTAMP NULL DEFAULT NULL | Laravel SoftDeletes |

> **No audit exceptions** — all 21 tables have all 6 audit columns.

---

## Cross-Module FK Summary

| HST Column | Type | References | Note |
|------------|------|-----------|------|
| `hst_hostels.warden_id` | INT UNSIGNED | `sys_users.id` | Head warden |
| `hst_warden_assignments.user_id` | INT UNSIGNED | `sys_users.id` | Warden user |
| `hst_allotments.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_allotments.academic_term_id` | INT UNSIGNED | `sch_academic_term.id` | Table is `sch_academic_term` (singular) |
| `hst_allotments.allotted_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_fee_structures.academic_term_id` | INT UNSIGNED | `sch_academic_term.id` | |
| `hst_fee_structures.created_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_mess_weekly_menus.academic_term_id` | INT UNSIGNED | `sch_academic_term.id` | |
| `hst_special_diets.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_special_diets.approved_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_visitor_log.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_visitor_log.verified_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_movement_log.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_attendance.academic_term_id` | INT UNSIGNED | `sch_academic_term.id` | |
| `hst_attendance.taken_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_complaints.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_complaints.assigned_to` | INT UNSIGNED | `sys_users.id` | |
| `hst_complaints.resolved_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_sick_bay_log.student_id` | INT UNSIGNED | `std_students.id` | |
| `hst_sick_bay_log.attended_by` | INT UNSIGNED | `sys_users.id` | Nurse/doctor |
| `hst_sick_bay_log.hpc_record_id` | BIGINT UNSIGNED | *(no FK)* | Soft ref to HPC module — no DB constraint |
| `hst_leave_passes.approved_by` | INT UNSIGNED | `sys_users.id` | |
| `hst_incident_media.media_id` | **INT UNSIGNED** | `sys_media.id` | INT UNSIGNED — sys_media.id is INT UNSIGNED |
| All `created_by` / `updated_by` | INT UNSIGNED | `sys_users.id` | 21 tables × 2 = 42 FKs |

> **FK Type Rule:** All cross-module FKs use `INT UNSIGNED` (matching parent PK types in tenant_db_v2.sql). HST-internal PKs and FKs use `BIGINT UNSIGNED`.

---

## Special Design Notes

### Double-Allotment Prevention (hst_allotments)
Two generated columns enforce that no bed or student can have two active allotments simultaneously:
```sql
gen_active_bed_id     BIGINT GENERATED ALWAYS AS (IF(status='active', bed_id, NULL)) STORED
gen_active_student_id BIGINT GENERATED ALWAYS AS (IF(status='active', student_id, NULL)) STORED
UNIQUE KEY uq_hst_allot_active_bed (gen_active_bed_id)
UNIQUE KEY uq_hst_allot_active_student (gen_active_student_id)
```
MySQL allows multiple NULLs in a UNIQUE index, so vacated/transferred allotments don't block new active ones.

### Cascade Deletes
| Parent Table | Child Table | Behavior |
|-------------|------------|---------|
| `hst_attendance` | `hst_attendance_entries` | CASCADE DELETE |
| `hst_incidents` | `hst_incident_media` | CASCADE DELETE |

### Denormalized Counters
| Column | Table | Maintained By |
|--------|-------|--------------|
| `present_count`, `absent_count`, `leave_count`, `late_count` | `hst_attendance` | `HstAttendanceService::computeAndStoreCounts()` |
| `current_occupancy` | `hst_hostels` | `AllotmentService` |
| `current_occupancy` | `hst_rooms` | `AllotmentService` |

### Status FSMs
| Table | Column | States |
|-------|--------|--------|
| `hst_allotments` | `status` | active → vacated / transferred / suspended |
| `hst_beds` | `status` | available ↔ occupied / reserved / maintenance |
| `hst_complaints` | `status` | open → assigned → in_progress → resolved / escalated / closed |
| `hst_leave_passes` | `status` | pending → approved / rejected → completed |

---

## ENUM Reference

| Table | Column | Values |
|-------|--------|--------|
| `hst_hostels` | `hostel_type` | boys, girls, co-ed |
| `hst_rooms` | `room_type` | dormitory, private, semi-private, suite |
| `hst_beds` | `status` | available, occupied, reserved, maintenance |
| `hst_fee_structures` | `billing_cycle` | monthly, quarterly, annually, one-time |
| `hst_mess_weekly_menus` | `day_of_week` | monday, tuesday, wednesday, thursday, friday, saturday, sunday |
| `hst_mess_weekly_menus` | `meal_type` | breakfast, lunch, snacks, dinner |
| `hst_allotments` | `status` | active, vacated, transferred, suspended |
| `hst_allotments` | `gender` | male, female, other |
| `hst_movement_log` | `movement_type` | out, in |
| `hst_movement_log` | `purpose` | leave, outing, emergency, medical, other |
| `hst_attendance_entries` | `status` | present, absent, late, leave, sick_bay |
| `hst_mess_attendance` | `status` | present, absent, leave, special |
| `hst_incidents` | `severity` | low, medium, high, critical |
| `hst_incidents` | `status` | open, under_investigation, resolved, closed |
| `hst_complaints` | `priority` | low, medium, high, urgent |
| `hst_complaints` | `status` | open, assigned, in_progress, resolved, escalated, closed |
| `hst_leave_passes` | `leave_type` | home, medical, emergency, other |
| `hst_leave_passes` | `status` | pending, approved, rejected, completed |
| `hst_room_change_requests` | `status` | pending, approved, rejected, completed |
| `hst_sick_bay_log` | `discharge_status` | recovered, referred, hospitalized |

---

## Index Summary

| Table | Index Type | Columns | Purpose |
|-------|-----------|---------|---------|
| `hst_allotments` | UNIQUE (generated) | `gen_active_bed_id` | BR-HST-001: one active allotment per bed |
| `hst_allotments` | UNIQUE (generated) | `gen_active_student_id` | BR-HST-002: one active allotment per student |
| `hst_attendance` | UNIQUE | `hostel_id, date, academic_term_id` | One attendance record per hostel per day |
| `hst_mess_attendance` | UNIQUE | `student_id, date, meal_type` | One mess attendance per student per meal |
| `hst_fee_structures` | UNIQUE | `room_type, academic_term_id` | One fee structure per room type per term |
| `hst_warden_assignments` | INDEX | `user_id, floor_id` | WardenScopeMiddleware lookups |
| All status columns | INDEX | `status` | FSM-based filtering |
| All date columns | INDEX | `date`, `departure_date`, etc. | Date-range queries |
