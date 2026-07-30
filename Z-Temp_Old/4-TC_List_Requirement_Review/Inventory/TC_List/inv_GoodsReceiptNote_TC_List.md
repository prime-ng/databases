# inv_GoodsReceiptNote — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Goods Receipt Notes (CRUD + QC Inspection + Stock Posting + Asset Creation)
**DB scope:** TENANT-side (`inv_goods_receipt_notes`, `inv_grn_items`, `inv_stock_ledger`) · **Test style:** Browser Dusk
**Primary table:** `inv_goods_receipt_notes` (Layer 7) · **Module URL prefix:** `/inventory/procurement?tab=grns`
**Test file:** `inv_GoodsReceiptNote_TestCas.php`
**Tab:** GRNs (fourth tab of Procurement page)

Controllers:
- `GrnController` — CRUD + inspect + accept + reject + trashed lifecycle
- `InvMenuController::procurement()` — loads GRNs + dropdowns for all 4 tabs

Service:
- `GrnPostingService` — acceptGrn, generateGrnNumber, createAssetRecords, autoTransitionPo
- `StockLedgerService` — postEntry (inward stock entry)
- `StockValuationService` — updateLastPurchaseCost
- `ReorderAlertService` — checkAndDispatch

Routes (`inventory.` prefix):
- `GET /inventory/procurement` — combined tab page
- `GET /inventory/grns` — index (redirects to procurement tab)
- `POST /inventory/grns` — store (with nested items)
- `GET /inventory/grns/{goodsReceiptNote}` — show
- `GET /inventory/grns/{goodsReceiptNote}/edit` — edit (redirects to show)
- `PUT /inventory/grns/{goodsReceiptNote}` — update (only received status)
- `DELETE /inventory/grns/{goodsReceiptNote}` — soft delete (only received status)
- `PATCH /inventory/grns/{goodsReceiptNote}/inspect` — QC inspection (received→inspected)
- `PATCH /inventory/grns/{goodsReceiptNote}/accept` — accept stock (inspected→accepted)
- `POST /inventory/grns/{goodsReceiptNote}/reject` — reject GRN (received/inspected→rejected)
- `GET /inventory/grns/trash/view` — trashed
- `GET /inventory/grns/{id}/restore` — restore
- `DELETE /inventory/grns/{id}/force-delete` — force delete

