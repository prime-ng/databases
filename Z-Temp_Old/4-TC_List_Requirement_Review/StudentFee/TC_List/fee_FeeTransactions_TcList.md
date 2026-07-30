# fee_FeeTransactions_TcList

## Module: StudentFee → Payment → Fee Transactions

## 1. Feature Information

| Item | Details |
|---|---|
| Module / Tab Group / Feature | StudentFee / Payment / Fee Transactions |
| URL(s) | `GET /student-fee/payment` (route `student-fee.payment`)<br>`GET /student-fee/fee-transaction` (route `student-fee.fee-transaction.index`)<br>`GET /student-fee/fee-transaction/{fee_transaction}` (route `student-fee.fee-transaction.show`)<br>`GET /student-fee/fee-transaction/{id}/receipt` (route `student-fee.fee-transaction.receipt`) |
| Controller | `Modules\StudentFee\Http\Controllers\StudentFeeManagementController::payment()` loads the tab grid.<br>`Modules\StudentFee\Http\Controllers\FeeTransactionController` handles the redirect, show, and receipt download (`index()`, `show()`, `downloadReceipt()`). |
| Model(s) | `Modules\StudentFee\Models\FeeTransaction` (table: `fee_transactions`)<br>`Modules\StudentFee\Models\FeeTransactionDetail` (table: `fee_transaction_details`)<br>`Modules\StudentFee\Models\FeePaymentGatewayLog` (table: `fee_payment_gateway_logs`)<br>`Modules\StudentFee\Models\FeeReceipt` (table: `fee_receipts`) |
| Validation (Create) | None (read-only tab) |
| Validation (Update) | None (read-only tab) |
| Policy | `Modules\StudentFee\Policies\FeeTransactionPolicy` |
| Permissions | `tenant.fee-transaction.viewAny`, `tenant.fee-transaction.view`, `tenant.fee-transaction.create`, `tenant.fee-transaction.update`, `tenant.fee-transaction.delete`, `tenant.fee-transaction.restore`, `tenant.fee-transaction.forceDelete`, `tenant.fee-transaction.import`, `tenant.fee-transaction.export`, `tenant.fee-transaction.print`, `tenant.fee-transaction.status`, `tenant.fee-transaction.email-schedule`, `tenant.fee-transaction.remark`, `tenant.fee-transaction.pdf`. The tab also requires `tenant.student-fee-management.viewAny`. |
| Pagination | 15 records per page using the default Laravel `page` parameter for the transaction grid. The sibling receipt grid uses `receipt_page`. |
| Soft Deletes | Yes — `FeeTransaction` uses `Illuminate\Database\Eloquent\SoftDeletes`; the `fee_transactions` DDL has `deleted_at` TIMESTAMP NULL. No restore UI is exposed in this read-only screen. |
| Data Source | Transaction records are created by external payment flows (`FeeInvoiceController::recordPayment()`, online gateway callbacks, refund flows) and are displayed here. |
| Read-Only | Yes — no create/update/delete UI elements. The resource route is limited to `index` and `show`. |
| PDF Service | `Barryvdh\DomPDF\Facade\Pdf` for receipt download. |
| Receipt Auto-Generation | `downloadReceipt()` auto-creates `FeeReceipt` inside `DB::transaction()` if none exists. |

## 2. Pre-conditions

- Dusk environment variables are set: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`.
- The test tenant has the StudentFee module active and the `tenant.student-fee-management.viewAny` and `tenant.fee-transaction.view` permissions seeded.
- A role exists with the required permissions, and the test user is assigned to that role.
- Seed data includes at least one academic session, one class, one section, one student, one fee structure, one invoice, and fee transactions in each relevant status (`Success`, `Pending`, `Failed`, `Refunded`) and mode (`Cash`, `UPI`, `Cheque`, `DD`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`).
- For dependency tests, ensure the database enforces the foreign keys defined in `StudentFee_DDL_v4.sql`.
- Clean up test transactions and child rows before each test run to avoid duplicate `transaction_no` or `receipt_no` values.
- For receipt download tests, ensure `storage/app/public/` is writable for PDF generation.

## 3. Default Data Load

The grid is rendered by `StudentFeeManagementController::payment()` at `GET /student-fee/payment` (route `student-fee.payment`). Default filters are empty (`search`, `payment_mode`, `status` all empty strings).

| Data | Source | Query | Filters | Pagination |
|---|---|---|---|---|
| Fee Transactions grid | `payment()` | `FeeTransaction::with(['student.user','invoice','collector'])->latest('payment_date')` | `search` (transaction_no or student name), `payment_mode`, `status` | 15 per page (`page`) |
| Fee Receipts grid | `payment()` | `FeeReceipt::with(['transaction.student.user'])->latest('receipt_date')` | None | 15 per page (`receipt_page`) |

> **Data Source:** Transaction records are created by payment recording flows (invoice record payment, online gateway callbacks, refund flows) and are only displayed in this tab.

## 4. Test Data Strategy

- Create test transactions via the API/UI of the invoice record-payment flow or by direct database seeding, using the current tenant and academic session.
- Use transaction numbers in the pattern `TXN-YYYY-XXXXXX` where `XXXXXX` is padded to 6 digits and unique.
- Ensure at least one transaction per payment mode (`Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`) and per status (`Success`, `Pending`, `Failed`, `Refunded`).
- For pagination overflow, create at least 16 transactions so the second page is reachable.
- Create at least one transaction with a linked `FeeReceipt` and one without, to test receipt auto-generation.
- Clean up `fee_transactions`, `fee_transaction_details`, `fee_payment_gateway_logs`, and `fee_receipts` rows created by the test suite after execution.

