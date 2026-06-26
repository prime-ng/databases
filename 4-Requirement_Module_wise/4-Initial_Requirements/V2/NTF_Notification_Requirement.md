# NTF — Notification Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** NTF | **Module Type:** Tenant | **Table Prefix:** `ntf_`
**RBS Reference:** Module Q — Communication & Messaging (Notification subsystem)

---

## 1. Executive Summary

The Notification module (NTF) is the central communication backbone for the Prime-AI platform. It provides multi-channel notification delivery to all tenant stakeholders — school administrators, teachers, students, and parents. It implements an event-driven architecture where any tenant module can fire a `SystemNotificationTriggered` event that is asynchronously dispatched through a queued listener (`ProcessSystemNotification`) to one or more configured channels: Email, In-App, SMS, WhatsApp, and Push.

**Implementation State (as of 2026-03-26):** ~50% complete. The module has a well-structured schema (15 DDL tables), 12 controllers, 15 models, 2 service files, 10 FormRequests, comprehensive views, and Laravel event/listener infrastructure in place. However, the module is entirely inaccessible in production due to a combination of critical routing and authorization bugs, and none of the external delivery channels (Email, SMS, WhatsApp, Push) work correctly.

**Completion Score:** 5.0 / 10 (Gap Analysis: 36 issues — 6 Critical, 11 High, 13 Medium, 6 Low)

### Critical Blockers (must fix before any production use)

| Bug ID | Severity | Description |
|--------|----------|-------------|
| BUG-NTF-001 | CRITICAL | Template routes entirely commented out in `tenant.php` — template management blocked |
| BUG-NTF-002 | CRITICAL | `EnsureTenantHasModule` middleware NOT applied to notification route group |
| BUG-NTF-003 | CRITICAL | Gate prefix `prime.notification.*` instead of `tenant.notification.*` — multi-tenant auth broken |
| BUG-NTF-004 | CRITICAL | `store()` / `update()` in `NotificationManageController` use `$request->field` instead of `$request->validated()` — FormRequest validation bypassed |
| BUG-NTF-005 | CRITICAL | `ProcessNotificationJob::dispatch()` commented out in `process()` — notifications never actually sent |
| BUG-NTF-006 | HIGH | Email `sendEmail()` call commented out in `NotificationService::dispatchToChannel()` — email silently skipped |

### Effort Estimation

| Priority | Hours |
|----------|-------|
| P0 Fixes (critical bugs) | 12–16 |
| P1 Fixes (feature completion) | 32–40 |
| P2 Fixes (quality, missing channels) | 40–56 |
| P3 Enhancements | 16–24 |
| Test Suite | 20–28 |
| **Total** | **120–164** |

---

## 2. Module Overview

### 2.1 Business Purpose

Schools require timely, reliable, multi-channel communication to inform parents about fee dues, exam results, attendance alerts, and emergency notices. Teachers need to broadcast homework assignments and quiz reminders. Administrators need to send school-wide announcements. The NTF module unifies all of these use cases under a single configurable notification engine.

Core capabilities:
- Automated event-driven notifications triggered by any other module
- Manual ad-hoc notifications composed by admins or teachers
- Multi-channel delivery with fallback logic
- Recipient targeting by role, class, section, group, or individual
- Per-user preference and opt-in/opt-out management (GDPR-compliant)
- Delivery tracking with full audit trail
- DLT-compliant SMS template registration workflow (India regulatory)
- Notification inbox UI with read/unread management

### 2.2 Architecture Overview

```
[Any Module fires event]
    SystemNotificationTriggered::dispatch($eventCode, $context)
         |
         v
[Laravel Queue — ProcessSystemNotification listener]
    $tries=3, $backoff=10s, $timeout=120s
         |
         v
[NotificationService::trigger($eventCode, $payload)]
    1. Lookup ntf_notifications WHERE notification_event = $eventCode
    2. foreach active channel on that notification:
         a. Fetch ntf_templates WHERE template_code = $eventCode AND channel_id = ?
         b. Render template: replace {{placeholders}} with $payload values
         c. Resolve recipients from ntf_notification_targets
         d. Write to ntf_resolved_recipients (batch_id for bulk)
         e. Enqueue in ntf_delivery_queue
         f. dispatchToChannel($channelCode, $content, $recipient)
              EMAIL    → Mail::send() [currently commented out]
              IN_APP   → $user->notify(new InAppSystemNotification())  [working]
              SMS      → SMS Gateway adapter [stub only]
              PUSH     → FCM via ntf_user_devices.device_token [stub only]
              WHATSAPP → Meta Business API [stub only]
         g. Write to ntf_delivery_logs (status, timestamps, cost)
```

### 2.3 Feature Status Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Channel Master Configuration | 🟡 Partial | Schema + controller + views exist; routes present |
| Provider Master (gateway config) | 🟡 Partial | Schema + controller + views exist; encryption not enforced |
| Notification Templates | ❌ Blocked | Routes commented out in tenant.php |
| Notification Create/Manage | 🟡 Partial | Controller exists; uses `$request->field` not `validated()` |
| Target Groups | 🟡 Partial | Schema + controller + views; resolution logic missing |
| Event-Driven Dispatch | 🟡 Partial | Event + listener exist; `process()` dispatch commented out |
| Email Delivery | ❌ Broken | `sendEmail()` call commented out (BUG-NTF-006) |
| In-App Delivery | ✅ Working | Via Laravel Notification system |
| SMS Delivery | ❌ Not Started | Stub only in switch/default |
| WhatsApp Delivery | ❌ Not Started | Not implemented |
| Push (FCM) Delivery | ❌ Not Started | Device model exists; dispatch stubbed |
| Delivery Queue Management | 🟡 Partial | Schema + controller; no worker implementation |
| Delivery Logs | 🟡 Partial | Schema + model; service does not write to it |
| User Notification Preferences | 🟡 Partial | Schema + controller + FormRequest; routes present |
| User Device Registry (FCM) | 🟡 Partial | Model exists; no dedicated controller |
| Notification Threads | 🟡 Partial | Schema + controller; functional in isolation |
| Schedule Audit | ❌ Missing | Schema exists; no controller or views |
| DLT Template Registration | ❌ Not Started | Indian SMS compliance — not modeled |
| Rate Limiting Enforcement | ❌ Not Started | Schema has columns; code does not enforce |
| Retry Logic | ❌ Not Started | Schema has max_retry; service does not implement |
| Cost Tracking | ❌ Not Started | Schema has cost columns; never populated |
| Tests | ❌ Not Started | Zero tests (only .gitkeep files) |

### 2.4 Menu Path

```
Tenant Dashboard
  > Communication
      > Notifications (index — tab layout)
          - Manage Notifications
          - Templates
          - Channels
          - Providers
          - Target Groups
          - User Preferences
          - Delivery Queue
          - Delivery Logs
          - Threads
```

---

## 3. Stakeholders & Roles

| Actor | Role in NTF | Access Level |
|-------|-------------|--------------|
| Super Admin (Prime) | Platform-wide channel/provider seeding | Full access to system templates |
| School Admin | Create notifications, manage templates, channels, providers | Full CRUD on all NTF resources |
| Teacher | Send targeted notifications to own class/section students or parents | Create + send to own classes only |
| Student | Receive in-app notifications | Read-only (inbox) |
| Parent | Receive email/SMS/push/WhatsApp notifications | Read-only; opt-in/opt-out |
| System (event-driven) | Automated notification triggers from other modules | Fire-and-forget via `SystemNotificationTriggered` |
| Queue Worker | Process `ntf_delivery_queue` items | Infrastructure-level; no UI actor |

---

## 4. Functional Requirements

### FR-NTF-01: Channel Master Management

**RBS Ref:** F.Q1.2, F.Q2.2, F.Q3.2
**Status:** 🟡 Partial — routes present but missing `EnsureTenantHasModule` middleware

**REQ-NTF-01.1 — Channel Configuration**
The system shall maintain a master list of notification channels per tenant. Supported channel types: `EMAIL`, `SMS`, `WHATSAPP`, `IN_APP`, `PUSH`. Each channel shall have configurable rate limits (`rate_limit_per_minute`, `daily_limit`, `monthly_limit`), retry behavior (`max_retry`, `retry_delay_minutes`), cost tracking (`cost_per_unit`), priority order, and an optional `fallback_channel_id` self-reference.

**REQ-NTF-01.2 — Channel Activation**
Admin shall be able to activate or deactivate any channel. An inactive channel shall be skipped by `NotificationService` without error. The system shall log a warning when a configured channel is skipped due to inactive status.

**REQ-NTF-01.3 — Fallback Routing**
When a channel fails delivery and a `fallback_channel_id` is configured, the system shall automatically route the delivery attempt to the fallback channel. Fallback chains must not be circular.

**REQ-NTF-01.4 — Rate Limit Enforcement**
📐 Rate limits shall be enforced at the queue worker level using Laravel's `RateLimiter` (not just stored in config). Deliveries exceeding `rate_limit_per_minute` shall be deferred to the next window. Daily/monthly limits shall halt dispatch and log an alert to admin.

**Acceptance Criteria:**
- AC-01.1: Admin creates EMAIL channel with valid rate limits → persisted, visible in channel list.
- AC-01.2: Channel deactivated → NotificationService skips it without exception; log entry written.
- AC-01.3: Primary channel fails → system routes to `fallback_channel_id` automatically.
- AC-01.4: Rate limit exceeded → delivery queued for next window; no delivery dropped silently.

**Implementation Notes:**
- `ntf_channel_master` DDL defined (line 2289). `ChannelMasterController` exists. Routes present in tenant.php.
- Missing: `ChannelMasterRequest` FormRequest (FR-02 in gap analysis). Rate limit code not implemented.

---

### FR-NTF-02: Provider Master — External Gateway Configuration

**RBS Ref:** F.Q2.2, F.Q3.1
**Status:** 🟡 Partial — controller + FormRequest + views exist; encryption not enforced in model

**REQ-NTF-02.1 — Provider Setup**
Admin shall configure external notification providers (Twilio, MSG91, AWS SES, Firebase FCM). Multiple providers per channel are supported with `provider_type` designation: PRIMARY, SECONDARY, BACKUP.

**REQ-NTF-02.2 — Credential Encryption**
Provider credentials (`api_key_encrypted`, `api_secret_encrypted`) shall be stored using Laravel's `encrypted` cast or explicit `Crypt::encrypt()`. Plaintext storage is prohibited. Encryption key rotation must be supported without data loss.

**REQ-NTF-02.3 — Provider Test Connection**
📐 Admin shall be able to test provider connectivity before saving. The system shall send a test ping/message to the provider API and return success/failure with the response payload visible in the UI.

