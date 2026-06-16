# Goods Receipt Notes (GRN) — Requirements

## What It Does
Manages goods receipt against purchase orders. GRN records physical receipt of goods, supports quality control inspection (pass/fail/partial per line), and upon acceptance triggers stock entry creation, stock balance updates, vendor last purchase rate updates, accounting voucher posting (through GrnAccepted event), and asset record creation for asset-type items.

## Database Fields

### inv_goods_receipt_notes

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `grn_number` | VARCHAR(50) | Required. Unique. Auto-generated: GRN-{YEAR}-{SEQUENCE}. |
| `po_id` | BIGINT UNSIGNED FK → inv_purchase_orders | Required. Source purchase order. |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Required. Denormalized from PO for query convenience. INT UNSIGNED. |
| `receipt_date` | DATE | Required. Date goods were physically received. |
| `godown_id` | BIGINT UNSIGNED FK → inv_godowns | Required. Receiving storage location. |
| `status` | ENUM('draft','inspected','accepted','partial','rejected') | Default 'draft'. |
| `qc_status` | ENUM('pending','passed','failed','partial') | Default 'pending'. |
| `qc_notes` | TEXT | Nullable. QC inspector notes at GRN header level. |
| `received_by` | BIGINT UNSIGNED FK → sys_users | Required. User who received the goods. |
| `voucher_id` | BIGINT UNSIGNED FK → acc_vouchers | Nullable. Set by GrnPostingService when GRN is accepted and Accounting creates the Purchase Voucher. NULL until accepted. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_grn_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `grn_id` | BIGINT UNSIGNED FK → inv_goods_receipt_notes | Required. ON DELETE CASCADE. |
| `po_item_id` | BIGINT UNSIGNED FK → inv_purchase_order_items | Required. Source PO item line. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. Denormalized from PO item. |
| `received_qty` | DECIMAL(15,3) | Required. Total quantity physically received. |
| `accepted_qty` | DECIMAL(15,3) | Required. Quantity that passed QC. |
| `rejected_qty` | DECIMAL(15,3) | Default 0. Quantity that failed QC. |
| `unit_cost` | DECIMAL(15,2) | Required. Actual cost per unit (may differ from PO unit_price). |
| `batch_number` | VARCHAR(50) | Nullable. For batch-tracked items. |
| `expiry_date` | DATE | Nullable. For expiry-tracked items. |
| `qc_remarks` | VARCHAR(255) | Nullable. Per-line QC inspector notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `grn_number` | Required, string, max:50, unique | Auto-generated. Never user-provided. "The GRN number has already been taken." |
| `po_id` | Required, integer, exists:inv_purchase_orders,id | "The selected purchase order is invalid." PO must exist and must NOT have status 'closed' or 'cancelled'. PO must be in 'sent' or 'partial' status to receive goods. |
| `vendor_id` | Required, integer, exists:vnd_vendors,id | Auto-populated from PO. Validated against PO's vendor_id. Mismatch error: "Vendor does not match the purchase order vendor." |
| `receipt_date` | Required, date | "The receipt date is required." Cannot be a future date. |
| `godown_id` | Required, integer, exists:inv_godowns,id | "The selected godown is invalid." Godown must be active. |
| `status` | Required, enum | Set by state machine transitions only. |
| `qc_status` | Required, enum | Set during inspection/acceptance. |
| `received_by` | Required, integer, exists:sys_users,id | Auto-set to auth user. |
| `voucher_id` | Read-only (system-set) | Nullable. Set by GrnPostingService after Accounting creates Purchase Voucher. Never user-input. |
| `received_qty` (item line) | Required, numeric, gt:0 | "The received quantity must be greater than 0." |
| `accepted_qty` (item line) | Required, numeric, min:0 | "The accepted quantity must be 0 or greater." |
| `rejected_qty` (item line) | Required, numeric, min:0, default 0 | "The rejected quantity must be 0 or greater." |
| `unit_cost` (item line) | Required, numeric, min:0 | "The unit cost must be at least 0." |
| `batch_number` (item line) | Nullable, string, max:50 | Required if item has `has_batch_tracking = 1`. If missing for batch-tracked item: "Batch number is required for item {item_name} as batch tracking is enabled." |
| `expiry_date` (item line) | Nullable, date | Required if item has `has_expiry_tracking = 1`. If missing: "Expiry date is required for item {item_name} as expiry tracking is enabled." If provided, must be in the future (or at least not already expired): "The expiry date must be a future date." |
| `po_item_id` (item line) | Required, integer, exists:inv_purchase_order_items,id | Must reference a valid PO item belonging to the same PO. Cross-PO validation error: "The PO item does not belong to the specified purchase order." |
| `qc_remarks` (item line) | Nullable, string, max:255 | Line-level QC notes. |

