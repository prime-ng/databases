# Fee Demands — Business Requirements

## What This Screen Does

The Fee Demands screen provides a local audit of all fee charges originating from the Hostel module. Every fee-related action (room rent, mess bill, damage charge, laundry charge, etc.) generates a fee demand record here. These demands are then pushed to the main finance/fee module for consolidated collection and reconciliation.

---

## When This Screen Is Used

- Viewing all hostel-related charges for a student
- Monthly: Reviewing generated fee demands before pushing to finance
- Pushing fee demands to the main fee module
- Reconciling which demands have been paid
- Manual adjustments: Adding or crediting hostel fee charges

---

## Key Fields

- **Student** — Charged student
- **Demand Type** — Room Rent / Mess Bill / Electricity / Damage / Laundry / Penalty / Security Deposit / Other
- **Amount** — Charge amount
- **Period** — Month/Year or date range
- **Source Table** — Which table generated this (hst_fee_structures, hst_mess_bills, etc.)
- **Source ID** — Reference to the source record
- **Pushed to Fee Module** — Whether demand has been sent
- **Pushed Date** — When pushed
- **External Fee Reference** — ID in the main fee module (for reconciliation)
- **Status** — Pending / Pushed / Partially Paid / Paid / Waived / Cancelled

---

## Business Rules

- Every financial charge from the Hostel module creates a fee demand record
- Demands are pushed to the main fee module in bulk (weekly/monthly)
- Once pushed, corrections require a reversal (credit note) in the fee module
- Waived demands require admin approval and reason documentation
- Paid status is synced from the main fee module (not editable in hostel)
- Audit trail: Every demand links back to its source (mess bill, damage charge, etc.)

---

## Related Screens

- **Fee Structures** (Tab 38) — Room rent demands generated from fee structures
- **Mess Bills** (Tab 37) — Mess bill demands
- **Room Inventory** (Tab 20) — Damage charges from inventory
- **Laundry Tickets** (Tab 23) — Laundry charges
