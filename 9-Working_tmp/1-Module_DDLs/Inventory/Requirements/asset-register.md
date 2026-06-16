# Asset Register — Requirements

## What It Does
Manages the fixed asset register. One record per physical asset unit. Auto-created when a GRN is accepted for stock items with item_type = 'asset'. Tracks asset condition lifecycle (good → fair → poor → under_repair → disposed), employee assignments, godown location changes via movement history, warranty expiry, and book value synced from the Accounting module's depreciation computation.

## Database Fields

### inv_assets

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `asset_tag` | VARCHAR(50) | Required. Unique. Auto-generated: ASSET-{YEAR}-{SEQUENCE}. |
| `asset_category_id` | BIGINT UNSIGNED FK → inv_asset_categories | Required. Asset category with depreciation rates. |
| `stock_item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Parent stock item definition. |
| `grn_item_id` | BIGINT UNSIGNED FK → inv_grn_items | Nullable. Source GRN item that created this asset. |
| `purchase_date` | DATE | Nullable. Purchase date from GRN. |
| `purchase_cost` | DECIMAL(15,2) | Nullable. Purchase cost per unit from GRN. |
| `current_book_value` | DECIMAL(15,2) | Nullable. Current depreciated value. Synced from acc_fixed_assets. |
| `acc_fixed_asset_id` | BIGINT UNSIGNED FK → acc_fixed_assets | Nullable. Accounting's fixed asset record ID. Synced after Accounting creates it. |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Nullable. Current storage location. |
| `assigned_employee_id` | INT UNSIGNED FK → sch_employees | Nullable. Currently assigned employee. |
| `condition` | ENUM('good','fair','poor','under_repair','disposed') | Required. Default 'good'. Current physical condition. |
| `warranty_expiry_date` | DATE | Nullable. Warranty expiry = purchase_date + stock_item.warranty_months. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_asset_movements

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `asset_id` | BIGINT UNSIGNED FK → inv_assets | Required. Asset being transferred. |
| `movement_date` | DATE | Required. Date of transfer. |
| `from_godown_id` | BIGINT UNSIGNED FK → inv_godowns | Nullable. Previous storage location. NULL if no previous location. |
| `to_godown_id` | BIGINT UNSIGNED FK → inv_godowns | Nullable. New storage location. NULL if transfer to employee without location change. |
| `from_employee_id` | INT UNSIGNED FK → sch_employees | Nullable. Previous assignee. NULL if unassigned previously. |
| `to_employee_id` | INT UNSIGNED FK → sch_employees | Nullable. New assignee. NULL if becoming unassigned. |
| `reason` | VARCHAR(500) | Nullable. Transfer reason. |
| `moved_by` | BIGINT UNSIGNED FK → sys_users | Required. User who executed the transfer. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `asset_tag` | Required, string, max:50, unique | Auto-generated as ASSET-{YEAR}-{SEQUENCE}. Never user-supplied. |
| `asset_category_id` | Required, integer, exists:inv_asset_categories,id | Must reference an active asset category. Error: "The selected asset category is invalid." |
| `stock_item_id` | Required, integer, exists:inv_stock_items,id | Must reference a stock item with item_type = 'asset'. Error: "Cannot create asset from a consumable item." |
| `grn_item_id` | Nullable, integer, exists:inv_grn_items,id | Set automatically on asset creation from GRN. Not user-editable after creation. |
| `purchase_date` | Nullable, date, before_or_equal:today | Cannot be future date. Auto-populated from GRN receipt_date. |
| `purchase_cost` | Nullable, numeric, min:0 | Auto-populated from GRN unit_cost. |
| `current_book_value` | Nullable, numeric, min:0 | Read-only. Synced from acc_fixed_assets by Accounting module. Never user-editable. |
| `acc_fixed_asset_id` | Nullable, integer | Read-only after first sync. Set by Accounting event listener. Never user-supplied. |
| `godown_id` | Nullable, integer, exists:inv_godowns,id | Updated on transfer. Can be NULL if asset is assigned to employee without location. |
| `assigned_employee_id` | Nullable, integer, exists:sch_employees,id | Must reference active employee. Updated on transfer. |
| `condition` | Required, enum: good/fair/poor/under_repair/disposed | Transitioned by dedicated endpoints. Not directly editable. |
| `warranty_expiry_date` | Nullable, date | Computed as purchase_date + stock_item.warranty_months. Auto-populated. Read-only. |
| `movement_date` (movement) | Required, date, before_or_equal:today | Cannot be future. |
| `from_godown_id` / `to_godown_id` (movement) | Nullable, both cannot be NULL simultaneously | At least one of godown or employee must change. |
| `moved_by` (movement) | Required, integer, exists:sys_users,id | Must be authenticated user executing transfer. |

### Entity-Specific Rules / Lifecycle State Machine

**Asset Creation (triggered by GRN acceptance for item_type='asset'):**
- GrnPostingService::createAssetRecords() creates one inv_assets record per integer unit of accepted_qty
- For accepted_qty = 3: creates 3 separate asset records with sequential asset_tags
- Fields auto-populated:
  - asset_tag: ASSET-{YEAR}-{SEQUENCE} (auto-incrementing per asset)
  - asset_category_id: from stock_item's stock_group mapping (lookup table or configurable)
  - purchase_date: from GRN receipt_date
  - purchase_cost: from GRN line unit_cost
  - warranty_expiry_date: purchase_date + stock_item.warranty_months (NULL if warranty_months is NULL)
  - condition: 'good'
  - godown_id: from GRN godown
  - grn_item_id: from inv_grn_items.id
- If accepted_qty has decimal: floor(accepted_qty) integer records created; fractional part remains as consumable stock
- AssetDisposed event fires after Accounting creates corresponding acc_fixed_assets record

**Condition State Machine:**

```
                    ┌─────────────────────────────────────┐
                    │                                     │
