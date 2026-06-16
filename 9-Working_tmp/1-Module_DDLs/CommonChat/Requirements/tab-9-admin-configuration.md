# CommonChat Tab 9: Admin Configuration

This screen is accessible only to Super Admin users. It allows the school to configure all chat-related settings: who can message whom, maximum group sizes, attachment size limits, message retention policies, and default user preferences. Changes made here affect all users in the school.

---

## How It Works

The admin opens the Chat Settings screen from the administration menu. They see a form divided into several sections. The first section contains general settings such as maximum group members, maximum file/audio/video attachment sizes (in MB), and message retention days. The second section contains default user preferences — the defaults that apply to new users when they first access the chat module, such as whether read receipts are shown, whether online status is visible, and whether notifications are enabled by default.

The third and most complex section is the permission configuration. For each role in the school (Super Admin, Principal, Teacher, Student, Parent, etc.), the admin can define which roles that role is allowed to message. They can also enable or disable specific capabilities per role pair: text chat, sending attachments, sending audio, sending video, sending URLs, sending emojis, creating groups, and creating announcements. There is also a "can message anyone" override that bypasses all restrictions for specific roles. The system stores these rules in `cht_permission_config`. Individual user overrides are also supported — an admin can set custom permissions for a specific user that override their role-based defaults.

---

## Important Business Rules

- Only users with the `tenant.chat.settings` permission (Super Admin by default) can access this screen.
- The `cht_settings` table has exactly one row per school. Settings have no version history — each save overwrites the existing values.
- Permission configuration is evaluated in a priority order: (1) user-specific override in `cht_permission_config`, (2) role-based rule in `cht_permission_config`, (3) default value from `cht_settings`.
- The maximum group member limit has a hard upper bound of 500. The admin cannot set a value higher than this even if they enter a larger number.
- Setting message retention days to 0 means messages are kept indefinitely. Any positive number enables auto-purge of messages older than that many days.
- Disabling "show read receipts" at the school level prevents all users from seeing read status, even if their individual preference is enabled.
- Audio and video sharing are disabled by default and must be explicitly enabled by the admin via the permission config.
- The "can message anyone" flag overrides all other role-based restrictions for the specified role. It should be used sparingly.
- Changes to permission config take effect immediately. Active sessions may need to refresh to see updated UI options.

---

## Database Columns & Behavior

### cht_settings
- `id` — TINYINT UNSIGNED PK. Always 1. Single row per tenant.
- `max_group_members` — SMALLINT UNSIGNED DEFAULT 100. Max participants per group. Hard upper limit 500.
- `max_file_attachment_size_mb` — TINYINT UNSIGNED DEFAULT 10. Max file upload size in MB.
- `max_audio_attachment_size_mb` — TINYINT UNSIGNED DEFAULT 10. Max audio upload size in MB.
- `max_video_attachment_size_mb` — TINYINT UNSIGNED DEFAULT 10. Max video upload size in MB.
- `message_retention_days` — SMALLINT UNSIGNED DEFAULT 0. 0 = keep indefinitely. Positive = auto-purge older messages.
- `default_read_receipt_enabled` — TINYINT(1) DEFAULT 1. School default for read receipt display.
- `default_show_online_status` — TINYINT(1) DEFAULT 1. School default for online status visibility.
- `default_notify_on_new_message` — TINYINT(1) DEFAULT 1. School default for new message notifications.
- `default_notify_on_mention` — TINYINT(1) DEFAULT 1. School default for mention notifications.
- `show_message_preview_in_notif` — TINYINT(1) DEFAULT 1. School default for notification preview text.
- `can_text_chat`, `can_send_attachment`, `can_send_audio`, `can_send_video`, `can_send_url`, `can_send_emoji` — TINYINT(1) DEFAULT values. Global defaults for these capabilities.
- `can_create_group`, `can_create_announcement` — TINYINT(1) DEFAULT 0. Global defaults.
- `can_message_anyone` — TINYINT(1) DEFAULT 0. Global override.
- `read_receipt_enabled` — TINYINT(1) DEFAULT 1. Global read receipt display toggle.

