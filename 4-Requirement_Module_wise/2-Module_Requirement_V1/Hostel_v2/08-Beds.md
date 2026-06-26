# Beds — Business Requirements

## What This Screen Does

The Beds screen manages individual beds within each room. Each bed has a label (e.g., "Lower", "Upper"), bed type, and current status. Beds are the lowest level in the hostel hierarchy and are directly linked to student allotments.

---

## When This Screen Is Used

- During room setup to define all beds in a room
- When furniture is rearranged or replaced
- To mark a bed for maintenance (temporarily unavailable)
- To toggle bed status (available → occupied auto-updates on allotment)

---

## Key Fields

- **Room** — Which room the bed is in (auto-filled/read-only)
- **Bed Label** — Identifier within the room (e.g., "Bed 1", "Lower", "Upper", "Window Side")
- **Bed Type** — Dropdown from Bed Types (Tab 03)
- **Current Student** — Auto-filled from active allotment (read-only)
- **Condition** — Good / Fair / Poor
- **Notes** — Any bed-specific notes
- **Status** — Free / Occupied / Under Maintenance (from Status Masters)

---

## Business Rules

- Bed label must be unique within a room
- When a student is allotted to a bed, status auto-changes to "Occupied"
- When an allotment ends, status auto-changes back to "Free"
- A bed cannot be deleted if it has any active or past allotments
- Maintenance status can be toggled manually — blocks new allotments
- Bed type change allowed only when bed is unoccupied

---

## Related Screens

- **Rooms** (Tab 07) — Parent entity
- **Bed Types** (Tab 03) — Bed type classification
- **Room Allotments** (Tab 11) — Students are allotted to specific beds
- **Bed Maintenance** (Tab 21) — Maintenance tickets linked to beds