[good] ──→ [fair] ──→ [poor] ──→ [under_repair] ──→ [disposed]
  ↑           ↑         ↑              │
  │           │         └──────────────┘
  │           └────────────┘
  └──────────────────┘
  (condition can be updated to any earlier state via conditionUpdate())
```

Transitions:
| From | To | Pre-conditions | Side Effects |
|---|---|---|---|
| Any | good | Asset must not be disposed | Asset returned to serviceable state |
| Any | fair | Asset must not be disposed | — |
| Any | poor | Asset must not be disposed | May trigger maintenance recommendation |
| Any | under_repair | Asset must not be disposed | Maintenance record typically created; asset unavailable for use |
| under_repair | good/fair/poor | Repair completed | Maintenance record updated to completed |
| Any | disposed | Cannot have pending maintenance records | AssetDisposed event fired; acc_fixed_assets write-off; condition set to 'disposed' |

**Disposal Rules:**
- Route: `POST /inventory/assets/{id}/dispose`
- Pre-disposal checks:
  1. No pending maintenance with status = 'scheduled' or 'overdue' — error: "Cannot dispose asset with pending maintenance. Complete or cancel all maintenance records first."
  2. acc_fixed_asset_id must not be NULL (Accounting must have created the fixed asset record) — error: "Asset not yet synced with Accounting. Cannot dispose."
- Side effects:
  1. inv_assets.condition = 'disposed'
  2. AssetDisposed event fired → Accounting writes off residual value in acc_fixed_assets
  3. Asset tagged as disposed — cannot be transferred, maintained, or condition-changed after disposal

**Transfers (Location/Assignment Change):**
- Route: `POST /inventory/assets/{id}/transfer`
- Pre-conditions: asset condition != 'disposed'
- Side effects:
  1. inv_asset_movements record created with from/to godown and employee IDs
  2. inv_assets.godown_id updated to to_godown_id (or NULL)
  3. inv_assets.assigned_employee_id updated to to_employee_id (or NULL)
  4. At least one of godown or employee must change (both can change simultaneously)
- Movement history is immutable once created

**Asset Tag Auto-generation:**
- Format: ASSET-{YEAR}-{SEQUENCE}
- Example: ASSET-2026-156
- Sequence resets annually
- Generated by AssetService on creation

**Warranty Expiry Date Computation:**
- warranty_expiry_date = purchase_date + INTERVAL stock_item.warranty_months MONTH
- If stock_item.warranty_months is NULL: warranty_expiry_date remains NULL
- Not user-editable — read-only display field
- Expiry alerts: scheduled command checks assets with warranty_expiry_date < NOW() + 30 days

**current_book_value Sync:**
- NOT computed by Inventory module — owned by Accounting module (BR-INV-018)
- Accounting computes depreciation annually per Income Tax Act WDV rates (stored in inv_asset_categories)
- Inventory syncs value via event listener when Accounting updates acc_fixed_assets
- current_book_value can be NULL before first sync; after sync, always matches acc_fixed_assets.book_value
- Manual override not permitted — displayed as read-only with tooltip: "Book value managed by Accounting module"

### Data Integrity Rules

- Asset tag is globally unique across all assets (not just per year)
- ON DELETE SET NULL for grn_item_id — if GRN item is deleted, asset remains with link severed
- ON DELETE SET NULL for godown_id, assigned_employee_id — foreign key integrity without cascade
- acc_fixed_asset_id ON DELETE SET NULL — if Accounting deletes fixed asset record, inventory asset remains
- One inv_assets record per physical unit — no quantity field on assets (unlike stock items)
- Movement records are immutable once created — no UPDATE/DELETE on inv_asset_movements
- Asset cannot be created manually (UI create form disabled) — only via GRN acceptance or bulk import (admin-only Artisan command)
- An asset's stock_item_id cannot be changed after creation
- purchase_cost and purchase_date cannot be changed after creation (set from GRN at creation time)
- Duplicate asset_tag prevented at DB level via UNIQUE constraint
- condition field changes are logged individually — each transition is an auditable event

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: condition must not be 'disposed'. Error: "Cannot delete disposed asset. Use force delete if needed."
2. Pre-delete check: asset must not have pending maintenance records (status = 'scheduled'). Error: "Cannot delete asset with pending maintenance."
3. Soft delete sets deleted_at. Asset remains visible in trash view.
4. inv_asset_movements are NOT soft-deleted with asset (they remain for historical reference)
5. Audit log: action = "delete", entity_type = "inv_assets", entity_id = {id}, asset_tag = {tag}

**Restore:**
1. Only on soft-deleted records
2. Sets deleted_at = NULL
3. Does NOT restore is_active (remains 0)
4. Audit log: action = "restore"

**Force Delete:**
1. Only on already soft-deleted records
2. Only if no linked acc_fixed_asset_id (Accounting record must be handled separately)
3. Permanently removes asset record; movement records remain (orphaned with NULL asset_id — ON DELETE SET NULL not possible since FK has no SET NULL on movement table)

### Audit Trail Rules

- Every create (via GRN acceptance), condition change, transfer, disposal, soft delete, restore logged to hst_audit_log
- AuditService::log() called with: entity_type = "inv_assets", entity_id = {id}, action = {action_type}
- Condition changes: log old_condition and new_condition values
- Transfers: log from/to godown and employee IDs, reason, moved_by
- Disposal: log asset_tag, purchase_cost, current_book_value, acc_fixed_asset_id
- current_book_value sync events logged as informational audit entries (action = "book_value_synced")
- Movement records are self-auditing — each movement record inherently records who moved it and when

### List View Rules

- Controller: index() method, Gate: 'inventory.asset.viewAny'
- Pagination: 15 records per page
- Eager loads: assetCategory (name), stockItem (name, sku), godown (name), assignedEmployee (name)
- Default sort: by created_at descending
- Columns displayed: Asset Tag, Item Name, Category, Condition (badge — color-coded), Assigned To, Godown, Purchase Date, Purchase Cost, Current Book Value, Warranty Expiry, Actions
- Filter: asset_tag search (text input)
- Filter: asset_category_id dropdown
- Filter: condition dropdown (all/good/fair/poor/under_repair/disposed)
- Filter: assigned_employee_id searchable select2
- Filter: godown_id dropdown
- Filter: warranty status (within 30 days/expired/all) via dropdown
- All filters preserved across pagination
- Actions column: View, Transfer, Update Condition, Dispose, Print Tag — permission-gated
- Print Tag button: renders barcode/QR label for physical asset tagging

### Integration Rules

**Accounting Integration (via AssetDisposed Event):**
- Event: AssetDisposed fired when asset condition set to 'disposed'
- Payload: `{asset_id, asset_tag, acc_fixed_asset_id, disposal_date, book_value, purchase_cost}`
- Consumer: Accounting writes off residual value in acc_fixed_assets
- AssetDisposed may also trigger StockAdjusted event if asset was in stock_balances (asset items should not normally be in stock_balances after GRN acceptance)

**Accounting Integration (Book Value Sync):**
- Listens to: FixedAssetDepreciationComputed or FixedAssetValueUpdated event from Accounting
- Updates: inv_assets.current_book_value to match acc_fixed_assets.book_value
- Updates: inv_assets.acc_fixed_asset_id on first sync (set from NULL to Accounting record ID)

**GRN Integration (Auto-creation):**
- Triggered by: GrnPostingService when item_type = 'asset' and GRN is accepted
- Creates: inv_assets records (one per unit of accepted_qty)
- Flows: GRN items (batch, expiry, cost, purchase date) → Asset fields

**Print Tag Integration:**
- Route: `GET /inventory/assets/{id}/print-tag`
- Renders print-friendly barcode/QR label with: asset_tag, item name, category, purchase date, godown
- Barcode: Code128 encoding of asset_tag
- QR: URL to asset detail page (for mobile scanning)
- Batch print: `POST /inventory/assets/print-tags-batch` — accepts array of asset IDs, max 200 per request

**Maintenance Integration:**
- Assets with pending scheduled maintenance cannot be disposed
- Asset maintenance records reference asset_id (inv_asset_maintenance)

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.asset.viewAny` |
| View details | `inventory.asset.view` |
| Update condition | `inventory.asset.update` |
| Transfer | `inventory.asset.transfer` |
| Dispose | `inventory.asset.dispose` |
| Print tag | `inventory.asset.print` |
| Soft delete | `inventory.asset.delete` |
| View trash & restore | `inventory.asset.restore` |
| Force delete | `inventory.asset.forceDelete` |

Note: Create is NOT listed as a permission because assets are auto-created via GRN acceptance (BR-INV-012), not via manual UI. Bulk import (admin Artisan command) is available for initial tenant onboarding.
