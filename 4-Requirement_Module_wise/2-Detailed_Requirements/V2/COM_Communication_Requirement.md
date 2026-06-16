# Communication Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** COM  |  **Module Path:** `📐 Proposed: Modules/Communication/`
**Module Type:** Tenant  |  **Database:** `📐 Proposed: tenant_db`
**Table Prefix:** `com_*`  |  **Processing Mode:** RBS_ONLY
**RBS Reference:** N (Communication & Notifications)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/COM_Communication_Requirement.md`
**Gap Analysis:** N/A (Greenfield module extending Notification)
**Generation Batch:** 8/10

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Routes and API Endpoints](#6-routes-and-api-endpoints)
7. [Business Rules](#7-business-rules)
8. [Authorization and RBAC](#8-authorization-and-rbac)
9. [Message Delivery Pipeline](#9-message-delivery-pipeline)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Notification Module Relationship and Gap Fixes](#12-notification-module-relationship-and-gap-fixes)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Test Coverage](#14-test-coverage)
15. [Implementation Status](#15-implementation-status)
16. [Development Priorities and Recommendations](#16-development-priorities-and-recommendations)

---

## 1. Module Overview

The Communication module is the human-authored messaging hub for Indian K-12 schools on the Prime-AI SaaS ERP platform. It handles all intentional, school-initiated communications — circulars, bulk SMS/email/WhatsApp campaigns, in-app direct messaging between teachers and parents, announcement boards, and emergency broadcast. It deliberately separates from the Notification module (`ntf_*`), which handles automated system-event notifications. The Communication module handles purposeful, composed messages that require audience selection, scheduling, delivery tracking, acknowledgement workflows, and DLT compliance.

This V2 document incorporates the full RBS v4.0 sub-module set N1–N8, adds the delivery pipeline state machine, expands the data model with missing tables from V1, adds full mobile API routes, and documents the remediation work needed in the existing Notification module as a prerequisite.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Communication |
| Module Code | COM |
| nwidart Module Namespace | `📐 Modules\Communication` |
| Module Path | `📐 Modules/Communication/` |
| Route Prefix | `communication/` |
| Route Name Prefix | `communication.` |
| DB Table Prefix | `com_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` + `routes/api.php` |
| Queue Name | `communications` (dedicated worker) |
| Emergency Queue | `emergency` (highest priority) |

### 1.2 Module Scale

| Metric | V1 Proposed | V2 Proposed |
|---|---|---|
| Controllers | 10 | 📐 13 |
| Models | 12 | 📐 16 |
| Services | 7 | 📐 10 |
| Jobs | 1 | 📐 4 |
| FormRequests | 18 | 📐 26 |
| Policies | 10 | 📐 13 |
| DDL Tables (`com_*`) | 11 | 📐 14 |
| ntf_* tables fixed/extended | 0 | 📐 6 (fix existing) |
| Views (Blade) | ~70 | 📐 ~85 |
| API endpoints (mobile) | 3 | 📐 18 |
| Test cases | 12 | 📐 22 |

### 1.3 V1→V2 Delta Summary

| Area | V1 Gap | V2 Resolution |
|---|---|---|
| Notification module prereqs | Not addressed | Section 12 — full gap list + remediation steps |
| Delivery state machine | Implied | Section 9 — explicit state diagram with all transitions |
| Mobile API endpoints | 3 webhooks only | Section 6.2 — 18 REST endpoints for mobile app |
| Template translations | Noted as v2 TODO | `com_message_template_translations` table added (Section 5) |
| User notification preferences | Not in COM scope | `com_user_preferences` table added (N7) |
| Event-driven notification triggers | Not in COM scope | Section 11 — 8 module integrations with trigger contracts |
| Notification module gate prefix bug | Not addressed | Section 12.1 — documented fix |
| ntf_* commented routes | Not addressed | Section 12.2 — route re-enablement plan |
| Delivery status polling service | Mentioned | `DeliveryStatusPoller` job added to service layer |
| DND filtering | Mentioned | `DndFilterService` added |

---

## 2. Business Context

### 2.1 Business Purpose

Indian schools are communication-intensive organisations. Administration issues dozens of circulars annually — PTM invitations, holiday notifications, fee due notices, exam schedules, government directives. Without a structured system, schools rely on informal WhatsApp groups, paper circulars, and phone calls — resulting in information loss, non-acknowledgement, and compliance failures.

Key problems addressed:

1. **Circular and Notice Management** — Create, distribute, and track acknowledgement of official school circulars across targeted audiences.
2. **DLT-Compliant Bulk SMS** — TRAI mandates all bulk SMS use pre-registered DLT templates with a registered Entity ID and Sender ID. Non-compliant SMS is blocked at the network level.
3. **Email Campaigns** — Formal communications (report cards, newsletters, appointment letters) with delivery tracking.
4. **WhatsApp Business API** — India has near-universal WhatsApp adoption; structured template-based outbound messaging replaces informal group chaos.
5. **In-App Direct Messaging** — Teacher-to-parent and teacher-to-student messaging within the platform with moderation controls appropriate for a school environment.
6. **Emergency Alerts** — One-click multi-channel broadcast (SMS + Email + Push + In-App) bypassing user preferences for school closure, security incidents, exam cancellations.
7. **Communication Audit Trail** — Regulatory compliance and dispute resolution require proof that messages were sent, delivered, and acknowledged.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| School Admin | Issue circulars, configure gateways, manage groups, view all reports, trigger emergency alerts |
| Principal | Issue circulars, broadcast announcements, trigger emergency alerts, view reports |
| Class Teacher | Send direct messages to parents of own class, post class-level announcements |
| Subject Teacher | Message parents about student-specific academic concerns |
| Parent | Receive all communications, acknowledge circulars, reply to direct messages from teachers |
| Student (portal) | Receive teacher messages, view announcements, view circulars |
| HR Manager | Internal staff communications — training notices, HR circulars |

### 2.3 Indian School Context — Regulatory and Operational Notes

- **TRAI DLT Compliance (mandatory)**: All bulk SMS (promotional, transactional, service category) must use pre-registered DLT templates. The 6-character Sender ID, Entity ID, and Template ID must all match the TRAI DLT portal registration. Any mismatch causes silent rejection at the telecom network level with no error returned from the gateway.
- **DND Registry**: TRAI maintains the National Customer Preference Registry (NCPR). Promotional SMS to DND numbers is illegal. Gateways that support DND scrubbing should be configured to skip DND numbers; this must be logged.
- **WhatsApp WABA Approval**: Meta requires business verification (2–4 weeks) before a WhatsApp Business Account is approved. Template approval takes additional 24–72 hours per template. Schools must start this process before code development on WhatsApp features.
- **PTM and Fee Reminders** are the two most common use cases, generating the highest SMS volume.
- **Government Circulars** (`circular_type = 'government'`) from CBSE/ICSE/State Boards must be forwarded to relevant staff — these carry official reference numbers.
- **Multi-language**: Templates support `en`, `hi`, and regional codes (e.g., `gu` Gujarati, `ta` Tamil, `mr` Marathi). A single logical template can have multiple language variants via `com_message_template_translations`.

---

## 3. Scope and Boundaries

### 3.1 In-Scope (V2)

- Circular and notice management with audience targeting (class, section, role, group, individual)
- Circular acknowledgement tracking with deadline enforcement and reminder dispatch
- Bulk email composition, scheduling, and delivery via configured SMTP/SES/Mailgun
- Bulk SMS composition and DLT-compliant delivery via MSG91/Twilio/Kaleyra
- WhatsApp Business API integration (outbound approved templates; inbound webhooks for delivery status)
- In-app direct messaging (1:1 and 1:group) with reply threading, read receipts, and file attachments
- Message moderation: flagging, admin review, auto-hide threshold
- Reusable message template management with multi-language variant support
- Communication group management (auto-sync class/section/role; custom groups)
- Message scheduling and recurring rules
- Emergency alert broadcast (multi-channel, bypasses user preferences, two-step confirmation)
- User notification preference management (opt-in/out per category per channel; emergency always on)
- Event-driven notification trigger contracts (consumed by StudentFee, Attendance, Examination, etc.)
- Delivery and read analytics per message/campaign
- Communication reports (PDF via DomPDF; CSV via fputcsv)
- SMS gateway configuration (MSG91/Twilio/Kaleyra with DLT fields)
- Per-tenant SMTP/SES/Mailgun email sending configuration
- Mobile REST API for all in-app messaging, circular, and preference endpoints
- Gateway delivery status webhooks (SMS, WhatsApp)
- Notification module gap remediation (prerequisite — Section 12)

### 3.2 Out of Scope

- Automated event-triggered notifications — handled by `ntf_*` Notification module. COM module calls NTF when it needs system-event notifications.
- WhatsApp inbound message handling / chatbot — v3 scope.
- Email inbox (inbound reading) — outbound only.
- Social media posting — not applicable.
- Voice/IVR call campaigns — not in scope.
- Video conferencing integration — separate module.
- FCM device token management — owned by `ntf_user_devices` (Notification module).
- Two-way SMS conversations — v3 scope.

---

## 4. Functional Requirements

### 4.1 N1 — SMS Gateway Integration (DLT-Compliant)

**RBS Sub-Module:** N1 | **Priority:** P1 (mandatory for India)

#### FR-COM-001: SMS Gateway Configuration
📐 Status: ❌ Not Started

- Admin configures SMS gateway in `com_gateway_configs` (gateway_type = `sms`):
  - Provider: MSG91, Twilio, Kaleyra, Textlocal, Fast2SMS (selectable from enum; determines API format)
  - API key (stored via Laravel `encrypt()`)
  - Sender ID (6-character DLT-registered alphanumeric)
  - DLT Entity ID (TRAI-issued, 19-digit)
  - DLT Principal Entity ID
  - Base URL override (for resellers/BSPs)
  - Rate limit: `max_per_second` (default 10; gateway-specific)
  - Test mode flag + test recipient number
  - Sandbox mode (log only — no actual dispatch; for CI/staging)
- Test SMS action: dispatches a single SMS to `test_recipient`, validates gateway response, shows success/error in UI
- Only one active SMS gateway config per tenant (UNIQUE constraint on `gateway_type`)

#### FR-COM-002: DLT Template Registration
📐 Status: ❌ Not Started

- Admin registers pre-approved DLT templates in `com_sms_dlt_templates`:
  - Template name (internal label)
  - DLT Template ID (from TRAI DLT portal — exact match required at dispatch)
  - Template body (with `{#var#}` placeholders as registered with TRAI — exact character match)
  - Variable mapping JSON: maps system field names to positional `{#var#}` slots
    ```json
    [{"position":1,"system_field":"student.name","max_length":50},
     {"position":2,"system_field":"fee.amount","max_length":10}]
    ```
  - Category: `transactional`, `promotional`, `service`
  - Sender ID used (must match registered Sender ID for this template)
- Template body reconstruction at dispatch: replace each `{#var#}` in order with resolved value; if resolved body differs from registered body skeleton, reject dispatch with error
- Templates can be deactivated (soft-delete)

#### FR-COM-003: Compose and Send SMS Campaign
📐 Status: ❌ Not Started

- Authorized user composes SMS in `com_messages` (channel = `sms`):
  - Select DLT template (required — free-text SMS not permitted per TRAI)
  - Enter variable values for merge fields
  - Recipient selection: group / role / class / section / individual / CSV upload
  - Preview rendered SMS body with estimated credit count (160 chars/credit; Unicode/Hindi 70 chars/credit)
  - Schedule or send immediately
- Phone number validation: strip non-numeric, ensure 10-digit Indian mobile, prepend `+91`
- Duplicate phone deduplication within single campaign (one delivery record per unique phone)
- DND filtering: if gateway supports DND scrubbing API, call it before dispatch; log skipped numbers with reason `dnd_registered`
- Dispatch: `SmsDispatchJob` queued on `communications` queue, processes in batches of 100

#### FR-COM-004: Bulk SMS via CSV Upload
📐 Status: ❌ Not Started

- Upload CSV with columns: `name`, `mobile`, plus one column per DLT template variable
- Validation:
  - Mobile: 10-digit numeric (after stripping spaces/dashes)
  - Required variable columns present
  - Max 5,000 rows; rows beyond 5,000 rejected before processing
- Validation report: downloadable CSV of invalid rows with reason column
- Valid rows queued as individual `com_message_recipients_jnt` entries under a parent `com_messages` record
- Progress tracking via `send_stats_json` on `com_messages` (total/sent/failed counts updated by job)

#### FR-COM-005: SMS Delivery Tracking
📐 Status: ❌ Not Started

- Each SMS sent creates a `com_message_recipients_jnt` record with `delivery_status = 'pending'`
- Gateway delivery webhook (`POST /api/v1/communication/webhook/sms`):
  - Validates HMAC/token signature per gateway spec
  - Maps gateway-specific status codes to internal enum: `delivered`, `failed`, `pending`
  - Updates `com_message_recipients_jnt.delivery_status` and `gateway_message_id`
- Polling fallback (`DeliveryStatusPollerJob`): every 15 minutes for up to 24 hours for records still `pending`
- SMS Logs view: filterable by date range, status, campaign, sender
- Export logs to CSV

---

### 4.2 N2 — Email System

**RBS Sub-Module:** N2 | **Priority:** P1

#### FR-COM-006: Email Sending Configuration
📐 Status: ❌ Not Started

- Admin configures per-tenant email sending in `com_gateway_configs` (gateway_type = `email`):
  - Driver: `smtp`, `ses`, `mailgun`, `sendgrid`, `postmark`
  - Driver-specific credentials (host/port/user/password for SMTP; API key for others) — encrypted
  - From name (default: school name)
  - From email (default: school email from `sch_profile`)
  - Reply-to email (optional)
  - Test mode + test recipient email
- Test email action: sends a test email to `test_recipient`, verifies delivery

#### FR-COM-007: Compose and Send Email Campaign
📐 Status: ❌ Not Started

- Authorized user composes email in `com_messages` (channel = `email`):
  - Subject line (required, max 255 chars; supports merge fields)
  - Body: rich-text HTML via TinyMCE or Quill editor
  - Plain text fallback body (auto-generated from HTML; editable)
  - Template selection (optional — pre-fill subject/body from `com_message_templates`)
  - Attachments: up to 5 files via `sys_media`; max 10MB total
  - From name override
  - Reply-to override
  - Priority: `normal`, `high`
  - Recipient selection: group / role / class / section / individual
  - Schedule or send immediately
- Preview mode: render final email in modal before sending
- Dispatch: `EmailDispatchJob` on `communications` queue, batches of 50

#### FR-COM-008: Email Template Management
📐 Status: ❌ Not Started

- Admin/HR manages reusable templates in `com_message_templates` (channel = `email`):
  - Template name (unique per tenant + channel)
  - Category: `fee_reminder`, `ptm_invite`, `exam_schedule`, `holiday_notice`, `welcome`, `general`
  - Subject template with merge fields: `{{student_name}}`, `{{amount}}`, `{{due_date}}`
  - HTML body template with merge fields
  - Variables JSON: `[{"key":"student_name","label":"Student Full Name","sample":"Rahul Sharma","required":true}]`
  - Language code
- Template versioning: editing creates new record with `version` incremented and `parent_template_id` set to previous; original archived (not deleted)
- Multi-language variants in `com_message_template_translations` (see Section 5)

#### FR-COM-009: Recurring Email Rules
📐 Status: ❌ Not Started

- Admin creates recurring send rules in `com_recurring_rules`:
  - Base template, channel, audience, recurrence type (`daily`/`weekly`/`monthly`/`custom_cron`)
  - Start date, end date (optional)
  - Cron expression for `custom_cron` type
- `ProcessRecurringRulesJob` runs every 15 minutes; checks `next_scheduled_at <= NOW()`, dispatches, updates `last_sent_at` and `next_scheduled_at`

---

### 4.3 N3 — Push Notifications (Communication-Initiated)

**RBS Sub-Module:** N3 | **Priority:** P2

#### FR-COM-010: Communication-Initiated Push Notifications
📐 Status: ❌ Not Started

- Communication module delegates push to Notification module's FCM infrastructure:
  - Admin composes push message: title (max 100 chars), body (max 300 chars), deep-link URL
  - Selects audience: class, section, role, group, or individual
  - Communication module resolves target user IDs
  - Calls `NotificationService::dispatchBulkPush(userIds[], title, body, deepLink, data[])` — internal PHP call, not HTTP
  - Notification module handles FCM token lookup (`ntf_user_devices`) and FCM dispatch
  - Communication module logs dispatch in `com_messages` (channel = `push`) with `ntf_notification_ref_id`
- Users without FCM tokens (no mobile app installed) logged as `delivery_status = 'skipped'` with reason `no_fcm_token`
- Deep-link targets:
  - `fee_payment` → opens fee payment screen
  - `circular/{id}` → opens specific circular
  - `exam_timetable` → opens exam schedule
  - `message/{id}` → opens specific in-app message thread
  - `announcement/{id}` → opens announcement detail
- **Prerequisite**: Notification module must be operational (Section 12)

---

### 4.4 N4 — In-App Messaging

**RBS Sub-Module:** N4 | **Priority:** P1

#### FR-COM-011: One-to-One Direct Messaging
📐 Status: ❌ Not Started

- Teacher initiates direct message to parent or student:
  - Recipient search (teachers see only parents of students in their assigned class/section — enforced by `CommunicationPolicy`)
  - Message body: plain text + emoji; no raw HTML (stored as plain text; rendered with nl2br)
  - Attachments: up to 3 files (image/PDF/DOC); each max 5MB; MIME whitelist: `image/jpeg`, `image/png`, `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
  - Parent can reply; student (portal) can reply
  - Admin/Principal can message anyone
- Reply threading: replies linked via `parent_message_id` forming a conversation thread
- Thread view: all messages with same root `parent_message_id` displayed chronologically
- Read receipt: when recipient opens thread, `com_message_recipients_jnt.is_read = 1`, `read_at` set
- Unread badge count: `SELECT COUNT(*) FROM com_message_recipients_jnt WHERE recipient_id = ? AND is_read = 0`
- Message list sorted by latest reply activity; unread threads appear first
- School config: `com_school_settings.parents_can_initiate` (default `0`; if `1`, parents can start new conversations)

#### FR-COM-012: Group Messaging
📐 Status: ❌ Not Started

- Teacher sends message to communication group (e.g., "Class 5A Parents"):
  - One `com_messages` record with `recipient_type = 'group'`
  - `com_message_recipients_jnt` rows created per member at send time (point-in-time snapshot; late-added group members do not receive old messages)
  - Group replies allowed; each reply is a new `com_messages` with `parent_message_id` set
  - School Admin can send school-wide messages (`recipient_type = 'all'`)
- Group message delivery status = aggregate of member records

#### FR-COM-013: Message Moderation
📐 Status: ❌ Not Started

- Any user can flag a message via `com_message_flags`:
  - Reason: `abusive`, `spam`, `inappropriate`, `misinformation`, `other`
  - Optional note
- Admin receives in-app notification when a message is flagged
- Admin actions: `dismiss`, `delete_message` (soft-delete), `warn_sender` (system notification), `block_sender` (revoke `com.message.send` permission)
- Auto-moderation: configurable threshold in `com_school_settings.auto_hide_flag_count` (default `3`); when reached, message hidden pending admin review without waiting for manual action
- Flagged message log: admin view of all flagged messages with resolution status

---

### 4.5 N5 — Announcement Board

**RBS Sub-Module:** N5 | **Priority:** P1

#### FR-COM-014: Create and Distribute Circular
📐 Status: ❌ Not Started

- Principal/Admin creates circular in `com_circulars`:
  - Title (required, max 300 chars)
  - Content (rich text HTML; XSS-sanitized via HTMLPurifier on save)
  - Circular type: `general`, `academic`, `exam`, `fee`, `event`, `emergency`, `government`, `newsletter`
  - Circular number (optional; e.g., `CBSE/2025/016` for government circulars)
  - Issued date (default today)
  - Expiry date (optional; must be >= issued_date)
  - Requires acknowledgement flag + deadline date
  - Attachments (up to 5 files via `sys_media`)
  - Audience targeting via `com_circular_targets_jnt`: `all`, `class`, `section`, `role`, `group`, `individual`
- On publish: optionally dispatch via SMS/email/push as companion message (links back to circular)

#### FR-COM-015: Circular Acknowledgement Tracking
📐 Status: ❌ Not Started

- When `requires_acknowledgement = 1`, recipients see "Acknowledge" button in portal/app
- Clicking creates `com_circular_acknowledgements` record (UNIQUE per circular + user — cannot acknowledge twice)
- Admin dashboard widget: per-circular — targeted count vs acknowledged vs pending
- Non-acknowledgement report: list of users who have not acknowledged by deadline; exportable CSV
- Reminder dispatch: Admin clicks "Send Reminder" → triggers `com_messages` (channel = `sms` or `email` or `in_app`) to non-acknowledgers
- Post-deadline: acknowledgement report locked; summary emailed to Principal automatically via `CircularDeadlineJob`

#### FR-COM-016: Notice Board Display
📐 Status: ❌ Not Started

- Portal notice board shows active circulars: `issued_date <= TODAY` AND (`expiry_date IS NULL` OR `expiry_date >= TODAY`)
- Role-filtered: teachers/parents see only circulars targeted at their role/class/section/group; Admin/Principal see all
- Pagination: 20 per page; newest first
- Filters: type, date range, acknowledgement status, audience
- Search: by title, circular number, type
- Mobile API: paginated list endpoint, single circular detail endpoint (Section 6.2)

---

### 4.6 N6 — Emergency Alerts

**RBS Sub-Module:** N6 | **Priority:** P0 (critical safety)

#### FR-COM-017: Emergency Alert Broadcast
📐 Status: ❌ Not Started

- Principal/Admin triggers emergency from dedicated screen (accessible from top navigation — one click away):
  - Alert type: `school_closure`, `security_incident`, `exam_cancellation`, `health_advisory`, `weather_warning`, `other`
  - Title (required, max 200 chars)
  - Message (required, max 1000 chars — kept brief for SMS compatibility; character counter shown)
  - Audience: default = ALL (parents + students + staff); overridable to class/section
  - Channels: multi-select checkboxes — SMS, Email, Push, In-App (all checked by default)
  - Two-step confirmation: compose screen → preview screen (shows exact SMS/email content) → "Confirm and Send" button
  - Single-click dispatch prohibited (BR-COM-015)
- Dispatch behaviour:
  - SMS: dispatched on `emergency` queue (highest priority); Gateway priority flag set if gateway supports it
  - Email: subject prefixed with `[URGENT]`; dispatched on `emergency` queue
  - Push: calls `NotificationService::dispatchBulkPush()` with `priority = 'high'`
  - In-App: creates `com_messages` record with `priority = 'emergency'`; `is_emergency = 1`
- Emergency alerts **bypass** `com_user_preferences` — all users receive regardless of opt-out settings (BR-COM-002)
- Emergency alert stored in `com_emergency_alerts` with delivery stats JSON updated as dispatching progresses

#### FR-COM-018: Alert Delivery Tracking
📐 Status: ❌ Not Started

- `com_emergency_alerts.delivery_stats_json` updated by dispatch jobs:
  ```json
  {
    "sms": {"total":500,"sent":498,"delivered":491,"failed":9},
    "email": {"total":500,"sent":500,"delivered":0,"failed":0},
    "push": {"total":500,"sent":312,"skipped_no_token":188},
    "in_app": {"total":500,"sent":500}
  }
  ```
- Alert log report: all past alerts, audience size, per-channel delivery stats
- Failed recipient report: users who did not receive on any channel

---

### 4.7 N7 — Notification Preferences

**RBS Sub-Module:** N7 | **Priority:** P2

#### FR-COM-019: User Notification Preference Management
📐 Status: ❌ Not Started

- Each user manages preferences in `com_user_preferences`:
  - Per category + per channel opt-in/out
  - Categories: `fee_reminder`, `exam_update`, `attendance`, `circular`, `event`, `homework`, `general`, `ptm`
  - Channels per category: `sms`, `email`, `push`, `in_app`
  - Emergency category: always `1` (not editable by user — system-enforced)
- Preference UI: settings page matrix (category rows × channel columns; toggle switches)
- Default: all categories + all channels opted IN on account creation
- At dispatch time, `CommunicationService::filterRecipientsByPreferences()` excludes opted-out users per channel
- Emergency alerts bypass this filter entirely

---

### 4.8 N8 — Event-Driven Notification Triggers

**RBS Sub-Module:** N8 | **Priority:** P2

#### FR-COM-020: Event Trigger Contract
📐 Status: ❌ Not Started

- Other modules call `CommunicationEventService::trigger(string $event, array $context)` to fire communications:
  ```php
  CommunicationEventService::trigger('fee.due_reminder', [
      'student_id' => 1234,
      'amount'     => 5500.00,
      'due_date'   => '2026-04-01',
  ]);
  ```
- `CommunicationEventService` looks up `com_event_trigger_rules` to find matching template, channels, audience, and scheduling offset
- Supported events (seeded defaults):

| Event Key | Trigger Module | Default Channel | Default Offset |
|---|---|---|---|
| `fee.due_reminder` | StudentFee | SMS + Email | -7 days, -1 day |
| `fee.overdue_notice` | StudentFee | SMS | +1 day after due |
| `attendance.absent_alert` | Attendance | SMS + Push | same day 4 PM |
| `attendance.low_attendance` | Attendance | Email | weekly |
| `exam.timetable_released` | Examination | Email + Push | immediate |
| `exam.result_published` | Examination | Push + In-App | immediate |
| `ptm.reminder` | Events/Calendar | SMS + Email | -7 days, -1 day |
| `admission.welcome` | Admission | Email | immediate |

- Module developers add new trigger rules via seeder; Communication module processes them without code changes
- All event-triggered messages create `com_messages` records like manually-sent messages (same pipeline)

---

### 4.9 Communication Groups

#### FR-COM-021: Group Management
📐 Status: ❌ Not Started

- Admin manages groups in `com_groups`:
  - `class` type: auto-synced — all parents of students in a specific class
  - `section` type: auto-synced — all parents of students in a class + section combination
  - `role` type: auto-synced — all users with a specific system role
  - `custom` type: manually maintained member list in `com_group_members_jnt`
  - `auto_sync = 1` groups have membership resolved dynamically at send time; no static member records
- Sync action: manual "Sync Now" button refreshes `member_count_cache` and `last_synced_at`
- Auto-sync groups run `SyncCommunicationGroupsJob` nightly at midnight

#### FR-COM-022: Group Membership Management
📐 Status: ❌ Not Started

- Custom groups: add members via user search or CSV upload (email/phone columns)
- Remove individual members (soft-delete from `com_group_members_jnt`)
- Bulk add: up to 500 users per CSV upload
- Member list view with role/class info and pagination
- Member count on group list updated after each add/remove

---

### 4.10 Scheduling and Templates

#### FR-COM-023: Schedule Messages
📐 Status: ❌ Not Started

- Any compose form allows "Schedule for later" with datetime picker (minute granularity)
- Past `scheduled_at` not allowed (BR-COM-006)
- `com_messages.status = 'scheduled'`
- `ProcessScheduledMessagesJob`: every 5 minutes, picks up to 100 due records, dispatches via channel service, updates status to `sent` or `failed`
- Scheduled messages editable (subject/body/template/recipients) before `scheduled_at`
- Cancellation: soft-delete if `status = 'scheduled'` and `sent_at IS NULL`

#### FR-COM-024: Communication Analytics Dashboard
📐 Status: ❌ Not Started

- Dashboard widgets (computed from `com_messages` and `com_message_recipients_jnt`):
  - Messages sent today / this week / this month — breakdown by channel
  - Active circulars pending acknowledgement (count + list with deadline)
  - Acknowledgement completion rate — last 30 days (line chart)
  - SMS delivery rate — last 30 days (%)
  - Email delivery rate — last 30 days (%)
  - Failed messages requiring attention (unresolved `delivery_status = 'failed'` records)
  - Top 5 senders last 7 days
  - Emergency alerts sent this month (with last alert date)

#### FR-COM-025: Communication Reports
📐 Status: ❌ Not Started

- Reports generated as PDF (DomPDF) or CSV (fputcsv):
  - **Sent Messages Report**: filter by channel, sender, date range, status
  - **Delivery Report**: per-campaign sent/delivered/failed per channel
  - **Acknowledgement Report**: per-circular targeted vs acknowledged vs pending
  - **Non-Acknowledgement Report**: list of users who have not acknowledged specific circular
  - **SMS Usage Report**: credits used per month, breakdown by campaign
  - **Email Campaign Report**: open rate (if tracking enabled), delivery rate
  - **Emergency Alert Report**: all alerts, audience size, per-channel delivery stats
  - **User Preference Report**: per-user opt-out summary (admin use)

---

## 5. Data Model

### 5.1 Existing Tables Used (Read/Join Only)

| Table | Module | Usage |
|---|---|---|
| `sys_users` | System | Sender, recipient identity, phone/email resolution |
| `sys_media` | System | File attachments for messages and circulars |
| `sys_activity_logs` | System | Audit trail for all communication actions |
| `sch_classes` | SchoolSetup | Class-based audience targeting |
| `sch_sections` | SchoolSetup | Section-based audience targeting |
| `std_students` | StudentMgmt | Student-parent relationship for parent targeting |
| `std_student_parents_jnt` | StudentMgmt | Resolve parent IDs from class/section |
| `ntf_user_devices` | Notification | FCM tokens for push dispatch (read-only) |
| `ntf_notifications` | Notification | Reference for push dispatch tracking |
| `ntf_channels` | Notification | Channel configuration reference |
| `ntf_templates` | Notification | Cross-reference for automated notification templates |

### 5.2 Proposed New Tables (`com_*`)

---

#### 📐 `com_gateway_configs`
SMS, Email, and WhatsApp gateway configuration per tenant.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `gateway_type` | ENUM('sms','email','whatsapp') | NOT NULL | |
| `provider_name` | VARCHAR(100) | NOT NULL | e.g., MSG91, Mailgun, Meta Cloud API |
| `driver_name` | VARCHAR(50) | DEFAULT NULL | For email: smtp/ses/mailgun/sendgrid/postmark |
| `api_key_encrypted` | TEXT | DEFAULT NULL | Laravel `encrypt()` |
| `api_secret_encrypted` | TEXT | DEFAULT NULL | For providers needing secret separately |
| `sender_id` | VARCHAR(20) | DEFAULT NULL | DLT-registered Sender ID (SMS) |
| `dlt_entity_id` | VARCHAR(50) | DEFAULT NULL | TRAI DLT Entity ID (19-digit) |
| `dlt_principal_entity_id` | VARCHAR(50) | DEFAULT NULL | TRAI Principal Entity ID |
| `waba_id` | VARCHAR(100) | DEFAULT NULL | WhatsApp Business Account ID |
| `phone_number_id` | VARCHAR(100) | DEFAULT NULL | WhatsApp Phone Number ID |
| `webhook_token_encrypted` | TEXT | DEFAULT NULL | WhatsApp/SMS webhook verification token |
| `smtp_host` | VARCHAR(200) | DEFAULT NULL | |
| `smtp_port` | SMALLINT UNSIGNED | DEFAULT NULL | |
| `smtp_username` | VARCHAR(200) | DEFAULT NULL | |
| `smtp_password_encrypted` | TEXT | DEFAULT NULL | |
| `smtp_encryption` | ENUM('tls','ssl','none') | DEFAULT 'tls' | |
| `from_name` | VARCHAR(150) | DEFAULT NULL | Email from name |
| `from_email` | VARCHAR(200) | DEFAULT NULL | |
| `base_url` | VARCHAR(300) | DEFAULT NULL | BSP/custom base URL |
| `test_mode` | TINYINT(1) | DEFAULT 0 | Route to test recipient |
| `test_recipient` | VARCHAR(255) | DEFAULT NULL | Phone or email |
| `max_per_second` | SMALLINT UNSIGNED | DEFAULT 10 | Rate limit |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

`UNIQUE KEY uq_gateway_type (gateway_type)` — one config per type per tenant

---

#### 📐 `com_sms_dlt_templates`
TRAI DLT registered SMS template repository.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | Internal label |
| `dlt_template_id` | VARCHAR(100) | NOT NULL UNIQUE | TRAI portal Template ID |
| `sender_id` | VARCHAR(20) | NOT NULL | Must match registered Sender ID for this template |
| `body_template` | TEXT | NOT NULL | Exact registered body with `{#var#}` placeholders |
| `variable_mapping_json` | JSON | DEFAULT NULL | `[{position, system_field, max_length}]` |
| `category` | ENUM('transactional','promotional','service') | DEFAULT 'transactional' | |
| `char_count_per_credit` | SMALLINT UNSIGNED | DEFAULT 160 | 70 for Unicode/Hindi |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_message_templates`
Reusable content templates for all channels.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `category` | VARCHAR(100) | DEFAULT NULL | fee_reminder, ptm_invite, exam_schedule, etc. |
| `channel` | ENUM('email','sms','whatsapp','in_app','push') | NOT NULL | |
| `language_code` | VARCHAR(10) | DEFAULT 'en' | |
| `subject` | VARCHAR(255) | DEFAULT NULL | Email subject template |
| `body_template` | MEDIUMTEXT | NOT NULL | HTML (email); plain (SMS/in_app); JSON (WhatsApp) |
| `variables_json` | JSON | DEFAULT NULL | `[{key, label, sample, required}]` |
| `version` | SMALLINT UNSIGNED | DEFAULT 1 | Auto-incremented on edit |
| `parent_template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | Version chain |
| `is_system` | TINYINT(1) | DEFAULT 0 | 1 = seeded default, cannot delete |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

`UNIQUE KEY uq_template_name_channel (name, channel)` — where `deleted_at IS NULL`

---

#### 📐 `com_message_template_translations`
Multi-language variants of a base template (V2 addition from V1 tech debt item #7).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `template_id` | BIGINT UNSIGNED | NOT NULL, FK→com_message_templates | Base template |
| `language_code` | VARCHAR(10) | NOT NULL | e.g., hi, gu, ta, mr |
| `subject` | VARCHAR(255) | DEFAULT NULL | Translated subject (email) |
| `body_template` | MEDIUMTEXT | NOT NULL | Translated body |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

`UNIQUE KEY uq_template_language (template_id, language_code)`

---

#### 📐 `com_whatsapp_templates`
WhatsApp Business API approved template registry.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `template_name` | VARCHAR(150) | NOT NULL | Exact name as in Meta Business Manager |
| `language_code` | VARCHAR(10) | DEFAULT 'en' | e.g., en, en_US, hi |
| `category` | ENUM('MARKETING','UTILITY','AUTHENTICATION') | NOT NULL | |
| `components_json` | JSON | NOT NULL | Meta template components (header/body/footer/buttons) |
| `variable_mapping_json` | JSON | DEFAULT NULL | System field → template variable mapping |
| `approval_status` | ENUM('pending_approval','approved','rejected','paused','disabled') | DEFAULT 'pending_approval' | |
| `rejection_reason` | TEXT | DEFAULT NULL | |
| `meta_template_id` | VARCHAR(100) | DEFAULT NULL | Meta-assigned template ID after approval |
| `message_template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | Optional base template link |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_groups`
Communication audience groups.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `description` | TEXT | DEFAULT NULL | |
| `group_type` | ENUM('class','section','role','custom') | NOT NULL | |
| `class_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_classes |
| `section_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_sections |
| `role_name` | VARCHAR(100) | DEFAULT NULL | System role name |
| `auto_sync` | TINYINT(1) | DEFAULT 0 | 1 = membership dynamically resolved |
| `member_count_cache` | INT UNSIGNED | DEFAULT 0 | |
| `last_synced_at` | TIMESTAMP | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

`UNIQUE KEY uq_group_name (name)` — where `deleted_at IS NULL`

---

#### 📐 `com_group_members_jnt`
Static members for custom groups.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `group_id` | BIGINT UNSIGNED | NOT NULL, FK→com_groups | |
| `user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `added_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

`UNIQUE KEY uq_group_member (group_id, user_id)` — where `deleted_at IS NULL`

---

#### 📐 `com_messages`
Core message record for all channels.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `sender_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `channel` | ENUM('email','sms','in_app','whatsapp','push') | NOT NULL | |
| `recipient_type` | ENUM('individual','group','role','class','section','all') | NOT NULL | |
| `group_id` | BIGINT UNSIGNED | FK→com_groups NULL | |
| `class_id` | INT UNSIGNED | FK→sch_classes NULL | |
| `section_id` | INT UNSIGNED | FK→sch_sections NULL | |
| `role_name` | VARCHAR(100) | DEFAULT NULL | For role-based targeting |
| `subject` | VARCHAR(255) | DEFAULT NULL | Email subject |
| `body` | LONGTEXT | NOT NULL | |
| `body_plain` | TEXT | DEFAULT NULL | Plain-text fallback (email) |
| `template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | |
| `dlt_template_id` | BIGINT UNSIGNED | FK→com_sms_dlt_templates NULL | SMS only |
| `whatsapp_template_id` | BIGINT UNSIGNED | FK→com_whatsapp_templates NULL | WhatsApp only |
| `event_trigger_rule_id` | BIGINT UNSIGNED | FK→com_event_trigger_rules NULL | If event-triggered |
| `status` | ENUM('draft','scheduled','dispatching','sent','partial_failure','failed','cancelled') | DEFAULT 'draft' | |
| `priority` | ENUM('normal','high','emergency') | DEFAULT 'normal' | |
| `is_emergency` | TINYINT(1) | DEFAULT 0 | Routes to emergency queue |
| `scheduled_at` | TIMESTAMP | DEFAULT NULL | |
| `sent_at` | TIMESTAMP | DEFAULT NULL | |
| `parent_message_id` | BIGINT UNSIGNED | FK→com_messages NULL | Reply threading |
| `ntf_notification_ref_id` | BIGINT UNSIGNED | DEFAULT NULL | Push ref to ntf_notifications |
| `attachments_json` | JSON | DEFAULT NULL | Array of sys_media IDs |
| `merge_values_json` | JSON | DEFAULT NULL | Key→value pairs used for template rendering |
| `send_stats_json` | JSON | DEFAULT NULL | `{total, queued, sent, delivered, failed, skipped}` |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

Indexes:
```sql
INDEX idx_com_messages_sender (sender_id)
INDEX idx_com_messages_status (status, scheduled_at)
INDEX idx_com_messages_channel (channel)
INDEX idx_com_messages_emergency (is_emergency, status)
INDEX idx_com_messages_thread (parent_message_id)
```

---

#### 📐 `com_message_recipients_jnt`
Per-recipient delivery tracking record.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `message_id` | BIGINT UNSIGNED | NOT NULL, FK→com_messages | |
| `recipient_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `phone_number` | VARCHAR(20) | DEFAULT NULL | Resolved at send time for SMS/WhatsApp |
| `email_address` | VARCHAR(255) | DEFAULT NULL | Resolved at send time for email |
| `delivery_status` | ENUM('queued','dispatched','delivered','read','failed','skipped','bounced') | DEFAULT 'queued' | |
| `is_read` | TINYINT(1) | DEFAULT 0 | In-app channel |
| `read_at` | TIMESTAMP | DEFAULT NULL | |
| `gateway_message_id` | VARCHAR(200) | DEFAULT NULL | Gateway-assigned tracking ID |
| `failure_reason` | VARCHAR(300) | DEFAULT NULL | |
| `skip_reason` | VARCHAR(100) | DEFAULT NULL | dnd_registered, no_fcm_token, opted_out, etc. |
| `retry_count` | TINYINT UNSIGNED | DEFAULT 0 | |
| `next_retry_at` | TIMESTAMP | DEFAULT NULL | Exponential backoff schedule |
| `last_attempted_at` | TIMESTAMP | DEFAULT NULL | |
| `dispatched_at` | TIMESTAMP | DEFAULT NULL | When sent to gateway |
| `delivered_at` | TIMESTAMP | DEFAULT NULL | When gateway confirmed delivery |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

Indexes:
```sql
INDEX idx_cmr_message (message_id)
INDEX idx_cmr_recipient (recipient_id)
INDEX idx_cmr_status (delivery_status, next_retry_at)
INDEX idx_cmr_gateway_id (gateway_message_id)
INDEX idx_cmr_unread (recipient_id, is_read, delivery_status)
```

---

#### 📐 `com_circulars`
Official school circulars and notices.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `title` | VARCHAR(300) | NOT NULL | |
| `content` | LONGTEXT | DEFAULT NULL | Rich text HTML (XSS-sanitized) |
| `circular_type` | ENUM('general','academic','exam','fee','event','emergency','government','newsletter') | NOT NULL | |
| `circular_number` | VARCHAR(100) | DEFAULT NULL | e.g., CBSE/2025/016 |
| `issued_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `issued_date` | DATE | NOT NULL | |
| `expiry_date` | DATE | DEFAULT NULL | NULL = never expires |
| `requires_acknowledgement` | TINYINT(1) | DEFAULT 0 | |
| `acknowledgement_deadline` | DATE | DEFAULT NULL | |
| `acknowledgement_report_sent` | TINYINT(1) | DEFAULT 0 | 1 = deadline summary emailed to Principal |
| `attachments_json` | JSON | DEFAULT NULL | Array of sys_media IDs |
| `companion_message_id` | BIGINT UNSIGNED | FK→com_messages NULL | If dispatched as SMS/email companion |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

Indexes:
```sql
INDEX idx_com_circulars_type (circular_type)
INDEX idx_com_circulars_dates (issued_date, expiry_date)
INDEX idx_com_circulars_ack (requires_acknowledgement, acknowledgement_deadline)
```

---

#### 📐 `com_circular_targets_jnt`
Audience targeting for each circular.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `circular_id` | BIGINT UNSIGNED | NOT NULL, FK→com_circulars | |
| `target_type` | ENUM('all','class','section','role','group','individual') | NOT NULL | |
| `target_id` | BIGINT UNSIGNED | DEFAULT NULL | ID in source table |
| `target_label` | VARCHAR(200) | DEFAULT NULL | Human-readable label (denormalized for history) |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

`INDEX idx_cct_circular (circular_id, target_type)`

---

#### 📐 `com_circular_acknowledgements`
Per-user acknowledgement records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `circular_id` | BIGINT UNSIGNED | NOT NULL, FK→com_circulars | |
| `user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `acknowledged_at` | TIMESTAMP | NOT NULL | |
| `device_type` | VARCHAR(50) | DEFAULT NULL | web / mobile |
| `ip_address` | VARCHAR(45) | DEFAULT NULL | |
| `user_agent` | VARCHAR(300) | DEFAULT NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

`UNIQUE KEY uq_circular_ack (circular_id, user_id)`

---

#### 📐 `com_emergency_alerts`
Emergency alert dispatch records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `alert_type` | ENUM('school_closure','security_incident','exam_cancellation','health_advisory','weather_warning','other') | NOT NULL | |
| `title` | VARCHAR(200) | NOT NULL | |
| `message` | TEXT | NOT NULL | |
| `audience_type` | ENUM('all','class','section') | DEFAULT 'all' | |
| `audience_class_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_classes |
| `audience_section_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_sections |
| `channels_json` | JSON | NOT NULL | `["sms","email","push","in_app"]` |
| `triggered_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `triggered_at` | TIMESTAMP | NOT NULL | |
| `confirmed_at` | TIMESTAMP | DEFAULT NULL | Two-step confirmation timestamp |
| `delivery_stats_json` | JSON | DEFAULT NULL | Per-channel delivery stats |
| `status` | ENUM('pending_confirmation','dispatching','sent','partial_failure','failed') | DEFAULT 'pending_confirmation' | |
| `com_message_id` | BIGINT UNSIGNED | FK→com_messages NULL | Linked in-app message record |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_message_flags`
User-submitted moderation flags on in-app messages.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `message_id` | BIGINT UNSIGNED | NOT NULL, FK→com_messages | |
| `flagged_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `flag_reason` | ENUM('abusive','spam','inappropriate','misinformation','other') | NOT NULL | |
| `flag_note` | TEXT | DEFAULT NULL | |
| `reviewed_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `reviewed_at` | TIMESTAMP | DEFAULT NULL | |
| `resolution` | ENUM('pending','dismissed','message_deleted','sender_warned','sender_blocked') | DEFAULT 'pending' | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

`INDEX idx_cmf_message (message_id, resolution)`

---

#### 📐 `com_recurring_rules`
Recurring message schedule definitions.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `template_id` | BIGINT UNSIGNED | NOT NULL, FK→com_message_templates | |
| `channel` | ENUM('email','sms','in_app','whatsapp') | NOT NULL | |
| `audience_type` | ENUM('group','role','class','section','all') | NOT NULL | |
| `group_id` | BIGINT UNSIGNED | FK→com_groups NULL | |
| `class_id` | INT UNSIGNED | FK→sch_classes NULL | |
| `section_id` | INT UNSIGNED | FK→sch_sections NULL | |
| `role_name` | VARCHAR(100) | DEFAULT NULL | |
| `recurrence_type` | ENUM('daily','weekly','monthly','custom_cron') | NOT NULL | |
| `cron_expression` | VARCHAR(100) | DEFAULT NULL | |
| `start_date` | DATE | NOT NULL | |
| `end_date` | DATE | DEFAULT NULL | NULL = runs indefinitely |
| `last_sent_at` | TIMESTAMP | DEFAULT NULL | |
| `next_scheduled_at` | TIMESTAMP | DEFAULT NULL | |
| `send_count` | INT UNSIGNED | DEFAULT 0 | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_user_preferences`
Per-user notification channel preferences by category (N7).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `category` | ENUM('fee_reminder','exam_update','attendance','circular','event','homework','general','ptm','emergency') | NOT NULL | |
| `channel` | ENUM('sms','email','push','in_app') | NOT NULL | |
| `is_opted_in` | TINYINT(1) | DEFAULT 1 | 0 = opted out |
| `updated_at` | TIMESTAMP | | |
| `created_at` | TIMESTAMP | | |

`UNIQUE KEY uq_user_pref (user_id, category, channel)`
`INDEX idx_pref_user (user_id)`

Note: `emergency` category rows always have `is_opted_in = 1` enforced by application layer (BR-COM-002).

---

#### 📐 `com_event_trigger_rules`
Event-driven notification trigger configuration (N8).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `event_key` | VARCHAR(100) | NOT NULL | e.g., `fee.due_reminder` |
| `description` | VARCHAR(300) | DEFAULT NULL | |
| `template_id` | BIGINT UNSIGNED | NOT NULL, FK→com_message_templates | |
| `channel` | ENUM('sms','email','push','in_app','whatsapp') | NOT NULL | |
| `audience_resolver` | VARCHAR(100) | NOT NULL | Class name of audience resolver e.g., `FeeReminderAudienceResolver` |
| `offset_days` | SMALLINT | DEFAULT 0 | Negative = before event; positive = after |
| `offset_direction` | ENUM('before','after','immediate') | DEFAULT 'immediate' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `is_system` | TINYINT(1) | DEFAULT 1 | 1 = seeded, not deletable |
| `created_by` | BIGINT UNSIGNED | FK→sys_users | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

`UNIQUE KEY uq_event_rule (event_key, channel, offset_days)`

---

#### 📐 `com_school_settings`
Per-tenant Communication module configuration.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `setting_key` | VARCHAR(100) | NOT NULL UNIQUE | |
| `setting_value` | TEXT | DEFAULT NULL | |
| `setting_type` | ENUM('boolean','integer','string','json') | DEFAULT 'string' | |
| `description` | VARCHAR(300) | DEFAULT NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

Seeded settings:

| setting_key | Default | Description |
|---|---|---|
| `parents_can_initiate` | `0` | Parents can start new message threads |
| `auto_hide_flag_count` | `3` | Auto-hide flagged message threshold |
| `email_tracking_pixel` | `0` | Enable email open tracking |
| `sms_dnd_filter` | `1` | Filter DND numbers before SMS dispatch |
| `default_sender_language` | `en` | Default template language |
| `emergency_confirmation_required` | `1` | Two-step confirmation for emergency alerts |

---

### 5.3 ntf_* Tables Extended/Fixed (Prerequisites — Section 12)

The following Notification module tables require structural fixes or new data seeding before the Communication module can use them:

| ntf_* Table | Issue | Required Fix |
|---|---|---|
| `ntf_channels` | SMS and Push rows exist but are stubs | Populate `config_json` with real gateway fields |
| `ntf_templates` | Gate prefix `prime.*` blocks template access | Fix gate prefix to `tenant.*` |
| `ntf_deliveries` | Status polling not implemented | Add `polling_until` column |
| `ntf_user_devices` | FCM token management exists | No changes — read-only for COM |
| `ntf_targets` | All routes commented out | Re-enable routes per Section 12.2 |

---

## 6. Routes and API Endpoints

### 6.1 Web Routes (`routes/tenant.php`)

All routes: middleware `['auth', 'verified', 'tenant']`, prefix `communication/`, name prefix `communication.`

#### Dashboard and Analytics
```
GET  communication/                           communication.dashboard
GET  communication/reports/dashboard          communication.reports.dashboard
GET  communication/reports/sent               communication.reports.sent
GET  communication/reports/delivery           communication.reports.delivery
GET  communication/reports/acknowledgements   communication.reports.acknowledgements
GET  communication/reports/sms-usage          communication.reports.sms-usage
GET  communication/reports/emergency          communication.reports.emergency
GET  communication/reports/preferences        communication.reports.preferences
```

#### Circulars
```
GET    communication/circulars                             communication.circulars.index
GET    communication/circulars/create                      communication.circulars.create
POST   communication/circulars                             communication.circulars.store
GET    communication/circulars/{id}                        communication.circulars.show
GET    communication/circulars/{id}/edit                   communication.circulars.edit
PUT    communication/circulars/{id}                        communication.circulars.update
DELETE communication/circulars/{id}                        communication.circulars.destroy
POST   communication/circulars/{id}/acknowledge            communication.circulars.acknowledge
GET    communication/circulars/{id}/acknowledgements       communication.circulars.acknowledgements
POST   communication/circulars/{id}/send-reminder          communication.circulars.send-reminder
GET    communication/circulars/{id}/export-non-ack         communication.circulars.export-non-ack
```

#### Email
```
GET    communication/email                                 communication.email.index
GET    communication/email/compose                         communication.email.compose
POST   communication/email                                 communication.email.store
GET    communication/email/{id}                            communication.email.show
DELETE communication/email/{id}                            communication.email.destroy
POST   communication/email/{id}/cancel                     communication.email.cancel
GET    communication/email/gateway                         communication.email.gateway.show
POST   communication/email/gateway                         communication.email.gateway.save
POST   communication/email/gateway/test                    communication.email.gateway.test
```

#### SMS
```
GET    communication/sms                                   communication.sms.index
GET    communication/sms/compose                           communication.sms.compose
POST   communication/sms                                   communication.sms.store
GET    communication/sms/{id}                              communication.sms.show
DELETE communication/sms/{id}                              communication.sms.destroy
GET    communication/sms/logs                              communication.sms.logs
GET    communication/sms/gateway                           communication.sms.gateway.show
POST   communication/sms/gateway                           communication.sms.gateway.save
POST   communication/sms/gateway/test                      communication.sms.gateway.test
GET    communication/sms/dlt-templates                     communication.sms.dlt.index
GET    communication/sms/dlt-templates/create              communication.sms.dlt.create
POST   communication/sms/dlt-templates                     communication.sms.dlt.store
GET    communication/sms/dlt-templates/{id}/edit           communication.sms.dlt.edit
PUT    communication/sms/dlt-templates/{id}                communication.sms.dlt.update
DELETE communication/sms/dlt-templates/{id}                communication.sms.dlt.destroy
```

#### WhatsApp
```
GET    communication/whatsapp                              communication.whatsapp.index
GET    communication/whatsapp/compose                      communication.whatsapp.compose
POST   communication/whatsapp                              communication.whatsapp.store
GET    communication/whatsapp/gateway                      communication.whatsapp.gateway.show
POST   communication/whatsapp/gateway                      communication.whatsapp.gateway.save
GET    communication/whatsapp/templates                    communication.whatsapp.templates.index
GET    communication/whatsapp/templates/create             communication.whatsapp.templates.create
POST   communication/whatsapp/templates                    communication.whatsapp.templates.store
GET    communication/whatsapp/templates/{id}/edit          communication.whatsapp.templates.edit
PUT    communication/whatsapp/templates/{id}               communication.whatsapp.templates.update
DELETE communication/whatsapp/templates/{id}               communication.whatsapp.templates.destroy
```

#### In-App Messaging
```
GET    communication/messages                              communication.messages.index
GET    communication/messages/create                       communication.messages.create
POST   communication/messages                              communication.messages.store
GET    communication/messages/{id}                         communication.messages.show
POST   communication/messages/{id}/reply                   communication.messages.reply
POST   communication/messages/{id}/read                    communication.messages.read
POST   communication/messages/{id}/flag                    communication.messages.flag
GET    communication/messages/flags                        communication.messages.flags.index
POST   communication/messages/flags/{id}/resolve           communication.messages.flags.resolve
```

#### Groups
```
GET    communication/groups                                communication.groups.index
GET    communication/groups/create                         communication.groups.create
POST   communication/groups                                communication.groups.store
GET    communication/groups/{id}                           communication.groups.show
GET    communication/groups/{id}/edit                      communication.groups.edit
PUT    communication/groups/{id}                           communication.groups.update
DELETE communication/groups/{id}                           communication.groups.destroy
GET    communication/groups/{id}/members                   communication.groups.members.index
POST   communication/groups/{id}/members                   communication.groups.members.store
DELETE communication/groups/{id}/members/{user_id}         communication.groups.members.destroy
POST   communication/groups/{id}/sync                      communication.groups.sync
POST   communication/groups/{id}/members/csv-upload        communication.groups.members.csv-upload
```

#### Templates
```
GET    communication/templates                             communication.templates.index
GET    communication/templates/create                      communication.templates.create
POST   communication/templates                             communication.templates.store
GET    communication/templates/{id}                        communication.templates.show
GET    communication/templates/{id}/edit                   communication.templates.edit
PUT    communication/templates/{id}                        communication.templates.update
DELETE communication/templates/{id}                        communication.templates.destroy
POST   communication/templates/{id}/translate              communication.templates.translate
```

#### Emergency Alerts
```
GET    communication/emergency                             communication.emergency.index
GET    communication/emergency/compose                     communication.emergency.compose
POST   communication/emergency/preview                     communication.emergency.preview
POST   communication/emergency/confirm                     communication.emergency.confirm
GET    communication/emergency/{id}                        communication.emergency.show
```

#### Recurring Rules
```
GET    communication/recurring                             communication.recurring.index
GET    communication/recurring/create                      communication.recurring.create
POST   communication/recurring                             communication.recurring.store
GET    communication/recurring/{id}/edit                   communication.recurring.edit
PUT    communication/recurring/{id}                        communication.recurring.update
DELETE communication/recurring/{id}                        communication.recurring.destroy
POST   communication/recurring/{id}/toggle                 communication.recurring.toggle
```

#### User Preferences
```
GET    communication/preferences                           communication.preferences.index
POST   communication/preferences                           communication.preferences.save
POST   communication/preferences/reset                     communication.preferences.reset
```

#### Settings
```
GET    communication/settings                              communication.settings.index
POST   communication/settings                              communication.settings.save
```

---

### 6.2 API Routes (`routes/api.php`) — Mobile App Endpoints

All routes: middleware `['auth:sanctum', 'tenant']`, prefix `/api/v1/communication`.
Response format: `{"success": bool, "data": {...}, "message": "string"}`.

#### Circulars (Mobile)
```
GET    /api/v1/communication/circulars                    Paginated active circulars for authenticated user (role-filtered)
GET    /api/v1/communication/circulars/{id}               Single circular with attachment download URLs
POST   /api/v1/communication/circulars/{id}/acknowledge   Record acknowledgement
GET    /api/v1/communication/circulars/unread-count       Count of unacknowledged required-ack circulars
```

#### In-App Messages (Mobile)
```
GET    /api/v1/communication/messages                     Paginated thread list (unread first)
GET    /api/v1/communication/messages/{id}                Full thread with all replies
POST   /api/v1/communication/messages                     Send new message (teachers/admin only)
POST   /api/v1/communication/messages/{id}/reply          Reply to existing thread
POST   /api/v1/communication/messages/{id}/read           Mark thread as read (sets is_read=1 for all in thread)
POST   /api/v1/communication/messages/{id}/flag           Flag message as inappropriate
GET    /api/v1/communication/messages/unread-count        Badge count value for app icon
```

#### Emergency Alerts (Mobile — Receive Only)
```
GET    /api/v1/communication/emergency/latest             Latest active emergency alert (for mobile banner)
GET    /api/v1/communication/emergency                    Paginated history of emergency alerts
```

#### User Preferences (Mobile)
```
GET    /api/v1/communication/preferences                  Current user preference matrix
PUT    /api/v1/communication/preferences                  Update preferences array [{category, channel, is_opted_in}]
```

#### Webhooks (No auth middleware — signature verification instead)
```
POST   /api/v1/communication/webhook/sms                  SMS delivery status callback (gateway → platform)
GET    /api/v1/communication/webhook/whatsapp             WhatsApp webhook verification (Meta GET challenge)
POST   /api/v1/communication/webhook/whatsapp             WhatsApp delivery status + status events
```

---

## 7. Business Rules

| Rule ID | Description |
|---|---|
| BR-COM-001 | SMS messages MUST use a DLT-registered template. Ad-hoc free-text SMS dispatch is not permitted (TRAI compliance). Template body reconstruction must match the registered skeleton exactly before dispatch. |
| BR-COM-002 | Emergency alerts BYPASS `com_user_preferences` — all targeted users receive regardless of any channel opt-out. The `emergency` preference category is always `is_opted_in = 1` and cannot be modified by users. |
| BR-COM-003 | WhatsApp messages MUST use a Meta-approved template with `approval_status = 'approved'`. Unapproved or paused templates cannot be dispatched; return HTTP 422. |
| BR-COM-004 | Circular acknowledgement is only permitted for users who appear in the circular's `com_circular_targets_jnt` audience (resolved dynamically for auto-sync target types). |
| BR-COM-005 | A user cannot acknowledge the same circular twice — enforced by UNIQUE KEY on `com_circular_acknowledgements (circular_id, user_id)`. Second attempt returns HTTP 422. |
| BR-COM-006 | `scheduled_at` must be at least 2 minutes in the future at save time. Past or near-past datetimes are rejected with a validation error. |
| BR-COM-007 | Bulk SMS CSV upload: max 5,000 rows. Rows beyond this limit cause entire upload rejection before any processing begins. |
| BR-COM-008 | In-app message body must be sanitized (HTMLPurifier or equivalent) before storage. Raw `<script>`, `<iframe>`, `javascript:` href values, and inline event handlers must be stripped. |
| BR-COM-009 | Auto-sync groups (`auto_sync = 1`) cannot have manual member entries in `com_group_members_jnt`. Attempting manual member add returns HTTP 422. |
| BR-COM-010 | A message can only be cancelled if `status IN ('draft', 'scheduled')` AND `sent_at IS NULL`. Cancellation of a dispatching or sent message is rejected. |
| BR-COM-011 | Delivery retry: maximum 3 attempts per recipient. Schedule: +1 min, +5 min, +15 min. After 3 failures, `delivery_status = 'failed'`, no further retries. |
| BR-COM-012 | Circular `expiry_date` must be >= `issued_date` if provided. Violation returns HTTP 422. |
| BR-COM-013 | Teachers can only send in-app messages to parents of students enrolled in their assigned class/section(s). Cross-class messaging by teachers returns HTTP 403. |
| BR-COM-014 | Message template `body_template` must contain at least one `{{variable}}` placeholder if `variables_json` is non-empty. Mismatch caught at template save validation. |
| BR-COM-015 | Emergency alert dispatch requires two-step confirmation: POST `/emergency/preview` first, then POST `/emergency/confirm` with returned `alert_id`. Single-step dispatch endpoint does not exist. |
| BR-COM-016 | DLT `{#var#}` variable values must not exceed declared `max_length` per variable position. Over-length values are truncated with a dispatch warning logged to `sys_activity_logs`. |
| BR-COM-017 | WhatsApp delivery webhook must be verified with HMAC-SHA256 using `webhook_token_encrypted` before processing. Unverified webhooks return HTTP 403 and are logged. |
| BR-COM-018 | `com_message_recipients_jnt` rows created synchronously for campaigns up to 500 recipients. Campaigns > 500 use `PrepareRecipientsJob` (async); message status stays `dispatching` until job completes. |

---

## 8. Authorization and RBAC

### 8.1 Permission Registry

All permissions prefixed with `com.`, registered via `sys_permissions`. Gate definitions in `CommunicationServiceProvider` use `tenant.*` gate prefix (not `prime.*`).

| Permission | Description |
|---|---|
| `com.dashboard.view` | View communication dashboard and analytics |
| `com.circular.create` | Create and distribute circulars |
| `com.circular.view` | View circulars targeted at own role/class |
| `com.circular.view_all` | View all circulars regardless of targeting |
| `com.circular.acknowledge` | Acknowledge circulars |
| `com.circular.remind` | Send acknowledgement reminders |
| `com.email.compose` | Compose and send email campaigns |
| `com.email.configure_gateway` | Configure email sending gateway |
| `com.sms.compose` | Compose and send SMS campaigns |
| `com.sms.configure_gateway` | Configure SMS gateway and DLT templates |
| `com.whatsapp.compose` | Compose and send WhatsApp messages |
| `com.whatsapp.configure` | Configure WhatsApp gateway and templates |
| `com.message.send` | Send in-app messages |
| `com.message.reply` | Reply to in-app messages |
| `com.message.flag` | Flag in-app messages as inappropriate |
| `com.message.moderate` | Review and resolve flagged messages |
| `com.push.send` | Trigger push notification campaigns |
| `com.group.manage` | Create/edit/delete communication groups |
| `com.template.manage` | Create/edit/delete message templates |
| `com.emergency.send` | Trigger emergency alert broadcasts |
| `com.recurring.manage` | Create/edit/delete recurring rules |
| `com.settings.manage` | Modify Communication module settings |
| `com.reports.view` | View communication reports and analytics |
| `com.preferences.manage` | Manage own notification preferences |

### 8.2 Role-Permission Matrix

| Permission | School Admin | Principal | Class Teacher | Subject Teacher | Parent | Student |
|---|---|---|---|---|---|---|
| `com.dashboard.view` | Yes | Yes | — | — | — | — |
| `com.circular.create` | Yes | Yes | — | — | — | — |
| `com.circular.view` | Yes | Yes | Yes (own class) | Yes (own class) | Yes (targeted) | Yes (targeted) |
| `com.circular.view_all` | Yes | Yes | — | — | — | — |
| `com.circular.acknowledge` | Yes | Yes | Yes | Yes | Yes | Yes |
| `com.circular.remind` | Yes | Yes | — | — | — | — |
| `com.email.compose` | Yes | Yes | — | — | — | — |
| `com.email.configure_gateway` | Yes | — | — | — | — | — |
| `com.sms.compose` | Yes | Yes | — | — | — | — |
| `com.sms.configure_gateway` | Yes | — | — | — | — | — |
| `com.whatsapp.compose` | Yes | Yes | — | — | — | — |
| `com.whatsapp.configure` | Yes | — | — | — | — | — |
| `com.message.send` | Yes | Yes | Yes | Yes | configurable | — |
| `com.message.reply` | Yes | Yes | Yes | Yes | Yes | Yes |
| `com.message.flag` | Yes | Yes | Yes | Yes | Yes | Yes |
| `com.message.moderate` | Yes | Yes | — | — | — | — |
| `com.push.send` | Yes | Yes | — | — | — | — |
| `com.group.manage` | Yes | — | — | — | — | — |
| `com.template.manage` | Yes | — | — | — | — | — |
| `com.emergency.send` | Yes | Yes | — | — | — | — |
| `com.recurring.manage` | Yes | — | — | — | — | — |
| `com.settings.manage` | Yes | — | — | — | — | — |
| `com.reports.view` | Yes | Yes | — | — | — | — |
| `com.preferences.manage` | Yes | Yes | Yes | Yes | Yes | Yes |

### 8.3 Policy Classes

| Policy | Key Checks |
|---|---|
| 📐 `CircularPolicy` | create: `com.circular.create`; view: targeting check for non-admin; acknowledge: audience membership |
| 📐 `MessagePolicy` | send: `com.message.send` + class-scope check for teachers; view: participant or admin |
| 📐 `MessageFlagPolicy` | flag: any authenticated user; resolve: `com.message.moderate` |
| 📐 `EmergencyAlertPolicy` | create: `com.emergency.send`; confirm: must own the pending preview record |
| 📐 `GroupPolicy` | CUD: `com.group.manage`; view: any authenticated |
| 📐 `MessageTemplatePolicy` | CUD: `com.template.manage`; `is_system = 1` templates cannot be deleted |
| 📐 `GatewayConfigPolicy` | Checks type-specific permission per gateway_type |
| 📐 `DltTemplatePolicy` | CUD: `com.sms.configure_gateway` |
| 📐 `WhatsAppTemplatePolicy` | CUD: `com.whatsapp.configure` |
| 📐 `RecurringRulePolicy` | CUD: `com.recurring.manage` |
| 📐 `PreferencePolicy` | manage: own preferences only; emergency category always opted-in |
| 📐 `CommunicationReportPolicy` | view: `com.reports.view` |
| 📐 `EventTriggerRulePolicy` | manage: `com.settings.manage`; `is_system = 1` rules cannot be deleted |

---

## 9. Message Delivery Pipeline

### 9.1 Message Status State Machine

All `com_messages.status` transitions are enforced by `CommunicationService` — invalid transitions throw `InvalidMessageStateException`.

```
[form saved]          [scheduled_at set]      [scheduled_at <= NOW or immediate send]
    │                       │                              │
    ▼                       ▼                              │
  DRAFT ──────────► SCHEDULED ──────────────────────────► │
    │                                                      │
    │ [send immediately]                                   │
    └─────────────────────────────────────────────────────►
                                                           │
                                           ┌───────────────▼──────────────┐
                                           │         DISPATCHING           │
                                           │  (recipients queued/sending)  │
                                           └──────┬──────────┬─────────────┘
                                                  │          │
                                  [all completed] │          │ [some failed]
                                                  ▼          ▼
                                                SENT    PARTIAL_FAILURE
                                  [all failed] ──────────────► FAILED

  SCHEDULED ─────────────────────────────────────────────────► CANCELLED
  (only if sent_at IS NULL)
```

Valid transitions:
- `draft` → `scheduled` | `dispatching`
- `scheduled` → `dispatching` | `cancelled`
- `dispatching` → `sent` | `partial_failure` | `failed`

Terminal states (no further transitions): `sent`, `partial_failure`, `failed`, `cancelled`

### 9.2 Recipient Delivery Status State Machine

Per `com_message_recipients_jnt.delivery_status`:

```
  [recipients created]
         │
         ▼
      QUEUED ───────────────────────────────────────────► SKIPPED
         │                                    [opted_out / dnd_registered /
         │ [job processes record,              no_fcm_token / invalid_number]
         │  calls gateway API]
         ▼
    DISPATCHED
         │
         ├────────────────────────────────► DELIVERED
         │  [gateway/webhook confirms]           │
         │                                       │ [recipient opens msg,
         │                                       │  in-app read receipt]
         │                                       ▼
         │                                     READ
         │
         ├────────────────────────────────► FAILED
         │  [gateway error / timeout]           │
         │                                      ├─ [retry_count < 3] → back to QUEUED
         │                                      │   (after backoff: 1min/5min/15min)
         │                                      └─ [retry_count = 3] → stays FAILED
         │
         └────────────────────────────────► BOUNCED
            [email hard bounce or
             permanent SMS failure code]
```

Terminal states: `DELIVERED`, `READ`, `FAILED` (max retries), `SKIPPED`, `BOUNCED`

### 9.3 Channel Pipeline Details

#### SMS Pipeline
1. `SmsService::dispatch(Message $message)` — retrieve `com_gateway_configs` for `sms`
2. Resolve phone numbers from `com_message_recipients_jnt`
3. DND filter: if `sms_dnd_filter = 1`, call gateway DND scrub API; mark excluded as `SKIPPED` / `dnd_registered`
4. DLT body reconstruction: iterate `{#var#}` positions in `dlt_template.body_template`, substitute from `merge_values_json` in order; validate reconstructed body length
5. Dispatch `SmsDispatchJob` to `communications` queue (or `emergency` queue if `is_emergency = 1`)
6. Job calls gateway API with DLT Template ID in header (`X-DLT-TemplateId`), Sender ID, Entity ID
7. Store `gateway_message_id` from response, set `delivery_status = 'dispatched'`
8. Webhook or `DeliveryStatusPollerJob` updates final status

#### Email Pipeline
1. `EmailService::dispatch(Message $message)` — retrieve `com_gateway_configs` for `email`
2. Build Laravel `Mailable` with dynamic transport from gateway config (SMTP credentials or API key)
3. Render Blade template with `merge_values_json`; inline CSS with Emogrifier
4. Inject tracking pixel per recipient if `email_tracking_pixel = 1`
5. Dispatch `EmailDispatchJob` to `communications` queue in batches of 50
6. On bounce webhook, set `delivery_status = 'bounced'`, store bounce reason

#### Push Pipeline
1. `CommunicationService::dispatchPush()` resolves target user IDs
2. Apply `com_user_preferences` filter (skip if `emergency`)
3. Exclude users without FCM tokens — log as `SKIPPED` / `no_fcm_token`
4. Call `NotificationService::dispatchBulkPush(userIds, title, body, data)` — PHP service call
5. Log result in `com_message_recipients_jnt`

#### In-App Pipeline
1. `InAppMessageService::store()` — creates `com_messages` + `com_message_recipients_jnt` rows synchronously
2. `delivery_status` immediately `delivered` (no external gateway)
3. Triggers push companion notification via Notification module (if user has FCM token + category opted in)
4. Read receipt: `POST /messages/{id}/read` → `is_read = 1`, `read_at = NOW()`, `delivery_status = 'read'`

#### WhatsApp Pipeline
1. `WhatsAppService::dispatch()` — fetch approved `com_whatsapp_templates` record
2. Build Meta message payload: assemble `components` array from `components_json` + resolved variable values
3. Dispatch `WhatsAppDispatchJob` to `communications` queue
4. Call Meta Cloud API `POST /{phone_number_id}/messages` (or BSP base_url)
5. Store `wamid` as `gateway_message_id`, set status `dispatched`
6. WhatsApp webhook: `sent` → `dispatched`, `delivered` → `delivered`, `read` → `read`, `failed` → `failed`

### 9.4 Emergency Alert Pipeline

```
Admin composes
     │
     ▼
POST /emergency/preview
→ Creates com_emergency_alerts with status='pending_confirmation'
→ Returns {alert_id, preview_html}
     │
     ▼ Admin reviews preview
POST /emergency/confirm  (with alert_id)
→ status='dispatching', confirmed_at=NOW()
     │
     ▼ EmergencyAlertService::dispatch()
     ├─ SmsDispatchJob        → emergency queue (priority HIGH)
     ├─ EmailDispatchJob      → emergency queue ([URGENT] prefix in subject)
     ├─ NotificationService   → dispatchBulkPush() synchronous call
     └─ InAppMessageService   → store() synchronous call
     │
     ▼ (1 minute later)
EmergencyAlertStatusJob
→ Aggregates per-channel delivery counts into delivery_stats_json
→ Sets final status: sent / partial_failure / failed
```

All 4 channels fire in parallel — SMS/Email via queued jobs, Push/In-App synchronous to minimize latency.

---

## 10. Service Layer Architecture

### 10.1 Services

| Service | Path | Responsibility |
|---|---|---|
| 📐 `CommunicationService` | `Services/CommunicationService.php` | Orchestrator: resolve recipients, apply preference filters, route to channel-specific services, coordinate dispatch |
| 📐 `CircularService` | `Services/CircularService.php` | Circular CRUD, target audience resolution, acknowledgement management, reminder dispatch, deadline reporting |
| 📐 `SmsService` | `Services/SmsService.php` | DLT template body reconstruction, phone validation, DND filtering, gateway HTTP calls (MSG91/Twilio/Kaleyra adapter pattern) |
| 📐 `EmailService` | `Services/EmailService.php` | Template rendering (Blade), CSS inlining (Emogrifier), tracking pixel injection, Laravel Mail dynamic transport dispatch |
| 📐 `WhatsAppService` | `Services/WhatsAppService.php` | Meta Cloud API + BSP integration, template component assembly, HMAC-SHA256 webhook verification |
| 📐 `InAppMessageService` | `Services/InAppMessageService.php` | Message store/update, reply threading, read receipts, unread count queries, auto-hide on flag threshold |
| 📐 `EmergencyAlertService` | `Services/EmergencyAlertService.php` | Two-step confirmation flow, multi-channel parallel dispatch, preference bypass enforcement, delivery stats aggregation |
| 📐 `CommunicationGroupService` | `Services/CommunicationGroupService.php` | Group CRUD, dynamic membership resolution for auto-sync types, manual member management, count cache updates |
| 📐 `CommunicationEventService` | `Services/CommunicationEventService.php` | Public event trigger API (called by other modules), `com_event_trigger_rules` lookup, audience resolver dispatch, scheduled offset calculation |
| 📐 `DndFilterService` | `Services/DndFilterService.php` | Gateway DND scrub API calls, local DND cache (Redis/DB), log skipped numbers |
| 📐 `CommunicationReportService` | `Services/CommunicationReportService.php` | All report generation — PDF via DomPDF, CSV via fputcsv, for delivery/acknowledgement/SMS-usage/emergency/preference reports |

### 10.2 Jobs

| Job | Queue | Trigger | Responsibility |
|---|---|---|---|
| 📐 `ProcessScheduledMessagesJob` | `communications` | Every 5 min (Laravel Scheduler) | Dispatch up to 100 due `scheduled` messages per run |
| 📐 `ProcessRecurringRulesJob` | `communications` | Every 15 min | Dispatch due recurring rules, compute next `next_scheduled_at` |
| 📐 `DeliveryStatusPollerJob` | `communications` | Every 15 min | Poll gateway for `dispatched` records older than 15 min and younger than 24 h |
| 📐 `SyncCommunicationGroupsJob` | `communications` | Daily midnight | Refresh `member_count_cache` for all auto-sync groups |
| 📐 `CircularDeadlineJob` | `communications` | Daily 8 AM | Email acknowledgement summary to Principal for past-deadline circulars |
| 📐 `SmsDispatchJob` | `communications` / `emergency` | On-demand | Batch SMS dispatch to gateway, retry handling |
| 📐 `EmailDispatchJob` | `communications` / `emergency` | On-demand | Batch email dispatch via Laravel Mail, bounce handling |
| 📐 `WhatsAppDispatchJob` | `communications` | On-demand | Batch WhatsApp dispatch via Meta Cloud API |
| 📐 `PrepareRecipientsJob` | `communications` | On-demand | Create `com_message_recipients_jnt` rows for campaigns > 500 recipients |

### 10.3 Controllers

| Controller | Routes Handled |
|---|---|
| 📐 `DashboardController` | Dashboard, summary widgets |
| 📐 `CircularController` | Circular CRUD, acknowledge, remind, export |
| 📐 `EmailCampaignController` | Email compose, send, logs, gateway config |
| 📐 `SmsCampaignController` | SMS compose, send, logs, gateway, DLT templates |
| 📐 `WhatsAppController` | WhatsApp compose, gateway, templates |
| 📐 `InAppMessageController` | Messages CRUD, reply, read |
| 📐 `MessageModerationController` | Flag list, resolve actions |
| 📐 `EmergencyAlertController` | Compose, preview, confirm, history |
| 📐 `CommunicationGroupController` | Group CRUD, members, sync |
| 📐 `MessageTemplateController` | Template CRUD, translations |
| 📐 `RecurringRuleController` | Recurring rule CRUD, toggle |
| 📐 `PreferenceController` | User preference matrix, save, reset |
| 📐 `ReportController` | All report generation |
| 📐 `WebhookController` | SMS and WhatsApp webhooks |
| 📐 `Api/CircularApiController` | Mobile circular endpoints |
| 📐 `Api/MessageApiController` | Mobile in-app message endpoints |
| 📐 `Api/PreferenceApiController` | Mobile preference endpoints |
| 📐 `Api/EmergencyApiController` | Mobile emergency alert display |

### 10.4 Models

| Model | Table | Key Relationships |
|---|---|---|
| 📐 `GatewayConfig` | `com_gateway_configs` | — |
| 📐 `DltTemplate` | `com_sms_dlt_templates` | hasMany Messages |
| 📐 `MessageTemplate` | `com_message_templates` | hasMany Translations; belongsTo self (parent); hasMany RecurringRules |
| 📐 `MessageTemplateTranslation` | `com_message_template_translations` | belongsTo MessageTemplate |
| 📐 `WhatsAppTemplate` | `com_whatsapp_templates` | belongsTo MessageTemplate |
| 📐 `Group` | `com_groups` | hasMany GroupMembers; belongsTo Class; belongsTo Section |
| 📐 `GroupMember` | `com_group_members_jnt` | belongsTo Group; belongsTo User |
| 📐 `Message` | `com_messages` | hasMany Recipients; belongsTo User (sender); belongsTo self (parent); belongsTo MessageTemplate; belongsTo DltTemplate |
| 📐 `MessageRecipient` | `com_message_recipients_jnt` | belongsTo Message; belongsTo User |
| 📐 `Circular` | `com_circulars` | hasMany CircularTargets; hasMany Acknowledgements; belongsTo User (issuedBy) |
| 📐 `CircularTarget` | `com_circular_targets_jnt` | belongsTo Circular |
| 📐 `CircularAcknowledgement` | `com_circular_acknowledgements` | belongsTo Circular; belongsTo User |
| 📐 `EmergencyAlert` | `com_emergency_alerts` | belongsTo User (triggeredBy); belongsTo Message |
| 📐 `MessageFlag` | `com_message_flags` | belongsTo Message; belongsTo User (flaggedBy/reviewedBy) |
| 📐 `RecurringRule` | `com_recurring_rules` | belongsTo MessageTemplate; belongsTo Group |
| 📐 `UserPreference` | `com_user_preferences` | belongsTo User |
| 📐 `EventTriggerRule` | `com_event_trigger_rules` | belongsTo MessageTemplate |
| 📐 `SchoolSetting` | `com_school_settings` | (accessed via `CommunicationSettings` facade) |

---

## 11. Integration Points

### 11.1 Inbound: Modules That Trigger Communications

These modules call `CommunicationEventService::trigger(eventKey, context[])` to fire communications without coupling to channel-specific implementation.

| Module | Event Key | Trigger Condition | Default Channels | Audience |
|---|---|---|---|---|
| **StudentFee** | `fee.due_reminder` | 7 days and 1 day before fee due date | SMS + Email | Parents of students with pending fees |
| **StudentFee** | `fee.overdue_notice` | 1 day after due date if unpaid | SMS | Parents of overdue students |
| **StudentFee** | `fee.receipt_issued` | Immediately on payment confirmed | Email | Paying parent |
| **Attendance** | `attendance.absent_alert` | Same day at 4 PM if student marked absent | SMS + Push | Parents of absent students |
| **Attendance** | `attendance.low_attendance` | Weekly check if attendance < school threshold | Email | Parents of low-attendance students |
| **Examination** | `exam.timetable_released` | Immediately when exam timetable published | Email + Push | All parents + students of affected classes |
| **Examination** | `exam.result_published` | Immediately when results published | Push + In-App | Affected parents + students |
| **Events/Calendar** | `ptm.reminder` | 7 days and 1 day before PTM date | SMS + Email | All parents |
| **Admission** | `admission.welcome` | Immediately on admission confirmation | Email | New student's parent |
| **Homework (LMS)** | `homework.assigned` | Immediately on homework published | Push + In-App | Students of affected class/section |
| **Hostel** | `hostel.fee_due` | 7 days before hostel fee due | SMS + Email | Hostel students' parents |

### 11.2 Outbound: Modules Communication Calls

| Dependency | Direction | What COM Calls |
|---|---|---|
| **Notification module** (`ntf_*`) | COM → NTF | `NotificationService::dispatchBulkPush()` for all push channel deliveries; reads `ntf_user_devices` for FCM tokens |
| **System Media** (`sys_media`) | COM → Media | Stores and retrieves circular/message file attachments; resolves download URLs |
| **Auth** (`sys_users`) | COM reads | Sender identity, recipient phone/email, role assignments |
| **SchoolSetup** (`sch_classes`, `sch_sections`) | COM reads | Class/section audience resolution |
| **StudentMgmt** (`std_students`, `std_student_parents_jnt`) | COM reads | Parent-of-student relationship for class-level parent targeting |
| **Audit** (`sys_activity_logs`) | COM writes | Logs all message dispatches, emergency alerts, gateway config changes |

### 11.3 Event Trigger Contract (Inbound Interface)

Any module can fire a communication by calling:

```php
use Modules\Communication\Services\CommunicationEventService;

// Injected via DI or resolved from container
$eventService->trigger('fee.due_reminder', [
    'student_id'   => 1234,
    'amount'       => 5500.00,
    'due_date'     => '2026-04-01',
    'academic_year' => '2025-26',
]);
```

Contract rules:
- `CommunicationEventService` looks up all active `com_event_trigger_rules` matching `event_key`
- For each matching rule, resolves audience via the rule's `audience_resolver` class (e.g., `FeeReminderAudienceResolver::resolve($context)` returns user IDs)
- Merges `context` array into `merge_values_json` for template rendering
- Applies `offset_days` / `offset_direction` to set `scheduled_at` (immediate if `offset_direction = 'immediate'`)
- Creates a `com_messages` record per channel per rule and queues dispatch
- Returns array of created `com_messages` IDs (calling module can log/ignore)

### 11.4 Notification Module Dependency Details

The Notification module provides the FCM device token registry (`ntf_user_devices`) and FCM dispatch infrastructure. Communication module never directly reads FCM tokens or calls FCM APIs — all push is delegated to `NotificationService`.

Before the Communication module can use push notifications:
1. Notification module routes must be un-commented and working (Section 12)
2. `NotificationService` must expose a public `dispatchBulkPush(array $userIds, string $title, string $body, array $data = [])` method
3. `ntf_user_devices` table must be populated via the mobile app's device registration flow

---

## 12. Notification Module Relationship and Gap Fixes

### 12.1 Identified Gaps in Existing Notification Module

The Notification module (`ntf_*`) was audited as part of V2 planning. The following gaps must be resolved before the Communication module can be fully operational:

| Gap ID | File/Location | Issue | Fix Required |
|---|---|---|---|
| NTF-GAP-001 | `CommunicationServiceProvider.php` (and all ntf_* policies) | Gate prefix uses `prime.*` instead of `tenant.*` | Global find-replace `Gate::define('prime.ntf.*'` → `Gate::define('tenant.ntf.*'` across all Notification module files |
| NTF-GAP-002 | `routes/tenant.php` (Notification section) | All ntf_* routes are commented out — module is completely inaccessible | Uncomment routes; verify each controller method exists before uncommenting |
| NTF-GAP-003 | `ntf_channels` table (SMS row) | SMS channel `config_json` is an empty stub `{}` | Populate with required fields: `{gateway_type, api_key_field, sender_id_field, dlt_entity_id_field}` |
| NTF-GAP-004 | `ntf_channels` table (Push row) | FCM channel `config_json` is a stub | Populate with `{fcm_server_key_field, fcm_project_id_field}` |
| NTF-GAP-005 | `NotificationService.php` | `dispatchSms()` and `dispatchPush()` are stubs returning `true` without actual dispatch | Implement real gateway calls; COM module depends on `dispatchBulkPush()` being functional |
| NTF-GAP-006 | `ntf_deliveries` table | No `polling_until` column — delivery status polling cannot track expiry | `ALTER TABLE ntf_deliveries ADD COLUMN polling_until TIMESTAMP NULL DEFAULT NULL` |
| NTF-GAP-007 | `ntf_templates` seeder | Email channel partial — many template types missing for standard school events | Seed required templates for: fee_reminder, attendance_alert, exam_timetable, ptm_reminder, homework_assigned |

### 12.2 Notification Module Route Re-enablement Plan

The commented-out ntf_* routes must be re-enabled in a specific order to avoid runtime errors:

**Phase 1 — Core (enable first):**
1. `ntf_channels` CRUD routes (prerequisite for all notification config)
2. `ntf_templates` CRUD routes (prerequisite for event-triggered notifications)
3. `ntf_targets` CRUD routes

**Phase 2 — Delivery:**
4. `ntf_notifications` index/show routes
5. `ntf_deliveries` status routes

**Phase 3 — User-facing:**
6. `ntf_user_preferences` routes
7. `ntf_user_devices` registration routes (required for push)

Each phase should be enabled and smoke-tested before proceeding to the next.

### 12.3 Communication vs Notification — Responsibility Boundary

| Responsibility | Communication Module | Notification Module |
|---|---|---|
| Human-authored messages | YES | — |
| Automated system event notifications | — | YES |
| SMS dispatch (human-authored campaigns) | YES (SmsService) | — |
| SMS dispatch (automated events via trigger) | YES (via CommunicationEventService) | — |
| FCM device token management | — (reads ntf_user_devices) | YES |
| FCM push dispatch | — (calls NotificationService) | YES |
| Email sending (human campaigns) | YES (EmailService) | — |
| Email sending (automated events) | YES (via event trigger) | YES (for system events like password reset) |
| User delivery preferences | YES (com_user_preferences, per category) | YES (ntf_user_preferences, per channel globally) |
| Template management (COM channels) | YES (com_message_templates) | — |
| Template management (NTF events) | — | YES (ntf_templates) |
| Circular/Notice board | YES | — |
| Emergency alerts | YES | — |
| In-app messaging | YES | — |

The key rule: if a human is composing or approving the message → Communication module. If the system fires it automatically on a database event → Notification module.

---

## 13. Non-Functional Requirements

### 13.1 Performance

| Requirement | Target |
|---|---|
| Bulk dispatch for up to 5,000 recipients | Fully async via queue; HTTP request returns in < 2 seconds after queuing |
| Emergency alert dispatch begin time | Within 30 seconds of confirmation (measured from `confirmed_at`) |
| Circular notice board page load | < 2 seconds for up to 100 active circulars |
| In-app message list load | < 500 ms per user |
| SMS batch throughput | Configurable via `max_per_second`; default 10 SMS/second |
| Unread count API endpoint | < 100 ms (indexed query on `com_message_recipients_jnt`) |

### 13.2 Scalability

- All bulk dispatch operations queued via Laravel Queue with dedicated `communications` worker
- Emergency alerts use separate `emergency` queue worker for isolation
- Batch size: SMS 100/batch, Email 50/batch, WhatsApp 50/batch
- For campaigns > 500 recipients: `PrepareRecipientsJob` creates `com_message_recipients_jnt` rows async, preventing timeout on large schools
- `com_message_recipients_jnt` will be the largest table — partition by `created_at` (monthly) recommended after 1M rows
- `member_count_cache` on `com_groups` avoids COUNT queries on every group list load

### 13.3 Security

- SMS gateway API keys, WhatsApp access tokens, SMTP passwords — all encrypted at rest using Laravel `encrypt()` (AES-256-CBC)
- DLT Sender ID and Entity ID validated against gateway on save; mismatch flagged immediately
- In-app message body sanitized with HTMLPurifier before storage and before render
- Webhook endpoints use HMAC-SHA256 signature verification (not IP allowlisting alone)
- No cross-tenant data access — stancl/tenancy enforces DB isolation; all queries scoped to tenant_db
- CSV upload: MIME type validation (`text/csv`, `text/plain`), max file size 5MB, rows sanitized before processing
- Rate limiting on webhook endpoints: 1000 requests/minute per IP via Laravel throttle middleware
- Emergency alert `confirmed_at` IP and user agent logged in `sys_activity_logs`

### 13.4 TRAI/DLT Compliance

- All bulk and transactional SMS must use DLT-registered templates (mandatory for India since 2021)
- Variable substitution must not introduce words outside the registered template skeleton
- DLT Template ID (`X-DLT-TemplateId`), Sender ID, and Entity ID must be included in every SMS API call header
- DND (Do Not Disturb) numbers must be filtered before dispatch (NCPR compliance) — `DndFilterService` handles this
- Variable value over-length: truncate + warn (do not reject entire campaign for one recipient's data issue)

### 13.5 Reliability

- Delivery status polling fallback: if gateway webhook is missed, `DeliveryStatusPollerJob` polls every 15 minutes for up to 24 hours
- Retry on transient failures: 3 attempts with exponential backoff (1 min → 5 min → 15 min)
- Emergency alerts: dedicated `emergency` queue worker that does NOT process normal `communications` queue (queue isolation prevents large campaigns blocking emergencies)
- `ProcessScheduledMessagesJob` uses a database-level lock (via `withoutOverlapping()`) to prevent concurrent execution
- Job failure notifications: all failed jobs in `communications` queue logged to `sys_activity_logs` and alert sent to Admin

### 13.6 Audit

- Every message dispatch logged to `sys_activity_logs`: `{model: com_messages, action: dispatched, channel, recipient_count, sender_id}`
- Emergency alert confirmation logged with IP + user agent
- Gateway config changes logged: `{model: com_gateway_configs, action: updated, changed_fields[]}`
- Failed delivery attempts logged per recipient in `com_message_recipients_jnt.failure_reason`
- DND filter skips logged in `com_message_recipients_jnt.skip_reason = 'dnd_registered'`

---

## 14. Test Coverage

### 14.1 Proposed Test Cases

| Test Class | Type | Description |
|---|---|---|
| 📐 `CircularCreationTest` | Feature | Create circular with audience targets; verify `com_circular_targets_jnt` rows; check visibility for targeted/non-targeted users |
| 📐 `CircularAcknowledgementTest` | Feature | Targeted user acknowledges; record created with correct `acknowledged_at`; non-targeted user gets 403 |
| 📐 `DuplicateAcknowledgementTest` | Feature | Second acknowledgement attempt returns 422; only one row in DB |
| 📐 `CircularExpiryTest` | Unit | Active circulars query excludes expired (past `expiry_date`) and future (future `issued_date`) |
| 📐 `SmsGatewayConfigTest` | Feature | Store config; verify API key encrypted at rest; test-SMS endpoint mocks gateway and returns success |
| 📐 `DltTemplateSubstitutionTest` | Unit | `SmsService::reconstructBody()` correctly replaces all `{#var#}` in order; over-length value truncated |
| 📐 `BulkSmsCsvValidationTest` | Feature | Upload CSV with mix of valid/invalid rows; confirm valid rows queued; invalid rows CSV returned |
| 📐 `BulkSmsCsvLimitTest` | Feature | Upload CSV with 5,001 rows; expect 422 before any row processing |
| 📐 `ScheduledMessageDispatchTest` | Feature | Message with `scheduled_at` in past dispatched by job; future message not yet dispatched |
| 📐 `ScheduledMessageCancelTest` | Feature | Cancel scheduled message; `status = 'cancelled'`; no dispatch occurs on next job run |
| 📐 `EmergencyAlertTwoStepTest` | Feature | Alert cannot be dispatched without `/emergency/confirm`; confirmed alert fires on all selected channels |
| 📐 `EmergencyAlertBypassPreferencesTest` | Feature | User with all channels opted out still receives emergency alert on all channels |
| 📐 `InAppMessageReadReceiptTest` | Feature | Mark message read via API; `is_read = 1`, `read_at` set; unread count decremented |
| 📐 `InAppMessageThreadTest` | Feature | Reply creates new message with `parent_message_id`; thread view returns all messages in order |
| 📐 `MessageFlagModerationTest` | Feature | User flags message; admin sees flag; admin resolves as `delete_message`; message soft-deleted |
| 📐 `MessageAutoHideTest` | Feature | When flag count reaches `auto_hide_flag_count`, message hidden without admin action |
| 📐 `AutoSyncGroupTest` | Feature | Auto-sync group for Class 5A dynamically returns all parents of Class 5A students; manual member add returns 422 |
| 📐 `RecurringRuleDispatchTest` | Feature | Recurring rule with daily recurrence dispatches on due run; `last_sent_at` updated; `next_scheduled_at` advanced 1 day |
| 📐 `UserPreferenceFilterTest` | Feature | User opts out of SMS for `fee_reminder`; SMS dispatch job skips that user; `delivery_status = 'skipped'` with `skip_reason = 'opted_out'` |
| 📐 `UserPreferenceEmergencyTest` | Unit | `UserPreference` model: `emergency` category `is_opted_in` cannot be set to `0`; setter silently keeps `1` |
| 📐 `EventTriggerRuleTest` | Feature | Call `CommunicationEventService::trigger('fee.due_reminder', context)`; verify `com_messages` records created per matching rule; audience resolver called with context |
| 📐 `DeliveryRetryTest` | Feature | Mark recipient as failed; `DeliveryStatusPollerJob` re-queues with `retry_count = 1`; after 3 failures record stays `failed` |

### 14.2 Test Infrastructure Notes

- All Feature tests use `Tests\TestCase` with `RefreshDatabase` and `WithFaker`
- Tenant context injected via `$this->actingAs($user)` within tenant DB scope using `tenancy()->initialize($tenant)` in setUp
- Gateway HTTP calls mocked via Laravel HTTP fake: `Http::fake(['api.msg91.com/*' => Http::response(['type' => 'success'], 200)])`
- Email dispatch: `Mail::fake()` — assert `Mail::assertSent(CommunicationMailable::class)`
- Queue assertions: `Queue::fake()` — assert `Queue::assertPushed(SmsDispatchJob::class)`
- FCM calls: mock `NotificationService` via `$this->mock(NotificationService::class)`

---

## 15. Implementation Status

### 15.1 Feature Status Summary

| FR Code | Feature | RBS Sub-Module | Status |
|---|---|---|---|
| FR-COM-001 | SMS Gateway Configuration | N1 | ❌ Not Started |
| FR-COM-002 | DLT Template Registration | N1 | ❌ Not Started |
| FR-COM-003 | Compose and Send SMS Campaign | N1 | ❌ Not Started |
| FR-COM-004 | Bulk SMS via CSV Upload | N1 | ❌ Not Started |
| FR-COM-005 | SMS Delivery Tracking and Webhook | N1 | ❌ Not Started |
| FR-COM-006 | Email Sending Configuration | N2 | ❌ Not Started |
| FR-COM-007 | Compose and Send Email Campaign | N2 | ❌ Not Started |
| FR-COM-008 | Email Template Management | N2 | ❌ Not Started |
| FR-COM-009 | Recurring Email Rules | N2 | ❌ Not Started |
| FR-COM-010 | Communication-Initiated Push Notifications | N3 | ❌ Not Started |
| FR-COM-011 | One-to-One Direct Messaging | N4 | ❌ Not Started |
| FR-COM-012 | Group Messaging | N4 | ❌ Not Started |
| FR-COM-013 | Message Moderation and Flagging | N4 | ❌ Not Started |
| FR-COM-014 | Create and Distribute Circular | N5 | ❌ Not Started |
| FR-COM-015 | Circular Acknowledgement Tracking | N5 | ❌ Not Started |
| FR-COM-016 | Notice Board Display | N5 | ❌ Not Started |
| FR-COM-017 | Emergency Alert Broadcast | N6 | ❌ Not Started |
| FR-COM-018 | Emergency Alert Delivery Tracking | N6 | ❌ Not Started |
| FR-COM-019 | User Notification Preference Management | N7 | ❌ Not Started |
| FR-COM-020 | Event-Driven Trigger Contract | N8 | ❌ Not Started |
| FR-COM-021 | Communication Group Management | N4/N5 | ❌ Not Started |
| FR-COM-022 | Group Membership Management | N4/N5 | ❌ Not Started |
| FR-COM-023 | Schedule Messages for Future Delivery | N1-N4 | ❌ Not Started |
| FR-COM-024 | Communication Analytics Dashboard | N1-N8 | ❌ Not Started |
| FR-COM-025 | Communication Reports | N1-N8 | ❌ Not Started |

**Notification Module Prerequisites (tracked separately):**

| Task | Status |
|---|---|
| NTF-GAP-001: Fix gate prefix `prime.*` → `tenant.*` | ❌ Not Started |
| NTF-GAP-002: Uncomment ntf_* routes (phased) | ❌ Not Started |
| NTF-GAP-003: Populate SMS channel config_json | ❌ Not Started |
| NTF-GAP-004: Populate Push channel config_json | ❌ Not Started |
| NTF-GAP-005: Implement SmsService and PushService stubs | ❌ Not Started |
| NTF-GAP-006: Add `polling_until` to ntf_deliveries | ❌ Not Started |
| NTF-GAP-007: Seed standard notification templates | ❌ Not Started |

### 15.2 Code Artifacts — All Proposed (None Exist)

| Artifact | Proposed Path |
|---|---|
| 📐 Module root | `Modules/Communication/` |
| 📐 All Controllers | `Modules/Communication/Http/Controllers/` |
| 📐 All API Controllers | `Modules/Communication/Http/Controllers/Api/` |
| 📐 WebhookController | `Modules/Communication/Http/Controllers/Webhooks/WebhookController.php` |
| 📐 All Services | `Modules/Communication/Services/` |
| 📐 All Models | `Modules/Communication/Models/` |
| 📐 All Jobs | `Modules/Communication/Jobs/` |
| 📐 All Policies | `Modules/Communication/Policies/` |
| 📐 All FormRequests | `Modules/Communication/Http/Requests/` |
| 📐 CommunicationServiceProvider | `Modules/Communication/Providers/CommunicationServiceProvider.php` |
| 📐 Blade views | `Modules/Communication/Resources/views/` |
| 📐 Web routes | `Modules/Communication/Routes/web.php` |
| 📐 API routes | `Modules/Communication/Routes/api.php` |
| 📐 DDL | `1-DDL_Tenant_Modules/XX-Communication/DDL/` |
| 📐 Seeders | `Modules/Communication/Database/Seeders/` |

### 15.3 Seeder Checklist

| Seeder | Contents |
|---|---|
| 📐 `CommunicationPermissionSeeder` | 24 permissions for `com.*` namespace |
| 📐 `MessageTemplateSeed` | 6 default email templates + 4 SMS templates + 2 in-app templates |
| 📐 `EventTriggerRuleSeeder` | 9 default event trigger rules (fee, attendance, exam, PTM, admission, homework) |
| 📐 `CommunicationGroupSeeder` | Auto-sync group definitions (not actual members — auto-resolved at runtime) |
| 📐 `CommunicationSchoolSettingsSeeder` | 6 default school settings |

---

## 16. Development Priorities and Recommendations

### 16.1 Phase 0 — Notification Module Prerequisites (Sprint 0)

Before ANY Communication module work, resolve Notification module gaps:

1. Fix gate prefix bug (NTF-GAP-001) — 1 day; affects all ntf_* permission checks
2. Un-comment Phase 1 routes: channels, templates, targets (NTF-GAP-002) — 1 day
3. Implement `NotificationService::dispatchBulkPush()` with real FCM dispatch (NTF-GAP-005) — 3 days
4. Seed standard notification templates (NTF-GAP-007) — 1 day

**Estimated effort: 6 days.** Block Communication module development until Phase 0 is complete.

### 16.2 Phase 1 — Foundation: Circulars and In-App Messaging (Sprint 1–2)

Highest immediate value; zero external service dependencies.

1. **Database migrations** — all 14 `com_*` tables + seeders — 2 days
2. **Communication Group Management** (FR-COM-021, FR-COM-022) — prerequisite for all bulk sends — 3 days
3. **Circular Management** (FR-COM-014, FR-COM-015, FR-COM-016) — highest demand feature; drives portal adoption — 4 days
4. **In-App Direct Messaging** (FR-COM-011, FR-COM-012) — teacher-parent communication; no external dependencies — 4 days
5. **Message Moderation** (FR-COM-013) — safety feature; concurrent with messaging — 2 days

**Phase 1 deliverable**: Schools can create/distribute/acknowledge circulars and teachers can message parents within the platform.

### 16.3 Phase 2 — SMS Gateway and Email (Sprint 3–4)

Requires school to have DLT registration before testing.

1. **SMS Gateway Config + DLT Templates** (FR-COM-001, FR-COM-002) — configuration prerequisite — 3 days
2. **SMS Compose and Send** (FR-COM-003, FR-COM-004, FR-COM-005) — bulk SMS + delivery tracking — 4 days
3. **Email Gateway Config** (FR-COM-006) — SMTP/SES/Mailgun dynamic transport — 2 days
4. **Email Campaign + Templates** (FR-COM-007, FR-COM-008) — email compose + template versioning — 4 days

**Phase 2 deliverable**: Schools can run SMS and email campaigns with full DLT compliance and delivery tracking.

### 16.4 Phase 3 — Scheduling, Push, and Emergency (Sprint 5)

1. **Message Scheduling** (FR-COM-023) + `ProcessScheduledMessagesJob` — 2 days
2. **Recurring Rules** (FR-COM-009) + `ProcessRecurringRulesJob` — 2 days
3. **Push Notifications** (FR-COM-010) — requires Phase 0 complete — 2 days
4. **User Preferences** (FR-COM-019) — opt-in/out matrix — 2 days
5. **Emergency Alert Broadcast** (FR-COM-017, FR-COM-018) — critical safety feature; thorough testing required — 4 days

**Phase 3 deliverable**: Automated scheduling, push delivery, preference management, and emergency broadcast operational.

### 16.5 Phase 4 — Event Integration, WhatsApp, and Analytics (Sprint 6–7)

1. **Event Trigger Contract** (FR-COM-020) + `CommunicationEventService` — 3 days
2. **StudentFee integration**: fee.due_reminder + fee.overdue_notice + fee.receipt_issued triggers — 2 days (requires StudentFee module cooperation)
3. **Attendance integration**: absent_alert + low_attendance triggers — 1 day
4. **WhatsApp Gateway + Templates** (FR-COM-022, FR-COM-023) — requires WABA approval (start 3–4 weeks before sprint) — 4 days
5. **Analytics Dashboard** (FR-COM-024) + **Reports** (FR-COM-025) — 4 days
6. **Mobile API endpoints** (Section 6.2) — mobile app integration — 3 days

**Phase 4 deliverable**: Full event-driven automation, WhatsApp channel, complete analytics, mobile app ready.

### 16.6 Key Technical Decisions Before Implementation

| Decision | Options | Recommendation |
|---|---|---|
| In-app message recipient materialization | Pre-materialize all rows vs. lazy-resolve at read time | **Pre-materialize up to 500 synchronously; use `PrepareRecipientsJob` above 500.** Lazy resolution creates N+1 risk on read; pre-materialization is simpler and allows per-recipient status tracking. |
| Email open tracking | Tracking pixel (1x1 image) vs. no tracking | **Off by default** (`email_tracking_pixel = 0`). Privacy implications; many email clients block images. Enable only if school explicitly configures it. |
| DND filter caching | No cache vs. Redis cache vs. DB cache | **Redis cache with 6-hour TTL** per phone number. DND status rarely changes intraday; avoid per-SMS API call to DND scrub service. |
| WhatsApp inbound (future) | Webhook receive vs. polling | Design webhook endpoint now (already in route table); don't implement inbound processing yet. Keeps door open for v3 chatbot features without schema changes. |
| Template storage for WhatsApp | Store full components_json vs. link to Meta API | **Store full components_json locally.** Meta API responses can change; local copy ensures rendering stability and avoids runtime API dependency. |

### 16.7 DLT Registration Prerequisites for Schools

Before a school can use the SMS channel, the school admin must complete:

1. Register on TRAI DLT portal (Airtel, Vodafone Idea, Jio, BSNL DLT portals — any registered principal entity)
2. Obtain DLT Entity ID (19-digit principal entity ID)
3. Register Sender ID (6-character alpha) — approval takes 2–7 business days
4. Register each SMS template individually — approval takes 1–3 business days; exact body must match what is stored in `com_sms_dlt_templates`
5. Enter Entity ID, Sender ID, and Template IDs in Prime-AI SMS Gateway Config screen

**Communication module should display a setup checklist** on the SMS configuration page showing which of these steps are completed vs. pending.

### 16.8 WhatsApp Lead Time Warning

WhatsApp Business Account (WABA) setup requires:
- Meta Business Verification: 2–4 weeks
- Phone number registration: 1–3 days
- Template submission and approval: 24–72 hours per template
- BSP onboarding (if using Interakt/Gupshup etc.): 3–7 days

**Schools must begin WABA setup at least 6 weeks before the WhatsApp sprint begins.** The Communication module settings page should show a WhatsApp setup wizard with links to Meta Business Manager and status indicators for each step.
