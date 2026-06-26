# Quotations (RFQ) — Requirements

## What It Does
Manages the Request for Quotation (RFQ) process between an approved PR and PO conversion. Supports sending RFQs to multiple vendors, recording their quoted rates, generating a comparison matrix for side-by-side evaluation, and converting selected quotes to purchase orders. PR is optional (direct RFQ without PR).

## Database Fields

### inv_quotations

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `rfq_number` | VARCHAR(50) | Required. Unique. Auto-generated: RFQ-{YEAR}-{SEQUENCE}. |
| `pr_id` | BIGINT UNSIGNED FK → inv_purchase_requisitions | Nullable. Source PR. Null allowed for direct RFQ without PR. |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Required. INT UNSIGNED to match vnd_vendors.id. |
| `validity_date` | DATE | Nullable. Quote validity date. After this date, the quotation is stale. |
| `status` | ENUM('draft','sent','received','expired','converted') | Default 'draft'. |
| `notes` | TEXT | Nullable. RFQ-level notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### inv_quotation_items

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `quotation_id` | BIGINT UNSIGNED FK → inv_quotations | Required. ON DELETE CASCADE. |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| `quoted_rate` | DECIMAL(15,2) | Required. Vendor's quoted price per unit. |
| `lead_time_days` | INT | Nullable. Vendor lead time in days for this specific item. |
| `remarks` | VARCHAR(255) | Nullable. Line-level notes. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `rfq_number` | Required, string, max:50, unique | Auto-generated. Never user-provided. "The RFQ number has already been taken." |
| `pr_id` | Nullable, integer, exists:inv_purchase_requisitions,id | "The selected purchase requisition is invalid." If provided, must reference an existing PR. Null for direct RFQ. |
| `vendor_id` | Required, integer, exists:vnd_vendors,id | "The selected vendor is invalid." Must reference an existing active vendor. |
| `validity_date` | Nullable, date, after_or_equal:today | "The validity date must be today or a future date." Informational — the system does not auto-expire based on this field (expire is manual or via the status transition). |
| `status` | Required, enum | Set by state machine transitions. Never user-selectable directly. |
| `notes` | Nullable, string, max:5000 | Free-text notes at quotation header level. |
| `quoted_rate` (item line) | Required, numeric, min:0 | "The quoted rate must be at least 0." Must be a valid price per unit. |
| `item_id` (item line) | Required, integer, exists:inv_stock_items,id | "The selected item is invalid." Must reference an existing active stock item. |
| `lead_time_days` (item line) | Nullable, integer, min:0, max:999 | "The lead time must be between 0 and 999 days." |
| `remarks` (item line) | Nullable, string, max:255 | Line-level notes. |

### Entity-Specific Rules / Lifecycle State Machine

**Status Lifecycle:**
```
[Draft] ──send()──→ [Sent] ──receiveQuotes()──→ [Received] ──convertToPO()──→ [Converted]
                                                       │
                                                (comparison matrix)
                                                       │
                                                  select & convert

[Draft] ──expire()──→ [Expired]
[Sent] ──expire()──→ [Expired]
[Received] ──expire()──→ [Expired]
[Expired] ←── (terminal)
[Converted] ←── (terminal)
```

**Status Transition Details:**

**1. Draft → Sent (`send()`):**
- **Guard (at least 1 line item):** Quotation must have at least one inv_quotation_items record. Error: "Cannot send an RFQ with no items. Add at least one item first."
- **Guard (all quoted_rates > 0):** Every line item's `quoted_rate` must be >= 0. Error: "Line item #{line_number}: Quoted rate is required and must be a valid price."
- **Action:** Sets `status = 'sent'`.
- **Side effect:** Records a timestamp in `updated_at`.

**2. Sent → Received (`receiveQuotes()`):**
- **Guard (status must be 'sent'):** Error: "Cannot receive quotes for an RFQ with status '{current_status}'. Only sent RFQs can receive quotes."
- **Action:** Sets `status = 'received'`.
- **Side effect:** Notification can be sent that quotes have been received and are ready for comparison.

**3. Received → Converted (`convertToPO()`):**
- **Guard (status must be 'received'):** Error: "Cannot convert an RFQ with status '{current_status}'. Only received RFQs can be converted to purchase orders."
- **Guard (at least 1 line item):** Must have line items to convert. Error: "Cannot convert an RFQ with no items."
- **Action:** Sets `status = 'converted'`.
- **Side effect:** Selected line items are used to create a new `inv_purchase_orders` record with `quotation_id` referenced.
- **Side effect:** All line items become read-only after conversion.

