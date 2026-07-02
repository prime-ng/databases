# PTM (Parent-Teacher Meeting) — Report Design v1

> **Source DDL:** `1-DDL_Tenant_Modules/2-SchoolSetup/PTM/Ptm_Setup_ddl_v3.sql` (9 tables).
> **Audience:** Developers building the PTM reporting suite.
> **DB:** tenant_db (per-school). Prefix `ptm_*`.

---

## 1. Conventions

- **Report ID** — `R-PTM-NNN`.
- **Type** — `LIST` · `PIVOT` · `CHART` · `KPI` · `REGISTER` (printable) · `DETAIL`.
- **Audience** — `Parent`, `Student`, `Teacher`, `Class-Teacher`, `Coordinator`, `Principal`, `Admin`.
- **Refresh** — `Live` · `5 min` · `Hourly` · `Daily`.
- **Soft deletes** — every query applies `WHERE deleted_at IS NULL` unless audit-mode.
- **Status values** — read straight from ENUMs in the DDL (`ptm_slots.status`, `ptm_slot_bookings.status`); display labels are pre-defined (no FK to status master).

## 2. Standard filter chips

| Filter | Source | Default |
|--------|--------|---------|
| Academic Session | `ptm_events.academic_session_id` (FK `sch_academic_sessions`) | current |
| Academic Term | `ptm_events.academic_term` | all |
| PTM Event | `ptm_events.id` | latest active |
| Class+Section | `ptm_event_class_section_jnt.class_section_id` (FK `sch_class_section_jnt`) | all the user can access |
| Scheduled Date | `ptm_event_class_section_jnt.scheduled_date` | event date range |
| Teacher | `ptm_slots.teacher_id` (FK `sys_users`) | self for teacher view |
| Meeting Mode | `IN_PERSON / ONLINE / HYBRID` | all |
| Allocation Mode | `SCHOOL_ALLOCATED / PARENT_PICK` | all |
| Booking Status | ENUM in `ptm_slot_bookings.status` | CONFIRMED |
| Slot Status | ENUM in `ptm_slots.status` | all |
| Include Inactive | toggle | OFF |

## 3. Standard column conventions

| Column | Source | Display |
|--------|--------|---------|
| Event | `ptm_events.code + ' — ' + title` | hyperlink |
| Class+Section | `sch_classes.name + '-' + sch_sections.name` (via `sch_class_section_jnt`) | "X-A" |
| Teacher | `sys_users.first_name + last_name` | hyperlink |
| Student | `std_students.first_name + last_name + admission_no` | hyperlink |
| Slot | `slot_start + '–' + slot_end` (`HH:mm`) | — |
| Date | DATE | `DD-MMM-YYYY` |
| Date-time | DATETIME | `DD-MMM-YYYY HH:mm` |
| Status | ENUM label | colored badge |
| Mode | ENUM | icon + label |

## 4. Report catalogue

| # | Section | Reports |
|---|---------|---------|
| A | Event Setup & Coverage | R-PTM-001 .. R-PTM-004 |
| B | Slot & Capacity Planning | R-PTM-010 .. R-PTM-013 |
| C | Booking Operations | R-PTM-020 .. R-PTM-024 |
| D | Teacher Day-View | R-PTM-030 .. R-PTM-032 |
| E | Parent / Student Facing | R-PTM-040 .. R-PTM-042 |
| F | Attendance & Outcome | R-PTM-050 .. R-PTM-052 |
| G | Cancellation & Compliance | R-PTM-060 .. R-PTM-061 |
| H | Executive Dashboard | R-PTM-070 .. R-PTM-071 |

**Total: 22 reports.**

---

# A. Event Setup & Coverage

## R-PTM-001 — PTM Event Master List

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Principal |
| Purpose | All PTM events configured per session/term with high-level setup. |
| Refresh | Live |

**Tables used** — `ptm_events`, `sch_academic_sessions`, `sch_academic_terms`, `sys_users` (created_by), `ptm_event_class_section_jnt` (count).

**Columns**