## 5. Business Conditions

### 5.1 Database Schema — `fee_transactions`

| BC ID | Column | Type (DDL) | Constraints |
|---|---|---|---|
| BC-DB-01 | `id` | INT UNSIGNED | PK, auto-increment. |
| BC-DB-02 | `transaction_no` | VARCHAR(50) | NOT NULL, UNIQUE. |
| BC-DB-03 | `student_id` | INT UNSIGNED | NOT NULL, FK → `std_students.id` (`ON DELETE RESTRICT`), index `idx_transaction_student`. |
| BC-DB-04 | `invoice_id` | INT UNSIGNED | NOT NULL, FK → `fee_invoices.id` (`ON DELETE RESTRICT`). |
| BC-DB-05 | `guardian_id` | INT UNSIGNED | NULL, FK → `std_guardians.id` (`ON DELETE SET NULL`). |
| BC-DB-06 | `payment_date` | DATETIME | NOT NULL. |
| BC-DB-07 | `payment_mode` | ENUM | NOT NULL: `Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`. |
| BC-DB-08 | `payment_reference` | VARCHAR(100) | NULL, comment "Cheque/DD/Transaction ID". |
| BC-DB-09 | `bank_name` | VARCHAR(100) | NULL. |
| BC-DB-10 | `cheque_date` | DATE | NULL. |
| BC-DB-11 | `amount` | DECIMAL(12,2) | NOT NULL. |
| BC-DB-12 | `fine_adjusted` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| BC-DB-13 | `concession_adjusted` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| BC-DB-14 | `status` | ENUM | NOT NULL, DEFAULT `Pending`: `Success`, `Pending`, `Failed`, `Refunded`. |
| BC-DB-15 | `collected_by` | INT UNSIGNED | NOT NULL, FK → `sys_users.id` (`ON DELETE RESTRICT`). |
| BC-DB-16 | `remarks` | TEXT | NULL. |
| BC-DB-17 | `receipt_generated` | TINYINT(1) | NOT NULL, DEFAULT `0`. |
| BC-DB-18 | `receipt_id` | INT UNSIGNED | NULL, no FK constraint in DDL. |
| BC-DB-19 | `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| BC-DB-20 | `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |
| BC-DB-21 | `deleted_at` | TIMESTAMP | NULL, enables soft delete. |
| BC-DB-22 | Index `idx_transaction_date` | DATETIME | On `payment_date`. |
| BC-DB-23 | Index `idx_transaction_status` | ENUM | On `status`. |
| BC-DB-24 | Index `idx_transaction_mode` | ENUM | On `payment_mode`. |

> **Note:** The original requirement doc listed `payment_mode` values as `Cash`, `Cheque`, `Online`, `DD`, `Bank Transfer`. The DDL and the view filter use the wider set above. The code is the authoritative source.
>
> **Note:** The original requirement doc listed `collected_by` as nullable, but the DDL declares it `NOT NULL`.
>
> **Note:** The code model `FeeTransaction::guardian()` belongs to `User` (`sys_users`), but the DDL declares `guardian_id` against `std_guardians`. The model has no explicit `receipt()` relationship even though `receipt_id` is stored.

### 5.2 Database Schema — `fee_transaction_details`

| BC ID | Column | Type (DDL) | Constraints |
|---|---|---|---|
| BC-DB-25 | `id` | INT UNSIGNED | PK, auto-increment. |
| BC-DB-26 | `transaction_id` | INT UNSIGNED | NOT NULL, FK → `fee_transactions.id` (`ON DELETE CASCADE`). |
| BC-DB-27 | `head_id` | INT UNSIGNED | NOT NULL, FK → `fee_head_master.id` (`ON DELETE RESTRICT`). |
| BC-DB-28 | `amount` | DECIMAL(10,2) | NOT NULL. |
| BC-DB-29 | `fine_amount` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| BC-DB-30 | `concession_amount` | DECIMAL(10,2) | NOT NULL, DEFAULT `0.00`. |
| BC-DB-31 | `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| BC-DB-32 | `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |
| BC-DB-33 | `uq_trans_detail` | UNIQUE KEY | (`transaction_id`, `head_id`). |

> **Note:** The model sets `const UPDATED_AT = null`, so the `updated_at` column defined in the DDL will not be maintained by Eloquent updates.

### 5.3 Database Schema — `fee_payment_gateway_logs`

