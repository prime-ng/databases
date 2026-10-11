# Item-Vendor Links — Requirements

## What It Does
Manages the many-to-many relationship between stock items and vendors. Each link records the vendor's SKU for cross-reference, the last purchase rate and date (auto-updated on GRN acceptance), delivery lead time, and a preferred flag (one preferred vendor per item). Nested route under `items/{item}/vendors`.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `item_id` | BIGINT UNSIGNED FK → inv_stock_items | Required. |
| `vendor_id` | INT UNSIGNED FK → vnd_vendors | Required. INT UNSIGNED to match vnd_vendors.id. |
| `vendor_sku` | VARCHAR(50) | Nullable. Vendor's own item code for cross-reference. |
| `last_purchase_rate` | DECIMAL(15,2) | Nullable. Auto-updated on GRN acceptance. Not user-editable. |
| `last_purchase_date` | DATE | Nullable. Auto-updated on GRN acceptance. Not user-editable. |
| `lead_time_days` | INT | Nullable. Vendor delivery lead time in days. |
| `is_preferred` | TINYINT(1) | Default 0. 1 = preferred vendor for this item. Only one preferred per item allowed. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

### Field-Level Validation Rules

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `item_id` | Required, integer, exists:inv_stock_items,id | "The selected item is invalid." Must reference an existing stock item. |
| `vendor_id` | Required, integer, exists:vnd_vendors,id | "The selected vendor is invalid." Must reference an existing vendor record. |
| `vendor_sku` | Nullable, string, max:50 | Must not exceed 50 characters. If provided, stored as-is with whitespace trimmed. |
| `last_purchase_rate` | Read-only (system-updated) | Never accepted from user input. Updated only by GrnPostingService on GRN acceptance. |
| `last_purchase_date` | Read-only (system-updated) | Never accepted from user input. Updated only by GrnPostingService on GRN acceptance. |
| `lead_time_days` | Nullable, integer, min:0, max:999 | Must be between 0 and 999. Used for delivery planning and expected delivery date calculation. |
| `is_preferred` | Required, boolean, default 0 | Must be 0 or 1. If user sets to 1, system must first unset any other preferred vendor for the same item (application-level enforcement). |

### Entity-Specific Rules / Lifecycle State Machine

**Preferred Vendor Enforcement:**
- Only one vendor per item can have `is_preferred = 1` at any time.
- When setting `is_preferred = 1` on a link, the system must automatically set `is_preferred = 0` on the currently preferred link for the same item (if one exists).
- This enforcement happens within the same DB transaction to prevent race conditions.
- If no vendor is explicitly marked preferred, the item has no preferred vendor (all links have `is_preferred = 0`).

**Last Purchase Rate/Date Auto-Update (triggered by GrnPostingService):**
- When a GRN is accepted (status transitions to 'accepted'), GrnPostingService updates `last_purchase_rate` and `last_purchase_date` for the matching inv_item_vendor_jnt record.
- Matching criteria: GRN's `vendor_id` + each GRN item's `item_id` must match an existing inv_item_vendor_jnt record.
- If no matching link record exists (vendor not linked to that item), the system does NOT create one automatically — the GRN acceptance proceeds but no rate/date is recorded.
- `last_purchase_rate` is set to the `unit_cost` from the accepted GRN line item.
- `last_purchase_date` is set to the GRN's `receipt_date`.
- If multiple GRN items reference the same (item_id, vendor_id), the last chronologically processed line wins.
- These fields are computed and MUST NOT be exposed in any create/update form request. They are strictly read-only for API consumers.

**Vendor SKU Cross-Reference:**
- The `vendor_sku` field stores the vendor's own identification code for this item.
- Used when generating purchase orders to include the vendor's SKU for easy vendor-side reference.
- No uniqueness constraint beyond display/reference purposes.

**Lead Time Application:**
- When creating a PO with `expected_delivery_date`, if the selected vendor has a `lead_time_days` value on the link, the system MAY pre-populate `expected_delivery_date` as `order_date + lead_time_days` (application-level convenience, not enforced).
- Lead time is informational; the actual delivery date is set manually on the PO.

### Data Integrity

**Unique Constraint:**
- `(item_id, vendor_id)` is UNIQUE — a vendor can be linked to an item only once.
- Attempting to create a duplicate link returns: "This vendor is already linked to this item."

**Foreign Key Integrity:**
- `item_id` → `inv_stock_items.id`: Standard FK. Cannot delete a stock item that has vendor links without first removing links. DB-level CASCADE not defined; application must handle.
- `vendor_id` → `vnd_vendors.id`: Standard FK. INT UNSIGNED to match vnd_vendors.id. Cannot delete a vendor that has links without first removing links.