| # | Column | Source |
|---|--------|--------|
| 1 | Code | `ptm_events.code` |
| 2 | Title | `ptm_events.title` |
| 3 | Session | `sch_academic_sessions.name` |
| 4 | Term | `sch_academic_terms.name` |
| 5 | Start / End Dates | `event_start_date`, `event_end_date` |
| 6 | Default Mode | `default_meeting_mode` |
| 7 | Booking Window | `booking_window_start` → `booking_window_end` |
| 8 | Default Duration (min) | `default_slot_duration_min` |
| 9 | Default Buffer (min) | `default_buffer_min` |
| 10 | Default Max Participants | `default_max_participants` |
| 11 | Allow Reschedule | `allow_reschedule` |
| 12 | Cancellation Lead (hrs) | `cancellation_lead_time_hrs` |
| 13 | Notify on Book / Cancel | `notify_parent_on_book`, `_cancel` |
| 14 | Class+Sections Covered | `COUNT(ptm_event_class_section_jnt)` |
| 15 | Is Active | `is_active` |
| 16 | Created By | `sys_users.name` |

**Filters** — Session, Term, Is Active, Date range, Mode.
**Indexes used** — `idx_ptmEvents_academicSession`, `idx_ptmEvents_dates`.
**Drilldown** — row → R-PTM-002 for that event.
**Export** — PDF, Excel.

---

## R-PTM-002 — Event Coverage by Class+Section

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Principal |
| Purpose | For a chosen event, which class+sections are scheduled, on which date, in which room/mode, and whether an assignment exists. |
| Refresh | Live |

**Tables used** — `ptm_event_class_section_jnt`, `sch_class_section_jnt`, `sch_classes`, `sch_sections`, `sch_rooms`, `ptm_assignments` (LEFT JOIN to flag missing assignment).

**Columns** — Class+Section, Scheduled Date, Day Start/End, Mode, Room, Virtual Link, Notes, Assignment Created (Y/N), Primary Teacher (if assigned), Is Published, Published At, Is Active.

**Filters** — Event (required), Mode, Date range, Assignment-missing-only, Unpublished-only.
**Indexes used** — `uq_ptmEventCS_event_classSec`, `idx_ptmEventCS_date`.
**Compliance check** — highlight rows where `assignment.id IS NULL` (means setup incomplete).

---

## R-PTM-003 — Batch Templates Library

| Field | Value |
|-------|-------|
| Type | `LIST` + `DETAIL` |
| Audience | Teacher, Coordinator |
| Purpose | All reusable batch templates with the slot grid preview. |
| Refresh | Live |

**Tables used** — `ptm_batches_template`, `ptm_batch_slot_template`, `sys_users` (owner_teacher_id).

**List columns** — Code, Name, Owner Teacher, Window (start–end), Slot Duration, Buffer, Max Participants per Slot, Expected Total Slots, Active, Used-by-Assignment count (`COUNT(ptm_assignments WHERE batch_template_id=...)`).

**Detail panel (on row click)** — list of `ptm_batch_slot_template` rows: Ordinal, Start, End, Is Break, Break Label. Pre-rendered timeline strip.

**Filters** — Owner Teacher, Duration range, Has Breaks (Y/N), Active only.
**Indexes used** — `idx_ptmBatches_ownerTeacher`.

---

## R-PTM-004 — Teacher Blockout Calendar

| Field | Value |
|-------|-------|
| Type | `LIST` + Calendar |
| Audience | Teacher, Coordinator |
| Purpose | All teacher blockouts (lunch, meetings, unavailability) within events. |
| Refresh | Live |

**Tables used** — `ptm_blockouts`, `ptm_events`, `sys_users` (teacher_id).

**Columns** — Event, Teacher (or "ALL" when NULL), Blockout Date, Start, End, Duration (min), Reason, Created By.

**Filters** — Event, Teacher (multi), Date range, Reason contains, Applies-to-all-only (`teacher_id IS NULL`).
**Indexes used** — `idx_ptmBlockouts_event_teacher_date`.
**View toggle** — list / calendar (per teacher swimlane).

---

# B. Slot & Capacity Planning

## R-PTM-010 — Slot Inventory & Status

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Teacher |
| Purpose | All generated slots for an event with status, capacity, booked-count, room/mode. |
| Refresh | Live |

**Tables used** — `ptm_slots`, `ptm_assignments`, `ptm_event_class_section_jnt`, `sch_class_section_jnt`, `sys_users` (teacher_id), `sch_rooms`.

