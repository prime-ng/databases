# CommonChat Module — 2-Step Generation Prompt

> **Module:** CommonChat (Common Chat Functionality)
> **Proposed Table Prefix:** `cht_`
> **Scope:** Tenant-scoped (per-school isolated data in `tenant_db`)
> **Goal:** Standalone direct-messaging + group-chat system for ALL registered users (Students, Teachers, Employees, Admin, Parent) within a school tenant.
> **Prompt Created by:** Enterprise Architect Agent
> **Date:** 2026-05-14

---

## CONTEXT: Why This Module Exists

Two contextual chat systems already exist in the platform:
1. **StudentProfile** — `LeaveApplicationRemark` model with a chat-style UI (`_chat_item.blade.php`) for leave approval threads (student ↔ teacher, contextual only).
2. **SchoolSetup** — `EmployeeLeaveApplicationRemark` + `EmployeeLeaveApplicationRemarkController` for employee leave approval chat threads (employee ↔ approver, contextual only).

Both are **contextual** (tied to a specific leave application). Neither supports free direct messaging between any two users. CommonChat fills this gap — a standalone module where ANY registered user (regardless of role) can initiate a private 1:1 conversation or a group conversation with other school users.

---

## HOW TO USE THIS PROMPT

Copy everything below the `---BEGIN PROMPT---` marker into a NEW Claude conversation. Claude will read all required files and produce both Phase-1 and Phase-2 documents, saving them to the target folder.

---BEGIN PROMPT---

# Task: Generate CommonChat Module — Requirements + DDL Schema

You are acting as **DB Architect + Business Analyst** for the **Prime-AI Academic Intelligence Platform** — a multi-tenant SaaS for Indian K-12 schools (stancl/tenancy v3.9, Laravel 12, nwidart/laravel-modules v12).

## STEP 0 — Load Architecture Context First

Before doing anything else, read the following files to understand the platform:

```
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/config/paths.md
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/project-context.md
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/tenancy-map.md
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/conventions.md
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/decisions.md
Read: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/modules-map.md
```

Key facts to extract from these files:
- The 3-layer DB architecture (global_db / prime_db / tenant_db)
- Table prefix registry (to ensure `cht_` is not already taken)
- Multi-tenancy rules (all CommonChat data goes in `tenant_db`, never `prime_db`)
- Conventions: all tables need `created_at`, `updated_at`, `deleted_at`, `is_active`, `created_by`
- `sys_users` is the user table (both in prime_db for central and tenant_db for tenant scope)

---

## STEP 1 — Read Existing Chat Implementations (Reference Code)

Read these files to understand the chat-style UI and remark patterns ALREADY in use. CommonChat must follow the same conventions but extend them to a standalone system.

### 1A — StudentProfile Leave Remarks (Student chat pattern)

```
Read all files in: /Users/bkwork/Herd/prime_ai/Modules/StudentProfile/app/Models/
Read: /Users/bkwork/Herd/prime_ai/Modules/StudentProfile/resources/views/leave-management/leave-remarks/_chat_item.blade.php
```

Focus on:
- `LeaveApplicationRemark` model fields (message, remark_type, remarked_by, parent_remark_id, read_at, read_by, is_resolved)
- `LeaveApplicationDocument` model fields (how files are attached to a remark)
- How `is_from_teacher` drives left/right bubble alignment in the UI

### 1B — SchoolSetup Employee Leave Remarks (Employee/Approver chat pattern)

```
Read: /Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/app/Http/Controllers/EmployeeLeaveApplicationRemarkController.php
Read all files in: /Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/app/Models/
```

Focus on:
- `EmployeeLeaveApplicationRemark` model fields and relationships
- `getByApplication()` — how messages are fetched for a conversation thread (ordered by `created_at ASC`)
- `markAsRead()` — how bulk read-marking works (`read_at`, `read_by`)
- AJAX flow: `store()` returns JSON with remark + sender info for real-time append
- Auto-status-change pattern (how a message can trigger a state transition)
- Document upload on `store()` using Spatie Media Library

### 1C — SchoolSetup Module Structure

```
Read: /Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/routes/web.php
Read: /Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/app/Providers/SchoolSetupServiceProvider.php
```

Focus on: route prefix convention, Gate permission naming pattern (`tenant.{feature}.{action}`), standard CRUD route registration.

