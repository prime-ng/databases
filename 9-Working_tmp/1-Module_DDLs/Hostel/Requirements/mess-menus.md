# Mess Weekly Menus — Requirements

## What It Does
Weekly mess menu planning. Defines meal items per day of week (Mon-Sun) and meal type (breakfast/lunch/dinner/snacks). Supports published/draft states and week copying.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `academic_session_id` | INT UNSIGNED FK → sch_academic_term | Required. |
| `week_start_date` | DATE | Required. Monday of the week. |
| `day_of_week` | TINYINT UNSIGNED | Required. 1=Monday, 7=Sunday. |
| `meal_type` | ENUM(breakfast, lunch, dinner, snacks) | Required. |
| `menu_description` | TEXT | Nullable. |
| `is_special_diet_available` | TINYINT(1) | Default 0. |
| `special_diet_description` | VARCHAR(500) | Nullable. |
| `is_published` | TINYINT(1) | Default 0. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Unique Constraint**
- (`hostel_id`, `week_start_date`, `day_of_week`, `meal_type`)

**Menu Lifecycle**
Draft → Published

**Copy Week**
- Duplicates all meal entries from a source week to a target week

## CRUD Operations

**Create** — `GET /hostel/mess/menus/create` → form | `POST /hostel/mess/menus` → validates → saves → redirects

**List** — `GET /hostel/mess/menus` → paginated by week | Tab in Mess & Dining | Columns: Week, Day, Meal Type, Menu, Published, Actions

**Copy Week** — `POST /hostel/mess/menus/copy-week` → copies menu from one week to another

**Toggle Published** — `POST /hostel/mess/menus/{menu}/toggle-published` → toggles `is_published` → JSON

**View** — `GET /hostel/mess/menus/{id}` → detail

**Edit** — `GET /hostel/mess/menus/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/mess/menus/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-mess-menu.viewAny` |
| View details | `tenant.hostel-mess-menu.view` |
| Create | `tenant.hostel-mess-menu.create` |
| Edit/update | `tenant.hostel-mess-menu.update` |
| Publish | `tenant.hostel-mess-menu.publish` |
| Soft delete | `tenant.hostel-mess-menu.delete` |
