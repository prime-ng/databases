# LMS Exam Tab 10: Activity Log

This tab provides a complete audit trail of all status transitions and significant events that occur during the exam lifecycle. It is a read-only log that helps administrators and teachers track who did what and when, across all exams, papers, and results.

---

## How It Works

The screen shows a filterable, paginated table of log entries. Each entry records the event code (e.g., DRAFT→PUBLISHED), the event type (Exam, Paper, Result, or Attempt), the entity affected (exam title, paper name, or student name), the user who performed the action, and a timestamp.

The user can filter logs by date range, event type, exam, or user. A search bar allows searching by entity name or event code.

Each log entry can be expanded to show additional metadata stored as JSON — such as the previous and new values of key fields, IP address, user agent, and any system-generated notes.

The log is immutable. No entries can be edited or deleted. It serves as a compliance and debugging tool.

---

## Important Business Rules

- The activity log is read-only. No user can edit, delete, or clear log entries.
- All status transitions for exams, papers, results, and attempts are automatically logged when the status changes.
- Key events logged include: exam created, exam published, paper evaluated, result computed, result published, result reopened, student attempt started, student attempt submitted, and marks overridden.
- The `action_logic` JSON field in the `lms_exam_status_events` table stores the business logic configuration for each event type, which determines what side effects occur during the transition.
- Logs are retained for the lifetime of the school's data in the system. There is no automatic purging.
- Bulk operations (e.g., publish all papers) generate individual log entries for each entity affected.
- The log can be exported to CSV or Excel for external audit purposes.
- System-level events (scheduled result publishing, auto-evaluation) are logged with user_id set to NULL or a system user.

---

## Database Columns & Behavior

### lms_exam_status_events
- `id` — INT UNSIGNED PK. Referenced by logs and entity status fields.
- `code` — VARCHAR(50), unique. Event code e.g., 'DRAFT', 'PUBLISHED', 'CONCLUDED', 'ARCHIVED', 'EVALUATED'.
- `name` — VARCHAR(100). Human-readable event name.
- `description` — VARCHAR(255), nullable. Explanation of what this status means.
- `event_type` — ENUM('EXAM','PAPER','RESULT','ATTEMPT'). Categorizes which entity type this status applies to.
- `action_logic` — JSON. Stores the business logic configuration for side effects during the transition.
- `is_active` — TINYINT(1), default 1.

### lms_exams (status tracking)
- `status_id` — INT UNSIGNED FK to lms_exam_status_events.id. Current status of the exam. Changes here trigger a log entry.

### lms_exam_papers (status tracking)
- `status_id` — INT UNSIGNED FK to lms_exam_status_events.id. Current status of the paper. Changes here trigger a log entry.

---

## Deep Analysis

### Business Workflows & State Machines

The activity log is a passive, immutable audit trail — it does not drive or participate in any state machine. It is the recording mechanism for all state transitions across three entity types:

```
EXAM:   DRAFT ──► PUBLISHED ──► CONCLUDED ──► ARCHIVED
PAPER:  NOT_STARTED ──► IN_PROGRESS ──► ... ──► EVALUATED ──► RESULT_PUBLISHED
RESULT: NOT_STARTED ──► COMPUTED ──► PUBLISHED ──► REOPENED
ATTEMPT: NOT_STARTED ──► IN_PROGRESS ──► SUBMITTED ──► ... ──► EVALUATED
```

Each transition creates one log entry in the `lms_exam_status_events` table (or a dedicated audit table). The `event_type` column categorizes the entity (EXAM/PAPER/RESULT/ATTEMPT), and the `action_logic` JSON column stores side-effect configuration that was executed during the transition. The log is write-only — no user can edit, delete, or clear entries.

### Validation Rules & Edge Cases

- **Immutability:** No UPDATE, DELETE, or TRUNCATE operations are permitted on log entries. The database user for the application should have INSERT and SELECT only on the audit table.
- **Bulk operation logging:** When a bulk action (e.g., "Publish All Papers") triggers multiple status changes, each affected entity generates an individual log entry with the same `user_id` and `created_at` timestamp for correlation.
- **System-level events:** Actions performed by cron jobs or auto-evaluators log with `user_id = NULL` (or a dedicated system user ID). The UI should display these as "System" in the user column.
- **JSON metadata schema:** The `action_logic` JSON should follow a consistent schema for all entries: `{"previous_status": "...", "new_status": "...", "ip_address": "...", "user_agent": "...", "notes": "..."}`. If the JSON is malformed for an entry, the UI should render it as raw text rather than throwing an error.
- **Filter edge cases:** Filtering by date range with no results shows "No activity found for the selected filters." Filtering by event type that has no entries for the selected scope should not error.
- **Export limits:** CSV/Excel exports should have a configurable row limit (default 10,000 rows) to prevent memory exhaustion. Files should be generated asynchronously for large datasets.
- **Retention:** No automatic purging. Logs are retained for the lifetime of the school's data. If retention policies are needed, they must be implemented as a separate archival job.

### Integration Points

- **FKs:** `lms_exam_status_events.id` — referenced by `lms_exams.status_id`, `lms_exam_papers.status_id` (and potentially `lms_exam_results.status_id` for future result tables).
- **Module dependencies:** LMS (exams, papers, results/attempts tables), SYS (users for audit attribution).
- **Events consumed:** All status transition events across the LMS Exam module are written here. No events are emitted by this tab — it is a pure consumer/recorder.
- **Potential integration:** External audit/compliance tools could consume log exports via API.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View activity log | Admin, Principal | `lms.exam.audit.view` |
| Filter/search logs | Admin, Principal | `lms.exam.audit.search` |
| Expand log entry details | Admin, Principal | `lms.exam.audit.details` |
| Export logs (CSV/Excel) | Admin | `lms.exam.audit.export` |
| View system-level events | Admin | `lms.exam.audit.view.system` |
| Delete/clear logs | (None) | Not permitted for any role |
