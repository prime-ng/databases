# Purchase Orders — Requirements

## What It Does
Manages purchase orders sent to vendors. Can originate from PR conversion, quotation conversion, or direct creation. Features a full state machine (Draft → Approved → Sent → Partial → Received → Closed / Cancelled), configurable approval threshold enforcement (BR-INV-016), auto-received when all items are delivered (BR-INV-005), and auto-updated received_qty from GRNs.

## Database Fields

### inv_purchase_orders

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `po_number` | VARCHAR(50) | Required. Unique. Auto-generated: PO-{YEAR}-{SEQUENCE}. |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Required. INT UNSIGNED to match vnd_vendors.id. |
| `pr_id` | BIGINT UNSIGNED FK → inv_purchase_requisitions | Nullable. Source PR. NULL for direct PO. |
| `quotation_id` | BIGINT UNSIGNED FK → inv_quotations | Nullable. Source quotation. NULL for direct or PR-only PO. |
| `order_date` | DATE | Required. Date the PO was issued. |
| `expected_delivery_date` | DATE | Nullable. Promised delivery date from vendor. |
| `status` | ENUM('draft','sent','partial','received','cancelled','closed') | Default 'draft'. Note: 'approved' is a transient state between draft and sent when threshold exceeded. |
| `total_amount` | DECIMAL(15,2) | Default 0. Pre-tax subtotal (sum of line totals before tax). |
| `tax_amount` | DECIMAL(15,2) | Default 0. GST total (CGST + SGST or IGST). |
| `discount_amount` | DECIMAL(15,2) | Default 0. Total discount across all lines. |
| `net_amount` | DECIMAL(15,2) | Default 0. Final payable (total_amount + tax_amount - discount_amount). |
| `approved_by` | BIGINT UNSIGNED FK → sys_users | Nullable. Set when PO is approved. |
| `approval_threshold_amount` | DECIMAL(15,2) | Nullable. School's approval threshold captured at PO creation time. Compared against net_amount for BR-INV-016. |
| `terms_and_conditions` | TEXT | Nullable. PO terms and conditions. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_purchase_order_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `po_id` | BIGINT UNSIGNED FK → inv_purchase_orders | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| `ordered_qty` | DECIMAL(15,3) | Required. Quantity ordered. |
| `received_qty` | DECIMAL(15,3) | Default 0. Auto-updated by GrnPostingService. NOT user-editable. |
| `unit_price` | DECIMAL(15,2) | Required. Agreed unit price. |
| `tax_rate_id` | BIGINT UNSIGNED FK → acc_tax_rates | Nullable. GST rate applied to this line. |
| `discount_percent` | DECIMAL(5,2) | Default 0. Line-level discount percentage. |
| `total_amount` | DECIMAL(15,2) | Required. Line total after tax and discount. Computed: ordered_qty × unit_price × (1 - discount_percent/100) × (1 + tax_rate/100). |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `po_number` | Required, string, max:50, unique | Auto-generated. Never user-provided. "The PO number has already been taken." |
| `vendor_id` | Required, integer, exists:vnd_vendors,id | "The selected vendor is invalid." Vendor must be active. |
| `pr_id` | Nullable, integer, exists:inv_purchase_requisitions,id | "The selected purchase requisition is invalid." If provided, PR must be in 'approved' status. |
| `quotation_id` | Nullable, integer, exists:inv_quotations,id | "The selected quotation is invalid." If provided, quotation must be in 'received' status. |
| `order_date` | Required, date | "The order date is required." Defaults to today's date if not provided. |
| `expected_delivery_date` | Nullable, date, after_or_equal:order_date | "The expected delivery date must be on or after the order date." |
| `status` | Required, enum | Set by state machine transitions. Never user-selectable directly. |
| `total_amount` | Read-only (computed) | Computed from line items. Never accepted from user input. Recalculated on any line item change. |
| `tax_amount` | Read-only (computed) | Computed sum of line-level tax. Never user-input. |
| `discount_amount` | Read-only (computed) | Computed sum of line-level discounts. Never user-input. |
| `net_amount` | Read-only (computed) | Computed as `total_amount + tax_amount - discount_amount`. Never user-input. |
| `approved_by` | Read-only (system-set) | Set on approve action only. |
| `approval_threshold_amount` | Read-only (system-set) | Captured from school config at PO creation time. Not user-editable on existing PO. |
| `ordered_qty` (item line) | Required, numeric, gt:0 | "The ordered quantity must be greater than 0." |
| `received_qty` (item line) | Read-only (system-updated) | Auto-updated by GrnPostingService on GRN acceptance. Never user-input. If attempted: "Received quantity is auto-updated from GRN and cannot be manually set." |
| `unit_price` (item line) | Required, numeric, min:0 | "The unit price must be at least 0." |
| `tax_rate_id` (item line) | Nullable, integer, exists:acc_tax_rates,id | "The selected tax rate is invalid." |
| `discount_percent` (item line) | Required, numeric, min:0, max:100 | "The discount percent must be between 0 and 100." |
| `total_amount` (item line) | Read-only (computed) | Computed. Never user-input. Recalculated on any change to qty, unit_price, discount_percent, or tax_rate_id. |