**Columns** — Event, Class+Section, Date, Slot Time (start–end), Teacher, Sub-Batch (from `ptm_assignment_teacher_jnt.sub_batch_label` if present), Room / Virtual Link, Capacity, Booked Count, Available Count (`capacity − booked_count`), Status (`AVAILABLE / BOOKED / FULL / BLOCKED / COMPLETED / CANCELLED`), Is Break.

**Filters** — Event, Class+Section, Teacher, Date, Status (multi), Has-availability-only (`booked_count < capacity AND status='AVAILABLE'/'BOOKED'`), Break-only.
**Indexes used** — `idx_ptmSlots_assignment`, `idx_ptmSlots_status`, `idx_ptmSlots_slotStart`, `uq_ptmSlots_teacher_start`.
**Sort** — default: date → slot_start → teacher.
**Export** — Excel.

---

## R-PTM-011 — Slot Utilization by Class+Section

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Coordinator, Principal |
| Purpose | How well each class+section's slots are filling up. Identifies under-booked classes. |
| Refresh | 5 min |

**Tables used** — `ptm_slots`, `ptm_assignments`, `ptm_event_class_section_jnt`, `sch_class_section_jnt`, `std_students` (roster size).

**Computation per (event, class+section)**

```
total_slots          = COUNT(ptm_slots WHERE assignment in event+CS AND is_break=0)
bookable_capacity    = SUM(capacity WHERE same scope)
total_bookings       = SUM(booked_count WHERE same scope)
utilization_pct      = total_bookings / bookable_capacity × 100
class_roster_size    = COUNT(std_students for class_section_id)
booking_coverage_pct = DISTINCT_student_count(confirmed bookings) / class_roster_size × 100
```

**Columns** — Class+Section, Scheduled Date, Teacher, Total Slots, Bookable Capacity, Booked, Available, Utilization %, Roster Size, Booking Coverage %, Mode.

**Filters** — Event, Date range, Utilization < threshold, Coverage < threshold.
**Chart** — bar of bottom-10 classes by utilization %.
**Drilldown** — class row → R-PTM-021 (parent booking list for that class).

---

## R-PTM-012 — Slot Generation Audit

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Admin |
| Purpose | Verify slot generation matches expectation — counts vs `batch_template.expected_total_slots`. Flags blocked slots due to blockouts. |
| Refresh | Live |

**Tables used** — `ptm_assignments`, `ptm_batches_template`, `ptm_batch_slot_template`, `ptm_slots`, `ptm_blockouts`.

**Computation per assignment**

```
template_slot_count   = COUNT(ptm_batch_slot_template WHERE batch_template_id AND is_break=0)
generated_slot_count  = COUNT(ptm_slots WHERE assignment_id AND is_break=0)
blocked_slot_count    = COUNT(ptm_slots WHERE assignment_id AND status='BLOCKED')
expected_total_slots  = ptm_batches_template.expected_total_slots
```

**Columns** — Event, Class+Section, Teacher, Batch Template Code, Template Slot Count, Generated Slot Count, Blocked Slot Count, Expected (from template), Variance, Is Published, Published At.

**Filters** — Event, Variance ≠ 0 only (compliance), Unpublished only.

---

## R-PTM-013 — Multi-Teacher Sub-Batch Allocation

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator |
| Purpose | Where a class+section is split into parallel sub-batches with different teachers/rooms (Req §3 — Multi-Teacher). |
| Refresh | Live |

**Tables used** — `ptm_assignment_teacher_jnt`, `ptm_assignments`, `sys_users`, `sch_rooms`, `ptm_event_class_section_jnt`, `sch_class_section_jnt`.

**Columns** — Event, Class+Section, Assignment ID, Primary Teacher, Sub-Batch Label, Sub-Batch Teacher, Room, Virtual Link, Student Filter (decoded from `student_filter_json` — e.g. "Roll 1-15"), Is Active.

**Filters** — Event, Class+Section, Teacher, Has Filter (`student_filter_json IS NOT NULL`).
**Indexes used** — `uq_ptmAsgnTeacher_asgn_teacher`.

---

# C. Booking Operations

