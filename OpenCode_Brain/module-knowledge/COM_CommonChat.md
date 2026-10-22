# Module Knowledge: CommonChat (COM)
# Last Updated: 2026-06-29
# Completion Status: ~70% BUILT (schema + service + web/mobile controllers + views live; tests, notification wiring, moderation audit, reply-depth guard outstanding)

---

> **CORRECTION NOTICE (2026-06-29) — supersedes the 2026-06-27 seed.**
> The prior version of this file claimed "0% Greenfield" and described TWO modules: CommonChat
> (`cht_`) and a separate broadcast "Communication" (`com_`) module with 14 proposed tables, SMS/DLT,
> WhatsApp, email campaigns, circulars, emergency alerts, etc. **That `com_` broadcast module does NOT
> exist in the live codebase.** There is no `Modules/Communication`, no `com_*` migration, and no `com_*`
> DDL. The seed conflated the real CommonChat chat module with an unrelated/aspirational broadcast spec.
> This file is rewritten to describe ONLY the live module that exists:
>
> | Identifier | Value |
> |------------|-------|
> | Module Name | **CommonChat** (real-time in-app chat) |
> | Module Code (this knowledge/FRD set) | **COM** |
> | Table prefix | **`cht_`** (chat) |
> | Namespace | `Modules\CommonChat` |
> | App path | `Modules/CommonChat/` |
> | Route prefix | `chat/` (web), `api/v1/` (sanctum stub), mobile `admin/chat/` |
> | DB layer | `tenant_db` (per-school isolated; NO `tenant_id` column) |
>
> CODE = COM, PREFIX = `cht_` is the intentional, verified pairing. Do not re-introduce the `com_`
> broadcast tables — if school-wide SMS/email/circular broadcast is needed it is a *different, future*
> module and must not be merged here.

---

## Module Facts (verified against live tree 2026-06-29)

| Item | Value | Evidence |
|------|-------|----------|
| Module Code | COM | task assignment |
| Module Name | CommonChat | `Modules/CommonChat/module.json` |
| Table prefix | `cht_` | migrations |
| DDL (reference) | `2-DDL_Tenant_Consolidated/Sch_CommonChat_DDL_v1.sql` (header: "Requirement: CHT_Requirements_v1.md") | DDL file |
| Live migrations | **9** tenant migrations dated `2026_06_16_1007xx` | `database/migrations/tenant/` |
| DB | `tenant_db` (per-school) | migration targets `sys_users`/`sys_roles` |
| Tables | **9** `cht_*` tables | migrations |
| Models | **9** (one per table) | `app/Models/` |
| Controllers | **15** = 9 web + 6 mobile | `app/Http/Controllers/` |
| Services | **1** — `ChatService` (559 LOC, 15 public/private methods) | `app/Services/` |
| Policies | **4** — Conversation, Message, Participant, PermissionConfig | `app/Policies/` (module-local) |
| FormRequests | **5** — CreateDm, CreateGroup, MarkAsRead, StoreMessage, UpdateParticipant | `app/Http/Requests/` |
| Blade views | **19** | `resources/views/` |
| Seeders | **2** — `CommonChatDatabaseSeeder` (1 row in `cht_settings`), `ChatPermissionConfigSeeder` (role-pair defaults) | `database/seeders/` |
| Console commands | **1** — `chat:purge-old-messages` (`PurgeOldChatMessages`), scheduled `->daily()` | `app/Console/Commands/` + ServiceProvider |
| Route files | **3** — `web.php` (full CRUD+ajax), `api.php` (sanctum `apiResource commonchats` stub), `mobile_api.php` (admin/chat endpoints) | `routes/` |
| Tests | **0** — `tests/Feature` and `tests/Unit` empty | filesystem |
| FRD status | **Generated 2026-06-29** — `COM_FRD_Complete_2026-06-29.md` | this run |
| Permission strings | `tenant.chat.create`, `tenant.chat.message`, `tenant.chat.moderate`, `tenant.chat.settings`, `tenant.chat-permission-config.{view,create,update,delete,restore,status}` | grep of policies/controllers |

---

## DDL / Schema — Live Table Inventory (9 tables, from migrations)