### Entity-Specific Rules / Lifecycle State Machine

**Full Status Lifecycle:**
```
[Draft] ──approve()──→ [Approved] ──sendToVendor()──→ [Sent]
    │                                                        │
    │  (if net_amount < threshold)                           │
    └──────────── sendToVendor() ────────────────────────────┘

[Sent] ──partialGRN()──→ [Partial] ──finalGRN()──→ [Received] ──close()──→ [Closed]

[Draft] ──cancel()──→ [Cancelled]
[Approved] ──cancel()──→ [Cancelled]
[Sent] ──cancel()──→ [Cancelled]
[Partial] ──cancel()──→ ✗ (cannot cancel partial — goods already received)
[Received] ──cancel()──→ ✗ (cannot cancel received — goods received)
[Closed] ←── (terminal — cannot be modified or reopened)
[Cancelled] ←── (terminal — cannot be reverted)

Note: Auto-transition [Sent] → [Received] triggered when all items received_qty >= ordered_qty (BR-INV-005)
```

**State Transition Details:**

**1. Draft → Approved (`approve()`):**
- **Guard:** PO status must be 'draft'. Error: "Cannot approve a PO with status '{current_status}'. Only draft POs can be approved."
- **Guard (permission):** Auth user must have `inventory.purchase-order.approve` permission. Error: "You do not have permission to approve purchase orders."
- **Action:** Sets `status = 'approved'`, `approved_by = auth()->id()`.
- **Side effect:** Record approval in audit log.

**2. Draft → Sent (`sendToVendor()` — direct, bypassing approve):**
- **Guard (no threshold check needed):** If `net_amount < approval_threshold_amount`, the PO can go directly from Draft → Sent without explicit approval.
- **Guard (at least 1 line item):** Error: "Cannot send a PO with no items."
- **Pre-condition (vendor active):** Vendor must be active. If inactive: "Cannot send PO to an inactive vendor."
- **Action:** Sets `status = 'sent'`.
- **Side effect:** A `PO Sent` notification/event MAY be dispatched to the vendor (future: email integration).

**3. Approved → Sent (`sendToVendor()` — after approval):**
- **Guard (status must be 'approved'):** Error: "Cannot send a PO that has not been approved."
- **Action:** Sets `status = 'sent'`.
- **Side effect:** Same as direct send.

**4. Sent → Partial (`partialGRN()` — triggered by GrnPostingService):**
- This transition happens automatically when a GRN is accepted for some (but not all) of the PO's items.
- **Trigger:** `GrnPostingService::acceptGrn()` — after processing GRN acceptance, checks if any PO items have `received_qty < ordered_qty`.
- If at least one item has received_qty < ordered_qty, AND the PO was previously 'sent', transition to 'partial'.
- **Guard:** PO status must be 'sent'. If already 'partial' or 'received', no transition.
- **Action:** Sets `status = 'partial'`.
- This is NOT a user action — it is system-triggered.