### Entity-Specific Rules / Lifecycle State Machine

**Full Status Lifecycle:**
```
[Draft] ──inspect()──→ [Inspected] ──accept()──→ [Accepted]
                            │              │
                        reject()      partialAccept()
                            │              │
                       [Rejected]      [Partial]
                            │              │
                       (terminal)    (open for further GRN)

[Accepted] ──fires──→ GrnAccepted event (side effects)
[Partial] ──fires──→ GrnAccepted event (for accepted lines only)
[Rejected] ←── (terminal — goods returned to vendor)
```

**QC Status Lifecycle:**
```
[pending] ──inspect()──→ [passed] (all items accepted_qty = received_qty)
[pending] ──inspect()──→ [failed] (all items accepted_qty = 0)
[pending] ──inspect()──→ [partial] (some items partially accepted)
[passed/failed/partial] ←── (no further transitions — set during inspect/accept)
```

**State Transition Details:**

**1. Draft → Inspected (`inspect()`):**
- **Guard (all line items have QC data):** Every line item must have `accepted_qty` and `rejected_qty` filled. Error: "All line items must have QC quantities entered before marking as inspected."
- **Guard (accepted_qty + rejected_qty = received_qty per line — BR-INV-006):** For each line: `received_qty` must equal `accepted_qty + rejected_qty`. Error: "Line item #{line_number}: The sum of accepted ({accepted}) and rejected ({rejected}) quantities ({sum}) does not equal received quantity ({received})."
- **Guard (batch_number for batch-tracked items):** For items with `has_batch_tracking = 1`, batch_number is required on each line. Missing: "Batch number is required for line #{line_number} ({item_name}) as batch tracking is enabled for this item."
- **Guard (expiry_date for expiry-tracked items):** For items with `has_expiry_tracking = 1`, expiry_date is required on each line. Missing: "Expiry date is required for line #{line_number} ({item_name}) as expiry tracking is enabled for this item."
- **Action:** Sets `status = 'inspected'`. Sets `qc_status` based on aggregate of line items:
  - If ALL items have `accepted_qty = received_qty`: `qc_status = 'passed'`.
  - If ALL items have `accepted_qty = 0`: `qc_status = 'failed'`.
  - If MIXED: `qc_status = 'partial'`.
- **Side effect:** Records inspection timestamp in `updated_at`.

**2. Inspected → Accepted (`accept()`):**
- **Guard (status must be 'inspected'):** Error: "Cannot accept a GRN with status '{current_status}'. Only inspected GRNs can be accepted."
- **Guard (all items pass BR-INV-006):** Re-validate `accepted_qty + rejected_qty = received_qty` per line (defense-in-depth).
- **Guard (BR-INV-007 — received_qty <= PO ordered balance):** For each line, validate: `received_qty <= (po_item.ordered_qty - po_item.received_qty)`. Error: "Line item #{line_number}: Cannot receive {received_qty} units of {item_name}. The PO has {ordered} ordered and {already_received} already received across prior GRNs. Maximum receivable: {balance}."
- **Guard (PO not closed/cancelled):** PO must be in 'sent' or 'partial' status. Error: "Cannot accept GRN because the purchase order is {po_status}. Only active POs can receive goods."
- **Action:** Sets `status = 'accepted'`.
- **Side effects (STEP 1: within same DB transaction — see Integration Rules below for full detail):**
  1. Fire `GrnAccepted` event → Accounting creates Purchase Voucher.
  2. `inv_stock_entries` (entry_type='inward') created for each accepted line.
  3. `inv_stock_balances` updated via `lockForUpdate()`.
  4. `inv_item_vendor_jnt.last_purchase_rate` and `last_purchase_date` updated.
  5. If `item_type = 'asset'`: `inv_assets` records created.
  6. PO `inv_purchase_order_items.received_qty` incremented.
  7. PO status auto-transitioned if fully received (BR-INV-005).
  8. `ReorderAlertJob` dispatched if balance <= reorder_level.
  9. GRN `voucher_id` set after Accounting responds with voucher ID.