**4. Any → Expired (`expire()`):**
- **Guard (status not already 'expired' or 'converted'):** Error: "Cannot expire an RFQ that is already {current_status}."
- **Action:** Sets `status = 'expired'`.
- Can be manual (user action) or automatic (scheduled command checking validity_date).

**RFQ Number Auto-Generation:**
- Pattern: `RFQ-{YEAR}-{SEQUENCE}`
- 4-digit zero-padded sequence: RFQ-2026-0001, RFQ-2026-0002, ...
- Generated in `QuotationService::generateRFQNumber()`:
  1. Get current year.
  2. Find highest RFQ number for current year.
  3. Extract numeric suffix, increment by 1.
  4. Format with zero padding.
  5. If none exist for year, start at RFQ-{YEAR}-0001.

**One Quotation Per Vendor Per PR Rule:**
- A PR can have at most one active (non-deleted, non-converted, non-expired) quotation per vendor.
- If a second quotation is attempted for the same (pr_id, vendor_id), the system checks:
  - If the existing quotation is in 'draft' status: block creation with error: "A draft RFQ already exists for this vendor and PR. Edit the existing draft instead."
  - If the existing quotation is in 'sent' or 'received' status: block creation with error: "An active RFQ already exists for this vendor and PR. Expire or cancel the existing RFQ first."
  - If the existing quotation is 'expired' or 'converted': Allow creation (the old one is terminal).
- This rule is enforced at the application level (no DB unique constraint on pr_id + vendor_id because a vendor can have multiple expired/converted quotes for the same PR over time).

### Data Integrity

**Unique Constraints:**
- `rfq_number` is UNIQUE. Auto-generated; never user-provided.
- No unique constraint on `(pr_id, vendor_id)` — multiple historical quotations per vendor per PR are allowed, but only one can be active (non-expired, non-converted, non-deleted) at any time.

**Foreign Key Cascades:**
- `inv_quotation_items.quotation_id` → `inv_quotations.id`: ON DELETE CASCADE.
- `inv_quotation_items.item_id` → `inv_stock_items.id`: Standard FK.
- `inv_quotations.pr_id` → `inv_purchase_requisitions.id`: ON DELETE SET NULL. If the source PR is deleted, the quotation retains its line items but `pr_id` becomes null.
- `inv_quotations.vendor_id` → `vnd_vendors.id`: Standard FK. Cannot delete vendor if referenced by active quotations.

**PR-Ready Check for PR-Linked RFQs:**
- When RFQ is created with a `pr_id`, the referenced PR must have status 'approved'.
- If PR status is not 'approved': "The selected purchase requisition must be in an approved state to create an RFQ."
- The PR remains 'approved' during the RFQ process — it is only converted to 'converted' when the PO is created.

### Comparison Matrix Rules (UI Feature)

**Comparison Matrix View:**
- Route: `GET /inventory/quotations/compare`.
- Query params: `pr_id` (required to scope comparison), optionally `item_ids[]`.
- Display: Table where rows = items, columns = vendor quotations.
- Each cell shows: quoted_rate, lead_time_days, remarks.
- The lowest quoted_rate per item is highlighted (green background).
- If vendor rates include tax (flagged in notes), and others are exclusive, the comparison should display both raw and estimated total.
- The comparison view is read-only — no edits allowed from this screen.
- Action button per row/vendor: "Select for PO Conversion" → triggers convertToPO() for selected vendor.

**PR Item Matching:**
- When comparison is viewed for items from a PR, only quotation items that match the PR's line items are displayed.
- If a vendor did not quote on a particular item, their column shows "Not Quoted" for that item.

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: status must NOT be 'converted'. Error: "Cannot delete a converted quotation."
2. Pre-delete check: status must NOT be 'received' (must expire first). Error: "Cannot delete a received quotation. Expire it first."
3. If status is 'draft', 'sent', or 'expired': delete allowed.
4. Pre-delete action: sets `is_active = 0`.
5. The quotation record gets `deleted_at` timestamp set.
6. Quotation items are NOT cascade soft-deleted (they remain for historical reference).
7. Audit log entry: action = "delete", entity_type = "inv_quotations", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records.
2. Sets `deleted_at` to NULL.
3. Does NOT set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_quotations", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records.
2. Pre-delete check: must not be referenced by any PO (where `quotation_id = {id}`). If referenced: "Cannot force delete this quotation because it has been converted to one or more purchase orders."
3. Permanently removes the record. Line items are cascade-deleted.
4. Audit log entry: action = "force_delete", entity_type = "inv_quotations", entity_id = {id}.

