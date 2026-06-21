# Hostel Module — Report Design v1

> **Source DDL:** `1-DDL_Tenant_Modules/Hostel/DDL/HST_DDL_v3.sql` (36 tables, 2026-05-04).
> **Audience:** Developers building the Hostel reporting suite.
> **Scope:** Every report needed to operate a hostel — operational, compliance, financial, audit, executive dashboards.
> **Database:** tenant_db (per-school). All `hst_*` tables.

---

## 1. Conventions used in this document

- **Report ID** — `R-HST-NNN` (R-HST-001 ... ). Reuse the ID in tickets, routes, and tests.
- **Type** — `LIST` (paginated data grid) · `PIVOT` (cross-tab) · `CHART` (visual) · `KPI` (tile / scorecard) · `REGISTER` (printable, day-wise) · `DETAIL` (single-entity drilldown).
- **Audience** — `Warden`, `Chief Warden`, `Principal`, `HOD`, `Finance`, `Parent`, `Student`, `Auditor`.
- **Refresh** — `Live` (no cache) · `5 min` · `1 h` · `Daily` · `Manual`.
- **Export** — `PDF` (DomPDF), `Excel` (Maatwebsite), `CSV`, `Print`.
- **Tables used** — first table is primary; subsequent ones join in. Soft-deleted rows always filtered (`deleted_at IS NULL`) unless the report is explicitly an audit-trail report.
- **Status decoding** — every `status` column on hst_* tables is an FK to `hst_dynamic_status_masters`. Reports MUST display `name` from that table, not the numeric `id`. Standard alias: join via `JOIN hst_dynamic_status_masters s ON s.id = t.status`.
- **Tenant scoping** — every query already runs inside the tenant database (DB-per-tenant). No `tenant_id` filter required.

## 2. Standard filter chips (shared by most reports)

| Filter | Source | Notes |
|--------|--------|-------|
| Academic Session | `sch_academic_term.id` | Default = current session. |
| Hostel | `hst_hostels.id` | Multi-select; default = all the user can access (warden scoping). |
| Floor / Block | `hst_floors.id` / `block_code` | Cascade from hostel. |
| Room Type | `hst_room_types.id` | Multi-select. |
| Date Range | from / to | Default per report (today / current month). |
| Status | `hst_dynamic_status_masters` (status_type filtered to report context) | Multi-select. |
| Student | `std_students.id` | Auto-complete by name / admission no. |
| Class / Section | `sch_classes.id`, `sch_sections.id` | When report cuts by class. |
| Gender | `hst_hostels.type` (boys/girls/mixed) | Implied by hostel selection but allows global filter. |
| Include Inactive | toggle | Default OFF. |
| Include Soft-Deleted | toggle | Auditor-only; default OFF. |

## 3. Standard column conventions

| Column | Source | Display rule |
|--------|--------|--------------|
| Student | `std_students.first_name + ' ' + std_students.last_name`, `admission_no` | Hyperlink to student profile. |
| Class | `sch_classes.name + '-' + sch_sections.name` | E.g. "X-A". |
| Hostel | `hst_hostels.name` | Code in tooltip. |
| Room | `hst_rooms.room_number`, `hst_floors.floor_number`, `hst_hostels.code` | E.g. "203 (Floor 2, BH1)". |
| Bed | `hst_beds.bed_label` | E.g. "Lower". |
| Warden | `sys_users.first_name + sys_users.last_name` | Hyperlink. |
| Status | `hst_dynamic_status_masters.name` | Color from `priority_flags_json`/badge palette. |
| Amount | `DECIMAL(10,2)` | Locale-aware ₹ formatting; thousands separator. |
| Date | DATE | `DD-MMM-YYYY`. |
| Date-Time | TIMESTAMP | `DD-MMM-YYYY HH:mm`. |
| Duration | computed | `DATEDIFF` / `TIMEDIFF`. |

## 4. Report catalogue overview

| # | Section | Reports |
|---|---------|---------|
| A | Occupancy & Allotment | R-HST-001 .. R-HST-007 |
| B | Attendance (hostel roll-call) | R-HST-010 .. R-HST-013 |
| C | Movement & Visitor | R-HST-020 .. R-HST-023 |
| D | Leave Pass | R-HST-030 .. R-HST-032 |
| E | Discipline & Incidents | R-HST-040 .. R-HST-043 |
| F | Complaints & Maintenance | R-HST-050 .. R-HST-053 |
| G | Mess Operations | R-HST-060 .. R-HST-064 |
| H | Sick Bay / Medical | R-HST-070 .. R-HST-072 |
| I | Fee & Financial | R-HST-080 .. R-HST-083 |
| J | Laundry | R-HST-090 |
| K | Warden Duty / HR | R-HST-100 .. R-HST-102 |
| L | Audit & Compliance | R-HST-110 .. R-HST-112 |
| M | Executive Dashboard | R-HST-120 .. R-HST-122 |
| N | Reservations & Admission Funnel | R-HST-130 .. R-HST-131 |

**Total: 39 reports.**

---

# A. Occupancy & Allotment Reports

## R-HST-001 — Hostel-wide Occupancy Snapshot

| Field | Value |
|-------|-------|
| Type | `KPI` + `LIST` |
| Audience | Chief Warden, Principal |
| Purpose | Live view of bed occupancy across every hostel: total capacity, occupied, vacant, reserved, under maintenance. |
| Refresh | 5 min (cached) |
| Layout | KPI strip at top (Total / Occupied / Vacant / Under Maintenance / Reserved / Occupancy %) + per-hostel list grid. |

**Tables used**
- Primary: `hst_hostels`
- Joined: `hst_floors`, `hst_rooms`, `hst_beds`, `hst_dynamic_status_masters` (bed status), `hst_allotments` (active = `is_alloted = 1 AND deleted_at IS NULL`)

**Columns**

| # | Column | Source | Notes |
|---|--------|--------|-------|
| 1 | Hostel | `hst_hostels.name` + `code` | — |
| 2 | Type | `hst_hostels.type` | boys / girls / mixed |
| 3 | Floors | `hst_hostels.total_floors` | — |
| 4 | Total Beds | `COUNT(hst_beds.id)` | — |
| 5 | Occupied | `COUNT(WHERE bed.status='occupied')` | — |
| 6 | Vacant | `COUNT(WHERE bed.status='available')` | — |
| 7 | Reserved | `COUNT(WHERE bed.status='reserved')` | — |
| 8 | Maintenance | `COUNT(WHERE bed.status='maintenance')` | — |
| 9 | Occupancy % | `occupied / total_beds * 100` | Color: < 70% green / 70-90 amber / > 90 red |
| 10 | Chief Warden | `hst_users join via warden_id` | hyperlink |
| 11 | Sick Bay Capacity | `hst_hostels.sick_bay_capacity` | — |

**Filters**
- Hostel (multi)
- Type (boys / girls / mixed)
- Show only hostels with `is_active = 1`
- "As of" date — defaults to today (uses historical allotments)