**3. Inspected → Rejected (`reject()`):**
- **Guard (status must be 'inspected'):** Error: "Cannot reject a GRN with status '{current_status}'. Only inspected GRNs can be rejected."
- **Guard (qc_notes required):** Rejection reason must be provided. Error: "QC notes are required when rejecting a GRN."
- **Action:** Sets `status = 'rejected'`, `qc_status = 'failed'`.
- **Side effect:** No stock entries created. No accounting entries. The goods are assumed returned to vendor (out of scope for Inventory module).
- Audit log: "GRN {grn_number} rejected by {user_name}. Reason: {qc_notes}."

**4. Inspected → Partial (`partialAccept()`):**
- **Guard (status must be 'inspected'):** Error: "Cannot partially accept a GRN with status '{current_status}'."
- **Guard (at least 1 line fully accepted):** At least one line item must have `accepted_qty = received_qty`. Error: "Partial acceptance requires at least one fully accepted line item."
- **Action:** Sets `status = 'partial'`.
- **Side effects:** Same as accept() but only for fully accepted lines. Lines with `accepted_qty < received_qty` are treated as pending (will need a follow-up GRN or separate handling).
- **Behavior:** The GRN remains open at 'partial' status. A follow-up GRN against the same PO can be created for the remaining quantity. Partial GRN moves PO to 'partial' status (if not already).

**Terminal States:**
- `accepted`: Terminal — no further transitions. The GRN has been fully processed.
- `rejected`: Terminal — no further transitions. The GRN is void.
- `partial`: Can transition to 'accepted' if the remaining items are resolved? DECISION: No — 'partial' GRNs are NOT reopened. Partial GRNs remain at partial status. A NEW GRN should be created for subsequent receipts against the same PO items.

**GRN Number Auto-Generation:**
- Pattern: `GRN-{YEAR}-{SEQUENCE}`
- 4-digit zero-padded sequence: GRN-2026-0001, GRN-2026-0002, ...
- Generated in `GrnService::generateGRNNumber()`:
  1. Get current year: `date('Y')`.
  2. Find highest GRN number for current year using `LIKE 'GRN-{YEAR}-%'`.
  3. Extract numeric suffix, increment by 1.
  4. Format: `GRN-{YEAR}-{str_pad($seq, 4, '0', STR_PAD_LEFT)}`.
  5. If none exist for year, start at GRN-{YEAR}-0001.

**Multiple GRNs Against Same PO:**
- A PO can have multiple GRNs over time (for partial deliveries).
- Each GRN is independent with its own status workflow.
- The PO's `status` reflects the aggregate: 'sent' (no GRNs), 'partial' (some items partially received), 'received' (all items fully received).
- The PO's `status` does NOT go back from 'partial' to 'sent' — once any GRN exists, the PO is at least 'partial'.

### Data Integrity

**Unique Constraints:**
- `grn_number` is UNIQUE. Auto-generated.
- No composite unique constraint required — multiple GRNs against same PO are allowed.

**Foreign Key Cascades:**
- `inv_grn_items.grn_id` → `inv_goods_receipt_notes.id`: ON DELETE CASCADE.
- `inv_grn_items.po_item_id` → `inv_purchase_order_items.id`: Standard FK (no cascade).
- `inv_grn_items.item_id` → `inv_stock_items.id`: Standard FK.
- `inv_goods_receipt_notes.po_id` → `inv_purchase_orders.id`: Standard FK.
- `inv_goods_receipt_notes.vendor_id` → `vnd_vendors.id`: Standard FK.
- `inv_goods_receipt_notes.godown_id` → `inv_godowns.id`: Standard FK.
- `inv_goods_receipt_notes.received_by` → `sys_users.id`: Standard FK.
- `inv_goods_receipt_notes.voucher_id` → `acc_vouchers.id`: FK (nullable). Set only after Accounting creates voucher.

**QC Quantity Integrity (BR-INV-006):**
- For EVERY line item: `accepted_qty + rejected_qty = received_qty`.
- Enforced at:
  1. FormRequest validation: `accepted_qty + rejected_qty === received_qty`.
  2. Service layer re-validation: Same check in GrnPostingService.
  3. If database integrity is needed: a CHECK constraint can be added (MySQL 8.0.16+): `CHECK (accepted_qty + rejected_qty = received_qty)`.
- Error: "Line item #{line_number}: The sum of accepted ({accepted}) and rejected ({rejected}) quantities must equal the received quantity ({received})."

