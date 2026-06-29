# CommonChat (COM) — Complete Functional Requirements & Analysis Pack
**Module:** CommonChat | **Code:** COM | **Table prefix:** `cht_` | **Date:** 2026-06-29
**Sources read:** Live code `Modules/CommonChat/` (15 controllers, `ChatService` 559 LOC, 9 models, 4 policies, 5 FormRequests, 19 views, 2 seeders, 1 scheduled command), 9 tenant migrations `2026_06_16_1007xx_create_cht_*`, consolidated DDL `Sch_CommonChat_DDL_v1.sql`, V1 screen specs `CommonChat_v2/tab-1..tab-10`, AI_Brain agent + module-knowledge `COM_CommonChat.md`.
**Register:** Business language in Sections 1–9 & 11–18; technical register confined to Section 5.x technical view, Section 13 (dependency map) and Section 19 (gap analysis).

> **Scope clarification (load-bearing):** This module is *CommonChat* — real-time, in-app, person-to-person
> and group chat between a school's own users. It is **not** a broadcast/SMS/email/WhatsApp/circular engine;
> any such "Communication (`com_`)" broadcast module is out of scope and does not exist in code.
> **Multi-tenant:** all data lives in `tenant_db` and is isolated per school — there is no cross-school
> chat and no `tenant_id` column.

---

## Section 0 — Index / Table of Contents
1. Module Overview (purpose, value, scope, terminology)
2. User Roles & Access (actors, role-feature matrix)
3. Functional Requirements (REQ-COM-001 … 022)
4. Business Rules Register (BR-COM-001 … 030)
5. Data Requirements (business entities + technical data dictionary)
6. Workflows (with exception paths + notifications)
7. Reporting & Analytics (RPT-COM-001 … 005)
8. Future Enhancement Log (ENH-COM-001 …)
9. Non-Functional Requirements
10. Gap Analysis Readiness Index (coverage contract for downstream audits)
11. Requirements Traceability Matrix (RTM)
12. Requirement Conditions & Validation / Edge-Case Catalog
13. Cross-Module Dependency Map
14. State Machine (FSM) Catalog
15. Risk Register
16. Prioritization (MoSCoW)
17. Effort Estimation & Sprint Task Breakdown
18. User Stories (Gherkin, P0/P1)
19. Requirements-vs-Code Gap Analysis (BA-side)

---

## Section 1 — Module Overview

### 1.1 Purpose
CommonChat gives every authorised member of a school — staff, teachers, students and parents — a private,
in-app messaging space. Users hold one-to-one (direct) conversations, participate in named group chats, and
receive one-way announcement threads, all governed by school-defined rules about *who is allowed to talk to
whom*. It keeps school communication inside the platform (auditable, moderated, retention-controlled) rather
than on personal phones and third-party apps.

### 1.2 Business Value
- **Safe, controlled communication channel** — the school decides which roles may message which roles
  (e.g. parents may only reach their child's teachers), with per-user overrides for exceptions.
- **Accountability & child-safety** — every conversation is school-owned, admins can moderate and remove
  messages, and an audit trail records moderation actions.
- **Reduced reliance on personal messaging apps** for teacher–parent and staff coordination.
- **Operational hygiene** — configurable message retention auto-purges old chat data.

### 1.3 Scope

**In scope**
- Conversation dashboard (list, unread badges, pin, archive, search).
- Direct (1:1) conversations with one-conversation-per-pair guarantee.
- Group conversations with admins, membership management, and ownership transfer.
- Announcement threads (one-way broadcast within chat).
- Message composing, reply threading (one level), and soft-delete.
- File/image attachments on messages.
- Read receipts, message status and unread counts.
- Message search across the user's own conversations.
- Per-conversation mute and per-user pin/archive.
- Per-user notification & privacy personalisation.
- Online/offline presence.
- School-level chat configuration and role-pair permission matrix (with user overrides).
- Admin moderation console and activity/audit log.
- Message retention auto-purge.
- Mobile chat API.

**Out of scope (≥3, explicit)**
- Mass broadcast / campaign messaging over **SMS, email, WhatsApp** (no `com_*` broadcast module exists).
- School **circulars / notice board / acknowledgement tracking** (separate document module).
- **Emergency mass-alert** dispatch with multi-channel fan-out.
- Voice/video **calling** (only file attachments of audio/video are configurable, not live calls).
- **Cross-school / inter-tenant** chat.
- External chat federation (no integration with parents' personal WhatsApp/Telegram).

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Conversation | A chat container; one of three types — Direct, Group, or Announcement. |
| Direct Message (DM) | A private 1:1 conversation; exactly one can exist per pair of users. |
| Group | A named, multi-member conversation with one or more administrators. |
| Announcement | A one-way conversation where only admins post and members read. |
| Participant | A user's membership record in a conversation, carrying that user's personal state (unread count, mute, pin, archive, role). |
| Read Receipt | A record that a specific recipient has read a specific message, with a timestamp. |
| Unread Count | A running badge of unread messages per user per conversation. |
| Mute | A per-user, per-conversation setting that suppresses notifications and unread increments. |
| Pin | A per-user marker that floats a conversation to the top of the dashboard (max 5). |
| Per-user Archive vs School Archive | User-archive hides a conversation for one user; school-archive makes a group read-only for everyone. |
| Permission Config | The school-defined matrix of which role may message which role, and with what capabilities. |
| Retention Purge | The scheduled removal of messages older than the school's retention period. |
| Presence | A user's online/offline state, derived from a recent heartbeat. |

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| Super Admin | Full chat administration: configures settings, permission matrix, moderates, views audit log; can message anyone. |
| Principal / Vice-Principal | Senior staff; broad messaging reach; may moderate / view activity log (per `tenant.chat.moderate`). |
| Teacher | Can create groups/announcements and message students, parents and staff per the permission matrix. |
| Office / Support Staff (accountant, librarian, etc.) | Can message staff and senior roles; limited reach to students/parents. |
| Student | Can message teachers and senior staff; student-to-student only if the school enables it. |
| Parent | Can message senior staff and only the teacher(s) assigned to their child's class-section. |
| System (scheduler) | Runs the daily retention purge; (intended) dispatches notifications. |

### 2.2 Role–Feature Matrix
| Feature | Super Admin | Principal | Teacher | Staff | Student | Parent |
|---------|:-:|:-:|:-:|:-:|:-:|:-:|
| Start a Direct message | All | All | Per matrix | Staff/seniors | Teachers/seniors (+student if enabled) | Seniors + own child's teacher |
| Create Group | Yes | Yes | Yes | Config | No (default) | No (default) |
| Create Announcement | Yes | Yes | Yes | Config | No | No |
| Send message / attachment | Yes | Yes | Yes | Yes | Yes | Yes |
| Reply / pin / mute / archive (own view) | Yes | Yes | Yes | Yes | Yes | Yes |
| Manage group membership / transfer admin | If group admin | If group admin | If group admin | If group admin | If group admin | If group admin |
| Soft-delete own message | Yes | Yes | Yes | Yes | Yes | Yes |
| Moderate (delete any message) | Yes (`tenant.chat.moderate`) | Yes | No | No | No | No |
| View activity / audit log | Yes (`tenant.chat.moderate`) | Yes | No | No | No | No |
| Configure chat settings | Yes (`tenant.chat.settings`) | No | No | No | No | No |
| Manage permission config | Yes (`tenant.chat-permission-config.*`) | No | No | No | No | No |

> Membership-based actions (view a conversation, send within it) are granted *implicitly* by an active
> participant record (`left_at IS NULL`), not by a named permission.

---

## Section 3 — Functional Requirements

> Format per requirement: ID · Priority · Tags · Description · Actors · BRs · Acceptance Criteria · Integration · Enhancement notes. Priorities: Core (P0) / Standard (P1) / Enhanced (P2).

### REQ-COM-001 — Chat Dashboard / Conversation List
**Priority:** Core (P0) · **Tags:** [DASHBOARD][DATA_ENTRY]
**Description:** Every user sees a single scrollable list of the conversations they actively participate in, newest activity first, with the other party's name (DM) or group name, last-message preview, time, and unread badge. Pinned conversations float to the top; per-user-archived and left conversations are excluded.
**Actors:** Initiates — any user; Views — same user.
**Business Rules:** BR-COM-001, BR-COM-002, BR-COM-003, BR-COM-026.
**Acceptance Criteria:**
- Given a user with conversations, when they open the dashboard, then conversations appear sorted by last activity, pinned ones first.
- Given a conversation with ≥10 unread, then the badge shows "9+".
- Given a per-user-archived or left conversation, then it does not appear in the main list.
- Given a non-participant, when they request another user's conversations, then access is refused.
- Given no conversations, then a friendly empty-state prompt is shown. List paginates 20 per page.
**Integration:** `sys_users` for DM display names.
**Enhancement notes:** real-time push of new rows (ENH-COM-001).

### REQ-COM-002 — Direct (1:1) Messaging
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW][PERMISSION]
**Description:** A user starts or reopens a private conversation with exactly one other allowed user; the system enforces one DM per pair and applies role-pair permission rules before allowing initiation.
**Actors:** Initiates — any user (subject to matrix); Views — both participants.
**Business Rules:** BR-COM-004, BR-COM-005, BR-COM-006, BR-COM-007, BR-COM-013.
**Acceptance Criteria:**
- Given an existing DM between A and B, when A starts a chat with B, then the existing conversation opens (no duplicate created).
- Given a self-recipient, then initiation is refused.
- Given an inactive recipient account, then initiation is refused.
- Given a student to another student where the school disables student-to-student chat, then initiation is refused.
- Given a parent and a teacher NOT assigned to the parent's child's class-section, then initiation is refused.
**Integration:** `sys_users`, `sys_roles`, StudentProfile/SchoolSetup for parent-teacher gating.
**Enhancement notes:** —

### REQ-COM-003 — Group Conversations
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW][PERMISSION]
**Description:** Authorised users create a named group (name required, optional description/avatar), selecting at least two other members; the creator becomes the first admin. Members chat; admins manage the group.
**Actors:** Initiates — Teacher/Principal/Super Admin; Views — members.
**Business Rules:** BR-COM-008, BR-COM-009, BR-COM-010, BR-COM-027.
**Acceptance Criteria:**
- Given fewer than two additional members selected, then creation is refused with "at least 3 members".
- Given a member count at the school maximum, then no further members can be added.
- Given a student or parent, then group creation is refused.
- Given a created group, then the creator's participant role is Admin and a member row exists for each selected member.
**Integration:** `cht_settings.max_group_members`, Spatie Media for avatar.
**Enhancement notes:** group system messages on lifecycle events (ENH-COM-004).