**Export** — PDF, Excel, Print.
**Drilldown** — clicking a hostel opens R-HST-002 for that hostel.
**Indexes used** — `idx_hst_bed_status`, `uq_hst_allot_active_bed`.
**SQL sketch**
```sql
SELECT h.id, h.name, h.type,
       SUM(CASE WHEN bs.code='occupied' THEN 1 ELSE 0 END)   AS occupied,
       SUM(CASE WHEN bs.code='available' THEN 1 ELSE 0 END)  AS vacant,
       SUM(CASE WHEN bs.code='reserved' THEN 1 ELSE 0 END)   AS reserved,
       SUM(CASE WHEN bs.code='maintenance' THEN 1 ELSE 0 END) AS maintenance,
       COUNT(b.id) AS total_beds
FROM hst_hostels h
LEFT JOIN hst_floors f ON f.hostel_id = h.id AND f.deleted_at IS NULL
LEFT JOIN hst_rooms  r ON r.floor_id  = f.id AND r.deleted_at IS NULL
LEFT JOIN hst_beds   b ON b.room_id   = r.id AND b.deleted_at IS NULL
LEFT JOIN hst_dynamic_status_masters bs ON bs.id = b.status
WHERE h.deleted_at IS NULL AND h.is_active = 1
GROUP BY h.id;
```

---

## R-HST-002 — Floor & Room Occupancy Map

| Field | Value |
|-------|-------|
| Type | `PIVOT` (floor × room grid) + `DETAIL` on click |
| Audience | Warden, Chief Warden |
| Purpose | Visual room-by-room map of a hostel: which rooms are full, vacant, maintenance, reserved. |
| Refresh | 5 min |
| Layout | Floor-wise rows; each room rendered as a tile with capacity / occupied / colored status. |

**Tables used** — `hst_hostels`, `hst_floors`, `hst_rooms`, `hst_beds`, `hst_dynamic_status_masters`, `hst_allotments` (active), `std_students` (for tooltip).

**Tile content per room**
- Room number, block_code
- Capacity vs current_occupancy (e.g. "2 / 3")
- Room status badge (available / full / maintenance / reserved)
- Hover tooltip: list of occupants (student name + class)
- Right-click: "Show damage history" → R-HST-053 filtered to this room

**Filters**
- Hostel (single, required)
- Floor (multi)
- Block code (multi)
- Room type (multi)
- Status (multi)
- Show only rooms with `accessibility_features_json IS NOT NULL` toggle

**Export** — PDF (print-friendly map), Excel (flat list).
**Indexes used** — `idx_hst_room_status`, `idx_hst_room_floor`, `idx_hst_bed_room`.

---

## R-HST-003 — Current Allotment Register

| Field | Value |
|-------|-------|
| Type | `LIST` / `REGISTER` (printable) |
| Audience | Warden, Chief Warden, Finance |
| Purpose | List of all currently-allotted students with room, bed, meal plan, allotment date, fee linked. |
| Refresh | Live |

**Tables used**
- Primary: `hst_allotments` (active: `is_alloted = 1`)
- Joined: `std_students`, `sch_classes`, `sch_sections`, `hst_beds`, `hst_rooms`, `hst_floors`, `hst_hostels`, `hst_dynamic_status_masters`, `sch_academic_term`

**Columns** — Student, Admission No, Class, Hostel, Floor, Room, Bed, Meal Plan, Allotment Date, Days Since Allotment, Is Emergency, Transferred-From, Allotment Status, Remarks.

**Filters**
- Standard chips +
- Meal Plan (multi)
- Is Emergency (Y/N/All)
- Allotment Status (`status` from dropdown)
- "Allotted between" date range
- Transferred (Y/N) — `transfer_from_allotment_id IS NOT NULL`

**Sort** — default: hostel, floor, room, bed.
**Pagination** — 50 rows.
**Export** — PDF, Excel, CSV. Printable register layout includes hostel header + warden signature block.
**Drilldown** — student row → student hostel profile page.
**Indexes used** — `uq_hst_allot_active_student`, `idx_hst_allot_session`, `idx_hst_allot_date`.

---

## R-HST-004 — Vacant Beds (Available for Allotment)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Admissions |
| Purpose | All currently-available beds matching admission preferences; basis for new allotments and re-allotments. |
| Refresh | Live |

**Tables used** — `hst_beds`, `hst_rooms`, `hst_floors`, `hst_hostels`, `hst_room_types`, `hst_bed_types`, `hst_dynamic_status_masters` (status='available'), `hst_room_reservations` (left join to flag soft-reserved beds), `hst_bed_maintenance_log` (left join to flag open tickets).

**Columns** — Hostel, Floor / Block, Room (with capacity), Bed Label, Bed Type, Windows Facing, Accessibility Features, Current Room Occupancy, Reservation Flag (if any), Maintenance Flag (if any open ticket), Available Since (date), Effective Fee (computed from `hst_fee_structures` for that room_type+meal_plan).

**Filters**
- Hostel / Type
- Room Type
- Bed Type
- Floor / Block
- Windows facing (multi)
- Accessibility features (multi-select keys from JSON)
- Meal plan (drives fee column)
- "Min capacity remaining" (number)
- Hide rooms with any open maintenance ticket (toggle)
- Hide rooms with pending room_reservations (toggle)

**Export** — Excel, CSV.
**Indexes used** — `idx_hst_bed_status`, `idx_hst_bed_room`.

---

## R-HST-005 — Allotment History (Transfers, Vacations, Waitlist)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Chief Warden, Auditor |
| Purpose | All allotment records — current + historical (transferred, vacated, waitlisted). Source for tenure reports and audit. |
| Refresh | Live |

**Tables used** — `hst_allotments`, `std_students`, `hst_beds`, `hst_rooms`, `hst_hostels`, `hst_dynamic_status_masters`, `hst_room_change_requests` (to mark transfer-driven moves).

**Columns** — Student, Hostel, Room, Bed, Allotment Date, Vacating Date, Stay (days), Status (active / vacated / transferred / waitlisted), Vacation Reason, Vacated By, Is Emergency, Transferred From (id + room snapshot), New Allotment (after this), Remarks.

**Filters**
- Standard +
- Vacation Reason (multi)
- Is Emergency (Y/N)
- "Min stay days" (number) — `vacating_date − allotment_date`
- Transfer chain only (`transfer_from_allotment_id IS NOT NULL`)
- Show soft-deleted (Auditor-only)

**Sort** — default: most recent activity first.
**Indexes used** — `idx_hst_allot_session`, `idx_hst_allot_transfer_from`, `idx_hst_allot_date`.

---

## R-HST-006 — Room Inventory & Damage Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Finance |
| Purpose | All room inventory items with condition, damage, repair status, financial responsibility, and photo evidence. |
| Refresh | Live |

