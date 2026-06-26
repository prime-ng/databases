# Room Inventory — Business Requirements

## What This Screen Does

The Room Inventory screen tracks all items and assets present in each hostel room. This includes furniture (beds, tables, chairs, cupboards), electronics (fans, lights, ACs, geysers), and other items (curtains, dustbins, etc.). Each item's condition is tracked, damaged items can be flagged for repair or charge to student.

---

## When This Screen Is Used

- At the start of the academic year when rooms are inventoried
- When a student moves in/out and items are verified
- When an item is damaged and needs repair or replacement
- At the end of the academic year for handover/takeover
- When a student is charged for damage

---

## Key Fields

- **Room** — Which room the item belongs to
- **Item Name** — Description (e.g., "Wooden Bed", "Ceiling Fan")
- **Quantity** — Number of items
- **Condition** — Good / Fair / Poor / Damaged
- **Damage Description** — If damaged, what's wrong
- **Estimated Repair Cost** — Cost to repair
- **Repair Status** — Not Required / Pending / In Progress / Completed
- **Responsible Student** — Student assigned to this item (for accountability)
- **Charge to Fee** — Whether repair cost should be charged to student's fee account
- **Photo Evidence** — Photos of item condition
- **Status** — Active / Removed / Replaced

---

## Business Rules

- Room inventory is verified at check-in and check-out of each student
- Damage found at check-in is attributed to previous occupant
- Damage found at check-out can be charged to the vacating student
- Items marked for "Charge to Fee" create a fee demand entry
- Photo evidence is mandatory for damaged items
- Inventory report printable for student handover/takeover

---

## Workflow Steps

**Adding Inventory**
Warden selects room, adds item name, quantity, condition. For damaged items, adds description, photo, and estimated repair cost.

**Verifying at Check-Out**
When a student vacates, warden verifies inventory. Any new damage is recorded and can be charged.

**Tracking Repairs**
Damaged items show in the repair queue. Warden updates repair status as work progresses.

---

## Related Screens

- **Rooms** (Tab 07) — Room is the parent entity
- **Bed Maintenance** (Tab 21) — Maintenance tickets for room items
- **Fee Demands** (Tab 39) — Damage charges create fee demands
