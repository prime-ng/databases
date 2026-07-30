# Lib Book Purchases — Business Requirements

## What This Screen Does

The Book Purchases screen records library acquisition transactions — when the library buys books and digital resources from vendors or suppliers. Each purchase record captures the vendor, invoice/bill number, bill date, financial totals (bill amount, tax amount, net amount), and a breakdown of items purchased. Every item line specifies which book was bought, the resource type (physical or digital), quantity, unit price, tax details, and automatically calculated amounts. When a purchase is saved, the system creates individual copy records for physical books or digital resource records for digital items, establishing the direct link between acquisition and inventory.

This screen is a tab within the Library Acquisition hub alongside Books and Book Copies. The create/edit process uses a `BookPurchaseService` that handles the full flow of creating the purchase header, items, and inventory records in a single transaction.

---

## When This Screen Is Used

- When the library purchases new books from an approved vendor
- When recording a shipment of books and their associated costs for accounting
- When viewing or editing purchase history for budget tracking and audit
- When managing the financial details of acquisitions (per-item costs, tax breakdowns)
- When tracing which purchase order a specific book copy came from

## Default Data Load

The Book Purchases screen opens as a tab pane within the Library Acquisition hub page (`library.acquisitionIndex` with `tab=book-purchases`). The `index()` method redirects to the hub. The paginated list loads purchases with vendor relation, ordered by latest. The create form loads all active vendors, books, resource types, book copies, and digital resources as dropdown options. Show view loads the purchase with vendor, items (with book, resourceType, copy, digitalResource).

---

## Key Fields at a Glance

**Purchase Header**
Every purchase is linked to a vendor (FK to `vnd_vendors.id` with ON DELETE RESTRICT). The bill number (VARCHAR(50)) captures the vendor's invoice reference. The bill date (DATE) records when the purchase was made. Notes (VARCHAR(150)) allow free-text annotations.

**Financial Breakdown**
The bill amount (DECIMAL 12,2) is the total cost of all items before tax. The bill tax amount (DECIMAL 10,2) captures the total tax. The bill net amount (DECIMAL 12,2) is the final total including tax. All three are stored at the header level and can be auto-calculated from item totals.

**Purchase Items**
Each item line references a book (FK to `lib_books_master.id`), resource type (FK to `lib_resource_types.id`), unit price (DECIMAL 10,2), quantity (INT, min 1), and auto-calculated amounts: item total (book_amt = price × qty), tax amount (book_tax_amt = book_amt × tax_percent/100), and net amount (book_net_amt = book_amt + book_tax_amt). Each item can optionally link to an existing book copy or digital resource. The item's `resource_type_id` must match the book's own resource type — validated by a custom after-validation hook.

---

## Business Rules and Conditions

**Resource Type Matching**
Each purchase item's `resource_type_id` must match the book's own `resource_type_id` from `lib_books_master`. The `StoreLibBookPurchaseRequest` includes an after-validation callback that checks this and adds per-item errors for mismatches.

**Auto-Creation of Copies and Digital Resources**
When the `BookPurchaseService` processes a purchase, it creates individual `LibBookCopy` records for physical resources (one per quantity) and `LibDigitalResource` records for digital resources. Each copy/resource is linked back to the purchase item via `book_copy_id` or `digital_resource_id`.

**Vendor FK Restriction**
The `lib_book_purchases.vendor_id` FK uses `ON DELETE RESTRICT`, preventing deletion of a vendor that has purchase records.

**Financial Calculation Convention**
Item-level: `book_amt = book_price × book_quantity`. `book_tax_amt = book_amt × (book_tax_percent / 100)`. `book_net_amt = book_amt + book_tax_amt`. The header-level `bill_amt`, `bill_tax_amt`, and `bill_net_amt` should represent the sum of all item values.

**Delete Protection via FK Restrict**
The `lib_book_purchases_items.book_id` FK uses `ON DELETE RESTRICT`, preventing deletion of a book master that has purchase records. Purchase items FK to book copies and digital resources use `ON DELETE SET NULL`, allowing those resources to exist independently after a purchase item is removed.