### 1D — StudentProfile Module Structure

```
Read: /Users/bkwork/Herd/prime_ai/Modules/StudentProfile/routes/web.php
Read: /Users/bkwork/Herd/prime_ai/Modules/StudentProfile/app/Providers/StudentProfileServiceProvider.php
```

Focus on: How the student-facing routes are registered and how permissions are gated.

---

## STEP 2 — Understand Users Who Will Use CommonChat

```
Read: /Users/bkwork/Herd/prime_ai/Modules/SchoolSetup/app/Models/Employee.php (or similar)
Read the sys_users-related section in /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/memory/project-context.md
```

From the project context, the tenant roles are:
- **Super Admin / Principal / Vice Principal** — Full admin users
- **Teacher** — Academic staff
- **Staff / Non-Teaching Staff** — Non-academic employees
- **Accountant / Librarian** — Functional roles
- **Parent** — Guardian with read-only school access
- **Student** — Learner

ALL of these user types use `sys_users` (tenant DB) as their base user record. CommonChat should allow any `sys_users` record to start or join a conversation.

---

## STEP 3 — Generate Phase-1: High Level Requirement Document

After reading all the above files, generate **Phase-1** as a markdown document. Save it to:

**Output Path:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/1-Sub-Modules/CommonChat/CHT_Requirements_v1.md`

### Phase-1 Document Structure

```markdown
# CommonChat Module — High Level Requirements (CHT)
**Version:** v1.0
**Date:** {today}
**Module Code:** CHT
**Table Prefix:** cht_
**Scope:** Tenant-scoped (tenant_db)
**Module Path:** Modules/CommonChat/

---

## 1. Module Purpose
[2–3 sentence summary of what this module does and why it exists as a standalone module separate from leave-remark threads]

## 2. Users & Actors
| Actor | Role in CommonChat | Can Initiate? | Can Receive? |
|-------|-------------------|---------------|--------------|
| Super Admin | ... | ... | ... |
| Principal | ... | ... | ... |
| Teacher | ... | ... | ... |
| Staff | ... | ... | ... |
| Accountant | ... | ... | ... |
| Librarian | ... | ... | ... |
| Parent | ... | ... | ... |
| Student | ... | ... | ... |

## 3. Core Feature Inventory

### F-CHT-01: Direct Messaging (1:1 Chat)
**Description:** Any two registered users can open a private conversation.
**Conditions:**
- Both users must be active (`sys_users.is_active = 1`) in the same tenant.
- A conversation between User A and User B is unique — only one DM conversation can exist between the same pair.
- Either participant can send a message at any time.
- Deleted conversations (soft-delete) are hidden from both parties.
- Messages sent before a user is deleted are retained in the other user's view.

### F-CHT-02: Group Chat
**Description:** Any user with appropriate permissions can create a named group conversation.
**Conditions:**
- Group creator is automatically added as admin/owner of the group.
- Group name is required; group description is optional.
- Minimum 2 participants (excluding creator). Maximum participants defined by school settings (default: 100).
- Any group admin can add or remove members.
- Group creator cannot be removed unless they transfer ownership.
- Group members can leave voluntarily (sets left_at timestamp).
- Group can be archived by admin (no new messages; read-only for all members).
- Group avatar upload supported (Spatie Media Library).

### F-CHT-03: Message Sending
**Description:** Authenticated users can send text, emoji, and file-attached messages.
**Conditions:**
- Message body must not be empty unless an attachment is present.
- Maximum message text length: 5,000 characters.
- Message body stored as plain text (no HTML to prevent XSS).
- Attachments supported: Images (jpg/png/gif/webp), Documents (pdf/doc/docx/xls/xlsx), max 10MB per file.
- Only 1 attachment per message (simplicity; multi-file can be Phase-2 enhancement).
- Sender cannot delete another user's message; sender can delete their own (soft-delete, shown as "Message deleted").
- Message timestamps stored in UTC; displayed in user's local timezone.

### F-CHT-04: Message Threading (Reply-to)
**Description:** A message can reference (reply to) an earlier message in the same conversation.
**Conditions:**
- `parent_message_id` references the original message in the same conversation.
- Deleted parent messages are still shown as a "Deleted message" stub in the reply context.
- A reply to a reply is NOT supported — reply depth is limited to 1 level.

