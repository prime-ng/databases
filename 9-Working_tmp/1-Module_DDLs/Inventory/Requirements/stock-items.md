# Stock Items — Requirements

## Parent Tab: Masters

## What It Does
Core item catalog for the entire Inventory module. Every procurable, issuable, and sellable item is defined here with its valuation method, stock group classification, primary UOM, reordering parameters, accounting ledger linkage, and GST classification. The item's `item_type` (consumable vs asset) determines behavior on GRN posting — asset items trigger auto-creation of a fixed asset record. Opening balances are captured at item creation time (tenant onboarding only) and cannot be modified after the first stock movement.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(150) | Required. Item display name. |
| `sku` | VARCHAR(50) | Nullable. Unique. Stock Keeping Unit code. |
| `alias` | VARCHAR(150) | Nullable. Alternative name. |
| `stock_group_id` | BIGINT UNSIGNED FK → inv_stock_groups | Required. Item category. |
| `uom_id` | BIGINT UNSIGNED FK → inv_units_of_measure | Required. Primary unit of measure. |
| `item_type` | ENUM('consumable','asset') | Required. Default 'consumable'. Determines GRN behavior. |
| `opening_balance_qty` | DECIMAL(15,3) | Default 0. Tenant onboarding initial quantity. |
| `opening_balance_rate` | DECIMAL(15,2) | Default 0. Per-unit rate at onboarding. |
| `opening_balance_value` | DECIMAL(15,2) | Default 0. Total value at onboarding (qty × rate). |
| `valuation_method` | ENUM('fifo','weighted_average','last_purchase') | Default 'weighted_average'. Per-item stock valuation. |
| `reorder_level` | DECIMAL(15,3) | Nullable. Alert threshold — triggers ReorderAlertJob. |
| `reorder_qty` | DECIMAL(15,3) | Nullable. Quantity to reorder. |
| `min_stock` | DECIMAL(15,3) | Nullable. Minimum stock level. |
| `max_stock` | DECIMAL(15,3) | Nullable. Maximum stock level. |
| `auto_reorder_pr` | TINYINT(1) | Default 0. 1 = auto-create draft PR when reorder level hit. |
| `has_batch_tracking` | TINYINT(1) | Default 0. 1 = batch number tracking enabled. |
| `has_expiry_tracking` | TINYINT(1) | Default 0. 1 = expiry date tracking enabled. |
| `hsn_sac_code` | VARCHAR(20) | Nullable. GST HSN (goods) or SAC (services) code. |
| `brand` | VARCHAR(100) | Nullable. Brand name. |
| `model` | VARCHAR(100) | Nullable. Model number. |
| `warranty_months` | INT | Nullable. Warranty period in months (asset items only). |
| `tax_rate_id` | BIGINT UNSIGNED FK → acc_tax_rates | Nullable. Default GST rate for this item. |
| `purchase_ledger_id` | BIGINT UNSIGNED FK → acc_ledgers | Nullable. Stock-in-hand ledger for purchases. |
| `sales_ledger_id` | BIGINT UNSIGNED FK → acc_ledgers | Nullable. Sales/issue ledger. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | Required. FK to `sys_users.id`. |
| `created_at` | TIMESTAMP | Nullable. Laravel standard. |
| `updated_at` | TIMESTAMP | Nullable. Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:150 | "The name field is required." / "Item name must not exceed 150 characters." |
| `sku` | Nullable, string, max:50, unique across all stock items (including soft-deleted) | "The SKU has already been taken." — checked at application level since DB UNIQUE is nullable and MySQL allows multiple NULLs |
| `alias` | Nullable, string, max:150 | "Alias must not exceed 150 characters." |
| `stock_group_id` | Required, integer, exists:inv_stock_groups,id | "The stock group field is required." / "The selected stock group is invalid." |
| `uom_id` | Required, integer, exists:inv_units_of_measure,id | "The unit of measure field is required." / "The selected UOM is invalid." |
| `item_type` | Required, enum: consumable/asset | "The item type must be either consumable or asset." Once any stock movement exists, item_type cannot be changed. |
| `opening_balance_qty` | Required, numeric, min:0, max:999999999.999 | "Opening quantity must be a non-negative number." Default 0. Cannot be modified after first stock entry. |
| `opening_balance_rate` | Required, numeric, min:0, max:999999999999.99 | "Opening rate must be a non-negative number." Default 0. Cannot be modified after first stock entry. |
| `opening_balance_value` | Read-only (computed as qty × rate) | Automatically calculated on create: `opening_balance_qty × opening_balance_rate`. Stored for audit/historical reference. |
| `valuation_method` | Required, enum: fifo/weighted_average/last_purchase | "The selected valuation method is invalid." Default 'weighted_average'. Cannot be changed after any stock movement exists if stock balance > 0. |
| `reorder_level` | Nullable, numeric, min:0 | If provided, must be >= 0. If `auto_reorder_pr` is 1, reorder_level and reorder_qty are required. |
| `reorder_qty` | Nullable, numeric, min:0 | If `auto_reorder_pr` is 1, required. If provided without reorder_level, ignored. |
| `min_stock` | Nullable, numeric, min:0 | "Minimum stock must be a non-negative number." Should be less than max_stock if both provided. |
| `max_stock` | Nullable, numeric, min:0 | "Maximum stock must be a non-negative number." Should be greater than min_stock if both provided. |
| `auto_reorder_pr` | Required, boolean, default 0 | Must be 0 or 1. If 1, reorder_level and reorder_qty become required. |
| `has_batch_tracking` | Required, boolean, default 0 | Must be 0 or 1. Cannot be disabled (set from 1 to 0) after any stock movement exists for this item. |
| `has_expiry_tracking` | Required, boolean, default 0 | Must be 0 or 1. Requires `has_batch_tracking = 1` (expiry tracking requires batch tracking). Cannot be disabled after stock movement exists. |
| `hsn_sac_code` | Nullable, string, max:20, regex:/^\d{4,8}$/ for HSN or /^\d{4,15}$/ for SAC | "HSN code must be 4 to 8 digits." / "SAC code must be 4 to 15 digits." Validated based on item type context. |
| `brand` | Nullable, string, max:100 | "Brand must not exceed 100 characters." |
| `model` | Nullable, string, max:100 | "Model must not exceed 100 characters." |
| `warranty_months` | Nullable, integer, min:0, max:600 | Required if `item_type = 'asset'`. Nullable for consumables. "Warranty months must be between 0 and 600." |
| `tax_rate_id` | Nullable, integer, exists:acc_tax_rates,id | "The selected tax rate is invalid." Must reference an existing tax rate record. |
| `purchase_ledger_id` | Nullable, integer, exists:acc_ledgers,id | "The selected purchase ledger is invalid." Must reference an existing ledger. |
| `sales_ledger_id` | Nullable, integer, exists:acc_ledgers,id | "The selected sales ledger is invalid." Must reference an existing ledger. |

