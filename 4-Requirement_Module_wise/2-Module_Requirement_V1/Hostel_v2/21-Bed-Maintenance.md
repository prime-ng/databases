# Bed Maintenance — Business Requirements

## What This Screen Does

The Bed Maintenance screen manages the complete lifecycle of maintenance tickets for beds and room items. From reporting an issue, assigning it to maintenance staff, tracking repair progress, recording costs, and verifying completion — all with before/after photo evidence.

---

## When This Screen Is Used

- A student reports a broken bed, leaking pipe, or faulty fan
- Warden inspects rooms and finds items needing repair
- Maintenance staff updates progress on assigned tickets
- Warden verifies completed repairs
- End-of-session: Bulk maintenance check

---

## Key Fields

- **Bed / Room** — Which bed/room needs maintenance
- **Issue Type** — Plumbing / Electrical / Furniture / Structural / Other
- **Description** — Detailed description of the problem
- **Severity** — Low / Medium / High / Critical
- **Reported By** — Student or warden who reported
- **Reported Date** — When it was reported
- **Assigned To** — Maintenance staff assigned
- **Assigned Date** — When assigned
- **Estimated Cost** — Estimated repair cost
- **Actual Cost** — Final cost after repair
- **Resolution Action** — What was done to fix it
- **Completed Date** — When work was completed
- **Before Photo** — Photo of the issue
- **After Photo** — Photo of the completed repair
- **Status** — Reported / In Progress / Completed / Closed (from Status Masters)

---

## Business Rules

- Critical severity issues must be acknowledged within 1 hour
- Before and after photos are required for all repairs
- Actual cost should not exceed estimated cost by more than 20% without approval
- Completed tickets are verified by warden before closing
- Repeated issues for the same item may indicate replacement needed
- Maintenance history per bed is available for reference

---

## Workflow Steps

**Reporting**
Student or warden reports issue with description, severity, and before photo.

**Assigning**
Warden assigns to maintenance staff, sets estimated cost if known.

**Repairing**
Maintenance staff updates progress, records actual cost, adds after photo.

**Verifying**
Warden inspects completed work, verifies photos, closes the ticket.

---

## Related Screens

- **Beds** (Tab 08) — Maintenance linked to specific beds
- **Room Inventory** (Tab 20) — Related inventory items
- **Audit Log** (Tab 25) — All status changes logged