**REQ-NTF-02.4 — DLT Registration (India-specific)**
📐 For SMS channels in India, the system shall store the DLT (Distributed Ledger Technology) registered template ID from TRAI's portal. Each `ntf_templates` record for SMS channel type shall have an optional `dlt_template_id` field. SMS delivery shall use the DLT template ID as the `template_id` parameter in MSG91/Twilio requests. Notifications without a registered `dlt_template_id` on the SMS channel shall be blocked with an error.

**Acceptance Criteria:**
- AC-02.1: Provider API key saved → stored encrypted; cannot be retrieved in plaintext from DB.
- AC-02.2: Test connection button → returns HTTP 200 + provider confirmation message.
- AC-02.3: SMS template without DLT ID → delivery blocked with clear error: "DLT template ID required for SMS".

---

### FR-NTF-03: Notification Template System

**RBS Ref:** F.Q1.2
**Status:** ❌ Blocked — routes commented out in tenant.php (BUG-NTF-001)

**REQ-NTF-03.1 — Template Management**
Templates shall be linked to a specific `channel_id` and identified by `template_code` (matches `notification_event`). Templates support versioning (`template_version` INT) with a full approval workflow. Template body uses `{{placeholder_name}}` syntax (both `{{key}}` and `{{ key }}` forms supported by `render()`).

**REQ-NTF-03.2 — Approval Workflow**
Template approval states: `DRAFT` → `PENDING` (submitted for review) → `APPROVED` (active for dispatch) → `REJECTED` (with reason comment) or `ARCHIVED` (superseded). Only `APPROVED` templates can be used for delivery. System templates (`is_system_template = 1`) can only be managed by Prime Super Admin.

**REQ-NTF-03.3 — Template Rendering**
`NotificationTemplate::render(array $payload): array` shall interpolate scalar values from `$payload` into `{{key}}` placeholders in both `subject` and `body`. Non-scalar payload values shall be skipped silently. Rendered output is stored in `ntf_resolved_recipients.personalized_subject` and `personalized_body`.

**REQ-NTF-03.4 — Template Versioning**
Multiple versions of the same `template_code` for the same channel may exist. The unique constraint is `(tenant_id, template_code, template_version)`. When dispatching, the system shall use the highest `template_version` record with `approval_status = APPROVED` within its `effective_from`/`effective_to` date range.

**REQ-NTF-03.5 — Multi-Language Support**
Templates are identified per language via `language_code` (default: `en`). The system shall select the template matching the recipient's language preference, falling back to the `en` template if no match.

**REQ-NTF-03.6 — DLT Template ID**
📐 `ntf_templates` shall have an optional `dlt_template_id VARCHAR(50)` column (new in V2). Required for all SMS-channel templates deployed in India. Displayed in template edit form under "Compliance" section.

**Acceptance Criteria:**
- AC-03.1: Template with `{{student_name}}` and payload `['student_name'=>'Rahul']` → rendered body substitutes correctly.
- AC-03.2: DRAFT template dispatch attempt → blocked with "Template not approved" error.
- AC-03.3: Two versions of same template_code — system picks highest APPROVED version in date range.
- AC-03.4: SMS template missing DLT ID → blocked on Indian tenant with compliance warning.

**Implementation Notes:**
- `ntf_templates` DDL table defined (line 2544). `NotificationTemplate` model has working `render()` method.
- `TemplateController` and `NotificationTemplateController` both exist — duplication to resolve (keep `TemplateController`).
- **FIX REQUIRED:** Uncomment template routes in tenant.php lines 2503–2506.
- **FIX REQUIRED:** Model `NotificationTemplate` maps to `ntf_notification_templates` but DDL defines `ntf_templates` — align model `$table` property.

---

### FR-NTF-04: Notification Creation (Manual)

**RBS Ref:** F.Q1.1, F.Q5.1
**Status:** 🟡 Partial — controller exists with 569 lines; critical validation and dispatch bugs

**REQ-NTF-04.1 — Manual Notification Compose**
Admin and teachers shall compose ad-hoc notifications with: title, notification_type (TRANSACTIONAL/PROMOTIONAL/ALERT/REMINDER/DIGEST), priority, schedule type (IMMEDIATE/SCHEDULED/RECURRING/TRIGGERED), channel assignment, target group or explicit recipient selection, and template selection or custom body.

**REQ-NTF-04.2 — Scheduling**
For SCHEDULED type, admin specifies `scheduled_at` datetime. For RECURRING type, admin configures `recurring_pattern` (HOURLY/DAILY/WEEKLY/MONTHLY/YEARLY/CUSTOM) and `recurring_expression` (cron or RRULE string). The scheduler job shall pick up due notifications and dispatch them.

**REQ-NTF-04.3 — Approval Workflow for Bulk**
📐 Notifications of type PROMOTIONAL targeting more than 100 recipients shall require approval by a School Admin before processing. `approved_by` and `approved_at` columns in `ntf_notifications` shall be populated on approval.

**REQ-NTF-04.4 — Notification Expiry**
Notifications with `expires_at` set shall not be dispatched after that timestamp. Queue workers shall check `expires_at` before processing.

**REQ-NTF-04.5 — Validated Input**
Controllers shall use `$request->validated()` from the corresponding FormRequest, never direct `$request->field` access.

**Acceptance Criteria:**
- AC-04.1: Immediate notification created → enters processing within queue worker cycle.
- AC-04.2: Scheduled notification → dispatched within 1 minute of `scheduled_at`.
- AC-04.3: Promotional notification to 200+ recipients → status stays PENDING until approved.
- AC-04.4: Notification past `expires_at` → skipped by queue worker; status set to EXPIRED.
- AC-04.5: Invalid form submission → 422 returned with field-level errors from FormRequest.

**Implementation Notes:**
- `NotificationManageController` (569 lines) — massive `index()` god-method loading 8+ queries simultaneously (PERF-01).
- **BUG-NTF-004:** `store()` (lines 274–310) and `update()` (lines 371–393) use `$request->field` not `$request->validated()`.
- **BUG-NTF-005:** `process()` method has `ProcessNotificationJob::dispatch()` commented out — notifications never sent.
- `getRouteKeyName()` returns `notification_uuid` but controllers call `findOrFail($id)` with integer ID — route model binding conflict (MD-01).

---

### FR-NTF-05: Event-Driven Notification Dispatch

**RBS Ref:** F.Q1.1, F.Q5.1, F.Q6.1
**Status:** 🟡 Partial — event/listener infrastructure exists; dispatch commented out; SMS/Push stubbed

**REQ-NTF-05.1 — Event API for Other Modules**
Any module shall trigger notifications by dispatching:
```php
SystemNotificationTriggered::dispatch(string $eventCode, array $context)
```
`$eventCode` must match `ntf_notifications.notification_event` and `ntf_templates.template_code`. If no matching notification record is found, `NotificationService::trigger()` shall log a warning and return without error.

**REQ-NTF-05.2 — Queued Listener**
`ProcessSystemNotification` implements `ShouldQueue` with `$tries = 3`, `$backoff = 10` seconds, `$timeout = 120` seconds. Failed jobs after 3 attempts are logged via `failed()` method to application logs and stored in Laravel's `failed_jobs` table.

**REQ-NTF-05.3 — Channel Dispatch Pipeline**
`NotificationService::trigger()` shall:
1. Find the `ntf_notifications` record matching `notification_event`.
2. For each active channel (`ntf_notification_channels`): fetch the APPROVED template, render with context, resolve recipients, write `ntf_resolved_recipients`, enqueue in `ntf_delivery_queue`, call `dispatchToChannel()`.
3. Write each delivery attempt result to `ntf_delivery_logs`.

**REQ-NTF-05.4 — Channel Dispatch Implementations**
- **EMAIL:** `Mail::send()` using HTML body from rendered template subject/body. Supports attachments via `sys_media`.
- **IN_APP:** `$user->notify(new InAppSystemNotification($content))` via Laravel's notification system.
- **SMS:** Call provider adapter using `ntf_provider_master` credentials. DLT template ID passed to MSG91/Twilio API.
- **PUSH (FCM):** Use `ntf_user_devices.device_token` to send via Firebase Admin SDK or HTTP v1 API.
- **WHATSAPP:** Meta Business API (Cloud API) using template name and language parameters.

**REQ-NTF-05.5 — Delivery Status Tracking**
After each dispatch attempt, write to `ntf_delivery_logs`: `delivery_stage` (QUEUED → SENT → DELIVERED), `provider_message_id`, `duration_ms`, `cost`, and on failure: `error_message`. Update counter columns on `ntf_notifications` (`sent_count`, `failed_count`).

**REQ-NTF-05.6 — ProcessNotificationJob**
📐 A dedicated `ProcessNotificationJob` shall process items from `ntf_delivery_queue`. Worker locking via `locked_by`/`locked_at` prevents duplicate processing. The job shall: lock a PENDING batch, dispatch each item, update status to SENT/FAILED, and release the lock. On failure, increment `attempt_count`; if `attempt_count >= max_attempts`, set status to FAILED.

**Acceptance Criteria:**
- AC-05.1: `FEE_DUE_REMINDER` event fired → EMAIL and IN_APP channels both receive and log delivery.
- AC-05.2: Email dispatch exception → `ntf_delivery_logs` records `delivery_stage = BOUNCED`, `error_message` populated.
- AC-05.3: Unknown event code fired → warning logged, no exception thrown, no orphan records.
- AC-05.4: Push token invalid → error logged; delivery marked FAILED; other recipients unaffected.
- AC-05.5: Queue worker crashes mid-batch → locked items auto-released after lock timeout; reprocessed.

**Implementation Notes:**
- `SystemNotificationTriggered` event — complete.
- `ProcessSystemNotification` listener — present with retry logic.
- **BUG-NTF-006:** `NotificationService.php:77` has `//$this->sendEmail(...)` commented out.
- SMS/PUSH/WHATSAPP: `switch/default` branch only — no implementation.
- No `ProcessNotificationJob` exists yet (ARCH-01, ARCH-02 from gap analysis).

---

### FR-NTF-06: Recipient Targeting

**RBS Ref:** F.Q5.2, F.Q6.1
**Status:** 🟡 Partial — schema + controller + views exist; dynamic resolution not implemented

**REQ-NTF-06.1 — Target Group Management**
Admin shall create named target groups (`ntf_target_groups`) as STATIC or DYNAMIC. Static groups have fixed member lists managed via a many-to-many join. Dynamic groups store a `dynamic_query` JSON descriptor that is resolved at dispatch time (e.g., `{"role":"PARENT","class_id":5,"section_id":null}`). System groups (`is_system_group = 1`) are pre-seeded and cannot be deleted.

**REQ-NTF-06.2 — Notification Target Assignment**
Each notification may have multiple target entries in `ntf_notification_targets`. Target types (from `sys_dropdown_table`): STUDENT, PARENT, TEACHER, CLASS, SECTION, GROUP, INDIVIDUAL. The system shall resolve these to individual user records and write to `ntf_resolved_recipients`.

