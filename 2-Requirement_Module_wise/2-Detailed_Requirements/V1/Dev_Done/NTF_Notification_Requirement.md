# Notification Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** NTF | **Module Type:** Tenant Module
**Table Prefix:** `ntf_*` | **Processing Mode:** FULL
**RBS Reference:** Module Q — Communication & Messaging (partial — notification subsystem)

---

## 1. Executive Summary

The Notification module (NTF) is the central communication backbone for the Prime-AI platform, providing multi-channel notification delivery to all tenant stakeholders — school administrators, teachers, students, and parents. It implements an event-driven architecture where any tenant module can fire a `SystemNotificationTriggered` event that is asynchronously dispatched through a queued listener (`ProcessSystemNotification`) to one or more configured channels (Email, In-App, and future SMS/Push/WhatsApp).

**Implementation Statistics:**
- Controllers: 12 (ChannelMasterController, DeliveryQueueController, NotificationManageController, NotificationTargetController, NotificationTemplateController, NotificationThreadController, NotificationThreadMemberController, ProviderMasterController, ResolvedRecipientController, TargetGroupController, TemplateController, UserPreferenceController)
- Models: 14 (ChannelMaster, DeliveryQueue, Notification, NotificationChannel, NotificationDeliveryLog, NotificationTarget, NotificationTemplate, NotificationThread, NotificationThreadMember, ProviderMaster, ResolvedRecipient, TargetGroup, UserDevice, UserPreference)
- Services: 2 (NotificationService, NotificationService_25_02_2026 — legacy backup)
- FormRequests: 10
- Tests: 0 (none exist)
- Completion: ~50%

**Critical Issues Identified:**
1. **ROUTES COMMENTED OUT (BUG-NTF-001):** All routes in `Modules/Notification/routes/web.php` are commented out — the entire module is inaccessible via HTTP. The single resource route `Route::resource('notifications', NotificationController::class)` is wrapped in a comment.
2. **WRONG GATE PREFIX (BUG-NTF-002):** The policy (`PrimeNotificationPolicy`) uses `prime.notification.*` permission strings instead of the expected `tenant.notification.*` pattern for a tenant module.
3. **EMAIL DISPATCH COMMENTED OUT (BUG-NTF-003):** In `NotificationService::dispatchToChannel()`, the `case 'EMAIL'` branch calls `$this->sendEmail(...)` which is commented out — email delivery is silently skipped.
4. **NO TESTS:** Zero test coverage across all controllers, services, and models.
5. **MODEL TABLE MISMATCH:** `NotificationTemplate` maps to `ntf_notification_templates` but the DDL defines `ntf_templates` — potential migration inconsistency.

---

## 2. Module Overview

### 2.1 Business Purpose

The Notification module serves as the unified messaging layer for the Prime-AI school ERP. Schools require timely, reliable communication across multiple channels to inform parents about fee dues, exam results, attendance alerts, and emergency notices. The module must support:
- Automated event-driven notifications (triggered by other modules)
- Manual ad-hoc notifications (composed by admins/teachers)
- Multi-channel delivery with fallback logic
- Recipient targeting by role, class, section, or individual
- Per-user preference and opt-in/opt-out management
- Delivery tracking and analytics

### 2.2 Feature Summary

| Feature | Status |
|---------|--------|
| Channel Master Configuration | Schema defined, controller exists, routes missing |
| Provider Master (SMS/Email gateway config) | Schema defined, controller exists, routes missing |
| Notification Templates (with placeholder rendering) | Partially implemented |
| Notification Creation (manual) | Controller exists, routes missing |
| Target Groups (static and dynamic) | Schema defined, controller exists |
| Event-Driven Dispatch (SystemNotificationTriggered) | Working — listener queued with 3 retries |
| Email Delivery | Code exists but `sendEmail()` call is commented out |
| In-App Delivery | Working via Laravel Notification system |
| SMS / Push / WhatsApp Delivery | Stubbed — switch default case only |
| User Device Registry (FCM tokens) | Schema defined, model exists |
| User Notification Preferences | Schema defined, model exists, routes missing |
| Delivery Queue Management | Schema defined, model/controller exist |
| Thread/Chat Messaging | Models exist (NotificationThread, NotificationThreadMember) |
| Delivery Logs | Model exists (NotificationDeliveryLog) |

