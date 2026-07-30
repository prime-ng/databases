# Fee Refund — Business Requirements

## What This Screen Does

The Fee Refund screen manages fee refunds to students/parents on withdrawal or overpayment. Each refund is linked to an original successful transaction and goes through a 4-stage approval workflow: Pending → Approved → Processed → Rejected. Tracks refund mode (Cash, Cheque, Bank Transfer, Original Mode) with full approval and processing audit trail.

---

## When This Screen Is Used

- **Student Withdrawal** when a student leaves the school mid-session and is entitled to a fee refund
- **Overpayment Correction** when a parent accidentally overpays and requests a refund
- **Duplicate Payment Resolution** when a payment is made twice for the same invoice
- **Refund Approval Workflow** when authorized personnel approve/reject/process refund requests

## Default Data Load

The index page loads `FeeRefund::with(['originalTransaction', 'student.user'])->latest()->paginate(15)`. The create page loads only successful transactions (`FeeTransaction::where('status', FeeTransaction::STATUS_SUCCESS)`).

---

## Key Fields at a Glance

**Refund Identity**
`refund_no` — auto-generated format `RFD-YEAR-XXXXX` (e.g., RFD-2026-00001). `original_transaction_id` links to the original payment. `student_id` identifies the beneficiary.

**Financial Details**
`refund_date`, `refund_amount` (must not exceed original transaction amount), `refund_mode` (Cash/Cheque/Bank Transfer/Original Mode), `refund_reference` (cheque no/UTR), `refund_reason` (required, max 500 chars).

**Status Workflow**
Four statuses: `Pending` → `Approved` → `Processed` / `Rejected`.
- `Pending`: Initial state on creation
- `Approved`: Authorized by approver (`approved_by`, `approved_at`)
- `Processed`: Completed (`processed_by`, `processed_at`, marks original transaction as Refunded)
- `Rejected`: Denied with `rejection_reason`

---

## Business Rules and Conditions

**Status Transition Rules**
- Pending → Approved: only if current status is Pending. Error: "Only pending refunds can be approved."
- Pending → Rejected: only if current status is Pending. Error: "Only pending refunds can be rejected."
- Approved → Processed: only if current status is Approved. Error: "Only approved refunds can be processed."
- Edit/Delete: only allowed if status is Pending. Errors: "Only pending refunds can be edited." / "Only pending refunds can be updated." / "Only pending refunds can be deleted."

**Amount Validation**
- `refund_amount` cannot exceed original transaction `amount`. Error: "Refund amount cannot exceed the original transaction amount."
- Only successful transactions can be refunded (validated in FormRequest via `FeeTransaction::STATUS_SUCCESS`)
- The original invoice must be paid before creating a refund. Error: "The original invoice must be paid before creating a refund."

**Transaction Status Update**
When refund is **Processed**: `$feeRefund->originalTransaction->markRefunded()` sets original transaction status to `Refunded`.

**Refund Number Generation**
Auto-generated via `generateRefundNumber()`: uses DB transaction with `lockForUpdate()`, increments max ID + 1, formats as `RFD-YEAR-XXXXX` (zero-padded to 5 digits).

---

## Workflow Steps

**Creating a Refund Request**
Admin selects the original successful transaction, enters refund amount, refund mode, refund reference (optional), and refund reason. System generates refund_no and creates with status=Pending.

**Approving a Refund**
Authorized personnel clicks Approve on a Pending refund. System sets status=Approved, approved_by, approved_at.

**Rejecting a Refund**
Authorized personnel enters rejection_reason and clicks Reject. System sets status=Rejected, rejection_reason.

**Processing a Refund**
Finance team clicks Process on an Approved refund. System sets status=Processed, processed_by, processed_at, updates refund_reference if provided, and calls markRefunded() on the original transaction.

**Editing a Pending Refund**
Admin can edit all fields of a Pending refund. Once Approved/Processed/Rejected, editing is blocked.

---

## Example Scenario

A student withdraws in October. The original tuition fee of ₹50,000 was paid via bank transfer in April. The school's refund policy allows pro-rata refund of ₹35,000. The admin creates a refund request (status=Pending). The accounts manager approves it (status=Approved). The finance team processes the bank transfer (status=Processed). The original transaction is marked as Refunded. Refund number: RFD-2026-00001.

---

## Related Screens

- **Fee Transactions** — Original transactions linked to refunds
- **Fee Invoices** — Invoice payment status updated when refund is processed
- **Payment** — Payment records showing refunded transactions

---

## Requirements

- Controller `FeeRefundController` with full resource routes plus custom approve/reject/process routes (all POST)
- `index()` gates `tenant.fee-refund.viewAny`, loads with originalTransaction and student.user relations, paginated at 15
- `create()` gates `tenant.fee-refund.create`, loads only successful transactions ordered by payment_date desc
- `store()` validates via `StoreFeeRefundRequest`, generates refund_no, creates with status=Pending and created_by
- `show()` loads with originalTransaction, invoice, student.user, approvedBy, processedBy, createdBy
- `edit()` gates `tenant.fee-refund.update`, blocks if not Pending ("Only pending refunds can be edited.")
- `update()` validates via `UpdateFeeRefundRequest`, blocks if not Pending ("Only pending refunds can be updated.")
- `destroy()` gates `tenant.fee-refund.delete`, blocks if not Pending ("Only pending refunds can be deleted."), soft-deletes
- `approve()` gates `tenant.fee-refund.approve`, checks Pending status, sets status=Approved, approved_by, approved_at
- `reject()` gates `tenant.fee-refund.reject`, checks Pending status, validates rejection_reason (required, string, max:500), sets status=Rejected
- `process()` gates `tenant.fee-refund.process`, checks Approved status ("Only approved refunds can be processed."), sets status=Processed, calls markRefunded() on original transaction

