# CommonChat Tab 8: Notifications & Alerts

This screen controls how users receive notifications about new chat messages. Users are alerted when someone sends them a message, mentions them with an @username tag in a group, or when a conversation they are in has new activity. The system supports both in-app alerts and integration with the school's notification module.

---

## How It Works

When a new message is sent in a conversation the user is a member of, the system checks whether the user has muted that conversation. If not muted, an in-app notification is created. For direct messages, the notification shows the sender's name and the first 80 characters of the message. For group conversations, it shows the group name, the sender's name, and the message preview. If the user is @mentioned in a group message, the notification is highlighted as a mention.

Users can configure their notification preferences from a settings screen within the chat module. They can choose to receive or suppress notifications for new messages generally, for mentions only, or disable them entirely. They can also control whether message preview text appears in notifications — a privacy option for users who share devices. Additionally, each individual conversation can be muted permanently or for a set duration directly from the conversation settings.

---

## Important Business Rules

- Notifications are sent only for non-muted conversations. A muted conversation produces no notification and does not increment the unread count.
- When a conversation is muted, the user can still read and send messages. Only the notification and unread counter are suppressed.
- Mute can be set for a specific duration (until a future timestamp) or permanently (using a far-future date like 9999-12-31 23:59:59).
- The @mention feature triggers a special highlighted notification, but only if the recipient has `notify_on_mention` enabled in their personalisation settings.
- Users can disable all chat notifications permanently from their personalisation settings without affecting other users.
- Message preview in notifications can be suppressed per-user via `cht_personalization_settings.show_message_preview_in_notif`.
- If the school's Notification module is unavailable, the system falls back to updating unread counts only (no notification dispatched).
- Mute status is per-user and per-conversation. One user muting a conversation does not affect other participants.
- In-app notifications appear in the global notification bell/dropdown in the application header, integrated with the ntf_* notification delivery chain.

---

## Database Columns & Behavior

### cht_participants
- `id` — BIGINT UNSIGNED PK. Participant identifier.
- `conversation_id` — BIGINT UNSIGNED FK. The conversation being muted or notified.
- `user_id` — INT UNSIGNED FK. The user whose notification setting is being controlled.
- `muted_until` — TIMESTAMP NULL. NULL = not muted. Future timestamp = muted until that date. Far-future = muted indefinitely.
- `unread_count` — INT UNSIGNED. Not incremented when the conversation is muted.

### cht_personalization_settings
- `id` — INT UNSIGNED PK. Setting record identifier.
- `user_id` — INT UNSIGNED FK. One-to-one with sys_users. Created lazily on first chat access.
- `role_id` — INT UNSIGNED FK. Denormalised for role-based default queries.
- `notify_on_new_message` — TINYINT(1) DEFAULT 1. When 0, no notifications are sent for new messages.
- `notify_on_mention` — TINYINT(1) DEFAULT 1. When 1, @mentions trigger highlighted notifications.
- `show_message_preview_in_notif` — TINYINT(1) DEFAULT 1. When 0, notifications show only "New message from {name}" without body text.
- `show_online_status` — TINYINT(1) DEFAULT 1. Privacy: when 0, user always appears offline.
- `show_read_receipt_enabled` — TINYINT(1) DEFAULT 1. When 0, the user's read status is not shown to others.

### cht_settings
- `id` — TINYINT UNSIGNED PK. Default 1. Single-row school-level config.
- `default_notify_on_new_message` — TINYINT(1) DEFAULT 1. Default value when user settings are first created.
- `default_notify_on_mention` — TINYINT(1) DEFAULT 1. Default value for mention notification preference.
- `show_message_preview_in_notif` — TINYINT(1) DEFAULT 1. School-wide default for message preview in notifications.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| New message sent | System checks `muted_until` on participant row | Not muted → dispatch notification | If `muted_until IS NULL` or `muted_until < NOW()` |
| New message sent | System checks `muted_until` on participant row | Muted → no notification | `muted_until >= NOW()`; `unread_count` NOT incremented |
| Notification dispatched | Message contains @mention | Highlighted mention notification | Checked against `notify_on_mention` setting |
| User receives notification | User opens conversation | Notification dismissed | Unread badge cleared; mark-read endpoint called |
| User wants to mute | User sets mute via conversation settings | Muted (temporary or permanent) | `muted_until` set to future timestamp or 9999-12-31 |
| Mute expires | Current time passes `muted_until` | Active (unmuted) | Next message will trigger notification; `muted_until` not auto-cleared |
| User changes global prefs | User toggles `notify_on_new_message` | Prefs updated | `cht_personalization_settings` updated; affects all conversations |

- When the school's Notification module (`ntf_*` tables) is unavailable, the system gracefully degrades: no notification event is dispatched, but the `unread_count` is still incremented (for non-muted conversations). The dashboard badge still reflects new activity even without notification delivery.
- The mute duration is stored as a single `muted_until` timestamp. A far-future date (`9999-12-31 23:59:59`) is used to represent permanent mute. The service layer checks `muted_until >= NOW()` to determine mute status; no separate `is_muted` column is needed.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Muted conversation | `unread_count` NOT incremented when muted | N/A — silent behaviour |
| Mute duration | `muted_until` must be a future timestamp or far-future for permanent | N/A — validation in FormRequest if user-input driven |
| @mention | Only triggers highlight if recipient has `notify_on_mention = 1` | N/A — silent filter |
| All notifications disabled | `notify_on_new_message = 0` → all chat notifications suppressed | N/A — user preference; no error |
| Message preview disabled | `show_message_preview_in_notif = 0` → "New message from {name}" only | N/A — user preference; privacy option |
| Notification module down | Falls back to unread count update only | N/A — graceful degradation |
| Per-conversation mute | Does not affect other participants | N/A — per-user column |
| Muted user sends message | Sender's own messages still sent; only recipient notifications suppressed | N/A — sender not affected |
| User deactivated | Deactivated user still has notification settings preserved | N/A — settings retained for reactivation |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_participants` | `muted_until` | Per-conversation mute status; checked before notification dispatch |
| CommonChat | `cht_personalization_settings` | `user_id` → `sys_users.id` | Global notification preferences |
| CommonChat | `cht_settings` | N/A | School-level default notification preferences |
| Notifications (ntf) | `ntf_notifications` | N/A (event-driven) | External notification delivery chain; triggered via event/listener |
| System | `sys_users` | N/A (JOIN on `user_id`) | Sender display name in notification body |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Receive chat notifications | Any active chat user with `notify_on_new_message = 1` | Implicit — based on user preference |
| Mute/unmute conversation | Any conversation participant | Implicit — `cht_participants.muted_until` update |
| Configure notification preferences | Any authenticated user | `cht_personalization_settings` update |
| Disable message preview in notifications | Any authenticated user | `cht_personalization_settings.show_message_preview_in_notif` |
| Set school defaults for notifications | Super Admin | `cht_settings.default_notify_on_new_message`, `default_notify_on_mention`