### REQ-COM-004 — Group Membership Management
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][PERMISSION][APPROVAL]
**Description:** Group admins add/remove members, rename/redescribe the group, transfer admin ownership, and archive/unarchive; any member may voluntarily leave. The creator cannot be removed until ownership is transferred; if the last admin leaves, the longest-tenured active member is auto-promoted.
**Actors:** Initiates — group admin (or any member for "leave"); Views — members.
**Business Rules:** BR-COM-010, BR-COM-011, BR-COM-012, BR-COM-029.
**Acceptance Criteria:**
- Given the creator with no other admin, when removal is attempted, then it is refused until ownership is transferred.
- Given the last admin leaves, then the longest-tenured active member becomes admin.
- Given a removed/left member re-added by an admin, then their prior message history remains visible.
- Given a non-admin, when they attempt add/remove, then the action is refused.
**Integration:** `cht_participants`.
**Enhancement notes:** system message per event (ENH-COM-004).

### REQ-COM-005 — Announcement Threads (one-way)
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY][WORKFLOW][PERMISSION]
**Description:** Authorised users create a named announcement conversation where only admins post and all other members read — a school-internal broadcast within chat.
**Actors:** Initiates — Teacher/Principal/Super Admin; Views — members.
**Business Rules:** BR-COM-009, BR-COM-014.
**Acceptance Criteria:**
- Given an announcement, when a non-admin member attempts to post, then the post is refused.
- Given an announcement, then its `name` is required (cannot be NULL).
- Given an authorised admin, when they post, then all members receive the message and unread increments.
**Integration:** `cht_conversations` (type Announcement).
**Enhancement notes:** —

### REQ-COM-006 — Message Composer (Send + Reply Threading)
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
**Description:** Within a conversation, a user composes and sends a text message (≤5,000 chars), optionally replying to one earlier top-level message. Sending requires either body text or an attachment. Sends use AJAX without page reload.
**Actors:** Initiates — active participant; Views — all participants.
**Business Rules:** BR-COM-015, BR-COM-016, BR-COM-017, BR-COM-018, BR-COM-019, BR-COM-020.
**Acceptance Criteria:**
- Given an empty body and no attachment, then send is refused.
- Given a body over 5,000 characters, then send is refused.
- Given a reply whose parent is itself a reply, then send is refused (only one nesting level). *(GAP-COM-002: not yet enforced.)*
- Given a reply whose parent belongs to a different conversation, then send is refused.
- Given an archived conversation, then send is refused.
- Given a non-participant, then send is refused.
**Integration:** `cht_messages`, `cht_participants` (membership), `cht_conversations.is_archived`.
**Enhancement notes:** rich text / mentions indexing (ENH-COM-005).

### REQ-COM-007 — File & Media Attachments
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
**Description:** A user attaches a single image or document to a message. Allowed types: JPEG, PNG, GIF, WebP, PDF, DOC, DOCX, XLS, XLSX. Size limited by school settings. Images show inline previews (with thumbnail); documents show file cards. File access is restricted to conversation participants.
**Actors:** Initiates — active participant (with `can_send_attachment`); Views — participants.
**Business Rules:** BR-COM-021, BR-COM-022, BR-COM-023.
**Acceptance Criteria:**
- Given a disallowed file type, then upload is refused.
- Given a file exceeding the school's max attachment size, then upload is refused. *(GAP-COM-007: size currently hardcoded 10 MB; allow-list not enforced.)*
- Given a soft-deleted message, then its attachment URL is no longer served (metadata row retained).
- Given a non-participant hitting the file URL directly, then access is refused.
- Given Phase 1, then only one attachment per message is accepted.
**Integration:** Spatie Media Library; `cht_settings.max_file_attachment_size_mb`.
**Enhancement notes:** multiple attachments per message (ENH-COM-006).

### REQ-COM-008 — Read Receipts & Message Status
**Priority:** Core (P0) · **Tags:** [WORKFLOW][REPORT]
**Description:** On send, the system creates one receipt per non-sender active participant (initially unread). When a recipient opens the conversation, their receipts are marked read with a timestamp. Senders see "Seen at {time}" (DM) or "Read by X of Y members" (group). Read tracking continues even when display is disabled.
**Actors:** Initiates — system (on send) / recipient (on open); Views — sender.
**Business Rules:** BR-COM-024, BR-COM-025, BR-COM-028.
**Acceptance Criteria:**
- Given a sent message, then one unread receipt exists per non-sender active participant.
- Given a recipient opens the conversation, then their unread receipts for it become read.
- Given a user who disabled read-receipt display, then their reads are still recorded but not shown to others.
- Given a group, then the sender sees "Read by X of Y" where Y excludes the sender.
**Integration:** `cht_message_receipts`, `cht_personalization_settings`, `cht_settings`.
**Enhancement notes:** —

### REQ-COM-009 — Unread Count & Mark-as-Read
**Priority:** Core (P0) · **Tags:** [WORKFLOW]
**Description:** Each participant carries a denormalised unread counter incremented on each new message in a non-muted conversation, and reset to zero when the user opens/marks the conversation read — within a single transaction alongside receipt updates.
**Actors:** Initiates — system / user; Views — user.
**Business Rules:** BR-COM-024, BR-COM-028.
**Acceptance Criteria:**
- Given a new message in a non-muted conversation, then each recipient's unread count increases by one.
- Given a muted conversation, then the unread count does not increase.
- Given mark-as-read, then the unread count becomes zero and receipts are timestamped in the same transaction.
**Integration:** `cht_participants.unread_count`.
**Enhancement notes:** —