**Tables used** — `hst_room_inventory`, `hst_rooms`, `hst_floors`, `hst_hostels`, `hst_dynamic_status_masters` (room_condition + repair_status), `std_students` (responsible student), `sys_media` (photo).

**Columns** — Hostel / Room, Item Name, Quantity, Room Condition (good/fair/poor), Repair Status, Last Inspected, Damage Description, Estimated Repair Cost, Responsible Student, Charge Pushed To Fee (Y/N), Photo (preview thumbnail).

**Filters**
- Standard +
- Room Condition (multi)
- Repair Status (multi)
- Responsible Student
- Has Damage (`damage_description IS NOT NULL`)
- Cost Range (₹ from / to)
- Charge Pushed (Y/N)
- Photo Available (Y/N) — `photo_media_id IS NOT NULL`

**Export** — PDF (with embedded photos), Excel.
**Drilldown** — item row → full damage history + linked fee_demand (R-HST-082).

---

## R-HST-007 — Occupancy Trend (time-series)

| Field | Value |
|-------|-------|
| Type | `CHART` (line / area) + `LIST` |
| Audience | Principal, Chief Warden |
| Purpose | Daily occupancy % per hostel over a date range. Identifies seasonal patterns. |
| Refresh | Daily |

**Tables used** — `hst_allotments` (computed daily count using `allotment_date` and `vacating_date`), `hst_hostels`.

**Computation** — for each day `d` in range and each hostel: `occupancy_pct = COUNT(allotments WHERE allotment_date ≤ d AND (vacating_date IS NULL OR vacating_date > d)) / hostel.total_capacity × 100`.

**Filters** — Hostel (multi), Date range (default: last 90 days), Granularity (day / week / month).

**Export** — PNG (chart), Excel (data + chart).
**Cache** — daily snapshot table recommended (precompute nightly into `hst_occupancy_snapshots_view` materialised view or scheduled job).

---

# B. Attendance Reports (hostel roll-call)

## R-HST-010 — Daily Attendance Register

| Field | Value |
|-------|-------|
| Type | `REGISTER` (printable) |
| Audience | Warden, Parent (own-child filter) |
| Purpose | Per-hostel, per-shift attendance for a single day. Printable for warden file. |
| Refresh | Live |

**Tables used** — `hst_attendance` + `hst_attendance_entries` + `std_students` + `hst_dynamic_status_masters` + `hst_allotments` (to resolve room) + `hst_hostels`.

**Columns** — Sr.No, Student, Admission No, Class, Room/Bed, Status (Present/Absent/Leave/Sick Bay/Late/Home), Check-in time, Late remarks. Footer: counts per status, "marked_by" name, locked flag.

**Filters** — Hostel, Date (default today), Shift (morning/evening/night), Class (optional).
**Indexes used** — `uq_hst_att_session`, `idx_hst_ae_attendance`, `uq_hst_att_entry`.
**Sort** — Room → bed → student name.
**Export** — PDF (warden file format with signature block), Excel.

---

## R-HST-011 — Student Attendance % Report

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Warden, Class Teacher, Parent |
| Purpose | Per-student attendance % across a date range, for hostel roll-call. |
| Refresh | Daily |

**Tables used** — `hst_attendance_entries`, `hst_attendance`, `std_students`, `hst_dynamic_status_masters`, `hst_allotments` (active).

**Computation per student**

```
total_sessions  = COUNT(entries)
present_sessions = COUNT(entries WHERE status='present')
late_sessions    = COUNT(entries WHERE status='late')
absent_sessions  = COUNT(entries WHERE status='absent')
leave_sessions   = COUNT(entries WHERE status='leave')
home_sessions    = COUNT(entries WHERE status='home')
sickbay_sessions = COUNT(entries WHERE status='sick_bay')

attendance_pct = (present_sessions + late_sessions) / total_sessions × 100
```

**Columns** — Student, Class, Room, Total Sessions, Present, Late, Absent, On Leave, At Home, Sick Bay, Attendance %.

**Filters** — Standard + Class + "Below %" threshold (e.g. show students under 75%) + Group by (class / room / floor).

**Drilldown** — student row → R-HST-012.
**Chart** — bar of bottom-20 students by attendance %.

---

## R-HST-012 — Per-student Attendance Calendar

| Field | Value |
|-------|-------|
| Type | `DETAIL` — monthly calendar |
| Audience | Warden, Parent, Student |
| Purpose | Calendar view of a single student's daily hostel attendance with status colour-coding. |
| Refresh | Live |

**Tables used** — `hst_attendance_entries`, `hst_attendance`, `hst_dynamic_status_masters`.

**Filters** — Student (required), Month (default current).

**Display** — month grid: each cell = the day's hostel-attendance status (combine all shifts of that day with a per-shift dot or worst-shift colour). Tooltip: per-shift detail + late_remarks.

---

## R-HST-013 — Roll-call Compliance Report (warden-side)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Chief Warden |
| Purpose | Identifies which hostel-shifts were NOT marked, or marked late, or marked but not locked. |
| Refresh | Daily |

**Tables used** — `hst_attendance`, `hst_hostels`, `hst_warden_duty_roster` (to identify expected warden), `sys_users`.

**Computation** — for each (hostel, date, shift) in expected schedule:
- `was_marked` = exists row in `hst_attendance`
- `marked_on_time` = `created_at` within the shift window
- `is_locked` from the row
- Expected warden = duty roster for that slot
- Actual warden = `hst_attendance.marked_by`

**Columns** — Hostel, Date, Shift, Marked (Y/N), Marked At, Locked (Y/N), Expected Warden, Actual Warden, Mismatch (Y/N), Delay (minutes).

**Filters** — Date range (default last 7 days), Hostel, Shift, "Only show missing" toggle.
**Export** — Excel.

---

# C. Movement & Visitor Reports

## R-HST-020 — Daily In/Out Movement Register

| Field | Value |
|-------|-------|
| Type | `REGISTER` |
| Audience | Warden, Security |
| Purpose | Day-wise gate-pass log: who left, when, expected return, actual return. |
| Refresh | Live |

**Tables used** — `hst_movement_log`, `std_students`, `hst_hostels`, `sys_users` (gate_pass_issued_by), `sys_media` (consent).

**Columns** — Sr.No, Student, Class, Out Time, Destination, Purpose, Expected Return, Actual Return (in_time), Late by (mins), Overnight (Y/N), Parent Consent (Y/N + view consent doc), Gate pass issued by, Overdue notified.

**Filters** — Hostel, Date (default today), Overnight (Y/N), Currently out (`in_time IS NULL`), Overdue only (`expected_return_time < now AND in_time IS NULL`), Class.

**Indexes used** — `idx_hst_ml_hostel_date`, `idx_hst_ml_expected_return`, `idx_hst_ml_student_in`.
**Drilldown** — row → student movement history (last 30 days).

---

## R-HST-021 — Currently-Out / Overdue Students (Live Dashboard)

