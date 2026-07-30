# Lib Book Copies — Business Requirements

## What This Screen Does

The Book Copies screen manages individual physical copies of library books. While the Books Master defines a title's bibliographic data, this screen tracks each specific copy — its barcode, accession number, RFID tag, shelf location, current physical condition, circulation status, and purchase provenance. Every copy is linked to a parent book through `lib_books_master.id` and carries flags for lost, damaged, and withdrawn states.

Beyond standard CRUD, this screen provides dedicated workflows for marking copies as lost (which auto-closes active transactions and generates lost-book fines) and marking copies as damaged (which sets status to under_maintenance and creates condition history records). The status can also be updated directly via an AJAX endpoint. Whenever a copy's data changes, the parent book's `is_available` cached flag is recalculated.

---

## When This Screen Is Used

- When viewing all physical copies of a specific book to check availability and location
- When a copy is damaged — marking it as damaged triggers condition logging and status change
- When a copy is lost — marking it lost closes active borrow transactions and generates a replacement-cost fine
- When issuing or returning books (status changes handled via the Transactions screen)
- When updating a copy's barcode, location, or condition after shelf reorganization
- When withdrawing a damaged or outdated copy from the collection

## Default Data Load

The Book Copies screen opens as a tab pane within the Library Acquisition hub (`library.acquisitionIndex` with `tab=book-copies`). The controller's `index()` method redirects to the hub. The paginated list loads copies with book, shelfLocation, condition, and purchase.vendor relations. Filters support search by accession number, barcode, RFID, or book title, with additional filters for book_id, status, shelf_location_id, condition_id, and is_active. 15 items per page.

---

## Key Fields at a Glance

**Core Identity**
Every copy must have a unique accession number (VARCHAR(50)) — the institution's internal identifier — and a unique scannable barcode (VARCHAR(100)). An optional RFID tag (VARCHAR(100)) provides an additional unique tracking mechanism for libraries using RFID gates. All three fields have unique constraints at the database level.

**Relational Mapping**
The copy is linked to its parent book (FK to `lib_books_master.id`), its shelf location (FK to `lib_shelf_locations.id`, nullable), its current physical condition (FK to `lib_book_conditions.id`, required), and the purchase order that acquired it (FK to `lib_book_purchases.id`, nullable).

**Status and State Flags**
The `status` field is an FK to `lib_library_status_masters.id` where `status_type = 'Book Status'` — possible values: Available, Issued, Reserved, Under_Maintenance, Lost, Withdrawn. Three boolean flags (`is_lost`, `is_damaged`, `is_withdrawn`) provide quick filtering. `current_due_date` is updated when the copy is issued. `withdrawal_reason` is required when withdrawing.

**Condition History**
Every condition change is logged to `lib_book_condition_jnt` with date, book_id, copy_id, condition_id, and note. This provides a full audit trail of wear and tear.

---

## Business Rules and Conditions

**Delete Protection for Issued Copies**
The `destroy()` method checks if the copy's status is "Issued" by comparing against `LibLibraryStatusMaster::getIdByCode('Book Status', 'issued')`. If currently issued, deletion is blocked with error: "Cannot delete a copy that is currently issued."

**Mark Lost — Transaction Closure and Fine Generation**
When `markLost()` is called, the copy's `is_lost` is set to true and status changes to "Lost". If an active transaction (status = Issued or Overdue) exists for this copy, it is closed with status "Lost" and return_date = now(). A lost-book fine is auto-generated: replacement cost = purchase item's book_price (defaults to ₹500 if not found). The fine is attached to the member (`member_id`), and the member's `outstanding_fines` is incremented.

**Mark Damaged — Status Change and Condition Log**
When `markDamaged()` is called, the copy's `is_damaged` is set to true and status changes to "Under_Maintenance". The system finds the "damaged" condition code in `lib_book_conditions`, updates `current_condition_id`, and creates a `LibBookConditionJnt` history record.

**Availability Sync**
Every copy mutation (create, update, delete, restore, forceDelete, toggleStatus, markLost, markDamaged, updateStatus) calls `LibBookMaster::syncBookAvailability($bookId)` to recalculate the parent book's `is_available` flag. The flag is true if at least one active copy has status "Available".

**Unique Constraints (FormRequest)**
- `accession_number`: unique, ignored on update for current record
- `barcode`: unique, ignored on update for current record
- `rfid_tag`: nullable, unique, ignored on update for current record
- `withdrawal_reason`: required_if is_withdrawn = true

