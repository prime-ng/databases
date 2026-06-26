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

### Supplier Identity & Contact

- Every supplier must be identified by their company name.
- A contact person's name may optionally be recorded.
- A phone number, if provided, must contain only digits, plus signs (+), hyphens (-), spaces, and parentheses. If other characters are entered, the system shows: *"Phone number must contain only digits, +, -, spaces, and parentheses."*
- An email address, if provided, must be a valid email format.

### FSSAI License Tracking

- An FSSAI license number may optionally be recorded for a supplier.
- An FSSAI expiry date may optionally be recorded. If a date in the past is entered, the system shows: *"FSSAI license has already expired."* — the expiry date must still be in the future at the time of entry.

### Supply Categories

- The supply categories a supplier can provide are stored as a list of labels, for example: `["Vegetables", "Grains", "Dairy", "Spices"]`
- A maximum of 20 categories can be assigned to a single supplier.
- If the same category label is added more than once (regardless of capitalisation), the duplicate is silently removed.
- Suggested categories include: Vegetables, Fruits, Grains, Pulses, Dairy, Spices, Beverages, Condiments, Cleaning, and Other.
- If the format is invalid, the system shows: *"The supply categories format is invalid."*

### FSSAI Expiry Alert

- Two alert levels are shown on the supplier list and detail pages:
  - **30-day warning:** A warning badge appears.
  - **7-day critical alert:** A critical badge appears and a notification is sent to cafeteria administrators.
- The system checks for expiring licenses automatically every night.

### Deleting a Supplier

- A supplier can only be deleted if no stock items are linked to them. If stock items exist, the system shows: *"Cannot delete supplier with existing stock items. Reassign stock items first."*
- When a supplier is deleted, any stock items that were linked to them will no longer show a supplier name.

### List View

- The supplier list shows all registered suppliers.
- Columns shown: Name, Contact Person, Phone, FSSAI License Number, FSSAI Expiry Date (with coloured badge), Status, and Action buttons.
- The FSSAI expiry badge uses the following colour codes:
  - **Green:** More than 60 days remaining.
  - **Yellow:** 30 to 60 days remaining.
  - **Orange:** 7 to 30 days remaining.
  - **Red:** Less than 7 days remaining or already expired.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.supplier.*` |