**Over-Receipt Prevention (BR-INV-007):**
- For every line item at acceptance time: `grn_item.received_qty <= (po_item.ordered_qty - po_item.current_received_qty)`.
- The `current_received_qty` is the SUM of all prior GRN items' accepted_qty for that PO item.
- This prevents over-receipt across ALL GRNs against the same PO.
- Error: "Line item #{line_number}: Cannot receive {grn_item.received_qty} units of {item_name}. Maximum receivable: {balance} (ordered: {ordered}, already received: {already_received})."

**Vendor ID Consistency:**
- The GRN's `vendor_id` is denormalized from the PO and must match.
- At create time: auto-populated from PO, not user-selected.
- If somehow a mismatch is attempted: "Vendor must match the purchase order's vendor."

**Voucher ID (Post-Acceptance):**
- `voucher_id` is NULL during drafting, inspection, and initial creation.
- It is set to a non-null value ONLY by GrnPostingService after:
  1. GRN is accepted.
  2. GrnAccepted event is fired.
  3. Accounting module processes the event and creates a Purchase Voucher.
  4. The Accounting response (or event listener callback) provides the `voucher_id`.
- If Accounting processing fails, the GRN acceptance transaction ROLLS BACK entirely.
- The `voucher_id` remains NULL and the GRN remains at 'inspected' status if the Accounting module is unavailable (future: retry mechanism).

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must be 'draft' or 'inspected' (before any acceptance). Error: "Cannot delete a GRN with status '{current_status}'. Only draft or inspected GRNs can be deleted."
2. Pre-delete check: GRN must NOT have `voucher_id` set. If voucher exists: "Cannot delete a GRN that has been posted to accounting. Contact the accounting department to reverse the voucher first."
3. Pre-delete action: sets `is_active = 0`.
4. The GRN record gets `deleted_at` timestamp set.
5. GRN items are NOT cascade soft-deleted.
6. Audit log entry: action = "delete", entity_type = "inv_goods_receipt_notes", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_goods_receipt_notes", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: GRN must not have associated stock entries (via voucher_id). If stock entries exist: "Cannot force delete this GRN because stock entries have been created from it."
3. Permanently removes the record. Line items cascade-deleted.
4. Audit log entry: action = "force_delete", entity_type = "inv_goods_receipt_notes", entity_id = {id}.

### Status Toggle (`is_active`)

- Route: `POST /inventory/grn/{id}/toggle-status`
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), GRN must be 'draft' or 'inspected' or 'rejected'. Error: "Cannot deactivate a GRN that has been accepted or partially accepted."
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, inspect, accept, reject, partial-accept, soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On accept: log "GRN {grn_number} accepted by {user_name}. {count} items received. Stock entries created."
- On reject: log "GRN {grn_number} rejected by {user_name}. Reason: {qc_notes}."
- On partial accept: log "GRN {grn_number} partially accepted by {user_name}. {accepted_count} items stocked. Voucher ID: {voucher_id}."
- On inspect: log "GRN {grn_number} inspected by {user_name}. QC status: {qc_status}."
- On voucher_id set: log "GRN {grn_number} voucher posted. Voucher ID: {voucher_id}."
- The global `activityLog()` helper is called for each mutation.

### List View Rules

- Controller: `GrnController@index`, Gate: `inventory.grn.viewAny`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: po (inv_purchase_orders), vendor (vnd_vendors), godown (inv_godowns), items count.
- Default sort: by created_at descending (most recent first).
- Columns displayed: GRN Number, PO Number, Vendor Name, Receipt Date, Godown, Items Count, QC Status (badge: pending=gray, passed=green, failed=red, partial=orange), Status (badge with color), Voucher ID (or "Pending" badge if null), Actions (View, Edit, Inspect, Accept, Reject, Delete buttons).
- Filter: status dropdown.
- Filter: po_id (select/search by PO number).
- Filter: vendor (searchable select).
- Filter: date range (receipt_date from/to).
- Filter: qc_status dropdown.
- Search: by GRN number, PO number, or vendor name (text input).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated:
  - Inspect button: visible only on draft GRNs.
  - Accept button: visible only on inspected GRNs with qc_status != 'failed'.
  - Reject button: visible only on inspected GRNs.
  - Edit button: visible only on draft GRNs.
  - Delete button: visible only on draft/inspected/rejected GRNs.
- Quick stats bar: counts per status, plus "Pending Voucher" count (accepted GRNs with null voucher_id).

### Integration Rules

