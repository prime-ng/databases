# Appraisals — Requirements

## What It Does
The core appraisal workflow: employees submit self-ratings against KPI items, managers/reviewers submit review ratings, HR finalizes the appraisal. Supports 2-phase rating (self + reviewer) with weighted computation. Appraisal results can trigger increment processing via IncrementFlag.

Features:
- 2-phase rating: self-assessment followed by manager review
- KPI item ratings stored as JSON with individual scores
- Weighted overall rating computation
- Self comments and reviewer comments
- HR remarks for finalization
- 4 status states: draft, submitted, reviewed, finalized
- AppraisalFinalized event on completion
- Auto-increment flag creation on finalization
- Soft-delete with restore

## Database Fields

**hrs_appraisals**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `cycle_id` | BIGINT UNSIGNED FK → `hrs_appraisal_cycles` | Required. |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. |
| `reviewer_id` | BIGINT UNSIGNED FK → `sch_employees` | Nullable. Assigned reviewer. |
| `self_rating_json` | JSON | Array of `{kpi_item_id, rating, comment}`. Cast to array. |
| `reviewer_rating_json` | JSON | Array of `{kpi_item_id, rating, comment}`. Cast to array. |
| `overall_rating` | DECIMAL(5,2) | Weighted average rating out of the template's scale. |
| `self_comments` | TEXT | Nullable. Employee's overall comments. Min 10, max 2000. |
| `reviewer_comments` | TEXT | Nullable. Reviewer's overall comments. |
| `hr_remarks` | TEXT | Nullable. HR's final remarks. |
| `status` | ENUM | `draft`, `submitted`, `reviewed`, `finalized`. |
| `finalized_at` | DATETIME | Nullable. When finalized. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

**hrs_appraisal_increment_flags**

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `appraisal_id` | BIGINT UNSIGNED FK → `hrs_appraisals` | Required. Unique. |
| `employee_id` | BIGINT UNSIGNED FK → `sch_employees` | Required. |
| `cycle_id` | BIGINT UNSIGNED FK → `hrs_appraisal_cycles` | Required. |
| `flag_status` | ENUM | `pending`, `processed`. Default `pending`. |
| `processed_at` | DATETIME | Nullable. When the increment was processed. |
| `is_active` | BOOLEAN | Default true. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard timestamps. |

## Business Rules

**Appraisal Status Workflow**
```
draft → submitted → reviewed → finalized
```

1. **draft**: Appraisal created by system (cycle generation). Employee can fill self-assessment.
2. **submitted**: Employee has submitted self-assessment. Read-only for employee.
3. **reviewed**: Manager/reviewer has submitted review assessment. Read-only for both.
4. **finalized**: HR has marked as finalized. Final score locked. `AppraisalFinalized` event fired.

**Self-Assessment Flow**
- Employee sees KPI items from the cycle's template
- Each item: name, description (if any), weight, rating slider/selector
- Employee rates each item and can add per-item comments
- Overall self-comments field
- On submit: `self_rating_json` is saved, status → `submitted`
- Validation: all items must be rated, `self_comments` min 10 chars

**Reviewer Assessment Flow**
- Reviewer sees the employee's self-ratings and their own rating columns side by side
- Reviewer rates each item independently (does not see employee's rating by default — configurable)
- Reviewer adds per-item comments and overall `reviewer_comments`
- On submit: `reviewer_rating_json` is saved, status → `reviewed`

**Overall Rating Computation**
- Weighted average of reviewer ratings (if available) else self ratings
- Formula: `sum(kpi_item.rating × kpi_item.weight) / sum(weights)`
- Result stored in `overall_rating`
- Scale matches the template's rating scale (5 or 10)

**Finalization**
- HR reviews the self and reviewer assessments
- Adds `hr_remarks` (optional)
- On finalize: status → `finalized`, `finalized_at` = now
- Creates `AppraisalIncrementFlag` with `flag_status = pending`
- Fires `AppraisalFinalized` event

**Self vs Reviewer Rating Priority**
- If reviewer rating exists: that's used for overall computation
- If no reviewer rating (employee not yet reviewed): self rating is used
- If neither: overall_rating = null (appraisal not yet submitted)

**Increment Flag**
- Created automatically when appraisal is finalized
- `flag_status = pending`: ready for increment processing
- `flag_status = processed`: increment already applied
- One-to-one with appraisal (unique `appraisal_id`)

## CRUD Operations

**List Appraisals**
- Tabbed: My Appraisals (employee), Pending Review (reviewer), All Appraisals (HR)
- Filters: cycle, status, employee, department
- Columns: employee, cycle, type, overall rating, status, actions

**Show Appraisal**
- Full view: employee info, KPI items with self/ reviewer ratings side by side, comments, HR remarks
- Rating breakdown table per KPI item
- Timeline of status changes

**Generate Appraisals (for cycle)**
- Creates appraisal records for all eligible employees in a cycle
- Eligible = employees in applicable departments with matching category
- Idempotent: skips employees who already have an appraisal for this cycle
- If `reviewer_mode = auto`: assigns reviewer based on hierarchy

**Submit Self-Assessment**
- Status must be `draft`
- Saves `self_rating_json`, `self_comments`
- Status → `submitted`

**Submit Review**
- Status must be `submitted`
- Saves `reviewer_rating_json`, `reviewer_comments`
- Computes `overall_rating`
- Status → `reviewed`

**Finalize Appraisal**
- Status must be `reviewed`
- Sets `finalized_at`, `hr_remarks`
- Status → `finalized`
- Creates `AppraisalIncrementFlag`
- Fires `AppraisalFinalized` event

**Soft Delete / Restore / Force Delete**
- Only draft/submitted appraisals can be deleted
- Finalized appraisals cannot be deleted

## Permissions

| Operation | Permission Key |
|---|---|
| View all appraisals | `hrs.appraisal.manage` |
| Submit self-assessment | `hrs.appraisal.self` |
| Submit review (as manager) | `hrs.appraisal.review` |
| Finalize appraisal | `hrs.appraisal.manage` |
| Delete appraisal | `hrs.appraisal.manage` |
