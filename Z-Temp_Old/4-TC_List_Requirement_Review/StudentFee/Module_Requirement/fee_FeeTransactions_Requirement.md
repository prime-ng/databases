# Fee Transactions & Receipts — Business Requirements

## What This Screen Does

The Fee Transactions screen is a read-only ledger of every fee payment recorded against a student invoice. It lets finance staff look up a payment, confirm its mode (cash, cheque, UPI, card, etc.) and status (`Success`, `Pending`, `Failed`, `Refunded`), view the per-head allocation and online gateway audit trail, and download an official PDF receipt for successful transactions. Because the screen is read-only, all payment recording, refunds, and reconciliations happen in other flows (primarily `FeeInvoiceController::recordPayment()`), and this screen only displays the resulting records. It also includes a sibling Fee Receipts tab that lists generated receipts and their delivery status.

---

## When This Screen Is Used

- A parent pays online and the office needs to verify the gateway status and download the receipt.
- A cash or cheque payment is recorded and the accountant wants to confirm the collector, amount, and invoice it was applied to.
- A refund is processed and the finance team needs to see the transaction marked as `Refunded`.
- A parent or auditor asks for a copy of the fee receipt and the staff downloads the PDF.
- The school reconciles daily collections and filters the list by payment mode or status.
- An administrator needs to view the per-head split of a payment across fee heads via `FeeTransactionDetail`.
- A gateway audit is performed and the `FeePaymentGatewayLog` payload is inspected.

---

## Default Data Load

The screen is loaded by `StudentFeeManagementController::payment()` at `GET /student-fee/payment` (route `student-fee.payment`). The tab requires the gate `tenant.student-fee-management.viewAny`.

It loads `FeeTransaction` with the relations `student.user`, `invoice`, and `collector`, ordered by `payment_date` descending and paginated at 15 records per page using the default Laravel `page` query parameter. The page also loads the sibling Fee Receipts tab via `FeeReceipt::with(['transaction.student.user'])`, paginated at 15 records per page using the `receipt_page` parameter.

Default filter values are empty: `search` = `''`, `payment_mode` = `''`, `status` = `''`. Visiting `GET /student-fee/fee-transaction` directly invokes `FeeTransactionController::index()`, which authorizes `tenant.fee-transaction.view` and redirects to the payment tab.

---

## Key Fields at a Glance

**Transaction Identity**

- `transaction_no` — Unique transaction identifier (format `TXN-YYYY-XXXXXX` where `YYYY` is year and `XXXXXX` is zero-padded sequence).
- `student` — Student whose fee was paid; shown via `student.user.name` relation.
- `invoice` — Invoice the payment was applied to; shown via `invoice.invoice_no`.
- `guardian_id` — Optional link to the parent/guardian who made the payment.

**Payment Details**

- `payment_date` — Date and time when the payment was recorded (DATETIME).
- `payment_mode` — Enum: `Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`.
- `payment_reference` — Reference for cheque/DD/online transaction (VARCHAR 100).
- `bank_name` / `cheque_date` — Required for cheque/DD payments.
- `amount` — Total payment amount recorded (DECIMAL 12,2).
- `fine_adjusted` / `concession_adjusted` — Fine or concession applied in this transaction (DECIMAL 10,2 each).

**Status and Tracking**

- `status` — `Success`, `Pending`, `Failed`, `Refunded`. Default is `Pending`.
- `collected_by` — Staff member who collected/recorded the payment (FK to `sys_users`, NOT NULL).
- `receipt_generated` — Boolean flag indicating if receipt PDF exists.
- `receipt_id` — Optional link to `fee_receipts` row.

**Related Data**

- `FeeTransactionDetail` rows — Per-head split: fee head, amount, fine amount, concession amount. Unique per `(transaction_id, head_id)`.
- `FeePaymentGatewayLog` — Online gateway trace: gateway name, gateway transaction/order/payment IDs, request/response payloads (JSON), status, error message, IP address, user agent.
- `FeeReceipt` — Generated receipt number, date, format (`Standard`, `Detailed`, `Tax Invoice`), sent-to-parent status, and delivery method.

---

## Business Rules and Conditions

**Read-Only Nature**

This feature is exclusively read-only via `FeeTransactionController`. Only `index()`, `show()`, and `downloadReceipt()` methods are registered. No create, update, or delete routes exist for transactions. All data mutations occur through `FeeInvoiceController::recordPayment()`, online gateway callbacks, and refund flows.

