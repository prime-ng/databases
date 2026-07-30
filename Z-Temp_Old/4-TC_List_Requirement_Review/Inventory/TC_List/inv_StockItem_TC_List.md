# inv_StockItem — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Stock Items / Item Catalog (CRUD + Soft-Delete + Toggle + Print Labels + Search)
**DB scope:** TENANT-side (`inv_stock_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_stock_items` (Layer 3) · **Module URL prefix:** `/inventory/stock-items`
**Test file:** `inv_StockItem_TestCas.php`

Controller:
- `StockItemController` — CRUD + trash + toggle + printLabels + search AJAX
- No dedicated Service Layer — all business logic inline in controller

Routes (`inventory.` prefix):
- `GET /inventory/stock-items` — index (paginated 25, search + group + type filters)
- `GET /inventory/stock-items/create` — create (loads groups, uoms, taxRates, ledgers)
- `POST /inventory/stock-items` — store
- `GET /inventory/stock-items/{stockItem}` — show (details, stock balances, vendors tabs)
- `GET /inventory/stock-items/{stockItem}/edit` — edit
- `PUT /inventory/stock-items/{stockItem}` — update
- `DELETE /inventory/stock-items/{stockItem}` — soft delete (guarded if stock on hand)
- `POST /inventory/stock-items/{stockItem}/toggle-status` — AJAX toggle
- `POST /inventory/stock-items/{stockItem}/print-labels` — print labels view
- `GET /inventory/stock-items/search` — AJAX search (by name/SKU, paginated 20)
- `GET /inventory/stock-items/trash/view` — trashed
- `GET /inventory/stock-items/{id}/restore` — restore
- `DELETE /inventory/stock-items/{id}/force-delete` — force delete

**DDL reference:** `inv_stock_items` (Layer 3), FKs to `inv_stock_groups` (L2), `inv_units_of_measure` (L1), `acc_tax_rates`, `acc_ledgers` (cross-module)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_stock_items`: id (BIGINT PK AI), name (VARCHAR 150 NOT NULL), sku (VARCHAR 50 NULL UNIQUE), alias (VARCHAR 150 NULL), stock_group_id (BIGINT UNSIGNED NOT NULL FK), uom_id (BIGINT UNSIGNED NOT NULL FK), item_type (ENUM consumable/asset), opening_balance_qty/rate/value (DECIMAL), valuation_method (ENUM fifo/weighted_average/last_purchase), reorder_level/qty/min_stock/max_stock (DECIMAL 15,3), variance_threshold (DECIMAL 15,3), auto_reorder_pr/has_batch_tracking/has_expiry_tracking (TINYINT boolean), hsn_sac_code (VARCHAR 20), brand/model (VARCHAR 100), warranty_months (INT), tax_rate_id (BIGINT UNSIGNED NULL FK → acc_tax_rates), purchase_ledger_id (BIGINT UNSIGNED NULL FK → acc_ledgers), sales_ledger_id (BIGINT UNSIGNED NULL FK → acc_ledgers), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_si_sku, idx_inv_sitm_stock_group_id/uom_id/item_type/tax_rate_id/purchase_ledger_id/sales_ledger_id/is_active | DDL |
| BC-DB-02 | FK `fk_inv_sitm_stock_group_id`: stock_group_id → inv_stock_groups.id (NOT NULL, CASCADE). FK `fk_inv_sitm_uom_id`: uom_id → inv_units_of_measure.id (NOT NULL, CASCADE). Both enforced at DB level | DDL |
| BC-DB-03 | FK references to acc_tax_rates and acc_ledgers — defined in DDL but COMMENTED OUT (not yet enabled at DB level). Validation enforced via `exists` rules in StoreStockItemRequest | DDL |
| BC-DB-04 | Model `StockItem`: table inv_stock_items, SoftDeletes, fillable 25 fields. Casts: decimals→decimal:3/2, booleans→boolean, item_type/valuation_method→string. Relations: stockGroup() BelongsTo, uom() BelongsTo, stockBalances() HasMany, vendorLinks() HasMany, stockEntries() HasMany, assets() HasMany, taxRate() BelongsTo (acc), purchaseLedger() BelongsTo (acc), salesLedger() BelongsTo (acc) | Model |
| BC-DB-05 | **Downstream FK dependency map** — tables referencing inv_stock_items.id (NOT NULL FK, deletion blocked at DB level unless ON DELETE CASCADE): inv_stock_balances (stock_item_id), inv_item_vendor_jnt (item_id), inv_rate_contract_items_jnt (item_id), inv_purchase_requisition_items (item_id), inv_quotation_items (item_id), inv_purchase_order_items (item_id), inv_issue_request_items (item_id), inv_stock_adjustment_items (item_id), inv_grn_items (item_id), inv_stock_issue_items (item_id), inv_stock_entries (stock_item_id), inv_assets (stock_item_id) | DDL |

### BC-VAL — Validation (StoreStockItemRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `name` required string max:150 | FR |
| BC-VAL-02 | `sku` nullable string max:50 unique:inv_stock_items,sku (ignores own ID on update) | FR |
| BC-VAL-03 | `alias` nullable string max:150 | FR |
| BC-VAL-04 | `stock_group_id` required integer exists:inv_stock_groups,id | FR |
| BC-VAL-05 | `uom_id` required integer exists:inv_units_of_measure,id | FR |
| BC-VAL-06 | `item_type` required in:consumable,asset | FR |
| BC-VAL-07 | `valuation_method` required in:fifo,weighted_average,last_purchase | FR |
| BC-VAL-08 | `opening_balance_qty` nullable numeric min:0 | FR |
| BC-VAL-09 | `opening_balance_rate` nullable numeric min:0 | FR |
| BC-VAL-10 | `reorder_level` nullable numeric min:0 | FR |
| BC-VAL-11 | `reorder_qty` nullable numeric min:0 | FR |
| BC-VAL-12 | `min_stock` nullable numeric min:0 | FR |
| BC-VAL-13 | `max_stock` nullable numeric min:0 | FR |
| BC-VAL-14 | `auto_reorder_pr` boolean | FR |
| BC-VAL-15 | `variance_threshold` nullable numeric min:0 | FR |
| BC-VAL-16 | `has_batch_tracking` boolean | FR |
| BC-VAL-17 | `has_expiry_tracking` boolean | FR |
| BC-VAL-18 | `hsn_sac_code` nullable string max:20 | FR |
| BC-VAL-19 | `brand` nullable string max:100 | FR |
| BC-VAL-20 | `model` nullable string max:100 | FR |
| BC-VAL-21 | `warranty_months` nullable integer min:0 | FR |
| BC-VAL-22 | `tax_rate_id` nullable integer exists:acc_tax_rates,id | FR (cross-module) |
| BC-VAL-23 | `purchase_ledger_id` nullable integer exists:acc_ledgers,id | FR (cross-module) |
| BC-VAL-24 | `sales_ledger_id` nullable integer exists:acc_ledgers,id | FR (cross-module) |

### BC-AUTH — Authorization (StockItemPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/search gate `tenant.inventory.stock-item.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.stock-item.create` | Policy |
| BC-AUTH-03 | show/printLabels gate `tenant.inventory.stock-item.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.inventory.stock-item.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.stock-item.delete` | Policy (+ restore/forceDelete in policy) |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Index: paginated 25, loads stockGroup+uom relations. Search filters: search (name LIKE), group_id (exact), item_type (exact). Groups and UOMs loaded for filter dropdowns | Ctrl |
| BC-BIZ-02 | Index cards: name, SKU code badge, item_type badge (info/warning), stock group name, UOM symbol, valuation method badge, status toggle, action buttons | View |
| BC-BIZ-03 | Create page: loads active StockGroups, active UOMs, active TaxRates, active Ledgers for dropdowns. Uses Select2 on stock_group_id, uom_id, tax_rate_id, purchase_ledger_id, sales_ledger_id | View |
| BC-BIZ-04 | Create form: Basic Information (name, SKU, alias, stock_group_id, uom_id), Configuration (item_type, valuation_method, is_active), Opening Balance (qty, rate, value auto-calc via JS), Stock Control (reorder levels, auto_reorder_pr toggle), Inventory Tracking (batch_tracking, expiry_tracking toggles), Accounting & Tax (tax_rate_id, purchase_ledger_id, sales_ledger_id), Additional Details (brand, model, hsn_sac_code, warranty_months) | View |
| BC-BIZ-05 | Store: opening_balance_value auto-calculated as qty × rate (server-side). Boolean fields handled via $request->boolean(). Sets created_by + updated_by = auth()->id(). Redirects to show page with success | Ctrl |
| BC-BIZ-06 | Show page: two-column layout — left 8-col (tabs: Details, Stock Balance, Vendors), right 4-col (Item Info sidebar, Quick Actions) | View |
| BC-BIZ-07 | Details tab: Stock Group, UOM, Valuation Method, HSN/SAC, Reorder Level/Qty, Min/Max Stock, Brand, Model, Warranty, Opening Balance (qty/rate/value), Tax Rate, Purchase/Sales Ledger, Auto Reorder PR, Batch Tracking, Expiry Tracking, Status | View |
| BC-BIZ-08 | Stock Balance tab: table per godown — Godown name, Current Qty, UOM Symbol, Value/Unit, Total Value. Empty state if no balances | View |
| BC-BIZ-09 | Vendors tab: table — Vendor ID, Preferred (star), Lead Time Days, Min Order Qty, Last Purchase Rate. Empty state if no vendor links | View |
| BC-BIZ-10 | Right sidebar: Item Info (Created At, Updated At, Created By). Quick Actions: Toggle Status (form POST), Print Labels (form POST), Delete (form — disabled with tooltip if stock on hand) | View |
| BC-BIZ-11 | Edit page: opening_balance fields become readonly when stockEntries()->exists() (has stock movements). Alert info banner shown | View |
| BC-BIZ-12 | Edit form: same layout as create, pre-populated with old() or existing values | View |
| BC-BIZ-13 | Update: same logic as store but no opening_balance_value auto-calc. Sets updated_by. Redirects to show | Ctrl |
| BC-BIZ-14 | Toggle: updates is_active to opposite, sets updated_by, returns JSON {success, message, is_active} | Ctrl |
| BC-BIZ-15 | Delete guarded: checks stockBalances()->where('current_qty', '>', 0)->exists(). If true → back() with error 'Cannot delete item with stock on hand.' Otherwise soft deletes after setting updated_by | Ctrl |
| BC-BIZ-16 | **Gap**: Delete does NOT check downstream FK dependencies: vendorLinks, PR items, PO items, GRN items, issue requests, stock entries, assets, rate contract items, quotation items, adjustment items. Only stock on hand is checked | Ctrl |
| BC-BIZ-17 | Print Labels: dedicated page with controls bar (Qty input, Size S/M/L), label grid with item name, SKU, group, type, brand/model, HSN, reorder level. JavaScript dynamic rendering, window.print() | View |
| BC-BIZ-18 | Search AJAX endpoint: GET /inventory/stock-items/search?q=. Returns paginated 20 results {id, name, sku}. Used by autocomplete in other modules | Ctrl |
| BC-BIZ-19 | Empty state index: "No Stock Items Found" with icon + "Add Item" CTA button | View |
| BC-BIZ-20 | Index pagination: appends all query params (search, group_id, item_type) | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Delete item with stock on hand (current_qty > 0) → blocked (redirect error) | Ctrl |
| BC-EDG-02 | Delete item referenced by downstream FKs (vendor links, PR, PO, GRN, issue, entry, asset, etc.) — only stock balance is checked; ALL other downstream refs NOT guarded. Item will soft-delete but downstream FK constraints at DB level may fail on force-delete | Gap |
| BC-EDG-03 | Duplicate SKU → unique validation error (unique:inv_stock_items,sku ignores own ID on update) | FR |
| BC-EDG-04 | Invalid stock_group_id (non-existent) → exists:inv_stock_groups validation error | FR |
| BC-EDG-05 | Invalid uom_id (non-existent) → exists:inv_units_of_measure validation error | FR |
| BC-EDG-06 | Invalid tax_rate_id (non-existent/deleted) → exists:acc_tax_rates validation error | FR |
| BC-EDG-07 | Invalid purchase_ledger_id or sales_ledger_id → exists:acc_ledgers validation error | FR |
| BC-EDG-08 | Opening balance value auto-calc: qty × rate on store (server-side) — both must be present. If one is null, the other should also be ignored. Check if partial (qty without rate or vice versa) creates value=0 | Ctrl |
| BC-EDG-09 | Opening balance fields readonly on edit when stockEntries exist — stockEntries()->exists() check. Cannot modify after first stock movement | View |
| BC-EDG-10 | name > 150 chars → max validation error | FR |
| BC-EDG-11 | SKU > 50 chars → max validation error | FR |
| BC-EDG-12 | Negative numeric fields (qty, rate, reorder, etc.) → min:0 rule | FR |
| BC-EDG-13 | Invalid item_type (not consumable/asset) → in rule validation error | FR |
| BC-EDG-14 | Invalid valuation_method → in rule validation error | FR |
| BC-EDG-15 | warranty_months < 0 → min:0 rule | FR |
| BC-EDG-16 | has_batch_tracking + has_expiry_tracking — non-boolean values → boolean rule | FR |
| BC-EDG-17 | auto_reorder_pr — non-boolean values → boolean rule | FR |
| BC-EDG-18 | variance_threshold = 0 → allowed (min:0). Empty = null → auto-approve behavior | FR |
| BC-EDG-19 | Print labels: qty input capped at 200 (min 1). Empty/default = 10 labels | View |
| BC-EDG-20 | Print labels: item with no SKU → displays "NO-SKU" as fallback | View |
| BC-EDG-21 | Restore already-active item → restore() on non-trashed model (Laravel no-op) | Ctrl |

---

## 2. Test Case List

### Screen 1: Item Catalog Index (GET /inventory/stock-items)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P10 | Positive | View | Index: paginated card list (name, SKU, item_type badge, stock group, UOM symbol, valuation_method badge, toggle, actions) | Rendered | test_inv_sitm_10 | Automated |
| TC-INVSITM-P11 | Positive | View | Search by name (LIKE), filter by stock_group_id (exact), filter by item_type (consumable/asset) | Filters | test_inv_sitm_11 | Automated |
| TC-INVSITM-P12 | Positive | View | Filter dropdowns populated: Stock Groups (active, ordered), item_type (consumable/asset) | Dropdowns | test_inv_sitm_12 | Automated |
| TC-INVSITM-P13 | Positive | View | "Add Item" button links to create page | Link | test_inv_sitm_13 | Automated |
| TC-INVSITM-P14 | Positive | View | Empty state: icon, "No Stock Items Found" heading, "Add Item" CTA | Empty | test_inv_sitm_14 | Automated |
| TC-INVSITM-P15 | Positive | View | Pagination: 25 per page, query params preserved (search, group_id, item_type) | Paginated | test_inv_sitm_15 | Automated |

### Screen 2: Create (GET /inventory/stock-items/create) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P30 | Positive | View | Create page: all sections rendered — Basic Info, Configuration, Opening Balance, Stock Control, Tracking, Accounting, Additional | Sections | test_inv_sitm_30 | Automated |
| TC-INVSITM-P31 | Positive | View | Dropdowns loaded: Stock Groups (active), UOMs (active), Tax Rates (active), Ledgers (active) — each with Select2 | Dropdowns | test_inv_sitm_31 | Automated |
| TC-INVSITM-P32 | Positive | View | Opening balance value auto-calculated client-side when qty or rate changes | JS calc | test_inv_sitm_32 | Automated |
| TC-INVSITM-P33 | Positive | Ctrl | Valid store (all fields): creates item, opening_balance_value = qty × rate, redirects to show with success | Created | test_inv_sitm_33 | Automated |
| TC-INVSITM-P34 | Positive | Ctrl | Store with minimal fields (name, stock_group_id, uom_id, item_type, valuation_method only) | Created | test_inv_sitm_34 | Automated |
| TC-INVSITM-P35 | Positive | Ctrl | Store with cross-module FKs: tax_rate_id, purchase_ledger_id, sales_ledger_id all valid → created | Created | test_inv_sitm_35 | Automated |
| TC-INVSITM-P36 | Positive | Ctrl | Store with boolean flags: auto_reorder_pr, has_batch_tracking, has_expiry_tracking all true → saved as 1 | Created | test_inv_sitm_36 | Automated |
| TC-INVSITM-P37 | Positive | Ctrl | Store with item_type=asset → creates asset-type item (triggers asset creation on GRN acceptance elsewhere) | Created | test_inv_sitm_37 | Automated |
| TC-INVSITM-P38 | Positive | Ctrl | Store with opening_balance_qty=null, rate=null → defaults to 0, value=0 | Created | test_inv_sitm_38 | Automated |
| TC-INVSITM-N39 | Negative | Val | Missing name → required error | Error | test_inv_sitm_39 | Automated |
| TC-INVSITM-N40 | Negative | Val | name > 150 chars → max error | Error | test_inv_sitm_40 | Automated |
| TC-INVSITM-N41 | Negative | Val | Missing stock_group_id → required error | Error | test_inv_sitm_41 | Automated |
| TC-INVSITM-N42 | Negative | Val | Invalid stock_group_id (non-existent) → exists validation error | Error | test_inv_sitm_42 | Automated |
| TC-INVSITM-N43 | Negative | Val | Missing uom_id → required error | Error | test_inv_sitm_43 | Automated |
| TC-INVSITM-N44 | Negative | Val | Invalid uom_id (non-existent) → exists validation error | Error | test_inv_sitm_44 | Automated |
| TC-INVSITM-N45 | Negative | Val | Missing item_type → required error | Error | test_inv_sitm_45 | Automated |
| TC-INVSITM-N46 | Negative | Val | Invalid item_type → in:consumable,asset error | Error | test_inv_sitm_46 | Automated |
| TC-INVSITM-N47 | Negative | Val | Missing valuation_method → required error | Error | test_inv_sitm_47 | Automated |
| TC-INVSITM-N48 | Negative | Val | Invalid valuation_method → in:fifo,weighted_average,last_purchase error | Error | test_inv_sitm_48 | Automated |
| TC-INVSITM-N49 | Negative | Val | Duplicate SKU → unique validation error | Error | test_inv_sitm_49 | Automated |
| TC-INVSITM-N50 | Negative | Val | SKU > 50 chars → max error | Error | test_inv_sitm_50 | Automated |
| TC-INVSITM-N51 | Negative | Val | Negative opening_balance_qty → min:0 error | Error | test_inv_sitm_51 | Automated |
| TC-INVSITM-N52 | Negative | Val | Negative opening_balance_rate → min:0 error | Error | test_inv_sitm_52 | Automated |
| TC-INVSITM-N53 | Negative | Val | Negative reorder_level → min:0 error | Error | test_inv_sitm_53 | Automated |
| TC-INVSITM-N54 | Negative | Val | Invalid tax_rate_id (non-existent) → exists error (cross-module) | Error | test_inv_sitm_54 | Automated |
| TC-INVSITM-N55 | Negative | Val | Invalid purchase_ledger_id (non-existent) → exists error (cross-module) | Error | test_inv_sitm_55 | Automated |
| TC-INVSITM-N56 | Negative | Val | Invalid sales_ledger_id (non-existent) → exists error (cross-module) | Error | test_inv_sitm_56 | Automated |
| TC-INVSITM-N57 | Negative | Val | Negative warranty_months → min:0 error | Error | test_inv_sitm_57 | Automated |
| TC-INVSITM-N58 | Negative | Val | Non-boolean value for has_batch_tracking → boolean error | Error | test_inv_sitm_58 | Automated |
| TC-INVSITM-N59 | Negative | Val | hsn_sac_code > 20 chars → max error | Error | test_inv_sitm_59 | Automated |
| TC-INVSITM-N60 | Negative | Val | brand > 100 chars → max error | Error | test_inv_sitm_60 | Automated |

### Screen 3: Show (GET /inventory/stock-items/{stockItem})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P80 | Positive | View | Show: left column — tabs (Details, Stock Balance, Vendors), right sidebar (Item Info + Quick Actions) | Layout | test_inv_sitm_80 | Automated |
| TC-INVSITM-P81 | Positive | View | Details tab: all fields displayed — Stock Group, UOM, Valuation Method, HSN, Reorder, Min/Max, Brand, Model, Warranty, Opening Balance, Accounting, Tracking flags | Details | test_inv_sitm_81 | Automated |
| TC-INVSITM-P82 | Positive | View | Stock Balance tab: table — Godown name, Current Qty (formatted), UOM symbol, Value/Unit, Total Value. Empty state if none | Table | test_inv_sitm_82 | Automated |
| TC-INVSITM-P83 | Positive | View | Vendors tab: table — Vendor ID, Preferred star, Lead Time, Min Order Qty, Last Purchase Rate. Empty state if none | Table | test_inv_sitm_83 | Automated |
| TC-INVSITM-P84 | Positive | View | Right sidebar: Created At, Updated At, Created By timestamps | Meta | test_inv_sitm_84 | Automated |
| TC-INVSITM-P85 | Positive | View | Quick Actions: Toggle Status button (matches active state), Print Labels button, Delete button (disabled if stock on hand with tooltip) | Actions | test_inv_sitm_85 | Automated |
| TC-INVSITM-P86 | Positive | View | Delete button enabled when totalQty <= 0 (no stock on hand) | Enabled | test_inv_sitm_86 | Automated |
| TC-INVSITM-P87 | Positive | View | Delete button disabled with "Cannot delete — stock on hand: X.XX" when stock exists | Disabled | test_inv_sitm_87 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P110 | Positive | View | Edit page: form pre-populated with all field values, dropdowns selected correctly | Pre-filled | test_inv_sitm_110 | Automated |
| TC-INVSITM-P111 | Positive | View | Opening balance fields readonly when stockEntries exist — alert banner "Stock movements exist — opening balance fields are read-only" | Readonly | test_inv_sitm_111 | Automated |
| TC-INVSITM-P112 | Positive | View | Opening balance fields editable when no stock movements yet | Editable | test_inv_sitm_112 | Automated |
| TC-INVSITM-P113 | Positive | Ctrl | Update changes fields, redirects to show with success | Updated | test_inv_sitm_113 | Automated |
| TC-INVSITM-P114 | Positive | Ctrl | Update SKU to same value (own SKU) → allowed (unique ignores self) | Allowed | test_inv_sitm_114 | Automated |
| TC-INVSITM-P115 | Positive | Ctrl | Update changes stock_group_id or uom_id to a different valid value | Updated | test_inv_sitm_115 | Automated |
| TC-INVSITM-N116 | Negative | Val | Update: missing name → required error | Error | test_inv_sitm_116 | Automated |
| TC-INVSITM-N117 | Negative | Val | Update: duplicate SKU (taken by another item) → unique error | Error | test_inv_sitm_117 | Automated |

### Screen 5: Toggle Status

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P140 | Positive | Ctrl | Toggle active→inactive returns JSON {success:true, message, is_active:false} | JSON false | test_inv_sitm_140 | Automated |
| TC-INVSITM-P141 | Positive | Ctrl | Toggle inactive→active returns JSON {success:true, message, is_active:true} | JSON true | test_inv_sitm_141 | Automated |

### Screen 6: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P160 | Positive | Ctrl | Delete item with no stock on hand → soft-deleted, appears in trash | Deleted | test_inv_sitm_160 | Automated |
| TC-INVSITM-N161 | Negative | Biz | Delete item with stock on hand (current_qty > 0) → back() with error 'Cannot delete item with stock on hand.' → NOT deleted | Blocked | test_inv_sitm_161 | Automated |
| TC-INVSITM-P162 | Positive | View | Trash page: table with Name, SKU, Item Type, Deleted At, restore/force-delete actions | Table | test_inv_sitm_162 | Automated |
| TC-INVSITM-P163 | Positive | Ctrl | Restore from trash → success message 'Record restored successfully.' | Restored | test_inv_sitm_163 | Automated |
| TC-INVSITM-P164 | Positive | Ctrl | Force delete from trash → success message 'Permanently deleted.' | Perm deleted | test_inv_sitm_164 | Automated |

### Screen 7: Print Labels (POST /inventory/stock-items/{stockItem}/print-labels)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P180 | Positive | View | Print labels page: controls bar (qty input, size S/M/L buttons), label grid with item info | Rendered | test_inv_sitm_180 | Automated |
| TC-INVSITM-P181 | Positive | View | Label card: header (group, type, #N), body (name, sub-line brand·model, SKU in monospace), footer (UOM, HSN, reorder) | Card | test_inv_sitm_181 | Automated |
| TC-INVSITM-P182 | Positive | View | Default 10 labels rendered, size M (3 per row), grid updates when qty/size changes via JS | Dynamic | test_inv_sitm_182 | Automated |
| TC-INVSITM-P183 | Positive | View | Item with no SKU → displays "NO-SKU" fallback | Fallback | test_inv_sitm_183 | Automated |
| TC-INVSITM-P184 | Positive | View | Qty input capped at max 200, min 1 | Constraints | test_inv_sitm_184 | Automated |

### Screen 8: AJAX Search (GET /inventory/stock-items/search)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P200 | Positive | Ctrl | Search by name fragment → returns JSON paginated results {id, name, sku} | Results | test_inv_sitm_200 | Automated |
| TC-INVSITM-P201 | Positive | Ctrl | Search by SKU fragment → returns matching results | Results | test_inv_sitm_201 | Automated |
| TC-INVSITM-P202 | Positive | Ctrl | Search with no query (q=empty) → returns all items paginated 20 | All | test_inv_sitm_202 | Automated |
| TC-INVSITM-P203 | Positive | Ctrl | Search only active items (scope:active) | Active only | test_inv_sitm_203 | Automated |

### Cross-Entity FK Dependency Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P220 | Positive | FK | Create with valid stock_group_id → group exists in inv_stock_groups | Created | test_inv_sitm_220 | Automated |
| TC-INVSITM-P221 | Positive | FK | Create with valid uom_id → uom exists in inv_units_of_measure | Created | test_inv_sitm_221 | Automated |
| TC-INVSITM-P222 | Positive | FK | Create with valid tax_rate_id → tax rate exists in acc_tax_rates (cross-module) | Created | test_inv_sitm_222 | Automated |
| TC-INVSITM-P223 | Positive | FK | Create with valid purchase_ledger_id → ledger exists in acc_ledgers (cross-module) | Created | test_inv_sitm_223 | Automated |
| TC-INVSITM-P224 | Positive | FK | Create with valid sales_ledger_id → ledger exists in acc_ledgers (cross-module) | Created | test_inv_sitm_224 | Automated |
| TC-INVSITM-N225 | Negative | FK | Create with stock_group_id of inactive/deleted group → exists validation error (only active groups in dropdown but exists rule checks entire table) | Error | test_inv_sitm_225 | Automated |
| TC-INVSITM-N226 | Negative | FK | Delete stock_group referenced by stock items → DB FK constraint prevents (CASCADE — would delete items) | Blocked | test_inv_sitm_226 | Integration |
| TC-INVSITM-N227 | Negative | FK | Delete uom referenced by stock items → DB FK constraint prevents (CASCADE — would cascade delete items, but UOM controller only guards stockItems()->exists()) | Blocked | test_inv_sitm_227 | Integration |

### Downstream Dependency Gap Tests (Delete Guard Gap)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-D230 | Gap | Biz | Delete item with vendorLinks (item_vendor_jnt) but no stock on hand → soft-deletes (not guarded — potential data integrity gap) | Soft-deleted | test_inv_sitm_230 | Automated |
| TC-INVSITM-D231 | Gap | Biz | Delete item referenced by purchase_requisition_items but no stock on hand → soft-deletes (not guarded) | Soft-deleted | test_inv_sitm_231 | Automated |
| TC-INVSITM-D232 | Gap | Biz | Delete item referenced by purchase_order_items but no stock on hand → soft-deletes (not guarded) | Soft-deleted | test_inv_sitm_232 | Automated |
| TC-INVSITM-D233 | Gap | Biz | Delete item referenced by grn_items but no stock on hand → soft-deletes (not guarded) | Soft-deleted | test_inv_sitm_233 | Automated |
| TC-INVSITM-D234 | Gap | Biz | Delete item referenced by stock_entries but no stock on hand → soft-deletes (not guarded) | Soft-deleted | test_inv_sitm_234 | Automated |
| TC-INVSITM-D235 | Gap | Biz | Delete item referenced by assets but no stock on hand → soft-deletes (not guarded) | Soft-deleted | test_inv_sitm_235 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSITM-P250 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_inv_sitm_250 | Automated |
| TC-INVSITM-N251 | Negative | Auth | Without viewAny → 403 on index/search | 403 | test_inv_sitm_251 | Automated |
| TC-INVSITM-N252 | Negative | Auth | Without create → 403 on create page/store | 403 | test_inv_sitm_252 | Automated |
| TC-INVSITM-N253 | Negative | Auth | Without view → 403 on show/printLabels | 403 | test_inv_sitm_253 | Automated |
| TC-INVSITM-N254 | Negative | Auth | Without update → 403 on edit/update/toggle | 403 | test_inv_sitm_254 | Automated |
| TC-INVSITM-N255 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_sitm_255 | Automated |
