# Book Return Screen — Requirement Document

## 1. Screen Purpose & Overview
The Book Return screen functions as a circulation desk terminal used by librarians to process check-in transactions. When a physical copy is returned, the system scans its barcode, identifies the active loan transaction, calculates overdue durations, evaluates penalty rates based on active fine master slabs, handles manual fee waivers, and updates inventory status.

---

## 2. Common Business Use Cases
1. **On-Time Check-In:** Processing a return on or before the due date, returning the book status to `available` with zero fee generation.
2. **Late Return with Penalty:** Returning an overdue item, calculating overdue days, applying slab rules, writing a pending entry to `lib_fines`, and updating the member’s outstanding balance.
3. **Authorized Fine Waiving:** Processing an overdue return where a portion or all of the computed fee is waived due to extenuating circumstances (e.g. library closure or verified medical leave).
4. **Returning Damaged Materials:** Identifying that a copy is returned in a damaged condition, updating the copy condition record, and triggering a separate "Damaged Book" fine.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_transactions` (Updated during return)
*   **Table Name**: `lib_fines` (Created during return if overdue or damaged)

### Columns in `lib_transactions` Updated on Return:
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `received_by_id` | `bigint` | Yes | `NULL` | FK to `sys_users.id` (staff processing return). |
| `return_condition_id`| `bigint` | Yes | `NULL` | FK to `lib_book_conditions.id`. |
| `return_date` | `datetime` | Yes | `NULL` | Timestamp when physical return was processed. |
| `status` | `enum` | No | `'Issued'` | Updated to `'Returned'` or `'Lost'`. |

### Columns in `lib_fines` Created on Overdue/Damage:
| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Primary Key. |
| `transaction_id` | `bigint` | No | N/A | FK to `lib_transactions.id`. |
| `member_id` | `bigint` | No | N/A | FK to `lib_members.id`. |
| `fine_slab_config_id`| `bigint` | Yes | `NULL` | FK to `lib_fine_slab_config.id`. |
| `waived_by_id` | `bigint` | Yes | `NULL` | FK to `sys_users.id` (staff authorizing waiver). |
| `fine_type` | `enum` | No | N/A | Values: `'Late Return'`, `'Lost Book'`, `'Damaged Book'`, `'Processing Fee'`. |
| `amount` | `decimal(10,2)` | No | N/A | Generated penalty amount before waivers. |
| `days_overdue` | `unsigned int` | No | `0` | Number of calendar days past due. |
| `calculated_from` | `date` | No | N/A | Usually `due_date + 1`. |
| `calculated_to` | `date` | No | N/A | Date physical copy was returned. |
| `waived_amount` | `decimal(10,2)` | No | `0.00` | Excluded portion of the fine. |
| `waived_reason` | `text` | Yes | `NULL` | Required reason text if `waived_amount > 0`. |
| `waived_at` | `datetime` | Yes | `NULL` | Timestamp of waiver processing. |
| `status` | `enum` | No | `'Pending'` | Values: `'Pending'`, `'Paid'`, `'Waived'`, `'Overdue'`. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Scan Copy Barcode** | Text Input / Scan | Yes | Must correspond to an active checkout in `lib_transactions.status = 'Issued'`. | None |
| **Return Condition** | Dropdown | Yes | Select active type from `lib_book_conditions`. | Prefilled to copy's issue condition |
| **Apply Fine** | Checkbox | No | If unchecked, bypasses auto-fine generation. | Checked (True) |
| **Waive Fine** | Checkbox | No | Boolean. Enables the Waive Amount input. | Unchecked (False) |
| **Waived Amount** | Number Input | Conditional| Required if **Waive Fine** is checked. Decimal $\ge 0.00$ and $\le$ calculated fine. | `0.00` |
| **Waiver Reason** | Text Area | Conditional| Required if **Waived Amount** is $> 0.00$. Max 500 chars. | None |
| **Staff Return Notes** | Text Area | No | Max 1000 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Transaction Lookup Validation:** Scanning the book copy barcode must find a record in `lib_book_copies` with status `'issued'`. If not found, throws validation error: *"No active checkout transaction found for this copy."*
2. **Late Return Days Calculation:**
   $$\text{Days Overdue} = \max\left(0, \text{Return Date} - \text{Due Date}\right)$$
3. **Fine Slab Precedence Evaluation:** If $\text{Days Overdue} > 0$, the system retrieves the matching fine config according to priority rules and calculates cumulative rates:
   $$\text{Subtotal Fine} = \sum_{\text{slab } i} \max\left(0, \min(\text{Days Overdue}, \text{to\_day}_i) - \text{from\_day}_i + 1\right) \times \text{rate\_per\_day}_i$$
   The total is capped according to `max_fine_amount` (fixed limit, book replacement price, or unlimited).
4. **Member Balance Update:** The member's balance is updated on save:
   $$\text{Outstanding Fines}_{\text{new}} = \text{Outstanding Fines}_{\text{old}} + (\text{Subtotal Fine} - \text{Waived Amount})$$
5. **Condition Change Logic:** If the selected `return_condition_id` differs from the `issue_condition_id`, the system updates `lib_book_copies.current_condition_id`. If the condition is marked non-borrowable (`is_borrowable = 0`), the copy's status is set to `'under_maintenance'`; otherwise, it toggles back to `'available'`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Book Return tab at `/library-mgt/transactions`.

### Scenario A: Happy Path Return (On-Time)
1. Scan Copy Barcode: `BC-GATS-001` (Checked out with due date in future).
2. Verify checkout details (Jane Doe, Due Date) load on screen.
3. Keep Return Condition: `Good`.
4. Click **"Process Return"**.
5. **Expected Result**: Success alert displays, book copy status updates to `'available'`, and no fine record is created.

### Scenario B: Overdue Return with Fine Accrual
1. Locate or set up a checkout transaction for copy `BC-GATS-001` that is 5 days past due.
2. Scan Copy Barcode.
3. Observe calculated penalty shows (e.g. 5 days overdue $\times$ $2.00/day = $10.00).
4. Do not waive fine. Click **"Process Return"**.
5. **Expected Result**: Transaction is marked `'Returned'`. A new fine record is created in `lib_fines` with status `'Pending'` for `$10.00`, and Jane Doe's `outstanding_fines` increments by `$10.00`.

### Scenario C: Overdue Return with Fine Waiver
1. Scan barcode for a checkout transaction that is 10 days past due ($20.00 fine).
2. Check the **Waive Fine** checkbox.
3. Enter Waived Amount: `15.00`.
4. Leave Waiver Reason blank and click **"Process Return"**. (Fails validation).
5. Enter Waiver Reason: *"Closed due to storm"* and click **"Process Return"**.
6. **Expected Result**: Transaction completes. Copy returns to `'available'`. Fine record created with `$20.00` total, `$15.00` waived, and `$5.00` charged to member.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Book Return Tab)
* **Tab Selector**: `@book-return-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-return-tab')
            ->type('copy_barcode', 'BC-GATS-001')
            ->press('@load-transaction-btn')
            ->waitForText('Jane Doe')
            ->select('return_condition_id', $this->goodCondition->id)
            ->press('@return-submit-btn')
            ->assertSee('Return processed successfully');
});
```

### 3. Verification of Empty State Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-return-tab')
            ->type('copy_barcode', 'BC-AVAILABLE-002') // Not checked out
            ->press('@load-transaction-btn')
            ->assertSee('No active checkout transaction found for this copy.');
});
```
