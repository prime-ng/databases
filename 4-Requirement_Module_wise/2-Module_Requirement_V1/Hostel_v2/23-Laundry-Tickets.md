# Laundry Tickets — Business Requirements

## What This Screen Does

The Laundry Tickets screen manages the entire laundry process for hostel students. Students submit laundry (clothes, linens) with a ticket, the laundry processes it, and students collect it. The system tracks submission, weight-based charges, disputes, and fee linkage.

---

## When This Screen Is Used

- Student drops off laundry for washing
- Laundry staff processes and returns cleaned items
- Student collects laundry and verifies items
- Dispute resolution for lost or damaged items
- Monthly laundry charge computation

---

## Key Fields

- **Student** — Who submitted the laundry
- **Ticket Number** — Unique ticket identifier
- **Submission Date** — When submitted
- **Item Count** — Number of items submitted
- **Description** — List of items (e.g., "5 shirts, 3 pants, 2 bedsheets")
- **Weight** — Total weight (if charging by weight)
- **Charge** — Calculated laundry charge
- **Dispute Notes** — If student disputes charge or missing items
- **Charge Pushed to Fee** — Whether charge has been added to fee account
- **Collected Date** — When student collected
- **Status** — Submitted / In Wash / Ready / Collected / Disputed

---

## Business Rules

- Each submission gets a unique ticket number (auto-generated)
- Items are counted and optionally weighed at submission
- Charges are calculated based on configured rate (per item or per kg)
- If not collected within 7 days of "Ready" status, reminder is sent
- Disputes are flagged for warden review
- Charges can be pushed to student's fee account for consolidated billing
- Collection requires student verification (ID or ticket)

---

## Workflow Steps

**Submitting Laundry**
Student gives laundry to counter. Staff counts items, records weight, generates ticket. Status: Submitted.

**Processing**
Laundry washes items. Staff marks as "In Wash", then "Ready" when done.

**Collecting**
Student presents ticket, collects items. Staff marks as "Collected". If items are missing or damaged, dispute is logged.

**Dispute Resolution**
Warden reviews dispute, determines resolution (waive charge, partial credit, etc.), updates status.

---

## Related Screens

- **Fee Demands** (Tab 39) — Charges pushed to fee account
- **Housekeeping** (Tab 22) — Linen change schedule
