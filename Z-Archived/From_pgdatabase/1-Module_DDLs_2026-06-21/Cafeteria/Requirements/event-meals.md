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

#### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:150 | "The name field is required." |
| `event_date` | Required, date | |
| `meal_category_id` | Required, integer, exists:caf_menu_categories,id | |
| `target_class_ids_json` | Nullable, JSON | Validated per JSON structure rules below. |
| `status` | Required, enum: Draft/Published/Archived | Same lifecycle as daily menus. |

#### JSON Structure: `target_class_ids_json`

```json
[5, 8, 12]
```

- Must be a valid JSON array of integers (class/grade IDs from `sch_classes`).
- Empty array `[]`: hidden from all students.
- NULL: all students/classes are eligible.
- Max 100 class IDs. Exceeding: "Target classes cannot exceed 100 entries."
- Duplicate class IDs silently removed on save.
- Invalid JSON: "The target class IDs format is invalid."

#### Relationship with Daily Menus

- Event meals are independent of daily menus. Both can exist on the same date.
- Portal display logic:
  - Students NOT in target class set: see regular daily menu.
  - Students IN target class set: see event meal items instead.
- If `target_class_ids_json` is NULL: event meal replaces regular menu for all students.
- Multiple event meals can exist for the same date if `meal_category_id` differs.

#### Lifecycle State Machine

Same as daily menus: Draft → Published → Archived.
- Published event meals appear on student portal for pre-orders.
- Same publish/archive guards: must have at least one item to publish; only past events can archive.

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

- At least one of `menu_item_id` or `free_text_item` must be provided. Both NULL: "Either select a dish from the library or enter a free-text item name."
- If `menu_item_id` is provided, `free_text_item` is ignored (overwritten to NULL on save).
- Free-text items are for festival/one-off dishes not worth adding to the permanent dish library.
- No UNIQUE beyond PK: the same dish can appear multiple times.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.event-meal.*` |
