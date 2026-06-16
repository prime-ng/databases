# INV — Inventory Module Development Plan
**Module:** Inventory (`Modules\Inventory`) | **Branch:** Brijesh_Main | **Date:** 2026-03-26
**Route Prefix:** `inventory/` | **Route Name Prefix:** `inventory.` | **DB Prefix:** `inv_`
**Scale:** 18 controllers · 28 models · 7 services · 13 FormRequests · 13 Policies · ~65 views

---

## Section 1 — Controller Inventory (18 Controllers)

All controllers namespace: `Modules\Inventory\app\Http\Controllers\`
All routes middleware: `['auth', 'tenant', 'EnsureTenantHasModule:Inventory']`

---

### 1.1 `InvDashboardController`
**File:** `app/Http/Controllers/InvDashboardController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/dashboard` | `inventory.dashboard` | — | `inventory.view` |

---

### 1.2 `StockGroupController`
**File:** `app/Http/Controllers/StockGroupController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/stock-groups` | `inventory.stock-groups.index` | — | `inventory.stock-group.viewAny` |
| `store` | POST | `/inventory/stock-groups` | `inventory.stock-groups.store` | `StoreStockGroupRequest` | `inventory.stock-group.create` |
| `show` | GET | `/inventory/stock-groups/{id}` | `inventory.stock-groups.show` | — | `inventory.stock-group.view` |
| `update` | PUT | `/inventory/stock-groups/{id}` | `inventory.stock-groups.update` | `StoreStockGroupRequest` | `inventory.stock-group.update` |
| `destroy` | DELETE | `/inventory/stock-groups/{id}` | `inventory.stock-groups.destroy` | — | `inventory.stock-group.delete` |
| `toggleStatus` | PATCH | `/inventory/stock-groups/{id}/toggle-status` | `inventory.stock-groups.toggle-status` | — | `inventory.stock-group.update` |

---

### 1.3 `UomController`
**File:** `app/Http/Controllers/UomController.php`
**Note:** Handles both UOMs and UOM conversions (two related entities, one controller).

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/uoms` | `inventory.uoms.index` | — | `inventory.uom.viewAny` |
| `store` | POST | `/inventory/uoms` | `inventory.uoms.store` | `StoreUomRequest` | `inventory.uom.create` |
| `show` | GET | `/inventory/uoms/{id}` | `inventory.uoms.show` | — | `inventory.uom.view` |
| `update` | PUT | `/inventory/uoms/{id}` | `inventory.uoms.update` | `StoreUomRequest` | `inventory.uom.update` |
| `destroy` | DELETE | `/inventory/uoms/{id}` | `inventory.uoms.destroy` | — | `inventory.uom.delete` |
| `indexConversions` | GET | `/inventory/uom-conversions` | `inventory.uom-conversions.index` | — | `inventory.uom.viewAny` |
| `storeConversion` | POST | `/inventory/uom-conversions` | `inventory.uom-conversions.store` | `StoreUomConversionRequest` | `inventory.uom.create` |
| `updateConversion` | PUT | `/inventory/uom-conversions/{id}` | `inventory.uom-conversions.update` | `StoreUomConversionRequest` | `inventory.uom.update` |
| `destroyConversion` | DELETE | `/inventory/uom-conversions/{id}` | `inventory.uom-conversions.destroy` | — | `inventory.uom.delete` |

---

### 1.4 `StockItemController`
**File:** `app/Http/Controllers/StockItemController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/stock-items` | `inventory.stock-items.index` | — | `inventory.stock-item.viewAny` |
| `store` | POST | `/inventory/stock-items` | `inventory.stock-items.store` | `StoreStockItemRequest` | `inventory.stock-item.create` |
| `show` | GET | `/inventory/stock-items/{id}` | `inventory.stock-items.show` | — | `inventory.stock-item.view` |
| `update` | PUT | `/inventory/stock-items/{id}` | `inventory.stock-items.update` | `StoreStockItemRequest` | `inventory.stock-item.update` |
| `destroy` | DELETE | `/inventory/stock-items/{id}` | `inventory.stock-items.destroy` | — | `inventory.stock-item.delete` |
| `toggleStatus` | PATCH | `/inventory/stock-items/{id}/toggle-status` | `inventory.stock-items.toggle-status` | — | `inventory.stock-item.update` |
| `printLabels` | POST | `/inventory/stock-items/{id}/print-labels` | `inventory.stock-items.print-labels` | — | `inventory.stock-item.view` |

---

### 1.5 `GodownController`
**File:** `app/Http/Controllers/GodownController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/godowns` | `inventory.godowns.index` | — | `inventory.godown.viewAny` |
| `store` | POST | `/inventory/godowns` | `inventory.godowns.store` | `StoreGodownRequest` | `inventory.godown.create` |
| `show` | GET | `/inventory/godowns/{id}` | `inventory.godowns.show` | — | `inventory.godown.view` |
| `update` | PUT | `/inventory/godowns/{id}` | `inventory.godowns.update` | `StoreGodownRequest` | `inventory.godown.update` |
| `destroy` | DELETE | `/inventory/godowns/{id}` | `inventory.godowns.destroy` | — | `inventory.godown.delete` |

---

### 1.6 `AssetCategoryController`
**File:** `app/Http/Controllers/AssetCategoryController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/asset-categories` | `inventory.asset-categories.index` | — | `inventory.asset-category.viewAny` |
| `store` | POST | `/inventory/asset-categories` | `inventory.asset-categories.store` | — | `inventory.asset-category.create` |
| `show` | GET | `/inventory/asset-categories/{id}` | `inventory.asset-categories.show` | — | `inventory.asset-category.view` |
| `update` | PUT | `/inventory/asset-categories/{id}` | `inventory.asset-categories.update` | — | `inventory.asset-category.update` |
| `destroy` | DELETE | `/inventory/asset-categories/{id}` | `inventory.asset-categories.destroy` | — | `inventory.asset-category.delete` |

---

### 1.7 `ItemVendorController`
**File:** `app/Http/Controllers/ItemVendorController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/items/{item}/vendors` | `inventory.item-vendors.index` | — | `inventory.rate-contract.viewAny` |
| `store` | POST | `/inventory/items/{item}/vendors` | `inventory.item-vendors.store` | — | `inventory.rate-contract.create` |
| `update` | PUT | `/inventory/items/{item}/vendors/{vendor}` | `inventory.item-vendors.update` | — | `inventory.rate-contract.update` |
| `destroy` | DELETE | `/inventory/items/{item}/vendors/{vendor}` | `inventory.item-vendors.destroy` | — | `inventory.rate-contract.delete` |

---