## R-PTM-020 — All Bookings Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Principal |
| Purpose | Master booking list with status, slot details, parent comments. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings`, `ptm_slots`, `ptm_assignments`, `ptm_event_class_section_jnt`, `sch_class_section_jnt`, `std_students`, `sys_users` (teacher_id, booked_by_user_id), `ptm_events`.

**Columns** — Booking ID, Event, Class+Section, Student, Teacher, Slot Date+Time, Room/Mode, Status (`CONFIRMED / CANCELLED / NO_SHOW / COMPLETED / RESCHEDULED`), Booked By, Booked At, Cancelled At, Cancel Reason, Parent Comments, Attended (Y/N/—), Meeting Notes.

**Filters** — Event, Class+Section, Teacher, Student, Status (multi), Booked-at range, Slot-date range, Has Comments (`parent_comments IS NOT NULL`), Has Notes (`meeting_notes IS NOT NULL`).
**Indexes used** — `idx_ptmBooking_slot`, `idx_ptmBooking_student`, `idx_ptmBooking_status`.
**Sort** — slot_start ascending.
**Export** — PDF, Excel.

---

## R-PTM-021 — Class-wise Parent Booking List (printable)

| Field | Value |
|-------|-------|
| Type | `REGISTER` |
| Audience | Class Teacher, Coordinator |
| Purpose | Printable per-class roster showing each student's booked slot or "Not Booked". |
| Refresh | Live |

**Tables used** — `std_students` (full roster of class+section), `ptm_slot_bookings` (LEFT JOIN on event+student where status='CONFIRMED'), `ptm_slots`.

**Computation** — left-join roster to confirmed bookings; rows with no booking shown as "Not Booked" (highlight in red).

**Columns** — Sr.No, Roll No, Student Name, Booking Status, Booked Slot (date + time), Teacher (when slot allocation crosses teachers — e.g. sub-batch), Parent Comments.

**Filters** — Event, Class+Section (required), "Show only not-booked" toggle.
**Export** — PDF (class teacher hand-out), Excel.
**Summary footer** — Roster Size · Booked · Not Booked · Booking Coverage %.

---

## R-PTM-022 — Booking Funnel (counts by status)

| Field | Value |
|-------|-------|
| Type | `KPI` + `CHART` |
| Audience | Coordinator, Principal |
| Purpose | Quick numerical pulse of the booking funnel. |
| Refresh | 5 min |

**Tables used** — `ptm_slot_bookings`, `ptm_slots` (for "available capacity unfilled").

**KPI tiles** — Total Confirmed · Total Cancelled · Total No-Show · Total Completed · Total Rescheduled · Unfilled Capacity (remaining `capacity − booked_count` in available slots).

**Chart** — donut by status. Time-series line of confirmed bookings per day across the booking window.

**Filters** — Event (required), Class+Section (multi), Teacher (multi).

---

## R-PTM-023 — Unbooked Available Slots (live)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator (chasing parents); Parent Portal (auto-feeds parent UI) |
| Purpose | Slots still open for booking — drives parent reminders. |
| Refresh | Live |

**Tables used** — `ptm_slots` where `status IN ('AVAILABLE','BOOKED') AND booked_count < capacity AND is_break=0 AND is_active=1`.

**Columns** — Event, Class+Section, Teacher, Date, Slot Time, Capacity, Booked Count, Available Count, Room/Mode.

**Filters** — Event (required), Class+Section, Teacher, Mode, Date.
**Sort** — slot_start asc.
**Export** — CSV (for bulk SMS/email blast scripts).

---

## R-PTM-024 — Booking Activity Log (audit)

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Auditor |
| Purpose | All booking lifecycle events — created / cancelled / rescheduled, with timestamps and actor. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings` (all rows including cancelled, since cancellation is a status-change), `sys_users`, `std_students`.

**Computed columns** — Event, Student, Teacher, Original Slot, Booked At, Cancelled At, Booked By (user), Status, Cancel Reason, Lead Time at Cancellation (`slot_start − cancelled_at` in hours).

**Filters** — Event, Date range (booked_at or cancelled_at), Status (multi), Actor (booked_by_user_id), Cancellation within lead-time-window only (compliance flag — when `lead_time_hrs < event.cancellation_lead_time_hrs`).
**Indexes used** — `idx_ptmBooking_status`.

---

# D. Teacher Day-View

## R-PTM-030 — Teacher Daily Schedule (printable)

| Field | Value |
|-------|-------|
| Type | `REGISTER` |
| Audience | Teacher |
| Purpose | A teacher's PTM day printable — every slot in order with student name, comments, room. |
| Refresh | Live |

