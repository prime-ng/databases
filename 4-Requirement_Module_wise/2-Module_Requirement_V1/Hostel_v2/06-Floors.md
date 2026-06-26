# Floors — Business Requirements

## What This Screen Does

The Floors screen manages floor/block definitions within each hostel building. Each hostel can have multiple floors, and each floor can have a block code (e.g., East Wing, West Wing) and a floor in-charge. Floors are the second level in the hostel hierarchy.

---

## When This Screen Is Used

- During hostel setup to define all floors in a building
- When a new wing or block is added to an existing hostel
- To assign or change the floor in-charge
- To deactivate a floor for renovation

---

## Key Fields

- **Hostel** — Which hostel the floor belongs to (dropdown)
- **Floor Number** — Numeric floor level (0 = Ground, 1, 2, 3, ...)
- **Block / Wing Code** — Optional wing identifier (e.g., "A", "B", "East", "West")
- **Floor In-Charge** — Staff member responsible for this floor
- **Description** — Any additional notes
- **Status** — Active / Inactive

---

## Business Rules

- Floor number + block code combination must be unique within a hostel
- A floor cannot be deleted if it has rooms, beds, or active allotments
- Block code is optional — if the hostel has no wings, leave blank
- Floor in-charge can be assigned from employee records

---

## Related Screens

- **Hostels** (Tab 05) — Parent entity
- **Rooms** (Tab 07) — Rooms belong to a floor
- **Warden Assignments** (Tab 10) — Floor-level warden assignments overrides hostel-level