### 1.8 `RateContractController`
**File:** `app/Http/Controllers/RateContractController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/rate-contracts` | `inventory.rate-contracts.index` | — | `inventory.rate-contract.viewAny` |
| `store` | POST | `/inventory/rate-contracts` | `inventory.rate-contracts.store` | `StoreRateContractRequest` | `inventory.rate-contract.create` |
| `show` | GET | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.show` | — | `inventory.rate-contract.view` |
| `update` | PUT | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.update` | `StoreRateContractRequest` | `inventory.rate-contract.update` |
| `destroy` | DELETE | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.destroy` | — | `inventory.rate-contract.delete` |
| `activate` | PATCH | `/inventory/rate-contracts/{id}/activate` | `inventory.rate-contracts.activate` | — | `inventory.rate-contract.update` |
| `items` | GET | `/inventory/rate-contracts/{id}/items` | `inventory.rate-contracts.items` | — | `inventory.rate-contract.view` |
| `storeItem` | POST | `/inventory/rate-contracts/{id}/items` | `inventory.rate-contracts.items.store` | — | `inventory.rate-contract.update` |
| `updateItem` | PUT | `/inventory/rate-contracts/{id}/items/{item}` | `inventory.rate-contracts.items.update` | — | `inventory.rate-contract.update` |
| `destroyItem` | DELETE | `/inventory/rate-contracts/{id}/items/{item}` | `inventory.rate-contracts.items.destroy` | — | `inventory.rate-contract.delete` |

---

### 1.9 `PurchaseRequisitionController`
**File:** `app/Http/Controllers/PurchaseRequisitionController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/purchase-requisitions` | `inventory.prs.index` | — | `inventory.purchase-requisition.viewAny` |
| `store` | POST | `/inventory/purchase-requisitions` | `inventory.prs.store` | `StorePurchaseRequisitionRequest` | `inventory.purchase-requisition.create` |
| `show` | GET | `/inventory/purchase-requisitions/{id}` | `inventory.prs.show` | — | `inventory.purchase-requisition.view` |
| `update` | PUT | `/inventory/purchase-requisitions/{id}` | `inventory.prs.update` | `StorePurchaseRequisitionRequest` | `inventory.purchase-requisition.update` |
| `destroy` | DELETE | `/inventory/purchase-requisitions/{id}` | `inventory.prs.destroy` | — | `inventory.purchase-requisition.delete` |
| `submit` | PATCH | `/inventory/purchase-requisitions/{id}/submit` | `inventory.prs.submit` | — | `inventory.purchase-requisition.update` |
| `approve` | PATCH | `/inventory/purchase-requisitions/{id}/approve` | `inventory.prs.approve` | — | `inventory.purchase-requisition.approve` |
| `reject` | PATCH | `/inventory/purchase-requisitions/{id}/reject` | `inventory.prs.reject` | — | `inventory.purchase-requisition.approve` |
| `import` | POST | `/inventory/purchase-requisitions/import` | `inventory.prs.import` | — | `inventory.purchase-requisition.create` |

---

### 1.10 `QuotationController`
**File:** `app/Http/Controllers/QuotationController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/quotations` | `inventory.quotations.index` | — | `inventory.purchase-order.viewAny` |
| `store` | POST | `/inventory/quotations` | `inventory.quotations.store` | `StoreQuotationRequest` | `inventory.purchase-order.create` |
| `show` | GET | `/inventory/quotations/{id}` | `inventory.quotations.show` | — | `inventory.purchase-order.view` |
| `update` | PUT | `/inventory/quotations/{id}` | `inventory.quotations.update` | `StoreQuotationRequest` | `inventory.purchase-order.update` |
| `destroy` | DELETE | `/inventory/quotations/{id}` | `inventory.quotations.destroy` | — | `inventory.purchase-order.delete` |
| `compare` | GET | `/inventory/quotations/compare` | `inventory.quotations.compare` | — | `inventory.purchase-order.viewAny` |
| `convertToPO` | POST | `/inventory/quotations/{id}/convert-to-po` | `inventory.quotations.convert-to-po` | — | `inventory.purchase-order.create` |

---

### 1.11 `PurchaseOrderController`
**File:** `app/Http/Controllers/PurchaseOrderController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/purchase-orders` | `inventory.pos.index` | — | `inventory.purchase-order.viewAny` |
| `store` | POST | `/inventory/purchase-orders` | `inventory.pos.store` | `StorePurchaseOrderRequest` | `inventory.purchase-order.create` |
| `show` | GET | `/inventory/purchase-orders/{id}` | `inventory.pos.show` | — | `inventory.purchase-order.view` |
| `update` | PUT | `/inventory/purchase-orders/{id}` | `inventory.pos.update` | `StorePurchaseOrderRequest` | `inventory.purchase-order.update` |
| `destroy` | DELETE | `/inventory/purchase-orders/{id}` | `inventory.pos.destroy` | — | `inventory.purchase-order.delete` |
| `sendToVendor` | PATCH | `/inventory/purchase-orders/{id}/send` | `inventory.pos.send` | — | `inventory.purchase-order.update` |
| `approve` | PATCH | `/inventory/purchase-orders/{id}/approve` | `inventory.pos.approve` | — | `inventory.purchase-order.approve` |
| `cancel` | PATCH | `/inventory/purchase-orders/{id}/cancel` | `inventory.pos.cancel` | — | `inventory.purchase-order.update` |
| `convertFromPR` | POST | `/inventory/purchase-orders/from-pr/{pr}` | `inventory.pos.from-pr` | — | `inventory.purchase-order.create` |

---

### 1.12 `GrnController`
**File:** `app/Http/Controllers/GrnController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/grns` | `inventory.grns.index` | — | `inventory.grn.viewAny` |
| `store` | POST | `/inventory/grns` | `inventory.grns.store` | `StoreGrnRequest` | `inventory.grn.create` |
| `show` | GET | `/inventory/grns/{id}` | `inventory.grns.show` | — | `inventory.grn.view` |
| `update` | PUT | `/inventory/grns/{id}` | `inventory.grns.update` | `StoreGrnRequest` | `inventory.grn.update` |
| `destroy` | DELETE | `/inventory/grns/{id}` | `inventory.grns.destroy` | — | `inventory.grn.delete` |
| `inspect` | PATCH | `/inventory/grns/{id}/inspect` | `inventory.grns.inspect` | — | `inventory.grn.update` |
| `accept` | POST | `/inventory/grns/{id}/accept` | `inventory.grns.accept` | — | `inventory.grn.accept` |
| `reject` | PATCH | `/inventory/grns/{id}/reject` | `inventory.grns.reject` | — | `inventory.grn.accept` |

---

### 1.13 `IssueRequestController`
**File:** `app/Http/Controllers/IssueRequestController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/issue-requests` | `inventory.issue-requests.index` | — | `inventory.stock-issue.viewAny` |
| `store` | POST | `/inventory/issue-requests` | `inventory.issue-requests.store` | `StoreIssueRequestRequest` | `inventory.stock-issue.create` |
| `show` | GET | `/inventory/issue-requests/{id}` | `inventory.issue-requests.show` | — | `inventory.stock-issue.view` |
| `update` | PUT | `/inventory/issue-requests/{id}` | `inventory.issue-requests.update` | `StoreIssueRequestRequest` | `inventory.stock-issue.update` |
| `destroy` | DELETE | `/inventory/issue-requests/{id}` | `inventory.issue-requests.destroy` | — | `inventory.stock-issue.delete` |
| `approve` | PATCH | `/inventory/issue-requests/{id}/approve` | `inventory.issue-requests.approve` | — | `inventory.stock-issue.approve` |
| `reject` | PATCH | `/inventory/issue-requests/{id}/reject` | `inventory.issue-requests.reject` | — | `inventory.stock-issue.approve` |

---

### 1.14 `StockIssueController`
**File:** `app/Http/Controllers/StockIssueController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/stock-issues` | `inventory.stock-issues.index` | — | `inventory.stock-issue.viewAny` |
| `store` | POST | `/inventory/stock-issues` | `inventory.stock-issues.store` | `StoreStockIssueRequest` | `inventory.stock-issue.create` |
| `show` | GET | `/inventory/stock-issues/{id}` | `inventory.stock-issues.show` | — | `inventory.stock-issue.view` |
| `acknowledge` | PATCH | `/inventory/stock-issues/{id}/acknowledge` | `inventory.stock-issues.acknowledge` | — | `inventory.stock-issue.update` |
| `printSlip` | GET | `/inventory/stock-issues/{id}/print-slip` | `inventory.stock-issues.print-slip` | — | `inventory.stock-issue.view` |

---

### 1.15 `StockEntryController`
**File:** `app/Http/Controllers/StockEntryController.php`
**Read-only — no create/update/delete routes (BR-INV-014).**

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/stock-entries` | `inventory.stock-entries.index` | — | `inventory.stock-adjustment.viewAny` |
| `show` | GET | `/inventory/stock-entries/{id}` | `inventory.stock-entries.show` | — | `inventory.stock-adjustment.view` |

---

### 1.16 `StockAdjustmentController`
**File:** `app/Http/Controllers/StockAdjustmentController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/stock-adjustments` | `inventory.adjustments.index` | — | `inventory.stock-adjustment.viewAny` |
| `store` | POST | `/inventory/stock-adjustments` | `inventory.adjustments.store` | `StoreStockAdjustmentRequest` | `inventory.stock-adjustment.create` |
| `show` | GET | `/inventory/stock-adjustments/{id}` | `inventory.adjustments.show` | — | `inventory.stock-adjustment.view` |
| `update` | PUT | `/inventory/stock-adjustments/{id}` | `inventory.adjustments.update` | `StoreStockAdjustmentRequest` | `inventory.stock-adjustment.update` |
| `submit` | PATCH | `/inventory/stock-adjustments/{id}/submit` | `inventory.adjustments.submit` | — | `inventory.stock-adjustment.update` |
| `approve` | PATCH | `/inventory/stock-adjustments/{id}/approve` | `inventory.adjustments.approve` | — | `inventory.stock-adjustment.approve` |
| `reject` | PATCH | `/inventory/stock-adjustments/{id}/reject` | `inventory.adjustments.reject` | — | `inventory.stock-adjustment.approve` |

---

### 1.17 `AssetController`
**File:** `app/Http/Controllers/AssetController.php`

| Method | HTTP | URI | Route Name | FormRequest | Policy |
|--------|------|-----|-----------|------------|--------|
| `index` | GET | `/inventory/assets` | `inventory.assets.index` | — | `inventory.asset.viewAny` |
| `show` | GET | `/inventory/assets/{id}` | `inventory.assets.show` | — | `inventory.asset.view` |
| `update` | PUT | `/inventory/assets/{id}` | `inventory.assets.update` | — | `inventory.asset.update` |
| `transfer` | POST | `/inventory/assets/{id}/transfer` | `inventory.assets.transfer` | — | `inventory.asset.update` |
| `dispose` | POST | `/inventory/assets/{id}/dispose` | `inventory.assets.dispose` | — | `inventory.asset.delete` |
| `maintenanceIndex` | GET | `/inventory/assets/{id}/maintenance` | `inventory.assets.maintenance.index` | — | `inventory.asset.view` |
| `storeMaintenance` | POST | `/inventory/assets/{id}/maintenance` | `inventory.assets.maintenance.store` | — | `inventory.asset.update` |
| `printTag` | GET | `/inventory/assets/{id}/print-tag` | `inventory.assets.print-tag` | — | `inventory.asset.view` |

---

### 1.18 `InvReportController`
**File:** `app/Http/Controllers/InvReportController.php`

| Method | HTTP | URI | Route Name | FR Coverage |
|--------|------|-----|-----------|------------|
| `stockBalance` | GET | `/inventory/reports/stock-balance` | `inventory.reports.stock-balance` | INV-015 |
| `stockValuation` | GET | `/inventory/reports/stock-valuation` | `inventory.reports.stock-valuation` | INV-015 |
| `stockLedger` | GET | `/inventory/reports/stock-ledger` | `inventory.reports.stock-ledger` | INV-015 |
| `consumption` | GET | `/inventory/reports/consumption` | `inventory.reports.consumption` | INV-015 |
| `purchaseRegister` | GET | `/inventory/reports/purchase-register` | `inventory.reports.purchase-register` | INV-015 |
| `pendingPO` | GET | `/inventory/reports/pending-po` | `inventory.reports.pending-po` | INV-015 |
| `grnRegister` | GET | `/inventory/reports/grn-register` | `inventory.reports.grn-register` | INV-015 |
| `reorderAlerts` | GET | `/inventory/reports/reorder-alerts` | `inventory.reports.reorder-alerts` | INV-015 |
| `fastSlowMovers` | GET | `/inventory/reports/fast-slow-movers` | `inventory.reports.fast-slow-movers` | INV-015 |
| `expiryAlerts` | GET | `/inventory/reports/expiry-alerts` | `inventory.reports.expiry-alerts` | INV-015 |
| `assetRegister` | GET | `/inventory/reports/asset-register` | `inventory.reports.asset-register` | INV-011 |
| `export` | GET | `/inventory/reports/export/{type}` | `inventory.reports.export` | INV-015 |