**Tables used** — `ptm_slots`, `ptm_slot_bookings`, `std_students`, `ptm_event_class_section_jnt`, `sch_class_section_jnt`, `sch_rooms`.

**Columns** — Sr.No, Slot Time, Class+Section, Student (or "Available"/"Blocked"/"Break"), Mode, Room/Link, Parent Comments, Booking Status, Notes-capture-field (blank for handwriting).

**Filters** — Teacher (required), Date (required), Event.
**Export** — PDF (teacher hand-out), Print-only stylesheet.
**Sort** — slot_start asc.
**Indexes used** — `uq_ptmSlots_teacher_start`.

---

## R-PTM-031 — Teacher Workload Across Events

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Principal |
| Purpose | How many slots each teacher has across events — workload balance. |
| Refresh | Daily |

**Tables used** — `ptm_slots`, `sys_users` (teacher_id).

**Computation per teacher** — Total Slots, Bookable Slots (`is_break=0`), Total Capacity (`SUM(capacity)`), Total Bookings (`SUM(booked_count)`), Total Hours (computed `SUM(slot_end − slot_start)` in hours).

**Filters** — Event (multi), Date range, Department.

**Sort** — Total Bookings desc (highlight overloaded teachers).

---

## R-PTM-032 — Teacher Conflict / Overlap Detector

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator |
| Purpose | Detects any teacher with overlapping slots — defensive check beyond the DB UNIQUE on `(teacher_id, slot_start)`. Looks for `slot_end` extending into next slot's start. |
| Refresh | Live |

**Tables used** — `ptm_slots` self-join on `teacher_id`.

**SQL skeleton**

```sql
SELECT s1.teacher_id, s1.id AS slot1, s2.id AS slot2,
       s1.slot_start AS s1_start, s1.slot_end AS s1_end,
       s2.slot_start AS s2_start, s2.slot_end AS s2_end
FROM ptm_slots s1
JOIN ptm_slots s2
  ON s1.teacher_id = s2.teacher_id
 AND s1.id < s2.id
 AND s1.slot_end  > s2.slot_start
 AND s1.slot_start < s2.slot_end
WHERE s1.deleted_at IS NULL AND s2.deleted_at IS NULL
  AND s1.status NOT IN ('CANCELLED','BLOCKED')
  AND s2.status NOT IN ('CANCELLED','BLOCKED');
```

**Columns** — Teacher, Slot 1 (id + time), Slot 2 (id + time), Overlap (min), Assignments involved.
**Action** — link to resolve (cancel one).

---

# E. Parent / Student Facing

## R-PTM-040 — Parent — My Child's Bookings

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Parent (parent portal) |
| Purpose | All confirmed/upcoming bookings for the parent's children across events. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings` (`status='CONFIRMED'`), `ptm_slots`, `ptm_events`, `std_students`, `sys_users` (teacher), `sch_rooms`, `ptm_event_class_section_jnt`.

**Columns** — Event, Child Name, Class+Section, Teacher, Slot Date+Time, Mode (Room or Join Link), Parent Comments, Cancel Allowed (`now + cancellation_lead_time_hrs ≤ slot_start AND event.is_active`), Reschedule Allowed (`event.allow_reschedule`).
**Actions** — Cancel · Reschedule (if allowed) · View Comments.

**Filters** — Active children (parent-scoped) · Event (multi) · Past / Upcoming toggle.

**Privacy** — strictly parent-of-student data; enforce via `std_student_guardian_jnt` policy.

---

## R-PTM-041 — Parent — Slot Picker (available slots)

| Field | Value |
|-------|-------|
| Type | `LIST` (grid) |
| Audience | Parent (parent portal) |
| Purpose | Show open slots for parent's child's class, allocation_mode = PARENT_PICK. |
| Refresh | Live |

**Tables used** — `ptm_slots` (status `AVAILABLE`/`BOOKED` AND `booked_count < capacity`), `ptm_assignments` (`allocation_mode='PARENT_PICK' AND is_published=1`), `ptm_event_class_section_jnt`, `ptm_events` (current booking window).

**Validations enforced server-side**
- `event.booking_window_start ≤ now ≤ event.booking_window_end`
- No existing CONFIRMED booking for `(event, student)` (via the unique key on `active_booking_key`)
- Slot not BLOCKED / FULL