**GrnPostingService :: acceptGrn() — Full Transaction Detail:**

The entire accept flow is wrapped in `DB::transaction()` to ensure atomicity:

```
Step 1: Validate all pre-conditions
  ├── GRN status == 'inspected'
  ├── Per line: accepted_qty + rejected_qty == received_qty (BR-INV-006)
  ├── Per line: received_qty <= (po.ordered_qty - po.received_qty) (BR-INV-007)
  └── PO status IN ('sent', 'partial')

Step 2: Fire GrnAccepted event (BEFORE accounting, AFTER validation)
  └── Event payload: {
        grn_id, vendor_id, godown_id,
        items: [{item_id, qty=accepted_qty, rate=unit_cost, amount, batch_number}],
        total_amount, purchase_ledger_id, party_ledger_id, narration
      }
  └── Accounting module listens, creates Purchase Voucher, returns voucher_id

Step 3: Create inv_stock_entries (one per accepted line item)
  └── entry_type = 'inward'
  └── quantity = accepted_qty
  └── rate = unit_cost
  └── amount = accepted_qty * unit_cost
  └── voucher_id = (from Step 2 response)
  └── batch_number, expiry_date carried forward from GRN item

Step 4: Update inv_stock_balances
  └── lockForUpdate() on balance row
  └── current_qty += accepted_qty
  └── current_value += accepted_qty * unit_cost (via valuation method)
  └── last_entry_at = now()

Step 5: Update inv_item_vendor_jnt (last purchase tracking)
  └── last_purchase_rate = unit_cost
  └── last_purchase_date = receipt_date
  └── Where (item_id, vendor_id) matches

Step 6: Create inv_assets for asset-type items (BR-INV-012)
  └── IF item_type == 'asset' AND accepted_qty > 0
  └── Create ceil(accepted_qty) inv_assets records
  └── asset_tag: ASSET-{YEAR}-{SEQUENCE} (auto-generated per record)
  └── Each record: condition = 'good', godown_id = GRN godown, purchase_date = receipt_date

Step 7: Update PO item received_qty
  └── inv_purchase_order_items.received_qty += accepted_qty

Step 8: Auto-transition PO status (BR-INV-005)
  └── Check if ALL PO items have received_qty >= ordered_qty
  └── If yes AND PO status is 'sent' or 'partial': transition to 'received'
  └── If some items partially received AND PO status is 'sent': transition to 'partial'

Step 9: Set GRN voucher_id
  └── inv_goods_receipt_notes.voucher_id = (from Step 2)


Step 10: Dispatch async jobs (AFTER transaction commits)
  └── ReorderAlertJob::dispatch() for each item where balance <= reorder_level (BR-INV-011)
```

**Asset Item Handling on GRN Acceptance (BR-INV-012):**
- When a GRN line item has `item_type = 'asset'` in the stock item master, and `accepted_qty > 0`.
- The system creates `ceil(accepted_qty)` individual `inv_assets` records (one per physical unit).
- Each asset record receives an auto-generated `asset_tag` in format `ASSET-{YEAR}-{SEQUENCE}`.
- Asset category is determined from item's stock group → mapped to inv_asset_categories (application-level mapping).
- The `grn_item_id` is stored on the asset record for traceability.

**Voucher ID Handling:**
- `voucher_id` is NULL on GRN until acceptance.
- The GrnAccepted event is synchronous (or at least awaited) to obtain the voucher_id.
- If the Accounting module is unavailable or returns an error, the entire transaction ROLLS BACK.
- Future enhancement: An async retry mechanism for voucher creation could be implemented, but initially synchronous is required per D21.

**PO Status Auto-Transition:**
- After each GRN acceptance, GrnPostingService calls `PurchaseOrderService::autoTransitionStatus()`.
- This method checks all PO items and transitions the PO status accordingly.
- The transition is logged: "PO {po_number} auto-transitioned to {status} after GRN {grn_number} acceptance."

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.grn.viewAny` |
| View details | `inventory.grn.view` |
| Create | `inventory.grn.create` |
| Edit/update (draft only) | `inventory.grn.update` |
| Inspect (Draft → Inspected) | `inventory.grn.inspect` |
| Accept (Inspected → Accepted) | `inventory.grn.accept` |
| Reject (Inspected → Rejected) | `inventory.grn.reject` |
| Soft delete | `inventory.grn.delete` |
| Restore | `inventory.grn.restore` |
| Force delete | `inventory.grn.forceDelete` |
