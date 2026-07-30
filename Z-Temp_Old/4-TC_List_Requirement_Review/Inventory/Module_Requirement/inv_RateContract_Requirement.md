# Rate Contracts — Business Requirements

## What This Screen Does

The Rate Contracts screen manages fixed-price agreements with vendors for specific stock items over a defined validity period. Each contract belongs to one vendor and contains one or more items with agreed-upon rates. Rate contracts follow a lifecycle: Draft → Active → Expired (or Cancelled). Active contracts are locked from editing and deletion.

This is the first tab (`?tab=rate-contracts`) of the Vendor & Contracts page at `/inventory/vendor-contracts`.

## When This Screen Is Used

- **Vendor Pricing Agreement**: Locking in fixed rates for frequently purchased items
- **Procurement Reference**: Purchase Orders can reference rate contracts for pre-negotiated pricing
- **Rate Comparison**: Comparing rates across vendors for the same item
- **Contract Lifecycle Management**: Activating draft contracts, monitoring expirations

## Key Fields

### Rate Contract Header
- **Vendor** (required) — FK to `vnd_vendors.id` (cross-module: Vendor Management)
- **Contract Number** (optional, unique) — Reference number, max 50 characters (e.g., "RC-2026-001")
- **Valid From** (required) — Contract start date
- **Valid To** (required) — Contract end date; must be on or after Valid From
- **Status** (auto-managed) — Enum: `draft`, `active`, `expired`, `cancelled`
- **Remarks** (optional) — Notes, max 2000 characters

### Contract Items (Line Items)
- **Stock Item** (required) — FK to `inv_stock_items.id`; unique per contract (composite unique: rate_contract_id + item_id)
- **Agreed Rate** (required) — Fixed price per unit, DECIMAL(15,2)
- **Min Order Qty** (optional) — Minimum order quantity constraint
- **Max Order Qty** (optional) — Maximum order quantity constraint

## Business Rules

### Status Lifecycle
```
draft ──[activate]──→ active ──[auto-expire on valid_to]──→ expired
  │                      │
  └──[cancel]──→ cancelled     └──[cancel]──→ cancelled
```
- **draft**: Editable, deletable, items can be added/edited/removed
- **active**: Locked — cannot be edited (abort 403 on edit), cannot be deleted, items table shows "Locked"
- **expired**: Past `valid_to` date; read-only
- **cancelled**: Manually terminated; read-only

### Activation Guard
A contract can only be activated if:
1. Current status is `draft` (InvalidArgumentException if not)
2. Has at least one item (`items()->count() > 0`) (DomainException if zero)

### Edit Protection for Active Contracts
- `edit()` aborts with 403: "Active contracts cannot be edited."
- `update()` throws DomainException: "Active rate contract {number} cannot be edited. Deactivate it first."
- Items can only be added/edited/deleted when status is `draft`

### Delete Protection for Active Contracts
`delete()` throws DomainException: "Active rate contract {number} cannot be deleted."

### Cascade Soft-Delete
When a rate contract is soft-deleted, all its items are also soft-deleted via `$rc->items()->delete()` before `$rc->delete()`. Restore restores the contract but items are not automatically restored (only the contract is restored; items may need manual handling).

### Service Layer
All CRUD + lifecycle operations go through `RateContractService`:
- `create()`: Sets status=draft, creates nested items, logs 'Created'
- `update()`: Guards against active status, ignores items (managed via AJAX), logs 'Updated'
- `activate()`: Guards draft + items>0, sets status=active, logs 'Activated'
- `expire()`: Guards active status, sets status=expired, logs 'Expired'
- `cancel()`: Guards against already cancelled/expired, sets status=cancelled, logs 'Cancelled'
- `delete()`: Guards against active, cascade-deletes items, logs 'Deleted'

### Unique Constraints
- `contract_number` is unique when provided
- `(rate_contract_id, item_id)` is unique — same item cannot appear twice in one contract

### Cross-Module Dependencies
- `vendor_id` references `vnd_vendors` (Vendor module) — commented FK, validated via `exists` rule
- `item_id` references `inv_stock_items` (Inventory module) — hard FK with CASCADE

### Expiry Alert
The DDL comment mentions that an expiry alert fires 30 days before `valid_to`. This is likely implemented as an Artisan command (`inventory:rate-contract-expiry` or similar).

## Workflow

1. Staff navigates to Inventory → Vendor & Contracts → Rate Contracts tab
2. Staff views existing contracts as cards (contract number, vendor, validity dates, status badge, item count)
3. Staff clicks "Add Rate Contract" to open the create modal
4. Staff selects vendor, sets validity dates, optionally adds contract number and remarks
5. Staff adds at least one item with agreed rate, then saves (contract created as Draft)
6. Staff views contract detail page with items table
7. Staff adds/edits/removes additional items via AJAX modals
8. Staff activates the contract when ready (status changes to Active — locked)
9. Active contracts are referenced during PO creation for pre-negotiated pricing

## Related Screens

- **Item-Vendor Links** — Second tab on same page; links vendors to items with lead times and preferences
- **Stock Items** — Items referenced by contract items; must exist before creating contracts
- **Vendors** — Cross-module (Vendor Management); vendors must exist before creating contracts
- **Purchase Orders** — Can reference rate contracts for pricing
- **Purchase Requisitions** — Items requested can be sourced per rate contract rates

## Requirements

- MUST display paginated rate contracts at `/inventory/vendor-contracts?tab=rate-contracts` as cards with search and status filter
- MUST authorize via `tenant.inventory.rate-contract.*` policy gates (5 gates)
- MUST validate store with 11 rules including nested items array (min:1)
- MUST create contract with status=draft by default
- MUST create nested items during store
- MUST manage items via AJAX endpoints (CRUD) returning JSON
- MUST guard activation: only draft contracts with ≥1 items can be activated
- MUST guard edit/update: active contracts cannot be edited (403/DomainException)
- MUST guard delete: active contracts cannot be deleted (DomainException)
- MUST cascade soft-delete items when contract is deleted
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show contract detail page with contract details and items table
- MUST show "Locked" on item actions when contract is not draft
- MUST show Activate button only on draft contracts
- MUST enforce unique (rate_contract_id, item_id) per contract
- MUST enforce unique contract_number
- MUST log all CRUD and lifecycle operations via activityLog()
