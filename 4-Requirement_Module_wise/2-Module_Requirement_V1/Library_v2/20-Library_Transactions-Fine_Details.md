# Fine Details Ledger — Requirement Document

## 1. Screen Purpose & Overview
This screen provides the detailed audit trail and payment terminal for library fines (`lib_fines`). It allows librarians to inspect penalty breakdowns (such as daily overdue rates or damage logs), accept fine payments via Cash or Online systems, record transactions in the payment ledger (`lib_fine_payments`), and automatically update member balances.

---

## 2. Common Business Use Cases
1. **Settling a Late Fee Balance:** Recording a Cash payment for a student's overdue book fine and generating a printed or emailed payment receipt.
2. **Accepting Partial Payments:** Registering a partial payment when a member pays a fraction of their fine, keeping the fine record in `Pending` or `Overdue` state.
3. **Auditing Fine Breakdown:** Opening a modal popup to check the specific dates and day-rate calculations before collecting funds.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_fines` (Source fine records)
*   **Table Name**: `lib_fine_payments` (Ledger payment records)

### Columns in `lib_fine_payments` (Created on payment):
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `fine_id` | `bigint` | No | N/A | FK linking to `lib_fines.id`. |
| `received_by_id` | `bigint` | No | N/A | FK to `sys_users.id` (staff receiving the payment). |
| `amount_paid` | `decimal(10,2)` | No | N/A | Numeric value of collected funds. |
| `payment_method` | `enum` | No | N/A | Values: `'Cash'`, `'Online'`, `'Transfer To Fee'`. |
| `payment_reference`| `varchar(100)`| Yes | `NULL` | Transaction reference code (e.g. gateway transaction ID). |
| `payment_date` | `datetime` | No | N/A | Timestamp of payment processing. |
| `receipt_number` | `varchar(50)` | No | N/A | Globally unique invoice receipt ID. |
| `notes` | `text` | Yes | `NULL` | Optional remarks. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Amount Paid** | Number Input | Yes | Decimal $> 0.00$. Must be $\le$ the remaining pending fine balance. | Prefilled with remaining balance |
| **Payment Method** | Dropdown | Yes | Choice of: `Cash`, `Online`, `Transfer To Fee`. | `Cash` |
| **Payment Reference**| Text Input | Conditional| Required if **Payment Method** is `Online`. Max 100 characters. | None |
| **Receipt Number** | Text Input | Yes | Unique alphanumeric. Max 50 characters. | Auto-generated |
| **Payment Notes** | Text Area | No | Max 500 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Pending Balance Calculation:** The remaining fine amount is computed dynamically:
   $$\text{Pending Balance} = \text{Amount} - \text{Waived Amount} - \sum(\text{Amount Paid})$$
2. **Double Payment Protection:** Fine payments are blocked if `lib_fines.status` is `'Paid'` or `'Waived'`.
3. **Overpayment Prevention:** The system blocks payments where `amount_paid > \text{Pending Balance}`.
4. **Member Outstanding Balance Updates:** Saving a payment triggers an automatic decrement on the member’s profile:
   $$\text{Outstanding Fines}_{\text{new}} = \text{Outstanding Fines}_{\text{old}} - \text{Amount Paid}$$
   If $\sum(\text{Amount Paid}) + \text{Waived Amount} == \text{Amount}$, the status of the related `lib_fines` record automatically updates to `'Paid'`.
5. **Receipt Number Uniqueness:** The `receipt_number` must be unique in `lib_fine_payments`, preventing receipt collision errors.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Fine Details / Ledger tab at `/library-mgt/transactions`.

### Scenario A: Processing Full Cash Payment (Happy Path)
1. Select a pending fine from the list (Jane Doe - $10.00 overdue fee).
2. Click **"Pay Fine"**.
3. Verify that **Amount Paid** defaults to `$10.00`.
4. Keep Payment Method as `Cash`.
5. Click **"Process Payment"**.
6. **Expected Result**: Ledger record is written, Jane Doe's `outstanding_fines` decreases by `$10.00` to `$0.00`, and the fine status displays as `'Paid'`.

### Scenario B: Processing Partial Online Payment
1. Select a pending fine of `$25.00`.
2. Click **"Pay Fine"**.
3. Enter Amount Paid: `15.00`.
4. Select Payment Method: `Online`.
5. Enter Payment Reference: `TXN-8800991`.
6. Click **"Process Payment"**.
7. **Expected Result**: Payment saves. The fine status remains `'Pending'` but lists a remaining unpaid balance of `$10.00`. Jane Doe's `outstanding_fines` decreases by `$15.00`.

### Scenario C: Overpayment Validation Failure
1. Select a pending fine of `$10.00`.
2. Click **"Pay Fine"**.
3. Enter Amount Paid: `15.00` (Greater than balance).
4. Click **"Process Payment"**.
5. **Expected Result**: Submission is rejected, displaying: *"Amount paid cannot exceed the pending fine balance."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Fine Ledger Tab)
* **Tab Selector**: `@fine-ledger-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@fine-ledger-tab')
            ->click('@pay-fine-btn-1') // Pay the first pending fine
            ->waitFor('#pay-fine-modal')
            ->type('amount_paid', '10.00')
            ->select('payment_method', 'Cash')
            ->type('receipt_number', 'RECEIPT-DUSK-001')
            ->press('@submit-payment-btn')
            ->assertSee('Payment processed successfully');
});
```

### 3. Payment Reference Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@fine-ledger-tab')
            ->click('@pay-fine-btn-1')
            ->waitFor('#pay-fine-modal')
            ->select('payment_method', 'Online')
            ->type('payment_reference', '') // Missing reference
            ->press('@submit-payment-btn')
            ->assertSee('The payment reference field is required when payment method is Online.');
});
```
