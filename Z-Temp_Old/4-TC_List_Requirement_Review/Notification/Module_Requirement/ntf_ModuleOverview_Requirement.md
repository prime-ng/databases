# Notification Module — Business Requirements Overview

## Module Purpose

The Notification module is the central nervous system of the Prime Gurukul platform. It manages all outbound communication across the ecosystem — transactional messages (fee receipts, exam results), promotional broadcasts (event announcements, holiday alerts), reminders (fee due, homework pending), alerts (security incidents, system warnings), and digests (daily summaries, weekly reports). It is **channel-agnostic**, meaning it can route the same message through Email, SMS, WhatsApp, In-App, or Push Notification depending on channel configuration, availability, and user preference. It enforces **rate limits, cost tracking, delivery auditing, retry logic with exponential backoff, and fallback chaining** between channels.

This module also provides the **Inbox** experience — a unified notification feed for students, parents, and teachers to view, read, and manage their notification history. The module powers **two-factor authentication** (OTP verification, challenge flows) and **email verification** for tenant users.

## Default Data Load

When the module is accessed at the main URL (`http://test.localhost:8000/notification/notification-mgt`), the `tabIndex()` method on `Modules\Notification\Http\Controllers\NotificationManageController` loads — and the full `index()` method paginates — the following data sets simultaneously:

| Data Set | Source Model | Page Size |
|----------|-------------|-----------|
| Notifications | `Notification` (with `channels.channel`) | 10 |
| Notification Templates | `NotificationTemplate` (with `channel`) | 10 |
| Delivery Logs | `NotificationDeliveryLog` (with `notification`, `channel`) | 10 |

The main view (`notification::index`) renders 11 tabbed interfaces, each including the respective `Blade` partial for its data set.

## Notification Management — Tabbed Workspace (11 Tabs)

The module presents a unified **tabbed workspace** under the single URL `http://test.localhost:8000/notification/notification-mgt`. All 11 tabs share the same route group with the breadcrumb *"Notification Management > Notifications"*. Each tab corresponds to a distinct business function within the notification lifecycle:

### Tab 1 — Notifications
Create, edit, view, soft-delete, and manage the lifecycle of outbound notifications. Each notification has a UUID, source module/event context, type (TRANSACTIONAL/PROMOTIONAL/ALERT/REMINDER/DIGEST), scheduling options (immediate/scheduled/recurring/triggered), priority, confidentiality, status tracking (draft → approved → processing → completed/failed/partial), cost estimation, and delivery counters.

### Tab 2 — Channels
Define delivery **channels** (EMAIL, SMS, WHATSAPP, IN_APP, PUSH) with business rules: channel type (IMMEDIATE/BULK/TRANSACTIONAL), priority order, retry policy, rate limits (per-minute, daily, monthly), cost per unit, and fallback channel for auto-escalation on failure. Circular fallback chains are prevented by validating up to 5 hops depth. Self-referencing as fallback is prohibited.

### Tab 3 — Providers
Register **provider endpoints** that implement a channel (e.g., Twilio for SMS, MSG91 for SMS, AWS SES for Email, Firebase for Push). Each provider belongs to exactly one channel. Credentials (`api_key_encrypted`, `api_secret_encrypted`) are stored with `SafeEncrypted` casting. Providers are typed as PRIMARY/SECONDARY/BACKUP with configurable priority for failover routing.

### Tab 4 — Target Groups
Define **static** (manually curated member list) or **dynamic** (query-based) groups of recipients. Dynamic groups use a `dynamic_query` JSON field to resolve members at resolution time. System groups (e.g., "All Students", "All Teachers") are flagged with `is_system_group = true` and created by seeders. Member count is tracked in `total_members` and can be recalculated on demand.

### Tab 5 — Targets
Associate **recipient specifications** with a notification. A target can be:
- An **individual** user (via `target_selected_id`)
- A **target group** (via `target_group_id`)
- A **condition-based query** (via `target_condition` JSON providing table/column/value)
- A **class** or **section** (resolved by `RecipientResolutionService` against `std_students`)