### SKU Uniqueness Rules

- `sku` is optional (nullable). Multiple items can have NULL SKU.
- If SKU is provided, it must be unique across ALL stock items (including soft-deleted).
- Uniqueness is enforced via DB UNIQUE KEY `uq_inv_si_sku` on `sku` column.
- Since MySQL UNIQUE allows multiple NULL values, multiple items with NULL SKU are permitted.
- SKU, when provided, should follow a consistent naming convention (e.g., 'RAW-COT-001', 'FG-SHIRT-001').
- SKU cannot be changed to a value that conflicts with an existing SKU (including soft-deleted records): "The SKU has already been taken."
- SKU can be changed from a value to NULL without restriction.
- Auto-generation option: the system may provide an "Auto-generate SKU" button that creates a SKU based on stock group code + sequential number.

### Item Type Rules

**On Create:**
- `item_type` is selectable as 'consumable' (default) or 'asset'.
- If 'asset' is selected, `warranty_months` becomes required (min 0, max 600).
- If 'asset' is selected, the system must also validate that the stock group belongs to the Fixed Assets group path or allow any group.

**On Change (Protection):**
- Once any stock movement exists for this item (any record in inv_stock_balances, inv_purchase_order_items, inv_issue_request_items, inv_stock_adjustment_items, or related GRN tables), `item_type` cannot be changed.
- Check: `SELECT COUNT(*) FROM inv_stock_balances WHERE stock_item_id = {id}` — if any record exists (even with zero balance), reject: "Cannot change item type after stock movements exist for this item."
- If no stock movements exist, item_type can be freely changed.

