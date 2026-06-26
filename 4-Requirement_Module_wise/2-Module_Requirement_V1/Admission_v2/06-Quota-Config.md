# Quota Config — Business Requirements

## What This Screen Does

The Quota Config screen allows the admin to define seat reservation categories (quotas) for each admission cycle. These quotas determine how seats are distributed among different applicant groups — such as General, RTE (Right to Education), NRI, Staff Ward, EWS, OBC, SC/ST, etc.

Each quota has a name, percentage allocation, and priority order. The seat allotment engine uses these quotas to automatically match eligible applicants to reserved seats.

---

## When This Screen Is Used

- After creating an admission cycle: Admin defines the quota types applicable for the upcoming admissions
- Regulatory changes: Admin needs to update quota percentages to comply with government mandates (e.g., RTE 25%)
- School policy changes: Admin adds new categories like "Staff Ward" or "Alumni Sibling"

---

## Key Fields at a Glance

**Quota Name**
The display name (e.g., "General", "RTE 25%", "NRI", "Staff Ward", "EWS", "OBC").

**Percentage**
The percentage of total seats reserved for this quota. For example, RTE = 25%, General = 40%, etc.

**Priority Order**
A numeric priority that determines the order of allotment. Lower numbers are processed first. For example, RTE (priority 1) gets allotted before General (priority 2).

**Cycle**
The admission cycle this quota belongs to.

**Status**
Enable/disable toggle to temporarily suspend a quota category.

---

## Business Rules and Conditions

**Cycle-Scoped**
Quota configurations belong to a single admission cycle and do not carry over automatically.

**Percentage Must Sum to 100 or Less**
All quotas for a given cycle must have percentages that sum to 100% (or less, if unallocated seats fall under General).

**Priority Must Be Unique**
Each quota within a cycle must have a unique priority order number.

**Seat Capacity Interaction**
Quota percentages are applied against the total seat capacity per class during allotment. If a quota is underfilled, remaining seats roll over to General.

**Soft Delete**
Quotas can be soft-deleted. Active applications already using the quota retain their association.

---

## Workflow Steps

**Adding a Quota**
Admin clicks "Add Quota", enters the name, percentage, priority order, and submits. The new quota appears in the table.

**Editing a Quota**
Admin clicks the Edit icon on any row. The form populates and changes are saved inline.

**Toggling Status**
Admin toggles the status switch to enable/disable a quota. Disabled quotas are not considered during allotment.

**Deleting a Quota**
Admin clicks Delete. A confirmation dialog appears.

---

## Example Scenario

A school configures quotas for the 2027-28 cycle:

| Quota | Percentage | Priority |
|-------|-----------|----------|
| RTE 25% | 25 | 1 |
| Staff Ward | 10 | 2 |
| NRI | 15 | 3 |
| General | 50 | 4 |

Total: 100%. During allotment, RTE applicants are processed first (25% of total seats), followed by Staff Ward, then NRI, and finally General.

---

## Related Screens

- **Admission Cycles** — Quotas are scoped to a cycle
- **Seat Capacity** — Quota percentages are applied against total seats
- **Allotments** — Quota matching during seat allotment
- **Merit Lists** — Quota types appear in merit list entries
