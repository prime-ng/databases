# Fee Invoices — Requirements

## What It Does
Generates and manages student fee invoices per installment. Supports manual and bulk generation, PDF download, email/WhatsApp delivery, payment recording, and cancellation. Invoice has a computed `balance_amount` (generated column: `total_amount - paid_amount`). Implements a `Payable` contract for payment gateway integration.

Features:
- Auto-generated invoice numbers (`INV-YYYYMM-XXXX`)
- 6 status lifecycle: Draft → Published → Partially Paid → Paid → Overdue → Cancelled
- Concession amount application (from approved student concessions)
- Fine amount tracking (from fee fine transactions)
- Tax amount computation
- Computed balance column (stored generated column)
- Bulk generation for all active assignments
- PDF generation via DomPDF
- Email delivery via Notification system
- WhatsApp share link
- Payment recording with transaction history
- Soft-delete with full restore

## Database Fields

**fee_invoices**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `invoice_no` | VARCHAR(50) | Required. UNIQUE. Auto-format: `INV-YYYYMM-XXXX`. |
| `student_assignment_id` | BIGINT UNSIGNED FK → `fee_student_assignments` | Required. |
| `installment_id` | BIGINT UNSIGNED FK → `fee_installments` | Required. |
| `invoice_date` | DATE | Required. Date of invoice generation. |
| `due_date` | DATE | Required. Payment due date (from installment). |
| `base_amount` | DECIMAL(12,2) | Required. Installment amount before adjustments. |
| `concession_amount` | DECIMAL(12,2) | Default 0.00. Approved concession amount. |
| `fine_amount` | DECIMAL(12,2) | Default 0.00. Applied late fee. |
| `tax_amount` | DECIMAL(12,2) | Default 0.00. Tax on taxable heads. |
| `total_amount` | DECIMAL(12,2) | Required. `base_amount - concession_amount + fine_amount + tax_amount`. |
| `paid_amount` | DECIMAL(12,2) | Default 0.00. Cumulative payments. |
| `balance_amount` | DECIMAL(12,2) | STORED GENERATED column: `total_amount - paid_amount`. |
| `status` | ENUM | `Draft`, `Published`, `Partially Paid`, `Paid`, `Overdue`, `Cancelled`. |
| `invoice_pdf_path` | VARCHAR(255) | Nullable. Path to generated PDF. |
| `generated_by` | BIGINT UNSIGNED FK → `sys_users` | Who generated the invoice. |
| `cancelled_by` | BIGINT UNSIGNED FK → `sys_users` | Nullable. Who cancelled. |
| `cancellation_reason` | VARCHAR(255) | Nullable. Why cancelled. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Invoice Number Generation**
- Format: `INV-YYYYMM-XXXX` (e.g., `INV-202604-0001`)
- `YYYYMM` = year + month of generation
- `XXXX` = auto-incrementing sequence per month
- Generated during creation

**Status Transition**
```
Draft ──→ Published ──→ Partially Paid ──→ Paid
                │               │
                ▼               ▼
             Overdue         Cancelled
```
- `Draft`: Initial state. Can be edited.
- `Published`: Ready for payment. Visible to student/parent.
- `Partially Paid`: Some payment received but not full amount.
- `Paid`: Full payment received. `paid_amount = total_amount`.
- `Overdue`: Past due date + grace period without full payment.
- `Cancelled`: Voided invoice. Cannot be paid.

**Amount Computation**
- `concession_amount`: sum of all approved `FeeStudentConcession.discount_amount` for this assignment
- `fine_amount`: sum of all `FeeFineTransaction.fine_amount - waived_amount` for this invoice
- `tax_amount`: sum of `head.amount × (head.tax_percentage / 100)` for taxable heads in this installment
- `total_amount = base_amount - concession_amount + fine_amount + tax_amount`
- `balance_amount = total_amount - paid_amount` (stored generated column — computed by MySQL)

**Bulk Generation**
- `generateFeeInvoice()`: Creates Published invoices for all active assignments without existing unpaid invoices for the same installment
- Prevent duplicates: one published invoice per assignment + installment combination
- After generation: sends notification per invoice (configurable)

**Payment Recording**
- `recordPayment(Request, $id)`: Creates `FeeTransaction`, updates `paid_amount`, recalculates status
- If `paid_amount >= total_amount`: status → `Paid`
- If `paid_amount > 0` but `< total_amount`: status → `Partially Paid`
- If `paid_amount = 0`: status unchanged
- All wrapped in DB transaction

**Invoice PDF**
- Generated on-demand or during bulk generation
- Stored in `fee_invoices.invoice_pdf_path`
- Download via `GET /student-fee/fee-invoice/{id}/pdf`
- DomPDF template: `fee-invoice.invoice-pdf`
- Includes: school header, student info, fee breakdown, due date, payment QR (optional)

**Email/WhatsApp Delivery**
- Email: generates PDF, saves to storage, dispatches Notification with FEE_PAYMENT_REMINDER type
- WhatsApp: generates PDF, saves to storage, redirects to WhatsApp link with pre-populated message

**Cancellation Rules**
- Cannot cancel if `status = Paid`
- Cannot cancel if already cancelled
- On cancel: sets `cancelled_by`, `cancellation_reason`, status → `Cancelled`

**Implements Payable Contract**
- `getPayableLabel()`: returns `"Fee Invoice: {invoice_no}"`
- `getPayableAmount()`: returns `balance_amount`
- `getPayableCustomer()`: returns student/guardian details
- `getPayableMetadata()`: returns invoice metadata for gateway

## CRUD Operations

**List Invoices**
- Search by: invoice_no, student name
- Filter by: status
- Shows: invoice no, student, installment, due date, total, paid, balance, status

**Create Invoice (Manual)**
- Select: active assignment, installment
- Base amount auto-populated from installment
- Concessions and fines auto-applied
- Manual override for adjustments

**Show Invoice**
- Full invoice view with breakdown
- Payment history table
- Fine transactions table
- Action buttons (download PDF, email, WhatsApp, record payment, cancel)

**Bulk Generate Invoices**
- Creates Published invoices for all active assignments without existing invoices
- Progress indicator

**Download PDF**
- Generates and downloads PDF

**Send Email**
- Sends invoice via email notification

**Send WhatsApp**
- Opens WhatsApp share link

**Record Payment**
- Creates transaction, updates invoice

**Cancel Invoice**
- Cancels invoice with reason

## Permissions

| Operation | Permission Key |
|---|---|
| View invoices | `tenant.fee-invoice.viewAny` |
| Create invoice | `tenant.fee-invoice.create` |
| Update invoice | `tenant.fee-invoice.update` |
| Delete invoice | `tenant.fee-invoice.delete` |
| Download PDF | `tenant.fee-invoice.pdf` |
| Email invoice | `tenant.fee-invoice.emailSchedule` |
| Record payment | `tenant.fee-invoice.create` |
| Cancel invoice | `tenant.fee-invoice.delete` |