### 2.3 Menu Path

`Tenant Dashboard > Communication > Notifications`
- Manage Notifications
- Notification Templates
- Channel Settings
- Target Groups
- User Preferences
- Delivery Logs

### 2.4 Architecture

```
[Any Module]
    → SystemNotificationTriggered::dispatch($eventCode, $context)
    → EventServiceProvider::listen()
    → ProcessSystemNotification (ShouldQueue, 3 retries, 120s timeout)
    → NotificationService::trigger($eventCode, $payload)
        → Notification::where('notification_event', $eventCode)->first()
        → foreach $notification->channels as $channel
            → NotificationTemplate::where('template_code', $eventCode)->where('channel_id', ...)->first()
            → $template->render($payload)   // replaces {{key}} placeholders
            → dispatchToChannel($channelCode, $content, ...)
                → case 'EMAIL': sendEmail() [COMMENTED OUT]
                → case 'IN_APP': $user->notify(new InAppSystemNotification($content))
                → default: (SMS/Push stubbed)
```

---

## 3. Stakeholders & Actors

| Actor | Role | Access Level |
|-------|------|-------------|
| Super Admin (Prime) | Platform-wide notification config | Full access to channel/provider master |
| School Admin | Create notifications, manage templates | Create, send, view all notifications |
| Teacher | Send targeted notifications to students/parents | Create and send to own classes |
| Student | Receive in-app notifications | Read-only |
| Parent | Receive notifications (email/SMS/push) | Read-only |
| System (automated) | Event-triggered notifications | Fire-and-forget via event dispatch |

---

## 4. Functional Requirements

### FR-NTF-01: Channel Master Management

**RBS Ref:** F.Q1.2, F.Q2.2, F.Q3.2

**REQ-NTF-01.1 — Channel Configuration**
- The system shall maintain a master list of notification channels: EMAIL, SMS, WHATSAPP, IN_APP, PUSH.
- Each channel shall have: `code` (unique per tenant), `name`, `channel_type` (IMMEDIATE/BULK/TRANSACTIONAL), `max_retry`, `retry_delay_minutes`, `rate_limit_per_minute`, `daily_limit`, `monthly_limit`, `cost_per_unit`, `fallback_channel_id`.
- Admin shall be able to activate/deactivate channels.
- The system shall enforce rate limits per channel to prevent abuse.

**Acceptance Criteria:**
- Given an admin navigates to Channel Settings, they can create an EMAIL channel with SMTP configuration.
- Given a channel is inactive, the NotificationService skips it without error.
- Given a channel fails delivery, the system routes to `fallback_channel_id` if configured.

**Current Implementation:**
- `ntf_channel_master` table defined in DDL.
- `ChannelMasterController` exists with CRUD operations.
- Routes are commented out — channel management is inaccessible via UI.

**Test Cases:**
- TC-NTF-01.1: Create EMAIL channel with valid data → persisted, returned in list.
- TC-NTF-01.2: Deactivate channel → NotificationService skips it.
- TC-NTF-01.3: Channel rate limit exceeded → notification queued for next window.

---

### FR-NTF-02: Provider Master (Gateway Configuration)

**RBS Ref:** F.Q2.2, F.Q3.1

**REQ-NTF-02.1 — External Provider Setup**
- Admin shall configure external SMS/email/push providers (Twilio, MSG91, AWS SES, Firebase FCM).
- Provider credentials (`api_key_encrypted`, `api_secret_encrypted`) shall be stored encrypted.
- Multiple providers per channel are allowed with PRIMARY/SECONDARY/BACKUP designation.
- Admin shall be able to test provider connectivity before saving.

**Current Implementation:**
- `ntf_provider_master` table with encrypted credential fields in DDL.
- `ProviderMasterController` exists.
- Routes missing — provider configuration inaccessible.

---

### FR-NTF-03: Notification Template System

**RBS Ref:** F.Q1.2