**DDL reference:** `inv_goods_receipt_notes` (Layer 7), `inv_grn_items` (Layer 8)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_goods_receipt_notes`: id (BIGINT PK AI), grn_number (VARCHAR 50 NOT NULL UNIQUE), po_id (BIGINT UNSIGNED NOT NULL), vendor_id (INT UNSIGNED NOT NULL), receipt_date (DATE NOT NULL), godown_id (BIGINT UNSIGNED NOT NULL), status (ENUM draft/inspected/accepted/partial/rejected DEFAULT draft), qc_status (ENUM pending/passed/failed/partial DEFAULT pending), qc_notes (TEXT NULL), received_by (BIGINT UNSIGNED NOT NULL), voucher_id (BIGINT UNSIGNED NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: po_id → inv_purchase_orders.id, godown_id → inv_godowns.id; vendor_id/voucher_id FKs commented | DDL |
| BC-DB-02 | Table `inv_grn_items`: id (BIGINT PK AI), grn_id (BIGINT UNSIGNED NOT NULL), po_item_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), received_qty (DECIMAL 15,3 NOT NULL), accepted_qty (DECIMAL 15,3 NOT NULL), rejected_qty (DECIMAL 15,3 NOT NULL DEFAULT 0), unit_cost (DECIMAL 15,2 NOT NULL), batch_number (VARCHAR 50 NULL), expiry_date (DATE NULL), qc_remarks (VARCHAR 255 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: grn_id → inv_goods_receipt_notes.id CASCADE, po_item_id → inv_purchase_order_items.id, item_id → inv_stock_items.id | DDL |
| BC-DB-03 | Model `GoodsReceiptNote`: table inv_goods_receipt_notes, SoftDeletes, fillable 11 fields, casts: receipt_date→date, is_active→boolean, status/qc_status→string. Relations: purchaseOrder() BelongsTo (PurchaseOrder::class, 'po_id'), godown() BelongsTo (Godown::class), vendor() BelongsTo (Vendor::class), receivedBy() BelongsTo (User::class, 'received_by'), items() HasMany (GrnItem) | Model |
| BC-DB-04 | Model `GrnItem`: table inv_grn_items, SoftDeletes. Casts: received_qty/accepted_qty/rejected_qty→decimal:3, unit_cost→decimal:2, expiry_date→date, is_active→boolean. Relations: goodsReceiptNote() BelongsTo, purchaseOrderItem() BelongsTo (PurchaseOrderItem::class, 'po_item_id'), stockItem() BelongsTo (StockItem::class, 'item_id'), poItem() BelongsTo (alias), assets() HasMany (Asset::class) | Model |

### BC-VAL — Validation (StoreGrnRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `po_id` required integer exists:inv_purchase_orders,id | FR |
| BC-VAL-02 | `vendor_id` required integer exists:vnd_vendors,id | FR |
| BC-VAL-03 | `grn_number` nullable string max:50 unique:inv_goods_receipt_notes,grn_number (ignores own ID on update) | FR |
| BC-VAL-04 | `receipt_date` required date | FR |
| BC-VAL-05 | `godown_id` required integer exists:inv_godowns,id | FR |
| BC-VAL-06 | `qc_notes` nullable string max:2000 | FR |
| BC-VAL-07 | `items` required array min:1 | FR |
| BC-VAL-08 | `items.*.po_item_id` required integer exists:inv_purchase_order_items,id | FR |
| BC-VAL-09 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-10 | `items.*.received_qty` required numeric min:0.01 | FR |
| BC-VAL-11 | `items.*.accepted_qty` required numeric min:0 | FR |
| BC-VAL-12 | `items.*.rejected_qty` required numeric min:0 | FR |
| BC-VAL-13 | `items.*.unit_cost` required numeric min:0 | FR |
| BC-VAL-14 | `items.*.batch_number` nullable string max:50 | FR |
| BC-VAL-15 | `items.*.expiry_date` nullable date | FR |
| BC-VAL-16 | `items.*.qc_remarks` nullable string max:255 | FR |
| BC-VAL-17 | Custom: accepted_qty + rejected_qty must equal received_qty (BR-INV-006) — validated in withValidator after() hook | FR |

### BC-AUTH — Authorization (GoodsReceiptNotePolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.grn.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.grn.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.grn.view` | Policy |
| BC-AUTH-04 | edit/update/inspect gate `tenant.inventory.grn.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.grn.delete` | Policy |
| BC-AUTH-06 | accept gate `tenant.inventory.grn.accept` (separate permission for stock posting) | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Procurement page: GRNs is fourth tab | MenuCtrl |
| BC-BIZ-02 | GRNs tab: card list — grn_number (linked), vendor name, PO reference (linked), GRN date, godown, status badge (received/inspected/accepted/rejected), Inspect/Accept inline buttons (conditional), actions | View |
| BC-BIZ-03 | Create via modal: PO select (filtered to sent/partial POs only), Vendor select, GRN Date (required, default today), Godown select (required), First Item section (po_item_id, item_id, received_qty, accepted_qty, rejected_qty, unit_cost, batch_number, expiry_date). JS: PO select fetches items via AJAX, auto-fills stock item and unit rate | View |
| BC-BIZ-04 | Store: creates GRN with generated grn_number (GRN-YYYY-NNNN), status=draft (→received), received_by=auth user, creates items, redirects to show | Ctrl |
| BC-BIZ-05 | Show page: GRN header (number, vendor, PO reference, GRN date, godown, status badge, qc_notes) + Items table (item, received_qty, accepted_qty, rejected_qty, unit_cost, batch, expiry, qc_remarks) | View |
| BC-BIZ-06 | Inspect: updates items with accepted_qty, rejected_qty, batch_number, expiry_date, qc_remarks. Sets status=inspected. Validates BR-INV-006 (accepted+rejected=received) | Ctrl |
| BC-BIZ-07 | Accept (via GrnPostingService::acceptGrn()): runs in DB transaction. Validates QC totals (BR-INV-006) and PO balance (BR-INV-007). Posts stock ledger entry (inward) for accepted qty. Updates PO item received_qty. Updates vendor last purchase cost. Creates asset records for asset-type items (BR-INV-012). Auto-transitions PO status (BR-INV-005). Dispatches reorder alert (BR-INV-011). Fires GrnAccepted event for Accounting module | Service |
| BC-BIZ-08 | Reject: sets status=rejected, requires qc_notes (required string max:500). Allowed from received or inspected status | Ctrl |
| BC-BIZ-09 | Update: only allowed when status=received (pre-inspection). Deletes all items and recreates | Ctrl |
| BC-BIZ-10 | Delete: only allowed when status=received (pre-inspection). Items cascade deleted via DB | Ctrl |
| BC-BIZ-11 | Search: by grn_number/vendor, filter by status (All/Draft/Verified/Closed — limited view options) | View |
| BC-BIZ-12 | Empty state: "No GRNs Found" with boxes-stacked icon | View |
| BC-BIZ-13 | Pagination: appends tab=grns to pagination links | View |
| BC-BIZ-14 | Status lifecycle: draft → received (via store) → inspected (via inspect) → accepted (via accept with stock posting) OR rejected. Status from view: received/inspected/accepted/rejected | Ctrl/Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | accepted_qty + rejected_qty ≠ received_qty → custom validation error in StoreGrnRequest withValidator hook (BR-INV-006) | FR |
| BC-EDG-02 | accepted_qty + rejected_qty ≠ received_qty → DomainException in GrnPostingService::validateQcTotals (BR-INV-006) | Service |
| BC-EDG-03 | received_qty exceeds PO balance → DomainException in GrnPostingService::validateReceivedVsPo (BR-INV-007) | Service |
| BC-EDG-04 | Accept already-accepted GRN → InvalidArgumentException | Service |
| BC-EDG-05 | Inspect non-received GRN → abort 422 | Ctrl |
| BC-EDG-06 | Accept non-inspected GRN → abort 422 | Ctrl |
| BC-EDG-07 | Update non-received GRN (inspected/accepted) → abort 422 | Ctrl |
| BC-EDG-08 | Delete non-received GRN → abort 422 | Ctrl |
| BC-EDG-09 | Reject with missing qc_notes → validation error (required) | FR |
| BC-EDG-10 | Asset-type items → asset records created (1 per integer unit of accepted_qty) with tag ASSET-YYYY-NNNNN (BR-INV-012) | Service |
| BC-EDG-11 | PO auto-transition: all items fully received → status=received; some received → status=partial (BR-INV-005) | Service |
| BC-EDG-12 | Duplicate grn_number → unique validation error | FR |
| BC-EDG-13 | Invalid po_id → exists:inv_purchase_orders error | FR |
| BC-EDG-14 | Invalid godown_id → exists:inv_godowns error | FR |
| BC-EDG-15 | Invalid po_item_id → exists:inv_purchase_order_items error | FR |
| BC-EDG-16 | Zero received_qty → min:0.01 error | FR |
| BC-EDG-17 | Negative unit_cost → min:0 error | FR |

