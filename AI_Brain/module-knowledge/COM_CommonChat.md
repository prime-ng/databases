# Module Knowledge: CommonChat (CHT) + Communication (COM)
# Last Updated: 2026-06-27
# Completion Status: 0% — Greenfield (no implementation started)

---

> **IMPORTANT — Two Distinct Modules Covered By This File**
>
> The DDL source (`Sch_CommonChat_DDL_v1.sql`) defines the **CommonChat** module with prefix `cht_`.
> The requirement source (`COM_Communication_Requirement.md`) defines the **Communication** module with prefix `com_`.
> These are architecturally separate but tightly linked: COM handles broadcast/campaign messaging (circulars, SMS, email, WhatsApp, emergency alerts); CHT handles real-time in-app chat (conversations, read receipts, presence). Both live in `tenant_db`. This file captures facts from both sources until a separate COM knowledge file is created.

---

## Module Facts

### CHT — CommonChat (Real-Time Chat)

| Item | Value |
|------|-------|
| Module Code | CHT |
| Module Name | CommonChat |
| Table prefix | `cht_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Sch_CommonChat_DDL_v1.sql` — 8 tables |
| V2 Requirement | None linked in DDL header (DDL references `CHT_Requirements_v1.md` — not the COM req) |
| Migration file | `2026_05_14_000001_create_cht_common_chat_tables.php` |
| Seeder | `ChtSettingsSeeder` (seeds 1 row in `cht_settings` with all defaults) |
| DB | `tenant_db` (per-school; no tenant_id columns) |
| Models | 8 (one per table) |
| FRD status | Not yet generated |
| Business Rules | BR-CHT-001 to BR-CHT-016 referenced in DDL comments |

### COM — Communication (Broadcast Messaging)

