# Fee Refunds — Requirements

## What It Does
Manages fee refunds to students/parents on withdrawal or overpayment. Each refund is linked to an original transaction and goes through a 4-stage approval workflow: Pending → Approved → Processed → Rejected. Tracks refund mode (cash, cheque, bank transfer, online reversal).

Features:
- Auto-generated refund numbers
- 4-stage refund workflow with approval chain
- Multiple refund modes
- Approval and processing audit trail
- Soft-delete with restore

## Database Fields

**fee_refunds**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `refund_no` | VARCHAR(50) | Required. UNIQUE. Auto-format: `RFD-YYYYMM-XXXX`. |
| `original_transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Required. Original payment being refunded. |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `refund_date` | DATE | Required. Date of refund. |
| `refund_amount` | DECIMAL(12,2) | Required. Amount to refund. Cannot exceed original transaction amount. |
| `refund_mode` | ENUM | `Cash`, `Cheque`, `Bank Transfer`, `Online Reversal`. |
| `refund_reference` | VARCHAR(255) | Nullable. Cheque number, UTR, reversal ID. |
| `refund_reason` | VARCHAR(500) | Required. Why the refund is being made. |
| `approved_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. |
| `approved_at` | DATETIME | Nullable. |
| `status` | ENUM | `Pending`, `Approved`, `Processed`, `Rejected`. |
| `rejection_reason` | VARCHAR(255) | Nullable. |
| `processed_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. |
| `processed_at` | DATETIME | Nullable. |
| `created_by` | BIGINT UNSIGNED FK → `sys_users` | Required. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Refund Workflow**
```
Pending → Approved → Processed (success)
    │                     │
    ▼                     ▼
 Rejected            (terminal)
```
- `Pending`: Refund request created, awaiting approval
- `Approved`: Refund approved, ready for processing
- `Processed`: Refund completed — money returned
- `Rejected`: Refund denied with reason

**Amount Validation**
- `refund_amount` cannot exceed the original transaction `amount`
- Only successful transactions can be refunded
- Cannot refund the same transaction twice (total refunds ≤ original amount)

**Refund Modes**
- `Cash`: Hand-delivered cash refund
- `Cheque`: Refund via cheque
- `Bank Transfer`: Refund via NEFT/RTGS/IMPS
- `Online Reversal`: Reverse the original online payment

**Transaction Status Update**
- When refund is processed: original transaction `status` → `Refunded`
- Linked invoice `paid_amount` is reduced by the refund amount
- Invoice status may change from `Paid` → `Partially Paid` if partially refunded

## Permissions

| Operation | Permission Key |
|---|---|
| View refunds | `tenant.fee-invoice.viewAny` |
| Create refund request | `tenant.fee-invoice.create` |
| Approve / Reject refund | `tenant.fee-invoice.create` |
| Process refund | `tenant.fee-invoice.create` |
