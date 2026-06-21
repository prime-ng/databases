# Library Tab 4: Book Copies & Locations

This tab manages individual physical copies of books. While the Book Master Catalog tracks the title, this tab tracks each actual copy — where it is, what condition it is in, and its circulation status.

---

## How It Works

When the librarian opens this tab, they first search for a book master record. Below the selected book, they see a table listing every physical copy. Each row shows the copy's accession number, barcode, current status (Available, Issued, Reserved, Under Maintenance, Lost, Withdrawn), shelf location, current condition, and purchase details.

**Adding a New Copy:** The librarian clicks "Add Copy" for the selected book. They enter the accession number (auto-generated or manual), barcode, RFID tag (optional), shelf location, condition at acquisition, purchase date, purchase price, and vendor. The new copy is created with status "Available."

**Managing Copy Status:** The librarian can mark a copy as:
- Under Maintenance — when the copy needs repair
- Lost — when a copy cannot be found after a reasonable search period
- Withdrawn — when a copy is permanently removed from the collection (with reason)

Each status change records the date, the staff member who made the change, and the reason.

**Condition Tracking:** When a copy is issued or returned, the librarian records its condition. The condition history is maintained in `lib_book_condition_jnt`, showing every condition change with date and notes. When the condition drops to "Poor" or "Damaged," the system warns that the copy should not be issued until repaired.

**Moving Copies:** If a copy is moved to a different shelf location, the librarian updates the location. The system logs the move in the activity log.

**Bulk Operations:** The librarian can select multiple copies and perform bulk actions like changing shelf location, updating condition, or exporting copy details.

---

## Important Business Rules

- Each copy must have a unique accession number within the library. The system auto-generates a sequential number but allows manual override.
- Barcodes and RFID tags are optional but must be unique if provided.
- A copy with status "Issued" cannot be withdrawn or marked as lost. The librarian must first receive the return.
- A copy with status "Lost" can be marked as "Found" if rediscovered. This restores the previous status.
- Withdrawing a copy requires a reason (min 10 characters). Common reasons: damaged beyond repair, outdated content, stolen.
- The condition at issue time is recorded in `lib_transactions.issue_condition_id`. The condition at return is recorded in `lib_transactions.return_condition_id`. If the return condition is worse than the issue condition, the system flags it for fine calculation.
- Copies of reference-only books have the same issue restrictions — they cannot be issued regardless of status.
- A copy's purchase price is used for fine calculation if the book is lost and the fine slab specifies "BookCost" as the maximum fine type.

---

## Database Columns & Behavior

### `lib_book_copies`

(Full column table documented in Tab 1 — Dashboard.)

### `lib_book_condition_jnt`

| Column | Type | FK | Nullable | Default | Behavior |
|--------|------|----|----------|---------|----------|
| id | BIGINT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| book_id | BIGINT UNSIGNED | `lib_books_master.id` | No | — | Book reference |
| date | DATE | No | No | — | When condition was assessed |
| condition_id | BIGINT UNSIGNED | `lib_book_conditions.id` | No | — | Assessed condition |
| note | TEXT | No | Yes | NULL | Optional notes |
| created_at | TIMESTAMP | No | Yes | CURRENT_TIMESTAMP | Record creation |

**Note:** This table tracks condition changes at the book master level. For copy-level condition tracking, see `lib_book_copies.current_condition_id`.

---

## Deep Analysis

### Business Workflows & State Machines

**Copy Status Lifecycle:**
```
AVAILABLE ──→ ISSUED (via transaction)
     ↑            ↓
     │       RETURNED → AVAILABLE
     │            ↓
     │          OVERDUE → (returned) → AVAILABLE
     │                     (lost) → LOST
     │
     ├──→ UNDER MAINTENANCE → (repaired) → AVAILABLE
     ├──→ LOST → (found) → AVAILABLE
     └──→ WITHDRAWN (terminal state)
```

**Condition Change Flow:**
```
Record condition at issue → Store in issue_condition_id
Record condition at return → Store in return_condition_id
  → If return_condition < issue_condition: flag for fine
  → Update lib_book_copies.current_condition_id
  → Log to lib_book_condition_jnt (if applicable)
```

### Validation Rules & Edge Cases

| Operation | Rule | Error Message |
|-----------|------|---------------|
| Add copy | Accession number unique | "Accession number {value} already exists" |
| Add copy | Barcode unique (if provided) | "Barcode {value} is already assigned to another copy" |
| Mark as withdrawn | Copy must not be issued | "Cannot withdraw a copy that is currently issued" |
| Mark as lost | Copy must not be issued | "Return the copy first or mark as lost during return" |
| Mark as found | Copy must be in "Lost" status | "Only lost copies can be marked as found" |
| Change location | Copy must be available | "Cannot move a copy that is currently issued or reserved" |
| Update condition | New condition must exist | "Invalid condition selected" |

**Edge Cases:**
- If a copy is lost and later found, all lost-related fine records remain but a new condition assessment is required.
- Withdrawn copies remain in the database for historical reference but do not appear in the available count.
- A copy withdrawn due to damage has its condition recorded at withdrawal time for insurance purposes.
- If all copies of a book are withdrawn or lost, the book master record shows "No copies available" in search results.

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| Book Master | `lib_books_master` | `book_id` | Parent catalog record |
| Shelf Location | `lib_shelf_locations` | `shelf_location_id` | Physical placement |
| Book Condition | `lib_book_conditions` | `current_condition_id` | Condition state |
| Transactions | `lib_transactions` | `copy_id` (via transaction) | Issue/return history |
| Vendor | External | `vendor_id` | Purchase source |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View copies | Librarian, Admin | `tenant.library.copies.view` |
| Add copy | Librarian, Admin | `tenant.library.copies.create` |
| Edit copy details | Librarian, Admin | `tenant.library.copies.update` |
| Update condition | Librarian, Admin | `tenant.library.copies.assessCondition` |
| Mark lost/found | Librarian, Admin | `tenant.library.copies.markLost` |
| Mark withdrawn | Admin only | `tenant.library.copies.withdraw` |
| Bulk operations | Librarian, Admin | `tenant.library.copies.bulkUpdate` |