---

## Section 2 — Service Inventory (7 Services)

All services namespace: `Modules\Inventory\app\Services\`

---

### 2.1 `StockLedgerService`
**File:** `app/Services/StockLedgerService.php`
**Depends on:** `StockValuationService`
**Fires:** *(no events — called by GrnPostingService / StockIssueService which fire events)*

```
postInward(StockItem $item, float $qty, float $rate, ?string $batch,
           ?Carbon $expiry, Godown $godown, int $voucherId): StockEntry
  └── Creates inv_stock_entries (inward); updates inv_stock_balances (lockForUpdate +)

postOutward(StockItem $item, float $qty, float $cost, ?string $batch,
            Godown $godown, int $voucherId): StockEntry
  └── Guard: current_qty >= qty (BR-INV-003); updates balance (lockForUpdate -)

postTransfer(StockItem $item, float $qty, float $rate,
             Godown $from, Godown $to, int $voucherId): array  // [transfer_out, transfer_in]
  └── Creates pair of inv_stock_entries; updates both balances atomically

postAdjustment(StockAdjustment $adj, int $voucherId): array  // [StockEntry, ...]
  └── Reads variance_qty from each adj_item; posts inward (surplus) or outward (deficit)

recalculateBalances(?int $itemId = null, ?int $godownId = null): void
  └── Rebuilds inv_stock_balances by SUM(inv_stock_entries grouped by item+godown)
  └── Called by inventory:recalculate-balances Artisan command

guardImmutable(int $entryId): void
  └── Throws ImmutableEntryException if any UPDATE/DELETE attempted (BR-INV-014)
```

---

### 2.2 `StockValuationService`
**File:** `app/Services/StockValuationService.php`
**Depends on:** *(none)*
**Fires:** *(none)*

```
getIssueCost(StockItem $item, Godown $godown, float $qty): float
  └── Dispatches to correct method based on item.valuation_method

fifoIssueCost(StockItem $item, Godown $godown, float $qty): float
  └── BR-INV-008: Selects batches in ascending creation order (oldest first)
  └── Queries inv_stock_entries (inward, entry_type=inward) ORDER BY created_at ASC
  └── Returns weighted average cost of selected batches for issued qty

weightedAverageCost(StockItem $item, Godown $godown): float
  └── current_value / current_qty from inv_stock_balances

lastPurchaseCost(StockItem $item): float
  └── Reads inv_item_vendor_jnt.last_purchase_rate for preferred vendor, else latest GRN

recalculateWACAfterInward(StockItem $item, Godown $godown,
                           float $newQty, float $newRate): float
  └── Updates running WAC after each inward: (old_value + new_qty*new_rate) / (old_qty + new_qty)

assignValuationMethod(StockItem $item, string $method): void
  └── Validates method is in ['fifo','weighted_average','last_purchase']; saves
```

---

### 2.3 `GrnPostingService`
**File:** `app/Services/GrnPostingService.php`
**Depends on:** `StockLedgerService`, `StockValuationService`, `ReorderAlertService`
**Fires:** `GrnAccepted`

**GRN Acceptance Sequence (10 steps):**
```
acceptGrn(GoodsReceiptNote $grn): void

  Step 1: Validate all items: accepted_qty + rejected_qty == received_qty per line (BR-INV-006)
  Step 2: Validate cumulative received_qty (across all GRNs) <= PO ordered_qty per item (BR-INV-007)
  Step 3: DB transaction begins
  Step 4: For each accepted GRN item:
            $cost = StockValuationService::recalculateWACAfterInward(...)
            StockLedgerService::postInward(item, accepted_qty, unit_cost, batch, expiry, godown, $voucherId=0)
            → Creates inv_stock_entries (inward) — voucher_id updated by Accounting listener after event
            → Updates inv_stock_balances (lockForUpdate, add qty + value)
            → If item.item_type == 'asset': create one inv_assets record per unit
  Step 5: Update inv_purchase_order_items.received_qty for each line
            → If all PO items fully received: PO status → 'received'
            → If partially received: PO status → 'partial'
  Step 6: Update inv_item_vendor_jnt: last_purchase_rate = unit_cost, last_purchase_date = today
  Step 7: GRN status → 'accepted' (or 'partial' if any GRN item has rejected_qty > 0)
  Step 8: DB transaction commits
  Step 9: Fire GrnAccepted event (Accounting creates Purchase Voucher; updates stock_entries.voucher_id)
  Step 10: ReorderAlertService::checkAfterInward() — no reorder alert on inward (stock increased)

partialAcceptGrn(GoodsReceiptNote $grn, array $acceptedItems): void
  └── Accepts subset; creates new GRN for rejected items (workflow-driven)

rejectGrn(GoodsReceiptNote $grn, string $reason): void
  └── Sets GRN status = 'rejected'; no stock entry created; fires no accounting event
```

---

### 2.4 `PurchaseOrderService`
**File:** `app/Services/PurchaseOrderService.php`
**Depends on:** *(none)*
**Fires:** *(none — no domain events from PO; events fire only on GRN acceptance)*

```
createFromPR(PurchaseRequisition $pr, int $vendorId, array $overrides = []): PurchaseOrder
  └── Copies PR lines to PO; pre-fills rate from active rate contract if exists; PR status → 'converted'

createFromQuotation(Quotation $quotation, array $selectedItemIds): PurchaseOrder
  └── Pre-fills selected quotation item rates; marks quotation status → 'converted'

createDirect(array $data): PurchaseOrder
  └── Creates PO without PR/RFQ; vendor_id required; approvals based on net_amount threshold

checkApprovalThreshold(PurchaseOrder $po): bool
  └── Returns true if po.net_amount > school config threshold (requires HOD/Principal approval)

autoTransitionStatus(PurchaseOrder $po): string
  └── Recalculates PO status after each GRN: 'partial' if some items remain, 'received' if all done

applyRateContract(PurchaseOrder $po): void
  └── For each PO line, checks inv_rate_contract_items_jnt for active contract; applies agreed_rate
```

---

### 2.5 `StockIssueService`
**File:** `app/Services/StockIssueService.php`
**Depends on:** `StockLedgerService`, `StockValuationService`, `ReorderAlertService`
**Fires:** `StockIssued`

**Issue Execution Sequence (9 steps):**
```
executeIssue(IssueRequest $request, array $issueItems, int $godownId): StockIssue

  Step 1: Check inv_stock_balances.current_qty >= requested_qty per item (BR-INV-003)
            Throws InsufficientStockException if any item would go negative
  Step 2: Determine issue cost per item via StockValuationService::getIssueCost()
  Step 3: DB transaction begins
  Step 4: Create inv_stock_issues header (issue_number auto-generated: SI-YYYY-NNN)
  Step 5: For each item:
            Create inv_stock_issue_items (qty, unit_cost, batch_number)
            StockLedgerService::postOutward(item, qty, cost, batch, godown, $voucherId=0)
            → Creates inv_stock_entries (outward) — voucher_id set by Accounting listener
            → Updates inv_stock_balances (lockForUpdate, deduct qty + value)
            → Update inv_issue_request_items.issued_qty
  Step 6: IssueRequest status → 'issued' (or 'partial' if some items not fully issued)
  Step 7: DB transaction commits
  Step 8: Fire StockIssued event (Accounting creates Stock Journal Voucher)
  Step 9: ReorderAlertService::checkAfterOutward(items, godown)
            → If current_qty <= reorder_level: dispatch ReorderAlertJob (delay 60s, 3 retries)

executeDirectIssue(array $items, int $godownId, int $departmentId): StockIssue
  └── Bypass IssueRequest; requires inventory.stock-issue.direct permission

acknowledgeIssue(StockIssue $issue, int $acknowledgedBy): void
  └── Sets acknowledged_by + acknowledged_at; mandatory for asset items (check inv_assets)
```

---

### 2.6 `ReorderAlertService`
**File:** `app/Services/ReorderAlertService.php`
**Depends on:** *(none — reads inv_stock_balances directly)*
**Fires:** `ReorderThresholdReached` (via `ReorderAlertJob`), `RateContractExpiringSoon`

```
checkAfterOutward(array $stockItems, Godown $godown): void
  └── For each item: if current_qty <= reorder_level → dispatch ReorderAlertJob(item, godown)

checkAllItems(): void
  └── Full scan of inv_stock_balances joined with inv_stock_items.reorder_level
  └── Called by inventory:check-reorder-levels Artisan command

autoCreatePR(StockItem $item, float $reorderQty): ?PurchaseRequisition
  └── Only when item.auto_reorder_pr == true
  └── Creates draft PR with auto-generated pr_number; assigns pr_number = PR-YYYY-NNN

checkExpiringContracts(int $daysBefore = 30): void
  └── Queries inv_rate_contracts WHERE valid_to BETWEEN today AND today+30d AND status='active'
  └── Dispatches RateContractExpiringSoon notification per contract
```

---

### 2.7 `InventoryReportService`
**File:** `app/Services/InventoryReportService.php`
**Depends on:** *(none — direct DB queries)*
**Fires:** *(none)*
**Export:** CSV via `fputcsv` to `php://temp`; PDF via `DomPDF`; chunked at 500 rows for large exports

```
stockBalanceReport(array $filters): Collection
  └── inv_stock_balances + inv_stock_items + inv_godowns; filter by group, godown, item_type

stockValuationReport(array $filters): Collection
  └── inv_stock_balances.current_value; group by stock_group; subtotals

stockLedgerReport(int $itemId, int $godownId, Carbon $from, Carbon $to): Collection
  └── inv_stock_entries WHERE (stock_item_id, godown_id, created_at BETWEEN) ORDER BY created_at
  └── Uses index: idx_inv_sent_item_godown_date for < 500ms (NFR)

consumptionReport(Carbon $from, Carbon $to, ?int $departmentId = null): Collection
  └── inv_stock_issue_items + inv_stock_issues; GROUP BY item + department

purchaseRegisterReport(Carbon $from, Carbon $to): Collection
  └── inv_goods_receipt_notes (accepted) + inv_grn_items + vnd_vendors

assetRegisterReport(array $filters): Collection
  └── inv_assets + inv_asset_categories + inv_stock_items; filter by condition, category

export(string $type, array $filters, string $format = 'csv'): Response
  └── Delegates to appropriate report method; streams response; chunk(500) for large sets
```

