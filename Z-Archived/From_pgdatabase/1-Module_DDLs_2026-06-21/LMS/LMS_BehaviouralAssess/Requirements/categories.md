# Categories & Criteria — Requirements

## What It Does
Manages the behavioural taxonomy — categories (e.g., "Classroom Engagement") with polarity (positive/negative), weights, and observable criteria within each category. Also supports class-level applicability mapping.

## Database Fields

### `ba_categories`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `parent_id` | BIGINT UNSIGNED | Nullable FK → self. Self-reference for sub-categories. `ON DELETE SET NULL`. |
| `name` | VARCHAR(100) | Required. Category name (e.g., "Classroom Engagement"). |
| `description` | TEXT | Nullable. |
| `polarity` | ENUM('positive','negative') | Required. Whether this tracks desirable or undesirable behaviours. |
| `weight` | DECIMAL(5,2) | Default `100.00`. Contribution to overall score (proportional weighting). |
| `sort_order` | TINYINT UNSIGNED | Required. Display order. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `ba_criteria`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `category_id` | BIGINT UNSIGNED | FK → `ba_categories.id`. Parent category. `ON DELETE CASCADE`. |
| `name` | VARCHAR(255) | Required. Criterion text (e.g., "Active participation in class discussions"). |
| `description` | TEXT | Nullable. |
| `weight` | DECIMAL(5,2) | Default `0.00`. Weight within category (proportional). |
| `sort_order` | TINYINT UNSIGNED | Required. Display order within category. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### `ba_class_category_jnt`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `class_id` | INT UNSIGNED | FK → `sch_classes.id` (cross-module). `ON DELETE CASCADE`. |
| `category_id` | BIGINT UNSIGNED | FK → `ba_categories.id`. `ON DELETE CASCADE`. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_class_cat` — `(class_id, category_id)`: one mapping per class per category.

## Business Rules

**Polarity Concept**
- **Positive** categories (e.g., "Classroom Engagement"): higher rating = better score.
- **Negative** categories (e.g., "Disruptive Behaviours"): scores are **inverted** during computation: `inverted_score = (max_scale_value + 1) - raw_rating`. A student rated 5 (worst) on a negative criterion gets an inverted score of 1 (best).

**Weighting**
- Category weights and criterion weights are **proportional** — they do NOT need to sum to 100.
- The engine calculates: `contribution = (score × weight) / sum_of_all_weights`.
- Default seed: all categories have `weight = 100` (equal contribution).
- Default seed: criteria within a category get equal weight = 100/count.

**Class Applicability**
- Categories are mapped to classes via `ba_class_category_jnt`.
- Different grade levels can have different categories (e.g., Primary gets only positive categories; Secondary gets all).
- If no mappings exist for a class, ALL active categories apply (permissive default).

**Hierarchy**
- Categories support self-referencing via `parent_id` for sub-categories.
- Default seed data uses all top-level categories (`parent_id = NULL`).
- On edit, a category cannot be set as its own parent.

## CRUD Operations

### Categories

**Create**
- Route: `POST /behavioural-assessment/categories` → via modal form
- Validates: `name` required, max:100; `polarity` enum; `weight` numeric 0–100; `sort_order` integer

**List**
- Route: `GET /behavioural-assessment/categories` → accordion list with nested criteria
- Shows polarity badge, weight, sort order, active/inactive status, actions

**View**
- Route: `GET /behavioural-assessment/categories/{category}` → category detail with criteria list

**Update**
- Route: `PUT /behavioural-assessment/categories/{category}` → validates → updates → logs activity

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/categories/{category}` → cascades to criteria
- Pre-delete: deactivates (`is_active = false`)
- Blocked if criteria have existing assessment ratings

**Reorder**
- Route: `POST /behavioural-assessment/categories/reorder` → accepts array of IDs in new order → updates sort_order

### Criteria

**Create**
- Route: `POST /behavioural-assessment/categories/{category}/criteria` → via modal
- Validates: `name` required, max:255; `weight` numeric 0–100; `sort_order` integer

**List**
- Route: `GET /behavioural-assessment/categories/{category}/criteria` → inline list within category accordion

**View**
- Route: `GET /behavioural-assessment/criteria/{criterion}` → criterion detail

**Update**
- Route: `PUT /behavioural-assessment/criteria/{criterion}` → validates → updates → logs activity

**Delete (Soft)**
- Route: `DELETE /behavioural-assessment/criteria/{criterion}` → blocked if assessment ratings exist
- Deactivate via `is_active = false` instead of delete if ratings exist

**Reorder**
- Route: `POST /behavioural-assessment/categories/{category}/criteria/reorder` → drag-and-drop SortableJS

### Class-Category Mapping

**List**
- Route: `GET /behavioural-assessment/class-category-mapping` → checkbox matrix: classes × categories

**Save**
- Route: `POST /behavioural-assessment/class-category-mapping` → accepts `class_id` + array of `category_ids`
- UPSERTs mappings: adds new, removes unchecked

**Delete**
- Route: `DELETE /behavioural-assessment/class-category-mapping/{mapping}` → removes single mapping

## Permissions

| Operation | Permission Key |
|---|---|
| View categories tab | `tenant.ba.category.viewAny` |
| View category details | `tenant.ba.category.viewAny` |
| Create/Edit categories | `tenant.ba.category.manage` |
| Delete categories | `tenant.ba.category.manage` |
| Manage criteria | `tenant.ba.category.manage` |
| Manage class-category mapping | `tenant.ba.category.manage` |

## Seeded Data

**9 Categories (5 Positive + 4 Negative) with 58 Criteria:**

| # | Category | Polarity | Criteria Count |
|---|---|---|---|
| 1 | Classroom Engagement | Positive | 8 |
| 2 | Respect & Responsibility | Positive | 8 |
| 3 | Cooperation & Collaboration | Positive | 7 |
| 4 | Emotional & Social Development | Positive | 6 |
| 5 | Leadership & Initiative | Positive | 6 |
| 6 | Disruptive Behaviours | Negative | 7 |
| 7 | Aggressive / Bullying | Negative | 6 |
| 8 | Academic Misconduct | Negative | 6 |
| 9 | Health & Safety Violations | Negative | 4 |