### REQ-COM-010 — Message Search & History
**Priority:** Standard (P1) · **Tags:** [REPORT][DATA_ENTRY]
**Description:** A user searches message text across all conversations they actively participate in (min 2 chars), seeing matches with surrounding context and the ability to jump to the message. Deleted messages are excluded; results are capped.
**Actors:** Initiates/Views — searching user.
**Business Rules:** BR-COM-030.
**Acceptance Criteria:**
- Given a query under 2 characters, then search is not triggered.
- Given results, then only conversations where the user is an active participant are searched.
- Given deleted messages, then they are excluded from results.
- Given more matches than the cap (50), then the user is asked to refine.
**Integration:** `cht_messages`, `cht_participants` (membership gate).
**Enhancement notes:** full-text index / attachment search (ENH-COM-007).

### REQ-COM-011 — Mute / Pin / Archive (Per-User)
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][CONFIGURATION]
**Description:** A user mutes a conversation (timed or permanent), pins up to five conversations, and archives/unarchives conversations for their own view only — none of which affect other participants.
**Actors:** Initiates/Views — the user.
**Business Rules:** BR-COM-002, BR-COM-026, BR-COM-028.
**Acceptance Criteria:**
- Given a user with 5 pinned conversations, when they pin a sixth, then the action is refused.
- Given a muted conversation, then notifications and unread increments are suppressed but messages remain readable/sendable.
- Given a per-user archive, then the conversation is hidden only for that user.
**Integration:** `cht_participants` (`muted_until`, `is_pinned`, `pin_order`, `archived_at`).
**Enhancement notes:** —

### REQ-COM-012 — Notifications & Alerts (NTF Integration)
**Priority:** Standard (P1) · **Tags:** [NOTIFICATION][INTEGRATION]
**Description:** On a new message (or @mention) in a non-muted conversation, the system raises an in-app notification through the school Notification module, honouring each user's notification preferences and privacy (message-preview suppression). If Notification is unavailable, the system degrades to unread-count-only.
**Actors:** Initiates — system; Views — recipient.
**Business Rules:** BR-COM-028, BR-COM-024.
**Acceptance Criteria:**
- Given a non-muted new message and a recipient with notifications enabled, then a notification is delivered. *(GAP-COM-004: not implemented.)*
- Given a recipient who disabled message preview, then the notification shows no body text.
- Given the Notification module unavailable, then the unread count still updates and no error surfaces.
- Given a muted conversation, then no notification is sent.
**Integration:** Notification (NTF) module.
**Enhancement notes:** @mention parsing/indexing (ENH-COM-005).

### REQ-COM-013 — Online/Offline Presence
**Priority:** Standard (P1) · **Tags:** [WORKFLOW]
**Description:** The client sends a periodic heartbeat; the system records each user's last-seen time and derives an online indicator. Users who disable "show online status" always appear offline to others.
**Actors:** Initiates — user client; Views — other participants.
**Business Rules:** BR-COM-031 (presence), BR-COM-015 privacy via personalisation.
**Acceptance Criteria:**
- Given a heartbeat within the online threshold, then the user shows online.
- Given no heartbeat beyond the threshold, then the user shows offline.
- Given a user who disabled online-status display, then they appear offline regardless of heartbeat.
**Integration:** `cht_user_presence`.
**Enhancement notes:** typing indicator (ENH-COM-008).

### REQ-COM-014 — Message Soft-Delete (Sender & Admin)
**Priority:** Core (P0) · **Tags:** [WORKFLOW][PERMISSION]
**Description:** A sender deletes their own message; an admin (moderator) deletes any message. Deletion clears the body, flags the message deleted, records who deleted it, and retains the row for thread integrity. The UI distinguishes "This message was deleted" (sender) from "Removed by Admin".
**Actors:** Initiates — sender or moderator; Views — participants.
**Business Rules:** BR-COM-019, BR-COM-032.
**Acceptance Criteria:**
- Given a non-sender, non-admin user, when they attempt to delete a message, then it is refused.
- Given a soft-deleted message, then its body is cleared and the row is retained with the deleter recorded.
- Given an admin deletion, then a moderation audit entry is recorded. *(GAP-COM-003: audit write not implemented.)*
**Integration:** `cht_messages` (`is_deleted`, `deleted_by`); `sys_activity_logs` (intended).
**Enhancement notes:** —

### REQ-COM-015 — Personalization & Privacy Settings
**Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
**Description:** Each user manages their own chat preferences: notifications on/off, mention notifications, message-preview-in-notification, online-status visibility, and read-receipt display. Settings are created lazily on first chat access from school defaults.
**Actors:** Initiates/Views — the user.
**Business Rules:** BR-COM-015, BR-COM-028.
**Acceptance Criteria:**
- Given a first-time chat user, then a personalisation row is created from school defaults.
- Given a user who disables notifications, then no chat notifications reach them (others unaffected).
- Given read-receipt display disabled, then the user neither shows their reads nor sees others'.
**Integration:** `cht_personalization_settings`, `cht_settings` defaults.
**Enhancement notes:** —

### REQ-COM-016 — School Chat Configuration
**Priority:** Core (P0) · **Tags:** [CONFIGURATION]
**Description:** A Super Admin configures school-wide chat behaviour in a single settings record: max group size (hard cap 500), attachment size limits (file/audio/video), message-retention days, default user preferences, and global capability defaults. Saves overwrite the single record (no version history).
**Actors:** Initiates/Views — Super Admin (`tenant.chat.settings`).
**Business Rules:** BR-COM-033, BR-COM-034, BR-COM-035.
**Acceptance Criteria:**
- Given a max-group-members value over 500, then it is rejected/clamped.
- Given retention days = 0, then auto-purge is disabled.
- Given a save, then exactly one settings record is updated (never inserted twice).
- Given a non-admin, then the settings screen is inaccessible.
**Integration:** `cht_settings`.
**Enhancement notes:** —

### REQ-COM-017 — Permission Configuration (Role-Pair Matrix + User Override)
**Priority:** Core (P0) · **Tags:** [CONFIGURATION][PERMISSION]
**Description:** A Super Admin defines, per source-role → target-role pair, which capabilities are allowed (text, attachment, audio, video, URL, emoji, create group, create announcement, "message anyone", read receipts). User-specific overrides supersede role rules. Rules can be toggled active/inactive, soft-deleted, restored, and force-deleted.
**Actors:** Initiates/Views — Super Admin (`tenant.chat-permission-config.*`).
**Business Rules:** BR-COM-006, BR-COM-007, BR-COM-036.
**Acceptance Criteria:**
- Given a duplicate (source-role, user, target-role) rule, then creation is refused.
- Given a user-specific override and a role rule for the same source, then the override wins.
- Given `can_message_anyone`, then all other restrictions for that role/user are bypassed.
- Given a rule set inactive, then it is retained but not evaluated.
**Integration:** `cht_permission_config`, `sys_roles`, `sys_users`.
**Enhancement notes:** reconcile role display-name vs short_name (GAP-COM-005).

### REQ-COM-018 — Admin Moderation Console
**Priority:** Standard (P1) · **Tags:** [WORKFLOW][PERMISSION][DASHBOARD]
**Description:** Moderators view recently-deleted messages (last 7 days), high-volume conversations (last 24h), and a searchable conversation list, and can remove any message as a moderation action.
**Actors:** Initiates/Views — Super Admin / Principal (`tenant.chat.moderate`).
**Business Rules:** BR-COM-032, BR-COM-037.
**Acceptance Criteria:**
- Given a non-moderator, then the moderation console is inaccessible.
- Given an admin removal, then the message is soft-deleted as "Removed by Admin".
- Given the console, then recently-deleted and high-volume conversations are listed.
**Integration:** `cht_messages`, `cht_conversations`.
**Enhancement notes:** message flagging by users (ENH-COM-009).

### REQ-COM-019 — Activity Log & Audit Trail
**Priority:** Standard (P1) · **Tags:** [REPORT][INTEGRATION]
**Description:** Moderators review an append-only, immutable log of moderation/admin events (admin delete, group created/archived/renamed, member added/removed, admin transferred, retention purge), filterable by date/user/action. For admin deletes the original body is never stored — only a SHA-256 hash.
**Actors:** Initiates — system on each event; Views — moderators.
**Business Rules:** BR-COM-037, BR-COM-038.
**Acceptance Criteria:**
- Given a moderation or group-admin event, then an immutable audit entry is recorded with actor, action and timestamp. *(GAP-COM-003: writes not implemented.)*
- Given an admin delete, then only a SHA-256 hash of the original body is stored (not the text).
- Given any user, then audit entries cannot be edited or deleted.
**Integration:** `sys_activity_logs`.
**Enhancement notes:** —