### Tab 6 — User Preferences
Each user can set per-channel notification preferences: enable/disable, opt-in/opt-out with timestamps, quiet hours (with overnight support), daily digest toggle and time, and a priority threshold below which messages are suppressed. The `canReceiveNow()` method checks all these conditions before dispatch.

### Tab 7 — Resolved Recipients
When a notification's targets are resolved, each individual recipient gets a row in `ntf_resolved_recipients`. This table stores the resolved address, personalized subject/body (rendered from template + payload), batch ID for chunked processing, priority, and processing status. The `RecipientResolutionService` handles resolution and preference filtering.

### Tab 8 — Notification Threads
Group related notifications into **threads** — useful for conversations (parent-teacher direct messaging), digests (daily summary per class), or broadcasts (school-wide announcement with follow-ups). Threads have a UUID, type (CONVERSATION/DIGEST/BROADCAST), parent-child hierarchy, participant count, and a root notification reference.

### Tab 9 — Notification Thread Members
The many-to-many join between threads and notifications. Each member record stores the `thread_id`, `notification_id`, and `sequence_order` for ordering within the thread.

### Tab 10 — Templates
Reusable message templates scoped to a channel. Templates have a code, name, version, subject, body (rich text sanitized via `SanitizesRichText` trait), alt_body, placeholders (JSON array), language code, optional media attachment, approval workflow (DRAFT → PENDING → APPROVED → REJECTED → ARCHIVED), and effective date range. The `render()` method replaces `{{key}}` and `{{ key }}` placeholders with payload values.

### Tab 11 — Delivery Log
The audit trail of every delivery attempt. Each log record captures the notification, channel, provider, resolved recipient, delivery status (SUCCESS/FAILED), delivery stage (SENT/DELIVERED/READ/CLICKED/BOUNCED/COMPLAINT), response code and payload, error message, duration in milliseconds, user IP and user agent, and cost. This powers the **Inbox** tab where users can see their notification history and mark messages as read.

## Requirements (system-level MUST bullets)

1. **Multi-tenant isolation**: Every table includes `tenant_id` (unsigned integer or UUID) and all queries scope to the current tenant via the `scopeActive()` pattern and `when(tenant(), ...)` conditions.
2. **Soft deletes on all entities**: All 15 `ntf_*` tables implement `Illuminate\Database\Eloquent\SoftDeletes`. The UI exposes trash/restore/forceDelete actions for all CRUD operations.
3. **Active/Inactive toggle**: Every table has an `is_active` boolean column. The UI allows toggling via AJAX `toggleStatus()` endpoints returning JSON.
4. **Audit trail via activityLog**: All create, update, delete, restore, toggle, and process operations log to the activity log system with performer attribution.
5. **Gate-based authorization**: Every controller method gates on a `tenant.<feature>.<action>` permission (e.g., `tenant.notification.create`, `tenant.channel-master.viewAny`, `tenant.provider-master.forceDelete`). The `PrimeNotificationPolicy` class handles coarse-grained checks.
6. **Form Request validation**: Mutations use dedicated Form Requests (e.g., `NotificationRequest`, `ProviderMasterRequest`) with validation rules, custom messages, and `prepareForValidation()` defaulting.
7. **Channel-level rate limiting**: The `NotificationService::isRateLimited()` method enforces per-minute, daily, and monthly limits from the channel configuration, with warning logging on skip.
8. **Circular fallback prevention**: When setting `fallback_channel_id` on a channel, the validation walks up to 5 levels of fallback chain and rejects if any loop is detected.
9. **Encrypted credentials**: Provider API keys and secrets are cast via `SafeEncrypted` for transparent encryption-at-rest in the database.
10. **Recipient resolution pipeline**: Targets → Resolve → Filter by Preference → Personalize → Queue → Dispatch — a pluggable pipeline via `RecipientResolutionService`.
11. **Recurring notifications**: Support for HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY, and CUSTOM (cron/RRULE) recurring patterns with execution count tracking, end date, and schedule audit logging.
12. **Quiet hours**: Per-user per-channel quiet hours with overnight span support (e.g., 22:00–06:00), evaluated at dispatch time.
13. **In-App notification delivery**: Uses Laravel's `Notifiable` trait with a custom `InAppSystemNotification` to store notifications in the database-based notification system, visible in the Inbox.

