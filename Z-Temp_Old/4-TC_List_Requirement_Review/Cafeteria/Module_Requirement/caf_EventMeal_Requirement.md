# Event Meals — Business Requirements

## What This Screen Does

The Event Meals screen manages special/festival meals outside the regular daily menu schedule. Each event meal has a **name**, **event date**, **meal category**, optional **class-group targeting** (visible only to specific classes), and a set of **menu items** (from the dish library or free-text entries). Event Meals appear as the fourth tab (`?tab=event-meals`) of the Menu Planning page at `/cafeteria/menu-planning`.

Event meals follow the same Draft → Published → Archived lifecycle as weekly menus but are standalone (not tied to the daily menu calendar).

## When This Screen Is Used

- **Special Meals**: Festival celebrations, farewell dinners, sports day meals
- **Class-Specific Events**: Meals targeting specific class groups (e.g., only Grade 10–12)
- **Custom Items**: Adding free-text items not in the regular dish library
- **Event Menu Management**: Drafting, publishing, and archiving event-specific menus

## Key Fields

- **Name** (required) — Event meal name, max 150 characters
- **Event Date** (required) — Date of the special meal
- **Meal Category** (FK → `caf_menu_categories`, required) — Which meal time (Breakfast, Lunch, etc.)
- **Target Class IDs** (JSON array, optional) — Array of class IDs; NULL/empty = all classes (BR-CAF-016)
- **Status** (enum) — `Draft` (default), `Published`, `Archived` (note: only Draft→Published is enforced; Archived not explicitly checked anywhere)
- **Published At** (timestamp, nullable) — When published
- **Notes** (text, nullable) — Kitchen notes
- **Is Active** (boolean) — Soft enable/disable

### Junction: Event Meal Items (`caf_event_meal_items_jnt`)
- **Event Meal** (FK CASCADE) — Parent event meal
- **Menu Item** (FK SET NULL, nullable) — Optional link to dish library; NULL for free-text items
- **Free Text Item** (optional) — Item name when not in dish library (e.g. "Special Cake")
- **Quantity Per Student** (optional) — Serving quantity per student
- **Display Order** — Sort order

## Business Rules

**Dual Item Type:** Event meal items support two modes:
- **Library Item:** `menu_item_id` references `caf_menu_items` (FK with ON DELETE SET NULL)
- **Free-Text Item:** `free_text_item` stores a custom name when no library dish matches

**Class Targeting (BR-CAF-016):** `target_class_ids_json` stores an array of class IDs. The `EventMeal::scopeForClass($classId)` scope filters event meals where the array is NULL/empty (all classes) or contains the given class ID.

**Publish Guard:** `MenuService::publishEventMeal()` throws `DomainException` if the event meal is not in Draft status.

**Status Lifecycle (Simplified):** Unlike weekly menus, event meals only enforce Draft→Published publishing. There is no explicit guard against publishing Archived event meals (the publish guard only checks `status !== 'Draft'`).

**Activity Logging:**
- Create: `"Event meal {name} created."`
- Update: `"Event meal {name} updated."`
- Publish: `"Event meal {name} published."`
- Delete: `"Event meal {name} deleted."`
- Restore: `"Event meal {name} restored."`
- Force Delete: `"Event meal {name} permanently deleted."`

**No Archive Route in Service:** Unlike weekly menus, event meals do not have an explicit archive action in MenuService. The status can be set via update, but there's no dedicated `archiveEventMeal()` method.

## Workflow

1. Staff navigates to Cafeteria → Menu Planning → Event Meals tab
2. Staff clicks "Add" → navigates to create page (`/cafeteria/event-meals/create`) with name, event date, meal category, class select (multi), notes, and item assignment
3. Event meal created as Draft, appears in paginated table
4. Staff can click Publish (Draft only) → visible to targeted students/parents
5. Staff can click Edit/View → dedicated show/edit pages with items
6. Staff can soft-delete any event meal

## Related Screens

- **Meal Categories** — Defines the meal slot for the event
- **Menu Items** — Optional dish library reference for event meal items
- **Weekly Menus** — Similar lifecycle for regular daily menus
- **Orders & Attendance** — Published event meals visible for ordering/attendance

## Requirements

- MUST display event meals at `/cafeteria/menu-planning?tab=event-meals` as a paginated table with search and status filter
- MUST authorize via `cafeteria.event-meals.*` policy gates (note: policy uses `cafeteria.event.meal.*` permission keys)
- MUST validate store with 7 rules (BC-VAL-01 through 07)
- MUST create event meal as Draft via MenuService::createEventMeal() in transaction
- MUST support dedicated create/show/edit pages
- MUST support publish (guarded: must be Draft)
- MUST support soft-delete lifecycle
- MUST support class-targeting via JSON array with scopeForClass() query scope
- MUST support dual item types: library items (menu_item_id) and free-text items (free_text_item)
- MUST log all lifecycle operations via activityLog()