**5. Sent/Partial → Received (`finalGRN()` / auto-transition — triggered by GrnPostingService):**
- **Trigger:** `GrnPostingService::acceptGrn()` — after processing GRN acceptance, checks if ALL PO items have `received_qty >= ordered_qty` (BR-INV-005).
- **Guard:** PO status must be 'sent' or 'partial'.
- If all items fully received, transition to 'received'.
- Even if received_qty > ordered_qty on some lines (over-receipt — see guard in GRN rules), the transition still fires.
- **Action:** Sets `status = 'received'`.
- **Side effect:** Fires event that PO is fully received (for reporting/dashboard).
- This is NOT a user action — it is system-triggered.

**6. Received → Closed (`close()`):**
- **Guard:** PO status must be 'received'. Error: "Cannot close a PO with status '{current_status}'. Only received POs can be closed."
- **Guard:** All items must have received_qty >= ordered_qty. If not: "Cannot close a PO with pending items. All items must be fully received."
- **Action:** Sets `status = 'closed'`.
- **Side effect:** An audit entry records the closure. After closing, no further GRNs can be created against this PO.

**7. Any → Cancelled (`cancel()`):**
- **Guard:** Status must NOT be 'partial', 'received', 'closed', or 'cancelled'. Error: "Cannot cancel a PO with status '{current_status}'. Only draft, approved, or sent POs can be cancelled."
- **Guard:** If PO has any GRNs (even rejected), cancellation may be blocked depending on business logic. Decision: If any GRN exists with status accepted or partial, block cancellation. Error: "Cannot cancel a PO that has accepted GRNs. Reverse the GRNs first."
- **Action:** Sets `status = 'cancelled'`.
- **Remarks:** Optional cancellation reason.

**Approval Threshold Enforcement (BR-INV-016):**
- The school has a configurable `po_approval_threshold` amount in the school settings/config.
- At PO creation time (before send), the current threshold is captured in `approval_threshold_amount`.
- If `net_amount >= approval_threshold_amount`:
  - The PO must go through Draft → Approved → Sent (two-step process).
  - The Send button is hidden/disabled until the PO is approved.
  - Error if attempting to send without approval: "This PO exceeds the approval threshold (₹{threshold}). It must be approved before sending."
- If `net_amount < approval_threshold_amount`:
  - The PO can go directly Draft → Sent (one-step process).
- If `approval_threshold_amount` is NULL (not configured): All POs require approval (conservative default).
- NOTE: The approved_by user can be the same user who created the PO (self-approval) — this is allowed unless a separate policy forbids it.

**PO Number Auto-Generation:**
- Pattern: `PO-{YEAR}-{SEQUENCE}`
- 4-digit zero-padded sequence: PO-2026-0001, PO-2026-0002, ...
- Generated in `PurchaseOrderService::generatePONumber()`:
  1. Get current year.
  2. Find highest PO number for current year.
  3. Extract numeric suffix, increment by 1.
  4. Format with zero padding.
  5. If none exist for year, start at PO-{YEAR}-0001.

**Amount Calculation Rules:**
All amount fields are READ-ONLY and computed automatically:
- `line total_amount` = `ordered_qty * unit_price * (1 - discount_percent/100) * (1 + tax_rate/100)`
  - If tax_rate_id is null: tax component is 0.
  - Tax rate is fetched from `acc_tax_rates.rate` (percentage, e.g., 18 for 18%).
- `header total_amount` = SUM of line `total_amount / (1 + tax_rate/100)` for all lines (pre-tax total).
- `header tax_amount` = SUM(line `total_amount - (line total_amount / (1 + tax_rate/100))`) for all lines.
- `header discount_amount` = SUM(line `ordered_qty * unit_price * discount_percent/100`) for all lines.
- `header net_amount` = header `total_amount + header tax_amount - header discount_amount`.

**Line Item Modifications by Status:**
- `draft`: Full CRUD on line items. Add, update, delete any line.
- `approved`: Line items are locked except unit_price (can be adjusted before sending). Reasonable adjustment allowed.
- `sent`: Line items are locked (read-only). No modifications allowed.
- `partial`: Line items are locked. received_qty is being updated by GRN — no manual changes.
- `received`: All fields locked. PO is complete.
- `closed`: All fields locked. PO is archived.
- `cancelled`: All fields locked. PO is void.

