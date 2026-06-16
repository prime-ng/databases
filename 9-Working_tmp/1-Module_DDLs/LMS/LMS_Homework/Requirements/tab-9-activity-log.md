# Homework Tab 9: Activity Log

This tab records every significant action that happens within the Homework module. It is an audit trail for accountability and troubleshooting — showing who did what, when, and to which homework.

---

## How It Works

The activity log records actions across the Homework module. Each log entry captures the event type, the homework or submission it was performed on, who performed it, and relevant details.

The following activities are logged:

**Homework Management Actions:** Creating a homework, updating settings, changing status (publish, archive, draft), toggling active/inactive, and deleting or restoring a homework.

**Assignment Actions:** Creating assignment records (on publish), updating due dates, updating assign dates, toggling release status, sending reminders, and overriding late submission policies.

**Submission Actions:** Submitting homework, updating submissions, grading submissions, requesting resubmissions, and rechecking submissions.

**Cloning Actions:** When a homework is cloned to another section, the source homework, target section, and the user who performed the clone are recorded.

---

## Filters and Search

The teacher can filter the activity log by homework, by action type (creation, update, deletion, grading, etc.), by user who performed the action, and by date range.

Filtered logs can be exported for record-keeping.

---

## Important Business Rules

- Log entries are append-only. They cannot be edited or deleted by anyone, including administrators.
- The log retains entries indefinitely. There is no automatic purging.
- Students cannot see the activity log. It is visible only to teachers, school administrators, and system admins.
- If a homework is deleted, the activity log entries for that homework remain. The homework title is preserved in the log entry.
- If a user is deleted from the system, their name in the activity log is replaced with "(Deleted User)."
- The activity log is separate from the student's submission timeline. The activity log covers teacher actions, while the submission timeline covers student actions within a single submission.
- Each log entry includes enough context to understand what happened without cross-referencing other screens. For example, a due date change entry includes the old and new dates and the student's name.

---

## Deep Analysis

### Business Workflows & State Machines

The Activity Log is an append-only audit trail with no state machine. Entries are created but never modified or deleted. The log is partitioned by action category:

| Action Category | Event Types | Actor |
|---|---|---|
| Homework Management | Created, Updated, Published, Archived, Draft reverted, Deleted, Restored, Toggled active/inactive | Teacher |
| Assignment Actions | Created (bulk on publish), Due date changed, Assign date changed, Released, Un-released, Reminder sent, Late override granted | Teacher / System (cron) |
| Submission Actions | Submitted, Updated, Graded, Resubmit requested, Rechecked, Score published | Teacher / Student / System |
| Cloning Actions | Cloned from X to Y | Teacher |

Each log entry is an immutable record: `{ event_type, source_table, source_id, actor_id, old_values, new_values, ip_address, user_agent, created_at }`.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Edit/delete log entry | Not allowed under any circumstance | N/A — append-only |
| Homework deletion — log preservation | Log entries remain after homework is deleted; homework title stored in entry | N/A — data preserved |
| User deletion — log preservation | Actor name replaced with "(Deleted User)" | N/A — graceful degradation |
| Log retention | Indefinite — no automatic purging | N/A |
| Log visibility | Students cannot access log; teachers see their school's logs; admins see all | N/A — row-level security |
| Export | Filtered logs can be exported (format TBD) | N/A |
| Contextual detail | Each entry stores `old_values` and `new_values` as JSON for full context | N/A |
| Cross-reference | Store `homework_id`, `assignment_id`, `submission_id` for linking | N/A |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Homework Core | `lms_homework` | `source_id` (polymorphic) | Log entries reference homework records |
| Assignment Tracking | `lms_homework_assignment` | `source_id` (polymorphic) | Assignment-level events |
| Submission Management | `lms_homework_submissions` | `source_id` (polymorphic) | Submission-level events |
| Users | `sys_users` | `actor_id` | Actor identity (or "(Deleted User)" fallback) |
| LMS Core | (polymorphic logger) | Shared `activity_log` table or module-specific log table | Centralized audit infrastructure |

The activity log may be implemented as a dedicated `lms_homework_activity_log` table or piggyback on a system-wide `activity_log` with a `module = 'lms_homework'` discriminator.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View activity log | Teacher | `lms.homework.activity_log.view` |
| View activity log (all schools) | Admin | `lms.homework.activity_log.view_all` |
| Export activity log | Teacher, Admin | `lms.homework.activity_log.export` |
| View log entries for own actions | Teacher | (implicit — own entries) |
| View log entries for school | Teacher | (implicit — school-scoped) |