| # | Table | Layer | PK | Purpose | Notable columns |
|---|-------|-------|----|---------|-----------------|
| 1 | `cht_settings` | L1 | `id` **UNSIGNED TINYINT default 1** (singleton) | School-level chat config (1 row) | `max_group_members` (default 100), `max_file/audio/video_attachment_size_mb`, `message_retention_days` (0=forever), default_* preference flags, capability defaults (`can_*`) |
| 2 | `cht_permission_config` | L1 | `id` UNSIGNED INT | Role-pair / user-override permission matrix | `permission_for_role_id` FK→sys_roles, `permission_for_user_id` FK→sys_users (NULL=role rule), `allowed_whom_to_connect_with` FK→sys_roles, capability flags, `is_active`, softDeletes. UNIQUE(role,user,allowed) |
| 3 | `cht_personalization_settings` | L1 | `id` UNSIGNED INT | Per-user chat preferences + privacy | `show_online_status`, `notify_on_new_message`, `notify_on_mention`, `show_message_preview_in_notif`, `show_read_receipt_enabled`, `is_deactivated_by_admin`, `is_active`, `created_by` (NO `updated_by`), `role_id` FK, `user_id` FK, softDeletes. UNIQUE(role_id,user_id) |
| 4 | `cht_user_presence` | L1 | **`user_id`** (no surrogate; upsert) | Heartbeat presence | `last_seen_at`, `device_type`. No `is_active`/`created_by`/`deleted_at` |
| 5 | `cht_conversations` | L2 | `id` BIGINT | DM / Group / Announcement header | `conversation_type` ENUM('Announcement','Direct','Group') default Direct, `name`, `description`, `avatar_media_id`, `last_message_at`, `last_message_preview`, `is_archived`, `user_a_id`/`user_b_id` FK→sys_users, **`dm_pair_hash` VIRTUAL generated col** + UNIQUE, composite UNIQUE(created_by,type,name,deleted_at), CHECK on name-by-type, softDeletes |
| 6 | `cht_participants` | L3 | `id` BIGINT | Membership + per-user state | `conversation_id` FK cascade, `user_id` FK cascade, `role` ENUM('Admin','Member'), `joined_at`, `left_at`, `muted_until`, `is_pinned`, `pin_order` (TINYINT), `unread_count`, `archived_at`, softDeletes. UNIQUE(conversation_id,user_id) |
| 7 | `cht_messages` | L4 | `id` BIGINT | Messages | `body` VARCHAR(2000), `message_type` ENUM('Attachment','System','Text') **default 'text' (lowercase — see BUG below)**, `is_deleted`, `conversation_id` FK cascade, `sender_id` FK set-null, `parent_message_id` self-FK null-on-delete, `deleted_by` FK set-null, softDeletes |
| 8 | `cht_attachments` | L5 | `id` BIGINT | File metadata per message | `file_name`, `file_path` (500), `file_size`, `mime_type`, `media_id`, `thumbnail_media_id`, `is_active`, `created_by`, `updated_by`, `message_id` FK cascade. **No `deleted_at`** (follows message lifecycle) |
| 9 | `cht_message_receipts` | L5 | `id` BIGINT | Per-recipient read receipt | `read_at` NULL, **HAS `created_at`/`updated_at`** but NO `created_by`/`updated_by`/`deleted_at`, `message_id` FK cascade, `user_id` FK cascade. UNIQUE(message_id,user_id) |

> **There is NO dedicated `cht_activity_log` table.** Moderation/admin audit is intended to flow to the
> system-wide `sys_activity_logs` (per V1 tab-10) — but see GAP-COM-003: that write is not yet implemented.

### Three-way reconciliation (DDL ↔ migration ↔ model)
- **DM uniqueness:** migration creates `dm_pair_hash` as a **VIRTUAL** generated column (not STORED as the
  old seed claimed). MySQL 8.0+ still required (`LEAST`/`GREATEST` in generated column). Service
  (`createDm`) also sets `user_a_id=LEAST`, `user_b_id=GREATEST` and pre-checks for an existing row.
- **`cht_settings` singleton:** live migration declares `primary('id')` only — the "missing comma /
  duplicate UNIQUE" syntax error noted against the raw .sql in the old seed does **not** exist in the
  live migration. Seeder uses `firstOrCreate(['id'=>1])`.