| Field | Value |
|-------|-------|
| Type | `KPI` + `LIST` |
| Audience | Warden, Security, Principal |
| Purpose | Real-time list of students currently outside the hostel, flagging anyone past their expected return. |
| Refresh | Live (no cache; every page load) |

**Tables used** — `hst_movement_log` (where `in_time IS NULL AND deleted_at IS NULL`), `std_students`.

**KPI tiles** — Total currently out · Overdue · Overnight expected · Without parent consent.

**List columns** — Student, Out Time, Expected Return, Time Overdue, Destination, Phone (guardian), Issued By, Quick action: "Mark Returned", "Notify Parent" → writes `hst_notification_log`.

**Filters** — Hostel, Overdue only, Overnight only, Without consent.

---

## R-HST-022 — Visitor Log Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Security |
| Purpose | Day-wise / range visitor entries with ID proof, photo, override flag. |
| Refresh | Live |

**Tables used** — `hst_visitor_log`, `std_students`, `sys_users` (allowed_by), `sys_media` (photo, signed register), `hst_visitor_media` (multi-photo).

**Columns** — Sr.No, Visit Date, Visitor Name, Relationship, Visitor Phone, ID Proof (Type / Masked No.), Student, In Time, Out Time, Duration, Purpose, Allowed By, Outside Visiting Hours (Y/N + override reason), Photo (preview), Signed Register (preview).

**Filters** — Hostel, Date range (default current month), Visitor Name (partial), Student, Relationship, Outside hours (Y/N), Override Reason present (Y/N), Photo missing (compliance toggle), ID proof missing.

**Indexes used** — `idx_hst_vl_hostel_date`, `idx_hst_vl_student`.
**Export** — PDF (with thumbnail), Excel.

---

## R-HST-023 — Visitor Frequency Summary (per student)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Chief Warden, Parent |
| Purpose | How often each student receives visits — pattern detection (very frequent, very rare). |
| Refresh | Daily |

**Tables used** — `hst_visitor_log`, `std_students`.

**Computation per student** — `total_visits`, `total_unique_visitors`, `avg_visits_per_month`, `last_visit_date`, `outside_hours_count`.

**Columns** — Student, Class, Hostel, Total visits, Distinct visitors, Avg per month, Last visit, Outside-hours count.

**Filters** — Date range (default 90 days), Hostel, "Min visits", "Max visits", Class.

**Sort** — by `total_visits` desc by default.

---

# D. Leave Pass Reports

## R-HST-030 — Pending Leave Pass Approvals (queue)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden / Approver |
| Purpose | All leave passes awaiting approval, sorted by urgency (from_date). |
| Refresh | Live |

**Tables used** — `hst_leave_passes` with `status` = pending (resolve via dropdown lookup), `std_students`, `hst_allotments`, `hst_hostels`, `sys_users` (applied_by), `sys_media` (consent).

**Columns** — Student, Class, Hostel/Room, Leave Type, From, To, Days, Destination, Purpose, Guardian Name + Contact, Overnight (Y/N), Parent Consent (Y/N), Applied At, Pending (hours), Approve/Reject actions.

**Filters** — Hostel, Leave Type, From-date window, Overnight, Consent missing, Class.
**Indexes used** — `idx_hst_lp_status`, `idx_hst_lp_dates`.

---

## R-HST-031 — Active & Upcoming Leaves (Hostel View)

| Field | Value |
|-------|-------|
| Type | `LIST` + Calendar |
| Audience | Warden, Mess in-charge (for headcount) |
| Purpose | Approved leaves that affect today + the next N days — drives mess attendance & bed availability planning. |
| Refresh | Live |

**Tables used** — `hst_leave_passes` (status=approved + from_date ≤ today + N), `std_students`, `hst_allotments`.

**Columns** — Student, Class, Room, Leave Type, From, To, Destination, Returned (Y/N), Days Remaining, Actual Return Date, Late Return Incident link.

**View toggle** — list / calendar (Gantt-style bars per student over date range).

---

## R-HST-032 — Leave Pass Statistics (compliance + trend)

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Chief Warden, Principal |
| Purpose | Frequency of leave per student, late returns, leave-type distribution. |
| Refresh | Daily |

**Tables used** — `hst_leave_passes`, `std_students`, `hst_incidents` (joined via `late_return_incident_id`).

**Per-student summary** — total leaves taken, total days, late returns count, longest leave, most-common reason.

**Charts** — pie of leave-type distribution; bar of top-10 students by leave count.

**Filters** — Date range (current session default), Hostel, Class, Late-return-only.

---

# E. Discipline & Incident Reports

## R-HST-040 — Incident Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Chief Warden, Principal |
| Purpose | Discipline incident log with severity, action, escalation, warnings. |
| Refresh | Live |

**Tables used** — `hst_incidents`, `hst_incident_types`, `std_students`, `hst_hostels`, `sys_users` (reported_by), `hst_incident_warnings`, `hst_incident_media`.

**Columns** — Date / Time, Student, Class, Hostel, Incident Type (from master), Severity, Description, Action Taken, Reported By, Escalated (Y/N + at), Warning Sent (count from warnings), Parent Notified, Auto-generated, Attachments (count).

**Filters** — Standard + Severity (multi) + Incident Type (multi, via `hst_incident_types`) + Auto-generated only + Has Warning (Y/N) + Parent Notified (Y/N).
**Indexes used** — `idx_hst_inc_date`, `idx_hst_inc_type_id`, `idx_hst_inc_student`.

---

## R-HST-041 — Per-student Discipline History

| Field | Value |
|-------|-------|
| Type | `DETAIL` |
| Audience | Class Teacher, Counsellor, Parent (own child) |
| Purpose | Chronological discipline history for one student with all warning letters. |
| Refresh | Live |

**Tables used** — `hst_incidents`, `hst_incident_warnings`, `hst_incident_media`, `hst_dynamic_status_masters`.

**Sections**
1. Summary KPIs — total incidents, minor / moderate / serious counts, total warnings (verbal / written / final / suspension).
2. Timeline — chronological list of incidents with linked warnings.
3. Warning letters table — date, level, signed by, delivered_at, parent_acknowledged_at, download letter (`letter_media_id`).

**Filters** — Student (required), Session, Date range.

---

## R-HST-042 — Warning-letter Audit (per student / hostel)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Principal, Chief Warden, Auditor |
| Purpose | Warning-letter dispatch + acknowledgement audit. |
| Refresh | Live |

**Tables used** — `hst_incident_warnings`, `hst_incidents`, `std_students`, `sys_users` (signed_by), `sys_media` (letter PDF).

**Columns** — Date Signed, Student, Incident (link), Warning Level, Template, Subject, Signed By, Delivered (date + method), Acknowledged (date + method), Days to Ack, Letter PDF.

**Filters** — Date range, Warning Level (multi), Delivery Method, Acknowledgement Method, Unacknowledged > N days (compliance).
**Indexes used** — `idx_hst_iw_student`, `idx_hst_iw_incident`.

