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

#### Core Data Conditions

- Only one menu can exist per calendar date. If a menu already exists for that date, the system shows "A menu for this date already exists."
- The week start date is automatically calculated as the Monday of the menu's week. If entered manually, it must be a Monday.
- An academic term can optionally be associated with the menu.
- Every menu follows a Draft → Published → Archived lifecycle. Status transitions must follow the rules below.
- Optional kitchen notes can be added for the day.

#### Menu Lifecycle — Draft → Published → Archived

**Publishing a Draft Menu:**
- At least one menu item must be assigned before the menu can be published. If no items exist, the system shows "Cannot publish a menu with no items."
- When published, the system records the date/time of publication and who published it.
- The menu becomes visible to students on the portal.

**Archiving a Published Menu:**
- Only menus with a past date can be archived. Attempting to archive a future-dated menu shows "Cannot archive a future menu."
- Once archived, the menu is read-only and no longer displayed on the portal.
- No transitions are allowed from Archived status — it is permanent.

**Unpublishing (Reverting to Draft):**
- A published menu can be reverted to draft only if the menu date is today or in the future. Past menus cannot be reverted.
- Unpublishing clears the recorded publication date/time and publisher information.

**Deleting Draft Menus:**
- Draft menus can be deleted directly without any special conditions.

#### Menu Date Uniqueness

- Each calendar date can have only one menu — this is enforced at the database level.
- Even deleted menus occupy their date in the system. To reuse a date for a new menu, you must first restore or permanently delete the existing menu that occupies that date.
- If you try to create a menu for a date that is already taken, the system shows "A menu for {date} already exists. Restore the existing menu to reuse this date."

#### Data Integrity — Effect on Junction Records

- When a daily menu is soft-deleted (hidden but kept), its item assignments remain in the system so they can be restored if needed.
- When a daily menu is permanently deleted, its item assignments are also permanently removed.
- If a menu item is permanently deleted, its junction assignments are also permanently removed.

#### Deleting, Restoring, and Permanently Removing Daily Menus

**Deleting a Daily Menu (Soft Delete):**
- Only menus with Draft status can be deleted. If you try to delete a Published or Archived menu, the system shows "Cannot delete a published or archived menu. Archive first or unpublish first."
- When deleted, the menu is deactivated. Its assigned items remain intact for possible restoration.
- An activity log entry records the deletion.

**Restoring a Deleted Daily Menu:**
- Before restoring, the system checks that no other active menu exists for the same date. If one exists, the system shows "Cannot restore — another menu already exists for this date."
- When restored, the menu stays deactivated — it does not automatically become active again.

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

#### Core Data Conditions

- Every junction record must link to a valid daily menu and a valid menu item. If either the parent menu or the menu item is permanently deleted, the junction record is automatically removed.
- Every junction record must link to a valid meal category. If the meal category is deleted, the system prevents the deletion because this junction record still links to it.
- A serving size note can optionally be recorded (e.g., "1 plate", "200ml").
- The sort position within each meal category is controlled by a display order value.

#### Additional Rules

- A dish cannot appear twice in the same meal category on the same day. For example, "Chapati" cannot be listed twice under "Lunch" on the same menu.
- However, the same dish can appear in different meal categories on the same day (e.g., "Chapati" under both "Lunch" and "Dinner").
- If the selected meal category does not match the menu item's own category, the system shows a warning.
- Junction records are not soft-deleted — they are either kept or permanently removed along with their parent menu.

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.cafeteria.daily-menu.viewAny` |
| Create/Store | `tenant.cafeteria.daily-menu.create` |
| Update | `tenant.cafeteria.daily-menu.update` |
| Delete | `tenant.cafeteria.daily-menu.delete` |
| Publish/Archive | `tenant.cafeteria.daily-menu.publish` |
