# Library Keywords — Requirement Document

## 1. Screen Purpose & Overview
Provides tag-like lookup terms (e.g., `Artificial Intelligence`, `World War II`) linked to book records to power search indexes and catalog discoveries.

---

## 2. Common Business Use Cases
1. **Creating Keywords:** Adding a new tag "Machine Learning".
2. **Cataloging Association:** Tagging multiple research books with a specific keyword.
3. **Soft Deleting:** Archiving redundant keywords.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_keywords`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique code. Max 30 chars. Alphanumeric. |
| `name` | `varchar(100)` | No | N/A | Text tag. Max 100 chars. Unique. |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Keyword Code** | Text Input | Yes | Unique. Max 30 chars. Alphanumeric. E.g., `KEY-01`. | None |
| **Keyword Name** | Text Input | Yes | Unique. Max 100 chars. | None |
| **Active Toggle** | Checkbox | No | Boolean. Default true. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **No Duplicates:** Unique indexes on both `code` and `name`. Duplicate codes trigger: *"The code has already been taken."*
2. **Referential Integrity:** Soft deletion removes them from active autocomplete list grids but preserves junction metadata.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Keywords** tab.

### Scenario A: Happy Path Create
1. Click **"Add Keyword"**.
2. Enter Code: `PYTHON`.
3. Enter Name: `Python Programming`.
4. Keep the **"Active"** checkbox checked.
5. Click **"Save"**.
6. **Expected Result**: Redirects to index, success alert displays, and `PYTHON` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Keyword"**.
2. Leave **Keyword Code** and **Keyword Name** blank.
3. Click **"Save"**.
4. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The code field is required."*
   * *"The name field is required."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `Python Programming` in the list.
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Keywords Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@keywords-tab')
            ->click('@add-keyword-btn')
            ->type('code', 'KEY-TEST')
            ->type('name', 'Test Keyword')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-keyword-btn')
            ->type('code', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
