# Payment Details — Business Requirements

## What This Screen Does

The Payment Details screen is where the finance team views, records, and manages all payments made to vendors. While invoice generation happens on the Vendor Invoice screen, every payment transaction — whether it is a partial payment, a full settlement, or a reconciled payment — is recorded and tracked here.

Think of this screen as the vendor payment register. It shows a complete history of every payment the school has made to its vendors, along with payment method, reference number, reconciliation status, and any remarks.

---

## When This Screen Is Used

- Finance team wants to see all payments made to a specific vendor within a selected date range
- Admin wants to check whether a payment is reconciled (confirmed to have reached the vendor's bank)
- Finance needs to review payment history by status — e.g., see only INITIATED or FAILED payments
- A payment was entered incorrectly and needs to be edited or removed
- Finance head wants to audit all payments in a given month for internal review

---

## Key Fields at a Glance

**Payment Date**
The date on which the payment was actually made by the school. This is different from the invoice date or the due date.

**Vendor Name**
The vendor to whom the payment belongs. Linked automatically from the invoice.

**Invoice Number**
The specific invoice against which this payment is being made.

**Amount Paid**
The actual rupee amount paid in this transaction. Multiple payments can be made against a single invoice (partial payments).

**Payment Mode**
How the payment was made — Cash, NEFT, RTGS, UPI, Cheque, or any other mode from the configured dropdown. This is important for reconciliation and audit purposes.

**Reference Number**
The UTR number for NEFT/RTGS, the UPI transaction ID, or the cheque number. This is the proof of payment and is used during bank reconciliation.

**Payment Status**
The current state of the payment:
- **INITIATED** — The payment has been triggered or instructed but not yet confirmed
- **SUCCESS** — The payment has been confirmed as received
- **FAILED** — The payment attempt was unsuccessful and needs to be retried

**Reconciled**
A Yes/No flag indicating whether this payment has been matched against the bank statement. Reconciliation confirms that the amount transferred from the school's bank account matches what the vendor received.
- If Yes → the reconciled date and the person who performed reconciliation are stored
- If No → the payment is outstanding and awaiting bank confirmation

**Paid By**
The system records which logged-in user initiated or recorded the payment entry. This provides an audit trail.

**Remarks**
Any notes about the payment — for example, "Partial payment against invoice INV-123, balance to be paid next month" or "Payment on hold due to vendor dispute."

---

## Business Rules and Conditions

**Payment Amount Cannot Exceed Balance Due**
When recording a payment, the amount entered must not exceed the remaining balance due on the invoice. If the invoice has a net payable of ₹25,000 and ₹10,000 has already been paid, the maximum additional payment that can be recorded is ₹15,000.

**Multiple Payments Per Invoice**
A single invoice can have multiple payment records against it. For example:
- 1st May: ₹10,000 paid → Invoice status becomes Partially Paid
- 15th May: ₹15,000 paid → Invoice status becomes Fully Paid

**Invoice Status Updates Automatically**
When a payment is recorded, the system recalculates the invoice's paid amount and updates the invoice status accordingly:
- If paid amount = 0: Status → Pending
- If 0 < paid amount < net payable: Status → Partially Paid
- If paid amount ≥ net payable: Status → Fully Paid

**Reconciliation Tracking**
When a payment is marked as reconciled at the time of entry, the system automatically records:
- Who reconciled it (the logged-in user)
- When it was reconciled (current timestamp)

If reconciliation is done later (after the initial entry), the payment record can be edited to mark it as reconciled.

**Status Filter for Quick Review**
Finance can filter payments by status — for example, view all INITIATED payments to follow up with the bank, or view all FAILED payments to re-initiate.

**Vendor and Date Range Filters**
Finance can filter payments by selecting a specific vendor and a date range. This helps isolate the payment history for a single vendor for a given month or quarter.

**Soft Delete**
Payments can be deleted if entered in error. Deleted payments are soft-deleted and removed from the active view. The linked invoice's paid amount must be recalculated accordingly when a payment is deleted.

---

## Workflow Steps

**Viewing Payment History**
Finance opens the Payment Details tab, selects a vendor from the dropdown, selects a date range, and clicks Search. All payments made to that vendor in that period are shown in a table.

**Recording a Payment (Done via Vendor Invoice Screen)**
Payments are not added directly from this screen. They are initiated from the Vendor Invoice screen using the "Add Payment" action on a specific invoice. Once saved, the payment appears on this Payment Details screen.

**Editing a Payment**
Finance clicks the Edit option from the Action dropdown on a specific payment row. A modal opens showing all editable fields — date, amount, mode, reference number, status, reconciled flag, and remarks. Admin saves the changes.

**Marking a Payment as Reconciled**
Finance opens the edit modal for a payment, checks the Reconciled toggle, and saves. The system records the reconciliation date and the user who performed it.

**Deleting a Payment**
Finance clicks Delete from the Action dropdown. A confirmation prompt appears. On confirmation, the payment is soft-deleted and the linked invoice's paid amount is updated.

**Pagination**
The payment list is paginated. Finance can navigate through pages if there are many records. The tab filter (payment_details) is preserved across pages.

---

## Example Scenario

The school has paid Sharma Transport Services in two installments for an invoice of ₹21,240:

**Payment 1 — Partial**
- Date: 10 May 2025
- Amount: ₹10,000
- Mode: NEFT
- Reference: UTR123456
- Status: SUCCESS
- Reconciled: Yes (confirmed same day)

Finance records this payment via the Vendor Invoice screen under the Route A invoice. The invoice status changes from Pending to Partially Paid. The balance due is now ₹11,240.

**Payment 2 — Final**
- Date: 25 May 2025
- Amount: ₹11,240
- Mode: UPI
- Reference: UPI789012
- Status: SUCCESS
- Reconciled: No (pending bank statement match)

Finance records the second payment. The invoice status changes to Fully Paid. Balance due becomes ₹0.

Both payment records now appear in the Payment Details screen under Sharma Transport Services for May 2025. Finance head reviews them during month-end audit and marks Payment 2 as reconciled after checking the bank statement.

---

## Related Screens

- **Vendor Invoice** — Payments are initiated from this screen and linked to a specific invoice
- **Vendor Agreement** — The payment terms (due date calculation) are defined in the agreement
- **Vendor Master** — Vendor details (bank account, UPI ID) are referenced during payment processing
