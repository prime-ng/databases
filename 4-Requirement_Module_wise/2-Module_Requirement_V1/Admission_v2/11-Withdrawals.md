# Withdrawals — Business Requirements

## What This Screen Does

The Withdrawals screen records and manages student exits from the admission process, either before enrollment (from an allotment) or after enrollment (from the school). Each withdrawal includes the reason, refund amount (auto-computed from the cycle's refund policy), and status.

The screen shows a withdrawals list (within the Allotment & Enrollment tab group) with applicant/student details, reason, refund amount, and status. Each withdrawal has a show page with detailed information and refund processing actions.

---

## When This Screen Is Used

- Pre-enrollment: A parent declines an allotment or requests withdrawal
- Post-enrollment: A parent withdraws their child from the school
- Admin processes refunds for withdrawn applicants
- Admin tracks withdrawal trends and reasons

---

## Key Fields at a Glance

**Applicant / Student**
The person being withdrawn. Shows name, application number, and class.

**Withdrawal Type**
Pre-Enrollment — withdrawal before admission is finalized (from allotment).
Post-Enrollment — withdrawal after the student has officially enrolled.

**Reason**
The stated reason for withdrawal (e.g., "Accepted another school", "Relocating", "Financial reasons").

**Refund Amount**
Auto-computed based on the cycle's refund policy and the withdrawal date relative to the cycle end date.

**Status**
Pending — withdrawal requested, refund not yet processed.
Processed — refund has been completed.
Closed — withdrawal is finalized.

---

## Business Rules and Conditions

**Refund Policy**
The refund amount is auto-computed from the admission cycle's refund policy (percentage deduction based on days remaining or fixed cutoff dates).

**Seat Release**
On withdrawal, the allotted seat is immediately released back to the available pool. Rolling admissions can re-allot it.

**Pre vs Post Enrollment**
Pre-enrollment withdrawals only affect the allotment record. Post-enrollment withdrawals affect the student's academic session status as well.

**Soft Delete**
Withdrawals can be soft-deleted.

---

## Workflow Steps

**Recording a Withdrawal**
Admin clicks "Add Withdrawal", selects the applicant/student, enters the reason, and submits. The system auto-computes the refund amount.

**Viewing Withdrawal List**
The withdrawals tab displays all withdrawals with status badges, applicant/student names, reason, and refund amount.

**Viewing Withdrawal Details**
Admin clicks on a withdrawal to open the show page. This page displays the applicant/student info, withdrawal reason, refund calculation, and action buttons.

**Processing a Refund**
Admin clicks "Process Refund" on a Pending withdrawal. A confirmation dialog appears. The refund is marked as Processed.

**Editing a Withdrawal**
Admin can edit the reason or details of a pending withdrawal.

**Deleting a Withdrawal**
Admin clicks Delete. A confirmation dialog appears.

---

## Example Scenario

A parent who was allotted a Class IX seat decides to accept an offer from another school. The admin records a withdrawal:
- Type: Pre-Enrollment
- Reason: "Accepted another school"
- Refund: The cycle policy states 50% refund if withdrawn more than 15 days before session start. The system computes the refund amount.
- Admin processes the refund. The seat is released back to the pool.

---

## Related Screens

- **Allotments** — Withdrawals are linked to allotments (pre-enrollment)
- **Enrollment** — Post-enrollment withdrawals affect enrollment records
- **Admission Cycles** — Refund policy is defined in the cycle configuration
- **Dashboard** — Withdrawal counts feed into funnel KPIs
