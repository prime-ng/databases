# Event Meals — Requirements

## Parent Tab: Menu Planning

## What It Does
Special and festival meal management with optional class-group targeting. Event meals sit alongside regular daily menus — they override the regular menu for targeted student groups.

## Tables Covered

1. `caf_event_meals` — Event meal headers
2. `caf_event_meal_items_jnt` — Junction: event meal × dish assignments (supports free-text items)

---

## Entity: Event Meals (`caf_event_meals`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `name` | VARCHAR(150) | Required. Event meal name (e.g. Diwali Special Lunch). |
| `event_date` | DATE | Required. Date of special meal. |
| `meal_category_id` | INT UNSIGNED FK → caf_menu_categories | Required. ON DELETE RESTRICT. |
| `target_class_ids_json` | JSON | Nullable. Array of class IDs; NULL = all students. |
| `status` | ENUM('Draft','Published','Archived') | Default 'Draft'. |
| `published_at` | TIMESTAMP | Nullable. |
| `notes` | TEXT | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### Business Rules

#### Core Data Conditions

- Each event meal must have a display name.
- Every event meal is scheduled for a specific date and assigned to a meal category.
- The event meal can optionally be restricted to specific class groups (see JSON rules below).
- Every event meal follows a Draft → Published → Archived lifecycle, the same as daily menus.

#### Target Class Groups — JSON Rules

The target class groups are stored as a JSON array of numbers representing class/grade IDs, for example: `[5, 8, 12]`.

- An empty array means no students will see this event meal.
- A value of NULL means all students and classes are eligible.
- A maximum of 100 class IDs can be specified. If exceeded, the system shows "Target classes cannot exceed 100 entries."
- Duplicate class IDs are silently removed when saving.
- If the data format is invalid, the system shows "The target class IDs format is invalid."

#### How Event Meals Work Alongside Daily Menus

- Event meals are separate from daily menus. Both can exist for the same date.
- On the student portal:
  - Students who are NOT in the target class group see the regular daily menu.
  - Students who ARE in the target class group see the event meal items instead of the regular menu.
- If no class restriction is set (NULL), the event meal replaces the regular menu for everyone.
- Multiple event meals can exist for the same date as long as they belong to different meal categories (e.g., a Diwali special lunch and a separate snack event).

#### Lifecycle — Draft → Published → Archived

Follows the same rules as daily menus:

- Published event meals appear on the student portal for pre-orders.
- At least one item must be assigned to the event meal before it can be published.
- Only past event meals can be archived.

---

## Entity: Event Meal Items Junction (`caf_event_meal_items_jnt`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `event_meal_id` | INT UNSIGNED FK → caf_event_meals | Required. ON DELETE CASCADE. |
| `menu_item_id` | INT UNSIGNED FK → caf_menu_items | Nullable. NULL for free-text items. ON DELETE SET NULL. |
| `free_text_item` | VARCHAR(150) | Nullable. Item name when not in dish library. |
| `quantity_per_student` | DECIMAL(5,2) | Nullable. Serving qty. |
| `display_order` | TINYINT UNSIGNED | Default 0. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

#### Core Data Conditions

- Every junction record must link to a valid event meal. If the event meal is permanently deleted, its item records are automatically removed.
- Each record can reference either a dish from the permanent library OR a free-text description, but not both. At least one must be provided. If both are blank, the system shows "Either select a dish from the library or enter a free-text item name."
- If a dish from the library is selected, any free-text description is ignored and cleared on save.
- If a linked dish from the library is deleted, the reference is set to blank but the junction record is kept.
- A serving quantity per student can optionally be specified.
- The sort position within the event meal is controlled by a display order value.

#### Additional Rules

- Free-text items are intended for festival or one-time dishes that do not need to be added to the permanent dish library.
- The same dish can appear multiple times — there are no uniqueness rules beyond the record ID.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.event-meal.*` |
