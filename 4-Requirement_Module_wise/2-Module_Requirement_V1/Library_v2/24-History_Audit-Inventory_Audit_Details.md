# Inventory Audit Details — Requirement Document

## 1. Screen Purpose & Overview
This screen provides a real-time barcode scanning interface linked to an active inventory audit session. Staff members scan book copy barcodes or RFID labels at physical shelves. The system verifies expected storage coordinates against actual scan locations, registers copy condition updates, identifies misplaced resources, and logs individual detail lines (`lib_inventory_audit_details`).

---

## 2. Common Business Use Cases
1. **Scanning Books on Shelves:** Scanning physical book copy barcodes consecutively. If the catalog coordinate matches the physical shelf, the copy is marked `found`.
2. **Identifying Misplaced Items:** Scanning a copy expected in *Aisle 2* while auditing *Aisle 4*. The system flags it as `misplaced` and alerts the librarian to relocate it.
3. **Updating Book Condition during Audits:** Flagging a copy as "Water Damaged" during the scan, which updates its status to `damaged` and schedules it for maintenance.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_inventory_audit_details`
*   **Primary Key**: None (Composite key: `audit_id`, `copy_id`)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `audit_id` | `bigint` | No | N/A | FK linking to the parent session `lib_inventory_audit.id`. |
| `copy_id` | `bigint` | No | N/A | FK linking to the scanned item `lib_book_copies.id`. |
| `expected_location_id`| `bigint`| Yes | `NULL` | FK referencing the expected `lib_shelf_locations.id`. |
| `actual_location_id`  | `bigint`| Yes | `NULL` | FK referencing the actual scan `lib_shelf_locations.id`. |
| `scanned_at` | `datetime` | No | N/A | Precise timestamp of the scan action. |
| `condition_id` | `bigint` | Yes | `NULL` | FK referencing the wear condition `lib_book_conditions.id`. |
| `status` | `enum` | No | N/A | Scan result. Values: `'found'`, `'missing'`, `'misplaced'`, `'damaged'`. |
| `notes` | `text` | Yes | `NULL` | Deviation remarks or audit comments. |

> [!NOTE]
> This table is optimized for write operations and does not contain standard Laravel `created_at` or `updated_at` columns.

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Scan Barcode** | Text Input / Scan | Yes | Must correspond to a valid barcode in `lib_book_copies.barcode`. | None |
| **Actual Shelf Location** | Dropdown | Yes | Lock to the active shelf area being audited. FK to `lib_shelf_locations`. | Selected audit location |
| **Current Wear Condition** | Dropdown | Yes | Select active condition type from `lib_book_conditions`. | Prefilled to copy's current condition |
| **Scan Remarks / Notes** | Text Area | No | Detail log. Max 500 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Deviation Detection Logic:** When a barcode is scanned, the system fetches the expected location (`lib_book_copies.shelf_location_id`) and computes the status:
   * **found**: If $\text{actual\_location\_id} == \text{expected\_location\_id}$ AND condition is borrowable.
   * **misplaced**: If $\text{actual\_location\_id} \ne \text{expected\_location\_id}$.
   * **damaged**: If the scanned copy is marked with a non-borrowable condition.
2. **Duplicate Scan Policy:** If the same barcode is scanned multiple times during the same session, the system prevents duplicate rows:
   * If a record already exists for the combination of `(audit_id, copy_id)`, the system updates the existing row's `scanned_at`, `actual_location_id`, and `condition_id` instead of writing a new row.
3. **Session Status Constraint:** Scans are only processed if the parent audit record has a status of `'In Progress'`.
4. **Progression Metrics:**
   $$\text{Audit Progress (\%)} = \left( \frac{\text{Total Scanned Copies}}{\text{Total Expected Copies}} \right) \times 100$$

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the Inventory Auditing screen (`/library/inventory-audit`).
* Open or initialize a session (Status: *In Progress*) and open the scanner panel.

### Scenario A: Scan Copy at Correct Location (Happy Path - 'found')
1. Set Actual Shelf Location: `Aisle 3, Shelf 2`.
2. Scan Copy Barcode: `BC-GATS-001` (Catalog record expects: `Aisle 3, Shelf 2`, condition `Good`).
3. Click **"Submit Scan"**.
4. **Expected Result**: Row is added to the scanned list with a green status badge labeled `'found'`.

### Scenario B: Scan Copy at Incorrect Location ('misplaced')
1. Set Actual Shelf Location: `Aisle 4, Shelf 1`.
2. Scan Copy Barcode: `BC-GATS-001` (Catalog expects: `Aisle 3, Shelf 2`).
3. Click **"Submit Scan"**.
4. **Expected Result**: Row is saved with a yellow status badge labeled `'misplaced'`. A misplaced alert count increases.

### Scenario C: Duplicate Scan Updates Timestamp
1. Scan barcode `BC-GATS-001` at `10:00 AM`.
2. Wait 1 minute. Scan the barcode `BC-GATS-001` again.
3. **Expected Result**: No duplicate row is added. The `scanned_at` timestamp for `BC-GATS-001` updates to `10:01 AM` in the database.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library/inventory-audit/session-uuid` (Active Scan View)
* **Tab/Pane Selector**: `@audit-scanner-panel`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library/inventory-audit/'.$this->activeAudit->uuid)
            ->waitFor('@audit-scanner-panel')
            ->select('actual_location_id', $this->correctLocation->id)
            ->type('copy_barcode', 'BC-GATS-001')
            ->press('@submit-barcode-btn')
            ->waitForText('BC-GATS-001')
            ->assertSeeIn('@status-badge-1', 'found');
});
```

### 3. Misplaced Alert Verification Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library-inventory-audit/'.$this->activeAudit->uuid)
            ->select('actual_location_id', $this->incorrectLocation->id) // Misplaced shelf
            ->type('copy_barcode', 'BC-GATS-001')
            ->press('@submit-barcode-btn')
            ->waitForText('BC-GATS-001')
            ->assertSeeIn('@status-badge-1', 'misplaced');
});
```