**REQ-NTF-06.3 — Recipient Resolution Pipeline**
📐 A `RecipientResolutionService` (new in V2) shall:
1. Accept a `Notification` with its `NotificationTarget` records.
2. For each target: expand to individual `sys_users` records.
3. For each user: check `ntf_user_preferences` — skip channel if user has opted out.
4. Apply quiet hours check — if within quiet window, set `scheduled_at` to end of window.
5. Write one `ntf_resolved_recipients` row per (user × channel).
6. Group into batches (batch_id = UUID), set `batch_sequence`.

**Acceptance Criteria:**
- AC-06.1: Target type CLASS → all students in that class resolved to individual rows in `ntf_resolved_recipients`.
- AC-06.2: User opted out of SMS channel → SMS recipient row not created for that user.
- AC-06.3: User in quiet hours → recipient row created with `scheduled_at` = end of quiet window.
- AC-06.4: Dynamic group `{"role":"PARENT"}` → all parent users of tenant resolved.

---

### FR-NTF-07: User Preferences & Device Management

**RBS Ref:** F.Q3.2
**Status:** 🟡 Partial — models + controller + FormRequest exist; routes present

**REQ-NTF-07.1 — User Notification Preferences**
Each user can configure preferences per channel in `ntf_user_preferences`:
- Enable/disable the channel (`is_enabled`).
- GDPR opt-in/opt-out with timestamps (`opted_in_at`, `opted_out_at`).
- Quiet hours: `quiet_hours_start`, `quiet_hours_end`, and `quiet_hours_timezone` (IANA timezone string).
- Daily digest mode with configurable `digest_time`.
- Priority threshold (`priority_threshold_id`) — only receive notifications at or above this priority.

**REQ-NTF-07.2 — Opt-Out Compliance**
`is_opted_in = 0` MUST be respected immediately and absolutely. No notification shall be delivered to a user who has opted out of a channel, regardless of other settings. Opt-out is final until explicitly reversed by the user (not by admin).

**REQ-NTF-07.3 — Device Registration (FCM/Push)**
Mobile apps and browsers register FCM/APNS tokens via `ntf_user_devices`. Supported device types: ANDROID, IOS, WEB, DESKTOP. Unique constraint on `(user_id, device_token)` prevents duplicates. Token refresh from app replaces old token. `last_active_at` updated on each use.

**REQ-NTF-07.4 — Device Controller**
📐 A `UserDeviceController` shall be created (new in V2) to handle device token registration from mobile/web clients. Requires a secure API endpoint (`POST /api/v1/notifications/devices`) with auth:sanctum middleware.

**Acceptance Criteria:**
- AC-07.1: User disables EMAIL channel → no email delivered, even for system events.
- AC-07.2: Opt-out at 14:00 → notification queued at 13:55 for that user is cancelled.
- AC-07.3: App submits same device token twice → second insert ignored (upsert by unique key).
- AC-07.4: Device token expired → FCM error caught; device record marked inactive; delivery logged as FAILED.

---

### FR-NTF-08: Delivery Queue & Retry

**RBS Ref:** F.Q7.1
**Status:** 🟡 Partial — schema + controller + views exist; no worker/consumer implementation

**REQ-NTF-08.1 — Queue Entry Creation**
One `ntf_delivery_queue` record is created per resolved recipient per channel. Fields: `resolved_recipient_id`, `notification_id`, `channel_id`, `provider_id`, `queue_status` (PENDING/PROCESSING/SENT/FAILED/RETRY/CANCELLED), `priority`, `scheduled_at`, worker locking (`locked_by`/`locked_at`), `attempt_count`, `max_attempts`, `last_error`, `next_attempt_at`.

**REQ-NTF-08.2 — Worker Processing**
Queue workers shall select PENDING items ordered by `(priority ASC, scheduled_at ASC)`. Workers lock items by setting `locked_by = worker_id` and `locked_at = NOW()`. Lock timeout of 5 minutes — items locked longer than timeout are reclaimed by the next worker.

**REQ-NTF-08.3 — Retry Logic**
On delivery failure: increment `attempt_count`, set `queue_status = RETRY`, compute `next_attempt_at = NOW() + (attempt_count × retry_delay_minutes)`. When `attempt_count >= max_attempts`, set `queue_status = FAILED`. Write failure details to `ntf_delivery_logs`.

**REQ-NTF-08.4 — Admin Queue Monitor**
Admin UI shall display the delivery queue with filters by status, channel, date range. Admin shall be able to manually retry FAILED items or cancel PENDING items.

**Acceptance Criteria:**
- AC-08.1: Delivery fails 3 times → status = FAILED; `last_error` populated; delivery log written for each attempt.
- AC-08.2: Worker crashes → locked items auto-released after 5-minute lock timeout.
- AC-08.3: Admin cancels PENDING item → status = CANCELLED; recipient receives nothing.
- AC-08.4: Queue monitor paginated; 1000-item backlog visible without timeout.

---

### FR-NTF-09: Delivery Logging & Audit Trail

**Status:** 🟡 Partial — `ntf_delivery_logs` DDL defined; model exists; service never writes to it

**REQ-NTF-09.1 — Delivery Log Entries**
Every delivery attempt shall create a record in `ntf_delivery_logs`: notification_id, channel_id, resolved_recipient_id, resolved_user_id, provider_id, delivery_stage (QUEUED/SENT/DELIVERED/READ/CLICKED/BOUNCED/COMPLAINT/UNSUBSCRIBED), `provider_message_id`, timestamps (`delivered_at`, `read_at`, `clicked_at`), `response_payload` JSON, `error_message`, `duration_ms`, `cost`.

**REQ-NTF-09.2 — Read/Click Tracking (In-App)**
For IN_APP notifications: `read_at` is set when the user opens the notification bell and marks it read. `clicked_at` is set when the user clicks a CTA link within the notification. These events are fired via AJAX endpoints.

**REQ-NTF-09.3 — Webhook Callbacks (External)**
For SMS/Email/Push providers that support delivery receipts (MSG91, AWS SES bounce/complaint webhooks): the system shall expose a secured webhook endpoint that updates `ntf_delivery_logs.delivery_stage` and related timestamps from provider callbacks.

**REQ-NTF-09.4 — Immutability**
Delivery log records are append-only. No log entry shall be deleted or updated. New entries are created for each delivery stage transition.

**REQ-NTF-09.5 — Aggregate Counters**
Counters on `ntf_notifications` (`sent_count`, `failed_count`, `delivered_count`, `read_count`, `click_count`) shall be updated atomically (`increment()`) by the delivery service after each log entry.

**Acceptance Criteria:**
- AC-09.1: Successful email delivery → log entry with `delivery_stage = SENT`, `delivered_at` set, `duration_ms` populated.
- AC-09.2: Bounce webhook received → `delivery_stage` updated to BOUNCED, `bounced_at` set, `ntf_notifications.failed_count` incremented.
- AC-09.3: `ntf_delivery_logs` records cannot be deleted via UI or API.

---

### FR-NTF-10: Notification Inbox (In-App UI)

**Status:** ❌ Not Started — no dedicated inbox views found in Notification module

**REQ-NTF-10.1 — Notification Bell**
A notification bell icon in the tenant header shall show the count of unread in-app notifications for the current user. Count shall be retrieved via AJAX polling or Laravel Echo WebSocket subscription.

**REQ-NTF-10.2 — Inbox View**
Users shall have a notification inbox listing all their in-app notifications with: title, summary text, received timestamp, read/unread status, source module badge, and a deep-link URL to the source record.

**REQ-NTF-10.3 — Read/Mark All Read**
Users shall mark individual notifications as read or use "Mark all as read" bulk action. Read state is tracked in `ntf_resolved_recipients` or a dedicated `ntf_user_reads` table (📐 new in V2 if resolved_recipients is too heavy).

**REQ-NTF-10.4 — Notification Preferences Link**
Inbox shall include a link to user preferences (`/notifications/preferences`) allowing users to adjust channel settings and quiet hours.

**Acceptance Criteria:**
- AC-10.1: New in-app notification fires → bell count increments within 30 seconds.
- AC-10.2: User clicks notification → marked read; count decremented; deep-link followed.
- AC-10.3: Mark all read → all notifications marked; count = 0.

---

### FR-NTF-11: Notification Threads

**Status:** 🟡 Partial — schema + controller + views exist; functional in isolation

**REQ-NTF-11.1 — Thread Grouping**
Related notifications may be grouped into threads (`ntf_notification_threads`) of type: CONVERSATION (bidirectional), DIGEST (periodic summary), BROADCAST (one-to-many). Each thread has a `thread_uuid`, optional subject, and parent/child relationship for nesting.

**REQ-NTF-11.2 — Thread Members**
`ntf_notification_thread_members` links notifications to threads via `sequence_order`. A notification may belong to exactly one thread (unique constraint).

**REQ-NTF-11.3 — Recalculate Counters**
The `recalculate` route endpoint on `NotificationThreadController` shall recompute `total_notifications` and `participant_count` from member records.

---

### FR-NTF-12: Scheduled & Recurring Notifications

**Status:** ❌ Not Started — schema fields exist; no scheduler job or cron handling

**REQ-NTF-12.1 — Scheduled Dispatch**
A Laravel scheduled command `notifications:process-due` shall run every minute. It selects `ntf_notifications` where `schedule_type = SCHEDULED` and `scheduled_at <= NOW()` and `notification_status_id = APPROVED`. For each, it triggers the dispatch pipeline.

**REQ-NTF-12.2 — Recurring Dispatch**
For `schedule_type = RECURRING`, after each dispatch, the command computes the next occurrence from `recurring_expression` (cron format) and creates a new `ntf_schedule_audit` record. The parent notification `recurring_pattern` drives frequency.

**REQ-NTF-12.3 — Schedule Audit**
Every scheduled execution (success, failure, or skipped) is recorded in `ntf_schedule_audit` with `execution_status`, `actual_execution_time`, and `error_message` if failed.

**Acceptance Criteria:**
- AC-12.1: Scheduled notification at 08:00 → dispatched by 08:01 (within 1 scheduler cycle).
- AC-12.2: Daily recurring notification → fires each day at configured time; `ntf_schedule_audit` records each execution.
- AC-12.3: Skipped notification (no recipients resolved) → `execution_status = SKIPPED` logged.

---

## 5. Data Model

### 5.1 Table Overview (15 tables)

