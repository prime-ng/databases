# CommonChat Tab 1: Chat Dashboard

This is the main landing screen that every user sees when they open the chat module. It displays all of the user's active conversations in a single scrollable list, sorted by most recent activity. The dashboard gives the user a snapshot of who they have been talking to and which conversations have new, unread messages.

---

## How It Works

When the user opens the dashboard, they see a list of all conversations they are currently a participant in. Each conversation row shows the other participant's name (for direct messages) or the group name (for group chats), a preview of the last message sent, the time of that last message, and a badge with the number of unread messages. Pinned conversations always appear at the top of the list in the order the user has chosen.

The user can click any conversation to open it and start reading or sending messages. At the top of the screen, there are buttons to start a new direct message, create a new group, or view archived conversations. The dashboard also has a search bar to find conversations or specific messages. Archived conversations are hidden from the main list but can be accessed through a dedicated filter or tab.

---

## Important Business Rules

- The conversation list is sorted by `last_message_at` descending — the most recently active conversation appears first.
- Pinned conversations (maximum 5 per user) always appear at the top, sorted by `pin_order`, before unpinned conversations.
- Conversations with zero unread messages do not show a badge. Conversations with 10 or more unread messages show "9+" instead of the exact number.
- A conversation that has been archived by the user does not appear in the main list. The user must switch to the "Archived" view to see it.
- A conversation where the user has left (group departure) does not appear in the list at all.
- If the user has no conversations, a friendly empty-state message is shown with a prompt to start their first conversation.
- The dashboard loads 20 conversations per page with infinite scroll or click-to-load-more pagination.
- Non-participants cannot see any conversation list data. Every request validates that the user is a member of the conversations returned.

---

## Database Columns & Behavior

### cht_participants
- `id` — BIGINT UNSIGNED PK. Primary row identifier.
- `conversation_id` — BIGINT UNSIGNED FK to cht_conversations.id. Links the participant record to the conversation header.
- `user_id` — INT UNSIGNED FK to sys_users.id. The participant user.
- `role` — ENUM('Member','Admin'). Not displayed directly but controls available actions on each conversation.
- `joined_at` — TIMESTAMP. When the user joined the conversation. Used for display on the conversation info screen.
- `left_at` — TIMESTAMP NULL. If set, the conversation is hidden from the dashboard for this user.
- `muted_until` — TIMESTAMP NULL. Muted conversations still appear in the list but the unread count badge is not incremented.
- `is_pinned` — TINYINT(1). When 1, the conversation floats to the top of the list.
- `pin_order` — TINYINT UNSIGNED NULL. Sort position for pinned items (1–5).
- `unread_count` — INT UNSIGNED. Denormalised counter shown as the badge on each conversation row.
- `archived_at` — TIMESTAMP NULL. When set, the conversation is hidden from the main dashboard and shown only in the Archived view.

### cht_conversations
- `id` — BIGINT UNSIGNED PK. Conversation identifier.
- `conversation_type` — ENUM('Direct','Group','Announcement'). Determines icon and display style in the list.
- `name` — VARCHAR(150) NULL. Group or announcement name. NULL for DMs; the dashboard derives the display name from the other participant's sys_users.name.
- `last_message_at` — TIMESTAMP NULL. Primary sort column for the dashboard list.
- `last_message_preview` — VARCHAR(100) NULL. First 100 characters of the most recent message, shown as the preview text on each row.
- `is_archived` — TINYINT(1). School-level archive (read-only for all participants). Separate from per-user archive.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Visible (main list) | User archives conversation | Archived | Per-user `archived_at` set |
| Archived | User unarchives conversation | Visible (main list) | `archived_at` cleared |
| Visible (main list) | User leaves group | Hidden from list | `left_at` set; cannot rejoin |
| Visible (main list) | User pins conversation | Pinned (top of list) | Max 5 pins; `is_pinned=1`, `pin_order` set |
| Pinned | User unpins conversation | Visible (normal position) | `is_pinned=0`, `pin_order=NULL` |

- Pagination flow: Dashboard loads 20 conversations per page. Infinite scroll triggers next page when user scrolls near bottom. Each page validates participant membership server-side.
- Empty-state flow: If `cht_participants` returns zero rows (and no archived conversations exist), a friendly empty-state CTA prompts the user to start their first conversation.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Pin count | Max 5 pinned conversations per user | "You can only pin up to 5 conversations. Unpin one before pinning another." |
| Unread badge display | ≥10 unread → show "9+" | N/A — client-side formatting rule |
| Archived conversation visibility | `archived_at` IS NOT NULL → excluded from main list | N/A — silent exclusion |
| Left group visibility | `left_at` IS NOT NULL → excluded from list | N/A — silent exclusion |
| Conversation membership | Non-participant requests list → 403 | "You are not a participant in this conversation." |
| Pagination | Page size = 20, max page depth = none | N/A |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_participants` | `conversation_id` → `cht_conversations.id` | Links membership to conversation header |
| CommonChat | `cht_participants` | `user_id` → `sys_users.id` | Identifies the participant user |
| CommonChat | `cht_conversations` | `last_message_at`, `last_message_preview` | Denormalised sort and preview columns; updated via service-layer event after every message insert |
| System (sys) | `sys_users` | N/A (JOIN on `cht_participants.user_id`) | Derives display name for DM conversations |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View dashboard (list conversations) | Any active chat participant | Implicit — granted by membership in `cht_participants` |
| Pin/unpin conversation | Any conversation participant | Implicit — per-user state toggle |
| Archive/unarchive conversation (per-user) | Any conversation participant | Implicit — per-user state toggle |
| View archived conversations | Any conversation participant | Implicit — requires `archived_at IS NOT NULL` filter
