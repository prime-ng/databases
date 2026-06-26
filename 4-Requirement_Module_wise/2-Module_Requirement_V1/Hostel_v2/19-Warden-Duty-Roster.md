# Warden Duty Roster — Business Requirements

## What This Screen Does

The Warden Duty Roster screen manages daily shift scheduling for wardens. Each day, wardens are assigned to shifts (Morning, Afternoon, Evening, Night, Full Day, On Call) to ensure 24x7 coverage of the hostel. The roster handles shift swaps, emergency replacements, and leave coverage.

---

## When This Screen Is Used

- At the start of each week/month to schedule warden shifts
- When a warden calls in sick and needs replacement
- When wardens want to swap shifts
- To verify who is on duty at any given time
- For attendance and payroll reference

---

## Key Fields

- **Date** — Roster date
- **Warden** — Which warden (from Warden Assignments)
- **Shift** — Morning / Afternoon / Evening / Night / Full Day / On Call
- **Hostel** — Which hostel
- **Is Replacement** — Whether this is covering for another warden
- **Replaced Warden** — Original warden being covered
- **Notes** — Any shift notes
- **Status** — Scheduled / On Duty / Completed / Absent

---

## Business Rules

- Each shift must have at least one warden assigned per hostel
- A warden cannot be assigned to two shifts at the same time
- Shift swaps require both wardens' confirmation
- Emergency replacements can be made by admin override
- Roster is visible to all wardens so they know their schedule
- Historical roster is maintained for audit and payroll

---

## Related Screens

- **Warden Assignments** (Tab 10) — Available wardens populate the roster
- **Hostel Attendance** (Tab 14) — Warden on duty is responsible for attendance