### REQ-COM-020 — Message Retention Auto-Purge
**Priority:** Standard (P1) · **Tags:** [SCHEDULED]
**Description:** A daily scheduled job hard-deletes messages older than the school's retention period (0 = never), cascading receipts and attachments, and (intended) records a purge audit entry with counts.
**Actors:** Initiates — scheduler; Views — moderators (via audit log).
**Business Rules:** BR-COM-039.
**Acceptance Criteria:**
- Given retention = 0, then the job runs but purges nothing.
- Given retention = N days, then messages older than N days are hard-deleted with receipts/attachments cascaded.
- Given a purge run, then an audit entry records the count purged. *(GAP-COM-003.)*
**Integration:** `cht_settings.message_retention_days`, `cht_messages`.
**Enhancement notes:** —

### REQ-COM-021 — Mobile Chat API
**Priority:** Standard (P1) · **Tags:** [INTEGRATION]
**Description:** Authenticated mobile clients access chat over a dedicated API: dashboard overview, conversation list/detail/create, pin/mute/archive/leave, message list/send/read/delete, message & user search, and presence (ping/typing/online).
**Actors:** Initiates/Views — authenticated mobile user (Sanctum).
**Business Rules:** Inherits all messaging/permission BRs.
**Acceptance Criteria:**
- Given an unauthenticated request, then access is refused.
- Given an authenticated user, then they may only act on conversations they participate in.
- Given the mobile endpoints, then behaviour matches the web service layer (shared `ChatService`).
**Integration:** Sanctum auth; `Mobile/*` controllers.
**Enhancement notes:** push delivery via NTF (REQ-COM-012).

### REQ-COM-022 — Admin Chat Access Revocation
**Priority:** Standard (P1) · **Tags:** [PERMISSION][CONFIGURATION]
**Description:** An admin can deactivate a specific user's chat access, blocking all send and receive while preserving their conversation history for audit.
**Actors:** Initiates — Super Admin; Views — the affected user (read-only history).
**Business Rules:** BR-COM-040.
**Acceptance Criteria:**
- Given a user flagged deactivated, when they attempt to send/receive, then it is blocked. *(GAP-COM-010: enforcement guard missing.)*
- Given deactivation, then existing history remains visible.
**Integration:** `cht_personalization_settings.is_deactivated_by_admin`.
**Enhancement notes:** —

---

## Section 4 — Business Rules Register

| BR ID | Rule (business statement) | Type | Trigger | Enforcement point | Priority |
|-------|---------------------------|------|---------|-------------------|----------|
| BR-COM-001 | Conversation list is sorted by most-recent activity, newest first. | Workflow | Dashboard load | Conversation list service | P0 |
| BR-COM-002 | Pinned conversations float to top (max 5 per user), ordered by pin position; per-user-archived and left conversations are excluded from the main list. | Workflow | Dashboard load / pin | Service | P0 |
| BR-COM-003 | Unread badge hidden at zero; shows "9+" at ten or more. | Workflow | Dashboard render | Client formatting | P1 |
| BR-COM-004 | Exactly one Direct conversation may exist per pair of users. | Concurrency | DM create | DB unique index on `dm_pair_hash` (contended resource = the user-pair) + service pre-check | P0 |
| BR-COM-005 | A user cannot start a conversation with themselves. | Validation | DM create | `ChatService::canInitiateDm` | P0 |
| BR-COM-006 | A user may only initiate a DM with a role they are permitted to message; permission resolves user-override → role-pair → school default. | Permission | DM create | `ChatService::checkPermissionConfig` | P0 |
| BR-COM-007 | `can_message_anyone` at any resolution tier bypasses all role-pair restrictions for that role/user. | Permission | DM create / send | Service | P0 |
| BR-COM-008 | A group requires at least 3 members at creation (creator + 2). | Validation | Group create | `ChatService::createGroup` | P0 |
| BR-COM-009 | Group/Announcement name must not be NULL; Direct name must be NULL. | Validation | Conversation create | DB CHECK constraint | P0 |
| BR-COM-010 | Group cannot exceed the school's max members (hard cap 500). | Validation | Add member | `ChatService` (see GAP-COM-008 off-by-one) | P1 |
| BR-COM-011 | The group creator cannot be removed until ownership is transferred to another member. | Workflow | Remove member | `ChatService::removeParticipant` | P1 |
| BR-COM-012 | If the last admin leaves, the longest-tenured active member is auto-promoted to admin. | Workflow | Leave group | `ChatService::leaveGroup` | P1 |
| BR-COM-013 | Both users must be active (`sys_users.is_active`) to exchange new DMs; history remains visible if one becomes inactive. | Validation | DM create / send | Service | P0 |
| BR-COM-014 | Only admins may post in an Announcement conversation; other members read only. | Permission | Send | Service / policy | P1 |
| BR-COM-015 | Message body is stored as plain text only; HTML is not allowed (XSS prevention). | Validation | Send | FormRequest / sanitisation | P0 |
| BR-COM-016 | Message body max length is 5,000 characters. | Validation | Send | `StoreMessageRequest` | P0 |
| BR-COM-017 | A message must have body text OR an attachment (not both empty). | Validation | Send | `StoreMessageRequest::withValidator` | P0 |
| BR-COM-018 | A reply's parent must belong to the same conversation. | Validation | Send (reply) | Service / FormRequest | P0 |
| BR-COM-019 | Reply depth is capped at one level — a reply to a reply is rejected. | Validation | Send (reply) | **Intended; not yet enforced (GAP-COM-002)** | P0 |
| BR-COM-020 | Messages cannot be sent to an archived (school-level) conversation. | Workflow | Send | `ChatService::sendMessage` | P0 |
| BR-COM-021 | Attachment file types are limited to JPEG, PNG, GIF, WebP, PDF, DOC, DOCX, XLS, XLSX, validated by content. | Validation | Upload | FormRequest (GAP-COM-007: allow-list not enforced) | P1 |
| BR-COM-022 | Attachment size must not exceed the school's configured limit. | Validation | Upload | FormRequest (GAP-COM-007: hardcoded 10 MB) | P1 |
| BR-COM-023 | Phase 1 allows only one attachment per message. | Validation | Upload | Service / client | P1 |
| BR-COM-024 | Unread count increments only for non-muted recipients; muting suppresses notifications + unread, never read tracking. | Workflow | Send / mute | `ChatService::sendMessage` (`isMuted()` check) | P0 |
| BR-COM-025 | On send, one read receipt is created per non-sender active participant, initially unread. | Workflow | Send | `ChatService::sendMessage` | P0 |
| BR-COM-026 | A user who has left a group (or per-user-archived) does not see that conversation in the main list. | Workflow | Dashboard / list | Service query filters | P1 |
| BR-COM-027 | Students and parents cannot create groups or announcements (default). | Permission | Group/announcement create | Policy / permission config | P0 |
| BR-COM-028 | Mark-as-read sets all the user's unread receipts for the conversation to read AND resets unread count to zero, in one transaction. | Concurrency | Conversation open | `ChatService::markAsRead` (contended = unread counter) | P0 |
| BR-COM-029 | A re-added member retains visibility of prior message history. | Workflow | Add member | `ChatService::addParticipant` (reactivates trashed row) | P1 |
| BR-COM-030 | Search returns only conversations where the requester is an active participant; deleted messages excluded; min 2 chars; capped at 50 results. | Permission/Validation | Search | `ChatMessageController::search` | P1 |
| BR-COM-031 | A user is "online" only if their last heartbeat is within the online threshold (~60s). | Calculation | Presence read | Presence query (online = `last_seen_at > now − 60s`) | P1 |
| BR-COM-032 | Only the message sender or a moderator may delete a message; deletion clears body, retains row, records deleter. | Permission | Delete | `ChatService::deleteMessage` | P0 |
| BR-COM-033 | `cht_settings` holds exactly one row per school; saves overwrite, never insert a second. | Validation | Settings save | `id=1` PK pattern + `firstOrCreate` | P0 |
| BR-COM-034 | Max group members cannot exceed the hard upper bound of 500. | Validation | Settings save | Settings FormRequest | P0 |
| BR-COM-035 | Retention days = 0 means keep messages indefinitely. | Workflow | Settings save / purge | Settings + purge job | P0 |
| BR-COM-036 | A permission rule is unique on (source-role, user, target-role). | Validation | Permission rule create | DB unique index | P0 |
| BR-COM-037 | Only users with chat-moderate permission may view the activity log / moderation console; entries are immutable. | Permission | Console / log access | Policy (`moderate`) | P1 |
| BR-COM-038 | Admin-delete audit stores only a SHA-256 hash of the original body, never the text. | Workflow | Admin delete | Intended (GAP-COM-003) | P1 |
| BR-COM-039 | Retention purge hard-deletes messages older than the period, cascading receipts and attachments. | Workflow | Daily schedule | `chat:purge-old-messages` | P1 |
| BR-COM-040 | A user flagged `is_deactivated_by_admin` is blocked from sending and receiving while history is preserved. | Permission | Send / receive | Intended (GAP-COM-010) | P1 |