- **`message_type` ENUM default bug:** column default is `'text'` (lowercase) but the ENUM members are
  `'Attachment','System','Text'` (capitalised). MySQL will reject/normalise the default — confirmed
  schema smell. Service always writes a capitalised value via a `match`, so runtime inserts are safe,
  but the column default is invalid. → GAP-COM-006.

---

## Feature → Table → Code Map (live)

| REQ (FRD) | Feature | Key tables | Primary code | Status |
|-----------|---------|-----------|--------------|--------|
| REQ-COM-001 | Chat dashboard / conversation list | participants, conversations | `ChatController@index/conversations`, `ChatService::getConversationsForUser` | BUILT |
| REQ-COM-002 | Direct (1:1) messaging | conversations, participants, messages | `ChatService::createDm/canInitiateDm` | BUILT |
| REQ-COM-003 | Group chat | conversations, participants | `ChatService::createGroup` | BUILT |
| REQ-COM-004 | Group membership mgmt (add/remove/leave/transfer/auto-promote) | participants | `ChatParticipantController`, `ChatService::addParticipant/removeParticipant/leaveGroup` | PARTIAL (no system-message events) |
| REQ-COM-005 | Announcement threads (one-way) | conversations, participants | `ChatService` (isAnnouncement branches) | PARTIAL (create-announcement view exists; send-restriction logic thin) |
| REQ-COM-006 | Composer: send + reply threading | messages | `ChatMessageController@store`, `ChatService::sendMessage`, `StoreMessageRequest` | PARTIAL (reply-depth cap NOT enforced) |
| REQ-COM-007 | File & media attachments | attachments | `StoreMessageRequest` (file rule) | PARTIAL (MIME allow-list + per-setting size not enforced; one-per-msg) |
| REQ-COM-008 | Read receipts & status | message_receipts | `ChatService::sendMessage` (receipt fan-out), markAsRead | BUILT |
| REQ-COM-009 | Unread count + mark-as-read | participants, message_receipts | `ChatService::markAsRead` | BUILT |
| REQ-COM-010 | Message search & history | messages | `ChatMessageController@search` | BUILT (LIKE search) |
| REQ-COM-011 | Mute / Pin / Archive (per-user) | participants | `ChatService::pin/mute/archiveConversation` | BUILT |
| REQ-COM-012 | Notifications & alerts (NTF integration) | participants, personalization | — | NOT BUILT (no NTF dispatch anywhere) |
| REQ-COM-013 | Online/offline presence | user_presence | `ChatAjaxController@ping`, `MobileChatPresenceController` | BUILT |
| REQ-COM-014 | Message soft-delete (sender + admin) | messages | `ChatService::deleteMessage` | BUILT (no audit write) |
| REQ-COM-015 | Personalization & privacy settings | personalization_settings | `ChatPersonalizationController` | BUILT |
| REQ-COM-016 | School chat configuration | settings | `ChatSettingsController` | BUILT |
| REQ-COM-017 | Permission config matrix + user override | permission_config | `ChatPermissionConfigController` (full CRUD+trash+restore+toggle) | BUILT |
| REQ-COM-018 | Admin moderation console | messages, conversations | `ChatModerationController` | PARTIAL (view + admin-delete; flagging UI thin) |
| REQ-COM-019 | Activity log & audit trail | sys_activity_logs (intended) | — | NOT BUILT (no sys_activity_logs writes) |
| REQ-COM-020 | Retention auto-purge | settings, messages | `PurgeOldChatMessages` cmd (daily) | BUILT |
| REQ-COM-021 | Mobile chat API | all | `Mobile/*` (6 controllers) | BUILT |
| REQ-COM-022 | Admin chat access revocation | personalization_settings | `is_deactivated_by_admin` column | PARTIAL (column present; enforcement guard not in send path) |

---

## Known Gaps & Open Issues