**REQ-NTF-03.1 — Template Management**
- Templates shall be linked to a specific `channel_id` and identified by `template_code`.
- Templates support versioning (`template_version` INT field) with `approval_status` workflow (DRAFT → PENDING → APPROVED → ARCHIVED).
- Template body supports placeholder syntax `{{placeholder_name}}` and `{{ placeholder_name }}` (both forms handled by `render()` method).
- Templates have `effective_from`/`effective_to` date range for time-bounded validity.
- System templates (`is_system_template = 1`) cannot be deleted by tenant admins.
- Multi-language support via `language_code` field.

**REQ-NTF-03.2 — Template Rendering**
- The `NotificationTemplate::render(array $payload): array` method shall interpolate scalar payload values into `{{key}}` placeholders in both subject and body.
- Non-scalar values (arrays/objects) in payload shall be silently skipped.

**Acceptance Criteria:**
- Given template body = "Dear {{student_name}}, your fee of {{amount}} is due." and payload = ['student_name' => 'Rahul', 'amount' => '5000'], rendered body = "Dear Rahul, your fee of 5000 is due."
- Given a template is in DRAFT status, it shall not be sent to recipients.
- Given template version 2 is APPROVED and version 1 is ARCHIVED, version 2 shall be used for dispatch.

**Current Implementation:**
- `NotificationTemplate` model with `render()` method implemented.
- `ntf_templates` DDL table defined. Model maps to `ntf_notification_templates` — mismatch that needs resolution.
- `TemplateController` and `NotificationTemplateController` both exist (possible duplication).

---

### FR-NTF-04: Event-Driven Notification Dispatch

**RBS Ref:** F.Q1.1, F.Q5.1, F.Q6.1

**REQ-NTF-04.1 — Event Firing**
- Any module shall fire a notification by dispatching: `SystemNotificationTriggered::dispatch(string $eventCode, array $context)`.
- The event carries `eventCode` (matches `ntf_notifications.notification_event`) and `context` (payload for template rendering).

**REQ-NTF-04.2 — Queued Listener**
- `ProcessSystemNotification` implements `ShouldQueue` with `$tries = 3`, `$backoff = 10` seconds, `$timeout = 120` seconds.
- Failed jobs after 3 attempts shall log error to `Log::error()` via the `failed()` method.
- On handle, it calls `NotificationService::trigger($eventCode, $context)`.

**REQ-NTF-04.3 — Channel Dispatch**
- NotificationService shall loop all active channels for a given notification event.
- Per-channel template shall be fetched by matching `template_code` + `channel_id`.
- EMAIL: dispatch via `Mail::send()` with HTML body and optional attachments.
- IN_APP: dispatch via Laravel's `$user->notify(new InAppSystemNotification($content))`.
- SMS/PUSH/WHATSAPP: stubbed — no-op in current implementation.

**Acceptance Criteria:**
- Given event EXAM_RESULT_PUBLISHED fires, EMAIL and IN_APP channels both receive the notification.
- Given Email dispatch throws an exception, delivery log records status = 'FAILED' and exception is re-thrown.
- Given In-App dispatch succeeds, delivery log records status = 'SENT' with `delivered_at` timestamp.

**Current Implementation:**
- Event: `SystemNotificationTriggered` — complete.
- Listener: `ProcessSystemNotification` — complete with retry/timeout logic.
- `NotificationService` — IN_APP working; EMAIL code exists but call is commented out at line 77 (`//$this->sendEmail(...)`) — this is **BUG-NTF-003**.

---

### FR-NTF-05: Recipient Targeting

**RBS Ref:** F.Q5.2, F.Q6.1

**REQ-NTF-05.1 — Target Group Management**
- Admin shall create named target groups (STATIC or DYNAMIC).
- Static groups have fixed member lists.
- Dynamic groups store a JSON-based query to resolve recipients at dispatch time.
- System groups (`is_system_group = 1`) are pre-defined (e.g., "All Parents", "All Teachers").

**REQ-NTF-05.2 — Notification Target Assignment**
- Each notification can have multiple target entries via `ntf_notification_targets`.
- Target types (from `sys_dropdown_table`): STUDENT, PARENT, TEACHER, CLASS, SECTION, GROUP, INDIVIDUAL.
- The system shall resolve targets to individual users and store in `ntf_resolved_recipients`.