---

## R-HST-043 — Incident Type Heatmap

| Field | Value |
|-------|-------|
| Type | `PIVOT` (incident type × month) + Heatmap |
| Audience | Principal |
| Purpose | Identify hotspots — which incident types peak in which month / hostel. |
| Refresh | Daily |

**Tables used** — `hst_incidents`, `hst_incident_types`.

**Layout** — rows = incident type; cols = month within session; cell = count, color intensity by count.

**Filters** — Session, Hostel (multi), Severity.

---

# F. Complaints & Maintenance Reports

## R-HST-050 — Open Complaints (SLA dashboard)

| Field | Value |
|-------|-------|
| Type | `LIST` + `KPI` |
| Audience | Warden, Assigned staff |
| Purpose | All open complaints sorted by SLA due-date; flag overdue. |
| Refresh | Live |

**Tables used** — `hst_complaints`, `hst_hostels`, `hst_rooms`, `std_students`, `sys_users` (assigned_to), `hst_dynamic_status_masters`.

**KPI** — Open · In Progress · Resolved last 7d · Overdue · Avg time to resolve.

**Columns** — Subject, Category, Priority, Status, Reporter (student or user), Room (if any), Assigned To, Acknowledged At, SLA Due, Overdue By, Last Update.

**Filters** — Standard + Category (multi) + Priority (multi) + Status (multi) + Assigned-To + Overdue-only + Escalated-only + Unacknowledged (`acknowledged_at IS NULL`).
**Indexes used** — `idx_hst_cmp_status_sla`, `idx_hst_cmp_assigned`.

---

## R-HST-051 — Complaint Resolution Performance

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Principal, Chief Warden |
| Purpose | Resolution SLA performance — by category, by assignee. Satisfaction score trend. |
| Refresh | Daily |

**Tables used** — `hst_complaints`.

**Per-category KPIs** — avg time to acknowledge, avg time to resolve, SLA-breach %, avg satisfaction score (1-5).

**Per-assignee table** — Assignee, Total Closed, Avg Time to Resolve, % SLA Met, Avg Satisfaction.

**Filters** — Date range, Hostel, Category.

---

## R-HST-052 — Bed Maintenance Tickets

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Maintenance staff |
| Purpose | Open + resolved bed/room maintenance tickets with cost, photos, blocked-bed flag. |
| Refresh | Live |

**Tables used** — `hst_bed_maintenance_log`, `hst_beds`, `hst_rooms`, `hst_hostels`, `sys_users` (reported_by, assigned_to), `hst_dynamic_status_masters`, `sys_media` (before / after photos).

**Columns** — Reported At, Hostel / Room / Bed, Severity, Issue, Reporter, Assigned To, Status, Bed Blocked (Y/N), Cost Estimated, Cost Actual, Resolved At, Days Open, Before/After Photos.

**Filters** — Standard + Severity (multi) + Status (multi) + Bed Blocked (Y/N) + Cost > threshold + Date Range.
**Indexes used** — `idx_hst_bm_status`, `idx_hst_bm_reported_at`.

---

## R-HST-053 — Housekeeping Daily Log

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden |
| Purpose | Daily housekeeping records, quality rating, re-cleaning needed. |
| Refresh | Live |

**Tables used** — `hst_housekeeping_log`, `hst_rooms`, `hst_hostels`, `sys_users`, `sys_media`.

**Columns** — Date, Hostel, Room or Area, Service Type, Cleaned By, Verified By, Quality Rating (1-5), Issues Found, Re-cleaning Required, Photo.

**Filters** — Date range, Hostel, Service Type (multi), Quality < threshold, Re-cleaning required toggle.

---

# G. Mess Operations Reports

## R-HST-060 — Daily Mess Attendance

| Field | Value |
|-------|-------|
| Type | `REGISTER` |
| Audience | Mess in-charge, Warden |
| Purpose | Per-meal attendance for headcount + cost reconciliation. |
| Refresh | Live |

**Tables used** — `hst_mess_attendance`, `std_students`, `hst_hostels`, `hst_dynamic_status_masters`, `hst_special_diets` (for special_diet_served flag).

**Columns** — Student, Class, Status (present/absent/on_leave/opted_out), Special Diet Served (Y/N + desc), Marked By, Shift (if multi-shift), Time.

**Filters** — Hostel, Date (default today), Meal Type (breakfast/lunch/dinner/snacks), Shift, Class.
**Indexes used** — `uq_hst_mess_att`.

**Summary footer** — present count, absent count, special diet count.

---

## R-HST-061 — Mess Headcount Forecast

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Mess in-charge |
| Purpose | Tomorrow / future-day mess headcount projection — drives kitchen procurement. |
| Refresh | 1 h |

**Computation** — `expected_headcount = active_allotments − approved_leaves_overlapping − approved_mess_opt_outs_overlapping`.

**Tables used** — `hst_allotments`, `hst_leave_passes` (approved), `hst_mess_opt_outs` (approved + active), `hst_special_diets`.

**Columns per date × meal_type** — Total Boarders, On Leave, Opted Out, Special Diet count, Expected Headcount, Notes.

**Filters** — Hostel, Meal Type, Date Range (default today + 7 days).

---

## R-HST-062 — Mess Opt-out Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Mess in-charge, Warden |
| Purpose | All mess opt-outs (pending / approved / cancelled) with credit-applied flag. |
| Refresh | Live |

**Tables used** — `hst_mess_opt_outs`, `std_students`, `hst_hostels`, `hst_dynamic_status_masters`, `sys_users` (approved_by).

**Columns** — Student, From, To, Meal Types (decoded from JSON), Reason, Recurring (Y/N + pattern), Status, Approved By, Approved At, Credit Applied (Y/N).

**Filters** — Hostel, Date range, Reason (multi), Status, Recurring, Credit Pending (`status='approved' AND mess_bill_credit_applied=0`).

---

## R-HST-063 — Monthly Mess Bills

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Mess in-charge, Finance, Parent (own child) |
| Purpose | Per-student monthly bill with totals, credits, manual adjustment. |
| Refresh | Daily |

**Tables used** — `hst_mess_bills`, `std_students`, `hst_hostels`, `hst_dynamic_status_masters`, `hst_fee_demands` (link).

**Columns** — Student, Hostel, Bill Month, Meal Plan, Meals Planned, Consumed, On Leave, Opted Out, Special Diet, Base, Special Diet Charge, Leave Credit, Opt-out Credit, Manual Adjustment + Reason, Total (auto), Pushed To Fee (Y/N + pushed_at), Status.

**Filters** — Bill Month (single, required), Hostel, Meal Plan, Status (multi), Pushed-to-fee (Y/N), Total > threshold.

**Indexes used** — `uq_hst_mb_student_month`.

**Drilldown** — bill row → per-day mess attendance + opt-out detail for that student/month.

---

## R-HST-064 — Weekly Menu Sheet (publishable)