| Table | Purpose | DDL Line |
|-------|---------|----------|
| `ntf_channel_master` | Channel configuration (EMAIL/SMS/etc.) | 2289 |
| `ntf_provider_master` | External gateway credentials | 2318 |
| `ntf_notifications` | Notification header records | 2342 |
| `ntf_notification_channels` | Per-notification channel assignment | 2406 |
| `ntf_target_groups` | Named recipient groups (static/dynamic) | 2439 |
| `ntf_notification_targets` | Target definitions per notification | 2464 |
| `ntf_user_devices` | FCM/APNS device tokens | 2491 |
| `ntf_user_preferences` | Per-user per-channel preferences | 2513 |
| `ntf_templates` | Message templates with placeholder support | 2544 |
| `ntf_resolved_recipients` | Final resolved recipients with personalization | 2581 |
| `ntf_delivery_queue` | Delivery work queue with locking | 2622 |
| `ntf_delivery_logs` | Complete delivery audit trail | 2654 |
| `ntf_notification_threads` | Thread grouping of notifications | 2697 |
| `ntf_notification_thread_members` | Thread-notification association | 2721 |
| `ntf_schedule_audit` | Recurring notification execution history | 2737 |

### 5.2 Table: `ntf_channel_master`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| tenant_id | INT UNSIGNED | NOT NULL, INDEX | Tenant isolation (see DB-01 note) |
| code | VARCHAR(20) | NOT NULL, UNIQUE(tenant_id, code) | EMAIL, SMS, WHATSAPP, IN_APP, PUSH |
| name | VARCHAR(50) | NOT NULL | Display name |
| channel_type | ENUM | IMMEDIATE/BULK/TRANSACTIONAL | |
| priority_order | TINYINT | DEFAULT 5 | 1=Highest, 10=Lowest |
| max_retry | INT | DEFAULT 3 | Max delivery retries |
| retry_delay_minutes | INT | DEFAULT 5 | Minutes between retries |
| rate_limit_per_minute | INT | DEFAULT 100 | Throttle limit |
| daily_limit | INT | DEFAULT 10000 | Daily cap |
| monthly_limit | INT | DEFAULT 100000 | Monthly cap |
| cost_per_unit | DECIMAL(10,4) | DEFAULT 0 | Per-message cost |
| fallback_channel_id | INT UNSIGNED | NULL, FK → self | Auto-fallback channel |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at / updated_at / deleted_at | TIMESTAMP | Standard | |

**DDL Note DB-01:** `tenant_id` column exists in a database-per-tenant architecture — redundant. Migration to remove should be evaluated in V3 DDL cleanup.

### 5.3 Table: `ntf_provider_master`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | Redundant — see DB-02 |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| provider_name | VARCHAR(50) | Twilio, MSG91, AWS SES, Firebase FCM |
| provider_type | ENUM | PRIMARY / SECONDARY / BACKUP |
| api_key_encrypted | TEXT NULL | Must use Laravel encrypted cast |
| api_secret_encrypted | TEXT NULL | Must use Laravel encrypted cast |
| from_address | VARCHAR(255) NULL | Sender email / phone number |
| configuration | JSON NULL | Provider-specific settings |
| is_active | TINYINT(1) | DEFAULT 1 |
| created_at / updated_at / deleted_at | TIMESTAMP | |

### 5.4 Table: `ntf_notifications`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | Redundant — see DB-03 |
| notification_uuid | CHAR(36) | Public-facing UUID; route key |
| source_module | VARCHAR(50) | Originating module code (e.g., FIN, EXM) |
| source_record_id | INT UNSIGNED NULL | FK to source record in originating module |
| notification_event | VARCHAR(50) | Event code; matches ntf_templates.template_code |
| notification_type | ENUM | TRANSACTIONAL/PROMOTIONAL/ALERT/REMINDER/DIGEST |
| title | VARCHAR(255) | Human-readable title |
| template_id | INT UNSIGNED | FK → ntf_templates |
| priority_id | INT UNSIGNED | FK → sys_dropdown_table |
| confidentiality_level_id | INT UNSIGNED | FK → sys_dropdown_table |
| schedule_type | ENUM | IMMEDIATE/SCHEDULED/RECURRING/TRIGGERED |
| scheduled_at | DATETIME NULL | Dispatch datetime for SCHEDULED type |
| recurring_pattern | ENUM | NONE/HOURLY/DAILY/WEEKLY/MONTHLY/YEARLY/CUSTOM |
| recurring_expression | VARCHAR(100) NULL | Cron or RRULE |
| expires_at | DATETIME NULL | Cancel if not dispatched by this time |
| total_recipients | INT | Calculated — count of ntf_resolved_recipients |
| sent_count / failed_count / delivered_count / read_count / click_count | INT | Running counters |
| notification_status_id | INT UNSIGNED | FK → sys_dropdown_table |
| is_manual | TINYINT(1) | 0=event-driven, 1=manual |
| approved_by / approved_at | INT/DATETIME | Approval for bulk PROMOTIONAL |
| created_at / updated_at / deleted_at | TIMESTAMP | |

### 5.5 Table: `ntf_notification_channels` (junction)

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| notification_id | INT UNSIGNED | FK → ntf_notifications |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| provider_id | INT UNSIGNED | FK → ntf_provider_master |
| template_id | INT UNSIGNED | Per-channel template override |
| status_id | INT UNSIGNED | FK → sys_dropdown_table |
| retry_count | INT | Current retry count |
| next_retry_at | DATETIME NULL | Computed retry schedule |
| created_at / updated_at | TIMESTAMP | |

### 5.6 Table: `ntf_templates`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | Redundant per DB-per-tenant |
| template_code | VARCHAR(50) | Matches notification_event |
| template_name | VARCHAR(100) | Display name |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| template_version | INT | DEFAULT 1; part of unique key |
| subject | VARCHAR(255) NULL | Email subject line |
| body | TEXT NOT NULL | Template body with {{placeholders}} |
| alt_body | TEXT NULL | Plain text fallback |
| placeholders | JSON NULL | Required placeholder names list |
| language_code | VARCHAR(10) | DEFAULT 'en' |
| media_id | INT UNSIGNED NULL | FK → sys_media (attachments) |
| is_system_template | TINYINT(1) | DEFAULT 0; Prime-only management |
| approval_status | ENUM | DRAFT/PENDING/APPROVED/REJECTED/ARCHIVED |
| approved_by / approved_at | INT / DATETIME | Approval metadata |
| effective_from / effective_to | DATETIME NULL | Date-range validity |
| dlt_template_id | VARCHAR(50) NULL | 📐 New V2: TRAI DLT registered ID |
| is_active / created_by / created_at / updated_at / deleted_at | Standard | |
| UNIQUE | (tenant_id, template_code, template_version) | |

### 5.7 Table: `ntf_resolved_recipients`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| notification_id | INT UNSIGNED | FK → ntf_notifications |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| template_id | INT UNSIGNED | FK → ntf_templates |
| notification_target_id | INT UNSIGNED | FK → ntf_notification_targets |
| user_preference_id | INT UNSIGNED NULL | FK → ntf_user_preferences |
| resolved_user_id | INT UNSIGNED | FK → sys_user |
| device_id | INT UNSIGNED NULL | FK → ntf_user_devices (push) |
| recipient_address | VARCHAR(255) NULL | Resolved email / phone; NULL for IN_APP |
| personalized_subject | VARCHAR(500) NULL | Rendered subject |
| personalized_body | TEXT NULL | Rendered body |
| personalization_data | JSON NULL | Placeholder key-value map used |
| priority | TINYINT | DEFAULT 5 |
| batch_id | VARCHAR(36) NULL | UUID for bulk batch grouping |
| batch_sequence | INT NULL | Order within batch |
| is_processed | TINYINT(1) | DEFAULT 0 |
| processed_at | DATETIME NULL | |
| is_active / created_at / updated_at / deleted_at | Standard | |

**DDL Note DB-05:** FK references `sys_user` (singular) but project convention is `sys_users` (plural). Needs DDL migration fix.

### 5.8 Table: `ntf_delivery_queue`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| resolved_recipient_id | INT UNSIGNED | FK → ntf_resolved_recipients |
| notification_id | INT UNSIGNED | FK → ntf_notifications |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| provider_id | INT UNSIGNED | FK → ntf_provider_master |
| queue_status | ENUM | PENDING/PROCESSING/SENT/FAILED/RETRY/CANCELLED |
| priority | TINYINT | DEFAULT 5 |
| scheduled_at | DATETIME NULL | Defer until this time |
| locked_by | VARCHAR(50) NULL | Worker ID for locking |
| locked_at | DATETIME NULL | Lock timestamp |
| attempt_count | INT | DEFAULT 0 |
| max_attempts | INT | DEFAULT 3 |
| last_error | VARCHAR(512) NULL | Last failure reason |
| next_attempt_at | DATETIME NULL | Computed next retry time |
| created_at / updated_at | TIMESTAMP | No soft delete (operational table) |

**DDL Note DB-06:** Missing `is_active`, `deleted_at` — by design (append-only operational table).

### 5.9 Table: `ntf_delivery_logs`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| notification_id | INT UNSIGNED | FK → ntf_notifications |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| resolved_recipient_id | INT UNSIGNED | FK → ntf_resolved_recipients |
| resolved_user_id | INT UNSIGNED | FK → sys_user |
| provider_id | INT UNSIGNED | FK → ntf_provider_master |
| delivery_status_id | INT UNSIGNED | FK → sys_dropdown_table |
| delivery_stage | ENUM | QUEUED/SENT/DELIVERED/READ/CLICKED/BOUNCED/COMPLAINT/UNSUBSCRIBED |
| provider_message_id | VARCHAR(255) NULL | Provider-assigned message ID |
| delivered_at / read_at / clicked_at / bounced_at / complaint_at | DATETIME NULL | Stage timestamps |
| response_code | VARCHAR(20) NULL | HTTP/API response code |
| response_payload | JSON NULL | Full provider response |
| error_message | VARCHAR(512) NULL | Error detail on failure |
| duration_ms | INT NULL | Delivery latency in ms |
| ip_address | VARCHAR(45) NULL | Client IP for read/click tracking |
| user_agent | VARCHAR(255) NULL | Browser/app for read/click |
| cost | DECIMAL(12,4) | DEFAULT 0.0000 |
| created_at / updated_at | TIMESTAMP | Append-only |

### 5.10 Table: `ntf_user_preferences`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| user_id | INT UNSIGNED | FK → sys_user |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| is_enabled | TINYINT(1) | Channel on/off |
| is_opted_in | TINYINT(1) | GDPR consent flag |
| opted_in_at / opted_out_at | DATETIME NULL | Consent timestamps |
| quiet_hours_start / quiet_hours_end | TIME NULL | Delivery deferral window |
| quiet_hours_timezone | VARCHAR(50) NULL | IANA timezone string |
| daily_digest | TINYINT(1) | Batch to daily summary |
| digest_time | TIME NULL | Digest delivery time |
| priority_threshold_id | INT UNSIGNED NULL | FK → sys_dropdown_table |
| created_at / updated_at | TIMESTAMP | |