### Status Toggle (`is_active`)

- Route: `POST /inventory/quotations/{id}/toggle-status`
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- Pre-toggle guard: if toggling from 1→0 (deactivating), quotation must not be 'converted'. Error: "Cannot deactivate a converted quotation."
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, status transition (send, receive, expire, convert), soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On status transitions: log "RFQ {rfq_number}: status changed from {old} to {new} by {user_name}."
- On convert: log "RFQ {rfq_number} converted to purchase order PO-{po_number}."
- On create: log "RFQ {rfq_number} created for vendor {vendor_name} with {count} items."
- On comparison view access: No audit logging (read-only view).

### List View Rules

- Controller: `QuotationController@index`, Gate: `inventory.quotation.viewAny`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: vendor (vnd_vendors), pr (inv_purchase_requisitions — nullable), items count.
- Default sort: by created_at descending.
- Columns displayed: RFQ Number, Vendor Name, Source PR (linked if exists), Validity Date, Items Count, Status (badge with color: draft=gray, sent=blue, received=green, expired=red, converted=purple), Notes Preview, Actions (View, Edit, Send, Receive, Convert to PO, Expire, Delete).
- Filter: status dropdown.
- Filter: vendor (searchable select).
- Filter: pr_id (if a specific PR is selected, show only RFQs for that PR).
- Filter: date range (created_at).
- Search: by RFQ number or vendor name (text input).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated:
  - Send button: visible only on draft RFQs.
  - Receive button: visible only on sent RFQs.
  - Convert to PO button: visible only on received RFQs.
  - Expire button: visible on draft/sent/received (but not expired/converted).
  - Edit button: visible only on draft RFQs.
  - Delete button: visible only on deletable statuses.
- Quick stats bar at top: counts per status.

### Integration Rules

**PurchaseOrderService Integration (Convert RFQ to PO):**
- When an RFQ is converted to PO, `PurchaseOrderService::convertFromQuotation()` performs:
  1. Validates quotation status = 'received'.
  2. If `pr_id` is set, validates referenced PR is in 'approved' status.
  3. Creates a new `inv_purchase_orders` with `quotation_id = {quotation_id}` and `pr_id = {quotation.pr_id}`.
  4. Copies line items from `inv_quotation_items` to `inv_purchase_order_items` with `unit_price = quoted_rate`.
  5. Sets PO `vendor_id = quotation.vendor_id`.
  6. Marks quotation status as 'converted'.
  7. If PR existed and all quotations for the PR have been converted, PR can proceed to 'converted' status.
  8. Once converted, the quotation is read-only.

**Direct RFQ Without PR:**
- An RFQ can be created without a source PR (`pr_id = NULL`).
- This is used for direct procurement requests that bypass the formal PR workflow.
- The RFQ follows the same lifecycle but cannot be linked back to a PR for reporting.
- When converting to PO from a direct RFQ, the PO will have `pr_id = NULL`.

**Validity Date Enforcement:**
- The `validity_date` on the quotation header is informational.
- A scheduled command `inventory:expire-expired-rfqs` MAY be implemented to auto-expire RFQs where `validity_date < CURDATE()` and `status IN ('sent', 'received')`.
- If implemented, the command transitions: sent/received → expired.
- Manual expiration is always available regardless of validity_date.

**PR Status Integration:**
- When a PR-linked RFQ is created, the PR remains in 'approved' status.
- When that RFQ is converted to PO, the PR may transition to 'converted' if all lines are fulfilled.
- The PR's `status` is managed by PurchaseRequisitionController, not QuotationController — the quotation conversion sends an event or calls a service method to trigger the PR status check.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.quotation.viewAny` |
| View details | `inventory.quotation.view` |
| Create | `inventory.quotation.create` |
| Edit/update (draft only) | `inventory.quotation.update` |
| Send (Draft → Sent) | `inventory.quotation.send` |
| Receive (Sent → Received) | `inventory.quotation.receive` |
| Convert to PO | `inventory.quotation.convert-to-po` |
| Soft delete | `inventory.quotation.delete` |
| Restore | `inventory.quotation.restore` |
| Force delete | `inventory.quotation.forceDelete` |
