# Library Book Master — Requirement Document

## 1. Screen Purpose & Overview
This is the cataloging repository for all library titles. It aggregates bibliographic metadata, ISBNs, publication details, and ratings. It acts as the central master index that links physical copy acquisitions and digital resource access.

---

## 2. Common Business Use Cases
1. **Cataloging a Novel:** Adding "Dune" by Frank Herbert, specifying publisher, edition, and resource type.
2. **Bibliographic Metadata Tracking:** Querying publication year, language, and page counts.
3. **Reference Restriction:** Marking rare books as "Reference Only" to block checkout operations.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_book_masters` (or `lib_books_master`)
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `title` | `varchar(500)` | No | N/A | Main book title. |
| `isbn` | `varchar(20)` | Yes | `NULL` | Unique International Standard Book Number. Has unique index. |
| `resource_type_id` | `bigint` | No | N/A | Foreign key referencing `lib_resource_types.id`. |
| `publisher_id` | `bigint` | No | N/A | Foreign key referencing `lib_publishers.id`. |
| `publication_year` | `integer` | Yes | `NULL` | Four-digit calendar year (1000 to 2100). |
| `is_reference_only`| `boolean` | No | `0` | If true, copies cannot be checked out of the library. |
| `page_count` | `integer` | Yes | `NULL` | Number of pages. Must be $> 0$. |
| `language` | `varchar(50)` | Yes | `'English'`| Written language. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Book Title** | Text Input | Yes | String. Max 500 chars. | None |
| **ISBN** | Text Input | No | Optional. Unique alphanumeric. Max 20 chars. | None |
| **Resource Type** | Dropdown | Yes | Must exist in `lib_resource_types.id`. | None |
| **Publisher** | Dropdown | Yes | Must exist in `lib_publishers.id`. | None |
| **Publication Year** | Number Input | No | Integer between 1000 and 2100. | None |
| **Reference Only** | Checkbox | No | Boolean. | Unchecked (False) |
| **Page Count** | Number Input | No | Integer $> 0$. | None |
| **Language** | Dropdown / Input | No | Max 50 chars. | `'English'` |

---

## 5. Business Logic & Validation Policies
1. **ISBN Uniqueness:** ISBN must be globally unique to prevent duplicate catalog entries. Duplicate ISBNs trigger: *"The ISBN has already been taken."*
2. **Reference Loans:** Reference-only books generate alert flags and block loan creation in the Book Issue grid.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to `/library-mgt/masters` and click the **Books** tab.

### Scenario A: Happy Path Create
1. Click **"Add Book"** (or "+ New Book").
2. Enter Title: `1984`.
3. Enter ISBN: `9780451524935`.
4. Select Resource Type: `Physical Book`.
5. Select Publisher: `Signet Classic`.
6. Enter Publication Year: `1961`.
7. Click **"Save"**.
8. **Expected Result**: Redirects to index, success alert displays, and `1984` appears in the catalog listing.

### Scenario B: Validation Failures
1. Click **"Add Book"**.
2. Leave **Book Title**, **Resource Type**, and **Publisher** blank.
3. Enter Publication Year: `800` (invalid year).
4. Click **"Save"**.
5. **Expected Result**: Submission fails. Errors are highlighted:
   * *"The title field is required."*
   * *"The resource type field is required."*
   * *"The publisher field is required."*
   * *"The publication year must be between 1000 and 2100."*

### Scenario C: Reference Only Check
1. Click **"Add Book"**.
2. Create a book with **"Reference Only"** checked.
3. **Expected Result**: Record is saved. Database has `is_reference_only = 1`. Try issuing this book copy in the transaction screen; checkout should be blocked.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/masters` (Books Tab)

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@books-tab')
            ->click('@add-book-btn')
            ->type('title', 'Test Book Master')
            ->type('isbn', '1234567890123')
            ->select('resource_type_id', '1')
            ->select('publisher_id', '1')
            ->press('@save-btn')
            ->assertSee('saved successfully');
});
```

### 3. Validation Failures Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->librarianUser)
            ->visit('/library-mgt/masters')
            ->click('@add-book-btn')
            ->type('title', '') // Clear required field
            ->press('@save-btn')
            ->assertSee('required');
});
```