### 5.11 Table: `ntf_user_devices`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| user_id | INT UNSIGNED | FK → sys_user (note: convention requires sys_users) |
| device_type | ENUM | ANDROID / IOS / WEB / DESKTOP |
| device_token | VARCHAR(512) | FCM or APNS token |
| last_active_at | DATETIME NULL | Last successful dispatch to this device |
| UNIQUE KEY | (user_id, device_token) | No duplicate tokens |

**DDL Note DB-04:** Missing `deleted_at` column — cannot soft-delete stale device records. Migration required.

### 5.12 Proposed DDL Changes (V2)

| Change | Type | Rationale |
|--------|------|-----------|
| Add `dlt_template_id VARCHAR(50) NULL` to `ntf_templates` | ALTER | India DLT compliance |
| Add `deleted_at TIMESTAMP NULL` to `ntf_user_devices` | ALTER | Soft delete consistency |
| Fix FK references `sys_user` → `sys_users` | ALTER | Convention alignment |
| Add `created_by` to `ntf_channel_master`, `ntf_notification_channels`, `ntf_provider_master` | ALTER | Audit trail completeness |
| Consider removing `tenant_id` from all ntf_ tables in DB-per-tenant context | ALTER V3 | Architecture cleanup |

---

## 6. API Endpoints & Routes

### 6.1 Current Route State

**CRITICAL NOTE:** Template routes are fully commented out in `tenant.php` lines 2503–2506. The `EnsureTenantHasModule` middleware is missing from the notification route group (RT-01). All other resource routes are registered but the Gate prefix bug (BUG-NTF-003) makes all authorization checks fail.

Additionally, `routes/web.php` in the Notification module itself contains only:
```php
Route::middleware(['auth', 'verified'])->group(function () {
    //Route::resource('notifications', NotificationController::class)->names('notification');
});
```
This file is unused — actual routing is in the main app's `tenant.php`.

### 6.2 Required Route Fixes

```php
// In routes/tenant.php — add middleware + uncomment templates
Route::middleware(['auth', 'verified', 'tenant', EnsureTenantHasModule::class . ':NTF'])
    ->prefix('notifications')
    ->name('notification.')
    ->group(function () {

    // Tab index
    Route::get('/', [NotificationManageController::class, 'index'])->name('tab-index');

    // Notifications CRUD
    Route::resource('notifications', NotificationManageController::class);
    Route::post('notifications/{notification}/process',   [NotificationManageController::class, 'process'])->name('notifications.process');
    Route::post('notifications/{notification}/approve',   [NotificationManageController::class, 'approve'])->name('notifications.approve');
    Route::patch('notifications/{notification}/status',   [NotificationManageController::class, 'updateStatus'])->name('notifications.update-status');
    Route::get('notifications/trashed',                   [NotificationManageController::class, 'trash'])->name('notifications.trash');
    Route::post('notifications/{id}/restore',             [NotificationManageController::class, 'restore'])->name('notifications.restore');
    Route::delete('notifications/{id}/force-delete',      [NotificationManageController::class, 'forceDelete'])->name('notifications.force-delete');

    // Templates — UNCOMMENT (currently blocked by BUG-NTF-001)
    Route::resource('templates', TemplateController::class);
    Route::post('templates/{template}/approve',           [TemplateController::class, 'approve'])->name('templates.approve');
    Route::post('templates/{template}/archive',           [TemplateController::class, 'archive'])->name('templates.archive');
    Route::get('templates/trashed',                       [TemplateController::class, 'trash'])->name('templates.trash');
    Route::post('templates/{id}/restore',                 [TemplateController::class, 'restore'])->name('templates.restore');
    Route::delete('templates/{id}/force-delete',          [TemplateController::class, 'forceDelete'])->name('templates.force-delete');

    // Channels
    Route::resource('notification-channels', ChannelMasterController::class);
    Route::patch('notification-channels/{channel}/toggle-status', [ChannelMasterController::class, 'toggleStatus'])->name('notification-channels.toggle-status');

    // Providers
    Route::resource('provider-master', ProviderMasterController::class);
    Route::post('provider-master/{provider}/test',        [ProviderMasterController::class, 'testConnection'])->name('provider-master.test');
    Route::patch('provider-master/{provider}/toggle-status', [ProviderMasterController::class, 'toggleStatus'])->name('provider-master.toggle-status');

    // Target Groups
    Route::resource('target-group', TargetGroupController::class);
    Route::post('target-group/{group}/resolve',           [TargetGroupController::class, 'resolve'])->name('target-group.resolve');

    // Notification Targets
    Route::resource('notification-targets', NotificationTargetController::class);
    Route::post('notification-targets/{target}/resolve',  [NotificationTargetController::class, 'resolve'])->name('notification-targets.resolve');

    // User Preferences
    Route::resource('user-preferences', UserPreferenceController::class);

    // Resolved Recipients
    Route::resource('resolved-recipients', ResolvedRecipientController::class);
    Route::post('resolved-recipients/process-batch',      [ResolvedRecipientController::class, 'processBatch'])->name('resolved-recipients.process-batch');

    // Delivery Queue
    Route::resource('delivery-queue', DeliveryQueueController::class);
    Route::post('delivery-queue/{item}/retry',            [DeliveryQueueController::class, 'retry'])->name('delivery-queue.retry');
    Route::post('delivery-queue/{item}/cancel',           [DeliveryQueueController::class, 'cancel'])->name('delivery-queue.cancel');
    Route::post('delivery-queue/process',                 [DeliveryQueueController::class, 'process'])->name('delivery-queue.process');

    // Delivery Logs
    Route::resource('delivery-log', DeliveryLogController::class)->only(['index', 'show']);

    // Threads
    Route::resource('notification-threads', NotificationThreadController::class);
    Route::post('notification-threads/{thread}/recalculate', [NotificationThreadController::class, 'recalculate'])->name('notification-threads.recalculate');
    Route::resource('notification-thread-members', NotificationThreadMemberController::class);
});
```

### 6.3 API Endpoints (Sanctum-protected)

```
// Device Registration
POST   /api/v1/notifications/devices           → UserDeviceController@store
DELETE /api/v1/notifications/devices/{id}      → UserDeviceController@destroy

// Notification Inbox (In-App)
GET    /api/v1/notifications/inbox             → NotificationInboxController@index
POST   /api/v1/notifications/{uuid}/read       → NotificationInboxController@markRead
POST   /api/v1/notifications/read-all          → NotificationInboxController@markAllRead
GET    /api/v1/notifications/unread-count      → NotificationInboxController@unreadCount

// Delivery Webhook (provider callbacks)
POST   /api/v1/notifications/webhook/{provider} → WebhookController@handle
```

### 6.4 Gate Authorization Fix

**All controllers** currently use `prime.notification.*` permission strings. The fix is to globally replace with `tenant.notification.*`. Example from `NotificationManageController`:

```php
// BROKEN (current):
$this->authorize('prime.notification.view');

// FIXED (required):
$this->authorize('tenant.notification.view');
```

This affects all 12 controllers. A global find-and-replace across `Modules/Notification/app/Http/Controllers/` is required.

---

## 7. UI Screen Inventory

| Screen | Route | Status | Notes |
|--------|-------|--------|-------|
| Notification Tab Index | `notification.tab-index` | ✅ View exists | Tab layout for all sub-modules |
| Notification List | `notification.notifications.index` | 🟡 View exists | Routes present; god-method issue |
| Create Notification | `notification.notifications.create` | 🟡 View exists | No Gate auth on create() |
| Edit Notification | `notification.notifications.edit` | 🟡 View exists | No Gate auth on edit() |
| Templates List | `notification.templates.index` | ❌ Blocked | Routes commented out |
| Template Create | `notification.templates.create` | ❌ Blocked | Routes commented out |
| Template Edit | `notification.templates.edit` | ❌ Blocked | Routes commented out |
| Channel List | `notification.notification-channels.index` | 🟡 View exists | Missing ChannelMasterRequest |
| Provider List | `notification.provider-master.index` | 🟡 View exists | Encryption not enforced |
| Target Groups | `notification.target-group.index` | 🟡 View exists | Dynamic resolution not implemented |
| Notification Targets | `notification.notification-targets.index` | 🟡 View exists | |
| User Preferences | `notification.user-preferences.index` | 🟡 View exists | |
| Resolved Recipients | `notification.resolved-recipients.index` | 🟡 View exists | |
| Delivery Queue Monitor | `notification.delivery-queue.index` | 🟡 View exists | No worker; process() commented out |
| Delivery Logs | `notification.delivery-log.index` | 🟡 View exists | Service never writes to it |
| Notification Threads | `notification.notification-threads.index` | 🟡 View exists | |
| Thread Members | `notification.notification-thread-members.index` | 🟡 View exists | |
| Notification Inbox (Bell) | (layout partial) | ❌ Not Started | No dedicated inbox view |
| Schedule Audit | N/A | ❌ Missing | No controller or views |
| Notification Analytics | N/A | ❌ Not Started | Delivery rates, open rates |

**Backup files to remove:**
- `resources/views/notifications/index.blade_18_02_2026.php`
- `app/Services/NotificationService_25_02_2026.php`

---

## 8. Business Rules & Domain Constraints

**BR-NTF-01 — Dispatch Only Approved Notifications**
A notification can only be dispatched if `notification_status_id` maps to APPROVED or SCHEDULED. DRAFT notifications must not be processed by the queue worker.

**BR-NTF-02 — Opt-Out is Absolute**
A user with `ntf_user_preferences.is_opted_in = 0` for a given channel shall never receive notifications on that channel. This takes priority over admin overrides, system notifications, and event-driven triggers. The only exception is OTP/security notifications on systems where opt-out of security comms is not permitted.

