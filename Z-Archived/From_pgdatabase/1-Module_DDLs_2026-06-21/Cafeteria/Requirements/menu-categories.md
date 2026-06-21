# Meal Categories — Requirements

## Parent Tab: Menu Planning

## What It Does
Meal-type category master — defines Breakfast, Lunch, Snacks, Dinner, Tuck Shop. Each category represents a serving time/type for the cafeteria.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(100) | Required. Category name (Breakfast, Lunch, Snacks, Dinner, Tuck Shop). |
| `code` | VARCHAR(20) | Nullable. Unique. Short code (BRK, LNC, SNK). |
| `meal_time` | ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop') | Required. Serving type discriminator. |
| `meal_start_time` | TIME | Nullable. Scheduled serving start time. |
| `description` | TEXT | Nullable. Optional description. |
| `display_order` | TINYINT UNSIGNED | Default 0. Sort order on student portal. |
| `is_active` | TINYINT(1) | Default 1. Soft enable/disable. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |

## Business Rules

### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:100 | "The name field is required." / "Name must not exceed 100 characters." |
| `code` | Nullable, string, max:20, unique | "The code has already been taken." — enforced via UNIQUE KEY. |
| `meal_time` | Required, enum: Breakfast/Lunch/Snacks/Dinner/Tuck_Shop | "The selected meal time is invalid." |
| `meal_start_time` | Nullable, date_format:H:i | Must be a valid time in HH:MM format. |
| `description` | Nullable, string | No strict limit beyond column capacity. |
| `display_order` | Required, integer, min:0, max:255 | Defaults to 0. Must be 0–255. |
| `is_active` | Required, boolean, default 1 | Must be 0 or 1. |

### Entity Lifecycle

- **Create:** New category created with `is_active = true` and `display_order = 0` (if not specified).
- **Update:** Name, code, meal_time, meal_start_time can be changed freely if unique constraints are satisfied.
- **Code Uniqueness:** `code` is optional (nullable). If provided, must be unique across all categories (including soft-deleted). MySQL UNIQUE allows multiple NULLs, so multiple categories with NULL code are permitted.
- **Deactivation:** `is_active = 0` does NOT affect existing menu items or menu assignments — items become hidden from selection dropdowns only.

### Soft Delete & Restore

**Soft Delete:**
1. Pre-check: category must have 0 menu items referencing it. If any exist: "Cannot delete category with existing menu items."
2. Sets `is_active = 0` before soft delete.
3. Sets `deleted_at` timestamp. Record remains in database.
4. Activity log: "Menu category '{name}' was soft-deleted."
5. Redirect to categories list with flash `flash('trashed.menu-category')`.

**Restore:**
1. Only on soft-deleted records (onlyTrashed scope).
2. Sets `deleted_at = NULL`.
3. Does NOT auto-set `is_active` back to 1 (remains 0).
4. Activity log + redirect to trash with `flash('restored.menu-category')`.

**Force Delete:**
1. Only on already soft-deleted records.
2. Must have 0 menu items. Guard: "Cannot permanently delete category with existing menu items."
3. Permanently removes from DB.

### is_active Toggle

- Route: `POST /cafeteria/menu-categories/{menuCategory}/toggle-status`.
- AJAX endpoint. No pre-guard for deactivation.
- Returns JSON: `{"success": true, "is_active": bool}`.
- Works on both active and soft-deleted records.

### List View

- Controller: MenuCategoryController@index. Gate: `tenant.cafeteria.menu-category.viewAny`.
- Pagination: 15 per page, sorted by `display_order ASC, name ASC`.
- Columns: Name, Code, Meal Time (badge), Start Time, Display Order, Status (active/inactive), Actions.
- Filters: search by name/code, meal time dropdown (auto-submit).
- Action buttons permission-gated.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.menu-category.viewAny` |
| View details | `tenant.cafeteria.menu-category.view` |
| Create | `tenant.cafeteria.menu-category.create` |
| Update | `tenant.cafeteria.menu-category.update` |
| Delete | `tenant.cafeteria.menu-category.delete` |
| Restore | `tenant.cafeteria.menu-category.restore` |
| Force delete | `tenant.cafeteria.menu-category.forceDelete` |