| Item | Value |
|------|-------|
| Module Code | COM |
| Module Name | Communication |
| Table prefix | `com_*` |
| DDL (canonical) | Not yet written — V2 requirement proposes 14 new `com_*` tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/COM_Communication_Requirement.md` |
| Module Namespace | `Modules\Communication` |
| Module Path | `Modules/Communication/` |
| Route Prefix | `communication/` |
| DB | `tenant_db` (per-school; no tenant_id columns) |
| Processing Mode | RBS_ONLY |
| RBS Sub-Modules | N1 (SMS), N2 (Email), N3 (Push), N4 (In-App DM), N5 (Circular/Notice Board), N6 (Emergency), N7 (Preferences), N8 (Event Triggers) |
| Queue Names | `communications` (dedicated) + `emergency` (highest priority) |
| Controllers | 18 proposed (13 web + 4 API + 1 webhook) |
| Models | 18 proposed |
| Services | 11 proposed |
| Jobs | 9 proposed |
| FormRequests | 26 proposed |
| Policies | 13 proposed |
| Blade Views | ~85 proposed |
| API endpoints (mobile) | 18 proposed |
| Test cases | 22 proposed |
| FRs count | 25 (FR-COM-001 to FR-COM-025) |
| BRs count | 18 (BR-COM-001 to BR-COM-018) |
| Permissions | 24 (`com.*` namespace) |
| FRD status | Not yet generated |

---

## DDL Layer Structure

### CHT — CommonChat (8 tables)

| Layer | Tables | Notes |
|-------|--------|-------|
| Layer 1 (no cht_* deps) | `cht_settings` | Singleton config; PK is `TINYINT UNSIGNED DEFAULT 1` (not standard BIGINT AI) |
| Layer 1 (no cht_* deps) | `cht_permission_config` | Role-pair permission matrix; FKs only to `sys_roles` + `sys_users` |
| Layer 1 (no cht_* deps) | `cht_personalization_settings` | Per-user preferences; FKs only to `sys_users` + `sys_roles` |
| Layer 1 (no cht_* deps) | `cht_user_presence` | Ephemeral heartbeat table; PK = `user_id` (upsert pattern — not surrogate) |
| Layer 2 (deps Layer 1) | `cht_conversations` | DM / Group / Announcement header; STORED generated `dm_pair_hash` column |
| Layer 3 (deps Layer 2) | `cht_participants` | User-conversation membership; one row per user per conversation |
| Layer 4 (deps Layer 3) | `cht_messages` | Individual messages within a conversation; soft-delete clears body |
| Layer 5 (deps Layer 4) | `cht_message_receipts` | Per-message per-recipient read receipts; append-only |
| Layer 5 (deps Layer 4) | `cht_attachments` | File metadata for message attachments |

### COM — Communication Proposed Tables (14 com_* tables — DDL not yet written)

| Layer | Tables |
|-------|--------|
| Layer 1 (no com_* deps) | `com_gateway_configs`, `com_sms_dlt_templates`, `com_message_templates`, `com_whatsapp_templates`, `com_groups`, `com_school_settings` |
| Layer 2 (deps Layer 1) | `com_message_template_translations`, `com_group_members_jnt`, `com_recurring_rules`, `com_event_trigger_rules`, `com_user_preferences` |
| Layer 3 (deps Layer 2) | `com_messages`, `com_circulars` |
| Layer 4 (deps Layer 3) | `com_message_recipients_jnt`, `com_circular_targets_jnt`, `com_circular_acknowledgements`, `com_emergency_alerts`, `com_message_flags` |

> Note: The requirement document states "14 DDL tables" for `com_*`. The Layer 4 derivative/junction tables bring the effective total to 18 distinct tables. The "14" count excludes some junction and log tables.

---

## Feature Groups

### CHT — CommonChat

| FR | Feature | Tables | Priority |
|----|---------|--------|----------|
| F-CHT-01 | School-level chat configuration | `cht_settings` | Critical |
| F-CHT-02 | Role-pair permission matrix (who can message whom) | `cht_permission_config` | Critical |
| F-CHT-03 | Per-user chat personalization + privacy | `cht_personalization_settings` | High |
| F-CHT-04 | Online/offline presence tracking | `cht_user_presence` | High |
| F-CHT-05 | Direct (1:1) conversations | `cht_conversations`, `cht_participants` | Critical |
| F-CHT-06 | Group conversations | `cht_conversations`, `cht_participants` | High |
| F-CHT-07 | Announcement broadcast threads (one-way) | `cht_conversations`, `cht_participants` | High |
| F-CHT-08 | Message send + reply threading (depth 1) | `cht_messages` | Critical |
| F-CHT-09 | File attachments on messages | `cht_attachments` | High |
| F-CHT-10 | Read receipts per message per recipient | `cht_message_receipts` | High |
| F-CHT-11 | Message soft-delete (body cleared, row retained) | `cht_messages.is_deleted` | Critical |
| F-CHT-12 | Mute / Pin / Archive per user | `cht_participants` (`muted_until`, `is_pinned`, `archived_at`) | Medium |
| F-CHT-13 | Admin chat access revocation | `cht_personalization_settings.is_deactivated_by_admin` | Medium |
| F-CHT-14 | Message retention auto-purge | `cht_settings.message_retention_days` + `ChtPurgeOldMessagesJob` | Medium |

### COM — Communication

| FR# | Feature | Tables | Priority |
|-----|---------|--------|----------|
| FR-COM-001 | SMS Gateway Configuration (DLT-compliant) | `com_gateway_configs` | P1 |
| FR-COM-002 | DLT Template Registration (TRAI NCPR) | `com_sms_dlt_templates` | P1 |
| FR-COM-003 | Compose and Send SMS Campaign | `com_messages`, `com_message_recipients_jnt` | P1 |
| FR-COM-004 | Bulk SMS via CSV Upload (max 5,000 rows) | `com_messages`, `com_message_recipients_jnt` | P1 |
| FR-COM-005 | SMS Delivery Tracking + Webhook | `com_message_recipients_jnt` | P1 |
| FR-COM-006 | Email Sending Configuration (SMTP/SES/Mailgun) | `com_gateway_configs` | P1 |
| FR-COM-007 | Compose and Send Email Campaign | `com_messages`, `com_message_recipients_jnt` | P1 |
| FR-COM-008 | Email Template Management (versioned) | `com_message_templates`, `com_message_template_translations` | P1 |
| FR-COM-009 | Recurring Email/SMS Rules | `com_recurring_rules` | P1 |
| FR-COM-010 | Communication-Initiated Push Notifications | `com_messages`, `com_message_recipients_jnt` | P2 |
| FR-COM-011 | One-to-One In-App Direct Messaging | `com_messages`, `com_message_recipients_jnt` | P1 |
| FR-COM-012 | Group Messaging | `com_messages`, `com_message_recipients_jnt`, `com_groups` | P1 |
| FR-COM-013 | Message Moderation + Flagging | `com_message_flags` | P1 |
| FR-COM-014 | Create and Distribute Circular | `com_circulars`, `com_circular_targets_jnt` | P1 |
| FR-COM-015 | Circular Acknowledgement Tracking | `com_circular_acknowledgements` | P1 |
| FR-COM-016 | Notice Board Display (role-filtered, paginated) | `com_circulars`, `com_circular_targets_jnt` | P1 |
| FR-COM-017 | Emergency Alert Broadcast (multi-channel) | `com_emergency_alerts`, `com_messages` | P0 |
| FR-COM-018 | Emergency Alert Delivery Tracking | `com_emergency_alerts` | P0 |
| FR-COM-019 | User Notification Preference Management | `com_user_preferences` | P2 |
| FR-COM-020 | Event-Driven Trigger Contract (N8) | `com_event_trigger_rules`, `com_messages` | P2 |
| FR-COM-021 | Communication Group Management | `com_groups` | P1 |
| FR-COM-022 | Group Membership Management | `com_group_members_jnt` | P1 |
| FR-COM-023 | Schedule Messages for Future Delivery | `com_messages` (`scheduled_at`) | P1 |
| FR-COM-024 | Communication Analytics Dashboard | `com_messages`, `com_message_recipients_jnt` (aggregated) | P2 |
| FR-COM-025 | Communication Reports (PDF + CSV) | All com_* tables | P2 |

---

## DDL Gaps

### CHT — Tables Referenced but Not in DDL

| Gap | Reference Location | Impact | Priority |
|-----|--------------------|--------|----------|
| `CHT_Requirements_v1.md` not read | DDL header references this requirement file — it is NOT the COM req | If CHT requirement specifies additional tables (reactions, @mention tracking, etc.) they may not be in this DDL | P1 — read CHT req before coding |
| `sys_roles` | Referenced by `cht_permission_config.permission_for_role_id` and `cht_personalization_settings.role_id` | Must exist and be seeded before any `cht_permission_config` inserts | P0 — SYS prerequisite |
| `sys_users` | Referenced by all FKs for `user_id`, `created_by`, `sender_id`, `deleted_by`, etc. | Must be complete before any CHT table can be populated | P0 — SYS prerequisite |
| Spatie Media Library `spatie_media` | Referenced logically by `cht_attachments.media_id` and `cht_conversations.avatar_media_id` (INT UNSIGNED; no FK constraint) | Package must be installed and its migration run before CHT is fully functional | P0 |

### COM — Tables Referenced in Requirement but DDL Not Yet Written

All 14+ proposed `com_*` tables are gaps since no DDL file exists. Key structural issues to fix when writing DDL:

| Gap Table | Issue | Priority |
|-----------|-------|----------|
| ALL `com_*` tables | Requirement uses `BIGINT UNSIGNED` for PKs — must be corrected to `INT UNSIGNED` per platform standard | P0 |
| ALL `com_*` tables | `created_by` / `updated_by` columns shown as `BIGINT UNSIGNED FK→sys_users` — must be `INT UNSIGNED` (sys_users.id = INT UNSIGNED) | P0 |
| `com_group_members_jnt` | `group_id` FK — if `com_groups.id` uses INT UNSIGNED PK, FK must also be INT UNSIGNED; same for `user_id`, `added_by` | P0 |
| `com_messages` | `sender_id`, `created_by` → INT UNSIGNED; `group_id`, `template_id`, `dlt_template_id`, `whatsapp_template_id`, `parent_message_id`, `event_trigger_rule_id` → INT UNSIGNED (matching their parent table PKs) | P0 |
| `com_message_recipients_jnt` | `message_id`, `recipient_id` → INT UNSIGNED | P0 |
| `com_event_trigger_rules` | Requirement proposal has no `updated_by` column — verify at DDL write time | P1 |
| `com_circular_targets_jnt` | No `created_by` / `deleted_at` in req proposal — confirm intentional at DDL write time | P1 |
| `com_user_preferences` | No `deleted_at` in req — correct: preference rows are never soft-deleted; `is_opted_in` toggle is the lifecycle | P1 |
| `com_message_flags` | No `deleted_at` in req — confirm intentional (flag is immutable moderation audit record) | P1 |
| `com_message_template_translations` | No `deleted_at` in req — deactivation via `is_active = 0` only; confirm at DDL write | P1 |

---

## DDL Corrections & Platform Deviations

### CHT DDL — Issues Found

| Issue | Location | Correction |
|-------|----------|------------|
| `cht_settings.id` is `TINYINT UNSIGNED NOT NULL DEFAULT 1` — not the standard `BIGINT UNSIGNED AUTO_INCREMENT` | `cht_settings` PK | **Intentional** — singleton table (exactly 1 row per tenant). Do not change. |
| `cht_user_presence` — PK is `user_id INT UNSIGNED` (not a surrogate `id`) | `cht_user_presence` | **Intentional** — upsert-by-user pattern. Do not add a surrogate PK. |
| Missing comma in `cht_settings` DDL: `UNIQUE \`uq_cht_setting\` (\`id\`)` appears immediately after `PRIMARY KEY (\`id\`)` without a preceding comma | `cht_settings` DDL near line 61 | **Syntax error** — must add comma between `PRIMARY KEY` clause and `UNIQUE` clause. Fix before running migration. |
| `cht_permission_config` closing `) ENGINE=InnoDB ...` statement is missing in the file as read | `cht_permission_config` DDL | **Possible truncation or syntax error** — verify in the actual file and add closing statement if missing. |
| `cht_personalization_settings` has `created_by INT UNSIGNED NULL` but NO `updated_by` column | `cht_personalization_settings` | **Intentional** — single-user record; `updated_by` is redundant. Note in model. |
| `cht_messages.deleted_by INT UNSIGNED NULL` — extra audit column not in standard convention | `cht_messages` | **Intentional** — required to distinguish "deleted by sender" vs "deleted by admin" for UI label. Keep. |
| `cht_attachments.media_id` / `thumbnail_media_id` — `INT UNSIGNED NULL` references Spatie media but no FK constraint | `cht_attachments` | **Intentional** — Spatie Media Library manages its own table lifecycle; FK omitted by design. |
| `cht_message_receipts` — no `deleted_at`, no `created_by`, no `updated_by` | `cht_message_receipts` | **Intentional** — immutable append-only receipt log. Do not add these columns. |
| `cht_attachments` — no `deleted_at` | `cht_attachments` | **Intentional** — follows parent message lifecycle (cascade from cht_messages). |
| All CHT FKs referencing `sys_users.id` use `INT UNSIGNED` | All cht_* tables | **Correct** — consistent with platform standard (sys_users.id = INT UNSIGNED). |