| BC ID | Column | Type (DDL) | Constraints |
|---|---|---|---|
| BC-DB-34 | `id` | INT UNSIGNED | PK, auto-increment. |
| BC-DB-35 | `transaction_id` | INT UNSIGNED | NULL, FK → `fee_transactions.id` (`ON DELETE SET NULL`). |
| BC-DB-36 | `gateway_name` | ENUM | NOT NULL: `Razorpay`, `Paytm`, `CCAvenue`, `BillDesk`, `Other`. |
| BC-DB-37 | `gateway_transaction_id` | VARCHAR(100) | NULL, index `idx_gateway_trans`. |
| BC-DB-38 | `order_id` | VARCHAR(100) | NULL, index `idx_gateway_order`. |
| BC-DB-39 | `payment_id` | VARCHAR(100) | NULL. |
| BC-DB-40 | `request_payload` | JSON | NULL. |
| BC-DB-41 | `response_payload` | JSON | NULL. |
| BC-DB-42 | `amount` | DECIMAL(12,2) | NOT NULL. |
| BC-DB-43 | `status` | VARCHAR(50) | NOT NULL, index `idx_gateway_status`. |
| BC-DB-44 | `error_message` | TEXT | NULL. |
| BC-DB-45 | `ip_address` | VARCHAR(45) | NULL. |
| BC-DB-46 | `user_agent` | TEXT | NULL. |
| BC-DB-47 | `created_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP`. |
| BC-DB-48 | `updated_at` | TIMESTAMP | NULL, DEFAULT `CURRENT_TIMESTAMP` ON UPDATE `CURRENT_TIMESTAMP`. |

### 5.4 Authorization

| BC ID | Permission | Behavior |
|---|---|---|
| BC-AUTH-01 | `tenant.student-fee-management.viewAny` | Without it, `GET /student-fee/payment` returns HTTP 403. |
| BC-AUTH-02 | `tenant.fee-transaction.view` | Without it, `GET /student-fee/fee-transaction/{id}` and `GET /student-fee/fee-transaction/{id}/receipt` return HTTP 403. |
| BC-AUTH-03 | `tenant.fee-transaction.view` | `GET /student-fee/fee-transaction` also requires it before redirecting to the payment tab. |
| BC-AUTH-04 | Guest access | Unauthenticated request to any route is redirected to `/login`. |

### 5.5 Business Logic

| BC ID | Condition | Expected Behavior |
|---|---|---|
| BC-BIZ-01 | Default load of `GET /student-fee/payment` | Loads `FeeTransaction` grid ordered by `payment_date` DESC, paginated 15 per page, no filters applied. |
| BC-BIZ-02 | Search by transaction number | Query filters where `transaction_no` LIKE `%search%`. |
| BC-BIZ-03 | Search by student name | Query filters where `student.user.name` LIKE `%search%`. |
| BC-BIZ-04 | Filter by `payment_mode` | Query filters `payment_mode = <selected value>`. |
| BC-BIZ-05 | Filter by `status` | Query filters `status = <selected value>`. |
| BC-BIZ-06 | Combine search, mode, and status | All active filters are applied together (AND). |
| BC-BIZ-07 | Transaction status badge | `Success` = success, `Pending` = warning, `Failed` = danger, `Refunded` = info, default = secondary. |
| BC-BIZ-08 | Receipt PDF button | The PDF button is rendered only when `status === 'Success'`. |
| BC-BIZ-09 | Download receipt | `downloadReceipt()` auto-creates a `FeeReceipt` if missing, then returns a PDF download. |
| BC-BIZ-10 | Direct `GET /student-fee/fee-transaction` | `FeeTransactionController::index()` authorizes and redirects to `student-fee.payment`. |
| BC-BIZ-11 | Receipt auto-creation atomicity | Both `FeeReceipt::create()` and transaction `update()` happen inside a single `DB::transaction()`. |

## 6. Test Case List

