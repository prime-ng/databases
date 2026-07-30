# fee_FeeInvoice_TcList

## Module: StudentFee → Billing → Fee Invoice

## 1. Feature Information

| Item | Details |
|---|---|
| Module / Tab Group / Feature | StudentFee / Billing / Fee Invoice |
| URL(s) | `GET /student-fee/billing` (parent tab)<br>`GET /student-fee/fee-invoice` (redirects to billing)<br>`GET /student-fee/fee-invoice/create`<br>`POST /student-fee/fee-invoice` (store)<br>`GET /student-fee/fee-invoice/{fee_invoice}` (show)<br>`GET /student-fee/fee-invoice/{fee_invoice}/edit`<br>`PUT /student-fee/fee-invoice/{fee_invoice}` (update)<br>`DELETE /student-fee/fee-invoice/{fee_invoice}` (destroy)<br>`GET /student-fee/fee-invoice/trash/view`<br>`GET /student-fee/fee-invoice/{id}/restore`<br>`DELETE /student-fee/fee-invoice/{id}/force-delete`<br>`POST /student-fee/fee-invoice/{fee_invoice}/toggle-status`<br>`POST /student-fee/fee-invoice/generate/all`<br>`GET /student-fee/fee-invoice/{fee_invoice}/invoice/view`<br>`GET /student-fee/fee-invoice/{fee_invoice}/pdf`<br>`POST /student-fee/fee-invoice/{fee_invoice}/email`<br>`POST /student-fee/fee-invoice/{fee_invoice}/whatsapp`<br>`PUT /student-fee/fee-invoice/{fee_invoice}/cancel`<br>`POST /student-fee/fee-invoice/{fee_invoice}/record-payment` |
| Controller | `Modules\StudentFee\Http\Controllers\FeeInvoiceController` (billing parent loaded by `StudentFeeManagementController::billing()`) |
| Model(s) | `Modules\StudentFee\Models\FeeInvoice` (`table: fee_invoices`), `Modules\StudentFee\Models\FeeTransaction` (`table: fee_transactions`) |
| Validation (Create) | `Modules\StudentFee\Http\Requests\StoreFeeInvoiceRequest` |
| Validation (Update) | `Modules\StudentFee\Http\Requests\UpdateFeeInvoiceRequest` |
| Validation (Cancel) | `Modules\StudentFee\Http\Requests\CancelFeeInvoiceRequest` |
| Validation (Payment) | `Modules\StudentFee\Http\Requests\RecordFeeInvoicePaymentRequest` |
| Policy | `Modules\StudentFee\Policies\FeeInvoicePolicy` |
| Permissions | `tenant.student-fee-management.viewAny`, `tenant.fee-invoice.view`, `tenant.fee-invoice.create`, `tenant.fee-invoice.update`, `tenant.fee-invoice.delete`, `tenant.fee-invoice.restore`, `tenant.fee-invoice.forceDelete`, `tenant.fee-invoice.import`, `tenant.fee-invoice.export`, `tenant.fee-invoice.print`, `tenant.fee-invoice.status`, `tenant.fee-invoice.email-schedule`, `tenant.fee-invoice.remark`, `tenant.fee-invoice.pdf` |
| Pagination | 15 records per page using `page` parameter (`withQueryString()`); trash view uses 10 per page; create form use no pagination |
| Soft Deletes | Yes — `FeeInvoice` uses `SoftDeletes` trait; `deleted_at` is TIMESTAMP NULL in DDL |
| Activity Log | `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Cancelled` |
| Import / Export | Not supported |
| Data Source | Invoices stored in `fee_invoices`; transactions stored in `fee_transactions` |
| PDF Service | `Barryvdh\DomPDF\Facade\Pdf` (A4 for download/WhatsApp, A3 for email) |
| Notification Service | `Modules\Notification\Facades\Notification` (type `FEE_PAYMENT_REMINDER`) |

## 2. Pre-conditions

- User is authenticated with a role that grants the required permissions.
- Tenant context is initialized (`DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD` env vars are set for Dusk tests).
- An active academic session exists in `Modules\Prime\Models\AcademicSession::current()`.
- At least one active student fee assignment exists in `fee_student_assignments` with `is_active = true`.
- Required parent records exist: `sys_users` (cashier/admin), `std_students`, `fee_installments`, and optionally `fee_structure_master` details.
- For payment recording tests, an invoice exists in a status other than `Paid` or `Cancelled`.
- For trash/restore tests, a soft-deleted invoice exists in `fee_invoices` with `deleted_at` set.
- For PDF tests, DomPDF is installed and configured.
- For email tests, the Notification system is configured with a valid mail driver.

## 3. Default Data Load

The tab is loaded by `StudentFeeManagementController::billing()` (route `student-fee.billing`, `GET /student-fee/billing`). It loads the current academic session, queries `FeeInvoice` with related `studentAssignment.student.user` and `installment`, applies optional `search` and `status` filters, orders by `invoice_date` descending, and paginates 15 per page.

| Data | Source | Query | Filters | Pagination |
|---|---|---|---|---|
| Invoice grid | `StudentFeeManagementController::billing()` | `FeeInvoice::with(['studentAssignment.student.user', 'installment'])` | current session, `search` (invoice_no/student name), `status` | 15 per page (`page`) |
| Create form assignments dropdown | `FeeInvoiceController::create()` | `FeeStudentAssignment::with(['student.user'])->where('is_active', true)->get()` | `is_active = true` | None |
| Create form installments dropdown | `FeeInvoiceController::create()` | `FeeInstallment::with('feeStructure')->where('is_active', true)->orderBy('due_date')->get()` | `is_active = true` | None |
| Edit form installments dropdown | `FeeInvoiceController::edit()` | Same as create | `is_active = true` | None |

> **Data Source:** Student names and admission numbers come from `std_students` through `fee_student_assignments`. Installment data comes from `fee_installments`.

## 4. Test Data Strategy

- Create test assignments and students through direct database inserts or seeders; ensure each test student has a unique `admission_no`.
- Use consistent date ranges: invoice dates in the current month, due dates 15–30 days later.
- Pre-test cleanup: remove invoices created by previous test runs using a fixed invoice number pattern or test tenant isolation.
- For pagination overflow: create at least 16 invoices to verify the second page exists and the per-page limit is 15.
- For status filter tests: create one invoice per status (`Draft`, `Published`, `Partially Paid`, `Paid`, `Overdue`, `Cancelled`) within the current session.
- For payment tests: create a `Published` invoice with a positive balance and do not pay it fully until the relevant test step.
- For delete/restore tests: create a `Draft` or `Published` invoice, soft-delete it, then verify the trash view and restore action.
- For PDF tests: ensure `storage/app/public/invoices/` directory exists and is writable.
- For email tests: ensure a tested student user has a valid email address.

