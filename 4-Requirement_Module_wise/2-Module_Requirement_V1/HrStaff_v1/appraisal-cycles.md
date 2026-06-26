# Appraisal Cycles — Requirements

## What It Does
Defines performance appraisal periods with configurable date windows for self-assessment and manager review. Each cycle is linked to a KPI template. Supports 4 appraisal types: annual, mid-year, probation, and confirmation. Features auto/manual reviewer assignment modes and department-specific applicability.

Features:
- 4 appraisal types
- Self-assessment and manager review date windows
- Auto or manual reviewer assignment
- Department filtering (which departments participate)
- Linked to KPI template for rating criteria
- 3 status states: draft, active, closed
- Soft-delete with full restore

## Database Fields

**hrs_appraisal_cycles**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `name` | VARCHAR(200) | Required. E.g., `Annual Appraisal 2025-26`, `Probation Review - John Doe`. |
| `academic_year_id` | BIGINT UNSIGNED FK → `glb_academic_sessions` | Required. |
| `appraisal_type` | ENUM | `annual`, `mid_year`, `probation`, `confirmation`. |
| `kpi_template_id` | BIGINT UNSIGNED FK → `hrs_kpi_templates` | Required. KPI criteria for this cycle. |
| `self_open_date` | DATE | Self-assessment start. |
| `self_close_date` | DATE | Self-assessment end. Must be after open. |
| `manager_open_date` | DATE | Manager review start. |
| `manager_close_date` | DATE | Manager review end. Must be after open. |
| `applicable_departments` | JSON | Array of department IDs. Cast to array. Empty = all departments. |
| `reviewer_mode` | ENUM | `auto`, `manual`. |
| `status` | ENUM | `draft`, `active`, `closed`. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Appraisal Type Behavior**
- `annual`: Yearly performance review. All eligible employees participate.
- `mid_year`: Half-yearly review. Optional — schools may or may not conduct.
- `probation`: Probation period review. For employees nearing probation end.
- `confirmation`: Confirmation review. For employees completing probation.

**Date Windows**
- `self_open_date` → `self_close_date`: Employees submit their self-assessment
- `manager_open_date` → `manager_close_date`: Managers/reviewers submit their assessment
- Self window must close before manager window opens (not enforced at DB level but as a business rule)
- Date validation: `self_close_date > self_open_date`, `manager_close_date > manager_open_date`

**Reviewer Assignment Modes**
- `auto`: System auto-assigns reviewer based on employee's reporting hierarchy (department head, manager)
- `manual`: HR manually assigns reviewers during cycle setup

**Department Filter**
- `applicable_departments` is a JSON array of `sch_department` IDs
- Empty array = all departments participate
- Non-empty = only employees in specified departments are included in the cycle
- Used when generating appraisals for the cycle

**Status Lifecycle**
```
draft → active → closed
```
- `draft`: Setup phase. Editable. Appraisals not yet generated.
- `active`: Appraisals generated and in progress. Date windows enforced.
- `closed`: All appraisals finalized. No further submissions allowed.

**Generation**
- When a cycle is activated, `AppraisalController@generate` creates appraisal records for all eligible employees
- Eligible = employees in applicable departments with matching employee category (template's applicable_to)
- For probation type: only employees whose probation_end_date falls within a configurable window

## CRUD Operations

**List Appraisal Cycles**
- Table: name, type, academic year, status, date windows, department count
- Color-coded status badges

**Create Appraisal Cycle**
- Type selector changes available fields (probation type adds employee search)
- KPI template dropdown filtered by applicability
- Department multi-select
- Date window pickers

**Show / Edit / Update / Destroy**
- Edit restricted when status is `active` or `closed` (policy check)
- Only `draft` cycles can be updated or deleted

**Toggle Active Status / Soft Delete / Restore / Force Delete**

## Permissions

| Operation | Permission Key |
|---|---|
| View appraisal cycles | `hrs.appraisal.manage` |
| Create / Edit cycles | `hrs.appraisal.manage` |
| Delete (draft only) / Restore / Force delete | `hrs.appraisal.manage` |
