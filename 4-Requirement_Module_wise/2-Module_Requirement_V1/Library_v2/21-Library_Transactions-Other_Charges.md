# Other Charges — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the manual posting of miscellaneous, non-circulation library fees (such as replacement costs for lost volumes, repair fees for damaged covers, or processing charges) linked to a specific transaction. It creates custom penalty entries in `lib_fines` and instantly updates the outstanding balance of the associated member.

---

## 2. Common Business Use Cases
1. **Charging a Damaged Book Fee:** Post check-in assessment determines that a book copy’s binding is severely torn. A librarian posts a repair fee of $20.00 linked to the return transaction.
2. **Levying a Processing Charge:** Posting administrative fees for processing a replaced catalog card or handling a special external acquisition request.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_fines`
*   **Primary Key**: `id` (bigint, auto-increment)

The following columns are populated when registering miscellaneous other charges:

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `transaction_id` | `bigint` | No | N/A | FK linking to the related `lib_transactions.id`. |
| `member_id` | `bigint` | No | N/A | FK linking to the target `lib_members.id`. |
| `fine_type` | `enum` | No | N/A | Values: `'Late Return'`, `'Lost Book'`, `'Damaged Book'`, `'Processing Fee'`. |
| `amount` | `decimal(10,2)` | No | N/A | Cash amount levied for the charge. |
| `days_overdue` | `unsigned int` | No | `0` | Set to `0` for manual miscellaneous charges. |
| `calculated_from` | `date` | No | N/A | Date bounds tracking fee duration (usually defaults to today). |
| `calculated_to` | `date` | No | N/A | Date bounds tracking fee duration (usually defaults to today). |
| `status` | `enum` | No | `'Pending'` | Preset status for new charges. |
| `notes` | `text` | Yes | `NULL` | Explanation of the manual charge details. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Transaction** | Dropdown | Yes | Must select a valid record from `lib_transactions` list. | None |
| **Member** | Dropdown | Yes | Must select an active record from `lib_members`. | None |
| **Charge Type** | Dropdown | Yes | Options: `Lost Fee` (Lost Book), `Processing Fee` (Processing Fee), `Other` (Damaged Book). | None |
| **Amount** | Number Input | Yes | Decimal value $\ge 0.01$. | None |
| **Calculated From** | Date Picker | Yes | Standard date. | Today's Date |
| **Calculated To** | Date Picker | Yes | Must be after or equal to **Calculated From**. | Today's Date |
| **Notes** | Text Area | No | Detailed explanation of fee (max 1000 characters). | None |

---

## 5. Business Logic & Validation Policies
1. **Transaction Link Constraint:** Contrary to older offline workflows, the database structure requires `transaction_id` to be a non-null foreign key linked to a valid transaction. Manual charges must be associated with the loan record under which the copy was borrowed or returned.
2. **Direct Balance Accrual:** Saving a new charge updates the member's outstanding fine record:
   $$\text{Outstanding Fines}_{\text{new}} = \text{Outstanding Fines}_{\text{old}} + \text{Amount}$$
3. **Internal Code Mapping:** Input selection strings must map to correct database enum parameters:
   * `"Lost Fee"` $\to$ `'Lost Book'`
   * `"Processing Fee"` $\to$ `'Processing Fee'`
   * `"Other"` $\to$ `'Damaged Book'`
4. **Accounting Integration Event:** Creating a manual fine triggers an automatic call to the application ledger event processor (`RemoteEntryService::processEvent` under event code `LIB_LOST_BOOK_FINE`, `LIB_DAMAGED_BOOK_FINE`, or similar) to post double-entry balances in the finance module.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/transactions` and select the **Other Charges** tab.
* Click **"Add Other Charge"** to open the modal form.

### Scenario A: Happy Path Post Damage Charge
1. Select Transaction: `#142 - Introduction to Java - John Doe`.
2. Select Member: `John Doe`.
3. Choose Charge Type: `Other` (Damaged Book Fee).
4. Enter Amount: `15.00`.
5. Enter Notes: *"Binding damaged, requires tape and cover re-lamination."*
6. Keep dates as today's date.
7. Click **"Save Charge"**.
8. **Expected Result**: Fine record is posted, member's outstanding fine balance is incremented by `$15.00`, and a success notice displays.

### Scenario B: Validation Failures
1. Click **"Add Other Charge"**.
2. Leave **Transaction** and **Member** unselected.
3. Enter Amount: `-5.00` (Negative) or `0.00`.
4. Click **"Save Charge"**.
5. **Expected Result**: Submission fails. Form error states display:
   * *"The transaction id field is required."*
   * *"The member id field is required."*
   * *"The amount must be at least 0.01."*

### Scenario C: Accounting Entry Audit Verify
1. Add a charge for a member and save.
2. Verify that `lib_members.outstanding_fines` has increased.
3. Check the application log or developer logs to confirm `RemoteEntryService` successfully fired a webhook/event for the posted fine.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Other Charges Tab/Pane)
* **Tab Selector**: `@other-charges-tab`
* **Modal Selector**: `#otherChargesModal`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@other-charges-tab')
            ->click('@add-charge-btn') // Opens modal
            ->waitFor('#otherChargesModal')
            ->select('transaction_id', $this->activeTransaction->id)
            ->select('member_id', $this->studentMember->id)
            ->select('fine_type', 'Other')
            ->type('amount', '20.00')
            ->press('@save-charge-btn')
            ->assertSee('Fine created successfully');
});
```

### 3. Missing Inputs Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@other-charges-tab')
            ->click('@add-charge-btn')
            ->waitFor('#otherChargesModal')
            ->type('amount', '0.00') // Invalid amount
            ->press('@save-charge-btn')
            ->assertSee('The transaction id field is required')
            ->assertSee('The member id field is required');
});
```