**Status Values**

The system supports exactly four statuses as defined in the DDL: `Success`, `Pending`, `Failed`, and `Refunded`.

**Receipt Download Availability**

The UI renders a PDF download button only when `status === 'Success'`. The receipt is generated on demand if it does not already exist. When no receipt exists, `downloadReceipt()` auto-creates a `FeeReceipt` inside a `DB::transaction()`, updates the transaction's `receipt_generated` and `receipt_id`, and then returns the PDF.

> **Note:** `downloadReceipt()` does not enforce a status check itself. The UI hides the button for non-Success transactions, but a direct URL hit could still generate a receipt for a `Pending` or `Failed` transaction.

**Receipt Number Format**

Auto-generated as `RCP-YYYY-XXXXX` where `YYYY` is the current year and `XXXXX` is zero-padded (`FeeReceipt::max('id') + 1`) to 5 digits.

**Receipt Formats**

Three formats are defined in the DDL: `Standard` (basic receipt), `Detailed` (per-head breakdown), and `Tax Invoice` (includes tax breakup). The current auto-generation always creates `Standard` format.

**Payment Mode Values**

The DDL and view filter define the authoritative list: `Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`.

> **Note:** The original requirement document listed `Online` and `Bank Transfer` modes which differ from the DDL.

**Effective Amount Computation**

The effective amount of a transaction is `amount + fine_adjusted - concession_adjusted`. The effective amount of a detail line is `amount + fine_amount - concession_amount`.

**Payment Side Effects**

- `FeeTransaction::markSuccessful()` calls `invoice->updatePayment($this->amount)` to update the linked invoice.
- `FeeTransaction::markRefunded()` calls `invoice->deductPayment($this->amount)` to reverse the payment.

**Soft Deletes**

`FeeTransaction` uses the `SoftDeletes` trait, but no restore UI is exposed since the screen is read-only.

---

## Workflow Steps

**1. Open the Payment tab.** The user navigates to `Student Fee → Payment`. The default active tab is `Fee Transactions` and the list loads with the most recent payments first.

**2. Search or filter.** The user enters a transaction number or student name in the search box, chooses a payment mode from the dropdown, or chooses a status (`Success`, `Pending`, `Failed`, `Refunded`), then clicks `Search`. The grid reloads with the matching records and preserves the query string in pagination links.

**3. View a transaction.** The user clicks a transaction row. The system opens the transaction detail page (`GET /student-fee/fee-transaction/{id}`) showing the student, invoice, payment details, amount summary, receipt info, and record info.

**4. Download a receipt.** If the transaction status is `Success`, the detail page shows a `Download Receipt` button. Clicking it calls `FeeTransactionController::downloadReceipt($id)`. If no `FeeReceipt` record exists, the controller creates one inside a database transaction, updates the transaction's `receipt_generated` and `receipt_id`, and then renders and downloads the PDF (`receipt-{receipt_no}.pdf`).

---

## Example Scenario

Aryan Sharma's invoice `INV-2026-0045` has a balance of ₹25,000. His father pays ₹10,000 online through the school's payment gateway. The payment recording flow creates a `FeeTransaction` with `transaction_no = TXN-202604-0012`, `payment_mode = UPI`, `amount = 10000.00`, and `status = Success`. It also stores a `FeePaymentGatewayLog` with `gateway_name = Razorpay` and the gateway transaction ID.

The next day, the accountant opens `Student Fee → Payment`, searches for "Aryan", and sees the transaction in the list. She clicks the transaction to open the detail page and then clicks `Download Receipt`. Since no receipt exists yet, the system creates `FeeReceipt` with `receipt_no = RCP-2026-00045` and downloads the PDF. The receipt shows Aryan's name, the invoice number, the UPI mode, the amount, and a success badge.

---

## Related Screens

- **Fee Receipts** — sibling tab on the same Payment page; lists generated receipts and their sent-to-parent status.
- **Fee Invoices** — source of the invoice number, balance, and the payment recording flow that creates transactions.
- **Fee Student Assignment** — links the student to the academic session and fee structure that the invoice is based on.
- **Fee Cheque / DD Reconciliation** — handles clearing or bouncing cheque/DD transactions that originated here.
- **Fee Refund** — creates refunded transactions shown in this ledger.
- **Fee Fine Transaction** — fine transactions that may be linked to the invoice shown here.

---

## Requirements

