# Library Genres — Requirement Document

## 1. Screen Purpose & Overview
This screen manages literary genre classification tags (e.g., `Science Fiction`, `Biography`, `Self-Help`) that cross-cut hierarchical categories for flexible searching and cataloging.

---

## 2. Common Business Use Cases
1. **Creating Genres:** Adding "Historical Fiction" to classify historical novels.
2. **Standardizing Catalog Classifications**: Viewing active literary tags.
3. **Deactivating Genres:** Soft-deactivating an unused genre.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_genres`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique, alphanumeric shorthand key. |
| `name` | `varchar(100)` | No | N/A | Descriptive genre name. Unique. |
| `description` | `varchar(255)` | Yes | `NULL` | Background details. |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Genre Code** | Text Input | Yes | Required. Alphanumeric, unique. Max 30 chars. E.g., `GEN-01`. | None |
| **Genre Name** | Text Input | Yes | Required. Unique. Max 100 chars. | None |
| **Description** | Text Area | No | Max 255 chars. | None |
| **Active Status** | Checkbox | No | Boolean. Default true. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Strict Unique Constraints:** Both `code` and `name` must be unique in `lib_genres` table. Duplicates trigger: *"The code/name has already been taken."*
2. **Soft Deletion Safety:** Active genres linked to books in `lib_book_genre_jnt` cannot be hard deleted. Soft deleting deactivates selection.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Genres** tab.

### Scenario A: Happy Path Create
1. Click **"Add Genre"**.
2. Enter Code: `SCI-FI`.
3. Enter Name: `Science Fiction`.
4. Enter Description: `Science fiction and space odyssey titles`.
5. Keep the **"Active"** checkbox checked.
6. Click **"Save"**.
7. **Expected Result**: Redirects to index, success alert displays, and `SCI-FI` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Genre"**.
2. Leave **Genre Code** and **Genre Name** blank.
3. Click **"Save"**.
4. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The code field is required."*
   * *"The name field is required."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `Science Fiction` in the list.
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Genres Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@genres-tab')
            ->click('@add-genre-btn')
            ->type('code', 'GEN-TEST')
            ->type('name', 'Test Genre')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-genre-btn')
            ->type('code', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
