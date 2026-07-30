# Fines — Business Requirements

## What This Screen Does

The Fines screen manages all library fines imposed on members for overdue, lost, or damaged books. Fines are created automatically when a book is returned late or marked as lost, or manually by librarians for other charges. The screen supports the complete fine lifecycle: creation, calculation, payment collection (cash, card, online via Razorpay), waiver, status tracking, and deletion. Outstanding fines are tracked on the member record and can block further borrowing. This screen lives within the Library Fines hub alongside the Fine Payments tab.

---

## When This Screen Is Used

- When a member returns a book late — the fine is calculated and displayed during check-in
- When a member wants to pay their outstanding fine at the library counter
- When the librarian wants to waive a fine (partial or full waiver)
- When a member pays online via Razorpay for a pending fine
- When viewing all fines filtered by status (Pending, Paid, Waived, Overdue), fine type, or member

## Default Data Load

This screen displays as a standalone page loaded by `LibraryController@finesIndex()`. All fines are loaded with eager-loaded `transaction.copy.book`, `digitalTransaction.book`, `member.user`, `waivedBy`, `fineType`, `statusMaster`, and `payments` relationships, ordered by latest first, paginated at 15 per page. Fines include soft-deleted records (`withTrashed()`). Filters available for search (member name or book title), status (by `lib_library_status_masters.id`), fine type, and member.

---

---

## Key Fields at a Glance

**Transaction Source**
Every fine originates from either a Physical transaction (`lib_transactions`) or a Digital transaction (`lib_digital_access_transactions`), identified by `transaction_type` (ENUM: Digital, Physical). The corresponding FK links to the specific transaction that caused the fine. The `member_id` FK identifies the member responsible.

**Fine Calculation**
The `amount` (DECIMAL 10,2) is the total fine assessed. For late returns, `days_overdue` captures the overdue days (after grace period), and `calculated_from` / `calculated_to` define the overdue period. The `fine_slab_config_id` FK links to the slab configuration used for calculation, and `calculation_breakdown_json` stores the detailed JSON breakdown (slab range, rate per day, max fine applied, etc.). The `fine_type` FK references `lib_fine_type` (e.g., LateReturn, LostBook, DamagedBook).

**Status Tracking**
The `status` FK references `lib_library_status_masters` with status type "Fine Status". Possible values: Pending, Paid, Waived, Overdue. Status transitions are: Pending → Paid (via payment or markPaid), Pending → Waived (partial or full), Pending → Overdue (scheduled job). Only Pending and Overdue fines can receive payments.

**Waiver Management**
Partial or full waivers are tracked via `waived_amount`, `waived_by_id` (FK to `sys_users`), `waived_reason`, and `waived_at`. The computed `payable_amount` accessor = `amount - waived_amount` (never negative). A fine is considered fully waived when `waived_amount >= amount`.

---

## Business Rules and Conditions

**Status Transition Rules**
- Only Pending or Overdue fines can be marked as Paid or Waived
- Once Paid, a fine cannot be modified or waived
- The `toggleStatus()` method returns 404 — status is not toggled via the standard toggleStatus route; it transitions through dedicated methods (markPaid, waive, payment)

**Payment and Outstanding Balance**
When a fine is created, the member's `outstanding_fines` is incremented by the fine amount. When a payment is recorded and fine is marked paid, outstanding_fines is decremented. When a fine is waived, outstanding_fines is decremented by the waived amount. When a pending or overdue fine is deleted, outstanding_fines is decremented by the payable amount.

**Grace Period**
The fine calculation respects the membership type's `grace_period_days`. The effective overdue days = max(0, raw overdue days - grace period days). If the effective overdue is 0 or negative, no fine is applied.

**Slab-Based Calculation**
Fine calculation uses the `LibFineSlabConfig` matched by `membership_type_id`, `resource_type_id`, and `fine_type_id` (LateReturn). Within the slab config, `LibFineSlabDetail` determines the rate per day based on the overdue day range. A `max_fine_amt` cap on the slab config limits the total fine. If no slab config matches, the membership type's default `fine_rate_per_day` is used.

**Financial Reporting Integration**
Payments are forwarded to the Accounting module via `RemoteEntryService::processEvent()` with event type `LIB_FINE_PAYMENT` for automated accounting ledger entries.

**Online Payment (Razorpay)**
Pending fines can be paid online via Razorpay. The `razorpayInitiate()` method creates a payment order, and `razorpayCallback()` verifies the signature, records the payment, and marks the fine as paid in a database transaction with row-level locking to prevent race conditions.

---

## Workflow Steps

**Fine Creation (Automatic via Return)**
When a member returns a book, the `LibTransactionController@returnBook()` method calls `calculateFine()` on the transaction. The system checks if the due date + grace period is past. If so, it calculates the fine using slab configs or default rate. The librarian can preview the fine amount before confirming and optionally override it.

