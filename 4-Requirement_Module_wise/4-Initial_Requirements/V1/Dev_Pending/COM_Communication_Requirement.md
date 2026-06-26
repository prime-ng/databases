# Communication Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** COM | **Module Path:** `Modules/Communication`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `com_*`
**Processing Mode:** RBS-ONLY (Greenfield — No code, DDL, or tests exist)
**RBS Reference:** Module Q — Communication & Messaging (lines 3536–3639)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [API and Routes](#7-api-and-routes)
8. [Business Rules](#8-business-rules)
9. [Authorization and RBAC](#9-authorization-and-rbac)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Test Coverage](#12-test-coverage)
13. [Implementation Status](#13-implementation-status)
14. [Known Issues and Technical Debt](#14-known-issues-and-technical-debt)
15. [Development Priorities and Recommendations](#15-development-priorities-and-recommendations)

---

## 1. Module Overview

The Communication module is the human communication hub for Indian K-12 schools on the Prime-AI SaaS ERP platform. It manages all intentional, human-authored communications — from school circulars and official notices to bulk SMS campaigns, email broadcasts, WhatsApp messages, in-app direct messaging, and emergency alerts. It is deliberately distinct from the Notification module (`ntf_*`), which handles automated system-generated event notifications. The Communication module handles purposeful, authored messages that require composition, audience selection, scheduling, delivery tracking, and acknowledgement workflows.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Communication |
| Module Code | COM |
| nwidart Module Namespace | `Modules\Communication` |
| Module Path | `Modules/Communication` |
| Route Prefix | `communication/` |
| Route Name Prefix | `communication.` |
| DB Table Prefix | `com_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |

### 1.2 Module Scale (Proposed)

| Metric | Proposed Count |
|---|---|
| Controllers | 📐 10 |
| Models | 📐 12 |
| Services | 📐 7 |
| FormRequests | 📐 18 |
| Policies | 📐 10 |
| Browser Tests | 📐 12 |
| DDL Tables | 📐 11 |
| Views | 📐 ~70 Blade templates |

---

## 2. Business Context

### 2.1 Business Purpose

Indian schools are communication-intensive organisations. Parents demand timely updates about academics, fees, events, and emergencies. Teachers need to communicate with parents about student progress. Administration needs to broadcast official notices, government circulars, PTM schedules, and exam timetables. Without a structured communication system, schools rely on informal WhatsApp groups, paper circulars, and phone calls — leading to information loss, non-acknowledgement, and compliance failures.

The Communication module addresses the following specific problems:

1. **Circular and Notice Management**: Schools issue dozens of circulars annually — PTM invitations, holiday notifications, fee due notices, exam schedules, government directives. These need to be created, distributed to targeted audiences, and tracked for acknowledgement.
2. **Bulk SMS Campaigns**: For time-sensitive messages (exam results, fee reminders, event reminders), SMS is the most reliable channel in India — even for parents without smartphones.
3. **Email Campaigns**: For formal communications (report cards attached, newsletters, appointment letters), email provides a paper trail.
4. **WhatsApp Integration**: India has near-universal WhatsApp adoption. Many schools use WhatsApp as a primary parent communication channel. Structured WhatsApp Business API integration replaces informal WhatsApp group chaos.
5. **In-App Direct Messaging**: Teacher-to-parent and teacher-to-student messaging within the platform, with moderation controls appropriate for a school environment.
6. **Emergency Alerts**: Schools face weather closures, security incidents, examination cancellations, and health emergencies. A one-click multi-channel emergency broadcast capability is essential.
7. **Communication Audit Trail**: Regulatory compliance and dispute resolution require proof that communications were sent, received, and acknowledged.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| School Admin / Principal | Issue circulars, broadcast announcements, trigger emergency alerts, view all reports |
| Class Teacher | Send direct messages to parents, post class-level announcements |
| Subject Teacher | Message parents about student-specific academic concerns |
| Parent | Receive all communications, acknowledge circulars, reply to direct messages |
| Student (portal) | Receive teacher messages, view announcements |
| HR Manager | Internal staff communications (training notices, HR circulars) |

### 2.3 Indian School Context

- SMS delivery uses Indian TRAI-registered DLT (Distributed Ledger Technology) compliant SMS gateways. The Sender ID (6-character) and message content must be pre-registered as templates with TRAI.
- WhatsApp Business API requires a registered WABA (WhatsApp Business Account) and approved message templates for outbound messages.
- PTM (Parent-Teacher Meeting) reminders are among the most common use cases — scheduling reminders 7 days and 1 day before PTM.
- Fee reminders are the second most common — typically 7 days before due date and on due date.
- Government circulars from education boards (CBSE, ICSE, State Board) must be forwarded to teachers and staff — these are `circular_type = 'government'`.
- School newsletters are monthly publications distributed to all parents — structured as circulars with PDF attachments.
- Communication language: English + Hindi + regional language (Gujarati, Tamil, Marathi etc.) — templates support multi-language versions.

---

## 3. Scope and Boundaries

### 3.1 In-Scope Features

- Circular and notice management with audience targeting (class, section, role, individual)
- Circular acknowledgement tracking (read receipts with timestamp)
- Bulk email composition, scheduling, and delivery via configured SMTP/SendGrid
- Bulk SMS composition and delivery via configured SMS gateway (DLT-compliant)
- WhatsApp Business API integration stub (send approved templates; receive not in scope for v1)
- In-app direct messaging (one-to-one and one-to-group) with attachment support
- Message moderation (flagging, admin review)
- Reusable message template management (email, SMS, WhatsApp, in-app)
- Communication group management (auto-sync groups like "Class 5A Parents", custom groups)
- Communication scheduling (schedule messages for future delivery)
- Emergency alert broadcast (multi-channel — SMS + Email + Push simultaneously)
- Delivery and read analytics per message/campaign
- Communication history and audit log
- SMS gateway configuration (API key, sender ID, DLT entity ID)
- Email sending configuration (via existing Laravel mail config or per-tenant SMTP settings)

### 3.2 Out of Scope

- Automated event-triggered notifications — handled by Notification module (`ntf_*`). The Communication module is for human-authored messages only.
- WhatsApp inbound message handling and chatbot responses — v2 scope.
- Email inbox (inbound email reading) — out of scope; only outbound email supported.
- Social media posting (Facebook, Twitter) — not applicable for school context.
- Voice/IVR call campaigns — not in scope.
- Video conferencing or live meeting integration (Zoom, Google Meet) — separate module consideration.
- Push notification device management — handled by Notification module (`ntf_user_devices`).
- Two-way SMS conversations — v2 scope.

---

## 4. Functional Requirements

### 4.1 Q1 — Email Communication

**RBS Ref:** F.Q1.1 — Email Sending (T.Q1.1.1, T.Q1.1.2), F.Q1.2 — Template Management (T.Q1.2.1, T.Q1.2.2)

#### 4.1.1 Email Composition and Dispatch

**FR-COM-001: Compose and Send Email**
📐 Status: Not Started

- Authorized user (Principal, Admin, Class Teacher based on audience scope) can compose a new email campaign in `com_messages` (channel = `email`):
  - Recipient selection:
    - Select from communication groups (`com_groups`)
    - Select by role (all parents, all teaching staff, specific class parents)
    - Select specific individuals (user search)
    - Upload CSV for bulk recipients (phone/email column, phone numbers validated against registered user accounts)
  - Subject line (required, max 255 chars)
  - Body (rich-text HTML editor — TinyMCE or Quill)
  - Attachments (multiple files via `sys_media`; max 5 attachments; max 10MB total)
  - From name override (defaults to school name)
  - Reply-to email (optional; defaults to school email)
  - Priority: `normal`, `high`
- Preview mode: preview rendered email before sending
- Send immediately or schedule for future (`scheduled_at`)

**FR-COM-002: Recurring Email Rules**
📐 Status: Not Started

- Authorized user can create a recurring email rule in `com_recurring_rules`:
  - Base message template (FK to `com_message_templates`)
  - Recurrence type: `daily`, `weekly`, `monthly`, `custom_cron`
  - Start date, end date (optional)
  - Audience (group or role)
  - Last sent at tracking
- Recurring rules are processed by a scheduled Laravel Job (every 15 minutes checks for due rules)

#### 4.1.2 Email Template Management

**FR-COM-003: Email Template CRUD**
📐 Status: Not Started

- HR Manager / Admin can create reusable email templates in `com_message_templates` (channel = `email`):
  - Template name (unique)
  - Category (e.g., `fee_reminder`, `ptm_invite`, `exam_schedule`, `general`)
  - Subject template (with merge field placeholders: `{{student_name}}`, `{{amount}}`, `{{due_date}}`)
  - Body template (HTML with merge field placeholders)
  - Variables list (JSON array: `[{"key":"student_name","label":"Student Full Name","required":true}]`)
  - Language (`en`, `hi`, regional codes)
- Templates can be activated or deactivated
- Merge field substitution at send time using recipient data from `sys_users` and related student/parent records
- Templates versioned: new version created on edit; old version archived (not deleted)

### 4.2 Q2 — SMS Communication

**RBS Ref:** F.Q2.1 — SMS Sending (T.Q2.1.1, T.Q2.1.2), F.Q2.2 — Gateway Integration (T.Q2.2.1, T.Q2.2.2)

#### 4.2.1 SMS Composition and Dispatch

**FR-COM-004: Compose and Send SMS**
📐 Status: Not Started

- Authorized user can compose an SMS campaign in `com_messages` (channel = `sms`):
  - Recipient selection (same as email — group / role / individual / CSV upload)
  - SMS body (plain text only; character counter; 160 chars per SMS credit; Unicode for Hindi requires 70 chars per credit)
  - DLT Template selection (required for TRAI compliance — maps to `com_sms_dlt_templates`)
  - Merge field substitution in DLT template body
  - Send immediately or schedule
- Phone number validation: strip non-numeric; ensure 10-digit Indian mobile number; prepend `+91` for gateway
- Duplicate phone number deduplication within single campaign

**FR-COM-005: Bulk SMS via CSV Upload**
📐 Status: Not Started

- Authorized user can upload a CSV file with columns: `name`, `mobile`, `merge_field_1`, `merge_field_2`...
- System validates:
  - Mobile number format (10 digits)
  - Required merge fields present
  - Max 5,000 rows per upload
- Invalid rows flagged in validation report; user can download invalid rows CSV
- Valid rows queued for dispatch

**FR-COM-006: SMS Gateway Configuration**
📐 Status: Not Started

- Admin configures SMS gateway settings in `com_gateway_configs` (gateway_type = `sms`):
  - Provider name (e.g., MSG91, Textlocal, Kaleyra, Fast2SMS)
  - API key (encrypted)
  - Sender ID (6-character DLT-registered)
  - DLT Entity ID
  - DLT Principal Entity ID
  - Test mode flag (routes to test number instead of actual recipients)
  - Test phone number (for test mode)
- Test SMS action: sends a test SMS to test_phone_number, verifies response
- Sandbox mode: messages logged but not dispatched (for non-production environments)

**FR-COM-007: DLT Template Registration**
📐 Status: Not Started

- Admin registers pre-approved DLT templates in `com_sms_dlt_templates`:
  - Template name
  - DLT Template ID (from TRAI DLT portal)
  - Template body (with `{#var#}` placeholders per TRAI format)
  - Variable mapping (how Prime-AI merge fields map to DLT `{#var#}` positions)
  - Category: `transactional`, `promotional`, `service`
  - Status: `active`, `inactive`
- When sending SMS, system replaces `{#var#}` with actual values and sends the matched DLT template body

**FR-COM-008: SMS Delivery Tracking**
📐 Status: Not Started

- Each SMS sent creates a record in `com_message_recipients_jnt` with initial `delivery_status = 'pending'`
- Gateway webhook or polling updates delivery status:
  - `delivered`: confirmed delivery by network
  - `failed`: delivery failed (invalid number, DND, network error)
  - `pending`: submitted to gateway, awaiting network confirmation
- SMS logs viewable in Communication > SMS Logs with filters: date range, status, campaign
- Export SMS logs to CSV

### 4.3 Q3 — Push Notification (Communication-Initiated)

**RBS Ref:** F.Q3.1 — Push Notification Sending (T.Q3.1.1, T.Q3.1.2), F.Q3.2 — Mobile App Integration (T.Q3.2.1, T.Q3.2.2)

**FR-COM-009: Communication-Initiated Push Notifications**
📐 Status: Not Started

- Communication module can trigger a push notification campaign via the Notification module's FCM infrastructure (`ntf_user_devices`, `ntf_notifications`).
- The Communication module does NOT manage FCM tokens — it delegates to `ntf_*`.
- Workflow: Admin composes push message (title, body, deep-link URL/route) → selects audience → Communication module calls `NotificationService::dispatchBulkPush()` with resolved user IDs → Notification module handles FCM delivery.
- Communication module logs the dispatch in `com_messages` (channel = `push`) with reference to `ntf_notifications.id`
- Targeted push: filter by class, section, role, or communication group
- Deep-link support: link to specific screen in mobile app (e.g., fee payment, exam timetable, event detail)

### 4.4 Q4 — In-App Messaging

**RBS Ref:** F.Q4.1 — Chat Messaging (T.Q4.1.1, T.Q4.1.2), F.Q4.2 — Message Moderation (T.Q4.2.1, T.Q4.2.2)

#### 4.4.1 Direct Messaging

**FR-COM-010: One-to-One In-App Messaging**
📐 Status: Not Started

- Teacher can initiate a direct message to a parent or student in `com_messages` (channel = `in_app`):
  - Recipient selection via user search
  - Message body (rich text — text + emoji; no raw HTML for security)
  - Attachments: up to 3 files (images, PDFs); each max 5MB; MIME type whitelist enforced
  - Reply threading: messages within a conversation are linked via `parent_message_id`
- Parent can reply to a message from a teacher (reply-only; parents cannot initiate new conversations by default — configurable per school)
- Read receipt: when recipient opens the message, `com_message_recipients_jnt.is_read = 1` and `read_at` is set
- Unread badge count: computed from unread records per user
- Message list view: sorted by latest activity; unread first

**FR-COM-011: Group Messaging**
📐 Status: Not Started

- Teacher can send a message to a communication group (e.g., "Class 5A Parents"):
  - Creates one `com_messages` record with `recipient_type = 'group'`
  - `com_message_recipients_jnt` records created for each group member at send time (snapshot)
  - Group replies: group recipients can reply — reply creates new message linked via `parent_message_id`
- School Admin can send school-wide or role-wide group messages
- Group message delivery status = aggregate of all recipient delivery statuses

#### 4.4.2 Message Moderation

**FR-COM-012: Message Flagging**
📐 Status: Not Started

- Any user can flag a message as inappropriate from `com_message_flags`:
  - Flag reason: `abusive`, `spam`, `inappropriate`, `misinformation`, `other`
  - Flag note (optional text)
- Admin/Principal receives notification when a message is flagged
- Admin can review flagged messages and take action:
  - `dismiss`: flag resolved, no action
  - `delete_message`: soft-delete message, sender notified
  - `warn_sender`: system sends a warning notification to the sender
  - `block_sender`: revokes sender's messaging permission (set flag in `sys_users` attributes or permissions)
- Auto-moderation (configurable): if a message receives N flags within X hours, it is auto-hidden pending admin review

### 4.5 Q5 — Circular and Notice Board

**RBS Ref:** F.Q5.1 — Create Announcement (T.Q5.1.1, T.Q5.1.2), F.Q5.2 — Audience Targeting (T.Q5.2.1, T.Q5.2.2)

#### 4.5.1 Circular Management

**FR-COM-013: Create and Distribute Circular**
📐 Status: Not Started

- Principal or Admin creates a circular in `com_circulars`:
  - Title (required, max 300 chars)
  - Content (rich text / HTML)
  - Circular type: `general`, `academic`, `exam`, `fee`, `event`, `emergency`, `government`, `newsletter`
  - Issued date (defaults to today)
  - Expiry date (optional — circular disappears from notice board after this date)
  - Requires acknowledgement: `1` / `0`
  - Acknowledgement deadline date (if requires_acknowledgement = 1)
  - Attachments: up to 5 files (PDFs, images) via `sys_media`
  - Audience targeting via `com_circular_targets_jnt`:
    - `all`: entire school
    - `class`: specific class (FK to sch_classes)
    - `section`: specific section
    - `role`: specific system role (e.g., "all parents", "all teachers")
    - `individual`: specific user

**FR-COM-014: Circular Acknowledgement Tracking**
📐 Status: Not Started

- When `requires_acknowledgement = 1`, each targeted recipient must click "Acknowledge" in the portal/app.
- Acknowledgement creates a record in `com_circular_acknowledgements` with `acknowledged_at` timestamp.
- Admin can view acknowledgement status: total targeted vs acknowledged vs pending
- Non-acknowledgement report: list of users who have not acknowledged by deadline
- Admin can send reminders to non-acknowledgers (triggers a new COM message or Notification)
- Acknowledgement deadline enforcement: after deadline, report is locked and emailed to Principal

**FR-COM-015: Notice Board Display**
📐 Status: Not Started

- Active circulars (issued_date <= today <= expiry_date or expiry_date is null) are shown on the portal notice board
- Filtering: by type, by audience, by date range
- Pagination: 20 per page, most recent first
- Teacher and parent views show only circulars targeted at their role/class/section
- Admin and Principal see all circulars
- Search: by title, by type, by date

### 4.6 Q6 — Emergency Alerts

**RBS Ref:** F.Q6.1 — Alert Broadcast (T.Q6.1.1, T.Q6.1.2), F.Q6.2 — Alert Logs (T.Q6.2.1, T.Q6.2.2)

**FR-COM-016: Emergency Alert Broadcast**
📐 Status: Not Started

- Principal or Admin can trigger an emergency alert from a dedicated "Emergency Alert" screen:
  - Alert type: `school_closure`, `security_incident`, `exam_cancellation`, `health_advisory`, `weather_warning`, `other`
  - Alert title (required, max 200 chars)
  - Alert message (required, max 1000 chars — kept brief for SMS compatibility)
  - Audience: default = all (parents + students + staff); overridable
  - Channels: multi-select checkboxes — SMS, Email, In-App, Push (all checked by default)
  - Two-step confirmation: preview screen → confirm → dispatch
- Dispatch flow:
  - SMS: immediate, highest gateway priority
  - Email: immediate, queued at front of email queue
  - Push: via Notification module's FCM path
  - In-App: creates com_messages record (channel = `in_app`) with `priority = 'high'`
- High-priority flag: SMS and Email marked urgent; email subject prefixed with `[URGENT]`

**FR-COM-017: Alert Delivery Tracking**
📐 Status: Not Started

- Emergency alert stored in `com_emergency_alerts` with:
  - Alert details, audience, channels used
  - Triggered by (FK to sys_users)
  - Triggered at timestamp
  - Delivery summary per channel (sent count, delivered count, failed count) — JSON
  - Status: `dispatching`, `sent`, `partial_failure`, `failed`
- Alert log report: list all past emergency alerts with delivery stats
- Failed recipient report: which users did not receive the alert and on which channel

### 4.7 Communication Templates

**FR-COM-018: Template Management**
📐 Status: Not Started

- All message templates (email, SMS, in-app, WhatsApp) managed in `com_message_templates`:
  - Template name (unique within school and channel)
  - Category (for grouping in UI)
  - Channel: `email`, `sms`, `whatsapp`, `in_app`
  - Subject (for email templates; NULL for SMS/in_app)
  - Body template (plain text for SMS; HTML for email; approved template body for WhatsApp)
  - Variables JSON (definition of merge fields with key, label, sample value, required flag)
  - Language code (`en`, `hi`, regional)
  - Status: active / inactive
- Common pre-built templates seeded per school setup:
  - Fee Reminder (SMS + Email + WhatsApp)
  - PTM Invitation (SMS + Email)
  - Exam Timetable Release (Email)
  - Holiday Notice (SMS + Email)
  - Circular Acknowledgement Reminder (SMS + Email)
  - New Admission Welcome (Email)

### 4.8 Communication Groups

**FR-COM-019: Group Management**
📐 Status: Not Started

- Admin can create communication groups in `com_groups`:
  - Group name (unique)
  - Description
  - Group type:
    - `class`: auto-synced — includes all parents of a specific class (FK to sch_classes)
    - `section`: auto-synced — all parents of a class+section
    - `role`: auto-synced — all users with a specific system role
    - `custom`: manually maintained member list
  - Auto-sync flag: for class/section/role groups, membership is auto-refreshed on group query
  - Manual groups: members added/removed individually via `com_group_members_jnt`

**FR-COM-020: Group Membership Management**
📐 Status: Not Started

- For custom groups: Admin/Teacher can add or remove members individually
- Add member: user search, select, add to `com_group_members_jnt`
- Remove member: delete from junction table (soft-delete with `deleted_at`)
- Bulk add: upload CSV of user emails/phone numbers
- View all members in a group with role/class info
- Member count displayed on group list

### 4.9 Communication Scheduling

**FR-COM-021: Schedule Messages for Future Delivery**
📐 Status: Not Started

- When composing any message (email, SMS, in-app, circular), user can select "Schedule for later" and set `scheduled_at` (datetime picker with minute granularity)
- Scheduled messages stored with `status = 'scheduled'` in `com_messages`
- A Laravel Scheduler Job (`ProcessScheduledMessagesJob`) runs every 5 minutes:
  - Query `com_messages` where `status = 'scheduled'` AND `scheduled_at <= NOW()`
  - Process up to 100 messages per run
  - Dispatch via appropriate channel service
  - Update `status` to `sent` or `failed`, set `sent_at`
- Scheduled messages can be edited (subject/body/attachments) before `scheduled_at` by the sender
- Scheduled messages can be cancelled (soft-delete before scheduled_at)
- Recurring rules (FR-COM-002) also processed by this job

### 4.10 WhatsApp Integration

**FR-COM-022: WhatsApp Business API Configuration**
📐 Status: Not Started

- Admin configures WhatsApp Business API settings in `com_gateway_configs` (gateway_type = `whatsapp`):
  - WABA ID (WhatsApp Business Account ID)
  - Phone number ID
  - Access token (encrypted)
  - Business name
  - Webhook verification token (for Meta webhook setup)
  - Test mode flag
- Provider-agnostic design: supports Meta Cloud API directly or third-party BSPs (Business Solution Providers) like Interakt, Gupshup, AiSensy via configurable base URL

**FR-COM-023: WhatsApp Template Message Sending**
📐 Status: Not Started

- Admin registers approved WhatsApp template messages in `com_whatsapp_templates`:
  - Template name (as registered in Meta Business Manager)
  - Template language code
  - Template category: `MARKETING`, `UTILITY`, `AUTHENTICATION`
  - Components JSON (Meta template components structure — header, body, footer, buttons)
  - Variable mapping (how system data maps to template variables)
  - Status: `pending_approval`, `approved`, `rejected`
- When composing a WhatsApp message:
  - Only `approved` templates can be selected
  - Merge field values entered per variable
  - Recipients: group, role, or individual (phone numbers from `sys_users.phone`)
  - Dispatch via WhatsApp gateway service
- Delivery status tracked in `com_message_recipients_jnt` (status: `sent`, `delivered`, `read`, `failed`)

### 4.11 Communication Analytics

**RBS Ref:** F.Q7.1 — Message Reports (T.Q7.1.1, T.Q7.1.2), F.Q7.2 — Analytics (T.Q7.2.1, T.Q7.2.2)

**FR-COM-024: Communication Reports**
📐 Status: Not Started

- Admin and Principal can generate the following reports (PDF via DomPDF; CSV via fputcsv):
  - **Sent Messages Report**: All messages sent in a date range; filter by channel, sender, audience
  - **Delivery Report**: Per-campaign breakdown of sent/delivered/failed counts per channel
  - **Acknowledgement Report**: Per-circular — targeted count vs acknowledged count vs pending; exportable
  - **Non-Acknowledgement Report**: List of users who have not acknowledged a specific circular
  - **SMS Usage Report**: Total SMS credits used per month; breakdown by campaign
  - **Email Campaign Report**: Open rate, delivery rate per campaign (if email tracking pixel enabled)
  - **Emergency Alert Report**: All alerts sent, audience size, channel delivery stats

**FR-COM-025: Communication Analytics Dashboard**
📐 Status: Not Started

- Dashboard widgets:
  - Messages sent today / this week / this month (by channel — SMS, Email, In-App, WhatsApp)
  - Active circulars pending acknowledgement (count + list)
  - Acknowledgement completion rate for last 30 days (chart)
  - SMS delivery rate for last 30 days (%)
  - Email delivery rate for last 30 days (%)
  - Low-engagement groups: groups with lowest average read rate (identify unreached audiences)
  - Failed message count: unresolved delivery failures needing attention
  - Top senders (last 7 days): users who sent most messages

---

## 5. Non-Functional Requirements

### 5.1 Performance
- Bulk SMS/email dispatch for up to 5,000 recipients must be queued and processed asynchronously — never blocking the HTTP request.
- Emergency alert dispatch must begin within 30 seconds of confirmation.
- Circular notice board page load must complete within 2 seconds for up to 100 active circulars.
- In-app message list for a user must load within 500ms.

### 5.2 Scalability
- Bulk dispatch queued via Laravel Queue (Redis or database queue driver) with dedicated `communications` queue worker.
- Batch processing: dispatch in batches of 100 recipients to avoid gateway rate limits.
- SMS rate limit compliance: configurable `max_per_second` per gateway in `com_gateway_configs`.

### 5.3 Security
- SMS gateway API keys and WhatsApp access tokens encrypted at rest using Laravel `encrypt()`.
- DLT sender ID and entity ID must match registered values — mismatch results in SMS delivery failure; validated before save.
- In-app message body sanitized with HTMLPurifier to prevent XSS in stored content.
- Message moderation flag: any user can flag; only Admin/Principal can view flagged content.
- No cross-tenant data access (stancl/tenancy row isolation).

### 5.4 TRAI/DLT Compliance
- All outbound promotional and transactional SMS must use DLT-registered templates.
- Variable values replacing `{#var#}` must not introduce new words outside the template skeleton.
- DLT template ID must be sent in SMS API header as required by TRAI regulation (effective 2021).
- DND (Do Not Disturb) number filtering: before dispatch, check recipient numbers against DND list if gateway supports it; log skipped numbers.

### 5.5 Reliability
- Delivery status polling/webhook retry: if gateway webhook is missed, system polls delivery status every 15 minutes for up to 24 hours.
- Failed message retry: for transient failures (gateway timeout), retry up to 3 times with exponential backoff (1 min, 5 min, 15 min).
- Emergency alerts bypass normal queue — dispatched on high-priority queue.

### 5.6 Audit
- All message sends logged to `sys_activity_logs` (message_id, channel, recipient count, sender, timestamp).
- Emergency alert triggers logged with IP address and user agent.

---

## 6. Database Schema

### 6.1 Existing Tables Used (Read/Join Only)

| Table | Usage |
|---|---|
| `sys_users` | Sender, recipient, and approved_by references |
| `sys_media` | File attachments for messages and circulars |
| `sys_activity_logs` | Audit trail for all communication actions |
| `sch_classes` | Class-based audience targeting |
| `sch_sections` | Section-based audience targeting |
| `ntf_user_devices` | FCM tokens for push notification dispatch (read-only; managed by Notification module) |
| `ntf_notifications` | Notification module reference for push dispatch |

### 6.2 Proposed New Tables (`com_*`)

---

#### 📐 `com_gateway_configs`
SMS and WhatsApp gateway configuration per tenant.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `gateway_type` | ENUM('sms','whatsapp','email') | NOT NULL | |
| `provider_name` | VARCHAR(100) | NOT NULL | e.g., "MSG91", "Meta Cloud API" |
| `api_key_encrypted` | TEXT | DEFAULT NULL | Laravel encrypted |
| `sender_id` | VARCHAR(20) | DEFAULT NULL | DLT sender ID for SMS |
| `dlt_entity_id` | VARCHAR(50) | DEFAULT NULL | TRAI DLT Entity ID |
| `dlt_principal_entity_id` | VARCHAR(50) | DEFAULT NULL | |
| `waba_id` | VARCHAR(100) | DEFAULT NULL | WhatsApp Business Account ID |
| `phone_number_id` | VARCHAR(100) | DEFAULT NULL | WhatsApp Phone Number ID |
| `webhook_verification_token_encrypted` | TEXT | DEFAULT NULL | |
| `base_url` | VARCHAR(300) | DEFAULT NULL | For BSP providers |
| `test_mode` | TINYINT(1) | DEFAULT 0 | Route to test number |
| `test_recipient` | VARCHAR(50) | DEFAULT NULL | |
| `max_per_second` | SMALLINT UNSIGNED | DEFAULT 10 | Rate limit |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_gateway_type` (`gateway_type`) -- one config per type per tenant

---

#### 📐 `com_sms_dlt_templates`
TRAI DLT registered SMS template repository.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `dlt_template_id` | VARCHAR(100) | NOT NULL | From TRAI portal |
| `body_template` | TEXT | NOT NULL | With `{#var#}` placeholders |
| `variable_mapping_json` | JSON | DEFAULT NULL | Maps system fields to variable positions |
| `category` | ENUM('transactional','promotional','service') | DEFAULT 'transactional' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
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
| `category` | VARCHAR(100) | DEFAULT NULL | e.g., fee_reminder, ptm_invite |
| `channel` | ENUM('email','sms','whatsapp','in_app') | NOT NULL | |
| `language_code` | VARCHAR(10) | DEFAULT 'en' | |
| `subject` | VARCHAR(255) | DEFAULT NULL | For email |
| `body_template` | TEXT | NOT NULL | HTML for email; plain for SMS; Meta JSON for WhatsApp |
| `variables_json` | JSON | DEFAULT NULL | [{key, label, sample, required}] |
| `version` | SMALLINT UNSIGNED | DEFAULT 1 | Auto-increments on edit |
| `parent_template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | For version chain |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

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
| `variable_mapping_json` | JSON | DEFAULT NULL | How system data maps to template variables |
| `status` | ENUM('pending_approval','approved','rejected','paused') | DEFAULT 'pending_approval' | |
| `message_template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | Optional base template link |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
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
| `class_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_classes (for class/section types) |
| `section_id` | INT UNSIGNED | DEFAULT NULL | FK→sch_sections (for section type) |
| `role_name` | VARCHAR(100) | DEFAULT NULL | System role name (for role type) |
| `auto_sync` | TINYINT(1) | DEFAULT 0 | 1 = membership auto-resolved from source |
| `member_count_cache` | INT UNSIGNED | DEFAULT 0 | Updated on sync |
| `last_synced_at` | TIMESTAMP | DEFAULT NULL | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_group_members_jnt`
Explicit members for custom groups.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `group_id` | BIGINT UNSIGNED | NOT NULL, FK→com_groups | |
| `user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `added_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

UNIQUE KEY `uq_group_member` (`group_id`, `user_id`) WHERE `deleted_at` IS NULL

---

#### 📐 `com_messages`
Core message record for all channels (email, SMS, in-app, WhatsApp, push).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `sender_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `channel` | ENUM('email','sms','in_app','whatsapp','push') | NOT NULL | |
| `recipient_type` | ENUM('individual','group','role','all') | NOT NULL | |
| `group_id` | BIGINT UNSIGNED | FK→com_groups NULL | If recipient_type = group |
| `subject` | VARCHAR(255) | DEFAULT NULL | For email |
| `body` | LONGTEXT | NOT NULL | |
| `body_plain` | TEXT | DEFAULT NULL | Plain text fallback for email |
| `template_id` | BIGINT UNSIGNED | FK→com_message_templates NULL | |
| `dlt_template_id` | BIGINT UNSIGNED | FK→com_sms_dlt_templates NULL | For SMS |
| `status` | ENUM('draft','scheduled','dispatching','sent','partial_failure','failed','cancelled') | DEFAULT 'draft' | |
| `priority` | ENUM('normal','high','emergency') | DEFAULT 'normal' | |
| `scheduled_at` | TIMESTAMP | DEFAULT NULL | |
| `sent_at` | TIMESTAMP | DEFAULT NULL | |
| `parent_message_id` | BIGINT UNSIGNED | FK→com_messages NULL | For reply threading |
| `is_emergency` | TINYINT(1) | DEFAULT 0 | Routes to emergency queue |
| `ntf_notification_ref_id` | BIGINT UNSIGNED | DEFAULT NULL | For push channel — ref to ntf_notifications |
| `attachments_json` | JSON | DEFAULT NULL | Array of sys_media IDs |
| `send_stats_json` | JSON | DEFAULT NULL | {total, sent, delivered, failed} per channel |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_message_recipients_jnt`
Per-recipient delivery record for each message.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `message_id` | BIGINT UNSIGNED | NOT NULL, FK→com_messages | |
| `recipient_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `phone_number` | VARCHAR(20) | DEFAULT NULL | Resolved at send time for SMS/WhatsApp |
| `email_address` | VARCHAR(255) | DEFAULT NULL | Resolved at send time for email |
| `delivery_status` | ENUM('pending','sent','delivered','read','failed','skipped') | DEFAULT 'pending' | |
| `is_read` | TINYINT(1) | DEFAULT 0 | For in-app channel |
| `read_at` | TIMESTAMP | DEFAULT NULL | |
| `gateway_message_id` | VARCHAR(200) | DEFAULT NULL | Gateway-assigned message ID for delivery tracking |
| `failure_reason` | VARCHAR(300) | DEFAULT NULL | |
| `retry_count` | TINYINT UNSIGNED | DEFAULT 0 | |
| `last_attempted_at` | TIMESTAMP | DEFAULT NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

INDEX `idx_com_recipient_message` (`message_id`, `recipient_id`)
INDEX `idx_com_recipient_delivery` (`delivery_status`, `last_attempted_at`)

---

#### 📐 `com_circulars`
Official school circulars and notices.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `title` | VARCHAR(300) | NOT NULL | |
| `content` | LONGTEXT | DEFAULT NULL | Rich text / HTML |
| `circular_type` | ENUM('general','academic','exam','fee','event','emergency','government','newsletter') | NOT NULL | |
| `issued_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `issued_date` | DATE | NOT NULL | |
| `expiry_date` | DATE | DEFAULT NULL | NULL = never expires |
| `requires_acknowledgement` | TINYINT(1) | DEFAULT 0 | |
| `acknowledgement_deadline` | DATE | DEFAULT NULL | |
| `attachments_json` | JSON | DEFAULT NULL | Array of sys_media IDs |
| `circular_number` | VARCHAR(50) | DEFAULT NULL | e.g., "CBSE/2025/016" |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_circular_targets_jnt`
Audience targeting records for each circular.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `circular_id` | BIGINT UNSIGNED | NOT NULL, FK→com_circulars | |
| `target_type` | ENUM('all','class','section','role','group','individual') | NOT NULL | |
| `target_id` | INT UNSIGNED | DEFAULT NULL | ID in relevant table (class_id, section_id, etc.) |
| `target_label` | VARCHAR(200) | DEFAULT NULL | Human-readable label stored for history |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

---

#### 📐 `com_circular_acknowledgements`
Track per-user acknowledgement of circulars.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `circular_id` | BIGINT UNSIGNED | NOT NULL, FK→com_circulars | |
| `user_id` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `acknowledged_at` | TIMESTAMP | NOT NULL | |
| `device_type` | VARCHAR(50) | DEFAULT NULL | web / mobile |
| `ip_address` | VARCHAR(45) | DEFAULT NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

UNIQUE KEY `uq_circular_acknowledgement` (`circular_id`, `user_id`)

---

#### 📐 `com_message_flags`
User-submitted flags on inappropriate in-app messages.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `message_id` | BIGINT UNSIGNED | NOT NULL, FK→com_messages | |
| `flagged_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `flag_reason` | ENUM('abusive','spam','inappropriate','misinformation','other') | NOT NULL | |
| `flag_note` | TEXT | DEFAULT NULL | |
| `reviewed_by` | BIGINT UNSIGNED | FK→sys_users NULL | Admin who resolved it |
| `reviewed_at` | TIMESTAMP | DEFAULT NULL | |
| `resolution` | ENUM('pending','dismissed','message_deleted','sender_warned','sender_blocked') | DEFAULT 'pending' | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |

---

#### 📐 `com_emergency_alerts`
Emergency alert dispatch records.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `alert_type` | ENUM('school_closure','security_incident','exam_cancellation','health_advisory','weather_warning','other') | NOT NULL | |
| `title` | VARCHAR(200) | NOT NULL | |
| `message` | TEXT | NOT NULL | |
| `audience_type` | ENUM('all','class','section','role','group') | DEFAULT 'all' | |
| `audience_target_id` | INT UNSIGNED | DEFAULT NULL | |
| `channels_used_json` | JSON | NOT NULL | e.g., ["sms","email","push","in_app"] |
| `triggered_by` | BIGINT UNSIGNED | NOT NULL, FK→sys_users | |
| `triggered_at` | TIMESTAMP | NOT NULL | |
| `delivery_stats_json` | JSON | DEFAULT NULL | Per channel: {sent, delivered, failed} |
| `status` | ENUM('dispatching','sent','partial_failure','failed') | DEFAULT 'dispatching' | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

#### 📐 `com_recurring_rules`
Recurring message schedule definitions.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | PK, AI | |
| `name` | VARCHAR(150) | NOT NULL | |
| `template_id` | BIGINT UNSIGNED | NOT NULL, FK→com_message_templates | |
| `channel` | ENUM('email','sms','in_app','whatsapp') | NOT NULL | |
| `audience_type` | ENUM('group','role','all') | NOT NULL | |
| `group_id` | BIGINT UNSIGNED | FK→com_groups NULL | |
| `role_name` | VARCHAR(100) | DEFAULT NULL | |
| `recurrence_type` | ENUM('daily','weekly','monthly','custom_cron') | NOT NULL | |
| `cron_expression` | VARCHAR(100) | DEFAULT NULL | For custom_cron type |
| `start_date` | DATE | NOT NULL | |
| `end_date` | DATE | DEFAULT NULL | NULL = runs indefinitely |
| `last_sent_at` | TIMESTAMP | DEFAULT NULL | |
| `next_scheduled_at` | TIMESTAMP | DEFAULT NULL | |
| `send_count` | INT UNSIGNED | DEFAULT 0 | Total dispatches |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_by` | BIGINT UNSIGNED | FK→sys_users NULL | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | | |
| `deleted_at` | TIMESTAMP | DEFAULT NULL | |

---

## 7. API and Routes

### 7.1 Web Routes (Tenant — `routes/tenant.php`)

All routes prefixed with `communication/`, named `communication.*`, middleware `['auth', 'verified', 'tenant']`.

#### Circulars
```
GET    communication/circulars                               communication.circulars.index
POST   communication/circulars                               communication.circulars.store
GET    communication/circulars/{id}                          communication.circulars.show
PUT    communication/circulars/{id}                          communication.circulars.update
DELETE communication/circulars/{id}                          communication.circulars.destroy
POST   communication/circulars/{id}/acknowledge              communication.circulars.acknowledge
GET    communication/circulars/{id}/acknowledgements         communication.circulars.acknowledgements
POST   communication/circulars/{id}/send-reminder            communication.circulars.send-reminder
```

#### Email
```
GET    communication/email                                   communication.email.index
POST   communication/email/compose                           communication.email.compose
POST   communication/email/send                              communication.email.send
GET    communication/email/{id}                              communication.email.show
DELETE communication/email/{id}                              communication.email.destroy
```

#### SMS
```
GET    communication/sms                                     communication.sms.index
POST   communication/sms/compose                             communication.sms.compose
POST   communication/sms/send                                communication.sms.send
GET    communication/sms/logs                                communication.sms.logs
GET    communication/sms/gateway                             communication.sms.gateway.show
POST   communication/sms/gateway                             communication.sms.gateway.save
POST   communication/sms/gateway/test                        communication.sms.gateway.test
GET    communication/sms/dlt-templates                       communication.sms.dlt-templates.index
POST   communication/sms/dlt-templates                       communication.sms.dlt-templates.store
PUT    communication/sms/dlt-templates/{id}                  communication.sms.dlt-templates.update
DELETE communication/sms/dlt-templates/{id}                  communication.sms.dlt-templates.destroy
```

#### WhatsApp
```
GET    communication/whatsapp                                communication.whatsapp.index
POST   communication/whatsapp/config                         communication.whatsapp.config.save
POST   communication/whatsapp/send                           communication.whatsapp.send
GET    communication/whatsapp/templates                      communication.whatsapp.templates.index
POST   communication/whatsapp/templates                      communication.whatsapp.templates.store
PUT    communication/whatsapp/templates/{id}                 communication.whatsapp.templates.update
```

#### In-App Messaging
```
GET    communication/messages                                communication.messages.index
POST   communication/messages                                communication.messages.store
GET    communication/messages/{id}                           communication.messages.show
POST   communication/messages/{id}/reply                     communication.messages.reply
POST   communication/messages/{id}/read                      communication.messages.read
POST   communication/messages/{id}/flag                      communication.messages.flag
GET    communication/messages/flags                          communication.messages.flags.index
POST   communication/messages/flags/{id}/resolve             communication.messages.flags.resolve
```

#### Groups
```
GET    communication/groups                                  communication.groups.index
POST   communication/groups                                  communication.groups.store
GET    communication/groups/{id}                             communication.groups.show
PUT    communication/groups/{id}                             communication.groups.update
DELETE communication/groups/{id}                             communication.groups.destroy
GET    communication/groups/{id}/members                     communication.groups.members.index
POST   communication/groups/{id}/members                     communication.groups.members.store
DELETE communication/groups/{id}/members/{user_id}           communication.groups.members.destroy
POST   communication/groups/{id}/sync                        communication.groups.sync
```

#### Templates
```
GET    communication/templates                               communication.templates.index
POST   communication/templates                               communication.templates.store
GET    communication/templates/{id}                          communication.templates.show
PUT    communication/templates/{id}                          communication.templates.update
DELETE communication/templates/{id}                          communication.templates.destroy
```

#### Emergency Alerts
```
GET    communication/emergency                               communication.emergency.index
POST   communication/emergency/send                          communication.emergency.send
GET    communication/emergency/{id}                          communication.emergency.show
```

#### Recurring Rules and Scheduling
```
GET    communication/recurring                               communication.recurring.index
POST   communication/recurring                               communication.recurring.store
PUT    communication/recurring/{id}                          communication.recurring.update
DELETE communication/recurring/{id}                          communication.recurring.destroy
```

#### Reports and Analytics
```
GET    communication/reports/dashboard                       communication.reports.dashboard
GET    communication/reports/sent                            communication.reports.sent
GET    communication/reports/delivery                        communication.reports.delivery
GET    communication/reports/acknowledgements/{circular_id}  communication.reports.acknowledgements
GET    communication/reports/sms-usage                       communication.reports.sms-usage
GET    communication/reports/emergency                       communication.reports.emergency
```

### 7.2 API Routes (`routes/api.php`)

```
POST   api/v1/communication/webhook/sms              Inbound delivery status webhook (SMS gateway)
POST   api/v1/communication/webhook/whatsapp         Inbound WhatsApp webhook (status updates)
GET    api/v1/communication/webhook/whatsapp          WhatsApp webhook verification
```

---

## 8. Business Rules

| Rule ID | Description |
|---|---|
| BR-COM-001 | SMS messages must use a DLT-registered template; ad-hoc free-text SMS is not permitted (TRAI compliance). |
| BR-COM-002 | WhatsApp messages must use a Meta-approved template with `status = 'approved'`; unapproved templates cannot be sent. |
| BR-COM-003 | Emergency alert channels must include at least one channel (SMS recommended as minimum). |
| BR-COM-004 | Circular acknowledgement can only be submitted by a user who is in the circular's target audience. |
| BR-COM-005 | A user cannot acknowledge the same circular twice (UNIQUE constraint on com_circular_acknowledgements). |
| BR-COM-006 | Scheduled messages with scheduled_at in the past cannot be saved as scheduled; they must be sent immediately or discarded. |
| BR-COM-007 | Bulk SMS upload CSV: max 5,000 rows. Rows exceeding this limit are rejected with an error before processing begins. |
| BR-COM-008 | In-app message body must be sanitized (HTMLPurifier) before storage to prevent XSS. |
| BR-COM-009 | Auto-sync groups (class, section, role) cannot have manually managed members in com_group_members_jnt. |
| BR-COM-010 | A message can only be cancelled if its status is `scheduled` or `draft` and `sent_at` is NULL. |
| BR-COM-011 | Failed message retry count must not exceed 3; after 3 failures, status is `failed` and no further retry. |
| BR-COM-012 | Circular `expiry_date` must be >= `issued_date` if provided. |
| BR-COM-013 | Teachers can only send direct messages to parents of students in their assigned class/section(s); not to arbitrary users. |
| BR-COM-014 | Message template body must contain at least one `{{variable}}` placeholder if variables_json is non-empty. |
| BR-COM-015 | Emergency alert dispatch confirmation is required (two-step: preview → confirm); single-click emergency dispatch is not permitted. |

---

## 9. Authorization and RBAC

### 9.1 Proposed Permissions

| Permission | School Admin | Principal | Class Teacher | Subject Teacher | Parent | Student |
|---|---|---|---|---|---|---|
| `com.circular.create` | Yes | Yes | No | No | No | No |
| `com.circular.view` | Yes | Yes | Yes (own class) | Yes (own class) | Yes (targeted) | Yes (targeted) |
| `com.circular.acknowledge` | No | No | Yes | Yes | Yes | Yes |
| `com.email.send_bulk` | Yes | Yes | No | No | No | No |
| `com.sms.send_bulk` | Yes | Yes | No | No | No | No |
| `com.sms.configure_gateway` | Yes | No | No | No | No | No |
| `com.whatsapp.send` | Yes | Yes | No | No | No | No |
| `com.message.send` | Yes | Yes | Yes | Yes | No | No |
| `com.message.reply` | Yes | Yes | Yes | Yes | Yes | Yes |
| `com.message.flag` | Yes | Yes | Yes | Yes | Yes | Yes |
| `com.message.moderate` | Yes | Yes | No | No | No | No |
| `com.group.manage` | Yes | No | No | No | No | No |
| `com.template.manage` | Yes | No | No | No | No | No |
| `com.emergency.send` | Yes | Yes | No | No | No | No |
| `com.reports.view` | Yes | Yes | No | No | No | No |

---

## 10. Service Layer Architecture

| Service | Responsibility |
|---|---|
| 📐 `CircularService` | Create circulars, resolve targets, track acknowledgements, send reminders |
| 📐 `EmailService` | Compose email messages, template rendering, SMTP dispatch, delivery tracking |
| 📐 `SmsService` | Validate recipients, DLT template matching, gateway API dispatch, delivery status polling |
| 📐 `WhatsAppService` | Template message construction, Meta Cloud API dispatch, delivery status via webhook |
| 📐 `InAppMessageService` | Store messages, read receipts, threading, unread counts, moderation actions |
| 📐 `EmergencyAlertService` | Multi-channel dispatch coordination, delivery stats aggregation, priority queue routing |
| 📐 `CommunicationGroupService` | Group CRUD, auto-sync (class/section/role), member management, member count cache |
| 📐 `MessageSchedulerJob` | Scheduled Laravel Job — processes due scheduled messages and recurring rules |
| 📐 `CommunicationReportService` | All reports (delivery, acknowledgement, SMS usage, emergency) — PDF and CSV |

---

## 11. Integration Points

| Module | Integration Type | Description |
|---|---|---|
| Notification (`ntf_*`) | Outbound call | For push notification dispatch, Communication module calls Notification module's FCM service. Device tokens are in `ntf_user_devices`. |
| SchoolSetup | Read-only FK | `sch_classes`, `sch_sections` for class/section-based audience targeting |
| Student Management | Read-only | Resolve parent-student relationships for class-level parent targeting |
| Auth (`sys_users`) | Read-only | Sender identity, recipient phone/email resolution |
| System Media (`sys_media`) | Read-write | Circular and message file attachments |
| Finance/Fees | Trigger source | Fee module can trigger Communication module to send fee reminders (event-based) |
| Events Module | Trigger source | Event Engine fires PTM/event reminder messages via Communication module |
| Audit (`sys_activity_logs`) | Write | All message sends and emergency alerts logged |

---

## 12. Test Coverage

### 12.1 Proposed Test Cases

| Test | Type | Description |
|---|---|---|
| 📐 `CircularCreationTest` | Feature | Create circular, verify target records created, check visibility by targeted/non-targeted user |
| 📐 `CircularAcknowledgementTest` | Feature | Targeted user acknowledges; verify record created; non-targeted user cannot acknowledge |
| 📐 `DuplicateAcknowledgementTest` | Feature | Second acknowledgement attempt returns 422 (UNIQUE constraint) |
| 📐 `SmsGatewayConfigTest` | Feature | Store config; API key encrypted; test SMS endpoint returns success on mock gateway |
| 📐 `DltTemplateSmsTest` | Unit | DLT variable substitution replaces `{#var#}` in correct sequence |
| 📐 `BulkSmsCsvValidationTest` | Feature | Validate CSV with invalid rows; confirm valid rows queued; invalid rows returned |
| 📐 `ScheduledMessageProcessingTest` | Feature | Message scheduled for past time is dispatched; future time is not yet dispatched |
| 📐 `EmergencyAlertTwoStepTest` | Feature | Alert cannot be sent without confirmation step; confirmed alert dispatches on all selected channels |
| 📐 `InAppMessageReadReceiptTest` | Feature | Mark message as read; is_read = 1, read_at set; unread count decremented |
| 📐 `MessageFlagModerationTest` | Feature | User flags message; admin sees flag; admin resolves as delete_message; message soft-deleted |
| 📐 `AutoSyncGroupTest` | Feature | Auto-sync group for Class 5A returns all parents of Class 5A students dynamically |
| 📐 `RecurringRuleDispatchTest` | Feature | Recurring rule with daily recurrence triggers dispatch on due run; next_scheduled_at updated |

---

## 13. Implementation Status

### 13.1 Feature Status Summary

| FR Code | Feature | Status |
|---|---|---|
| FR-COM-001 | Compose and Send Email | ❌ Not Started |
| FR-COM-002 | Recurring Email Rules | ❌ Not Started |
| FR-COM-003 | Email Template CRUD | ❌ Not Started |
| FR-COM-004 | Compose and Send SMS | ❌ Not Started |
| FR-COM-005 | Bulk SMS via CSV Upload | ❌ Not Started |
| FR-COM-006 | SMS Gateway Configuration | ❌ Not Started |
| FR-COM-007 | DLT Template Registration | ❌ Not Started |
| FR-COM-008 | SMS Delivery Tracking | ❌ Not Started |
| FR-COM-009 | Communication-Initiated Push | ❌ Not Started |
| FR-COM-010 | One-to-One In-App Messaging | ❌ Not Started |
| FR-COM-011 | Group Messaging | ❌ Not Started |
| FR-COM-012 | Message Flagging and Moderation | ❌ Not Started |
| FR-COM-013 | Create and Distribute Circular | ❌ Not Started |
| FR-COM-014 | Circular Acknowledgement Tracking | ❌ Not Started |
| FR-COM-015 | Notice Board Display | ❌ Not Started |
| FR-COM-016 | Emergency Alert Broadcast | ❌ Not Started |
| FR-COM-017 | Alert Delivery Tracking | ❌ Not Started |
| FR-COM-018 | Template Management | ❌ Not Started |
| FR-COM-019 | Group Management | ❌ Not Started |
| FR-COM-020 | Group Membership Management | ❌ Not Started |
| FR-COM-021 | Schedule Messages for Future Delivery | ❌ Not Started |
| FR-COM-022 | WhatsApp Business API Configuration | ❌ Not Started |
| FR-COM-023 | WhatsApp Template Message Sending | ❌ Not Started |
| FR-COM-024 | Communication Reports | ❌ Not Started |
| FR-COM-025 | Communication Analytics Dashboard | ❌ Not Started |

### 13.2 Code Artifacts — All Proposed (None Exist)

| Artifact | Path (Proposed) |
|---|---|
| 📐 Module root | `Modules/Communication/` |
| 📐 CircularController | `Modules/Communication/Http/Controllers/CircularController.php` |
| 📐 EmailCampaignController | `Modules/Communication/Http/Controllers/EmailCampaignController.php` |
| 📐 SmsCampaignController | `Modules/Communication/Http/Controllers/SmsCampaignController.php` |
| 📐 WhatsAppController | `Modules/Communication/Http/Controllers/WhatsAppController.php` |
| 📐 InAppMessageController | `Modules/Communication/Http/Controllers/InAppMessageController.php` |
| 📐 EmergencyAlertController | `Modules/Communication/Http/Controllers/EmergencyAlertController.php` |
| 📐 CommunicationGroupController | `Modules/Communication/Http/Controllers/CommunicationGroupController.php` |
| 📐 MessageTemplateController | `Modules/Communication/Http/Controllers/MessageTemplateController.php` |
| 📐 RecurringRuleController | `Modules/Communication/Http/Controllers/RecurringRuleController.php` |
| 📐 CommunicationReportController | `Modules/Communication/Http/Controllers/CommunicationReportController.php` |
| 📐 Webhook controllers | `Modules/Communication/Http/Controllers/Webhooks/` |
| 📐 All Service classes | `Modules/Communication/Services/` |
| 📐 All Models | `Modules/Communication/Models/` |
| 📐 ProcessScheduledMessagesJob | `Modules/Communication/Jobs/ProcessScheduledMessagesJob.php` |
| 📐 DDL | `1-DDL_Tenant_Modules/XX-Communication/DDL/` |

---

## 14. Known Issues and Technical Debt

1. **TRAI DLT Compliance Complexity**: TRAI regulations are evolving. The DLT template registration flow requires exact match between the pre-approved body and the runtime-substituted body. Any deviation (even extra spaces) causes message rejection at network level. The `SmsService` must implement strict template-body reconstruction before dispatch.

2. **WhatsApp 24-Hour Session Window**: Meta's WhatsApp Business API only allows free-form messages within a 24-hour customer-service session window. After 24 hours, only approved templates can be sent. Since Prime-AI currently only supports outbound marketing and utility templates, this is not a blocker for v1 — but template-based sending must be the only path.

3. **SMS Delivery Webhook vs Polling**: Most Indian SMS gateways support webhooks for delivery status, but webhook URLs must be publicly accessible. For development/staging environments, polling is the only practical approach. The `SmsService` must support both modes, configurable per gateway.

4. **In-App Message Volume**: For schools with 500 students and 500 parents, a single school-wide message creates 1,000 `com_message_recipients_jnt` records. Circular targets are better served by a lazy-resolution pattern (resolve recipients at read time from group definition) rather than pre-materializing all rows. This architectural decision must be made before implementation begins.

5. **Email Open Rate Tracking**: Tracking email open rates requires embedding a 1x1 tracking pixel (unique URL per recipient per message). This is technically feasible but introduces privacy considerations and may be blocked by email clients. Open rate tracking should be an opt-in feature, disabled by default.

6. **Push Channel Dependency**: FR-COM-009 depends on the Notification module's `ntf_user_devices` table having FCM tokens for all target users. If a user has not installed the mobile app, push will silently fail. The Communication module must handle this gracefully and report push-not-applicable users separately.

7. **Multi-Language Template Rendering**: The current design stores one body per template record. For multi-language support, a `com_message_template_translations` extension table is recommended in v2 to store language variants of the same logical template.

---

## 15. Development Priorities and Recommendations

### 15.1 Phase 1 — Foundation (Recommended First Sprint)
1. **Circular and Notice Management** (FR-COM-013, FR-COM-014, FR-COM-015) — Highest immediate value; circular distribution and acknowledgement is the most universally needed feature. No gateway configuration required.
2. **In-App Direct Messaging** (FR-COM-010, FR-COM-011) — Teacher-parent communication within platform; drives portal adoption. Requires only database and UI — no external service dependencies.
3. **Communication Group Management** (FR-COM-019, FR-COM-020) — Prerequisite for all bulk communications; auto-sync groups for class/section are especially high value.

### 15.2 Phase 2 — SMS and Email Campaigns
4. **SMS Gateway Configuration and DLT Templates** (FR-COM-006, FR-COM-007) — Configuration prerequisite.
5. **SMS Compose and Send** (FR-COM-004, FR-COM-005, FR-COM-008) — Bulk SMS for fee reminders, PTM invitations.
6. **Email Templates and Campaigns** (FR-COM-001, FR-COM-002, FR-COM-003) — Formal communication channel.

### 15.3 Phase 3 — Scheduling, Push, and Emergency
7. **Message Scheduling and Recurring Rules** (FR-COM-021, FR-COM-002) — Enables automation of periodic communications.
8. **Emergency Alert Broadcast** (FR-COM-016, FR-COM-017) — Critical safety feature; must be thoroughly tested.
9. **Communication-Initiated Push** (FR-COM-009) — Dependent on Notification module being live.

### 15.4 Phase 4 — WhatsApp and Analytics
10. **WhatsApp Integration** (FR-COM-022, FR-COM-023) — External WABA approval required; plan at least 2-3 weeks for Meta template approval lead time.
11. **Communication Reports and Dashboard** (FR-COM-024, FR-COM-025) — Analytics layer; builds on all above.

### 15.5 Integration Prerequisites
- Notification module (`ntf_*`) must be fully operational before push channel (FR-COM-009) can be implemented.
- `sys_users` must include valid `phone` and `email` fields for all users before SMS/email targeting works.
- WhatsApp requires a registered WABA with Meta before any code development on FR-COM-022/023 — start business verification process early.
- For DLT compliance, school must pre-register sender ID and templates with TRAI DLT portal before any SMS can be sent.