---

## Section 3 — FormRequest Inventory (13 FormRequests)

All FormRequests namespace: `Modules\Inventory\app\Http\Requests\`

| # | Class | Used By | Key Validation Rules |
|---|-------|---------|---------------------|
| 1 | `StoreStockGroupRequest` | StockGroupController@store/update | `name` required\|max:100; `code` nullable\|unique:inv_stock_groups,code,{id}; `parent_id` nullable\|exists:inv_stock_groups,id; parent_id must not equal self (after-rule) |
| 2 | `StoreUomRequest` | UomController@store/update | `name` required\|max:50; `symbol` required\|max:10; `decimal_places` integer\|between:0,4 |
| 3 | `StoreUomConversionRequest` | UomController@storeConversion/updateConversion | `from_uom_id` required\|exists:inv_units_of_measure,id; `to_uom_id` required\|exists\|different:from_uom_id; `conversion_factor` required\|numeric\|gt:0; if both dates provided: effective_from <= effective_to |
| 4 | `StoreStockItemRequest` | StockItemController@store/update | `name` required\|max:150; `sku` nullable\|unique:inv_stock_items,sku,{id}; `stock_group_id` required\|exists; `uom_id` required\|exists:inv_units_of_measure,id; `item_type` in:consumable,asset; `valuation_method` in:fifo,weighted_average,last_purchase; `reorder_level` nullable\|numeric\|gte:0 |
| 5 | `StoreGodownRequest` | GodownController@store/update | `name` required\|max:100; `code` nullable\|unique:inv_godowns,code,{id}; `parent_id` nullable\|exists:inv_godowns,id; parent must not equal self or be a descendant |
| 6 | `StorePurchaseRequisitionRequest` | PurchaseRequisitionController@store/update | `required_date` required\|date\|after_or_equal:today; `priority` in:low,normal,high,urgent; `items` required\|array\|min:1; `items.*.item_id` required\|exists:inv_stock_items,id; `items.*.qty` required\|numeric\|gt:0 |
| 7 | `StoreQuotationRequest` | QuotationController@store/update | `vendor_id` required\|exists:vnd_vendors,id; `validity_date` required_if:status,sent; `items` required\|array\|min:1; `items.*.item_id` required\|exists; `items.*.quoted_rate` required\|numeric\|gt:0 |
| 8 | `StorePurchaseOrderRequest` | PurchaseOrderController@store/update | `vendor_id` required\|exists:vnd_vendors,id; `order_date` required\|date; `items` required\|array\|min:1; `items.*.item_id` required\|exists; `items.*.unit_price` required\|numeric\|gt:0; `items.*.ordered_qty` required\|numeric\|gt:0 |
| 9 | `StoreGrnRequest` | GrnController@store/update | `po_id` required\|exists:inv_purchase_orders,id\|whereIn:status,[sent,partial]; `godown_id` required\|exists:inv_godowns,id; `items` required\|array\|min:1; `items.*.accepted_qty + items.*.rejected_qty == items.*.received_qty` (BR-INV-006 — after rule); `items.*.received_qty <= remaining_qty_from_po` (BR-INV-007) |
| 10 | `StoreIssueRequestRequest` | IssueRequestController@store/update | `department_id` required\|exists:sch_department,id; `required_date` required\|date\|after_or_equal:today; `items` required\|array\|min:1; `items.*.item_id` required\|exists; `items.*.qty` required\|numeric\|gt:0 |
| 11 | `StoreStockIssueRequest` | StockIssueController@store | `godown_id` required\|exists:inv_godowns,id; `issue_request_id` nullable\|exists:inv_issue_requests,id\|whereIn:status,[approved]; `items` required\|array\|min:1; each item qty must not exceed available stock (after-rule calling StockBalance) |
| 12 | `StoreRateContractRequest` | RateContractController@store/update | `vendor_id` required\|exists:vnd_vendors,id; `valid_from` required\|date; `valid_to` required\|date\|after:valid_from; `items` required\|array\|min:1; `items.*.agreed_rate` required\|numeric\|gt:0 |
| 13 | `StoreStockAdjustmentRequest` | StockAdjustmentController@store/update | `adjustment_date` required\|date; `godown_id` required\|exists:inv_godowns,id; `items` required\|array\|min:1; `items.*.item_id` required\|exists; `items.*.physical_qty` required\|numeric\|gte:0; do NOT include `variance_qty` (it is GENERATED — BR-INV-018) |

---

## Section 4 — Blade View Inventory (~67 views)

**Base path:** `Modules/Inventory/resources/views/inventory/`
**Layout extends:** `layouts.tenant-master` (or equivalent app layout)

---

### Dashboard (1 view)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `dashboard.blade.php` | `inventory.dashboard` | InvDashboardController@index | KPIs: low-stock count (AJAX), pending POs, GRNs pending QC, pending issue requests, asset maintenance due |

---

### Masters (9 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `stock-groups/index.blade.php` | `inventory.stock-groups.index` | StockGroupController@index | Hierarchical tree list; inline create/edit modal; drag-reorder |
| `uoms/index.blade.php` | `inventory.uoms.index` | UomController@index | UOM list + conversion rules tab; modal for UOM CRUD |
| `stock-items/index.blade.php` | `inventory.stock-items.index` | StockItemController@index | DataTable with group/type filter; SKU search; barcode column |
| `stock-items/create.blade.php` | `inventory.stock-items.store` | StockItemController (form) | Full item form: name, SKU, group, UOM, valuation method, reorder levels, accounting linkage |
| `stock-items/show.blade.php` | `inventory.stock-items.show` | StockItemController@show | Item detail: current stock by godown, ledger, vendor list, label print button |
| `godowns/index.blade.php` | `inventory.godowns.index` | GodownController@index | Tree list with parent-child hierarchy; CRUD modal |
| `asset-categories/index.blade.php` | `inventory.asset-categories.index` | AssetCategoryController@index | List with depreciation rate; modal CRUD |
| `stock-items/_form.blade.php` | — | (partial) | Reusable item form partial (used by create + edit) |
| `stock-items/labels.blade.php` | `inventory.stock-items.print-labels` | StockItemController@printLabels | DomPDF label template; QR code via `chillerlan/php-qrcode`; max 200 per batch |

---

### Vendor Linkage (6 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `item-vendors/index.blade.php` | `inventory.item-vendors.index` | ItemVendorController@index | Per-item vendor list; preferred flag; last purchase rate |
| `rate-contracts/index.blade.php` | `inventory.rate-contracts.index` | RateContractController@index | List with status badge; expiry countdown; activate button |
| `rate-contracts/create.blade.php` | `inventory.rate-contracts.store` | (form) | Create contract with dynamic line items (Alpine.js) |
| `rate-contracts/show.blade.php` | `inventory.rate-contracts.show` | RateContractController@show | Contract detail + item list; activate button |
| `rate-contracts/edit.blade.php` | `inventory.rate-contracts.update` | (form) | Edit contract; add/remove line items |
| `rate-contracts/_items.blade.php` | — | (partial) | Reusable line-items table for create/edit |

---

### Procurement (16 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `purchase-requisitions/index.blade.php` | `inventory.prs.index` | PRController@index | List with status filter; submit/approve actions |
| `purchase-requisitions/create.blade.php` | `inventory.prs.store` | (form) | PR form with dynamic line items; item search with current stock info |
| `purchase-requisitions/show.blade.php` | `inventory.prs.show` | PRController@show | PR detail; approve/reject/convert buttons; audit trail |
| `purchase-requisitions/import.blade.php` | `inventory.prs.import` | PRController@import | CSV upload + preview validation table before import |
| `quotations/index.blade.php` | `inventory.quotations.index` | QuotationController@index | RFQ list grouped by PR; status filter |
| `quotations/create.blade.php` | `inventory.quotations.store` | (form) | RFQ form; vendor select; line items with quoted rate |
| `quotations/show.blade.php` | `inventory.quotations.show` | QuotationController@show | Quotation detail; convert to PO button |
| `quotations/compare.blade.php` | `inventory.quotations.compare` | QuotationController@compare | Side-by-side vendor quote matrix; lowest rate highlighted in green via JS; select per line |
| `purchase-orders/index.blade.php` | `inventory.pos.index` | POController@index | PO list with status; value filter; send/approve actions |
| `purchase-orders/create.blade.php` | `inventory.pos.store` | (form) | PO form; rate contract auto-fill via AJAX on vendor change |
| `purchase-orders/show.blade.php` | `inventory.pos.show` | POController@show | PO detail; received/pending qty per line; GRN list |
| `purchase-orders/edit.blade.php` | `inventory.pos.update` | (form) | Edit draft PO |
| `grns/index.blade.php` | `inventory.grns.index` | GrnController@index | GRN list with QC status; pending acceptance count |
| `grns/create.blade.php` | `inventory.grns.store` | (form) | GRN form; PO line items auto-populated; accepted+rejected=received Alpine.js validation |
| `grns/show.blade.php` | `inventory.grns.show` | GrnController@show | GRN detail; QC notes per item; accept/reject buttons |
| `grns/inspect.blade.php` | `inventory.grns.inspect` | GrnController@inspect | QC inspection form; per-item accepted/rejected qty with inline row total validation |

---

### Stock Issue (8 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `issue-requests/index.blade.php` | `inventory.issue-requests.index` | IssueRequestController@index | Request list; department filter; approve/reject bulk action |
| `issue-requests/create.blade.php` | `inventory.issue-requests.store` | (form) | Issue request form; item search with current balance indicator |
| `issue-requests/show.blade.php` | `inventory.issue-requests.show` | IssueRequestController@show | Request detail; approve/reject/execute issue buttons |
| `stock-issues/index.blade.php` | `inventory.stock-issues.index` | StockIssueController@index | Issue execution list; acknowledge pending badge |
| `stock-issues/create.blade.php` | `inventory.stock-issues.store` | (form) | Issue execution form; godown selector; available qty realtime via AJAX |
| `stock-issues/show.blade.php` | `inventory.stock-issues.show` | StockIssueController@show | Issue detail; acknowledge button; print slip |
| `stock-issues/slip.blade.php` | `inventory.stock-issues.print-slip` | StockIssueController@printSlip | DomPDF issue slip template; gate/store keeper signature fields |
| `stock-issues/_items.blade.php` | — | (partial) | Reusable items table for create/show |

---

### Stock Ledger & Balance (4 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `stock-entries/index.blade.php` | `inventory.stock-entries.index` | StockEntryController@index | Immutable ledger; item+godown+date filter; read-only |
| `stock-entries/show.blade.php` | `inventory.stock-entries.show` | StockEntryController@show | Single entry detail; voucher linkage (D21) |
| `stock-balances/index.blade.php` | (dashboard widget) | (inline AJAX endpoint) | Godown-wise balance grid; low-stock highlight |
| `stock-balances/item.blade.php` | (from StockItemController@show) | — | Per-item balance across all godowns; ledger mini-table |

---

### Stock Adjustments (4 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `stock-adjustments/index.blade.php` | `inventory.adjustments.index` | AdjController@index | Adjustment list with status; value variance column |
| `stock-adjustments/create.blade.php` | `inventory.adjustments.store` | (form) | Physical count form; system qty shown readonly; physical qty entered; variance computed JS |
| `stock-adjustments/show.blade.php` | `inventory.adjustments.show` | AdjController@show | Adjustment detail; variance per item; approve/reject buttons |
| `stock-adjustments/_items.blade.php` | — | (partial) | Line items partial; system qty + physical qty + variance column |

---

### Assets (8 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `assets/index.blade.php` | `inventory.assets.index` | AssetController@index | Asset register with condition badge; category filter; expiring warranty alert |
| `assets/show.blade.php` | `inventory.assets.show` | AssetController@show | Asset card: current location, assigned employee, condition, movement history, maintenance list |
| `assets/transfer.blade.php` | `inventory.assets.transfer` | AssetController@transfer | Transfer form: to_godown + to_employee + reason |
| `assets/dispose.blade.php` | `inventory.assets.dispose` | AssetController@dispose | Dispose form: reason + confirmation; fires AssetDisposed event |
| `assets/tag.blade.php` | `inventory.assets.print-tag` | AssetController@printTag | DomPDF asset tag: asset_tag QR code, name, category, purchase date |
| `assets/maintenance/index.blade.php` | `inventory.assets.maintenance.index` | AssetController@maintenanceIndex | Maintenance list per asset; overdue badge; next due date calendar |
| `assets/maintenance/create.blade.php` | `inventory.assets.maintenance.store` | (form) | Schedule/log maintenance: type, vendor, cost, next_due_date |
| `assets/_condition.blade.php` | — | (partial) | Condition badge + update dropdown partial |

---

### Reports (8 views)
| View File | Route Name | Controller Method | Description |
|-----------|-----------|-------------------|-------------|
| `reports/stock-balance.blade.php` | `inventory.reports.stock-balance` | InvReportController@stockBalance | Balance by item+godown; group subtotals; low-stock highlight |
| `reports/stock-valuation.blade.php` | `inventory.reports.stock-valuation` | InvReportController@stockValuation | Valuation by stock group; total value summary |
| `reports/stock-ledger.blade.php` | `inventory.reports.stock-ledger` | InvReportController@stockLedger | Movement ledger with opening+closing balance per period |
| `reports/purchase-register.blade.php` | `inventory.reports.purchase-register` | InvReportController@purchaseRegister | GRN-based purchase register with GST columns |
| `reports/pending-po.blade.php` | `inventory.reports.pendingPO` | InvReportController@pendingPO | POs with outstanding delivery; aging |
| `reports/reorder-alerts.blade.php` | `inventory.reports.reorder-alerts` | InvReportController@reorderAlerts | Items below reorder level with auto-PR flag |
| `reports/asset-register.blade.php` | `inventory.reports.asset-register` | InvReportController@assetRegister | Full asset register with book value; condition filter |
| `reports/export-layout.blade.php` | — | (partial/layout) | Shared export UI: format selector (CSV/PDF), date range, download button |

---

### Shared Partials (5 views)
| View File | Used In | Description |
|-----------|---------|-------------|
| `partials/_pagination.blade.php` | All index views | Standard pagination with page-size selector |
| `partials/_export-buttons.blade.php` | All report views | CSV + PDF export buttons with route param encoding |
| `partials/_confirm-modal.blade.php` | Destroy / approve / reject / dispose | Alpine.js confirmation dialog; customizable message |
| `partials/_status-badge.blade.php` | All list views | Status ENUM → Bootstrap badge color mapping |
| `partials/_line-items-table.blade.php` | PR, PO, GRN, Issue, Adjustment forms | Alpine.js dynamic line items: add/remove rows, total auto-calc |

**Total views: 67** (1 dashboard + 9 masters + 6 vendor + 16 procurement + 8 issue + 4 ledger + 4 adjustment + 8 assets + 8 reports + 5 partials)

---

## Section 5 — Complete Route List

**Common middleware on ALL routes:** `['auth', 'tenant', 'EnsureTenantHasModule:Inventory']`

| # | Method | URI | Route Name | Controller@method | FR |
|---|--------|-----|-----------|------------------|----|
| 1 | GET | `/inventory/dashboard` | `inventory.dashboard` | InvDashboardController@index | — |
| 2 | GET | `/inventory/stock-groups` | `inventory.stock-groups.index` | StockGroupController@index | INV-001 |
| 3 | POST | `/inventory/stock-groups` | `inventory.stock-groups.store` | StockGroupController@store | INV-001 |
| 4 | GET | `/inventory/stock-groups/{id}` | `inventory.stock-groups.show` | StockGroupController@show | INV-001 |
| 5 | PUT | `/inventory/stock-groups/{id}` | `inventory.stock-groups.update` | StockGroupController@update | INV-001 |
| 6 | DELETE | `/inventory/stock-groups/{id}` | `inventory.stock-groups.destroy` | StockGroupController@destroy | INV-001 |
| 7 | PATCH | `/inventory/stock-groups/{id}/toggle-status` | `inventory.stock-groups.toggle-status` | StockGroupController@toggleStatus | INV-001 |
| 8 | GET | `/inventory/uoms` | `inventory.uoms.index` | UomController@index | INV-002 |
| 9 | POST | `/inventory/uoms` | `inventory.uoms.store` | UomController@store | INV-002 |
| 10 | PUT | `/inventory/uoms/{id}` | `inventory.uoms.update` | UomController@update | INV-002 |
| 11 | DELETE | `/inventory/uoms/{id}` | `inventory.uoms.destroy` | UomController@destroy | INV-002 |
| 12 | GET | `/inventory/uom-conversions` | `inventory.uom-conversions.index` | UomController@indexConversions | INV-002 |
| 13 | POST | `/inventory/uom-conversions` | `inventory.uom-conversions.store` | UomController@storeConversion | INV-002 |
| 14 | PUT | `/inventory/uom-conversions/{id}` | `inventory.uom-conversions.update` | UomController@updateConversion | INV-002 |
| 15 | DELETE | `/inventory/uom-conversions/{id}` | `inventory.uom-conversions.destroy` | UomController@destroyConversion | INV-002 |
| 16 | GET | `/inventory/stock-items` | `inventory.stock-items.index` | StockItemController@index | INV-003 |
| 17 | POST | `/inventory/stock-items` | `inventory.stock-items.store` | StockItemController@store | INV-003 |
| 18 | GET | `/inventory/stock-items/{id}` | `inventory.stock-items.show` | StockItemController@show | INV-003 |
| 19 | PUT | `/inventory/stock-items/{id}` | `inventory.stock-items.update` | StockItemController@update | INV-003 |
| 20 | DELETE | `/inventory/stock-items/{id}` | `inventory.stock-items.destroy` | StockItemController@destroy | INV-003 |
| 21 | PATCH | `/inventory/stock-items/{id}/toggle-status` | `inventory.stock-items.toggle-status` | StockItemController@toggleStatus | INV-003 |
| 22 | POST | `/inventory/stock-items/{id}/print-labels` | `inventory.stock-items.print-labels` | StockItemController@printLabels | INV-015 |
| 23 | GET | `/inventory/godowns` | `inventory.godowns.index` | GodownController@index | INV-004 |
| 24 | POST | `/inventory/godowns` | `inventory.godowns.store` | GodownController@store | INV-004 |
| 25 | GET | `/inventory/godowns/{id}` | `inventory.godowns.show` | GodownController@show | INV-004 |
| 26 | PUT | `/inventory/godowns/{id}` | `inventory.godowns.update` | GodownController@update | INV-004 |
| 27 | DELETE | `/inventory/godowns/{id}` | `inventory.godowns.destroy` | GodownController@destroy | INV-004 |
| 28 | GET | `/inventory/asset-categories` | `inventory.asset-categories.index` | AssetCategoryController@index | INV-011 |
| 29 | POST | `/inventory/asset-categories` | `inventory.asset-categories.store` | AssetCategoryController@store | INV-011 |
| 30 | PUT | `/inventory/asset-categories/{id}` | `inventory.asset-categories.update` | AssetCategoryController@update | INV-011 |
| 31 | DELETE | `/inventory/asset-categories/{id}` | `inventory.asset-categories.destroy` | AssetCategoryController@destroy | INV-011 |
| 32 | GET | `/inventory/items/{item}/vendors` | `inventory.item-vendors.index` | ItemVendorController@index | INV-010 |
| 33 | POST | `/inventory/items/{item}/vendors` | `inventory.item-vendors.store` | ItemVendorController@store | INV-010 |
| 34 | PUT | `/inventory/items/{item}/vendors/{vendor}` | `inventory.item-vendors.update` | ItemVendorController@update | INV-010 |
| 35 | DELETE | `/inventory/items/{item}/vendors/{vendor}` | `inventory.item-vendors.destroy` | ItemVendorController@destroy | INV-010 |
| 36 | GET | `/inventory/rate-contracts` | `inventory.rate-contracts.index` | RateContractController@index | INV-010 |
| 37 | POST | `/inventory/rate-contracts` | `inventory.rate-contracts.store` | RateContractController@store | INV-010 |
| 38 | GET | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.show` | RateContractController@show | INV-010 |
| 39 | PUT | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.update` | RateContractController@update | INV-010 |
| 40 | DELETE | `/inventory/rate-contracts/{id}` | `inventory.rate-contracts.destroy` | RateContractController@destroy | INV-010 |
| 41 | PATCH | `/inventory/rate-contracts/{id}/activate` | `inventory.rate-contracts.activate` | RateContractController@activate | INV-010 |
| 42 | GET | `/inventory/purchase-requisitions` | `inventory.prs.index` | PRController@index | INV-007 |
| 43 | POST | `/inventory/purchase-requisitions` | `inventory.prs.store` | PRController@store | INV-007 |
| 44 | GET | `/inventory/purchase-requisitions/{id}` | `inventory.prs.show` | PRController@show | INV-007 |
| 45 | PUT | `/inventory/purchase-requisitions/{id}` | `inventory.prs.update` | PRController@update | INV-007 |
| 46 | DELETE | `/inventory/purchase-requisitions/{id}` | `inventory.prs.destroy` | PRController@destroy | INV-007 |
| 47 | PATCH | `/inventory/purchase-requisitions/{id}/submit` | `inventory.prs.submit` | PRController@submit | INV-007 |
| 48 | PATCH | `/inventory/purchase-requisitions/{id}/approve` | `inventory.prs.approve` | PRController@approve | INV-007 |
| 49 | PATCH | `/inventory/purchase-requisitions/{id}/reject` | `inventory.prs.reject` | PRController@reject | INV-007 |
| 50 | POST | `/inventory/purchase-requisitions/import` | `inventory.prs.import` | PRController@import | INV-007 |
| 51 | GET | `/inventory/quotations` | `inventory.quotations.index` | QuotationController@index | INV-013 |
| 52 | POST | `/inventory/quotations` | `inventory.quotations.store` | QuotationController@store | INV-013 |
| 53 | GET | `/inventory/quotations/{id}` | `inventory.quotations.show` | QuotationController@show | INV-013 |
| 54 | PUT | `/inventory/quotations/{id}` | `inventory.quotations.update` | QuotationController@update | INV-013 |
| 55 | DELETE | `/inventory/quotations/{id}` | `inventory.quotations.destroy` | QuotationController@destroy | INV-013 |
| 56 | GET | `/inventory/quotations/compare` | `inventory.quotations.compare` | QuotationController@compare | INV-013 |
| 57 | POST | `/inventory/quotations/{id}/convert-to-po` | `inventory.quotations.convert-to-po` | QuotationController@convertToPO | INV-013 |
| 58 | GET | `/inventory/purchase-orders` | `inventory.pos.index` | POController@index | INV-008 |
| 59 | POST | `/inventory/purchase-orders` | `inventory.pos.store` | POController@store | INV-008 |
| 60 | GET | `/inventory/purchase-orders/{id}` | `inventory.pos.show` | POController@show | INV-008 |
| 61 | PUT | `/inventory/purchase-orders/{id}` | `inventory.pos.update` | POController@update | INV-008 |
| 62 | DELETE | `/inventory/purchase-orders/{id}` | `inventory.pos.destroy` | POController@destroy | INV-008 |
| 63 | PATCH | `/inventory/purchase-orders/{id}/send` | `inventory.pos.send` | POController@sendToVendor | INV-008 |
| 64 | PATCH | `/inventory/purchase-orders/{id}/approve` | `inventory.pos.approve` | POController@approve | INV-008 |
| 65 | PATCH | `/inventory/purchase-orders/{id}/cancel` | `inventory.pos.cancel` | POController@cancel | INV-008 |
| 66 | POST | `/inventory/purchase-orders/from-pr/{pr}` | `inventory.pos.from-pr` | POController@convertFromPR | INV-008 |
| 67 | GET | `/inventory/grns` | `inventory.grns.index` | GrnController@index | INV-005 |
| 68 | POST | `/inventory/grns` | `inventory.grns.store` | GrnController@store | INV-005 |
| 69 | GET | `/inventory/grns/{id}` | `inventory.grns.show` | GrnController@show | INV-005 |
| 70 | PUT | `/inventory/grns/{id}` | `inventory.grns.update` | GrnController@update | INV-005 |
| 71 | DELETE | `/inventory/grns/{id}` | `inventory.grns.destroy` | GrnController@destroy | INV-005 |
| 72 | PATCH | `/inventory/grns/{id}/inspect` | `inventory.grns.inspect` | GrnController@inspect | INV-005 |
| 73 | POST | `/inventory/grns/{id}/accept` | `inventory.grns.accept` | GrnController@accept | INV-005 |
| 74 | PATCH | `/inventory/grns/{id}/reject` | `inventory.grns.reject` | GrnController@reject | INV-005 |
| 75 | GET | `/inventory/issue-requests` | `inventory.issue-requests.index` | IssueRequestController@index | INV-014 |
| 76 | POST | `/inventory/issue-requests` | `inventory.issue-requests.store` | IssueRequestController@store | INV-014 |
| 77 | GET | `/inventory/issue-requests/{id}` | `inventory.issue-requests.show` | IssueRequestController@show | INV-014 |
| 78 | PUT | `/inventory/issue-requests/{id}` | `inventory.issue-requests.update` | IssueRequestController@update | INV-014 |
| 79 | DELETE | `/inventory/issue-requests/{id}` | `inventory.issue-requests.destroy` | IssueRequestController@destroy | INV-014 |
| 80 | PATCH | `/inventory/issue-requests/{id}/approve` | `inventory.issue-requests.approve` | IssueRequestController@approve | INV-014 |
| 81 | PATCH | `/inventory/issue-requests/{id}/reject` | `inventory.issue-requests.reject` | IssueRequestController@reject | INV-014 |
| 82 | GET | `/inventory/stock-issues` | `inventory.stock-issues.index` | StockIssueController@index | INV-014 |
| 83 | POST | `/inventory/stock-issues` | `inventory.stock-issues.store` | StockIssueController@store | INV-014 |
| 84 | GET | `/inventory/stock-issues/{id}` | `inventory.stock-issues.show` | StockIssueController@show | INV-014 |
| 85 | PATCH | `/inventory/stock-issues/{id}/acknowledge` | `inventory.stock-issues.acknowledge` | StockIssueController@acknowledge | INV-014 |
| 86 | GET | `/inventory/stock-issues/{id}/print-slip` | `inventory.stock-issues.print-slip` | StockIssueController@printSlip | INV-014 |
| 87 | GET | `/inventory/stock-entries` | `inventory.stock-entries.index` | StockEntryController@index | INV-009 |
| 88 | GET | `/inventory/stock-entries/{id}` | `inventory.stock-entries.show` | StockEntryController@show | INV-009 |
| 89 | GET | `/inventory/stock-adjustments` | `inventory.adjustments.index` | AdjustmentController@index | INV-006 |
| 90 | POST | `/inventory/stock-adjustments` | `inventory.adjustments.store` | AdjustmentController@store | INV-006 |
| 91 | GET | `/inventory/stock-adjustments/{id}` | `inventory.adjustments.show` | AdjustmentController@show | INV-006 |
| 92 | PUT | `/inventory/stock-adjustments/{id}` | `inventory.adjustments.update` | AdjustmentController@update | INV-006 |
| 93 | PATCH | `/inventory/stock-adjustments/{id}/submit` | `inventory.adjustments.submit` | AdjustmentController@submit | INV-006 |
| 94 | PATCH | `/inventory/stock-adjustments/{id}/approve` | `inventory.adjustments.approve` | AdjustmentController@approve | INV-006 |
| 95 | PATCH | `/inventory/stock-adjustments/{id}/reject` | `inventory.adjustments.reject` | AdjustmentController@reject | INV-006 |
| 96 | GET | `/inventory/assets` | `inventory.assets.index` | AssetController@index | INV-011 |
| 97 | GET | `/inventory/assets/{id}` | `inventory.assets.show` | AssetController@show | INV-011 |
| 98 | PUT | `/inventory/assets/{id}` | `inventory.assets.update` | AssetController@update | INV-011 |
| 99 | POST | `/inventory/assets/{id}/transfer` | `inventory.assets.transfer` | AssetController@transfer | INV-012 |
| 100 | POST | `/inventory/assets/{id}/dispose` | `inventory.assets.dispose` | AssetController@dispose | INV-012 |
| 101 | GET | `/inventory/assets/{id}/maintenance` | `inventory.assets.maintenance.index` | AssetController@maintenanceIndex | INV-012 |
| 102 | POST | `/inventory/assets/{id}/maintenance` | `inventory.assets.maintenance.store` | AssetController@storeMaintenance | INV-012 |
| 103 | GET | `/inventory/assets/{id}/print-tag` | `inventory.assets.print-tag` | AssetController@printTag | INV-011 |
| 104 | GET | `/inventory/reports/stock-balance` | `inventory.reports.stock-balance` | InvReportController@stockBalance | INV-015 |
| 105 | GET | `/inventory/reports/stock-valuation` | `inventory.reports.stock-valuation` | InvReportController@stockValuation | INV-015 |
| 106 | GET | `/inventory/reports/stock-ledger` | `inventory.reports.stock-ledger` | InvReportController@stockLedger | INV-015 |
| 107 | GET | `/inventory/reports/consumption` | `inventory.reports.consumption` | InvReportController@consumption | INV-015 |
| 108 | GET | `/inventory/reports/purchase-register` | `inventory.reports.purchase-register` | InvReportController@purchaseRegister | INV-015 |
| 109 | GET | `/inventory/reports/pending-po` | `inventory.reports.pending-po` | InvReportController@pendingPO | INV-015 |
| 110 | GET | `/inventory/reports/grn-register` | `inventory.reports.grn-register` | InvReportController@grnRegister | INV-015 |
| 111 | GET | `/inventory/reports/reorder-alerts` | `inventory.reports.reorder-alerts` | InvReportController@reorderAlerts | INV-015 |
| 112 | GET | `/inventory/reports/fast-slow-movers` | `inventory.reports.fast-slow-movers` | InvReportController@fastSlowMovers | INV-015 |
| 113 | GET | `/inventory/reports/expiry-alerts` | `inventory.reports.expiry-alerts` | InvReportController@expiryAlerts | INV-015 |
| 114 | GET | `/inventory/reports/asset-register` | `inventory.reports.asset-register` | InvReportController@assetRegister | INV-011 |
| 115 | GET | `/inventory/reports/export/{type}` | `inventory.reports.export` | InvReportController@export | INV-015 |

**Total routes: 115** *(includes all state-transition routes; core CRUD+workflow is ~65 if counting only non-state routes)*

> **No update/delete routes exist for `inv_stock_entries`** — read-only per BR-INV-014 ✓

---

## Section 6 — Implementation Phases (7 Phases)

---

### Phase 1 — Masters
**FRs:** INV-001, INV-002, INV-003, INV-004
**Pre-requisite:** Migration run; seeders executed

| Artifact | Files |
|----------|-------|
| **Controllers** | InvDashboardController, StockGroupController, UomController, StockItemController, GodownController, AssetCategoryController |
| **Models** | StockGroup, UnitOfMeasure, UomConversion, StockItem, Godown, AssetCategory |
| **Services** | StockValuationService *(valuation_method assignment + getIssueCost stubs only)* |
| **FormRequests** | StoreStockGroupRequest, StoreUomRequest, StoreUomConversionRequest, StoreStockItemRequest, StoreGodownRequest |
| **Policies** | StockGroupPolicy, UomPolicy, StockItemPolicy, GodownPolicy, AssetCategoryPolicy |
| **Seeders** | InvUomSeeder, InvStockGroupSeeder, InvGodownSeeder, InvAssetCategorySeeder, InvSeederRunner |
| **Views** | 9 master views + 5 partials |
| **Tests** | StockGroupTest (8 tests), StockItemTest (10 tests), UomConversionTest (5 tests), GodownTest (5 tests) |

---

### Phase 2 — Vendor Linkage
**FRs:** INV-010 (partial — item-vendor + rate contracts)
**Pre-requisite:** VND module active (vnd_vendors table exists)

| Artifact | Files |
|----------|-------|
| **Controllers** | ItemVendorController, RateContractController |
| **Models** | ItemVendor (inv_item_vendor_jnt), RateContract, RateContractItem (inv_rate_contract_items_jnt) |
| **Services** | *(direct in controller — no dedicated service)* |
| **FormRequests** | StoreRateContractRequest |
| **Policies** | RateContractPolicy |
| **Events** | `RateContractExpiringSoon` |
| **Artisan** | `inventory:expire-rate-contracts` → runs daily midnight; updates status='expired' |
| **Views** | 6 vendor linkage views |
| **Tests** | RateContractTest (8 tests) |

---

### Phase 3 — Procurement (PR + Quotation + PO)
**FRs:** INV-007 (PR), INV-013 (RFQ), INV-008 (PO)
**Pre-requisite:** SCH module active (sch_department exists); VND module active

| Artifact | Files |
|----------|-------|
| **Controllers** | PurchaseRequisitionController, QuotationController, PurchaseOrderController |
| **Models** | PurchaseRequisition, PurchaseRequisitionItem, Quotation, QuotationItem, PurchaseOrder, PurchaseOrderItem |
| **Services** | PurchaseOrderService (createFromPR, createFromQuotation, createDirect, applyRateContract, checkApprovalThreshold) |
| **FormRequests** | StorePurchaseRequisitionRequest, StoreQuotationRequest, StorePurchaseOrderRequest |
| **Policies** | PurchaseRequisitionPolicy, PurchaseOrderPolicy |
| **Views** | 16 procurement views (PR list/create/show/import, Quotation list/create/show/compare, PO list/create/show/edit, GRN list/create/show/inspect) |
| **Tests** | PurchaseRequisitionTest (10 tests), QuotationTest (8 tests), PurchaseOrderTest (10 tests) |

**Key test scenarios:** PR CSV bulk import; RFQ comparison matrix; PO approval threshold enforcement (BR-INV-016); rate contract auto-apply on vendor change.

---

### Phase 4 — GRN & Stock Entry
**FRs:** INV-005 (GRN), INV-005a (QC), INV-009 (stock ledger)
**Pre-requisite:** Phase 3 complete (POs exist); ACC module VoucherServiceInterface available (or mocked)

| Artifact | Files |
|----------|-------|
| **Controllers** | GrnController, StockEntryController |
| **Models** | GoodsReceiptNote, GrnItem, StockEntry, StockBalance |
| **Services** | StockLedgerService (full), GrnPostingService (acceptGrn 10-step sequence) |
| **FormRequests** | StoreGrnRequest |
| **Policies** | GrnPolicy |
| **Events** | `GrnAccepted` *(payload: grn_id, po_id, vendor_id, voucher_id=null, items[{item_id, accepted_qty, unit_cost, godown_id}])* |
| **Artisan** | `inventory:recalculate-balances {--item=} {--godown=}` |
| **Views** | 4 GRN views + 2 stock ledger views |
| **Tests** | GrnTest (12 tests), StockLedgerServiceTest (8 tests), GrnPostingServiceTest (8 tests), StockBalanceTest (6 tests) |

**Key test scenarios:** BR-INV-006 (accepted+rejected=received); BR-INV-007 (cumulative PO overage); GrnAccepted event fires with correct payload; asset auto-creation on asset item acceptance; PO status auto-transition; `Event::fake()` used throughout.

---

### Phase 5 — Issue Workflow + Reorder
**FRs:** INV-014 (issue), INV-015 (reorder)
**Pre-requisite:** Phase 4 complete (stock entries and balances exist)

| Artifact | Files |
|----------|-------|
| **Controllers** | IssueRequestController, StockIssueController |
| **Models** | IssueRequest, IssueRequestItem, StockIssue, StockIssueItem |
| **Services** | StockIssueService (executeIssue 9-step sequence), ReorderAlertService (complete) |
| **Jobs** | `ReorderAlertJob` — `$tries = 3`, `$backoff = 60`, dispatched with 60s delay |
| **FormRequests** | StoreIssueRequestRequest, StoreStockIssueRequest |
| **Policies** | IssueRequestPolicy, StockIssuePolicy |
| **Events** | `StockIssued` *(payload: stock_issue_id, godown_id, department_id, items[{item_id, qty, unit_cost}])*; `ReorderThresholdReached` *(payload: item_id, godown_id, current_qty, reorder_level)* |
| **Artisan** | `inventory:check-reorder-levels` → daily morning |
| **Views** | 8 issue views + issue slip DomPDF |
| **Tests** | StockIssueTest (12 tests), ReorderAlertTest (6 tests), ReorderAlertServiceTest (5 tests) |

**Key test scenarios:** BR-INV-003 (negative stock prevention); FIFO batch selection (BR-INV-008); partial issue; auto-PR on reorder trigger; direct issue bypass; `Queue::fake()` for ReorderAlertJob.

---

### Phase 6 — Assets
**FRs:** INV-011 (asset register), INV-012 (maintenance + transfer + disposal)
**Pre-requisite:** Phase 4 complete (assets auto-created on GRN acceptance)

| Artifact | Files |
|----------|-------|
| **Controllers** | AssetController |
| **Models** | Asset, AssetMovement, AssetMaintenance |
| **Services** | *(direct queries in controller; no dedicated service)* |
| **Events** | `AssetDisposed` *(payload: asset_id, asset_tag, acc_fixed_asset_id, disposal_date)*; `MaintenanceOverdue` *(payload: asset_id, asset_tag, next_due_date)* |
| **Artisan** | `inventory:maintenance-overdue` → daily morning; fires MaintenanceOverdue per overdue record |
| **Views** | 8 asset views (register, detail, transfer, dispose, tag DomPDF, maintenance list/create, condition partial) |
| **Tests** | AssetTest (10 tests) |

**Key test scenarios:** Asset auto-created on GRN acceptance for asset items; one inv_assets record per unit; AssetDisposed event fires on dispose; movement history recorded per transfer.

---

### Phase 7 — Adjustments & Reports
**FRs:** INV-006 (adjustment), INV-015 (reports + labels)
**Pre-requisite:** Phase 4 complete (stock ledger exists for report data)

| Artifact | Files |
|----------|-------|
| **Controllers** | StockAdjustmentController, InvReportController |
| **Models** | StockAdjustment, StockAdjustmentItem |
| **Services** | InventoryReportService (all 12 reports + export); StockValuationService (complete — FIFO + WAC + LPC) |
| **FormRequests** | StoreStockAdjustmentRequest |
| **Policies** | StockAdjustmentPolicy |
| **Events** | `StockAdjusted` *(payload: adjustment_id, godown_id, items[{item_id, variance_qty, unit_cost}])* |
| **Views** | 4 adjustment views + 8 report views + export layout |
| **Tests** | StockAdjustmentTest (8 tests), StockValuationServiceTest (6 unit tests) |

**Key test scenarios:** `variance_qty` GENERATED column — never included in INSERT/UPDATE; BR-INV-017 (approval threshold for large adjustments); FIFO oldest-batch-first unit test; WAC recalculation on inward; report chunking at 500 rows.

---

## Section 7 — Seeder Execution Order

```
php artisan module:seed Inventory --class=InvSeederRunner
  ↓
  1. InvUomSeeder              — no dependencies; inserts 10 system UOMs
  ↓
  2. InvStockGroupSeeder       — depends on InvUomSeeder; resolves default_uom_id by symbol
  ↓
  3. InvGodownSeeder           — no dependencies; inserts 5 system godowns
  ↓
  4. InvAssetCategorySeeder    — no dependencies; inserts 5 categories with IT Act rates