- The Payment tab grid is loaded by `StudentFeeManagementController::payment()` at `GET /student-fee/payment` (`student-fee.payment`).
- `FeeTransactionController::index()` at `GET /student-fee/fee-transaction` authorizes `tenant.fee-transaction.view` and redirects to `student-fee.payment`.
- `FeeTransactionController::show($id)` at `GET /student-fee/fee-transaction/{fee_transaction}` authorizes `tenant.fee-transaction.view`, uses `FeeTransaction::with(['student.user','invoice','collector'])->findOrFail($id)`, loads the linked receipt via `FeeReceipt::where('transaction_id', $id)->first()`, and renders `studentfee::fee-transaction.show`.
- `FeeTransactionController::downloadReceipt($id)` at `GET /student-fee/fee-transaction/{id}/receipt` authorizes `tenant.fee-transaction.view`, loads the transaction with `student.user`, `invoice.studentAssignment.feeStructure`, and `collector`, auto-creates a `FeeReceipt` inside a `DB::transaction()` if none exists (with `receipt_no = RCP-YYYY-XXXXX`, `receipt_format = FeeReceipt::FORMAT_STANDARD`, `sent_to_parent = false`), updates the transaction's `receipt_generated` and `receipt_id`, renders `studentfee::fee-transaction.receipt-pdf` via `Barryvdh\DomPDF\Facade\Pdf`, and returns a PDF download.
- Models involved are `FeeTransaction` (`fee_transactions`), `FeeTransactionDetail` (`fee_transaction_details`), `FeePaymentGatewayLog` (`fee_payment_gateway_logs`), and `FeeReceipt` (`fee_receipts`).
- `FeeTransaction` uses the `SoftDeletes` trait and defines status constants `STATUS_SUCCESS`, `STATUS_PENDING`, `STATUS_FAILED`, `STATUS_REFUNDED`.
- No form request classes are used by this read-only screen.
- The policy class is `Modules\StudentFee\Policies\FeeTransactionPolicy`. It defines all standard permission methods, but only `tenant.fee-transaction.view` is actually invoked by the controller methods covered by this screen.
- The resource route is defined as `Route::resource('fee-transaction', FeeTransactionController::class)->only(['index', 'show']);` plus the custom receipt route.
- The route `POST /student-fee/fee-invoice/{fee_invoice}/record-payment` (in `FeeInvoiceController`) is the entry point for creating transactions, not this screen.

---

## Who Can Access