**Cascade Delete on Purchase**
When a purchase is force-deleted, its items are deleted via CASCADE (`lib_book_purchases_items.book_purchase_id` FK uses `ON DELETE CASCADE`). However, the copies and digital resources created from those items are set to NULL (`ON DELETE SET NULL`) rather than being deleted.

---

## Workflow Steps

1. Navigate to Library → Acquisition hub → Book Purchases tab
2. View the paginated purchase list with vendor and date info
3. Click "Add Purchase" to open the create form
4. Select vendor, enter bill number (optional), bill date, and notes
5. Add purchase items: select a book, resource type, enter quantity, unit price, tax head/percent
6. System auto-calculates item totals; review the grand total at the bottom
7. Save — the service creates the purchase header, items, and inventory records (copies or digital resources)
8. View a purchase to see all items and their linked copies/resources
9. Edit a purchase to modify items, quantities, or financials — the service updates all related records
10. Delete sends to trash; force-delete handles FK constraint protection

---

## Example Scenario

The library receives an invoice from "ABC Book Distributors" for 30 copies of "Mathematics for Class 10" and 5 digital licenses of "Interactive Science Grade 8". The librarian creates a new purchase with vendor ABC, enters the bill date and invoice number, and adds two item lines: 30 copies at ₹450 each (physical, 12% tax) and 5 digital licenses at ₹800 each (digital, 18% tax). The system calculates: physical item total = 30×450 = ₹13,500, tax = ₹1,620, net = ₹15,120; digital item total = 5×800 = ₹4,000, tax = ₹720, net = ₹4,720. On save, the system creates 30 individual book copy records for the physical books and 5 digital resource records. The copies all reference this purchase ID for provenance tracking.

---

## Related Screens

- Books Master — books must exist before they can appear in purchase items
- Book Copies — copies auto-created from purchase items, linked via book_purchase_id
- Digital Resources — digital resources auto-created from digital purchase items
- Library Acquisition Hub — parent tab container (Books + Book Copies + Purchases)
- Vendor Module — vendors referenced by purchases

---

## Requirements

**Controller:** `Modules\Library\Http\Controllers\LibBookPurchaseController`
**Model:** `Modules\Library\Models\LibBookPurchase` (table: `lib_book_purchases`, uses `SoftDeletes`)
**Model (Items):** `Modules\Library\Models\LibBookPurchaseItem` (table: `lib_book_purchases_items`, uses `SoftDeletes`)
**Service:** `Modules\Library\Services\BookPurchaseService` (handles header + items + inventory creation in one transaction)
**Requests:** `StoreLibBookPurchaseRequest` (validates header + items array with resource type matching validation)
**Policy:** Named permission string `tenant.lib-book-purchases.*`
**Route:** Resource route `Route::resource('lib-book-purchases', LibBookPurchaseController::class)` with extras: `trashed`, `restore`, `forceDelete`, `getBookResources`

Key controller methods:
- `index()` — Redirects to hub tab with `tab=book-purchases`
- `create()` — Returns create form with vendors, books, resourceTypes, bookCopies, digitalResources
- `store(StoreLibBookPurchaseRequest)` — Delegates to `BookPurchaseService::createPurchase()`; catches duplicate entry exception
- `show($id)` — Loads with vendor, items (with book, resourceType, copy, digitalResource)
- `edit($id)` — Loads purchase with items for editing
- `update(StoreLibBookPurchaseRequest, $id)` — Delegates to `BookPurchaseService::updatePurchase()`; catches FK exception
- `destroy($id)` — Soft-deletes
- `trashed()` — Lists soft-deleted purchases with vendor
- `restore($id)` — Restores from trash
- `forceDelete($id)` — Force-deletes; catches FK exception with user-friendly message
- `getBookResources($book_id)` — AJAX endpoint returning copies and digital resources for a book