| Field | Value |
|-------|-------|
| Type | `REGISTER` (printable / postable) |
| Audience | Students, Parents (read-only) |
| Purpose | Weekly mess menu in poster format. |
| Refresh | Manual (re-publish) |

**Tables used** — `hst_mess_weekly_menus`.

**Layout** — 7-day × 4-meal grid: each cell shows menu_description and special_diet_description (if available).

**Filters** — Hostel, Week start date (defaults to current week).
**Export** — PDF (poster size A3/A4 with school header).

---

# H. Sick Bay / Medical Reports

## R-HST-070 — Sick Bay Admission Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Nurse, Principal |
| Purpose | All sick-bay admissions (open + closed). |
| Refresh | Live |

**Tables used** — `hst_sick_bay_log`, `std_students`, `hst_hostels`, `sys_users` (attending_staff_id).

**Columns** — Admission Date/Time, Student, Class, Symptoms, Initial Diagnosis, Attending Staff, Discharge Date/Time, Duration, Hospital Referred (Y/N), Parent Notified, Medical Consent (Y/N), Treatment Notes, Discharge Notes.

**Filters** — Hostel, Admission date range (default last 30 days), Currently admitted (`discharge_datetime IS NULL`), Hospital referred only, Consent missing only.
**Indexes used** — `idx_hst_sb_hostel_admission`, `idx_hst_sb_discharge`, `idx_hst_sb_hospital_ref`.

---

## R-HST-071 — Sick Bay Detail (vitals + medication)

| Field | Value |
|-------|-------|
| Type | `DETAIL` |
| Audience | Nurse, Doctor, Parent (own child) |
| Purpose | Full clinical record of one admission with vital-sign trend and medications. |
| Refresh | Live |

**Tables used** — `hst_sick_bay_log`, `hst_sick_bay_vitals`, `hst_sick_bay_medications`, `sys_users`.

**Sections**
1. Admission header (admission/discharge, symptoms, attending staff).
2. Vitals chart — line chart of temperature, pulse, SpO2 over time; tabular view with `is_alarm` highlighted in red.
3. Medications table — Drug, Generic, Dose, Route, Prescribed By, Administered At, Administered By, Self-administered (Y/N), Notes.

**Filters** — Sick Bay Log ID (required).

---

## R-HST-072 — Medical Trends (period-wise)

| Field | Value |
|-------|-------|
| Type | `CHART` + `LIST` |
| Audience | Principal, Chief Warden |
| Purpose | Trend of symptoms / admissions — detect outbreaks. |
| Refresh | Daily |

**Tables used** — `hst_sick_bay_log`, `hst_sick_bay_vitals` (alarms).

**Charts**
- Daily admissions count (line)
- Symptom frequency (bar) — extract top words / categories from `presenting_symptoms`
- Avg admission duration (KPI)
- Hospital referral rate (KPI)
- Alarm-vital count (KPI)

**Filters** — Date range, Hostel.

---

# I. Fee & Financial Reports

## R-HST-080 — Hostel Fee Demand Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Finance, Chief Warden |
| Purpose | Every fee demand raised by hostel — room rent, mess, electricity, damage, penalty etc. |
| Refresh | Live |

**Tables used** — `hst_fee_demands`, `std_students`, `hst_hostels`, `hst_dynamic_status_masters`, `hst_allotments`.

**Columns** — Date, Student, Demand Type, Period (start→end), Amount, Description, Source Table + Source Id, Status (draft/pushed/accepted/rejected/revised/settled), Pushed At, External Demand Id (fin_* link), External Invoice Id.

**Filters** — Standard + Demand Type (multi) + Status + Period Range + Amount Range + Pushed-only / Pending-push only + Rejected-only.
**Indexes used** — `idx_hst_fd_student_status`, `idx_hst_fd_hostel_period`, `idx_hst_fd_external`.

---

## R-HST-081 — Pending Push to Finance

| Field | Value |
|-------|-------|
| Type | `LIST` + Action |
| Audience | Finance, Chief Warden |
| Purpose | Demands in `draft` status — need pushing to fin_*. |
| Refresh | Live |

**Tables used** — `hst_fee_demands` (status='draft' or 'rejected' / 'revised').

**Columns** — As R-HST-080 + bulk-action checkbox to "Push selected to Finance" (writes to fin_* via service + updates status to `pushed`).

**Filters** — Hostel, Demand Type, Date range.

---

## R-HST-082 — Damage Charge Reconciliation

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Finance, Warden |
| Purpose | Cross-link between `hst_room_inventory` damages and resulting `hst_fee_demands` of type `damage`. |
| Refresh | Live |

**Tables used** — `hst_room_inventory` (charge_pushed_to_fee=1), `hst_fee_demands` (demand_type='damage'), `std_students`, `hst_rooms`.

**Columns** — Inventory item, Damage description, Estimated cost, Responsible student, Demand raised (Y/N), Demand amount, Demand status, Difference (estimated vs raised).

**Filters** — Hostel, Date range, Mismatch only (estimated ≠ demand amount), Demand missing.

---

## R-HST-083 — Mess Bill → Fee Reconciliation

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Finance |
| Purpose | Reconcile finalised mess bills against pushed fee demands. |
| Refresh | Daily |

**Tables used** — `hst_mess_bills`, `hst_fee_demands` (via `fee_demand_id`).

**Columns** — Bill Month, Student, Total (bill), Pushed To Fee (Y/N), Pushed At, Linked Demand Id, Demand Amount, Difference, Demand Status.

**Filters** — Bill Month, Hostel, Difference > 0 only, Pushed-pending only.

---

# J. Laundry

## R-HST-090 — Laundry Ticket Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Warden, Laundry vendor, Parent |
| Purpose | All laundry tickets with status, items, weight, charge, disputes. |
| Refresh | Live |

**Tables used** — `hst_laundry_tickets`, `std_students`, `hst_hostels`, `hst_dynamic_status_masters`.

**Columns** — Ticket No, Student, Hostel, Submitted At, Items, Weight (kg), Expected Return, Returned At, Status, Charge, Pushed To Fee (Y/N), Dispute Notes, Submitted To (vendor).

**Filters** — Hostel, Status (multi: submitted/in_wash/ready/collected/lost/damaged/disputed), Submission date range, Pending-return (`returned_at IS NULL`), Dispute-only (`dispute_notes IS NOT NULL`), Lost/damaged-only.

**Indexes used** — `uq_hst_lt_ticket`, `idx_hst_lt_student_status`, `idx_hst_lt_submitted`.

---

# K. Warden Duty / HR

## R-HST-100 — Warden Duty Roster (calendar)

| Field | Value |
|-------|-------|
| Type | `REGISTER` / Calendar |
| Audience | Chief Warden |
| Purpose | Calendar of warden duty assignments — daily and nightly cover. |
| Refresh | Live |

**Tables used** — `hst_warden_duty_roster`, `sys_users`, `hst_hostels`, `hst_floors`.

