# Complaint Categories — Requirements

## What It Does
Manages the hierarchical taxonomy of complaint types. Each category defines:
- A name and optional short code
- Default severity level and priority score
- Expected resolution time (in hours)
- 5-level escalation timeline (strictly increasing hours L1 < L2 < L3 < L4 < L5)
- Active/inactive status
- Optional parent category for sub-categorization

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `parent_id` | BIGINT FK → self | Nullable. If NULL = root category. If set = sub-category. FK uses `restrictOnDelete`. |
| `name` | VARCHAR(100) | Required. Max 100 characters. |
| `code` | VARCHAR(30) | Nullable. Must be unique across all categories (validated at application level). |
| `description` | VARCHAR(512) | Nullable. |
| `severity_level_id` | BIGINT FK → `sys_dropdowns` | Nullable. References system dropdown for severity levels. |
| `priority_score_id` | BIGINT FK → `sys_dropdowns` | Nullable. References system dropdown for priority scores. |
| `expected_resolution_hours` | UNSIGNED INT | Required. Minimum 1 hour. Baseline SLA for this category. |
| `escalation_hours_l1` | UNSIGNED INT | Required. Hours before first escalation. |
| `escalation_hours_l2` | UNSIGNED INT | Required. Must be greater than L1. |
| `escalation_hours_l3` | UNSIGNED INT | Required. Must be greater than L2. |
| `escalation_hours_l4` | UNSIGNED INT | Required. Must be greater than L3. |
| `escalation_hours_l5` | UNSIGNED INT | Required. Must be greater than L4. |
| `is_active` | BOOLEAN | Default true. Controls whether category is available for selection. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Escalation Chain Validation**
All 5 escalation levels must form a strictly increasing sequence:
```
L1 < L2 < L3 < L4 < L5
```
This is enforced at the form validation level. If any level is not greater than the previous, the form is rejected with a validation error.

**Parent-Child Hierarchy**
- A category with `parent_id = NULL` is a root-level category
- A category with `parent_id` set is a sub-category
- A category cannot be set as its own parent (enforced during edit)
- Only root-level categories appear in the parent dropdown when creating/editing
- When editing, the category itself is excluded from its parent dropdown

**Soft Delete Behavior**
- Soft-deleting a category does NOT check for children (children can exist with a soft-deleted parent)
- Before soft delete, the category is automatically deactivated (`is_active = false`)
- Soft-deleted categories are hidden from the main listing

**Force Delete Behavior**
- Only applies to already soft-deleted records
- Blocked if the category has any child categories
- Error message: "Cannot delete category having subcategories"
- The `restrictOnDelete` FK constraint on `parent_id` provides database-level protection

**Status Toggle**
- Active/inactive state can be toggled via AJAX POST
- The toggle endpoint accepts `is_active` as a boolean parameter
- Returns JSON with the new state
- Works even on soft-deleted records

## CRUD Operations

**Create**
- Route: `GET /complaint/complaint-categories/create` → form
- Submit: `POST /complaint/complaint-categories` → validates → saves → redirects to master view
- After successful creation: redirects to `/complaint/complaint-mgt` with success flash message
- On validation failure: returns to create form with error messages and old input preserved

**List**
- Displayed as a tab panel in the master view at `/complaint/complaint-mgt`
- Shows table with columns: Name, Code, Parent Category, Severity, Priority, Status, Actions
- Supports filtering by: search text, status (active/inactive), severity level, priority score, parent category
- Paginated with standard Laravel pagination
- Columns and actions are permission-gated

**View**
- Route: `GET /complaint/complaint-categories/{id}`
- Loads with relationships: children, parent, severityLevel, priorityScore
- Two rendering modes:
  - AJAX: Used by the index modal (clicking "View" in the list)
  - Full page: Direct browser visit with breadcrumbs and action buttons
- Shows all category details in a table layout

**Edit**
- Route: `GET /complaint/complaint-categories/{id}/edit` → pre-filled form
- Submit: `PUT /complaint/complaint-categories/{id}` → validates → detects changes → updates → logs activity → redirects
- Validation differs from create: parent_id cannot be self, code uniqueness ignores own ID, is_active is required
- On update, an activity log entry is created recording old and new values for each changed field
- After successful update: redirects to master view with success flash message

**Delete (Soft)**
- Route: `DELETE /complaint/complaint-categories/{id}`
- Triggered via SweetAlert2 confirmation popup
- Pre-delete: sets `is_active = false`
- Records a "Deleted" activity log entry
- After deletion: redirects to master view with success flash message

**Restore**
- Route: `GET /complaint/complaint-categories/{id}/restore`
- Trash page: `GET /complaint/complaint-categories/trash/view` — lists soft-deleted records with pagination
- Triggered via SweetAlert2 confirmation popup
- Restores `deleted_at` to null
- Records a "Restored" activity log entry
- After restore: redirects to master view with success flash message

**Force Delete**
- Route: `DELETE /complaint/complaint-categories/{id}/force-delete`
- Only available for soft-deleted records
- Checks for existing children before deletion — blocked if children exist
- Records a "Force Deleted" activity log entry
- After force delete: record is permanently removed from database

**Toggle Status**
- Route: `POST /complaint/complaint-categories/{id}/toggle-status`
- AJAX endpoint that accepts `{ is_active: boolean }`
- Returns JSON: `{ success: true, is_active: bool, message: string }`
- Records a "Toggled" activity log entry

## Permissions

| Operation | Permission Key |
|---|---|
| View category tab | `tenant.complaint-category.viewAny` |
| View category details | `tenant.complaint-category.view` |
| Show create form | `tenant.complaint-category.create` |
| Save new category | `tenant.complaint-category.store` |
| Edit/update category | `tenant.complaint-category.update` |
| Soft delete category | `tenant.complaint-category.delete` |
| View trash & restore | `tenant.complaint-category.restore` |
| Force delete category | `tenant.complaint-category.forceDelete` |
