# Menu Items — Business Requirements

## What This Screen Does

The Menu Items screen is the school's permanent dish library. Every food item that the cafeteria can prepare and serve is registered here — from idli and sambar to paneer biryani and fruit salad. Each dish has its nutritional information, food type classification (Veg/Non-Veg/Egg/Jain), price, photo, and real-time availability toggle.

Think of Menu Items as the cafeteria's complete recipe catalogue. Once a dish is defined here, it can be assigned to daily menus, event meals, and student pre-order forms. The inventory never needs to be re-entered — it is defined once and reused everywhere.

---

## When This Screen Is Used

- A new dish is introduced to the cafeteria menu and needs to be added to the library
- Nutritional information (calories, protein, carbs, fat) needs to be updated for an existing dish
- Dish prices change due to ingredient cost fluctuations
- A dish is temporarily unavailable (e.g., seasonal ingredients) and needs to be hidden from POS
- A dish is permanently discontinued and should be deactivated
- Admin needs to check which dishes are available for a specific meal category

---

## Key Fields at a Glance

**Dish Name**
A clear, descriptive name for the dish — for example, "Masala Dosa," "Chicken Biryani," or "Fruit Salad."

**Category**
The meal category this dish belongs to (Breakfast, Lunch, Snacks, Dinner, or Tuck Shop). Every dish must be assigned to exactly one category. This determines which meal time forms the dish can appear in.

**Price**
The per-serving price in INR. This is the base price that gets snapshotted into order items at order time. The price can be changed later, but existing orders retain the original price.

**Food Type**
The type classification: Veg, Non-Veg, Egg, or Jain. This is critical for dietary compliance checking — when a student with a "Veg" preference tries to order "Non-Veg," the system shows a warning. When a student flagged with nut allergy orders an item with allergen notes containing "nut," a RED alert is shown at POS.

**Nutritional Info**
Calories (kcal), protein (grams), carbs (grams), and fat (grams) per serving. These are optional but recommended for schools that track nutritional intake.

**Allergen Notes**
Free-form text about potential allergens — for example, "Contains peanuts, dairy, and gluten."

**Dish Photo**
An optional photo of the dish. Shows up on the student portal and POS screens.

**Real-Time Availability**
A toggle that controls whether the dish is currently available for POS counter sales. A dish can be "unavailable" for counter sales while still being visible in pre-order forms.

**Status**
Each dish can be Active or Inactive. Inactive dishes are hidden everywhere and cannot be ordered or assigned to menus.

---

## Business Rules and Conditions

**Category is Mandatory**
Every dish must belong to an active menu category. A dish cannot exist without a category.

**Food Type Validation**
The food type classification drives dietary conflict checks. At POS scan time, if a student's dietary profile conflicts with the ordered dish's food type, a display-only warning is shown. The transaction is never blocked.

**Price Modification**
Price can be changed at any time. Existing orders retain the unit_price that was snapshotted at order creation time.

**Availability Toggle**
Setting availability to OFF means the dish is greyed out on the POS menu and cannot be added to POS transactions. It remains visible in pre-order dropdowns.

**Soft Delete Protection**
A dish cannot be soft-deleted if it is assigned to any active daily menu.

---

## Workflow Steps

**Adding a New Dish**
Admin opens the Add Dish form, selects the category, enters the dish name and price, chooses the food type, optionally fills nutritional values, adds allergen notes, uploads a photo, and submits.

**Viewing Dishes**
The dish list page shows all dishes with filters — filter by category, food type, or search by name. Each row shows a photo thumbnail, dish name, category, food type colour badge, price, availability toggle, and active status.

**Editing a Dish**
Admin can update any field. Changing the category moves the dish to a different meal type.

**Toggling Availability**
Admin clicks the availability toggle to mark a dish as temporarily unavailable for POS.

**Deactivating a Dish**
Admin sets the dish to Inactive. The dish is hidden from all menus, orders, and POS screens.

---

## Example Scenario

A school cafeteria adds breakfast dishes:
- **Idli** (Veg, ₹15, 60 kcal, available)
- **Masala Dosa** (Veg, ₹25, 120 kcal, available)
- **Egg Omelette** (Egg, ₹20, 90 kcal, available)
- **Chicken Sandwich** (Non-Veg, ₹35, available only on Wednesdays)

---

## Related Screens

- **Menu Categories** — Each dish is assigned to one category
- **Weekly Menus** — Dishes are assigned to daily menus via junction table
- **Event Meals** — Dishes can be assigned to event meals
- **Orders** — Order items snapshot the dish name and price at order time