```

**Minimum seeders per phase:**
- Phase 1 tests: `InvUomSeeder` + `InvStockGroupSeeder`
- Phase 3+ tests: add `InvGodownSeeder`
- Phase 6 tests: add `InvAssetCategorySeeder`

**Artisan Scheduled Commands** (`routes/console.php`):

```php
Schedule::command('inventory:expire-rate-contracts')->dailyAt('00:00');
Schedule::command('inventory:check-reorder-levels')->dailyAt('07:00');
Schedule::command('inventory:maintenance-overdue')->dailyAt('07:30');
```

| Command | Description |
|---------|-------------|
| `inventory:expire-rate-contracts` | Sets `status='expired'` for rate contracts past `valid_to`; fires `RateContractExpiringSoon` 30 days before |
| `inventory:check-reorder-levels` | Full scan of `inv_stock_balances`; dispatches `ReorderAlertJob` for items below threshold |
| `inventory:maintenance-overdue` | Marks `inv_asset_maintenance.status='overdue'` where `next_due_date < today AND status='scheduled'`; fires `MaintenanceOverdue` |
| `inventory:recalculate-balances` | Manual recovery: rebuilds `inv_stock_balances` by SUM of `inv_stock_entries`; takes `--item` and `--godown` options |

---

## Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests
**Namespace:** `Tests\Feature\Inventory\` (Feature) · `Tests\Unit\Inventory\` (Unit)

---

### Feature Test Setup
```php
uses(Tests\TestCase::class, RefreshDatabase::class);

