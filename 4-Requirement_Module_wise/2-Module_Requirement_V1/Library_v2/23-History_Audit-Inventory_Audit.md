# Inventory Audit — Requirement Document

## 1. Screen Purpose & Overview
This screen handles the tracking of physical library inventory audit events. It allows administrators and librarians to initialize audit sessions (`lib_inventory_audit`), capture snapshot counts of expected copy stock, monitor scan processes in real-time, record staff responsibilities, compute variances (missing/damaged/misplaced copies), and lock logs upon session completion.

---

## 2. Common Business Use Cases
1. **Starting a Shelf Audit:** Initiating a new audit session for a floor or campus building, capturing expected count snapshots, and preparing the system for copy barcode scanning.
2. **Completing an Audit Session:** Finalizing the scans, calculating missing and misplaced books, and locking the record as `Completed`.
3. **Cancelling a Draft Session:** Marking a session as `Cancelled` to void any recorded scan logs due to operational issues.

---

## 3. Database Schema & Data Dictionary
*   **Table Name**: `lib_inventory_audit`
*   **Primary Key**: `id` (bigint, auto-increment)

| Column Name | Data Type | Nullable | Default | Description / Key Details |
|---|---|---|---|---|
| `id` | `bigint` | No | N/A | Auto-increment primary key. |
| `uuid` | `uuid` | No | N/A | Globally unique session tracker code. |
| `audit_date` | `date` | No | N/A | Date when the audit was initialized. |
| `performed_by_id` | `bigint` | No | N/A | FK linking to `sys_users.id` (auditor). |
| `total_scanned` | `unsigned int` | No | `0` | Total number of physical copies scanned during the session. |
| `total_expected` | `unsigned int` | No | `0` | Snapshot count of total active copies in stock at start. |
| `missing_copies` | `unsigned int` | No | `0` | Calculated count of expected copies not found. |
| `misplaced_copies`| `unsigned int` | No | `0` | Calculated count of copies found in incorrect shelf locations. |
| `damaged_copies`  | `unsigned int` | No | `0` | Count of scanned copies flagged as damaged. |
| `status` | `enum` | No | `'In Progress'`| Values: `'In Progress'`, `'Completed'`, `'Cancelled'`. |
| `completed_at` | `datetime` | Yes | `NULL` | Timestamp when session was set to `'Completed'`. |
| `notes` | `text` | Yes | `NULL` | General notes or session scope details. |
| `created_at` | `timestamp` | Yes | `NULL` | Session creation timestamp. |
| `updated_at` | `timestamp` | Yes | `NULL` | Session modification timestamp. |
| `deleted_at` | `timestamp` | Yes | `NULL` | Soft-delete timestamp. |

---

## 4. Screen Fields & Input Rules
| Field Name (Screen Label) | HTML Control | Required | Validation & Constraints | Default Value |
|---|---|---|---|---|
| **Audit Date** | Date Picker | Yes | Standard date. Must be $\ge$ today's date for new sessions. | Today's Date |
| **Performed By (Auditor)**| Dropdown | Yes | Select active staff member from `sys_users`. | Prefilled to current user |
| **Session Notes** | Text Area | No | Max 1000 characters. | None |

---

## 5. Business Logic & Validation Policies
1. **Single Active Session Rule:** To maintain data integrity, only one audit session can be active in `'In Progress'` status at a time. The system blocks initiating a new audit if another is active:
   $$\text{Block Creation} \iff \exists A \in \text{lib\_inventory\_audit} \text{ where } A.\text{status} = \text{'In Progress'}$$
2. **Snapshot Initialization:** At session start, the system auto-generates a `uuid` and captures a snapshot of total expected book copies:
   $$\text{total\_expected} = \text{Count}(\text{lib\_book\_copies where is\_active} = 1 \land \text{status} \ne \text{'withdrawn'})$$
3. **Completion Locking:** Once marked `'Completed'` or `'Cancelled'`, the audit record is locked. No further details can be scanned, and fields become read-only.
4. **Variance Computation:** On completion, totals are computed:
   $$\text{missing\_copies} = \max\left(0, \text{total\_expected} - \text{total\_scanned}\right)$$
5. **Soft Delete Cascading:** Soft-deleting an audit record flags `deleted_at` on the header, and must logically restrict or cascade soft-deletes to all child records in `lib_inventory_audit_details`.

---

## 6. Detailed Step-by-Step Manual Testing Plan

### Pre-requisites
* Log in as an Administrator/Librarian.
* Navigate to the History & Audit section (`/library-mgt/history` or `/library/inventory-audit`) and click the **Inventory Auditing** tab.

### Scenario A: Initialize Audit Session (Happy Path)
1. Click **"Initialize Audit"**.
2. Keep Audit Date as today.
3. Enter Notes: *"Annual inventory audit for Main Science Library - Aisle A & B."*
4. Click **"Start Session"**.
5. **Expected Result**: Audit session starts, a unique UUID is created, the grid indicates a status of `'In Progress'`, and `total_expected` records the count of all active copies.

### Scenario B: Double Open Sessions Blocked
1. With the Scenario A session still active, click **"Initialize Audit"** again.
2. Fill details and click **"Start Session"**.
3. **Expected Result**: Rejection alert displays: *"Cannot start a new audit. An active inventory audit session is already in progress."*

### Scenario C: Finalizing Session and Variance Calculations
1. Open the active session.
2. Scan 8 copy barcodes (Assume total expected snapshot was 10 copies).
3. Click **"Complete Audit"** and confirm the confirmation prompt.
4. **Expected Result**: Session status toggles to `'Completed'`, `completed_at` is set to current time, and totals write: `total_scanned = 8`, `missing_copies = 2`. The session details lock.

---

## 7. Laravel Dusk Automation Test Guidance

### 1. Target Page & Navigation
* **URL/Route**: `/library/inventory-audit`
* **Tab/Page Selector**: `@inventory-audit-view`

### 2. Happy Path Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library/inventory-audit')
            ->click('@init-audit-btn')
            ->type('audit_date', '2026-05-23')
            ->type('notes', 'Dusk Test Audit Session')
            ->press('@start-session-btn')
            ->assertSee('Audit session started successfully')
            ->assertSee('In Progress');
});
```

### 3. Double Session Block Dusk Test Flow
```php
$this->browse(function (Browser $browser) {
    $browser->loginAs($this->adminUser)
            ->visit('/library/inventory-audit')
            ->click('@init-audit-btn')
            ->press('@start-session-btn')
            ->assertSee('An active inventory audit session is already in progress.');
});
```
