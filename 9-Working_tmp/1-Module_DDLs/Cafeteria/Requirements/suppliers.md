# Suppliers — Requirements

## Parent Tab: Stock & Compliance

## What It Does
Food and material supplier register with FSSAI license expiry tracking and supply category classification.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(150) | Required. Company name. |
| `contact_person` | VARCHAR(100) | Nullable. |
| `phone` | VARCHAR(20) | Nullable. |
| `email` | VARCHAR(100) | Nullable. |
| `address` | TEXT | Nullable. |
| `fssai_license_no` | VARCHAR(50) | Nullable. |
| `fssai_expiry_date` | DATE | Nullable. Alert 30/7 days before expiry. |
| `supply_categories_json` | JSON | Nullable. Array of supply category strings. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:150 | |
| `contact_person` | Nullable, string, max:100 | |
| `phone` | Nullable, string, max:20, regex:/^[0-9+\-\s()]+$/ | "Phone number must contain only digits, +, -, spaces, and parentheses." |
| `email` | Nullable, email, max:100 | |
| `fssai_license_no` | Nullable, string, max:50 | |
| `fssai_expiry_date` | Nullable, date | If past: "FSSAI license has already expired." |

### JSON Structure: `supply_categories_json`

```json
["Vegetables", "Grains", "Dairy", "Spices"]
```

- Array of strings, max 50 chars each. Max 20 categories.
- Duplicates silently removed (case-insensitive).
- Standard values (suggested): Vegetables, Fruits, Grains, Pulses, Dairy, Spices, Beverages, Condiments, Cleaning, Other.
- Invalid JSON: "The supply categories format is invalid."

### FSSAI Expiry Alert (BR-CAF-014)

- Two-tier alert:
  - **30-day alert:** Warning badge on list and show page.
  - **7-day alert:** CRITICAL badge + notification to cafeteria admins.
- Checked daily by `SendFssaiAlertsCommand` cron.

### Soft Delete

- Pre-check: 0 stock items referencing this supplier. If exists: "Cannot delete supplier with existing stock items. Reassign stock items first."
- ON DELETE SET NULL: existing stock items get `supplier_id = NULL` at DB level.

### List View

- Controller: SupplierController@index. Gate: `tenant.cafeteria.supplier.viewAny`.
- Columns: Name, Contact Person, Phone, FSSAI License, FSSAI Expiry (badge), Status, Actions.
- FSSAI expiry badge colors: green (>60 days), yellow (30-60), orange (7-30), red (<7 or expired).

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.supplier.*` |
