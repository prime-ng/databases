# Activity Log — Business Requirements

## What This Screen Does

The Activity Log screen shows a record of events that happen while a student is taking a quiz. Think of it as a security camera recording — it captures things like: did the student switch browser tabs? Did they leave the fullscreen mode? Did they try to copy-paste content?

This log is used by teachers to:
- Check for suspicious behavior during online assessments
- Investigate if a student's score seems unusual
- Understand if technical issues (browser problems, network drops) affected an attempt
- Maintain a verifiable record for academic integrity

The log entries are created automatically by the Student Portal while the student is taking the quiz. Teachers and administrators can only VIEW the log — nothing can be edited or deleted.

---

## When This Screen Is Used

- **Post-Exam Review** — Teachers check for suspicious behavior after submissions
- **Academic Integrity Investigations** — When a student's score is questioned
- **Technical Support** — Determine if browser/network issues affected an attempt
- **Audit Compliance** — Maintain verifiable records

## Default Data Load

This screen is the "Activity Log" tab within Quiz Management (`active_tab=activity_log`). It loads a paginated list (15 entries per page) of log entries scoped to `attempt_type = 'QUIZ'`, sorted by `occurred_at` descending (most recent first).

**Filters available:**
- **Event Type** — Dropdown from `lms_attempt_activity_event_types` (e.g., TAB_SWITCH, FOCUS_LOST)
- **Date From / Date To** — Range filter on `occurred_at` timestamp

The event types dropdown is loaded from `AttemptActivityEventType::active()->get()`.

---

## Key Fields at a Glance

### Log Entry Table (`lms_attempt_activity_logs`)
| Field | Type | Details |
|-------|------|---------|
| `id` | bigint, PK | Auto-increment |
| `attempt_id` | bigint | Polymorphic — ID in attempt table |
| `attempt_type` | varchar | Enum: QUIZ, QUEST, EXAM — discriminates which table attempt_id references |
| `event_type_id` | FK → `lms_attempt_activity_event_types` | What happened (FOCUS_LOST, TAB_SWITCH, etc.) |
| `event_data` | longtext, nullable | JSON blob — extra context (IP, key codes, screen coords, etc.) |
| `occurred_at` | datetime | When the event happened |
| `created_at` | timestamp | When the log was recorded |

**Note:** There is NO `deleted_at` and NO `created_by` — these are immutable system records.

### Event Types Table (`lms_attempt_activity_event_types`)
| Field | Details |
|-------|---------|
| `code` | Unique ID like `FOCUS_LOST`, `TAB_SWITCH`, `BROWSER_RESIZE` |
| `name` | Display name |
| `description` | Optional explanation |
| `is_active` | Toggle to enable/disable tracking |

---

## How the Screen Works (Plain Language)

When a teacher opens the Activity Log tab, the system runs through a simple flow. There's nothing to save or edit — it's purely a read-only log viewer.

**Step 1 — Load the Log Entries**
The system fetches activity log entries from the database, but only ones related to QUIZ attempts (not quest or exam attempts). Each entry is loaded along with its event type name (like "Tab Switch" or "Focus Lost") so the teacher sees readable labels, not numbers.

**Step 2 — Apply Filters (if any)**
If the teacher has selected filter options, the system narrows down the results:

- **Filter by Event Type** — Teacher picks "TAB_SWITCH" from the dropdown. System shows only entries where the event type is TAB_SWITCH. All other events are hidden.
- **Filter by Date Range** — Teacher enters a "From" date AND a "To" date. System shows only entries that happened between those two dates (inclusive of the full day on both ends).
  - **Important:** Both dates must be filled. If the teacher fills only one date, the date filter is ignored entirely.

**Step 3 — Sort and Display**
All entries are shown most-recent-first. The system paginates at 15 entries per page using a separate page counter (`log_page`) so it doesn't interfere with other tabs that might be open.

**Step 4 — Load the Event Type Dropdown**
Separately, the system loads the list of active event types to populate the filter dropdown. This list is fetched from the event types master table.

**What the Teacher Sees:**
- A table with columns: Event Type (name), Occurred At (date/time), and a "View" button for details
- A filter bar at the top with: Event Type dropdown, Date From field, Date To field, Filter button, Reset button
- Pagination controls at the bottom (15 per page)