## 5. Business Conditions

### 5.1 Database Schema — `fee_invoices`

| BC ID | Column | Type (DDL) | Constraints |
|---|---|---|---|
| BC-DB-01 | `id` | INT UNSIGNED | AUTO_INCREMENT PRIMARY KEY |
| BC-DB-02 | `invoice_no` | VARCHAR(50) | NOT NULL, UNIQUE |
| BC-DB-03 | `student_assignment_id` | INT UNSIGNED | NOT NULL, FK → `fee_student_assignments.id`, ON DELETE RESTRICT |
| BC-DB-04 | `installment_id` | INT UNSIGNED | NULL, FK → `fee_installments.id`, ON DELETE SET NULL |
| BC-DB-05 | `invoice_date` | DATE | NOT NULL |
| BC-DB-06 | `due_date` | DATE | NOT NULL |
| BC-DB-07 | `base_amount` | DECIMAL(12,2) | NOT NULL |
| BC-DB-08 | `concession_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-09 | `fine_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-10 | `tax_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-11 | `total_amount` | DECIMAL(12,2) | NOT NULL |
| BC-DB-12 | `paid_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0.00 |
| BC-DB-13 | `balance_amount` | DECIMAL(12,2) | GENERATED ALWAYS AS (`total_amount` - `paid_amount`) STORED |
| BC-DB-14 | `status` | ENUM | NOT NULL, DEFAULT 'Draft'; values: Draft, Published, Partially Paid, Paid, Overdue, Cancelled |
| BC-DB-15 | `invoice_pdf_path` | VARCHAR(255) | NULL |
| BC-DB-16 | `generated_by` | INT UNSIGNED | NOT NULL, FK → `sys_users.id`, ON DELETE RESTRICT |
| BC-DB-17 | `cancelled_by` | INT UNSIGNED | NULL |
| BC-DB-18 | `cancellation_reason` | TEXT | NULL |
| BC-DB-19 | `created_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-20 | `updated_at` | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-21 | `deleted_at` | TIMESTAMP | NULL |
| BC-DB-22 | `idx_invoice_status` | INDEX | On `status` |
| BC-DB-23 | `idx_invoice_due_date` | INDEX | On `due_date` |
| BC-DB-24 | `idx_invoice_student` | INDEX | On `student_assignment_id` |

> **Note:** The model includes `balance_amount` in `$fillable` and the controller writes to it in `store()` and `update()`. Because the DDL defines it as a stored generated column, the database may ignore or reject the explicit write. The DDL value is the source of truth.

### 5.2 Validation Rules — `StoreFeeInvoiceRequest` (Create)

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-01 | `student_assignment_id` | `required`, `integer`, `exists:fee_student_assignments,id` | Laravel default |
| BC-VAL-02 | `installment_id` | `nullable`, `integer`, `exists:fee_installments,id` | Laravel default |
| BC-VAL-03 | `invoice_date` | `required`, `date` | Laravel default |
| BC-VAL-04 | `due_date` | `required`, `date`, `after_or_equal:invoice_date` | Laravel default |
| BC-VAL-05 | `base_amount` | `required`, `numeric`, `min:0` | Laravel default |
| BC-VAL-06 | `concession_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-07 | `fine_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-08 | `tax_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-09 | `status` | `required`, `in:Draft,Published` | Laravel default |

### 5.3 Validation Rules — `UpdateFeeInvoiceRequest` (Update)

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-10 | `installment_id` | `nullable`, `integer`, `exists:fee_installments,id` | Laravel default |
| BC-VAL-11 | `invoice_date` | `required`, `date` | Laravel default |
| BC-VAL-12 | `due_date` | `required`, `date`, `after_or_equal:invoice_date` | Laravel default |
| BC-VAL-13 | `concession_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-14 | `fine_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-15 | `tax_amount` | `nullable`, `numeric`, `min:0` | Laravel default |
| BC-VAL-16 | `status` | `required`, `in:Draft,Published` | Laravel default |

### 5.4 Validation Rules — `CancelFeeInvoiceRequest`

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-17 | `cancellation_reason` | `nullable`, `string`, `max:500` | Laravel default |

### 5.5 Validation Rules — `RecordFeeInvoicePaymentRequest`

| BC ID | Field | Rule(s) | Error Message |
|---|---|---|---|
| BC-VAL-18 | `amount` | `required`, `numeric`, `min:0.01` | Laravel default |
| BC-VAL-19 | `payment_date` | `required`, `date` | Laravel default |
| BC-VAL-20 | `payment_mode` | `required`, `in:Cash,Bank Transfer,Cheque,UPI,Credit Card,Debit Card` | Laravel default |
| BC-VAL-21 | `payment_reference` | `nullable`, `string`, `max:100` | Laravel default |
| BC-VAL-22 | `remarks` | `nullable`, `string`, `max:500` | Laravel default |

> **Note:** `Bank Transfer` is allowed by the request but is not an enum value in the DDL `fee_transactions.payment_mode` (`Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet`).

### 5.6 Authorization

| BC ID | Permission | Behavior |
|---|---|---|
| BC-AUTH-01 | `tenant.student-fee-management.viewAny` | Without it, `GET /student-fee/billing` returns 403. |
| BC-AUTH-02 | `tenant.fee-invoice.view` | Without it, `show`, `invoice` preview, and `downloadPdf` return 403. |
| BC-AUTH-03 | `tenant.fee-invoice.create` | Without it, `create`, `store`, and `generateFeeInvoice` return 403. |
| BC-AUTH-04 | `tenant.fee-invoice.update` | Without it, `update`, `cancel`, `recordPayment`, `sendEmail`, and `sendWhatsapp` return 403. |
| BC-AUTH-05 | `tenant.fee-invoice.delete` | Without it, `destroy` returns 403. |
| BC-AUTH-06 | `tenant.fee-invoice.restore` | Without it, `trashedFeeInvoice` and `restore` return 403. |
| BC-AUTH-07 | `tenant.fee-invoice.forceDelete` | Without it, `forceDelete` returns 403. |
| BC-AUTH-08 | Guest access | Any guest request is redirected to `/login`. |

### 5.7 Business Logic

