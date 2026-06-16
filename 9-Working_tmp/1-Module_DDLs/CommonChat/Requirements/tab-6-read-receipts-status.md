# CommonChat Tab 6: Read Receipts & Message Status

This screen displays delivery and read status information for sent messages. The sender can see whether each recipient has received and read their message, along with the timestamp of when it was read. This feature helps users know when their message has been seen.

---

## How It Works

When a user sends a message, the system immediately creates one receipt record for every non-sender participant in the conversation. For direct messages, this is a single receipt for the other participant. For group conversations, a receipt is created for all other members. Each receipt starts with a NULL `read_at`, meaning the message has been delivered but not yet read.

When a recipient opens the conversation, the system calls a mark-read endpoint that sets `read_at` to the current timestamp for all unread messages in that conversation. The UI then updates to reflect the read status. In a direct message, the sender sees a "Seen at 10:42 AM" label below the message. In a group conversation, the sender sees a summary like "Read by 4 of 6 members". The sender can also tap or hover on the read status to see the list of individual recipients who have read the message.

---

## Important Business Rules

- A `cht_message_receipts` row is created for each non-sender participant at the time the message is sent, even if the message is never read.
- `read_at` is set to NULL initially and updated to the current timestamp only when the recipient performs a mark-read action (by opening or interacting with the conversation).
- In a direct message, the sender sees "Seen at {time}" once the single recipient reads the message.
- In a group conversation, the sender sees "Read by X of Y members". Clicking shows individual names and read times.
- A message is considered fully read when all non-sender participants have a non-NULL `read_at`.
- Read receipts are still tracked in the database even if the school or user has disabled displaying them in the UI.
- Individual users can disable showing their own read receipts via `cht_personalization_settings.show_read_receipt_enabled`. When disabled, their read actions are still tracked but not shown to senders.
- The school can globally disable read receipt display in the UI via `cht_settings.default_read_receipt_enabled`.
- Muted conversations still track read receipts. Muting only suppresses notifications, not read tracking.
- The `cht_participants.unread_count` is reset to 0 when the mark-read endpoint is called for that conversation.

---

## Database Columns & Behavior

### cht_message_receipts
- `id` — BIGINT UNSIGNED PK. Receipt record identifier.
- `message_id` — BIGINT UNSIGNED FK. The message this receipt tracks.
- `user_id` — INT UNSIGNED FK. The recipient user. One row per non-sender participant per message.
- `read_at` — TIMESTAMP NULL. NULL when delivered but not read. TIMESTAMP when the recipient first opened the conversation and fetched messages.
- `created_at` — TIMESTAMP. When the receipt record was created (same time as the message was sent).
- `updated_at` — TIMESTAMP. Updated when `read_at` is set.

### cht_participants
- `id` — BIGINT UNSIGNED PK. Participant identifier.
- `conversation_id` — BIGINT UNSIGNED FK. The conversation.
- `user_id` — INT UNSIGNED FK. The user.
- `unread_count` — INT UNSIGNED. Denormalised counter. Decremented to 0 when the user calls mark-read. Incremented by 1 for each new message in non-muted conversations.
- `muted_until` — TIMESTAMP NULL. Muted conversations still track receipts but do not increment `unread_count`.

### cht_personalization_settings
- `id` — INT UNSIGNED PK. Setting record identifier.
- `user_id` — INT UNSIGNED FK. One-to-one with sys_users.
- `show_read_receipt_enabled` — TINYINT(1). When 1, the UI shows read receipts. When 0, receipts are tracked in the DB but not displayed. When disabled, the user also cannot see others' read status.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Message sent | System creates receipt rows | Sent (delivered, not read) | One `cht_message_receipts` row per non-sender participant; `read_at = NULL` |
| Delivered (not read) | Recipient opens conversation | Read (mark-read endpoint called) | `read_at` set to current TIMESTAMP; `cht_participants.unread_count` reset to 0 |
| Read (DM) | Single recipient reads | "Seen at {time}" shown to sender | UI label below the message |
| Read (Group) | X of Y recipients read | "Read by X of Y members" shown | Sender can hover/tap for individual list |
| All recipients read | Last non-sender reads | Fully read | No further UI state changes |
| Any state | User disables read receipt display | UI hides read status | Receipts still tracked in DB; `show_read_receipt_enabled = 0` |
| Any state | School disables read receipts globally | UI hides read status for all users | `cht_settings.default_read_receipt_enabled = 0` |

- The mark-read endpoint is called whenever the user opens a conversation or sends a message. It runs a single UPDATE query: `UPDATE cht_message_receipts SET read_at = NOW() WHERE user_id = ? AND read_at IS NULL AND message_id IN (SELECT id FROM cht_messages WHERE conversation_id = ?)`.
- In groups, the sender sees a summary line. Expanding it fetches individual recipient read times via a JOIN on `cht_message_receipts` with `sys_users`.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Receipt creation | Row created for every non-sender participant at send time | N/A — system action; no error surface |
| Muted conversation | Muted conversations still track receipts but do not increment `unread_count` | N/A — silent behaviour |
| Per-user toggle off | User disables display → their read status hidden from others | N/A — UI-only; DB still tracks |
| School toggle off | School-wide disable → all receipt display suppressed | N/A — UI-only; DB still tracks |
| Deleted user | User deleted → their receipt rows remain (immutable audit log) | N/A — receipt table has no FK cascade delete |
| Group read summary | Sender sees "Read by X of Y members" where Y = active participants minus sender | N/A — computed dynamically |
| Message deleted before read | Message deleted → receipt rows remain with `read_at = NULL` | N/A — no UI surface for deleted messages |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_message_receipts` | `message_id` → `cht_messages.id` | Links receipt to the tracked message |
| CommonChat | `cht_message_receipts` | `user_id` → `sys_users.id` | Identifies the recipient user |
| CommonChat | `cht_participants` | `unread_count` | Denormalised counter reset on mark-read |
| CommonChat | `cht_personalization_settings` | `user_id` → `sys_users.id` | Per-user read receipt display toggle |
| CommonChat | `cht_settings` | `default_read_receipt_enabled` | School-level read receipt display toggle |
| System | `sys_users` | N/A (JOIN on `user_id`) | Display names in group read-receipt detail list |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| See read status (DM) | Message sender | Implicit — sender of the message |
| See read summary (Group) | Message sender | Implicit — sender of the message; sees "Read by X of Y" |
| See individual read details (Group) | Message sender | Implicit — expandable list on hover/tap |
| Toggle own read receipt display | Any chat user | `cht_personalization_settings.show_read_receipt_enabled` |
| Mark conversation as read | Any active participant | Implicit — trigger on conversation open or message send |
| Disable read receipts (school-wide) | Super Admin | `cht_settings.default_read_receipt_enabled`
