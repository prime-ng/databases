# inv_RateContract — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Rate Contracts (CRUD + Status Lifecycle + Contract Items)
**DB scope:** TENANT-side (`inv_rate_contracts`, `inv_rate_contract_items_jnt`) · **Test style:** Browser Dusk
**Primary table:** `inv_rate_contracts` (Layer 4) · **Module URL prefix:** `/inventory/vendor-contracts?tab=rate-contracts`
**Test file:** `inv_RateContract_TestCas.php`
**Tab:** Rate Contracts (first tab of Vendor & Contracts page)

Controllers:
- `RateContractController` — CRUD + activate + items CRUD (AJAX) + trash
- `InvMenuController::vendorContracts()` — loads rate contracts + vendors + stock items for both tabs

Service:
- `RateContractService` — create, update, activate, expire, cancel, delete

Routes (`inventory.` prefix):
- `GET /inventory/vendor-contracts` — combined tab page (rate-contracts default)
- `GET /inventory/rate-contracts` — index (redirects to vendor-contracts tab)
- `POST /inventory/rate-contracts` — store (with nested items array)
- `GET /inventory/rate-contracts/{rateContract}` — show
- `GET /inventory/rate-contracts/{rateContract}/edit` — edit (blocked if active)
- `PUT /inventory/rate-contracts/{rateContract}` — update
- `DELETE /inventory/rate-contracts/{rateContract}` — soft delete (blocked if active)
- `POST/PATCH /inventory/rate-contracts/{rateContract}/activate` — activate (from draft)
- `GET /inventory/rate-contracts/{rateContract}/items` — list items (JSON)
- `POST /inventory/rate-contracts/{rateContract}/items` — store item (JSON, draft only)
- `PUT /inventory/rate-contracts/{rateContract}/items/{item}` — update item (JSON, draft only)
- `DELETE /inventory/rate-contracts/{rateContract}/items/{item}` — destroy item (JSON)
- `GET /inventory/rate-contracts/trash/view` — trashed
- `GET /inventory/rate-contracts/{id}/restore` — restore
- `DELETE /inventory/rate-contracts/{id}/force-delete` — force delete

