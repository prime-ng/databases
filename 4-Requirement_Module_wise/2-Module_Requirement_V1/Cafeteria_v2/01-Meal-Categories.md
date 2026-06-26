# Meal Categories — Business Requirements

## What This Screen Does

The Meal Categories screen is where the school defines the different meal times or service types offered by the cafeteria — for example, Breakfast, Lunch, Snacks, Dinner, and Tuck Shop. Each category represents a specific serving window during the day.

Think of Meal Categories as the foundation of the cafeteria's scheduling system. Every menu item, daily menu, order, and attendance record is linked to one of these categories. Before any dish can be added to the system or any menu can be planned, the meal categories must first be defined here.

---

## When This Screen Is Used

- A new school year begins and the cafeteria admin wants to set up meal categories for the term
- A new meal type needs to be added (e.g., a "Pre-School Snack" time for younger students)
- An existing category's serving time or name needs to be updated
- A meal category is no longer in use (e.g., Tuck Shop discontinued) and needs to be deactivated
- Admin needs to reorder how categories appear on the student portal

---

## Key Fields at a Glance

**Category Name**
A clear name like "Breakfast," "Lunch," "Snacks," "Dinner," or "Tuck Shop." This is the primary identifier used throughout the module — in menus, orders, attendance, and reports.

**Short Code**
An optional short identifier like BRK, LNC, or SNK. This code must be unique if provided. It is typically used in kitchen displays or quick-reference reports.

**Meal Time**
The serving type discriminator — Breakfast, Lunch, Snacks, Dinner, or Tuck Shop. This determines when the meal is served and helps the system apply cutoff rules for pre-orders.

**Meal Start Time**
The scheduled start time for this meal category (e.g., Breakfast at 7:30 AM, Lunch at 12:00 PM). This is used by the pre-order cutoff engine to determine whether an order can still be placed.

**Description**
Optional notes about this category — for example, "Tuck Shop items available during recess only."

**Display Order**
A number that controls the sort order on the student portal. Categories with lower numbers appear first. For example, Breakfast might be 1, Lunch 2, Snacks 3, Dinner 4.

**Status**
Each category can be Active (visible in dropdowns and menus) or Inactive (hidden from selection but still available for historical records).

---

## Business Rules and Conditions

**Unique Code**
If a short code is provided, no two categories in the same school can share the same code. Multiple categories can have NULL codes (no code is acceptable).

**Deactivation Safety Check**
When a category is deactivated, existing menu items linked to it remain unaffected. However, the category will not appear in new menu planning dropdowns or order forms. Reactivating it restores visibility.

**Soft Delete Protection**
A category cannot be soft-deleted or force-deleted if it has menu items still referencing it. All menu items must be reassigned or deleted first. This prevents orphaned records.

**Display Order Range**
The display order must be between 0 and 255. The default is 0. Categories with the same display order are sorted alphabetically by name.

---

## Workflow Steps

**Adding a New Category**
Admin opens the Add Category form, enters the category name (e.g., "Evening Tea"), selects the meal time (Snacks), optionally enters a short code (e.g., "EVT"), picks a serving start time (3:30 PM), writes a short description, sets the display order, and submits.

**Viewing Categories**
The category list page shows all categories ordered by display order and name. Each row shows the name, code, meal time (shown as a coloured badge), start time, and active status. Search by name or code is supported.

**Editing a Category**
Admin clicks on a category and updates any field. If the code is changed, uniqueness is rechecked. The meal time can be changed, but doing so does not affect existing menu items or orders — they remain linked to the category ID.

**Reordering Categories**
Admin can change the display order of each category to control how they appear on the student portal and kitchen screens. Lower numbers appear first.

**Deactivating a Category**
Admin toggles the status to Inactive. The category disappears from all active selection dropdowns but remains visible in historical orders, menus, and reports.

**Deleting a Category**
Admin soft-deletes the category. If any menu items reference it, the system blocks deletion with a clear error message. Deleted categories can be restored from trash.

---

## Example Scenario

A school starts using the cafeteria module mid-year. The admin sets up four categories:
- **Breakfast** (code: BRK, meal time: Breakfast, start time: 07:30, display order: 1)
- **Lunch** (code: LNC, meal time: Lunch, start time: 12:00, display order: 2)
- **Evening Snacks** (code: SNK, meal time: Snacks, start time: 15:30, display order: 3)
- **Dinner** (code: DNR, meal time: Dinner, start time: 19:00, display order: 4)

The school also runs a Tuck Shop which they add as an additional category (code: TCK, meal time: Tuck_Shop, display order: 5).

---

## Related Screens

- **Menu Items** — Each menu item belongs to a category
- **Weekly Menus** — Daily menu dish assignments reference meal categories
- **Orders** — Every order is for a specific meal category
- **Meal Attendance** — Attendance records are linked to the meal category being served
