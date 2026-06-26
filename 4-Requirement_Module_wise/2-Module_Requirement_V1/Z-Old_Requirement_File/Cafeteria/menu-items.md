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

### Core Data Conditions

- Every menu item must belong to a valid existing meal category.
- Each dish must have a unique name within the system.
- A price must be set for each item; a price of zero means the item is free or complimentary.
- Every item must be classified into a food type (Veg, Non_Veg, Egg, or Jain) for dietary conflict checking.
- Nutritional information (calories, protein, carbs, fat) can optionally be recorded per serving.
- Free-form allergen notes can optionally be provided to support allergy alerts at the POS terminal.
- A dish photo can optionally be attached from uploaded media.
- Items have two independent statuses: one for general active/inactive state, and another for real-time POS availability.

### Dietary Conflict Warnings

When a student's card is scanned at the POS terminal, the system checks for dietary conflicts and displays warning messages. The transaction is NOT blocked — these are alerts only:

- If a **Veg student** orders a **Non_Veg** item: "This item contains non-vegetarian ingredients."
- If a **Jain student** orders a **Non_Veg** or **Egg** item: "This item conflicts with your dietary preference."
- If a student with a **nut allergy flag** scans an item whose allergen notes mention "nut": A red alert shows "ALLERGY ALERT: This item may contain nuts."

### Pricing Rules

- The price can be changed at any time.
- Existing orders are not affected by price changes — each order keeps a snapshot of the price at the time it was placed.
- A price of ₹0.00 means the item is free or complimentary.

### Availability Toggle

- When an item is marked Unavailable, it is greyed out on the POS menu and cannot be added to POS transactions.
- However, unavailable items still show in pre-order dropdowns so the kitchen can plan accordingly.
- The availability can be toggled via an AJAX action button that returns a JSON response.

### Deleting, Restoring, and Permanently Removing Menu Items

**Deleting a Menu Item (Soft Delete):**
- A menu item can only be deleted if it is not assigned to any active daily menu. If it is assigned, the system shows "Cannot delete menu item that is assigned to an active daily menu."
- When deleted, the item is automatically deactivated and marked unavailable.
- An audit trail is created for the deletion.

**Restoring a Deleted Menu Item:**
- When restored, the item is brought back but stays marked Unavailable — it does not automatically become Available again.

**Permanently Removing a Menu Item (Force Delete):**
- Only applies to items that have already been deleted (soft-deleted) and have no remaining daily menu assignments.

### List View

- Menu items are sorted by their category's sort order, then alphabetically by item name.
- 15 items are shown per page.
- The list displays a photo thumbnail, all identifying information, the assigned meal category, food type (with a color-coded badge), price, availability toggle switch, status indicator, and action buttons.
- Food type badges use these colors: Green = Veg, Red = Non_Veg, Orange = Egg, Blue = Jain.
- Users can search by name and filter by category or food type using dropdowns.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.menu-item.viewAny` |
| Create | `tenant.cafeteria.menu-item.create` |
| Update | `tenant.cafeteria.menu-item.update` |
| Delete | `tenant.cafeteria.menu-item.delete` |
