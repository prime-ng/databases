# Weekly Menus — Requirements

## Parent Tab: Menu Planning

## What It Does
Daily menu headers with Draft → Published → Archived lifecycle. One menu per calendar date with dish assignments via junction table to determine what is served each day.

## Tables Covered

1. `caf_daily_menus` — Daily menu headers
2. `caf_daily_menu_items_jnt` — Junction: day × meal-category × dish assignments

---

## Entity: Daily Menus (`caf_daily_menus`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `menu_date` | DATE | Required. Unique. One menu per calendar date. |
| `week_start_date` | DATE | Required. ISO Monday of the menu week. |
| `academic_term_id` | SMALLINT UNSIGNED FK → sch_academic_terms | Nullable. |
| `status` | ENUM('Draft','Published','Archived') | Default 'Draft'. Lifecycle: Draft→Published→Archived. |
| `published_at` | TIMESTAMP | Nullable. When menu was published. |
| `published_by` | INT UNSIGNED FK → sys_users | Nullable. Who published. |
| `notes` | TEXT | Nullable. Kitchen notes for this day. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### Business Rules

#### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `menu_date` | Required, date, unique | "A menu for this date already exists." — one menu per date (UNIQUE KEY). |
| `week_start_date` | Required, date | Auto-computed as ISO Monday. If manually provided, must be a Monday. |
| `academic_term_id` | Nullable, integer, exists:sch_academic_terms,id | |
| `status` | Required, enum: Draft/Published/Archived | Transitions validated by workflow below. |
| `notes` | Nullable, string, max:1000 | Kitchen notes. |

#### Menu Lifecycle State Machine

| From | To | Guard | Side Effects |
|---|---|---|---|
| Draft | Published | At least one item assigned via junction. If none: "Cannot publish a menu with no items." | `published_at = now()`, `published_by = auth()->id()`. Visible on portal. |
| Published | Archived | `menu_date` must be in the past. Future: "Cannot archive a future menu." | Read-only. Not displayed on portal. |
| Published | Draft (unpublish) | Only if `menu_date` is today/future. Past menus cannot revert. | Clears `published_at` and `published_by`. |
| Draft | (soft delete) | None | Allowed directly. |
| Archived | (none) | No transitions from Archived. | Immutable. |

#### Menu Date Uniqueness

- `menu_date` is UNIQUE (DB-level). Even soft-deleted records occupy their date.
- To reuse a date: restore the soft-deleted menu, or force-delete it.
- Error on collision: "A menu for {date} already exists. Restore the existing menu to reuse this date."

#### Data Integrity: Junction Cascade

- Soft-delete: junction records are NOT automatically deleted (they remain for restore).
- Force-delete: junction records cascade-deleted (FK ON DELETE CASCADE).
- Menu item cascade-delete: junction record cascade-deleted.

#### Soft Delete & Restore

**Soft Delete:**
1. Guard: status must be 'Draft'. Published/Archived: "Cannot delete a published or archived menu. Archive first or unpublish first."
2. Sets `is_active = 0`. Junction items remain intact.
3. Activity log: "Daily menu for {menu_date} was soft-deleted."

**Restore:**
1. Pre-restore check: no other active menu exists for same date. If taken: "Cannot restore — another menu already exists for this date."
2. Does NOT auto-set `is_active` to 1.

---

## Entity: Daily Menu Items Junction (`caf_daily_menu_items_jnt`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `daily_menu_id` | INT UNSIGNED FK → caf_daily_menus | Required. ON DELETE CASCADE. |
| `menu_item_id` | INT UNSIGNED FK → caf_menu_items | Required. ON DELETE CASCADE. |
| `meal_category_id` | INT UNSIGNED FK → caf_menu_categories | Required. ON DELETE RESTRICT. |
| `serving_size_notes` | VARCHAR(100) | Nullable. e.g. "1 plate", "200ml". |
| `display_order` | TINYINT UNSIGNED | Default 0. Sort order within meal category. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

- UNIQUE on `(daily_menu_id, menu_item_id, meal_category_id)`. Same dish cannot appear in same meal category twice on same day.
- Same menu item can appear in multiple meal categories on the same day (e.g., "Chapati" in Lunch and Dinner).
- `meal_category_id` validated against item's own `category_id`: warning if mismatch.
- No `deleted_at`: junction table; individual assignments are not soft-deleted.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.daily-menu.viewAny` |
| Create/Store | `tenant.cafeteria.daily-menu.create` |
| Update | `tenant.cafeteria.daily-menu.update` |
| Delete | `tenant.cafeteria.daily-menu.delete` |
| Publish/Archive | `tenant.cafeteria.daily-menu.publish` |