**Current Implementation:**
- `TargetGroup` model and `TargetGroupController` exist.
- `NotificationTarget` model and `NotificationTargetController` exist.
- `ResolvedRecipient` model and controller exist.
- Routes missing for all.

---

### FR-NTF-06: User Preferences & Device Management

**RBS Ref:** F.Q3.2

**REQ-NTF-06.1 — User Notification Preferences**
- Each user can enable/disable notification per channel.
- GDPR opt-in/opt-out with timestamp tracking (`opted_in_at`, `opted_out_at`).
- Quiet hours support (`quiet_hours_start`, `quiet_hours_end`, `quiet_hours_timezone`).
- Daily digest mode with configurable digest time.
- Priority threshold — user only receives notifications above a minimum priority level.

**REQ-NTF-06.2 — Device Registration**
- Mobile devices register FCM tokens via `ntf_user_devices`.
- Supports ANDROID, IOS, WEB, DESKTOP device types.
- Unique constraint on `(user_id, device_token)` prevents duplicate registrations.

**Current Implementation:**
- `UserPreference` model and `UserPreferenceController` exist.
- `UserDevice` model exists (no dedicated controller found).
- Routes missing.

---

### FR-NTF-07: Delivery Queue & Logging

**RBS Ref:** F.Q7.1

**REQ-NTF-07.1 — Delivery Queue**
- `ntf_delivery_queue` stores individual delivery tasks (one per resolved recipient per channel).
- Queue statuses: PENDING, PROCESSING, SENT, FAILED, RETRY, CANCELLED.
- Worker locking via `locked_by` / `locked_at` prevents duplicate processing.
- Retry with `max_attempts` limit.

**REQ-NTF-07.2 — Delivery Logging**
- Every delivery attempt (success or failure) shall be recorded in `NotificationDeliveryLog`.
- Log fields: `notification_id`, `channel_id`, `resolved_user_id`, `delivery_status`, `delivered_at`.

**Current Implementation:**
- `DeliveryQueue` model and `DeliveryQueueController` exist.
- `NotificationDeliveryLog` model exists.
- Routes missing.

---

## 5. Data Model

### 5.1 Table: `ntf_channel_master`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT UNSIGNED | PK, AUTO_INCREMENT | |
| tenant_id | INT UNSIGNED | NOT NULL, INDEX | Multi-tenant isolation |
| code | VARCHAR(20) | NOT NULL, UNIQUE(tenant_id,code) | EMAIL, SMS, WHATSAPP, IN_APP, PUSH |
| name | VARCHAR(50) | NOT NULL | Display name |
| channel_type | ENUM | IMMEDIATE/BULK/TRANSACTIONAL | |
| priority_order | TINYINT | DEFAULT 5 | 1=Highest, 10=Lowest |
| max_retry | INT | DEFAULT 3 | |
| retry_delay_minutes | INT | DEFAULT 5 | |
| rate_limit_per_minute | INT | DEFAULT 100 | |
| daily_limit | INT | DEFAULT 10000 | |
| monthly_limit | INT | DEFAULT 100000 | |
| cost_per_unit | DECIMAL(10,4) | DEFAULT 0 | |
| fallback_channel_id | INT UNSIGNED | NULL, FK→self | Auto-fallback |
| is_active | TINYINT(1) | DEFAULT 1 | |
| deleted_at | TIMESTAMP | NULL | Soft delete |

### 5.2 Table: `ntf_provider_master`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| provider_name | VARCHAR(50) | Twilio, MSG91, AWS SES, Firebase |
| provider_type | ENUM | PRIMARY/SECONDARY/BACKUP |
| api_key_encrypted | TEXT NULL | Encrypted |
| api_secret_encrypted | TEXT NULL | Encrypted |
| from_address | VARCHAR(255) NULL | Sender email/phone |
| configuration | JSON NULL | Provider-specific config |

