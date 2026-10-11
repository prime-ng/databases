# CommonChat Module — High Level Requirements (CHT)

**Version:** v1.0
**Date:** 2026-05-14
**Module Code:** CHT
**Table Prefix:** `cht_`
**Scope:** Tenant-scoped (`tenant_db`, per-school isolated)
**Module Path:** `Modules/CommonChat/`
**Route Prefix:** `/chat/*`
**Permission Prefix:** `tenant.chat.*`

---

## 1. Module Purpose

CommonChat is a standalone direct-messaging and group-chat system that allows any registered user within a school tenant to initiate and participate in conversations with any other registered user, subject to role-based access rules. It replaces the ad-hoc contextual remark threads (student leave remarks in `StudentProfile`, employee leave remarks in `SchoolSetup`) with a purpose-built, persistent messaging layer that is conversation-centric rather than document-centric. All message data is isolated per tenant in `tenant_db`; no cross-tenant communication is supported.

---

## 2. Existing Chat Pattern Reference

Two contextual remark systems already exist and served as the design reference for CommonChat:

| Reference | Module | Table | Pattern |
|-----------|--------|-------|---------|
| Student Leave Remarks | StudentProfile | `std_leave_application_remarks` | Chat-style thread on a leave application; `is_from_teacher` drives bubble alignment; media attached via separate `LeaveApplicationDocument` model; no SoftDeletes (permanent audit trail) |
| Employee Leave Remarks | SchoolSetup | `sch_employee_leave_application_remarks` | AJAX-based remark thread on an employee leave application; `read_at`/`read_by` for single-recipient read receipts; `markAsRead()` bulk endpoint; auto-status-change triggers on applicant response |

**Key learning:** Both systems use a `parent_remark_id` for threading, a `remarked_by` FK to `sys_users`, and document attachment via a separate join table. CommonChat adopts these patterns universally, decoupled from any specific workflow.

---

## 3. Users & Actors

All participants are records in `sys_users` (tenant database). Every role type that has a `sys_users` entry can be a CommonChat participant.

| Actor | Tenant Role(s) | Can Initiate DM? | Can Receive DM? | Can Create Group? | Can Broadcast? |
|-------|---------------|-----------------|-----------------|-------------------|----------------|
| Super Admin | super-admin | Any user | Yes | Yes | Yes |
| Principal | principal | Any user | Yes | Yes | Yes |
| Vice Principal | vice-principal | Any user | Yes | Yes | Yes |
| Teacher | teacher | Any user | Yes | Yes | No |
| Staff (Non-Teaching) | staff | Other staff, Admin | Yes | Yes | No |
| Accountant | accountant | Other staff, Admin | Yes | Yes | No |
| Librarian | librarian | Other staff, Admin | Yes | Yes | No |
| Parent | parent | Child's teachers + Admin | Yes (restricted) | No | No |
| Student | student | Teachers + Admin only | Yes (restricted) | No | No |

**Default restrictions shown above are overridable via `cht_settings`:**
- Students cannot initiate DMs to other students.
- Students cannot initiate DMs to parents (including their own).
- Parents cannot initiate DMs to other parents.
- Parents can only initiate DMs to teachers who currently teach their child's enrolled class-section.
- Parents can also initiate DMs to the Department heads (e.g. Library Manager, Transport Manager, Account Manager etc.).
- Teacher can initiate DMs to anyone including Students, Parents, Staff.
- Other Staff can initiate DMs to any non-student, non-parent user only.

---

## 4. Core Feature Inventory

### F-CHT-01: Direct Messaging (1:1 Chat)

**Description:** Any two registered users can open a private one-to-one conversation.

**Conditions:**
- Both users must be active (`sys_users.is_active = 1`) in the same tenant.
- Only one DM conversation can exist between the same pair of users. DB-enforced via a `STORED` generated column `dm_pair_hash` with a `UNIQUE` index (pattern from Architectural Decision D-TMP-003).
- Either participant can send a message at any time while both users are active.
- Deleted conversations (soft-deleted `cht_participants` record) are hidden only from the deleting user; the other participant's view is unaffected.
- Messages sent before a user's account is deactivated are retained in the other user's view.
- A user cannot initiate a DM with themselves (BR-CHT-002).