---

## 2. Test Case List

### Screen 1: Procurement Tab / GRNs List (GET /inventory/procurement?tab=grns)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P10 | Positive | View | GRNs tab active via ?tab=grns | Active | test_inv_grn_10 | Automated |
| TC-INVGRN-P11 | Positive | View | Card list: grn_number (link), vendor name, PO reference (linked), GRN date, godown, status badge (received/inspected/accepted/rejected), Inspect/Accept inline buttons (conditional), actions | Rendered | test_inv_grn_11 | Automated |
| TC-INVGRN-P12 | Positive | View | Search by grn_number/vendor, filter by status dropdown | Filters | test_inv_grn_12 | Automated |
| TC-INVGRN-P13 | Positive | View | Create button opens modal with PO select (sent/partial only), Vendor select, GRN Date, Godown select, First Item section with dynamic PO items | Modal | test_inv_grn_13 | Automated |
| TC-INVGRN-P14 | Positive | View | Empty state: "No GRNs Found" with boxes-stacked icon | Empty | test_inv_grn_14 | Automated |
| TC-INVGRN-P15 | Positive | View | Pagination appends tab=grns query param | Paginated | test_inv_grn_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P30 | Positive | View | Create modal: PO select (only sent/partial POs), Vendor, GRN Date (default today), Godown (required), First Item section (po_item_id, item_id, received_qty, accepted_qty, rejected_qty, unit_cost, batch, expiry, qc_remarks) | Fields | test_inv_grn_30 | Automated |
| TC-INVGRN-P31 | Positive | View | JS: PO select change triggers AJAX fetch of PO items, auto-fills stock item + unit rate on po_item selection | JS | test_inv_grn_31 | Automated |
| TC-INVGRN-P32 | Positive | Ctrl | Valid store with 1 item: creates GRN with generated grn_number (GRN-YYYY-NNNN), status received, received_by=auth user, items created, redirects to show | Created | test_inv_grn_32 | Automated |
| TC-INVGRN-P33 | Positive | Ctrl | Store with batch_number and expiry_date set → saved | Created | test_inv_grn_33 | Automated |
| TC-INVGRN-N34 | Negative | Val | Missing po_id → required error | Error | test_inv_grn_34 | Automated |
| TC-INVGRN-N35 | Negative | Val | Invalid po_id → exists:inv_purchase_orders error | Error | test_inv_grn_35 | Automated |
| TC-INVGRN-N36 | Negative | Val | Missing vendor_id → required error | Error | test_inv_grn_36 | Automated |
| TC-INVGRN-N37 | Negative | Val | Missing receipt_date → required error | Error | test_inv_grn_37 | Automated |
| TC-INVGRN-N38 | Negative | Val | Missing godown_id → required error | Error | test_inv_grn_38 | Automated |
| TC-INVGRN-N39 | Negative | Val | Invalid godown_id → exists:inv_godowns error | Error | test_inv_grn_39 | Automated |
| TC-INVGRN-N40 | Negative | Val | No items → items required min:1 error | Error | test_inv_grn_40 | Automated |
| TC-INVGRN-N41 | Negative | Val | Invalid po_item_id → exists:inv_purchase_order_items error | Error | test_inv_grn_41 | Automated |
| TC-INVGRN-N42 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_grn_42 | Automated |
| TC-INVGRN-N43 | Negative | Val | Zero received_qty → min:0.01 error | Error | test_inv_grn_43 | Automated |
| TC-INVGRN-N44 | Negative | Val | Negative unit_cost → min:0 error | Error | test_inv_grn_44 | Automated |
| TC-INVGRN-N45 | Negative | Val | accepted_qty + rejected_qty ≠ received_qty → custom after validation error (BR-INV-006) | Error | test_inv_grn_45 | Automated |
| TC-INVGRN-N46 | Negative | Val | qc_remarks > 255 chars → max error | Error | test_inv_grn_46 | Automated |