**What Happens When Filters Change:**
1. Teacher selects "TAB_SWITCH" → page reloads with only TAB_SWITCH events
2. Teacher adds a date range → page reloads with only TAB_SWITCH events within that date range
3. Teacher clicks "Reset" → page reloads with all events, no filters

---

## Business Rules Summary

| # | Rule | Details |
|---|------|---------|
| 1 | Immutable records | No deletes, no updates, no created_by — system-generated only |
| 2 | Polymorphic attempt_id | Same column references QUIZ, QUEST, or EXAM attempts depending on attempt_type |
| 3 | Always scoped to QUIZ | `WHERE attempt_type = 'QUIZ'` — quest and exam logs not shown |
| 4 | Event type from master table | `event_type_id` FK to `lms_attempt_activity_event_types` |
| 5 | Date filter requires BOTH date_from AND date_to | Partial date filter silently ignored |
| 6 | Pagination | 15 per page, separate paginator `log_page` |
| 7 | Ordering | Most recent first (`latest('occurred_at')`) |
| 8 | No data entry | Read-only screen — logs created by StudentPortal during attempts |

---

## Workflow Steps (Non-Technical)

1. Navigate to Quiz Management → "Activity Log" tab
2. System shows the most recent 15 log entries (all event types, all dates)
3. Each row shows: event type name (e.g., "Tab Switch"), when it happened, and which attempt
4. Optionally filter:
   - Select "Event Type" from dropdown (e.g., "Focus Lost")
   - Set "Date From" and "Date To"
   - Click "Filter" → list updates
5. Click "Reset" to clear all filters
6. Click "View" on any log entry to see full event data (JSON payload)

---

## Example Scenarios (Non-Technical)

**SC-001 — Suspicious Behavior Review (Non-Technical)**
After a quiz, Ravi notices Student "Arjun" scored 95% — much higher than his usual 60%. Ravi opens Activity Log and filters by Arjun's attempt. The log shows:
- 3 TAB_SWITCH events — Arjun switched browser tabs 3 times
- 2 COPY_PASTE events — Arjun tried to copy/paste content
- 1 FULLSCREEN_EXIT — Arjun exited fullscreen mode
Ravi decides to investigate further and schedules a conversation with Arjun.

**SC-002 — Technical Issue Investigation (Non-Technical)**
Student Priya reports her quiz submitted unexpectedly. Teacher checks the Activity Log for her attempt and sees:
- Multiple FOCUS_LOST events around the submission time
- Several BROWSER_RESIZE events
- A TAB_SWITCH event that coincides with the submission timestamp
Teacher determines Priya's browser likely crashed and allows a retake.

**SC-003 — Filter by Event Type (Non-Technical)**
Teacher selects "TAB_SWITCH" from the filter dropdown and clicks Filter. System shows only TAB_SWITCH events across all QUIZ attempts. Teacher can see which students switched tabs most frequently.

**SC-004 — Filter by Date Range (Non-Technical)**
Teacher sets date range to last 7 days. System shows only events from the past week. Useful for weekly integrity audits.

---



## Requirements

**Controller:** `Modules\LmsQuiz\Http\Controllers\LmsQuizController@index()` (activity_log tab logic)
**Models (in StudentPortal):**
- `AttemptActivityLog` (table: `lms_attempt_activity_logs`) — append-only, no soft deletes
- `AttemptActivityEventType` (table: `lms_attempt_activity_event_types`) — event type master

**View:** `lmsquiz::activity_log.index`
**Policy:** `tenant.quiz-activity-log.view`

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `lms_attempt_activity_logs` | Primary | Append-only event log (StudentPortal module) |
| `lms_attempt_activity_event_types` | FK/Reference | Event type master (StudentPortal module) |
| `lms_quiz_quest_attempts` | Polymorphic reference | attempt_id reference (assessment_type=QUIZ) |
| **StudentPortal** | External module | Both tables live in StudentPortal |

**Important:** These tables are created by the StudentPortal migration `2026_06_16_112813_create_lms_attempt_activity_event_types_table.php`. Run `php artisan tenants:migrate` if this migration hasn't been applied.
