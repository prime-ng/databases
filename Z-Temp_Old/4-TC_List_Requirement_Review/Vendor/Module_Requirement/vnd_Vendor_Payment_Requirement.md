# Vendor Payment — Business Requirements

## What This Screen Does

The Vendor Payment screen records and manages payments made against vendor invoices. Think of it as a payment ledger: administrators record payments (cash, cheque, bank transfer, UPI, etc.) against specific invoices, track payment status (Initiated → Success/Failed), mark payments as matched with bank statements, and the system automatically updates the invoice balance and status.

Each invoice has a **total amount** (called net payable). The school can pay this amount either **in full** or **in parts** (partial payments). Every time a payment is added, edited, or removed, the system recalculates how much has been paid so far and updates the invoice status accordingly.

The main list view shows all payments with filters to narrow down by vendor, invoice, payment mode, status, date range, and bank matching status. Administrators can view payment details, edit existing payments (which recalculates the linked invoice), and delete payments (which reduces the invoice's paid amount and updates its status). Payment creation is handled within the Invoice creation flow.

---

## When This Screen Is Used

- **Recording a Payment** — When a payment is made against a vendor invoice
- **Viewing Payment History** — To review the full payment trail for an invoice or vendor
- **Editing a Payment** — When payment details need correction (date, amount, mode, status), which re-applies or reverts the amount to the linked invoice
- **Matching Payments with Bank Statements** — To mark payments as reconciled after bank statement matching, recording who matched it and when
- **Deleting a Payment** — To remove an erroneous payment entry, which recalculates the linked invoice's paid amount and status

---

## Who Can Access This Screen

- **School Admin** — Full access (view, update, delete, mark as matched with bank)
- **Accounts Manager** — Full access for financial operations
- **Accounts Viewer** — Read-only access to view payment records

All access is controlled by permissions. The system checks these permissions on every action.

**Note:** There is no standalone screen to create a payment — payments are created as part of the Invoice creation flow. There is also no way to restore deleted payments through this screen.

---

## How This Screen Works — Logic Flow

### The Payment List

When an administrator opens the Vendor Payment screen, the system shows a list of payments (20 per page) with these details: Serial Number, Vendor, Invoice Number, Payment Date, Amount, Payment Mode, Reference Number, Status, Bank Match Status, and Actions (View, Edit, Delete). A filter panel above the list lets administrators narrow down by Vendor, Invoice, Payment Mode, Status, Date Range, and Bank Match Status.

The list shows only payments that have not been deleted. Vendor names and invoice references are automatically pulled in from their respective records.

### Viewing a Payment

When the administrator clicks "View" on a payment, the system retrieves and displays the full payment details. This includes the vendor name, invoice reference, payment mode label, who recorded the payment, who matched it with the bank (if applicable), and the bank match date. This information is typically shown in a pop-up window or a detail panel.

### Editing a Payment

When the administrator edits a payment, the system loads the existing record and presents a form with the following editable fields:
- Payment Date
- Amount
- Payment Mode (dropdown with options: Cash, Cheque, Bank Transfer, UPI, etc.)
- Status (dropdown: Initiated, Confirmed, Failed)
- Reference Number (optional)
- Mark as Matched with Bank Statement (checkbox)

When the edit is saved, the system recalculates the linked invoice:
1. The system **reverts** the old payment amount from the invoice's paid amount
2. The system **applies** the new payment amount to the invoice's paid amount
3. The invoice balance (what is still owed) automatically recalculates
4. The invoice status is updated based on the new paid amount vs the total invoice amount

### Deleting a Payment

When an administrator deletes a payment, the system does the following in a protected sequence:
1. The payment amount is subtracted from the invoice's paid amount
2. The invoice balance (still owed) automatically recalculates
3. The invoice status is updated:
   - If nothing is paid → Pending
   - If partially paid → Partially Paid
   - If fully paid → Fully Paid
4. The payment record is hidden (soft-deleted) — it is no longer shown in the list

If anything goes wrong during the recalculation, the entire operation is reversed so that no data is left in an inconsistent state.

### Matching Payments with Bank Statements (Reconciliation)

Administrators can mark payments as matched with bank statements by checking the "Reconciled" checkbox on the edit form. When a payment is marked as matched:
- The bank match flag is turned on
- The current user is recorded as the person who performed the match
- The date and time of matching are recorded

### Payment Status Flow

Payments follow these statuses:
- **Initiated** — The payment has been started but not yet cleared
- **Confirmed** — The payment has been successfully cleared (this is the default)
- **Failed** — The payment was rejected or did not go through

Status changes:
- Initiated → Confirmed (when the payment clears in the bank)
- Initiated → Failed (when the payment is rejected)
- Confirmed → Marked as Matched with Bank (after bank statement matching)

### Invoice Status After Payment

The linked invoice's status is automatically recalculated based on the total amount paid so far:
- Nothing paid → **Pending**
- Some amount paid (more than zero but less than the total) → **Partially Paid**
- Full amount paid (equal to or more than the total) → **Fully Paid**

The balance (amount still owed) is automatically computed as the invoice total minus the amount paid, so it always reflects the latest state.

---

## Validate Before Save

### Vendor Payment Update — Validation Rules

When saving payment edits, the system checks the following:

**Payment Fields:**
- **payment_date** — Must be provided and must be a valid date
- **amount** — Must be provided, must be a number, minimum 0.01
- **payment_mode** — Must be selected from the available payment modes
- **status** — Must be one of: Confirmed, Initiated, Failed
- **reconciled** — Optional, must be Yes or No
- **reference_no** — Optional, can be left blank

---

## Business Rules and Conditions

### Rule 1: Payment Amount Should Not Exceed the Balance Due
The payment amount should not be more than what is still owed on the invoice. **Note:** This rule is not yet enforced by the system — it is a known business expectation that still needs to be implemented.

### Rule 2: Reference Number Requirements by Payment Mode
Certain payment modes require a reference number:
- **Bank Transfer (NEFT/RTGS)** — Reference number is required
- **UPI** — Reference number is required
- **Cheque** — Cheque number is required
**Note:** This rule is not yet enforced by the system — it is a known business expectation that still needs to be implemented.

### Rule 3: Deleting a Payment Recalculates the Invoice
When a payment is deleted, the linked invoice's paid amount is reduced by the deleted payment amount, and the invoice status is recalculated. This is enforced when a payment is deleted.

### Rule 4: Payment Modes Are Managed Centrally
The available payment modes (Cash, Cheque, Bank Transfer, UPI, etc.) are managed in a central system configuration. These modes are shared across the entire application and cannot be deleted if they are in use by any payment.

### Rule 5: No Direct Payment Creation
Payments are not created through this screen. Instead, payments are recorded as part of the Invoice creation flow. This means there is no "Create Payment" button or form here.

### Rule 6: No Restore or Permanent Delete
Once a payment is deleted, it cannot be restored or permanently deleted through this screen. Deleted payments are simply hidden from view.

### Rule 7: Safe Deletion with Rollback
When a payment is deleted, the system ensures that the invoice amount recalculation happens safely. If the recalculation fails, the deletion is reversed, and the payment remains unchanged. This protects data integrity between payments and invoices.

### Rule 8: Invoice Balance Is Automatically Computed
The balance (amount still owed) on an invoice is automatically calculated as the invoice total minus the amount paid. This value is always accurate and cannot be manually changed — it updates automatically whenever the paid amount changes.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Rule 1 | Payment amount should not exceed the balance due (not yet enforced) |
| Rule 2 | Bank transfers and UPI need a reference number; Cheque needs a cheque number (not yet enforced) |
| Rule 3 | Deleting a payment recalculates the invoice paid amount and status (enforced) |
| Rule 4 | Payment modes are managed centrally and cannot be removed if in use |
| Rule 5 | Payments are created via Invoice creation, not through this screen |
| Rule 6 | Deleted payments cannot be restored or permanently deleted |
| Rule 7 | Payment deletion is protected — if invoice update fails, deletion is reversed |
| Rule 8 | Invoice balance is automatically computed and cannot be manually changed |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing payment date | "The payment date field is required." |
| Invalid payment date | "The payment date is not a valid date." |
| Missing amount | "The amount field is required." |
| Amount is not a number | "The amount must be a number." |
| Amount less than 0.01 | "The amount must be at least 0.01." |
| Payment mode not selected | "The payment mode field is required." |
| Invalid payment mode | "The selected payment mode is invalid." |
| Status not selected | "The status field is required." |
| Invalid status value | "The selected status is invalid." |
| Invalid bank match value | "The reconciled field must be true or false." |
| Payment not found (view) | "Payment not found." |
| Payment not found (edit) | "Payment not found." |
| Payment not found (delete) | "Payment not found." |
| Deletion fails due to system error | "Failed to delete payment. Please try again." |

---

## Success Scenarios

- An administrator views the payment list filtered by a specific vendor. The system returns a list showing all payments for that vendor with invoice references, amounts, modes, and statuses.

- An administrator edits a payment changing the amount from ₹5,000 to ₹3,000 for a payment linked to an invoice with a total of ₹10,000 and current paid amount of ₹5,000. The system reverts the old ₹5,000 (paid amount becomes ₹0) and applies the new ₹3,000 (paid amount becomes ₹3,000). The invoice status changes from "Fully Paid" to "Partially Paid".

- An administrator marks a payment as matched with the bank statement. The system records that the payment is matched, notes who did it, and stamps the date and time.

- An administrator deletes a payment of ₹2,000 linked to an invoice with a paid amount of ₹6,000 and a total of ₹10,000. The system subtracts ₹2,000 from the paid amount (becomes ₹4,000), the balance automatically updates to ₹6,000, and the invoice status remains "Partially Paid".

---

## Failure Scenarios

- An administrator tries to set the amount to ₹0. The system rejects with "The amount must be at least 0.01."

- An administrator tries to set an invalid status like "PENDING". The system rejects with "The selected status is invalid."

- An administrator tries to access a payment that has been deleted. The system returns "Payment not found."

- An administrator edits a payment and the system encounters an error during invoice recalculation. The entire operation is reversed, the payment remains unchanged, and the system returns an error.

---

## Example Scenario

Mr. Sharma, an Accounts Manager at Sunshine International School, needs to record and manage payments for vendor invoices.

**Recording a Payment (via Invoice Creation):**
He creates an invoice for EduSupplies India for ₹50,000 against a purchase order. During invoice creation, he also records a payment of ₹20,000 via Bank Transfer (reference: NEFT-2024-001). The system creates both the invoice (status: Partially Paid, paid amount = ₹20,000, balance due = ₹30,000) and the payment record (status: Confirmed).

**Viewing Payments:**
Later, he navigates to the Vendor Payment screen and filters by vendor "EduSupplies India". The system shows the ₹20,000 payment with vendor name, invoice reference, Bank Transfer mode, reference number, and Confirmed status.

**Editing a Payment:**
He notices the payment was actually ₹25,000, not ₹20,000. He clicks Edit, changes the amount to ₹25,000, and saves. The system:
1. Reverts ₹20,000 from the invoice paid amount (becomes ₹0)
2. Applies ₹25,000 to the invoice paid amount (becomes ₹25,000)
3. Balance automatically updates to ₹25,000
4. Invoice status remains "Partially Paid"

**Matching with Bank Statement:**
At month-end, the bank statement confirms the NEFT cleared. Mr. Sharma edits the payment, checks "Reconciled", and saves. The system records that the payment is matched with the bank, notes Mr. Sharma as the person who matched it, and stamps the date and time.

**Deleting a Payment:**
He discovers an erroneous payment entry of ₹5,000 that was recorded twice. He deletes the duplicate. The system:
1. Subtracts ₹5,000 from the invoice paid amount
2. Balance automatically updates
3. Invoice status recalculates
4. Payment record is hidden (no longer appears in the list)

---

## Related Screens

- **Vendor Invoice** — Where payments are created; displays payment history
- **Vendor Master** — Vendor directory referenced by payments
- **Vendor Item** — Item catalogue for invoice line items
- **System Configuration / Dropdown Master** — Where payment mode values are managed
- **Bank Reconciliation** — External process that uses the bank match flag

---

## Dependencies

| Module | How It Connects |
|--------|----------------|
| Vendor Payment Core | Stores all payment information (who paid, how much, when, payment mode, status, bank match status) |
| Vendor Invoice | Payments are linked to invoices; changing a payment updates the invoice's paid amount, balance, and status |
| Vendor Master | Stores vendor details referenced by payments |
| System Configuration | Stores payment mode options and user information for who recorded or matched the payment |

---

### Payment Status Flow

```
Initiated → Confirmed (payment cleared in bank)
Initiated → Failed (payment rejected by bank)
Confirmed → Marked as Matched with Bank (after bank statement matching)
```

### Invoice Status After Payment

| Condition | Invoice Status |
|-----------|---------------|
| Nothing paid | Pending |
| Some amount paid (more than zero but less than total) | Partially Paid |
| Full amount paid (equal to or more than total) | Fully Paid |

The balance (amount still owed) is automatically computed as the invoice total minus the amount paid, ensuring the balance always reflects the latest paid amount.