> **Technical Auditor Mode X (2026-06-29)** confirmed/added the issues below. Report:
> `3-Audit_Reports/V1_Jun-2026/CommonChat_Complete_Audit_2026-06-29.md`. New auditor-coded items:
> - **P0 MIG-COM-001** — `cht_permission_config` FKs to `sys_roles` (migration `...100703:32,:36`); `sys_roles`
>   has NO create migration anywhere → `tenants:migrate` fails errno 150/1824. DEPLOY BLOCKER (Layer-2.5 systemic).
> - **P1 SEC-COM-001** — attachments on `public` disk, served via `Storage::disk('public')->url()`
>   (`ChatAjaxController:479,506,508`), no auth/membership gate → confidential files world-readable by URL.
> - **P1 JOB-COM-001** — `chat:purge-old-messages` scheduled in CENTRAL context (`CommonChatServiceProvider:82`),
>   no `tenants:run`/tenancy init → retention purge never runs per-tenant (REQ-COM-020 non-functional).
> - **P1 BUG-COM-001** — `ChatService::deleteMessage:365` hardcodes `hasAnyRole(['super-admin','principal'])`;
>   conflicts with policy `tenant.chat.moderate` + service short_names → moderation/admin-delete fails.
> - **P1 DAT-COM-001** — `cht_messages.body` VARCHAR(2000) vs validation/BR-COM-016 max 5000 → truncation/SQL 22001.
> - **P1 VAL-COM-001** — reply integrity unenforced: no same-conversation (BR-COM-018) and no depth-1 (BR-COM-019)
>   check on `parent_message_id` → cross-conversation reply + content leak. (supersedes scope of GAP-COM-002)
> - **P1 BUG-COM-003** — PII `Log::debug` on every user search (`ChatController:210,218,227`).
> - **P2 SEC-COM-003** — `ChatAjaxController` bypasses Policy gates; announcement post-restriction (BR-COM-014)
>   only in policy, not in `ChatService::sendMessage` → AJAX/mobile send path doesn't enforce it.
> - **P2 VAL-COM-002** — permission-config uniqueness (BR-COM-036) not validated at request layer (DB index only → 500).
> - **P3 DEAD-COM-001** — `CommonChatController` scaffold stub + `api.php commonchats` group has no tenancy middleware.
> - **Snapshot correction:** attachment MIME allow-list + per-setting size **ARE** enforced and `cht_attachments`
>   rows **ARE** created on the AJAX/mobile path (`ChatAjaxController:167-194,481`) — GAP-COM-007 applies only to the
>   web `StoreMessageRequest`/`ChatService::sendMessage` path (hardcoded `max:10240`, no persistence there).
> - **Good (not gaps):** all 5 FormRequests delegate `authorize()` to policies (beats D30); `dm_pair_hash` VIRTUAL
>   generated col correctly emitted (beats D36); web+mobile tenancy stack present.

### P0
- **GAP-COM-001 — No automated tests.** `tests/Feature` and `tests/Unit` are empty. Zero coverage on DM
  uniqueness, permission resolution, receipt fan-out, retention purge.
- **GAP-COM-002 — Reply-depth cap (BR-COM) NOT enforced.** `StoreMessageRequest` only checks
  `parent_message_id` exists; neither the FormRequest nor `ChatService::sendMessage` verifies the parent
  is top-level (`parent_message_id IS NULL`). Reply-to-reply is currently possible.
- **GAP-COM-003 — Moderation audit not written.** `deleteMessage` sets `is_deleted/deleted_by` but does
  NOT write to `sys_activity_logs` and does NOT store the SHA-256 body hash that V1 tab-10 mandates.
  The "Activity Log & Audit Trail" screen (REQ-COM-019) has no backing data source.

### P1
- **GAP-COM-004 — Notification integration absent.** V1 tab-8 specifies in-app notifications + NTF
  fallback on new message / @mention. No NTF dispatch exists in `ChatService` or any listener
  (`EventServiceProvider` has empty `$listen`). Only `unread_count` increments.
- **GAP-COM-005 — Role-name mismatch between seeder and service.** `ChatPermissionConfigSeeder` keys on
  role **display names** ("Super Admin", "School Admin", "Teacher", "Student", "Parent"). But
  `ChatService::canInitiateDm` branches on role **`short_name`** values ("super_admin", "principal",
  "vice_principal", "teacher", "staff", "accountant", "librarian", "student", "parent"). "School Admin"
  has no short_name branch; "principal/vice_principal" are not seeded. Permission resolution is
  inconsistent across the two layers.
- **GAP-COM-006 — `cht_messages.message_type` invalid column default** (`'text'` lowercase vs ENUM
  members capitalised). Cosmetic at runtime (service writes capitalised) but invalid schema default.