### COM Requirement vs Platform Standard

| Claim in Requirement | Platform Correction |
|---------------------|---------------------|
| All `com_*` PKs: `BIGINT UNSIGNED` | Must be `INT UNSIGNED` per platform standard |
| `created_by` / `updated_by`: `BIGINT UNSIGNED FK→sys_users` | Must be `INT UNSIGNED` (sys_users.id is INT UNSIGNED in tenant_db) |
| `com_groups.class_id` / `section_id`: `INT UNSIGNED` | Correct — `sch_classes.id` and `sch_sections.id` are INT UNSIGNED |
| `com_emergency_alerts.audience_class_id` / `audience_section_id`: `INT UNSIGNED` | Correct |
| No `academic_session_id` on `com_messages` | Correct — messages are not session-scoped; the design is right as specified |

---

## Key Design Decisions

### CHT — CommonChat

1. **DM uniqueness via STORED generated column `dm_pair_hash`**: The service layer guarantees `user_a_id = LEAST(userId, recipientId)` and `user_b_id = GREATEST(userId, recipientId)` before insert. The UNIQUE constraint on `dm_pair_hash` enforces exactly one conversation per user pair at the DB level. Requires MySQL 8.0+ (`LEAST`/`GREATEST` in STORED generated columns not available on 5.7).

2. **Single `cht_conversations` table covers all three conversation types**: `Direct`, `Group`, and `Announcement` are discriminated by `conversation_type` ENUM. A CHECK constraint enforces `name IS NOT NULL` for Group/Announcement and `name IS NULL` for Direct. Avoids three separate tables while enabling per-type query filtering.

3. **`cht_participants` carries all per-user state**: Unread count, mute, pin order, and per-user archive are on the participant row — NOT on conversations. This ensures per-user personalisation without affecting other participants in the same conversation.

4. **Conversation-level archive vs participant-level archive**: `cht_conversations.is_archived = 1` makes the conversation read-only school-wide (admin action). `cht_participants.archived_at` is a per-user UI-only hiding mechanism that does not affect other participants.

