# Feedback Tab 1: Dashboard

This is the first screen the user sees when they open the Feedback module. It provides a high-level overview of all feedback activity across the school — active cycles, response counts, participation rates, and pending items that need attention.

---

## How It Works

When the user opens this tab, they see summary cards at the top showing key metrics: number of active feedback cycles, total responses submitted today, overall participation rate across all cycles, and how many targets have not yet reached the minimum response threshold. Each card can be clicked to drill into more detail.

Below the cards is a list of all feedback cycles sorted by status. Active cycles appear first, followed by Draft, Closed, and Published cycles. Each cycle row shows its name, date range, the number of feedback types included, total expected responses, and how many have been received so far. A progress bar visually shows completion.

At the bottom there is a pending-responses section that shows cycles where the user themselves has not yet submitted their feedback. This personal to-do list helps teachers, students, and parents quickly find what they still need to complete.

Users can filter the dashboard by academic session, term, and date range to focus on a specific period.

---

## Important Business Rules

- The dashboard shows data across all cycles the user has permission to view. Teachers see cycles relevant to their classes. Students see cycles they need to respond to. Admins see everything.
- Summary numbers are read from fbk_summary (materialized aggregates) for performance, with real-time counts for today's submissions only.
- A cycle is considered "active" when current date falls between start_date and end_date and status is Active.
- The participation rate is calculated as: (Total Submitted Responses / Total Expected Responses) × 100 across all active cycles.
- The personal pending-responses section checks if the logged-in user has any incomplete draft or no response for each cycle feedback type where they are an eligible respondent.
- Cycles with zero expected responses or zero feedback types are not shown on the dashboard.
- The dashboard refreshes on page load. Users can manually refresh to see updated counts.

---

## Database Columns & Behavior

### fbk_cycles (displayed as cycle rows)
- `id` — Primary key. Links to other tables for aggregations.
- `name` — Displayed as the cycle title. VARCHAR(200).
- `start_date` / `end_date` — Date range. Used to determine active status and progress. DATE.
- `status_id` — FK to sys_dropdown_table (key: fbk_cycles.status). Determines cycle badge color and sort order. INT UNSIGNED.
- `academic_session_id` — Filters dashboard by session. FK to sch_org_academic_sessions_jnt.

### fbk_summary (materialized aggregate source)
- `cycle_id` — FK to fbk_cycles. Used to group aggregates per cycle.
- `total_responses` — Count of submitted responses. SMALLINT UNSIGNED.
- `eligible_respondent_count` — How many respondents were expected. SMALLINT UNSIGNED.
- `participation_rate` — Computed percentage. DECIMAL(5,2).
- `respondent_breakdown_json` — JSON breakdown of respondent kinds (Student, Parent, Teacher).

### fbk_responses (for personal pending items)
- `respondent_user_id` — Filtered to the logged-in user. FK to sys_users.
- `cycle_id` — FK to fbk_cycles. Determines which cycle the user needs to act on.
- `status_id` — FK to sys_dropdown_table (key: fbk_responses.status). Only statuses Draft and Submitted are relevant.
- `submitted_at` — Used to determine if response was submitted. TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines

This is a read-only aggregate view with no state transitions. The primary workflow is navigation/drill-down: clicking a summary card navigates to Tab 9 (Results & Reports) filtered by that cycle, clicking a pending response navigates to Tab 8 (Response Collection). Dashboard data refreshes on page load with manual refresh capability. Filter workflow: user selects academic session, term label, and/or date range — the system re-query fbk_summary and fbk_cycles accordingly.

### Validation Rules & Edge Cases

- Dashboard is purely read-only; no data mutations occur from this tab.
- Edge case: user belongs to zero cycles — dashboard shows empty states for all sections except summary cards (which show 0s).
- Edge case: a cycle with no feedback types or zero expected responses is excluded — must not appear in cycle list or pending section.
- Edge case: date range filter that excludes all cycles — show "No cycles match filters" with a clear-all button.
- Edge case: today's submission count in summary cards uses real-time query from fbk_responses, but the other aggregates come from fbk_summary — these could diverge by seconds if a submission is in-flight.
- Performance: fbk_summary must be indexed on (cycle_id, target_user_id, is_published) to keep dashboard queries fast.
- The participation rate formula must guard against division by zero when eligible_respondent_count = 0.
- Personal pending-responses must exclude responses with status = Withdrawn.

### Integration Points

- **fbk_cycles** via cycle_id for cycle list and status-based sorting.
- **fbk_summary** via cycle_id for aggregate metrics (total_responses, participation_rate, respondent_breakdown_json).
- **fbk_responses** via respondent_user_id + cycle_id for personal pending items.
- **sch_org_academic_sessions_jnt** via academic_session_id for session filter.
- **sys_users** via respondent_user_id to identify the logged-in user.
- **sys_dropdown_table** via status_id to resolve cycle status display labels and sort order.

### Permissions Matrix

| Action | Admin | Principal | Teacher | Student | Parent | Staff |
|---|---|---|---|---|---|---|
| View all cycles | Yes | Yes | Own classes only | Own responses only | Own children only | Own responses only |
| View summary aggregates | Yes | Yes | Own targets only | No | No | No |
| View pending items | Yes | Yes | Yes (own) | Yes (own) | Yes (own) | Yes (own) |
| Filter dashboard | Yes | Yes | Yes | Yes | Yes | Yes |
| Drill down to results | Yes | Yes | Own targets | No | No | No |
| Drill down to response | Yes | Yes | Yes (own) | Yes (own) | Yes (own) | Yes (own) |