### 5.3 Table: `ntf_notifications`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | |
| notification_uuid | CHAR(36) | Public-facing UUID |
| source_module | VARCHAR(50) | Originating module |
| source_record_id | INT UNSIGNED NULL | Source record ID |
| notification_event | VARCHAR(50) | Event code matching templates |
| notification_type | ENUM | TRANSACTIONAL/PROMOTIONAL/ALERT/REMINDER/DIGEST |
| title | VARCHAR(255) | |
| template_id | INT UNSIGNED | FK → ntf_templates |
| priority_id | INT UNSIGNED | FK → sys_dropdown_table |
| schedule_type | ENUM | IMMEDIATE/SCHEDULED/RECURRING/TRIGGERED |
| scheduled_at | DATETIME NULL | |
| recurring_pattern | ENUM | NONE/HOURLY/DAILY/WEEKLY/MONTHLY/YEARLY/CUSTOM |
| recurring_expression | VARCHAR(100) NULL | Cron or RRULE |
| expires_at | DATETIME NULL | |
| total_recipients | INT | Calculated |
| sent_count / failed_count / delivered_count / read_count / click_count | INT | Calculated counters |
| notification_status_id | INT UNSIGNED | FK → sys_dropdown_table |
| is_manual | TINYINT(1) | 0=event-driven, 1=manual |
| approved_by / approved_at | INT/DATETIME | Approval workflow |

### 5.4 Table: `ntf_templates`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | |
| template_code | VARCHAR(50) | Matches notification_event |
| template_name | VARCHAR(100) | |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| template_version | INT | DEFAULT 1 |
| subject | VARCHAR(255) NULL | Email subject |
| body | TEXT | Template body with {{placeholders}} |
| alt_body | TEXT NULL | Plain text fallback |
| placeholders | JSON NULL | Required placeholder list |
| language_code | VARCHAR(10) | DEFAULT 'en' |
| approval_status | ENUM | DRAFT/PENDING/APPROVED/REJECTED/ARCHIVED |
| is_system_template | TINYINT(1) | |
| effective_from / effective_to | DATETIME NULL | |

### 5.5 Table: `ntf_resolved_recipients`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| notification_id | INT UNSIGNED | FK → ntf_notifications |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| template_id | INT UNSIGNED | FK → ntf_templates |
| resolved_user_id | INT UNSIGNED | FK → sys_user |
| device_id | INT UNSIGNED NULL | FK → ntf_user_devices (push) |
| recipient_address | VARCHAR(255) NULL | Resolved email/phone |
| personalized_subject | VARCHAR(500) NULL | Rendered |
| personalized_body | TEXT NULL | Rendered |
| personalization_data | JSON NULL | Placeholder values |
| batch_id | VARCHAR(36) NULL | For bulk processing |
| is_processed | TINYINT(1) | DEFAULT 0 |

### 5.6 Table: `ntf_user_preferences`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| user_id | INT UNSIGNED | FK → sys_user |
| channel_id | INT UNSIGNED | FK → ntf_channel_master |
| is_enabled | TINYINT(1) | |
| is_opted_in | TINYINT(1) | GDPR consent |
| opted_in_at / opted_out_at | DATETIME NULL | |
| quiet_hours_start / end | TIME NULL | |
| daily_digest | TINYINT(1) | |
| priority_threshold_id | INT UNSIGNED NULL | Min priority threshold |

### 5.7 Table: `ntf_user_devices`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| user_id | INT UNSIGNED | FK → sys_user |
| device_type | ENUM | ANDROID/IOS/WEB/DESKTOP |
| device_token | VARCHAR(512) | FCM/APNS token |
| last_active_at | DATETIME NULL | |
| UNIQUE KEY | (user_id, device_token) | |

### 5.8 Table: `ntf_target_groups`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | |
| group_name / group_code | VARCHAR | UNIQUE(tenant_id, group_code) |
| group_type | ENUM | STATIC / DYNAMIC |
| dynamic_query | TEXT NULL | JSON/SQL for dynamic resolution |
| is_system_group | TINYINT(1) | Cannot be deleted by tenant |

### 5.9 Table: `ntf_notification_channels` (junction)

Per-notification channel assignment with status, retry tracking, and per-channel template override.

### 5.10 Table: `ntf_notification_targets` (junction)

Target definitions per notification with target_type, target_group reference, and condition JSON.

