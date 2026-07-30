# Bulk Transfer — Business Requirements

## What This Screen Does

The Bulk Transfer screen enables movement of stock items between godowns. It posts transfer_out entries from the source godown and transfer_in entries to the destination godown in the stock ledger. There is no dedicated transfer table — all transfer records are stored as ledger entries in `inv_stock_entries`.

This is a standalone page at `/inventory/bulk-transfer`, separate from the Stock Movement tabs.

## When This Screen Is Used

- **Stock Rebalancing**: Moving excess stock from one godown to another
- **Consolidation**: Transferring stock to a central godown
- **Branch Supply**: Supplying stock from main store to sub-stores
- **Correction**: Fixing stock location errors

## Key Fields

### Transfer Parameters
- **From Godown** (required) — Source location, FK to `inv_godowns.id`
- **To Godown** (required) — Destination location, FK to `inv_godowns.id`; must differ from source
- **Items** (required, min:1) — Dynamic rows with:
  - **Stock Item** (required) — FK to `inv_stock_items.id`
  - **Quantity** (required) — DECIMAL(15,3), min 0.001
  - **Unit Cost** (optional) — Valuation rate per unit

## Business Rules

### Transaction Flow
Inside a DB transaction, for each item:
1. Posts `transfer_out` entry to `inv_stock_entries` from source godown
   - Sets `destination_godown_id` to target godown
   - Uses entry_type = `transfer_out`
2. Posts `transfer_in` entry to `inv_stock_entries` to destination godown
   - Uses entry_type = `transfer_in`

### Negative Stock Guard (BR-INV-003)
`StockLedgerService::postEntry()` for transfer_out entries checks that sufficient stock exists in the source godown before posting.

### Reference Generation
Reference number is auto-generated as `Bulk Transfer #` + `strtoupper(uniqid())`. No sequential format is used.

### No Dedicated Transfer Table
Unlike Issue Requests and Stock Issues, Bulk Transfer does not have a dedicated DB table. All data is stored as ledger entries in `inv_stock_entries`.

### Authorization
Uses the same `tenant.inventory.stock-issue.create` permission as Stock Issues.

### Cross-Module Dependencies
- `godown_from` / `godown_to` both reference `inv_godowns` (Inventory)
- `item_id` references `inv_stock_items` (Inventory)
- Stock ledger references `inv_stock_entries` (append-only, BR-INV-014)

## Workflow

1. Staff navigates to Inventory → Bulk Transfer (separate page)
2. Staff selects source and destination godowns (must differ)
3. Staff adds items with quantities and optional unit costs
4. Staff submits → system posts transfer_out from source and transfer_in to destination
5. Staff is redirected to Stock Movement page

## Related Screens

- **Stock Ledger** — Transfer entries appear as Transfer Out / Transfer In
- **Stock Issues** — Uses same create permission
- **Godowns** — Both source and destination godowns
- **Stock Items** — Items being transferred

## Requirements

- MUST display transfer form with From/To godown selects (different constraint)
- MUST validate with 6+ rules including items (min:1)
- MUST execute in a DB transaction
- MUST post transfer_out entry from source godown with destination_godown_id
- MUST post transfer_in entry to destination godown
- MUST generate reference number using 'Bulk Transfer #' + uniqid
- MUST guard: from/to godowns must differ (different validation)
- MUST guard against insufficient stock in source godown (BR-INV-003)
- MUST authorize via `tenant.inventory.stock-issue.create` permission
- MUST redirect to stock-movement page with success message
