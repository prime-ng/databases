# Stock Ledger — Business Requirements

## What This Screen Does

The Stock Ledger is a read-only, append-only journal of all stock movements. Every stock transaction — GRN receipts, stock issues, adjustments, and transfers — is recorded here as an immutable entry. The ledger provides a complete audit trail for inventory movements with entry type, quantity, rate, value, and narration.

This is the fourth tab (`?tab=ledger`) of the Stock Movement page at `/inventory/stock-movement`.

## When This Screen Is Used

- **Audit Trail**: Reviewing historical stock movements for any item
- **Value Tracking**: Monitoring stock movement values (quantity × rate)
- **Reconciliation**: Matching physical stock with ledger entries
- **Transaction Lookup**: Finding specific movements by item, godown, or date

## Key Fields

### Ledger Entry (inv_stock_entries)
- **Date** (created_at) — When the entry was recorded
- **Entry Type** — Enum: `inward` (GRN), `outward` (Issue), `transfer_in`, `transfer_out`, `adjustment`
- **Stock Item** (required) — FK to `inv_stock_items.id`
- **Quantity** (required) — Movement quantity, signed in display (+ for inbound, − for outbound)
- **Rate** (required) — Valuation rate per unit
- **Total Value** (auto-calculated) — `quantity × rate`
- **Godown** (required) — Source or destination godown
- **Batch Number** (optional) — Batch tracking
- **Expiry Date** (optional) — Batch expiry
- **Destination Godown** (optional) — Only for transfer entries
- **Narration** (optional) — Movement description, truncated to 30 chars in display
- **Voucher ID** (required) — Accounting voucher reference (BR-INV-001)

## Business Rules

### Append-Only (BR-INV-014)
Stock entries are IMMUTABLE. Once inserted, entries must never be UPDATEd or DELETEd. Soft delete is only possible via `StockLedgerService` guard and should never happen in normal operation.

### Voucher Mandatory (BR-INV-001)
`voucher_id` is a NOT NULL column — every stock entry must be linked to an accounting voucher. Currently set to 0 as a placeholder until the Accounting module goes live (D21).

### Entry Type Mapping (Display)
| DB Value | Display Label | Color |
|----------|--------------|-------|
| `inward` | Inward | Green/success |
| `outward` | Outward | Red/danger |
| `transfer_in` | Transfer In | Blue/info |
| `transfer_out` | Transfer Out | Blue/info |
| `adjustment_in` | Adjustment In | Yellow/warning |
| `adjustment_out` | Adjustment Out | Yellow/warning |
| `opening` | Opening | Green/success |

(Same as adjustments tab, the view maps `adjustment` to `adjustment_in`/`adjustment_out` based on variance sign.)

### Source Modules
Entries are posted by:
- **GRN Acceptance** → `inward` (via GrnPostingService)
- **Stock Issue** → `outward` (via StockIssueService)
- **Stock Adjustment** → `adjustment` (via StockAdjustmentService)
- **Bulk Transfer** → `transfer_out` from source, `transfer_in` to destination (via StockLedgerService)

### Filtering
Users can filter by:
- Item (dropdown: All Items / specific item)
- Godown (dropdown: All Godowns / specific godown)
- Free-text search (search within item name, narration, etc.)

## Related Screens

- **GRNs** — Post inward entries on acceptance
- **Stock Issues** — Post outward entries on issue execution
- **Stock Adjustments** — Post adjustment entries on approval
- **Bulk Transfer** — Posts transfer_out and transfer_in entries
- **Stock Items** — Items referenced by ledger entries
- **Godowns** — Locations referenced by ledger entries

## Requirements

- MUST display paginated ledger entries in a table with entry type badges and signed quantities
- MUST authorize for read-only access (viewAny, view)
- MUST NOT provide create/edit/delete operations from the UI
- MUST filter by item and godown via dropdowns
- MUST display quantity with +/− sign and color coding (green inbound, red outbound)
- MUST format rate and total value as ₹ currency
- MUST truncate narration at 30 chars with tooltip
- MUST display all entry types with correct labels and badge colors
- MUST support combined pagination with filter params
- MUST show appropriate empty state message
- MUST adhere to BR-INV-014 (immutable append-only ledger)
