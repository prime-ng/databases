# Notification Module — Deep Gap Analysis & Implementation Blueprint

> **Document Version:** 1.0  
> **Last Updated:** 2026-05-29  
> **Module:** Notification (`ntf_*` prefix)  
> **DDL Source:** `tenant_db_v3.sql` (15 notification tables)  
> **Codebase:** `/home/shail/project/Modules/Notification/`  
> **Analyst:** AntiGravity AI Brain  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Purpose & Scope](#2-module-purpose--scope)
3. [DDL Schema Deep Dive](#3-ddl-schema-deep-dive)
4. [Current Implementation Status](#4-current-implementation-status)
5. [Tab-by-Tab Implementation Analysis](#5-tab-by-tab-implementation-analysis)
6. [Architecture & Data Flow](#6-architecture--data-flow)
7. [Critical Gaps & Missing Components](#7-critical-gaps--missing-components)
8. [Phase-Wise Implementation Roadmap](#8-phase-wise-implementation-roadmap)
9. [Security Audit](#9-security-audit)
10. [Performance Considerations](#10-performance-considerations)
11. [Module Integration Points](#11-module-integration-points)
12. [Appendix: File Inventory](#12-appendix-file-inventory)

---

## 1. Executive Summary

The Notification module is designed as a **unified, multi-channel notification orchestration engine** capable of dispatching messages via Email, SMS, WhatsApp, In-App (database), and Push Notifications. It features a comprehensive schema with 15 tables supporting template management, channel configuration, provider integration, target group resolution, delivery queuing, delivery logging, thread grouping, recurring scheduling, and user preference management.

**Current completion estimate: ~55%**  

The **CRUD layer is largely complete** — 12 controllers, 14 models, 62 view files, 10 FormRequests, and a functional facade/event/listener pipeline exist. However, the **actual notification delivery pipeline is severely incomplete**. Only 2 of 5 channels (EMAIL and IN_APP) have working delivery code. SMS, WhatsApp, and Push are stubs. The delivery queue exists as a data structure but has no worker process consuming it. Recurring schedules are schema-defined but not wired to any cron job. Real provider integrations (Twilio, MSG91, AWS SES, Firebase) are not implemented.

---

## 2. Module Purpose & Scope

### 2.1 What This Module Should Do

The Notification module serves as the **central nervous system** for all communication within the Prime AI platform. It provides:

1. **Multi-Channel Delivery** — Send notifications via Email, SMS, WhatsApp, In-App (database), and Push Notifications from a single unified API
2. **Template Management** — Create and manage message templates with `{{placeholder}}` variable substitution per channel
3. **Target Resolution** — Resolve recipient lists from static groups, dynamic queries, or direct user selection
4. **Delivery Orchestration** — Queue, prioritize, send, retry, and track every notification with full audit trail
5. **User Preference Management** — Respect user opt-in/opt-out, quiet hours, daily digest, and channel preferences
6. **Provider Abstraction** — Support multiple providers per channel with automatic fallback (e.g., AWS SES → SMTP for email, Twilio → MSG91 for SMS)
7. **Threading & Grouping** — Group related notifications into threads for conversation-style or digest delivery
8. **Recurring & Scheduled Delivery** — Schedule one-time, recurring, or trigger-based notification campaigns
9. **Cost Tracking** — Track per-notification cost for billing and analytics

### 2.2 Architecture Design Principles

- **Event-Driven Dispatch** — Modules dispatch notifications via `Notification::dispatch('event_code', $payload)` — they never call providers directly
- **Provider Abstraction** — ChannelMaster → ProviderMaster → ProviderClass (strategy pattern). Adding a new provider requires only a new ProviderClass implementation
- **Async by Default** — All notification processing is queued (ShouldQueue) to avoid blocking HTTP requests
- **Audit Everything** — Every delivery attempt, retry, failure, read, and click is logged immutably
- **Tenant-Isolated** — All notification configurations are per-tenant (tenant_id FK on all config tables)

---

## 3. DDL Schema Deep Dive

The Notification module defines **15 tables** under the `ntf_` prefix in `tenant_db_v3.sql` (lines 2351–2811). Below is an exhaustive analysis of each table.

### 3.1 Core Configuration Layer

#### `ntf_channel_master` (Line 2351) — Channel Definitions

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | Primary key |
| `tenant_id` | INT UNSIGNED NOT NULL | Multi-tenant isolation |
| `code` | VARCHAR(20) NOT NULL | `EMAIL`, `SMS`, `WHATSAPP`, `IN_APP`, `PUSH` |
| `name` | VARCHAR(50) NOT NULL | Display name |
| `description` | VARCHAR(255) NULL | Human-readable description |
| `channel_type` | ENUM('IMMEDIATE','BULK','TRANSACTIONAL') | Delivery classification |
| `priority_order` | TINYINT(1-10) | Channel priority (1=highest) |
| `max_retry` | INT DEFAULT 3 | Max retry attempts |
| `retry_delay_minutes` | INT DEFAULT 5 | Delay between retries |
| `rate_limit_per_minute` | INT DEFAULT 100 | Rate limiting |
| `daily_limit` | INT DEFAULT 10000 | Daily cap |
| `monthly_limit` | INT DEFAULT 100000 | Monthly cap |
| `cost_per_unit` | DECIMAL(10,4) | Per-message cost |
| `fallback_channel_id` | INT UNSIGNED NULL | Auto-fallback on failure |
| `is_active` | TINYINT(1) | Soft enable/disable |
| `deleted_at` | TIMESTAMP NULL | Soft delete |

**Unique Key:** `(tenant_id, code)`  
**Self-Referential FK:** `fallback_channel_id → ntf_channel_master.id`  
**Indexes:** `tenant_id`, `code`

**Analysis:** This is the channel registry. Each tenant defines which channels they support. The fallback chain allows automatic channel downgrade (e.g., WhatsApp fails → SMS fallback). Rate limiting and cost tracking are built into the schema but not implemented in code.

---

#### `ntf_provider_master` (Line 2380) — Provider Configurations

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | Primary key |
| `tenant_id` | INT UNSIGNED NOT NULL | Multi-tenant |
| `channel_id` | INT UNSIGNED NOT NULL | FK → ntf_channel_master |
| `provider_name` | VARCHAR(50) | e.g., Twilio, MSG91, AWS SES, Firebase |
| `provider_type` | ENUM('PRIMARY','SECONDARY','BACKUP') | Role in channel |
| `api_endpoint` | VARCHAR(500) | API base URL |
| `api_key_encrypted` | TEXT | Encrypted API key |
| `api_secret_encrypted` | TEXT | Encrypted API secret |
| `from_address` | VARCHAR(255) | Sender email/phone |
| `configuration` | JSON | Provider-specific settings |
| `priority` | TINYINT(1-10) | Selection priority |
| `is_active` | TINYINT(1) | Enable/disable |
| `deleted_at` | TIMESTAMP NULL | Soft delete |

**FK:** `channel_id → ntf_channel_master.id`  

**Analysis:** Supports multiple providers per channel with PRIMARY/SECONDARY/BACKUP roles. API credentials are stored encrypted (column names say `_encrypted`). The `configuration` JSON column stores provider-specific settings (e.g., AWS region, Twilio webhook URL). Currently, no actual provider SDK integration exists — the data can be stored but no code uses it to send messages.

---

### 3.2 Template Layer

#### `ntf_templates` (Line 2606) — Message Templates

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | Primary key |
| `tenant_id` | INT UNSIGNED NOT NULL | Multi-tenant |
| `template_code` | VARCHAR(50) | Unique code per tenant |
| `template_name` | VARCHAR(100) | Display name |
| `channel_id` | INT UNSIGNED NOT NULL | FK → ntf_channel_master |
| `template_version` | INT DEFAULT 1 | Version counter |
| `subject` | VARCHAR(255) | Subject line (email) |
| `body` | TEXT NOT NULL | Main content with `{{placeholders}}` |
| `alt_body` | TEXT | Plain text version |
| `placeholders` | JSON | List of required variables |
| `language_code` | VARCHAR(10) DEFAULT 'en' | Language |
| `media_id` | INT UNSIGNED NULL | FK → sys_media |
| `is_system_template` | TINYINT(1) | System-defined (not editable) |
| `approval_status` | ENUM('DRAFT','PENDING','APPROVED','REJECTED','ARCHIVED') | Workflow status |
| `approved_by` | INT UNSIGNED NULL | Approver user ID |
| `effective_from` / `effective_to` | DATETIME | Validity period |
| `is_active` | TINYINT(1) | Enable/disable |

**Unique Key:** `(tenant_id, template_code, template_version)`  
**FKs:** `channel_id → ntf_channel_master`, `media_id → sys_media`

**Analysis:** Full versioning support (template_code + version), approval workflow (DRAFT → PENDING → APPROVED → REJECTED), channel-specific templates, multi-language support, placeholder extraction, and validity periods. The `render($payload)` method exists on the model and correctly replaces `{{key}}` placeholders. Approval workflow UI exists in `TemplateController`.

---

### 3.3 Target Resolution Layer

#### `ntf_target_groups` (Line 2501) — Reusable Target Groups

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | Primary key |
| `tenant_id` | INT UNSIGNED NOT NULL | Multi-tenant |
| `group_name` | VARCHAR(100) | Display name |
| `group_code` | VARCHAR(50) | System code |
| `description` | VARCHAR(255) | Description |
| `group_type` | ENUM('STATIC','DYNAMIC') | Static (manual) or Dynamic (query-based) |
| `dynamic_query` | TEXT | JSON/SQL for dynamic resolution |
| `total_members` | INT DEFAULT 0 | Cached count |
| `last_refreshed_at` | DATETIME | Last resolution timestamp |
| `is_system_group` | TINYINT(1) | Built-in group (not editable) |
| `is_active` | TINYINT(1) | Enable/disable |
| `created_by` | INT UNSIGNED | Creator |

**Unique Key:** `(tenant_id, group_code)`  

**Analysis:** Supports two group types: STATIC (manual member selection — the pivot table `ntf_target_group_members` is missing from DDL) and DYNAMIC (query-based — the `dynamic_query` JSON would contain filter criteria). The `refreshMembers()` method exists on `TargetGroupController` but only updates `last_refreshed_at` — it does not execute the query.

**CRITICAL MISSING TABLE:** `ntf_target_group_members` — This pivot table is required for STATIC groups to store individual member-to-group associations. The DDL defines `ntf_target_groups` but no junction table for static group membership.

---

#### `ntf_notification_targets` (Line 2526) — Per-Notification Target Definitions

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT UNSIGNED PK | Primary key |
| `notification_id` | INT UNSIGNED NOT NULL | FK → ntf_notifications |
| `target_type_id` | INT UNSIGNED NOT NULL | FK → sys_dropdown_table |
| `target_group_id` | INT UNSIGNED NULL | FK → ntf_target_groups |
| `target_table_name` | VARCHAR(60) | Direct table reference |
| `target_selected_id` | INT UNSIGNED NULL | Direct record ID |
| `target_condition` | JSON | Additional filter criteria |
| `estimated_count` | INT | Pre-resolution estimate |
| `actual_count` | INT | Post-resolution count |
| `is_active` | TINYINT(1) | Enable/disable |

**FKs:** `notification_id → ntf_notifications`, `target_type_id → sys_dropdown_table`, `target_group_id → ntf_target_groups`

**Analysis:** Targets can be: (a) a reusable group, (b) a direct table/record reference, or (c) a condition-based filter. The `resolveTargets()` method exists on `NotificationTargetController` but is a stub that does not perform actual resolution.

---

### 3.4 Core Notification Layer

#### `ntf_notifications` (Line 2404) — Notification Request Registry

This is the **central table** of the module. Key columns:

| Field | Purpose |
|-------|---------|
| `notification_uuid` CHAR(36) | Public-facing unique ID for tracking |
| `source_module` VARCHAR(50) | Which module triggered this (e.g., 'hostel', 'complaint') |
| `source_record_id` INT | ID of the triggering record |
| `notification_event` VARCHAR(50) | Event code (e.g., 'hostel.complaint.escalated') |
| `notification_type` ENUM | TRANSACTIONAL / PROMOTIONAL / ALERT / REMINDER / DIGEST |
| `title` / `description` | Notification content |
| `template_id` | FK → ntf_templates |
| `priority_id` | FK → sys_dropdown_table |
| `schedule_type` | IMMEDIATE / SCHEDULED / RECURRING / TRIGGERED |
| `scheduled_at` | When to send |
| `recurring_pattern` | NONE / HOURLY / DAILY / WEEKLY / MONTHLY / YEARLY / CUSTOM |
| `recurring_expression` | Cron or RRULE |
| `expires_at` | Auto-expiry |
| `total_recipients` / `sent_count` / `failed_count` / `delivered_count` / `read_count` / `click_count` | Aggregated tracking counters |
| `estimated_cost` / `actual_cost` | Cost tracking |
| `notification_status_id` | FK → sys_dropdown_table (DRAFT/SCHEDULED/PROCESSING/COMPLETED/PARTIAL/FAILED/CANCELLED/EXPIRED) |
| `is_manual` | Manually created (vs. system-triggered) |
| `created_by` / `approved_by` / `approved_at` | Audit trail |

**Analysis:** Extremely comprehensive schema. Supports every delivery pattern imaginable. However, most computed fields (`total_recipients`, `sent_count`, `failed_count`, `delivered_count`, `read_count`, `click_count`, `estimated_cost`, `actual_cost`) are never actually calculated — they remain at default values because the delivery pipeline is incomplete.

---

#### `ntf_notification_channels` (Line 2468) — Channel Assignments per Notification

Pivot table linking a notification to its channels. Key fields:

| Field | Purpose |
|-------|---------|
| `channel_id` | FK → ntf_channel_master |
| `provider_id` | FK → ntf_provider_master (optional override) |
| `template_id` | FK → ntf_templates (optional template override per channel) |
| `sending_order` | Sequence for fallback chain |
| `status_id` | FK → sys_dropdown_table |
| `sent_at` | Actual send timestamp |
| `retry_count` / `max_retry` / `next_retry_at` | Retry tracking |

**Analysis:** Supports per-channel template overrides and provider overrides. The fallback chain is defined by `sending_order`. Currently, `NotificationService::trigger()` reads channels from this table but only processes EMAIL and IN_APP — it skips SMS, WHATSAPP, and PUSH with just a log message.

---

### 3.5 Delivery Processing Layer

#### `ntf_resolved_recipients` (Line 2643) — Final Recipient List

| Field | Purpose |
|-------|---------|
| `resolved_user_id` | FK → sys_user |
| `channel_id` | FK → ntf_channel_master |
| `template_id` | FK → ntf_templates |
| `recipient_address` | Resolved email/phone |
| `personalized_subject` / `personalized_body` | Rendered with `{{placeholders}}` |
| `personalization_data` JSON | The actual placeholder values used |
| `device_id` | For push notifications |
| `batch_id` / `batch_sequence` | Batch processing support |
| `is_processed` | Processing flag |

**Analysis:** This table stores the fully resolved, personalized, ready-to-send recipient record. The `personalized_subject` and `personalized_body` are pre-rendered with actual values — no template processing needed at send time. Batch processing is supported via `batch_id`. This is the **input** to the delivery queue.

---

#### `ntf_delivery_queue` (Line 2684) — Send Queue

| Field | Purpose |
|-------|---------|
| `resolved_recipient_id` | FK → ntf_resolved_recipients |
| `notification_id` | FK → ntf_notifications |
| `channel_id` / `provider_id` | Target channel + provider |
| `queue_status` | PENDING / PROCESSING / SENT / FAILED / RETRY / CANCELLED |
| `priority` | Send priority (lower = higher priority) |
| `scheduled_at` | When to send |
| `locked_by` / `locked_at` | Worker lock (prevents double-processing) |
| `attempt_count` / `max_attempts` / `last_error` / `next_attempt_at` | Retry tracking |

**Analysis:** This is a **database-backed work queue**. Statuses: PENDING → PROCESSING → SENT | FAILED | CANCELLED. RETRY is used when a retry is scheduled. Worker locking via `locked_by`/`locked_at` prevents multiple workers from processing the same item. However, there is **no worker/daemon process** that actually consumes this queue. The `process()` method on `DeliveryQueueController` merely changes the status to PROCESSING — it does not invoke any provider.

---

#### `ntf_delivery_logs` (Line 2716) — Delivery Audit Trail

| Field | Purpose |
|-------|---------|
| `delivery_stage` | QUEUED → SENT → DELIVERED → READ → CLICKED → BOUNCED → COMPLAINT → UNSUBSCRIBED |
| `provider_message_id` | External provider message ID |
| `delivered_at` / `read_at` / `clicked_at` / `bounced_at` | Timeline tracking |
| `response_code` / `response_payload` JSON | Provider response |
| `duration_ms` | Delivery latency |
| `ip_address` / `user_agent` | Read/click tracking |
| `cost` | Per-message cost |

**Analysis:** Full delivery lifecycle tracking from QUEUED through SENT, DELIVERED, READ, CLICKED, to potential BOUNCE/COMPLAINT. Webhook support via `provider_message_id` for delivery status callbacks. Currently used by `NotificationService::trigger()` for EMAIL and IN_APP channels but not for SMS/WHATSAPP/PUSH.

---

### 3.6 Threading Layer

#### `ntf_notification_threads` (Line 2759) — Notification Threads

Groups related notifications into conversations or digests. Supports parent-child thread hierarchy for nested conversations. Three thread types: CONVERSATION (chat-like), DIGEST (batched summary), BROADCAST (one-to-many).

#### `ntf_notification_thread_members` (Line 2783) — Thread-Notification Association

Ordered junction table linking notifications to threads with sequence ordering for conversation-style display.

---

### 3.7 Schedule Audit Layer

#### `ntf_schedule_audit` (Line 2799) — Recurring Execution Log

Tracks every execution of recurring/scheduled notifications. Each row records the parent notification, the child instance, execution timestamps, and status (PENDING/SUCCESS/FAILED/SKIPPED).

**STATUS: NOT IMPLEMENTED.** No model, controller, views, or cron job exists for this table.

---

### 3.8 Device Registry

#### `ntf_user_devices` (Line 2553) — Push Notification Devices

| Field | Purpose |
|-------|---------|
| `user_id` | FK → sys_user |
| `device_type` | ANDROID / IOS / WEB / DESKTOP |
| `device_token` | Push notification token |
| `device_name` | Device display name |
| `app_version` / `os_version` | App/OS version |
| `last_active_at` | Last seen timestamp |

**Unique Key:** `(user_id, device_token)` — one device per token per user.

**STATUS: PARTIALLY IMPLEMENTED.** Model exists (`UserDevice`) but no controller or views exist. Devices can only be registered via API (not implemented). There is no Firebase Cloud Messaging (FCM) or Apple Push Notification Service (APNS) integration.

---

### 3.9 User Preferences

#### `ntf_user_preferences` (Line 2575) — Per-User Channel Settings

| Field | Purpose |
|-------|---------|
| `user_id` | FK → sys_user |
| `channel_id` | FK → ntf_channel_master |
| `is_enabled` | Master enable |
| `is_opted_in` | GDPR consent |
| `contact_value` | Override email/phone |
| `quiet_hours_start` / `quiet_hours_end` | Do-not-disturb window |
| `daily_digest` / `digest_time` | Digest mode |
| `priority_threshold_id` | Minimum priority to receive |

**STATUS: IMPLEMENTED.** Full CRUD controller, views, model with all business rules.

---

## 4. Current Implementation Status

### 4.1 Overall Completion Matrix

| Component | DDL Tables | Models | Controllers | Views | Working Logic |
|-----------|-----------|--------|-------------|-------|--------------|
| Channel Master | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD |
| Provider Master | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ No real integration |
| Notifications | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ Status management, ⚠️ Delivery pipeline |
| Notification Channels | ✅ (1) | ✅ | ⚠️ No dedicated controller | ⚠️ No dedicated views | ⚠️ Managed inside NotificationManageController index |
| Target Groups | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ `refreshMembers()` is stub |
| Notification Targets | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ `resolveTargets()` is stub |
| Templates | ✅ (1) | ✅ | ✅ (2 controllers) | ✅ | ✅ CRUD, ✅ Approval workflow, ✅ Placeholder rendering |
| User Preferences | ✅ (1) | ✅ | ✅ | ✅ | ✅ Full CRUD, ✅ toggle-enabled |
| User Devices | ✅ (1) | ✅ | ❌ Missing | ❌ Missing | ❌ No API, No FCM/APNS |
| Resolved Recipients | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ `markAsProcessed()`, ⚠️ No real processing |
| Delivery Queue | ✅ (1) | ✅ | ✅ | ✅ | ✅ CRUD, ⚠️ `process()`/`retry()`/`cancel()` are stubs |
| Delivery Logs | ✅ (1) | ✅ | ❌ No dedicated controller | ✅ (views exist) | ⚠️ Used by NotificationService::trigger() for EMAIL/IN_APP only |
| Notification Threads | ✅ (1) | ✅ | ✅ | ✅ | ✅ Full CRUD, ✅ recalculateCounts |
| Thread Members | ✅ (1) | ✅ | ✅ | ✅ | ✅ Full CRUD, ✅ updateSequence (drag-drop) |
| Schedule Audit | ✅ (1) | ❌ Missing | ❌ Missing | ❌ Missing | ❌ Completely absent |

### 4.2 What Is Actually Working (Production-Ready)

1. **Channel Master CRUD** — Create, read, update, delete, toggle-status, soft-delete, restore for notification channels. Statistics endpoint available.

2. **Provider Master CRUD** — Full CRUD for provider configurations. API credentials can be stored (encrypted columns exist but encryption is not implemented — stored as plain text).

3. **Target Groups CRUD** — Full CRUD for static/dynamic target groups. `refreshMembers()` is a stub but does update timestamp.

4. **Notification Targets CRUD** — Full CRUD. `resolveTargets()` stub exists.

5. **Notification Templates CRUD** — Full CRUD with approval workflow (DRAFT→PENDING→APPROVED→REJECTED), version management, placeholder extraction via regex, duplicate capability. The `render($payload)` method on the model correctly substitutes `{{placeholders}}` with values.

6. **User Preferences CRUD** — Full CRUD with toggle-enabled, opt-in/out tracking, quiet hours.

7. **Resolved Recipients CRUD** — Full CRUD with batch processing, mark-as-processed, bulk-process. However, "processing" does not actually send anything.

8. **Delivery Queue CRUD** — Full CRUD with stats endpoint, process/retry/cancel actions (status transitions only, no actual delivery).

9. **Notification Threads CRUD** — Full CRUD with recalculate-counts for thread metrics.

10. **Notification Thread Members CRUD** — Full CRUD with drag-drop sequence ordering.

11. **Facade/Event Pipeline** — `Notification::dispatch('event_code', $payload)` → `NotificationDispatcher::dispatch()` → fires `SystemNotificationTriggered` event → `ProcessSystemNotification` listener (queued) → `NotificationService::trigger()` — This pipeline works end-to-end.

12. **NotificationService::trigger() for EMAIL** — Finds active notification by event code, resolves channels, finds matching template, renders with payload, calls `Mail::send()` with HTML body, logs delivery attempt to `NotificationDeliveryLog`. Attachments supported via `$payload['attachments']`.

13. **NotificationService::trigger() for IN_APP** — Calls `$user->notify(new InAppSystemNotification($content))` which stores the notification in the database `notifications` table via Laravel's database notification channel. Logs delivery in `NotificationDeliveryLog`.

### 4.3 What Is Partially Working

1. **Notification Manage (Main Tab Dashboard)** — The multi-tab index page loads data from all entities but some tabs have slow queries (N+1 loading). The `process()` action on notifications changes status to PROCESSING but does not actually send.

2. **Delivery Queue Stats Endpoint** — Returns counts grouped by queue_status but the data is stale since no worker processes the queue.

3. **Target Group Refresh** — Updates `last_refreshed_at` timestamp but doesn't actually resolve dynamic queries.

4. **Notification Target Resolve** — Updates `actual_count` from `estimated_count` but doesn't actually resolve recipients.

### 4.4 What Is Not Implemented

1. **User Devices (ntf_user_devices)** — No controller, no views, no API endpoint for device token registration, no FCM/APNS integration code.

2. **Schedule Audit (ntf_schedule_audit)** — No model, no controller, no views, no cron job, no recurring schedule processing logic.

3. **SMS Channel Delivery** — The `NotificationService::trigger()` method has a `case 'SMS':` block that logs "SMS not implemented" and returns. No SMS provider integration (Twilio, MSG91, TextLocal, etc.).

4. **WhatsApp Channel Delivery** — Same as SMS — only a log placeholder.

5. **Push Notification Delivery** — Same as SMS — only a log placeholder. Requires `ntf_user_devices` to be implemented first.

6. **Delivery Queue Worker** — No artisan command, no daemon process, no supervisor configuration to consume the delivery queue. The `DeliveryQueueController::process()` method exists but does not invoke any provider.

7. **Recurring Notification Cron** — No cron job to process SCHEDULED or RECURRING notifications. The `ntf_schedule_audit` table is designed to track executions but nothing writes to it.

8. **Provider Credential Encryption** — The `api_key_encrypted` and `api_secret_encrypted` columns exist but the code stores/retrieves them as plain text. No encryption/decryption service is implemented.

9. **Delivery Webhook Handling** — No controller or routes for receiving delivery status callbacks from providers (SES bounce/complaint webhooks, Twilio status callbacks, WhatsApp webhooks). The `ntf_delivery_logs` schema supports `provider_message_id` and `delivery_stage` but no webhook receiver exists.

10. **Rate Limiting** — The `channel_master` table has `rate_limit_per_minute`, `daily_limit`, `monthly_limit` columns but no code enforces these limits.

11. **Cost Tracking** — `estimated_cost` and `actual_cost` fields exist on `ntf_notifications` and `ntf_delivery_logs` but are never calculated.

12. **Read/Click Tracking** — `read_at`, `clicked_at`, `ip_address`, `user_agent` exist on `ntf_delivery_logs` but no mechanism to track them (requires tracking pixels for email, webhook callbacks for SMS, etc.).

13. **Active Migrations** — All migration files in the module's `database/migrations/` directory have `.bk` extension (backup copies). No active migration files exist. The actual tenant migrations are presumably managed elsewhere, but this means the module cannot be freshly installed from its own migrations.

14. **Static Group Members Pivot Table** — `ntf_target_group_members` is referenced in the code logic but does not exist in the DDL. STATIC groups cannot store member associations.

---

## 5. Tab-by-Tab Implementation Analysis

### 5.1 Channel Master Tab

**Route:** `notification/notification-channels`  
**Controller:** `ChannelMasterController`  
**Table:** `ntf_channel_master`  

**Working Features:**
- Full CRUD with pagination, filtering, search
- Channel code auto-uppercased via `setCodeAttribute()` mutator
- Unique per-tenant validation
- Soft delete with restore/force-delete
- Status toggle
- Statistics endpoint

**Limitations & Gaps:**
- The `statistics()` method is called but its actual implementation could not be verified
- Fallback channel validation: The controller checks for circular fallback references but the `fallback_channel_id` FK is self-referential which could cause issues on delete
- Rate limit/daily limit/monthly limit fields are stored but never enforced anywhere in the delivery pipeline
- Cost tracking fields are stored but never used

**How It Should Work:**
The Channel Master tab serves as the registry of communication channels available in the tenant. When a school wants to enable email notifications, an admin creates a channel with code `EMAIL`, sets the maximum retry count (default 3), rate limits (default 100/minute), and an optional fallback channel (e.g., if WhatsApp fails, fall back to SMS). The channel configuration is read by `NotificationService::trigger()` to determine which channels to use for each notification event. Rate limiting is enforced by a middleware or service layer that checks the delivery queue against the configured limits before dispatching.

---

### 5.2 Provider Master Tab

**Route:** `notification/provider-master`  
**Controller:** `ProviderMasterController`  
**Table:** `ntf_provider_master`  

**Working Features:**
- Full CRUD with pagination
- Provider type badges (PRIMARY/SECONDARY/BACKUP)
- Status toggle
- Delete with relational checks

**Limitations & Gaps:**
- **CRITICAL:** API credentials stored as plain text despite column name `api_key_encrypted`
- No actual provider SDK integration — storing Twilio credentials does not mean Twilio is called
- No provider health check / connectivity test functionality
- No webhook URL registration per provider

**How It Should Work:**
Each channel requires at least one provider to actually send messages. For the EMAIL channel, providers could be AWS SES (PRIMARY), SMTP (SECONDARY), or SendGrid (BACKUP). When the delivery queue processes a notification for the EMAIL channel, it selects the PRIMARY provider. If the primary fails, it falls back to SECONDARY, then BACKUP. Provider credentials must be encrypted at rest using Laravel's `Crypt::encryptString()` and decrypted only at the moment of sending. A "Test Connection" button should verify provider credentials by sending a test message.

---

### 5.3 Target Groups Tab

**Route:** `notification/target-groups`  
**Controller:** `TargetGroupController`  
**Table:** `ntf_target_groups`  

**Working Features:**
- Full CRUD with pagination
- STATIC/DYNAMIC type selection
- System group protection (cannot delete/edit system groups)
- `refreshMembers()` updates timestamp

**Limitations & Gaps:**
- **CRITICAL:** No `ntf_target_group_members` pivot table in DDL — STATIC groups cannot store members
- `refreshMembers()` for DYNAMIC groups does not execute the dynamic query — it just updates the timestamp
- No actual member resolution logic exists
- No count synchronization mechanism

**How It Should Work:**
Target Groups define reusable recipient segments. A STATIC group like "All Hostel Wardens" requires a `ntf_target_group_members` pivot table storing `(group_id, user_id)` pairs. Users are added/removed manually via a member management interface within the group detail view.

A DYNAMIC group like "All Active Students" stores a query configuration in `dynamic_query` (JSON format specifying module, table, conditions). When `refreshMembers()` is called, a service class executes the query against the relevant table (e.g., `std_students WHERE is_active = 1`), resolves the matching user IDs, and updates `total_members`. The resolved members may be cached rather than stored in a pivot table for performance.

When creating a notification, the user selects a target group (or defines an inline target). The system estimates the count (`estimated_count`), then resolves actual recipients into `ntf_resolved_recipients` with personalized content.

---

### 5.4 Notification Targets Tab

**Route:** `notification/notification-targets`  
**Controller:** `NotificationTargetController`  
**Table:** `ntf_notification_targets`  

**Working Features:**
- Full CRUD
- `resolveTargets()` stub
- Target group linkage

**Limitations & Gaps:**
- `resolveTargets()` is a stub — does not create `ntf_resolved_recipients` records
- `calculateEstimatedCount()` and `resolveActualCount()` are empty stubs
- No integration with notification creation flow

**How It Should Work:**
When a notification is created with targets, the target resolution pipeline runs:
1. For each `ntf_notification_target`: determine target type (group, direct, or condition)
2. If group: load members from `ntf_target_group_members` (STATIC) or execute query (DYNAMIC)
3. If direct: load the specific user by `target_table_name` + `target_selected_id`
4. If condition: execute the condition filter against the specified module
5. Deduplicate resolved users
6. For each resolved user: create `ntf_resolved_recipients` with personalized subject/body
7. Insert into `ntf_delivery_queue`

The `resolveTargets()` method on the controller triggers this pipeline. Progress is tracked — `estimated_count` is set before resolution, `actual_count` after resolution.

---

### 5.5 Notifications Tab

**Route:** `notification/notifications`  
**Controller:** `NotificationManageController`  
**Table:** `ntf_notifications`  

**Working Features:**
- Full CRUD with multi-tab index page
- Status management (updateStatus action)
- Manual notification creation
- Channel assignment in create/edit forms
- `process()` action changes status to PROCESSING
- Activity logging for mutations

**Limitations & Gaps:**
- `process()` does not actually dispatch via the event pipeline
- Aggregated counters (sent_count, failed_count, etc.) are never updated
- Scheduled/recurring notifications are not processed by any cron job
- The `approved_by` / `approved_at` fields are not set during approval workflow
- No integration with the facade/event dispatch system — manually created notifications cannot be sent

**How It Should Work:**
The Notifications tab is the central hub. When an admin creates a notification manually:

1. **Draft Phase:** Admin fills title, description, selects template, sets priority, confidentiality, selects channels, defines targets or target groups, optionally schedules delivery.
2. **Approval Phase:** (for transactional) Admin submits for approval. Approver reviews and approves/rejects.
3. **Scheduling Phase:** If `schedule_type = IMMEDIATE`, the notification is queued for immediate processing. If `SCHEDULED`, it waits until `scheduled_at`. If `RECURRING`, the cron job checks the `recurring_expression` and creates child notifications accordingly.
4. **Processing Phase:** The delivery pipeline:
   a. Resolve targets → create `ntf_resolved_recipients`
   b. Personalize content using template → store `personalized_subject`/`personalized_body`
   c. Insert into `ntf_delivery_queue`
   d. Update `total_recipients` on parent notification
5. **Delivery Phase:** Queue worker picks up `ntf_delivery_queue` items → creates `ntf_notification_channels` record → calls provider → logs to `ntf_delivery_logs` → updates counters.
6. **Completion:** When all recipients are processed, `notification_status_id` changes to COMPLETED (or PARTIAL/FAILED).

For **system-triggered notifications**, the flow is:
- Module calls `Notification::dispatch('event_code', $payload)`
- Finds matching `ntf_notifications` record where `notification_event = event_code`
- Treats it as if it were manually created with those parameters
- Follows steps 4-6 above

---

### 5.6 Templates Tab

**Route:** `notification/templates`  
**Controller:** `TemplateController` (primary) + `NotificationTemplateController` (legacy)  
**Table:** `ntf_templates`  

**Working Features:**
- Full CRUD with version management
- Approval workflow (DRAFT → PENDING → APPROVED → REJECTED)
- Template duplication
- Placeholder extraction via `@preg_match_all('/\{\{(\w+)\}\}/', $body, $matches)`
- `render($payload)` method replaces `{{key}}` with `$payload['key']`
- Channel-specific templates
- Language support
- Media attachments via `media_id → sys_media`

**Limitations & Gaps:**
- Two controllers for the same entity (`TemplateController` + `NotificationTemplateController`) causes confusion
- The `approve()` method changes status to APPROVED but does not set `approved_by`/`approved_at`
- No template preview/send-test functionality
- Placeholder extraction works but no validation that all required placeholders are provided before send
- Version management UI is basic — creating a new version increments `template_version` but old versions are still editable
- No fallback language chain (if template not found in `en`, try default language)

**How It Should Work:**
Templates are the content layer. Each template belongs to a specific channel (e.g., an EMAIL template has subject + HTML body; an SMS template has only body). Placeholders like `{{student_name}}`, `{{date}}`, `{{amount}}` are extracted and stored in the `placeholders` JSON column.

Workflow:
1. **Admin creates** template in DRAFT status, writes subject/body with `{{placeholders}}`
2. **System extracts** placeholders automatically and stores in `placeholders` JSON
3. **Admin submits** for approval → status becomes PENDING
4. **Approver reviews** and approves/rejects. On approval, `approved_by` and `approved_at` are set, status becomes APPROVED
5. **System uses** only APPROVED templates for delivery
6. **At render time**, `$template->render($payload)` substitutes all placeholders. If a required placeholder is missing, the system logs a warning and either skips that recipient or uses a fallback value
7. **Version management:** When a template is updated, `createVersion()` duplicates the current template with incremented `template_version`. The old version remains for historical notifications. New notifications use the latest APPROVED version

---

### 5.7 User Preferences Tab

**Route:** `notification/user-preferences`  
**Controller:** `UserPreferenceController`  
**Table:** `ntf_user_preferences`  

**Working Features:**
- Full CRUD
- toggle-enabled with opt-in/out timestamp tracking
- Quiet hours with start/end time
- Daily digest configuration
- Priority threshold

**Limitations & Gaps:**
- No integration with the delivery pipeline — preferences are stored but never checked before sending
- The `NotificationService::trigger()` does not check `canReceiveNow()` or `isWithinQuietHours()`
- No bulk preference import/export
- No preference sync with user profile

**How It Should Work:**
Before adding a recipient to `ntf_resolved_recipients` or creating a `ntf_delivery_queue` entry, the system must check:

1. **is_enabled:** If user has disabled this channel, skip
2. **is_opted_in:** GDPR consent required for promotional messages
3. **isWithinQuietHours():**
   ```php
   public function isWithinQuietHours(): bool
   {
       if (!$this->quiet_hours_start || !$this->quiet_hours_end) return false;
       $now = Carbon::now($this->quiet_hours_timezone ?? 'UTC');
       $start = Carbon::createFromTimeString($this->quiet_hours_start, $this->quiet_hours_timezone);
       $end = Carbon::createFromTimeString($this->quiet_hours_end, $this->quiet_hours_timezone);
       return $now->between($start, $end);
   }
   ```
4. **priority_threshold:** If notification priority is below user's threshold, skip or use digest mode
5. **daily_digest:** If enabled, batch into digest instead of sending immediately
6. **contact_value:** If set, use this email/phone instead of user's default

---

### 5.8 Resolved Recipients Tab

**Route:** `notification/resolved-recipients`  
**Controller:** `ResolvedRecipientController`  
**Table:** `ntf_resolved_recipients`  

**Working Features:**
- Full CRUD with batch processing
- `markAsProcessed()` with sent_count increment on parent notification
- `bulkProcess()` for batch marking
- `getByBatch()` for batch retrieval
- Edit/delete blocked for processed records

**Limitations & Gaps:**
- "Processed" only means the database flag is set — no actual sending occurs
- The `personalized_subject` and `personalized_body` are NOT pre-rendered — they remain null because `render()` is never called during the resolution pipeline
- No integration with Delivery Queue — marking as processed should enqueue a delivery job

**How It Should Work:**
This is the **output of target resolution** and the **input to the delivery queue**. The flow:

1. Target resolution creates `ntf_resolved_recipients` records
2. For each record:
   a. Resolve user's contact info for the channel (email, phone, device token)
   b. Render template with `personalization_data` → store in `personalized_subject`/`personalized_body`
   c. Check user preferences (enabled, quiet hours, threshold)
   d. If passes all checks: create `ntf_delivery_queue` entry
   e. If fails checks: mark as skipped (new status needed)
3. `batch_id` groups recipients for bulk processing (e.g., all SMS recipients in one batch)
4. `is_processed` flag marks completion
5. Parent `ntf_notifications` counters are updated after processing

---

### 5.9 Delivery Queue Tab

**Route:** `notification/delivery-queue`  
**Controller:** `DeliveryQueueController`  
**Table:** `ntf_delivery_queue`  

**Working Features:**
- Full CRUD with stats endpoint
- `process()` action (status change only)
- `retry()` action (resets failed items)
- `cancel()` action (blocks sent/cancelled)
- Stats cards (Pending/Processing/Sent/Failed/Retry/Total)
- Worker lock fields (`locked_by`, `locked_at`)

**Limitations & Gaps:**
- **CRITICAL:** No worker daemon consumes the queue
- `process()` only changes status to PROCESSING — does not call any provider
- `retry()` works but retries are never scheduled because nothing fails
- `cancel()` works but is irrelevant since nothing is being sent
- No priority-based sorting for queue processing
- No scheduled_at based delay processing

**How It Should Work:**
The Delivery Queue is a **database-backed work queue** consumed by a worker process:

**Worker Command (`ntf:process-queue`):**
```php
// Pseudo-code for the queue worker
public function handle()
{
    // 1. Lock next batch of pending items (highest priority, earliest scheduled)
    $items = DeliveryQueue::where('queue_status', 'PENDING')
        ->where('scheduled_at', '<=', now())
        ->whereNull('locked_by')
        ->where(function($q) {
            $q->whereNull('next_attempt_at')
              ->orWhere('next_attempt_at', '<=', now());
        })
        ->orderBy('priority')
        ->orderBy('scheduled_at')
        ->limit(50)  // Batch size
        ->get();
    
    foreach ($items as $item) {
        // 2. Lock the item
        $item->update([
            'locked_by' => gethostname() . ':' . getmypid(),
            'locked_at' => now(),
            'queue_status' => 'PROCESSING'
        ]);
        
        // 3. Determine provider strategy
        $provider = ProviderMaster::find($item->provider_id);
        $channel = ChannelMaster::find($item->channel_id);
        
        // 4. Dispatch to appropriate provider class
        try {
            $providerClass = ProviderFactory::create($provider);
            $response = $providerClass->send(
                $item->resolvedRecipient->recipient_address,
                $item->resolvedRecipient->personalized_subject,
                $item->resolvedRecipient->personalized_body
            );
            
            // 5. On success
            $item->update(['queue_status' => 'SENT']);
            $this->logDelivery($item, $response, 'SENT');
            
        } catch (\Exception $e) {
            // 6. On failure
            $item->increment('attempt_count');
            if ($item->attempt_count >= $item->max_attempts) {
                $item->update(['queue_status' => 'FAILED', 'last_error' => $e->getMessage()]);
            } else {
                $item->update([
                    'queue_status' => 'RETRY',
                    'last_error' => $e->getMessage(),
                    'next_attempt_at' => now()->addMinutes($channel->retry_delay_minutes)
                ]);
            }
        } finally {
            // 7. Release lock
            $item->update(['locked_by' => null, 'locked_at' => null]);
        }
    }
}
```

The worker should be configured as a **supervisor-managed daemon** running `php artisan ntf:process-queue --sleep=3` (sleep 3 seconds when queue is empty).

---

### 5.10 Delivery Logs Tab

**Route:** `notification/delivery-log`  
**Controller:** ❌ **No dedicated controller** (views exist at `resources/views/delivery-log/`)  
**Table:** `ntf_delivery_logs`  

**Working Features:**
- Views exist for index, create, edit, show, trash
- Modal detail view with JSON response payload display

**Limitations & Gaps:**
- **No controller** — the views cannot be rendered via any route
- Delivery logs are created by `NotificationService::trigger()` but only for EMAIL and IN_APP
- Webhook receiver for delivery status updates is missing
- `delivery_stage` progression (QUEUED → SENT → DELIVERED → READ → CLICKED) is not implemented

**How It Should Work:**
The Delivery Log provides a **complete audit trail** for every notification:

1. **QUEUED** — When `ntf_delivery_queue` entry is created, a log is created with `delivery_stage = 'QUEUED'`
2. **SENT** — When provider confirms sending, stage updates to `SENT`, `provider_message_id` stored
3. **DELIVERED** — When provider sends delivery receipt (e.g., SES SNS notification, Twilio status callback), stage updates to `DELIVERED`, `delivered_at` recorded
4. **READ** — When tracking pixel is loaded (email) or message is opened (in-app), stage updates to `READ`, `read_at` recorded with `ip_address` and `user_agent`
5. **CLICKED** — When link is clicked, stage updates to `CLICKED`, `clicked_at` recorded
6. **BOUNCED** — When email bounces, stage updates to `BOUNCED`, `bounced_at` recorded
7. **COMPLAINT** — When user marks as spam, stage updates to `COMPLAINT`
8. **UNSUBSCRIBED** — When user unsubscribes, stage updates to `UNSUBSCRIBED`

**Webhook Receiver:** A dedicated controller receives callbacks from providers:
- AWS SES: SNS webhooks for bounces, complaints, deliveries
- Twilio: Status callback webhooks for SMS delivery
- WhatsApp Business API: Webhooks for message status
- The webhook endpoint is public (no auth — relies on signature verification)

---

### 5.11 Notification Threads Tab

**Route:** `notification/notification-threads`  
**Controller:** `NotificationThreadController`  
**Tables:** `ntf_notification_threads` + `ntf_notification_thread_members`  

**Working Features:**
- Full CRUD for threads
- `recalculateCounts()` recalculates `total_notifications` + `participant_count`
- Drag-drop sequence ordering via `updateSequence()`
- Parent-child thread hierarchy

**Limitations & Gaps:**
- Threads are not automatically linked to notifications during creation
- No digest generation logic (CONVERSATION mode)
- No broadcast sender logic (BROADCAST mode)
- No conversation view UI

**How It Should Work:**
Threads group related notifications for three use cases:

1. **BROADCAST (default):** One-to-many notification (e.g., "Fee reminder sent to all parents"). All child notifications share the same thread.

2. **CONVERSATION:** Threaded discussion (e.g., a complaint thread: "Complaint filed" → "Assigned to staff" → "Resolved" → "Satisfaction survey"). Each action adds a new notification to the thread. The parent-child hierarchy tracks the conversation flow.

3. **DIGEST:** Batch of notifications grouped for periodic delivery (e.g., daily digest of unread notifications). The `notification_type = 'DIGEST'` flag combined with `schedule_type = 'RECURRING'` enables this.

When a notification is created with a `thread_id`, the system checks if a thread notification should be created. In BROADCAST mode, all recipients receive the notification individually. In CONVERSATION mode, the thread subject is used for grouping in the UI.

---

### 5.12 User Devices Tab

**Route:** ❌ **No routes exist**  
**Controller:** ❌ **No controller**  
**Table:** `ntf_user_devices`  

**Current Status:** Model exists but no management interface.

**How It Should Work:**
User Devices enable **Push Notifications** via Firebase Cloud Messaging (FCM) for Android and web, and Apple Push Notification Service (APNS) for iOS.

1. **Device Registration API:** When a user logs into the mobile app or web portal, the app sends the device token to a public API endpoint:
   ```
   POST /api/v1/notification/devices
   Body: { device_type: "ANDROID", device_token: "fcm_token_here", device_name: "OnePlus 12" }
   ```
2. **Token Refresh:** The API updates the token if it already exists (same user + different token) or creates a new record
3. **Inactive Devices:** Devices not active for 90+ days are automatically marked inactive
4. **Send via FCM/APNS:** When a push notification needs to be sent, the system:
   a. Finds all active devices for the user
   b. Sends via FCM (Android/Web) or APNS (iOS)
   c. Removes devices that return `InvalidRegistration` or `NotRegistered` errors

A `PushNotificationService` class handles the actual FCM/APNS integration using either `kreait/laravel-firebase` or `laravel-notification-channels/fcm` package.

---

### 5.13 Schedule Audit Tab

**Route:** ❌ **No routes exist**  
**Controller:** ❌ **No controller**  
**Table:** `ntf_schedule_audit`  

**Current Status:** Completely unimplemented.

**How It Should Work:**
The Schedule Audit tracks recurring notification executions:

1. **Cron Job:** `ntf:process-scheduled` runs every minute
2. **Query:** Finds `ntf_notifications` where:
   - `schedule_type = 'RECURRING'` AND `notification_status_id = ACTIVE`
   - `scheduled_at <= now()` (for SCHEDULED type)
   - `expires_at >= now()` OR `expires_at IS NULL`
   - `recurring_executed_count < recurring_end_count` OR `recurring_end_count IS NULL`
3. **Processing:** For each matching notification:
   a. Check `ntf_schedule_audit` if already executed for this time slot
   b. If not executed: create child notification, process delivery pipeline
   c. Log execution in `ntf_schedule_audit`
   d. Increment `recurring_executed_count` on parent notification
4. **Recurring Patterns:**
   - `HOURLY`: Check if last execution was > 1 hour ago
   - `DAILY`: Check if last execution was yesterday
   - `WEEKLY`: Check if last execution was > 7 days ago
   - `MONTHLY`: Check if last execution was last month
   - `CUSTOM`: Parse `recurring_expression` (cron format) using `cron-expression/cron-expression` package

---

## 6. Architecture & Data Flow

### 6.1 System-Triggered Notification Flow

```
┌──────────────┐     ┌─────────────────────┐     ┌───────────────────────┐
│ Other Module  │     │  Notification::     │     │  SystemNotification   │
│ (Hostel,      │────→│  dispatch('event',  │────→│  Triggered Event      │
│  Complaint)   │     │  $payload)          │     │  (Dispatchable)       │
└──────────────┘     └─────────────────────┘     └──────────┬────────────┘
                                                            │ Queue: ShouldQueue
                                                            ▼
┌───────────────────────┐     ┌─────────────────────┐     ┌───────────────────────┐
│ ProcessSystem         │     │  NotificationService│     │  ntf_notifications    │
│ Notification Listener │────→│  ::trigger($event,  │────→│  (find by event_code) │
│ (ShouldQueue, 3 retry)│     │  $payload)          │     │                       │
└───────────────────────┘     └─────────────────────┘     └───────────────────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │  Loop Channels   │
                              │  from            │
                              │  ntf_notification │
                              │  _channels       │
                              └──────────────────┘
                                       │
                          ┌────────────┼────────────┐
                          ▼            ▼            ▼
                   ┌──────────┐ ┌──────────┐ ┌──────────┐
                   │  EMAIL   │ │  IN_APP  │ │ SMS/PUSH │
                   │ Mail::   │ │ $user->  │ │ /WHATSAPP│
                   │ send()   │ │ notify() │ │ (STUB)   │
                   └──────────┘ └──────────┘ └──────────┘
                          │            │            │
                          ▼            ▼            ▼
                   ┌──────────────────────────────────┐
                   │  ntf_delivery_logs                │
                   │  (SENT / FAILED recorded)         │
                   └──────────────────────────────────┘
```

### 6.2 Manual Notification Flow (Future State)

```
┌────────────────┐     ┌────────────────────┐     ┌──────────────────────┐
│ Admin creates  │     │ Target Resolution  │     │ Recipient            │
│ Notification   │────→│ Pipeline           │────→│ Personalization      │
│ via Web UI     │     │                    │     │ (Template Render)    │
└────────────────┘     └────────────────────┘     └──────────────────────┘
                                                          │
                                                          ▼
┌────────────────┐     ┌────────────────────┐     ┌──────────────────────┐
│ ntf_delivery_  │←────│ Queue Insert       │←────│ ntf_resolved_        │
│ queue          │     │ (Check prefs,      │     │ recipients           │
│ (PENDING)      │     │  batch, prioritize)│     │ (personalized)       │
└────────────────┘     └────────────────────┘     └──────────────────────┘
        │
        │ Worker: php artisan ntf:process-queue
        ▼
┌────────────────┐     ┌────────────────────┐     ┌──────────────────────┐
│ Provider       │────→│ Provider Class     │────→│ Provider Response    │
│ Selection      │     │ (send via SDK)     │     │ Parsing              │
│ (Primary/      │     │                    │     │                      │
│  Secondary/    │     │                    │     │                      │
│  Backup)       │     │                    │     │                      │
└────────────────┘     └────────────────────┘     └──────────────────────┘
                                                          │
                                                          ▼
┌────────────────┐     ┌────────────────────┐     ┌──────────────────────┐
│ Update Queue   │────→│ Update Notification│────→│ Log to              │
│ Status (SENT/  │     │ Counters           │     │ ntf_delivery_logs    │
│ FAILED/RETRY)  │     │ (sent_count, etc.) │     │ (full audit)        │
└────────────────┘     └────────────────────┘     └──────────────────────┘
                                                          │
                                                          ▼
                                                  ┌──────────────────────┐
                                                  │ Webhook Receiver     │
                                                  │ (SES bounce, Twilio  │
                                                  │  status, etc.) →     │
                                                  │ Update delivery_stage│
                                                  └──────────────────────┘
```

---

## 7. Critical Gaps & Missing Components

### 7.1 P0 — Must Fix Before Production (Security & Core Functionality)

| # | Gap | Severity | Description | Impact |
|---|-----|----------|-------------|--------|
| 1 | **Provider credentials stored in plain text** | CRITICAL | `api_key_encrypted` and `api_secret_encrypted` columns store plain text despite column name suggesting encryption | API keys exposed in database — any user with DB access can read all provider credentials |
| 2 | **No SMS delivery** | CRITICAL | The SMS channel logs "not implemented" — no Twilio, MSG91, TextLocal, or any other SMS provider integration | Schools cannot send SMS notifications — a core requirement for the Indian education market |
| 3 | **No WhatsApp delivery** | CRITICAL | Same as SMS — only a log placeholder | Cannot send WhatsApp messages despite it being the most popular messaging platform in India |
| 4 | **No Push Notification delivery** | CRITICAL | No FCM/APNS integration. `ntf_user_devices` table exists with no management interface | Cannot send push notifications to mobile app users |
| 5 | **No delivery queue worker** | CRITICAL | `ntf_delivery_queue` has no consumer process. Records are inserted but never processed | The entire queue infrastructure is decorative — nothing actually sends |
| 6 | **NotificationService::trigger() only handles 2/5 channels** | CRITICAL | Only EMAIL and IN_APP have working code. SMS, WHATSAPP, PUSH are stubs | System-triggered notifications only work via email and in-app |

### 7.2 P1 — High Priority

| # | Gap | Severity | Description |
|---|------|----------|-------------|
| 7 | **No delivery webhook receiver** | HIGH | No controller/routes to receive SES bounces, Twilio status callbacks, WhatsApp delivery receipts |
| 8 | **Target resolution pipeline is a stub** | HIGH | `resolveTargets()`, `calculateEstimatedCount()`, `resolveActualCount()` are empty — no recipients are ever resolved |
| 9 | **User preferences not checked during delivery** | HIGH | `isWithinQuietHours()`, `canReceiveNow()` exist on model but are never called |
| 10 | **No recurring notification cron** | HIGH | `ntf_schedule_audit` has no model, no controller, no cron — recurring notifications are non-functional |
| 11 | **No rate limiting enforcement** | HIGH | `rate_limit_per_minute`, `daily_limit`, `monthly_limit` stored but never enforced |
| 12 | **Missing ntf_target_group_members pivot table** | HIGH | STATIC target groups cannot store member associations |
| 13 | **No active migrations in module** | HIGH | All migration files are `.bk` backups — module cannot be freshly installed |

### 7.3 P2 — Medium Priority

| # | Gap | Severity | Description |
|---|------|----------|-------------|
| 14 | **No template preview/test-send** | MEDIUM | No way to preview or test-send a template before using it |
| 15 | **Duplicate template controllers** | MEDIUM | `TemplateController` and `NotificationTemplateController` both manage templates |
| 16 | **Delivery Logs have no controller** | MEDIUM | Views exist at `delivery-log/` but no controller renders them |
| 17 | **No cost tracking** | MEDIUM | `estimated_cost`/`actual_cost` never calculated |
| 18 | **No read/click tracking** | MEDIUM | Tracking infrastructure not implemented |
| 19 | **User Devices have no management interface** | MEDIUM | Model exists but no way to manage devices |
| 20 | **Not authenticated routes for notifications** | MEDIUM | The index/index actions load all 10+ entity queries per request (slow) |

### 7.4 P3 — Low Priority / Future

| # | Gap | Severity | Description |
|---|------|----------|-------------|
| 21 | No email attachment support in delivery queue worker | LOW |
| 22 | No digest generation logic | LOW |
| 23 | No unsubscribe mechanism (one-click unsubscribe link in emails) | LOW |
| 24 | No bulk notification import (CSV upload of recipients) | LOW |
| 25 | No notification analytics dashboard (sent/failed/delivered/read rates) | LOW |
| 26 | No delivery timeout handling | LOW |

---

## 8. Phase-Wise Implementation Roadmap

### Phase 1: Foundation & Security (Week 1 — 3-4 days)

**Objective:** Secure existing code and enable basic delivery for all 5 channels.

| Task | Files Affected | Effort |
|------|---------------|--------|
| Encrypt provider credentials using `Crypt::encryptString()` / `Crypt::decryptString()` | `ProviderMasterController::store()/update()`, `ProviderMaster::getDecryptedApiKeyAttribute()` | 2 hours |
| Create `SmsProvider` interface and `TwilioProvider`, `Msg91Provider` implementations | `app/Services/Providers/SmsProvider.php`, `TwilioProvider.php`, `Msg91Provider.php` | 4 hours |
| Create `EmailProvider` interface and `SesProvider`, `SmtpProvider` implementations | `app/Services/Providers/EmailProvider.php`, `SesProvider.php`, `SmtpProvider.php` | 4 hours |
| Create `WhatsAppProvider` interface and `MetaWhatsAppProvider` implementation | `app/Services/Providers/WhatsAppProvider.php`, `MetaWhatsAppProvider.php` | 4 hours |
| Create `PushNotificationProvider` interface and `FcmProvider` implementation | `app/Services/Providers/PushProvider.php`, `FcmProvider.php` | 4 hours |
| Implement `ProviderFactory` to map `ProviderMaster.provider_name` → Provider class | `app/Services/Providers/ProviderFactory.php` | 1 hour |
| Create `ntf:process-queue` artisan command with worker logic | `app/Console/Commands/ProcessDeliveryQueue.php` | 6 hours |
| Update `NotificationService::trigger()` to dispatch to queue instead of sending inline | `app/Services/NotificationService.php` | 2 hours |

**Total: ~27 hours**

---

### Phase 2: Delivery Pipeline (Week 2 — 3-4 days)

**Objective:** Complete the target resolution → personalization → queuing → delivery pipeline.

| Task | Files Affected | Effort |
|------|---------------|--------|
| Create `RecipientResolutionService` to resolve targets into resolved recipients | `app/Services/RecipientResolutionService.php` | 6 hours |
| Create `ntf_target_group_members` migration + model + controller | `database/migrations/`, `app/Models/TargetGroupMember.php`, controller | 3 hours |
| Implement `NotificationTargetController::resolveTargets()` to call `RecipientResolutionService` | `NotificationTargetController.php` | 3 hours |
| Create `PersonalizationService` to render templates with payload | `app/Services/PersonalizationService.php` | 2 hours |
| Wire delivery queue to actually use providers via `ProviderFactory` | `ProcessDeliveryQueue.php` | 4 hours |
| Implement retry logic with exponential backoff | `ProcessDeliveryQueue.php` | 2 hours |
| Create webhook receiver controller for SES/Twilio/WhatsApp callbacks | `app/Http/Controllers/WebhookController.php` | 4 hours |
| Create `DeliveryLogController` to render existing delivery-log views | `app/Http/Controllers/DeliveryLogController.php` | 2 hours |

**Total: ~26 hours**

---

### Phase 3: Advanced Features (Week 3 — 3-4 days)

**Objective:** Scheduling, recurring notifications, user preferences, rate limiting.

| Task | Files Affected | Effort |
|------|---------------|--------|
| Create `ScheduleAudit` model + migration + controller + views | Full stack for `ntf_schedule_audit` | 4 hours |
| Create `ntf:process-scheduled` cron command for recurring notifications | `app/Console/Commands/ProcessScheduledNotifications.php` | 4 hours |
| Integrate user preference checks into delivery queue worker | `ProcessDeliveryQueue.php` + `UserPreference::canReceiveNow()` | 2 hours |
| Implement rate limiting middleware/service | `app/Services/RateLimiter.php` | 3 hours |
| Create `UserDeviceController` with API endpoint + views | Full stack for `ntf_user_devices` | 4 hours |
| Add template preview/test-send functionality | `TemplateController.php` + views | 2 hours |
| Implement daily digest generation logic | `app/Services/DigestService.php` | 3 hours |
| Add cost calculation service | `app/Services/CostCalculator.php` | 2 hours |

**Total: ~24 hours**

---

### Phase 4: Optimization & Testing (Week 4 — 3-4 days)

**Objective:** Performance optimization, testing, documentation.

| Task | Effort |
|------|--------|
| Fix N+1 queries in all controllers (eager load relationships) | 3 hours |
| Implement `Cache::remember()` for channel master, provider master lookups | 2 hours |
| Add batch processing optimization (send emails in batch via SES API) | 4 hours |
| Write Pest tests for: NotificationService, ProviderFactory, DeliveryQueue worker, Webhook receiver | 8 hours |
| Remove duplicate `NotificationTemplateController` (merge into `TemplateController`) | 2 hours |
| Add unsubscribe link to email templates | 2 hours |
| Performance benchmark: measure throughput of queue worker | 2 hours |

**Total: ~23 hours**

---

## 9. Security Audit

### 9.1 Findings

| # | Issue | Severity | Location | Description |
|---|-------|----------|----------|-------------|
| SEC-NTF-001 | **API credentials stored in plain text** | CRITICAL | `ProviderMasterController::store()` | The `api_key_encrypted` and `api_secret_encrypted` columns are never encrypted. Anyone with DB access reads plaintext credentials |
| SEC-NTF-002 | **No authentication on webhook endpoints** | HIGH | Future: WebhookController | Webhook receivers must verify provider signatures (SES SNS signature verification, Twilio signature, WhatsApp webhook verification token) |
| SEC-NTF-003 | **Mass assignment in controllers** | MEDIUM | Multiple controllers | Several controllers use `$request->all()` or `$request->validated()` without checking fillable properties |
| SEC-NTF-004 | **No rate limiting on dispatch API** | MEDIUM | `NotificationDispatcher` | Modules can call `Notification::dispatch()` in a loop without any rate control |
| SEC-NTF-005 | **No permission checks on some actions** | MEDIUM | Various controllers | `@can` checks are inconsistent across controllers |
| SEC-NTF-006 | **ALL notification routes commented out in web.php** | CRITICAL | `routes/web.php` (Hostel module) | Hostel module notification routes are commented out — the Notification module's own routes separate |

### 9.2 Recommended Security Controls

1. **Credential Encryption:**
   ```php
   // In ProviderMaster model
   public function setApiKeyEncryptedAttribute($value)
   {
       $this->attributes['api_key_encrypted'] = encrypt($value);
   }
   
   public function getDecryptedApiKeyAttribute()
   {
       return decrypt($this->attributes['api_key_encrypted']);
   }
   ```

2. **Webhook Signature Verification:**
   - AWS SES: Verify SNS notification signature using AWS SDK
   - Twilio: Validate `X-Twilio-Signature` header
   - WhatsApp: Verify `verify_token` and signature

3. **Rate Limiting on Dispatch:**
   - Apply `throttle:60,1` middleware on any API endpoint
   - Implement in-memory rate limiting in the dispatcher facade

4. **Permission Checks:**
   - Ensure all controller actions have `@can('permission.name')` or `Gate::authorize()`
   - Add permission seeder for all 12 notification permissions

---

## 10. Performance Considerations

### 10.1 Current Performance Issues

1. **N+1 Queries in Index Pages:** The `ChannelMasterController::index()` and other index methods load related data without eager loading. For 50 channels, this could result in 50+ additional queries.

2. **Uncached Lookups:** Channel master, provider master, and template lookups are queried from the database on every notification dispatch. These rarely change and should be cached.

3. **Synchronous Email Sending:** The current `NotificationService::trigger()` sends EMAIL synchronously via `Mail::send()` inside the queued listener. For 100 recipients, this blocks the queue worker for 100× the email send time (potentially 5-10 minutes).

4. **Delivery Queue Without Worker:** Queue entries accumulate without being processed. Over time, this table grows unbounded.

### 10.2 Performance Recommendations

1. **Cache Configuration Tables:**
   ```php
   $channels = Cache::remember("tenant.{$tenantId}.channels", 3600, fn() => 
       ChannelMaster::where('tenant_id', $tenantId)->where('is_active', true)->get()
   );
   ```

2. **Batch Email Sending:** Use SES `SendBulkTemplatedEmail` API or Mailgun batch sending instead of individual `Mail::send()` calls.

3. **Database Indexing:** Ensure indexes exist on:
   - `ntf_delivery_queue(queue_status, scheduled_at, priority)` — for worker query
   - `ntf_notifications(notification_event)` — for event lookup
   - `ntf_delivery_logs(notification_id, resolved_user_id)` — for delivery lookup

4. **Queue Cleanup:** Archive `ntf_delivery_queue` records older than 30 days to a separate archive table.

5. **Resolved Recipients Archival:** Move processed `ntf_resolved_recipients` to cold storage after 90 days.

---

## 11. Module Integration Points

### 11.1 How Other Modules Should Use Notifications

Every module follows the same pattern:

```php
use Modules\Notification\Facades\Notification;

class HostelComplaintService
{
    public function escalate($complaint)
    {
        // ... escalation logic ...
        
        // Dispatch notification — one line, async
        Notification::dispatch('hostel.complaint.escalated', [
            'complaint_id' => $complaint->id,
            'complaint_subject' => $complaint->subject,
            'student_name' => $complaint->student->name,
            'hostel_name' => $complaint->hostel->name,
            'escalated_to' => $complaint->assignedTo->name,
            'priority' => $complaint->priority,
        ]);
    }
}
```

### 11.2 Event Code Naming Convention

```
{module}.{entity}.{action}
Examples:
- hostel.complaint.escalated
- hostel.incident.recorded
- hostel.leave_pass.approved
- hostel.leave_pass.rejected
- hostel.student.returned
- hostel.absence.detected
- hostel.sick_bay.admitted
- hostel.sick_bay.discharged
- student.fee.payment_received
- student.attendance.marked_absent
- transport.trip.starting
```

### 11.3 Current Modules Using Notifications

| Module | Status | Events Defined |
|--------|--------|---------------|
| Hostel | 7 events, no listeners | `LeavePassApproved`, `LeavePassRejected`, `StudentReturned`, `HostelAbsenceDetected`, `HostelIncidentRecorded`, `SickBayAdmissionRecorded`, `SickBayDischarged` |
| Complaint | 1 job, 1 event (Hostel-internal) | `HstComplaintService::escalate()` dispatches `SendHstNotificationJob` |
| Global (App\Notifications) | 7 Laravel Notification classes | User creation, tenant registration, complaint registered |

---

## 12. Appendix: File Inventory

### 12.1 Controllers (12 files)

| # | File | Entity | Lines | Status |
|---|------|--------|-------|--------|
| 1 | `ChannelMasterController.php` | `ntf_channel_master` | ~250 | ✅ Complete |
| 2 | `DeliveryQueueController.php` | `ntf_delivery_queue` | ~300 | ⚠️ Missing provider dispatch |
| 3 | `NotificationManageController.php` | `ntf_notifications` | ~400 | ⚠️ process() is stub |
| 4 | `NotificationTargetController.php` | `ntf_notification_targets` | ~200 | ⚠️ resolveTargets() is stub |
| 5 | `NotificationTemplateController.php` | `ntf_templates` (legacy) | ~200 | ⚠️ Duplicate of TemplateController |
| 6 | `NotificationThreadController.php` | `ntf_notification_threads` | ~200 | ✅ Complete |
| 7 | `NotificationThreadMemberController.php` | `ntf_notification_thread_members` | ~200 | ✅ Complete |
| 8 | `ProviderMasterController.php` | `ntf_provider_master` | ~250 | ⚠️ No encryption |
| 9 | `ResolvedRecipientController.php` | `ntf_resolved_recipients` | ~300 | ⚠️ markAsProcessed doesn't enqueue |
| 10 | `TargetGroupController.php` | `ntf_target_groups` | ~250 | ⚠️ refreshMembers() is stub |
| 11 | `TemplateController.php` | `ntf_templates` (primary) | ~350 | ✅ Complete |
| 12 | `UserPreferenceController.php` | `ntf_user_preferences` | ~250 | ✅ Complete |

### 12.2 Models (14 files)

| # | Model | Table | Relations | Status |
|---|-------|-------|-----------|--------|
| 1 | `ChannelMaster` | `ntf_channel_master` | — | ✅ |
| 2 | `DeliveryQueue` | `ntf_delivery_queue` | resolvedRecipient, notification, channel, provider | ✅ |
| 3 | `Notification` | `ntf_notifications` | tenant, priority, confidentialityLevel, notificationStatus, template, channels, creator, approver | ✅ |
| 4 | `NotificationChannel` | `ntf_notification_channels` | notification, channel, provider, status | ✅ |
| 5 | `NotificationDeliveryLog` | `ntf_delivery_logs` | notification, channel, target, user, status | ✅ |
| 6 | `NotificationTarget` | `ntf_notification_targets` | notification, targetType, targetGroup | ✅ |
| 7 | `NotificationTemplate` | `ntf_templates` | channel, media; render() method | ✅ |
| 8 | `NotificationThread` | `ntf_notification_threads` | parentThread, childThreads, rootNotification, notifications | ✅ |
| 9 | `NotificationThreadMember` | `ntf_notification_thread_members` | thread, notification | ✅ |
| 10 | `ProviderMaster` | `ntf_provider_master` | channel | ✅ |
| 11 | `ResolvedRecipient` | `ntf_resolved_recipients` | notification, channel, template, target, userPreference, user | ✅ |
| 12 | `TargetGroup` | `ntf_target_groups` | creator | ✅ |
| 13 | `UserDevice` | `ntf_user_devices` | user | ✅ (Model only — no controller) |
| 14 | `UserPreference` | `ntf_user_preferences` | user, channel; canReceiveNow(), isWithinQuietHours() | ✅ |

### 12.3 Views (62 files)

| Directory | Files | Status |
|-----------|-------|--------|
| `channels-master/` | 5 (index, create, edit, show, trash) | ✅ |
| `delivery-log/` | 5 | ❌ No controller |
| `delivery-queue/` | 5 | ✅ |
| `notification-targets/` | 5 | ✅ |
| `notification-thread-members/` | 5 | ✅ |
| `notification-threads/` | 5 | ✅ |
| `notifications/` | 5 | ✅ |
| `provider-master/` | 5 | ✅ |
| `resolved-recipients/` | 5 | ✅ |
| `target-group/` | 5 | ✅ |
| `templates/` | 5 | ✅ |
| `user-preferences/` | 5 | ✅ |
| `index.blade.php` | 1 (main dashboard) | ✅ |
| Layouts + Partials | 3 | ✅ |

### 12.4 Missing Files

| Required File | Purpose |
|--------------|---------|
| `app/Models/ScheduleAudit.php` | Model for `ntf_schedule_audit` table |
| `app/Http/Controllers/ScheduleAuditController.php` | Controller for schedule audit views |
| `resources/views/schedule-audit/*.blade.php` | Views for schedule audit (5 files) |
| `app/Http/Controllers/DeliveryLogController.php` | Controller for existing delivery-log views |
| `app/Http/Controllers/UserDeviceController.php` | Controller for device management |
| `resources/views/user-devices/*.blade.php` | Views for device management (5 files) |
| `app/Services/Providers/ProviderFactory.php` | Provider strategy pattern factory |
| `app/Services/Providers/SmsProvider.php` (interface) | SMS provider interface |
| `app/Services/Providers/TwilioProvider.php` | Twilio SMS implementation |
| `app/Services/Providers/Msg91Provider.php` | MSG91 SMS implementation |
| `app/Services/Providers/EmailProvider.php` (interface) | Email provider interface |
| `app/Services/Providers/SesProvider.php` | AWS SES implementation |
| `app/Services/Providers/WhatsAppProvider.php` | WhatsApp provider interface + Meta impl |
| `app/Services/Providers/PushProvider.php` (interface) | Push provider interface |
| `app/Services/Providers/FcmProvider.php` | Firebase Cloud Messaging implementation |
| `app/Services/RecipientResolutionService.php` | Target → resolved recipient pipeline |
| `app/Services/PersonalizationService.php` | Template rendering with payload |
| `app/Services/RateLimiter.php` | Channel rate limiting |
| `app/Console/Commands/ProcessDeliveryQueue.php` | Queue worker command |
| `app/Console/Commands/ProcessScheduledNotifications.php` | Recurring/scheduled processor |
| `app/Http/Controllers/WebhookController.php` | Delivery status webhook receiver |
| `database/migrations/xxx_create_ntf_target_group_members_table.php` | Missing pivot table migration |
| `database/migrations/xxx_create_ntf_schedule_audit_table.php` | Schedule audit table migration |

---

## Conclusion

The Notification module has a **strong architectural foundation** with a comprehensive schema (15 tables), extensive CRUD coverage (12 controllers, 14 models, 62 views), and a working event-driven dispatch pipeline. The template management system with placeholders, versioning, and approval workflow is production-ready.

However, the module is **only ~55% complete** for production use. The core delivery mechanisms — SMS, WhatsApp, Push, queue worker, webhook handling, target resolution, rate limiting, and recurring schedules — are either stubs or completely absent. The module can store configuration beautifully but cannot actually **send** notifications through any channel except email and in-app.

The Phase 1 implementation roadmap (approximately 27 hours of work) would secure credential storage and enable basic delivery for all 5 channels. Phase 2 (26 hours) would complete the delivery pipeline with proper target resolution, queuing, and webhook handling. Phase 3 (24 hours) would add advanced features like recurring schedules and rate limiting.

**Bottom Line:** The Notification module is a well-designed shell waiting for its delivery engine to be installed. With approximately 80-100 hours of additional development, it can become a fully production-ready, multi-channel notification powerhouse.
