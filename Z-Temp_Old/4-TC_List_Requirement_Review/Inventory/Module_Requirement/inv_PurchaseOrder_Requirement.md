# Purchase Orders — Business Requirements

## What This Screen Does

The Purchase Orders (PO) screen manages formal purchase agreements with vendors. Each PO specifies items, quantities, agreed prices, tax rates, discounts, and delivery terms. POs follow a lifecycle: Draft → Approved → Sent → Partially Received / Received → Closed.

This is the third tab (`?tab=pos`) of the Procurement page at `/inventory/procurement`.

## When This Screen Is Used

- **Vendor Ordering**: Issuing formal purchase orders to vendors
- **Approval Workflow**: POs require internal approval before dispatch
- **Receiving Tracking**: Monitoring received quantities against ordered quantities
- **Conversion**: Creating POs from approved PRs or received Quotations
- **Rate Contract Integration**: Pre-filling rates from active rate contracts during PR conversion

## Key Fields

### PO Header
- **PO Number** (auto-generated) — Format: PO-YYYY-NNNN (e.g., "PO-2026-0001")
- **Vendor** (required) — FK to `vnd_vendors.id` (cross-module: Vendor Management)
- **PR Reference** (optional) — FK to `inv_purchase_requisitions.id`; source PR
- **Quotation Reference** (optional) — FK to `inv_quotations.id`; source quotation
- **Order Date** (required) — PO issue date, default today
- **Expected Delivery Date** (optional) — Must be on or after Order Date
- **Status** (auto-managed) — Enum: `draft`, `sent`, `partial`, `received`, `cancelled`, `closed`
- **Total Amount** (auto-calculated) — Pre-tax subtotal
- **Tax Amount** (auto-calculated) — GST total (CGST+SGST or IGST)
- **Discount Amount** (auto-calculated) — Total discount
- **Net Amount** (auto-calculated) — Final payable = total - discount + tax
- **Approved By** (set on approval) — User who approved
- **Approval Threshold Amount** (captured at PO creation) — School's approval threshold for BR-INV-016
- **Terms & Conditions** (optional) — PO terms, max 5000 chars

### PO Items
- **Stock Item** (required) — FK to `inv_stock_items.id`
- **Ordered Qty** (required) — DECIMAL(15,3), min 0.001
- **Received Qty** (auto-updated) — Total received across all GRNs; updated by GrnPostingService
- **Unit Price** (required) — Agreed unit price, DECIMAL(15,2)
- **Discount Percent** (optional) — Line-level discount, max 100%
- **Tax Rate** (optional) — FK to `acc_tax_rates.id` (cross-module: Accounting)
- **Line Total** (auto-calculated) — After applying discount and tax

## Business Rules

### Status Lifecycle
```
draft ──[approve]──→ approved ──[send]──→ sent ──[receive goods]──→ partial/received ──[close]──→ closed
  │
  └──[cancel]──→ cancelled
```
- **draft**: Editable, deletable; Awaiting internal approval
- **approved**: Approved internally; ready to send to vendor
- **sent**: Dispatched to vendor; awaiting goods receipt
- **partial**: Some items received (auto-set by GrnPostingService)
- **received**: All items fully received (auto-set by GrnPostingService)
- **closed**: Manually closed after full delivery and settlement
- **cancelled**: PO cancelled before or after sending

### Amount Calculation
Line total = ordered_qty × unit_price
After discount: line_total - (line_total × discount_percent / 100)
After tax: line_total + (line_total × tax_rate / 100)
Header totals: sum of all item line totals

### Auto-Transition on GRN
When GRN items are accepted:
- `POItem.received_qty` is incremented
- If all items have received_qty ≥ ordered_qty → PO status = `received`
- If some items received → PO status = `partial`

### Convert PR to PO
`PurchaseOrderService::convertPrToPo()`:
1. Creates PO header with vendor from PR's linked vendor (or prompts)
2. Copies PR items as PO items
3. Pre-fills unit_price from active rate contracts (if available for the item-vendor pair)
4. Pre-fills tax_rate from default item tax rate
5. Redirects to PO edit page for adjustments

### Number Generation
`PurchaseOrderService` provides 3 generators:
- `generatePoNumber()` — PO-YYYY-NNNN
- `generatePrNumber()` — PR-YYYY-NNNN (shared for PRs)
- `generateRfqNumber()` — RFQ-YYYY-NNNN (shared for Quotations)

### Service Layer
Operations go through `PurchaseOrderService`:
- `create()`: Generates po_number, sets status=draft, creates items, calculates amounts, logs activity
- `update()`: Updates header + replaces items, recalculates amounts, logs activity
- `delete()`: Guards non-draft status, soft-deletes, logs activity
- `convertPrToPo()`: Creates PO from approved PR with rate contract pre-fill

### Cross-Module Dependencies
- `vendor_id` references `vnd_vendors` (Vendor Management) — validated via `exists` rule
- `pr_id` references `inv_purchase_requisitions` (Inventory) — FK ON DELETE SET NULL
- `quotation_id` references `inv_quotations` (Inventory) — FK ON DELETE SET NULL
- `tax_rate_id` references `acc_tax_rates` (Accounting) — validated via `exists` rule
- `approved_by` references `sys_users` (System/Auth module)

## Workflow

1. Staff navigates to Inventory → Procurement → POs tab
2. Staff creates PO directly (selects vendor, items, rates) or converts from an approved PR
3. PO is created as Draft with calculated amounts
4. Internal approver approves the PO (status → Approved)
5. PO is sent to vendor (status → Sent)
6. Vendor delivers goods partially or fully
7. GRN is created against the PO, updating received quantities
8. PO status auto-updates to Partial or Received based on fulfillment
9. PO is closed after all items received and accounts settled

## Related Screens

- **Purchase Requisitions** — First tab; source for PO conversion
- **Quotations** — Second tab; source for PO pricing
- **GRNs** — Fourth tab; goods receipt updates PO received quantities
- **Vendors** — Cross-module (Vendor Management)
- **Stock Items** — Items referenced by PO line items
- **Tax Rates** — Cross-module (Accounting)
- **Rate Contracts** — Pre-negotiated pricing for PR-to-PO conversion

## Requirements

- MUST display paginated POs as cards with search and status filter
- MUST authorize via `tenant.inventory.purchase-order.*` policy gates (5 gates)
- MUST validate store with 12+ rules including nested items (min:1)
- MUST generate unique po_number in format PO-YYYY-NNNN
- MUST create PO with status=draft by default
- MUST create nested items during store
- MUST calculate total, discount, tax, and net amounts automatically
- MUST guard approve: only draft POs can be approved
- MUST guard send: only approved POs can be sent
- MUST auto-transition PO status based on item received quantities
- MUST convert approved PR to PO with rate contract rate pre-fill
- MUST provide JSON endpoint for PO items (used by GRN create)
- MUST guard delete for non-draft POs
- MUST support soft-delete lifecycle
- MUST log all CRUD operations via activityLog()
