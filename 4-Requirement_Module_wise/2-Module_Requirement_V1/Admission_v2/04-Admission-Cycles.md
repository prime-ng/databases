# Admission Cycles — Business Requirements

## What This Screen Does

The Admission Cycles screen is the foundation of the entire admission workflow. A cycle represents a yearly admission campaign — it defines the start date, end date, age eligibility criteria, fee structure, refund policy, and overall status. Every other admission feature (enquiries, applications, tests, merit lists, allotments) is scoped within a cycle.

This screen shows a table of all cycles with their status, dates, and action buttons. A form panel on the side allows creating or editing a cycle inline. Each cycle can be activated (to begin accepting applications) or closed (to stop new applications).

---

## When This Screen Is Used

- At the start of the academic year: Admin creates a new admission cycle
- Mid-cycle: Admin modifies cycle dates or fee amounts
- End of cycle: Admin closes the cycle to stop new applications
- Admin needs to view past cycles for audit or reporting

---

## Key Fields at a Glance

**Cycle Name**
A human-readable label (e.g., "Academic Year 2026–27").

**Status**
Draft — cycle is being set up, not yet active.
Active — cycle is open for enquiries and applications.
Closed — cycle is ended, no further applications accepted.

**Start Date / End Date**
The date range during which applications are accepted.

**Age Criteria**
Minimum and maximum age (in years) for applicants. Validated against the applicant's date of birth during application submission.

**Late Fee Start Date**
After this date, a late fee is applied to new applications.

**Refund Policy**
Defines the refund deduction percentage and cutoff date for withdrawal refunds.

**Activate / Close Actions**
Buttons to transition the cycle between Draft → Active → Closed states.

---

## Business Rules and Conditions

**One Active Cycle at a Time**
Only one cycle can be in Active status at any given time. Activating a new cycle automatically deactivates the previous active one.

**Locked After Close**
Once a cycle is Closed, it cannot be reopened. Only viewing and reporting are allowed on closed cycles.

**Draft Edits Only**
Cycles can be freely edited in Draft status. Once Active, only certain fields (dates, late fee) remain editable.

**Soft Delete**
Cycles can be soft-deleted. Deleted cycles do not affect existing records (enquiries, applications, allotments) — they just become hidden from default views.

---

## Workflow Steps

**Creating a Cycle**
Admin clicks "Add Cycle", fills the form (name, dates, age criteria, fee, refund policy), and submits. The cycle is created in Draft status.

**Editing a Cycle**
Admin clicks the Edit icon on any row. The form populates with the cycle's data. Changes are saved inline.

**Activating a Cycle**
Admin clicks the Activate button on a Draft cycle. A confirmation dialog appears. On confirm, the cycle becomes Active (and any previously active cycle is deactivated).

**Closing a Cycle**
Admin clicks the Close button on an Active cycle. Once closed, no new applications can be submitted.

**Toggling Status**
Each cycle row has a toggle switch to quickly enable/disable it.

**Deleting a Cycle**
Admin clicks Delete. A confirmation dialog appears. On confirm, the cycle is soft-deleted.

---

## Example Scenario

A school starts planning for the 2027-28 academic year. Admin creates a cycle named "Academic Year 2027-28" with:
- Start Date: 01-Jan-2027, End Date: 31-Mar-2027
- Age Criteria: Min 5 years, Max 7 years (for Class I)
- Late Fee: Applicable from 15-Feb-2027 onwards
- Refund: 100% before 30 days, 50% before 15 days, 0% after

The cycle is saved as Draft. Admin configures seat capacities, quotas, and document checklists. When ready, admin activates the cycle — the portal opens for applications.

---

## Related Screens

- **Seat Capacity** — Allocate seats per class within this cycle
- **Quota Config** — Define quota types for this cycle
- **Document Checklist** — Set required documents per class within this cycle
- **Enquiry Pipeline** — All enquiries and applications are scoped to the active cycle
- **Dashboard** — Cycle filter drives all dashboard KPIs