### 6.1 Display & Filter Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-P01 | Load the Payment tab with the default transaction grid. | The `Fee Transactions` tab is active and shows up to 15 transactions ordered by `payment_date` descending. | — | — | ⬜ |
| TC-P02 | Verify the transaction grid columns. | Each row shows student name, transaction number, invoice number, payment mode, amount, status badge, payment date, and a receipt PDF link for `Success` rows. | — | — | ⬜ |
| TC-P03 | Search by a transaction number substring. | Grid reloads showing only transactions whose `transaction_no` contains the substring. | — | — | ⬜ |
| TC-P04 | Search by a student name. | Grid reloads showing only transactions whose `student.user.name` contains the search text. | — | — | ⬜ |
| TC-P05 | Filter by payment mode `Cash`. | Grid shows only `Cash` transactions. | — | — | ⬜ |
| TC-P06 | Filter by payment mode `UPI`. | Grid shows only `UPI` transactions. | — | — | ⬜ |
| TC-P07 | Filter by payment mode `Cheque`. | Grid shows only `Cheque` transactions. | — | — | ⬜ |
| TC-P08 | Filter by status `Success`. | Grid shows only `Success` transactions. | — | — | ⬜ |
| TC-P09 | Filter by status `Pending`. | Grid shows only `Pending` transactions. | — | — | ⬜ |
| TC-P10 | Filter by status `Failed`. | Grid shows only `Failed` transactions. | — | — | ⬜ |
| TC-P11 | Filter by status `Refunded`. | Grid shows only `Refunded` transactions. | — | — | ⬜ |
| TC-P12 | Combine search, mode, and status filters. | Grid applies all selected filters together and updates pagination links. | — | — | ⬜ |
| TC-P13 | Pagination first and last page. | Clicking page numbers moves through the transaction list while preserving filter query strings. | — | — | ⬜ |
| TC-P14 | Empty state when no transactions match. | The grid shows the message `No transactions found.` | — | — | ⬜ |
| TC-P15 | Open a transaction detail page. | Clicking a transaction row navigates to `GET /student-fee/fee-transaction/{id}` and shows the detail view. | — | — | ⬜ |
| TC-P16 | Verify detail page sections. | The page displays Student & Invoice, Payment Details, Amount, Receipt, and Record Info sections. | — | — | ⬜ |
| TC-P17 | Receipt download button visible only for `Success`. | `Download Receipt` button appears for `Success`; non-Success rows show `—` in the grid and no button on the detail page. | — | — | ⬜ |
| TC-P18 | Download an existing receipt. | Clicking `Download Receipt` returns a PDF with filename `receipt-<receipt_no>.pdf`. | — | — | ⬜ |
| TC-P19 | Download receipt auto-generates a missing receipt. | For a `Success` transaction without a `FeeReceipt`, clicking download creates a receipt in the database and returns the PDF. | — | — | ⬜ |
| TC-P20 | Direct index route redirects to the Payment tab. | `GET /student-fee/fee-transaction` returns HTTP 302 to `/student-fee/payment`. | — | — | ⬜ |
| TC-P21 | Fee Receipts sibling tab loads. | Switching to the `Fee Receipts` tab shows generated receipts with sent-to-parent status. | — | — | ⬜ |
| TC-P22 | Detail page shows payment gateway log when present. | Transaction with linked `FeePaymentGatewayLog` displays gateway name, transaction ID, and status. | — | — | ⬜ |
| TC-P23 | Detail page shows transaction details (per-head split). | Transaction with linked `FeeTransactionDetail` rows displays head-wise amount, fine, and concession breakdown. | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|
| TC-N01 | Access `GET /student-fee/payment` without `tenant.student-fee-management.viewAny`. | HTTP 403 forbidden response. | — | — | ⬜ |
| TC-N02 | Access `GET /student-fee/fee-transaction/{id}` without `tenant.fee-transaction.view`. | HTTP 403 forbidden response. | — | — | ⬜ |
| TC-N03 | Access `GET /student-fee/fee-transaction/{id}/receipt` without `tenant.fee-transaction.view`. | HTTP 403 forbidden response. | — | — | ⬜ |
| TC-N04 | Guest (unauthenticated) request to any transaction route. | Redirected to `/login`. | — | — | ⬜ |
| TC-N05 | Show a transaction id that does not exist. | HTTP 404 page. | — | — | ⬜ |
| TC-N06 | Download receipt for a transaction id that does not exist. | HTTP 404 page. | — | — | ⬜ |
| TC-N07 | Filter by an invalid payment_mode value (e.g., `Online`). | Grid returns `No transactions found.` because the value does not match the DDL enum. | — | — | ⬜ |
| TC-N08 | Filter by an invalid status value (e.g., `Cancelled`). | Grid returns `No transactions found.` because the value does not match the DDL enum. | — | — | ⬜ |
| TC-N09 | SQL injection attempt in the search box. | Search is escaped via parameterized query; no error and no rows matching the literal string. | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|
| TC-D01 | A | Verify `fee_transactions.deleted_at` column exists and soft delete works. | Records can be soft-deleted and restored via Eloquent; the tab excludes them by default. | — | — | ⬜ |
| TC-D02 | B | Delete a transaction that has child details. | `fee_transaction_details` rows are cascade-deleted (`ON DELETE CASCADE`). | — | — | ⬜ |
| TC-D03 | C | Delete a student referenced by a transaction. | Database refuses deletion due to `ON DELETE RESTRICT` on `student_id`. | — | — | ⬜ |
| TC-D04 | C | Delete an invoice referenced by a transaction. | Database refuses deletion due to `ON DELETE RESTRICT` on `invoice_id`. | — | — | ⬜ |
| TC-D05 | D | Delete a guardian referenced by a transaction. | `guardian_id` is set to `NULL` (`ON DELETE SET NULL`). | — | — | ⬜ |
| TC-D06 | E | Delete a transaction referenced by a gateway log. | `fee_payment_gateway_logs.transaction_id` is set to `NULL` (`ON DELETE SET NULL`). | — | — | ⬜ |
| TC-D07 | F | Insert a duplicate `transaction_no`. | Database raises unique constraint violation. | — | — | ⬜ |
| TC-D08 | F | Insert a duplicate `(transaction_id, head_id)` pair in details. | Database raises unique constraint violation on `uq_trans_detail`. | — | — | ⬜ |
| TC-D09 | G | Insert an invalid `status` value into `fee_transactions`. | Database rejects the value because it is not in the enum (`Success`, `Pending`, `Failed`, `Refunded`). | — | — | ⬜ |
| TC-D10 | G | Insert an invalid `payment_mode` value into `fee_transactions`. | Database rejects the value because it is not in the enum (`Cash`, `Cheque`, `DD`, `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`). | — | — | ⬜ |
| TC-D11 | H | Open the show page for a transaction. | The controller eager-loads `student.user`, `invoice`, and `collector`. | — | — | ⬜ |
| TC-D12 | H | Show page for a transaction with a receipt. | The linked `FeeReceipt` is fetched via `FeeReceipt::where('transaction_id', $id)->first()`. | — | — | ⬜ |
| TC-D13 | H | Verify gateway log relationship on the model. | `FeeTransaction::gatewayLog()` returns a `HasOne` relationship. | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|---|---|---|---|---|---|---|---|
| TC-CR01 | CR | P1 | Model `$fillable` — verify `FeeTransaction` `$fillable` matches the DDL columns of `fee_transactions`. | All columns in `fillable` exist in DDL; no extra columns are mass-assignable. | — | — | ◌ |
| TC-CR02 | CR | P1 | Model `$casts` — verify decimal, date, datetime, and boolean casts in `FeeTransaction` and `FeeTransactionDetail`. | `amount`, `fine_adjusted`, `concession_adjusted`, `payment_date`, `receipt_generated`, etc. are correctly cast. | — | — | ◌ |
| TC-CR03 | CR | P1 | SoftDeletes trait — `FeeTransaction` uses `SoftDeletes` and `deleted_at` is nullable in DDL. | Trait is present and column is TIMESTAMP NULL. | — | — | ◌ |
| TC-CR04 | CR | P1 | Relationships — verify `FeeTransaction` defines `student`, `invoice`, `guardian`, `collector`, and `gatewayLog`. | Relationships return correct Eloquent types. | — | — | ◌ |
| TC-CR05 | CR | P1 | Gate authorization — every public controller method calls `Gate::authorize()` before processing. | `index()`, `show()`, and `downloadReceipt()` all authorize `tenant.fee-transaction.view`. | — | — | ◌ |
| TC-CR06 | CR | P1 | DB transaction — receipt auto-creation is wrapped in `DB::transaction()`. | A receipt is created and the transaction is updated atomically. | — | — | ◌ |
| TC-CR07 | CR | P1 | View null-safety — verify the show and receipt-pdf views use `??` fallbacks for optional relationships. | No `Trying to get property of non-object` errors when relations are missing. | — | — | ◌ |
| TC-CR08 | CR | P1 | Route registration — verify the resource route for `fee-transaction` is limited to `index` and `show`, and the custom receipt route is registered. | `php artisan route:list` shows only `index`, `show`, and `receipt`. | — | — | ◌ |
| TC-CR09 | CR | P2 | Action component links — verify index view action links do not produce 404/405 for missing edit/destroy methods. | Action component links are non-functional for this read-only controller. | — | — | ◌ |