**Manual Fine Creation**
The librarian navigates to Fines and clicks Create Fine. They select the transaction type (Physical/Digital), member, fine type, and enter the amount and overdue details. On save, the system increments the member's outstanding_fines.

**Payment Collection**
The librarian clicks the payment button on a pending fine. A modal opens showing the fine amount, payable amount (after waivers), and remaining balance. The librarian selects payment method (Cash, Card, Online, or Waiver), enters reference details and receipt number, and processes the payment. The system creates a LibFinePayment record, decrements outstanding_fines, and transitions the fine status to Paid when sum(payments) + waived >= amount.

**Waiver Processing**
The librarian clicks the waive button on a pending fine. A waiver form opens showing the fine amount. The librarian enters the waived amount (partial or full) and reason. On save, the system decrements outstanding_fines and transitions to Waived status (if full waiver) or keeps as Pending (if partial waiver).

---

## Example Scenario

Member Raj returns "The Great Gatsby" 15 days late. His Premium membership has a 3-day grace period. The system calculates 12 effective overdue days. The slab config for Premium members charges ₹5/day for days 1–10 and ₹8/day for days 11–20. The fine is ₹50 (10×5) + ₹16 (2×8) = ₹66. The librarian shows Raj the breakdown. Raj pays ₹50 cash and requests a partial waiver for the remaining ₹16 due to a genuine medical reason. The librarian enters ₹16 as waived amount with reason "Medical emergency — doctor's note on file." The outstanding balance is settled, and the fine status transitions to Paid (via payment) with a partial waiver.

---

## Related Screens

