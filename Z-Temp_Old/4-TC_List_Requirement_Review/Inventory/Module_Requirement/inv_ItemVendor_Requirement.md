# Item-Vendor Links — Business Requirements

## What This Screen Does

The Item-Vendor Links screen manages which vendors supply each stock item, along with vendor-specific information like the vendor's SKU for cross-referencing, lead times, last purchase rates, and preferred vendor status. This is the junction/pivot between Stock Items (Inventory) and Vendors (Vendor Management module).

This is the second tab (`?tab=item-vendors`) of the Vendor & Contracts page at `/inventory/vendor-contracts`.

## When This Screen Is Used

- **Vendor Assignment**: Linking approved vendors to specific stock items for procurement
- **Preferred Vendor**: Marking one vendor per item as preferred (used for auto-suggestion in PR/PO)
- **Vendor Reference Data**: Storing vendor-specific item codes (vendor SKU) and lead times
- **Purchase Rate History**: Tracking the last purchase rate per vendor per item (auto-updated on GRN acceptance)

## Key Fields

- **Stock Item** (FK) — References `inv_stock_items.id`
- **Vendor** (FK) — References `vnd_vendors.id` (cross-module)
- **Vendor SKU** (optional, max 50) — The vendor's own code for this item
- **Last Purchase Rate** (optional, min:0) — Auto-updated on GRN acceptance
- **Last Purchase Date** (optional) — Date of last purchase from this vendor for this item
- **Lead Time (Days)** (optional, min:0) — Vendor's typical delivery lead time
- **Is Preferred** (boolean) — Only ONE vendor can be preferred per item

## Business Rules

### Only One Preferred Vendor Per Item
When a vendor link is created or updated with `is_preferred = true`, ALL other vendor links for the same item are automatically set to `is_preferred = false`. This is enforced in the controller via:
```php
if (! empty($data['is_preferred'])) {
    $item->vendorLinks()->update(['is_preferred' => false]);
}
```

### Update-or-Create (Idempotent Links)
The store action uses `updateOrCreate(['item_id', 'vendor_id'], ...)`, which means linking the same vendor to the same item a second time updates the existing record rather than creating a duplicate. The DB-level `UNIQUE (item_id, vendor_id)` constraint provides additional protection.

### All-AJAX Architecture
Unlike other inventory screens, the Item-Vendor Links module is entirely AJAX-based:
- **Index**: Returns JSON with vendor data (no dedicated Blade UI — consumed by frontend)
- **Store/Update/Destroy**: All return JSON `{status, message, data}` responses
- The tab page displays all stock items with their vendor summary, and the "Manage Vendors" button calls the JSON endpoint

### Cross-Module Dependencies
- `vendor_id` references the Vendor Management module (`vnd_vendors`). The DDL FK is commented out; validation is via `exists:vnd_vendors,id` rule.
- `item_id` references the Inventory module (`inv_stock_items`) with a hard FK constraint (CASCADE on delete).

### Auto-Update of Last Purchase Rate
The `last_purchase_rate` field is designed to be auto-updated by the GRN acceptance process (not in this controller). When a GRN is accepted, the unit cost from the GRN line item updates the corresponding `inv_item_vendor_jnt.last_purchase_rate`.

### Soft Delete Lifecycle
The model has a `deleted_at` column but the `ItemVendorJnt` model does NOT use the `SoftDeletes` trait (based on the source — the table schema has the column and the controller uses `delete()` and `onlyTrashed()` in the trash methods). Links can be soft-deleted and restored/force-deleted from the trash page.

## Workflow

1. Staff navigates to Inventory → Vendor & Contracts → Item-Vendor Links tab
2. Staff sees all stock items with their vendor summary (preferred vendor, total vendor count)
3. Staff clicks "Link Vendor" to open the modal
4. Staff selects stock item and vendor, optionally fills vendor SKU, lead time, last rate, sets preferred
5. Form action is dynamically set to `/inventory/items/{itemId}/vendors` via JavaScript
6. Staff can click "Manage Vendors" on an item to view all linked vendors (AJAX JSON)
7. Staff can edit vendor link details (rate, lead time, preferred status)
8. Staff can unlink (delete) a vendor from an item
9. Deleted links can be restored or force-deleted from the trash page

## Related Screens

- **Rate Contracts** — First tab on same page; negotiated pricing per vendor per item
- **Stock Items** — Items catalog; each item can have multiple vendor links
- **Vendors** — Cross-module (Vendor Management); vendor master data
- **Purchase Requisitions** — PR items can reference preferred vendors
- **Purchase Orders** — PO creation uses vendor links for suggestion
- **Goods Receipt Notes** — GRN acceptance auto-updates last_purchase_rate

## Requirements

- MUST display stock items as cards with vendor summary at `/inventory/vendor-contracts?tab=item-vendors`
- MUST authorize via `tenant.inventory.item-vendor.*` policy gates (4 gates)
- MUST validate store/update with 6 rules including cross-module exists checks
- MUST use `updateOrCreate` to prevent duplicate (item_id, vendor_id) pairs
- MUST enforce single preferred vendor per item (unset others when new preferred set)
- MUST return JSON from all CRUD endpoints
- MUST auto-set form action URL based on selected stock item (JS)
- MUST support soft-delete lifecycle with restore/force-delete
- MUST show vendor summary per item: preferred vendor (name/SKU), vendor count badge
- MUST display empty state "No Stock Items Found" when no items exist