### F-CHT-05: Read Receipts
**Description:** Senders see delivery and read status of their messages.
**Conditions:**
- A read receipt is created per message per recipient when the recipient opens the conversation.
- For group chats: message is "read" only when ALL non-sender members have read it.
- Read status shows count (e.g., "Read by 4 of 6") in group chats.
- Read status shows "Seen" with timestamp in DMs.

### F-CHT-06: Typing Indicators & Online Status
**Description:** Users see when another participant is typing and their online/offline status.
**Conditions:**
- Typing state is ephemeral (not stored in DB). Implementation via polling endpoint or future WebSocket upgrade.
- Online status updated via `cht_user_presence` table — last_seen_at timestamp updated on each API ping (30s interval).
- Users can disable their online status visibility (privacy setting in `cht_user_settings`).

### F-CHT-07: Message Search
**Description:** Users can search messages within a conversation.
**Conditions:**
- Full-text search on `cht_messages.body` within conversations the user belongs to.
- Results show message context (3 lines before/after) and conversation name.
- Cross-conversation search is NOT supported in Phase-1.

### F-CHT-08: Notifications
**Description:** Users receive in-app notifications for new messages in conversations they belong to.
**Conditions:**
- Notification is created in `ntf_*` tables (reuse existing Notification module) OR in `cht_*` unread counters.
- Notification shows sender name, conversation name, and message preview (first 80 characters).
- Message preview is NOT shown if sender's conversation is a private DM between protected roles (e.g., Principal ↔ Student).
- Users can mute a conversation — no notifications for muted conversations.

### F-CHT-09: Conversation Management
**Description:** Users can manage their conversation list.
**Conditions:**
- Users can pin up to 5 conversations (pin order maintained).
- Users can archive a conversation (hidden from main list; still searchable).
- Users can delete their copy of a DM conversation (soft-delete on their participant record; other user's copy unaffected).
- Conversation list is sorted by `last_message_at DESC` by default.

### F-CHT-10: Role-Based Access Control
**Description:** Certain roles have restrictions on who they can message.
**Conditions:**
- **Students** can message: Teachers, Admin — NOT directly message other Students unless allowed in school settings.
- **Parents** can message: Their child's Teachers (only teachers who teach their child's class/section), Admin — NOT other parents or students.
- **Teachers** can message: Any user in the tenant.
- **Admin roles** (Principal, Vice Principal, Super Admin) can message: Any user in the tenant.
- **Staff/Accountant/Librarian** can message: Any non-Student, non-Parent user (staff-to-staff + admin).
- School-level setting `cht_settings.allow_student_to_student` (default: OFF) overrides Student restriction.
- School-level setting `cht_settings.allow_parent_to_parent` (default: OFF) overrides Parent restriction.

### F-CHT-11: Announcements (One-Way Broadcast)
**Description:** Admin users can send a broadcast message to a class, section, or the whole school.
**Conditions:**
- Announcements create a system-generated group conversation (or dedicated announcement thread).
- Only the sender can post in an announcement thread. Recipients can only read.
- Announcement sender: Principal, Vice Principal, Super Admin, or users with `tenant.chat.broadcast` permission.
- Recipients receive an in-app notification.

### F-CHT-12: Message Moderation
**Description:** Admin can view and delete messages across all conversations.
**Conditions:**
- Only Super Admin / Principal can access conversation moderation view.
- Admin can soft-delete any message from any conversation.
- Moderation actions are logged in `sys_activity_logs`.
- Users whose messages were deleted see "Removed by Admin".

## 4. Non-Functional Requirements

| Requirement | Specification |
|-------------|---------------|
| **Performance** | Conversation list must load in < 1s. Messages within a conversation: paginate 50 per page. |
| **Scalability** | Support up to 500 concurrent users per tenant on polling-based implementation. |
| **Real-time** | Phase-1: Ajax polling every 5 seconds. Phase-2: Laravel Echo + Pusher/Reverb. |
| **Data Isolation** | All `cht_*` tables are in `tenant_db`. No cross-tenant message access is possible. |
| **Storage** | Attachments stored in `storage/tenant_{uuid}/chat-attachments/` via Spatie Media Library. |
| **Retention** | Messages are soft-deleted only. Hard delete requires explicit moderation action. |
| **Tenancy** | All queries MUST be scoped to current tenant (no global scopes needed — tenancy middleware handles DB switch). |
| **Security** | Participant check on EVERY message read/send endpoint. Users cannot read conversations they are not a member of. |
| **Compliance** | No chat message content stored in prime_db or global_db. |