- **GAP-COM-007 — Attachment validation thin.** `StoreMessageRequest` hardcodes `file max:10240` (10 MB)
  rather than reading `cht_settings.max_file_attachment_size_mb`; no MIME allow-list (JPEG/PNG/GIF/WebP/
  PDF/DOC/DOCX/XLS/XLSX) enforced; no server-side content sniffing; no `cht_attachments` row creation
  observed in `ChatService::sendMessage` (attachment persistence path incomplete).
- **GAP-COM-008 — Group max-member off-by-one.** `createGroup` rejects when `count(memberIds) >= maxMembers`,
  blocking at `maxMembers-1` additional members instead of allowing exactly `maxMembers` total.
- **GAP-COM-009 — System messages for group events not generated.** No `message_type='System'` rows for
  join/leave/admin-transfer/rename/archive (V1 tab-3 spec).
- **GAP-COM-010 — `is_deactivated_by_admin` not enforced in send/receive path.** Column exists; no guard
  in `ChatService::sendMessage` / message policy.

### P2
- **GAP-COM-011 — `api.php` `commonchats` apiResource is a scaffold stub** (`CommonChatController`) with no
  real chat semantics; either implement or remove.
- **GAP-COM-012 — Search uses `LIKE %term%`** with no FULLTEXT index; will not scale; attachment/file-name
  search out of Phase-1 scope.
- **GAP-COM-013 — Typing indicator** (`cht_settings.default_typing_indicator_enabled`, mobile `typing`
  endpoint) has no persistent backing; ephemeral only.

---

## Key Design Decisions (verified)

1. **DM uniqueness — VIRTUAL generated `dm_pair_hash`.** `CONCAT(LEAST(a,b),'_',GREATEST(a,b))` for Direct
   only; UNIQUE index enforces one DM per pair at DB level. Service also normalises a/b and pre-checks.
   Requires MySQL 8.0+.
2. **Single `cht_conversations` table for all three types** (Direct/Group/Announcement), discriminated by
   `conversation_type`; CHECK enforces `name NULL` for Direct, `name NOT NULL` for Group/Announcement.
3. **All per-user state lives on `cht_participants`** (unread_count, mute, pin, archive, left_at, role) —
   never on the conversation header — so personalisation never leaks across participants.
4. **Two-level archive:** `cht_conversations.is_archived` = school-wide read-only (admin); `cht_participants.archived_at`
   = per-user hide only.
5. **Soft-delete clears body:** `is_deleted=1`, `body=NULL`, `deleted_by` set; row retained for thread
   integrity. `deleted_by` distinguishes sender-delete vs admin-removal for UI labelling.
6. **Receipt fan-out at send time:** one `cht_message_receipts` row per non-sender active participant,
   `read_at=NULL`; `unread_count` incremented only for non-muted participants; all inside one transaction.
7. **Mark-read in one transaction:** bulk `read_at=now()` on the user's NULL receipts for the conversation,
   then `unread_count=0`.
8. **Mute via single `muted_until` timestamp:** future = timed mute, `9999-12-31` = permanent; no separate
   `is_muted` flag. Mute suppresses unread increment + (intended) notifications, not receipt tracking.
9. **Three-tier permission resolution:** user-specific `cht_permission_config` row → role-pair row →
   `cht_settings` defaults; `can_message_anyone` short-circuits. (Built in `checkPermissionConfig`, but see
   GAP-COM-005 role-name mismatch.)
10. **Retention purge:** `chat:purge-old-messages` daily; hard-`forceDelete()` messages older than
    `message_retention_days` (0 = never); receipts + attachments cascade via FK.
11. **Presence upsert:** `cht_user_presence` PK = `user_id`; 30s heartbeat; online threshold ~60s; ephemeral.
12. **Pin cap = 5** per user (service-enforced, not DB).
13. **Spatie Media** referenced by `avatar_media_id` / `media_id` / `thumbnail_media_id` (INT UNSIGNED,
    no FK — Spatie manages its own lifecycle).

---

## Cross-Module Dependencies

