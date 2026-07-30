# Menu Items — Business Requirements

## What This Screen Does

The Menu Items screen manages the dish library for the cafeteria. Each dish belongs to a **meal category**, has a **price**, **food type** (Veg/Non_Veg/Egg/Jain), optional **nutritional macros** (calories, protein, carbs, fat), **allergen notes**, and a **photo**. Menu Items appear as the second tab (`?tab=menu-items`) of the Menu Planning page at `/cafeteria/menu-planning`.

Dishes are reused across daily/weekly menus and event meals, linked via junction tables. Real-time **availability** toggling lets staff mark dishes as temporarily unavailable without deactivating them.

## When This Screen Is Used

- **Dish Library Management**: Adding/editing dishes with pricing, nutritional info, and dietary classification
- **Availability Control**: Toggling real-time availability (e.g. "sold out" for the day without deactivation)
- **Menu Composition**: Selecting dishes when creating daily/weekly menus and event meals
- **Compliance**: Tracking food type for dietary conflict checking (BR-CAF-002)

## Key Fields

- **Name** (required) — Dish name, max 150 characters
- **Category** (FK → `caf_menu_categories`) — Which meal type the dish belongs to (Breakfast, Lunch, etc.)
- **Description** (optional) — Free-form dish description
- **Price** (required) — Per-serving price in INR, decimal 8,2, min 0
- **Food Type** (required) — Enum: `Veg`, `Non_Veg`, `Egg`, `Jain`
- **Calories** (optional) — kcal per serving, smallint unsigned
- **Protein / Carbs / Fat** (optional) — Grams per serving, decimal 5,2, min 0
- **Allergen Notes** (optional) — Free-form allergen information
- **Photo** (optional) — Upload image (jpeg/png/jpg/gif/webp, max 2MB) → stored as Media record
- **Is Available** (boolean, default true) — Real-time availability toggle (separate from is_active)
- **Is Active** (boolean) — Soft enable/disable

## Business Rules

**Dual Toggle System:** Menu Items have two boolean toggles:
- `is_available` — Real-time availability (toggled via dedicated `toggleAvailability()` endpoint). Affects whether students can order the dish. Toggled frequently during service hours.
- `is_active` — Soft enable/disable (`toggleStatus()` endpoint). Used for permanent deactivation.

**Photo Upload:** Photos are uploaded via the MenuItem create/edit form. The request validates: `nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048` (2MB). On successful upload, a `sys_media` record is created and `photo_media_id` is stored on the menu item.

**Food Type Validation:** The `food_type` enum is validated in the request (`in:Veg,Non_Veg,Egg,Jain`). This drives dietary conflict checks in `OrderService::assertNoDietaryConflict()`.

**Category Deletion Protection:** Menu items have `ON DELETE RESTRICT` FK to `caf_menu_categories`. Attempting to delete a category with menu items will fail at the DB level unless the controller handles it (force-delete bypasses with FK_CHECKS=0).

**Activity Logging:**
- Create: `"Menu item created."`
- Update: `"Menu item updated."`
- Availability Toggle: `"Menu item availability toggled to available/unavailable."`
- Status Toggle: `"Menu item activated/deactivated."`
- Delete: `"Menu item deleted."`
- Restore: `"Menu item restored."`
- Force Delete: `"Menu item permanently deleted."`

**No Pagination on Tab:** Menu items on the tab are paginated (20 per page) via `->paginate(20)`.

## Workflow

1. Staff navigates to Cafeteria → Menu Planning → Menu Items tab
2. Staff clicks "Add" → navigates to dedicated create page (`/cafeteria/menu-items/create`) with category select
3. Staff fills in dish details (name, category, price, food type, optional nutritional fields, optional photo)
4. Dish appears in the paginated table with name, category, price, food type badge, availability badge, status toggle, actions
5. Staff can toggle availability directly (separate from active status)
6. Staff can click Edit/View to navigate to dedicated edit/show pages
7. Staff can soft-delete a dish
8. Deleted dishes appear in the trash for restore or permanent deletion

## Related Screens

- **Meal Categories** — First tab; defines the category taxonomy
- **Weekly Menus** — Third tab; dishes assigned to daily menus via junction table
- **Event Meals** — Fourth tab; dishes assigned to event meals via junction table
- **Orders** — Dishes ordered by students reference menu items

## Requirements

- MUST display menu items at `/cafeteria/menu-planning?tab=menu-items` as a paginated table with search and status filter
- MUST authorize via `cafeteria.menu-items.*` policy gates (note: policy uses `cafeteria.menu.item.*` permission keys)
- MUST validate store with 13 rules (BC-VAL-01 through 13)
- MUST create item via MenuService::createItem() with auth user and activity log
- MUST support dedicated create/show/edit pages (not inline modals)
- MUST support AJAX toggle-availability returning JSON `{status, is_available}`
- MUST support AJAX toggle-status returning JSON `{success, is_active, message}`
- MUST support photo upload (image, 2MB max, jpeg/png/jpg/gif/webp)
- MUST enforce food_type enum validation
- MUST support soft-delete lifecycle
- MUST log all CRUD operations via activityLog()
