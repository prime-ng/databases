# Meal Categories — Business Requirements

## What This Screen Does

The Meal Categories screen defines the meal-type taxonomy for the cafeteria module (Breakfast, Lunch, Snacks, Dinner, Tuck Shop). Each category can have a **meal time** enum value, an optional **start time** for cutoff calculations, a **display order**, and a unique **code**. Meal Categories appear as the first tab (`?tab=categories`) of the Menu Planning page at `/cafeteria/menu-planning`.

Categories are used across the module: menu items are assigned to categories, daily/weekly menus group dishes by category, event meals target a category, orders reference a category, and meal attendance is tracked per category.

## When This Screen Is Used

- **Meal Type Setup**: Defining the types of meals served (Breakfast, Lunch, Snacks, Dinner, Tuck Shop)
- **Cutoff Configuration**: Setting `meal_start_time` per category for order cutoff enforcement (BR-CAF-001)
- **Display Ordering**: Configuring the sequence categories appear on student portal and POS
- **Status Management**: Enabling/disabling categories without data loss

## Key Fields

- **Name** (required) — Category display name, max 100 characters
- **Code** (optional, unique) — Short identifier (e.g. BRK, LNC, SNK), max 20 chars. Unique across all categories (ignores soft-deleted).
- **Meal Time** (required) — Enum: `Breakfast`, `Lunch`, `Snacks`, `Dinner`, `Tuck_Shop`
- **Start Time** (optional) — HH:MM format; used to calculate ordering cutoff (meal_start_time - configurable cutoff hours)
- **Description** (optional) — Free-form text description
- **Display Order** (default 0) — Integer 0–255 for UI sort order; supports drag-and-drop reordering
- **Is Active** (boolean) — Soft enable/disable via AJAX toggle

## Business Rules

**Unique Code:** The `code` field has a UNIQUE constraint at the DB level. The validation request enforces this with `Rule::unique('caf_menu_categories', 'code')->ignore($id)->whereNull('deleted_at')`, meaning soft-deleted records do not block reuse of a code.

**Drag-and-Drop Reorder:** The categories table uses Sortable.js for drag-and-drop reordering. On drop, an AJAX POST is sent to `cafeteria.menu-categories.reorder` with the ordered array of IDs. The `MenuService::reorderCategories()` method updates `display_order` sequentially (0, 1, 2, ...) within a DB transaction.

**Edit via Modal (Inline):** Clicking the Edit/View action button on a category row opens an inline modal populated from `data-category` JSON attribute on the `<tr>` element. The modal form submits to the standard `update` route. View mode disables all inputs.

**Delete Protection (Dependencies):** The `forceDelete()` method calls `$category->hasDependencies()` before permanently deleting. Dependencies checked: `menuItems()`, `dailyMenuItems()`, `eventMeals()`, `mealAttendances()`, `orders()`, `staffMealLogs()`. If dependencies exist, the method shows a flash error listing them (comma-separated) and blocks deletion. The `destroy()` (soft delete) does **not** check dependencies — records are soft-deleted regardless.

**Force Delete Cascading:** When force delete bypasses the dependency check (e.g. admin override), the controller manually deletes child records via direct DB queries (`DB::table(...)->delete()`) after setting `SET FOREIGN_KEY_CHECKS=0`.

**Activity Logging:** All CRUD operations log activity:
- Create: `"Menu category created."`
- Update: `"Menu category updated."`
- Toggle: `"Menu category activated/deactivated."`
- Delete: `"Menu category deleted."`
- Restore: `"Menu category restored."`
- Force Delete: `"Menu category permanently deleted."`

**Toggle Status:** The `toggle()` endpoint flips `is_active` and returns JSON `{success, is_active, message}`.

**No Pagination:** Categories are fetched with `->get()` (no pagination) and displayed in a sortable table.

## Workflow

1. Staff navigates to Cafeteria → Menu Planning → Meal Categories tab
2. Staff clicks "Add" to open the create modal, fills in name (required), code, meal time (required), start time, description, display order, active status
3. Category appears in the sortable table with drag handle, name/description, meal time, status toggle, actions
4. Staff can drag rows to reorder (AJAX auto-saves)
5. Staff can click Edit button to open inline edit modal
6. Staff can toggle active status directly from the table
7. Staff can soft-delete a category (no dependency check)
8. Soft-deleted categories appear in the trash page for restore or permanent deletion

## Related Screens

- **Menu Items** — Second tab; items are assigned to meal categories
- **Weekly Menus** — Third tab; daily menus group items by meal category
- **Event Meals** — Fourth tab; event meals target a specific meal category
- **Orders & Attendance** — Orders and attendance are tracked per meal category
- **Stock Compliance** — Consumption logs reference meal category

## Requirements

- MUST display meal categories at `/cafeteria/menu-planning?tab=categories` as a sortable table with drag-and-drop reorder
- MUST authorize via `cafeteria.menu-categories.*` policy gates
- MUST validate store with 7 rules (BC-VAL-01 through 07)
- MUST enforce unique code validation (`Rule::unique` ignoring own ID + soft-deleted records)
- MUST create category via MenuService::createCategory() with auth user and activity log
- MUST update category via inline modal with MenuService::updateCategory()
- MUST support AJAX drag-and-drop reorder via POST to `menu-categories/reorder`
- MUST support AJAX toggle-status returning JSON
- MUST support soft-delete lifecycle (soft delete allowed regardless of dependencies)
- MUST guard force-delete with hasDependencies() check (blocks with error listing dependencies)
- MUST log all CRUD operations via activityLog()
- MUST NOT paginate categories (all loaded via `->get()` with ordered scope)