### cht_permission_config
- `id` — INT UNSIGNED PK. Permission rule identifier.
- `permission_for_role_id` — INT UNSIGNED FK to sys_roles.id. The role this rule applies to.
- `permission_for_user_id` — INT UNSIGNED FK NULL. Optional user-specific override. When set, overrides the role-based rule.
- `allowed_whom_to_connect_with` — INT UNSIGNED FK to sys_roles.id. The role that can be messaged.
- `can_text_chat`, `can_send_attachment`, `can_send_audio`, `can_send_video`, `can_send_url`, `can_send_emoji` — TINYINT(1). Per-role-pair capability flags.
- `can_create_group`, `can_create_announcement` — TINYINT(1). Permission to create groups or announcements with the target role.
- `can_message_anyone` — TINYINT(1). Override flag. When 1, all other restrictions for this role are bypassed.
- `read_receipt_enabled` — TINYINT(1). Per-role-pair read receipt override.
- `is_active` — TINYINT(1) DEFAULT 1. Toggle to enable/disable a rule without deleting it.
- Unique key on (`permission_for_role_id`, `permission_for_user_id`, `allowed_whom_to_connect_with`).

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Settings form loaded | Admin opens Chat Settings | Edit mode | Current values from `cht_settings` row in form fields |
| Edit mode | Admin modifies fields & saves | Saved (overwrite) | Single-row `cht_settings` updated; no version history |
| Saved | Admin navigates away | Done | Changes take effect immediately |
| Permission config empty | Admin navigates to permissions section | Add new rules | Create `cht_permission_config` rows per role-pair |
| Permission rule active | Admin toggles `is_active` to 0 | Rule disabled | Rule retained in DB but not evaluated |
| Permission rule disabled | Admin sets `is_active` to 1 | Rule active | Rule re-enabled |
| User override needed | Admin sets `permission_for_user_id` on a rule | User-specific rule created | Overrides role-based rule for that specific user |

- Permission evaluation priority chain:
  1. Check `cht_permission_config` where `permission_for_user_id = current_user.id` (user-specific override).
  2. If not found, check `cht_permission_config` where `permission_for_role_id = current_user.role_id` AND `permission_for_user_id IS NULL` (role-based rule).
  3. If not found, fall back to `cht_settings` defaults.
- The `can_message_anyone` flag at any level in the chain causes all other restrictions for that role/user to be bypassed immediately.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Max group members | Cannot exceed 500 (hard upper bound) | "Maximum group members cannot exceed 500." |
| Message retention days | 0 = keep indefinitely; positive = auto-purge | N/A — validated at save |
| `cht_settings` row count | Must always be exactly 1 row per tenant | Enforced by `id = 1` primary key pattern; insert-only on module seed |
| Permission priority | User-specific override > role-based rule > default | N/A — evaluation logic; no error |
| Disabled read receipts (school) | Overrides all per-user `show_read_receipt_enabled` settings | N/A — school-level toggle takes precedence |
| Audio/video defaults | Disabled by default; must be explicitly enabled | N/A — conscious design choice |
| `can_message_anyone` override | Bypasses all role-pair restrictions | N/A — intentional override |
| Active session refresh | Changes take effect immediately; UI updates on next page load | N/A — no stale cache issue |
| Duplicate permission rule | Unique key on (`permission_for_role_id`, `permission_for_user_id`, `allowed_whom_to_connect_with`) | "A permission rule for this role/user combination already exists." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_settings` | `id` (always 1) | Single-row school-level configuration |
| CommonChat | `cht_permission_config` | `permission_for_role_id` → `sys_roles.id` | Role-to-role permission rules |
| CommonChat | `cht_permission_config` | `permission_for_user_id` → `sys_users.id` | User-specific permission overrides |
| CommonChat | `cht_permission_config` | `allowed_whom_to_connect_with` → `sys_roles.id` | Target role for messaging rules |
| System | `sys_roles` | N/A (FK targets) | Role definitions used by permission config |
| System | `sys_users` | N/A (FK targets) | User-specific override identification |
| System | `sys_user_has_roles` | N/A | Current role context for permission evaluation |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| View chat settings | Super Admin | `tenant.chat.settings` |
| Edit general settings | Super Admin | `tenant.chat.settings` |
| Configure permission rules | Super Admin | `tenant.chat.settings` |
| Set user-specific overrides | Super Admin | `tenant.chat.settings` |
| Toggle role-pair capabilities | Super Admin | `tenant.chat.settings` |
| Set school defaults for notifications/read receipts | Super Admin | `tenant.chat.settings` |