**DDL reference:** `inv_rate_contracts` (Layer 4), `inv_rate_contract_items_jnt` (Layer 5)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_rate_contracts`: id (BIGINT PK AI), vendor_id (INT UNSIGNED NOT NULL), contract_number (VARCHAR 50 NULL UNIQUE), valid_from (DATE NOT NULL), valid_to (DATE NOT NULL), status (ENUM draft/active/expired/cancelled DEFAULT draft), remarks (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_rc_contract_number, idx_inv_rc_vendor_id/status/valid_to/is_active. FK to vnd_vendors (commented out) | DDL |
| BC-DB-02 | Table `inv_rate_contract_items_jnt`: id (BIGINT PK AI), rate_contract_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), agreed_rate (DECIMAL 15,2 NOT NULL), min_qty (DECIMAL 15,3 NULL), max_qty (DECIMAL 15,3 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. UNIQUE (rate_contract_id, item_id). FKs: rate_contract_id → inv_rate_contracts.id CASCADE, item_id → inv_stock_items.id CASCADE | DDL |
| BC-DB-03 | Model `RateContract`: table inv_rate_contracts, SoftDeletes, fillable 7 fields, casts: valid_from/valid_to→date, is_active→boolean, status→string. Relations: vendor() BelongsTo (Vendor::class), items() HasMany (RateContractItemJnt). Scopes: active(), activeContracts() (status=active AND valid_to >= today) | Model |
| BC-DB-04 | Model `RateContractItemJnt`: table inv_rate_contract_items_jnt, NO SoftDeletes. Casts: agreed_rate→decimal:2, min_qty/max_qty→decimal:3, is_active→boolean. Relations: rateContract() BelongsTo, stockItem() BelongsTo (StockItem::class) | Model |

### BC-VAL — Validation (StoreRateContractRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `vendor_id` required integer exists:vnd_vendors,id | FR |
| BC-VAL-02 | `contract_number` nullable string max:50 unique:inv_rate_contracts,contract_number (ignores own ID on update) | FR |
| BC-VAL-03 | `status` nullable in:draft,active,expired,cancelled | FR |
| BC-VAL-04 | `valid_from` required date | FR |
| BC-VAL-05 | `valid_to` required date after_or_equal:valid_from | FR |
| BC-VAL-06 | `remarks` nullable string max:2000 | FR |
| BC-VAL-07 | `items` required on POST, array min:1 | FR |
| BC-VAL-08 | `items.*.item_id` required integer exists:inv_stock_items,id + unique composite (rate_contract_id, item_id) DB constraint | FR |
| BC-VAL-09 | `items.*.agreed_rate` required numeric min:0 | FR |
| BC-VAL-10 | `items.*.min_qty` nullable numeric min:0 | FR |
| BC-VAL-11 | `items.*.max_qty` nullable numeric min:0 | FR |

### BC-VAL-ITEMS — Item-level validation (inline in controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-ITEMS-01 | `item_id` required integer exists:inv_stock_items,id (storeItem) | Ctrl |
| BC-VAL-ITEMS-02 | `agreed_rate` required numeric min:0 (storeItem + updateItem) | Ctrl |
| BC-VAL-ITEMS-03 | `min_qty` nullable numeric min:0 (storeItem + updateItem) | Ctrl |
| BC-VAL-ITEMS-04 | `max_qty` nullable numeric min:0 (storeItem + updateItem) | Ctrl |

### BC-AUTH — Authorization (RateContractPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.rate-contract.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.rate-contract.create` | Policy |
| BC-AUTH-03 | show/items gate `tenant.inventory.rate-contract.view` | Policy |
| BC-AUTH-04 | edit/update/activate/items.store/items.update gate `tenant.inventory.rate-contract.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete/items.destroy gate `tenant.inventory.rate-contract.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Vendor Contracts page: 2 tabs — Rate Contracts (default), Item-Vendor Links | MenuCtrl |
| BC-BIZ-02 | Rate Contracts tab: card list — contract_number (linked), vendor name, validity dates, status badge (draft/active/expired), items_count badge, Activate button (draft only), actions | View |
| BC-BIZ-03 | Create via modal: Vendor select, Valid From/To (required dates), Contract Number (optional), Remarks, First Item section (item_id, agreed_rate, min_qty, max_qty). Info alert: "After creating, you can add more contract items on the contract detail page." | View |
| BC-BIZ-04 | Store via RateContractService::create(): creates contract with status=draft, creates all nested items, logs 'Created' activity, redirects to show page | Service |
| BC-BIZ-05 | Show page: left column — Contract Details (vendor, contract_number, valid_from/to, status badge, remarks) + Actions card (Activate if draft, Back). Right column — Agreed Item Rates table with Add Item button (draft only) | View |
| BC-BIZ-06 | Agreed Item Rates table: Item Name/SKU (linked), UOM symbol, Agreed Rate (formatted), Min Qty, Max Qty, Actions (Edit/Delete buttons shown only for draft contracts, "Locked" for non-draft) | View |
| BC-BIZ-07 | Add Item modal (draft only): Select2 stock item select, agreed_rate required, min/max qty optional. JS AJAX submission, reloads on success | View |
| BC-BIZ-08 | Edit Item modal (draft only): Pre-filled rate/min/max, JS pre-fill from data attributes, AJAX PUT submission | View |
| BC-BIZ-09 | Delete Item: AJAX DELETE, JSON response {status, message}, confirm dialog, reloads on success | Ctrl |
| BC-BIZ-10 | Activate: RateContractService::activate() checks status=draft (throws InvalidArgumentException if not draft), checks items count > 0 (throws DomainException if no items). Redirects back with success/error | Service |
| BC-BIZ-11 | Edit page blocked: abort(403) if status=active — "Active contracts cannot be edited." | Ctrl |
| BC-BIZ-12 | Update: RateContractService::update() blocks if status=active (DomainException). Items not updated here — managed via AJAX endpoints. Redirects to list | Service |
| BC-BIZ-13 | Delete: RateContractService::delete() blocks if status=active (DomainException). Cascade soft-deletes items via items()->delete(). Redirects to list | Service |
| BC-BIZ-14 | Search: by name/contract_number, filter by status (is_active All/Active/Inactive) | View |
| BC-BIZ-15 | Empty state: "No Rate Contracts Found" with handshake icon | View |
| BC-BIZ-16 | Pagination: appends tab=rate-contracts to pagination links | View |
| BC-BIZ-17 | Status lifecycle: draft → active (via activate) → expired (via service::expire or auto) OR cancelled (via service::cancel). Active cannot be edited or deleted | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Activate contract with no items → DomainException "cannot be activated with no items" | Service |
| BC-EDG-02 | Activate already-active contract → InvalidArgumentException | Service |
| BC-EDG-03 | Edit active contract → abort 403 | Ctrl |
| BC-EDG-04 | Delete active contract → DomainException | Service |
| BC-EDG-05 | Duplicate item in same contract (same item_id) → unique composite constraint (rate_contract_id, item_id) | DDL |
| BC-EDG-06 | valid_to before valid_from → after_or_equal validation error | FR |
| BC-EDG-07 | Duplicate contract_number → unique validation error | FR |
| BC-EDG-08 | Invalid vendor_id → exists:vnd_vendors validation error | FR (cross-module) |
| BC-EDG-09 | Invalid item_id → exists:inv_stock_items validation error | FR |
| BC-EDG-10 | Store with zero items (empty array) → items required min:1 validation error | FR |
| BC-EDG-11 | Cancel already-cancelled contract → InvalidArgumentException via expire/cancel | Service |
| BC-EDG-12 | Cancel already-expired contract → InvalidArgumentException via cancel | Service |
| BC-EDG-13 | Expire non-active contract → InvalidArgumentException via expire | Service |
| BC-EDG-14 | Items table shows "Locked" text instead of Edit/Delete buttons when status != draft | View |