### Data Integrity

**Unique Constraints:**
- `po_number` is UNIQUE. Auto-generated; never user-provided.

**Foreign Key Cascades:**
- `inv_purchase_order_items.po_id` → `inv_purchase_orders.id`: ON DELETE CASCADE.
- `inv_purchase_order_items.item_id` → `inv_stock_items.id`: Standard FK.
- `inv_purchase_order_items.tax_rate_id` → `acc_tax_rates.id`: ON DELETE SET NULL (tax rate can be deleted, PO retains price).
- `inv_purchase_orders.vendor_id` → `vnd_vendors.id`: Standard FK. Cannot delete vendor if referenced by PO.
- `inv_purchase_orders.pr_id` → `inv_purchase_requisitions.id`: ON DELETE SET NULL. If source PR is deleted, PO retains reference but pr_id becomes null.
- `inv_purchase_orders.quotation_id` → `inv_quotations.id`: ON DELETE SET NULL.

**Received Qty Auto-Update (BR-INV-005 related):**
- `received_qty` on PO items is UPDATED ONLY by GrnPostingService.
- The field is never exposed in any create/update form request.
- If form validation detects a value in `received_qty`, it's silently ignored or raises: "Received quantity is managed by the system and cannot be manually entered."
- The update happens within the same DB transaction as the GRN acceptance.
- Calculation: `UPDATE inv_purchase_order_items SET received_qty = received_qty + {grn_accepted_qty} WHERE id = {po_item_id}`.

**Auto-Close on Full Receipt (BR-INV-005):**
- After every GRN acceptance, GrnPostingService checks: `SELECT COUNT(*) FROM inv_purchase_order_items WHERE po_id = {po_id} AND received_qty < ordered_qty`.
- If count = 0 (all items fully received), the PO status transitions to 'received'.
- If the PO was already 'partial', it transitions to 'received'.
- If the PO was already 'received', no change.
- This check is done AFTER the received_qty update in the same transaction.

**Over-Receipt Protection (BR-INV-007):**
- At GRN acceptance time, the system validates: `grn_item.received_qty <= (po_item.ordered_qty - po_item.received_qty)`.
- This prevents receiving more than the ordered quantity.
- Error if violated: "Cannot receive more than the ordered quantity for item {item_name}. Ordered: {ordered_qty}, Already received: {already_received}, Attempting to receive: {attempted_qty}."

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must be 'draft' or 'cancelled'. Error: "Cannot delete a PO with status '{current_status}'. Only draft or cancelled POs can be deleted."
2. Pre-delete check: PO must not have any associated GRNs. If GRNs exist: "Cannot delete a PO that has goods receipt notes."
3. Pre-delete action: sets `is_active = 0`.
4. The PO record gets `deleted_at` timestamp set.
5. PO items are NOT cascade soft-deleted.
6. Audit log entry: action = "delete", entity_type = "inv_purchase_orders", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_purchase_orders", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: must not be referenced by any GRN. If referenced: "Cannot force delete this PO because goods receipt notes exist against it."
3. Permanently removes the record. Line items cascade-deleted.
4. Audit log entry: action = "force_delete", entity_type = "inv_purchase_orders", entity_id = {id}.

### Status Toggle (`is_active`)

- Route: `POST /inventory/purchase-orders/{id}/toggle-status`
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), PO must be 'draft' or 'cancelled'. Error: "Cannot deactivate a PO that is in active workflow."
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, approve, send, cancel, close, soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On status transitions: log "PO {po_number}: status changed from {old_status} to {new_status} by {user_name}."
- On auto-transition (partial/received): log "PO {po_number}: auto-transitioned to {new_status} by GrnPostingService."
- On create (from PR): log "PO {po_number} created from PR {pr_number} by {user_name} with {count} items."
- On create (from quotation): log "PO {po_number} created from quotation {rfq_number} by {user_name}."
- On create (direct): log "PO {po_number} created directly for vendor {vendor_name} by {user_name}."
- On amount recalculations: log total_amount/tax_amount/discount_amount/net_amount changes (detected via getChanges()).
- Audit entries include: `entity_type = 'inv_purchase_orders'`, `entity_id = {id}`, `action = {action_type}`, `old_values`, `new_values`, `created_by`.