5. **Soft-delete clears message body for privacy**: `cht_messages.is_deleted = 1` + `body = NULL`. Row retained for thread integrity and audit. `deleted_by` column enables two UI labels: if `deleted_by = sender_id` → "This message was deleted"; if `deleted_by != sender_id` (admin) → "Removed by Admin".

6. **Reply depth capped at 1 level** (BR-CHT-016): `parent_message_id` can only reference a top-level message (one with `parent_message_id IS NULL`). Service layer rejects reply-to-reply before insert. Prevents unbounded nesting complexity.

7. **`cht_message_receipts` is append-only**: No `deleted_at`, no `created_by`, no `updated_by`. `read_at` is set once and never cleared. High-volume table — indexed on `(message_id, user_id)` and `(user_id, read_at)` for the two primary query patterns.

8. **`cht_attachments` follows message lifecycle**: No `deleted_at` on `cht_attachments`. When message is soft-deleted, the `ChatAttachment` model accessor returns `NULL` for URL. When message is hard-deleted by admin, attachment cascades via FK. Attachment rows are never independently soft-deleted.

9. **`cht_user_presence` upsert pattern**: No surrogate PK; `user_id` IS the PK. Every 30-second heartbeat does `INSERT ... ON DUPLICATE KEY UPDATE last_seen_at = NOW()`. Online threshold = `last_seen_at > UTC_TIMESTAMP() - INTERVAL 60 SECOND`. No `deleted_at` or `created_by` — ephemeral state only.

10. **Permission resolution priority** (three-tier): User-specific `cht_permission_config` row (where `permission_for_user_id IS NOT NULL`) overrides role-level row (where `permission_for_user_id IS NULL`), which overrides global defaults in `cht_settings`. Fallback chain enforced at service layer — never bypass to `cht_settings` if a role row exists.

11. **Phase-1 one-attachment-per-message** with Phase-2 multi-attachment path: `cht_attachments` has an INDEX (not UNIQUE) on `message_id`. UNIQUE constraint deliberately omitted so Phase-2 can support multiple attachments without schema change. Service layer enforces Phase-1 limit.

12. **Group avatar via Spatie Media Library**: `cht_conversations.avatar_media_id INT UNSIGNED NULL` references Spatie's media table by ID. No FK constraint (Spatie manages its own lifecycle). Same pattern for `thumbnail_media_id` on `cht_attachments`.

### COM — Communication

13. **Two-step confirmation mandatory for emergency alerts** (BR-COM-015): `POST /emergency/preview` creates `com_emergency_alerts` with `status = 'pending_confirmation'` and returns `{alert_id, preview_html}`. `POST /emergency/confirm` (with `alert_id`) sets `status = 'dispatching'`. No single-step endpoint exists. Prevents accidental school-wide alerts.

14. **Emergency bypasses `com_user_preferences` entirely** (BR-COM-002): Emergency category rows always have `is_opted_in = 1` enforced at application layer; user cannot set to `0`. Emergency dispatches additionally bypass the entire preference filter in `CommunicationService` — no per-user exclusion even for opted-out channels.

15. **Pre-materialize recipients ≤ 500; async above 500** (BR-COM-018): `com_message_recipients_jnt` rows created synchronously for campaigns ≤ 500 recipients. `PrepareRecipientsJob` handles larger campaigns async; message stays `dispatching` until job completes. Pre-materialization chosen over lazy-resolve to enable per-recipient status tracking.

16. **Template versioning via parent chain**: Editing a `com_message_templates` record creates a NEW row with `version + 1` and `parent_template_id` pointing to the previous version. Original is archived (`is_active = 0`), never deleted. Full version history traceable via `parent_template_id` chain.

17. **DLT body reconstruction validates against registered skeleton** (BR-COM-001): Before SMS dispatch, `SmsService::reconstructBody()` substitutes each `{#var#}` in position order from `variable_mapping_json`. If the reconstructed skeleton (stripped of substituted values) differs from the stored `body_template`, dispatch is rejected with a TRAI compliance error.

18. **Auto-sync groups resolve dynamically at send time** (BR-COM-009): Groups with `auto_sync = 1` do not store member rows in `com_group_members_jnt`. Membership is resolved by `CommunicationGroupService` at dispatch based on `group_type` (class/section/role). Manual member add to auto-sync groups returns HTTP 422.

19. **`com_messages` is the unified record for ALL channels**: One table covers email, SMS, in-app, WhatsApp, and push. Channel-specific FKs (`dlt_template_id`, `whatsapp_template_id`, `ntf_notification_ref_id`) are nullable and populated only when relevant.

20. **Dedicated `emergency` queue worker — queue isolation**: Normal campaigns use `communications` queue. Emergency alerts use `emergency` queue. Workers must NEVER process both on the same process — a large SMS campaign on `communications` must not block emergency dispatch.

21. **WhatsApp `components_json` stored locally** (not fetched from Meta at runtime): `com_whatsapp_templates.components_json` stores the full Meta template component structure locally. Meta API responses can change; local copy ensures rendering stability without a runtime API dependency.

22. **DND filter uses Redis cache with 6-hour TTL**: Avoids a per-SMS DND scrub API call per recipient. Cache key = phone number; value = DND status. `DndFilterService` manages cache population and expiry.

23. **Gateway credentials encrypted at rest with Laravel `encrypt()`** (AES-256-CBC): `api_key_encrypted`, `api_secret_encrypted`, `webhook_token_encrypted`, `smtp_password_encrypted` — never stored in plain text. Only decrypted in memory during dispatch.

---

## Business Rules

### CHT — CommonChat