## 5. Business Rules Summary

| Rule ID | Rule |
|---------|------|
| BR-CHT-001 | One DM conversation per user pair (enforce via UNIQUE generated column). |
| BR-CHT-002 | A user cannot send a message to themselves. |
| BR-CHT-003 | A user cannot read messages from conversations they are not a participant of (IDOR protection). |
| BR-CHT-004 | Deleted messages show "This message was deleted" placeholder — body is cleared, not physically deleted. |
| BR-CHT-005 | Group admins cannot remove the last admin from a group (must transfer ownership first). |
| BR-CHT-006 | Muted conversations do not appear in unread counts or notification badges. |
| BR-CHT-007 | Parent can only message teachers who currently teach a class/section that their linked child is enrolled in. |
| BR-CHT-008 | Student-to-student messaging is disabled by default (school setting gates this). |
| BR-CHT-009 | All message sends return JSON (AJAX only) — no full page reload on send. |
| BR-CHT-010 | Attachment file size limit: 10MB. Mime types validated server-side (not just extension). |
| BR-CHT-011 | Conversation `last_message_at` is updated atomically on every new message (DB transaction). |
| BR-CHT-012 | Unread count is per-user, per-conversation — stored in `cht_participants.unread_count`. |

## 6. Integration with Other Modules

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| sys_users (tenant_db) | Direct FK | All participants are sys_users records |
| SchoolSetup (sch_*) | Read-only reference | Teacher-class-section mapping for Parent→Teacher restriction (BR-CHT-007) |
| StudentProfile (std_*) | Read-only reference | Student enrollment to find child's teachers (Parent actor) |
| Notification (ntf_*) | Event-driven | Fire NotificationEvent on new message → ntf_ delivery chain |
| sys_activity_logs | Write | Log moderation actions (admin message delete) |
| Spatie Media Library | Direct | Attachment storage and URL generation |

## 7. Screens (UI Inventory)

| Screen ID | Screen Name | Actors |
|-----------|-------------|--------|
| SCR-CHT-01 | Chat Dashboard (Conversation List) | All users |
| SCR-CHT-02 | Direct Message Conversation View | Sender + Recipient |
| SCR-CHT-03 | Group Conversation View | Group members |
| SCR-CHT-04 | New Conversation / New Group | All users |
| SCR-CHT-05 | Group Info & Member Management | Group admins |
| SCR-CHT-06 | Search Messages | All users |
| SCR-CHT-07 | Conversation Settings (mute, pin, archive) | All users |
| SCR-CHT-08 | Admin Moderation View | Super Admin, Principal |
| SCR-CHT-09 | Announcement Broadcast Composer | Admin roles |
| SCR-CHT-10 | School Chat Settings | Super Admin |

## 8. Out of Scope (Phase-1)

- Video/audio calls
- Message reactions (emoji reactions)
- Message forwarding to another conversation
- Message scheduling (send later)
- End-to-end encryption
- Cross-tenant messaging (school-to-school)
- SMS/email fallback for offline users
- Mobile push notifications (Phase-2 via FCM/APNs)
- WebSocket real-time (Phase-2 via Laravel Echo + Pusher/Reverb)
```

---

## STEP 4 — Generate Phase-2: DDL Schema

After completing Phase-1, generate **Phase-2** as a SQL DDL file. Save it to:

**Output Path:** `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/1-Sub-Modules/CommonChat/CHT_DDL_v1.sql`

### Phase-2 DDL Requirements

Every table in this DDL MUST follow the platform's universal conventions:

**Standard Columns (on every table):**
```sql
`is_active`   TINYINT(1) NOT NULL DEFAULT 1,
`created_by`  BIGINT UNSIGNED NULL,
`updated_by`  BIGINT UNSIGNED NULL,
`created_at`  TIMESTAMP NULL DEFAULT NULL,
`updated_at`  TIMESTAMP NULL DEFAULT NULL,
`deleted_at`  TIMESTAMP NULL DEFAULT NULL
```

**Engine & Charset (all tables):**
```sql
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Index all foreign keys.** Prefix: `cht_`. All PKs: `BIGINT UNSIGNED AUTO_INCREMENT`.

