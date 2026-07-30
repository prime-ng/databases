# Goods Receipt Notes — Business Requirements

## What This Screen Does

The Goods Receipt Notes (GRN) screen records the physical receipt of goods against Purchase Orders. Each GRN captures received quantities, QC inspection results (accepted/rejected), batch tracking, and triggers stock posting upon acceptance. GRNs follow a lifecycle: Draft (Received) → Inspected → Accepted (stock posted) or Rejected.

This is the fourth tab (`?tab=grns`) of the Procurement page at `/inventory/procurement`.

## When This Screen Is Used

- **Goods Receiving**: Recording physical receipt of goods from vendors
- **QC Inspection**: Inspecting received goods, accepting or rejecting quantities
- **Stock Entry**: Posting accepted goods to inventory stock ledger
- **Asset Creation**: Automatically creating asset records for asset-type items
- **PO Fulfillment**: Tracking received quantities against Purchase Orders

## Key Fields

### GRN Header
- **GRN Number** (auto-generated) — Format: GRN-YYYY-NNNN (e.g., "GRN-2026-0001")
- **Purchase Order** (required) — FK to `inv_purchase_orders.id`; filtered to sent/partial POs
- **Vendor** (required) — FK to `vnd_vendors.id` (cross-module: Vendor Management)
- **Receipt Date** (required) — Physical receipt date, default today
- **Godown** (required) — Receiving godown, FK to `inv_godowns.id`
- **Status** (auto-managed) — Enum: `draft`, `inspected`, `accepted`, `partial`, `rejected`
- **QC Status** (auto-managed) — Enum: `pending`, `passed`, `failed`, `partial`
- **QC Notes** (optional) — Inspector notes, max 2000 chars
- **Received By** (auto-set) — Current authenticated user
- **Voucher ID** (nullable) — Accounting voucher reference; set when Accounting module processes GrnAccepted event

### GRN Items
- **PO Item** (required) — FK to `inv_purchase_order_items.id`; identifies the source PO line
- **Stock Item** (required) — FK to `inv_stock_items.id`; auto-filled from PO item selection
- **Received Qty** (required) — Total quantity received, DECIMAL(15,3), min 0.01
- **Accepted Qty** (required) — Quantity passing QC inspection, DECIMAL(15,3), min 0
- **Rejected Qty** (required) — Quantity failing QC, DECIMAL(15,3); accepted + rejected = received (BR-INV-006)
- **Unit Cost** (required) — Actual cost per unit, DECIMAL(15,2); auto-filled from PO unit price
- **Batch Number** (optional) — For batch-tracked items, max 50 chars
- **Expiry Date** (optional) — Batch expiry date
- **QC Remarks** (optional) — Per-line QC notes, max 255 chars

## Business Rules

### Status Lifecycle
```
draft ──[store]──→ received ──[inspect]──→ inspected ──[accept]──→ accepted
                              │                              │
                              └──[reject]──→ rejected         └──[reject]──→ rejected
```
- **draft**: Initial state after store (displayed as "received" in view)
- **received**: Goods received, awaiting QC inspection
- **inspected**: QC inspection complete, pending stock acceptance
- **accepted**: Stock posted to ledger, PO quantities updated, assets created
- **rejected**: Entire GRN rejected (with qc_notes reason)

### QC Validation (BR-INV-006)
For each GRN item: `accepted_qty + rejected_qty` must equal `received_qty` (within 0.001 tolerance).
- Validated at request level in `StoreGrnRequest::withValidator()` after hook
- Validated at service level in `GrnPostingService::validateQcTotals()` before acceptance

### PO Balance Validation (BR-INV-007)
`received_qty` per item must not exceed `(po_item.ordered_qty - po_item.received_qty)`. This prevents receiving more than the PO balance.

### Stock Posting (Accept)
When `GrnPostingService::acceptGrn()` executes (inside a DB transaction):
1. Pre-flight: Validates QC totals (BR-INV-006) and PO balance (BR-INV-007)
2. For each item with accepted_qty > 0:
   a. Posts stock ledger entry (inward) via `StockLedgerService`
   b. Increments PO item `received_qty`
   c. Updates vendor last purchase cost via `StockValuationService`
   d. Creates asset records for asset-type items (1 record per integer unit) — BR-INV-012
   e. Checks and dispatches reorder alerts — BR-INV-011
3. Auto-transitions PO status (BR-INV-005):
   - All items fully received → PO status = `received`
   - Some items received → PO status = `partial`
4. Sets GRN status = `accepted`
5. Fires `GrnAccepted` event for Accounting module integration

