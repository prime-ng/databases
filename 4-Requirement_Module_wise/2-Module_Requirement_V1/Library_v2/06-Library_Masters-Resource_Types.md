# Library Resource Types — Requirement Document

## 1. Screen Purpose & Overview
Defines formats of resources (Physical, Digital, Audio Book) and determines if they can be checked out. It establishes circulation capabilities for catalog categories.

---

## 2. Common Business Use Cases
1. **Creating Ebook format:** Setting `is_digital = 1` and `is_borrowable = 0` (students access online, no physical circulation).
2. **Creating Physical Novel format:** Setting `is_physical = 1` and `is_borrowable = 1` (traditional checkout allowed).
3. **Audio Book Setup**: Setting `is_audio_books = 1` for digital listen-only assets.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_resource_types`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `code` | `varchar(30)` | No | N/A | Unique formatting code. Has a unique DB index. |
| `name` | `varchar(100)` | No | N/A | Format name. |
| `is_physical` | `boolean` | No | `1` | True if the resource has a physical counterpart. |
| `is_digital` | `boolean` | No | `0` | True if the resource is a digital download. |
| `is_audio_books` | `boolean` | No | `0` | True if it's classified as an audio book. |
| `is_borrowable` | `boolean` | No | `1` | If true, copies of this type can be checked out. |
| `is_active` | `boolean` | No | `1` | Operational toggle. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Type Code** | Text Input | Yes | Unique. Max 30 chars. E.g., `PDF_E`. | None |
| **Type Name** | Text Input | Yes | Max 100 chars. | None |
| **Is Physical** | Checkbox | No | Boolean. | Checked (True) |
| **Is Digital** | Checkbox | No | Boolean. | Unchecked (False) |
| **Is Audio Books** | Checkbox | No | Boolean. | Unchecked (False) |
| **Is Borrowable** | Checkbox | No | Boolean. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Unique Code:** Code must be unique. Duplicate code triggers validation failure.
2. **Borrowable Restriction:** Only borrowable resource types can be issued during checkout operations. Non-borrowable items block the issue button on frontend transactions.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Resource Types** tab.

### Scenario A: Happy Path Create
1. Click **"Add Resource Type"**.
2. Enter Code: `AUDIO_B`.
3. Enter Name: `Audio CD Package`.
4. Check **"Is Physical"** and **"Is Audio Books"** checkboxes.
5. Uncheck **"Is Borrowable"** (reference only).
6. Click **"Save"**.
7. **Expected Result**: Redirects to index, success alert displays, and `Audio CD Package` appears in the listing.

### Scenario B: Validation Failures
1. Click **"Add Resource Type"**.
2. Leave **Type Code** and **Type Name** blank.
3. Click **"Save"**.
4. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The code field is required."*
   * *"The name field is required."*

### Scenario C: AJAX Status Toggling
1. Toggle the active switch for `Audio CD Package` in the list.
2. **Expected Result**: AJAX request toggles status and updates DB column `is_active` without page refresh.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Resource Types Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@resource-types-tab')
            ->click('@add-resource-type-btn')
            ->type('code', 'RES-TEST')
            ->type('name', 'Test Resource Type')
            ->check('is_physical')
            ->check('is_borrowable')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-resource-type-btn')
            ->type('code', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
