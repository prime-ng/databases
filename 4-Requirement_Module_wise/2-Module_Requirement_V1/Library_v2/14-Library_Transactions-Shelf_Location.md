# Shelf Locations — Requirement Document

## 1. Screen Purpose & Overview
This screen is used to map and catalog the physical coordinates of library resources. By defining building blocks, floor numbers, walkways (aisles), shelving racks, and compartments (shelves), administrators create specific coordinate keys. These keys are linked to book copies (`lib_book_copies.shelf_location_id`) to help users find physical materials on shelves.

---

## 2. Common Business Use Cases
1. **Adding a New Shelf Compartment:** Defining a location coordinate like Building 1, Floor 2, Aisle C, Rack R3, Shelf S2, and assigning it to the "Computer Science Zone".
2. **Deactivating a Section for Renovation:** Setting `is_active = 0` for an aisle to prevent new book acquisitions from being assigned to it.
3. **Relocating Books:** Checking for occupied slots in a location before physically moving stock.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_shelf_locations`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `code` | `varchar(30)` | No | N/A | Unique, short alphanumeric barcode/lookup key. |
| `aisle_number` | `varchar(20)` | No | N/A | Walkway row number/identifier. |
| `shelf_number` | `varchar(20)` | No | N/A | Vertical compartment shelf number. |
| `rack_number` | `varchar(20)` | Yes | `NULL` | Shelving unit rack identifier. |
| `floor_number` | `varchar(10)` | Yes | `NULL` | Floor or story identifier. |
| `building` | `varchar(100)` | Yes | `NULL` | Campus block/building name. |
| `zone` | `varchar(50)` | Yes | `NULL` | Subject area classification (e.g., *Science*, *Fiction*). |
| `description` | `varchar(255)` | Yes | `NULL` | Extra description or notes. |
| `is_active` | `boolean` | No | `1` | Operational state. |
| `created_at` | `timestamp` | Yes | `NULL` | Creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Update timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Location Code** | Text Input | Yes | Unique alphanumeric. Max 30 chars. | Auto-generated |
| **Aisle Number** | Text Input | Yes | Alphanumeric. Max 20 chars. | None |
| **Shelf Number** | Text Input | Yes | Alphanumeric. Max 20 chars. | None |
| **Rack Number** | Text Input | No | Alphanumeric. Max 20 chars. | None |
| **Floor Number** | Text Input | No | Alphanumeric. Max 10 chars. | None |
| **Building** | Text Input | No | String. Max 100 chars. | None |
| **Zone** | Text Input | No | String. Max 50 chars. | None |
| **Description** | Text Area | No | Max 255 chars. | None |
| **Active Toggle** | Checkbox | No | Boolean. Present means active. | Checked (True) |

---

## 5. Business Logic & Validation Policies
1. **Composite Coordinate Uniqueness:** The system enforces a database-level composite unique index:
   $$\text{uk\_shelf\_location} = (\text{aisle\_number}, \text{shelf\_number}, \text{rack\_number})$$
   Saving duplicate coordinates in the same aisle, shelf, and rack is blocked.
2. **Global Code Uniqueness:** The `code` column must be unique across all active shelf locations.
3. **Deletion Safeguard (Soft-Delete Restrictions):** A shelf location record cannot be soft-deleted if it is linked to any active book copy record (`lib_book_copies.shelf_location_id` matches this ID). Books must first be relocated to other coordinates.
4. **Auto-Code Generator Pattern:** The system can auto-generate the lookup code by combining building, floor, aisle, rack, and shelf parameters using dashes (e.g., `B1-F2-A03-R2-S4`).

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Library configurations page (`/library-mgt/masters` or `/library-mgt/transactions`) and select the **Shelf Locations** tab.

### Scenario A: Happy Path Create (Coordinates Autogen)
1. Click **"Add Location"**.
2. Enter Aisle Number: `A-12`.
3. Enter Shelf Number: `S-03`.
4. Enter Rack Number: `R-02`.
5. Enter Floor Number: `Floor 1`.
6. Enter Building: `Main Library`.
7. Enter Zone: `Reference Sections`.
8. Type Location Code: `M1-F1-A12-R2-S3`.
9. Click **"Save"**.
10. **Expected Result**: Location is saved successfully, redirects to list, displays a success alert, and shows the custom code on the list.

### Scenario B: Coordinate Collision Validation
1. Click **"Add Location"**.
2. Enter Aisle Number: `A-12` (Matches Scenario A).
3. Enter Shelf Number: `S-03` (Matches Scenario A).
4. Enter Rack Number: `R-02` (Matches Scenario A).
5. Click **"Save"**.
6. **Expected Result**: Validation fails, showing: *"The combination of Aisle, Shelf and Rack must be unique."*

### Scenario C: Deletion Blocked for Occupied Locations
1. Select an existing location that holds active cataloged books.
2. Click the **"Delete"** button.
3. **Expected Result**: The action is blocked, displaying: *"Cannot delete a shelf location that currently contains cataloged book copies."*

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library-mgt/transactions` (Shelf Location Tab)
* **Tab Selector**: `@shelf-location-tab`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@shelf-location-tab')
            ->click('@add-location-btn')
            ->type('code', 'TEST-SHELF-01')
            ->type('aisle_number', 'Aisle 10')
            ->type('shelf_number', 'Shelf 5')
            ->type('rack_number', 'Rack 1')
            ->press('@save-btn')
            ->assertSee('saved successfully')
            ->assertSee('TEST-SHELF-01');
});
```

### 3. Collision Validation Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-mgt/transactions')
            ->click('@shelf-location-tab')
            ->click('@add-location-btn')
            ->type('code', 'TEST-SHELF-COLLIDE')
            ->type('aisle_number', 'Aisle 10') // Duplicate coords
            ->type('shelf_number', 'Shelf 5')
            ->type('rack_number', 'Rack 1')
            ->press('@save-btn')
            ->assertSee('The combination of Aisle, Shelf and Rack');
});
```