### Asset Creation (BR-INV-012)
For stock items where `item_type === 'asset'`, asset records are created in `inv_assets`:
- One asset per integer unit of `accepted_qty` (ceil)
- Auto-generated asset tag: `ASSET-YYYY-NNNNN`
- Purchase cost = unit_cost, current book value = unit_cost
- Condition = 'good', warranty_expiry = null

### PO Auto-Transition (BR-INV-005)
After GRN acceptance, the PO status is reevaluated:
- `received` if all line items have received_qty ≥ ordered_qty
- `partial` if not all items are fully received
- Not changed if already in `received`, `closed`, or `cancelled` state

### Number Generation
GRN numbers generated by `GrnPostingService::generateGrnNumber()`: `GRN-YYYY-NNNN` (sequential per year).

### Edit Guard
Only GRNs with status `received` (pre-inspection) can be edited. Editing replaces all items (delete + recreate).

### Delete Guard
Only GRNs with status `received` (pre-inspection) can be deleted. Items cascade deleted.

### Update Guard
Only GRNs in `received` or `inspected` state can be rejected. Rejection requires required `qc_notes`.

### Service Layer
`GrnPostingService` handles all heavy lifting:
- `generateGrnNumber()`: Yearly sequential number generation
- `acceptGrn()`: Full acceptance workflow in transaction
- `validateQcTotals()`: BR-INV-006 enforcement
- `validateReceivedVsPo()`: BR-INV-007 enforcement
- `createAssetRecords()`: BR-INV-012 enforcement
- `autoTransitionPo()`: BR-INV-005 enforcement

### Cross-Module Dependencies
- `po_id` references `inv_purchase_orders` (Inventory) — hard FK
- `vendor_id` references `vnd_vendors` (Vendor Management) — validated via `exists` rule
- `godown_id` references `inv_godowns` (Inventory) — hard FK
- `item_id` references `inv_stock_items` (Inventory) — hard FK
- `received_by` references `sys_users` (System/Auth module)
- `voucher_id` references `acc_vouchers` (Accounting module, D21) — set via event
- Stock ledger entry affects `inv_stock_ledger` (Inventory)
- Asset creation affects `inv_assets` (Inventory)

## Workflow

1. Staff navigates to Inventory → Procurement → GRNs tab
2. Staff selects a sent/partial PO (AJAX loads PO items with quantities and rates)
3. Staff enters received quantities, initial accepted/rejected quantities, godown
4. Staff saves → GRN created in Received status
5. QC inspector opens the GRN, performs actual inspection
6. Inspector updates accepted_qty, rejected_qty, batch/expiry info, and QC remarks
7. QC inspection saved → GRN status = Inspected
8. Authorized staff accepts the GRN → Stock posted to ledger, PO quantities updated
9. For asset-type items, asset records are automatically created
10. If all PO items fully received, PO status auto-transitions to Received

## Related Screens

- **Purchase Orders** — Third tab; source POs for GRN creation; receive status updated by GRN acceptance
- **Purchase Requisitions** — First tab; origin of procurement request
- **Quotations** — Second tab; pricing source for PO
- **Godowns** — Inventory Masters; receiving location
- **Stock Items** — Items being received; asset-type items trigger asset creation
- **Stock Ledger** — Stock entries posted on GRN acceptance
- **Assets** — Asset records created for asset-type stock items

## Requirements

- MUST display paginated GRNs as cards with search and status filter
- MUST authorize via `tenant.inventory.grn.*` policy gates (6 gates including accept)
- MUST validate store with 17+ rules including nested items array (min:1)
- MUST validate accepted_qty + rejected_qty = received_qty per line (BR-INV-006)
- MUST generate unique grn_number in format GRN-YYYY-NNNN
- MUST create GRN with received_by set to authenticated user
- MUST support QC inspection flow: update items with inspection results
- MUST guard accept: only inspected GRNs with valid QC totals can be accepted
- MUST post stock ledger entries on acceptance (inward for accepted qty)
- MUST increment PO item received_qty on acceptance
- MUST auto-transition PO status on acceptance (BR-INV-005)
- MUST create asset records for asset-type items (1 per integer unit) (BR-INV-012)
- MUST validate PO balance before acceptance (BR-INV-007)
- MUST check and dispatch reorder alerts on acceptance (BR-INV-011)
- MUST fire GrnAccepted event for Accounting module integration
- MUST guard edit/update: only received (pre-inspection) GRNs can be edited
- MUST guard delete: only received (pre-inspection) GRNs can be deleted
- MUST support rejection with required qc_notes from received/inspected state
- MUST support soft-delete lifecycle with restore/force-delete
- MUST load PO items via AJAX on PO selection in create modal
- MUST auto-fill stock item and unit rate from PO item selection
- MUST log all CRUD and lifecycle operations via activityLog()
