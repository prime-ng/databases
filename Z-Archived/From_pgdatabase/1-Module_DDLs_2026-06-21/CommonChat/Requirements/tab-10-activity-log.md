# CommonChat Tab 10: Activity Log & Audit Trail

This screen provides an audit trail of significant events within the chat module. It allows Super Admins and Principals to review moderation actions, message deletions, and system-level changes. This screen is essential for compliance and for investigating disputes about message content or user behavior.

---

## How It Works

The activity log is accessible from the admin area. It displays a chronological list of events related to chat moderation and administration. Each entry shows the date and time of the event, the user who performed the action, the type of action (message deleted by admin, user removed from group, group archived, etc.), and a short description of what happened.

The log is filterable by date range, by the user who performed the action, and by the type of action. Each entry is read-only and cannot be edited or deleted, ensuring a reliable audit trail. The log also tracks message retention purges — when the scheduled job runs to delete messages older than the retention period, a log entry records how many messages were purged and from which conversations.

---

## Important Business Rules

- Only users with the `tenant.chat.moderate` permission (Super Admin, Principal by default) can view the activity log.
- Moderation actions (admin message deletion) are also written to the system-wide `sys_activity_logs` table with a structured JSON payload.
- When an admin deletes a message, the original body is NOT stored in the log. Only a SHA-256 hash of the original body is stored for verification purposes (privacy protection).
- The log captures the following event types: message moderated (admin delete), group created, group archived, group unarchived, member added, member removed, admin transferred, group renamed, and message retention purge.
- Entries in the activity log cannot be deleted or modified by any user, including Super Admin. The log is append-only.
- The message retention auto-purge is a scheduled job (`ChtPurgeOldMessagesJob`) that runs daily. It deletes messages older than the configured `message_retention_days` from `cht_messages`.
- When a message is hard-purged by the retention job, the corresponding receipt and attachment records are cascade-deleted.
- The activity log itself does NOT have automatic retention. It grows indefinitely to maintain the full audit trail.
- Deleted conversations still have their activity log entries preserved. The conversation ID is retained in the log even if the conversation record is hard-deleted.

---

## Database Columns & Behavior

### cht_activity_log (captured via sys_activity_logs integration)
- The module does not have a dedicated `cht_activity_log` table. Moderation and administrative actions are recorded in the system's `sys_activity_logs` table with:
- `subject_type` — Set to 'cht_messages' for message moderation, 'cht_conversations' for group management actions.
- `subject_id` — The ID of the affected message or conversation.
- `action` — Values: 'moderated' (admin message delete), 'group.created', 'group.archived', 'group.unarchived', 'member.added', 'member.removed', 'admin.transferred', 'group.renamed', 'messages.purged'.
- `causer_id` — INT UNSIGNED FK. The admin user who performed the action.
- `properties_json` — JSON payload. For moderation: `{reason: "string", original_body_hash: "sha256hash"}`. For purges: `{messages_deleted: number, conversations_affected: number}`.

### cht_messages (affected by the purge job)
- `id` — BIGINT UNSIGNED PK. Hard-deleted by the retention purge job when older than `message_retention_days`.
- `conversation_id` — BIGINT UNSIGNED FK. Used to count affected conversations during purge.
- `created_at` — TIMESTAMP. The retention job compares this against the configured retention period.
- `is_deleted` — TINYINT(1). Both active and already-soft-deleted messages are subject to hard purge.

### cht_settings
- `id` — TINYINT UNSIGNED PK. Single row per tenant.
- `message_retention_days` — SMALLINT UNSIGNED DEFAULT 0. Controls the hard-delete purge threshold. 0 = disabled (never purge).

### cht_message_receipts & cht_attachments
- Both tables cascade-delete when their parent `cht_messages` record is hard-deleted by the purge job.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Moderation action performed | Admin deletes a message | Log entry created | `sys_activity_logs` row with `action = 'moderated'`, `causer_id = admin.id` |
| Group management action | Admin adds/removes member, archives, renames | Log entry created | `action` set to 'member.added', 'member.removed', 'group.archived', etc. |
| Scheduled purge runs | Daily `ChtPurgeOldMessagesJob` executes | Log entry created | Single log entry with count of purged messages and conversations affected |
| Purge job runs | Retention disabled (0 days) | Job skips; no log entry | No action taken; no log written |
| Any log entry | Created | Append-only; never modified | Immutable; no edit/delete capability for any user |
| Deleted conversation | Conversation hard-deleted | Log entries preserved | `subject_id` retained even if FK target deleted |

- The activity log is read-only by design. There is no UI to edit or delete entries. The log uses the system-wide `sys_activity_logs` table rather than a dedicated module table.
- For moderation actions, the original message body is NOT stored. Only a SHA-256 hash is stored in `properties_json` under `original_body_hash`. This allows verification of content without exposing the actual message text — a privacy protection design decision.
- The `ChtPurgeOldMessagesJob` runs daily. It queries `cht_messages` WHERE `created_at < NOW() - INTERVAL message_retention_days DAY` and issues a hard DELETE. Cascade delete removes associated `cht_message_receipts` and `cht_attachments` rows.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Log modification | Log entries cannot be edited or deleted by any user | "Activity log entries are immutable and cannot be modified." |
| Log access | Only users with `tenant.chat.moderate` permission can view | 403 Forbidden — "You do not have permission to view the activity log." |
| Message body in log | Original body NOT stored; only SHA-256 hash | N/A — intentional privacy protection |
| Deleted conversation retention | Log retains `subject_id` even if conversation hard-deleted | N/A — FK `ON DELETE SET NULL` not used; subject_id preserved |
| Log growth | No automatic retention; log grows indefinitely | N/A — deliberate design for full audit trail |
| Purge job (retention disabled) | `message_retention_days = 0` → skip purge | N/A — scheduled job checks setting before executing |
| Purge job (large batch) | Single log entry for all messages purged in one run | N/A — counts aggregated in `properties_json` |
| FK cascade on purge | `cht_message_receipts` and `cht_attachments` cascade-deleted with parent message | N/A — database-level cascade |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| System | `sys_activity_logs` | `subject_type`, `subject_id` | Polymorphic reference to affected message or conversation |
| System | `sys_activity_logs` | `causer_id` → `sys_users.id` | Admin user who performed the action |
| CommonChat | `cht_messages` | Hard-deleted by purge job | Message retention enforcement |
| CommonChat | `cht_message_receipts` | Cascade delete on `cht_messages` hard-delete | Cleanup of orphaned receipt records |
| CommonChat | `cht_attachments` | Cascade delete on `cht_messages` hard-delete | Cleanup of orphaned attachment metadata |
| CommonChat | `cht_settings` | `message_retention_days` | Controls purge threshold |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View activity log | Super Admin, Principal | `tenant.chat.moderate` |
| Moderate (admin delete message) | Super Admin, Principal | `tenant.chat.moderate` |
| View moderation details | Super Admin, Principal | `tenant.chat.moderate` |
| Run retention purge job | System (scheduled task) | N/A — cron/scheduler; no user-facing permission |
| Archive/unarchive group | Group Admin | `cht_participants.role = 'Admin'` (logged to activity) |
| Remove group member | Group Admin | `cht_participants.role = 'Admin'` (logged to activity) |
| Transfer admin ownership | Group Admin (creator) | Admin role + creator check (logged to activity) |