**Columns** — Teacher, Slot Date+Time, Available Count (`capacity − booked_count`), Room/Mode, Action: "Book".

**Filters** — Event (required), Teacher (multi), Date.

---

## R-PTM-042 — Student — My PTM Schedule

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Student (student portal) |
| Purpose | Read-only view for student of own PTM bookings. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings` (own student_id, status='CONFIRMED'), `ptm_slots`, `ptm_events`, `sys_users`.

**Columns** — Event, Teacher, Date+Time, Room/Mode.

**Privacy** — student sees own data only.

---

# F. Attendance & Outcome

## R-PTM-050 — Attendance / No-Show Register

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Teacher, Coordinator |
| Purpose | Post-meeting attendance — mark `attended` and `meeting_notes` after the slot. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings` (status='CONFIRMED' AND slot in past), `ptm_slots`, `std_students`, `sys_users`.

**Columns** — Event, Class+Section, Teacher, Student, Slot Date+Time, Attended (Y/N/—), Status (auto-flip: CONFIRMED → COMPLETED on attended=Y or NO_SHOW on attended=N), Meeting Notes (edit inline).

**Filters** — Event, Date (default today), Teacher (self), Status (multi), "Pending attendance mark" only (`attended IS NULL AND slot_end < now`).

**Bulk actions** — Mark Attended / Mark No-Show on selected rows.

---

## R-PTM-051 — No-Show Analysis

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Coordinator, Principal, Class Teacher |
| Purpose | Identify students/parents who frequently no-show. |
| Refresh | Daily |

**Tables used** — `ptm_slot_bookings` (`status='NO_SHOW' OR attended=0`), `std_students`, `ptm_events`.

**Per-student aggregates** — Total Bookings, No-Shows, No-Show %, Last No-Show Date.

**Columns** — Student, Class+Section, Total Bookings, No-Shows, No-Show %, Last No-Show Date.

**Filters** — Event scope (multi or "All-time"), No-show % > threshold (e.g. ≥ 50%), Class+Section.

**Chart** — top-20 students by no-show count.

---

## R-PTM-052 — Meeting Notes Digest

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Class Teacher, Counsellor, Principal |
| Purpose | Search/filter teacher notes captured post-meeting. |
| Refresh | Live |

**Tables used** — `ptm_slot_bookings` (`meeting_notes IS NOT NULL`), `std_students`, `sys_users`.

**Columns** — Event, Class+Section, Student, Teacher, Slot Date, Notes (truncated with "show more"), Attended (Y/N).

**Filters** — Event, Class+Section, Teacher, Student, Keyword in notes (LIKE), Date range.

**Privacy** — restricted by role (class teacher sees own class; principal sees all).

---

# G. Cancellation & Compliance

## R-PTM-060 — Cancellation Analysis

