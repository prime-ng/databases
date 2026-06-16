# Feedback Tab 9: Results & Reports

This screen displays aggregate feedback results for targets, administrators, and school leadership. It shows average ratings, participation rates, category breakdowns, rating distributions, and highlights of top positive and concerning comments. The data comes from pre-computed summary tables for fast dashboard loading.

---

## How It Works

Targets (teachers, staff, departments) see their own feedback results once the minimum response threshold is met. Administrators and principals can view results for all targets across the school. The screen shows a summary card with the average rating, total responses received, and participation rate for the selected cycle and feedback type.

A detailed breakdown shows average ratings by category (theme), so a teacher can see they scored 4.5 on Teaching Quality but 3.2 on Communication. A rating distribution chart shows how many responses fell into each rating level (1 through 5 or 1 through 10). A respondent breakdown shows average ratings split by who provided the feedback — for example, Students rated 4.2, Parents rated 4.5, and Peer Teachers rated 4.1.

The screen also shows highlighted comments. The system automatically identifies top positive comments (from responses with high overall ratings) and top concern comments (from responses with low overall ratings or specific negative feedback). These give the target actionable qualitative insights alongside the quantitative scores.

Users can filter results by academic session, cycle, term, feedback type, and optionally by class section or subject. Trend charts compare ratings across multiple cycles to show improvement or decline over time.

---

## Important Business Rules

- Results are only visible to the target when the minimum response threshold is met. This protects respondent anonymity in small groups (k-anonymity). The default threshold is 3 responses.
- Anonymous responses never expose respondent identity. The target sees only aggregate numbers and comments stripped of identifying information.
- Administrators and principals can bypass the minimum response threshold and view all results, including respondent identities if needed for audit and abuse prevention.
- Results for peer relationships always have anonymity enforced. The target sees aggregate numbers only.
- Category averages are computed from grouped question weights within each category. Only numeric question types contribute to averages.
- Rating distribution shows the count of responses at each scale level. For Likert_5, this shows Strongly Disagree through Strongly Agree counts.
- Trend comparison requires at least two completed cycles with the same feedback type and target. The system shows available cycles for comparison in a dropdown.
- Summary data is stored in fbk_summary and is recomputed incrementally on each response submission or withdrawn, and fully recomputed when a cycle is closed.
- Targets can download their results as PDF or CSV for portfolio and performance review purposes.
- The overall rating displayed uses the template's configured rating method (weighted average, simple average, manual, or none).

---

## Database Columns & Behavior

### fbk_summary (materialized aggregate table)
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `cycle_id` — FK to fbk_cycles.id. INT UNSIGNED.
- `cycle_feedback_type_id` — FK to fbk_cycle_feedback_types.id. INT UNSIGNED.
- `target_type_id` — FK to fbk_target_types.id. SMALLINT UNSIGNED.
- `target_user_id` / `target_student_id` / `target_employee_id` / `target_department_id` — Polymorphic target identity. One populated. INT UNSIGNED, nullable.
- `class_section_id` / `subject_id` — Optional slice for sub-aggregates. INT UNSIGNED, nullable.
- `total_responses` — Total submitted responses count. SMALLINT UNSIGNED, default 0.
- `respondent_breakdown_json` — JSON with response counts per respondent kind. Example: {"Student":15,"Parent":8}. JSON, nullable.
- `eligible_respondent_count` — How many respondents were expected. SMALLINT UNSIGNED, nullable.
- `participation_rate` — Percentage of eligible respondents who submitted. DECIMAL(5,2), nullable.
- `average_rating` — Overall average rating. DECIMAL(4,2), nullable.
- `respondent_averages_json` — JSON with average rating per respondent kind. JSON, nullable.
- `rating_distribution_json` — JSON with count per rating level. Example: {"1":2,"2":5,"3":15}. JSON, nullable.
- `category_averages_json` — JSON with average rating per category code. JSON, nullable.
- `top_positive_comments_json` / `top_concern_comments_json` — Highlighted comments. JSON, nullable.
- `computed_at` — Timestamp of last computation. TIMESTAMP, nullable.
- `is_published` — Whether results are published to the target. TINYINT(1), default 0.
- `published_at` — When results were published. TIMESTAMP, nullable.

---

## Deep Analysis

