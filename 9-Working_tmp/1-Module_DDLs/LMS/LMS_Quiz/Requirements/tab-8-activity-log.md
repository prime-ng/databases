# Quiz Tab 8: Activity Log

This tab shows a timeline of everything that happened during quiz sessions — when students started, when they submitted, when they switched tabs, and more. It is useful for investigating issues or keeping an eye on student behavior.

---

## How It Works

The activity log is a list of events in chronological order, newest first. Each entry shows the timestamp, the student's name, which quiz they were on, what type of event occurred, and details about the event.

Events are recorded automatically for many student actions: starting a quiz, answering a question, changing an answer, submitting the quiz, switching to another browser tab, exiting fullscreen mode, pausing or resuming the quiz, and even losing and regaining internet connection. Each event gets its own entry in the log.

The teacher can filter the log to show only events for a specific student, a specific quiz, or a specific type of event — for example, show only tab switch events. They can also filter by date range.

---

## How Teachers Use This

The activity log is primarily used for two things. First, investigating student complaints — if a student says "the quiz submitted before I was done" or "my internet disconnected," the teacher can look at the log to see exactly what happened. Second, monitoring suspicious behavior — if a student switched tabs many times or submitted suspiciously fast, the log provides the evidence.

The log is not used for automatic enforcement. Even if a student switched tabs 20 times, their quiz is not invalidated automatically. The teacher reviews the log and decides whether to take action.

---

## Important Business Rules

- Activity logs are permanent. They cannot be edited or deleted by teachers. They are immutable records.
- If a quiz is deleted, the activity log entries for that quiz remain. The quiz name is replaced with "(Deleted Quiz)." If a student is deleted from the system, their name is replaced with "(Deleted User)."
- The log can get very large for schools with many students. Filters help narrow down the results. There is no auto-deletion — logs pile up indefinitely.
- The following events are always logged: quiz started, quiz submitted, auto-submission due to time expiry, tab switch, fullscreen exit, pause, resume, and connection lost/restored.
- Answer-level events (answering a question, changing an answer) are logged but can be filtered out to reduce noise. The default view shows only the major events.
- The log is append-only. No one, including administrators, can delete or modify any entry. This ensures the log is admissible as evidence in academic integrity investigations.
- If proctoring was not enabled for the quiz, tab switch and fullscreen events are not recorded. Only start, submit, pause, resume, and timer events are logged.
- The teacher cannot export the activity log directly from this tab. For record-keeping, they can use the browser's print function or take screenshots.

---

## Deep Analysis

### Business Workflows & State Machines

**Activity Log Event Types:**

| Event Category | Event Type | Always Logged? | Proctoring Required? |
|---|---|---|---|
| Session | QUIZ_STARTED | Yes | No |
| Session | QUIZ_SUBMITTED | Yes | No |
| Session | AUTO_SUBMIT_TIMEOUT | Yes | No |
| Session | QUIZ_PAUSED | Yes | No |
| Session | QUIZ_RESUMED | Yes | No |
| Proctoring | TAB_SWITCH | No | Yes |
| Proctoring | FULLSCREEN_EXIT | No | Yes |
| Connectivity | CONNECTION_LOST | Yes | No |
| Connectivity | CONNECTION_RESTORED | Yes | No |
| Answer | QUESTION_ANSWERED | Yes (filterable) | No |
| Answer | ANSWER_CHANGED | Yes (filterable) | No |

**Activity Log Workflow:**
1. Student performs an action during quiz attempt.
2. Client-side or server-side event handler fires.
3. Event is recorded with: timestamp, student ID, quiz ID, attempt ID, event type, metadata (JSON blob).
4. Event is persisted to the activity log table (append-only).
5. Teacher opens Tab 8, loads log entries (newest first).
6. Teacher applies filters: student, quiz, event type, date range.
7. System queries log table with filters, returns paginated results.
8. Teacher reviews entries — no action can be taken on individual entries.