| BC ID | Condition | Expected Behavior |
|---|---|---|
| BC-BIZ-01 | Default page load | Invoices are filtered by the current academic session when a current session exists. |
| BC-BIZ-02 | Search by `invoice_no` | Grid shows only invoices matching the invoice number pattern (LIKE %search%). |
| BC-BIZ-03 | Search by student name | Grid shows only invoices whose student's name matches the search term. |
| BC-BIZ-04 | Filter by `status` | Grid shows only invoices with the selected status. |
| BC-BIZ-05 | Card/list view toggle | Local storage preference `fee_invoice_view_preference` controls default view; buttons toggle between card and list containers. |
| BC-BIZ-06 | Pagination | 15 invoices per page; links preserve search and status filters via `withQueryString()`. |
| BC-BIZ-07 | Invoice number generation | Format is `INV-YYYY-XXXXX` where `YYYY` = current year, `XXXXX` = zero-padded `max(id) + 1` from locked transaction. |
| BC-BIZ-08 | Total amount calculation | `total_amount = base_amount - concession_amount + fine_amount + tax_amount`. |
| BC-BIZ-09 | Payment status update | After recording a payment, status becomes `Paid` if paid ≥ total, `Partially Paid` if 0 < paid < total, otherwise remains `Published`. |
| BC-BIZ-10 | Edit/cancel/delete block | `Paid` and `Cancelled` invoices cannot be edited, cancelled, or deleted. |
| BC-BIZ-11 | Over-payment not prevented | `RecordFeeInvoicePaymentRequest` validates `min:0.01` but does not enforce `max:balance_amount`. |
| BC-BIZ-12 | Bulk generate dispatches job | `generateFeeInvoice()` dispatches `GenerateFeeInvoicesJob`; returns flash that generation is queued. |
| BC-BIZ-13 | Email dispatches notification | `sendEmail()` generates PDF, saves to storage, dispatches `FEE_PAYMENT_REMINDER` notification. |
| BC-BIZ-14 | WhatsApp redirects to wa.me | `sendWhatsapp()` generates PDF, saves to storage, builds `https://wa.me/91{mobile}?text={message}` URL, redirects. |
| BC-BIZ-15 | `balance_amount` is generated column | DDL defines it as `GENERATED ALWAYS AS (total_amount - paid_amount) STORED`. |