### Tables to Design (minimum — expand as required)

Design the following tables. For each table, write:
1. A `-- PURPOSE:` comment explaining what the table does
2. A `-- FIELD:` comment on every non-obvious column explaining its meaning
3. All FK constraints with ON DELETE behavior
4. Required UNIQUE constraints (especially for conversation uniqueness)
5. Indexes on all columns used in WHERE clauses

**Required Tables:**

```
cht_conversations      — Header record for a conversation (DM or Group or Announcement)
cht_participants       — Who is in each conversation (per-user membership record)
cht_messages           — Individual messages within a conversation
cht_message_receipts   — Read receipts per message per recipient (for group read status)
cht_attachments        — File attachments linked to messages (Spatie media metadata)
cht_user_presence      — Last-seen timestamp per user (for online/offline status)
cht_user_settings      — Per-user chat preferences (online status visibility, notification prefs)
cht_settings           — School-level settings (student-to-student, parent-to-parent, etc.)
```

**Table Design Guidance:**

For `cht_conversations`:
- `conversation_type` ENUM: `direct`, `group`, `announcement`
- `name` — NULL for DMs (derived from other participant's name at query time); required for groups
- `description` — Group description; NULL for DMs
- `created_by` — User who created (for groups) or initiated (for DMs)
- `last_message_at` — Updated on every new message (index this — conversation list sorts by it)
- `last_message_preview` — First 100 chars of last message body (denormalized for performance; cleared if message deleted)
- `is_archived` TINYINT(1) — Admin archived flag (school-wide archive, not per-user)
- For DMs: enforce 1 conversation per pair via a STORED generated column `dm_pair_hash` = `CONCAT(LEAST(user_a_id, user_b_id), '_', GREATEST(user_a_id, user_b_id))` with UNIQUE index. Only populated for `direct` type conversations; NULL for groups.
- `user_a_id` / `user_b_id` — Only for `direct` type; NULL for groups.

For `cht_participants`:
- `conversation_id` FK → `cht_conversations.id`
- `user_id` FK → `sys_users.id`
- `role` ENUM: `member`, `admin` (only relevant for groups)
- `joined_at` TIMESTAMP — When user was added
- `left_at` TIMESTAMP NULL — When user voluntarily left (soft exit from group)
- `muted_until` TIMESTAMP NULL — NULL = not muted; FAR future date = muted indefinitely
- `is_pinned` TINYINT(1) DEFAULT 0 — User pinned this conversation
- `pin_order` TINYINT UNSIGNED NULL — 1-5, order of pins
- `unread_count` INT UNSIGNED DEFAULT 0 — Denormalized count; decremented on read
- `archived_at` TIMESTAMP NULL — Per-user archive (user hides from main list)
- UNIQUE: `(conversation_id, user_id)` — A user can only be in a conversation once

For `cht_messages`:
- `conversation_id` FK → `cht_conversations.id`
- `sender_id` FK → `sys_users.id`
- `parent_message_id` FK → `cht_messages.id` NULL (for reply-to; depth limited to 1)
- `body` TEXT — Message text (NULL if attachment-only message)
- `message_type` ENUM: `text`, `attachment`, `system` — system for auto-generated messages (e.g., "User joined", "Admin removed message")
- `is_deleted` TINYINT(1) DEFAULT 0 — Soft-delete flag; when 1, body is cleared, shown as "Message deleted"
- `deleted_by` BIGINT UNSIGNED NULL — Who deleted (sender vs admin)
- `deleted_at` TIMESTAMP NULL — When deleted
- Index: `(conversation_id, created_at)` — Messages fetched ordered by time within conversation

For `cht_message_receipts`:
- `message_id` FK → `cht_messages.id`
- `user_id` FK → `sys_users.id` (recipient who read it)
- `read_at` TIMESTAMP NULL — When message was read (NULL = unread)
- UNIQUE: `(message_id, user_id)`
- NO `deleted_at` on this table (immutable receipt log)

For `cht_attachments`:
- `message_id` FK → `cht_messages.id`
- `file_name` VARCHAR — Original filename
- `file_path` VARCHAR — Storage path
- `file_size` INT UNSIGNED — Bytes
- `mime_type` VARCHAR(100)
- `media_id` BIGINT UNSIGNED NULL — Spatie media library ID
- NO `deleted_at` (attachment removal handled by message soft-delete)

For `cht_user_presence`:
- `user_id` BIGINT UNSIGNED — FK to `sys_users.id`, also the PK (1 row per user)
- `last_seen_at` TIMESTAMP — Updated every 30s while user is active
- `is_online` TINYINT(1) — Computed: 1 if last_seen_at > (NOW() - 60 seconds)
- NO `deleted_at` (presence is always current state)
- PRIMARY KEY (`user_id`) — one row per user, upsert pattern

For `cht_user_settings`:
- `user_id` BIGINT UNSIGNED — FK to `sys_users.id`, also UNIQUE (1 row per user)
- `show_online_status` TINYINT(1) DEFAULT 1
- `notify_on_message` TINYINT(1) DEFAULT 1
- `notify_on_mention` TINYINT(1) DEFAULT 1
- `message_preview_in_notification` TINYINT(1) DEFAULT 1

For `cht_settings` (school-level):
- `id` BIGINT UNSIGNED PK
- `allow_student_to_student` TINYINT(1) DEFAULT 0 — Allow students to DM each other
- `allow_parent_to_parent` TINYINT(1) DEFAULT 0 — Allow parents to DM each other
- `allow_student_to_parent` TINYINT(1) DEFAULT 0 — Allow students to initiate DM to their own parent
- `max_group_members` SMALLINT UNSIGNED DEFAULT 100
- `max_attachment_size_mb` TINYINT UNSIGNED DEFAULT 10
- `retention_days` SMALLINT UNSIGNED DEFAULT 365 — Auto-purge old messages after N days (0 = never)
- UNIQUE: Only 1 row expected per tenant (use `id=1` always; no multi-row needed)

### DDL File Format

```sql
-- ============================================================
-- CommonChat Module (CHT) — Tenant DB Schema
-- Table Prefix: cht_
-- Scope: tenant_db (per-school isolated)
-- Version: v1.0
-- Date: {today}
-- ============================================================
-- SECTION 0: sys_dropdown_needs (if any ENUMs require seeding)
-- SECTION 1: cht_settings
-- SECTION 2: cht_user_settings
-- SECTION 3: cht_user_presence
-- SECTION 4: cht_conversations
-- SECTION 5: cht_participants
-- SECTION 6: cht_messages
-- SECTION 7: cht_message_receipts
-- SECTION 8: cht_attachments
-- ============================================================
```

Each table must use `DROP TABLE IF EXISTS` before `CREATE TABLE`.

---

## STEP 5 — Confirm Outputs

After generating both documents, confirm:

```
✅ Phase-1 saved: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/1-Sub-Modules/CommonChat/CHT_Requirements_v1.md
✅ Phase-2 saved: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/1-DDL_Tenant_Modules/2-SchoolSetup/1-Sub-Modules/CommonChat/CHT_DDL_v1.sql

Module: CommonChat (CHT)
Table Prefix: cht_
Tables Created: [list all table names]
Total Tables: [N]
Scope: tenant_db
Route Prefix (planned): /chat/*
```

---END PROMPT---

---

## Notes for Enterprise Architect Review

Before executing this prompt, verify:

1. **Prefix `cht_` is free** — not in `AI_Brain/agents/enterprise-architect.md` prefix registry. Confirmed: `cht_` does not appear in the registry.

2. **DM uniqueness** — The `dm_pair_hash` generated column pattern mirrors D-TMP-003 (scope_hash pattern). Ensure MySQL 5.7+ or 8.0 is confirmed before using STORED generated columns.

3. **Cross-module read** — CommonChat reads `std_*` (StudentProfile) and `sch_*` (SchoolSetup) for role-based contact restrictions. This is **read-only** — no FK constraints across modules. Enforced at Service layer, not DB layer.

4. **No WebSocket DDL needed** — Typing indicators and real-time presence are stateless (polling-based in Phase-1). No DB tables required for these features yet.

5. **Notification integration** — BR-CHT-006 (muted conversations) means CommonChat must either integrate with `ntf_*` tables OR manage its own mute flags in `cht_participants.muted_until`. The prompt opts for `cht_participants` to avoid hard coupling to Notification module.