**Layout** — calendar week / month view: each day cell shows shifts (morning/afternoon/evening/night/full_day/on_call) with warden name; emergency-cover entries highlighted; un-acknowledged entries flagged.

**Columns (list view)** — Date, Hostel, Floor, Shift, Warden, Replaces (when emergency cover), Acknowledged At, Notes.

**Filters** — Hostel, Floor, Date range (default current month), Shift, Emergency cover only, Unacknowledged only.

---

## R-HST-101 — Warden Activity Log

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Chief Warden, Principal |
| Purpose | Per-warden activity summary — attendance marked, incidents reported, complaints assigned. |
| Refresh | Daily |

**Tables used** — `sys_users` join with `hst_attendance.marked_by`, `hst_incidents.reported_by`, `hst_complaints.assigned_to`, `hst_warden_duty_roster.user_id`.

**Computation per warden over date range** — duty shifts done, attendance sessions marked, incidents reported, complaints handled, sick-bay admissions attended.

**Filters** — Date range, Hostel (multi).

---

## R-HST-102 — Warden Assignment History

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Chief Warden, HR |
| Purpose | Long-term warden assignment history (`hst_warden_assignments` — distinct from duty roster). |
| Refresh | Live |

**Tables used** — `hst_warden_assignments`, `sys_users`, `hst_hostels`, `hst_floors`.

**Columns** — Hostel, Floor, User, Assignment Type (chief/block/floor/assistant), Effective From, Effective To, Active (Y/N), Remarks.

**Filters** — Hostel, Assignment Type, Active only, Date "as of".

---

# L. Audit & Compliance Reports

## R-HST-110 — Generic Audit Trail Viewer

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Auditor, Principal |
| Purpose | Generic before/after change trail across any hst_* entity. |
| Refresh | Live |

**Tables used** — `hst_audit_log`, `sys_users`.

**Columns** — Created At, Entity Type, Entity Id, Action, Actor (User + Role), Reason, IP, Request ID, View Diff (modal showing `before_json` vs `after_json` and `field_diff_json`).

**Filters** — Date range, Entity Type (dropdown), Entity Id (free), Action (multi), Actor User (auto-complete), Request ID (free).

**Indexes used** — `idx_hst_al_entity`, `idx_hst_al_actor_time`, `idx_hst_al_action_time`, `idx_hst_al_request`.

**Export** — CSV (forensic format with JSON columns preserved).

---

## R-HST-111 — Notification Delivery Audit

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Principal, Compliance, Parent-app support |
| Purpose | Every notification dispatched — delivery status, retries, vendor IDs. |
| Refresh | Live |

**Tables used** — `hst_notification_log`, `sys_users` (recipient_user_id).

**Columns** — Created At, Entity (type + id, link), Notification Type, Channel, Recipient (name/phone/email), Subject, Status, Sent At, Delivered At, Read At, Retry Count, Failure Reason, External Message Id (Twilio/MSG91/SES).

**Filters** — Date range, Entity Type, Notification Type, Channel, Status (multi), Recipient phone/email (free), External Message Id (free).

**Indexes used** — `idx_hst_nl_entity`, `idx_hst_nl_status_time`, `idx_hst_nl_external`.

---

## R-HST-112 — Parent Consent Compliance

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Principal, Auditor |
| Purpose | Identifies events where parent consent was required but not received / not on file. |
| Refresh | Daily |

**Sources** — `hst_movement_log` (overnight without consent), `hst_leave_passes` (consent flag), `hst_sick_bay_log` (medical consent), `hst_visitor_log` (override without reason).

**Columns** — Event Date, Type (Movement / Leave / Sick Bay / Visitor Override), Student, Hostel, Consent Required (Y/N), Consent Received (Y/N), Consent Document (view), Compliance Flag.

**Filters** — Date range, Hostel, Type (multi), Non-compliant only (default ON).

---

# M. Executive Dashboard

## R-HST-120 — Hostel Operations Dashboard

| Field | Value |
|-------|-------|
| Type | `KPI` + multi-card layout |
| Audience | Principal, Chief Warden |
| Purpose | One-page overview of all hostel operations. |
| Refresh | 5 min |

**KPI tiles** — Total Occupancy %, Currently Out, Overdue Movement, Pending Leave Requests, Open Complaints, Overdue Complaints, Active Sick Bay Admissions, Pending Mess Bills, Pending Fee Demands, Today's Incidents, Pending Warning Letters, Unacknowledged Duty Slots.

**Quick widgets**
- Donut: bed status distribution (occupied / vacant / reserved / maintenance)
- Donut: complaint status
- Bar: today's mess attendance per meal
- Table: top-5 overdue movements, top-5 oldest open complaints, top-5 unacknowledged warning letters

