# KPI Templates — Requirements

## What It Does
Defines reusable KPI (Key Performance Indicator) templates for employee performance appraisals. Each template contains multiple KPI items with categories (academic, behavioral, administrative), weights, and descriptions. Templates can be assigned to appraisal cycles. Supports 5-point or 10-point rating scales. Soft-delete with full restore.

Features:
- Configurable rating scale (5-point or 10-point)
- KPI categorization (academic, behavioral, administrative)
- Weighted KPI items (sum must equal 100%)
- Applicability filter (All/Teaching/Non-Teaching)
- Reusable across multiple appraisal cycles
- Soft-delete with full restore/force-delete workflow

## Database Fields

**hrs_kpi_templates**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(200) | Required. E.g., `Teaching Staff KPI`, `Admin Staff KPI`. |
| `applicable_to` | ENUM | `All`, `Teaching`, `Non-Teaching`. |
| `rating_scale` | INTEGER | 5 or 10. Max rating value. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |
| `created_by` | BIGINT UNSIGNED FK → `sys_users` | Who created the template. |

**hrs_kpi_template_items**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `template_id` | BIGINT UNSIGNED FK → `hrs_kpi_templates` | Required. CASCADE on delete. |
| `kpi_name` | VARCHAR(200) | Required. E.g., `Lesson Plan Quality`, `Student Engagement`. |
| `category` | ENUM | `academic`, `behavioral`, `administrative`. |
| `weight` | DECIMAL(5,2) | Weight percentage for this KPI. E.g., 30.00 = 30%. |
| `description` | VARCHAR(500) | Nullable. Detailed description of what this KPI measures. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Weight Allocation**
- Sum of all KPI item weights in a template must equal 100.00
- Validated at store/update time
- Example: Academic (40%) + Behavioral (35%) + Administrative (25%) = 100%

**Rating Scale Interpretation**
- 5-point scale: 1=Poor, 2=Below Average, 3=Average, 4=Good, 5=Excellent
- 10-point scale: 1-10 with more granular differentiation
- Overall rating is computed as weighted average: `sum(rating × weight) / sum(weights)`
- Scale is set at template level — all items use the same scale

**Template Reusability**
- A template can be used across multiple appraisal cycles
- Changes to a template after cycles have started do NOT retroactively change existing appraisals
- The template is snapshotted via the appraisal cycle's `kpi_template_id` — the cycle gets the template's items at creation time

**Applicability**
- `All`: Template available for all employee categories
- `Teaching`: Only teaching staff appraisals can use this template
- `Non-Teaching`: Only non-teaching staff appraisals can use this template

## CRUD Operations

**List KPI Templates**
- Table: name, rating scale, applicable to, item count, active status
- Expandable rows showing KPI items

**Create KPI Template**
- Dynamic KPI item rows: name, category dropdown, weight, description
- Weight sum indicator (must reach 100%)
- Rating scale selector

**Show / Edit / Update / Destroy**
- Items re-orderable by drag and drop

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View / Manage KPI templates | `hrs.kpi_template.manage` |
| Create / Edit / Delete | `hrs.kpi_template.manage` |
| Toggle status / Restore / Force delete | `hrs.kpi_template.manage` |
