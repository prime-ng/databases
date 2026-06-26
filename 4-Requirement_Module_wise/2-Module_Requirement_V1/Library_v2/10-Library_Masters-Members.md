# Library Members — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the registration and management of library members. It bridges system users (`sys_users`) with the library system by assigning them a membership profile. The module tracks membership categories, library card barcodes, validity dates, borrowing analytics, suspension status, and engagement metrics (such as lifetime value and churn risk).

---

## 2. Common Business Use Cases
1. **Onboarding a Library Member:** Selecting a system user (Student/Staff), linking them to a membership type, scanning or assigning a unique barcode card, and setting validity parameters.
2. **Account Status Monitoring:** Inspecting outstanding fines, checked-out volumes, and updating status to *Suspended* or *Deactivated* based on policy violations or manual requests.
3. **Tracking Engagement & Reading Goals:** Updating annual reading goals, monitoring progress, and tracking lifetime value (LTV).

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_members`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `user_id` | `bigint` | No | N/A | FK linking to `sys_users.id`. Globally unique (one membership per user). |
| `membership_type_id` | `bigint` | No | N/A | FK linking to `lib_membership_types.id`. |
| `membership_number` | `varchar(50)` | No | N/A | Unique human-readable membership identifier. |
| `library_card_barcode` | `varchar(100)` | Yes | `NULL` | Unique barcode scanned from the physical card. |
| `registration_date` | `date` | No | N/A | The date member was registered. |
| `expiry_date` | `date` | No | N/A | The date the membership expires. |
| `is_auto_renew` | `boolean` | No | `1` | Automatically renews membership if enabled. |
| `last_activity_date` | `date` | Yes | `NULL` | Date of last checkout, check-in, or login. |
| `total_books_borrowed` | `integer` | No | `0` | Cumulative total of borrowed books. |
| `total_fines_paid` | `decimal(10,2)` | No | `0.00` | Sum of all fines settled. |
| `outstanding_fines` | `decimal(10,2)` | No | `0.00` | Current unpaid fines balance. |
| `status` | `enum` | No | `'active'` | Values: `'active'`, `'expired'`, `'suspended'`, `'deactivated'`. |
| `suspension_reason` | `text` | Yes | `NULL` | Explanation of suspension when status is set to `'suspended'`. |
| `notes` | `text` | Yes | `NULL` | General notes or staff remarks. |
| `reading_level` | `enum` | Yes | `NULL` | Values: `'Beginner'`, `'Intermediate'`, `'Advanced'`, `'Expert'`. |
| `preferred_notification_channel` | `enum` | No | `'Email'` | Values: `'Email'`, `'SMS'`, `'Push'`, `'InApp'`. |
| `member_segment` | `varchar(50)` | Yes | `NULL` | Segmentation label (e.g., High-Value, At-Risk, Inactive, New). |
| `last_segment_calculation` | `timestamp` | Yes | `NULL` | Timestamp of last background analytics segmentation. |
| `engagement_score` | `decimal(5,2)` | No | `0.00` | System-calculated score representing library activity (0 to 100). |
| `churn_risk_score` | `decimal(5,2)` | No | `0.00` | Risk factor of member leaving or becoming inactive (0 to 100). |
| `lifetime_value` | `decimal(10,2)` | No | `0.00` | Total contribution: $\text{LTV} = \text{Total Fines Paid} + \text{Registration Fees}$. |
| `preferred_language` | `varchar(50)` | No | `'English'` | Preferred communication language. |
| `reading_goal_annual` | `integer` | No | `0` | Yearly target number of books to read. |
| `reading_progress_ytd` | `integer` | No | `0` | Current number of books read in the calendar year. |
| `is_active` | `boolean` | No | `1` | Soft switch for record visibility. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Update timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **System User** | Dropdown / Search | Yes | Must select an active user from `sys_users` not already linked to a membership. | None |
| **Membership Type** | Dropdown | Yes | Select active type from `lib_membership_types`. | None |
| **Membership Number** | Text Input | Yes | Unique alphanumeric code. Max 50 characters. | Auto-generated standard |
| **Card Barcode** | Text Input | No | Unique alphanumeric code. Max 100 characters. | None |
| **Registration Date** | Date Picker | Yes | Standard date format. | Today's Date |
| **Expiry Date** | Date Picker | Yes | Date must be strictly after Registration Date. | Today + 1 Year |
| **Auto-Renew** | Checkbox | No | Boolean toggle. | Checked (True) |
| **Status** | Dropdown | Yes | Choice of `'active'`, `'expired'`, `'suspended'`, `'deactivated'`. | `'active'` |
| **Suspension Reason** | Text Area | No | Required only if **Status** is set to `'suspended'`. Max 500 chars. | None |
| **Annual Reading Goal** | Number Input | No | Integer $\ge 0$. | `0` |
| **Preferred Language** | Dropdown | No | Standard locale choices (English, Spanish, Arabic, Hindi, etc.) | `'English'` |
| **Notification Channel**| Dropdown | No | Choice of Email, SMS, Push, InApp. | `'Email'` |
| **Staff Notes** | Text Area | No | Max 1000 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **One Profile Per User:** A system user (`sys_users.id`) can only be linked to a single record in `lib_members.user_id`.
2. **Barcode and Number Uniqueness:** Both `membership_number` and `library_card_barcode` must be unique across all members, bypassing current record ID on edits.
3. **Date Constraints:** The `expiry_date` must be chronologically after the `registration_date`.
4. **Auto-Suspension threshold:** If a member's `outstanding_fines` exceeds the allowable threshold defined in `lib_membership_types.max_unpaid_fines`, the status is automatically toggled to `'suspended'`.
5. **Borrowing Block Policy:** Members whose status is `'suspended'`, `'expired'`, or `'deactivated'` are completely blocked from checking out resources.
6. **Deletion Safe-Guards (Soft Delete):** A member cannot be soft-deleted if they currently have unreturned book copies (`lib_transactions.return_date IS NULL`) or unpaid outstanding fines (`outstanding_fines > 0`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and select the **Members** tab.

### Scenario A: Happy Path Onboarding Member
1. Click **"Add Member"**.
2. Select System User: `John Doe (Student)`.
3. Select Membership Type: `Standard Student`.
4. Leave Membership Number as default (auto-generated) or type `MEM-2026-001`.
5. Scan or type Barcode: `BC-990881`.
6. Set Registration Date to today.
7. Set Expiry Date to one year from today.
8. Click **"Save"**.
9. **Expected Result**: Member profile is successfully created, success alert displays, redirects back to index, and Jane Doe's library membership is active.

### Scenario B: Validation Failures
1. Click **"Add Member"**.
2. Select System User: `John Doe` (already has an active membership).
3. Set Expiry Date to yesterday (before registration date).
4. Type Card Barcode: `BC-990881` (already used in Scenario A).
5. Click **"Save"**.
6. **Expected Result**: Validation fails. The following errors are shown:
   * *"The user has already been registered as a member."*
   * *"The expiry date must be a date after the registration date."*
   * *"The library card barcode has already been taken."*

### Scenario C: Block Deletion due to Outstanding Fines
1. Select a member record who has an outstanding fine balance of `$15.00`.
2. Click **"Delete"** next to their row.
3. Confirm the delete prompt.
4. **Expected Result**: The action is rejected, and an error warning banner shows: *"Cannot delete member with active borrowings or outstanding fine balances."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Members Tab)
* **Tab Selector**: `@members-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@members-tab')
            ->click('@add-member-btn')
            ->select('user_id', $this->availableStudentUser->id)
            ->select('membership_type_id', $this->studentMembershipType->id)
            ->type('membership_number', 'MEMBER-9988')
            ->type('library_card_barcode', 'BARCODE-9988')
            ->type('expiry_date', '2027-05-23')
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('MEMBER-9988');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@members-tab')
            ->click('@add-member-btn')
            ->type('expiry_date', '2020-01-01') // Invalid past date
            ->press('@save-btn')
            ->assertSee('The expiry date must be a date after');
});
```