- **Fine Payments** — Adjacent tab showing all fine payment records
- **Transactions** — The borrowing transaction that triggered the fine
- **Members** — Member record displays outstanding_fines balance
- **Fine Slab Configs** — Defines the rate structure used for fine calculation
- **Fine Types** — Defines fine categories (Late Return, Lost Book, Damaged Book, Processing Fee)
- **Dashboard** — Fine collection KPIs on the library master dashboard

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibFineController`
**Model:** `Modules\Library\Models\LibFine` (table: `lib_fines`, uses `SoftDeletes`, implements `Payable`)
**Requests:** `LibFineRequest` (store/update validation), `LibFineWaiveRequest` (waive validation)
**Policy:** `LibFinePolicy` (permissions match `tenant.lib-fines.*` group in permissionslist.php — includes extra `waive` action)
**Route:** Resource route `Route::resource('lib-fines', LibFineController::class)` + trashed/restore/forceDelete/toggleStatus/markPaid/waivePage/waive/payment/razorpayInitiate/razorpayCallback

Key controller methods:
- `index()` — Redirects to `library.finesIndex` tab
- `create()` — Loads members, transactions, digital transactions, fine slab configs for dropdowns
- `store(LibFineRequest)` — Creates fine; increments member's outstanding_fines; logs activity
- `show($id)` — Shows fine details with all relations (transaction, digitalTransaction, member, waivedBy, statusMaster, payments, fineSlabConfig)
- `edit($id)` — Loads fine and dropdowns for editing; only pending fines can be edited
- `update(LibFineRequest, $id)` — Validates only pending status; updates fine amount including outstanding_fines diff; logs activity
- `destroy($id)` — Soft-deletes; decrements outstanding_fines if pending/overdue
- `trashed()` — Lists soft-deleted fines with relations
- `restore($id)` — Restores soft-deleted fine; re-increments outstanding_fines if pending/overdue
- `forceDelete($id)` — Permanently deletes
- `toggleStatus($id)` — Returns 404 (not applicable for fines)
- `markPaid($id)` — Marks fine as paid after validating pending/overdue status
- `waivePage($id)` — Shows waiver form for pending fines
- `waive(LibFineWaiveRequest, $id)` — Processes full or partial waiver
- `payment(Request, $id)` — Records manual payment (cash/card); integrates with RemoteEntryService for accounting; marks fine paid when balance settled
- `razorpayInitiate($id)` — Initiates Razorpay payment for pending fine
- `razorpayCallback(Request, $id)` — Verifies Razorpay signature; creates payment record; marks fine paid (row-level locking to prevent race conditions)
- `calculate($transactionId)` — AJAX endpoint calculating fine for a transaction: checks grace period, slab configs, default rate; returns breakdown JSON

---

## Who Can Access This Screen

| Role | Access Level |
|---|---|
| Super Admin | Full access — all CRUD + payment + waiver + trash |
| Librarian Admin | Full access — create, edit, payment, waiver, delete, restore |
| Librarian Operator | View, collect payments, create fines |
| Librarian (view only) | View fines only |

All access is gated by `Gate::authorize('tenant.lib-fines.{action}')`. The `waive` action uses a dedicated `tenant.lib-fines.waive` permission (defined in permissionslist.php).

---

## How This Screen Works — Logic Flow (Non-Technical)

The Fines screen shows a table of all fines for all members. Each row shows the member name, fine type (e.g., Late Return, Lost Book), the book title, the fine amount, amount paid/waived, current status (Pending, Paid, Waived), and action buttons. The librarian can search by member name or book title, and filter by status, fine type, or member. For pending fines, a "Collect Payment" button opens a modal where the librarian selects the payment method (Cash/Card/Online/Waiver), enters the payment reference and receipt number, and processes the transaction. A "Waive" button opens a waiver form for partial or full forgiveness. Fines marked as Lost automatically trigger a replacement cost fine. Every payment or waiver updates the member's outstanding fines balance. Online payments via Razorpay generate a payment link that the member can use to pay through their own device.

---

## Validate Before Save

**Create / Update (`LibFineRequest`):**
1. **`transaction_type`:** required, in: Digital, Physical
2. **`transaction_id`:** nullable, exists in `lib_transactions.id` (required when transaction_type=Physical)
3. **`digital_transaction_id`:** nullable, exists in `lib_digital_access_transactions.id` (required when transaction_type=Digital)
4. **`member_id`:** required, exists in `lib_members.id`
5. **`fine_type_id`:** required, integer, exists in `lib_fine_type.id`
6. **`amount`:** required, numeric, min:0
7. **`days_overdue`:** nullable, integer, min:0
8. **`calculated_from`:** nullable, date
9. **`calculated_to`:** nullable, date, after_or_equal:calculated_from
10. **`fine_slab_config_id`:** nullable, exists in `lib_fine_slab_config.id`
11. **`notes`:** nullable, string, max:500
12. **`status`:** nullable (create) / required (update), exists in `lib_library_status_masters.id`

**Payment (`LibFineController@payment()`):**
1. **`amount_paid`:** required, numeric, min:0.01, max: payable_amount
2. **`payment_method`:** required, string
3. **`payment_reference`:** nullable, string, max:255
4. **`payment_date`:** required, date
5. **`receipt_number`:** required, string, max:100, unique in `lib_fine_payments`
6. **`notes`:** nullable, string, max:1000

**Waive (`LibFineWaiveRequest`):**
1. **`waived_amount`:** required, numeric, min:0, max: fine amount
2. **`waived_reason`:** nullable, string, max:1000

---

## Error Handling and Validation Messages

| Condition | Message |
|---|---|
| Fine not found | 404 — "Fine not found" |
| Non-pending edit | "Only pending fines can be updated." |
| Non-pending payment | "Only pending fines can receive payment." |
| Non-pending waive | "Only pending fines can be waived." |
| Payment exceeds payable | "Payment amount exceeds the remaining payable balance of ₹{balance}." |
| Duplicate receipt number | "The receipt number has already been taken." |
| Razorpay verification failed | "Payment verification failed." |
| Fine already processed (concurrent) | "Fine already processed." (from DB transaction with lockForUpdate) |

---

## Success Scenarios

1. A member returns a book 10 days overdue. The system calculates a fine of ₹50 using the slab config for their membership type. The librarian collects ₹50 cash, enters receipt number, and processes payment. The fine status changes to Paid, and outstanding_fines is decremented.
2. A librarian waives a ₹200 fine in full due to a library system error. The waiver form records the reason "System error — book was renewed but renewal was not logged." The fine status changes to Waived, and outstanding_fines is decremented by ₹200.
3. A member pays a ₹150 fine online via Razorpay. The Razorpay callback verifies the signature, creates a LibFinePayment record, and marks the fine as Paid in a single database transaction.

---

## Failure Scenarios

1. A librarian attempts to collect payment for a fine that was already paid. The system checks the status and rejects the request: "Only pending fines can receive payment."
2. Two librarians simultaneously attempt to process payment for the same fine. The `lockForUpdate()` in the `razorpayCallback()` prevents the race condition — one succeeds, the other gets "Fine already processed."
3. A librarian attempts to edit a fine that has already been paid. The update method checks `$fine->status !== $pendingId` and returns an error.
4. The Razorpay signature verification fails due to tampering. The payment is marked as failed, and no fine status change occurs.

---

## Dependencies module and tables

| Module | Tables |
|---|---|
| Library Core | `lib_fines` (primary, soft-deletes via `deleted_at`) |
| Library Fines Sub | `lib_fine_payments` (FK `fine_id`), `lib_fine_type` (FK `fine_type`), `lib_fine_slab_config` (FK `fine_slab_config_id`), `lib_fine_slab_details` |
| Library Transactions | `lib_transactions` (FK `transaction_id`), `lib_digital_access_transactions` (FK `digital_transaction_id`) |
| Library Members | `lib_members` (FK `member_id`; `outstanding_fines` updated on events) |
| Library Status | `lib_library_status_masters` (FK `status`, status_type = 'Fine Status') |
| User / Auth | `sys_users` (FK `waived_by_id`) |
| Accounting | `RemoteEntryService` for `LIB_FINE_PAYMENT` accounting entries |
| Payment (Module) | Razorpay integration via `PaymentService` and `GatewayManager` |
| Student Profile | `Student` model for student_id lookup in accounting integration |