**Data Retention:**
- Logs are never auto-deleted.
- Log entries survive quiz deletion (quiz name replaced with "(Deleted Quiz)").
- Log entries survive student deletion (student name replaced with "(Deleted User)").
- No cascading deletes affect the log table.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|---|---|---|
| Log Entry – Creation | Append-only; no editing/deleting | Not applicable (system-only operation) |
| Quiz Deleted | Log entries preserved; quiz name → "(Deleted Quiz)" | No error — automatic |
| Student Deleted | Log entries preserved; student name → "(Deleted User)" | No error — automatic |
| Proctoring Disabled | Tab switch and fullscreen events not recorded | No events generated for these types |
| Large Log Volume | No auto-deletion; filters required for performance | Warning: "Refine your filters for faster results" (if applicable) |
| Filter – No Results | Empty list | "No activity found for the selected filters." |
| Filter – Date Range | Invalid range (start > end) | "Start date must be before end date." |
| Filter – Student | Must be valid student ID | "Student not found." |
| Filter – Quiz | Must be valid quiz ID | "Quiz not found." |
| Default View | Major events only (answer events filtered out) | No error |
| Export | Not available | "Activity log cannot be exported. Use browser print or screenshots." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|---|---|---|---|
| Quiz Core | `lms_quizzes` | (via log table's `quiz_id`) | Identify quiz; display quiz title or "(Deleted Quiz)" |
| Quiz Attempts | `lms_quiz_attempts` (or similar) | (via log table's `attempt_id`) | Link events to specific attempts |
| Students | `std_students` | (via log table's `student_id`) | Display student name or "(Deleted User)" |
| Proctoring | Quiz settings (`lms_quizzes`) | — | Determines whether proctoring events are recorded |
| Activity Log Table | (separate log/monitoring table, not in DDL above) | — | Stores all event entries; append-only, no cascading deletes |

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| View Activity Log | Teacher | `quiz.activity-log.view` |
| Filter by Student | Teacher | `quiz.activity-log.filter-student` |
| Filter by Quiz | Teacher | `quiz.activity-log.filter-quiz` |
| Filter by Event Type | Teacher | `quiz.activity-log.filter-event` |
| Filter by Date Range | Teacher | `quiz.activity-log.filter-date` |
| View All Logs | Admin | `quiz.activity-log.view.all` |
| Edit/Delete Log Entry | No one | Not permitted (immutable) |

---

## Database Columns & Behavior

### Activity Log Table (conceptual — not in DDL, but referenced by this tab)

The activity log is stored in a separate auditing/monitoring table. While not present in the provided DDL, the logical schema based on requirements is:

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key |
| `quiz_id` | INT UNSIGNED | Yes → `lms_quizzes.id` (no cascade) | No | — | FK to quiz; preserved even if quiz deleted |
| `attempt_id` | INT UNSIGNED | Yes → `lms_quiz_attempts.id` (no cascade) | Yes | NULL | FK to attempt; may be NULL for non-attempt events |
| `student_id` | INT UNSIGNED | Yes → `std_students.id` (no cascade) | Yes | NULL | FK to student; preserved even if student deleted |
| `event_type` | VARCHAR(50) | No | No | — | Event type code (e.g. QUIZ_STARTED, TAB_SWITCH) |
| `event_data` | JSON/TEXT | No | Yes | NULL | Metadata blob with event-specific details |
| `ip_address` | VARCHAR(45) | No | Yes | NULL | Student's IP at time of event |
| `user_agent` | TEXT | No | Yes | NULL | Browser user agent string |
| `created_at` | TIMESTAMP | No | No | CURRENT_TIMESTAMP | Record creation time (immutable) |

### Table: `lms_quizzes` (relevant columns only)

| Column | Type | FK | Nullable | Default | Behavior |
|---|---|---|---|---|---|
| `id` | INT UNSIGNED | No | No | AUTO_INCREMENT | Primary key, referenced by activity log |
| `title` | VARCHAR(100) | No | No | — | Displayed in log; replaced with "(Deleted Quiz)" after deletion |
| `is_active` | TINYINT(1) | No | No | 1 | Soft-delete flag |
