# inv_ItemVendor — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Item-Vendor Links (AJAX CRUD + Soft-Delete + Preferred Vendor)
**DB scope:** TENANT-side (`inv_item_vendor_jnt`) · **Test style:** Browser Dusk
**Primary table:** `inv_item_vendor_jnt` (Layer 4) · **Module URL prefix:** `/inventory/vendor-contracts?tab=item-vendors`
**Test file:** `inv_ItemVendor_TestCas.php`
**Tab:** Item-Vendor Links (second tab of Vendor & Contracts page)

Controller:
- `ItemVendorController` — AJAX CRUD (nested under items/{item}/vendors) + trash lifecycle
- `InvMenuController::vendorContracts()` — loads stock items with vendorLinks for tab page

Routes (`inventory.` prefix):
- `GET /inventory/vendor-contracts` — combined tab page (item-vendors tab)
- `GET /inventory/items/{item}/vendors` — list vendors for an item (JSON)
- `POST /inventory/items/{item}/vendors` — link vendor to item (JSON, updateOrCreate)
- `PUT /inventory/items/{item}/vendors/{vendor}` — update link (JSON)
- `DELETE /inventory/items/{item}/vendors/{vendor}` — unlink vendor (JSON)
- `GET /inventory/item-vendors/trash/view` — trashed (dedicated top-level route)
- `GET /inventory/item-vendors/{id}/restore` — restore
- `DELETE /inventory/item-vendors/{id}/force-delete` — force delete