**BR-NTF-03 — Quiet Hours Deferral**
If current time (in user's `quiet_hours_timezone`) falls within `quiet_hours_start` to `quiet_hours_end`, notification delivery is deferred — `ntf_resolved_recipients.scheduled_at` is set to end-of-quiet-window rather than immediate.

**BR-NTF-04 — System Template Protection**
System templates (`is_system_template = 1`) may only be created, edited, or deleted by Prime Super Admin. Tenant School Admins can clone system templates to create custom versions.

**BR-NTF-05 — Template Must Be Approved**
`ntf_templates.approval_status` must be `APPROVED` for a template to be used in dispatch. DRAFT, PENDING, REJECTED, and ARCHIVED templates are blocked.

**BR-NTF-06 — Event Code Registry**
Event codes fired via `SystemNotificationTriggered` must match records in `ntf_notifications.notification_event`. Unrecognized event codes are logged as warnings (not errors) and silently ignored.

**BR-NTF-07 — Rate Limit Queuing (Not Dropping)**
Exceeding `rate_limit_per_minute`, `daily_limit`, or `monthly_limit` on a channel must result in delivery queuing for the next available window. Silent dropping of messages is prohibited.

**BR-NTF-08 — Delivery Log Immutability**
Records in `ntf_delivery_logs` are append-only. No API endpoint or UI action may delete or update delivery log records.

**BR-NTF-09 — Bulk Promotional Approval**
Manual notifications of type `PROMOTIONAL` targeting more than 100 recipients require explicit approval (separate from notification creation) before processing begins.

**BR-NTF-10 — DLT Compliance for SMS (India)**
SMS notifications on Indian tenants must use TRAI DLT-registered templates. A template without `dlt_template_id` on the SMS channel must be blocked from delivery with a compliance error message.

**BR-NTF-11 — Provider Credential Encryption**
`ntf_provider_master.api_key_encrypted` and `api_secret_encrypted` must be stored using Laravel's `encrypted` cast. The model must define these as encrypted attributes. Storing plaintext credentials is a security violation.

**BR-NTF-12 — Notification Expiry**
The queue worker must check `ntf_notifications.expires_at` before processing. Notifications with `expires_at < NOW()` must be marked `EXPIRED` and not dispatched.

**BR-NTF-13 — Circular Fallback Prevention**
`ntf_channel_master.fallback_channel_id` chains must not be circular. On channel create/update, the system validates that no circular fallback reference exists (depth check up to 5 levels).

---

## 9. Workflows

### 9.1 Notification Lifecycle FSM

```
[DRAFT]
   |— Admin submits → [PENDING_APPROVAL]  (PROMOTIONAL + >100 recipients)
   |— Auto/immediate → [APPROVED]
                           |
                    [SCHEDULED]  ← schedule_type=SCHEDULED; waiting for scheduled_at
                           |
                    [PROCESSING] ← queue worker picks up; resolving recipients + enqueuing
                           |
                    ┌──────┴──────┐
              [COMPLETED]    [PARTIAL]    ← some channels failed
                                |
                           [FAILED]       ← all channels failed
[CANCELLED] ← admin action at any stage before PROCESSING
[EXPIRED]   ← expires_at reached before PROCESSING; auto-transitioned by scheduler
```

### 9.2 Template Approval Workflow

```
[DRAFT]
   |— Submit for review → [PENDING]
                              |— Approve → [APPROVED]  ← only state that allows dispatch
                              |— Reject (with reason) → [REJECTED] → can be edited → [DRAFT]
[APPROVED]
   |— New version created → old version → [ARCHIVED]
```

### 9.3 Delivery Queue State Machine

```
[PENDING]
   |— Worker picks up, sets locked_by + locked_at → [PROCESSING]
                    |— Success → [SENT]
                    |— Failure + attempt_count < max_attempts → [RETRY]
                    |       |— next_attempt_at reached → [PENDING] (recycle)
                    |— Failure + attempt_count >= max_attempts → [FAILED]
[CANCELLED] ← admin action or notification cancelled
```

### 9.4 Event-Driven Dispatch Pipeline (Full Flow)

```
Step 1: Module fires event
   SystemNotificationTriggered::dispatch('FEE_DUE_REMINDER', ['student_id'=>42, 'amount'=>5000])

Step 2: Queue listener picks up
   ProcessSystemNotification::handle()
     → NotificationService::trigger('FEE_DUE_REMINDER', $context)

Step 3: Lookup notification record
   ntf_notifications WHERE notification_event = 'FEE_DUE_REMINDER'
   → If not found: log warning, return. No error thrown.

Step 4: For each active channel (ntf_notification_channels):
   4a. Fetch APPROVED template:
       ntf_templates WHERE template_code = 'FEE_DUE_REMINDER'
         AND channel_id = $channel->id
         AND approval_status = 'APPROVED'
         AND effective_from <= NOW() AND (effective_to IS NULL OR effective_to >= NOW())
         ORDER BY template_version DESC LIMIT 1

   4b. Render template:
       NotificationTemplate::render($context)
       → Replaces {{student_name}}, {{amount}}, etc.

   4c. Resolve recipients:
       RecipientResolutionService::resolve($notification, $channel)
       → Expand NotificationTargets (CLASS/SECTION/GROUP/INDIVIDUAL)
       → Filter opted-out users
       → Apply quiet hours deferral
       → Write ntf_resolved_recipients rows with batch_id

   4d. Enqueue:
       ProcessNotificationJob::dispatch($batch_id)
       → Creates ntf_delivery_queue rows for each resolved recipient

Step 5: Worker processes ntf_delivery_queue
   → Lock batch → dispatch per channel type:
     EMAIL:    Mail::send() with rendered subject/body + attachments
     IN_APP:   $user->notify(new InAppSystemNotification())
     SMS:      SmsProviderAdapter::send($dlt_template_id, $phone, $params)
     PUSH:     FcmAdapter::send($device_token, $title, $body)
     WHATSAPP: WhatsAppAdapter::send($phone, $template_name, $components)
   → Write ntf_delivery_logs entry (SENT or FAILED)
   → Update ntf_notifications counter columns
   → Update ntf_resolved_recipients.is_processed = 1
```

### 9.5 DLT-Compliant SMS Flow (India)

```
Pre-requisite:
   1. School admin registers SMS templates on TRAI DLT portal (external)
   2. DLT portal returns `template_id` (numeric string, e.g., "1507161985783893622")
   3. Admin enters `dlt_template_id` in NTF template edit form
   4. Platform stores in ntf_templates.dlt_template_id

Dispatch:
   1. Template resolved for SMS channel
   2. Validate: dlt_template_id IS NOT NULL → else block + error log
   3. Construct MSG91/Twilio request:
      { "template_id": "1507161985783893622",
        "sender": "PRMAI1",
        "mobiles": ["91XXXXXXXXXX"],
        "VAR1": "Rahul", "VAR2": "5000" }
   4. Provider returns message_id → stored in ntf_delivery_logs.provider_message_id
```

### 9.6 User Opt-Out Flow

```
User opts out via preferences page (or unsubscribe link in email):
   1. ntf_user_preferences.is_opted_in = 0, opted_out_at = NOW()
   2. Any PENDING items in ntf_delivery_queue for this user+channel → CANCELLED
   3. Future RecipientResolutionService calls skip this user for this channel
   4. Delivery log: stage = UNSUBSCRIBED
   5. Re-opt-in possible only by user action → is_opted_in = 1, opted_in_at = NOW()
```

---

## 10. Non-Functional Requirements

**NFR-NTF-01 — Asynchronous Processing**
All notification dispatch must be asynchronous. `ProcessSystemNotification` implements `ShouldQueue`. A bulk notification to 1,000 recipients must complete within 5 minutes with default queue worker count. Synchronous dispatch is prohibited except for IN_APP in low-priority contexts.

**NFR-NTF-02 — Reliability & Retry**
Queue listener: 3 retries with 10-second backoff. Failed jobs logged to `failed_jobs` table. `ProcessNotificationJob` retry logic: up to `max_attempts` with exponential backoff (`attempt_count × retry_delay_minutes`). Delivery failure for one recipient must not affect other recipients in the same batch.

**NFR-NTF-03 — Credential Security**
Provider API credentials stored in `ntf_provider_master.api_key_encrypted` and `api_secret_encrypted` must use Laravel's `encrypted` cast. Plaintext storage is a P0 security violation. Device tokens (`ntf_user_devices.device_token`) must be treated as sensitive — not exposed in logs or API responses.

**NFR-NTF-04 — GDPR / Privacy Compliance**
User opt-out (`is_opted_in = 0`) must be respected immediately. Opt-out timestamps are retained indefinitely for compliance audit. Marketing/PROMOTIONAL notifications require explicit opt-in. Delivery log IP addresses and user agents must be subject to the platform's data retention policy (configurable via `sys_settings`).

**NFR-NTF-05 — DLT Compliance (India)**
All SMS notifications on Indian tenants must use TRAI-registered DLT template IDs. The system must block non-DLT SMS delivery with a clear compliance error. DLT template IDs must be configurable per template record.

**NFR-NTF-06 — Performance (Delivery SLA)**
- IMMEDIATE priority notifications: delivery attempt within 30 seconds of event firing.
- NORMAL priority: within 2 minutes.
- BULK/DIGEST: within 15 minutes for batches up to 10,000 recipients.
- In-app unread count refresh: within 30 seconds via polling (or real-time via Laravel Echo).

**NFR-NTF-07 — Scalability**
The delivery queue design (batch_id, locked_by/locked_at) supports horizontal scaling with multiple queue workers. Adding workers must not cause duplicate delivery. Lock timeout of 5 minutes prevents stale locks from blocking processing.

**NFR-NTF-08 — Observability**
All delivery attempts (success and failure) must be logged in `ntf_delivery_logs`. Aggregate counters on `ntf_notifications` must reflect real-time delivery state. Admin must be able to view delivery success rates, bounce rates, and cost per channel from the delivery logs view.

**NFR-NTF-09 — Availability**
The notification module (event listener + queue workers) must be isolated from web request failures. If the queue worker is down, notifications are safely queued in `ntf_delivery_queue` and processed when workers recover. No notification data is lost during worker restarts.

**NFR-NTF-10 — Input Sanitization**
Template `body` and `alt_body` fields must be sanitized before rendering to prevent XSS injection via notification content (SEC-05 from gap analysis). Use `htmlspecialchars()` for IN_APP rendering. Allow HTML in email body but strip dangerous tags (`<script>`, `<iframe>`, etc.) via a purifier.

---

## 11. Cross-Module Dependencies

### 11.1 Modules That NTF Depends On (Inbound)

| Dependency | Purpose |
|-----------|---------|
| `sys_dropdown_table` | Priority, status, notification type, target type lookups |
| `sys_users` | Recipient user resolution, device token ownership |
| `sys_media` | Template attachments via `ntf_templates.media_id` |
| `sys_settings` | Data retention policy, quiet hours defaults |
| Laravel Queue | `ShouldQueue` for async processing |
| Laravel Mail (SMTP) | Email delivery transport |
| Firebase FCM (external) | Push notification delivery |
| MSG91 / Twilio (external) | SMS delivery; DLT-registered sender |
| Meta WhatsApp Business API (external) | WhatsApp delivery |

### 11.2 Modules That Fire Events (NTF Consumers)

| Module | Event Codes Fired |
|--------|-------------------|
| FIN — Student Fees | `FEE_DUE_REMINDER`, `PAYMENT_RECEIVED`, `FEE_RECEIPT_GENERATED` |
| EXM — LMS Exam | `EXAM_RESULT_PUBLISHED`, `EXAM_SCHEDULED`, `EXAM_REMINDER` |
| HMW — LMS Homework | `HOMEWORK_ASSIGNED`, `HOMEWORK_DUE_REMINDER`, `HOMEWORK_GRADED` |
| ATT — Attendance | `ATTENDANCE_MARKED_ABSENT`, `ATTENDANCE_DAILY_SUMMARY` |
| ADM — Admission | `STUDENT_ADMITTED`, `ADMISSION_APPLICATION_RECEIVED` |
| LIB — Library | `BOOK_OVERDUE`, `BOOK_RETURN_REMINDER` |
| TPT — Transport | `VEHICLE_ARRIVAL_ALERT`, `ROUTE_CHANGED` |
| COM — Communication | `CIRCULAR_PUBLISHED`, `ANNOUNCEMENT_POSTED` |
| STD — Student Profile | `STUDENT_PROFILE_UPDATED`, `ID_CARD_GENERATED` |
| SYS — System | `PASSWORD_RESET`, `OTP_VERIFICATION`, `LOGIN_ALERT` |

### 11.3 COM Module Relationship

The Communication module (COM) uses NTF as its underlying delivery engine. COM handles the user-facing composition and targeting UI for school communications (circulars, announcements), while NTF handles the actual channel dispatch. COM fires `SystemNotificationTriggered` events that NTF processes.

### 11.4 Integration Patterns

```php
// Standard pattern for any module to trigger a notification:
SystemNotificationTriggered::dispatch(
    'FEE_DUE_REMINDER',
    [
        'student_name' => $student->full_name,
        'amount'       => $fee->due_amount,
        'due_date'     => $fee->due_date->format('d M Y'),
        'school_name'  => $tenant->school_name,
    ]
);
```

Event codes must be registered in `ntf_notifications` before the event fires. If the record does not exist, the notification is silently skipped with a warning log.

---

## 12. Test Scenarios

**Current State:** Zero tests exist. Only `.gitkeep` files in `tests/Feature/` and `tests/Unit/`.

### 12.1 Required Test Suite

| Test Class | Type | Priority | Key Assertions |
|-----------|------|----------|----------------|
| `NotificationTemplateRenderTest` | Unit | P0 | `{{placeholder}}` substitution; non-scalar skip; both `{{key}}` and `{{ key }}` forms |
| `NotificationServiceTriggerTest` | Feature | P0 | IN_APP dispatch works; email dispatch works; unknown event code warns + returns |
| `ProcessSystemNotificationListenerTest` | Feature | P0 | Queued listener: 3 retries; failed() logs; trigger called correctly |
| `NotificationManageControllerTest` | Feature | P0 | store/update use validated(); DRAFT cannot be processed; Gate `tenant.*` prefix works |
| `TemplateControllerTest` | Feature | P1 | CRUD; approve flow; DRAFT blocked from approve if missing fields |
| `ChannelMasterControllerTest` | Feature | P1 | Create/update/toggle-status; fallback channel validation; circular fallback rejected |
| `RecipientResolutionServiceTest` | Unit | P1 | CLASS target expands to all students; opted-out user skipped; quiet hours deferred |
| `DeliveryQueueWorkerTest` | Feature | P1 | PENDING → SENT; PENDING → RETRY on failure; FAILED after max_attempts; lock timeout release |
| `UserPreferenceOptOutTest` | Unit | P1 | opt-out blocks delivery; opt-in restores; quiet hours correctly deferred |
| `DltComplianceTest` | Unit | P1 | SMS without dlt_template_id blocked; DLT ID passed to provider call |
| `DeliveryLogImmutabilityTest` | Feature | P2 | Delete endpoint returns 403/405; log records accumulate |
| `ProviderCredentialEncryptionTest` | Unit | P2 | api_key saved encrypted; retrieved value decrypts correctly; plaintext not visible in DB |
| `BulkApprovalWorkflowTest` | Feature | P2 | PROMOTIONAL >100 recipients requires approval; status stays PENDING until approved |
| `NotificationInboxTest` | Feature | P2 | unread count increments on new in-app; mark-read decrements; mark-all-read zeros count |

### 12.2 Sample Unit Test: Template Render

```php
test('renders {{placeholder}} in subject and body', function () {
    $template = NotificationTemplate::factory()->make([
        'subject' => 'Fee Due for {{student_name}}',
        'body'    => 'Dear {{student_name}}, your fee of {{amount}} is due.',
    ]);

    $rendered = $template->render([
        'student_name' => 'Rahul Kumar',
        'amount'       => '5000',
    ]);

    expect($rendered['subject'])->toBe('Fee Due for Rahul Kumar');
    expect($rendered['body'])->toBe('Dear Rahul Kumar, your fee of 5000 is due.');
});

test('skips non-scalar payload values silently', function () {
    $template = NotificationTemplate::factory()->make([
        'body' => 'Hello {{name}}',
    ]);
    $rendered = $template->render(['name' => ['nested' => 'array']]);
    expect($rendered['body'])->toBe('Hello {{name}}');
});
```

### 12.3 Sample Feature Test: Gate Prefix

```php
test('notification list requires tenant.notification.view permission', function () {
    $user = User::factory()->create();
    actingAs($user)
        ->get(route('notification.notifications.index'))
        ->assertForbidden();

    $user->givePermissionTo('tenant.notification.view');
    actingAs($user)
        ->get(route('notification.notifications.index'))
        ->assertOk();
});
```

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Channel | A delivery medium: EMAIL, SMS, WHATSAPP, IN_APP, PUSH |
| Event Code | Upper-snake-case string linking a module event to notification templates (e.g., `FEE_DUE_REMINDER`) |
| Template | Reusable message body with `{{placeholder}}` variables, versioned and approval-gated |
| Resolved Recipient | A single (user × channel) row in `ntf_resolved_recipients`, ready for delivery |
| Target Group | Named set of users — STATIC (fixed list) or DYNAMIC (query-based) |
| Quiet Hours | Time window during which notification delivery is deferred to protect user sleep/focus time |
| Fallback Channel | Alternative delivery channel used when primary channel fails |
| Digest | Batched summary of multiple notifications sent as a single message at a scheduled time |
| DLT | Distributed Ledger Technology — TRAI's SMS template registration system (India-specific) |
| DLT Template ID | Unique numeric ID assigned by TRAI portal for a registered SMS template |
| Opt-In / Opt-Out | GDPR-aligned user consent to receive notifications on a specific channel |
| Provider | External service used for delivery: MSG91, Twilio, AWS SES, Firebase FCM, Meta WhatsApp |
| FCM | Firebase Cloud Messaging — Google's push notification service for Android, iOS, Web |
| APNS | Apple Push Notification Service — Apple's push notification delivery network |
| Worker Locking | `locked_by` + `locked_at` mechanism preventing duplicate processing of queue items |
| Batch ID | UUID grouping `ntf_resolved_recipients` rows for bulk parallel processing |
| Thread | Group of related notifications; types: CONVERSATION, DIGEST, BROADCAST |

---

## 14. Suggestions & Recommendations

### 14.1 P0 — Must Fix Before Any Production Use

1. **Uncomment template routes in `tenant.php`** (lines 2503–2506). Template management is entirely blocked. Minimum fix: uncomment and verify `TemplateController` methods are complete.

2. **Add `EnsureTenantHasModule` middleware** to the notification route group. Without this, schools without the NTF module license can access notification endpoints (RT-01).

3. **Fix Gate prefix** — global find-and-replace `prime.notification.` → `tenant.notification.` across all controllers in `Modules/Notification/app/Http/Controllers/`. The wrong prefix causes authorization failures for all tenant users (BUG-NTF-003).

4. **Use `$request->validated()`** in `NotificationManageController::store()` (lines 274–310) and `update()` (lines 371–393). FormRequests exist but are bypassed (BUG-NTF-004, CT-01, CT-02).

5. **Uncomment `ProcessNotificationJob::dispatch()`** in `process()` method — line ~555. Without this, no notifications are ever processed from the UI (BUG-NTF-005, CT-06).

6. **Remove backup files:**
   - `Modules/Notification/app/Services/NotificationService_25_02_2026.php`
   - `Modules/Notification/resources/views/notifications/index.blade_18_02_2026.php`

### 14.2 P1 — Fix Before Beta

7. **Uncomment email dispatch** in `NotificationService.php:77`. The `sendEmail()` method exists but the call is commented out. Uncomment and test with a real SMTP provider (BUG-NTF-006).

8. **Create `ProcessNotificationJob`** — a dedicated Laravel Job to process `ntf_delivery_queue` items with worker locking, retry logic, and per-channel dispatch. This is the missing architectural piece (ARCH-01, ARCH-02).

9. **Implement `RecipientResolutionService`** to resolve `ntf_notification_targets` (CLASS/SECTION/TEACHER/GROUP targets) to individual `ntf_resolved_recipients` rows, applying opt-out and quiet-hours filtering.

10. **Add Gate authorization to `create()` and `edit()`** methods in `NotificationManageController` (CT-04, CT-05, SEC-03). Any authenticated user can currently access these views.

11. **Create `ChannelMasterRequest` FormRequest** (FR-02). This is the only missing FormRequest.

12. **Fix `getRouteKeyName()` conflict** — `Notification` model returns `notification_uuid` but controllers call `findOrFail($id)` with integer ID. Either remove `getRouteKeyName()` override or update all controller calls to use UUID (MD-01).

13. **Fix DDL FK convention** — `ntf_user_devices` and `ntf_resolved_recipients` reference `sys_user` but the project convention is `sys_users`. Write a migration to update the FK constraint names (DB-05, DB-10).

### 14.3 P2 — Fix Before GA

14. **Implement SMS dispatch** using `ntf_provider_master` credentials and a provider adapter pattern (`SmsProviderAdapter` interface with MSG91 and Twilio implementations). Include DLT template ID in request payload.

15. **Implement Push (FCM) dispatch** using device tokens from `ntf_user_devices`. Use Firebase Admin SDK or HTTP v1 API. Handle expired/invalid token errors gracefully — mark device inactive.

16. **Implement WhatsApp dispatch** via Meta Cloud API. Store WhatsApp-specific template parameters (template name, language, components) in `ntf_templates.configuration` JSON column.

17. **Refactor `NotificationManageController::index()`** — the god-method loading 8+ separate queries is a performance bottleneck. Convert to tabbed AJAX loading — each sub-resource tab loads its own paginated data via separate lightweight endpoints (CT-03, PERF-01).

18. **Implement delivery logging** — `NotificationService::dispatchToChannel()` must write to `ntf_delivery_logs` for every delivery attempt. Currently, the `NotificationDeliveryLog` model exists but the service never uses it (SV-04).

19. **Enforce provider credential encryption** — add `encrypted` cast to `api_key_encrypted` and `api_secret_encrypted` in `ProviderMaster` model (SEC-01).

20. **Add `dlt_template_id` column** to `ntf_templates` DDL and create a migration (V2 schema change, per FR-NTF-03.6).

21. **Build notification inbox UI** — bell widget in layout header, inbox page, read/unread tracking, mark-all-read, deep-link support (FR-NTF-10).

22. **Add `deleted_at` to `ntf_user_devices`** to enable soft deletion of stale device records (DB-04).

### 14.4 P3 — Enhancements

23. **Implement rate-limit enforcement at queue worker level** using Laravel `RateLimiter`, not just config storage. Per-minute sliding window checks before dispatching each delivery item.

24. **Add notification analytics dashboard** showing: delivery success rate per channel, bounce rate, open rate (in-app read rate), cost per channel per month, top 10 failing templates.

25. **Implement channel adapter pattern** — replace `switch/case` in `NotificationService::dispatchToChannel()` with a `ChannelAdapter` interface and provider-specific implementations (ARCH-06). Enables easy addition of new channels.

26. **Add `ntf_schedule_audit` controller and views** — currently the table exists and is populated by schedule logic, but there is no admin UI to view scheduling history (gap analysis Section 13).

27. **Add event code registry validation** — create a `ntf_event_codes` seeder or a validator that prevents unknown event codes from being silently dropped. Consider adding a `php artisan notifications:validate-events` command.

28. **Implement webhook endpoints** for provider delivery receipts (MSG91 DND callbacks, AWS SES bounce/complaint SNS notifications, FCM token refresh callbacks). Required for accurate delivery tracking.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path | Status |
|------|------|--------|
| Event | `Modules/Notification/app/Events/SystemNotificationTriggered.php` | ✅ Complete |
| Listener | `Modules/Notification/app/Listeners/ProcessSystemNotification.php` | ✅ Present |
| Service | `Modules/Notification/app/Services/NotificationService.php` | 🟡 Email commented out |
| Service Backup | `Modules/Notification/app/Services/NotificationService_25_02_2026.php` | ❌ Delete this |
| Policy | `Modules/Notification/app/Policies/PrimeNotificationPolicy.php` | ❌ Wrong Gate prefix |
| Template Model | `Modules/Notification/app/Models/NotificationTemplate.php` | 🟡 Wrong $table property |
| Notification Model | `Modules/Notification/app/Models/Notification.php` | 🟡 Commented relationships |
| Routes (module) | `Modules/Notification/routes/web.php` | ❌ Single resource commented out |
| Routes (tenant) | `routes/tenant.php` (main app) lines 2474–2619+ | 🟡 Template routes commented out |
| InApp Notification | `Modules/Notification/app/Notifications/InAppSystemNotification.php` | ✅ Complete |
| Facade | `Modules/Notification/app/Facades/Notification.php` | 🟡 Registration unclear |
| DDL | `tenant_db_v2.sql` lines 2286–2749 | ✅ 15 tables defined |
| Views | `Modules/Notification/resources/views/` | 🟡 Backup file to delete |
| Tests | `Modules/Notification/tests/` | ❌ Only .gitkeep files |

### Appendix B: Complete Bug Register

| Bug ID | Severity | Description | File | Fix |
|--------|----------|-------------|------|-----|
| BUG-NTF-001 | CRITICAL | Template routes commented out in tenant.php | `routes/tenant.php:2503-2506` | Uncomment routes |
| BUG-NTF-002 | CRITICAL | `EnsureTenantHasModule` middleware missing from notification group | `routes/tenant.php:2474` | Add middleware |
| BUG-NTF-003 | CRITICAL | Gate prefix `prime.notification.*` → should be `tenant.notification.*` | All 12 controllers | Global find-replace |
| BUG-NTF-004 | CRITICAL | `store()`/`update()` use `$request->field` not `$request->validated()` | `NotificationManageController.php:274,371` | Use validated() |
| BUG-NTF-005 | CRITICAL | `ProcessNotificationJob::dispatch()` commented out in process() | `NotificationManageController.php:555` | Uncomment dispatch |
| BUG-NTF-006 | HIGH | `sendEmail()` call commented out in dispatchToChannel() | `NotificationService.php:77` | Uncomment call |
| BUG-NTF-007 | HIGH | No Gate auth on `create()` and `edit()` | `NotificationManageController.php:228,337` | Add authorize() |
| BUG-NTF-008 | MEDIUM | Model `NotificationTemplate.$table` = `ntf_notification_templates` vs DDL `ntf_templates` | `NotificationTemplate.php:16` | Align to DDL |
| BUG-NTF-009 | MEDIUM | `getRouteKeyName()` returns `notification_uuid` but controllers use `findOrFail($id)` | `Notification.php:93` | Fix usage pattern |
| BUG-NTF-010 | MEDIUM | `resolvedRecipients()` and `logs()` relationships commented out in Notification model | `Notification.php:154-181` | Uncomment |
| BUG-NTF-011 | MEDIUM | Missing `canBeProcessed()` method referenced in controller | `NotificationManageController.php:532` | Add to model |
| BUG-NTF-012 | MEDIUM | Backup file in production: NotificationService_25_02_2026.php | Services directory | Delete file |
| BUG-NTF-013 | MEDIUM | Backup view in production: index.blade_18_02_2026.php | Views directory | Delete file |
| BUG-NTF-014 | LOW | FK references `sys_user` (singular) vs project convention `sys_users` (plural) | DDL lines 2506, 2614 | Migration fix |

### Appendix C: Event Code Conventions

Event codes follow the format: `MODULE_VERB_SUBJECT` in UPPER_SNAKE_CASE.

| Module | Example Event Codes |
|--------|---------------------|
| FIN | `FEE_DUE_REMINDER`, `PAYMENT_RECEIVED`, `FEE_OVERDUE_ALERT` |
| EXM | `EXAM_RESULT_PUBLISHED`, `EXAM_SCHEDULED`, `EXAM_REMINDER_24H` |
| ATT | `ATTENDANCE_MARKED_ABSENT`, `ATTENDANCE_HALF_DAY_MARKED` |
| HMW | `HOMEWORK_ASSIGNED`, `HOMEWORK_DUE_REMINDER`, `HOMEWORK_GRADED` |
| ADM | `STUDENT_ADMITTED`, `ADMISSION_ENQUIRY_RECEIVED` |
| LIB | `BOOK_OVERDUE`, `BOOK_RETURN_REMINDER` |
| TPT | `VEHICLE_ARRIVAL_ALERT`, `ROUTE_CHANGE_NOTIFICATION` |
| COM | `CIRCULAR_PUBLISHED`, `EVENT_REMINDER` |
| SYS | `OTP_VERIFICATION`, `PASSWORD_RESET`, `LOGIN_SUSPICIOUS` |

### Appendix D: DLT Registration Workflow (India)

1. School registers on Jio/Vodafone/Airtel DLT portal as "Principal Entity".
2. Add sender ID (e.g., `PRMAI1`) — 6-character alphanumeric.
3. Create SMS template on portal, matching exactly the template body in NTF (with variables as `{#var#}` format in DLT but `{{var}}` in NTF internal format).
4. DLT portal assigns a numeric `template_id` (e.g., `1507161985783893622`).
5. Admin enters this ID in NTF template edit form → stored in `ntf_templates.dlt_template_id`.
6. At dispatch time, NTF sends the `dlt_template_id` + `sender_id` to MSG91/Twilio as required.

**Note:** DLT compliance is mandatory for all transactional and promotional SMS in India under TRAI regulations effective 2021. Non-compliant SMS are blocked by telecom operators.

### Appendix E: Provider Integration Matrix

| Provider | Channel | Integration Method | Auth Type | DLT Support |
|---------|---------|-------------------|-----------|-------------|
| MSG91 | SMS | REST API v5 | `authkey` header | Yes (template_id param) |
| Twilio | SMS | REST API | AccountSid + Token | Limited (US focus) |
| AWS SES | EMAIL | SES SDK / SMTP | IAM key / SMTP credentials | N/A |
| SMTP (generic) | EMAIL | Laravel Mail | Username/password | N/A |
| Firebase FCM | PUSH | HTTP v1 API | OAuth2 service account | N/A |
| Meta WhatsApp | WHATSAPP | Cloud API | Permanent token | Template pre-approval via Meta |

---

## 16. V1 → V2 Delta

### 16.1 New Requirements in V2

| ID | Section | Description |
|----|---------|-------------|
| FR-NTF-03.6 | Templates | DLT template ID field (India SMS compliance) |
| FR-NTF-04.3 | Notifications | Bulk PROMOTIONAL approval workflow (>100 recipients) |
| FR-NTF-05.6 | Dispatch | ProcessNotificationJob specification (dedicated delivery worker) |
| FR-NTF-06.3 | Targeting | RecipientResolutionService specification |
| FR-NTF-07.4 | Devices | UserDeviceController (API endpoint for token registration) |
| FR-NTF-10 | Inbox | Full notification inbox / bell widget specification |
| FR-NTF-12 | Scheduling | Scheduled + recurring notification command specification |
| BR-NTF-09 | Business Rules | Bulk promotional approval rule |
| BR-NTF-10 | Business Rules | DLT compliance rule |
| BR-NTF-11 | Business Rules | Credential encryption rule (was in NFR in V1; promoted to BR) |
| BR-NTF-13 | Business Rules | Circular fallback prevention rule |

### 16.2 V1 Issues Carried Forward (Unresolved)

All 4 bugs from V1 Appendix B (BUG-NTF-001 through 004) remain unresolved. V2 expands the bug register to 14 items based on the deep gap analysis.

### 16.3 Schema Changes (V1 → V2)

| Change | Table | Column | Type |
|--------|-------|--------|------|
| Add DLT template ID | `ntf_templates` | `dlt_template_id` | VARCHAR(50) NULL |
| Add soft delete | `ntf_user_devices` | `deleted_at` | TIMESTAMP NULL |
| Fix FK names | `ntf_user_devices`, `ntf_resolved_recipients` | FKs to sys_users | Migration |
| Add created_by | `ntf_channel_master`, `ntf_provider_master`, `ntf_notification_channels` | `created_by` | INT UNSIGNED NOT NULL |

### 16.4 Completion Trajectory

| Metric | V1 (2026-03-25) | V2 Target | Notes |
|--------|-----------------|-----------|-------|
| Overall completion | ~50% | 85% | After P0+P1 fixes |
| Bug count | 4 known | 14 identified | Full audit in V2 |
| Test coverage | 0% | 70% | Minimum 14 test classes |
| Channels working | 1/5 (IN_APP) | 3/5 (+ EMAIL, SMS) | WhatsApp/Push in V3 |
| Routes accessible | ~80% (templates blocked) | 100% | After BUG-NTF-001 fix |
| DLT compliance | 0% | 100% | New V2 requirement |

