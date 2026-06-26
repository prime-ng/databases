# Seat Capacity — Business Requirements

## What This Screen Does

The Seat Capacity screen allows the admin to define how many seats are available for each class within an admission cycle. This is the numerical foundation for allotments — the system ensures that allotments do not exceed the defined capacity.

Each seat capacity entry specifies a class, the total number of seats, and which cycle it applies to. The quota configuration percentages are then applied against these totals to determine per-quota seat availability.

---

## When This Screen Is Used

- After creating a cycle and quotas: Admin allocates seats per class
- Capacity expansion: School adds a new section to a class, increasing seat count
- Mid-cycle adjustments: Admin increases capacity for a high-demand class

---

## Key Fields at a Glance

**Class**
The class for which seats are being allocated (e.g., Class I, Class II, Class IX).

**Total Seats**
The total number of seats available for this class in this cycle.

**Filled Seats**
A read-only count of how many seats have already been allotted. Automatically updated as allotments are made.

**Available Seats**
Calculated as total minus filled. This number decreases as allotments are processed.

**Cycle**
The admission cycle this capacity belongs to.

---

## Business Rules and Conditions

**Cycle-Scoped**
Each seat capacity belongs to a specific admission cycle. Different cycles can have different capacities.

**Cannot Exceed Total**
The allotment engine refuses to create an allotment if the class's filled seats would exceed total seats.

**Quota Distribution**
Total seats × quota percentage = seats available for that quota type. Allotments respect these derived limits.

**Soft Delete**
Seat capacity records can be soft-deleted. Deleting a capacity record does not affect existing allotments.

---

## Workflow Steps

**Adding Seat Capacity**
Admin selects the class, enters the total seats, selects the cycle, and submits.

**Editing Capacity**
Admin clicks the Edit icon on any row. The total seats field can be increased (but not decreased below current filled count).

**Viewing Fill Status**
Each row shows a progress bar with filled vs total seats, color-coded: green (< 60%), yellow (60-89%), red (90%+).

**Deleting Capacity**
Admin clicks Delete to soft-delete a capacity record.

---

## Example Scenario

For the 2027-28 cycle, the admin sets:
- Class I: 120 seats (4 sections × 30)
- Class II: 60 seats (2 sections × 30)
- Class IX: 180 seats (6 sections × 30)
- Class X: 60 seats (2 sections × 30)

With a 25% RTE quota, Class I effectively has 30 RTE seats and 90 General + Other seats.

---

## Related Screens

- **Admission Cycles** — Capacity is scoped to a cycle
- **Quota Config** — Quota percentages are applied against total seats
- **Allotments** — Allotments check remaining capacity before assigning
- **Dashboard** — Seat fill progression chart is displayed on the dashboard