| Gate / Permission | Methods | Notes |
|---|---|---|
| `tenant.student-fee-management.viewAny` | `StudentFeeManagementController::payment()` | Required to open the Payment tab. |
| `tenant.fee-transaction.view` | `FeeTransactionController::show()` and `downloadReceipt()` | Required to view a transaction and download its receipt. |
| `tenant.fee-transaction.view` | `FeeTransactionController::index()` | Only used to authorize the redirect to the payment tab. |
| `FeeTransactionPolicy` | Policy wrapper | Defines `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `status`, `emailSchedule`, `remark`, and `pdf`. |

---

## Logic Flow

**1. Page load.** The user opens the Payment tab. `StudentFeeManagementController::payment()` authorizes `tenant.student-fee-management.viewAny`, builds a `FeeTransaction` query with optional `search`, `payment_mode`, and `status` filters, orders by `payment_date` descending, paginates 15 records per page, and renders `studentfee::payment`. The view includes `fee-transaction.index`, which renders the active `Fee Transactions` pane and the filter form.

**2. Show transaction.** `FeeTransactionController::show($id)` authorizes `tenant.fee-transaction.view`, fetches the transaction via `findOrFail` with eager-loaded `student.user`, `invoice`, and `collector`, fetches the first linked `FeeReceipt`, and renders `studentfee::fee-transaction.show`. The view uses null-safe operators (`??`) for optional relationships and conditionally shows the `Download Receipt` button only for `Success` status.

**3. Download receipt.** `FeeTransactionController::downloadReceipt($id)` authorizes `tenant.fee-transaction.view`, fetches the transaction with eager-loaded relations. If no linked `FeeReceipt` exists, it creates a receipt number `RCP-{YYYY}-{XXXXX}` (padded to 5 digits using `FeeReceipt::max('id') + 1`), creates a `FeeReceipt` inside a `DB::transaction()` with `receipt_format = FeeReceipt::FORMAT_STANDARD` and `sent_to_parent = false`, updates the transaction's `receipt_generated` to `true` and `receipt_id` to the new receipt id, commits the transaction, loads the PDF view (`studentfee::fee-transaction.receipt-pdf`), and returns a download response.

**4. No save path.** This screen has no create, edit, update, or delete actions. All data mutations are performed by external payment recording flows (`FeeInvoiceController::recordPayment()`, online gateway callbacks, refund flows).

---

## Validate Before Save

Not applicable — this screen has no save action.

---

## Error Handling and Validation Messages

| Scenario | Message / Behavior | Type |
|---|---|---|
| Missing `tenant.student-fee-management.viewAny` on payment tab | HTTP 403 from `Gate::authorize`. | Authorization |
| Missing `tenant.fee-transaction.view` on show/receipt | HTTP 403 from `Gate::authorize`. | Authorization |
| Requested transaction id does not exist | HTTP 404 from `findOrFail`. | Controller check |
| Receipt download for a non-existent transaction | HTTP 404 from `findOrFail`. | Controller check |
| No transactions match the search/filter | The grid shows `No transactions found.` | Empty state |

No custom validation messages are defined for this screen because it has no form submissions.

---

## Success Scenarios

**SC-001 — Payment tab loads.** The user opens `Student Fee → Payment`. The Fee Transactions tab is active and displays the 15 most recent transactions ordered by payment date.

**SC-002 — Search by transaction number.** The user enters `TXN-202604-0012` in the search box and clicks `Search`. The grid reloads showing only the transaction whose `transaction_no` contains the entered text.

**SC-003 — Search by student name.** The user enters "Aryan" in the search box and clicks `Search`. The grid reloads showing transactions whose student's user name contains "Aryan".

**SC-004 — Filter by payment mode.** The user selects `UPI` from the payment mode dropdown and clicks `Search`. The grid shows only UPI transactions.

**SC-005 — Filter by status.** The user selects `Success` from the status dropdown and clicks `Search`. The grid shows only successful transactions.

**SC-006 — Download receipt.** The user opens a `Success` transaction and clicks `Download Receipt`. A PDF named `receipt-RCP-2026-00045.pdf` is downloaded. If no receipt existed, the system creates it first inside a database transaction.

**SC-007 — Empty state.** When no transactions exist, the tab displays `No transactions found.`

---

## Failure Scenarios

**FC-001 — User lacks permission to open the Payment tab.** A user without `tenant.student-fee-management.viewAny` hits `GET /student-fee/payment`. The request returns HTTP 403.

**FC-002 — User lacks permission to view a transaction.** A user without `tenant.fee-transaction.view` hits `GET /student-fee/fee-transaction/123`. The request returns HTTP 403.

**FC-003 — Transaction not found.** The user requests `GET /student-fee/fee-transaction/999999`. Because the id does not exist, `findOrFail` throws a 404.

**FC-004 — Receipt download for missing transaction.** The user requests `GET /student-fee/fee-transaction/999999/receipt`. The controller returns HTTP 404.

**FC-005 — SQL injection attempt.** A malicious search string is entered. The query is escaped via parameterized query and returns no results without error.

---

## Dependencies module and tables

| Dependency | Type | Details |
|---|---|---|
| `std_students` | FK parent | `fee_transactions.student_id` → `std_students.id` (`ON DELETE RESTRICT`). |
| `fee_invoices` | FK parent | `fee_transactions.invoice_id` → `fee_invoices.id` (`ON DELETE RESTRICT`). |
| `std_guardians` | FK parent | `fee_transactions.guardian_id` → `std_guardians.id` (`ON DELETE SET NULL`). |
| `sys_users` | FK parent | `fee_transactions.collected_by` → `sys_users.id` (`ON DELETE RESTRICT`). |
| `fee_transaction_details` | Child table | `transaction_id` → `fee_transactions.id` (`ON DELETE CASCADE`). |
| `fee_payment_gateway_logs` | Child table | `transaction_id` → `fee_transactions.id` (`ON DELETE SET NULL`). |
| `fee_receipts` | Child table | `transaction_id` → `fee_transactions.id` (`ON DELETE RESTRICT`). |
| `Modules\StudentFee\Models\FeeInvoice` | Cross-module consumer | `markSuccessful()` calls `invoice->updatePayment()`; `markRefunded()` calls `invoice->deductPayment()`. |
| `Barryvdh\DomPDF\Facade\Pdf` | Service | Used by `downloadReceipt()` for PDF generation. |

> **Note:** The code model `FeeTransaction::guardian()` belongs to `Modules\SchoolSetup\Models\User` (likely `sys_users`), but the consolidated DDL declares the `guardian_id` FK against `std_guardians`. The model also lacks a defined `receipt()` relationship even though `receipt_id` is stored in the table.
>
> **Note:** `collected_by` is declared `NOT NULL` in the DDL, whereas the original requirement doc listed it as nullable. The `downloadReceipt()` logic uses `transaction->collector->name` with a null-safe fallback (`??`), so the controller is defensive, but the schema requires a collector for every row.
>
> **Note:** The original requirement doc listed payment modes as `Cash`, `Cheque`, `Online`, `DD`, `Bank Transfer`. The DDL and the view filter dropdown use `Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`. The code is the authoritative set.
>
> **Note:** `fee_transactions.payment_reference` DDL length is `VARCHAR(100)`, while the original requirement doc listed `VARCHAR(255)`.
>
> **Note:** The index view renders generic `<x-backend.table.action>` which produces edit/delete links, but the controller only exposes `index`, `show`, and `downloadReceipt`. Those action links would lead to 404/405 errors if clicked.

**Table:** `fee_transactions`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | PK, auto-increment. |
| `transaction_no` | VARCHAR(50) | NOT NULL, UNIQUE. |
| `student_id` | INT UNSIGNED | NOT NULL, FK → `std_students.id` (`ON DELETE RESTRICT`), index `idx_transaction_student`. |
| `invoice_id` | INT UNSIGNED | NOT NULL, FK → `fee_invoices.id` (`ON DELETE RESTRICT`). |
| `guardian_id` | INT UNSIGNED | NULL, FK → `std_guardians.id` (`ON DELETE SET NULL`). |
| `payment_date` | DATETIME | NOT NULL. |
| `payment_mode` | ENUM | NOT NULL: `Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`. |
| `payment_reference` | VARCHAR(100) | NULL, comment "Cheque/DD/Transaction ID". |
| `bank_name` | VARCHAR(100) | NULL. |
| `cheque_date` | DATE | NULL. |
| `amount` | DECIMAL(12,2) | NOT NULL. |
| `fine_adjusted` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| `concession_adjusted` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| `status` | ENUM | NOT NULL, DEFAULT `Pending`: `Success`, `Pending`, `Failed`, `Refunded`. |
| `collected_by` | INT UNSIGNED | NOT NULL, FK → `sys_users.id` (`ON DELETE RESTRICT`). |
| `remarks` | TEXT | NULL. |
| `receipt_generated` | TINYINT(1) | NOT NULL, DEFAULT `0`. |
| `receipt_id` | INT UNSIGNED | NULL, no FK constraint in DDL. |
| `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |
| `deleted_at` | TIMESTAMP | NULL, enables soft deletes. |

