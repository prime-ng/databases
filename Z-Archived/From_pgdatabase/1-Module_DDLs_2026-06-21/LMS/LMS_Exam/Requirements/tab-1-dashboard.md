# LMS Exam Tab 1: Exam Dashboard

This is the first tab the teacher or admin sees when opening the Exam module. It provides a real-time overview of all exams — ongoing, upcoming, and past — along with summary statistics and recent activity, all in one place.

---

## How It Works

When the user opens this tab, they see several summary cards at the top. One card shows the total number of exams created in the current academic session. Another shows how many exams are currently in progress or scheduled to start soon. A third shows completed exams where results are still pending publication. A fourth shows exams whose results have already been published.

Below the summary cards, there is an "Upcoming Exams" list showing the next 5 exams sorted by start date. Each entry displays the exam title, class, exam type, start date, and current status. Next to it, a "Recently Concluded" list shows exams that ended in the last 7 days, highlighting ones still awaiting result publication.

At the bottom, a mini activity feed shows the last 10 status-change events — such as an exam moving from Draft to Published, or a result being published. A filter bar at the top allows the user to filter by academic session, class, and exam type.

---

## Important Business Rules

- The dashboard is read-only — no exam creation or edits can be made here.
- If no exams exist for the selected session, all cards show zero and message "No exams created yet" appears with a button linking to Exam Creation tab.
- Upcoming exams are those with `start_date` >= current date and `status_id` not in CONCLUDED or ARCHIVED.
- "Recently Concluded" shows exams with `end_date` within the last 7 days regardless of publish status.
- Activity feed reads from `lms_exam_status_events` via the audit/logging mechanism.
- All counts are scoped to the selected academic session. If none is selected, defaults to the current active session.
- Teachers see only exams assigned to their classes. Admins and principals see all exams.

---

## Database Columns & Behavior

### lms_exams (used via aggregate and listing queries)
- `id` — Primary key. Used for counting and linking.
- `academic_session_id` — INT FK to glb_academic_sessions.id. Scopes all dashboard data to a session.
- `exam_type_id` — INT FK to lms_exam_types.id. Used for filtering by exam type.
- `class_id` — INT FK to sch_classes.id. Scopes data to user's accessible classes.
- `title` — Displayed as the exam name in lists.
- `start_date` — DATE. Upcoming exams are filtered by this >= current date.
- `end_date` — DATE. Recently concluded filter uses this.
- `status_id` — INT FK to lms_exam_status_events.id. Determines the status badge shown.
- `result_published` — ENUM('IMMEDIATE','SCHEDULED','MANUAL'). Completion logic uses this.
- `is_result_published` — TINYINT(1). When 1, the exam is counted as results-published.
- `is_active` — TINYINT(1). Only active exams are counted.
- `created_at` — TIMESTAMP. Used for activity ordering.

---

## Deep Analysis

### Business Workflows & State Machines

The dashboard is a passive read-only view — it initiates no state transitions. It renders based on exam `status_id` values (DRAFT, PUBLISHED, CONCLUDED, ARCHIVED) and the `is_result_published` flag. The "upcoming" workflow examines `start_date >= CURDATE()` with status not in CONCLUDED/ARCHIVED. The "recently concluded" workflow examines `end_date` within last 7 days. Activity feed polls `lms_exam_status_events` for the last 10 log entries scoped to the user's accessible exams. No state machine operates here; the dashboard is purely a consumer of state from downstream tabs.

### Validation Rules & Edge Cases

- **Empty state:** When no exams exist for the selected session, all cards render zero and a CTA links to Tab 3 (Exam Creation). The session default falls back to the current active session if none is selected.
- **Status edge case:** An exam with `start_date` in the past but status still DRAFT (never published) should still appear in upcoming if it hasn't been concluded or archived.
- **Activity feed gap:** If `lms_exam_status_events` is empty for the user's scope, the feed shows "No recent activity" with no error.
- **Cross-session boundary:** Summary counts must reset to zero when switching sessions; stale results from a previous session must not persist in the UI.
- **Teacher scope:** Teachers see only exams whose `class_id` matches their assigned classes. If a teacher has no class assignments, all cards show zero with no error.

### Integration Points

- **FK references:** `lms_exams.academic_session_id` → `glb_academic_sessions.id`, `exam_type_id` → `lms_exam_types.id`, `class_id` → `sch_classes.id`, `status_id` → `lms_exam_status_events.id`.
- **Module dependencies:** Relies on GLB (academic sessions), SCH (classes), LMS (exam types, status events).
- **Events consumed:** Reads from `lms_exam_status_events` for the activity feed; no events are emitted.
- **No outgoing integration** — this tab does not write or trigger side effects.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View dashboard | Teacher | `lms.exam.dashboard.view` |
| View dashboard | Admin | `lms.exam.dashboard.view` |
| View dashboard | Principal | `lms.exam.dashboard.view.all` |
| Filter by session/class/type | Teacher, Admin, Principal | (inherited from view) |