### 5.8 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|---|---|---|---|
| BC-REF-01 | `fee_invoices.student_assignment_id` | `fee_student_assignments.id` | RESTRICT |
| BC-REF-02 | `fee_invoices.installment_id` | `fee_installments.id` | SET NULL |
| BC-REF-03 | `fee_invoices.generated_by` | `sys_users.id` | RESTRICT |
| BC-REF-04 | `fee_transactions.invoice_id` | `fee_invoices.id` | RESTRICT |
| BC-REF-05 | `fee_fine_transactions.invoice_id` | `fee_invoices.id` | RESTRICT |

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-P01 | Load the Billing tab with invoices in the current session | Grid renders in card view with 15 or fewer invoices; current session name shown | — | — | ⬜ |
| TC-P02 | Load the Billing tab when no invoices exist | Empty state message "No invoices found for the current session." is displayed | — | — | ⬜ |
| TC-P03 | Search invoices by invoice number | Only invoices matching the number appear; pagination updates | — | — | ⬜ |
| TC-P04 | Search invoices by student name | Only invoices for matching student names appear | — | — | ⬜ |
| TC-P05 | Filter invoices by status `Draft` | Only Draft invoices are shown | — | — | ⬜ |
| TC-P06 | Filter invoices by status `Published` | Only Published invoices are shown | — | — | ⬜ |
| TC-P07 | Filter invoices by status `Partially Paid` | Only Partially Paid invoices are shown | — | — | ⬜ |
| TC-P08 | Filter invoices by status `Paid` | Only Paid invoices are shown | — | — | ⬜ |
| TC-P09 | Filter invoices by status `Overdue` | Only Overdue invoices are shown | — | — | ⬜ |
| TC-P10 | Filter invoices by status `Cancelled` | Only Cancelled invoices are shown | — | — | ⬜ |
| TC-P11 | Navigate to page 2 of the invoice grid | Second page of invoices renders; query string preserves filters | — | — | ⬜ |
| TC-P12 | Toggle between card and list views | Card view hides, list view shows, and preference is saved in localStorage | — | — | ⬜ |
| TC-P13 | Create a Published invoice with required fields only | Invoice is created with status `Published`, auto-generated invoice number, and redirect to show page with success message | — | — | ⬜ |
| TC-P14 | Create a Draft invoice with all fields filled | Invoice is created with status `Draft`, selected installment, and computed total amount | — | — | ⬜ |
| TC-P15 | Create invoice auto-fills base amount from student assignment | Selecting an assignment sets `base_amount` to the assignment's `total_fee_amount` via `data-base` attribute | — | — | ⬜ |
| TC-P16 | Open the edit page for a Draft invoice | Edit form loads with student and base amount read-only, other fields editable | — | — | ⬜ |
| TC-P17 | Update a Draft invoice to Published | Invoice status updates to `Published`; total amount recalculates if adjustments changed | — | — | ⬜ |
| TC-P18 | Open the invoice detail page | Show view displays student info, financial breakdown, payment history, and action buttons | — | — | ⬜ |
| TC-P19 | Open the print invoice preview | Browser preview renders the invoice HTML with print and client-side PDF buttons | — | — | ⬜ |
| TC-P20 | Download invoice PDF via server route | Browser receives a PDF download named `invoice-{invoice_no}.pdf` with A4 layout | — | — | ⬜ |
| TC-P21 | Record a full payment for an invoice | `FeeTransaction` created with `transaction_no`; invoice status changes to `Paid`; balance is ₹0.00 | — | — | ⬜ |
| TC-P22 | Record a partial payment for an invoice | `FeeTransaction` created; invoice status changes to `Partially Paid`; balance reduced by payment amount | — | — | ⬜ |
| TC-P23 | Cancel a Published invoice with a reason | Invoice status becomes `Cancelled`; `cancelled_by` and `cancellation_reason` are stored | — | — | ⬜ |
| TC-P24 | Trigger bulk invoice generation | Job is dispatched; success flash message `Invoice generation has been queued. Invoices will be created in the background.` appears | — | — | ⬜ |
| TC-P25 | Open the trashed invoices view | Soft-deleted invoices are listed with restore and force-delete actions | — | — | ⬜ |
| TC-P26 | Restore a soft-deleted invoice | Invoice reappears in the active grid; activity log records `Restored` | — | — | ⬜ |
| TC-P27 | Force delete a soft-deleted invoice without related transactions | Invoice is permanently removed; activity log records `Deleted` | — | — | ⬜ |
| TC-P28 | Send invoice via email | PDF generated and saved; `FEE_PAYMENT_REMINDER` notification dispatched; flash `Invoice email sent successfully.` | — | — | ⬜ |
| TC-P29 | Send invoice via WhatsApp | PDF generated and saved; browser redirects to `https://wa.me/91{mobile}?text=...` | — | — | ⬜ |
| TC-P30 | Full lifecycle: create → edit → partial payment → full payment → delete | Each step succeeds and status transitions are reflected correctly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-N01 | Create invoice without `student_assignment_id` | Validation error: `The student assignment id field is required.` | — | — | ⬜ |
| TC-N02 | Create invoice with non-existent `student_assignment_id` | Validation error: `The selected student assignment id is invalid.` | — | — | ⬜ |
| TC-N03 | Create invoice without `invoice_date` | Validation error: `The invoice date field is required.` | — | — | ⬜ |
| TC-N04 | Create invoice with `due_date` before `invoice_date` | Validation error: `The due date field must be a date after or equal to invoice date.` | — | — | ⬜ |
| TC-N05 | Create invoice without `base_amount` | Validation error: `The base amount field is required.` | — | — | ⬜ |
| TC-N06 | Create invoice with negative `base_amount` | Validation error: `The base amount field must be at least 0.` | — | — | ⬜ |
| TC-N07 | Create invoice with `status` not in `Draft,Published` | Validation error: `The selected status is invalid.` | — | — | ⬜ |
| TC-N08 | Create invoice without `due_date` | Validation error: `The due date field is required.` | — | — | ⬜ |
| TC-N09 | Edit a `Paid` invoice | Flash error: `Cannot edit a Paid or Cancelled invoice.` | — | — | ⬜ |
| TC-N10 | Edit a `Cancelled` invoice | Flash error: `Cannot edit a Paid or Cancelled invoice.` | — | — | ⬜ |
| TC-N11 | Record payment on a `Paid` invoice | Flash error: `Cannot record payment for a paid or cancelled invoice.` | — | — | ⬜ |
| TC-N12 | Record payment on a `Cancelled` invoice | Flash error: `Cannot record payment for a paid or cancelled invoice.` | — | — | ⬜ |
| TC-N13 | Record payment with amount `0` | Validation error: `The amount field must be at least 0.01.` | — | — | ⬜ |
| TC-N14 | Record payment with invalid `payment_mode` (e.g., `Crypto`) | Validation error: `The selected payment mode is invalid.` | — | — | ⬜ |
| TC-N15 | Cancel a `Paid` invoice | Flash error: `Invoice is already paid or cancelled.` | — | — | ⬜ |
| TC-N16 | Cancel an already `Cancelled` invoice | Flash error: `Invoice is already paid or cancelled.` | — | — | ⬜ |
| TC-N17 | Delete a `Paid` invoice | Flash error: `Cannot delete a paid invoice.` | — | — | ⬜ |
| TC-N18 | Access invoice show without `tenant.fee-invoice.view` permission | 403 `This action is unauthorized.` | — | — | ⬜ |
| TC-N19 | Access invoice create without `tenant.fee-invoice.create` permission | 403 `This action is unauthorized.` | — | — | ⬜ |
| TC-N20 | Access invoice update without `tenant.fee-invoice.update` permission | 403 on edit/update/cancel/recordPayment | — | — | ⬜ |
| TC-N21 | Access invoice as guest | Redirect to `/login` | — | — | ⬜ |
| TC-N22 | Request non-existent invoice ID | 404 response | — | — | ⬜ |
| TC-N23 | Bulk generation without active session | Flash error: `No active academic session found.` | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-D01 | A | Verify `balance_amount` is a generated column | Updating `paid_amount` automatically recalculates `balance_amount` without an explicit application update | — | — | ⬜ |
| TC-D02 | B | Soft delete and restore an invoice | `deleted_at` is set on delete; `restore()` clears it and invoice reappears in active grid | — | — | ⬜ |
| TC-D03 | C | Delete a `fee_student_assignments` row referenced by an invoice | Database rejects deletion due to RESTRICT FK | — | — | ⬜ |
| TC-D04 | D | Delete a `fee_installments` row referenced by an invoice | `installment_id` is set to NULL on the invoice (SET NULL) | — | — | ⬜ |
| TC-D05 | E | Delete a `sys_users` row referenced by `generated_by` | Database rejects deletion due to RESTRICT FK | — | — | ⬜ |
| TC-D06 | F | Delete an invoice that has related `fee_transactions` | Database rejects deletion due to RESTRICT FK on `fee_transactions.invoice_id` | — | — | ⬜ |
| TC-D07 | G | Delete an invoice that has related `fee_fine_transactions` | Database rejects deletion due to RESTRICT FK on `fee_fine_transactions.invoice_id` | — | — | ⬜ |
| TC-D08 | H | Verify model relationships are eager-loaded | `show()` and `edit()` load relations without N+1 queries | — | — | ⬜ |
| TC-D09 | I | Verify payment status transition logic | Recording payments moves `Published` → `Partially Paid` → `Paid` correctly | — | — | ⬜ |
| TC-D10 | J | Verify activity log entries | Each create, update, cancel, delete, restore creates a corresponding `activityLog` entry | — | — | ⬜ |
| TC-D11 | K | Verify policy gates are checked | Removing a permission causes the matching controller action to return 403 | — | — | ⬜ |
| TC-D12 | L | Verify all routes are registered | `php artisan route:list` contains `fee-invoice.*` routes with correct methods and controllers | — | — | ⬜ |
| TC-D13 | M | Verify `lockForUpdate()` in invoice number generation | `generateInvoiceNumber()` uses `DB::transaction` with `lockForUpdate()` to prevent duplicate invoice numbers | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|---|
| TC-CR01 | CR | P1 | Model `$fillable` matches `fee_invoices` DDL columns | All writable columns in DDL are present; no extra non-existent columns; `balance_amount` in fillable is flagged as a conflict with generated column | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` for booleans, integers, decimals, and dates | `decimal:2` casts for amounts, `date` for dates, `integer` for FKs, `string` for status | — | — | ◌ |
| TC-CR03 | CR | P1 | `SoftDeletes` trait correctly implemented | `FeeInvoice` uses `SoftDeletes`; trashed scope and restore work | — | — | ◌ |
| TC-CR04 | CR | P1 | Relationships defined per FK | `studentAssignment`, `installment`, `generator`, `canceller`, `transactions`, `fineTransactions` exist | — | — | ◌ |
| TC-CR05 | CR | P1 | Try-catch exception handling on write methods | `recordPayment()` wraps logic in try-catch; rollback occurs on failure | — | — | ◌ |
| TC-CR06 | CR | P1 | DB transactions on multi-step writes | `recordPayment()` uses explicit `DB::beginTransaction` / `commit` / `rollBack`; `generateInvoiceNumber()` uses `DB::transaction()` with `lockForUpdate()` | — | — | ◌ |
| TC-CR07 | CR | P1 | `Gate::authorize()` on every method | Every public controller method calls `Gate::authorize()` with the correct permission | — | — | ◌ |
| TC-CR08 | CR | P1 | Activity logged on all state changes | `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Cancelled` are logged with `invoice_no` | — | — | ◌ |
| TC-CR09 | CR | P1 | `toggleStatus()` method exists for registered route | Route `fee-invoice.toggleStatus` is registered but controller method is missing; document as a bug | — | — | ◌ |
| TC-CR10 | CR | P1 | Trash/restore/forceDelete flow | `onlyTrashed()`, `withTrashed()`, `restore()`, and `forceDelete()` are correctly used | — | — | ◌ |
| TC-CR11 | CR | P1 | Flash success/error response after writes | Each write method redirects with `success` or `error` flash message (exact strings verified) | — | — | ◌ |
| TC-CR12 | CR | P1 | Request validation rules cover all fields | Store, Update, Cancel, and Payment request classes validate all submitted fields | — | — | ◌ |
| TC-CR13 | CR | P1 | Policy methods and permission strings match routes | Policy defines `view`, `viewAny`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `status`, `email-schedule`, `remark`, `pdf` | — | — | ◌ |
| TC-CR14 | CR | P1 | Resource and custom routes registered | All routes from Section 9 are registered with correct verbs and controller methods | — | — | ◌ |
| TC-CR15 | CR | P2 | Blade `@can` directives on action buttons | Verify whether action buttons are gated by `@can` or only by status; document any gaps | — | — | ◌ |
| TC-CR16 | CR | P1 | Null-safe checks for relationship variables | Views use `??` fallback for student/user names, class/section, and installment | — | — | ◌ |
| TC-CR17 | CR | P2 | Verification of DomPDF template | `downloadPdf()` uses `fee-invoice.invoice-pdf` view; `sendEmail()` uses `fee-invoice.invoice-email` view; both generate valid PDFs | — | — | ◌ |

## 7. Detailed Test Steps

### Code Review TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-CR01 | Open `app/Models/FeeInvoice.php` | Compare each DDL column with `$fillable` | Every writable DDL column is present; `balance_amount` in fillable is flagged as conflict with generated column |
| TC-CR02 | Inspect `$casts` in `FeeInvoice.php` | Cross-check with DDL types | Amount fields use `decimal:2`; dates use `date`; FKs use `integer`; status uses `string` |
| TC-CR03 | Confirm `use SoftDeletes;` in `FeeInvoice.php` | Check `trashedFeeInvoice()` and `restore()` | Trait imported; methods use `onlyTrashed()` and `restore()` correctly |
| TC-CR04 | List all relationship methods in `FeeInvoice.php` | Verify FK parameter in each | `studentAssignment`, `installment`, `generator`, `canceller`, `transactions`, `fineTransactions` exist with correct FKs |
| TC-CR05 | Inspect `recordPayment()` | Verify try-catch block | `try { ... } catch (\Throwable $e) { DB::rollBack(); }` present; error flash on failure |
| TC-CR06 | Inspect `recordPayment()` and `generateInvoiceNumber()` | Verify DB transactions | `DB::beginTransaction()/commit()/rollBack()` in `recordPayment()`; `DB::transaction()` with `lockForUpdate()` in `generateInvoiceNumber()` |
| TC-CR07 | List every public method in `FeeInvoiceController.php` | Verify `Gate::authorize()` call | Each method begins with `Gate::authorize(...)` with correct permission string |
| TC-CR08 | Search for `activityLog(` calls in controller | Verify log payload includes `invoice_no` | Calls exist for `Created`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Cancelled` |
| TC-CR09 | Check `routes/web.php` for `fee-invoice.toggleStatus` | Search controller for `toggleStatus` | Route exists but method missing; file a bug |
| TC-CR10 | Inspect `trashedFeeInvoice()`, `restore()`, `forceDelete()` | Verify correct Eloquent methods | Uses `onlyTrashed()`, `withTrashed()`, `restore()`, `forceDelete()` |
| TC-CR11 | Inspect all write methods | Verify flash messages | Each redirect uses `->with('success', ...)` or `back()->with('error', ...)` with exact strings |
| TC-CR12 | Open all four request files | Compare `rules()` with form fields | Every submitted form field has a validation rule |
| TC-CR13 | Open `FeeInvoicePolicy.php` | Verify permission strings | Strings match `tenant.fee-invoice.*` pattern including `email-schedule` (kebab-case) |
| TC-CR14 | Run `php artisan route:list --path=fee-invoice` | Verify routes | All routes from Section 9 listed with correct verbs and controllers; model binding is `{fee_invoice}` |
| TC-CR15 | Open `index.blade.php` and `show.blade.php` | Check for `@can` directives | Document whether action buttons use `@can` or rely solely on status checks |
| TC-CR16 | Inspect all invoice views | Search for null-safe operators | Fallbacks such as `?? '-'` are used for student, user, installment |

### 7.1 Positive TC Steps

#### TC-P01: Load Billing Tab with Invoices

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as user with `tenant.student-fee-management.viewAny` | Dashboard loads |
| 2 | Navigate to `GET /student-fee/billing` | Billing tab loads with invoice grid |
| 3 | Verify grid shows invoices | Invoice cards display invoice numbers, student names, totals, balances, and status badges |

#### TC-P02: Empty State When No Invoices

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure current session has no invoices | Query returns empty collection |
| 2 | Navigate to `GET /student-fee/billing` | Message "No invoices found for the current session." is displayed |

#### TC-P03 through TC-P10: Search and Filter

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-P03 | Enter known invoice number in search | Click Search | Grid shows only matching invoices |
| TC-P04 | Enter known student name in search | Click Search | Grid shows only matching invoices |
| TC-P05 | Select `Draft` status filter | Click Search | Only Draft invoices shown |
| TC-P06 | Select `Published` status filter | Click Search | Only Published invoices shown |
| TC-P07 | Select `Partially Paid` status filter | Click Search | Only Partially Paid invoices shown |
| TC-P08 | Select `Paid` status filter | Click Search | Only Paid invoices shown |
| TC-P09 | Select `Overdue` status filter | Click Search | Only Overdue invoices shown |
| TC-P10 | Select `Cancelled` status filter | Click Search | Only Cancelled invoices shown |

#### TC-P11: Pagination Navigation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 16 invoices in the current session | Billing tab shows page 1 with 15 invoices |
| 2 | Click page 2 link | Page 2 shows the 16th invoice |
| 3 | Apply a status filter and navigate pages | Pagination links preserve the status query string |

#### TC-P12: Card/List View Toggle

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load the Billing tab | Card view is visible by default |
| 2 | Click list view button | List view table appears; card view hidden |
| 3 | Reload the page | List view remains active due to localStorage preference |

#### TC-P13: Create Published Invoice with Required Fields

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `GET /student-fee/fee-invoice/create` | Create form loads |
| 2 | Select an active student assignment | Base amount auto-fills from `data-base` attribute |
| 3 | Leave installment as `None` | `installment_id` will be null |
| 4 | Keep dates default, select status `Published` | Fields populated |
| 5 | Submit form | Redirect to show page with flash `Invoice created successfully.`; invoice status `Published` |

#### TC-P14: Create Draft Invoice with All Fields

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Navigate to create form | Form loads |
| 2 | Select assignment, installment, dates, and status `Draft` | All fields populated |
| 3 | Enter concession, fine, and tax amounts | Values accepted |
| 4 | Submit | Invoice created as `Draft` with computed total |

#### TC-P15: Auto-Fill Base Amount from Assignment

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open create form | Base amount field is empty |
| 2 | Select an assignment with known total fee | `base_amount` populated with assignment's `total_fee_amount` |

#### TC-P16 through TC-P30: (Steps follow the same pattern as table structure above)

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-P16 | Open edit for Draft invoice | — | Student/base_amount read-only; other fields editable |
| TC-P17 | Change status to `Published` | Submit | Redirect with `Invoice updated successfully.`; status `Published` |
| TC-P18 | Click invoice number in grid | — | Show page with student info, breakdown, payment history, action buttons |
| TC-P19 | Open `GET /student-fee/fee-invoice/{id}/invoice/view` | — | Browser preview with print and PDF buttons |
| TC-P20 | Open `GET /student-fee/fee-invoice/{id}/pdf` | — | Download of `invoice-{invoice_no}.pdf` |
| TC-P21 | Record payment = balance amount | Submit | Transaction created; status `Paid`; balance ₹0.00 |
| TC-P22 | Record payment < balance | Submit | Status `Partially Paid`; balance reduced |
| TC-P23 | Cancel Published invoice with reason | Submit | Status `Cancelled`; canceller and reason recorded |
| TC-P24 | Click Generate All Invoices | — | Flash queued message appears |
| TC-P25 | Navigate to trash view | — | Soft-deleted invoices listed |
| TC-P26 | Click Restore | — | Invoice restored; flash success |
| TC-P27 | Click Force Delete on trashed invoice | — | Invoice permanently removed |
| TC-P28 | Click Email on published invoice | — | PDF saved; notification dispatched; flash success |
| TC-P29 | Click WhatsApp on published invoice | — | Redirects to `https://wa.me/...` with message |
| TC-P30 | Create → edit → partial → full → delete | — | All steps succeed sequentially |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-N01 | Submit create with empty assignment | — | `The student assignment id field is required.` |
| TC-N02 | Submit with non-existent assignment ID | — | `The selected student assignment id is invalid.` |
| TC-N03 | Clear invoice_date and submit | — | `The invoice date field is required.` |
| TC-N04 | Set due_date before invoice_date | Submit | `must be a date after or equal to invoice date.` |
| TC-N05 | Clear base_amount and submit | — | `The base amount field is required.` |
| TC-N06 | Enter `-100` in base_amount | Submit | `must be at least 0.` |
| TC-N07 | Set status to `Paid` on create | Submit | `The selected status is invalid.` |
| TC-N08 | Clear due_date and submit | — | `The due date field is required.` |
| TC-N09 | Create and fully pay invoice | Submit edit | `Cannot edit a Paid or Cancelled invoice.` |
| TC-N10 | Create and cancel invoice | Submit edit | `Cannot edit a Paid or Cancelled invoice.` |
| TC-N11 | Record payment on `Paid` invoice | — | `Cannot record payment for a paid or cancelled invoice.` |
| TC-N12 | Record payment on `Cancelled` invoice | — | `Cannot record payment for a paid or cancelled invoice.` |
| TC-N13 | Submit payment with amount = 0 | — | `must be at least 0.01.` |
| TC-N14 | Submit payment with mode = `Crypto` | — | `The selected payment mode is invalid.` |
| TC-N15 | Cancel `Paid` invoice | — | `Invoice is already paid or cancelled.` |
| TC-N16 | Cancel already cancelled invoice | — | `Invoice is already paid or cancelled.` |
| TC-N17 | Delete `Paid` invoice | — | `Cannot delete a paid invoice.` |
| TC-N18 | Login without view permission | Open show | 403 Forbidden |
| TC-N19 | Login without create permission | Open create | 403 Forbidden |
| TC-N20 | Login without update permission | Submit edit | 403 Forbidden |
| TC-N21 | Log out | Open billing | Redirect to `/login` |
| TC-N22 | Navigate to `/fee-invoice/999999` | — | 404 Not Found |
| TC-N23 | Remove active session | Click Generate | `No active academic session found.` |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-D01 | Create invoice with total=₹50,000, paid=0 | Record ₹20,000 payment | `balance_amount` auto-updates to ₹30,000.00 via generated column |
| TC-D02 | Soft-delete an invoice | Restore it | `deleted_at` populated on delete, null on restore; appears in active grid |
| TC-D03 | Identify an invoice's student_assignment_id | Delete parent assignment row | MySQL error due to RESTRICT FK |
| TC-D04 | Identify invoice with non-null installment_id | Delete parent installment | Invoice's `installment_id` set to NULL |
| TC-D05 | Identify invoice's generated_by user | Delete user | MySQL error due to RESTRICT FK |
| TC-D06 | Create invoice with a transaction | Force-delete invoice | MySQL error (RESTRICT on transactions.invoice_id) |
| TC-D07 | Create invoice with fine transaction | Force-delete invoice | MySQL error (RESTRICT on fine_transactions.invoice_id) |
| TC-D08 | Enable query logging | Load show page | No N+1 queries for student, user, installment, transactions |
| TC-D09 | Create Published invoice (₹30,000) | Record ₹5,000 then ₹25,000 | Status: Published → Partially Paid → Paid |
| TC-D10 | Create, update, cancel, delete, restore, force delete | Inspect activity_log | Each action creates log entry with correct event type |
| TC-D11 | Revoke update permission | Submit edit/cancel/payment | All return 403 |
| TC-D12 | Run `php artisan route:list --name=fee-invoice` | — | All 18 routes listed with correct methods |
| TC-D13 | Call `generateInvoiceNumber()` concurrently | — | `lockForUpdate()` prevents duplicate invoice numbers |

## 8. Known Issues

| KI ID | Issue | Severity | Details |
|---|---|---|---|
| KI-01 | `toggleStatus` route is registered but method is missing in controller | High | `POST /student-fee/fee-invoice/{fee_invoice}/toggle-status` will return 500 because `FeeInvoiceController::toggleStatus()` does not exist. Either implement the method or remove the route. |
| KI-02 | `balance_amount` is a generated column but is included in `$fillable` and written by the controller | Medium | DDL defines `balance_amount` as `GENERATED ALWAYS AS (total_amount - paid_amount) STORED`. Writing to it in `store()` and `update()` may be ignored or raise a database error. |
| KI-03 | `Bank Transfer` payment mode is not in the DDL enum | Medium | `RecordFeeInvoicePaymentRequest` allows `Bank Transfer`, but `fee_transactions.payment_mode` enum is `Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet`. This will cause an insert failure. |
| KI-04 | Email and WhatsApp action buttons are missing from views | Low | Controller methods `sendEmail()` and `sendWhatsapp()` exist and routes are registered, but neither `index.blade.php` nor `show.blade.php` provide UI buttons. They are only accessible by direct URL. |
| KI-05 | Unused policy permissions | Low | `tenant.fee-invoice.email-schedule` and `tenant.fee-invoice.pdf` are defined in policy but controller uses `update` for email/WhatsApp and `view` for PDF download. |
| KI-06 | Over-payment is not blocked | Low | `RecordFeeInvoicePaymentRequest` does not enforce `max:balance_amount`. The controller's `updatePayment()` will accept any positive amount and mark the invoice `Paid`. |
| KI-07 | `fee-invoice.index` view lacks `@can` directives | Low | Action buttons are shown/hidden based on invoice status rather than user permissions. Users without update/delete permissions may see Edit/Cancel/Delete buttons that result in 403 when clicked. |

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|---|---|---|---|---|
| GET | `/student-fee/billing` | `student-fee.billing` | `StudentFeeManagementController::billing` | `tenant.student-fee-management.viewAny` |
| GET | `/student-fee/fee-invoice` | `student-fee.fee-invoice.index` | `FeeInvoiceController::index` | `tenant.fee-invoice.view` |
| GET | `/student-fee/fee-invoice/create` | `student-fee.fee-invoice.create` | `FeeInvoiceController::create` | `tenant.fee-invoice.create` |
| POST | `/student-fee/fee-invoice` | `student-fee.fee-invoice.store` | `FeeInvoiceController::store` | `tenant.fee-invoice.create` |
| GET | `/student-fee/fee-invoice/{fee_invoice}` | `student-fee.fee-invoice.show` | `FeeInvoiceController::show` | `tenant.fee-invoice.view` |
| GET | `/student-fee/fee-invoice/{fee_invoice}/edit` | `student-fee.fee-invoice.edit` | `FeeInvoiceController::edit` | `tenant.fee-invoice.update` |
| PUT | `/student-fee/fee-invoice/{fee_invoice}` | `student-fee.fee-invoice.update` | `FeeInvoiceController::update` | `tenant.fee-invoice.update` |
| DELETE | `/student-fee/fee-invoice/{fee_invoice}` | `student-fee.fee-invoice.destroy` | `FeeInvoiceController::destroy` | `tenant.fee-invoice.delete` |
| POST | `/student-fee/fee-invoice/generate/all` | `student-fee.fee-invoice.generate` | `FeeInvoiceController::generateFeeInvoice` | `tenant.fee-invoice.create` |
| GET | `/student-fee/fee-invoice/trash/view` | `student-fee.fee-invoice.trashed` | `FeeInvoiceController::trashedFeeInvoice` | `tenant.fee-invoice.restore` |
| GET | `/student-fee/fee-invoice/{id}/restore` | `student-fee.fee-invoice.restore` | `FeeInvoiceController::restore` | `tenant.fee-invoice.restore` |
| DELETE | `/student-fee/fee-invoice/{id}/force-delete` | `student-fee.fee-invoice.forceDelete` | `FeeInvoiceController::forceDelete` | `tenant.fee-invoice.forceDelete` |
| POST | `/student-fee/fee-invoice/{fee_invoice}/toggle-status` | `student-fee.fee-invoice.toggleStatus` | — (missing) | `tenant.fee-invoice.status` (policy only) |
| GET | `/student-fee/fee-invoice/{fee_invoice}/invoice/view` | `student-fee.fee-invoice.invoice` | `FeeInvoiceController::invoice` | `tenant.fee-invoice.view` |
| GET | `/student-fee/fee-invoice/{fee_invoice}/pdf` | `student-fee.fee-invoice.pdf` | `FeeInvoiceController::downloadPdf` | `tenant.fee-invoice.view` |
| POST | `/student-fee/fee-invoice/{fee_invoice}/email` | `student-fee.fee-invoice.email` | `FeeInvoiceController::sendEmail` | `tenant.fee-invoice.update` |
| POST | `/student-fee/fee-invoice/{fee_invoice}/whatsapp` | `student-fee.fee-invoice.whatsapp` | `FeeInvoiceController::sendWhatsapp` | `tenant.fee-invoice.update` |
| PUT | `/student-fee/fee-invoice/{fee_invoice}/cancel` | `student-fee.fee-invoice.cancel` | `FeeInvoiceController::cancel` | `tenant.fee-invoice.update` |
| POST | `/student-fee/fee-invoice/{fee_invoice}/record-payment` | `student-fee.fee-invoice.recordPayment` | `FeeInvoiceController::recordPayment` | `tenant.fee-invoice.update` |

## 10. Execution Status

### 10.1 Summary

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---|---|---|---|---|---|---|
| Positive | 30 | 0 | 0 | 0 | 0 | 30 |
| Negative | 23 | 0 | 0 | 0 | 0 | 23 |
| Dependency | 13 | 0 | 0 | 0 | 0 | 13 |
| Code Review | 17 | 0 | 0 | 0 | 0 | 17 |
| **Total** | **83** | **0** | **0** | **0** | **0** | **83** |

### 10.2 Per-TC Status

| TC ID | Test Name | Type | Status | Date | Tester | Remarks |
|---|---|---|---|---|---|---|
| TC-P01 | Load Billing Tab with Invoices | Positive | ⬜ | — | — | — |
| TC-P02 | Empty State When No Invoices | Positive | ⬜ | — | — | — |
| TC-P03 | Search by Invoice Number | Positive | ⬜ | — | — | — |
| TC-P04 | Search by Student Name | Positive | ⬜ | — | — | — |
| TC-P05 | Filter by Draft Status | Positive | ⬜ | — | — | — |
| TC-P06 | Filter by Published Status | Positive | ⬜ | — | — | — |
| TC-P07 | Filter by Partially Paid Status | Positive | ⬜ | — | — | — |
| TC-P08 | Filter by Paid Status | Positive | ⬜ | — | — | — |
| TC-P09 | Filter by Overdue Status | Positive | ⬜ | — | — | — |
| TC-P10 | Filter by Cancelled Status | Positive | ⬜ | — | — | — |
| TC-P11 | Pagination Navigation | Positive | ⬜ | — | — | — |
| TC-P12 | Card/List View Toggle | Positive | ⬜ | — | — | — |
| TC-P13 | Create Published Invoice with Required Fields | Positive | ⬜ | — | — | — |
| TC-P14 | Create Draft Invoice with All Fields | Positive | ⬜ | — | — | — |
| TC-P15 | Auto-Fill Base Amount from Assignment | Positive | ⬜ | — | — | — |
| TC-P16 | Edit Invoice Load | Positive | ⬜ | — | — | — |
| TC-P17 | Update Invoice Draft to Published | Positive | ⬜ | — | — | — |
| TC-P18 | Show Invoice Detail | Positive | ⬜ | — | — | — |
| TC-P19 | Print Invoice Preview | Positive | ⬜ | — | — | — |
| TC-P20 | Download Invoice PDF | Positive | ⬜ | — | — | — |
| TC-P21 | Record Full Payment | Positive | ⬜ | — | — | — |
| TC-P22 | Record Partial Payment | Positive | ⬜ | — | — | — |
| TC-P23 | Cancel Invoice | Positive | ⬜ | — | — | — |
| TC-P24 | Bulk Generate Invoices | Positive | ⬜ | — | — | — |
| TC-P25 | Trash List | Positive | ⬜ | — | — | — |
| TC-P26 | Restore Invoice | Positive | ⬜ | — | — | — |
| TC-P27 | Force Delete Invoice | Positive | ⬜ | — | — | — |
| TC-P28 | Send Invoice via Email | Positive | ⬜ | — | — | — |
| TC-P29 | Send Invoice via WhatsApp | Positive | ⬜ | — | — | — |
| TC-P30 | Full Lifecycle | Positive | ⬜ | — | — | — |
| TC-N01 | Create Invoice Without Student Assignment | Negative | ⬜ | — | — | — |
| TC-N02 | Create Invoice With Invalid Assignment ID | Negative | ⬜ | — | — | — |
| TC-N03 | Create Invoice Without Invoice Date | Negative | ⬜ | — | — | — |
| TC-N04 | Due Date Before Invoice Date | Negative | ⬜ | — | — | — |
| TC-N05 | Create Invoice Without Base Amount | Negative | ⬜ | — | — | — |
| TC-N06 | Negative Base Amount | Negative | ⬜ | — | — | — |
| TC-N07 | Invalid Status on Create | Negative | ⬜ | — | — | — |
| TC-N08 | Create Invoice Without Due Date | Negative | ⬜ | — | — | — |
| TC-N09 | Edit Paid Invoice | Negative | ⬜ | — | — | — |
| TC-N10 | Edit Cancelled Invoice | Negative | ⬜ | — | — | — |
| TC-N11 | Record Payment on Paid Invoice | Negative | ⬜ | — | — | — |
| TC-N12 | Record Payment on Cancelled Invoice | Negative | ⬜ | — | — | — |
| TC-N13 | Record Payment Amount Zero | Negative | ⬜ | — | — | — |
| TC-N14 | Record Payment Invalid Mode | Negative | ⬜ | — | — | — |
| TC-N15 | Cancel Paid Invoice | Negative | ⬜ | — | — | — |
| TC-N16 | Cancel Already Cancelled Invoice | Negative | ⬜ | — | — | — |
| TC-N17 | Delete Paid Invoice | Negative | ⬜ | — | — | — |
| TC-N18 | Missing View Permission | Negative | ⬜ | — | — | — |
| TC-N19 | Missing Create Permission | Negative | ⬜ | — | — | — |
| TC-N20 | Missing Update Permission | Negative | ⬜ | — | — | — |
| TC-N21 | Guest Access | Negative | ⬜ | — | — | — |
| TC-N22 | Non-Existent Invoice ID | Negative | ⬜ | — | — | — |
| TC-N23 | Bulk Generate Without Active Session | Negative | ⬜ | — | — | — |
| TC-D01 | Balance Amount Generated Column | Dependency | ⬜ | — | — | — |
| TC-D02 | Soft Delete and Restore | Dependency | ⬜ | — | — | — |
| TC-D03 | FK Restrict on Student Assignment Delete | Dependency | ⬜ | — | — | — |
| TC-D04 | FK Set Null on Installment Delete | Dependency | ⬜ | — | — | — |
| TC-D05 | FK Restrict on Generator User Delete | Dependency | ⬜ | — | — | — |
| TC-D06 | FK Restrict on Invoice Delete (Transactions) | Dependency | ⬜ | — | — | — |
| TC-D07 | FK Restrict on Invoice Delete (Fine Transactions) | Dependency | ⬜ | — | — | — |
| TC-D08 | Model Relationship Eager Loading | Dependency | ⬜ | — | — | — |
| TC-D09 | Payment Status Transitions | Dependency | ⬜ | — | — | — |
| TC-D10 | Activity Log Entries | Dependency | ⬜ | — | — | — |
| TC-D11 | Policy Gate Coverage | Dependency | ⬜ | — | — | — |
| TC-D12 | Route Registration | Dependency | ⬜ | — | — | — |
| TC-D13 | Invoice Number lockForUpdate | Dependency | ⬜ | — | — | — |
| TC-CR01 | Model Fillable Matches DDL | Code Review | ◌ | — | — | — |
| TC-CR02 | Model Casts Verification | Code Review | ◌ | — | — | — |
| TC-CR03 | SoftDeletes Trait Implementation | Code Review | ◌ | — | — | — |
| TC-CR04 | Model Relationships Defined | Code Review | ◌ | — | — | — |
| TC-CR05 | Try-Catch Exception Handling | Code Review | ◌ | — | — | — |
| TC-CR06 | DB Transactions on Multi-Step Writes | Code Review | ◌ | — | — | — |
| TC-CR07 | Gate Authorize on Every Method | Code Review | ◌ | — | — | — |
| TC-CR08 | Activity Logged on State Changes | Code Review | ◌ | — | — | — |
| TC-CR09 | Toggle Status Method Exists | Code Review | ◌ | — | — | — |
| TC-CR10 | Trash/Restore/ForceDelete Flow | Code Review | ◌ | — | — | — |
| TC-CR11 | Flash Success/Error After Writes | Code Review | ◌ | — | — | — |
| TC-CR12 | Request Validation Rules Cover Fields | Code Review | ◌ | — | — | — |
| TC-CR13 | Policy Methods and Permission Strings | Code Review | ◌ | — | — | — |
| TC-CR14 | Resource and Custom Routes Registered | Code Review | ◌ | — | — | — |
| TC-CR15 | Blade @can Directives on Buttons | Code Review | ◌ | — | — | — |
| TC-CR16 | Null-Safe Checks for Relationships | Code Review | ◌ | — | — | — |
| TC-CR17 | DomPDF Template Verification | Code Review | ◌ | — | — | — |

**Legend:** `⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)`