**ActivityLog Events:** Stored, Updated (with changes), Trashed, Restored, Deleted

---

## Who Can Access This Screen

| Role | Permission | Access Level |
|------|-----------|-------------|
| Super Admin | `tenant.lib-book-purchases.*` | Full access (bypasses policy via Gate::before) |
| Library Admin | `tenant.lib-book-purchases.*` | Full CRUD including purchase creation and editing |
| Librarian | `tenant.lib-book-purchases.viewAny`, `.view`, `.create` | View and add purchases |
| Library Assistant | `tenant.lib-book-purchases.viewAny`, `.view` | Read-only access |

---

## How This Screen Works — Logic Flow (Non-Technical)

The user opens the Library Acquisition page and clicks the Book Purchases tab. They see a list of all purchase orders with vendor name, invoice number, date, total items, and total amount. Clicking "Add Purchase" opens a form where the user selects a vendor, enters the invoice details, and adds individual line items for each book being purchased. For each item, they specify the book, whether it's physical or digital, the quantity, unit price, and any tax. The system automatically calculates each line total and shows a running grand total. When saved, the system not only records the purchase but also automatically creates individual copy records for physical books and digital resource records for digital items — each copy gets a unique barcode and accession number, linked back to this purchase for future tracking.

---

## Validate Before Save

| # | Field | Rule | Error Message |
|---|-------|------|---------------|
| 1 | vendor_id | Required, Exists:vnd_vendors,id | Vendor is required. |
| 2 | bill_no | Nullable, String, Max:50 | — |
| 3 | bill_date | Required, Date | Bill date is required. |
| 4 | bill_amt | Required, Numeric, Min:0 | Bill amount must be a non-negative number. |
| 5 | bill_tax_amt | Required, Numeric, Min:0 | Tax amount is required. |
| 6 | bill_net_amt | Required, Numeric, Min:0 | Net amount is required. |
| 7 | notes | Nullable, String, Max:150 | — |
| 8 | items | Nullable, Array | — |
| 9 | items.*.book_id | Required with items, Exists:lib_books_master,id | Book is required for each item. |
| 10 | items.*.resource_type_id | Required with items, Exists:lib_resource_types,id | Resource type is required. |
| 11 | items.*.book_price | Required with items, Numeric, Min:0 | Price must be a non-negative number. |
| 12 | items.*.book_quantity | Required with items, Integer, Min:1 | Quantity must be at least 1. |
| 13 | items.*.book_tax_percent | Required with items, Numeric, 0-100 | Tax percentage must be between 0 and 100. |
| 14 | items.*.* | Resource type must match book's resource_type_id | The selected resource type does not match the resource type of the book '[title]'. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Status |
|----------|--------------|-------------|
| Validation fails | (per-field messages from Validate Before Save table) | 422 |
| Gate authorization fails | This action is unauthorized. | 403 |
| Duplicate entry (store) | A duplicate entry was detected. Please check the bill number and try again. | 422 (redirect with flash) |
| Duplicate entry (update) | A duplicate entry was detected. Please check the data and try again. | 422 (redirect with flash) |
| Force delete — FK constraint | Cannot delete this record: it is referenced by other records. Remove all dependencies first. | 422 (redirect with flash) |
| Model not found (show/edit) | No query results for model | 404 |
| Resource type mismatch | The selected resource type does not match the resource type of the book '[title]'. | 422 (per-item error) |

---

## Success Scenarios

**SC-001: Create a purchase with multiple item lines**
1. Librarian selects vendor "ABC Books", enters bill date and invoice number
2. Adds item 1: "Mathematics Class 10", physical, quantity 30, unit price ₹450, tax 12%
3. Adds item 2: "Science Grade 8 Digital", digital, quantity 5, unit price ₹800, tax 18%
4. System calculates item totals and grand total correctly
5. Librarian saves — BookPurchaseService creates header, items, 30 book copies, 5 digital resources
6. Flash success: "Book purchase created successfully."

**SC-002: Edit purchase to adjust quantity**
1. Librarian edits purchase ABC-2026-001, changes item 1 quantity from 30 to 35
2. Service recalculates totals and adjusts copy count accordingly (creates 5 additional copies)
3. Flash success: "Book purchase updated successfully."

---

## Failure Scenarios

**FC-001: Resource type mismatch on purchase item**
1. Librarian adds item for "Mathematics Class 10" (a physical book) but selects "Digital" as resource type
2. FormRequest after-validation callback detects mismatch
3. Per-item validation error: "The selected resource type does not match the resource type of the book 'Mathematics Class 10'."
4. Librarian corrects the resource type and resubmits successfully

**FC-002: Force delete purchase with referenced copies**
1. Librarian deletes a purchase (soft-delete), then navigates to Trash
2. Clicks force-delete — DB has copies referencing this purchase via `book_purchase_id` FK
3. ON DELETE RESTRICT on copies FK blocks the deletion
4. QueryException code 23000 caught, flash error: "Cannot delete this record: it is referenced by other records. Remove all dependencies first."
5. Purchase remains in trash

---

## Dependencies module and tables

| Type | Name | Details |
|------|------|---------|
| Table | lib_book_purchases | Purchase header with vendor_id (FK → vnd_vendors.id, ON DELETE RESTRICT), bill_no, bill_date, financial totals |
| Table | lib_book_purchases_items | Purchase items with book_id (FK → lib_books_master.id, ON DELETE RESTRICT), resource_type_id, price/quantity/tax amounts; links to book_copies and digital_resources via SET NULL |
| Table | lib_book_copies | Created automatically from purchase items; FK to book_purchase_id (ON DELETE SET NULL) |
| Table | lib_digital_resources | Created automatically from digital purchase items; FK to book_purchase_id |
| Table | lib_books_master | Books must exist before purchase; FK restrict on purchase items |
| Table | lib_resource_types | Resource type categorization for each item |
| Module | Vendor | Vendors referenced by purchases (vnd_vendors) |
| Module | Library Book Copies | Consumes purchase data for copy creation |
| Service | BookPurchaseService | Handles the full transaction of creating header + items + inventory records |

---

## Detailed Field Descriptions (from Lib_Conditions.md Section 4.2 & 4.2a)

### Purchase Header (`lib_book_purchases`)

**`vendor_id`** — INT UNSIGNED NOT NULL
- **Required:** Yes. FK to `vnd_vendors.id`. Every purchase must have a valid vendor.
- **FK Constraint:** `ON DELETE RESTRICT` — a vendor cannot be deleted if referenced by any purchase.
- **Dropdown Filter:** Only active vendors are shown in create/edit forms.
- **Display:** Vendor name is shown on purchase index, show, and edit pages.

**`bill_no`** — VARCHAR(50) NULL
- **Required:** No. Optional reference to the vendor's invoice number.
- **Search:** Searchable via text search in the purchase listing.
- **Uniqueness:** Not enforced at DB level (different vendors may use the same bill numbers).

**`bill_date`** — DATE NOT NULL
- **Required:** Yes. Must be a valid date.
- **Business Rule:** Cannot be a future date beyond the current system date.
- **Display:** Formatted as per locale in views (e.g., `d-m-Y`).

**`bill_amt`** — DECIMAL(12,2) NOT NULL DEFAULT 0
- **Auto-Calculated:** Total cost of all copies before tax = `SUM(items.book_amt)` where `deleted_at IS NULL`.
- **Manual Override:** Not directly editable — computed from line items via DB trigger/procedure `recalc_purchase_totals`.
- **Precision:** 12 total digits, 2 decimal places. Max value: 999,999,999.99.

**`bill_tax_amt`** — DECIMAL(10,2) NOT NULL DEFAULT 0
- **Auto-Calculated:** Total tax across all items = `SUM(items.book_tax_amt)` where `deleted_at IS NULL`.
- **Manual Override:** Not directly editable — computed from line items.
- **Precision:** 10 total digits, 2 decimal places. Max value: 99,999,999.99.

**`bill_net_amt`** — DECIMAL(12,2) NOT NULL DEFAULT 0
- **Auto-Calculated:** Total cost including tax = `SUM(items.book_net_amt)` or `bill_amt + bill_tax_amt`.
- **Manual Override:** Not directly editable — computed from line items.
- **Display:** Shown prominently as the final payable amount in purchase views.
- **Verification:** MUST equal `bill_amt + bill_tax_amt`. If these don't match, a data integrity issue exists.

**`notes`** — VARCHAR(150) NULL
- **Required:** No. Free-text for internal notes (e.g., "Urgent order — requested by Principal").

### Purchase Items (`lib_book_purchases_items`)

**`book_id`** — INT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_books_master.id`.
- **FK Constraint:** `ON DELETE RESTRICT` — prevents deleting a book if it appears in any purchase item.

**`resource_type_id`** — SMALLINT UNSIGNED NOT NULL
- **Required:** Yes. FK to `lib_resource_types.id`. Determines how the item is processed after purchase.
- **Validation Rule (CRITICAL):** This field MUST match the parent `resource_type_id` of the selected book in `lib_books_master`. A physical book title cannot be purchased as a digital resource, and vice versa.
- **Business Rules:**
  - If `resource_type.is_physical = 1` → A `book_copy_id` must be created (via `lib_book_copies`) after cataloging.
  - If `resource_type.is_digital = 1` → A `digital_resource_id` must be created (via `lib_digital_resources`).

**`book_copy_id`** — INT UNSIGNED NULL
- **Required:** No. FK to `lib_book_copies.id`. Initially NULL when a purchase is recorded. Populated after cataloging.
- **FK Constraint:** `ON DELETE SET NULL` — if the copy is hard-deleted, the purchase item reference becomes NULL.
- **Multi-Copy/Quantity Constraint (CRITICAL):** Since this is a single ID column, it can only link to exactly one physical copy. If `book_quantity > 1`:
  - Either separate purchase item rows must be created for each copy (each having `book_quantity = 1`).
  - Or the copies must be linked back to the purchase header/item via the copy table's own references (e.g., `book_purchase_id` / `purchase_item_id` in `lib_book_copies`), while `book_copy_id` here remains NULL or references only the first copy.
- **Business Rule:** This field creates the traceability link: Purchase → Item → Copy.

**`digital_resource_id`** — INT UNSIGNED NULL
- **Required:** No. FK to `lib_digital_resources.id`. Initially NULL for digital purchases. Populated after cataloging.
- **FK Constraint:** `ON DELETE SET NULL` — if the digital resource is hard-deleted, the reference becomes NULL.

**`book_price`** — DECIMAL(10,2) NOT NULL DEFAULT 0
- **Required:** Yes. Per-unit price as listed on the vendor's invoice.
- **Validation Rule:** Must be `>= 0.00`. Negative prices are blocked.
- **Precision:** 10 digits, 2 decimals. Max: 99,999,999.99.

**`book_quantity`** — INT NOT NULL DEFAULT 1
- **Required:** Yes. Must be `>= 1`. Zero or negative quantities are blocked.

**`book_tax_head`** — VARCHAR(50) NULL
- **Required:** No. Free-text description of the applicable tax (e.g., 'GST 18%', 'VAT 5%').

**`book_tax_percent`** — DECIMAL(5,2) NOT NULL DEFAULT 0
- **Required:** Yes (defaults to 0). Must be `>= 0.00` and `<= 100.00`.

### Auto-Calculated Item Fields

| Field | Formula | Example |
|-------|---------|---------|
| **`book_amt`** | `book_price × book_quantity` | ₹500 × 3 = ₹1,500.00 |
| **`book_tax_amt`** | `book_amt × (book_tax_percent ÷ 100)` | ₹1,500 × (18 ÷ 100) = ₹270.00 |
| **`book_net_amt`** | `book_amt + book_tax_amt` | ₹1,500 + ₹270 = ₹1,770.00 |

- **Trigger:** Calculated by BEFORE INSERT / BEFORE UPDATE triggers on `lib_book_purchases_items`.
- **Precision & Rounding Rule:** All line-item calculations must be rounded to exactly 2 decimal places (using `round(value, 2)` or `BCMath` library in PHP) before storing or aggregating, to avoid floating-point drift.
- **Soft-Delete Rule (CRITICAL):** Any items that are soft-deleted (`deleted_at IS NOT NULL`) MUST be completely ignored and excluded from rollup calculations.

### Purchase Auto-Calculation Flow (Complete)

**Step 1: Line Item Calculations** — Per-item `book_amt`, `book_tax_amt`, `book_net_amt` computed via DB triggers on INSERT/UPDATE.

**Scenario 1: No Tax (Tax-Exempt Purchase)**
| Input | Value |
|-------|-------|
| `book_price` | ₹500.00 |
| `book_quantity` | 3 |
| `book_tax_percent` | 0.00 |
| `book_amt` | ₹1,500.00 |
| `book_tax_amt` | ₹0.00 |
| `book_net_amt` | ₹1,500.00 |

**Scenario 2: Standard Tax (18% GST)**
| Input | Value |
|-------|-------|
| `book_price` | ₹500.00 |
| `book_quantity` | 3 |
| `book_tax_percent` | 18.00 |
| `book_amt` | ₹1,500.00 |
| `book_tax_amt` | ₹270.00 |
| `book_net_amt` | ₹1,770.00 |

**Scenario 3: Mixed Tax Items (Multiple Books with Different Tax Rates)**
| Item | Price | Qty | Tax% | book_amt | book_tax_amt | book_net_amt |
|------|-------|-----|------|----------|-------------|-------------|
| Book A | ₹500 | 3 | 18% | ₹1,500.00 | ₹270.00 | ₹1,770.00 |
| Book B | ₹1,200 | 2 | 12% | ₹2,400.00 | ₹288.00 | ₹2,688.00 |
| Book C | ₹300 | 5 | 0% | ₹1,500.00 | ₹0.00 | ₹1,500.00 |
| **Total** | | | | **₹5,400.00** | **₹558.00** | **₹5,958.00** |

**Step 2: Header Rollup Calculations** — The purchase header aggregates all active (non-deleted) line item totals:
| Field | Formula | Example (Scenario 3) |
|-------|---------|---------------------|
| **`bill_amt`** | `SUM(items.book_amt)` where `deleted_at IS NULL` | ₹5,400.00 |
| **`bill_tax_amt`** | `SUM(items.book_tax_amt)` where `deleted_at IS NULL` | ₹558.00 |
| **`bill_net_amt`** | `bill_amt + bill_tax_amt` (or `SUM(items.book_net_amt)`) | ₹5,958.00 |

**Step 3: Calculation Constraints & Validation Edge Cases**
1. **Future Date Prevention:** `bill_date` cannot be set to any date in the future (must be `<= CURRENT_DATE`).
2. **Zero Price/Free Books:** If a book is received as a donation or sample, `book_price` can be 0.00. However, `book_quantity` must still be `>= 1`.
3. **No Mismatched Totals:** Frontend MUST enforce auto-calculations on keystroke using the formulas to prevent validation failures on submission.

**Step 4: Post-Cataloging Linkage**
| Resource Type | Post-Cataloging Action |
|--------------|----------------------|
| **Physical** (`is_physical = 1`) | A row is created in `lib_book_copies`. `book_copy_id` in the purchase item is updated to reference this new copy. |
| **Digital** (`is_digital = 1`) | A row is created in `lib_digital_resources`. `digital_resource_id` in the purchase item is updated to reference this new resource. |

This creates a complete traceability chain: **Purchase Header → Purchase Item → Book Copy / Digital Resource**.