## Dependencies module and tables

### Primary Tables (all `ntf_` prefix)

| Table | Purpose | Key FK References |
|-------|---------|------------------|
| `ntf_channel_master` | Channel definitions (EMAIL/SMS/etc.) | `fallback_channel_id` → self |
| `ntf_provider_master` | Provider endpoints per channel | `channel_id` → `ntf_channel_master` |
| `ntf_notifications` | Notification records | `template_id` → `ntf_templates`, `priority_id`/`confidentiality_level_id`/`notification_status_id` → `sys_dropdown_table` |
| `ntf_notification_channels` | Channel assignment per notification | `notification_id` → `ntf_notifications`, `channel_id` → `ntf_channel_master`, `provider_id` → `ntf_provider_master` |
| `ntf_target_groups` | Static/dynamic recipient groups | `created_by` → `users` |
| `ntf_notification_targets` | Target specifications per notification | `notification_id` → `ntf_notifications`, `target_group_id` → `ntf_target_groups`, `target_type_id` → `sys_dropdown_table` |
| `ntf_user_preferences` | Per-user channel preferences | `user_id` → `users`, `channel_id` → `ntf_channel_master` |
| `ntf_user_devices` | Registered user devices for push | `user_id` → `users` |
| `ntf_templates` | Message templates | `channel_id` → `ntf_channel_master`, `media_id` → `media` |
| `ntf_resolved_recipients` | Resolved individual recipients | `notification_id` → `ntf_notifications`, `channel_id` → `ntf_channel_master`, `resolved_user_id` → `users` |
| `ntf_delivery_queue` | Queued delivery items | `resolved_recipient_id` → `ntf_resolved_recipients`, `notification_id` → `ntf_notifications`, `channel_id` → `ntf_channel_master` |
| `ntf_delivery_logs` | Delivery attempt audit trail | `notification_id` → `ntf_notifications`, `channel_id` → `ntf_channel_master`, `resolved_user_id` → `users` |
| `ntf_notification_threads` | Thread grouping | `parent_thread_id` → self, `root_notification_id` → `ntf_notifications` |
| `ntf_notification_thread_members` | Thread-to-notification mapping | `thread_id` → `ntf_notification_threads`, `notification_id` → `ntf_notifications` |
| `ntf_schedule_audit` | Recurring execution audit trail | `notification_id` → `ntf_notifications` |

### External Module Dependencies

| Module | Dependency | Usage |
|--------|-----------|-------|
| **SchoolSetup** | `Modules\SchoolSetup\Models\User` | Creator, approver, resolved user references; user device registration; preference ownership |
| **GlobalMaster** | `Modules\GlobalMaster\Models\Dropdown` | Lookup values for notification status, priority, confidentiality, delivery status, target type, provider |
| **Prime** | `Modules\Prime\Models\Tenant` | Multi-tenant scope isolation; `Modules\Prime\Models\Media` for template attachments |
| **Timetable (tpt_)** | `tpt_notification_log` | Notification log integrated with timetable module for class/section event notifications |
| **Hostel (hst_)** | `hst_notification_log` | Notification log integrated with hostel module for boarding house notifications |
| **Laravel Notifications** | `Illuminate\Notifications\Notifiable` trait | In-App notification delivery via `InAppSystemNotification` |
| **Activity Log** | `activityLog()` helper | Audit logging for all CRUD and lifecycle operations |