---

### F-CHT-02: Group Chat

**Description:** Authorised users can create a named group conversation with multiple participants.

**Conditions:**
- Group creator is automatically set as the group's first admin (`cht_participants.role = 'admin'`).
- Group `name` is required (max 100 characters); `description` is optional (max 500 characters).
- Minimum 2 additional participants at creation time (total ≥ 3 including creator).
- Maximum participants defined by `cht_settings.max_group_members` (default: 100).
- Any group admin can add or remove members. Members can be added while the group is active.
- Group creator cannot be removed unless they first transfer admin ownership to another member.
- If the last admin leaves or is removed without transferring ownership, the longest-tenured remaining active member is auto-promoted to admin.
- A member can voluntarily leave a group; their `cht_participants.left_at` is set, and they no longer receive messages. They can be re-added by an admin.
- Group can be archived by a group admin (`cht_conversations.is_archived = 1`): existing messages remain readable but no new messages can be sent. Archived status is visible to all members.
- Group avatar upload supported via Spatie Media Library (`employee_photo`-style media collection on the conversation record).
- Roles: Students and Parents cannot create groups (enforced at controller via Gate policy).

---

### F-CHT-03: Message Sending

**Description:** Authenticated participants can send text and/or file-attached messages within conversations they belong to.

**Conditions:**
- Message body must not be empty unless a file attachment is present (at least one of: body or attachment).
- Maximum message text length: 5,000 characters (enforced at FormRequest level).
- Message body stored as plain text — no HTML rendering to prevent XSS. Emojis stored as UTF-8 characters.
- Attachments supported:
  - Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
  - Documents: `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
  - Maximum file size: controlled by `cht_settings.max_attachment_size_mb` (default: 10 MB).
  - One attachment per message in Phase-1.
- Sender can delete their own message (soft-delete: `cht_messages.is_deleted = 1`, body cleared, shown as "This message was deleted").
- Sender cannot delete another user's message; only Admins can delete any message (moderation — F-CHT-12).
- All message-send endpoints return JSON (AJAX only); no full page reload on send (BR-CHT-009).
- Sending a message to an archived conversation is rejected with HTTP 422 and a validation error.
- Sending a message to a conversation the user is not a participant of returns HTTP 403 (IDOR protection, BR-CHT-003).

---

### F-CHT-04: Message Threading (Reply-To)

**Description:** A message can reference (reply to) an earlier message in the same conversation.

**Conditions:**
- `cht_messages.parent_message_id` stores the FK to the referenced message within the same conversation.
- Cross-conversation replies are not allowed (validated: parent message must share the same `conversation_id`).
- If a parent message is subsequently soft-deleted, it is shown as a "Deleted message" stub in the reply context — the reply itself is not affected.
- Reply depth is limited to 1 level: a reply cannot itself have a `parent_message_id` (BR-CHT-016). Validated at controller level.

---

### F-CHT-05: Read Receipts

**Description:** Senders see per-recipient read status for their messages.

**Conditions:**
- A `cht_message_receipts` record is created for each recipient when a message is sent (one row per message per non-sender participant).
- `read_at` is set when the recipient opens the conversation and fetches messages (bulk mark-read endpoint).
- For DM conversations: sender sees "Seen at {time}" once the single recipient reads.
- For group conversations: sender sees a count (e.g., "Read by 4 of 6 members").
- A message is considered fully read when ALL non-sender participants have a non-NULL `read_at`.
- Muted conversations (F-CHT-08): messages are still marked read when the user opens the conversation; muting only suppresses notifications, not read receipts.
- `cht_participants.unread_count` is a denormalised counter, decremented to 0 when the participant opens the conversation (bulk mark-read).

---

### F-CHT-06: Online Presence & Typing Indicators

**Description:** Users can see whether a conversation participant was recently active.

**Conditions:**
- Online status is determined from `cht_user_presence.last_seen_at`. A user is considered "Online" if `last_seen_at > (NOW() - INTERVAL 60 SECOND)`.
- `last_seen_at` is updated by the client on a 30-second heartbeat ping to a lightweight endpoint (`POST /chat/presence/ping`). No auth guard bypass — user must be authenticated.
- Users can disable their online status visibility via `cht_user_settings.show_online_status = 0`. When disabled, they appear Offline to everyone regardless of actual activity.
- Typing indicators are ephemeral — NOT stored in the database. Phase-1 implementation: client polls `GET /chat/{conversation}/typing` every 3 seconds; server returns active typists from an in-memory or short-TTL cache key (Redis, if available) or a lightweight presence table row updated on keypress. Detailed typing-indicator implementation is out of scope for the DDL.

---

### F-CHT-07: Message Search

**Description:** Users can search their message history within conversations.

**Conditions:**
- Search is scoped to conversations the requesting user is an active participant of (participant check enforced at every search query).
- Full-text search on `cht_messages.body` using MySQL `FULLTEXT` index or `LIKE %term%` (Phase-1: LIKE; Phase-2: FULLTEXT or Meilisearch).
- Deleted messages (`is_deleted = 1`) are excluded from search results.
- Results return the matched message with its conversation name, sender name, and 2 context messages before/after (fetched as a separate query).
- Cross-conversation search within the user's conversations is supported. Cross-tenant search is not possible (tenancy isolation).
- Maximum 50 search results per query.

---

### F-CHT-08: Conversation Notifications & Muting

**Description:** Users receive in-app notifications for new messages, with per-conversation mute controls.

**Conditions:**
- On every new message, the system increments `cht_participants.unread_count` for all non-sender participants whose `muted_until` is NULL or in the past.
- Notification delivery integrates with the `Notification` module: fires a `NewChatMessage` event → `ProcessChatNotification` listener → `ntf_*` delivery chain. If the Notification module is unavailable, falls back to updating unread counts only.
- Notification payload: sender name, conversation name (or other participant's name for DM), first 80 characters of message body.
- Message preview is suppressed (`cht_user_settings.show_message_preview_in_notif = 0`) by the recipient's setting, independent of the sender.
- A user can mute any conversation permanently or until a specific time (`cht_participants.muted_until`):
  - `NULL` = not muted.
  - Future timestamp = muted until that time.
  - Far-future timestamp (e.g., year 9999) = "muted forever" (practical equivalent).
- Muted conversations: `unread_count` is NOT incremented; no notification dispatched.
- Muted status is per-user, per-conversation (does not affect other participants).

---

### F-CHT-09: Conversation Management

**Description:** Users can organise their conversation list with pinning, archiving, and deletion.

**Conditions:**
- **Pinning:** Users can pin up to 5 conversations. Pinned conversations float to the top of the conversation list. `cht_participants.is_pinned = 1`, `pin_order` (1–5). Attempting to pin a 6th conversation returns a validation error prompting the user to unpin one first.
- **Per-user archiving:** Users can archive a conversation (`cht_participants.archived_at IS NOT NULL`). Archived conversations are hidden from the main list but remain accessible via a dedicated "Archived" tab. Archiving does not affect other participants.
- **Conversation deletion (DM only):** A user can delete their view of a DM conversation by soft-deleting their `cht_participants` record (`left_at` set). The other participant's view is unchanged. If both participants delete, the conversation and messages are retained for audit; hard deletion requires admin action.
- **List ordering:** Default sort: `cht_participants` joined to `cht_conversations`, ordered by `cht_conversations.last_message_at DESC`. Pinned conversations always listed first within their active/archived status.
- **Group departure:** A group member can leave via the "Leave Group" action (`cht_participants.left_at` set). They can be re-added by an admin.

---

### F-CHT-10: Role-Based Contact Restrictions

**Description:** The system enforces which roles can initiate conversations with which other roles, configurable via school settings.

**Default Rules (enforced at ChatService layer — not at DB layer):**

| Initiator | Can Message | Cannot Message (default) |
|-----------|------------|--------------------------|
| Super Admin / Principal / VP | Any user | — |
| Teacher | Any user | — |
| Staff / Accountant / Librarian | Admin + Other Staff | Students, Parents |
| Student | Teachers + Admin | Other Students, Parents, Staff |
| Parent | Child's active teachers + Admin | Other Parents, Students, Non-teaching Staff |

**Override via `cht_settings`:**

| Setting | When Enabled |
|---------|-------------|
| `allow_student_to_student` | Students can DM other students in their school |
| `allow_parent_to_parent` | Parents can DM other parents |
| `allow_student_to_parent` | Students can initiate DM to their own parent |
| `allow_student_to_staff` | Students can DM non-teaching staff |

**Parent → Teacher restriction enforcement:**
- Validated in `ChatService::canInitiateDm($initiator, $recipient)`.
- Query: `std_student_academic_sessions` → `sch_class_section_jnt` → teacher assignments → confirm recipient teacher_id is assigned to the class-section the parent's child is currently enrolled in.
- This is a read-only cross-module check; no FK constraint between `cht_*` and `std_*` tables.

---

### F-CHT-11: Announcements (One-Way Broadcast)

**Description:** Authorised users can send broadcast messages to a class, section, or the whole school.

**Conditions:**
- Announcement conversations have `cht_conversations.conversation_type = 'announcement'`.
- Only the original creator (and other admins) can post messages in an announcement thread. All other participants are read-only.
- Sender must have `tenant.chat.broadcast` permission (assigned to: Super Admin, Principal, Vice Principal by default).
- Scope options at creation: Whole School, Specific Class, Specific Class-Section.
- Recipient list is computed at creation time and stored as individual `cht_participants` records. If a new student joins the class after the announcement is sent, they do NOT automatically receive past messages (snapshot model).
- Each recipient receives a `NewChatMessage` notification (same as F-CHT-08).
- Announcement threads are not deletable by recipients; only the creator or a Super Admin can delete.

---

### F-CHT-12: Message Moderation

**Description:** Admin users can oversee and remove messages from any conversation in the school.

**Conditions:**
- Only users with `tenant.chat.moderate` permission (assigned to: Super Admin, Principal by default) can access the moderation view.
- Moderation view shows: flagged messages, recently deleted messages, high-volume conversations.
- Admin can soft-delete any message from any conversation (`cht_messages.is_deleted = 1`, `deleted_by = admin_user_id`, body cleared).
- After admin deletion, all participants see "Removed by Admin" instead of the original message body.
- All moderation actions are written to `sys_activity_logs` with: `subject_type = 'cht_messages'`, `subject_id`, `action = 'moderated'`, `causer_id = admin_user_id`, `properties_json = {reason, original_body_hash}`. Original body is NOT stored in the log — only its SHA-256 hash (privacy).
- Moderation cannot hard-delete messages; force-delete requires a separate manual DB operation.

---

## 5. Non-Functional Requirements

| Requirement | Specification |
|-------------|---------------|
| **Performance — List** | Conversation list must load in < 1 second. Query: paginated 20 conversations per page with last message preview (denormalised in `cht_conversations.last_message_preview`). |
| **Performance — Messages** | Messages within a conversation: paginated 50 per page, ordered `created_at DESC`, with cursor-based pagination for infinite scroll. |
| **Real-time (Phase-1)** | AJAX polling at 5-second intervals on the active conversation view. 30-second heartbeat for presence. |
| **Real-time (Phase-2)** | Laravel Echo + Pusher Channels or Laravel Reverb (self-hosted WebSocket). No DDL changes required. |
| **Data Isolation** | All `cht_*` tables reside in `tenant_db`. Multi-tenancy bootstrapper (`DatabaseTenancyBootstrapper`) ensures queries are automatically scoped to the correct tenant database. |
| **Storage** | Attachments stored in `storage/tenant_{uuid}/chat-attachments/` via Spatie Media Library (collection: `chat-attachment`). |
| **Retention** | Messages soft-deleted only by default. School can configure auto-purge after N days via `cht_settings.message_retention_days` (0 = never auto-purge). Hard delete via artisan command `chat:purge-messages --before=DATE`. |
| **Security** | Participant check on EVERY message read/send endpoint. Non-participants receive HTTP 403. |
| **Compliance** | No chat message content stored in `prime_db` or `global_db`. No PII stored in `cht_*` beyond `sys_users.id` references. |
| **Accessibility** | Message timestamps displayed in the authenticated user's locale (derived from `sys_users` settings or browser timezone). |

---

## 6. Business Rules Summary

| Rule ID | Rule |
|---------|------|
| BR-CHT-001 | Only one DM conversation can exist per user pair. Enforced via `dm_pair_hash` UNIQUE index on `cht_conversations` (MySQL STORED generated column). |
| BR-CHT-002 | A user cannot initiate a conversation with themselves. Validated at `ChatService::canInitiateDm()`. |
| BR-CHT-003 | A user cannot read, send, or search messages in any conversation they are not an active participant of. Enforced at every controller endpoint via a participant membership check. |
| BR-CHT-004 | Soft-deleted messages show "This message was deleted" (sender delete) or "Removed by Admin" (moderation delete). The `body` column is cleared to NULL on soft-delete; only the `is_deleted` flag and `deleted_by` remain. |
| BR-CHT-005 | A group cannot be left without an admin. The last admin must transfer ownership before leaving; otherwise, the system auto-promotes the longest-tenured active member. |
| BR-CHT-006 | Muted conversations produce no unread count increments and no notifications. The participant can still read and send messages. |
| BR-CHT-007 | Parent can only initiate a DM to a teacher if that teacher is currently assigned to the class-section where the parent's child is actively enrolled. Checked at `ChatService::canInitiateDm()` via cross-module read (no FK). |
| BR-CHT-008 | Student-to-student DMs are disabled by default. Enabled via `cht_settings.allow_student_to_student = 1`. |
| BR-CHT-009 | All message-send, message-load, and mark-read endpoints return JSON (AJAX-only). No full page reloads within the chat UI. |
| BR-CHT-010 | Attachment file size validated server-side against `cht_settings.max_attachment_size_mb`. MIME type validated against the allowed list (not just file extension). |
| BR-CHT-011 | `cht_conversations.last_message_at` and `last_message_preview` are updated atomically within a `DB::transaction()` on every message store. |
| BR-CHT-012 | `cht_participants.unread_count` is decremented to 0 when the participant opens the conversation (calls the mark-read endpoint). It is incremented by 1 for each new message received in non-muted conversations. |
| BR-CHT-013 | A participant who has left a group (`left_at IS NOT NULL`) cannot send or receive new messages until re-added by an admin. |
| BR-CHT-014 | Announcement threads (`conversation_type = 'announcement'`) are read-only for all participants except the creator and other designated admins. Enforced at the controller with a Gate policy check. |
| BR-CHT-015 | Pinned conversations: maximum 5 per user. Attempting to pin a 6th returns HTTP 422 ("Unpin a conversation before pinning a new one"). |
| BR-CHT-016 | Reply depth is limited to 1 level. A message with a non-NULL `parent_message_id` cannot itself be a parent. Validated at FormRequest level. |

---

## 7. Integration with Other Modules

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| `sys_users` (tenant_db) | Direct FK | All `cht_participants.user_id`, `cht_messages.sender_id`, etc. reference `sys_users.id`. |
| `SchoolSetup` (`sch_class_section_jnt`, teacher assignments) | Read-only cross-module | Used to validate Parent → Teacher DM permission (BR-CHT-007). No FK constraint. Accessed via `ChatService`. |
| `StudentProfile` (`std_student_academic_sessions`, `std_student_guardian_jnt`) | Read-only cross-module | Used to find which teacher teaches a Parent's child, and to look up a Student's current class-section. No FK constraint. |
| `Notification` (`ntf_*`) | Event-driven | `NewChatMessage` event → `ProcessChatNotification` listener (queued) → `ntf_*` delivery chain (in-app + email). |
| `sys_activity_logs` | Write | Log moderation actions (message deletions by admin). |
| Spatie Media Library (`media` table) | Direct | Attachment storage and URL generation via `InteractsWithMedia` on `ChatConversation` model. |

---

## 8. Screen Inventory

| Screen ID | Screen Name | Route | Actors |
|-----------|-------------|-------|--------|
| SCR-CHT-01 | Chat Dashboard (Conversation List) | `GET /chat` | All users |
| SCR-CHT-02 | Direct Message View | `GET /chat/{conversation}` | DM participants |
| SCR-CHT-03 | Group Conversation View | `GET /chat/{conversation}` | Group members |
| SCR-CHT-04 | New Direct Message (User Picker) | `GET /chat/new/direct` | Authorised users |
| SCR-CHT-05 | New Group (Name + Members) | `GET /chat/new/group` | Authorised users (excl. Student, Parent) |
| SCR-CHT-06 | Group Info & Member Management | `GET /chat/{conversation}/info` | Group admins |
| SCR-CHT-07 | Message Search | `GET /chat/search` | All users |
| SCR-CHT-08 | Conversation Settings (mute, pin, archive) | `GET /chat/{conversation}/settings` | Participants |
| SCR-CHT-09 | Admin Moderation View | `GET /chat/admin/moderation` | Super Admin, Principal |
| SCR-CHT-10 | Announcement Composer | `GET /chat/announcements/new` | Admin roles |
| SCR-CHT-11 | Archived Conversations | `GET /chat/archived` | All users |
| SCR-CHT-12 | School Chat Settings | `GET /chat/admin/settings` | Super Admin |

---

## 9. Controller & Service Plan

| Class | Responsibility |
|-------|----------------|
| `ChatController` | Conversation list, conversation view, new conversation creation |
| `ChatMessageController` | Send message, delete message, fetch paginated messages, search |
| `ChatParticipantController` | Add/remove members, leave group, transfer admin |
| `ChatPresenceController` | Presence ping, typing indicator poll |
| `ChatModerationController` | Admin moderation view, admin message delete |
| `ChatSettingsController` | School-level settings, user-level settings |
| `ChatAnnouncementController` | Announcement creation and management |
| `ChatService` | DM pair creation, role-access validation (`canInitiateDm()`), last-message update (transaction), unread count management |
| `ChatNotificationService` | Dispatch `NewChatMessage` event, build notification payload |

---

## 10. Permissions Required

| Permission Key | Description |
|---------------|-------------|
| `tenant.chat.viewAny` | Access the chat module (all registered users have this by default) |
| `tenant.chat.create` | Start a new DM or group conversation |
| `tenant.chat.message` | Send messages within a conversation |
| `tenant.chat.broadcast` | Create announcement threads |
| `tenant.chat.moderate` | Access the admin moderation view; delete any message |
| `tenant.chat.settings` | Manage school-level `cht_settings` |

---

## 11. Out of Scope — Phase 1

- Video and audio calling
- Message reactions (emoji reactions)
- Message forwarding to another conversation
- Scheduled / delayed message sending
- End-to-end encryption
- Cross-tenant messaging (school-to-school)
- SMS or email fallback for offline recipients
- Mobile push notifications (FCM/APNs) — Phase-2
- WebSocket real-time (Laravel Echo + Pusher/Reverb) — Phase-2
- Message translation (multi-language)
- Bulk message import/export for compliance

---

## 12. Migration Plan

No existing tables need to be modified. All `cht_*` tables are new additions to `tenant_db` via a dedicated tenant migration file.

**Recommended migration file name:**
`database/migrations/tenant/2026_05_14_000001_create_cht_common_chat_tables.php`

**Seeder:**
`database/seeders/tenant/ChtSettingsSeeder.php` — Seeds a single `cht_settings` row with all defaults.
