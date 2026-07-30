# Fine Payments — Business Requirements

## What This Screen Does

The Fine Payments screen is a read-only log of every fine payment collected, whether in cash, card, or online (Razorpay), including full and partial waiver records. It provides an auditable trail of all financial transactions related to fines for accounting reconciliation, receipt verification, and dispute resolution. The screen exists as a tab within the Library Fines hub alongside the main Fines tab.

---

## When This Screen Is Used

- When viewing payment history for a specific fine or member
- When reconciling payment records against cash drawer totals at end of day
- When verifying Razorpay online payment status and transaction IDs
- When reprinting or viewing payment receipt details
- When auditing fine collection activities for accounting purposes

## Default Data Load

This screen displays as a tab within the Library Fines hub (tab id `fine-payments`). The `LibFinePaymentController@index()` redirects to `library.transactionsIndex?tab=fine-payments` which loads all payments via the main operations hub query. Payments are loaded with eager-loaded `fine.member.user` and `receivedBy` relationships, ordered by latest first, paginated at 15 per page. The standalone `show()` route loads a single payment with all relations for detail view.

---

---

## Key Fields at a Glance

**Payment Identity**
Every payment record belongs to exactly one fine (`fine_id` FK to `lib_fines`). The `amount_paid` (DECIMAL 10,2) records how much was collected. Payment method is one of four ENUM values: Cash, Card, Online, Waiver. The `payment_reference` stores the transaction ID (for card), UPI reference (for online), or cheque number.

**Receipt and Date**
The `receipt_number` is a unique, required field (VARCHAR 50) — no two payments can share the same receipt number. The `payment_date` (DATETIME) records when the payment was collected. A unique index `uq_lib_finePayment_receipt` enforces receipt uniqueness at the database level.

**Staff Attribution**
The `received_by_id` FK links to `sys_users` to track which staff member collected the payment. Free-text `notes` (max 1000 chars) allow recording additional context.

---

## Business Rules and Conditions

**Append-Only with Soft Deletes**
Payments are created and viewed but typically not edited or deleted through the standard UI. Soft deletes are supported via dedicated trash/restore/forceDelete endpoints for administrative use.

**Receipt Uniqueness**
Each payment must have a unique receipt number. The validation rule on `LibFinePaymentRequest` ensures uniqueness in `lib_fine_payments.receipt_number`, ignoring the current record on update.

**Auto-Settlement Logic**
When a payment is created via `LibFinePaymentController@store()`, the system checks if sum(payments) + waived >= fine.amount. If fully settled, the fine status automatically transitions to Paid.

**Member Balance Update**
Creating a payment increments the member's `total_fines_paid` and decrements `outstanding_fines`, and updates `last_activity_date`.

**Concurrency Protection**
The `store()` method uses `lockForUpdate()` on the fine row within a database transaction to prevent concurrent payment/waiver from over-collecting on the same fine.

---

## Workflow Steps

**Viewing Payment Records**
The librarian navigates to Library → Fines → Fine Payments tab. The table shows fine reference, member name, amount paid, payment method, reference number, receipt number, payment date, status (Success), and a View button. Clicking View opens a detail page with full payment information including fine details, who collected it, and Razorpay order/payment IDs if applicable.

**Payment Creation (via Fines Screen)**
Payments are not created through the Fine Payments screen directly. They are created through the Fines management workflow: the librarian opens a pending fine, clicks Collect Payment, selects method (Cash/Card/Online/Waiver), enters details, and processes. The system creates the payment record and redirects to the fines tab.

---

## Example Scenario

During the end-of-day reconciliation, the librarian opens the Fine Payments tab to verify that all payments match the cash register. They see 12 payments collected today: 8 cash payments totaling ₹1,240, 2 card payments totaling ₹380, 1 online Razorpay payment of ₹150, and 1 waiver of ₹200. Each payment has a unique receipt number. The librarian cross-references the receipts against the cash drawer and finds a discrepancy — one cash payment of ₹100 has no corresponding receipt. Upon investigation, they find the payment was accidentally recorded under a different receipt number earlier and corrected. The audit trail in the Fine Payments screen confirms the correction with timestamps and staff attribution.

---

## Related Screens

