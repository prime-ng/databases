# Configuration — Requirements

## What It Does
School-level configuration for the Behavioural Assessment module. One record per academic session controlling the active rating scale, result card integration settings, aggregation method, and parent notification threshold.

## Database Fields

### `ba_config`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `academic_session_id` | SMALLINT UNSIGNED | FK → `sch_org_academic_sessions_jnt.id` (cross-module). Unique per session. |
| `rating_scale_id` | BIGINT UNSIGNED | FK → `ba_rating_scales.id`. Active scale for this session. `ON DELETE RESTRICT`. |
| `is_result_integration_enabled` | BOOLEAN | Default `0`. Whether behavioural scores appear on report cards. |
| `weightage_percent` | DECIMAL(4,1) | Default `10.0`. Contribution to final result (5.0–20.0%). |
| `aggregation_method` | ENUM('average','weighted_average','separate_display') | Default `'weighted_average'`. How category scores combine. |
| `parent_notification_threshold` | ENUM('minor','moderate','major','critical') | Default `'moderate'`. Min severity to trigger parent notification. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_config_session` — `(academic_session_id)`: one config per academic session.

## Business Rules

**Result Integration Formula (BR-BA-007)**
```
Final Result = (Academic Score × (1 - weightage/100)) + (Behavioural Score normalised to 100 × weightage/100)
```
- Example: 10% weightage with Academic=85% and Behavioural=4.2/5.0:
  `(85 × 0.90) + ((4.2/5.0 × 100) × 0.10) = 76.5 + 8.4 = 84.9`

**Aggregation Methods**
- `average` — Simple average of all category scores.
- `weighted_average` — Weighted by `ba_categories.weight` (recommended default).
- `separate_display` — No numeric merge; categories shown individually on report card.

**Parent Notification Threshold**
- `minor`: Notify for ALL incidents (most verbose).
- `moderate`: Notify for moderate, major, critical (default).
- `major`: Notify only for major and critical.
- `critical`: Notify only for critical incidents (least verbose).

**Config Auto-Creation**
- `ba_config` is NOT seeded during tenant onboarding.
- On first access, `BehaviouralConfigService::getConfig()` creates a default record with:
  - `is_result_integration_enabled = false`
  - `weightage_percent = 10.0`
  - `aggregation_method = 'weighted_average'`
  - `parent_notification_threshold = 'moderate'`
  - Default/active rating scale

## CRUD Operations

**View**
- Route: `GET /behavioural-assessment/config` → display current configuration

**Update**
- Route: `PUT /behavioural-assessment/config` → form with toggle, weightage slider (5–20%), aggregation dropdown, notification threshold dropdown, scale selector
- Validates: `rating_scale_id` exists and active; `weightage_percent` between 5 and 20; aggregation method enum
- UPSERTs config for current academic session

## Permissions

| Operation | Permission Key |
|---|---|
| View configuration | `tenant.ba.config.manage` |
| Update configuration | `tenant.ba.config.manage` |
