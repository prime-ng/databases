# inv_PurchaseOrder — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Purchase Orders (CRUD + Status Lifecycle + Items + Amount Calculations)
**DB scope:** TENANT-side (`inv_purchase_orders`, `inv_purchase_order_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_purchase_orders` (Layer 6) · **Module URL prefix:** `/inventory/procurement?tab=pos`
**Test file:** `inv_PurchaseOrder_TestCas.php`
**Tab:** POs (third tab of Procurement page)

Controllers:
- `PurchaseOrderController` — CRUD + approve/send/receive + convertFromPr + trashed lifecycle
- `InvMenuController::procurement()` — loads POs + dropdowns for all 4 tabs

Service:
- `PurchaseOrderService` — create, update, delete, convertPrToPo, generate numbers

Routes (`inventory.` prefix):
- `GET /inventory/procurement` — combined tab page
- `GET /inventory/pos` — index (redirects to procurement tab)
- `POST /inventory/pos` — store (with nested items array)
- `GET /inventory/pos/{purchaseOrder}` — show
- `GET /inventory/pos/{purchaseOrder}/edit` — edit
- `PUT /inventory/pos/{purchaseOrder}` — update
- `DELETE /inventory/pos/{purchaseOrder}` — soft delete (guarded if not draft)
- `PATCH /inventory/pos/{purchaseOrder}/approve` — approve (draft→approved)
- `PATCH /inventory/pos/{purchaseOrder}/send` — send (approved→sent)
- `PATCH /inventory/pos/{purchaseOrder}/receive` — receive (sent→received)
- `POST /inventory/pos/convert-from-pr` — convert approved PR to PO
- `GET /inventory/pos/{purchaseOrder}/items` — get PO items (JSON, for GRN creation)
- `GET /inventory/pos/trash/view` — trashed
- `GET /inventory/pos/{id}/restore` — restore
- `DELETE /inventory/pos/{id}/force-delete` — force delete

**DDL reference:** `inv_purchase_orders` (Layer 6), `inv_purchase_order_items` (Layer 7)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_purchase_orders`: id (BIGINT PK AI), po_number (VARCHAR 50 NOT NULL UNIQUE), vendor_id (INT UNSIGNED NOT NULL), pr_id (BIGINT UNSIGNED NULL), quotation_id (BIGINT UNSIGNED NULL), order_date (DATE NOT NULL), expected_delivery_date (DATE NULL), status (ENUM draft/sent/partial/received/cancelled/closed DEFAULT draft), total_amount (DECIMAL 15,2 NOT NULL DEFAULT 0), tax_amount (DECIMAL 15,2 NOT NULL DEFAULT 0), discount_amount (DECIMAL 15,2 NOT NULL DEFAULT 0), net_amount (DECIMAL 15,2 NOT NULL DEFAULT 0), approved_by (BIGINT UNSIGNED NULL), approval_threshold_amount (DECIMAL 15,2 NULL), terms_and_conditions (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: pr_id → inv_purchase_requisitions.id SET NULL, quotation_id → inv_quotations.id SET NULL; vendor_id FK commented | DDL |
| BC-DB-02 | Table `inv_purchase_order_items`: id (BIGINT PK AI), po_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), ordered_qty (DECIMAL 15,3 NOT NULL), received_qty (DECIMAL 15,3 NOT NULL DEFAULT 0), unit_price (DECIMAL 15,2 NOT NULL), tax_rate_id (BIGINT UNSIGNED NULL), discount_percent (DECIMAL 5,2 NOT NULL DEFAULT 0), total_amount (DECIMAL 15,2 NOT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: po_id → inv_purchase_orders.id CASCADE, item_id → inv_stock_items.id; tax_rate_id FK commented | DDL |
| BC-DB-03 | Model `PurchaseOrder`: table inv_purchase_orders, SoftDeletes, fillable 15 fields, casts: order_date/expected_delivery_date→date, is_active→boolean, status→string, amount fields→decimal. Relations: vendor() BelongsTo (Vendor::class), purchaseRequisition() BelongsTo (PurchaseRequisition::class, 'pr_id'), quotation() BelongsTo (Quotation::class, 'quotation_id'), items() HasMany (PurchaseOrderItem), approvedBy() BelongsTo (User::class) | Model |
| BC-DB-04 | Model `PurchaseOrderItem`: table inv_purchase_order_items, SoftDeletes. Casts: ordered_qty/received_qty→decimal:3, unit_price/discount_percent/total_amount→decimal. Relations: purchaseOrder() BelongsTo, stockItem() BelongsTo (StockItem::class), taxRate() BelongsTo (TaxRate::class). Alias: item() for stockItem | Model |

### BC-VAL — Validation (StorePurchaseOrderRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `vendor_id` required exists:vnd_vendors,id | FR |
| BC-VAL-02 | `pr_id` nullable exists:inv_purchase_requisitions,id | FR |
| BC-VAL-03 | `quotation_id` nullable exists:inv_quotations,id | FR |
| BC-VAL-04 | `order_date` required date | FR |
| BC-VAL-05 | `expected_delivery_date` nullable date after_or_equal:order_date | FR |
| BC-VAL-06 | `terms_and_conditions` nullable string max:5000 | FR |
| BC-VAL-07 | `items` required array min:1 | FR |
| BC-VAL-08 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-09 | `items.*.ordered_qty` required numeric min:0.001 | FR |
| BC-VAL-10 | `items.*.unit_price` required numeric min:0 | FR |
| BC-VAL-11 | `items.*.discount_percent` nullable numeric min:0 max:100 | FR |
| BC-VAL-12 | `items.*.tax_rate_id` nullable integer exists:acc_tax_rates,id | FR |

### BC-AUTH — Authorization (PurchaseOrderPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.purchase-order.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.purchase-order.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.purchase-order.view` | Policy |
| BC-AUTH-04 | edit/update/approve/send/receive gate `tenant.inventory.purchase-order.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.purchase-order.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Procurement page: POs is third tab | MenuCtrl |
| BC-BIZ-02 | POs tab: card list — po_number (linked), vendor name, PO date, expected delivery, net amount (formatted ₹), status badge (draft/sent/partial/received/closed/cancelled), Approve/Send inline buttons (draft only), actions | View |
| BC-BIZ-03 | Create via modal: Vendor select (required), PO Date (required, default today), Expected Delivery Date, Source PR select, Source Quotation select, Terms & Notes, First Item section (item_id, ordered_qty, unit_price, discount_percent, tax_rate_id) | View |
| BC-BIZ-04 | Store via PurchaseOrderService::create(): generates po_number via generatePoNumber(), sets status=draft, creates items, calculates amounts (total, discount, tax, net), redirects to show | Service |
| BC-BIZ-05 | Show page: PO header (number, vendor, PO date, expected delivery, status badge, terms, amount summary) + Items table (item, qty, rate, disc %, tax %, line total) | View |
| BC-BIZ-06 | Approve: sets status=approved, records approved_by. Cannot approve non-draft | Ctrl |
| BC-BIZ-07 | Send: sets status=sent. Vendor is notified/PO dispatched. Requires approved status | Ctrl |
| BC-BIZ-08 | Receive: sets status=received (when all items received) or partial. Usually triggered via GRN acceptance | Service |
| BC-BIZ-09 | Convert PR to PO: PurchaseOrderService::convertPrToPo() — copies PR header + items to new PO, pre-fills rates from rate contracts if available, redirects to edit page for adjustments | Service |
| BC-BIZ-10 | Get PO Items (JSON): returns items for a PO with stock_item.name, ordered_qty, received_qty, unit_price. Used by GRN create modal to pre-fill | Ctrl |
| BC-BIZ-11 | Search: by po_number/vendor, filter by status (All/Draft/Sent/Partial/Received/Closed/Cancelled) | View |
| BC-BIZ-12 | Empty state: "No Purchase Orders Found" with cart-shopping icon | View |
| BC-BIZ-13 | Pagination: appends tab=pos to pagination links | View |
| BC-BIZ-14 | Status lifecycle: draft → approved → sent → partial/received → closed. Or draft→cancelled | Ctrl/Service |
| BC-BIZ-15 | Approve/Send inline buttons shown on draft POs in the card list | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | expected_delivery_date before order_date → after_or_equal validation error | FR |
| BC-EDG-02 | Duplicate po_number → unique DB constraint | DDL |
| BC-EDG-03 | Invalid vendor_id → exists:vnd_vendors error | FR (cross-module) |
| BC-EDG-04 | Invalid pr_id → exists:inv_purchase_requisitions error | FR |
| BC-EDG-05 | Invalid quotation_id → exists:inv_quotations error | FR |
| BC-EDG-06 | Invalid tax_rate_id → exists:acc_tax_rates error | FR (cross-module) |
| BC-EDG-07 | Zero unit_price → min:0 error | FR |
| BC-EDG-08 | Discount > 100% → max:100 error | FR |
| BC-EDG-09 | Store with no items → items required min:1 error | FR |
| BC-EDG-10 | Negative ordered_qty → min:0.001 error | FR |
| BC-EDG-11 | Amount calculations: total_amount = sum(item total), discount_amount = sum(item disc), tax_amount = sum(item tax), net_amount = total - discount + tax | Service |
| BC-EDG-12 | Delete non-draft PO → guarded (policy may block) | Ctrl |

---

## 2. Test Case List

### Screen 1: Procurement Tab / POs List (GET /inventory/procurement?tab=pos)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P10 | Positive | View | POs tab active via ?tab=pos | Active | test_inv_po_10 | Automated |
| TC-INVPO-P11 | Positive | View | Card list: po_number (link), vendor name, PO date, expected delivery, net amount formatted ₹, status badge, Approve/Send inline buttons (draft only), actions | Rendered | test_inv_po_11 | Automated |
| TC-INVPO-P12 | Positive | View | Search by po_number/vendor, filter by status dropdown (All/Draft/Sent/Partial/Received/Closed/Cancelled) | Filters | test_inv_po_12 | Automated |
| TC-INVPO-P13 | Positive | View | Create button opens modal with all fields | Modal | test_inv_po_13 | Automated |
| TC-INVPO-P14 | Positive | View | Empty state: "No Purchase Orders Found" with cart-shopping icon | Empty | test_inv_po_14 | Automated |
| TC-INVPO-P15 | Positive | View | Pagination appends tab=pos query param | Paginated | test_inv_po_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P30 | Positive | View | Create modal: Vendor (required), PO Date (required, default today), Expected Delivery, Source PR, Source Quotation, Terms, First Item section (item_id, ordered_qty, unit_price, disc %, tax_rate) | Fields | test_inv_po_30 | Automated |
| TC-INVPO-P31 | Positive | Ctrl | Valid store with 1 item: creates PO with generated po_number, status=draft, amounts calculated, items created, redirects to show | Created draft | test_inv_po_31 | Automated |
| TC-INVPO-P32 | Positive | Ctrl | Store with PR reference → linked | Created | test_inv_po_32 | Automated |
| TC-INVPO-P33 | Positive | Ctrl | Store with Quotation reference → linked | Created | test_inv_po_33 | Automated |
| TC-INVPO-P34 | Positive | Ctrl | Amount calculation: total_amount = Σ(ordered_qty × unit_price) per item | Calculated | test_inv_po_34 | Automated |
| TC-INVPO-P35 | Positive | Ctrl | Amount calculation with discount and tax → correct net_amount | Calculated | test_inv_po_35 | Automated |
| TC-INVPO-N36 | Negative | Val | Missing vendor_id → required error | Error | test_inv_po_36 | Automated |
| TC-INVPO-N37 | Negative | Val | Invalid vendor_id → exists:vnd_vendors error | Error | test_inv_po_37 | Automated |
| TC-INVPO-N38 | Negative | Val | Missing order_date → required error | Error | test_inv_po_38 | Automated |
| TC-INVPO-N39 | Negative | Val | expected_delivery_date before order_date → after_or_equal error | Error | test_inv_po_39 | Automated |
| TC-INVPO-N40 | Negative | Val | No items → items required min:1 error | Error | test_inv_po_40 | Automated |
| TC-INVPO-N41 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_po_41 | Automated |
| TC-INVPO-N42 | Negative | Val | Missing ordered_qty → required error | Error | test_inv_po_42 | Automated |
| TC-INVPO-N43 | Negative | Val | Zero ordered_qty → min:0.001 error | Error | test_inv_po_43 | Automated |
| TC-INVPO-N44 | Negative | Val | Missing unit_price → required error | Error | test_inv_po_44 | Automated |
| TC-INVPO-N45 | Negative | Val | Negative unit_price → min:0 error | Error | test_inv_po_45 | Automated |
| TC-INVPO-N46 | Negative | Val | Discount > 100% → max:100 error | Error | test_inv_po_46 | Automated |
| TC-INVPO-N47 | Negative | Val | Invalid tax_rate_id → exists:acc_tax_rates error | Error | test_inv_po_47 | Automated |
| TC-INVPO-N48 | Negative | Val | Invalid pr_id → exists:inv_purchase_requisitions error | Error | test_inv_po_48 | Automated |
| TC-INVPO-N49 | Negative | Val | Invalid quotation_id → exists:inv_quotations error | Error | test_inv_po_49 | Automated |

### Screen 3: Show (GET /inventory/pos/{purchaseOrder})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P70 | Positive | View | Show: PO header — po_number, vendor, PO date, expected delivery, status badge, terms, amount summary (total, discount, tax, net) | Layout | test_inv_po_70 | Automated |
| TC-INVPO-P71 | Positive | View | Items table: Item Name/SKU, Ordered Qty, Received Qty, Unit Price (formatted ₹), Disc %, Tax %, Line Total | Table | test_inv_po_71 | Automated |
| TC-INVPO-P72 | Positive | View | Action buttons based on status: Approve (draft), Send (approved), Mark Received (sent) | Conditional | test_inv_po_72 | Automated |

### Screen 4: Status Transitions (Approve / Send / Receive)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P90 | Positive | View | Approve button on draft PO card (inline) and show page | Visible | test_inv_po_90 | Automated |
| TC-INVPO-P91 | Positive | Ctrl | Approve draft PO → status=approved, approved_by set, redirects | Approved | test_inv_po_91 | Automated |
| TC-INVPO-P92 | Positive | View | Send button on approved PO | Visible | test_inv_po_92 | Automated |
| TC-INVPO-P93 | Positive | Ctrl | Send approved PO → status=sent, redirects | Sent | test_inv_po_93 | Automated |
| TC-INVPO-N94 | Negative | Biz | Approve non-draft (e.g. sent/partial) → blocked | Blocked | test_inv_po_94 | Automated |
| TC-INVPO-N95 | Negative | Biz | Send non-approved PO → blocked | Blocked | test_inv_po_95 | Automated |

### Screen 5: Convert PR to PO

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P110 | Positive | Ctrl | Convert approved PR to PO → PO created with PR items, redirects to edit page for adjustments | Created draft | test_inv_po_110 | Automated |
| TC-INVPO-P111 | Positive | Ctrl | Convert PR with rate contract items → rates pre-filled from rate contract | Pre-filled | test_inv_po_111 | Automated |
| TC-INVPO-N112 | Negative | Biz | Convert non-approved PR → blocked | Blocked | test_inv_po_112 | Automated |

### Screen 6: Get PO Items (JSON endpoint for GRN)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P130 | Positive | Ctrl | GET /inventory/pos/{po}/items → JSON array: {id, item_id, item_name, ordered_qty, received_qty, unit_price} | JSON | test_inv_po_130 | Automated |
| TC-INVPO-N131 | Negative | Ctrl | Invalid PO id → 404 | 404 | test_inv_po_131 | Automated |

### Screen 7: Delete + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P150 | Positive | Ctrl | Delete draft PO → soft-deleted, items cascade deleted | Deleted | test_inv_po_150 | Automated |
| TC-INVPO-N151 | Negative | Biz | Delete sent/partial/received PO → blocked | Blocked | test_inv_po_151 | Automated |
| TC-INVPO-P152 | Positive | View | Trash page with restore/force-delete | Table | test_inv_po_152 | Automated |
| TC-INVPO-P153 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_po_153 | Automated |
| TC-INVPO-P154 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_po_154 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPO-P200 | Positive | Auth | PO CRUD with correct permissions → 200 | 200 | test_inv_po_200 | Automated |
| TC-INVPO-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_po_201 | Automated |
| TC-INVPO-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_po_202 | Automated |
| TC-INVPO-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_po_203 | Automated |
| TC-INVPO-N204 | Negative | Auth | Without update → 403 on edit/update/approve/send/receive | 403 | test_inv_po_204 | Automated |
| TC-INVPO-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_po_205 | Automated |