## 7. Detailed Test Steps

### Code Review TC Steps

#### TC-CR01: Verify FeeTransaction Fillable Matches DDL

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `Modules/StudentFee/app/Models/FeeTransaction.php`. | `$fillable` array is visible. |
| 2 | Compare each element with the `fee_transactions` DDL columns. | Every `fillable` field exists in DDL; `id`, `created_at`, `updated_at`, `deleted_at` are not fillable. |
| 3 | Confirm `receipt_id` is fillable but no `receipt()` relationship is defined. | Noted for dependency tracking. |

#### TC-CR02: Verify Model Casts

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Inspect `$casts` in `FeeTransaction`, `FeeTransactionDetail`, and `FeePaymentGatewayLog`. | Decimal fields use `decimal:2`, booleans use `boolean`, dates/datetimes are cast, JSON payloads are cast to `array`. |
| 2 | Verify `payment_date` is cast as `datetime` and `cheque_date` as `date`. | Casts are present. |

#### TC-CR03: Verify SoftDeletes Implementation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Confirm `use SoftDeletes` in `FeeTransaction`. | Trait is imported and used. |
| 2 | Confirm `deleted_at` is TIMESTAMP NULL in the DDL. | DDL matches. |

#### TC-CR04: Verify Relationships

| Step # | Action | Expected Result |
|---|---|---|
| 1 | List relationships in `FeeTransaction`. | `student` (BelongsTo), `invoice` (BelongsTo), `guardian` (BelongsTo), `collector` (BelongsTo), `gatewayLog` (HasOne). |
| 2 | Confirm `FeeTransactionDetail::transaction()` and `head()` are defined. | Both BelongsTo relationships exist. |
| 3 | Confirm `FeePaymentGatewayLog::transaction()` is defined. | BelongsTo relationship exists. |

#### TC-CR05: Verify Gate Authorization

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Inspect `FeeTransactionController::index()`. | Calls `Gate::authorize('tenant.fee-transaction.view')`. |
| 2 | Inspect `FeeTransactionController::show()`. | Calls `Gate::authorize('tenant.fee-transaction.view')`. |
| 3 | Inspect `FeeTransactionController::downloadReceipt()`. | Calls `Gate::authorize('tenant.fee-transaction.view')`. |
| 4 | Inspect `StudentFeeManagementController::payment()`. | Calls `Gate::authorize('tenant.student-fee-management.viewAny')`. |

#### TC-CR06: Verify DB Transaction on Receipt Auto-Create

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Inspect `downloadReceipt()`. | The `if (!$receipt)` block wraps creation in `DB::transaction()`. |
| 2 | Confirm both the receipt create and the transaction update happen inside the closure. | Both `FeeReceipt::create()` and `$transaction->update()` are inside the transaction. |

#### TC-CR07: Verify View Null-Safe Checks

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `show.blade.php` and `receipt-pdf.blade.php`. | All optional relationships (`student.user`, `invoice`, `collector`, `receipt`) use `??` or `?->` or `@if` guards. |
| 2 | Confirm no raw property access on potentially null relations. | No unguarded `->name` access. |

#### TC-CR08: Verify Route Registration

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Run `php artisan route:list | grep fee-transaction`. | Only `index`, `show`, and `receipt` routes are listed. |
| 2 | Confirm the custom receipt route URI matches `fee-transaction/{id}/receipt`. | Output matches. |

#### TC-CR09: Verify Action Component Links

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open `index.blade.php` for fee-transaction. | Check for `<x-backend.table.action>` usage. |
| 2 | Verify that edit/destroy links (if present) would lead to 404/405. | Document as a known issue. |