// Event::fake() pattern for GRN and Stock Issue tests:
Event::fake([GrnAccepted::class, StockIssued::class, StockAdjusted::class]);
// → Verifies event was dispatched with correct payload
// → Accounting listener NOT called in tests; Inventory fires, Accounting owns listener

// Queue::fake() for reorder alert tests:
Queue::fake(); // assert ReorderAlertJob dispatched with correct arguments

// Bus::fake() for Artisan command tests:
Bus::fake(); // assert inventory:check-reorder-levels dispatches jobs
```

---

### Feature Test Files (13 files)

| File | Tests | Key Scenarios |
|------|-------|--------------|
| `StockGroupTest.php` | 8 | CRUD; hierarchy; cannot delete group with items; system group cannot be deleted |
| `StockItemTest.php` | 10 | CRUD; SKU uniqueness; valuation method assignment; reorder level; toggle status |
| `UomConversionTest.php` | 5 | Conversion factor > 0; from_uom != to_uom; effective date range validation |
| `GodownTest.php` | 5 | CRUD; self-ref parent; circular parent prevention |
| `RateContractTest.php` | 8 | Create with items; activate; expiry; auto-apply on PO creation |
| `PurchaseRequisitionTest.php` | 10 | Draft→submit→approve→convert; reject; CSV import; PR number auto-generation |
| `QuotationTest.php` | 8 | Create from PR; compare matrix returns all vendors; convert selected lines to PO |
| `PurchaseOrderTest.php` | 10 | Create from PR; approval threshold (BR-INV-016); partial GRN tracking; auto-close on full receipt |
| `GrnTest.php` | 12 | BR-INV-006 (accepted+rejected=received); BR-INV-007 (cumulative overage); accept fires GrnAccepted; asset created per unit; PO status auto-transition; `Event::fake()` |
| `StockIssueTest.php` | 12 | BR-INV-003 (negative stock rejected); partial issue; direct issue bypass; StockIssued event fires; FIFO batch selection; `Queue::fake()` for ReorderAlertJob |
| `StockAdjustmentTest.php` | 8 | Draft→submit→approve→post; BR-INV-017 threshold; variance_qty NOT in INSERT; StockAdjusted event |
| `AssetTest.php` | 10 | Auto-created on GRN acceptance; one per unit; transfer records movement; dispose fires AssetDisposed; maintenance schedule; overdue flag |
| `StockBalanceTest.php` | 6 | Balance updated after each entry; lockForUpdate prevents double-deduction; recalculate-balances Artisan rebuilds correctly |

---

### Unit Test Files (5 files)

| File | Tests | Key Scenarios |
|------|-------|--------------|
| `StockValuationServiceTest.php` | 6 | FIFO: oldest batch selected first (BR-INV-008); WAC recalculated correctly on inward; LPC returns latest GRN rate; negative balance rejected |
| `StockLedgerServiceTest.php` | 8 | Post inward increments balance; post outward decrements; BR-INV-003 guard throws exception; BR-INV-014 attempt to update posted entry throws ImmutableEntryException |
| `GrnPostingServiceTest.php` | 8 | Full 10-step acceptance sequence; partial accept; reject does not create stock entry; vendor rate updated; PO status transitions |
| `ReorderAlertServiceTest.php` | 5 | Alert dispatched when below threshold; NOT dispatched when above; auto-PR created when auto_reorder_pr=true; contract expiry alert 30 days ahead |
| `PurchaseOrderServiceTest.php` | 5 | createFromPR copies lines; rate contract auto-applied on vendor match; approval threshold correctly computed; PO status auto-transitions |

---

### Policy Test
```
InventoryPolicyTest.php
  - Store manager (has inventory.stock-item.create): can create GRN ✓
  - HOD: can create issue request for own department only ✓
  - Accountant: cannot create PO (no inventory.purchase-order.create) ✓
  - Principal: can approve PR and PO ✓
  - Admin: can do everything ✓
