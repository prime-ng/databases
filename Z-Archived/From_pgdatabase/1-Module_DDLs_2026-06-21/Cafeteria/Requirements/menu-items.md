# Menu Items — Requirements

## Parent Tab: Menu Planning

## What It Does
Dish library with nutritional macros, food type classification, allergen notes, and real-time availability toggle for POS counter.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `category_id` | INT UNSIGNED FK → caf_menu_categories | Required. ON DELETE RESTRICT. |
| `name` | VARCHAR(150) | Required. Dish name. |
| `description` | TEXT | Nullable. Dish description. |
| `price` | DECIMAL(8,2) | Required. Per-serving price in INR. |
| `food_type` | ENUM('Veg','Non_Veg','Egg','Jain') | Default 'Veg'. For dietary conflict checks. |
| `calories` | SMALLINT UNSIGNED | Nullable. Calories per serving (kcal). |
| `protein_grams` | DECIMAL(5,2) | Nullable. Protein per serving (g). |
| `carbs_grams` | DECIMAL(5,2) | Nullable. Carbs per serving (g). |
| `fat_grams` | DECIMAL(5,2) | Nullable. Fat per serving (g). |
| `allergen_notes` | TEXT | Nullable. Free-form allergen information. |
| `photo_media_id` | INT UNSIGNED FK → sys_media | Nullable. Dish photo. |
| `is_available` | TINYINT(1) | Default 1. Real-time POS availability. |
| `is_active` | TINYINT(1) | Default 1. Soft enable/disable. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `category_id` | Required, integer, exists:caf_menu_categories,id | "The selected category is invalid." |
| `name` | Required, string, max:150 | "The name field is required." / "Dish name must not exceed 150 characters." |
| `price` | Required, numeric, min:0, max:999999.99 | "Price must be a valid amount." / "Price cannot be negative." |
| `food_type` | Required, enum: Veg/Non_Veg/Egg/Jain | "The selected food type is invalid." |
| `calories` | Nullable, integer, min:0, max:65535 | Must be 0–65535 kcal. |
| `protein_grams` | Nullable, numeric, min:0, max:999.99 | |
| `carbs_grams` | Nullable, numeric, min:0, max:999.99 | |
| `fat_grams` | Nullable, numeric, min:0, max:999.99 | |
| `allergen_notes` | Nullable, string, max:500 | Free-form text. |
| `photo_media_id` | Nullable, integer, exists:sys_media,id | Must reference a valid media record. |
| `is_available` | Required, boolean, default 1 | Real-time POS flag. Independent of `is_active`. |

### Dietary Conflict Check

Checked at POS scan time (display-only warnings — transaction is NOT blocked):
- **Veg student** ordering Non_Veg: "This item contains non-vegetarian ingredients."
- **Jain student** ordering Non_Veg or Egg: "This item conflicts with your dietary preference."
- **Nut allergy flagged** student scanning item with allergens containing "nut": RED alert "ALLERGY ALERT: This item may contain nuts."

### Price Modification Rules

- Price can be updated any time. Existing orders retain the `unit_price` snapshot from order time.
- Price changes do NOT retroactively affect placed orders.
- Price = 0.00 means free/complimentary item.

### Availability Toggle (`is_available`)

- `is_available = 0`: greyed out on POS menu, cannot be added to POS transaction.
- `is_available = 0`: still visible in pre-order dropdowns (kitchen can plan accordingly).
- Toggle route: `POST /cafeteria/menu-items/{menuItem}/toggle-availability`. AJAX, returns JSON.

### Soft Delete & Restore

**Soft Delete:**
1. Pre-check: item must not be referenced by any active (non-soft-deleted) daily menu assignments. If referenced: "Cannot delete menu item that is assigned to an active daily menu."
2. Sets `is_active = 0` and `is_available = 0`.
3. Standard soft delete with audit trail.

**Restore:** Standard pattern. Does NOT auto-restore `is_available` (remains 0).

**Force Delete:** Only on already soft-deleted records with no remaining junction references.

### List View

- Controller: MenuItemController@index. Gate: `tenant.cafeteria.menu-item.viewAny`.
- Pagination: 15 per page, sorted by category display_order then name.
- Columns: Photo (thumbnail), Name, Category, Food Type (color badge), Price, Available (toggle), Status, Actions.
- Food type badge colors: green=Veg, red=Non_Veg, orange=Egg, blue=Jain.
- Filters: search by name, category dropdown, food type dropdown.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.menu-item.viewAny` |
| Create | `tenant.cafeteria.menu-item.create` |
| Update | `tenant.cafeteria.menu-item.update` |
| Delete | `tenant.cafeteria.menu-item.delete` |
