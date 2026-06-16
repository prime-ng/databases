# Syllabus Tab 1: Syllabus Dashboard

This is the first tab the user sees when opening the Syllabus module. It provides a bird's-eye view of syllabus creation progress across all classes and subjects, along with recent changes and coverage statistics.

---

## How It Works

When the user opens this tab, they see a set of summary cards at the top. One card shows the total number of lessons created across all active class-subject combinations. Another shows total topics broken down across all hierarchy levels. A third card displays syllabus coverage as a percentage — how many lessons have been fully mapped with topics. A fourth shows the number of classes and subjects that have a complete syllabus defined.

Below the summary cards, a coverage matrix table lists each class vertically and each subject horizontally. Each cell shows how many lessons have been defined for that class-subject pair, along with a color-coded completeness indicator. Green means all lessons have topics mapped, yellow means partially complete, and red means no syllabus exists yet.

The bottom section shows the most recent activity — a chronological feed of the last 10 syllabus changes including lessons added, topics modified, and competencies mapped. Each entry shows what changed, who made the change, and when.

The user can filter the dashboard by academic session. When the session changes, all data reflects only that session's syllabus.

---

## Important Business Rules

- The dashboard is read-only. No create, edit, or delete actions are available here.
- Syllabus coverage percentage is calculated as: (lessons with at least one topic / total lessons) × 100.
- If no syllabus data exists for the selected session, all cards show zero and charts display an empty state with a message to start creating lessons.
- Only active records (is_active = 1) are counted in all dashboard metrics.
- The activity feed shows changes from the last 30 days only. Older changes are accessible via the Activity Log tab.
- Coverage data is computed live. For schools with very large curricula, a loading indicator appears while data is being fetched.
- Data is scoped to the logged-in user's school. Multi-tenant isolation is enforced.

---

## Database Columns & Behavior

### slb_lessons (used for lesson counts)
- `id` — Primary key. Counted for total lessons.
- `academic_session_id` — Filters to the selected session. INT UNSIGNED FK to sch_org_academic_sessions_jnt.
- `class_id` — Groups lessons by class. INT UNSIGNED FK to sch_classes.
- `subject_id` — Groups lessons by subject. INT UNSIGNED FK to sch_subjects.
- `is_active` — Only active lessons are counted. TINYINT(1), default 1.

### slb_topics (used for topic counts)
- `id` — Primary key. Counted for total topics.
- `lesson_id` — Joins to lessons for filtering. INT UNSIGNED FK to slb_lessons.
- `level_id` — Determines hierarchy depth for analysis. INT UNSIGNED FK to slb_topic_level_types.
- `is_active` — Only active topics are counted. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Read-only dashboard** — no state machine; data is fetched on mount and refreshed on session change.
- **Session scoping trigger** — switching academic session fires a re-fetch of all 4 summary cards, the coverage matrix, and the activity feed.
- **Coverage computation** — live query aggregates `COUNT(DISTINCT lessons.id)` and `COUNT(DISTINCT topics.lesson_id)` grouped by class-subject; no persisted snapshot.
- **Activity feed** — polls last 30 days of audit log from `slb_lessons` / `slb_topics` event triggers; no user action modifies state here.

### Validation Rules & Edge Cases
- **Empty state** — if no lessons exist for the session, all 4 cards = 0, the matrix is empty, show "Start creating lessons" prompt.
- **Large data** — schools with 500+ class-subject combos show a loading spinner; coverage query must be paginated or cached.
- **Multi-tenant filter** — all queries include `WHERE school_id = ?` (or equivalent tenant scope); cross-tenant leakage is prevented.
- **Color-coding** — green = `coverage = 100%`, yellow = `0 < coverage < 100%`, red = `coverage = 0`; edge case when lessons exist but no topics are mapped → red.
- **Last-30-day window** — if there is no activity in the last 30 days, the feed shows "No recent changes."

### Integration Points
- `sch_classes` — class listing for matrix rows and session filter.
- `sch_subjects` — subject listing for matrix columns.
- `slb_lessons` — lesson count and coverage denominator.
- `slb_topics` — topic count and coverage numerator.
- `sch_org_academic_sessions_jnt` — session filter dropdown.
- **Multi-tenant** — `school_id` column on all referenced tables for tenant isolation.

### Permissions Matrix
| Role | View Dashboard | Filter Session | View Activity Feed |
|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ✅ | ✅ | ✅ |
| Teacher | ✅ | ✅ | ✅ |
| Student/Parent | ❌ | ❌ | ❌ |