**Composite Uniqueness for Preferred Vendor:**
- The single-preferred-vendor constraint is enforced at the APPLICATION layer (not DB) because MySQL does not support partial unique indexes with conditions on TINYINT in all versions.
- Implementation: In `ItemVendorService::setPreferred()`, wrap the update in a DB transaction: `UPDATE inv_item_vendor_jnt SET is_preferred = 0 WHERE item_id = X AND is_preferred = 1` followed by `UPDATE inv_item_vendor_jnt SET is_preferred = 1 WHERE id = Y`.

### JSON Structure — Not applicable (no JSON columns).

### Soft Delete & Restore Rules

**Soft Delete:**
1. Pre-delete check: no active constraints (item-vendor links are reference data, not transactional records).
2. The record gets `deleted_at` timestamp set.
3. `is_active` is automatically set to 0.
4. The record remains in the database (soft-deleted).
5. Audit log entry: action = "delete", entity_type = "inv_item_vendor_jnt", entity_id = {id}.

**Restore:**
1. Only works on soft-deleted records (uses onlyTrashed() query scope).
2. Sets `deleted_at` to NULL.
3. Does NOT automatically set `is_active` back to 1.
4. Audit log entry: action = "restore", entity_type = "inv_item_vendor_jnt", entity_id = {id}.

**Force Delete:**
1. Only available on already soft-deleted records (uses withTrashed() scope).
2. Permanently removes the record from the database.
3. Audit log entry: action = "force_delete", entity_type = "inv_item_vendor_jnt", entity_id = {id}.

### Status Toggle (`is_active`)

- Route: `POST /inventory/item-vendors/{id}/toggle-status` (or nested under items).
- AJAX endpoint accepting JSON or form data.
- Toggles `is_active` between 0 and 1.
- No pre-toggle guard conditions (unlike hostels with occupancy checks).
- On success, returns JSON: `{"success": true, "is_active": bool, "message": "Status updated successfully."}`
- Audit log entry created on toggle.

### Audit Trail Rules

- Every create, update, soft delete, restore, force delete, and toggle-status action logs to `sys_activity_logs`.
- On create: log entity creation with item_id and vendor_id.
- On update: detect changed fields via `$model->getChanges()` (excluding updated_at, updated_by), log old/new values.
- On delete/restore: log the action type.
- The global `activityLog()` helper is called for each mutation.

### List View Rules

- Controller: `ItemVendorController`, accessed via nested routes `inventory/stock-items/{item}/vendors`.
- Pagination: 15 records per page via `->paginate(15)`.
- Eager loads: item, vendor (relationship names).
- Default sort: by vendor name ascending (or by created_at descending).
- Columns displayed: Vendor Name (from vnd_vendors), Vendor SKU, Last Purchase Rate, Last Purchase Date, Lead Time (days), Preferred (badge), Status (active/inactive badge), Actions (Edit, Delete).
- Filter: search by vendor name or vendor SKU (text input).
- Filter: is_preferred checkbox (show only preferred).
- All filters preserved across pagination via `->withQueryString()`.
- Actions column is permission-gated.
- Create button visible only if user has `inventory.item-vendor.create` permission.

### Integration Rules

**GrnPostingService Integration (BR-INV-013 related):**
- On GRN acceptance, GrnPostingService MUST update `last_purchase_rate` and `last_purchase_date` on the matching inv_item_vendor_jnt record.
- Service method call: `StockValuationService::updateLastPurchaseCost($itemId, $vendorId, $rate, $date)`.
- This update is part of the same DB transaction as the GRN acceptance and stock entry creation.
- If the update fails, the entire GRN acceptance transaction rolls back.

**PurchaseOrderService Integration:**
- When converting PR to PO, if the PR item has a preferred vendor link (`is_preferred = 1`), the system pre-fills the vendor selection in the PO creation form.
- If the preferred vendor also has an active rate contract for the item, the unit price is pre-filled from the rate contract (BR-INV-013).

**ReorderAlertJob Integration:**
- When auto-creating a Draft PR from reorder alert (if `auto_reorder_pr = true`), the system looks for the preferred vendor link (`is_preferred = 1`) for the item.
- If found, the PR's implied vendor preference is noted; if not found, no vendor preference is set.

**Item-Vendor Link as Cross-Module Dependency:**
- This table is read by the Vendor module (read-only, via tenant DB) to display which items a vendor supplies.
- No direct write access from Vendor module — all writes go through Inventory module's ItemVendorController.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `inventory.item-vendor.viewAny` |
| Create | `inventory.item-vendor.create` |
| Edit/update | `inventory.item-vendor.update` |
| Soft delete | `inventory.item-vendor.delete` |
| Restore | `inventory.item-vendor.restore` |
| Force delete | `inventory.item-vendor.forceDelete` |
