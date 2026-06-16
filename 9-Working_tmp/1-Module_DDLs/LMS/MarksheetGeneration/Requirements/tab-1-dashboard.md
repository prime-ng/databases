# MarksheetGeneration Tab 1: Marksheet Schedule Dashboard

This is the main landing screen for the MarksheetGeneration module. It gives the admin a bird's-eye view of all marksheet schedules, their current statuses, and recent computation activity. From here, the admin can navigate to create schedules, trigger computations, review results, and manage publications.

---

## How It Works

The dashboard displays a table listing every marksheet schedule across the current academic session. Each row shows the schedule name, marksheet type, linked exam group, the class-sections it covers, the number of students included, and its current lifecycle status. The statuses follow a fixed progression: Draft — Computed — Reviewed — Published — Locked. Colour-coded badges make it easy to spot schedules needing attention.

At the top of the screen, summary cards show counts for each status — how many schedules are still in draft, how many are computed and awaiting review, and how many have been published so far. A quick-action button lets the admin create a new schedule.

Below the schedule table, a section shows the most recent computation log entries. Each entry records when a computation was triggered, by whom, how long it took, whether it succeeded or failed, and how many students were processed. The admin can click through to see detailed error logs if a computation failed.

---

## Important Business Rules

- The dashboard is read-only — all actions (create, compute, review, publish) are performed from individual schedule screens.
- Schedules are scoped to the current academic session by default. The admin can switch sessions using a filter.
- A schedule cannot be computed if any of its class-sections lack a config template assignment. The dashboard shows a warning icon for schedules that are missing configuration.
- Computation logs shown here are the last 10 entries across all schedules. For schedule-specific logs, the admin navigates to the activity log tab.
- If no schedules exist yet, the table shows an empty state with a prompt to create the first schedule.

---

## Database Columns & Behavior

### msh_marksheet_schedules
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `code` — Unique schedule code within the session. VARCHAR(50). E.g. TERM1_SEC_2025.
- `name` — Display name shown on the dashboard. VARCHAR(150).
- `status_id` — Current lifecycle status. FK to sys_dropdowns. Values: DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED.
- `total_students` — Populated after computation. INT UNSIGNED, nullable.
- `config_template_id` — FK to msh_config_templates. Links to the template used.
- `academic_session_id` — FK to sch_org_academic_sessions_jnt.
- `last_computed_at` — Timestamp of last successful computation. DATETIME, nullable.
- `is_locked` — Lock flag after publication. TINYINT(1), default 0.
- `created_by` — FK to sys_users. INT UNSIGNED.
- `created_at` — Record creation timestamp. TIMESTAMP.

### msh_schedule_class_jnt
- `id` — Primary key. INT UNSIGNED, auto-increment.
- `schedule_id` — FK to msh_marksheet_schedules. The parent schedule.
- `class_section_id` — FK to sch_class_section_jnt. A class-section included in this schedule.
- Unique constraint on (schedule_id, class_section_id) — no duplicate assignments.

### msh_computation_logs
- `id` — Primary key. INT UNSIGNED, auto-increment. Immutable audit entry.
- `schedule_id` — FK to msh_marksheet_schedules. Which schedule was computed.
- `action` — The event type: COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, LOCK. VARCHAR(30).
- `triggered_by` — FK to sys_users. Who triggered the action.
- `started_at` — When the computation started. DATETIME, NOT NULL.
- `completed_at` — When it finished. DATETIME, nullable.
- `duration_seconds` — Total runtime. INT UNSIGNED, nullable.
- `total_students` — How many students were processed. INT UNSIGNED, nullable.
- `total_errors` — Count of errors encountered. INT UNSIGNED, default 0.
- `status` — IN_PROGRESS, SUCCESS, FAILED, or PARTIAL. VARCHAR(20).
- `error_log` — JSON text capturing error messages. TEXT, nullable.
- `remarks` — Free-text notes, such as unlock reason. TEXT, nullable.

---

## Deep Analysis

### Business Workflows & State Machines
The dashboard is the read-only entry point reflecting the full schedule lifecycle: **Draft → Computed → Reviewed → Published → Locked**. Each status transition is gated — e.g., Draft→Computed requires template assignment for all class-sections; Reviewed→Published requires explicit admin action. Summary cards count schedules per status, and warning icons flag schedules missing config. The recent computation log section shows the last 10 entries across all schedules; each entry passes through **IN_PROGRESS → SUCCESS/FAILED/PARTIAL**.

### Validation Rules & Edge Cases
- Empty state: if no schedules exist, the table shows a prompt to create the first schedule.
- Status-specific action buttons are hidden/greyed when the action is invalid (e.g., no "Publish" on Draft schedules).
- The "missing config" warning icon must re-evaluate whenever template assignments change.
- Session filter defaults to current academic session; switching sessions clears the view.
- Computation log polling: the UI must handle mid-poll navigation away and stale IN_PROGRESS entries.

### Integration Points
- **sch_org_academic_sessions_jnt**: Session scoping for the schedule list.
- **msh_marksheet_schedules**, **msh_schedule_class_jnt**: Core schedule data.
- **msh_computation_logs**: Recent activity feed.
- **sys_dropdowns**: Schedule status values.
- **sys_users**: Creator and computation triggerer references.

### Permissions Matrix
| Role | View Dashboard | View Summary Cards | View Recent Logs | Navigate to Schedule |
|---|---|---|---|---|
| Super Admin | Yes | Yes | Yes | Yes |
| School Admin | Yes | Yes | Yes | Yes |
| Principal | Yes | Yes | Yes | Yes |
| Class Teacher | Own class-sections only | Own class-sections only | No | Own class-sections only |
| Subject Teacher | No | No | No | No |
| Student/Parent | No | No | No | No |
