# Pending Returns — Business Requirements

## What This Screen Does

The Pending Returns screen is a focused subset of the Movement Log that shows only students who are currently marked as "Out" and have not yet returned. This is the primary screen wardens use at the end of each shift to ensure all students are accounted for and safe.

---

## When This Screen Is Used

- End of day: Warden checks who hasn't returned
- Night roll-call: Verifying all students are in
- After an incident: Quick check of who is still out
- Following up on overdue returns

---

## Key Fields

- **Student** — Name and class
- **Out Time** — When they left
- **Expected Return Time** — When they were expected
- **Destination** — Where they went
- **Purpose** — Why they left
- **Overdue Duration** — How late they are (auto-calculated)
- **Notifications Sent** — Whether parent/warden has been notified
- **Actions** — Record Return / Send Notification / Create Incident

---

## Business Rules

- Shows only students with status "Out" or "Overdue"
- Sorted by overdue duration (most overdue first)
- Warden can record return directly from this screen
- Overdue > 1 hour: Auto-notification to warden
- Overdue > 2 hours: Suggestion to contact parent
- Overdue > 4 hours: Option to create incident report
- Returning a student via this screen updates both Movement Log and this view

---

## Workflow Steps

**Reviewing Pending Returns**
Warden opens screen, sees list of all students currently out, sorted by urgency.

**Recording Return**
Warden clicks "Record Return" next to student, enters actual in-time (defaults to current time), adds remarks if late. Student is moved out of pending list.

**Taking Action on Overdue**
For overdue students, warden can send notification, contact parent, or escalate to create an incident.

---

## Related Screens

- **Movement Log** (Tab 17) — Parent data source
- **Incidents** (Tab 27) — Repeated overdue can create incidents