---

## Section 5 — Data Requirements

### 5.1 Business Entities (business view)
| Entity | Meaning | Key business attributes | Privacy |
|--------|---------|--------------------------|---------|
| Conversation | A chat container (Direct / Group / Announcement). | Type, name (group/announcement), description, avatar, last activity, last preview, school-archived flag. | Internal |
| Participant | A user's membership in a conversation and their personal state. | Role (Admin/Member), joined/left, mute-until, pinned + order, unread count, archived-at. | Confidential (per-user state) |
| Message | A single message within a conversation. | Body (plain text), type (Text/Attachment/System), reply-to, deleted flag + deleter, sent time. | Confidential (Sensitive if minors involved) |
| Attachment | File metadata for an attached file. | File name, size, type, storage path, thumbnail. | Confidential |
| Read Receipt | Whether/when a recipient read a message. | Read time. | Confidential |
| User Presence | A user's last-seen heartbeat. | Last-seen time, device type. | Internal |
| Personalisation Setting | A user's own chat preferences/privacy. | Notify on message/mention, preview, online-status visibility, read-receipt display, admin-deactivated. | Confidential |
| Chat Setting (School) | The school's single chat configuration record. | Max group size, attachment limits, retention days, default preferences, capability defaults. | Internal |
| Permission Rule | A role-pair (or user-override) capability rule. | Source role, optional user, target role, capability flags, active. | Internal |

### 5.2 Technical Data Dictionary (technical register — live schema, 9 tables)
> Layer/PK/columns verified from migrations `2026_06_16_1007xx`. Full column detail in `COM_CommonChat.md`.

| Table | PK | Key FKs | Soft-delete | Notable / anomalies |
|-------|----|---------|-------------|---------------------|
| `cht_settings` | `id` TINYINT default 1 (singleton) | — | No | One row per tenant; `message_retention_days` 0=forever; hard cap 500 for group size (app-enforced). |
| `cht_permission_config` | `id` INT | role/user/allowed → sys_roles/sys_users | Yes | UNIQUE(role,user,allowed); `is_active` toggle. |
| `cht_personalization_settings` | `id` INT | role_id, user_id | Yes | Has `created_by`, NO `updated_by`; `is_deactivated_by_admin`. |
| `cht_user_presence` | `user_id` (no surrogate) | user_id → sys_users | No | Upsert/heartbeat; `device_type`; ephemeral. |
| `cht_conversations` | `id` BIGINT | user_a/user_b/created_by/updated_by → sys_users | Yes | `dm_pair_hash` **VIRTUAL** generated + UNIQUE; CHECK on name-by-type; composite UNIQUE(created_by,type,name,deleted_at). |
| `cht_participants` | `id` BIGINT | conversation_id, user_id | Yes | UNIQUE(conversation,user); carries all per-user state; `role` ENUM(Admin,Member). |
| `cht_messages` | `id` BIGINT | conversation_id, sender_id, parent_message_id (self), deleted_by | Yes | `message_type` ENUM(Attachment,System,Text) — **invalid default 'text' (GAP-COM-006)**; soft-delete clears `body`. |
| `cht_attachments` | `id` BIGINT | message_id (cascade) | **No** | `is_active`, `created_by`, `updated_by`; follows message lifecycle. |
| `cht_message_receipts` | `id` BIGINT | message_id, user_id | **No** | HAS `created_at`/`updated_at`, NO `created_by`/`updated_by`; UNIQUE(message,user); append/update-`read_at` only. |

**Tenant isolation:** all tables in `tenant_db`; no `tenant_id` column; cross-school access impossible.
**Academic-year scoping:** chat data is **not** academic-year scoped (messages persist across sessions); the
only year-aware logic is parent-teacher DM gating, which resolves the *current* session to find the child's class-section.

---

## Section 6 — Workflows

### Workflow 1 — Start a Direct Message
- **Trigger:** User picks a recipient. **End states:** existing DM opened / new DM created / refused.
- **Swimlanes:** User | System.
- **Steps:** 1. User selects recipient → 2. System checks self/active/permission (BR-COM-005/006/007/013) → 3. Decision: existing DM? → open it; else create conversation + 2 participant rows in a transaction (BR-COM-004).
- **Exception paths:** self-recipient, inactive recipient, permission denied → refusal message; concurrent duplicate create → DB unique index blocks the second.
- **Notifications:** first message triggers recipient notification (REQ-COM-012, intended).

### Workflow 2 — Send a Message
- **Trigger:** User submits composer. **End states:** message stored / refused.
- **Steps:** 1. Validate body-or-attachment, length, reply integrity (BR-COM-015..020) → 2. Verify active participant + conversation not archived → 3. Insert message; update conversation last-activity/preview; fan-out receipts; increment unread for non-muted recipients — all in one transaction (BR-COM-024/025).
- **Exception paths:** empty/oversize body, archived conversation, non-participant, reply-to-reply (intended), cross-conversation reply → refusal.
- **Notifications:** new-message / @mention notification to non-muted recipients (intended).

### Workflow 3 — Mark Conversation Read
- **Trigger:** User opens a conversation. **Steps:** bulk-set user's NULL receipts to read + reset unread count to zero (one transaction, BR-COM-028). **Exception:** non-participant → no-op.

### Workflow 4 — Group Lifecycle (create → manage → archive/leave)
- **Trigger:** Admin/teacher creates group. **Steps:** create (min 3, BR-COM-008), add/remove members, transfer ownership, auto-promote on last-admin-leave (BR-COM-011/012), archive (read-only).
- **Exception paths:** remove-creator-without-transfer refused; non-admin manage refused; archived-group send refused.
- **Notifications/side-effects:** group system messages (intended, ENH-COM-004); audit entries (intended).

### Workflow 5 — Moderation & Audit
- **Trigger:** Moderator removes a message. **Steps:** soft-delete as "Removed by Admin"; write audit entry with SHA-256 body hash (intended, BR-COM-038). **Exception:** non-moderator → refused.

### Workflow 6 — Retention Purge (scheduled)
- **Trigger:** Daily scheduler. **Steps:** if retention>0, hard-delete messages older than the period; cascade receipts/attachments; write purge audit (intended). **Exception:** retention=0 → no-op.

---

## Section 7 — Reporting & Analytics

| RPT ID | Purpose | Audience | Frequency | Contents | Filters | Export |
|--------|---------|----------|-----------|----------|---------|--------|
| RPT-COM-001 | Recently-deleted (moderated) messages | Moderators | On demand | Deleted messages last 7 days: conversation, sender, deleter, time | Date range | Screen (PDF/CSV future) |
| RPT-COM-002 | High-volume conversations | Moderators | On demand | Conversations with ≥50 messages in last 24h | Time window | Screen |
| RPT-COM-003 | Read-receipt summary (group message) | Message sender | Live | "Read by X of Y", with per-recipient read times | Per message | Screen |
| RPT-COM-004 | Retention purge log | Moderators | Per run | Messages purged, conversations affected | Date | Audit log |
| RPT-COM-005 | Moderation / activity audit export | Super Admin / Principal | On demand | Action, actor, subject, time; body hash for deletes | Date / user / action | Audit log (CSV future) |

**KPIs (operational):** active conversations/day; messages/day; average unread backlog; moderation actions/month; % messages with attachments. (No analytics dashboard built yet — Enhanced.)

---

## Section 8 — Future Enhancement Log