| BR ID | Rule Summary | Enforcement Point |
|-------|-------------|-------------------|
| BR-CHT-001 | Only one DM conversation allowed between any two users | DB UNIQUE KEY on `cht_conversations.dm_pair_hash` |
| BR-CHT-003 | Group/Announcement `name` must NOT be NULL; DM `name` must be NULL | DB CHECK constraint on `cht_conversations` |
| BR-CHT-004 | Soft-delete sets `is_deleted = 1` and clears `body = NULL`; row retained | `ChatService` (service layer write) |
| BR-CHT-005 | One receipt row per message per recipient | DB UNIQUE KEY `uq_cht_message_receipts_msg_user (message_id, user_id)` |
| BR-CHT-006 | Mute indefinitely = `muted_until = '9999-12-31 23:59:59'`; prevents unread increment + notification | `ChatService` (mute check before unread increment) |
| BR-CHT-012 | Mark-read resets `cht_participants.unread_count = 0` in same `DB::transaction()` as setting `read_at` | `ChatService::markRead()` |
| BR-CHT-013 | User with `left_at IS NOT NULL` cannot send or receive new messages in that conversation | `MessagePolicy` + API middleware |
| BR-CHT-015 | Max 5 pinned conversations per user | `ChatService` (count check before pin, not DB-enforced) |
| BR-CHT-016 | Reply depth capped at 1 level — reply to a reply is rejected | `ChatService` / FormRequest (check `parent_message_id` of target) |
| BR-CHT-017 | `cht_settings` has exactly 1 row (`id = 1`); seeded on tenant create; never inserted again | DB PK + UNIQUE KEY; `ChtSettingsSeeder` |
| BR-CHT-018 | `is_deactivated_by_admin = 1` blocks all send and receive but preserves history | `MessagePolicy` / `ChatService` guard |

### COM — Communication

| BR ID | Rule Summary | Enforcement Point |
|-------|-------------|-------------------|
| BR-COM-001 | SMS MUST use a DLT-registered template; free-text SMS not permitted | `SmsService` — rejects dispatch if `dlt_template_id IS NULL` |
| BR-COM-002 | Emergency alerts bypass `com_user_preferences`; `emergency` category always `is_opted_in = 1` | `EmergencyAlertService` + `UserPreference` model setter (cannot set to 0) |
| BR-COM-003 | WhatsApp messages must use Meta-approved template (`approval_status = 'approved'`) | `WhatsAppService` — HTTP 422 if not approved |
| BR-COM-004 | Circular acknowledgement only for users who appear in `com_circular_targets_jnt` audience | `CircularPolicy::acknowledge()` — audience membership check |
| BR-COM-005 | User cannot acknowledge same circular twice | DB UNIQUE KEY `uq_circular_ack (circular_id, user_id)` → HTTP 422 on duplicate |
| BR-COM-006 | `scheduled_at` must be at least 2 minutes in the future at save time | FormRequest validation |
| BR-COM-007 | Bulk SMS CSV upload: max 5,000 rows; entire upload rejected if exceeded before any processing | `SmsCampaignController` early-exit validation |
| BR-COM-008 | In-app message body sanitized with HTMLPurifier before storage | `InAppMessageService::store()` |
| BR-COM-009 | Auto-sync groups (`auto_sync = 1`) cannot have manual `com_group_members_jnt` entries | `CommunicationGroupService` — HTTP 422 on attempt |
| BR-COM-010 | Message cancellable only if `status IN ('draft','scheduled')` AND `sent_at IS NULL` | `CommunicationService::cancel()` — rejects otherwise |
| BR-COM-011 | Delivery retry: max 3 attempts; exponential backoff 1 min → 5 min → 15 min; after 3 failures stays `failed` | `DeliveryStatusPollerJob` retry logic |
| BR-COM-012 | Circular `expiry_date` must be >= `issued_date` if provided | FormRequest → HTTP 422 on violation |
| BR-COM-013 | Teachers can only send in-app messages to parents of students in their own class/section(s) | `MessagePolicy` → HTTP 403 |
| BR-COM-014 | Template `body_template` must contain a `{{variable}}` placeholder if `variables_json` is non-empty | Template FormRequest save validation |
| BR-COM-015 | Emergency alert requires two-step: `POST /emergency/preview` then `POST /emergency/confirm` with returned `alert_id` | `EmergencyAlertController` — no single-step endpoint exists |
| BR-COM-016 | DLT `{#var#}` variable values exceeding declared `max_length` are truncated with a dispatch warning | `SmsService::reconstructBody()` + warning to `sys_activity_logs` |
| BR-COM-017 | WhatsApp webhook must be HMAC-SHA256 verified before processing | `WebhookController` — returns HTTP 403 and logs on failure |
| BR-COM-018 | Campaigns > 500 recipients use `PrepareRecipientsJob` async; message stays `dispatching` until complete | `CommunicationService` (count check before sync/async split) |

---

## State Machine Summaries

### CHT — CommonChat

| FSM | States |
|-----|--------|
| Message lifecycle | `is_deleted = 0` (active) → `is_deleted = 1, body = NULL` (soft-deleted). No further state. Row retained permanently (or until `ChtPurgeOldMessagesJob` per retention setting). |
| User presence | `(online)` if `last_seen_at > UTC_TIMESTAMP() - INTERVAL 60 SECOND`, else `(offline)`. Updated by 30-second heartbeat upsert. |
| Conversation archive | `is_archived = 0` (active, read-write) → `is_archived = 1` (read-only school-wide). Admin only; no reverse specified. |
| Participant membership | `joined_at SET, left_at NULL` (active) → `left_at SET` (left group; cannot send/receive). No re-join specified. |
| Mute state | `muted_until NULL` (unmuted) → `muted_until = future timestamp` (time-limited mute) or `'9999-12-31'` (indefinite) → `NULL` (unmuted). |
| Read receipt | `read_at NULL` (unread) → `read_at SET` (read). Immutable — never rolled back to unread. |

### COM — Communication