---

## 2. Test Case List

### Screen 1: Vendor Contracts Tab (GET /inventory/vendor-contracts)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P10 | Positive | View | Combined page: 2 tabs — Rate Contracts (default active), Item-Vendor Links | Tabs | test_inv_rc_10 | Automated |
| TC-INVRC-P11 | Positive | View | Rate Contracts tab: card list — contract_number (link), vendor name, validity dates, status badge (draft/active/expired/cancelled), items_count badge, Activate button (draft only), actions | Rendered | test_inv_rc_11 | Automated |
| TC-INVRC-P12 | Positive | View | Search by contract_number/vendor, filter by is_active status | Filters | test_inv_rc_12 | Automated |
| TC-INVRC-P13 | Positive | View | Create button opens modal with all fields (Vendor, Valid From/To, Contract Number, Remarks, First Item section) | Modal | test_inv_rc_13 | Automated |
| TC-INVRC-P14 | Positive | View | Create modal: info alert about adding more items on detail page | Alert | test_inv_rc_14 | Automated |
| TC-INVRC-P15 | Positive | View | Empty state: "No Rate Contracts Found" with handshake icon | Empty | test_inv_rc_15 | Automated |
| TC-INVRC-P16 | Positive | View | Pagination appends tab=rate-contracts query param | Paginated | test_inv_rc_16 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P30 | Positive | View | Create modal: Vendor select (required), Valid From (date, required), Valid To (date, required), Contract Number (optional), Remarks, First Item section (item_id, agreed_rate, min_qty, max_qty) | Fields | test_inv_rc_30 | Automated |
| TC-INVRC-P31 | Positive | Ctrl | Valid store with 1 item: creates contract with status=draft, items created, activity logged, redirects to show | Created draft | test_inv_rc_31 | Automated |
| TC-INVRC-P32 | Positive | Ctrl | Store with contract_number set → saved | Created | test_inv_rc_32 | Automated |
| TC-INVRC-N33 | Negative | Val | Missing vendor_id → required error | Error | test_inv_rc_33 | Automated |
| TC-INVRC-N34 | Negative | Val | Invalid vendor_id (non-existent) → exists:vnd_vendors error | Error | test_inv_rc_34 | Automated |
| TC-INVRC-N35 | Negative | Val | Missing valid_from → required error | Error | test_inv_rc_35 | Automated |
| TC-INVRC-N36 | Negative | Val | Missing valid_to → required error | Error | test_inv_rc_36 | Automated |
| TC-INVRC-N37 | Negative | Val | valid_to before valid_from → after_or_equal error | Error | test_inv_rc_37 | Automated |
| TC-INVRC-N38 | Negative | Val | Invalid valid_from (not a date) → date error | Error | test_inv_rc_38 | Automated |
| TC-INVRC-N39 | Negative | Val | Duplicate contract_number → unique error | Error | test_inv_rc_39 | Automated |
| TC-INVRC-N40 | Negative | Val | contract_number > 50 chars → max error | Error | test_inv_rc_40 | Automated |
| TC-INVRC-N41 | Negative | Val | No items (empty array) → items required min:1 error | Error | test_inv_rc_41 | Automated |
| TC-INVRC-N42 | Negative | Val | Invalid item_id in items[0] → exists:inv_stock_items error | Error | test_inv_rc_42 | Automated |
| TC-INVRC-N43 | Negative | Val | Missing agreed_rate in items[0] → required error | Error | test_inv_rc_43 | Automated |
| TC-INVRC-N44 | Negative | Val | Negative agreed_rate → min:0 error | Error | test_inv_rc_44 | Automated |
| TC-INVRC-N45 | Negative | Val | Negative min_qty → min:0 error | Error | test_inv_rc_45 | Automated |
| TC-INVRC-N46 | Negative | Val | remarks > 2000 chars → max error | Error | test_inv_rc_46 | Automated |
| TC-INVRC-N47 | Negative | Val | Duplicate item_id in store (same item in 2 lines) → unique composite constraint (rate_contract_id, item_id) | Error | test_inv_rc_47 | Automated |