### 5.11 Table: `ntf_delivery_queue`

Delivery queue with worker locking, attempt counting, and status tracking.

---

## 6. API & Route Specification

**Current State: ALL ROUTES COMMENTED OUT**

The module routes file (`Modules/Notification/routes/web.php`) contains only:
```php
Route::middleware(['auth', 'verified'])->group(function () {
    //Route::resource('notifications', NotificationController::class)->names('notification');
});
```

**Proposed Route Structure (Fix Required):**

```
// Channel & Provider Management (Admin only)
GET    /notifications/channels                    → ChannelMasterController@index
POST   /notifications/channels                    → ChannelMasterController@store
GET    /notifications/channels/{id}/edit          → ChannelMasterController@edit
PUT    /notifications/channels/{id}               → ChannelMasterController@update

GET    /notifications/providers                   → ProviderMasterController@index
POST   /notifications/providers                   → ProviderMasterController@store

// Templates
GET    /notifications/templates                   → TemplateController@index
POST   /notifications/templates                   → TemplateController@store
GET    /notifications/templates/{id}/edit         → TemplateController@edit
PUT    /notifications/templates/{id}              → TemplateController@update

// Notifications (manual)
GET    /notifications                             → NotificationManageController@index
POST   /notifications                             → NotificationManageController@store
GET    /notifications/{id}                        → NotificationManageController@show

// Target Groups
GET    /notifications/target-groups               → TargetGroupController@index
POST   /notifications/target-groups               → TargetGroupController@store

// User Preferences
GET    /notifications/preferences                 → UserPreferenceController@index
PUT    /notifications/preferences/{id}            → UserPreferenceController@update

// Delivery Queue & Logs
GET    /notifications/delivery-queue              → DeliveryQueueController@index
GET    /notifications/logs                        → ResolvedRecipientController@index
```

**Gate Prefix Fix Required:** Change policy from `prime.notification.*` to `tenant.notification.*`.

---

## 7. UI Screen Inventory

| Screen | Route | Status | Notes |
|--------|-------|--------|-------|
| Notification Dashboard | /notifications | Missing (routes commented out) | |
| Create/Send Notification | /notifications/create | Missing | |
| Channel Master List | /notifications/channels | Missing | |
| Provider Configuration | /notifications/providers | Missing | |
| Template List | /notifications/templates | Missing | |
| Template Editor | /notifications/templates/create | Missing | |
| Target Groups | /notifications/target-groups | Missing | |
| User Preferences | /notifications/preferences | Missing | |
| Delivery Queue Monitor | /notifications/delivery-queue | Missing | |
| Delivery Logs / Reports | /notifications/logs | Missing | |

---

## 8. Business Rules & Domain Constraints

**BR-NTF-01:** A notification can only be dispatched if its `notification_status_id` is APPROVED or SCHEDULED. DRAFT notifications cannot be sent.

**BR-NTF-02:** A user who has opted out (`is_opted_in = 0`) of a channel shall never receive notifications on that channel, regardless of other settings.

**BR-NTF-03:** Quiet hours enforcement — if current time falls between `quiet_hours_start` and `quiet_hours_end` for a user's timezone, notification delivery shall be deferred to the end of the quiet window.

**BR-NTF-04:** System templates (`is_system_template = 1`) cannot be modified or deleted by school admins. Only Prime super admins can manage system templates.

**BR-NTF-05:** Template `approval_status` must be APPROVED before a template can be used for delivery. Templates in DRAFT, PENDING, REJECTED, or ARCHIVED states shall not be used.

**BR-NTF-06:** Event codes must match between the firing module (`SystemNotificationTriggered`) and `ntf_notifications.notification_event` AND `ntf_templates.template_code`. If no match exists, `NotificationService::trigger()` silently returns without error.

**BR-NTF-07:** Each channel has a `rate_limit_per_minute`, `daily_limit`, and `monthly_limit`. Exceeding these limits shall queue messages for the next available window rather than dropping them.

**BR-NTF-08:** `ntf_resolved_recipients.recipient_address` shall be populated at time of resolution based on user's contact data. For IN_APP, this field is null (delivery is internal).

