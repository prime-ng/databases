# Fee Invoice — Business Requirements

## What This Screen Does

The Fee Invoice screen is used to create, publish, and manage student fee invoices. An invoice captures the base fee amount, any concession, fine, or tax adjustments, and produces a total due amount. It also tracks how much has been paid and the remaining balance via a database-generated column (`balance_amount = total_amount - paid_amount`). Staff can generate invoices manually for a single student assignment, record cash or offline payments, download a PDF, print the invoice, cancel an invoice, send it via email or WhatsApp, and trigger a background job that generates invoices in bulk for the current academic session. The `FeeInvoice` model implements `Modules\Payment\Contracts\Payable` for payment gateway integration.

---

## When This Screen Is Used

- A finance officer needs to create a one-time or installment invoice for an active student fee assignment.
- The billing team wants to search or filter invoices by invoice number, student name, or status.
- A payment is collected offline and must be recorded against an invoice.
- An invoice needs to be cancelled with a reason before it is paid.
- A printed or PDF copy of the invoice is needed for sharing with the parent or student.
- An invoice must be emailed to the parent or shared via WhatsApp.
- At the start of a fee cycle the team triggers bulk invoice generation for all eligible assignments in the current session.
- An administrator needs to restore or permanently delete a soft-deleted invoice from trash.

---

## Default Data Load

The tab is loaded by the billing parent route: `GET /student-fee/billing` (route `student-fee.billing`), rendered by `StudentFeeManagementController::billing()` lines 317–343. The controller loads the current academic session and then queries `FeeInvoice::with(['studentAssignment.student.user', 'installment'])` filtered by the current session, optional `search` (invoice number or student name), and optional `status`. Results are paginated at 15 records per page with `page` parameter and preserved query strings (`withQueryString()`). The view `resources/views/fee-invoice/index.blade.php` renders the grid in card view by default and includes a list view toggle with `localStorage` persistence.

---

## Key Fields at a Glance

**Identity and Tracking**

- `invoice_no` — Auto-generated unique identifier in format `INV-YYYY-XXXXX` (year + zero-padded sequence).
- `student_assignment_id` — Links the invoice to an active student fee assignment.
- `installment_id` — Optional link to a fee installment; `NULL` for one-time payments.
- `generated_by` — The staff user who created or generated the invoice (FK to `sys_users`, `ON DELETE RESTRICT`).
- `cancelled_by` / `cancellation_reason` — Captured when an invoice is cancelled.

**Financial Breakdown**