| ENH ID | Enhancement | Rationale |
|--------|-------------|-----------|
| ENH-COM-001 | Real-time delivery via WebSocket (replace 30s polling). | Lower latency, true live chat. |
| ENH-COM-002 | Automated test suite (Pest) for messaging/permission/purge. | Currently zero coverage (GAP-COM-001). |
| ENH-COM-003 | Notification integration with NTF + graceful degradation. | REQ-COM-012 currently unimplemented. |
| ENH-COM-004 | System messages for group join/leave/admin-transfer/rename/archive. | V1 tab-3 expectation. |
| ENH-COM-005 | @mention parsing, highlighting and indexing. | Mention notifications + search. |
| ENH-COM-006 | Multiple attachments per message. | Phase-1 limited to one. |
| ENH-COM-007 | Full-text search index / attachment-name search. | LIKE search won't scale. |
| ENH-COM-008 | Persistent typing indicator. | Setting exists; backing incomplete. |
| ENH-COM-009 | User-initiated message flagging for moderation. | Moderation currently admin-pull only. |
| ENH-COM-010 | Communication analytics dashboard + scheduled report exports. | KPI visibility. |

---

## Section 9 — Non-Functional Requirements

### 9.1 Performance
- NFR-COM-001: Conversation list and message pages load ≤2s under typical school load (paginate 20 conversations / 50 messages).
- NFR-COM-002: Message send returns ≤1s; receipt fan-out for large groups uses a single batch insert.
- NFR-COM-003: Presence heartbeat is lightweight (single upsert by `user_id`) and tolerates a ~30s cadence.

### 9.2 Security
- NFR-COM-004: All data is tenant-isolated (`tenant_db`); cross-school chat and file access are impossible.
- NFR-COM-005: Message bodies are plain-text only; HTML is escaped/stripped (XSS prevention).
- NFR-COM-006: Attachment URLs are authorised by conversation membership; direct unauthenticated access is refused.
- NFR-COM-007: Mobile API requires Sanctum authentication; every action re-checks participant membership.
- NFR-COM-008: Moderation audit is append-only and immutable; deleted message bodies are never retained (hash only).

### 9.3 Usability
- NFR-COM-009: All message operations are AJAX (no full page reload); empty states are friendly and actionable.
- NFR-COM-010: Unread badges, pin order and read status are consistent across web and mobile (shared service layer).

### 9.4 Scalability / Availability
- NFR-COM-011: `cht_message_receipts` is the highest-volume table; group sends batch-insert receipts.
- NFR-COM-012: Retention purge runs off-peak (daily) and degrades gracefully when disabled (retention=0).
- NFR-COM-013: When the Notification module is unavailable, chat continues to function (unread-count fallback).

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Coverage table (downstream contract — Yes/No flags)
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|---|---|---|---|---|---|---|---|---|
| REQ-COM-001 | Chat dashboard | P0 | DASHBOARD | Yes | Yes | Yes | No | Yes |
| REQ-COM-002 | Direct messaging | P0 | WORKFLOW/PERM | Yes | Yes | Yes | Yes | Yes |
| REQ-COM-003 | Group conversations | P0 | WORKFLOW/PERM | Yes | Yes | Yes | No | Yes |
| REQ-COM-004 | Group membership mgmt | P1 | WORKFLOW/APPROVAL | Yes | Yes | Yes | No | Yes |
| REQ-COM-005 | Announcement threads | P1 | WORKFLOW/PERM | Yes | Yes | Yes | Yes | Yes |
| REQ-COM-006 | Composer + reply | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-COM-007 | Attachments | P1 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-COM-008 | Read receipts | P0 | WORKFLOW/REPORT | Yes | Yes | Yes | No | Yes |
| REQ-COM-009 | Unread + mark-read | P0 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-COM-010 | Search & history | P1 | REPORT | No | Yes | Yes | No | Yes |
| REQ-COM-011 | Mute/pin/archive | P1 | WORKFLOW/CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-COM-012 | Notifications (NTF) | P1 | NOTIFICATION/INTEGRATION | No | No | No | Yes | Yes |
| REQ-COM-013 | Presence | P1 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-COM-014 | Soft-delete | P0 | WORKFLOW/PERM | Yes | Yes | Yes | No | Yes |
| REQ-COM-015 | Personalisation | P1 | CONFIGURATION | Yes | Yes | Yes | No | Yes |
| REQ-COM-016 | School configuration | P0 | CONFIGURATION | Yes | Yes | No | No | Yes |
| REQ-COM-017 | Permission config | P0 | CONFIG/PERM | Yes | Yes | No | No | Yes |
| REQ-COM-018 | Moderation console | P1 | WORKFLOW/DASHBOARD | Yes | Yes | No | No | Yes |
| REQ-COM-019 | Activity/audit log | P1 | REPORT/INTEGRATION | Yes (sys_activity_logs) | Yes | No | No | Yes |
| REQ-COM-020 | Retention purge | P1 | SCHEDULED | Yes | No | No | No | Yes |
| REQ-COM-021 | Mobile API | P1 | INTEGRATION | No | No | Yes | Yes | Yes |
| REQ-COM-022 | Chat access revocation | P1 | PERMISSION | Yes | Yes | No | No | Yes |

### 10.2 BR coverage
30 numbered rules effectively (BR-COM-001 … BR-COM-040 with the IDs assigned above; the catalog uses 40 stable IDs of which the active set is enumerated in Section 4). Types: Validation 14, Workflow 13, Permission 9, Concurrency 2, Calculation 1.

### 10.3 Report coverage
RPT-COM-001 … RPT-COM-005 (5 reports). RPT-001/002/004/005 depend on moderation/audit data (REQ-COM-018/019); RPT-003 is live read-receipt aggregation.

### 10.4 Totals (reconciled)
- **Requirements (REQ):** 22 — **P0 = 9** (001,002,003,006,008,009,014,016,017) · **P1 = 13** (004,005,007,010,011,012,013,015,018,019,020,021,022) · P2 = 0.
- **Business Rules (BR):** 40 stable IDs; Section 4 enumerates BR-COM-001…040.
- **Reports (RPT):** 5.
- **Enhancements (ENH):** 10.
- **Workflows:** 6. · **FSMs:** 6 (Section 14). · **NFRs:** 13. · **Risks:** 8.

---

## Section 11 — Requirements Traceability Matrix (RTM)

