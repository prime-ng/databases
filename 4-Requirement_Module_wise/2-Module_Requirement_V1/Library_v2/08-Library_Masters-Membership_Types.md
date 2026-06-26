# Library Membership Types — Requirement Document

## 1. Screen Purpose & Overview
Maintains privilege rules (book checkout caps, loan durations, grace periods, default fine rates) mapped to user classes (e.g., `Student`, `Staff`, `Premium Member`). It governs transaction rules on issue/return screens.

---

## 2. Common Business Use Cases
1. **Configuring Student Membership:** 5 books limit, 14-day loan, 2 grace days, ₹5/day late fee.
2. **Configuring Staff Membership:** 10 books limit, 30-day loan, 5 grace days, ₹2/day late fee.
3. **Grace Period Extension**: Changing grace periods during exam schedules.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_membership_types`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique privilege identifier key. Has unique index. |
| `name` | `varchar(100)` | No | N/A | Membership category display label. |
| `max_books_allowed`| `integer` | No | `0` | Max number of books a member can check out. |
| `loan_period_days` | `integer` | No | `14` | Duration of single loan before fine begins. |
| `renewal_allowed` | `boolean` | No | `1` | True if books can be renewed without return. |
| `max_renewals` | `integer` | Yes | `NULL` | Max renewal iterations. |
| `fine_rate_per_day`| `decimal(8,2)`| No | `0.00` | Fine rate charged per day past due. |
| `grace_period_days`| `integer` | No | `0` | Number of days past due before fine starts accumulating. |
| `priority_level` | `integer` | No | `0` | Sort precedence flag. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Membership Code** | Text Input | Yes | Unique. Max 30 chars. Alphanumeric. E.g., `STD_REG`. | None |
| **Membership Name** | Text Input | Yes | Max 100 chars. | None |
| **Max Books Allowed** | Number Input | Yes | Integer $\ge 0$. | `0` |
| **Loan Period Days** | Number Input | Yes | Integer $> 0$. | `14` |
| **Renewals Allowed** | Checkbox | No | Boolean. | Checked (True) |
| **Max Renewals** | Number Input | No | Integer $\ge 0$. Required if Renewals Allowed is Checked. | None |
| **Fine Rate Per Day** | Number Input | Yes | Decimal $\ge 0.00$. | `0.00` |
| **Grace Period Days** | Number Input | Yes | Integer $\ge 0$. | `0` |
| **Priority Level** | Number Input | Yes | Integer $\ge 0$. | `0` |

---

## 5. Business Logic & Validation Policies
1. **Unique Code:** Code must be unique. Duplicate codes fail validation.
2. **Grace Period Constraint:** Grace days must be less than or equal to standard loan period days.
3. **Renewal Enforcements:** If `renewal_allowed` is checked, `max_renewals` must be defined and $> 0$.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Membership Types** tab.

### Scenario A: Happy Path Create
1. Click **"Add Membership Type"**.
2. Enter Code: `STD_REG`.
3. Enter Name: `Regular Student`.
4. Enter Max Books: `3`. Enter Loan Period: `14` days.
5. Check **"Renewals Allowed"** and enter Max Renewals: `2`.
6. Enter Fine Rate: `5.00`. Enter Grace Period: `2`.
7. Click **"Save"**.
8. **Expected Result**: Redirects to index, success alert displays, and `Regular Student` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Membership Type"**.
2. Enter Loan Period: `-5` (negative).
3. Enter Grace Period: `20` (exceeds loan period).
4. Click **"Save"**.
5. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The loan period days must be greater than 0."*
   * *"The grace period days must not exceed standard loan period days."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `Regular Student` in the list (if present).
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Membership Types Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@membership-types-tab')
            ->click('@add-membership-type-btn')
            ->type('code', 'MEM-TEST')
            ->type('name', 'Test Membership')
            ->type('max_books_allowed', '5')
            ->type('loan_period_days', '14')
            ->type('fine_rate_per_day', '10.00')
            ->type('grace_period_days', '3')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-membership-type-btn')
            ->type('loan_period_days', '-5') // Negative days
            ->press('@save-btn')
            ->assertSee('must be greater than 0');
});
```
