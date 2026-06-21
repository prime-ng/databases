# Score Computation — Requirements

## What It Does
Cached computed scores per student per category per assessment period. The computation engine aggregates raw teacher ratings through weighted criteria → category → overall score, with multi-teacher averaging, negative polarity inversion, and grade mapping.

## Database Fields

### `ba_computed_scores`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED | FK → `std_students.id` (cross-module). |
| `category_id` | BIGINT UNSIGNED | FK → `ba_categories.id`. Category scored. |
| `period_id` | BIGINT UNSIGNED | FK → `ba_assessment_periods.id`. Assessment period. |
| `numeric_score` | DECIMAL(5,2) | Required. Computed category score. |
| `grade` | VARCHAR(5) | Nullable. Mapped grade (e.g., "A+"). |
| `overall_score` | DECIMAL(5,2) | Nullable. Overall weighted score (stored once on first category row). |
| `overall_grade` | VARCHAR(5) | Nullable. Overall mapped grade. |
| `computed_at` | TIMESTAMP | Required. When score was last computed. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |

**Unique Constraints:**
- `uq_ba_score` — `(student_id, category_id, period_id)`: one score per student per category per period.

## Computation Algorithm

```
Step 1: SELECT all ba_assessment_ratings WHERE student_id AND assessment.period_id
Step 2: GROUP BY criterion_id → for each: AVG(numeric_value) across teachers
Step 3: For negative polarity criteria: inverted = max_scale_value + 1 - raw_avg
Step 4: GROUP criteria BY category_id
Step 5: For each category: weighted_avg(criterion_scores, criterion.weight) → category_score
Step 6: Overall: weighted_avg(category_scores, category.weight) per aggregation_method
Step 7: Map overall_score → grade via grade_boundaries from rating scale
Step 8: UPSERT ba_computed_scores rows (one per category + overall on first)
```

## Business Rules

**Weighted Score Calculation (BR-BA-005, BR-BA-006)**

| Level | Formula | Notes |
|---|---|---|
| **Criterion Score** | `AVG(all teacher ratings for this criterion)` | If multiple teachers assess same student on same criterion |
| **Category Score** | `Σ(criterion_score × criterion_weight) / Σ(criterion_weights)` | Proportional weighted average |
| **Overall Score** | `Σ(category_score × category_weight) / Σ(category_weights)` | Proportional weighted average per aggregation method |
| **Final Result** | `(Academic × (1-w)) + (Behavioural_norm × w)` | Only when `is_result_integration_enabled = true` |

**Negative Polarity Inversion (BR-BA-019)**
- Criteria in negative-polarity categories have their scores inverted after averaging:
  `inverted_score = (max_scale_value + 1) - raw_avg`
- Example: On a 5-point scale, a student rated 5 (worst) on "Bullying" gets an inverted score of 1 (best).

**Grade Mapping (BR-BA-016)**
- Score-to-grade mapping uses the active rating scale's `min_rating`/`max_rating` boundaries.
- Boundaries are derived from `ba_rating_levels` numeric values (no separate JSON boundaries in v2 DDL).

**Computation Triggers**
- Automatic: When an assessment is approved (reviewed status).
- Manual: Via `POST /behavioural-assessment/reports/compute/{period}` for full period recomputation.
- Scores are cached in `ba_computed_scores` — read from cache, not recomputed on every view.

## Performance Considerations

- The `ba_assessment_ratings` table is the largest in the module (est. 120K rows/year for 2000 students).
- All computation runs in the `BehaviouralScoreService` — dispatched synchronously on approval, or via job for bulk recomputation.
- `ComputeSchoolScoresJob` handles period-wide recomputation on a queue for large schools.

## Permissions

| Operation | Permission Key |
|---|---|
| Compute scores | `tenant.ba.score.compute` |
| View computed scores | Implicitly via reports |