**On GRN (Goods Receipt Note) Posting:**
- If `item_type = 'consumable'`: GRN directly updates stock balance in inv_stock_balances. No fixed asset created.
- If `item_type = 'asset'`: GRN posting triggers:
  1. Stock balance is updated (quantity and value).
  2. A new record is auto-created in `acc_fixed_assets` with:
     - name = stock_item.name + " - " + GRN date + " - " + serial/batch (if tracked)
     - asset_category_id = determined from stock group mapping
     - purchase_cost = GRN line total
     - depreciation_rate = from asset category
     - useful_life_years = from asset category
     - warranty_months = from stock_item.warranty_months
     - purchase_date = GRN date
     - status = 'active'

### Valuation Method Rules

- Each stock item can have its own valuation method: `fifo`, `weighted_average`, or `last_purchase`.
- Default: `weighted_average`.
- `weighted_average`: On GRN, new rate = (current_value + new_value) / (current_qty + new_qty). On issue, rate = current weighted average rate.
- `fifo`: On issue, the oldest purchase rate is used first. Requires tracking purchase lots (inv_stock_ledger).
- `last_purchase`: On issue, the most recent GRN rate is used.
- **Change protection:** If any stock movement exists AND current balance > 0, valuation_method cannot be changed. If balance is 0 (but history exists), it can be changed with a warning: "Warning: Changing valuation method may affect historical cost calculations."
- The valuation method is copied to the stock issue line at issue time (denormalized for audit).

### Opening Balance Rules

- Opening balance fields (`opening_balance_qty`, `opening_balance_rate`, `opening_balance_value`) are for tenant onboarding only.
- **On Create:** The user enters `opening_balance_qty` and `opening_balance_rate`. `opening_balance_value` is auto-computed as `qty × rate`.
- **Locked after first stock entry:** Once any stock movement exists (GRN, issue, adjustment, transfer), these fields become read-only and hidden from the edit form.
- Check: `SELECT COUNT(*) FROM inv_stock_balances WHERE stock_item_id = {id}` — if > 0, fields are locked.
- **On onboarding flow:** The opening balance creates the initial record in `inv_stock_balances` for the default godown (or the godown selected during onboarding). A corresponding opening entry is made in `inv_stock_ledger` with transaction_type = 'opening'.
- If opening balance is 0 for both qty and rate, no initial stock_balance record is created (the first GRN will create it).

### Reorder & Auto-Reorder Rules

**Reorder Level Check:**
- A scheduled job (`ReorderAlertJob`) runs daily (configurable interval).
- Query: `SELECT si.* FROM inv_stock_items si WHERE si.reorder_level IS NOT NULL AND si.deleted_at IS NULL AND EXISTS (SELECT 1 FROM inv_stock_balances sb WHERE sb.stock_item_id = si.id AND sb.current_qty <= si.reorder_level AND sb.deleted_at IS NULL)`.
- For each item below reorder level, an alert/notification is created.

