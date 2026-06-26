# Library Book Conditions — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the configuration of standard wear-and-tear classification codes for library resources (e.g., *New*, *Good*, *Damaged*, *Lost*, *Under Maintenance*). It specifies whether copies in a given condition can be actively issued/circulated to members and guards system integrity by restricting modifications of core built-in status codes.

---

## 2. Common Business Use Cases
1. **Defining a New Condition Category:** Creating a condition like "Excellent" or "Brand New" where copies are highly borrowable (`is_borrowable = 1`).
2. **Flagging Damaged/Lost Materials:** Creating or updating a condition like "Water Damaged" or "Severe Wear" and setting `is_borrowable = 0` to prevent them from being checked out.
3. **Deactivating Condition Classifications:** Setting `is_active = 0` for custom condition types that are no longer in use.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_book_conditions`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `code` | `varchar(30)` | No | N/A | Unique alphanumeric identifier for the condition. |
| `name` | `varchar(50)` | No | N/A | Human-readable name of the book condition. |
| `description` | `varchar(255)` | Yes | `NULL` | Detailed description of criteria for this condition. |
| `is_borrowable` | `boolean` | No | `1` | Defines if copies under this condition can be issued. |
| `is_active` | `boolean` | No | `1` | Operational state of this condition record. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Condition Code** | Text Input | Yes | Alphanumeric, unique. Max 30 chars. | None |
| **Condition Name** | Text Input | Yes | String. Max 50 chars. | None |
| **Description** | Text Area | No | Max 255 characters. | None |
| **Is Borrowable** | Checkbox / Toggle | No | Boolean. If checked, books with this condition can be issued. | Checked (True) |
| **Active Status** | Checkbox / Toggle | No | Boolean. If checked, condition is active. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Unique Condition Code:** The `code` must be unique across all active book conditions. The unique check ignores the current record's ID on edits.
2. **System Codes Protection:** Built-in system condition codes (`GOOD`, `DAMAGED`, `LOST`) are protected. They cannot be modified or soft-deleted/purged, ensuring transaction logs stay consistent.
3. **Borrowable Flag Dependency:** If a book copy's condition is updated to a non-borrowable state (e.g., `is_borrowable = 0`), its circulation availability status must automatically be set to non-circulating (e.g., "Under Maintenance" or "Withdrawn") in transaction workflows.
4. **Soft Delete Policy:** When a custom book condition is soft-deleted, it must not be linked to any active book copies (`lib_book_copies.current_condition_id`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as a Librarian or Administrator.
* Navigate to the Library Master Configurations page `/library-mgt/masters` and select the **Book Conditions** tab.

### Scenario A: Happy Path Create
1. Click **"Add Book Condition"**.
2. Enter Code: `EXCELLENT`.
3. Enter Name: `Excellent / Like New`.
4. Enter Description: `No visible signs of wear, pages clean and intact`.
5. Keep **Is Borrowable** checked.
6. Keep **Active Status** checked.
7. Click **"Save"**.
8. **Expected Result**: The condition saves successfully, displays a success alert, redirects back to the index view, and the new condition `EXCELLENT` is listed.

### Scenario B: Validation Failures
1. Click **"Add Book Condition"**.
2. Enter an existing code, e.g., `GOOD` (built-in).
3. Leave **Condition Name** empty.
4. Click **"Save"**.
5. **Expected Result**: Submission fails. The form displays error validation messages:
   * *"The code has already been taken."*
   * *"The name field is required."*

### Scenario C: System Record Protection (Delete Restrict)
1. In the condition list, locate the system condition `GOOD` or `LOST`.
2. Attempt to click **"Delete"** or edit the record to change the code/delete it.
3. **Expected Result**: The interface either disables the edit/delete options for system-protected records, or if submitted, the backend rejects it with an error message: *"System default book conditions cannot be modified or deleted."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Book Conditions Tab)
* **Tab Selector**: `@book-condition-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@book-condition-tab')
            ->click('@add-condition-btn')
            ->type('code', 'NEW_COND')
            ->type('name', 'Brand New Copy')
            ->type('description', 'Fresh copy direct from publisher')
            ->check('is_borrowable')
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('Brand New Copy');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/masters')
            ->click('@book-condition-tab')
            ->click('@add-condition-btn')
            ->type('code', 'GOOD') // Existing code
            ->type('name', '')     // Missing name
            ->press('@save-btn')
            ->assertSee('The code has already been taken.')
            ->assertSee('The name field is required.');
});
```