**BR-NTF-09:** Delivery logs (`NotificationDeliveryLog`) are append-only and shall not be deleted.

---

## 9. Workflow & State Machines

### 9.1 Notification Lifecycle

```
DRAFT → SCHEDULED → PROCESSING → COMPLETED
                              → PARTIAL (some channels failed)
                              → FAILED (all channels failed)
       → CANCELLED (admin action)
       → EXPIRED (passes expires_at without being processed)
```

### 9.2 Template Approval Workflow

```
DRAFT → PENDING (submitted for review)
      → APPROVED (reviewer approves — can now be used)
      → REJECTED (reviewer rejects with comment)
APPROVED → ARCHIVED (superseded by newer version)
```

### 9.3 Delivery Queue State Machine

```
PENDING → PROCESSING (locked by worker)
        → SENT (delivered successfully)
        → FAILED (max attempts exhausted)
        → RETRY (will retry after backoff)
        → CANCELLED (admin action or notification cancelled)
```

### 9.4 Event-Driven Flow

```
Module fires: SystemNotificationTriggered::dispatch('FEE_DUE_REMINDER', $context)
    ↓
Queue Worker picks up: ProcessSystemNotification::handle()
    ↓
NotificationService::trigger('FEE_DUE_REMINDER', $context)
    ↓
Find ntf_notifications WHERE notification_event = 'FEE_DUE_REMINDER'
    ↓
For each active channel:
    Find ntf_templates WHERE template_code = 'FEE_DUE_REMINDER' AND channel_id = ?
    Render template with $context
    Dispatch to channel (EMAIL/IN_APP/SMS/PUSH)
    Write to NotificationDeliveryLog
```

---

## 10. Non-Functional Requirements

**NFR-NTF-01 (Performance):** Notification processing shall be asynchronous. The `ProcessSystemNotification` listener must implement `ShouldQueue`. A bulk notification to 1000 recipients shall complete within 5 minutes.

**NFR-NTF-02 (Reliability):** The queue listener retries 3 times with 10-second backoff. Failed jobs must be logged to the failed_jobs table and the `failed()` method writes to application logs.

**NFR-NTF-03 (Security):** Provider API credentials stored in `ntf_provider_master` must use `api_key_encrypted` / `api_secret_encrypted` fields. Plaintext storage is prohibited. Encryption key rotation must be supported.

**NFR-NTF-04 (Privacy/GDPR):** User opt-out (`is_opted_in = 0`) must be respected immediately. Opt-out timestamp shall be recorded. Marketing/promotional notifications require explicit opt-in.

**NFR-NTF-05 (Scalability):** The delivery queue design supports batch processing via `batch_id` grouping in `ntf_resolved_recipients`. The system must support horizontal scaling of queue workers.

**NFR-NTF-06 (Observability):** All delivery attempts (success and failure) must be logged. Aggregate counters (`sent_count`, `failed_count`, `delivered_count`, `read_count`, `click_count`) on `ntf_notifications` must be maintained.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| SystemConfig (sys_*) | Consumes | `sys_dropdown_table` for status/priority/type lookups; `sys_user` for recipient resolution; `sys_media` for template attachments |
| All tenant modules | Consumes (event source) | Any module fires `SystemNotificationTriggered` to trigger notifications |
| Student Management | Consumes | Resolve student/parent contact details for recipient address |
| Finance / Fees | Consumes | FEE_DUE_REMINDER, PAYMENT_RECEIVED events |
| Exam Module | Consumes | EXAM_RESULT_PUBLISHED, EXAM_SCHEDULED events |
| Laravel Queue | Infrastructure | `ShouldQueue` for async processing |
| Laravel Mail | Infrastructure | Email delivery via SMTP |
| Firebase FCM | External | Push notification delivery (stubbed) |
| SMS Gateway (MSG91/Twilio) | External | SMS delivery (stubbed) |

---

## 12. Test Coverage

**Current State: 0 tests exist.**

**Required Test Suite:**

