# Hostel Attendance — Business Requirements

## What This Screen Does

The Hostel Attendance screen manages daily roll-call for hostel residents. Wardens create attendance sessions per hostel/date/shift (Morning, Evening, Night) and mark each student as Present, Absent, Leave, or Late. Attendance is locked at the end of each shift to prevent retroactive changes.

---

## When This Screen Is Used

- Morning roll-call after wake-up time
- Evening roll-call before study hours
- Night roll-call before lights out
- To review past attendance records
- To generate attendance reports for disciplinary or parent communication

---

## Key Fields

**Session Header**
- **Hostel** — Which hostel
- **Date** — Attendance date
- **Shift** — Morning / Evening / Night
- **Locked** — Whether entries can still be edited
- **Total / Present / Absent / Leave / Late** — Auto-calculated counts

**Attendance Entries**
- **Student** — Each hostel resident
- **Status** — Present / Absent / Leave / Late
- **Check-In Time** — When the student was marked
- **Late Remarks** — Reason if marked late

---

## Business Rules

- Only students with active allotments appear in attendance
- Each student can have one entry per shift per day
- Once locked, attendance cannot be edited (only admin override)
- Bulk marking available (Mark All Present, then edit individuals)
- Late entry requires remarks
- Absent students can be flagged for parent notification
- Attendance data feeds into monthly reports and mess billing
- Wardens see only their assigned hostel's attendance; admins see all

---

## Workflow Steps

**Creating a Session**
Warden selects hostel, date, shift. System pre-populates all active residents. Warden marks attendance and locks the session.

**Editing a Session**
Before lock: Warden can edit individual entries. After lock: Only admin can unlock to edit.

**Viewing Reports**
Filter by hostel, date range, shift, student. Exportable for parent communication.

---

## Related Screens

- **Room Allotments** (Tab 11) — Only allotted students appear in attendance
- **Leave Passes** (Tab 16) — Students on approved leave auto-marked as Leave
- **Mess Attendance** (Tab 34) — Hostel attendance can feed into mess headcount