**Filters** — Hostel scope (defaults to user's accessible hostels).

---

## R-HST-121 — Monthly Hostel Operations Report (PDF deliverable)

| Field | Value |
|-------|-------|
| Type | `REGISTER` (multi-page PDF) |
| Audience | Principal, Management Committee |
| Purpose | Monthly summary deliverable — printable / mailable. |
| Refresh | Monthly (scheduled) |

**Sections** — Cover, Executive summary, Occupancy stats, Attendance %, Incident summary, Discipline actions, Mess summary (bills + opt-outs), Complaint resolution, Maintenance, Sick bay summary, Fee summary, Warden duty fulfilment, Notable incidents (top-5).

**Filters** — Month (single), Hostel (multi).
**Export** — PDF only (templated DomPDF).
**Schedule** — first day of next month, auto-mailed to Principal.

---

## R-HST-122 — Parent-facing Monthly Statement

| Field | Value |
|-------|-------|
| Type | `REGISTER` (per-student PDF) |
| Audience | Parent |
| Purpose | Combined view delivered to parent: attendance %, mess bill, fee demands, incidents (only those with parent_notified=1), leave pass history, sick-bay visits. |
| Refresh | Monthly |

**Filters** — Student (parent-portal-scoped), Month.
**Privacy** — only fields where the corresponding compliance flag is set (e.g. only show incidents with `parent_notified=1`).
**Export** — PDF (auto-mailed) + parent portal download.

---

# N. Reservations & Admission Funnel

## R-HST-130 — Room Reservation Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Admissions, Chief Warden |
| Purpose | Pre-allotment reservations — both prospective and existing students. |
| Refresh | Live |

**Tables used** — `hst_room_reservations`, `std_students` (when populated), `hst_hostels`, `hst_rooms`, `hst_dynamic_status_masters`, `hst_allotments` (converted_to_allotment_id).

**Columns** — Reservation Date, Student or Prospective Name, Contact, Hostel, Room (requested or assigned), Room Type, Meal Plan, Intended Join Date, Valid Until, Days Until Expiry, Deposit Amount, Deposit Paid (Y/N + at), Status, Converted (Y/N + link).

**Filters** — Status (multi: pending / confirmed / expired / converted / cancelled / refunded), Hostel, Intended-join-date range, Valid-until window, Deposit pending, Converted only.

**Indexes used** — `idx_hst_rr_hostel_status`, `idx_hst_rr_valid`, `idx_hst_rr_converted_allot`.

---

## R-HST-131 — Reservation Funnel & Conversion

| Field | Value |
|-------|-------|
| Type | `CHART` + `LIST` |
| Audience | Admissions, Principal |
| Purpose | Funnel: reservations created → confirmed → converted → expired/cancelled. Conversion %, avg time-to-convert. |
| Refresh | Daily |

**Tables used** — `hst_room_reservations`, `hst_allotments` (converted_to_allotment_id).

**KPIs** — Total reservations, Conversion %, Cancellation %, Expiry %, Avg days reservation→allotment.

**Charts** — Funnel chart, monthly trend bar chart.

**Filters** — Reservation date range (default current session), Hostel.

---

# 5. Cross-cutting concerns (apply to all reports)

## 5.1 RBAC & data-scoping

| Role | Access |
|------|--------|
| Student | Own data only (R-HST-012, R-HST-071 for self, R-HST-122 own copy). |
| Parent | Own child only — same as Student, plus monthly statement (R-HST-122). |
| Floor Warden | Hostels + floors they are assigned (via `hst_warden_assignments` and `hst_warden_duty_roster`). |
| Chief Warden | All hostels in the school. |
| Principal | All reports. |
| Finance | Read-only on R-HST-080..083 + push action on R-HST-081. |
| Auditor | All reports + soft-deleted toggle + R-HST-110/111/112. |
| Nurse / Medical | R-HST-070, R-HST-071, R-HST-072 (write on log/vitals/meds). |

> **Implementation note.** Apply `EnsureUserHasHostelAccess` middleware (to be built) that filters by `hst_warden_assignments` for warden roles; Spatie roles drive access at the report-route level.

## 5.2 Export & branding

- **PDF** templates use DomPDF (per D9) with school header `prm_tenant.logo` + footer with page no, run-by, run-at, applied filters.
- **Excel** via Maatwebsite — multi-sheet for parent + child detail where applicable; freeze header row; auto-width.
- **CSV** — raw rows, no formatting; suitable for forensic export.

## 5.3 Performance & caching

- Reports flagged `Refresh = Daily` should be precomputed by a scheduler (e.g. `php artisan hostel:precompute-reports`) into materialised summary tables (TBD in implementation) — listed below as candidates:
  - `hst_occupancy_snapshots` (R-HST-007)
  - `hst_attendance_pct_monthly` (R-HST-011)
  - `hst_incident_monthly_pivot` (R-HST-043)
  - `hst_complaint_perf_monthly` (R-HST-051)
- "Live" reports must page (default 50 rows) and use the indexes called out per report.
- Heatmap / chart reports should clamp range to ≤ 13 months to avoid scan blowups.

## 5.4 Common pitfalls (developer checklist)

1. **Status decoding** — never display `status` as a raw integer; always join `hst_dynamic_status_masters`.
2. **Soft deletes** — apply `WHERE deleted_at IS NULL` everywhere except R-HST-110.
3. **Active allotment lookup** — use `is_alloted = 1 AND deleted_at IS NULL` and the generated `gen_active_*` indexes (`uq_hst_allot_active_bed`, `uq_hst_allot_active_student`) — NEVER scan by `status` text.
4. **Hostel scoping** — apply warden access filter before any GROUP BY (otherwise totals leak across hostels).
5. **JSON columns** — use `JSON_EXTRACT` / `->>` for filtering on `meal_types_json`, `accessibility_features_json`, `priority_flags_json`, `availability_24x7`, etc. Index virtual generated columns when query volume is high.
6. **PII** — masked Aadhaar / ID proof numbers must remain masked in exports (`id_proof_number_masked` field). Confirm before PDF export.
7. **Rate-limit** PDF export endpoints — heavy reports (R-HST-121, R-HST-122) must be queued (`hostel_reports` queue).
8. **Audit reads** — financial reports (R-HST-080..083, R-HST-122) MUST write a `hst_audit_log` row with `action='read'` when accessed (compliance — who-saw-what).

## 5.5 Common UI components (developer cheat-sheet)

| Component | Used in |
|-----------|---------|
| Standard filter sidebar | All LIST reports |
| Status badge component (from `hst_dynamic_status_masters`) | All reports with status column |
| Student auto-complete | Filters across all reports |
| Hostel-floor-room cascading select | Occupancy / Maintenance reports |
| Date-range picker | All time-bounded reports |
| KPI tile | Dashboards |
| Print-friendly stylesheet | All REGISTER reports |
| Chart wrapper (ApexCharts / Chart.js) | All CHART reports |
| PDF preview modal | Warning letters, monthly statements, vitals chart |

---

# 6. Implementation hand-off summary

For each report, the developer task should include:

1. Create a route under `Modules/Hostel/Http/Controllers/Reports/`.
2. Create a Form Request class for the filter set (D25 / D30).
3. Create a Service class `Modules\Hostel\Services\Reports\{ReportId}Service.php` returning a paginated collection / DTO.
4. Create a Resource for JSON shape.
5. Blade view in `Modules/Hostel/Resources/views/reports/{report_id}.blade.php` extending the shared report layout.
6. PDF view (if applicable) in `reports/pdf/{report_id}.blade.php` using DomPDF.
7. Excel export class in `Modules/Hostel/Exports/{ReportId}Export.php`.
8. Feature test in `Modules/Hostel/Tests/Feature/Reports/{ReportId}Test.php` covering: happy path, RBAC denial, filter combinations, export formats, soft-delete suppression.
9. Audit-read entry in financial / sensitive reports (R-HST-080..083, R-HST-070..072, R-HST-122, R-HST-042).
10. Add route to `routes/api.php` (mobile) and `routes/tenant.php` (web) with appropriate middleware (`auth`, role-gate, `EnsureUserHasHostelAccess`).

# 7. Open Questions / Deferred to v2 of this report design

1. **Materialised tables for daily reports** — name, refresh schedule, retention period (need ops sign-off).
2. **Cross-module reports** — combined attendance (academic + hostel), combined fee (academic + hostel + transport) — coordinate with `std_*` and `fin_*` modules. Out of v1 scope.
3. **Mobile-only report variants** — should be re-shaped from web list to card UI per `02_mobile_srs_*` design (see Mobile-App SRS) — deferred to mobile rollout.
4. **Visitor blacklist report** — depends on planned `hst_visitor_blacklist` (v4 DDL deferral).
5. **Custom-report builder** — not in v1; users get the 39 canonical reports.
6. **Multi-tenant aggregated reports** (central console across all schools) — out of scope (DB-per-tenant design).
7. **Real-time WebSocket dashboards** — Phase-2 enhancement; v1 polls every 5 min.

---

> **End of HST_Report_Design_v1.md** — 39 reports covering operational, compliance, financial, audit and executive needs of the Hostel module.