### 7.1 Positive TC Steps

#### TC-P01: Load Payment Tab Default Grid

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as a user with `tenant.student-fee-management.viewAny` and `tenant.fee-transaction.view`. | Dashboard is visible. |
| 2 | Navigate to `GET /student-fee/payment`. | The `Fee Transactions` tab is active by default. |
| 3 | Verify the transaction list is visible. | Up to 15 transactions are shown, ordered by `payment_date` descending. |

#### TC-P02: Verify Transaction Grid Columns

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure at least one `Success` transaction exists. | Grid row is visible. |
| 2 | Inspect a row in the grid. | Student name, transaction number, invoice number, payment mode badge, amount, status badge, payment date, and a PDF download link are present. |
| 3 | Verify the status badge color matches the status. | `Success` = green, `Pending` = yellow, `Failed` = red, `Refunded` = blue. |

#### TC-P03: Search by Transaction Number

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Enter the substring `TXN-2026` in the search box. | Search box shows the text. |
| 2 | Click `Search`. | URL contains `search=TXN-2026`. |
| 3 | Verify the grid. | Only transactions with `transaction_no` containing `TXN-2026` are displayed. |

#### TC-P04: Search by Student Name

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Enter a known student first name in the search box. | Search box shows the text. |
| 2 | Click `Search`. | URL contains `search=<name>`. |
| 3 | Verify the grid. | Only transactions for students whose name contains the search text are displayed. |

#### TC-P05 through TC-P12: Filter Scenarios

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-P05 | Select `Cash` payment_mode | Click Search | Grid shows only Cash transactions |
| TC-P06 | Select `UPI` payment_mode | Click Search | Grid shows only UPI transactions |
| TC-P07 | Select `Cheque` payment_mode | Click Search | Grid shows only Cheque transactions |
| TC-P08 | Select `Success` status | Click Search | Grid shows only Success transactions |
| TC-P09 | Select `Pending` status | Click Search | Grid shows only Pending transactions |
| TC-P10 | Select `Failed` status | Click Search | Grid shows only Failed transactions |
| TC-P11 | Select `Refunded` status | Click Search | Grid shows only Refunded transactions |
| TC-P12 | Enter name + UPI + Success | Click Search | Grid shows only matching all three |

#### TC-P13: Pagination First and Last Page

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 16 or more transactions. | Pagination controls appear. |
| 2 | Click page `2`. | Second page loads; URL contains `page=2`. |
| 3 | Apply a filter and click page `2`. | URL contains both filter and `page=2`; results remain filtered. |

#### TC-P14: Empty State

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Apply a search string matching no transaction. | — |
| 2 | Click `Search`. | Grid displays `No transactions found.` |

#### TC-P15: Open Transaction Detail Page

| Step # | Action | Expected Result |
|---|---|---|
| 1 | From the grid, click a transaction row. | Navigates to `GET /student-fee/fee-transaction/{id}`. |
| 2 | Verify the page title. | The page shows `Transaction: <transaction_no>`. |

#### TC-P16: Verify Detail Page Sections

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open a transaction detail page. | Page loads without errors. |
| 2 | Verify sections. | `Student & Invoice`, `Payment Details`, `Amount`, `Receipt`, and `Record Info` sections are present. |
| 3 | Verify conditional fields. | `payment_reference`, `bank_name`, `cheque_date`, `fine_adjusted`, `concession_adjusted`, `remarks` appear only when non-empty. |

#### TC-P17: Receipt Download Button Visibility

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open detail page for a `Success` transaction. | `Download Receipt` button is visible. |
| 2 | Open detail page for a non-`Success` transaction. | No `Download Receipt` button rendered. |

#### TC-P18: Download Existing Receipt

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open a `Success` transaction that already has a `FeeReceipt` row. | Detail page shows receipt number and `Download Receipt` button. |
| 2 | Click `Download Receipt`. | Downloads PDF named `receipt-<receipt_no>.pdf`. |
| 3 | Open the PDF. | Receipt shows student name, invoice number, transaction number, payment mode, amounts, and status. |

#### TC-P19: Download Receipt Auto-Generates Missing Receipt

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open a `Success` transaction without a `FeeReceipt` row. | Detail page shows `No receipt generated` and the `Download Receipt` button. |
| 2 | Click `Download Receipt`. | `FeeReceipt` created with `receipt_no = RCP-YYYY-XXXXX`; PDF downloaded. |
| 3 | Re-open the detail page. | Receipt number and generated date are now shown. |

#### TC-P20: Direct Index Route Redirects to Payment

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Navigate to `GET /student-fee/fee-transaction`. | HTTP 302 redirect to `/student-fee/payment`. |

#### TC-P21: Fee Receipts Sibling Tab Loads

| Step # | Action | Expected Result |
|---|---|---|
| 1 | On the Payment page, click `Fee Receipts` tab. | Receipt list shown with student name, receipt number, transaction number, format, sent status, download icon. |

#### TC-P22: Gateway Log Displayed

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open detail page for a transaction with a gateway log. | Gateway name, transaction ID, and status displayed in a Gateway Log section. |

#### TC-P23: Transaction Details Displayed

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Open detail page for a transaction with per-head splits. | Head-wise breakdown table shows head name, amount, fine, concession. |