**DDL reference:** `inv_item_vendor_jnt` (Layer 4)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_item_vendor_jnt`: id (BIGINT PK AI), item_id (BIGINT UNSIGNED NOT NULL FK → inv_stock_items.id CASCADE), vendor_id (INT UNSIGNED NOT NULL → vnd_vendors.id), vendor_sku (VARCHAR 50 NULL), last_purchase_rate (DECIMAL 15,2 NULL), last_purchase_date (DATE NULL), lead_time_days (INT NULL), is_preferred (TINYINT 1 DEFAULT 0), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (item_id, vendor_id). Indexes: idx_inv_ivj_item_id/vendor_id/is_active. FK item_id → inv_stock_items.id (NOT NULL, CASCADE). FK vendor_id commented out | DDL |
| BC-DB-02 | Model `ItemVendorJnt`: table inv_item_vendor_jnt, NO SoftDeletes on model (but table has deleted_at). Casts: last_purchase_rate→decimal:2, last_purchase_date→date, lead_time_days→integer, is_preferred→boolean, is_active→boolean. Relations: stockItem() BelongsTo (StockItem::class) | Model |

### BC-VAL — Validation (StoreItemVendorRequest / UpdateItemVendorRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-02 | `vendor_id` required integer exists:vnd_vendors,id | FR (cross-module) |
| BC-VAL-03 | `vendor_sku` nullable string max:50 | FR |
| BC-VAL-04 | `lead_time_days` nullable integer min:0 | FR |
| BC-VAL-05 | `last_purchase_rate` nullable numeric min:0 | FR |
| BC-VAL-06 | `is_preferred` boolean | FR |

### BC-AUTH — Authorization (ItemVendorPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.item-vendor.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.item-vendor.create` | Policy |
| BC-AUTH-03 | update gate `tenant.inventory.item-vendor.update` | Policy |
| BC-AUTH-04 | destroy/trashed/restore/forceDelete gate `tenant.inventory.item-vendor.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Item-Vendor Links tab: card list per STOCK ITEM (not per link) — item name, SKU, type badge, preferred vendor (name/SKU), vendor count badge, status toggle, Manage Vendors button, actions | View |
| BC-BIZ-02 | Only ONE preferred vendor per item: setting is_preferred=true on one link un-sets preferred (false) on all others via $item->vendorLinks()->update(['is_preferred' => false]) | Ctrl |
| BC-BIZ-03 | Store: uses updateOrCreate(['item_id', 'vendor_id'], ...) — prevents duplicate links | Ctrl |
| BC-BIZ-04 | Index: returns JSON with vendor relationship loaded, ordered by is_preferred desc | Ctrl |
| BC-BIZ-05 | Link Vendor modal: Stock Item select, Vendor select, Vendor SKU, Lead Time, Last Purchase Rate, Preferred toggle | View |
| BC-BIZ-06 | Link Vendor form: JS dynamically sets action URL based on selected stock_item_id | View |
| BC-BIZ-07 | Empty state: "No Stock Items Found" with link icon — note: this is items-based, not links-based | View |
| BC-BIZ-08 | Manage Vendors button links to GET /inventory/items/{item}/vendors (JSON data — no dedicated UI page, consumed by frontend) | View |
| BC-BIZ-09 | Status switch on item (not on link) — references inventory.stock-items toggle URL | View |
| BC-BIZ-10 | All CRUD responses are JSON: {status: true, message, data} | Ctrl |
| BC-BIZ-11 | Destroy returns JSON on delete, trashed page shows table with item name+SKU, vendor ID, vendor SKU, last rate, deleted at, restore/force-delete | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Link same vendor twice to same item → updateOrCreate prevents duplicate (acts as update) | Ctrl |
| BC-EDG-02 | Set preferred vendor when one already exists → old preferred = false, new = true | Ctrl |
| BC-EDG-03 | Invalid item_id → exists:inv_stock_items validation error | FR |
| BC-EDG-04 | Invalid vendor_id → exists:vnd_vendors validation error | FR (cross-module) |
| BC-EDG-05 | Negative lead_time_days → min:0 error | FR |
| BC-EDG-06 | Negative last_purchase_rate → min:0 error | FR |
| BC-EDG-07 | vendor_sku > 50 chars → max error | FR |
| BC-EDG-08 | Non-boolean is_preferred → boolean rule | FR |
| BC-EDG-09 | Item with no vendors → "No preferred vendor" text in card | View |
| BC-EDG-10 | Item with multiple vendors → vendor count badge shows correct count | View |

---

## 2. Test Case List

### Screen 1: Item-Vendor Links Tab (GET /inventory/vendor-contracts?tab=item-vendors)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P10 | Positive | View | Item-Vendor tab: card list per stock item — name, SKU badge, type badge (consumable/asset), preferred vendor (name+SKU or "No preferred vendor"), vendors count badge, status toggle, Manage Vendors button, actions | Rendered | test_inv_iv_10 | Automated |
| TC-INVIV-P11 | Positive | View | Search and status filter (is_active of item) | Filters | test_inv_iv_11 | Automated |
| TC-INVIV-P12 | Positive | View | Link Vendor button opens modal with Stock Item, Vendor, Vendor SKU, Lead Time, Last Purchase Rate, Preferred toggle | Modal | test_inv_iv_12 | Automated |
| TC-INVIV-P13 | Positive | View | Link Vendor modal: JS sets form action to /inventory/items/{itemId}/vendors based on selected stock_item_id | Dynamic URL | test_inv_iv_13 | Automated |
| TC-INVIV-P14 | Positive | View | Item with preferred vendor: shows star icon, vendor ID, vendor SKU | Preferred | test_inv_iv_14 | Automated |
| TC-INVIV-P15 | Positive | View | Item with no vendors: shows "No preferred vendor" in italic muted text | No vendor | test_inv_iv_15 | Automated |
| TC-INVIV-P16 | Positive | View | Multiple vendors: badge shows "X vendors" (pluralized) | Count | test_inv_iv_16 | Automated |
| TC-INVIV-P17 | Positive | View | Empty state: "No Stock Items Found" with link icon | Empty | test_inv_iv_17 | Automated |
| TC-INVIV-P18 | Positive | View | Manage Vendors button links to AJAX endpoint (JSON) | Button | test_inv_iv_18 | Automated |

### Screen 2: Link Vendor (Modal) + Store (AJAX)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P30 | Positive | Ctrl | Store: link vendor to item → JSON {status:true, message, data}, link created | Created | test_inv_iv_30 | Automated |
| TC-INVIV-P31 | Positive | Ctrl | Store with all optional fields (vendor_sku, lead_time_days, last_purchase_rate) | Created | test_inv_iv_31 | Automated |
| TC-INVIV-P32 | Positive | Ctrl | Store with is_preferred=true → unsets preferred on other links for same item | Preferred set | test_inv_iv_32 | Automated |
| TC-INVIV-P33 | Positive | Ctrl | Store same vendor+item again → updateOrCreate updates existing (no duplicate) | Updated | test_inv_iv_33 | Automated |
| TC-INVIV-N34 | Negative | Val | Missing item_id → required error | Error | test_inv_iv_34 | Automated |
| TC-INVIV-N35 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_iv_35 | Automated |
| TC-INVIV-N36 | Negative | Val | Missing vendor_id → required error | Error | test_inv_iv_36 | Automated |
| TC-INVIV-N37 | Negative | Val | Invalid vendor_id → exists:vnd_vendors error (cross-module) | Error | test_inv_iv_37 | Automated |
| TC-INVIV-N38 | Negative | Val | Negative lead_time_days → min:0 error | Error | test_inv_iv_38 | Automated |
| TC-INVIV-N39 | Negative | Val | Negative last_purchase_rate → min:0 error | Error | test_inv_iv_39 | Automated |
| TC-INVIV-N40 | Negative | Val | vendor_sku > 50 chars → max error | Error | test_inv_iv_40 | Automated |
| TC-INVIV-N41 | Negative | Val | Non-boolean is_preferred → boolean rule | Error | test_inv_iv_41 | Automated |

### Screen 3: Update Vendor Link (AJAX PUT)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P50 | Positive | Ctrl | Update: changes vendor_sku, lead_time_days, last_purchase_rate → JSON success | Updated | test_inv_iv_50 | Automated |
| TC-INVIV-P51 | Positive | Ctrl | Update setting is_preferred=true → unsets preferred on other links for same item | Preferred | test_inv_iv_51 | Automated |
| TC-INVIV-P52 | Positive | Ctrl | Update clearing optional fields to null → saved as null | Cleared | test_inv_iv_52 | Automated |
| TC-INVIV-N53 | Negative | Val | Update: non-existent vendor link → firstOrFail throws ModelNotFoundException | 404 | test_inv_iv_53 | Automated |

### Screen 4: Delete / Unlink Vendor (AJAX DELETE)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P70 | Positive | Ctrl | Delete: unlinks vendor from item → JSON {status:true, message} | Deleted | test_inv_iv_70 | Automated |
| TC-INVIV-N71 | Negative | Ctrl | Delete non-existent link → firstOrFail 404 | 404 | test_inv_iv_71 | Automated |

### Screen 5: Index / List Vendors for Item (AJAX)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P80 | Positive | Ctrl | Index: GET items/{item}/vendors → JSON with vendor relationship loaded, ordered by is_preferred desc | JSON | test_inv_iv_80 | Automated |
| TC-INVIV-P81 | Positive | Ctrl | Item with multiple vendors → all returned | Multiple | test_inv_iv_81 | Automated |
| TC-INVIV-P82 | Positive | Ctrl | Item with no vendors → empty data array | Empty | test_inv_iv_82 | Automated |

### Screen 6: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P90 | Positive | View | Trash page: table — Stock Item name+SKU, Vendor ID, Vendor SKU, Last Rate, Deleted At, restore/force-delete | Table | test_inv_iv_90 | Automated |
| TC-INVIV-P91 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_iv_91 | Automated |
| TC-INVIV-P92 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_iv_92 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIV-P200 | Positive | Auth | ItemVendor CRUD with correct permissions → 200/JSON success | 200 | test_inv_iv_200 | Automated |
| TC-INVIV-N201 | Negative | Auth | Without viewAny → 403 on tab/index | 403 | test_inv_iv_201 | Automated |
| TC-INVIV-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_iv_202 | Automated |
| TC-INVIV-N203 | Negative | Auth | Without update → 403 on update | 403 | test_inv_iv_203 | Automated |
| TC-INVIV-N204 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_iv_204 | Automated |
