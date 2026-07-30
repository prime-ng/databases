# Weekly Menus — Business Requirements

## What This Screen Does

The Weekly Menus screen manages daily menu plans — one record per calendar date (`menu_date` UNIQUE constraint). Each menu has a **status lifecycle** (Draft → Published → Archived), a **week_start_date** for grouping, and a set of **menu items** assigned via a junction table (`caf_daily_menu_items_jnt`) that link dishes to meal categories. Weekly Menus appear as the third tab (`?tab=weekly-menus`) of the Menu Planning page at `/cafeteria/menu-planning`.

Menus control what dishes are available on which dates. Published menus are visible to students/parents via the portal/API for ordering. The system also exposes a **current week API** for mobile/portal consumption.

## When This Screen Is Used

- **Daily Menu Planning**: Creating menu schedules per date with dish assignments per meal category
- **Menu Publishing**: Publishing draft menus to make them visible for student ordering
- **Menu Duplication**: Copying a menu (header + items) to another date as a new Draft
- **Menu Archiving**: Archiving old published menus (auto-archived after 7 days via Artisan command)
- **Menu Status Management**: Draft → Published → Archived lifecycle

## Key Fields

- **Menu Date** (required, unique) — The calendar date this menu applies to. Unique constraint (ignores soft-deleted).
- **Week Start Date** (required) — ISO Monday of the week this menu belongs to
- **Academic Term** (FK → `sch_academic_term`, optional) — Links to the academic term
- **Status** (enum) — `Draft` (default), `Published`, `Archived`
- **Published At** (timestamp, nullable) — When menu was published
- **Published By** (FK → `sys_users`, nullable) — Who published it
- **Notes** (text, nullable) — Kitchen notes visible to staff
- **Is Active** (boolean) — Soft enable/disable

### Junction: Daily Menu Items (`caf_daily_menu_items_jnt`)
- **Daily Menu** (FK CASCADE) — Parent menu
- **Menu Item** (FK CASCADE) — Assigned dish
- **Meal Category** (FK RESTRICT) — Which meal slot (Breakfast/Lunch/etc.)
- **Serving Size Notes** (optional) — e.g. "1 plate", "200ml"
- **Display Order** — Sort order within the meal category
- **Duplicate Guard** — Unique constraint on (daily_menu_id, menu_item_id, meal_category_id) + custom validator

## Business Rules

**Status Lifecycle:**
- `Draft` → Can be edited, published, duplicated, or deleted
- `Published` → Visible to students; can be archived but not edited; publish button hidden
- `Archived` → Cannot be edited (`MenuService::updateDailyMenu()` throws `DomainException: "Archived menus cannot be edited."`); cannot be re-published

**Publish Guard (BR-CAF-005):** `MenuService::publishMenu()` throws `DomainException` if the menu has zero items assigned: `"Cannot publish a menu with no items assigned."`

**Duplicate Guard:** `MenuService::duplicateDailyMenu()` throws `DomainException` if a menu already exists for the target date: `"A menu already exists for {date}."`

**Duplicate Item Validation:** The `StoreDailyMenuRequest` has a custom `withValidator()` that rejects duplicate (menu_item_id + meal_category_id) combinations in the same menu with a descriptive error message.

**Unique Menu Date:** The `menu_date` field has a UNIQUE constraint at the DB level. The validation request enforces this with `Rule::unique('caf_daily_menus', 'menu_date')->ignore($id)->whereNull('deleted_at')`.

**Auto-Archive:** An Artisan command (`caf:archive-old-menus`) auto-archives published menus older than 7 days via `MenuService::archiveOldMenus()`.

**API Endpoint:** `GET /cafeteria/menus/current-week` (API route) returns all Published menus for the current ISO week with eager-loaded menu items and meal categories.

**Activity Logging:**
- Create: `"Daily menu created for {date}."`
- Update: `"Daily menu for {date} updated."`
- Publish: `"Daily menu for {date} published."`
- Archive: `"Daily menu for {date} archived."`
- Duplicate: `"Daily menu for {source_date} duplicated to {target_date}."`
- Delete: `"Daily menu for {date} deleted."`
- Restore: `"Daily menu for {date} restored."`
- Force Delete: `"Daily menu for {date} permanently deleted."`

**State-Specific Action Buttons on Tab:**
- Draft: Publish button + Duplicate button (opens modal with date picker) + Edit/Delete actions
- Published: Archive button + View action (no edit)
- Archived: View action only

## Workflow

1. Staff navigates to Cafeteria → Menu Planning → Weekly Menus tab
2. Staff clicks "Add" → navigates to create page (`/cafeteria/weekly-menu/create`) with date picker, academic term select, category tabs, dish checkboxes
3. Staff selects menu date, week start, academic term, notes, and assigns items (menu_item + meal_category pairs)
4. Menu created as Draft, appears in paginated table
5. Staff can click Publish (Draft only) → menu becomes visible for ordering
6. Staff can click Duplicate (Draft only) → modal asks for target date, copies menu + items
7. Staff can click Archive (Published only) → hides from student view
8. Staff can click Edit/View → dedicated edit/show pages
9. Staff can soft-delete any menu

## Related Screens

- **Meal Categories** — Defines the meal slots for item assignment
- **Menu Items** — The dish library; items are assigned to menus
- **Event Meals** — Similar lifecycle (Draft/Published/Archived)
- **Orders & Attendance** — Published menus drive ordering; attendance tracked per menu date/category

## Requirements

- MUST display weekly menus at `/cafeteria/menu-planning?tab=weekly-menus` as a paginated table with search and status filter
- MUST authorize via `cafeteria.weekly-menus.*` policy gates (note: policy uses `cafeteria.daily.menu.*` permission keys)
- MUST validate store with date, unique menu_date, and items array validation
- MUST enforce unique (menu_item_id + meal_category_id) combinations via custom validator
- MUST create menu as Draft via MenuService::createDailyMenu() in transaction
- MUST support dedicated create/show/edit pages (not inline modals)
- MUST support publish (guarded: requires ≥1 item, must be Draft)
- MUST support archive (Published → Archived; no re-publish)
- MUST support duplicate to new date as Draft (guarded: target date must not exist)
- MUST support soft-delete lifecycle
- MUST auto-archive published menus older than 7 days via Artisan command
- MUST expose current week API for portal/mobile
- MUST enforce DomainException for archived menu edits
- MUST log all lifecycle operations via activityLog()