```

---

### Factory Requirements

```php
// Modules/Inventory/Database/Factories/

StockItemFactory          → valuation_method (random), reorder_level, item_type (consumable/asset)
PurchaseRequisitionFactory → pr_number = 'PR-' . date('Y') . '-' . str_pad($seq, 3, '0', STR_PAD_LEFT)
                             status = 'draft', items (HasMany relationship)
PurchaseOrderFactory      → po_number = 'PO-YYYY-NNN', vendor_id from vnd_vendors seeder
GrnFactory                → grn_number = 'GRN-YYYY-NNN', linked po_id, status = 'draft'
StockIssueFactory         → issue_number = 'SI-YYYY-NNN', godown_id from InvGodownSeeder
```

---

### ReorderAlertJob Specification
```php
// Modules/Inventory/app/Jobs/ReorderAlertJob.php

class ReorderAlertJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60; // 60 second delay between retries

    public function __construct(
        public readonly int $stockItemId,
        public readonly int $godownId,
        public readonly float $currentQty,
        public readonly float $reorderLevel
    ) {}

    public function handle(): void
    {
        // 1. Fire ReorderThresholdReached event
        // 2. If item.auto_reorder_pr: call ReorderAlertService::autoCreatePR()
        // 3. Notify store manager via ntf_notifications
    }
}
```

---

### Coverage Targets Summary

| Rule / Feature | Test Location | Assertion |
|----------------|-------------|-----------|
| BR-INV-001 (voucher_id mandatory) | StockLedgerServiceTest | `stock_entries.voucher_id` is never null |
| BR-INV-003 (no negative stock) | StockIssueTest | Throws `InsufficientStockException` |
| BR-INV-006 (GRN qty balance) | GrnTest | 422 when accepted+rejected ≠ received |
| BR-INV-007 (PO overage) | GrnTest | 422 when cumulative received > ordered |
| BR-INV-008 (FIFO batch) | StockValuationServiceTest | Oldest batch consumed first |
| BR-INV-014 (immutable entries) | StockLedgerServiceTest | Update throws `ImmutableEntryException` |
| BR-INV-017 (adjustment threshold) | StockAdjustmentTest | Requires approval above threshold |
| GrnAccepted event | GrnTest | `Event::assertDispatched(GrnAccepted::class)` |
| StockIssued event | StockIssueTest | `Event::assertDispatched(StockIssued::class)` |
| ReorderAlertJob dispatch | StockIssueTest | `Queue::assertPushed(ReorderAlertJob::class)` |
| Asset auto-creation | GrnTest | `assertDatabaseCount('inv_assets', $acceptedUnits)` |
| Concurrent balance writes | StockBalanceTest | Row-lock test via parallel transactions |

---

## Phase 3 Quality Gate

- [x] All 18 controllers listed with all methods
- [x] All 7 services listed with ≥ 3 key method signatures each
- [x] GrnPostingService 10-step acceptance sequence (pseudocode)
- [x] StockIssueService 9-step execution sequence (pseudocode)
- [x] All 13 FormRequests listed with key validation rules
- [x] All 15 FRs appear in at least one implementation phase (INV-001 to INV-015)
- [x] All 7 phases have: FRs covered, files to create, test count
- [x] Seeder execution order with dependency note (UOM before StockGroup)
- [x] All 4 Artisan commands with schedule
- [x] Route list consolidated with FR reference (115 routes; no update/delete on stock_entries)
- [x] View count: 67 total across all sub-modules
- [x] Test strategy includes `Event::fake()` for GrnAccepted/StockIssued
- [x] BR-INV-003 (negative stock) test explicitly referenced
- [x] BR-INV-014 (immutable entries) test explicitly referenced
- [x] `inv_stock_entries` has NO update/delete routes
- [x] ReorderAlertJob documented with `$tries=3`, `$backoff=60`