**Table:** `fee_transaction_details`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | PK, auto-increment. |
| `transaction_id` | INT UNSIGNED | NOT NULL, FK → `fee_transactions.id` (`ON DELETE CASCADE`). |
| `head_id` | INT UNSIGNED | NOT NULL, FK → `fee_head_master.id` (`ON DELETE RESTRICT`). |
| `amount` | DECIMAL(10,2) | NOT NULL. |
| `fine_amount` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| `concession_amount` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |
| `uq_trans_detail` | UNIQUE KEY | (`transaction_id`, `head_id`). |

**Table:** `fee_payment_gateway_logs`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | PK, auto-increment. |
| `transaction_id` | INT UNSIGNED | NULL, FK → `fee_transactions.id` (`ON DELETE SET NULL`). |
| `gateway_name` | ENUM | NOT NULL: `Razorpay`, `Paytm`, `CCAvenue`, `BillDesk`, `Other`. |
| `gateway_transaction_id` | VARCHAR(100) | NULL, index `idx_gateway_trans`. |
| `order_id` | VARCHAR(100) | NULL, index `idx_gateway_order`. |
| `payment_id` | VARCHAR(100) | NULL. |
| `request_payload` | JSON | NULL. |
| `response_payload` | JSON | NULL. |
| `amount` | DECIMAL(12,2) | NOT NULL. |
| `status` | VARCHAR(50) | NOT NULL, index `idx_gateway_status`. |
| `error_message` | TEXT | NULL. |
| `ip_address` | VARCHAR(45) | NULL. |
| `user_agent` | TEXT | NULL. |
| `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |
