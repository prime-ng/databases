# Stock Ledger — Requirements

## What It Does
Provides the immutable central journal of all stock movements (inv_stock_entries) and the denormalized running balance per item per godown (inv_stock_balances). Every stock entry is append-only — once created it can never be updated or deleted. Corrections are handled exclusively through new Adjustment entries. Stock Balances is updated atomically with row-level locks to prevent race conditions on concurrent writes.

## Database Fields

### inv_stock_entries

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `stock_item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Item being moved. |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Required. Source (outward) or destination (inward) godown. |
| `voucher_id` | BIGINT UNSIGNED FK → acc_vouchers | Required. NOT NULL — every stock entry must have an accounting voucher (BR-INV-001). No orphan entries. |
| `entry_type` | ENUM('inward','outward','transfer_in','transfer_out','adjustment') | Required. Type of movement. |
| `quantity` | DECIMAL(15,3) | Required. Movement quantity. |
| `rate` | DECIMAL(15,2) | Required. Valuation rate per unit. |
| `amount` | DECIMAL(15,2) | Required. quantity × rate. Computed at service layer. |
| `batch_number` | VARCHAR(50) | Nullable. Batch number for batch-tracked items (FIFO). |
| `expiry_date` | DATE | Nullable. Batch expiry date. |
| `destination_godown_id` | BIGINT UNSIGNED FK → inv_godowns | Nullable. Only for transfer entries. |
| `party_ledger_id` | BIGINT UNSIGNED FK → acc_ledgers | Nullable. Vendor ledger (inward) or department/expense ledger (outward). |
| `narration` | VARCHAR(500) | Nullable. Movement description. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete — ONLY via StockLedgerService guard; never direct (BR-INV-014). |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_stock_balances

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `stock_item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Unique combo with godown_id. |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Required. Unique combo with stock_item_id. |
| `current_qty` | DECIMAL(15,3) | Required. Default 0. Running stock quantity updated atomically. |
| `current_value` | DECIMAL(15,2) | Required. Default 0. Running stock valuation (qty × rate). |
| `last_entry_at` | TIMESTAMP | Nullable. Timestamp of most recent stock movement for this item+godown. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `stock_item_id` (entry) | Required, integer, exists:inv_stock_items,id | Must reference an active stock item. |
| `godown_id` (entry) | Required, integer, exists:inv_godowns,id | Must reference an active godown. |
| `voucher_id` (entry) | Required, integer, exists:acc_vouchers,id | NOT NULL enforced at DB level (BR-INV-001). Every stock entry requires an accounting voucher. Error: "Stock entry must reference a valid accounting voucher." |
| `entry_type` (entry) | Required, enum: inward/outward/transfer_in/transfer_out/adjustment | Validated against exact enum values. Determined by calling service (GrnPostingService, StockIssueService, etc.). |
| `quantity` (entry) | Required, numeric, min:0.001 | Must be positive. Direction determined by entry_type, not negative quantity. |
| `rate` (entry) | Required, numeric, min:0 | Determined by StockValuationService based on item's valuation method. |
| `amount` (entry) | Read-only | Computed as quantity × rate at service layer before insert. Never accepted from user input. |
| `batch_number` (entry) | Nullable, string, max:50 | Required for items with has_batch_tracking = 1. Selected via FIFO for outward entries (BR-INV-008). |
| `destination_godown_id` (entry) | Nullable, integer, exists:inv_godowns,id | Only for transfer entries (entry_type = 'transfer_out'). Must differ from godown_id. |
| `current_qty` (balance) | Read-only | Updated atomically by StockLedgerService. Never user-supplied. |
| `current_value` (balance) | Read-only | Updated atomically by StockLedgerService. Never user-supplied. |
| `last_entry_at` (balance) | Read-only | Set automatically on every balance update. |

### Entity-Specific Rules / Lifecycle State Machine

**Stock Entry Immutability (BR-INV-014):**
- CRITICAL: inv_stock_entries are append-only — once inserted, they must NEVER be updated or deleted
- Enforcement points:
  1. Route layer: No UPDATE or DELETE routes are exposed for inv_stock_entries
  2. Service layer: StockLedgerService::postEntry() refuses to update/delete existing entries
  3. Model layer: Model events (saving, updating, deleting) check if entry already exists and block the operation
  4. Application convention: All corrections must go through new Adjustment entries
- If an entry was created in error, the only permitted remediation is a new Adjustment entry with opposite sign and appropriate narration

**Stock Balances Atomic Update (BR-INV-015):**
- inv_stock_balances is updated within the same DB transaction as the corresponding inv_stock_entries insert
- StockLedgerService::updateBalance() uses lockForUpdate() (row-level exclusive lock) on the inv_stock_balances row:
  ```php
  DB::transaction(function () use ($itemId, $godownId, $qtyDelta, $valueDelta) {
      $balance = InvStockBalance::where('stock_item_id', $itemId)
          ->where('godown_id', $godownId)
          ->lockForUpdate()
          ->firstOrNew();
      // atomically update
  });
  ```
- lockForUpdate() prevents race conditions when two concurrent requests try to adjust the same (item, godown) balance
- If the balance row does not exist (first entry for this item+godown), it is created (upsert pattern)
- The balance update is guarded: if the computed current_qty would go below 0, the transaction is rolled back with error "Insufficient stock: {item} in {godown}. Requested: {x}, Available: {y}." (BR-INV-003)

**Entry Types and Their Direction:**
| entry_type | Direction | quantity Sign | Stock Effect | Source Service |
|---|---|---|---|---|
| inward | Into godown | Positive (stored as positive) | current_qty increases | GrnPostingService (GRN acceptance) |
| outward | Out of godown | Positive (stored as positive) | current_qty decreases | StockIssueService (stock issue) |
| transfer_out | Out of source godown | Positive (stored as positive) | Source godown qty decreases | StockTransferService |
| transfer_in | Into destination godown | Positive (stored as positive) | Destination godown qty increases | StockTransferService |
| adjustment | Surplus or deficit | Positive (stored as positive) | Increases or decreases based on variance sign | StockAdjustmentService |

**Transfer Handling (Transfer out + Transfer in):**
- Godown-to-godown transfers create TWO entries in a single transaction:
  1. transfer_out from source godown (godown_id = source, destination_godown_id = target)
  2. transfer_in to destination godown (godown_id = target, destination_godown_id = NULL)
- Both entries share the same voucher_id
- Source godown current_qty decremented; destination godown current_qty incremented
- If either entry fails, both are rolled back

**Stock Balances current_value Update:**
- current_value is updated based on the item's valuation_method (inv_stock_items.valuation_method):
  - weighted_average: current_value = (current_value + inward_amount) for inward; current_value -= (outward_qty × weighted_average_rate) for outward
  - fifo: current_value tracks remaining batch values; outward removes oldest batch values
  - last_purchase: current_value updated to last_purchase_rate × current_qty after each inward
- Valuation logic delegated to StockValuationService

**Negative Stock Guard (BR-INV-003):**
- Before ANY outward/transfer_out/adjustment entry: StockLedgerService checks inv_stock_balances.current_qty >= requested quantity
- If insufficient: transaction rolls back, user receives error
- Check is performed AFTER lockForUpdate() to ensure accuracy under concurrent access
- Enforcement at service layer prevents any bypass via direct DB manipulation

**Recalculate Balance Command:**
- Artisan command: `inventory:recalculate-balances {--item=} {--godown=}`
- Reads all inv_stock_entries, computes net movement per (item, godown), and resets inv_stock_balances
- Used for data recovery if balances become desynchronized
- Respects soft-deleted entries (excludes them from calculation)
- Run with caution on large datasets — uses chunk(500) processing

### Data Integrity Rules

- voucher_id is NOT NULL with FK to acc_vouchers — DB-level guarantee (BR-INV-001)
- inv_stock_entries.amount is NOT stored as GENERATED column — computed at service layer for explicit control
- batch_number and expiry_date propagate from GRN acceptance through to stock issue for FIFO traceability
- destination_godown_id only set for transfer_out entries; must be NULL for all other entry types (validated at service layer)
- party_ledger_id connects stock movement to Accounting ledger (vendor for inward, department for outward)
- No direct UPDATE/DELETE on inv_stock_entries — enforced at model, service, and route layers (BR-INV-014)
- inv_stock_balances has UNIQUE (stock_item_id, godown_id) — one balance row per item per location
- inv_stock_entries (stock_item_id, godown_id, created_at) index optimized for ledger queries
- All stock entry mutations must occur inside DB::transaction() — no partial updates
- inv_stock_balances.deleted_at is set (soft delete) only when the (item, godown) combination is no longer in use — never during normal operations

### Soft Delete & Restore Rules

**Soft Delete (inv_stock_entries):**
- NOT ALLOWED under normal circumstances — entries are immutable (BR-INV-014)
- Only StockLedgerService (inventory:recalculate-balances or data correction scripts) can soft-delete entries via explicit service method
- Any application-level soft delete of stock entries is logged as a critical security event in sys_activity_logs
- Normal controllers do NOT expose delete functionality for stock entries

**Soft Delete (inv_stock_balances):**
- Practically never used — balance row is created with first entry and remains for the lifetime of (item, godown)
- Soft delete allowed only via dedicated Artisan command for cleaning up orphaned zero-balance rows
- Pre-delete check: current_qty must be 0. If > 0, error: "Cannot remove balance row with positive stock."

**Restore / Force Delete:**
- Not applicable under normal operations
- Available only via Artisan commands for data recovery scenarios

### Audit Trail Rules

- Every stock entry creation is automatically an audit event — the entry itself IS the audit trail
- StockLedgerService::postEntry() logs to sys_activity_logs with: action = "stock_entry.created", entry_type, item_id, godown_id, quantity, amount
- Balance updates are NOT separately audited (they are derived from entries)
- Any manual correction (via Artisan command) is logged as: action = "stock_entry.correction", with old/new state
- Unauthorized DELETE attempt on stock entries logs: action = "stock_entry.delete_attempt_blocked" as critical security event

### List View Rules

- Controller: index() method (read-only, no create/edit/delete routes exposed) — BR-INV-014 enforced at route level
- Gate: 'inventory.stock-ledger.viewAny'
- Pagination: 25 records per page (ledger can be large)
- Eager loads: stockItem (name, sku), godown (name), destinationGodown (name)
- Default sort: by created_at descending (most recent first)
- Columns displayed: Date, Entry Type (badge — color-coded: green=inward, red=outward, blue=transfer, yellow=adjustment), Item, Godown, Quantity, Rate, Amount, Voucher ID, Batch Number, Narration
- Filter: item_id dropdown (searchable select2 — supports 5000+ items)
- Filter: godown_id dropdown
- Filter: entry_type dropdown (all/inward/outward/transfer_in/transfer_out/adjustment)
- Filter: date range (from/to) for created_at
- Filter: voucher_id (exact match text input — for Accounting reconciliation)
- All filters preserved across pagination
- No create, edit, or delete actions in list view — consistent with immutability rule
- Export button: "Export Ledger" → CSV/Excel download of filtered results

### Integration Rules

**Accounting Integration:**
- StockLedgerService does NOT fire events directly — it is a low-level service called by higher-level services (GrnPostingService, StockIssueService, StockAdjustmentService)
- Each higher-level service fires its own event (GrnAccepted, StockIssued, StockAdjusted) AFTER postEntry() succeeds
- voucher_id on every inv_stock_entries row is the link to Accounting — mandatory NOT NULL (BR-INV-001)
- All inv_stock_entries for a single transaction share the same voucher_id

**Stock Balances — Read API:**
- Route: `GET /inventory/stock-balances` — list view
- Route: `GET /inventory/stock-balances/by-item/{item}` — all godowns for one item
- Route: `GET /inventory/stock-balances/by-godown/{godown}` — all items in one godown
- All routes read-only

**Recalculate Balances Command:**
- Scheduled (optional): `php artisan inventory:recalculate-balances --quiet` can be run nightly for data integrity verification
- On-demand: `php artisan inventory:recalculate-balances --item=42` for single item recovery
- Sends summary report to sys_activity_logs after completion

## Permissions

| Operation | Permission Key |
|---|---|
| View ledger | `inventory.stock-ledger.viewAny` |
| View balances | `inventory.stock-balances.viewAny` |
| Export ledger | `inventory.stock-ledger.export` |
| Run recalculate (Artisan) | `inventory.stock-ledger.recalculate` |

Note: There are NO create/edit/delete permissions for stock entries — immutability is core to the design (BR-INV-014). Stock entries are created as side effects of GRN acceptance, stock issues, stock adjustments, and godown transfers — not directly via the ledger UI.