| Field | Value |
|-------|-------|
| Type | `LIST` + `CHART` |
| Audience | Coordinator, Principal |
| Purpose | Cancellation volume, lead time, reasons. Flags late cancellations (within event's `cancellation_lead_time_hrs`). |
| Refresh | Daily |

**Tables used** — `ptm_slot_bookings` (`status='CANCELLED'`), `ptm_slots`, `ptm_events`.

**Computed columns per booking** — Lead Time at Cancellation (hrs) `slot_start − cancelled_at`, Within Policy (Y/N — compare to `event.cancellation_lead_time_hrs`).

**Columns** — Event, Class+Section, Teacher, Student, Booked At, Cancelled At, Slot Date+Time, Lead Time (hrs), Within Policy (Y/N), Cancel Reason.

**Filters** — Event, Within-policy filter (Y/N/All), Reason text contains, Lead < N hours.

**Chart** — distribution of cancellations by lead-time buckets; trend line of cancellations per day.

---

## R-PTM-061 — Setup Compliance Audit

| Field | Value |
|-------|-------|
| Type | `LIST` |
| Audience | Coordinator, Auditor |
| Purpose | Flags incomplete setup that would block parents from booking. |
| Refresh | Live |

**Checks performed (one row per failed check)**

| Check | Source |
|-------|--------|
| Event scheduled but no class+sections | `ptm_events` LEFT JOIN `ptm_event_class_section_jnt` |
| Class+section scheduled but no assignment | `ptm_event_class_section_jnt` LEFT JOIN `ptm_assignments` |
| Assignment exists but unpublished + event already open | `ptm_assignments.is_published=0 AND now BETWEEN booking_window_start/end` |
| Published assignment with 0 slots generated | `ptm_assignments.is_published=1` AND `COUNT(ptm_slots)=0` |
| ONLINE/HYBRID event_class_section without virtual_link | `meeting_mode IN ('ONLINE','HYBRID') AND virtual_link IS NULL` |
| IN_PERSON event_class_section without room_id | `meeting_mode='IN_PERSON' AND room_id IS NULL` |
| Booking window already started but slots not yet visible | derived |

**Columns** — Check Name, Event, Class+Section (if applicable), Severity (warning/error), Action link (deep-link to fix screen).

**Filters** — Event, Severity.
**Audience** — Coordinator dashboard widget; nightly email to Coordinator.

---

# H. Executive Dashboard

## R-PTM-070 — PTM Event Live Dashboard

| Field | Value |
|-------|-------|
| Type | `KPI` + multi-panel |
| Audience | Coordinator, Principal |
| Purpose | One-page live status of a PTM event. |
| Refresh | 5 min |

**KPI tiles** — Total Slots · Bookable Slots · Booked · Available · Cancelled · No-Show · Completed · Booking Coverage % · Top under-booked class · Top no-show class · Slots happening today.

**Panels**
1. Donut — slot status distribution.
2. Bar — bookings per day across the booking window.
3. Heatmap — booking density by class+section × date.
4. List — overdue setup tasks (from R-PTM-061).

**Filters** — Event (single, required).

---

## R-PTM-071 — Post-Event Outcome Report (PDF)

| Field | Value |
|-------|-------|
| Type | `REGISTER` (multi-page PDF) |
| Audience | Principal, Management |
| Purpose | After-action summary deliverable. |
| Refresh | Manual (post-event) |

**Sections**
- Cover (event code, title, dates).
- Executive summary KPIs.
- Class+section participation (from R-PTM-002 + R-PTM-011).
- Teacher participation (from R-PTM-031).
- Booking funnel (confirmed/cancelled/no-show/completed counts).
- No-show analysis (from R-PTM-051).
- Cancellation analysis (from R-PTM-060).
- Notable parent comments / teacher notes (top 10 longest non-empty entries).
- Compliance summary (R-PTM-061 — anything that failed).

**Filters** — Event (required).
**Export** — PDF only (DomPDF).

---

# 5. Cross-cutting concerns

## 5.1 RBAC

| Role | Allowed reports |
|------|-----------------|
| Parent | R-PTM-040, R-PTM-041 (own children only — `std_student_guardian_jnt` policy) |
| Student | R-PTM-042 (own only) |
| Teacher | R-PTM-003 (own templates), R-PTM-004 (own blockouts), R-PTM-010/030 (own slots), R-PTM-050 (own slot post-meeting), R-PTM-052 (own notes) |
| Class Teacher | + R-PTM-021 for own class, R-PTM-051 / R-PTM-052 for own class |
| Coordinator | All operational reports |
| Principal | All reports |
| Admin | All + R-PTM-024 audit, R-PTM-061 compliance |

> **Gate:** `ptm.assignment.manage` permission grants slot/booking modification authority per DDL Req §3. Other readers are read-only.

## 5.2 Performance / index map

| Report | Critical index |
|--------|----------------|
| R-PTM-001 | `idx_ptmEvents_academicSession`, `idx_ptmEvents_dates` |
| R-PTM-002 | `uq_ptmEventCS_event_classSec`, `idx_ptmEventCS_date` |
| R-PTM-003 | `idx_ptmBatches_ownerTeacher` |
| R-PTM-004 | `idx_ptmBlockouts_event_teacher_date` |
| R-PTM-010 / 020 / 030 | `idx_ptmSlots_status`, `idx_ptmSlots_slotStart`, `uq_ptmSlots_teacher_start` |
| R-PTM-020 / 024 | `idx_ptmBooking_status`, `idx_ptmBooking_slot`, `idx_ptmBooking_student` |
| R-PTM-032 | self-join on teacher_id; consider covering index `(teacher_id, slot_start, slot_end)` if volume grows |

## 5.3 Export & branding

- PDF — DomPDF (D9) with school header (`prm_tenant.logo`), event banner, run-by, run-at, applied filters in footer.
- Excel — Maatwebsite; freeze header row; auto-width.
- CSV — raw rows.

## 5.4 Common pitfalls (developer checklist)

1. **Soft delete** — apply `deleted_at IS NULL` everywhere except R-PTM-024 audit.
2. **Status filtering for "active" bookings** — always use `status = 'CONFIRMED'` for counts; do NOT join on `is_active` alone (cancelled rows keep `is_active = 1`).
3. **Unique active-booking key** — `active_booking_key` is a virtual generated column populated only when `status='CONFIRMED'` — useful for "does this student have any confirmed booking in this event?" lookup.
4. **Cross-class teacher conflict** — DB enforces `(teacher_id, slot_start)` uniqueness, but app must additionally guard `slot_end` overlap if durations vary across batches (see R-PTM-032).
5. **Booking window enforcement** — parent-facing slot picker (R-PTM-041) must server-side validate the booking window; never trust the client.
6. **Cancellation lead time** — apply at server side; compare `slot_start − now() ≥ event.cancellation_lead_time_hrs`.
7. **Multi-teacher sub-batch routing** — when `ptm_assignment_teacher_jnt` exists, slots have `assignment_teacher_id` populated and may use a different `room_id` / `virtual_link` than the parent assignment.
8. **PARENT_PICK vs SCHOOL_ALLOCATED** — slot-picker UI (R-PTM-041) only valid for `allocation_mode='PARENT_PICK'`. For `SCHOOL_ALLOCATED`, admin / scheduler creates bookings programmatically.
9. **Roster vs bookings** — for R-PTM-021 use LEFT JOIN from `std_students` so "not booked" students are visible.
10. **Audit read** — R-PTM-024 / R-PTM-061 should not themselves trigger audit-write rows (otherwise loops).

## 5.5 Common UI components

| Component | Reports |
|-----------|---------|
| Event picker (current/active) | All |
| Class+Section cascading select | Most |
| Status badge component (slot + booking ENUM labels) | R-PTM-010, R-PTM-020, R-PTM-030, R-PTM-050 |
| Teacher auto-complete | Many |
| Student auto-complete | R-PTM-020, R-PTM-051 |
| Calendar / swimlane view | R-PTM-004, R-PTM-030 |
| Bulk-action toolbar | R-PTM-050 |
| Print-friendly stylesheet | R-PTM-021, R-PTM-030, R-PTM-071 |

---

# 6. Implementation hand-off

Per report, the developer task should produce:

1. Route under `Modules/PTM/Http/Controllers/Reports/`.
2. Form Request class for the filter set.
3. Service class `Modules\PTM\Services\Reports\{ReportId}Service.php`.
4. Resource for JSON shape (mobile + web).
5. Blade view `Modules/PTM/Resources/views/reports/{report_id}.blade.php`.
6. PDF view (if applicable) under `reports/pdf/`.
7. Excel export class in `Modules/PTM/Exports/`.
8. Feature test covering: happy path, RBAC denial, filter combinations, export formats, soft-delete suppression, booking-window enforcement (for parent-facing).
9. Add route to `routes/api.php` (mobile) and `routes/tenant.php` (web) with appropriate middleware (`auth`, role-gate, `ptm.assignment.manage` where relevant, parent-of-student policy for parent reports).

# 7. Open items / Deferred to v2

1. Notification dispatch audit (`notify_parent_on_book` / `_cancel`) — currently no dedicated log table in PTM DDL; will need a generic notification log or piggyback on a global notification module. Out of scope of this report design.
2. Group-slot detail (`max_participants_per_slot > 1`) — current reports list `booked_count / capacity` but do not yet drill down to all participants in a single group slot. Add R-PTM-025 in v2.
3. Re-scheduling chain (RESCHEDULED status) — link `old booking → new booking` if a `parent_remark` or DDL link is added in v4.
4. Cross-event historical aggregates per student (multi-term) — would need a precomputed summary table; defer.
5. Real-time WebSocket on dashboard — v1 polls every 5 min.
6. Custom-report builder — not v1.

---

> **End of PTM_Report_Design_v1.md** — 22 reports covering setup, slot planning, booking ops, teacher day-view, parent/student portal, attendance & outcome, cancellation/compliance, executive dashboard.