## Who Can Access

| Gate/Permission | Methods | Notes |
|----------------|---------|-------|
| `tenant.fee-refund.viewAny` | `index()` | Page load |
| `tenant.fee-refund.view` | `show()` | View details |
| `tenant.fee-refund.create` | `create()`, `store()` | Create request |
| `tenant.fee-refund.update` | `edit()`, `update()` | Edit pending |
| `tenant.fee-refund.delete` | `destroy()` | Delete pending |
| `tenant.fee-refund.approve` | `approve()` | Approve request |
| `tenant.fee-refund.reject` | `reject()` | Reject request |
| `tenant.fee-refund.process` | `process()` | Process approved |

## Logic Flow

1. **Create** — `create()` loads successful transactions. `store()` validates amount ≤ original, validates invoice is paid. Generates refund_no via `RFD-YEAR-XXXXX`. Creates with status=Pending.
2. **Approve** — `approve()` checks Pending status. Sets approved_by, approved_at, status=Approved.
3. **Reject** — `reject()` checks Pending status. Validates rejection_reason required. Sets status=Rejected with reason.
4. **Process** — `process()` checks Approved status. Optionally updates refund_reference. Sets processed_by, processed_at, status=Processed. Calls markRefunded() on original transaction.
5. **Edit/Delete** — Both check `isPending()` status. Block if not Pending.

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `original_transaction_id` | `required, integer, exists:fee_transactions,id` where status=Success | — |
| `student_id` | `required, integer, exists:std_students,id` | — |
| `refund_date` | `required, date` | — |
| `refund_amount` | `required, numeric, min:0.01` | — |
| `refund_mode` | `required, string, max:50` | — |
| `refund_reference` | `nullable, string, max:100` | — |
| `refund_reason` | `required, string, max:500` | — |
| **Reject** — `rejection_reason` | `required, string, max:500` | — |
| **Process** — `refund_reference` | `nullable, string, max:100` | — |
| **Amount check** | refund_amount ≤ original_transaction.amount | "Refund amount cannot exceed the original transaction amount." |
| **Invoice check** | Original invoice must be paid | "The original invoice must be paid before creating a refund." |

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Edit non-pending | "Only pending refunds can be edited." | Controller |
| Update non-pending | "Only pending refunds can be updated." | Controller |
| Delete non-pending | "Only pending refunds can be deleted." | Controller |
| Approve non-pending | "Only pending refunds can be approved." | Controller |
| Reject non-pending | "Only pending refunds can be rejected." | Controller |
| Process non-approved | "Only approved refunds can be processed." | Controller |
| Amount exceeds original | "Refund amount cannot exceed the original transaction amount." | Validation (after) |
| Invoice not paid | "The original invoice must be paid before creating a refund." | Validation (after) |
| Create success | "Refund request created successfully." | Flash |
| Approve success | "Refund approved successfully." | Flash |
| Reject success | "Refund rejected successfully." | Flash |
| Process success | "Refund processed successfully." | Flash |

## Success Scenarios

**SC-001 — Full Refund Lifecycle**
Admin creates refund → status=Pending. Approver approves → status=Approved. Finance processes → status=Processed, original transaction marked as Refunded. All audit fields populated.

**SC-002 — Refund Rejected**
Admin creates refund → status=Pending. Approver rejects with reason "Insufficient documentation" → status=Rejected. Original transaction unchanged.

**SC-003 — Edit Pending Refund**
Admin creates refund → edits refund_amount and refund_reason before approval. Both updates allowed while status=Pending.

## Failure Scenarios

**FC-001 — Process Non-Approved Refund**
User tries to process a Pending refund directly. Error: "Only approved refunds can be processed."

**FC-002 — Amount Exceeds Original Transaction**
Admin enters refund_amount more than the original transaction amount. Validation error: "Refund amount cannot exceed the original transaction amount."

**FC-003 — Refund for Unpaid Invoice**
Admin selects a transaction whose invoice is not fully paid. Error: "The original invoice must be paid before creating a refund."

## Dependencies Module and Tables

| Dependency | Type | Details |
|-----------|------|---------|
| `fee_refunds` | Main Table | All CRUD + workflow on this table |
| `fee_transactions` | FK Table | `original_transaction_id` FK RESTRICT; status updated to Refunded on process |
| `std_students` | FK Table | `student_id` FK RESTRICT |
| `sys_users` | FK Table | `approved_by`, `processed_by`, `created_by` FK SET NULL |
| `fee_invoices` | Related Table | Invoice payment status validated before refund |
