# Rating Scales — Requirements

## What It Does
Manages configurable rating scales used as the measurement instrument for behavioural assessment. Each scale defines an ordered set of levels (e.g., 5-point) with labels, numeric values, and grade boundary mapping.

## Database Fields

### `ba_rating_scales`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `code` | VARCHAR(30) | Required. Machine-readable identifier (e.g., `5_POINT`). |
| `name` | VARCHAR(100) | Required. Scale name (e.g., "5-Point Behavioural Scale"). |
| `description` | TEXT | Nullable. Optional description. |
| `grade_type` | VARCHAR(20) | Required. How grades are displayed: `letter` / `numeric` / `descriptive`. |
| `min_rating` | DECIMAL(3,1) | Required. Minimum rating value (e.g., 1.0). |
| `max_rating` | DECIMAL(3,1) | Required. Maximum rating value (e.g., 5.0). |
| `is_default` | BOOLEAN | Default `0`. Whether this is the school's default scale. |
| `is_active` | BOOLEAN | Default `1`. Soft enable/disable. |
| `created_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `ba_rating_levels`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `rating_scale_id` | BIGINT UNSIGNED | FK → `ba_rating_scales.id`. Parent scale. |
| `label` | VARCHAR(50) | Required. Display label (e.g., "Outstanding"). |
| `numeric_value` | DECIMAL(3,1) | Required. Value for computation (e.g., 5.0). |
| `description` | VARCHAR(255) | Nullable. Optional description. |
| `sort_order` | TINYINT UNSIGNED | Required. Display order (1 = lowest/worst). |
| `is_active` | BOOLEAN | Default `1`. Soft enable/disable. |
| `created_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_level` — `(rating_scale_id, sort_order)`: one level per sort order per scale.

## Business Rules

**Scale-Level Relationship**
- A scale must have at least 2 levels defined (enforced in `StoreRatingScaleRequest`).
- `numeric_value` must fall within the parent scale's `[min_rating, max_rating]` range.
- Only one scale can have `is_default = 1` at a time (enforced at application layer).
- `sort_order = 1` represents the LOWEST level; highest `sort_order` = best.

**Grade Boundary Mapping**
- Grade mapping is derived from `min_rating`/`max_rating` + `ba_rating_levels.numeric_value` ranges.
- Boundaries are configurable per scale — allows different schools to use different letter-to-score mappings.

**CRUD Cascade**
- Deleting a scale (soft) cascades to its levels via `ON DELETE CASCADE`.
- Deleting a level sets `rating_level_id = NULL` on existing `ba_assessment_ratings` (via `ON DELETE SET NULL`).

## CRUD Operations

**Create**
- Route: `GET /behavioural-assessment/rating-scales/create` → form with dynamic level rows
- Submit: `POST /behavioural-assessment/rating-scales` → validates (name required, at least 2 levels, unique sort_order per scale) → saves → redirects to index
- Levels are saved as a nested array: `levels[0][label]`, `levels[0][numeric_value]`, etc.

**List**
- Route: `GET /behavioural-assessment/rating-scales` → table with name, grade type, level count, default badge, status, actions
- Default scale shown first with a "Default" badge

**View**
- Route: `GET /behavioural-assessment/rating-scales/{scale}` → full detail with levels table and grade boundaries

**Update**
- Route: `PUT /behavioural-assessment/rating-scales/{scale}` → validates → updates scale + syncs levels (add/remove/reorder)
- Change detection: log changes to `ba_audit_log` for rating scale/level modifications

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/rating-scales/{scale}` → SweetAlert2 confirmation → soft deletes scale + cascades to levels
- Cannot delete if scale is referenced by `ba_config` for any academic session

**Restore**
- Route: Route for restoring soft-deleted scales
- Trash page shows soft-deleted scales with restore/force-delete actions

**Force Delete**
- Route: Route for permanent deletion
- Only available for already soft-deleted records
- Blocked if any `ba_assessment_ratings` reference levels from this scale

## Permissions

| Operation | Permission Key |
|---|---|
| View rating scales tab | `tenant.ba.scale.manage` |
| View scale details | `tenant.ba.scale.manage` |
| Create scale | `tenant.ba.scale.manage` |
| Update scale | `tenant.ba.scale.manage` |
| Delete (soft) scale | `tenant.ba.scale.manage` |
| Restore scale | `tenant.ba.scale.manage` |
| Force delete scale | `tenant.ba.scale.manage` |