### Screen 3: Show (GET /inventory/grns/{goodsReceiptNote})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P70 | Positive | View | Show: GRN header — grn_number, vendor, PO reference (linked), GRN date, godown, status badge, qc_notes | Layout | test_inv_grn_70 | Automated |
| TC-INVGRN-P71 | Positive | View | Items table: Item Name/SKU, received_qty, accepted_qty, rejected_qty, unit_cost (formatted ₹), batch, expiry date, qc_remarks | Table | test_inv_grn_71 | Automated |
| TC-INVGRN-P72 | Positive | View | Action buttons: Inspect (received), Accept (inspected), Edit (received), Delete (received), Reject (received/inspected) | Conditional | test_inv_grn_72 | Automated |

### Screen 4: Inspect (QC)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P90 | Positive | View | Inspect button visible on received GRN | Visible | test_inv_grn_90 | Automated |
| TC-INVGRN-P91 | Positive | Ctrl | Inspect with valid items → updates accepted_qty, rejected_qty, batch, expiry, qc_remarks; status=inspected | Inspected | test_inv_grn_91 | Automated |
| TC-INVGRN-N92 | Negative | Val | accepted_qty + rejected_qty ≠ received_qty → validation error (BR-INV-006) | Error | test_inv_grn_92 | Automated |
| TC-INVGRN-N93 | Negative | Biz | Inspect non-received GRN (inspected/accepted) → abort 422 | 422 | test_inv_grn_93 | Automated |