| FSM | States |
|-----|--------|
| Message status (`com_messages.status`) | `draft` → `scheduled` or `dispatching`; `scheduled` → `dispatching` or `cancelled`; `dispatching` → `sent` or `partial_failure` or `failed`. Terminal: `sent`, `partial_failure`, `failed`, `cancelled`. |
| Recipient delivery (`com_message_recipients_jnt.delivery_status`) | `queued` → `dispatched` → `delivered` → `read` (in-app); `queued` → `skipped` (DND/opted-out/no FCM token); `dispatched` → `failed` → (retry if `retry_count < 3`) → back to `queued`; `dispatched` → `bounced` (email hard bounce / permanent SMS failure). Terminal: `read`, `skipped`, `bounced`, `failed` (after 3 retries). |
| Emergency alert status (`com_emergency_alerts.status`) | `pending_confirmation` → `dispatching` → `sent` or `partial_failure` or `failed`. Terminal: `sent`, `partial_failure`, `failed`. |
| WhatsApp template approval (`com_whatsapp_templates.approval_status`) | `pending_approval` → `approved` or `rejected`; `approved` → `paused` or `disabled`. Only `approved` templates can be dispatched. |
| Circular acknowledgement | Not a state machine — `com_circular_acknowledgements` row is created once and is immutable (UNIQUE prevents duplication). |

---

## Cross-Module Dependencies

### CHT — CommonChat

#### Inbound (CHT reads from)

| Module | Table | Data Used |
|--------|-------|-----------|
| System (SYS) | `sys_users` | User identity for sender, participants, `created_by`, `deleted_by`, `updated_by` |
| System (SYS) | `sys_roles` | Role-pair permission configuration in `cht_permission_config` and `cht_personalization_settings` |
| Spatie Media Library | `spatie_media` (logical) | Group avatar (`avatar_media_id`) and attachment thumbnails (`thumbnail_media_id`) |

#### Outbound (what CHT triggers / what modules read from CHT)

| Module | Integration |
|--------|-------------|
| Notification (NTF) | CHT triggers NTF push notifications for new messages when `notify_on_new_message = 1` and `notify_on_mention = 1` |
| Student Portal (STP) | Reads `cht_conversations`, `cht_messages`, `cht_participants` for student chat UI |
| Parent Portal (PPT) | Reads same tables for parent chat with teachers |

### COM — Communication

#### Inbound (COM reads from)

| Module | Table | Data Used |
|--------|-------|-----------|
| System (SYS) | `sys_users` | Sender identity, recipient phone/email, role assignments |
| System (SYS) | `sys_media` | File attachments for messages and circulars |
| System (SYS) | `sys_activity_logs` | Audit writes for all dispatch events, config changes, emergency confirmations |
| SchoolSetup (SCH) | `sch_classes`, `sch_sections` | Class/section-based audience targeting |
| StudentMgmt (STD) | `std_students`, `std_student_parents_jnt` | Parent-of-student relationship for class-level parent targeting |
| Notification (NTF) | `ntf_user_devices` | FCM device tokens for push dispatch (read-only) |
| Notification (NTF) | `ntf_notifications` | Push dispatch cross-reference (`ntf_notification_ref_id` on `com_messages`) |
| Notification (NTF) | `ntf_channels`, `ntf_templates` | Channel config and automated template references |

#### Outbound — Modules That Trigger COM

| Module | Event Key | Trigger Condition |
|--------|-----------|-------------------|
| StudentFee | `fee.due_reminder` | 7 days + 1 day before fee due date |
| StudentFee | `fee.overdue_notice` | 1 day after due if unpaid |
| StudentFee | `fee.receipt_issued` | On payment confirmation |
| Attendance | `attendance.absent_alert` | Same day 4 PM if student marked absent |
| Attendance | `attendance.low_attendance` | Weekly if attendance < school threshold |
| Examination | `exam.timetable_released` | On timetable publish |
| Examination | `exam.result_published` | On result publish |
| Events/Calendar | `ptm.reminder` | 7 days + 1 day before PTM |
| Admission | `admission.welcome` | On admission confirmation |
| Homework (LMS) | `homework.assigned` | On homework publish |
| Hostel | `hostel.fee_due` | 7 days before hostel fee due |

All triggers call `CommunicationEventService::trigger(string $event, array $context)` — no direct `com_*` table writes from external modules.

#### Outbound (what COM calls externally)

| Direction | Target | What |
|-----------|--------|------|
| COM → NTF | `NotificationService::dispatchBulkPush()` | All push channel deliveries delegated to NTF; COM never calls FCM directly |
| COM → SYS | `sys_activity_logs` | Audit records for dispatches, gateway config changes, emergency alert confirmations |
| COM → NTF | `ntf_user_devices` (read-only) | FCM token lookup before push dispatch |

---

## Technology Stack Notes

### CHT — CommonChat

- **Spatie Media Library**: Group avatars (`avatar_media_id` on `cht_conversations`) and attachment thumbnails (`thumbnail_media_id` on `cht_attachments`). Library manages its own `spatie_media` table; FK constraints intentionally absent.
- **Storage path**: Chat attachments stored at `storage/tenant_{uuid}/chat-attachments/`. Path in `cht_attachments.file_path` is relative to tenant disk root.
- **Presence polling**: Client pings heartbeat endpoint every 30 seconds. Online threshold = `last_seen_at > NOW() - 60 seconds`. No WebSocket dependency in Phase 1.
- **MySQL 8.0+ required**: `dm_pair_hash` uses a STORED generated column with `LEAST()`/`GREATEST()` functions — not available on MySQL 5.7. Block migration on MySQL < 8.0.
- **Concurrency for unread count**: `unread_count` on `cht_participants` incremented via `DB::transaction()` to prevent concurrent double-increment.
- **Scheduled job**: `ChtPurgeOldMessagesJob` runs daily; hard-deletes messages older than `cht_settings.message_retention_days` (0 = keep forever).
- **Large-group receipts**: `cht_message_receipts` is highest-volume table; batched insert when sending to groups.

### COM — Communication