**If `auto_reorder_pr = 1`:**
- The `ReorderAlertJob` additionally auto-creates a draft Purchase Requisition (inv_purchase_requisitions) when the reorder level is breached.
- PR quantity = `reorder_qty` (or `max_stock - current_qty` if reorder_qty is not set).
- The PR is created in 'draft' status for manual review and approval.
- PR department = default inventory department (configurable).
- PR required_date = today + supplier lead time (from item's preferred vendor).
- Multiple auto-PRs for the same item are NOT created if there is already a draft/submitted PR for that item.

**Constraints:**
- If `auto_reorder_pr = 1`, both `reorder_level` and `reorder_qty` must be provided. Validation: "Reorder level and reorder quantity are required when auto-reorder is enabled."
- If `reorder_level` is set, `reorder_qty` is recommended but not strictly required (defaults to `max_stock - min_stock` if max_stock is set).

### Batch & Expiry Tracking Rules

**Batch Tracking (`has_batch_tracking = 1`):**
- When enabled, all GRN postings for this item must include a batch number.
- The batch number is stored in `inv_stock_ledger` entries and `inv_stock_balances` must support batch-level breakdown.
- Batch format: free text, max 50 chars, user-entered or auto-generated.
- Cannot disable batch tracking after any stock movement exists.

**Expiry Tracking (`has_expiry_tracking = 1`):**
- Requires `has_batch_tracking = 1`. Validation: "Expiry tracking requires batch tracking to be enabled."
- When enabled, each batch must have an expiry date.
- A scheduled job (`ExpiryAlertJob`) alerts for items expiring within 30 days (configurable).
- Stock issue: FIFO by expiry date for batch-tracked items (earliest expiry issued first).
- Cannot disable expiry tracking after any stock movement exists.

**State Transitions:**
- From `has_batch_tracking = 0` to `1`: Allowed anytime (future transactions will track batches, past transactions remain as-is).
- From `has_batch_tracking = 1` to `0`: Blocked if any stock movement exists: "Cannot disable batch tracking after stock movements exist."
- From `has_expiry_tracking = 0` to `1`: Allowed if `has_batch_tracking` is already 1.
- From `has_expiry_tracking = 1` to `0`: Blocked if any stock movement exists.

### HSN/SAC Code Validation

- HSN code (for goods): Must be 4, 6, or 8 digits. Validated via regex `/^\d{4,8}$/`.
- SAC code (for services): Must be 4 to 15 digits.
- The system infers HSN vs SAC based on the stock group mapping (whether the group is tagged as goods vs services).
- If provided, the HSN/SAC code should exist in the master HSN/SAC database (if integrated with GST portal).
- Warning (non-blocking) if code is not found in the master: "The entered HSN/SAC code was not found in the GST master database. Please verify before proceeding."

### Warranty Months

- `warranty_months` is only relevant for `item_type = 'asset'`.
- For consumable items, `warranty_months` must be NULL.
- For asset items, `warranty_months` is required (can be 0 for assets with no warranty).
- The warranty period is copied to the fixed asset record at GRN time.
- A scheduled job checks warranty expiry and sends alerts 30 days before expiry.

### Soft Delete & Restore

**Soft Delete (`DELETE /inventory/stock-items/{id}` triggered via controller destroy()):**
1. Pre-delete check 1: `SELECT SUM(current_qty) FROM inv_stock_balances WHERE stock_item_id = {id} AND deleted_at IS NULL` — must be 0 (or null). If > 0, return error: "Cannot delete item with existing stock balance. Adjust stock to zero first."
2. Pre-delete check 2: `SELECT COUNT(*) FROM inv_purchase_order_items WHERE item_id = {id} AND po_id IN (SELECT id FROM inv_purchase_orders WHERE status IN ('draft','sent','partial')) AND deleted_at IS NULL` — if > 0, return error: "Cannot delete item with pending purchase orders."
3. Pre-delete check 3: `SELECT COUNT(*) FROM inv_issue_request_items WHERE item_id = {id} AND issue_request_id IN (SELECT id FROM inv_issue_requests WHERE status IN ('submitted','approved','partial')) AND deleted_at IS NULL` — if > 0, return error: "Cannot delete item with pending issue requests."
4. Pre-delete action: automatically sets `is_active = 0` (deactivated).
5. The stock item record gets `deleted_at` timestamp set.
6. The record remains in the database (soft-deleted).
7. Related `inv_stock_balances` records are NOT soft-deleted (they remain for historical reporting).
8. An audit log entry is created: action = "delete", entity_type = "inv_stock_items", entity_id = {id}.
9. An activity log entry is created: message = "A stock item was deactivated and soft-deleted."
10. After successful deletion, redirect to route('inventory.stock-items.index') with flash message flash('trashed.stock_item').

**Restore (`GET /inventory/stock-items/{id}/restore`):**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1 (remains 0 after restore).
4. An audit log entry is created: action = "restore", entity_type = "inv_stock_items", entity_id = {id}.
5. After successful restore, redirect to route('inventory.stock-items.trashed') with flash message flash('restored.stock_item').

**Force Delete (`DELETE /inventory/stock-items/{id}/force-delete`):**
1. Only available on already soft-deleted records (uses withTrashed() query scope).
2. Pre-delete check 1: `SELECT SUM(current_qty) FROM inv_stock_balances WHERE stock_item_id = {id}` — must be 0 (including soft-deleted balances).
3. Pre-delete check 2: `SELECT COUNT(*) FROM inv_purchase_order_items WHERE item_id = {id}` — must be 0 (including soft-deleted POs).
4. Pre-delete check 3: `SELECT COUNT(*) FROM inv_issue_request_items WHERE item_id = {id}` — must be 0.
5. If any check fails, return error: "Cannot permanently delete item with existing transaction history."
6. The record is permanently removed from the database.
7. Related stock_balances records are cascade-deleted.
8. An audit log entry is created: action = "force_delete", entity_type = "inv_stock_items", entity_id = {id}.
9. After successful force delete, redirect to route('inventory.stock-items.trashed') with flash message flash('force_deleted.stock_item').

**Trash Page (`GET /inventory/stock-items/trash/view`):**
- Lists only soft-deleted records (uses onlyTrashed() scope).
- Paginated 15 per page.
- Shows columns: Name, SKU, Stock Group, Item Type, Deleted At, Actions (Restore, Force Delete).
- Restore and Force Delete actions are permission-gated.

### Status Toggle

- Route: `POST /inventory/stock-items/{stockItem}/toggle-status`.
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle check if toggling from 1 to 0 (deactivating): same pre-checks as soft delete (stock balance check). If stock balance > 0, return JSON error: `{"success": false, "message": "Cannot deactivate item with existing stock balance."}`.
- Pre-toggle check if toggling from 0 to 1 (activating): no additional checks.
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`.
- An audit log entry is created on toggle.

### Audit Trail

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `inv_audit_log`.
- StockItemAuditService::log() is called with: entity_type = "inv_stock_items", entity_id = {id}, action = {action_type}.
- The global activityLog() helper is also called for each mutation.
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- Special audit events:
  - Opening balance created/attempted modification: "Opening balance fields are read-only after first stock movement. Edit attempt blocked."
  - Item type change attempt after stock movement: "Item type change blocked — stock movements exist."
  - Valuation method change: "Valuation method changed from {old} to {new}."

### List View

- Controller: StockItemController@index. Gate: 'tenant.inventory.stock-items.viewAny'.
- Pagination: 20 records per page via `->paginate(20)`.
- Default sort: by `name` ascending.
- Eager loads: stockGroup (name, parent hierarchy for display), uom (name, symbol, decimal_places).
- Columns displayed:
  1. Name (with alias in smaller text below if present).
  2. SKU (badge-styled if present, grey "—" if null).
  3. Stock Group (full hierarchy path, e.g., "Raw Materials → Chemicals").
  4. UOM (symbol with decimal places hint, e.g., "Kg (2 dp)").
  5. Item Type (color badge: blue="Consumable", orange="Asset").
  6. Reorder Level (formatted quantity + UOM symbol, or "—" if not set).
  7. Current Qty (from inv_stock_balances sum, formatted per UOM decimal_places).
  8. Status (active/inactive badge).
  9. Actions (View, Edit, Barcode, Delete buttons).
- Filters:
  - Search by name, SKU, or alias (text input, searches with LIKE %keyword%).
  - Stock group dropdown (tree-structured options, auto-submits on change).
  - Item type dropdown (consumable/asset/all).
  - Status dropdown (active/inactive/all).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated.

### Barcode / QR Label Printing

- A "Print Barcode" action button is available on each stock item row (and bulk selection).
- Route: `GET /inventory/stock-items/{id}/print-barcode` or `POST /inventory/stock-items/print-barcode-bulk`.
- Generates a barcode/QR label PDF containing:
  - Item name.
  - SKU.
  - Barcode (Code 128 or QR code encoding the SKU or item ID).
  - Price (if configured).
- Label format: configurable (e.g., 2" × 1" sticky labels, 8 per sheet).
- The barcode/QR is scannable at POS, GRN receipt, and stock counting.

### Opening Balance Entry on Create

- When creating a stock item, the create form includes:
  - `opening_balance_qty` field (default 0).
  - `opening_balance_rate` field (default 0, per-unit cost).
  - `opening_balance_godown_id` dropdown (default godown selection).
- On submit:
  1. Stock item record is created.
  2. If opening_balance_qty > 0:
     - A record is created in `inv_stock_balances` with current_qty = opening_balance_qty, current_value = opening_balance_value (= qty × rate).
     - A record is created in `inv_stock_ledger` with transaction_type = 'opening', qty = opening_balance_qty, rate = opening_balance_rate, value = opening_balance_value.
  3. If opening_balance_qty = 0, no stock_balance or stock_ledger records are created.
- After creation, the opening balance fields are locked and hidden on the edit form (see Opening Balance Rules above).

### Integration Rules

- **Referenced by:** `inv_stock_balances.stock_item_id` (FK), `inv_purchase_order_items.item_id` (FK), `inv_purchase_requisition_items.item_id` (FK), `inv_issue_request_items.item_id` (FK), `inv_quotation_items.item_id` (FK), `inv_stock_adjustment_items.item_id` (FK), `inv_rate_contract_items_jnt.item_id` (FK), `inv_item_vendor_jnt.item_id` (FK).
- Stock item data is consumed by:
  - **GRN Posting Service:** Reads item_type, uom_id, valuation_method, has_batch_tracking, has_expiry_tracking, purchase_ledger_id, tax_rate_id.
  - **Stock Issue Service:** Reads valuation_method for costing, uom_id for quantity display.
  - **Reordering (Scheduler):** Reads reorder_level, reorder_qty, auto_reorder_pr.
  - **Fixed Asset (Accounting):** Reads warranty_months for asset items at GRN time.
  - **GST Reporting:** Reads hsn_sac_code, tax_rate_id.
- The stock item is the central reference for all inventory transactions. Any change to core fields (uom_id, valuation_method, item_type) must be carefully guarded.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.inventory.stock-items.viewAny` |
| View details | `tenant.inventory.stock-items.view` |
| Create | `tenant.inventory.stock-items.create` |
| Edit/update | `tenant.inventory.stock-items.update` |
| Soft delete | `tenant.inventory.stock-items.delete` |
| View trash & restore | `tenant.inventory.stock-items.restore` |
| Force delete | `tenant.inventory.stock-items.forceDelete` |
| Toggle status | `tenant.inventory.stock-items.toggleStatus` |
| Print barcode | `tenant.inventory.stock-items.printBarcode` |