| Test Class | Type | Priority |
|-----------|------|----------|
| NotificationServiceTest | Feature | P0 — tests IN_APP and EMAIL dispatch paths |
| ProcessSystemNotificationTest | Feature | P0 — tests queued listener handling |
| NotificationTemplateRenderTest | Unit | P0 — tests placeholder substitution |
| ChannelMasterControllerTest | Feature | P1 |
| TemplateControllerTest | Feature | P1 |
| TargetGroupResolutionTest | Unit | P1 |
| UserPreferenceTest | Unit | P1 |
| DeliveryQueueTest | Unit | P2 |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Channel | A delivery medium: EMAIL, SMS, WHATSAPP, IN_APP, PUSH |
| Event Code | A string identifier that links a module event to notification templates |
| Template | A reusable message body with `{{placeholder}}` variables |
| Resolved Recipient | A single user/address combination ready for delivery |
| Target Group | A named set of users (static list or dynamic query) |
| Quiet Hours | Time window during which notification delivery is deferred |
| Fallback Channel | Alternative channel used if primary channel delivery fails |
| Digest | Batched summary notification instead of individual messages |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 1 — Critical Bug Fixes:**
1. **Uncomment routes in `web.php`** — the entire module is completely inaccessible. Minimum viable fix: uncomment the resource route and add routes for all 12 controllers.
2. **Fix Gate prefix in `PrimeNotificationPolicy`** — change `prime.notification.*` to `tenant.notification.*` to align with the tenant module RBAC pattern.
3. **Uncomment the email dispatch call** — in `NotificationService::dispatchToChannel()`, the `case 'EMAIL'` block has the `sendEmail()` call commented out. Uncomment and test.
4. **Resolve table name mismatch** — `NotificationTemplate` model maps to `ntf_notification_templates` but DDL defines `ntf_templates`. Either update model or add migration to rename.

**Priority 2 — Feature Completion:**
5. Implement SMS dispatch in `dispatchToChannel()` using `ntf_provider_master` credentials and a provider adapter pattern (similar to Payment's GatewayManager).
6. Implement Push notification dispatch via Firebase FCM using `ntf_user_devices.device_token`.
7. Implement dynamic target group resolution logic (currently `dynamic_query` field is stored but never executed).
8. Add WhatsApp channel support via Meta Business API.

**Priority 3 — Quality:**
9. Add a minimum of 8 unit/feature tests (see Section 12).
10. Implement an event-code registry to validate that modules fire recognized event codes.
11. Add a notification analytics dashboard showing open rates and delivery success rates per channel.
12. Consider rate-limit enforcement at the queue level, not just config — add a `RateLimiter` check before dequeuing.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path |
|------|------|
| Event | `Modules/Notification/app/Events/SystemNotificationTriggered.php` |
| Listener | `Modules/Notification/app/Listeners/ProcessSystemNotification.php` |
| Service | `Modules/Notification/app/Services/NotificationService.php` |
| Policy | `Modules/Notification/app/Policies/PrimeNotificationPolicy.php` |
| Template Model | `Modules/Notification/app/Models/NotificationTemplate.php` |
| Routes (broken) | `Modules/Notification/routes/web.php` |
| DDL | `tenant_db_v2.sql` lines 2286–2640 |

### Appendix B: Known Bugs Register

| Bug ID | Severity | Description | File | Fix Required |
|--------|----------|-------------|------|-------------|
| BUG-NTF-001 | CRITICAL | All routes commented out | `routes/web.php` | Uncomment routes |
| BUG-NTF-002 | HIGH | Gate prefix `prime.*` instead of `tenant.*` | `PrimeNotificationPolicy.php` | Update permission strings |
| BUG-NTF-003 | HIGH | Email dispatch call commented out | `NotificationService.php:77` | Uncomment `sendEmail()` call |
| BUG-NTF-004 | MEDIUM | Model table `ntf_notification_templates` vs DDL `ntf_templates` | `NotificationTemplate.php:16` | Align model to DDL |

### Appendix C: Event Code Conventions

Event codes should follow the format: `MODULE_ACTION_SUBJECT` in UPPER_SNAKE_CASE.

Examples:
- `FEE_DUE_REMINDER`
- `EXAM_RESULT_PUBLISHED`
- `ATTENDANCE_MARKED_ABSENT`
- `HOMEWORK_ASSIGNED`
- `STUDENT_ADMITTED`
