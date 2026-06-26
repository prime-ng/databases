# Transactions History Log — Requirement Document

## 1. Screen Purpose & Overview
This screen provides a read-only audit console to track the lifecycle of library resources. It records changes in circulation states (issues, returns, renewals, lost copy adjustments, and wear-and-tear condition updates) stored in the transaction history ledger (`lib_transaction_history`). It helps administrators monitor operator activity and review past book movement timelines.

---

## 2. Common Business Use Cases
1. **Circulation Auditing:** Reviewing who checked out and returned a specific copy of a book, including precise timestamps and the operators who handled the physical items.
2. **Investigating Renewal Limits:** Checking historical renewal records to verify if a copy was renewed beyond standard limits.
3. **Tracking Wear-and-Tear History:** Checking why a copy's condition was downgraded by examining the old and new condition json values.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_transaction_history`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `transaction_id` | `bigint` | No | N/A | FK to `lib_transactions.id`. |
| `performed_by_id` | `bigint` | No | N/A | FK to `sys_users.id` (staff operator). |
| `action_type` | `enum` | No | N/A | Values: `'issued'`, `'returned'`, `'renewed'`, `'marked_lost'`, `'condition_updated'`. |
| `old_value` | `json` | Yes | `NULL` | State representation of the record before the action. |
| `new_value` | `json` | Yes | `NULL` | State representation of the record after the action. |
| `performed_at` | `datetime` | No | `now()` | Timestamp of the logged event. |
| `notes` | `text` | Yes | `NULL` | Audit remarks or comments. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Update timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
Since this is a read-only console, input fields are limited to search and query filters:

| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Search Keyword** | Text Input | No | Optional. Filters list by Transaction ID, Member Name, or Book Title. | None |
| **Action Type** | Dropdown | No | Choice of: *All*, *Issued*, *Returned*, *Renewed*, *Marked Lost*, *Condition Updated*. | *All* |
| **Performed By (Staff)** | Dropdown | No | Choice of active operators. | *All Operators* |
| **Date From** | Date Picker | No | Filter records performed $\ge$ this date. | None |
| **Date To** | Date Picker | No | Must be $\ge$ **Date From** if both are provided. | None |

---

## 5. Business Logic & Validation Policies
1. **Audit Immutability Policy:** The transaction history log is designed as an append-only ledger. There are no insert forms, update endpoints, or delete buttons available on this screen. Any direct SQL attempts to alter this table must be flagged by backend policy rules.
2. **Circulation Logging Hooks:** Whenever a circulation event occurs, a background job or event listener must write a record to `lib_transaction_history`.
3. **JSON State Serialization:** For actions like `'condition_updated'`, the `old_value` and `new_value` columns must serialize model attributes to JSON (e.g. `{"condition": "Good"}` to `{"condition": "Damaged"}`).
4. **Calculated Volume Count:** The screen displays totals dynamically based on selected date filters:
   $$\text{Filtered Log Count} = \text{Count}(\text{lib\_transaction\_history records matching filters})$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the History & Audit section at `/library-mgt/history`.

### Scenario A: Happy Path Log Loading & Filtering
1. Open the Transaction History tab.
2. Verify that the table displays historical transactions with timestamps, action type labels, operator names, and notes.
3. Select Action Type: `Returned`.
4. **Expected Result**: Grid filters immediately via AJAX or page reload, showing only the returned transactions.

### Scenario B: Date Boundary Validation
1. Set the **Date From** picker to today.
2. Set the **Date To** picker to yesterday.
3. Click **"Apply Filters"**.
4. **Expected Result**: Validation fails, displaying: *"Date To must be a date after or equal to Date From."*

### Scenario C: Immutability Verification
1. Access the console as a standard librarian.
2. Verify there are no edit/delete buttons, checkboxes, or options to alter the rows.
3. Attempt to send a manual PUT/DELETE request to `/api/library/transaction-history/1`.
4. **Expected Result**: The server rejects the request with an HTTP `405 Method Not Allowed` or `403 Forbidden` error.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/history` (History Tab)
* **Tab Selector**: `@history-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/history')
            ->click('@history-tab')
            ->waitFor('@history-table')
            ->select('action_type', 'returned')
            ->press('@apply-filters-btn')
            ->assertSee('returned')
            ->assertDontSee('issued'); // Assert filter is active
});
```

### 3. Date Validation Failure Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/history')
            ->click('@history-tab')
            ->type('date_from', '2026-05-23')
            ->type('date_to', '2026-05-20') // Earlier date
            ->press('@apply-filters-btn')
            ->assertSee('must be a date after or equal to');
});
```