- **Two queue workers required**: `communications` (normal campaigns) and `emergency` (isolated highest priority). Never process on the same worker process.
- **Batch sizes**: SMS 100/batch, Email 50/batch, WhatsApp 50/batch. All bulk dispatch via queued jobs; HTTP request returns < 2 seconds after queuing.
- **SMS providers**: MSG91, Twilio, Kaleyra, Textlocal, Fast2SMS (selectable via `provider_name`; adapter pattern).
- **Email drivers**: SMTP, SES, Mailgun, SendGrid, Postmark (selectable via `driver_name`; Laravel Mail dynamic transport).
- **WhatsApp**: Meta Cloud API (or BSP via `base_url`); outbound template messages only; delivery status webhooks.
- **DomPDF**: PDF report generation (delivery reports, acknowledgement reports, SMS usage, emergency alert reports).
- **fputcsv**: CSV report generation — all report types.
- **HTMLPurifier**: In-app message body sanitization before storage; strips `<script>`, `<iframe>`, `javascript:` hrefs, inline event handlers.
- **Emogrifier**: CSS inlining for email Blade templates before dispatch (email client compatibility).
- **Laravel `encrypt()` (AES-256-CBC)**: Gateway API keys, WhatsApp tokens, SMTP passwords encrypted at rest; decrypted in memory during dispatch only.
- **HMAC-SHA256**: Webhook signature verification for WhatsApp + SMS gateway delivery callbacks.
- **Redis cache**: DND filter results cached with 6-hour TTL per phone number.
- **Rate limiting**: `max_per_second` (default 10) on `com_gateway_configs`; webhook endpoints throttled 1000 req/min per IP via Laravel throttle middleware.
- **Sanctum auth**: All mobile API endpoints use `auth:sanctum` middleware.
- **TRAI DLT compliance**: DLT Template ID, Sender ID, and DLT Entity ID in every SMS API call headers. NCPR (DND registry) filter mandatory.
- **Scheduled jobs**: `ProcessScheduledMessagesJob` (every 5 min; `withoutOverlapping()` lock); `ProcessRecurringRulesJob` (every 15 min); `DeliveryStatusPollerJob` (every 15 min; polls for up to 24 hours); `SyncCommunicationGroupsJob` (daily midnight); `CircularDeadlineJob` (daily 8 AM).

---

## Implementation Blockers / Prerequisites

### CHT — CommonChat

| # | Prerequisite | Owner Module | Blocks |
|---|-------------|-------------|--------|
| 1 | `sys_users` table complete + seeded | System (SYS) | All cht_* tables (sender_id, user_id, created_by, deleted_by) |
| 2 | `sys_roles` table seeded with all school roles | System (SYS) | `cht_permission_config` (FK on permission_for_role_id, allowed_whom_to_connect_with) |
| 3 | Spatie Media Library installed + migrations run | SYS / DevOps | `cht_conversations.avatar_media_id`, `cht_attachments.media_id` |
| 4 | MySQL 8.0+ confirmed | DevOps | `dm_pair_hash` STORED generated column (`LEAST`/`GREATEST`) |
| 5 | DDL syntax errors fixed | DB Architect | Migration cannot run as-is (missing comma in `cht_settings`; verify `cht_permission_config` closing statement) |
| 6 | `CHT_Requirements_v1.md` read | Business Analyst | Full CHT feature scope may exceed what DDL covers; may need additional tables |
| 7 | NTF module push dispatch functional | Notification (NTF) | CHT new-message push notifications |

### COM — Communication

| # | Prerequisite | Owner Module | Blocks |
|---|-------------|-------------|--------|
| 1 | NTF-GAP-001: Fix gate prefix `prime.*` → `tenant.*` | NTF | All ntf_* permission checks used by COM |
| 2 | NTF-GAP-002: Uncomment ntf_* routes (Phase 1 first) | NTF | COM push channel integration |
| 3 | NTF-GAP-005: Implement `NotificationService::dispatchBulkPush()` with real FCM | NTF | FR-COM-010 push channel |
| 4 | NTF-GAP-007: Seed standard notification templates | NTF | Event-triggered automated notifications |
| 5 | NTF-GAP-006: Add `polling_until` to `ntf_deliveries` | NTF | Delivery status polling integration |
| 6 | `sys_users`, `sys_media` complete | SYS | All com_* created_by, sender_id, recipient_id, attachment storage |
| 7 | `sch_classes`, `sch_sections` complete | SCH | Audience targeting (class/section) |
| 8 | `std_students`, `std_student_parents_jnt` complete | STD | Parent-of-student targeting for class-level messages |
| 9 | `com_*` DDL file written and reviewed | DB Architect | All COM development blocked until DDL exists |
| 10 | DLT registration completed by school admin | School Admin / External | FR-COM-001 to FR-COM-005 (SMS channel); 2–7 business days per step |
| 11 | WABA approval (6+ weeks lead time) | School Admin / Meta | WhatsApp channel (Phase 4); must begin before Phase 4 sprint starts |

---

## Implementation Sequence

### CHT — CommonChat (Recommended)

| Phase | Components |
|-------|-----------|
| Prerequisites | SYS (`sys_users`, `sys_roles`) complete; Spatie Media Library installed; DDL syntax errors fixed; MySQL 8.0+ confirmed |
| CHT Phase 1 | Core tables migrated; `ChtSettingsSeeder` + `cht_permission_config` seeded with school role pair defaults |
| CHT Phase 2 | `cht_personalization_settings` (lazy create on first chat access); presence tracking (`cht_user_presence` heartbeat endpoint) |
| CHT Phase 3 | Conversations (DM + Group + Announcement) + Participants; DM uniqueness enforcement via `dm_pair_hash` |
| CHT Phase 4 | Messages (send + reply threading + soft-delete); `cht_message_receipts` (read receipts); unread count management in `cht_participants` |
| CHT Phase 5 | Attachments (`cht_attachments`); file upload + thumbnail generation via Spatie |
| CHT Phase 6 | Mute / Pin / Archive per user; admin access revocation (`is_deactivated_by_admin`) |
| CHT Phase 7 | Mobile API endpoints; push notification integration with NTF; `ChtPurgeOldMessagesJob` |

