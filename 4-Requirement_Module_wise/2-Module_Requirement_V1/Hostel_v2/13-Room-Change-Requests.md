# Room Change Requests — Business Requirements

## What This Screen Does

The Room Change Requests screen manages the workflow when a student wants to change their room or bed. Students initiate a request with a reason, wardens review and approve or reject it. On approval, the system automatically transfers the student to the new accommodation.

---

## When This Screen Is Used

- Student requests a room change due to conflict, health reasons, or preference
- Warden initiates a room change for disciplinary or administrative reasons
- To review pending room change requests
- To view room change history for a student or room

---

## Key Fields

- **Student** — Student requesting the change
- **Current Hostel / Floor / Room / Bed** — Auto-populated from active allotment
- **Requested Hostel / Floor / Room / Bed** — New accommodation requested
- **Reason** — Why the change is requested
- **Request Date** — When the request was made
- **Approved By** — Warden who approved/rejected
- **Approval Date** — When decision was made
- **Status** — Pending / Approved / Rejected / Cancelled

---

## Business Rules

- Student must have an active allotment to request a change
- Only one pending room change request per student at a time
- Requested bed must be free at the time of approval
- On approval: current allotment ends, new allotment created, bed statuses updated
- On rejection: warden must provide a reason
- Notification sent to student on approval or rejection
- Room change history is maintained for audit

---

## Related Screens

- **Room Allotments** (Tab 11) — Allotment updates on approval
- **Beds** (Tab 08) — Bed status changes on transfer