### Screen 5: Accept Stock (Posting)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P110 | Positive | View | Accept button visible on inspected GRN | Visible | test_inv_grn_110 | Automated |
| TC-INVGRN-P111 | Positive | Ctrl | Accept inspected GRN → status=accepted, stock ledger posted (inward), PO received_qty incremented, vendor last purchase cost updated, PO status auto-transitioned, event fired | Accepted | test_inv_grn_111 | Automated |
| TC-INVGRN-P112 | Positive | Ctrl | Accept GRN with asset-type items → asset records created (1 per integer unit) | Assets created | test_inv_grn_112 | Automated |
| TC-INVGRN-P113 | Positive | Ctrl | Accept GRN fully fulfills PO → PO status becomes received (BR-INV-005) | PO received | test_inv_grn_113 | Automated |
| TC-INVGRN-P114 | Positive | Ctrl | Accept GRN partially fulfills PO → PO status becomes partial (BR-INV-005) | PO partial | test_inv_grn_114 | Automated |
| TC-INVGRN-N115 | Negative | Biz | Accept non-inspected GRN (received/draft) → abort 422 | 422 | test_inv_grn_115 | Automated |
| TC-INVGRN-N116 | Negative | Biz | Accept already-accepted GRN → InvalidArgumentException | Blocked | test_inv_grn_116 | Automated |
| TC-INVGRN-N117 | Negative | Biz | Accept with accepted_qty + rejected_qty ≠ received_qty → DomainException (BR-INV-006) | Blocked | test_inv_grn_117 | Automated |
| TC-INVGRN-N118 | Negative | Biz | Accept with received_qty > PO balance → DomainException (BR-INV-007) | Blocked | test_inv_grn_118 | Automated |
| TC-INVGRN-N119 | Negative | Auth | Accept without `tenant.inventory.grn.accept` permission → 403 | 403 | test_inv_grn_119 | Automated |

### Screen 6: Reject

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P140 | Positive | View | Reject button visible on received/inspected GRN | Visible | test_inv_grn_140 | Automated |
| TC-INVGRN-P141 | Positive | Ctrl | Reject received GRN with qc_notes → status=rejected | Rejected | test_inv_grn_141 | Automated |
| TC-INVGRN-N142 | Negative | Biz | Reject without qc_notes → validation error (required) | Error | test_inv_grn_142 | Automated |
| TC-INVGRN-N143 | Negative | Biz | Reject accepted GRN → abort 422 (not in allowed statuses) | 422 | test_inv_grn_143 | Automated |

### Screen 7: Update + Delete (Guarded)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P160 | Positive | Ctrl | Update received GRN → deletes old items, recreates with new data, redirects with success | Updated | test_inv_grn_160 | Automated |
| TC-INVGRN-N161 | Negative | Biz | Update inspected/accepted GRN → abort 422 "Only received GRNs can be edited" | 422 | test_inv_grn_161 | Automated |
| TC-INVGRN-P162 | Positive | Ctrl | Delete received GRN → soft-deleted, items cascade deleted | Deleted | test_inv_grn_162 | Automated |
| TC-INVGRN-N163 | Negative | Biz | Delete inspected/accepted GRN → abort 422 "Only pre-inspection GRNs can be deleted" | 422 | test_inv_grn_163 | Automated |
| TC-INVGRN-P164 | Positive | View | Trash page with restore/force-delete | Table | test_inv_grn_164 | Automated |
| TC-INVGRN-P165 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_grn_165 | Automated |
| TC-INVGRN-P166 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_grn_166 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVGRN-P200 | Positive | Auth | GRN CRUD with correct permissions → 200 | 200 | test_inv_grn_200 | Automated |
| TC-INVGRN-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_grn_201 | Automated |
| TC-INVGRN-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_grn_202 | Automated |
| TC-INVGRN-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_grn_203 | Automated |
| TC-INVGRN-N204 | Negative | Auth | Without update → 403 on edit/update/inspect | 403 | test_inv_grn_204 | Automated |
| TC-INVGRN-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_grn_205 | Automated |
| TC-INVGRN-N206 | Negative | Auth | Without accept permission → 403 on accept | 403 | test_inv_grn_206 | Automated |
