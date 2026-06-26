# Payment Reconciliation — Requirements

## What It Does
Manages cheque/DD clearance lifecycle for fee payments. Tracks cheque deposit, clearance, bounce with full audit trail including bounce charges and resubmission. Also stores payment gateway logs for online transactions with request/response payloads.

Features:
- 5-stage cheque lifecycle: Pending Deposit → Deposited → Cleared → Bounced → Resubmitted
- Bounce tracking with reason, charges, resubmit date
- Payment gateway log storage (Razorpay, Paytm, CCAvenue, BillDesk)
- Request/response payload capture for debugging

## Database Fields

**fee_payment_reconciliations**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Required. |
| `cheque_no` | VARCHAR(50) | Required. Cheque/DD number. |
| `bank_name` | VARCHAR(100) | Required. Bank name. |
| `cheque_date` | DATE | Required. Date on cheque. |
| `deposit_date` | DATE | Nullable. When deposited in bank. |
| `clearance_date` | DATE | Nullable. When cheque cleared. |
| `bounce_date` | DATE | Nullable. When cheque bounced. |
| `bounce_reason` | VARCHAR(255) | Nullable. Reason for bounce (insufficient funds, signature mismatch, etc.). |
| `bounce_charge` | DECIMAL(10,2) | Default 0.00. Bank penalty for bounce. |
| `resubmit_date` | DATE | Nullable. If cheque was resubmitted. |
| `status` | ENUM | `Pending Deposit`, `Deposited`, `Cleared`, `Bounced`, `Resubmitted`. |
| `remarks` | TEXT | Nullable. |
| `updated_by` | BIGINT UNSIGNED FK → `sys_users` | Who last updated the status. |

**fee_payment_gateway_logs**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Required. |
| `gateway_name` | ENUM | `Razorpay`, `Paytm`, `CCAvenue`, `BillDesk`, `Other`. |
| `gateway_transaction_id` | VARCHAR(255) | Gateway's transaction ID. |
| `order_id` | VARCHAR(255) | Gateway order ID. |
| `payment_id` | VARCHAR(255) | Gateway payment ID. |
| `request_payload` | JSON | Full request sent to gateway. Cast to array. |
| `response_payload` | JSON | Full response from gateway. Cast to array. |
| `amount` | DECIMAL(12,2) | Transaction amount. |
| `status` | VARCHAR(50) | Gateway status (success, failed, pending). |
| `error_message` | TEXT | Nullable. Gateway error message. |
| `ip_address` | VARCHAR(45) | Client IP address. |
| `user_agent` | TEXT | Client user agent. |

## Business Rules

**Cheque Lifecycle**
```
Pending Deposit → Deposited → Cleared (success)
                     │              │
                     ▼              ▼
                  Bounced ───→ Resubmitted → Cleared
```
- `Pending Deposit`: Cheque received but not yet deposited
- `Deposited`: Cheque deposited in bank
- `Cleared`: Cheque cleared (successful payment)
- `Bounced`: Cheque returned unpaid. `bounce_reason` and `bounce_date` recorded.
- `Resubmitted`: Cheque deposited again after bounce

**Bounce Handling**
- When a cheque bounces: transaction status changes to `Failed`
- `bounce_charge`: bank penalty fee tracked (may be passed to the student)
- On resubmission: a new reconciliation cycle starts from Deposited

**Gateway Logging**
- `request_payload` and `response_payload` store the full JSON sent/received from payment gateway
- Used for debugging payment failures and audit
- Logs are retained permanently (no automatic cleanup)

## Permissions

| Operation | Permission Key |
|---|---|
| View reconciliation | `tenant.fee-invoice.viewAny` |
| Update reconciliation status | `tenant.fee-invoice.create` |