- **Fines** — Payments are created from pending fines in the Fines screen
- **Library Dashboard** — Payment totals contribute to dashboard KPIs
- **Accounting Integration** — Payments feed into accounting via `RemoteEntryService`

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibFinePaymentController`
**Model:** `Modules\Library\Models\LibFinePayment` (table: `lib_fine_payments`, uses `SoftDeletes`)
**Requests:** `LibFinePaymentRequest` (store/update with receipt uniqueness and remaining-balance validation)
**Policy:** `LibFinePaymentPolicy` (permissions match `tenant.lib-fine-payments.*` group in permissionslist.php)
**Route:** Index, show, trashed, restore, forceDelete (no dedicated create/edit routes — payments created via `LibFineController@payment()`)

Key controller methods:
- `index()` — Redirects to `library.transactionsIndex?tab=fine-payments`
- `create()` — Loads fines and users for dropdown (not typically used standalone)
- `store(LibFinePaymentRequest)` — Creates payment in a DB transaction with `lockForUpdate()` on the fine; auto-settles fine status when fully paid; updates member outstanding_fines and total_fines_paid; logs activity
- `show($id)` — Shows payment details with fine.member.user, fine.transaction, and receivedBy relations
- `edit($id)` — Loads payment and fines/users dropdowns
- `update(LibFinePaymentRequest, $id)` — Updates payment with change tracking and activity log
- `destroy($id)` — Soft-deletes payment
- `trashed()` — Lists soft-deleted payments
- `restore($id)` — Restores soft-deleted payment
- `forceDelete($id)` — Permanently deletes with FK constraint error handling
- `toggleStatus($id)` — Returns 404 (not applicable for payments)

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — view all payments, trash operations |
| Librarian Admin | View all payments (payments are created via Fines screen) |
| Librarian Operator | View payments |

All access is gated by `Gate::authorize('tenant.lib-fine-payments.{action}')`.

---

## How This Screen Works — Logic Flow (Non-Technical)

The Fine Payments screen is a read-only log. When a staff member collects a payment on a fine (through the Fines screen), a payment record is automatically created. This screen displays all those payment records in a filterable, paginated table. Each row shows who paid, how much, which method, the receipt number, and who collected it. Clicking View shows the complete payment details including the related fine information. Payments cannot be created or modified directly from this screen — it exists purely for auditing and reconciliation. Receipt numbers are unique, so each payment can be traced back to a physical or digital receipt.

---

## Validate Before Save

**Create / Update (`LibFinePaymentRequest`):**
1. **`fine_id`:** required, integer, exists in `lib_fines.id`
2. **`amount_paid`:** required, numeric, min:0.01
3. **`payment_method`:** required, in: Cash, Card, Online, Waiver
4. **`payment_reference`:** nullable, string, max:100
5. **`payment_date`:** required, date
6. **`received_by_id`:** required, integer, exists in `sys_users.id`
7. **`receipt_number`:** required, string, max:50, unique in `lib_fine_payments.receipt_number` (ignoring current record on update)
8. **`notes`:** nullable, string, max:1000

**Custom Validation (`withValidator`):**
- Checks that `amount_paid` does not exceed the remaining unpaid balance (`fine.amount - totalPaid - waived`)

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Receipt number duplicate | "The receipt number has already been taken." |
| Payment exceeds remaining balance | "Payment amount (₹{amount}) cannot exceed the remaining unpaid balance of ₹{balance}." |
| Fine not found | "The selected fine is invalid." (from `exists` validation) |
| Invalid payment method | "The selected payment method is invalid." (not in Cash/Card/Online/Waiver) |
| FK constraint on force delete | "Cannot delete this record: it is referenced by other records. Remove all dependencies first." |

---

## Success Scenarios

1. A librarian collects ₹50 cash for a late return fine. The system creates a payment record with receipt number "LIB-2025-001", links it to the fine, updates the member's outstanding_fines, and auto-settles the fine as Paid.
2. A member pays a ₹500 lost-book fine via Razorpay. The system creates an online payment record with the Razorpay payment ID and order ID. The fine status transitions to Paid.
3. An accountant reviews the Fine Payments tab at month-end and finds all 203 payments for the month correctly recorded, each with unique receipt numbers and staff attribution.

---

## Failure Scenarios

1. A librarian attempts to enter a payment that exceeds the remaining balance. The custom validator rejects it: "Payment amount (₹600) cannot exceed the remaining unpaid balance of ₹250."
2. A librarian tries to enter a duplicate receipt number. The unique validation on `receipt_number` rejects the entry.
3. Two staff members attempt to process payments for the same fine simultaneously. The `lockForUpdate()` in the store method prevents a double-payment race condition.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_fine_payments` (primary, soft-deletes via `deleted_at`) |
| Library Fines | `lib_fines` (FK `fine_id`; fine status auto-settled on payment) |
| Library Members | `lib_members` (FK via `fine.member_id`; `total_fines_paid`, `outstanding_fines` updated) |
| User / Auth | `sys_users` (FK `received_by_id`) |
| Accounting | `RemoteEntryService::processEvent('LIBRARY', 'LIB_FINE_PAYMENT', ...)` for accounting integration |
