# Book Purchase (Book Copies) — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the registration and tracking of physical book copies (`lib_book_copies`) within the library catalog. While the Book Master holds bibliographic meta-information (ISBN, Title, Author), the Book Copies module manages individual physical items, including their accession numbers, unique barcodes, RFID chips, purchase costs, vendors, wear-and-tear conditions, shelf locations, and circulation states.

---

## 2. Common Business Use Cases
1. **Acquiring New Physical Stock:** Registering multiple copies of a newly purchased title (e.g. 5 copies of "Dune"), generating sequential barcodes/RFID codes, and placing them in a specific shelf aisle.
2. **Maintenance Transitions:** Updating a copy's wear-and-tear condition to "Damaged" and moving its status to `under_maintenance` to prevent circulation until repaired.
3. **Withdrawing Copies:** Retiring severely damaged or outdated copies from circulation and recording the retirement reason.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_book_copies`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `book_id` | `bigint` | No | N/A | FK to `lib_books_master.id`. Restricted on delete. |
| `accession_number` | `varchar(50)` | No | N/A | Unique library accession registry code. |
| `barcode` | `varchar(100)` | No | N/A | Unique barcode scanned from physical book label. |
| `rfid_tag` | `varchar(100)` | No | N/A | Unique RFID transponder chip code. |
| `shelf_location_id` | `bigint` | Yes | `NULL` | FK to `lib_shelf_locations.id`. Nullified on delete. |
| `current_condition_id` | `bigint` | No | N/A | FK to `lib_book_conditions.id`. Restricted on delete. |
| `purchase_date` | `date` | No | N/A | Date when the copy was acquired. |
| `purchase_price` | `decimal(10,2)` | No | `0.00` | Financial acquisition cost. Reference for book replacement fees. |
| `vendor_id` | `bigint` | Yes | `NULL` | FK to `vnd_vendors.id` (supplier). |
| `is_lost` | `boolean` | No | `0` | Flag identifying if copy is lost. |
| `is_damaged` | `boolean` | No | `0` | Flag identifying if copy is damaged. |
| `is_withdrawn` | `boolean` | No | `0` | Flag identifying if copy is retired. |
| `withdrawal_reason` | `varchar(512)` | Yes | `NULL` | Reason required if `is_withdrawn` is set to `1`. |
| `status` | `enum` | No | `'available'` | Values: `'available'`, `'issued'`, `'reserved'`, `'under_maintenance'`, `'lost'`, `'withdrawn'`. |
| `notes` | `text` | Yes | `NULL` | General notes or staff remarks. |
| `is_active` | `boolean` | No | `1` | Record status switch. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation date. |
| `updated_at` | `timestamp` | Yes | `NULL` | Modification date. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Book Title** | Dropdown / Search | Yes | Must select an active record from `lib_books_master`. | None |
| **Accession Number** | Text Input | Yes | Unique alphanumeric. Max 50 characters. | None |
| **Barcode** | Text Input | Yes | Unique alphanumeric. Max 100 characters. | None |
| **RFID Tag** | Text Input | Yes | Unique alphanumeric. Max 100 characters. | None |
| **Shelf Location** | Dropdown | No | Must select an active coordinate from `lib_shelf_locations`. | *Unassigned* |
| **Current Condition** | Dropdown | Yes | Select an active option from `lib_book_conditions`. | None |
| **Purchase Date** | Date Picker | Yes | Must be a valid date $\le$ today's date. | Today's Date |
| **Purchase Price** | Number Input | Yes | Decimal value $\ge 0.00$. | `0.00` |
| **Vendor** | Dropdown | No | Select from active vendor profiles in `vnd_vendors`. | None |
| **Circulation Status** | Dropdown | Yes | Choice of `'available'`, `'issued'`, `'reserved'`, `'under_maintenance'`, `'lost'`, `'withdrawn'`. | `'available'` |
| **Withdrawal Reason** | Text Area | Conditional| Required only if **Circulation Status** is `'withdrawn'`. Max 512 chars. | None |
| **Acquisition Notes** | Text Area | No | Max 1000 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Uniqueness Constraints:** The combination of barcode, accession number, and RFID tag must be globally unique across all book copies. On editing, checks ignore the current copy ID.
2. **Date Order Check:** `purchase_date` must not be a future date ($\le \text{today}$).
3. **Withdrawal Enforcement:** When status is set to `'withdrawn'`, the flag `is_withdrawn` must be set to `1` automatically, and `withdrawal_reason` becomes mandatory.
4. **Circulation Status Locks:**
   * If status is `'issued'`, the book copy cannot be edited to status `'available'` manually without a proper return transaction log.
   * If status is `'lost'`, the flag `is_lost` must toggle to `1`.
5. **Asset Depreciation Formula:**
   $$\text{Depreciated Value} = \max\left(\text{purchase\_price} \times (1 - \text{Usage Years} \times 0.10), \text{purchase\_price} \times 0.10\right)$$
   *(Assuming a standard 10% annual depreciation rate, floor-capped at 10% of original cost).*
6. **Deletion Safeguards:** A copy cannot be soft-deleted if its status is `'issued'`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the `/library-mgt/transactions` page and click the **Book Copies / Purchases** tab.

### Scenario A: Happy Path Register Copy
1. Click **"Add Book Copy"**.
2. Select Book: *The Great Gatsby (ISBN 9780743273565)*.
3. Enter Accession Number: `ACC-GATS-001`.
4. Enter Barcode: `BC-GATS-001`.
5. Enter RFID Tag: `RFID-GATS-001`.
6. Select Shelf Location: `Building 1, Floor 1, Aisle 2`.
7. Select Condition: `Good`.
8. Enter Purchase Date: Today's date.
9. Enter Purchase Price: `25.00`.
10. Click **"Save"**.
11. **Expected Result**: Copy is successfully registered, success alert shows, and `ACC-GATS-001` appears in the list as "available".

### Scenario B: Validation Failures
1. Click **"Add Book Copy"**.
2. Type Barcode: `BC-GATS-001` (Duplicate of Scenario A).
3. Type RFID Tag: `RFID-GATS-001` (Duplicate).
4. Set Purchase Date to a future date (e.g. 5 days from today).
5. Click **"Save"**.
6. **Expected Result**: Submission fails. Validation errors highlight the fields:
   * *"The barcode has already been taken."*
   * *"The rfid tag has already been taken."*
   * *"The purchase date cannot be in the future."*

### Scenario C: Withdrawal Reason Requirement
1. Edit copy `ACC-GATS-001`.
2. Change Circulation Status dropdown to `'withdrawn'`.
3. Leave **Withdrawal Reason** field blank.
4. Click **"Save"**.
5. **Expected Result**: Validation fails, displaying: *"The withdrawal reason field is required when status is withdrawn."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Book Copies Tab)
* **Tab Selector**: `@book-copies-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-copies-tab')
            ->click('@add-copy-btn')
            ->select('book_id', $this->gatsbyBookMaster->id)
            ->type('accession_number', 'ACC-TEST-99')
            ->type('barcode', 'BARCODE-TEST-99')
            ->type('rfid_tag', 'RFID-TEST-99')
            ->select('current_condition_id', $this->goodCondition->id)
            ->type('purchase_date', '2026-05-23')
            ->type('purchase_price', '50.00')
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('ACC-TEST-99');
});
```

### 3. Future Purchase Date Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@book-copies-tab')
            ->click('@add-copy-btn')
            ->type('purchase_date', '2030-01-01') // Future date
            ->press('@save-btn')
            ->assertSee('cannot be in the future');
});
```