### Inbound (CommonChat reads from)
| Module | Table | Used for |
|--------|-------|----------|
| System | `sys_users` | sender/participant identity, active check, created_by/deleted_by |
| System | `sys_roles` | role-pair permission config; role short_name in `canInitiateDm` |
| StudentProfile | `std_student_guardian_jnt` | parent→child link (parent-teacher DM gating) |
| SchoolSetup | `sch_academic_sessions`, `std_student_academic_sessions`, `sch_class_section_jnt` | resolve teacher-of-parent's-child for DM permission |
| Spatie Media Library | media (logical) | group avatar + attachment thumbnails |

### Outbound (CommonChat feeds / should feed)
| Module | Mechanism | Status |
|--------|-----------|--------|
| Notification (NTF) | new-message / @mention push | **NOT wired (GAP-COM-004)** |
| System | `sys_activity_logs` (moderation/audit) | **NOT wired (GAP-COM-003)** |
| Student/Parent portals | read `cht_*` for chat UI | consumer-side |

---

## Implementation Blockers / Prerequisites
| # | Prerequisite | Owner | Blocks |
|---|--------------|-------|--------|
| 1 | MySQL 8.0+ on all tenant DB servers | DevOps | `dm_pair_hash` generated column |
| 2 | `sys_users` + `sys_roles` seeded with consistent `short_name` values | SYS | permission resolution (GAP-COM-005) |
| 3 | Spatie Media Library installed + tenant disk routing | DevOps | attachments (REQ-COM-007) |
| 4 | NTF push dispatch functional | NTF | notification integration (REQ-COM-012) |

---

## Pending Next Steps
- [ ] Write Pest tests (GAP-COM-001) — DM uniqueness, permission matrix, receipt fan-out, purge.
- [ ] Enforce reply-depth cap (GAP-COM-002) in `StoreMessageRequest` + `ChatService::sendMessage`.
- [ ] Implement moderation/audit writes to `sys_activity_logs` with SHA-256 body hash (GAP-COM-003) to
      back REQ-COM-019.
- [ ] Wire NTF dispatch for new-message/@mention with graceful degradation (GAP-COM-004).
- [ ] Reconcile role display-name vs short_name across seeder and service (GAP-COM-005).
- [ ] Fix `cht_messages.message_type` column default (GAP-COM-006).
- [ ] Harden attachment validation + complete `cht_attachments` persistence (GAP-COM-007).
- [ ] Fix group max-member off-by-one (GAP-COM-008); add group system messages (GAP-COM-009).
- [ ] Enforce `is_deactivated_by_admin` in send/receive guard (GAP-COM-010).
- [ ] Decide WebSocket vs polling for real-time delivery (currently polling).
- [ ] Run Technical Auditor (12-layer) against this FRD's Section 10 coverage flags.

---

## Version History
| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Initial seed — INACCURATE: claimed 0% greenfield and merged a non-existent `com_` broadcast module. |
| 2026-06-29 | Technical Auditor | **Mode X complete audit.** Health 40/100 (capped — 1 P0). DEPLOY: NO-GO. P0×1 (MIG-COM-001 sys_roles FK), P1×10, P2×7, P3×3. Three-way reconcile found body 2000-vs-5000 mismatch (DAT-COM-001) and invalid enum default; confirmed sys_roles FK deploy blocker; found public-disk attachment exposure (SEC-COM-001), central-scheduled purge (JOB-COM-001), moderation role-slug bug (BUG-COM-001), unenforced reply integrity (VAL-COM-001), PII logging (BUG-COM-003). Corrected stale attachment-validation snapshot (AJAX path enforces MIME/size + persists). |
| 2026-06-29 | Business Analyst | **Full rewrite from live code.** Verified 9 `cht_*` migrations, 15 controllers, 9 models, 1 service (559 LOC), 4 policies, 5 FormRequests, 19 views, 2 seeders, 1 scheduled command, 0 tests. Removed the bogus `com_` broadcast content. Three-way reconciled DDL↔migration↔model (dm_pair_hash VIRTUAL not STORED; receipts have timestamps; message_type default bug). Catalogued 13 gaps (GAP-COM-001..013). Generated Complete FRD (`COM_FRD_Complete_2026-06-29.md`): 22 REQ, 30 BR, 5 RPT, workflows, FSMs, RTM, NFR/risk, sprint plan, user stories. |
</content>
</invoke>