- `base_amount` — Starting amount for the invoice (auto-populated from the assignment's `total_fee_amount` via `data-base` attribute).
- `concession_amount` — Approved concession or discount applied (manual input in current implementation).
- `fine_amount` — Late or other fine amount applied (manual input in current implementation).
- `tax_amount` — Tax amount applied (manual input in current implementation).
- `total_amount` — Computed as `base_amount - concession_amount + fine_amount + tax_amount`.
- `paid_amount` — Cumulative payment recorded against the invoice.
- `balance_amount` — Stored generated column: `GENERATED ALWAYS AS (total_amount - paid_amount) STORED`.

**Status**

- `status` — Enum: `Draft`, `Published`, `Partially Paid`, `Paid`, `Overdue`, `Cancelled`. The create and edit forms only allow `Draft` or `Published` as direct input; the other statuses are set by the system via `updatePayment()`, `cancel()`, or overdue detection logic.

---

## Business Rules and Conditions

**Invoice Number Generation**

The system assigns a unique invoice number automatically during creation. The controller uses `generateInvoiceNumber()` which returns `INV-YYYY-XXXXX` where `YYYY` is the current year and `XXXXX` is a zero-padded sequence based on the maximum invoice id plus one. The sequence is read inside a `DB::transaction` with `lockForUpdate()` to prevent duplicates.

> **Note:** The original requirement document stated the format `INV-YYYYMM-XXXX` (year + month). The implemented code uses the year-only format described above.

**Allowed Status Transitions**

- New invoices are created as either `Draft` or `Published`.
- `Published` invoices become `Partially Paid` when a payment less than the total is recorded.
- `Published` or `Partially Paid` invoices become `Paid` when the cumulative payment equals or exceeds the total.
- `Overdue` is not explicitly set by a controller action; it is determined by business logic based on the due date and remaining balance.
- `Cancelled` is a terminal state. A cancelled invoice cannot be paid, edited, or cancelled again.
- `Paid` invoices cannot be edited, cancelled, or deleted.

**Amount Computation**

- `total_amount` is calculated in the controller as `base_amount - concession_amount + fine_amount + tax_amount`.
- `balance_amount` is defined in the DDL as a stored generated column. The controller still writes to `balance_amount` during create and update, but the database value is ultimately determined by the generated column expression.

> **Note:** The original requirement document described `concession_amount`, `fine_amount`, and `tax_amount` as being automatically derived from approved concessions, fine transactions, and taxable heads. The current implementation treats these as manual input fields on the create and edit forms.

**Payment Recording**

- Payments can be recorded only on invoices that are not `Paid` or `Cancelled`.
- The recorded amount must be greater than 0.01 (validated by `RecordFeeInvoicePaymentRequest`).
- A successful payment creates a `FeeTransaction` record with `transaction_no` in the format `TXN-YYYY-XXXXXX` and updates the invoice's `paid_amount` and `status` via `FeeInvoice::updatePayment()`.
- All payment recording logic is wrapped in a `DB::transaction` block with rollback on exception.
- There is no validation preventing over-payment (amount exceeding `balance_amount`).

**Cancellation Rules**

- An invoice in `Paid` or `Cancelled` status cannot be cancelled.
- On cancellation the system sets `status = Cancelled`, records the `cancelled_by` user, and stores the optional `cancellation_reason`.

**PDF and Print**

- The print/preview view uses `invoice.blade.php` (browser HTML) and includes a client-side PDF export using html2pdf.js.
- The server-side PDF download uses `downloadPdf()` with `Barryvdh\DomPDF\Facade\Pdf` and the view `fee-invoice.invoice-pdf`, returning a file named `invoice-{invoice_no}.pdf`.

**Email and WhatsApp**

- `sendEmail()` generates a PDF from `fee-invoice.invoice-email` (A3 paper), saves it to `storage/app/public/invoices/invoice-{invoice_no}.pdf`, and dispatches a notification with type `FEE_PAYMENT_REMINDER` containing the PDF as an attachment.
- `sendWhatsapp()` generates a PDF from `fee-invoice.invoice-pdf`, saves it to the same storage path, builds a public URL, and redirects to `https://wa.me/91{mobile}?text={message}`.

> **Note:** The current `index.blade.php` and `show.blade.php` views do not include Email or WhatsApp action buttons, even though the routes and controller methods exist.

**Bulk Generation**

- `generateFeeInvoice()` dispatches `GenerateFeeInvoicesJob` with the current session ID and authenticated user ID.
- The job processes invoice creation in the background (queued).

**Payable Contract**

- `FeeInvoice` implements `Modules\Payment\Contracts\Payable` with methods `getPayableLabel()`, `getPayableAmount()`, `getPayableCustomer()`, and `getPayableMetadata()`.

---

## Workflow Steps

**Create a Single Invoice**

1. Open the Billing tab (`GET /student-fee/billing`).
2. Click the create route (`GET /student-fee/fee-invoice/create`).
3. Select an active student assignment. The base amount is auto-filled from the assignment's total fee amount.
4. Optionally select an installment; otherwise leave it as one-time payment.
5. Enter or confirm invoice date, due date, and status (`Draft` or `Published`).
6. Optionally adjust concession, fine, and tax amounts.
7. Submit. The controller computes the total, generates the invoice number, and redirects to the invoice detail page with `Invoice created successfully.`

**Record a Payment**

1. From the invoice detail page or the action dropdown on the billing tab, open the Record Payment modal for an unpaid invoice.
2. Enter amount (must be ≥ 0.01), payment date, payment mode, optional reference, and remarks.
3. Submit. The controller creates a `FeeTransaction` with `status = Success` and updates the invoice status to `Paid` or `Partially Paid`.

**Cancel an Invoice**

1. From the invoice detail page or action dropdown, open the Cancel modal for an invoice that is not already `Paid` or `Cancelled`.
2. Optionally enter a cancellation reason (max 500 characters).
3. Submit. The invoice status becomes `Cancelled` and the canceller is recorded.

**Download PDF**

1. From the invoice detail page or action dropdown, click Download PDF.
2. The controller returns a DomPDF-generated PDF download.

**Bulk Generate**

1. From the billing tab, click Generate All Invoices.
2. The controller checks for the current academic session and dispatches `GenerateFeeInvoicesJob`.
3. A success flash message informs the user that generation is queued.

**Send Email / WhatsApp**

1. From the invoice detail page, click Email or WhatsApp.
2. Email: dispatches `FEE_PAYMENT_REMINDER` notification. WhatsApp: redirects to WhatsApp Web with pre-populated message.

---

## Example Scenario

Ravi Kumar is enrolled in Class 10-A for the 2025–26 session and has a fee assignment with `total_fee_amount = ₹60,000`. The finance officer opens the Billing tab, clicks Create Invoice, selects Ravi's assignment, and the base amount is auto-filled to ₹60,000. The officer selects the first installment, sets the due date to 15 April 2026, and publishes the invoice. The system generates invoice `INV-2026-00012` with a total of ₹60,000 and balance of ₹60,000.

Ravi's parent pays ₹30,000 in cash at the office. The officer opens the invoice detail, records a cash payment of ₹30,000, and the invoice status changes to `Partially Paid` with a balance of ₹30,000. A second payment of ₹30,000 is recorded later, and the status changes to `Paid` with balance ₹0.00.

The officer later cancels a mistakenly created invoice for another student with reason `Duplicate entry`, sets status `Cancelled`, and the correct invoice remains.

---

## Related Screens

- **Billing Tab** — Parent container that loads the invoice grid (`billing.blade.php`).
- **Payment Tab** — Lists `FeeTransaction` records generated from invoice payments.
- **Fee Student Assignment** — Provides the student assignments and base amounts used when creating invoices.
- **Fee Installment** — Provides installment options for invoices.
- **Fee Transaction** — Stores payment records created by the Record Payment flow.
- **Fee Fine Transaction** — Related model referenced by the invoice relationship but not auto-applied to invoices.
- **Fee Cheque Reconciliation** — Handles cheque/DD clearing and bouncing for transactions linked to invoices.

---

## Requirements

- The tab is loaded under the Billing group via `GET /student-fee/billing` → `StudentFeeManagementController::billing()`, gated by `tenant.student-fee-management.viewAny`.
- Invoice CRUD operations are handled by `FeeInvoiceController`.
- `index()` authorizes `tenant.fee-invoice.view` and redirects to `student-fee.billing`.
- `create()` authorizes `tenant.fee-invoice.create` and loads active assignments and installments.
- `store()` authorizes `tenant.fee-invoice.create`, validates via `StoreFeeInvoiceRequest`, computes totals, generates the invoice number with `lockForUpdate()`, creates the `FeeInvoice`, logs `Created`, and redirects to `student-fee.fee-invoice.show` with flash `Invoice created successfully.`
- `show()` authorizes `tenant.fee-invoice.view`, eager loads `studentAssignment.student.user`, `studentAssignment.feeStructure`, `installment`, `transactions`, `generator`, and `canceller`.
- `edit()` authorizes `tenant.fee-invoice.update` and loads the invoice and active installments.
- `update()` authorizes `tenant.fee-invoice.update`, blocks edits on `Paid`/`Cancelled` invoices with error `Cannot edit a Paid or Cancelled invoice.`, validates via `UpdateFeeInvoiceRequest`, recalculates total/balance, logs `Updated`, and redirects with flash `Invoice updated successfully.`
- `destroy()` authorizes `tenant.fee-invoice.delete`, blocks deletion of `Paid` invoices with error `Cannot delete a paid invoice.`, logs `Trashed`, soft deletes, and redirects with flash `Invoice deleted successfully.`
- `trashedFeeInvoice()` authorizes `tenant.fee-invoice.restore` and paginates trashed invoices at 10 per page.
- `restore()` authorizes `tenant.fee-invoice.restore`, restores, logs `Restored`, and redirects with flash `Invoice restored successfully.`
- `forceDelete()` authorizes `tenant.fee-invoice.forceDelete`, logs `Deleted`, force deletes, and redirects with flash `Invoice permanently deleted.`
- `cancel()` authorizes `tenant.fee-invoice.update`, validates via `CancelFeeInvoiceRequest`, blocks on `Paid`/`Cancelled` with error `Invoice is already paid or cancelled.`, calls `FeeInvoice::cancel()`, logs `Cancelled`, and redirects with flash `Invoice cancelled successfully.`
- `recordPayment()` authorizes `tenant.fee-invoice.update`, validates via `RecordFeeInvoicePaymentRequest`, blocks on `Paid`/`Cancelled` with error `Cannot record payment for a paid or cancelled invoice.`, creates `FeeTransaction` in a DB transaction, calls `FeeInvoice::updatePayment()`, and redirects with flash `Payment of ₹{amount} recorded successfully.` On failure: `Payment recording failed. Please try again.`
- `invoice()` authorizes `tenant.fee-invoice.view` and renders browser preview view `fee-invoice.invoice`.
- `downloadPdf()` authorizes `tenant.fee-invoice.view` and returns a DomPDF download.
- `sendEmail()` authorizes `tenant.fee-invoice.update`, generates PDF, saves to storage, dispatches `Notification` with type `FEE_PAYMENT_REMINDER`, and redirects with flash `Invoice email sent successfully.`
- `sendWhatsapp()` authorizes `tenant.fee-invoice.update`, generates PDF, saves to storage, builds WhatsApp URL, and redirects externally.
- `generateFeeInvoice()` authorizes `tenant.fee-invoice.create`, dispatches `GenerateFeeInvoicesJob`, and returns flash `Invoice generation has been queued. Invoices will be created in the background.` or `No active academic session found.` if none exists.
- `FeeInvoice` model uses `SoftDeletes`, casts amounts to `decimal:2`, dates to `date`, and defines relationships.
- `FeeInvoice::updatePayment()` updates `paid_amount`, `balance_amount`, and `status`. `deductPayment()` reverses a payment.
- `FeeInvoice::cancel()` sets `status = Cancelled`, `cancelled_by`, and `cancellation_reason`.
- Activity logging uses `activityLog()` helper for all state changes.
- Validation is performed by `StoreFeeInvoiceRequest`, `UpdateFeeInvoiceRequest`, `CancelFeeInvoiceRequest`, and `RecordFeeInvoicePaymentRequest`.
- Policy is `FeeInvoicePolicy`.

> **Note:** The route `POST /student-fee/fee-invoice/{fee_invoice}/toggle-status` is registered in `web.php` but `FeeInvoiceController` does not implement a `toggleStatus()` method, which will result in a 500 error if the route is requested.

---

## Who Can Access This Screen

| Gate / Permission | Methods | Notes |
|---|---|---|
| `tenant.student-fee-management.viewAny` | `StudentFeeManagementController::billing()` | Required to open the Billing tab parent. |
| `tenant.fee-invoice.view` | `index`, `show`, `invoice`, `downloadPdf` | View invoice listing redirect, detail, print preview, and PDF download. |
| `tenant.fee-invoice.create` | `create`, `store`, `generateFeeInvoice` | Manual create and bulk generate. |
| `tenant.fee-invoice.update` | `update`, `cancel`, `recordPayment`, `sendEmail`, `sendWhatsapp` | Edit, cancel, record payment, email, and WhatsApp actions. |
| `tenant.fee-invoice.delete` | `destroy` | Soft delete. |
| `tenant.fee-invoice.restore` | `trashedFeeInvoice`, `restore` | View trash and restore. |
| `tenant.fee-invoice.forceDelete` | `forceDelete` | Permanently delete. |
| `tenant.fee-invoice.import` | `import` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.export` | `export` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.print` | `print` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.status` | `status` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.email-schedule` | `emailSchedule` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.remark` | `remark` (Policy only) | Not used by the controller. |
| `tenant.fee-invoice.pdf` | `pdf` (Policy only) | Not used by the controller. PDF download uses `tenant.fee-invoice.view`. |
| `FeeInvoicePolicy` | All policy methods | Gates are resolved via `Gate::authorize` in controllers and via `AuthorizesTenantFeature` trait in form requests. |

---

## Logic Flow

**1. Page Load:** User navigates to Billing. The parent controller loads the current session, queries invoices with optional search/status filters, and paginates 15 results. The view renders card and list layouts.

**2. Create Invoice:** User selects an assignment and installment. The create view auto-fills the base amount from the assignment's `total_fee_amount` via a `data-base` attribute. On submit, `StoreFeeInvoiceRequest` validates all fields, the controller computes `total_amount`, generates the invoice number inside a locked DB transaction, creates the record, logs `Created`, and redirects to the show page.

**3. Edit Invoice:** The edit form loads the existing invoice. The student and base amount are shown read-only. Only concession, fine, tax, dates, installment, and status can be changed. The controller blocks edits if the invoice is already `Paid` or `Cancelled`.

**4. Record Payment:** The payment modal submits amount, date, mode, reference, and remarks. The controller validates via `RecordFeeInvoicePaymentRequest`, checks that invoice is not `Paid`/`Cancelled`, creates a `FeeTransaction` within a DB transaction, calls `updatePayment()` which recalculates `paid_amount` and status, and commits. On failure, it rolls back and returns an error.

**5. Cancel Invoice:** The cancel modal submits an optional reason. The controller blocks paid or already cancelled invoices, then calls `FeeInvoice::cancel()` to record the state change.

**6. Download/Print PDF:** The browser preview view offers print and client-side PDF export. The server-side PDF route returns a DomPDF-generated file.

**7. Email/WhatsApp:** Email generates a PDF, saves it to storage, and dispatches a notification. WhatsApp generates a PDF and redirects to the WhatsApp web URL.

**8. Trash/Restore:** The trash view lists soft-deleted invoices. Restore reactivates the record; force delete removes it permanently.

**9. Bulk Generation:** Generate All Invoices dispatches a queued job for background processing.

---

## Validate Before Save

### Store Invoice Validation (`StoreFeeInvoiceRequest`)

| Field | Rule(s) | Error Message |
|---|---|---|
| `student_assignment_id` | `required`, `integer`, `exists:fee_student_assignments,id` | Laravel default. |
| `installment_id` | `nullable`, `integer`, `exists:fee_installments,id` | Laravel default. |
| `invoice_date` | `required`, `date` | Laravel default. |
| `due_date` | `required`, `date`, `after_or_equal:invoice_date` | Laravel default. |
| `base_amount` | `required`, `numeric`, `min:0` | Laravel default. |
| `concession_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `fine_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `tax_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `status` | `required`, `in:Draft,Published` | Laravel default. |

### Update Invoice Validation (`UpdateFeeInvoiceRequest`)

| Field | Rule(s) | Error Message |
|---|---|---|
| `installment_id` | `nullable`, `integer`, `exists:fee_installments,id` | Laravel default. |
| `invoice_date` | `required`, `date` | Laravel default. |
| `due_date` | `required`, `date`, `after_or_equal:invoice_date` | Laravel default. |
| `concession_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `fine_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `tax_amount` | `nullable`, `numeric`, `min:0` | Laravel default. |
| `status` | `required`, `in:Draft,Published` | Laravel default. |

### Cancel Invoice Validation (`CancelFeeInvoiceRequest`)

| Field | Rule(s) | Error Message |
|---|---|---|
| `cancellation_reason` | `nullable`, `string`, `max:500` | Laravel default. |

### Record Payment Validation (`RecordFeeInvoicePaymentRequest`)

| Field | Rule(s) | Error Message |
|---|---|---|
| `amount` | `required`, `numeric`, `min:0.01` | Laravel default. |
| `payment_date` | `required`, `date` | Laravel default. |
| `payment_mode` | `required`, `in:Cash,Bank Transfer,Cheque,UPI,Credit Card,Debit Card` | Laravel default. |
| `payment_reference` | `nullable`, `string`, `max:100` | Laravel default. |
| `remarks` | `nullable`, `string`, `max:500` | Laravel default. |

> **Note:** `Bank Transfer` is allowed by the request but is not an enum value in the DDL `fee_transactions.payment_mode` (`Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet`). Submitting `Bank Transfer` may pass form validation but fail at the database level.

### Controller-level Checks

| Check | Condition | Error Message |
|---|---|---|
| Update block | `status` is `Paid` or `Cancelled` | `Cannot edit a Paid or Cancelled invoice.` |
| Delete block | `status === Paid` | `Cannot delete a paid invoice.` |
| Cancel block | `status` is `Paid` or `Cancelled` | `Invoice is already paid or cancelled.` |
| Record payment block | `status` is `Paid` or `Cancelled` | `Cannot record payment for a paid or cancelled invoice.` |
| Bulk generation | No current academic session | `No active academic session found.` |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|---|---|---|
| Missing `student_assignment_id` on create | `The student assignment id field is required.` | Validation rule |
| `student_assignment_id` does not exist | `The selected student assignment id is invalid.` | Validation rule |
| `due_date` before `invoice_date` | `The due date field must be a date after or equal to invoice date.` | Validation rule |
| `status` not `Draft` or `Published` | `The selected status is invalid.` | Validation rule |
| Edit `Paid` or `Cancelled` invoice | `Cannot edit a Paid or Cancelled invoice.` | Controller check (flash error) |
| Delete `Paid` invoice | `Cannot delete a paid invoice.` | Controller check (flash error) |
| Cancel `Paid` or `Cancelled` invoice | `Invoice is already paid or cancelled.` | Controller check (flash error) |
| Record payment on `Paid`/`Cancelled` invoice | `Cannot record payment for a paid or cancelled invoice.` | Controller check (flash error) |
| Payment amount ≤ 0 | `The amount field must be at least 0.01.` | Validation rule |
| Invalid payment mode | `The selected payment mode is invalid.` | Validation rule |
| Payment recording throws exception | `Payment recording failed. Please try again.` | Controller catch (flash error) |
| Bulk generation with no active session | `No active academic session found.` | Controller check (flash error) |
| Missing view/create/update/delete permission | `This action is unauthorized.` (403) | Gate / Policy |
| Model not found | 404 response | `findOrFail` |
| Toggle status route requested | 500 error — method not implemented | Missing controller method |

---

## Success Scenarios

**SC-001 — Create a Published Invoice**

A user with `tenant.fee-invoice.create` selects assignment `FSA-10A-001`, selects installment `Term 1`, sets invoice date to 2026-04-01, due date to 2026-04-15, and status `Published`. Base amount auto-fills to ₹60,000. The system creates invoice `INV-2026-00012` with total ₹60,000, balance ₹60,000, status `Published`, and logs `Created`.

**SC-002 — Record a Full Payment**

On invoice `INV-2026-00012` with total ₹60,000 and balance ₹60,000, a user records a cash payment of ₹60,000. The system creates a `FeeTransaction` with `transaction_no = TXN-2026-000045`, sets `paid_amount` to ₹60,000, `balance_amount` to ₹0.00, and status to `Paid`.

**SC-003 — Record a Partial Payment**

On a published invoice with total ₹60,000, a user records ₹25,000. The system sets `paid_amount` to ₹25,000, `balance_amount` to ₹35,000, and status to `Partially Paid`.

**SC-004 — Cancel an Invoice**

A user cancels a `Published` invoice with reason `Fee waived by management`. The system sets status to `Cancelled`, records the current user in `cancelled_by`, stores the reason, and logs `Cancelled`.

**SC-005 — Download PDF**

A user clicks Download PDF on an invoice. The controller returns a PDF file named `invoice-INV-2026-00012.pdf` generated from `fee-invoice.invoice-pdf` using DomPDF with A4 paper size.

**SC-006 — Bulk Generate Invoices**

A user clicks Generate All Invoices while the current academic session is active. The system dispatches `GenerateFeeInvoicesJob` and redirects with the message `Invoice generation has been queued. Invoices will be created in the background.`

**SC-007 — Restore a Soft-Deleted Invoice**

An administrator opens the trash view, clicks restore on a deleted invoice, and the invoice is restored with status unchanged. The activity log records `Restored`.

**SC-008 — Send Invoice Email**

A user clicks Email on a published invoice. The system generates a PDF (A3), saves it to `storage/app/public/invoices/invoice-{no}.pdf`, dispatches a `FEE_PAYMENT_REMINDER` notification, and redirects with `Invoice email sent successfully.`

---

## Failure Scenarios

**FC-001 — Edit a Paid Invoice**

A user attempts to edit an invoice whose status is `Paid`. The controller rejects the request and returns with the flash error `Cannot edit a Paid or Cancelled invoice.`

**FC-002 — Delete a Paid Invoice**

A user attempts to delete an invoice whose status is `Paid`. The controller rejects with `Cannot delete a paid invoice.`

**FC-003 — Cancel an Already Paid Invoice**

A user attempts to cancel a `Paid` invoice. The controller rejects with `Invoice is already paid or cancelled.`

**FC-004 — Record Payment Against Cancelled Invoice**

A user submits the record payment form for a `Cancelled` invoice. The controller rejects with `Cannot record payment for a paid or cancelled invoice.`

**FC-005 — Payment Amount Exceeds Balance (No Validation)**

The payment form has an HTML `max` attribute set to the current balance, but if a larger amount is submitted directly, the business rule does not prevent it. The `updatePayment()` method will set `paid_amount` above the total and mark the invoice `Paid`. Over-payment is not blocked by validation or controller logic.

**FC-006 — Bulk Generation Without Active Session**

A user clicks Generate All Invoices when there is no active academic session. The controller returns `No active academic session found.`

**FC-007 — Toggle Status Route (500 Error)**

A request is made to `POST /student-fee/fee-invoice/{fee_invoice}/toggle-status`. Because `FeeInvoiceController::toggleStatus()` does not exist, the application returns a 500 error.

**FC-008 — Payment Mode Mismatch Bank Transfer**

A user records a payment with mode `Bank Transfer`. The `RecordFeeInvoicePaymentRequest` allows it, but the DDL enum for `fee_transactions.payment_mode` does not include `Bank Transfer` (valid values: `Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet`). The insert fails at the database level.

---

## Dependencies module and tables

### Foreign Key Dependencies

| Dependency | Type | Details |
|---|---|---|
| `fee_student_assignments` | Parent FK | `fee_invoices.student_assignment_id` → `fee_student_assignments.id`; `ON DELETE RESTRICT`. |
| `fee_installments` | Parent FK | `fee_invoices.installment_id` → `fee_installments.id`; `ON DELETE SET NULL`. |
| `sys_users` | Parent FK | `fee_invoices.generated_by` → `sys_users.id`; `ON DELETE RESTRICT`. |
| `fee_transactions` | Child FK | `fee_transactions.invoice_id` → `fee_invoices.id`; `ON DELETE RESTRICT`. Deleting an invoice is blocked if transactions exist. |
| `fee_fine_transactions` | Child FK | `fee_fine_transactions.invoice_id` → `fee_invoices.id`; `ON DELETE RESTRICT`. Deleting an invoice is blocked if fine transactions exist. |
| `Modules\Payment\Contracts\Payable` | Contract | Implemented by `FeeInvoice` for gateway integration. |
| `Modules\Notification\Facades\Notification` | Service | Dispatched by `sendEmail()` for email delivery. |
| `Barryvdh\DomPDF\Facade\Pdf` | Service | Used by `downloadPdf()`, `sendEmail()`, and `sendWhatsapp()`. |
| `GenerateFeeInvoicesJob` | Job | Dispatched by `generateFeeInvoice()` for background invoice generation. |
| Activity log | Service | `activityLog()` helper called on all state changes. |

### Table: `fee_invoices`

| Column | Type | Details |
|---|---|---|
| `id` | INT UNSIGNED | Auto-increment primary key. |
| `invoice_no` | VARCHAR(50) | NOT NULL, UNIQUE. |
| `student_assignment_id` | INT UNSIGNED | NOT NULL, FK → `fee_student_assignments.id`, ON DELETE RESTRICT. |
| `installment_id` | INT UNSIGNED | NULL, FK → `fee_installments.id`, ON DELETE SET NULL. |
| `invoice_date` | DATE | NOT NULL. |
| `due_date` | DATE | NOT NULL. |
| `base_amount` | DECIMAL(12,2) | NOT NULL. |
| `concession_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00. |
| `fine_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00. |
| `tax_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00. |
| `total_amount` | DECIMAL(12,2) | NOT NULL. |
| `paid_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00. |
| `balance_amount` | DECIMAL(12,2) | GENERATED ALWAYS AS (`total_amount` - `paid_amount`) STORED. |
| `status` | ENUM | NOT NULL, DEFAULT 'Draft'. Values: `Draft`, `Published`, `Partially Paid`, `Paid`, `Overdue`, `Cancelled`. |
| `invoice_pdf_path` | VARCHAR(255) | NULL. |
| `generated_by` | INT UNSIGNED | NOT NULL, FK → `sys_users.id`, ON DELETE RESTRICT. |
| `cancelled_by` | INT UNSIGNED | NULL. |
| `cancellation_reason` | TEXT | NULL. |
| `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP. |
| `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP. |
| `deleted_at` | TIMESTAMP | NULL. Soft delete column. |

**Indexes:** `idx_invoice_status` (status), `idx_invoice_due_date` (due_date), `idx_invoice_student` (student_assignment_id).
