# CommonChat Tab 2: Direct Messaging (1:1 Chat)

This screen is the private conversation view between two users. It shows the full message history between the pair and allows each participant to send new messages, reply to older messages, and manage the conversation through pinning, muting, or archiving.

---

## How It Works

When the user selects a direct message conversation from the dashboard, they enter a full-screen chat view. The entire message history between the two participants is displayed in chronological order, with the most recent messages at the bottom. Each message shows the sender's name (only in group context; for DMs the other participant's name is always known), the message body, the timestamp, and any attached files.

The user can type a new message in the composer at the bottom and press Enter or click Send to deliver it. Messages appear instantly in the UI and are persisted to the database. The user can also reply to a specific earlier message by clicking the reply icon on that message, which threads the new message below the original.

To start a new direct message, the user clicks a "New Chat" button on the dashboard, which opens a user picker. The picker shows all users the current user is allowed to message, filtered by role-based rules. After selecting a recipient, the system either creates a new conversation or opens the existing one — only one direct message conversation can exist between any two users.

---

## Important Business Rules

- Exactly one direct message conversation can exist for any pair of users. This is enforced at the database level by a unique index on the `dm_pair_hash` generated column.
- A user cannot start a conversation with themselves. The system rejects self-recipient selection.
- Both users must be active (`sys_users.is_active = 1`) to participate in a DM. If one user is deactivated, their existing messages remain visible but new messages cannot be sent or received.
- Students cannot initiate DMs to other students unless the school setting `allow_student_to_student` is enabled.
- Students and parents can only initiate DMs to teachers and admin roles by default. Additional role-based restrictions are configurable in cht_permission_config.
- Parents can only message teachers who are currently assigned to their child's enrolled class-section.
- When a user deletes a DM conversation (soft-deletes their participant record), only their own view is affected. The other participant still sees the full conversation.
- Messages are loaded 50 at a time with infinite scroll. Older messages load as the user scrolls up.
- All message operations (send, load, reply) use AJAX only. No full page reloads.

---

## Database Columns & Behavior

### cht_conversations
- `id` — BIGINT UNSIGNED PK. Conversation identifier.
- `conversation_type` — ENUM('Direct','Group','Announcement'). Always 'Direct' for DM conversations.
- `name` — VARCHAR(150) NULL. Always NULL for DMs. The display name is derived from the other participant's sys_users record.
- `user_a_id` — INT UNSIGNED NULL. The lower user ID of the pair. Set by the service layer using LEAST(userId, recipientId).
- `user_b_id` — INT UNSIGNED NULL. The higher user ID of the pair. Set by the service layer using GREATEST(userId, recipientId).
- `dm_pair_hash` — VARCHAR(100) GENERATED ALWAYS AS STORED. Unique hash string ("userAid_userBid") that prevents duplicate DM conversations between the same pair.
- `last_message_at` — TIMESTAMP NULL. Updated on every new message. Used for list sorting.
- `last_message_preview` — VARCHAR(100) NULL. First 100 characters of the most recent message.

### cht_participants
- `id` — BIGINT UNSIGNED PK. Participant row identifier.
- `conversation_id` — BIGINT UNSIGNED FK. Links to the DM conversation.
- `user_id` — INT UNSIGNED FK. One of the two participants.
- `role` — ENUM('Member','Admin'). Both participants in a DM have 'Member' role.
- `left_at` — TIMESTAMP NULL. When set, this user has deleted their view of the conversation.
- `unread_count` — INT UNSIGNED. Denormalised unread count for this user in this conversation.

### cht_messages
- `id` — BIGINT UNSIGNED PK. Message identifier.
- `conversation_id` — BIGINT UNSIGNED FK. The DM conversation this message belongs to.
- `sender_id` — INT UNSIGNED FK to sys_users.id. The message author.
- `body` — VARCHAR(2000) NULL. Plain text message content. Cleared on soft-delete.
- `message_type` — ENUM('Text','Attachment','System'). Distinguishes regular messages from attachment-only or system-generated messages.
- `parent_message_id` — BIGINT UNSIGNED FK NULL. Links to the message this reply references. Only one level of nesting allowed.
- `is_deleted` — TINYINT(1). When 1, the message body is cleared and "This message was deleted" is shown.
- `created_at` — TIMESTAMP. Message send time. Used for chronological ordering.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| No DM exists | User picks recipient & creates DM | DM created (active) | `cht_conversations` row created; 2 `cht_participants` rows inserted |
| DM active (both participants) | User deletes their view (soft-delete) | DM hidden for deleting user | `cht_participants.left_at` set; other user unaffected |
| DM hidden for user A | User A reopens DM | DM visible for user A again | New message from user B recreates participant row or clears `left_at` |
| DM active | One user deactivated | DM read-only | New messages blocked; history still visible |

- DM uniqueness enforced at DB level via `dm_pair_hash` generated column — the service layer sets `user_a_id = LEAST(userId, recipientId)` and `user_b_id = GREATEST(userId, recipientId)` to guarantee consistent hashing.
- Message loading flow: 50 messages per page, loaded via AJAX on scroll-up. Older messages fetched with `created_at < earliest_loaded`.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Self-recipient | User cannot message themselves | "You cannot start a conversation with yourself." |
| Active user check | Both users must have `sys_users.is_active = 1` | "Cannot start a conversation. The selected user account is inactive." |
| DM uniqueness | Only one DM per user pair | "A conversation already exists between you and this user." — system should redirect to existing conversation |
| Student-to-student DM | Blocked unless school setting enabled | "Students are not allowed to message other students." |
| Student-to-parent DM | Blocked by default | "Students cannot message parents directly." |
| Parent-teacher assignment | Parent can only message teachers assigned to their child's class-section | "You can only message teachers assigned to your child's class." |
| Message body length | Max 5,000 characters (FormRequest) | "Message cannot exceed 5,000 characters." |
| Reply depth | Only one level of nesting allowed | "You cannot reply to a reply." |
| Deleted user messages | `sender_id` set to NULL on user delete | Displayed as "Deleted User" |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| System | `sys_users` | `cht_participants.user_id`, `cht_messages.sender_id` | User identity; active status check |
| System | `sys_roles` | N/A (JOIN via `sys_users.role_id`) | Role-based permission evaluation for DM initiation |
| CommonChat | `cht_conversations` | `dm_pair_hash` | Enforces one-DM-per-pair constraint |
| CommonChat | `cht_messages` | `parent_message_id` → `cht_messages.id` | Reply threading |
| CommonChat | `cht_participants` | `conversation_id` → `cht_conversations.id` | Membership check and per-user state |
| CommonChat | `cht_permission_config` | `permission_for_role_id` | Role-based DM initiation rules |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Start new DM | All active users (with role restrictions) | Evaluated via `cht_permission_config` role-pair rules |
| Send message in DM | Active participant of the conversation | Implicit — `cht_participants` membership check |
| View DM history | Active participant of the conversation | Implicit — `cht_participants` membership check |
| Delete own message | Message sender | Implicit — `cht_messages.sender_id` match |
| Delete DM view (soft-delete) | Either participant | Implicit — sets `cht_participants.left_at`