### List View Rules

- Controller: `PurchaseOrderController@index`, Gate: `inventory.purchase-order.viewAny`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: vendor (vnd_vendors), pr relationship, items count.
- Default sort: by created_at descending (most recent first).
- Columns displayed: PO Number, Vendor Name, Order Date, Expected Delivery Date, Net Amount (₹), Items Count, Received % (progress bar or fraction), Status (badge with color), Source (PR/Quotation/Direct badge), Actions (View, Edit, Send, Approve, Cancel, Close buttons).
- Filter: status dropdown (draft/approved/sent/partial/received/closed/cancelled/all).
- Filter: vendor (searchable select).
- Filter: date range (order_date from/to).
- Filter: amount range (net_amount min/max).
- Filter: source (PR-linked / quotation-linked / direct).
- Search: by PO number or vendor name (text input).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is role/permission-gated:
  - Send button: visible on draft (if net_amount < threshold) or approved (if threshold met).
  - Approve button: visible on draft when net_amount >= threshold.
  - Cancel button: visible on draft/approved/sent (but not partial/received/closed).
  - Close button: visible only on received.
  - Edit button: visible only on draft/approved.
  - Delete button: visible only on draft/cancelled.
- Row color: overdue expected_delivery_date (past and still sent/partial) highlighted orange.
- Quick stats bar: counts per status.

### Integration Rules

**GrnPostingService Integration (BR-INV-005, BR-INV-007):**
- GrnPostingService is the ONLY service that updates `received_qty` on PO items.
- On GRN acceptance, GrnPostingService:
  1. Validates received_qty <= PO ordered_qty - already_received (BR-INV-007).
  2. Updates `inv_purchase_order_items.received_qty += grn_item.accepted_qty`.
  3. Checks auto-transition conditions (BR-INV-005).
  4. If all items fully received, transitions PO to 'received'.
  5. If some items partially received (first partial GRN), transitions PO to 'partial'.
- All within the same DB transaction.

**PurchaseOrderService Integration (Convert from PR):**
- When converting PR to PO, service performs:
  1. Validates PR status = 'approved'.
  2. Creates PO header with pr_id linking.
  3. Copies PR line items to PO items.
  4. Pre-fills vendor from item's preferred vendor link.
  5. Pre-fills unit_price from active rate contract if available (BR-INV-013); otherwise from last purchase rate; otherwise leaves blank for manual entry.
  6. Computes initial amounts (total_amount, tax_amount, discount_amount, net_amount).
  7. Marks PR status as 'converted' (or partially converted).

**PurchaseOrderService Integration (Convert from Quotation):**
- When converting quotation to PO, service performs:
  1. Validates quotation status = 'received'.
  2. Sets PO's quotation_id and optionally pr_id (from quotation's pr_id).
  3. Copies quotation line items to PO items with unit_price = quoted_rate.
  4. Computes amounts.
  5. Marks quotation as 'converted'.

**Accounting Integration:**
- The PO itself does NOT create accounting entries (the GRN does, via GrnAccepted event).
- PO values are used for:
  - Budget planning reports.
  - Purchase register reports.
  - Commitment tracking (open POs = committed spend).

**Vendor Module Integration:**
- PO references vnd_vendors.vendor_id for vendor details (name, address, contact, GSTIN).
- Vendor details are read at PO creation time and displayed on the PO document.
- If vendor details change after PO creation, the PO retains the original information via the stored vendor_id FK (details can be looked up at print time).

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.purchase-order.viewAny` |
| View details | `inventory.purchase-order.view` |
| Create | `inventory.purchase-order.create` |
| Edit/update (draft/approved) | `inventory.purchase-order.update` |
| Approve (threshold) | `inventory.purchase-order.approve` |
| Soft delete | `inventory.purchase-order.delete` |
| Restore | `inventory.purchase-order.restore` |
| Force delete | `inventory.purchase-order.forceDelete` |