---

## Workflow Steps

1. Navigate to Library → Acquisition hub → Book Copies tab
2. View the paginated copies list with search and multi-filter options
3. Click "Add Copy" to create a single copy manually (normally copies are created via purchases)
4. Enter barcode, accession number, select book, shelf location, condition, purchase, and status
5. Edit a copy to update location, condition, or flags
6. Click the status toggle button to activate/deactivate
7. Click "Mark Damaged" — system updates flags, condition, and logs history
8. Click "Mark Lost" — system flags the copy, closes active transactions, and generates fines
9. Delete only if the copy is not currently issued — otherwise blocked
10. Restore and force-delete from Trash

---

## Example Scenario

During a routine shelf check, the librarian finds a damaged copy of "Advanced Physics" with a torn cover. They open the Book Copies screen, search for the copy's barcode, and click "Mark Damaged". The system immediately changes the copy's status to "Under_Maintenance", links the "Damaged" condition, and creates a condition history entry. Two weeks later after repairs, the librarian edits the copy to change its condition back to "Good" and status back to "Available". Separately, a student reports losing a copy of "Chemistry Basics". The librarian finds the copy, clicks "Mark Lost" — the system closes the student's active transaction and generates an ₹850 fine (the copy's original purchase price).

---

## Related Screens

- Books Master — parent book for each copy
- Book Purchases — copies are created during purchase and linked via book_purchase_id
- Book Conditions — condition master data used by each copy
- Shelf Locations — physical location management
- Transactions — issue/return workflow that reads and updates copy status
- Fines — lost-book fines generated from markLost

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibBookCopyController`
**Model:** `Modules\Library\Models\LibBookCopy` (table: `lib_book_copies`, uses `SoftDeletes`)
**Requests:** `LibBookCopyRequest` (validates required fields, unique barcode/accession/rfid, required_if withdrawal_reason)
**Policy:** Named permission string `tenant.lib-book-copies.*`
**Route:** Resource route `Route::resource('lib-book-copies', LibBookCopyController::class)` with extras: `trashed`, `restore`, `forceDelete`, `toggleStatus`, `updateStatus`, `markLost`, `markDamaged`

Key controller methods:
- `index()` — Redirects to hub tab with `tab=book-copies`
- `create()` — Returns form with books, shelfLocations, conditions, vendors, statuses, purchases
- `store(LibBookCopyRequest)` — Creates copy with boolean normalization; syncs book availability
- `show($id)` — Loads with book, shelfLocation (building/zone/floor/aisle/rack/shelf), condition, purchase.vendor, statusMaster
- `edit($id)` — Loads copy for editing with same reference data
- `update(LibBookCopyRequest, $id)` — Updates copy, syncs availability
- `destroy($id)` — Blocks if currently issued; soft-deletes, syncs availability
- `trashed()` — Lists soft-deleted copies with book, shelfLocation, condition
- `restore($id)` — Restores from trash, syncs availability
- `forceDelete($id)` — Force-deletes; catches FK exception; syncs availability
- `toggleStatus($id)` — Toggles `is_active` via AJAX, syncs availability
- `updateStatus(Request, $id)` — Updates copy status FK via AJAX (available/issued/reserved/under_maintenance/lost/withdrawn)
- `markLost(Request, $id)` — Sets is_lost, closes active transactions, generates replacement-cost fine, syncs availability
- `markDamaged(Request, $id)` — Sets is_damaged, updates condition, creates condition log, syncs availability

**ActivityLog Events:** Stored, Updated, Trashed, Restored, Deleted, Toggled

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-book-copies.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-book-copies.*` | Full CRUD + mark lost/damaged + status change |
| Librarian | `tenant.lib-book-copies.viewAny`, `.view`, `.update` | View and update copies (status, condition changes) |
| Library Assistant | `tenant.lib-book-copies.viewAny`, `.view` | Read-only copy viewing |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user opens the Acquisition section and clicks the Book Copies tab. A table displays all individual copies with their barcode, book title, current condition, circulation status, and shelf location. Users can filter copies by barcode number, book title, condition, or status. Each copy has action buttons: editing allows changing the shelf location, condition, or flags. The "Mark Damaged" button immediately flags the copy, changes its status to under maintenance, and records the damage with a timestamp in the copy's history log. The "Mark Lost" button is more powerful — it not only flags the copy as lost but also checks if someone currently has it borrowed. If so, it closes that transaction and automatically calculates a replacement-cost fine, adding it to the member's outstanding fines balance. A copy that is currently issued to a member cannot be deleted; the system blocks this with a clear message.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | book_id | Required, Exists:lib_books_master,id | Please select a book. |
| 2 | accession_number | Required, String, Max:50, Unique (ignore self on update) | Accession number is required. / This accession number is already taken. |
| 3 | barcode | Required, String, Max:100, Unique (ignore self on update) | This barcode is required. / This barcode is already in use. |
| 4 | rfid_tag | Nullable, String, Max:100, Unique (ignore self on update) | This RFID tag is already in use. |
| 5 | shelf_location_id | Nullable, Exists:lib_shelf_locations,id | — |
| 6 | book_purchase_id | Nullable, Exists:lib_book_purchases,id | — |
| 7 | current_condition_id | Required, Exists:lib_book_conditions,id | Please select a condition. |
| 8 | status | Required, Exists:lib_library_status_masters,id | Please select a status. |
| 9 | withdrawal_reason | Nullable, Required_if:is_withdrawn,true, String, Max:512 | Withdrawal reason is required when withdrawing a copy. |
| 10 | is_lost | Boolean | — |
| 11 | is_damaged | Boolean | — |
| 12 | is_withdrawn | Boolean | — |
| 13 | is_active | Boolean | — |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Delete blocked — copy is issued | Cannot delete a copy that is currently issued. | 422 (redirect with flash) |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. Remove all dependencies first. | 422 (redirect with flash) |
| Store/update exception | Failed to create/update book copy: [detail] | 422 (redirect) |
| Model not found | No query results for model | 404 |
| Lost fine type not found | Unhandled exception (logged) | 500 |