| REQ-ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code Status | Gap |
|--------|---------|---------|-----------|----------|-----------|-------------|-----|
| REQ-COM-001 | Dashboard | 001,002,003,026 | conversations, index | WF1 | — | DONE | — |
| REQ-COM-002 | DM | 004,005,006,007,013 | create-direct, show | WF1 | — | DONE | role-name mismatch (GAP-005) |
| REQ-COM-003 | Group | 008,009,010,027 | create-group, show | WF4 | — | DONE | off-by-one (GAP-008) |
| REQ-COM-004 | Membership | 010,011,012,029 | info | WF4 | — | PARTIAL | no system msgs (GAP-009) |
| REQ-COM-005 | Announcement | 009,014 | create-announcement | WF4 | — | PARTIAL | post-restriction thin |
| REQ-COM-006 | Composer | 015-020 | show | WF2 | — | PARTIAL | reply-depth (GAP-002) |
| REQ-COM-007 | Attachments | 021,022,023 | show | WF2 | — | PARTIAL | validation/persist (GAP-007) |
| REQ-COM-008 | Receipts | 024,025,028 | show | WF2,WF3 | RPT-003 | DONE | — |
| REQ-COM-009 | Unread/mark-read | 024,028 | show | WF3 | — | DONE | — |
| REQ-COM-010 | Search | 030 | (search) | — | — | DONE | LIKE only (GAP-012) |
| REQ-COM-011 | Mute/pin/archive | 002,026,028 | show, archived | — | — | DONE | — |
| REQ-COM-012 | Notifications | 024,028 | — | WF2 | — | NOT STARTED | GAP-004 |
| REQ-COM-013 | Presence | 031,015 | — | — | — | DONE | typing (GAP-013) |
| REQ-COM-014 | Soft-delete | 019,032 | show, moderation | WF5 | — | DONE | no audit (GAP-003) |
| REQ-COM-015 | Personalisation | 015,028 | personalization | — | — | DONE | — |
| REQ-COM-016 | Settings | 033,034,035 | settings, settings-tab | — | — | DONE | — |
| REQ-COM-017 | Permission config | 006,007,036 | permission-config/* | — | — | DONE | GAP-005 |
| REQ-COM-018 | Moderation | 032,037 | moderation/index | WF5 | RPT-001,002 | PARTIAL | flagging (ENH-009) |
| REQ-COM-019 | Audit log | 037,038 | (activity) | WF5 | RPT-005 | NOT STARTED | GAP-003 |
| REQ-COM-020 | Retention purge | 039 | — | WF6 | RPT-004 | DONE | audit write (GAP-003) |
| REQ-COM-021 | Mobile API | (inherits) | — | WF1,2,3 | — | DONE | push (GAP-004) |
| REQ-COM-022 | Access revocation | 040 | personalization | — | — | PARTIAL | enforcement (GAP-010) |

---

## Section 12 — Requirement Conditions & Validation / Edge-Case Catalog
> Reuses BR-COM IDs. Canonical copy may also populate `5-Requirement_Conditions/CommonChat_Conditions.md`.

| Condition (=BR) | Field/Operation | Valid | Invalid | Boundary | Empty/Null | Concurrency | Expected behaviour |
|---|---|---|---|---|---|---|---|
| BR-COM-004 | DM create | new pair | duplicate pair | — | — | two simultaneous creates for same pair | second blocked by unique index; open existing |
| BR-COM-005 | DM recipient | other user | self | — | — | — | refuse self |
| BR-COM-008 | Group size | 3+ members | 1-2 | exactly 3 | none selected | — | refuse below 3 |
| BR-COM-010/034 | Max members | ≤ school max | > max | exactly max (GAP-008) | — | concurrent adds near cap | refuse over limit |
| BR-COM-016 | Body length | ≤5000 | >5000 | 5000 | empty (need attachment) | — | refuse over 5000 / empty-without-file |
| BR-COM-017 | Body or attachment | text only / file only / both | neither | — | both empty | — | refuse if both empty |
| BR-COM-019 | Reply depth | reply to top-level | reply to reply | — | — | — | refuse reply-to-reply (GAP-002) |
| BR-COM-018 | Reply scope | same conversation | different conversation | — | — | — | refuse cross-conversation reply |
| BR-COM-020 | Archived send | active conversation | school-archived | — | — | — | refuse send to archived |
| BR-COM-021/022 | Attachment | allowed type ≤ size | disallowed type / oversize | exactly size limit | no file | — | refuse (GAP-007) |
| BR-COM-002 | Pin | ≤5 pins | 6th pin | exactly 5 | — | concurrent pins | refuse 6th |
| BR-COM-028 | Mark-read | participant opens | non-participant | — | no unread | concurrent send + read | transaction-safe reset to 0 |
| BR-COM-033 | Settings row | update existing | second insert | — | — | concurrent saves | single row, last-write-wins |
| BR-COM-036 | Permission rule | unique triple | duplicate triple | — | — | — | refuse duplicate |
| BR-COM-040 | Deactivated user | active user | deactivated send/receive | — | — | — | block (GAP-010) |

---

## Section 13 — Cross-Module Dependency Map (technical register)

**Inbound (CommonChat reads from):**
| Source module | Data/Entity | Why |
|---------------|-------------|-----|
| System (SYS) | `sys_users` | sender/participant identity, active check, audit actors |
| System (SYS) | `sys_roles` | role-pair permission config; `short_name` in `canInitiateDm` |
| StudentProfile | `std_student_guardian_jnt` | resolve parent → child |
| SchoolSetup | `sch_academic_sessions`, `std_student_academic_sessions`, `sch_class_section_jnt` | resolve teacher of parent's child (current session) for DM gating |
| Spatie Media Library | media table (logical) | group avatar + attachment thumbnails |

**Outbound (CommonChat feeds / should feed):**
| Target module | Mechanism | What | Status |
|---------------|-----------|------|--------|
| Notification (NTF) | event/service | new-message / @mention push | NOT wired (GAP-COM-004) |
| System (SYS) | `sys_activity_logs` | moderation + purge audit (with body hash) | NOT wired (GAP-COM-003) |
| Student/Parent portals | read `cht_*` | embedded chat UI | consumer-side |

---

## Section 14 — State Machine (FSM) Catalog

1. **Message** — `Active` → (sender/admin delete) → `Deleted` (body cleared, row retained) → (retention job) → `Purged` (hard-deleted, cascades). Terminal: Purged. Illegal: un-delete.
2. **Conversation (school archive)** — `Active` ⇄ `Archived` (read-only school-wide; admin only).
3. **Participant membership** — `Active (left_at NULL)` → (leave/remove) → `Left` → (re-added by admin) → `Active` (history preserved). 
4. **Participant role** — `Member` → (admin grant / auto-promote) → `Admin`; `Admin` → (transfer/demote) → `Member`.
5. **Mute** — `Unmuted (muted_until NULL)` → `Muted (future ts)` / `Permanent (9999-12-31)` → `Unmuted`. (Expiry not auto-cleared; evaluated by comparison.)
6. **Read receipt** — `Unread (read_at NULL)` → `Read (read_at set)`. Immutable; never reverts.

> States are driven by columns, not a status master (no `*_dynamic_status_master` for this module).

---

## Section 15 — Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Mitigation | Owner |
|---------|------|----------|:-:|:-:|-----------|-------|
| RISK-COM-001 | Zero automated tests → regressions in core messaging | Quality | H | H | Build Pest suite (ENH-COM-002) before further features | Testing Architect |
| RISK-COM-002 | Reply-depth cap unenforced → unbounded nesting / UI breakage | Functional | M | M | Add guard in FormRequest + service (GAP-COM-002) | Backend Dev |
| RISK-COM-003 | No moderation audit / body-hash → compliance & dispute exposure (child safety) | Compliance | M | H | Implement `sys_activity_logs` writes with SHA-256 (GAP-COM-003) | Backend Dev |
| RISK-COM-004 | Notification integration missing → users miss messages | UX | H | M | Wire NTF with graceful fallback (GAP-COM-004) | Backend Dev |
| RISK-COM-005 | Role display-name vs short_name mismatch → wrong permission outcomes | Security | M | H | Reconcile seeder and service to one canonical key (GAP-COM-005) | DB Architect + Backend |
| RISK-COM-006 | Attachment validation gaps → malicious/oversize uploads | Security | M | H | Enforce MIME allow-list + per-setting size + content sniffing (GAP-COM-007) | Backend Dev |
| RISK-COM-007 | `is_deactivated_by_admin` not enforced → revoked users still chat | Security | M | M | Add send/receive guard (GAP-COM-010) | Backend Dev |
| RISK-COM-008 | LIKE search at scale → slow queries on large message volumes | Performance | M | M | FULLTEXT index / search service (ENH-COM-007) | DB Architect |

---

## Section 16 — Prioritization (MoSCoW)

- **Must (P0):** REQ-COM-001, 002, 003, 006, 008, 009, 014, 016, 017 — core chat + governance.
- **Should (P1):** REQ-COM-004, 005, 007, 010, 011, 013, 015, 018, 020, 021, 022 — membership, attachments, search, moderation, retention, mobile.
- **Should/now-gap:** REQ-COM-012 (notifications), 019 (audit) — high value, currently unbuilt.
- **Could (P2):** analytics dashboard, typing indicator, multi-attachment (tracked as ENH).
- **Won't (this release):** broadcast SMS/email/WhatsApp/circulars/emergency alerts (out of scope).

---

## Section 17 — Effort Estimation & Sprint Task Breakdown

| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|:-:|-----------|--------|
| 1 | Pest test suite: DM uniqueness, permission matrix, receipt fan-out, mark-read, purge | Testing | 24 | live code | S1 |
| 2 | Enforce reply-depth cap (FormRequest + service) | Backend | 4 | — | S1 |
| 3 | Reconcile role display-name vs short_name (seeder ↔ service, single canonical key) | Backend/Schema | 8 | sys_roles | S1 |
| 4 | Fix `cht_messages.message_type` column default | Schema | 2 | migration | S1 |
| 5 | Attachment hardening: MIME allow-list, per-setting size, content sniff, `cht_attachments` persistence | Backend | 16 | Spatie | S2 |
| 6 | Group max-member off-by-one fix + group system messages | Backend | 8 | — | S2 |
| 7 | Enforce `is_deactivated_by_admin` in send/receive guard | Backend | 4 | policy | S2 |
| 8 | Moderation audit writes to `sys_activity_logs` + SHA-256 body hash; back REQ-COM-019 screen | Backend/Integration | 16 | sys_activity_logs | S2 |
| 9 | NTF notification integration (new-message/@mention) + graceful fallback | Integration | 20 | NTF module | S3 |
| 10 | Activity-log screen + filters + RPT-005 export | Frontend/Report | 14 | task 8 | S3 |
| 11 | Retention purge audit entry (counts) | Backend | 4 | task 8 | S3 |
| 12 | Resolve/remove `api.php` `commonchats` stub | Backend | 3 | — | S3 |
> Estimation basis: comparable to mid-size tenant modules; assumes schema/migrations already live (they are). +N hours if NTF prerequisites are not ready.

---

## Section 18 — User Stories (Gherkin) — P0/P1

**US-COM-001 (REQ-COM-002, P0)** — As a *teacher*, I want to start a direct message with a parent so that I can discuss their child privately.
- Scenario happy: Given I am allowed to message the parent, When I open a chat with them, Then a conversation opens (existing if one exists).
- Scenario boundary: Given a DM already exists, When I start again, Then the existing conversation opens (no duplicate).
- Scenario permission-denied: Given a parent whose child is not in my class, When I try, Then access is refused.
- Scenario empty-state: Given no prior messages, Then the conversation shows an empty thread with a composer.
- DoD: unique-pair enforced; permission evaluated; receipt fan-out works; (notification fired — pending GAP-004).

**US-COM-002 (REQ-COM-003, P0)** — As a *teacher*, I want to create a group so that I can coordinate with a set of parents/students.
- Happy: Given ≥2 members selected, When I create, Then I become admin and members are added.
- Boundary: Given exactly 2 others, Then creation succeeds (3 total).
- Invalid: Given <2 others, Then refused.
- Permission-denied: Given I am a student, Then group creation is refused.
- DoD: creator=Admin; member rows created; max-size respected.

**US-COM-003 (REQ-COM-006, P0)** — As a *user*, I want to send and reply to messages so that I can converse.
- Happy: Given body text, When I send, Then it appears and recipients get unread+receipt.
- Boundary: Given a 5000-char body, Then it sends; 5001 is refused.
- Invalid: Given empty body and no file, Then send is refused.
- Permission-denied: Given an archived conversation, Then send is refused.
- Empty-state: Given a reply to a deleted parent, Then the reply context shows "Deleted message".
- DoD: reply same-conversation; reply-depth=1 (pending GAP-002).

**US-COM-004 (REQ-COM-008, P0)** — As a *sender*, I want to see who read my message so that I know it landed.
- Happy: Given a recipient opens the conversation, Then my message shows "Seen" / "Read by X of Y".
- Boundary: Given a group, Then Y excludes me.
- Permission/privacy: Given a recipient who disabled receipts, Then their read is tracked but not shown.
- DoD: receipts created on send; mark-read transactional.

**US-COM-005 (REQ-COM-014, P0)** — As an *admin*, I want to remove an inappropriate message so that the school stays safe.
- Happy: Given a flagged message, When I delete it, Then it shows "Removed by Admin".
- Permission-denied: Given a non-moderator, Then deletion is refused.
- DoD: body cleared, deleter recorded; (audit entry with hash — pending GAP-003).

**US-COM-006 (REQ-COM-016/017, P0)** — As a *Super Admin*, I want to set who can message whom so that communication stays appropriate.
- Happy: Given a role-pair rule, When I save, Then it governs new conversations.
- Boundary: Given max-group >500, Then it is rejected.
- Invalid: Given a duplicate rule triple, Then refused.
- DoD: single settings row; override > role > default; `can_message_anyone` short-circuits.

**US-COM-007 (REQ-COM-011, P1)** — As a *user*, I want to mute/pin/archive conversations so that I control my dashboard.
- Happy: pin floats to top; mute stops notifications/unread; archive hides for me only.
- Boundary: Given 5 pins, Then a 6th is refused.
- DoD: per-user only; others unaffected.

**US-COM-008 (REQ-COM-010, P1)** — As a *user*, I want to search my message history so that I can find past discussions.
- Happy: Given ≥2 chars, Then matches from my active conversations show with context.
- Invalid: Given <2 chars, Then no search runs.
- Permission: Given a conversation I left, Then it is excluded.
- DoD: deleted messages excluded; capped at 50.

**US-COM-009 (REQ-COM-004, P1)** — As a *group admin*, I want to manage membership and transfer ownership so that the group stays well-run.
- Happy: add/remove members; transfer admin.
- Boundary: Given I am the creator with no other admin, Then I cannot be removed until I transfer.
- Workflow: Given the last admin leaves, Then the longest-tenured member is promoted.
- DoD: re-added members see prior history.

**US-COM-010 (REQ-COM-012, P1)** — As a *recipient*, I want a notification on new messages so that I don't miss them. *(Pending GAP-COM-004.)*
- Happy: Given a non-muted new message and notifications on, Then I get a notification.
- Privacy: Given preview disabled, Then no body text shows.
- Resilience: Given Notification module down, Then unread still updates, no error.

---

## Section 19 — Requirements-vs-Code Gap Analysis (BA-side)

| REQ ref | Requirement | Code Status | Evidence | Gap |
|---------|-------------|-------------|----------|-----|
| REQ-COM-001 | Dashboard | DONE | `ChatService::getConversationsForUser` (pin/archive/left filters, paginate 20) | — |
| REQ-COM-002 | DM | DONE | `createDm`/`canInitiateDm`/`checkPermissionConfig` | GAP-COM-005 role-name |
| REQ-COM-003 | Group | DONE | `createGroup` (min 2 others, creator=Admin) | GAP-COM-008 off-by-one |
| REQ-COM-004 | Membership | PARTIAL | add/remove/leave/transfer + auto-promote present | GAP-COM-009 system msgs |
| REQ-COM-005 | Announcement | PARTIAL | type supported; create-announcement view | post-restriction enforcement thin |
| REQ-COM-006 | Composer | PARTIAL | `sendMessage` + `StoreMessageRequest` | GAP-COM-002 reply-depth |
| REQ-COM-007 | Attachments | PARTIAL | file rule in FormRequest | GAP-COM-007 validation/persistence |
| REQ-COM-008/009 | Receipts + unread | DONE | receipt fan-out + `markAsRead` transaction | — |
| REQ-COM-010 | Search | DONE | `ChatMessageController@search` | GAP-COM-012 LIKE only |
| REQ-COM-011 | Mute/pin/archive | DONE | `pin/mute/archiveConversation` | — |
| REQ-COM-012 | Notifications | NOT STARTED | no NTF call; empty `EventServiceProvider::$listen` | GAP-COM-004 |
| REQ-COM-013 | Presence | DONE | `ChatAjaxController@ping`, mobile presence | GAP-COM-013 typing |
| REQ-COM-014 | Soft-delete | DONE | `deleteMessage` (clears body, sets deleted_by) | GAP-COM-003 audit |
| REQ-COM-015 | Personalisation | DONE | `ChatPersonalizationController` | — |
| REQ-COM-016 | Settings | DONE | `ChatSettingsController` + seeder | — |
| REQ-COM-017 | Permission config | DONE | `ChatPermissionConfigController` (CRUD+trash+restore+toggle) | GAP-COM-005 |
| REQ-COM-018 | Moderation | PARTIAL | `ChatModerationController` (deleted/high-volume views) | flagging (ENH-009) |
| REQ-COM-019 | Audit log | NOT STARTED | no `sys_activity_logs` writes | GAP-COM-003 |
| REQ-COM-020 | Retention | DONE | `PurgeOldChatMessages` scheduled daily | purge audit (GAP-003) |
| REQ-COM-021 | Mobile API | DONE | 6 Mobile controllers + `mobile_api.php` | push (GAP-004) |
| REQ-COM-022 | Access revocation | PARTIAL | column present | GAP-COM-010 enforcement |

> Hand off to **Technical Auditor** (12-layer) for deep security/tenancy/performance verification keyed to
> Section 10.1 flags. This BA gap analysis is coverage-oriented, not defect-hunting.

---

*End of CommonChat (COM) Complete FRD & Analysis Pack — 2026-06-29.*
</content>