### Screen 3: Show (GET /inventory/rate-contracts/{rateContract})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P60 | Positive | View | Show: left column — Contract Details (vendor name, contract_number, valid_from/to formatted, status badge, remarks), Actions card (Activate button if draft, Back button) | Layout | test_inv_rc_60 | Automated |
| TC-INVRC-P61 | Positive | View | Right column — Agreed Item Rates table: Item Name/SKU (linked), UOM symbol, Agreed Rate (formatted ₹), Min Qty, Max Qty, Actions (Edit/Delete if draft, "Locked" text if not draft) | Table | test_inv_rc_61 | Automated |
| TC-INVRC-P62 | Positive | View | Add Item button visible only when status=draft | Conditional | test_inv_rc_62 | Automated |
| TC-INVRC-P63 | Positive | View | Empty items state: "No items added to this contract yet." with icon | Empty | test_inv_rc_63 | Automated |
| TC-INVRC-P64 | Positive | View | Draft contract: Edit button in header links to edit page | Edit link | test_inv_rc_64 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P80 | Positive | View | Edit page: form pre-populated with contract_number, vendor_id, valid_from, valid_to, remarks | Pre-filled | test_inv_rc_80 | Automated |
| TC-INVRC-P81 | Positive | View | Edit page blocked for active contract → 403 "Active contracts cannot be edited." | 403 | test_inv_rc_81 | Automated |
| TC-INVRC-P82 | Positive | Ctrl | Update draft contract fields → redirects to list with success, activity logged | Updated | test_inv_rc_82 | Automated |
| TC-INVRC-N83 | Negative | Val | Update with valid_to before valid_from → after_or_equal error | Error | test_inv_rc_83 | Automated |
| TC-INVRC-P84 | Positive | Ctrl | Update with same contract_number (own) → allowed (unique ignores self) | Allowed | test_inv_rc_84 | Automated |