---

## Success Scenarios

**SC-001: Mark a copy as lost with automatic fine generation**
1. Librarian finds copy "BARC-00123" is lost, clicks "Mark Lost"
2. System sets is_lost=true, status=Lost
3. System finds active transaction for this copy (student Ravi had it issued)
4. Transaction status changed to Lost, return_date set to now
5. System finds replacement cost: ₹850 (from purchase item's book_price)
6. LibFine created with amount=850, member=Ravi, fine_type=LostBook, status=Pending
7. Ravi's outstanding_fines incremented by 850
8. Parent book availability recalculated
9. Flash success: "Copy marked as lost."

**SC-002: Update copy's shelf location during reorganization**
1. Librarian edits copy, changes shelf_location_id from "Section A-Shelf 1" to "Section B-Shelf 5"
2. System updates shelf_location_id, recalculates book availability
3. Flash success: "Book copy updated successfully."

---

## Failure Scenarios

**FC-001: Delete a copy that is currently issued**
1. Librarian clicks delete on a copy with status "Issued"
2. Controller checks `$copy->status === getIdByCode('Book Status', 'issued')` → true
3. Deletion blocked, flash error: "Cannot delete a copy that is currently issued."
4. Copy remains active. Librarian must wait until the book is returned.

**FC-002: Force delete copy with transaction history**
1. Librarian soft-deletes copy, navigates to Trash, clicks force-delete
2. Copy has transaction records referencing it via FK
3. QueryException with code 23000 caught
4. Flash error: "Cannot delete this record: it is referenced by other records. Remove all dependencies first."
5. Copy remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_book_copies | Main copies table with unique barcode/accession/rfid, FK to books/shelfLocations/conditions/purchases/statusMasters |
| Table | lib_books_master | Parent book; syncBookAvailability() recalculates is_available flag |
| Table | lib_book_conditions | FK for current_condition_id; damaged condition code used in markDamaged |
| Table | lib_book_condition_jnt | Condition history logged on markDamaged and condition changes |
| Table | lib_shelf_locations | FK for physical shelf placement |
| Table | lib_book_purchases | FK for purchase provenance; used for replacement cost calculation |
| Table | lib_library_status_masters | FK for copy status (status_type = 'Book Status') |
| Table | lib_transactions | FK references from issue/return workflow; checked in destroy() and markLost() |
| Table | lib_fines | Created automatically in markLost() for replacement cost |
| Module | Library Book Purchases | Copies are bulk-created from purchase items |
| Module | Library Fines | Consumes lost-book fine generation |

---

## Detailed Field Descriptions (from Lib_Conditions.md Section 4.3)

### Core Identity Fields

**`book_id`** — INT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_books_master.id`. Every copy must belong to a valid book master record.
- **FK Constraint:** `ON DELETE RESTRICT` — prevents deleting a book master if it has active copies.
- **Display:** Book title (with ISBN) shown in copy listing and forms.

**`accession_number`** — VARCHAR(50) NOT NULL
- **Required:** Yes. Must be globally unique across all copies.
- **Uniqueness:** Enforced via `UNIQUE KEY uq_lib_bookCopy_accession`.
- **Purpose:** The accession number is the library's internal tracking identifier for this specific copy, used in manual records and catalog searches.

**`barcode`** — VARCHAR(100) NOT NULL
- **Required:** Yes. Must be globally unique across all copies.
- **Uniqueness:** Enforced via `UNIQUE KEY uq_lib_bookCopy_barcode`.
- **Purpose:** Primary machine-readable identifier. Scanned at the circulation desk during issue/return/renewal.

**`rfid_tag`** — VARCHAR(100) NULL
- **Required:** No. Optional — libraries using RFID tags store the tag ID here.
- **Uniqueness:** Enforced via `UNIQUE KEY uq_lib_bookCopy_rfid` (only non-NULL values).
- **Purpose:** Enables automated check-in/check-out via RFID gates.

### Location & Condition

**`shelf_location_id`** — INT UNSIGNED NULL
- **Required:** No. FK to `lib_shelf_locations.id`. Initially NULL until the librarian assigns a shelf location after cataloging.
- **FK Constraint:** `ON DELETE RESTRICT`.
- **Dropdown Filter:** Only active shelf locations are shown in copy forms.
- **Display:** Full location path (Rack → Shelf) is shown in copy views.

**`current_condition_id`** — INT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_book_conditions.id`. Every copy must have an assessed condition at all times.
- **Update Triggers:**
  1. **On Purchase Receive:** Condition is set based on the purchase receive assessment.
  2. **On Issue / Renewal Approval:** Condition is checked and recorded.
  3. **On Return:** Condition is re-assessed. If degraded from issue-time condition, a fine may apply.
- **Business Rule:** Books in `is_borrowable = 0` condition (Damaged, Lost, Withdrawn) cannot be issued to members.

**`book_purchase_id`** — INT UNSIGNED NULL
- **Required:** No. FK to `lib_book_purchases.id`. NULL for donated copies; populated for purchased copies.
- **FK Constraint:** `ON DELETE SET NULL` — if the purchase is deleted, this reference becomes NULL (no data loss).
- **Traceability:** Creates the chain: Purchase Header → Purchase Item → Book Copy.

### State Flags

**`is_lost`** — TINYINT(1) NOT NULL DEFAULT 0
- **Default:** 0 (not lost).
- **Business Rule:** When `is_lost = 1`, the copy CANNOT be issued to any member.
- **Trigger:** Setting this flag may automatically update `status` to a "Lost" status master.
- **Recovery:** When a lost copy is found, `is_lost` is reset to 0, and `status` is updated to "Available".
- **Fine/Liability:** When a member reports a copy as lost, a replacement fine is levied via the fines module.

**`is_damaged`** — TINYINT(1) NOT NULL DEFAULT 0
- **Default:** 0 (not damaged).
- **Business Rule:** When `is_damaged = 1`, the copy's condition degrades and `current_condition_id` should be updated to a "Damaged" condition.
- **Usage:** Set during return assessment if the book is returned in worse condition than when issued.

**`is_withdrawn`** — TINYINT(1) NOT NULL DEFAULT 0
- **Default:** 0 (active).
- **Business Rule:** When `is_withdrawn = 1`, the copy is permanently removed from circulation.
- **Withdrawal Reason:** Must be documented in `withdrawal_reason` field.
- **Status:** Cannot be re-activated once withdrawn (unlike lost/damaged which are reversible).

**`withdrawal_reason`** — VARCHAR(512) NULL
- **Required:** Conditional — must be provided when `is_withdrawn = 1`.
- **Examples:** "Weed out — outdated edition", "Damaged beyond repair", "Stolen — insurance claim filed".

### Status & Due Date

**`status`** — SMALLINT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_library_status_masters.id` where `status_type = 'Book Status'`.
- **Possible Values:** Available, Issued, Reserved, Under Maintenance, Lost, Withdrawn (pre-seeded in status masters).
- **Update Triggers (Status Lifecycle):**
  1. **On Issue:** Status changes from "Available" → "Issued"; `current_due_date` is set.
  2. **On Return:** Status changes from "Issued" → "Available"; `current_due_date` is cleared.
  3. **On Renewal Approval:** Status remains "Issued"; `current_due_date` is extended.
  4. **On Lost Report:** Status changes to "Lost".
  5. **On Withdraw:** Status changes to "Withdrawn".
- **Index:** `idx_lib_bookCopy_status_active` (`status`, `is_active`) — optimized for queries filtering by status + active state.

**`current_due_date`** — DATE NULL
- **Required:** No. NULL when the copy is available/not issued.
- **Set When:** Copy is issued to a member or a renewal is approved.
- **Cleared When:** Copy is returned.
- **Business Rule:** If `CURRENT_DATE > current_due_date`, the copy is considered overdue, and fines may accrue.

**`notes`** — TEXT NULL
- **Required:** No. Free-text field for internal librarian notes (e.g., "Repair pending", "Gift from Alumni Association", "Missing pages 45-48").

**`is_active`** — TINYINT(1) NOT NULL DEFAULT 1
- **Default:** 1 (active).
- **Business Rule:** Inactive copies are hidden from dropdowns and circulation operations but retained for audit/historical purposes.

### Condition Lifecycle & Degradation

The `lib_book_copies` and `lib_book_condition_jnt` tables interact across the copy lifecycle as follows:

```
  Purchase Receive     Issue to Member     Return from Member
         │                    │                     │
         ▼                    ▼                     ▼
  ┌──────────────────────────────────────────────────────────┐
  │              lib_book_condition_jnt                       │
  │  INSERT (date=receive_date, condition=New)                │
  │  INSERT (date=issue_date,   condition=Good)               │
  │  INSERT (date=return_date,  condition=Fair) ← degraded!   │
  └──────────────────────────────────────────────────────────┘
         │                    │                     │
         └──────────┬────────┴──────────┬──────────┘
                    ▼                    ▼
       ┌────────────────────┐  ┌──────────────────────┐
       │ lib_book_copies     │  │ Fine Assessment      │
       │ current_condition   │  │ If return_condition  │
       │ updated to latest   │  │ < issue_condition   │
       │ condition_id        │  │ → fine applicable    │
       └────────────────────┘  └──────────────────────┘
```

- **Condition Degradation Rule (Fine Applicability):**
  - When `return_condition.is_borrowable = false` OR `return_condition_id < issue_condition_id` (lower = worse), a fine for damage/loss may be applied.
  - The fine amount is determined by the library's fine slab configuration based on condition severity difference.
  - Applicable for both lost (`is_lost = 1`) and damaged (`is_damaged = 1`) returns.

### FK Constraints & Indexes

**Unique Keys:**
- `uq_lib_bookCopy_barcode` — barcode must be unique across all copies
- `uq_lib_bookCopy_accession` — accession number must be unique across all copies
- `uq_lib_bookCopy_rfid` — RFID tag must be unique (supports NULL)

**FK Constraints:**
- `fk_lib_bookCopy_bookId` → `lib_books_master(id)` — RESTRICT
- `fk_lib_bookCopy_shelfLocationId` → `lib_shelf_locations(id)` — RESTRICT
- `fk_lib_bookCopy_conditionId` → `lib_book_conditions(id)` — RESTRICT
- `fk_lib_bookCopy_purchaseId` → `lib_book_purchases(id)` — SET NULL
- `fk_lib_bookCopy_status` → `lib_library_status_masters(id)` — RESTRICT

**Indexes:**
- `idx_lib_bookCopy_book` (`book_id`) — efficient book-based lookups
- `idx_lib_bookCopy_barcode` (`barcode`) — fast barcode scan lookups
- `idx_lib_bookCopy_accession` (`accession_number`) — fast accession-based lookups
- `idx_lib_bookCopy_location` (`shelf_location_id`) — efficient location-based queries
- `idx_lib_bookCopy_status_active` (`status`, `is_active`) — circulation status + active state queries
- `idx_lib_bookCopy_condition` (`current_condition_id`) — condition-based reporting
