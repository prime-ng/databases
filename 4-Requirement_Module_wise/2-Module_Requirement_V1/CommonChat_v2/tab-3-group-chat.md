# CommonChat Tab 3: Group Chat

This screen allows authorised users to create and participate in multi-user group conversations. Groups have a name, an optional description, an optional avatar, and one or more administrators who manage the membership. The group chat view itself looks similar to a DM view but shows the group name at the top and displays the sender name alongside each message.

---

## How It Works

A user who has permission to create groups clicks "New Group" on the dashboard. They enter a group name (required), an optional description, and select at least two additional participants from the user picker. The group is created with the creator set as the first admin. After creation, members can see the group in their dashboard and start sending messages.

Group administrators can add new members, remove existing members, rename the group, change the description, upload a group avatar, or archive the entire group. Regular members can send messages and view the member list but cannot manage membership or change group settings. Any member can voluntarily leave the group; their departure is recorded and they stop receiving messages.

A group can be archived by any admin. Once archived, the conversation becomes read-only — existing messages remain visible but no new messages can be sent. Archived status is visible to all members. An admin can unarchive the group to restore normal function.

---

## Important Business Rules

- The group creator is automatically assigned the 'Admin' role in `cht_participants`.
- A group must have at least 3 members total at creation time (creator plus 2 additional participants).
- The maximum number of group members is set by the school's `cht_settings.max_group_members` (default 100, hard upper limit 500).
- A group admin can add or remove members at any time while the group is active.
- The group creator cannot be removed unless they first transfer admin ownership to another member.
- If the last admin leaves or is removed without transferring ownership, the longest-tenured remaining active member is auto-promoted to admin.
- Students and parents cannot create groups. This is enforced by a Gate policy at the controller level.
- A member who leaves a group can be re-added by an admin. Their previous message history remains visible after rejoining.
- System-generated messages (e.g., "John joined the group", "Jane was removed by Admin", "Ownership transferred to Sarah") are shown in the message stream with a distinct system style.
- Group name is limited to 100 characters; description is limited to 500 characters.

---

## Database Columns & Behavior

### cht_conversations
- `id` — BIGINT UNSIGNED PK. Conversation identifier.
- `conversation_type` — ENUM('Direct','Group','Announcement'). Always 'Group'.
- `name` — VARCHAR(150). Required for groups. Displayed in the chat header and conversation list.
- `description` — VARCHAR(1000) NULL. Optional group description. Shown on the Group Info screen.
- `avatar_media_id` — INT UNSIGNED NULL. Spatie Media Library media.id for the group avatar image.
- `is_archived` — TINYINT(1). When 1, the group is read-only. No new messages can be sent.
- `user_a_id`, `user_b_id` — Always NULL for groups.
- `dm_pair_hash` — Always NULL for groups.

### cht_participants
- `id` — BIGINT UNSIGNED PK. Participant row.
- `conversation_id` — BIGINT UNSIGNED FK. Links to the group conversation.
- `user_id` — INT UNSIGNED FK. The group member.
- `role` — ENUM('Member','Admin'). 'Admin' for group administrators. 'Member' for regular participants.
- `joined_at` — TIMESTAMP. When the user was added to the group. Used for auto-promotion logic.
- `left_at` — TIMESTAMP NULL. When set, the user has left the group. NULL means currently active.

### cht_messages
- `id` — BIGINT UNSIGNED PK. Message identifier.
- `conversation_id` — BIGINT UNSIGNED FK. The group this message belongs to.
- `sender_id` — INT UNSIGNED FK. The author. NULL for system messages or deleted users.
- `message_type` — ENUM('Text','Attachment','System'). System type for join/leave/admin-change events.
- `body` — VARCHAR(2000) NULL. Message content. For system messages, contains the event description.
- `created_at` — TIMESTAMP. Message timestamp.

---

## Deep Analysis

### Business Workflows & State Machines

| State | Trigger | Next State | Notes |
|-------|---------|------------|-------|
| Draft (creation form) | Creator selects participants & submits | Active | Min 3 members required; creator becomes Admin |
| Active | Admin archives group | Archived (read-only) | `cht_conversations.is_archived = 1`; no new messages |
| Archived | Admin unarchives group | Active | `cht_conversations.is_archived = 0`; normal function restored |
| Active | Member voluntarily leaves | Left (departed) | `cht_participants.left_at` set; member stops receiving messages |
| Active | Admin removes member | Removed | `cht_participants.left_at` set; can be re-added by admin |
| Active | Last admin leaves without transfer | Auto-promotion | Longest-tenured active member auto-promoted to Admin |

- Admin transfer flow: The creator cannot be removed unless they first transfer ownership. Transfer sets target user's `role = 'Admin'` and optionally demotes the transferor.
- System messages are auto-generated for: member join, member removal, ownership transfer, group rename, group archive/unarchive. These use `message_type = 'System'` and appear with distinct styling.
- Leave/rejoin flow: A member who left can be re-added by an admin. Their previous `cht_messages` history remains visible after rejoining.

### Validation Rules & Edge Cases

| Operation/Field | Rule | Error Message |
|----------------|------|---------------|
| Group creation | Min 3 members (creator + 2) | "A group must have at least 3 members." |
| Group member limit | Max `cht_settings.max_group_members` (default 100, hard cap 500) | "Group cannot exceed {limit} members." |
| Group name length | Max 100 characters | "Group name must be 100 characters or fewer." |
| Group description length | Max 500 characters | "Group description must be 500 characters or fewer." |
| Creator removal | Creator cannot be removed without transferring ownership | "You cannot remove the group creator. Ask them to transfer ownership first." |
| Student/parent group creation | Blocked at Gate policy level | "Students and parents are not allowed to create groups." |
| Last admin departure | Auto-promote longest-tenured member | N/A — system action; logged as system message |
| Archived group messaging | Message send rejected | "This conversation is archived and is now read-only." |
| Membership verification | Non-member attempts to send/view | HTTP 403 — "You are not a participant in this conversation." |

### Integration Points

| Module | Table(s) | Foreign Key | Purpose |
|--------|----------|-------------|---------|
| CommonChat | `cht_conversations` | `created_by` → `sys_users.id` | Tracks group creator for admin transfer rules |
| CommonChat | `cht_participants` | `conversation_id`, `user_id`, `role` | Memberships with Admin/Member roles |
| CommonChat | `cht_messages` | `sender_id` → `sys_users.id` (NULL for system messages) | Regular and system messages |
| CommonChat | `cht_settings` | N/A | Reads `max_group_members` for enforcement |
| System | `sys_users` | N/A (JOIN on user_id) | Display names, active status |
| Spatie Media Library | `cht_conversations.avatar_media_id` | FK to `media.id` | Group avatar storage |

### Permissions Matrix

| Action | Role | Permission Key |
|--------|------|----------------|
| Create group | Teacher, Admin, Super Admin | Evaluated via `cht_permission_config.can_create_group` |
| Send message in group | Active group member | Implicit — `cht_participants` membership check |
| Add/remove members | Group Admin | `cht_participants.role = 'Admin'` |
| Rename group | Group Admin | `cht_participants.role = 'Admin'` |
| Archive/unarchive group | Group Admin | `cht_participants.role = 'Admin'`; sets `is_archived` |
| Transfer ownership | Group Admin (creator) | Admin role + creator check; system message logged |
| Leave group | Any member | Implicit — self-service; `left_at` set |
| View member list | Any active member | Implicit — membership check |
| Upload group avatar | Group Admin | `cht_participants.role = 'Admin'`
