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

### Core Data Conditions

- Each meal category must have a unique display name within the system.
- Category codes are optional but must be unique across all categories, including deleted ones. Multiple categories can have no code at the same time — this is allowed.
- Every category must be assigned to a specific meal time (Breakfast, Lunch, Snacks, Dinner, or Tuck Shop).
- A meal category can optionally have a scheduled serving start time.
- An optional description can be provided with no strict length limit.
- The display order value controls sort position on the student portal.
- The active/inactive state controls whether the category is available for selection.

### Entity Lifecycle

- **Creating a Category:** New categories are created as Active by default with a default display order position.
- **Updating a Category:** All category properties can be freely changed as long as the unique code rule is followed.
- **Code Uniqueness:** The code is optional. If provided, it must be unique across all categories (including deleted ones). Multiple categories can have no code at the same time — this is allowed.
- **Deactivating a Category:** Setting a category to Inactive does not affect existing menu items or menu assignments. It only hides the category from selection dropdowns.

### Deleting, Restoring, and Permanently Removing Categories

**Deleting a Category (Soft Delete):**
- A category can only be deleted if no menu items are linked to it. If items exist, the system shows "Cannot delete category with existing menu items."
- When deleted, the category is automatically deactivated.
- The category is hidden from active use but remains saved in the system for record-keeping.
- An activity log entry records: "Menu category '{name}' was soft-deleted."
- After deletion, the user is redirected to the category list with a confirmation message.

**Restoring a Deleted Category:**
- Only categories that have been deleted can be restored.
- When restored, the category is brought back but stays deactivated — it does not automatically become active again.
- An activity log entry records the restoration.
- After restoring, the user is redirected with a confirmation message.

**Permanently Removing a Category (Force Delete):**
- Only applies to categories that have already been deleted (soft-deleted).
- The category must still have no menu items linked to it. If items exist, the system shows "Cannot permanently delete category with existing menu items."
- This action permanently removes the category from the database and cannot be undone.

### Toggling Active Status

- The Active/Inactive status can be toggled on and off using an AJAX action button.
- No special checks are required before deactivation — any category can be toggled at any time.
- The system returns a JSON response with the success status and the new active status value.
- This works on both active and deleted categories.

### List View

- Categories are sorted by display order (ascending), then alphabetically by name.
- 15 categories are shown per page.
- The list displays all identifying information, meal time (as a badge), serving start time, display order, status indicator, and action buttons.
- Users can search by name or code, and filter by meal time using a dropdown that auto-submits.
- Action buttons are shown or hidden based on user permissions.

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
