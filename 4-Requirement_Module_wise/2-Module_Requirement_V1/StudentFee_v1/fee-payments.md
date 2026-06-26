# Fee Payments & Receipts — Requirements

## What It Does
Records fee payments (transactions) against invoices. Each transaction has a unique number, tracks payment mode (cash, cheque, online, DD, bank transfer), and can split amounts across heads via transaction details. Generates receipts with multiple format options and supports parent delivery via email/SMS/WhatsApp.

Features:
- Auto-generated transaction numbers (`TXN-YYYYMM-XXXX`)
- Multiple payment modes
- Per-head amount allocation via transaction details
- Receipt generation (Standard, Detailed, Tax formats)
- Receipt delivery tracking (email, SMS, WhatsApp, print)
- On-demand PDF download via DomPDF
- Refund tracking on transactions
- Soft-delete with restore

## Database Fields

**fee_transactions**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `transaction_no` | VARCHAR(50) | Required. UNIQUE. Auto-format: `TXN-YYYYMM-XXXX`. |
| `student_id` | BIGINT UNSIGNED FK → `std_students` | Required. |
| `invoice_id` | BIGINT UNSIGNED FK → `fee_invoices` | Required. |
| `guardian_id` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Parent/guardian who made the payment. |
| `payment_date` | DATETIME | Required. When the payment was made. |
| `payment_mode` | ENUM | `Cash`, `Cheque`, `Online`, `DD`, `Bank Transfer`. |
| `payment_reference` | VARCHAR(255) | Nullable. Transaction ID, cheque number, DD number. |
| `bank_name` | VARCHAR(100) | Nullable. Required for cheque/DD/Bank Transfer. |
| `cheque_date` | DATE | Nullable. For cheque payments. |
| `amount` | DECIMAL(12,2) | Required. Payment amount. |
| `fine_adjusted` | DECIMAL(12,2) | Default 0.00. Fine amount adjusted in this payment. |
| `concession_adjusted` | DECIMAL(12,2) | Default 0.00. Concession amount adjusted. |
| `status` | ENUM | `Success`, `Pending`, `Failed`, `Refunded`. |
| `collected_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Staff who collected the payment. |
| `remarks` | TEXT | Nullable. |
| `receipt_generated` | BOOLEAN | Default false. Whether receipt PDF has been generated. |
| `receipt_id` | BIGINT UNSIGNED FK → `fee_receipts` | Nullable. Linked receipt. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**fee_transaction_details**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Required. |
| `head_id` | BIGINT UNSIGNED FK → `fee_head_masters` | Required. |
| `amount` | DECIMAL(10,2) | Required. Amount paid toward this head. |
| `fine_amount` | DECIMAL(10,2) | Default 0.00. Fine portion for this head. |
| `concession_amount` | DECIMAL(10,2) | Default 0.00. Concession portion for this head. |

**fee_receipts**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `receipt_no` | VARCHAR(50) | Required. UNIQUE. |
| `transaction_id` | BIGINT UNSIGNED FK → `fee_transactions` | Required. |
| `receipt_date` | DATETIME | Required. |
| `receipt_pdf_path` | VARCHAR(255) | Nullable. Path to generated PDF. |
| `receipt_format` | ENUM | `Standard`, `Detailed`, `Tax`. |
| `sent_to_parent` | BOOLEAN | Default false. |
| `sent_via` | ENUM | `Email`, `SMS`, `WhatsApp`, `Print`. |
| `sent_at` | DATETIME | Nullable. |

## Business Rules

**Transaction Number Format**
- Format: `TXN-YYYYMM-XXXX` (e.g., `TXN-202604-0001`)
- Auto-generated on payment recording
- Independent sequence per month

**Payment Modes**
- `Cash`: Direct cash payment. No reference required.
- `Cheque`: Requires `bank_name`, `cheque_date`, `payment_reference` (cheque number). Goes to reconciliation.
- `Online`: Requires `payment_reference` (gateway transaction ID). Linked to `FeePaymentGatewayLog`.
- `DD`: Demand Draft. Requires `bank_name`, `payment_reference`.
- `Bank Transfer`: Requires `bank_name`, `payment_reference`.

**Per-Head Allocation**
- Each transaction can be split across multiple fee heads via `FeeTransactionDetail`
- `amount`: How much was paid toward this head
- `fine_amount`: How much fine was covered by this payment
- `concession_amount`: How much concession was applied
- Net amount toward head = `amount + fine_amount + concession_amount`
- Sum of all detail `amount` values must equal transaction `amount`

**Receipt Generation**
- Auto-generated on successful payment
- 3 formats:
  - `Standard`: Basic receipt with total amount, payment mode, date
  - `Detailed`: Per-head breakdown, fines, concessions
  - `Tax`: Includes tax breakup for taxable heads
- PDF stored at `receipt_pdf_path`
- On-demand generation via `downloadReceipt($id)` if not yet generated

**Receipt Delivery**
- Receipt can be sent via email, SMS, WhatsApp, or printed
- Each send is logged with `sent_via`, `sent_at`
- `sent_to_parent` flag tracks whether any delivery was made

**Transaction Status**
- `Success`: Payment completed
- `Pending`: Payment initiated but not confirmed (online gateway)
- `Failed`: Payment failed (gateway declined, cheque bounced)
- `Refunded`: Payment was refunded (linked to FeeRefund)

## CRUD Operations

**List Transactions**
- Search by: transaction no, invoice no, student name
- Filter by: payment_mode, status
- Shows: transaction no, student, invoice, amount, mode, status, date

**Show Transaction**
- Full details: transaction info, per-head breakdown, receipt
- Linked invoice, fine transactions, gateway log

**Download Receipt**
- Generates receipt PDF if not already generated
- Downloads DomPDF receipt

## Permissions

| Operation | Permission Key |
|---|---|
| View transactions | `tenant.fee-transaction.viewAny` |
| View transaction details | `tenant.fee-transaction.view` |
| Download receipt | `tenant.fee-transaction.print` |
