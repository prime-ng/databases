# Room Allotments — Business Requirements

## What This Screen Does

The Room Allotments screen is the core occupancy management screen. It links a student to a specific bed in a room for an academic session. This is where students are assigned to their accommodation, transferred between rooms, and vacated at the end of their stay.

---

## When This Screen Is Used

- At the start of the academic year when students arrive
- When a new student is admitted mid-year
- When a student requests a room transfer
- When a student vacates (end of year, graduation, withdrawal)
- For emergency placements during special circumstances

---

## Key Fields

- **Student** — Selected from student records
- **Hostel** — Auto-filled from bed selection
- **Floor** — Auto-filled from bed selection
- **Room** — Auto-filled from bed selection
- **Bed** — Specific bed being allotted
- **Academic Session** — Current session
- **Allotment Date** — When the student moved in
- **Vacating Date** — When the student moved out (nullable)
- **Meal Plan** — Vegetarian / Non-Vegetarian / Mess Only / No Mess
- **Is Emergency Placement** — Flag for urgent/special allotments
- **Transfer History** — Linked to Room Change Requests
- **Status** — Active / Vacated / Transferred (from Status Masters)

---

## Business Rules

- A student can have only one active allotment at a time
- A bed can have only one active allotment at a time
- Allotment auto-creates an audit log entry
- Vacating a student also updates bed status to "Free"
- Transfer creates a new allotment and ends the old one
- Bulk vacate available for end-of-session clearing
- Students cannot be allotted to beds in a hostel of opposite gender type

---

## Workflow Steps

**Allotting a Student**
Warden selects student, hostel → floor → room → bed in cascade dropdown, sets allotment date and meal plan, submits. Bed status updates to "Occupied" automatically.

**Transferring a Student**
Warden initiates transfer, selects new room/bed, enters reason. Old allotment ends, new allotment created, Room Change Request optionally linked.

**Vacating a Student**
Warden selects active allotment, enters vacating date and reason. Bed status updates to "Free", student marked as vacated.

**Bulk Vacate**
Warden selects hostel/floor/room, marks multiple students for vacating with a common date and reason, submits once.

---

## Related Screens

- **Beds** (Tab 08) — Bed status updates on allotment/vacation
- **Room Reservations** (Tab 12) — Reservations convert to allotments
- **Room Change Requests** (Tab 13) — Transfers linked to change requests
- **Hostel Attendance** (Tab 14) — Allotted students appear in attendance
