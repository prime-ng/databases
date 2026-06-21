# Quest Tab 10: Activity Log

This tab records every significant action that happens within the Quest module. It is an audit trail for accountability and troubleshooting — showing who did what, when, and to which quest.

---

## How It Works

When the teacher opens this tab, they see a list of log entries sorted with the most recent first. Each entry shows the date and time of the action, the user who performed it (with their role), the quest it was performed on, the type of action taken, and any additional details.

The following activities are logged:

**Quest Management Actions:** Creating a quest, updating quest settings, changing the quest status (publish, cancel, archive), and deleting a quest. Each entry shows which fields were changed in the update.

**Question Actions:** Adding questions to a quest, removing questions, changing marks overrides, and reorganizing question order within a scope type.

**Scope Actions:** Creating, updating, renaming, reordering, activating, deactivating, and deleting scope types.

**Allocation Actions:** Allocating students to a quest, removing students from allocation, and bulk allocation by class.

**Answer Actions:** Submitting a quest attempt, auto-submission due to time expiry, and manual evaluation of subjective questions.

**Score Actions:** Score overrides with the original and new scores and the reason provided.

---

## Filters and Search

The teacher can filter the activity log by quest (select from a dropdown), by action type (creation, update, deletion, allocation, scoring), by user who performed the action, and by date range. They can also search for specific keywords in the details field.

The filtered log can be exported to Excel or PDF for record-keeping.

---

## Important Business Rules

- Log entries are append-only and cannot be edited or deleted by anyone, including administrators. They are a permanent record.
- The log retains entries indefinitely. There is no automatic purging of old entries. If storage becomes a concern, the system administrator can archive logs older than one year to a separate storage.
- Students cannot see the activity log. It is visible only to teachers, school administrators, and system admins.
- The detail field provides enough context to understand what happened without needing to cross-reference with other tabs. For example, a scope update entry includes the old and new name, and a score override entry includes the original and revised scores.
- If a quest is deleted, the activity log entries for that quest remain. The quest name is replaced with "(Deleted Quest)" to indicate the quest no longer exists.
- If a user is deleted from the system, their name in the activity log is replaced with "(Deleted User)."
- The activity log is separate from the student attempt timeline shown in Student Result Details. The activity log covers teacher actions across all quests, while the timeline covers a single student's actions within a single quest.
- Applying filters does not delete or modify any log entries. It only changes what is displayed on screen.
- The export includes a date range filter label at the top of the file, so readers know which period the exported data covers.
- Log entries are timestamped to the second using the school's configured timezone.

---

## Deep Analysis

### Business Workflows & State Machines

**Log Recording Flow:**
```
User Action Occurs
         │
         ▼
System creates log entry:
  - user_id (who did it)
  - action_type (what was done)
  - resource_type + resource_id (quest, question, allocation, etc.)
  - details (JSON with before/after values)
  - timestamp
         │
         ▼
Log entry stored (append-only, immutable)
```

**Action Categories Logged:**

| Category | Logged Actions |
|----------|----------------|
| Quest Management | Create, update settings, publish, cancel, archive, delete |
| Question Actions | Add, remove, change marks override, reorder, move scope |
| Scope Actions | Create, rename, reorder, activate, deactivate, delete |
| Allocation Actions | Allocate student, bulk allocate, remove allocation |
| Attempt Actions | Submit (manual), auto-submit (time expiry) |
| Evaluation Actions | Evaluate question, re-evaluate, score override |
| Score Actions | Override score with reason |

**Retention Policy:**
- Logs are kept indefinitely by default.
- System administrators can archive logs older than 1 year to cold storage.
- Archived logs are not visible in the UI but can be restored for audit purposes.

### Validation Rules & Edge Cases

| Scenario | Handling |
|----------|----------|
| Deleted quest referenced | Quest name replaced with "(Deleted Quest)" |
| Deleted user referenced | User name replaced with "(Deleted User)" |
| Extremely large log | Pagination applied. Filters available for narrowing |
| Admin edits log | Blocked — logs are append-only and immutable |
| Log export | Includes date range label, exported data matches visible filters |

**Edge Cases:**
- If a quest is deleted, all its log entries remain. The `resource_id` still points to the deleted record.
- If a user is deleted, their `user_id` in the log still exists (referential integrity via `ON DELETE SET NULL` or preserved).
- The details field stores a JSON payload with sufficient context for independent understanding:
  ```
  {"field": "status", "old": "DRAFT", "new": "PUBLISHED"}
  {"field": "marks_override", "old": null, "new": 5.0, "question_id": 42}
  ```
- Filtering by action type uses a fixed enum to prevent typos and injection.

### Integration Points

| Module | Tables | Purpose |
|--------|--------|---------|
| Activity Log (self) | Activity log table | Stores all entries |
| User | `sys_users` | User identity |
| Quest (self) | `lms_quests` | Quest reference (may be soft-deleted) |

**Events to consider:**
- No events are triggered from the activity log. It is a passive consumer of actions that occur in other tabs.

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View activity log | Teacher (own quests), Admin | `tenant.lms.quest.activity.view` |
| View all activity | Admin only | `tenant.lms.quest.activity.viewAny` |
| Export activity log | Teacher, Admin | `tenant.lms.quest.activity.export` |
| Archive old logs | System Admin only | `tenant.lms.quest.activity.archive` |

- Students have no access to the activity log.
- Teachers see logs only for quests they created or that are in their classes.
- Admin sees all logs across all quests and all users.