### 7.2 Negative TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-N01 | Login without viewAny permission | Open payment tab | HTTP 403 |
| TC-N02 | Login without view permission | Open show route | HTTP 403 |
| TC-N03 | Login without view permission | Download receipt | HTTP 403 |
| TC-N04 | Log out | Open any transaction route | Redirect to `/login` |
| TC-N05 | Open `GET /student-fee/fee-transaction/999999` | — | HTTP 404 |
| TC-N06 | Open `GET /student-fee/fee-transaction/999999/receipt` | — | HTTP 404 |
| TC-N07 | Craft URL `?payment_mode=Online` | — | Grid shows `No transactions found.` |
| TC-N08 | Craft URL `?status=Cancelled` | — | Grid shows `No transactions found.` |
| TC-N09 | Enter `'; DROP TABLE fee_transactions; --` in search | Click Search | No error; `No transactions found.`; table intact |

### 7.3 Dependency TC Steps

| TC ID | Step 1 | Step 2 | Expected Result |
|---|---|---|---|
| TC-D01 | Query DDL for fee_transactions columns | Soft-delete a transaction | `deleted_at` populated; row excluded from grid; restorable |
| TC-D02 | Create transaction with detail rows | Force-delete transaction | Detail rows cascade-deleted |
| TC-D03 | Identify student_id referenced by transaction | Delete student row | DB FK violation; delete fails |
| TC-D04 | Identify invoice_id referenced by transaction | Delete invoice row | DB FK violation; delete fails |
| TC-D05 | Create transaction with guardian_id set | Delete guardian row | `guardian_id` becomes NULL |
| TC-D06 | Create transaction with gateway log | Delete transaction | Gateway log remains; `transaction_id` becomes NULL |
| TC-D07 | Insert transaction with specific transaction_no | Insert duplicate | Unique constraint violation |
| TC-D08 | Insert detail (transaction_id, head_id) pair | Insert duplicate | `uq_trans_detail` violation |
| TC-D09 | Insert row with status = 'Cancelled' | — | DB rejects (invalid enum value) |
| TC-D10 | Insert row with payment_mode = 'Crypto' | — | DB rejects (invalid enum value) |
| TC-D11 | Enable query logging | Open show page | Single query with eager-loads; no N+1 |
| TC-D12 | Open show page for transaction with receipt | — | `FeeReceipt::where('transaction_id', $id)->first()` executed |
| TC-D13 | Attach FeePaymentGatewayLog to transaction | Call `with('gatewayLog')` | Relationship resolves correctly |

## 8. Known Issues

| KI ID | Issue | Severity | Details |
|---|---|---|---|
| KI-01 | Action component generates edit/delete links for a read-only controller | Medium | The index view uses `<x-backend.table.action :id="$txn->id" url="student-fee.fee-transaction" />`, which produces edit/destroy links, but the resource route is limited to `index` and `show`. Clicking those links results in 404 or 405 errors. |
| KI-02 | Receipt download does not validate transaction status | Medium | `FeeTransactionController::downloadReceipt()` does not check whether the transaction is `Success` before generating the PDF. The UI hides the button for non-Success, but a direct URL request can generate a receipt for `Pending` or `Failed` transactions. |
| KI-03 | `fee_transaction_details.updated_at` is not maintained by the model | Low | The DDL includes `updated_at`, but the model sets `const UPDATED_AT = null`, so Eloquent will not update that column. |
| KI-04 | `guardian_id` foreign-key target differs between model and DDL | Low | The DDL references `std_guardians.id`, while the model's `guardian()` relationship points to `Modules\SchoolSetup\Models\User` (`sys_users`). If data is not synchronized, the relationship may resolve incorrectly. |
| KI-05 | Payment mode vocabulary mismatch with original requirement | Low | Original requirement listed `Online` and `Bank Transfer`; DDL and view use `UPI`, `Credit Card`, `Debit Card`, `Net Banking`, `Wallet`. Code is authoritative. |
| KI-06 | `collected_by` is NOT NULL in DDL but was documented as nullable | Low | Schema requires a collector for every row. Controller is defensive with null-safe display, but inserts must supply a value. |

## 9. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|---|---|---|---|---|
| GET | `/student-fee/payment` | `student-fee.payment` | `StudentFeeManagementController::payment()` | `tenant.student-fee-management.viewAny` |
| GET | `/student-fee/fee-transaction` | `student-fee.fee-transaction.index` | `FeeTransactionController::index()` | `tenant.fee-transaction.view` |
| GET | `/student-fee/fee-transaction/{fee_transaction}` | `student-fee.fee-transaction.show` | `FeeTransactionController::show()` | `tenant.fee-transaction.view` |
| GET | `/student-fee/fee-transaction/{id}/receipt` | `student-fee.fee-transaction.receipt` | `FeeTransactionController::downloadReceipt()` | `tenant.fee-transaction.view` |

## 10. Execution Status

### 10.1 Summary

| Section | Total TCs | Executed | Passed | Failed | Blocked | Not Executed |
|---|---|---|---|---|---|---|
| 6.1 Display & Filter | 23 | 0 | 0 | 0 | 0 | 23 |
| 6.2 Negative | 9 | 0 | 0 | 0 | 0 | 9 |
| 6.3 Dependency | 13 | 0 | 0 | 0 | 0 | 13 |
| 6.4 Code Review | 9 | 0 | 0 | 0 | 0 | 9 |
| **Total** | **54** | **0** | **0** | **0** | **0** | **54** |

