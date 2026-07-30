# Stock Items / Item Catalog — Business Requirements

## What This Screen Does

The Stock Items (Item Catalog) screen defines every procurable and issuable item in the inventory system — consumables (stationery, lab supplies, sports equipment) and assets (computers, furniture, machinery). Each item has rich metadata: categorization via Stock Group, measurement via UOM, valuation method, stock control levels, accounting/tax linkages, and optional batch/expiry tracking.

This is a standalone page at `/inventory/stock-items` (NOT a tab on the Masters page). It is the central hub for item definition and the source of truth for all stock transactions.

## When This Screen Is Used

- **Item Onboarding**: Adding new items to the catalog for procurement, stocking, and issuing
- **Catalog Browsing**: Searching and filtering items by name, group, or type
- **Item Configuration**: Setting valuation methods (FIFO, Weighted Average, Last Purchase Price)
- **Stock Control Setup**: Defining reorder levels, min/max stock, auto-reorder PR generation
- **Accounting Configuration**: Linking items to tax rates (GST), purchase ledgers, and sales ledgers
- **Printing Labels**: Generating printable item labels with barcode-style SKU for physical tagging
- **Vendor Management**: Viewing linked vendors, preferred vendor status, lead times, last purchase rates
- **Stock Balance Viewing**: Checking current stock quantities and values across all godowns

## Key Fields

### Basic Information
- **Name** (required) — Display name, max 150 characters
- **SKU** (optional, unique) — Stock Keeping Unit code, max 50 characters, unique across all items
- **Alias** (optional) — Alternative/short name, max 150 characters
- **Stock Group** (required) — FK to `inv_stock_groups.id`; categorizes the item (e.g., Stationery, Lab Equipment)
- **Unit of Measure** (required) — FK to `inv_units_of_measure.id`; measurement unit (e.g., Pieces, Kg, Litre)

### Configuration
- **Item Type** (required) — Enum: `consumable` (regular stock) or `asset` (triggers fixed asset creation on GRN)
- **Valuation Method** (required) — Enum: `fifo`, `weighted_average`, `last_purchase`
- **Status** — Active/Inactive

### Opening Balance
- **Opening Qty** (optional, min:0) — Initial stock quantity for tenant onboarding
- **Opening Rate** (optional, min:0) — Initial unit cost
- **Opening Value** (auto-calculated) — Qty × Rate, computed both client-side (JS) and server-side

### Stock Control & Reorder
- **Reorder Level** (optional, min:0) — Alert threshold; triggers ReorderAlertJob
- **Reorder Quantity** (optional, min:0) — Quantity to reorder
- **Minimum Stock** (optional, min:0) — Safety stock level
- **Maximum Stock** (optional, min:0) — Upper limit
- **Variance Threshold** (optional, min:0) — Max variance qty before approval required on adjustments; empty/0 = auto-approve
- **Auto-reorder PR** (boolean) — Auto-create draft purchase requisition when reorder level reached

### Inventory Tracking
- **Batch/Lot Tracking** (boolean) — Enable batch number tracking
- **Expiry Tracking** (boolean) — Enable expiry date tracking

### Accounting & Tax
- **Tax Rate (GST)** (optional) — FK to `acc_tax_rates.id`; GST rate for procurement/issue valuation
- **Purchase Ledger** (optional) — FK to `acc_ledgers.id`; Stock-in-hand accounting ledger
- **Sales/Issue Ledger** (optional) — FK to `acc_ledgers.id`; Sales/issue accounting ledger

### Additional Details
- **Brand** (optional, max 100) — Brand name
- **Model** (optional, max 100) — Model number/specification
- **HSN/SAC Code** (optional, max 20) — GST classification code (HSN for goods, SAC for services)
- **Warranty (Months)** (optional, min:0) — Warranty period for asset-type items

## Business Rules

### Foreign Key Dependencies

**Referenced by Stock Items (inbound FKs):**
- `stock_group_id` → `inv_stock_groups.id` (NOT NULL, CASCADE) — Stock Group must exist
- `uom_id` → `inv_units_of_measure.id` (NOT NULL, CASCADE) — UOM must exist
- `tax_rate_id` → `acc_tax_rates.id` (nullable, SET NULL) — Cross-module (Accounting)
- `purchase_ledger_id` → `acc_ledgers.id` (nullable, SET NULL) — Cross-module (Accounting)
- `sales_ledger_id` → `acc_ledgers.id` (nullable, SET NULL) — Cross-module (Accounting)

**Downstream dependencies referencing Stock Items (outbound FKs) — ALL are NOT NULL with CASCADE:**
| Table | FK Column | Business Context |
|-------|-----------|------------------|
| `inv_stock_balances` | `stock_item_id` | Running stock qty per godown |
| `inv_item_vendor_jnt` | `item_id` | Vendor links for procurement |
| `inv_rate_contract_items_jnt` | `item_id` | Rate contract line items |
| `inv_purchase_requisition_items` | `item_id` | PR line items |
| `inv_quotation_items` | `item_id` | Quotation line items |
| `inv_purchase_order_items` | `item_id` | PO line items |
| `inv_issue_request_items` | `item_id` | Issue request line items |
| `inv_stock_adjustment_items` | `item_id` | Adjustment line items |
| `inv_grn_items` | `item_id` | GRN line items |
| `inv_stock_issue_items` | `item_id` | Stock issue execution lines |
| `inv_stock_entries` | `stock_item_id` | Immutable stock movement journal |
| `inv_assets` | `stock_item_id` | Fixed asset register |