### Business Workflows & State Machines

Results viewing is read-only with no state transitions. The key workflow is data computation:

1. **Incremental computation**: On every response Submit or Withdraw, the system recomputes the affected fbk_summary row(s). This is a real-time update — the affected row is identified via cycle_target_id or through (cycle_feedback_type_id, target identity).
2. **Full recomputation**: When a cycle transitions to Closed, the system runs a full recomputation of all fbk_summary rows for that cycle. This ensures data consistency and catches any missed incremental updates.
3. **Publish**: When cycle is Published (from Closed), is_published is set to 1 on all fbk_summary rows for that cycle. Targets can now view their results.

Target viewing workflow:
- Target logs in → navigates to Results → selects cycle → system checks fbk_summary.is_published AND total_responses ≥ min_responses_for_visibility → displays results if both conditions met.

### Validation Rules & Edge Cases

- **K-anonymity threshold**: If total_responses < min_responses_for_visibility (from cycle or cycle feedback type), the target sees "Not enough responses yet" instead of results. Admins bypass this.
- **Threshold value source**: The effective threshold is MAX(cycle.default_min_responses_for_visibility, cycle_feedback_type.min_responses_for_visibility). The fbk_summary.total_responses is compared against this effective threshold.
- **Peer anonymity enforcement**: For is_peer_relationship = 1, the system must:
  - Strip all respondent identity from comments in top_positive_comments_json and top_concern_comments_json.
  - Never expose respondent_breakdown_json at the individual level.
  - Only show aggregate numbers.
- **Admin bypass of k-anonymity**: Admins and principals can view results below the threshold. This is an explicit design choice for abuse prevention. The UI should show a banner: "Results below minimum responses — identities visible for audit purposes."
- **Self-relationships**: For is_self_relationship = 1, results show the individual's own self-assessment. The k-anonymity threshold does not apply (single respondent is the only one). But aggregate results that include self + other respondents follow normal rules.
- **Category averages with zero submissions**: If a category has 0 numeric responses, its average should be NULL. The display should show "N/A" rather than 0.
- **Rating distribution for Yes_No/Free_Text**: These question types contribute to NO distribution counts. The distribution only includes numeric types.
- **Trend comparison period alignment**: When comparing cycles, the system should align by term or date range for meaningful comparison. Comparing Annual cycle to Q1 cycle is misleading — the system should warn.
- **Zero participation**: When eligible_respondent_count = 0, participation_rate is NULL (not 0%). Division by zero guard.
- **Data freshness indicator**: fbk_summary.computed_at should be displayed to the user alongside results. "Results as of [timestamp]."
- **Download format**: PDF should include all charts and comments. CSV should include raw per-question data (one row per response) for advanced analysis in Excel.

### Integration Points

- **fbk_cycles** via cycle_id — filtering and lifecycle context.
- **fbk_cycle_feedback_types** via cycle_feedback_type_id — resolves template, anonymity, threshold settings.
- **fbk_templates** via cycle_feedback_type_id → template_id — determines rating method.
- **fbk_target_types** via target_type_id — determines target kind and display properties.
- **fbk_responses** via cycle_feedback_type_id + target identity — source data for summary computation.
- **fbk_answers** via response_id — source for category averages and comment highlighting.
- **sys_users** via target_user_id — for user-type target identity resolution.
- **std_students** via target_student_id — student target identity.
- **sch_employees** via target_employee_id — employee target identity.
- **sch_departments** via target_department_id — department target identity.
- **sch_org_academic_sessions_jnt** via cycle.academic_session_id — session filter.
- **Rating calculation engine**: Used during computation to recalculate averages.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View own results (threshold met) | Yes | Yes | Yes | Yes (self-reflection) | No | Yes |
| View own results (below threshold) | Bypass | Bypass | No | No | No | No |
| View all targets' results | Yes | Yes | No | No | No | No |
| View respondent identity | Yes | Yes | No | No | No | No |
| View peer results | Yes | Yes | Aggregate only | Aggregate only | No | Aggregate only |
| Download PDF/CSV (own) | Yes | Yes | Yes | Yes (self) | No | Yes |
| Download PDF/CSV (all) | Yes | Yes | No | No | No | No |
| View trend comparison | Yes | Yes | Yes (own) | No | No | Yes (own) |