### 10.2 Per-TC Execution

| TC ID | Test Name | Type | Status | Date | Tester | Remarks |
|---|---|---|---|---|---|---|
| TC-P01 | Load Payment Tab Default Grid | Positive | ⬜ | — | — | — |
| TC-P02 | Verify Transaction Grid Columns | Positive | ⬜ | — | — | — |
| TC-P03 | Search by Transaction Number | Positive | ⬜ | — | — | — |
| TC-P04 | Search by Student Name | Positive | ⬜ | — | — | — |
| TC-P05 | Filter by Payment Mode Cash | Positive | ⬜ | — | — | — |
| TC-P06 | Filter by Payment Mode UPI | Positive | ⬜ | — | — | — |
| TC-P07 | Filter by Payment Mode Cheque | Positive | ⬜ | — | — | — |
| TC-P08 | Filter by Status Success | Positive | ⬜ | — | — | — |
| TC-P09 | Filter by Status Pending | Positive | ⬜ | — | — | — |
| TC-P10 | Filter by Status Failed | Positive | ⬜ | — | — | — |
| TC-P11 | Filter by Status Refunded | Positive | ⬜ | — | — | — |
| TC-P12 | Combine Search and Filters | Positive | ⬜ | — | — | — |
| TC-P13 | Pagination First and Last Page | Positive | ⬜ | — | — | — |
| TC-P14 | Empty State When No Transactions Match | Positive | ⬜ | — | — | — |
| TC-P15 | Open Transaction Detail Page | Positive | ⬜ | — | — | — |
| TC-P16 | Verify Detail Page Sections | Positive | ⬜ | — | — | — |
| TC-P17 | Receipt Download Button Visibility | Positive | ⬜ | — | — | — |
| TC-P18 | Download Existing Receipt | Positive | ⬜ | — | — | — |
| TC-P19 | Download Receipt Auto-Generates Missing Receipt | Positive | ⬜ | — | — | — |
| TC-P20 | Direct Index Route Redirects to Payment | Positive | ⬜ | — | — | — |
| TC-P21 | Fee Receipts Sibling Tab Loads | Positive | ⬜ | — | — | — |
| TC-P22 | Gateway Log Displayed | Positive | ⬜ | — | — | — |
| TC-P23 | Transaction Details Displayed | Positive | ⬜ | — | — | — |
| TC-N01 | Missing viewAny on Payment Tab | Negative | ⬜ | — | — | — |
| TC-N02 | Missing view on Show | Negative | ⬜ | — | — | — |
| TC-N03 | Missing view on Receipt | Negative | ⬜ | — | — | — |
| TC-N04 | Guest Access Redirects to Login | Negative | ⬜ | — | — | — |
| TC-N05 | Show Non-Existent Transaction | Negative | ⬜ | — | — | — |
| TC-N06 | Receipt for Non-Existent Transaction | Negative | ⬜ | — | — | — |
| TC-N07 | Invalid Payment Mode Filter | Negative | ⬜ | — | — | — |
| TC-N08 | Invalid Status Filter | Negative | ⬜ | — | — | — |
| TC-N09 | SQL Injection Search Attempt | Negative | ⬜ | — | — | — |
| TC-D01 | Soft Delete Column | Dependency | ⬜ | — | — | — |
| TC-D02 | Cascade Delete Details | Dependency | ⬜ | — | — | — |
| TC-D03 | Student Delete Restricted | Dependency | ⬜ | — | — | — |
| TC-D04 | Invoice Delete Restricted | Dependency | ⬜ | — | — | — |
| TC-D05 | Guardian Delete Sets Null | Dependency | ⬜ | — | — | — |
| TC-D06 | Gateway Log Sets Null | Dependency | ⬜ | — | — | — |
| TC-D07 | Unique Transaction Number | Dependency | ⬜ | — | — | — |
| TC-D08 | Unique Detail Pair | Dependency | ⬜ | — | — | — |
| TC-D09 | Status Enum Constraint | Dependency | ⬜ | — | — | — |
| TC-D10 | Payment Mode Enum Constraint | Dependency | ⬜ | — | — | — |
| TC-D11 | Show Eager Loads | Dependency | ⬜ | — | — | — |
| TC-D12 | Receipt Relationship Loaded | Dependency | ⬜ | — | — | — |
| TC-D13 | Gateway Log Relationship | Dependency | ⬜ | — | — | — |
| TC-CR01 | FeeTransaction Fillable Matches DDL | Code Review | ◌ | — | — | — |
| TC-CR02 | Model Casts | Code Review | ◌ | — | — | — |
| TC-CR03 | SoftDeletes Implementation | Code Review | ◌ | — | — | — |
| TC-CR04 | Relationships | Code Review | ◌ | — | — | — |
| TC-CR05 | Gate Authorization | Code Review | ◌ | — | — | — |
| TC-CR06 | DB Transaction on Receipt Create | Code Review | ◌ | — | — | — |
| TC-CR07 | View Null-Safe Checks | Code Review | ◌ | — | — | — |
| TC-CR08 | Route Registration | Code Review | ◌ | — | — | — |
| TC-CR09 | Action Component Links | Code Review | ◌ | — | — | — |

**Legend:** `⬜ = Pending Execution | ✅ = Passed | ❌ = Failed | ⛔ = Blocked | ◌ = Code Review (structure verified, not executed)`
