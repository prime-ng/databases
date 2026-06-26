# Library Authors — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the master listing of book authors, providing metadata fields, biographies, and nationalities. It acts as the authority source for identifying content creators during book cataloging.

---

## 2. Common Business Use Cases
1. **Onboarding Authors:** Registering a new author's details.
2. **Linking Primary Genre:** Setting an author's primary genre for smart catalog suggestions.
3. **Quick Create in Cataloging:** Instantly onboarding an author via a popup modal while cataloging a new book.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_authors`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `short_name` | `varchar(50)` | No | N/A | Short identifier or alias. Unique. |
| `author_name` | `varchar(200)` | No | N/A | Full name. Unique. |
| `country` | `varchar(100)` | Yes | `NULL` | Nationality / Country of origin. |
| `primary_genre_id` | `bigint` | Yes | `NULL` | Foreign key referencing `lib_genres.id`. |
| `notes` | `text` | Yes | `NULL` | Biography or notes. |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Short Name** | Text Input | Yes | Unique. Max 50 chars. E.g., `GOrwell`. | None |
| **Author Name** | Text Input | Yes | Unique. Max 200 chars. | None |
| **Country** | Dropdown | No | Match global countries. | None |
| **Primary Genre** | Dropdown | No | Must exist in `lib_genres.id`. | None |
| **Notes** | Text Area | No | Free text. | None |
| **Active Toggle** | Checkbox | No | Boolean. Default true. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Dual Unique Constraints:** Both `short_name` and `author_name` must be unique in `lib_authors`. Duplicates throw: *"The short/author name has already been taken."*
2. **Genre Reference Integrity:** Binds to active genres. Attempting to link to an inactive or soft-deleted genre returns validation errors.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Authors** tab.

### Scenario A: Happy Path Create
1. Click **"Add Author"**.
2. Enter Short Name: `GOrwell`.
3. Enter Author Name: `George Orwell`.
4. Select Country: `United Kingdom`.
5. Click **"Save"**.
6. **Expected Result**: Redirects to index, success alert displays, and `George Orwell` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Author"**.
2. Leave **Short Name** and **Author Name** blank.
3. Click **"Save"**.
4. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The short name field is required."*
   * *"The author name field is required."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `George Orwell` in the list.
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Authors Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@authors-tab')
            ->click('@add-author-btn')
            ->type('short_name', 'TEST-AUTH')
            ->type('author_name', 'Test Author')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-author-btn')
            ->type('author_name', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
