# Fee Collection — Requirement Document

## 1. Screen Purpose & Overview

The Fee Collection screen serves as the cashier terminal for recording student payments against outstanding transport fee details. It supports multiple payment modes (Cash, Cheque, NEFT, UPI), updates invoice balances, calculates actual payment delay days, and handles bank reconciliation states.

---

## 2. Common Business Use Cases

1. **Recording Cash Payments:** The cashier receives cash from a parent, inputs the amount, and prints a payment receipt.
2. **Logging Bank Transfers:** Recording an online NEFT transaction, logging bank reference IDs for later finance reconciliation.
3. **Cheque Clearance Actions:** Reconciling or bouncing a previously submitted cheque.

---

## 3. Database Schema & Data Dictionary

All fields map to the `tpt_student_fee_collection` table:

* `id` (INT UNSIGNED): Primary Key, Auto-increment.
* `student_fee_detail_id` (INT UNSIGNED): FK to `tpt_student_fee_detail`. Mapped invoice reference.
* `payment_date` (DATE): Date the payment transaction was completed.
* `total_delay_days` (INT): Total days elapsed between invoice due date and actual payment date.
* `paid_amount` (DECIMAL(10,2)): The financial amount received.
* `payment_mode` (VARCHAR(20)): Payment format ('Cash', 'Cheque', 'NEFT', 'UPI').
* `status` (VARCHAR(20)): Collection status ('Cleared', 'Processing', 'Bounced', 'Reconciled').
* `reconciled` (TINYINT): Reconciliation confirmation flag (0 = No, 1 = Yes).
* `remarks` (VARCHAR(512)): Cashier notes or bank references.
* `created_at` (TIMESTAMP): Creation date-time.
* `deleted_at` (TIMESTAMP): Set for soft deletes.

---

## 4. Screen Fields & Input Rules

| Field Name (Screen Label) | UI Control Type | Validation Rules & Constraints | Source Database Mapping |
| :--- | :--- | :--- | :--- |
| **Invoice Reference** | Dropdown | Required. Searchable list of pending `tpt_student_fee_detail`. | `student_fee_detail_id` |
| **Payment Date** | Datepicker | Required. Defaults to `CURRENT_DATE()`. | `payment_date` |
| **Amount Paid** | Number Input | Required. Decimal $> 0.00$ and $\le$ invoice balance. | `paid_amount` |
| **Payment Mode** | Dropdown | Required. Options: `Cash`, `Cheque`, `NEFT`, `UPI`. | `payment_mode` |
| **Transaction Ref** | Text Input | Required for `NEFT`, `UPI`, `Cheque`. Max 100 chars. | `remarks` |
| **Reconciled Status** | Toggle / Checkbox| Required. Default is 1 for Cash/UPI, 0 for Cheque. | `reconciled` |
| **Cashier Remarks** | Text Area | Optional. Max 512 characters. | `remarks` (appended) |

---

## 5. Business Logic & Validation Policies

### Overpayment Prevention
* The input `paid_amount` cannot exceed the outstanding invoice balance:
  $$\text{paid\_amount} \le \text{tpt\_student\_fee\_detail.total\_amount} - \text{SUM(previously\_collected)}$$

### Delay Calculations
* The system automatically computes delay days upon saving a payment:
  $$\text{total\_delay\_days} = \text{DATEDIFF\_DAYS}(\text{tpt\_student\_fee\_detail.due\_date}, \text{payment\_date})$$
  * If $\text{total\_delay\_days} \le 0 \implies \text{total\_delay\_days} = 0$.

### Invoice Status Progression
* Upon successful payment transaction:
  * If $\text{SUM(paid\_amount)} \ge \text{tpt\_student\_fee\_detail.total\_amount}$:
    $$\text{tpt\_student\_fee\_detail.status} = \text{'Paid'}$$
  * If $\text{SUM(paid\_amount)} < \text{tpt\_student\_fee\_detail.total\_amount}$:
    $$\text{tpt\_student\_fee\_detail.status} = \text{'Partially Paid'}$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Test Case 1: Record Full Cash Payment (Happy Path)
1. Go to `/transport/fee-collection` and click "+ New Payment".
2. Select Invoice Reference: Bobby's pending May invoice (outstanding: ₹1,800.00).
3. Set Payment Date: Today. Set Mode: `Cash`.
4. Enter Amount Paid: `1800.00`.
5. Set Reconciled: **Yes**. Click Save.
6. Verify:
   - Bobby's invoice status in `tpt_student_fee_detail` changes to `Paid`.
   - The payment ledger lists the cash transaction.

### Test Case 2: Validate Overpayment Block
1. Click "+ New Payment".
2. Select Bobby's invoice (now showing outstanding: ₹0.00).
3. Enter Amount Paid: `50.00`. Click Save.
4. Verify validation error: "Amount Paid cannot exceed the remaining outstanding balance (0.00)."

### Test Case 3: Cheque Clearance Workflow
1. Click "+ New Payment" for a student owing ₹1,800.00.
2. Select Mode: `Cheque`, enter Transaction Ref: "CHQ-123456", set Reconciled: **No**, click Save.
3. Verify:
   - Payment is saved with status `Processing`.
   - Mapped invoice status changes to `Partially Paid` or remains `Pending`.
4. Later, go to payments, click "Reconcile" on the row, set Reconciled to **Yes**, and save. Confirm invoice status is updated to `Paid`.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Key Element Selectors
* **Fee Collection Tab**: `@fee-collection-tab`
* **New Collection Button**: `@add-collection-btn`
* **Invoice Dropdown**: `select[name="student_fee_detail_id"]`
* **Payment Date Field**: `input[name="payment_date"]`
* **Amount Paid Field**: `input[name="paid_amount"]`
* **Payment Mode Dropdown**: `select[name="payment_mode"]`
* **Transaction Ref Field**: `input[name="transaction_reference"]`
* **Reconciled Toggle**: `input[name="reconciled"]`
* **Save Button**: `@save-collection-btn`

### 2. Dusk Integration Test Code Block

```php
namespace Tests\Browser;

use Tests\DuskTestCase;
use Laravel\Dusk\Browser;
use App\Models\User;

class TransportFeeCollectionTest extends DuskTestCase
{
    public function testRecordCollectionAndValidationRules()
    {
        $this->browse(function (Browser $browser) {
            $browser->loginAs(User::find(1))
                    ->visit('/transport/fee-collection')
                    ->click('@fee-collection-tab')
                    ->click('@add-collection-btn')
                    ->select('student_fee_detail_id', '1') // Select pending invoice
                    ->type('paid_amount', '5000.00') // Overpayment (assume balance is 1800)
                    ->select('payment_mode', 'UPI')
                    ->type('transaction_reference', 'TXN112233')
                    ->click('@save-collection-btn')
                    ->assertSee('Amount Paid cannot exceed the remaining outstanding balance')
                    
                    // Correcting amount
                    ->type('paid_amount', '1800.00')
                    ->click('@save-collection-btn')
                    ->assertSee('saved successfully');
        });
    }
}
```