### Delete Guard Gap
**Current behavior:** The delete guard only checks `stockBalances()->where('current_qty', '>', 0)->exists()`. If a stock item has zero quantity but is referenced by ANY of the 12 downstream tables above, it will still soft-delete. This creates a potential data integrity issue where soft-deleted items block downstream operations (e.g., viewing a purchase order that references a deleted item). The 12 downstream FKs at the DB level will prevent `forceDelete` but not soft-delete.

### Opening Balance Protection
When stock movements exist (`stockEntries()->exists()`), the opening balance fields (qty, rate, value) are rendered as readonly on the edit page with an info banner: "Stock movements exist — opening balance fields are read-only." This prevents alteration of historical valuation after transactions have occurred.

### Valuation Methods
- **FIFO (First In First Out):** Oldest stock issued first; batch-level tracking for cost
- **Weighted Average:** Average cost calculated across all incoming stock
- **Last Purchase Price:** Items valued at most recent purchase rate

### Auto-Calculated Field
`opening_balance_value = opening_balance_qty × opening_balance_rate` — calculated both client-side (JS on input change) and server-side (on store). The value field in the form is marked `readonly`.

### Item Type — Asset Trigger
When `item_type = 'asset'`, the GRN acceptance process auto-creates a fixed asset record in `inv_assets` for each unit received. This is enforced by downstream domain events (not in this controller).

### Cross-Module Validation
Tax rates (`acc_tax_rates`) and ledgers (`acc_ledgers`) are from the Accounting module. Their `exists` validation rules depend on the Accounting module being installed with seeded data. The DDL FK constraints are commented out pending Accounting module integration.

## Workflow

1. Staff navigates to Inventory → Item Catalog
2. Staff searches/browses existing items (search by name, filter by group or type)
3. Staff clicks "Add Item" to open the create form
4. Staff fills in sections: Basic Information → Configuration → Opening Balance → Stock Control → Tracking → Accounting → Additional
5. Item created with opening balance value auto-calculated
6. Staff views item detail with tabs: Details, Stock Balance (across godowns), Vendors
7. Staff edits item details (opening balance locked after first stock movement)
8. Staff toggles item active status or prints labels
9. Staff deletes items (blocked only if stock on hand exists)
10. Deleted items can be restored or force-deleted from trash
11. Items are referenced across the system: PRs, POs, GRNs, Issues, Adjustments, Transfers, Assets

## Related Screens

- **Stock Groups** — Defines item categories; referenced by `stock_group_id`
- **Units of Measure** — Defines measurement units; referenced by `uom_id`
- **Godowns** — Storage locations; stock balances are per-item-per-godown
- **Stock Balances** — Running quantity/value per item per godown
- **Item Vendor Links** — Vendor assignments, preferred status, lead times
- **Rate Contracts** — Contract rates per item per vendor
- **Purchase Requisitions** — Items requested for procurement
- **Purchase Orders** — Items ordered from vendors
- **Goods Receipt Notes** — Items received; triggers asset creation for asset-type items
- **Stock Issues** — Items issued to departments/employees
- **Stock Entries** — Immutable stock movement journal
- **Stock Adjustments** — Physical count variances
- **Assets** — Fixed asset register for asset-type items
- **Accounting (Tax Rates, Ledgers)** — GST rates and accounting ledgers

## Requirements

- MUST display paginated item catalog (25/page) with search (name), filter (group_id, item_type)
- MUST authorize via `tenant.inventory.stock-item.*` policy gates (5 gates)
- MUST validate store with 24 rules including cross-module exists checks
- MUST create item with opening_balance_value = qty × rate (auto-calculated)
- MUST handle boolean fields via `$request->boolean()`
- MUST set created_by and updated_by to authenticated user
- MUST render opening balance fields readonly on edit when stock movements exist
- MUST guard delete only against stock on hand (current_qty > 0) — GAP noted for 12 downstream FKs
- MUST support AJAX toggle-status returning JSON
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show item detail page with 3 tabs (Details, Stock Balance, Vendors)
- MUST support print labels with dynamic quantity (1-200) and 3 size options (S/M/L)
- MUST support AJAX search endpoint for autocomplete (by name/SKU, paginated 20)
- MUST log all CRUD operations (no dedicated service layer — logging inline in controller)
- MUST paginate trashed items on `/inventory/stock-items/trash/view`
- MUST load active Stock Groups, UOMs, Tax Rates, and Ledgers for form dropdowns using Select2
- MUST enforce unique SKU across all items (ignoring own ID on update)