### Screen 5: Activate

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P100 | Positive | View | Activate button visible on card and show page for draft contracts | Visible | test_inv_rc_100 | Automated |
| TC-INVRC-P101 | Positive | Ctrl | Activate draft contract with items → status=active, redirects with success, activity logged | Activated | test_inv_rc_101 | Automated |
| TC-INVRC-N102 | Negative | Biz | Activate draft contract with NO items → DomainException, redirect with error | Blocked | test_inv_rc_102 | Automated |
| TC-INVRC-N103 | Negative | Biz | Activate already-active contract → InvalidArgumentException | Blocked | test_inv_rc_103 | Automated |
| TC-INVRC-N104 | Negative | Biz | Activate expired or cancelled contract → InvalidArgumentException | Blocked | test_inv_rc_104 | Automated |

### Screen 6: Contract Items CRUD (AJAX)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P120 | Positive | View | Add Item modal: Stock Item (Select2), Agreed Rate (required), Min Qty, Max Qty | Modal | test_inv_rc_120 | Automated |
| TC-INVRC-P121 | Positive | Ctrl | Store item via AJAX POST → JSON {status:true, message, data}, page reloads | Added | test_inv_rc_121 | Automated |
| TC-INVRC-P122 | Positive | Ctrl | Update item via AJAX PUT → JSON {status:true, message, data}, page reloads | Updated | test_inv_rc_122 | Automated |
| TC-INVRC-P123 | Positive | Ctrl | Delete item via AJAX DELETE → JSON {status:true, message}, confirm dialog, page reloads | Removed | test_inv_rc_123 | Automated |
| TC-INVRC-P124 | Positive | Ctrl | Items list (JSON): GET items endpoint returns items with stockItem.uom loaded | JSON | test_inv_rc_124 | Automated |
| TC-INVRC-N125 | Negative | Val | Store item: invalid item_id → 422 validation error | Error | test_inv_rc_125 | Automated |
| TC-INVRC-N126 | Negative | Val | Store item: negative agreed_rate → min:0 error | Error | test_inv_rc_126 | Automated |
| TC-INVRC-N127 | Negative | Val | Duplicate item_id in same contract → unique composite constraint | Error | test_inv_rc_127 | Automated |
| TC-INVRC-N128 | Negative | Biz | Add/edit item on active contract → no Add Item button visible, no Edit/Delete buttons (Locked) | Locked | test_inv_rc_128 | Automated |

### Screen 7: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P140 | Positive | Ctrl | Delete draft contract → soft-deleted, items cascade soft-deleted, activity logged | Deleted | test_inv_rc_140 | Automated |
| TC-INVRC-N141 | Negative | Biz | Delete active contract → DomainException "Active rate contract cannot be deleted" | Blocked | test_inv_rc_141 | Automated |
| TC-INVRC-P142 | Positive | View | Trash page: table with Contract No, Valid Until, Deleted At, restore/force-delete actions | Table | test_inv_rc_142 | Automated |
| TC-INVRC-P143 | Positive | Ctrl | Restore from trash → success, items restored (cascade) | Restored | test_inv_rc_143 | Automated |
| TC-INVRC-P144 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_rc_144 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVRC-P200 | Positive | Auth | RC CRUD with correct permissions → 200 | 200 | test_inv_rc_200 | Automated |
| TC-INVRC-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_rc_201 | Automated |
| TC-INVRC-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_rc_202 | Automated |
| TC-INVRC-N203 | Negative | Auth | Without view → 403 on show/items | 403 | test_inv_rc_203 | Automated |
| TC-INVRC-N204 | Negative | Auth | Without update → 403 on edit/update/activate/addItem/updateItem | 403 | test_inv_rc_204 | Automated |
| TC-INVRC-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete/destroyItem | 403 | test_inv_rc_205 | Automated |