### COM — Communication (from V2 Requirement Section 16)

| Phase | Sprint | Components | Est. Effort |
|-------|--------|-----------|-------------|
| Phase 0 | Sprint 0 | NTF module prerequisite fixes (NTF-GAP-001 to NTF-GAP-007) | 6 days |
| Phase 1 | Sprint 1–2 | `com_*` DDL migrations + seeders; Group Management (FR-COM-021, 022); Circular Management (FR-COM-014, 015, 016); In-App Direct Messaging (FR-COM-011, 012); Message Moderation (FR-COM-013) | ~15 days |
| Phase 2 | Sprint 3–4 | SMS Gateway + DLT Templates (FR-COM-001, 002); SMS Compose + Delivery Tracking (FR-COM-003, 004, 005); Email Gateway (FR-COM-006); Email Campaign + Templates (FR-COM-007, 008) | ~13 days |
| Phase 3 | Sprint 5 | Message Scheduling (FR-COM-023); Recurring Rules (FR-COM-009); Push Notifications (FR-COM-010); User Preferences (FR-COM-019); Emergency Alert Broadcast (FR-COM-017, 018) | ~12 days |
| Phase 4 | Sprint 6–7 | Event Trigger Contract (FR-COM-020) + module integrations; WhatsApp Gateway + Templates; Analytics Dashboard (FR-COM-024); Reports (FR-COM-025); Mobile API (18 endpoints) | ~17 days |

---

## Immutable / Special Records

### CHT — CommonChat

| Table | Reason | Missing Standard Columns |
|-------|--------|--------------------------|
| `cht_message_receipts` | Immutable delivery audit log; append-only | No `deleted_at`, no `created_by`, no `updated_by`, no `is_active` |
| `cht_attachments` | Follows message lifecycle via FK cascade; not independently soft-deleted | No `deleted_at` |
| `cht_user_presence` | Ephemeral state; no audit trail needed | No `deleted_at`, no `created_by`, no `updated_by`, no `is_active` |
| `cht_settings` | Singleton; `id = 1` always exists; never deleted | No `deleted_at`, no `is_active` |
| `cht_personalization_settings` | Has `created_by` but no `updated_by` | No `updated_by` |

### COM — Communication

| Table | Reason | Missing Standard Columns |
|-------|--------|--------------------------|
| `com_message_recipients_jnt` | Per-recipient delivery log; rows retained for audit | No `deleted_at` |
| `com_circular_acknowledgements` | Immutable acknowledgement record; UNIQUE enforces one-per-user | No `deleted_at` |
| `com_message_flags` | Immutable moderation audit record | No `deleted_at` |
| `com_message_template_translations` | Deactivation via `is_active = 0` only; not soft-deleted | No `deleted_at` |
| `com_user_preferences` | Preference rows are never removed; only `is_opted_in` toggled | No `deleted_at` |
| `com_circular_targets_jnt` | Audience targeting snapshot; no per-target soft-delete needed | No `deleted_at`, no `created_by` (per req proposal) |
| `com_event_trigger_rules` | System rules (`is_system = 1`) are not deletable; deactivate via `is_active = 0` | No `deleted_at` (per req proposal) |
| `com_school_settings` | Key-value store; no lifecycle management | No `deleted_at`, no `is_active` |

---

## Pending Next Steps

- [ ] **Fix CHT DDL syntax errors**: missing comma after `PRIMARY KEY` in `cht_settings`; verify `cht_permission_config` closing statement in `Sch_CommonChat_DDL_v1.sql`
- [ ] **Read `CHT_Requirements_v1.md`** — the actual CHT requirement file (not the COM req) to verify DDL covers all CHT features (reactions? @mention tracking table? search index?)
- [ ] **Write `com_*` DDL** — `act as DB Architect` — create DDL for all 14+ proposed COM tables; apply INT UNSIGNED type corrections throughout
- [ ] **Validate CHT DDL vs CHT requirement** — confirm no missing tables beyond the 8 in DDL
- [ ] **Generate FRD for CHT** — `act as Business Analyst` → "create an FRD for CommonChat"
- [ ] **Generate FRD for COM** — `act as Business Analyst` → "create an FRD for Communication"
- [ ] **Resolve NTF module gaps** (NTF-GAP-001 to NTF-GAP-007) before starting COM Phase 0
- [ ] **Clarify module code alignment**: status file uses "COM" for CommonChat (cht_* prefix); V2 req doc is for a different "Communication" module (com_* prefix) — determine if these should be two separate entries in the status file
- [ ] **Confirm MySQL 8.0+** on all tenant database servers before running CHT migration
- [ ] **Decide WebSocket vs polling** for real-time CHT message delivery (DDL supports both; affects infra choice)
- [ ] **Verify Spatie Media Library** multi-tenant disk routing for `chat-attachments/` (tenant UUID disk path)
- [ ] **Code Gap Analysis** — after FRDs generated — `act as Technical Auditor`

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Initial seed: CHT DDL facts from `Sch_CommonChat_DDL_v1.sql` (8 cht_* tables) + COM V2 requirement facts from `COM_Communication_Requirement.md` (25 FRs, 18 BRs, 14 proposed com_* tables). Two distinct modules documented. DDL syntax errors identified. INT UNSIGNED type corrections catalogued for COM DDL write. State machines, business rules, cross-module dependencies, and implementation sequence extracted from both sources. |
| 2026-06-27 | Business Analyst | File updated with full 15-section format matching CAF_Cafeteria.md reference format. Additional design decisions, DDL gaps table, and immutable records section added. |
