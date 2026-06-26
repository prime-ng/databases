# Book Issue Screen — Requirement Document

## 1. Screen Purpose & Overview
The Book Issue screen functions as a circulation desk terminal used by librarians to check out physical materials to members. The system performs real-time verification checks on member eligibility (including suspension states, fine thresholds, and overdue items) and copy availability before saving the checkout transaction.

---

## 2. Common Business Use Cases
1. **Standard Member Checkout:** Scanning a student’s library card, verifying their account status is clear, scanning a borrowable book copy, and printing or emailing the calculated return due date.
2. **Locking Suspended Members:** Throwing a hard block if a member attempts a checkout while their account is suspended due to outstanding fines.
3. **Locking Overdue Holders:** Blocking checkouts for users who are currently holding overdue books.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_transactions`
*   **Primary Key**: `id` (bigint, auto-increment)

The following columns are updated or populated during the book issuing process:

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `copy_id` | `bigint` | No | N/A | FK to `lib_book_copies.id` (copy being checked out). |
| `member_id` | `bigint` | No | N/A | FK to `lib_members.id` (borrowing member). |
| `issued_by_id` | `bigint` | No | N/A | FK to `sys_users.id` (staff processing transaction). |
| `issue_condition_id` | `bigint` | No | N/A | FK to `lib_book_conditions.id` (condition at issue). |
| `issue_date` | `datetime` | No | N/A | Timestamp of checkout transaction. |
| `due_date` | `date` | No | N/A | Expected return date. |
| `status` | `enum` | No | `'Issued'` | Set to `'Issued'` upon creation. |
| `notes` | `text` | Yes | `NULL` | Remarks or staff notes. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Member Barcode** | Text Input / Scan | Yes | Must correspond to an active barcode in `lib_members.library_card_barcode`. | None |
| **Copy Barcode** | Text Input / Scan | Yes | Must correspond to a copy in `lib_book_copies.barcode` with status `'available'`. | None |
| **Issue Condition** | Dropdown | Yes | Select active type from `lib_book_conditions`. | Prefilled to copy's current condition |
| **Remarks** | Text Area | No | Max 255 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Circulation Eligibility (Hard Blocks):**
   * **Active Membership Check:** The member's status must be `'active'`. Expired, suspended, or deactivated accounts are blocked.
   * **Fine Threshold Check:** The member's outstanding fines (`lib_members.outstanding_fines`) must not exceed the limit configured in their membership type (`lib_membership_types.max_unpaid_fines`):
     $$\text{Blocked} \iff \text{outstanding\_fines} > \text{max\_unpaid\_fines}$$
   * **Overdue Items Check:** If the member has any open transaction with a status of `'Overdue'`, checkout is blocked.
   * **Volume Limit Check:** The total count of open checkouts (`status = 'Issued' OR status = 'Overdue'`) plus the current scans must not exceed `lib_membership_types.max_borrow_limit`.
2. **Copy Verification Check:** The scanned copy status must be `'available'`. Copies marked as `'issued'`, `'reserved'`, `'lost'`, `'under_maintenance'`, or `'withdrawn'` are rejected.
3. **Due Date Calculation:** The due date is computed based on the member's profile limits:
   $$\text{Due Date} = \text{Issue Date} + \text{lib\_membership\_types.loan\_duration\_days}$$
4. **Copy Status Update:** Once the transaction is saved, the status of the related `lib_book_copies` record must immediately toggle to `'issued'`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Book Issue tab at `/library-mgt/transactions`.

### Scenario A: Happy Path Checkout
1. Scan Member Barcode: `BC-990881` (Jane Doe - Active Student).
2. Observe Jane's profile details and clear status appear on-screen.
3. Scan Copy Barcode: `BC-GATS-001` (*The Great Gatsby* - Available).
4. Verify that the Issue Condition defaults to "Good".
5. Click **"Process Issue"**.
6. **Expected Result**: Success notification displays, copy status becomes `'issued'` in backend, and transaction is created with the correct due date.

### Scenario B: Fine Limit Blocked Validation
1. Select or set up a member whose `outstanding_fines` is `$15.00` (Membership Type fine cap is `$10.00`).
2. Scan Member Barcode.
3. **Expected Result**: Screen immediately highlights a validation block: *"Checkout Blocked: Member has outstanding fines exceeding the allowable threshold."* The copy barcode scanner is disabled.

### Scenario C: Overdue Book Blocked Validation
1. Select a member who has a book that is 5 days overdue.
2. Scan Member Barcode.
3. **Expected Result**: System displays checkout block error: *"Checkout Blocked: Member currently has overdue items in possession."*

### Scenario D: Max Borrow Limit Blocked Validation
1. Select a member with 3 checked out books (their membership limit is 3).
2. Scan Member Barcode.
3. Scan Copy Barcode.
4. **Expected Result**: Processing fails, showing error: *"Checkout Blocked: Member has reached their maximum borrowing limit."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Book Issue Tab)
* **Tab Selector**: `@book-issue-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-issue-tab')
            ->type('member_barcode', 'BC-990881')
            ->press('@verify-member-btn')
            ->waitForText('Jane Doe')
            ->type('copy_barcode', 'BC-GATS-001')
            ->select('issue_condition_id', $this->goodCondition->id)
            ->press('@issue-submit-btn')
            ->assertSee('Transaction completed successfully');
});
```

### 3. Suspended Member Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-issue-tab')
            ->type('member_barcode', 'BC-SUSPENDED-99')
            ->press('@verify-member-btn')
            ->assertSee('Checkout Blocked: Member has outstanding fines');
});
```
