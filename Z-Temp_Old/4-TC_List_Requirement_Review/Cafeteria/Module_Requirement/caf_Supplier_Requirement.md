# Suppliers — Business Requirements

## What This Screen Does

The Suppliers tab manages vendors who supply raw materials to the cafeteria. Each supplier record tracks **name**, **contact person**, **phone**, **email**, **address**, **FSSAI license details** (license number and expiry date), and **supply categories** (JSON array of product categories they supply).

FSSAI expiry dates are visually highlighted: expired dates show red with an exclamation icon, dates expiring within 30 days show amber with a triangle icon. Suppliers with expired/expiring FSSAI also trigger alerts on the FSSAI tab (expiring within 30 days) and are surfaced in the `$expiringSupplier` collection for dashboard alerts.

## When This Screen Is Used

- **Vendor Management**: Adding/editing suppliers for raw material procurement
- **Compliance Monitoring**: Tracking supplier FSSAI license expiry dates
- **Stock Item Linking**: Associating stock items with their preferred supplier
- **Procurement Dispatches**: Identifying active suppliers for reorder alerts

## Key Fields

- **Name** (string 150) — Supplier business name
- **Contact Person** (string 100, nullable) — Person of contact
- **Phone** (string 20, nullable) — Contact number
- **Email** (string 100, nullable) — Email address
- **Address** (text, nullable) — Physical address
- **FSSAI License Number** (string 50, nullable) — Supplier's food license number
- **FSSAI Expiry Date** (date, nullable) — When their license expires
- **Supply Categories** (JSON array, nullable) — Categories they supply (e.g., ["Grains", "Dairy"])
- **Is Active** (boolean, default true) — Toggle via status switch

## Business Rules

**FSSAI Expiry Visual Indicators:**
- Expired (`fssai_expiry_date->isPast()`): red text + `fa-circle-exclamation` icon
- Expiring soon (`diffInDays(now()) <= 30`): amber text + `fa-triangle-exclamation` icon
- No expiry date: "—" (em dash)

**Expiring Supplier Alerts:** `CafeteriaController::stockCompliance()` queries suppliers where `fssai_expiry_date` is between today and 30 days from now. These are loaded as `$expiringSupplier` and displayed on the FSSAI tab as warning alerts. `StockService::checkFssaiExpiry()` also checks supplier FSSAI in tiered batches (30-day and 7-day) for notification dispatch.

**Status Toggle:** Ajax endpoint `toggleStatus()` flips `is_active` via `X-backend.table.status-switch` component. Returns JSON `{success, is_active, message}`.

**Soft Delete:** Model uses SoftDeletes. Supplier also has `trashed()`, `restore()`, `forceDelete()` methods.

**Supplier → Stock Items:** One-to-many relation via `stockItems()` HasMany. Used on Supplier show page to display linked stock items.

**Activity Logging:**
- Create: `"Supplier {name} added."`
- Update: `"Supplier {name} updated."`
- Delete: `"Supplier {name} deleted."`
- Toggle: `"Supplier {name} activated/deactivated."`

## Workflow

1. Staff navigates to Cafeteria → Stock & Compliance → Suppliers tab
2. Staff sees paginated table: Supplier Name (with contact person subtitle), Phone, Email, FSSAI Expiry (with visual indicators), Status toggle, Actions
3. Staff can create supplier via dedicated create page
4. Staff can view supplier detail (with linked stock items), edit, or delete
5. Staff toggles active/inactive via status switch (Ajax)

## Related Screens

- **Stock Items** — First tab; linked via supplier_id FK
- **FSSAI** — Third tab; FSSAI records reference suppliers
- **Dashboard** — Expiring supplier alerts shown on dashboard

## Requirements

- MUST display suppliers at `/cafeteria/stock-compliance?tab=suppliers` as paginated table with search + status filter
- MUST authorize via `cafeteria.suppliers.*` permission gates (note: policy uses `cafeteria.supplier.*` keys)
- MUST show FSSAI expiry date with visual indicators (expired red, expiring amber)
- MUST support status toggle via Ajax
- MUST support soft delete with restore/forceDelete
- MUST show contact person as subtitle under supplier name
- MUST support supply categories as JSON array
- MUST log all CRUD and toggle actions via activityLog()
