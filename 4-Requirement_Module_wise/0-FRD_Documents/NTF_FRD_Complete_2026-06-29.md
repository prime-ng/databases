# NTF Notification Module — Complete Analysis Pack
**Module:** Notification | **Code:** NTF | **Prefix:** `ntf_`
**Date:** 2026-06-29 | **Author:** pa-business-analyst
**Sources:** V2 Requirement (2026-03-26), live code + filesystem count (2026-06-30)

---

# TABLE OF CONTENTS

- Section A: Functional Requirements Document (FRD) — Sections 1–10
- Section B: Requirements Traceability Matrix (RTM)
- Section C: Business Rules Register + Requirement Conditions Catalog + Validation Catalog
- Section D: Process Flows + FSM Catalog
- Section E: Data Dictionary + Cross-Module Dependency Map
- Section F: NFR Catalog + Risk Register
- Section G: Prioritization (MoSCoW) + Effort Estimation
- Section H: User Stories + Reporting & Analytics Spec

> FRD is the single source of truth. All REQ-/BR-/RPT-/ENH- IDs are defined here; later sections reference them.

---

# SECTION A — FUNCTIONAL REQUIREMENTS DOCUMENT (FRD)

---

## 1. Module Overview

### 1.1 Purpose

The Notification module (NTF) is the central communication backbone for the Prime-AI platform. It delivers timely, accurate messages to every school stakeholder — administrators, teachers, students, and parents — across five channels: email, SMS, in-app alerts, push notifications, and WhatsApp. It supports both automated event-driven alerts (triggered when a fee falls due, an exam result is published, or a student is marked absent) and manually composed announcements (fee-due reminders, circular broadcasts, emergency alerts). Every message is template-driven, approval-gated, recipient-targeted, and delivery-tracked.

### 1.2 Business Value

- Schools replace ad-hoc phone calls and manual WhatsApp broadcasts with a governed, audited, multi-channel engine.
- Parents receive fee reminders, attendance alerts, and exam results in real time without administrative intervention.
- Administrators gain visibility into delivery success rates, bounce rates, and per-channel costs.
- India-specific regulatory compliance (TRAI DLT for SMS) is built in — non-compliant SMS are blocked before dispatch.
- GDPR-aligned opt-in/opt-out management protects user privacy and demonstrates compliance.

### 1.3 Scope

**In Scope:**
- Five delivery channels: Email, SMS, In-App, Push (FCM/APNS), WhatsApp
- Event-driven automatic notifications triggered by any other module
- Manually composed one-time and scheduled notifications
- Recurring scheduled notifications with cron-expression support
- Notification template management with versioning and approval workflow
- Recipient targeting by role, class, section, group, or individual
- Per-user channel preferences, quiet hours, and opt-in/opt-out
- Device token registration for push notifications
- Delivery queue management with worker locking and retry logic
- Full delivery audit trail (append-only delivery log)
- Notification inbox (bell widget + inbox list) for in-app channel
- Thread grouping for related notifications
- Schedule audit history for recurring dispatches
- India DLT SMS compliance

**Out of Scope:**
- Real-time bidirectional chat (that is the CommonChat module)
- School circular and announcement composition UI (that belongs to the Communication module — NTF is its underlying engine)
- Email marketing campaign builder (NTF sends; it does not provide campaign analytics beyond delivery metrics)
- Parent-Teacher Meeting notifications (handled by the PTM module using NTF events)
- Leave approval notifications (handled by the HrStaff module using NTF events)

### 1.4 Terminology

| Term | Business Meaning |
|------|-----------------|
| Notification | A single message record — the "envelope" that carries title, type, scheduling, template reference, and recipient targets |
| Delivery Channel | A medium for message delivery: Email, SMS, In-App, Push, or WhatsApp — each with its own provider, rate limits, and cost |
| Message Template | A reusable message body with `{{placeholder}}` variables (e.g., `{{student_name}}`), versioned and approval-gated before use |
| Target Group | A named set of recipients — either a fixed list (Static) or dynamically resolved at send time (e.g., "All Parents of Class 5A") |
| Resolved Recipient | A single (person × channel) row — the smallest dispatch unit; created when a Target is expanded to individual users |
| Delivery Queue | The pending work list: one entry per Resolved Recipient, processed asynchronously by background workers |
| Delivery Log | Append-only record of every delivery attempt — stage, timestamp, provider response, cost; cannot be edited or deleted |
| Event Code | An upper-snake-case string (e.g., `FEE_DUE_REMINDER`) linking a module event to its Notification and Templates |
| Quiet Hours | A per-user time window (e.g., 22:00–07:00) during which delivery is deferred, not cancelled |
| Opt-Out | A user's irrevocable choice to stop receiving notifications on a specific channel; overrides all admin settings |
| DLT Template ID | A numeric ID issued by India's TRAI telecom regulator for a registered SMS template; mandatory for all commercial SMS |
| Provider | External service used for delivery: MSG91 / Twilio (SMS), AWS SES (email), Firebase FCM (push), Meta Cloud API (WhatsApp) |
| Fallback Channel | A secondary channel automatically tried when the primary channel fails delivery |
| Batch ID | A UUID grouping all Resolved Recipients for one notification dispatch, enabling parallel bulk processing |
| Thread | A grouped set of related notifications; types: Conversation, Digest, or Broadcast |

---

## 2. User Roles & Access

### 2.1 Actors

| Actor | Role in NTF | Access Summary |
|-------|-------------|----------------|
| School Admin | Create and manage all notification resources | Full CRUD on channels, providers, templates, notifications, groups, preferences, queue, logs |
| Teacher | Send targeted notifications to own class/section students or parents | Create + send notifications scoped to own classes; read templates |
| Student | Receive and read in-app notifications | Read-only inbox; mark read; manage own preferences |
| Parent | Receive email/SMS/push/WhatsApp notifications | Read-only inbox; manage own opt-in/opt-out and quiet hours |
| Prime Super Admin | Manage system templates across all tenants | Full access including system-template creation; not tenant-scoped |
| System (automated) | Other modules firing `SystemNotificationTriggered` | No UI actor; fire-and-forget via event API |
| Queue Worker | Background process consuming the Delivery Queue | Infrastructure; no UI actor |

### 2.2 Role-Feature Matrix

| Feature | School Admin | Teacher | Student | Parent | Prime Super Admin |
|---------|:---:|:---:|:---:|:---:|:---:|
| Configure Delivery Channels | CRUD | — | — | — | CRUD |
| Configure External Providers | CRUD | — | — | — | CRUD |
| Manage Message Templates | CRUD + Approve | View | — | — | CRUD (incl. System) |
| Compose & Send Notifications | CRUD + Send | Create (own class) | — | — | — |
| Manage Target Groups | CRUD | View | — | — | — |
| View Delivery Queue | View + Retry/Cancel | — | — | — | View |
| View Delivery Logs | View | — | — | — | View |
| Manage Own Preferences | — | Manage | Manage | Manage | — |
| Register Device Token | — | Register | Register | Register | — |
| Read Notification Inbox | — | Read | Read | Read | — |
| View Schedule Audit | View | — | — | — | View |

---

## 3. Functional Requirements

### 3.1 Delivery Channel Configuration [CONFIGURATION]

**REQ-NTF-001** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** School staff configure the delivery channels available to their school.

A School Admin may create, edit, activate, or deactivate a Delivery Channel record. Each channel specifies: channel type (Email, SMS, WhatsApp, In-App, Push), display name, delivery priority order (1=highest), maximum retries, retry delay, per-minute rate cap, daily and monthly volume caps, per-message cost, and an optional Fallback Channel. Multiple channels of the same type are not permitted for the same school.

**Actors:** Initiates — School Admin | Processes — System | Views — School Admin

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | An inactive channel is skipped silently during dispatch; no error is raised | BR-NTF-007 |
| 2 | A fallback chain must not be circular (validated on save) | BR-NTF-013 |
| 3 | Deactivating a channel with pending queue entries cancels those entries | BR-NTF-007 |

**Acceptance Criteria:**
- AC-001a: Admin creates an Email channel with rate limit 200/minute → saved; visible in channel list; system enforces cap during dispatch.
- AC-001b: Admin deactivates SMS channel → subsequent dispatch skips SMS silently; delivery log records channel-skipped warning.
- AC-001c: Admin attempts to set Channel A fallback to Channel B and Channel B fallback to Channel A → system rejects with "Circular fallback not permitted."
- AC-001d: Deleting a channel that has active Notifications assigned → system warns "N notifications use this channel" before allowing force-delete.

**Integration:** Reads from `sys_dropdown_table` for channel type values (config-driven per D29).

---

**REQ-NTF-002** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** Channel activation toggle.

Admin may toggle any channel between active and inactive without editing other settings. The toggle action is recorded in the activity log with actor name and timestamp.

**Acceptance Criteria:**
- AC-002a: Toggle off → channel immediately skipped in next dispatch cycle.
- AC-002b: Activity log entry created on every toggle (actor, action, timestamp).

---

### 3.2 External Provider Configuration [CONFIGURATION]

**REQ-NTF-003** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** School Admin configures external delivery providers (gateways).

For each channel, one or more providers may be configured: Twilio or MSG91 (SMS), AWS SES or SMTP (Email), Firebase FCM (Push), Meta Cloud API (WhatsApp). Each provider record stores: provider name, provider role (Primary/Secondary/Backup), sender address or phone, and encrypted API credentials. Credentials are stored encrypted — never in plaintext.

**Actors:** Initiates — School Admin | Processes — System (encryption) | Views — School Admin

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | API key and API secret must be stored encrypted; plaintext storage is prohibited | BR-NTF-011 |
| 2 | Provider credentials are never returned to the browser in full; masked on display | BR-NTF-011 |

**Acceptance Criteria:**
- AC-003a: Admin saves provider with API key → key stored encrypted; database record shows ciphertext not plaintext.
- AC-003b: Admin views provider list → API key shown as masked (e.g., `****abc123`); never full value.
- AC-003c: Admin deletes provider in use by an active channel → system warns before deletion.

---

**REQ-NTF-004** | Priority: Standard (P1) | Tags: [CONFIGURATION]
**Feature:** Test provider connectivity before saving.

Admin may click "Test Connection" on any saved provider. The system sends a test ping to the provider API and returns success or failure with the response detail visible in the UI.

**Acceptance Criteria:**
- AC-004a: Valid credentials → "Connection successful" returned within 10 seconds.
- AC-004b: Invalid credentials → "Authentication failed: [provider message]" displayed; provider record unchanged.

---

**REQ-NTF-005** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** India DLT SMS provider setup.

For SMS channels on Indian school tenants, the Admin enters the DLT-registered sender ID (e.g., `PRMAI1`) on the provider record. This sender ID is passed to MSG91/Twilio in every SMS dispatch request.

**Acceptance Criteria:**
- AC-005a: Provider record saved with sender ID → ID appears in every outbound SMS API request.
- AC-005b: SMS provider without a sender ID on an Indian tenant → delivery blocked with "DLT sender ID required."

**Integration:** DLT compliance requirement (BR-NTF-010).

---

### 3.3 Message Template Management [CONFIGURATION][WORKFLOW]

**REQ-NTF-006** | Priority: Core (P0) | Tags: [CONFIGURATION][WORKFLOW]
**Feature:** Staff create and manage reusable message templates.

Templates are linked to a Delivery Channel and identified by a Template Code that matches the Event Code fired by other modules. Template body uses `{{placeholder_name}}` syntax. Subject (for email), body (all channels), and an optional plain-text alternative body may be specified. Each template belongs to one channel, one language, and carries a version number.

**Actors:** Initiates — School Admin | Processes — System | Views — School Admin, Teacher

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Only Approved templates may be used in dispatch | BR-NTF-005 |
| 2 | System templates may only be created/edited/deleted by Prime Super Admin; School Admins may clone them | BR-NTF-004 |

**Acceptance Criteria:**
- AC-006a: Admin creates template with `{{student_name}}` → saved with status DRAFT.
- AC-006b: Admin submits template for approval → status changes to Pending.
- AC-006c: Template in DRAFT or Pending status → dispatch attempt blocked with "Template not approved."

---

**REQ-NTF-007** | Priority: Core (P0) | Tags: [WORKFLOW]
**Feature:** Template approval workflow.

Templates follow a five-state approval lifecycle: Draft → Pending Review → Approved / Rejected → Archived. Only Approved templates may be dispatched. When a new version of a template is approved, the previous version is automatically Archived. System templates (seeded by Prime) can only be managed by Prime Super Admin.

**Actors:** Initiates — School Admin (submit, approve/reject) | Processes — System | Views — School Admin

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Template approval status must be "Approved" for dispatch | BR-NTF-005 |
| 2 | A rejection requires a reason comment | [inferred from workflow] |

**Acceptance Criteria:**
- AC-007a: Admin approves a Pending template → status = Approved; available for dispatch immediately.
- AC-007b: Admin rejects with reason "Missing greeting" → status = Rejected; rejection reason stored; template editable again.
- AC-007c: New version approved → previous version automatically Archived.
- AC-007d: Archived template dispatch attempt → blocked.

---

**REQ-NTF-008** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** Template placeholder rendering.

When a notification is dispatched, the system replaces each `{{key}}` placeholder in the template subject and body with the matching value from the notification context. Non-scalar context values (arrays, objects) are skipped silently. Both `{{key}}` and `{{ key }}` formats are supported.

**Acceptance Criteria:**
- AC-008a: Template body `"Dear {{student_name}}, fee of {{amount}} is due."` with context `{student_name: "Rahul", amount: "5000"}` → rendered as `"Dear Rahul, fee of 5000 is due."`.
- AC-008b: Context value is an array → placeholder left unreplaced (silently skipped).
- AC-008c: Both `{{key}}` and `{{ key }}` forms replaced correctly in the same template.

---

**REQ-NTF-009** | Priority: Standard (P1) | Tags: [CONFIGURATION]
**Feature:** Template versioning.

Multiple versions of the same Template Code for the same channel may exist (unique constraint on school, code, version). When dispatching, the system selects the highest-version Approved template within its effective date range.

**Acceptance Criteria:**
- AC-009a: Two approved versions (v1, v2) for the same code → v2 used for dispatch.
- AC-009b: v2 effective_from is in the future → v1 used until v2 becomes active.
- AC-009c: Creating v2 for a code → v1 remains Approved (not auto-archived until v2 is approved).

---

**REQ-NTF-010** | Priority: Future (P2) | Tags: [CONFIGURATION]
**Feature:** Multi-language template support.

Templates are tagged with a language code (default: English). At dispatch time, the system selects the template matching the recipient's preferred language, falling back to the English template if no match exists.

**Acceptance Criteria:**
- AC-010a: Hindi template exists for a code → recipient with Hindi preference receives Hindi version.
- AC-010b: No Hindi template → recipient with Hindi preference receives English fallback.
- AC-010c: No template in any language → dispatch blocked with "No approved template found."

---

**REQ-NTF-011** | Priority: Core (P0) | Tags: [CONFIGURATION]
**Feature:** India DLT template compliance.

SMS-channel templates for Indian school tenants must carry a DLT Template ID (numeric string issued by TRAI). Templates without this ID are blocked from SMS delivery with a compliance error.

**Acceptance Criteria:**
- AC-011a: SMS template with valid DLT ID → DLT ID passed as `template_id` parameter in every MSG91/Twilio request.
- AC-011b: SMS template missing DLT ID → blocked with "DLT Template ID required for SMS delivery in India."
- AC-011c: Email-channel template → DLT ID field not required or shown.

**Integration:** BR-NTF-010 (DLT compliance rule).

---

### 3.4 Manual Notification Composition [DATA_ENTRY][WORKFLOW]

**REQ-NTF-012** | Priority: Core (P0) | Tags: [DATA_ENTRY][WORKFLOW]
**Feature:** School staff compose and send ad-hoc notifications.

School Admin and Teachers may compose a notification with: title, notification type (Transactional / Promotional / Alert / Reminder / Digest), priority, confidentiality level, delivery schedule (Immediate / Scheduled / Recurring / Triggered), channel assignment, target group or explicit recipient selection, and template selection.

**Actors:** Initiates — School Admin, Teacher | Processes — System | Views — School Admin, Teacher

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | All input must be validated through the system's form validation rules | BR-NTF-001 |
| 2 | Promotional notifications to more than 100 recipients require explicit approval before processing | BR-NTF-009 |

**Acceptance Criteria:**
- AC-012a: Admin creates Immediate notification → enters Delivery Queue within one queue worker cycle (30 seconds or less).
- AC-012b: Teacher creates notification targeting "Class 5A Students" → only Class 5A students are resolved as recipients.
- AC-012c: Teacher attempts to target "All School Parents" → denied; scope limited to own classes.
- AC-012d: Invalid form submission (missing required field) → 422 returned with field-level error messages; no record created.

---

**REQ-NTF-013** | Priority: Standard (P1) | Tags: [WORKFLOW][SCHEDULED]
**Feature:** Schedule notifications for a future date and time.

Admin may specify a future dispatch datetime for a Scheduled notification. The system dispatches it within one scheduler cycle (one minute) after that time. A timezone may be specified so the scheduled time respects the school's local time.

**Acceptance Criteria:**
- AC-013a: Notification scheduled for 09:00 IST → dispatched between 09:00 and 09:01 IST.
- AC-013b: Notification scheduled in the past → blocked with "Scheduled time must be in the future."
- AC-013c: Admin cancels a Scheduled notification before its time → status = Cancelled; no dispatch.

---

**REQ-NTF-014** | Priority: Standard (P1) | Tags: [WORKFLOW][SCHEDULED]
**Feature:** Recurring notification scheduling.

Admin configures a recurring notification with a recurrence pattern (Hourly/Daily/Weekly/Monthly/Yearly/Custom) and a cron expression or RRULE string. The scheduler fires the notification at each computed occurrence until the end date or count limit is reached.

**Acceptance Criteria:**
- AC-014a: Monthly recurrence on the 5th → fires on the 5th of each month at the configured time.
- AC-014b: Each execution creates a Schedule Audit record (status: Completed / Skipped / Failed).
- AC-014c: End count reached → no further dispatches; notification status = Completed.

---

**REQ-NTF-015** | Priority: Standard (P1) | Tags: [WORKFLOW]
**Feature:** Bulk promotional notification approval.

A manually created notification of type Promotional targeting more than 100 resolved recipients remains in Pending Approval status until a School Admin explicitly approves it. No dispatch may begin until approval is recorded.

**Actors:** Initiates — School Admin (compose) | Approves — School Admin | Processes — System

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Promotional to more than 100 recipients → status stays Pending Approval until approved | BR-NTF-009 |

**Acceptance Criteria:**
- AC-015a: Admin creates Promotional notification targeting 200 parents → status = Pending Approval; no dispatch initiated.
- AC-015b: Second Admin approves → status = Approved; dispatch pipeline begins.
- AC-015c: Promotional to 50 recipients → no approval required; dispatched immediately.

---

**REQ-NTF-016** | Priority: Standard (P1) | Tags: [WORKFLOW]
**Feature:** Notification expiry.

A notification with an expiry datetime will not be dispatched after that time. The background scheduler checks the expiry field before processing. Expired notifications are marked with status "Expired" and the queue entries for them are cancelled.

**Acceptance Criteria:**
- AC-016a: Notification with expiry 08:00 reaches the queue at 08:05 → status set to Expired; no delivery attempt.
- AC-016b: Queue entry for an Expired notification → status = Cancelled; delivery log entry written (stage: Expired).

---

### 3.5 Event-Driven Notification Dispatch [INTEGRATION][WORKFLOW]

**REQ-NTF-017** | Priority: Core (P0) | Tags: [INTEGRATION][WORKFLOW]
**Feature:** Any module triggers a notification via the standard event API.

Any Prime-AI module fires the platform event `SystemNotificationTriggered` with an Event Code and a context payload. The Notification module listens asynchronously and processes the notification without blocking the originating module.

**Actors:** Initiates — Any Module (automated) | Processes — Notification Module | Views — School Admin (results in logs)

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Unrecognised Event Code → warning logged; no exception thrown; no orphan records | BR-NTF-006 |

**Acceptance Criteria:**
- AC-017a: Module fires `FEE_DUE_REMINDER` → notification located by event code; dispatch pipeline starts.
- AC-017b: Module fires unknown code `UNKNOWN_CODE` → warning logged; no exception; no delivery.
- AC-017c: Originating module's web request is not blocked by notification processing.

**Integration:** Standard pattern: `SystemNotificationTriggered::dispatch('EVENT_CODE', ['key' => 'value'])`.

---

**REQ-NTF-018** | Priority: Core (P0) | Tags: [WORKFLOW][INTEGRATION]
**Feature:** Asynchronous queued dispatch listener.

The notification listener processes the event in a background queue job (not synchronously in the web request). It retries up to 3 times with a 10-second backoff on failure. After 3 failures, the job is recorded in the failed jobs log and an administrator alert is fired.

**Acceptance Criteria:**
- AC-018a: Listener queued → processing occurs outside the HTTP request cycle.
- AC-018b: First attempt fails → retried after 10 seconds; up to 3 attempts total.
- AC-018c: All 3 attempts fail → job recorded in failed jobs log; system alert fired.

---

**REQ-NTF-019** | Priority: Core (P0) | Tags: [WORKFLOW]
**Feature:** Multi-channel dispatch pipeline.

For each notification, the system: (1) fetches the highest approved template per active channel, (2) renders the template with the context payload, (3) resolves the target recipients, (4) creates Delivery Queue entries, and (5) dispatches to each channel. Failure on one channel does not affect other channels.

**Acceptance Criteria:**
- AC-019a: Notification has Email + In-App channels → both dispatched independently; Email failure does not block In-App.
- AC-019b: No approved template found for a channel → that channel skipped; warning logged; other channels continue.
- AC-019c: Template rendered with full context → personalized subject and body stored per resolved recipient.

---

**REQ-NTF-020** | Priority: Core (P0) | Tags: [INTEGRATION]
**Feature:** Email delivery.

The system delivers email notifications using the school's configured Email provider (AWS SES or SMTP). The rendered template subject and body form the email content. Attachments may be linked via the media library.

**Acceptance Criteria:**
- AC-020a: Rendered email dispatched via configured SMTP provider → delivery log entry with stage "Sent" created.
- AC-020b: SMTP connection fails → delivery log stage = "Failed"; error message stored; retry queued.

---

**REQ-NTF-021** | Priority: Core (P0) | Tags: [NOTIFICATION]
**Feature:** In-app notification delivery.

In-app notifications are delivered directly to the user's notification inbox via Laravel's notification system. No external provider is required.

**Acceptance Criteria:**
- AC-021a: In-app notification dispatched → appears in recipient's inbox immediately.
- AC-021b: Bell counter increments by 1 for the recipient within 30 seconds.

---

**REQ-NTF-022** | Priority: Core (P0) | Tags: [INTEGRATION]
**Feature:** SMS delivery with DLT compliance.

The system delivers SMS notifications via the configured SMS provider (MSG91 or Twilio), passing the DLT Template ID and sender ID in the request. SMS without a registered DLT Template ID are blocked before dispatch.

**Acceptance Criteria:**
- AC-022a: SMS dispatched with valid DLT ID → provider accepts; delivery log = Sent; provider message ID stored.
- AC-022b: SMS template missing DLT ID → blocked with compliance error; no external API call made.
- AC-022c: Provider rejects SMS (DND number) → delivery log = Failed; error message stored; retry queued.

**Integration:** BR-NTF-010. Requires `ntf_provider_master` DLT sender ID configuration.

---

**REQ-NTF-023** | Priority: Standard (P1) | Tags: [INTEGRATION]
**Feature:** Push notification delivery (FCM/APNS).

The system delivers push notifications to registered mobile or browser devices using device tokens stored in the device registry. Invalid or expired tokens are caught, the device record is marked inactive, and the delivery is logged as failed.

**Acceptance Criteria:**
- AC-023a: Valid FCM token → notification delivered; delivery log = Sent.
- AC-023b: Expired token → FCM error caught; device record marked inactive; log = Failed.
- AC-023c: User with no registered devices → push delivery skipped; other channels unaffected.

---

**REQ-NTF-024** | Priority: Standard (P1) | Tags: [INTEGRATION]
**Feature:** WhatsApp delivery.

The system delivers WhatsApp notifications via Meta Cloud API using pre-approved WhatsApp template names and language parameters. Delivery status is tracked.

**Acceptance Criteria:**
- AC-024a: Valid WhatsApp template dispatched → Meta API accepts; delivery log = Sent.
- AC-024b: Meta API error (template not approved) → delivery log = Failed; error message stored.

---

### 3.6 Recipient Targeting [DATA_ENTRY][WORKFLOW]

**REQ-NTF-025** | Priority: Core (P0) | Tags: [DATA_ENTRY][CONFIGURATION]
**Feature:** Target Group management.

School Admin creates named target groups as Static (fixed member list) or Dynamic (query-based, resolved at dispatch time). Examples: "Class 5 Parents" (Static), "All Fee Defaulters" (Dynamic). System groups are pre-seeded and cannot be deleted.

**Acceptance Criteria:**
- AC-025a: Static group created with 25 parent users → those 25 appear as resolved recipients at dispatch.
- AC-025b: Dynamic group `{role: PARENT, class_id: 5}` → all parents of Class 5 resolved at dispatch time.
- AC-025c: Admin attempts to delete a system group → blocked with "System groups cannot be deleted."
- AC-025d: Deleted static group → any notification referencing it warns Admin before dispatch.

---

**REQ-NTF-026** | Priority: Core (P0) | Tags: [DATA_ENTRY]
**Feature:** Notification target assignment.

Each notification may have multiple target entries specifying who receives it. Target types (from the school's configuration master): Student, Parent, Teacher, Class, Section, Group, or Individual. At dispatch, each target type is expanded to individual user records.

**Acceptance Criteria:**
- AC-026a: Target = Class 7A → all enrolled students in Class 7A resolved.
- AC-026b: Target = Section B of Class 7 → only Section B students resolved.
- AC-026c: Target = Group "Fee Defaulters" → all members of that group resolved.
- AC-026d: Target = Individual (specific parent) → only that person resolved.

---

**REQ-NTF-027** | Priority: Core (P0) | Tags: [WORKFLOW]
**Feature:** Recipient resolution pipeline.

Before dispatch, the system expands all notification targets to individual (person × channel) rows. The resolution pipeline: (1) expands each target to individual users, (2) filters out opted-out users for each channel, (3) applies quiet hours deferral, (4) groups results into batches with a batch ID for parallel processing.

**Acceptance Criteria:**
- AC-027a: Class target of 40 students, Email channel → 40 resolved recipient rows created (or fewer if some opted out).
- AC-027b: Opted-out user in the class → that user's Email recipient row is not created.
- AC-027c: User in quiet hours window → recipient row created with scheduled delivery time = end of quiet window.
- AC-027d: All targets resolve to zero recipients → notification marked with status "No Recipients"; no queue entries created.

---

### 3.7 User Preferences & Device Registry [DATA_ENTRY][CONFIGURATION]

**REQ-NTF-028** | Priority: Core (P0) | Tags: [DATA_ENTRY][CONFIGURATION]
**Feature:** Per-user notification preference management.

Each user may configure their notification preferences per channel: enable/disable the channel, GDPR opt-in/opt-out (with timestamps), quiet hours window and timezone, daily digest mode, and a priority threshold (only receive notifications at or above a set priority level).

**Actors:** Initiates — Student, Parent, Teacher | Processes — System | Views — User (own preferences only)

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Opt-out is absolute; no notification may override it | BR-NTF-002 |
| 2 | Quiet hours defers delivery; does not cancel it | BR-NTF-003 |

**Acceptance Criteria:**
- AC-028a: User disables Email channel → no email delivered even for system events.
- AC-028b: User opts out at 14:00 → notification queued at 13:55 for that user is cancelled (queue entry set to Cancelled).
- AC-028c: Quiet hours 22:00–07:00 → notification arriving at 23:30 deferred to 07:00.
- AC-028d: User sets priority threshold to "High" → notifications of Normal or Low priority not delivered to that user.

---

**REQ-NTF-029** | Priority: Standard (P1) | Tags: [INTEGRATION]
**Feature:** Mobile and browser device token registration.

Mobile apps and browser clients register FCM/APNS device tokens via an API endpoint. Duplicate tokens for the same user are silently ignored (upsert). Stale tokens (expired by provider) are marked inactive. The last-active timestamp is updated on each successful delivery to that device.

**Acceptance Criteria:**
- AC-029a: App submits new token → device record created; subsequent push dispatches use this token.
- AC-029b: App submits same token again → upsert; no duplicate record; last-active updated.
- AC-029c: FCM reports token invalid → device marked inactive; future deliveries skip it.

---

### 3.8 Delivery Queue Management [WORKFLOW][SCHEDULED]

**REQ-NTF-030** | Priority: Core (P0) | Tags: [WORKFLOW][SCHEDULED]
**Feature:** Delivery queue entry creation and processing.

One Delivery Queue entry is created per resolved recipient per channel. Entries carry: status (Pending/Processing/Sent/Failed/Retry/Cancelled), delivery priority, scheduled delivery time, worker lock fields, attempt count, and next retry time.

**Actors:** Initiates — System (automatic) | Processes — Queue Worker | Views — School Admin

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Worker locks entries before processing to prevent duplicate delivery | [inferred from design] |
| 2 | Lock timeout of 5 minutes — stale locks auto-released for reprocessing | [inferred from design] |

**Acceptance Criteria:**
- AC-030a: Recipient resolved → one queue entry created with status Pending.
- AC-030b: Worker picks up entry → sets locked_by + lock timestamp; status = Processing.
- AC-030c: Worker crashes → lock expires after 5 minutes; another worker reclaims and processes.
- AC-030d: Admin views queue monitor → paginated list with filter by status, channel, date range.

---

**REQ-NTF-031** | Priority: Standard (P1) | Tags: [WORKFLOW]
**Feature:** Delivery retry logic.

On delivery failure, the system increments the attempt count, sets the status to Retry, and computes the next retry time using exponential backoff (attempt count multiplied by retry delay minutes). When the maximum attempts are exhausted, the status is set to Failed and a delivery log entry records the final error.

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Exceeding rate limits defers delivery to the next window; never drops silently | BR-NTF-007 |

**Acceptance Criteria:**
- AC-031a: Delivery fails once → status = Retry; next attempt in (1 × retry_delay_minutes).
- AC-031b: Delivery fails max times → status = Failed; `last_error` populated; delivery log written.
- AC-031c: Rate limit exceeded → delivery deferred to next window; status = Retry; not Failed.

---

**REQ-NTF-032** | Priority: Standard (P1) | Tags: [WORKFLOW]
**Feature:** Admin queue monitor — manual retry and cancel.

Admin may manually retry Failed queue entries or cancel Pending entries from the queue monitor UI.

**Acceptance Criteria:**
- AC-032a: Admin manually retries a Failed entry → status reset to Pending; attempt count reset; dispatch retried.
- AC-032b: Admin cancels a Pending entry → status = Cancelled; recipient receives nothing; delivery log records cancellation.

---

### 3.9 Delivery Logging & Audit [REPORT][WORKFLOW]

**REQ-NTF-033** | Priority: Core (P0) | Tags: [REPORT][WORKFLOW]
**Feature:** Append-only delivery audit trail.

Every delivery attempt creates a Delivery Log entry recording: notification, channel, resolved recipient, provider, delivery stage (Queued / Sent / Delivered / Read / Clicked / Bounced / Complaint / Unsubscribed), provider message ID, stage timestamps, response payload, error message, duration, and cost.

| # | Business Rule | Rule ID |
|---|---------------|---------|
| 1 | Delivery Log records are append-only; no editing or deletion allowed | BR-NTF-008 |

**Acceptance Criteria:**
- AC-033a: Successful email delivery → log entry with stage = Sent, delivered_at, duration_ms, provider_message_id.
- AC-033b: Bounce webhook received → new log entry with stage = Bounced; bounced_at set; failed_count incremented.
- AC-033c: Admin attempts to delete a delivery log record via UI → action blocked (405 or 403 returned).

---

**REQ-NTF-034** | Priority: Standard (P1) | Tags: [REPORT]
**Feature:** Read and click tracking for in-app notifications.

When a user opens their inbox and views a notification, `read_at` is set. When the user clicks a call-to-action link within the notification, `clicked_at` is set. These events are fired via lightweight AJAX calls and recorded as new delivery log entries.

**Acceptance Criteria:**
- AC-034a: User opens notification in inbox → read_at set; read_count on notification incremented; bell count decremented.
- AC-034b: User clicks link → clicked_at set; click_count incremented.

---

**REQ-NTF-035** | Priority: Standard (P1) | Tags: [INTEGRATION]
**Feature:** Provider delivery receipt webhooks.

The system exposes a secured webhook endpoint for SMS and email providers that support delivery receipts (MSG91, AWS SES bounce/complaint). On receipt, the delivery log entry is updated with the latest delivery stage and timestamps.

**Acceptance Criteria:**
- AC-035a: MSG91 DND callback received → delivery log updated to stage = Failed; no auth required on the webhook endpoint (must be outside auth middleware).
- AC-035b: AWS SES bounce notification received → stage = Bounced; bounced_at populated.

---

### 3.10 Notification Inbox (In-App) [NOTIFICATION][DASHBOARD]

**REQ-NTF-036** | Priority: Core (P0) | Tags: [NOTIFICATION][DASHBOARD]
**Feature:** Notification bell widget in the school header.

The school tenant header displays a bell icon showing the count of unread in-app notifications for the current user. The count is refreshed via AJAX polling every 30 seconds (or in real time via WebSocket if Laravel Echo is configured).

**Acceptance Criteria:**
- AC-036a: New in-app notification dispatched → bell count increments within 30 seconds.
- AC-036b: All notifications read → bell count = 0.

---

**REQ-NTF-037** | Priority: Core (P0) | Tags: [NOTIFICATION][DASHBOARD]
**Feature:** Notification inbox list view.

Clicking the bell opens an inbox listing all in-app notifications for the current user: title, summary text, received timestamp, read/unread status, source module badge, and a deep-link URL to the source record.

**Acceptance Criteria:**
- AC-037a: Inbox shows all in-app notifications for the current user; paginated.
- AC-037b: Unread notifications visually distinguished from read.
- AC-037c: Deep-link navigates to the source record (e.g., fee invoice, exam result).
- AC-037d: Empty state shown when no notifications exist.

---

**REQ-NTF-038** | Priority: Core (P0) | Tags: [NOTIFICATION]
**Feature:** Mark individual and all notifications as read.

Users may mark individual notifications as read or use a "Mark all as read" bulk action. Read state is persisted immediately.

**Acceptance Criteria:**
- AC-038a: User marks one notification read → read_at set; bell count decrements by 1.
- AC-038b: User clicks "Mark all as read" → all unread marked; bell count = 0; action completes within 2 seconds.
- AC-038c: Notification already read → mark-read action is idempotent (no error).

---

### 3.11 Notification Threads [DATA_ENTRY]

**REQ-NTF-039** | Priority: Standard (P1) | Tags: [DATA_ENTRY]
**Feature:** Thread grouping for related notifications.

Related notifications may be grouped into threads of type Conversation (bidirectional), Digest (periodic summary), or Broadcast (one-to-many). Each thread has a subject, optional parent thread for nesting, and automatic counters for total notifications and participant count.

**Acceptance Criteria:**
- AC-039a: Admin groups fee reminder and receipt notifications into a "Fee" thread → both appear under the thread.
- AC-039b: "Recalculate" action on a thread → total_notifications and participant_count refreshed from member records.
- AC-039c: A notification may belong to exactly one thread; duplicate assignment → rejected.

---

### 3.12 Scheduled & Recurring Processing [SCHEDULED][WORKFLOW]

**REQ-NTF-040** | Priority: Standard (P1) | Tags: [SCHEDULED][WORKFLOW]
**Feature:** Scheduled notification dispatch command.

A Laravel scheduled command `notifications:process-due` runs every minute. It selects Scheduled notifications whose dispatch time has arrived and are in Approved status, then initiates the dispatch pipeline for each.

**Acceptance Criteria:**
- AC-040a: Notification scheduled for 08:00 → dispatched by 08:01.
- AC-040b: Expired notification reached by command → status set to Expired; not dispatched.

---

**REQ-NTF-041** | Priority: Standard (P1) | Tags: [SCHEDULED][WORKFLOW]
**Feature:** Recurring notification execution and audit.

After each recurring dispatch, the system computes the next occurrence from the cron expression, creates a Schedule Audit record for the execution (status: Completed/Skipped/Failed), and increments the execution count. Processing stops when the end date or count limit is reached.

**Acceptance Criteria:**
- AC-041a: Daily recurring notification → fires each day; Schedule Audit record created per execution.
- AC-041b: No recipients resolved → Schedule Audit status = Skipped; no queue entries created.
- AC-041c: Execution count reaches `recurring_end_count` → no further dispatches; notification status = Completed.

---

**REQ-NTF-042** | Priority: Standard (P1) | Tags: [REPORT][WORKFLOW]
**Feature:** Schedule audit log view.

Admin may view the complete history of scheduled notification executions with filters by notification, date range, and execution status.

**Acceptance Criteria:**
- AC-042a: Schedule audit list shows execution datetime, status, and any error message per execution.
- AC-042b: Admin can filter by "Failed" status to identify recurring notifications that are not firing.

---

## 4. Business Rules Register

| Rule ID | Rule (business statement) | Type | Trigger | Enforcement Point | Priority |
|---------|--------------------------|------|---------|-------------------|---------|
| BR-NTF-001 | A notification may only be dispatched if its status is Approved or Scheduled; Draft notifications must never be processed | Workflow | Dispatch pipeline start | Queue worker + controller | P0 |
| BR-NTF-002 | A user who has opted out of a channel shall never receive notifications on that channel — this overrides admin instructions, system events, and event-driven triggers | Permission | Recipient resolution | RecipientResolutionService | P0 |
| BR-NTF-003 | If the current time (in the user's configured timezone) falls within their quiet hours window, delivery must be deferred to end-of-quiet-window, not cancelled | Workflow | Recipient resolution | RecipientResolutionService | P0 |
| BR-NTF-004 | System templates (seeded by Prime Super Admin) may only be created, edited, or deleted by Prime Super Admin; School Admins may clone them only | Permission | Template create/edit/delete | TemplateController Gate check | P0 |
| BR-NTF-005 | A template's approval status must be "Approved" for it to be used in any dispatch; Draft, Pending, Rejected, and Archived templates are blocked | Validation | Template selection at dispatch | NotificationService | P0 |
| BR-NTF-006 | An unrecognised Event Code (no matching notification record) is logged as a warning and silently ignored; no exception is thrown and no orphan records are created | Workflow | Event listener | ProcessSystemNotification listener | P0 |
| BR-NTF-007 | Exceeding a channel's rate limit (per-minute, daily, or monthly) must queue the delivery for the next available window; silent dropping of messages is prohibited | Validation | Queue worker | ProcessNotificationJob | P1 |
| BR-NTF-008 | Delivery log records are append-only; no API endpoint, UI action, or admin operation may delete or update a delivery log entry | Validation | DeliveryLogController | Controller + model (no destroy route) | P0 |
| BR-NTF-009 | A manually created Promotional notification targeting more than 100 resolved recipients must remain in Pending Approval status until explicitly approved by a School Admin | Workflow | Notification creation | NotificationManageController | P1 |
| BR-NTF-010 | SMS notifications sent by Indian school tenants must use TRAI-registered DLT Template IDs; a template without a registered DLT Template ID on the SMS channel is blocked from delivery with a compliance error | Validation | SMS dispatch | NotificationService (SMS adapter) | P0 |
| BR-NTF-011 | Provider API credentials (API key, API secret) must be stored encrypted using Laravel's encrypted cast; plaintext storage in the database is a security violation | Validation | Provider save | ProviderMaster model | P0 |
| BR-NTF-012 | A notification whose expiry datetime has passed must not be dispatched; the queue worker must check expiry before processing and mark expired notifications accordingly | Workflow | Queue worker | ProcessNotificationJob | P1 |
| BR-NTF-013 | Fallback channel chains must not be circular; on channel create or update, the system validates that no circular reference exists (depth check up to 5 hops) | Validation | Channel save | ChannelMasterController | P1 |

---

## 5. Data Requirements

### 5.1 Business Entities

**Entity: Delivery Channel**
The school's configuration record for a communication medium (Email, SMS, WhatsApp, In-App, Push). Controls rate limits, retry behavior, cost tracking, and fallback routing.
- Privacy: Internal (configuration data, no PII)

**Entity: External Provider**
An external gateway service (MSG91, Twilio, AWS SES, Firebase FCM, Meta WhatsApp). Stores encrypted API credentials and the DLT sender ID for SMS.
- Privacy: Confidential (encrypted credentials)

**Entity: Message Template**
A reusable, versioned, approval-gated message body with placeholder variables. Linked to one channel and one language.
- Privacy: Internal (template content; may reference PII field names but not values)

**Entity: Notification**
The "envelope" record for one dispatch event — manual or event-driven. Carries type, schedule, status, recipient targets, and running delivery counters.
- Privacy: Internal (notification metadata); Sensitive if notification content references student records

**Entity: Target Group**
A named set of recipients (Static or Dynamic). Used to target all parents of a class, all teachers, or custom lists.
- Privacy: Internal (group definitions; member list may reference PII)

**Entity: Resolved Recipient**
One (user × channel) dispatch row with the personalized rendered subject and body. Created at dispatch time from target expansion.
- Privacy: Confidential (personalized content including student names, amounts)

**Entity: Delivery Queue Entry**
One pending work item for a Resolved Recipient. Carries worker locking fields, attempt count, and retry schedule.
- Privacy: Internal (operational queue data)

**Entity: Delivery Log**
Immutable audit record of one delivery attempt. Records stage, timestamps, provider response, error, and cost.
- Privacy: Sensitive (IP address, user agent for read/click tracking; subject to data retention policy)

**Entity: User Preference**
A user's per-channel notification settings: enabled/disabled, opt-in/opt-out with GDPR timestamps, quiet hours, digest mode, priority threshold.
- Privacy: Sensitive (consent timestamps, user behavioral preferences)

**Entity: User Device**
A registered mobile or browser device with an FCM/APNS push token. Updated on every successful push delivery.
- Privacy: Confidential (device tokens are sensitive identifiers)

**Entity: Notification Thread**
A grouping container for related notifications with type (Conversation/Digest/Broadcast), subject, and counters.
- Privacy: Internal

**Entity: Schedule Audit**
Historical record of each scheduled/recurring notification execution with status and error details.
- Privacy: Internal

### 5.2 Privacy Classification Summary

| Entity | Privacy Level | Notes |
|--------|--------------|-------|
| Delivery Channel | Internal | No PII |
| External Provider | Confidential | Encrypted credentials |
| Message Template | Internal | Template text, no PII values |
| Notification | Internal/Sensitive | Depends on content |
| Target Group | Internal | Group definitions |
| Resolved Recipient | Confidential | Personalized rendered content |
| Delivery Queue Entry | Internal | Operational |
| Delivery Log | Sensitive | IP/UA for read tracking; data retention applies |
| User Preference | Sensitive | GDPR consent timestamps |
| User Device | Confidential | FCM/APNS tokens |
| Notification Thread | Internal | |
| Schedule Audit | Internal | |

---

## 6. Workflows

### Workflow 1: Event-Driven Notification Dispatch (Full Pipeline)
**Trigger:** Any module fires `SystemNotificationTriggered('EVENT_CODE', context_payload)`
**End States:** Completed / Partial / Failed / No Recipients
**Actors / Swimlanes:** Originating Module | Notification System | Queue Worker | External Provider

**Steps:**
1. [Originating Module] fires event with Event Code and payload context
2. [System] queued listener (`ProcessSystemNotification`) picks up event asynchronously
3. [System] looks up Notification record matching the Event Code → if not found: log warning, stop (BR-NTF-006)
4. [System] for each active channel assigned to the Notification:
   - Fetch highest-version Approved template matching the Event Code and channel
   - If no Approved template found: skip channel; log warning
   - Render template: replace `{{placeholders}}` with payload values
   - Expand target groups to individual users; filter opted-out users; apply quiet-hours deferral
   - Create Resolved Recipient rows (batch_id assigned for bulk grouping)
   - Create Delivery Queue entries (one per resolved recipient)
5. [Queue Worker] picks up Pending queue entries ordered by priority then scheduled_at
6. [Queue Worker] locks entry (locked_by = worker ID, locked_at = now)
7. [Queue Worker] dispatches to channel (Email, In-App, SMS, Push, or WhatsApp)
8. [System] writes Delivery Log entry (stage, provider_message_id, duration_ms, cost)
9. [System] updates atomic counters on Notification record
10. [System] marks Resolved Recipient as processed

**Exception Paths:**
- Worker crashes mid-batch → lock expires after 5 minutes; next worker reclaims and reprocesses
- Provider API down → delivery attempt = Failed; retry queued with exponential backoff
- Rate limit exceeded → delivery deferred to next window; not dropped (BR-NTF-007)
- Template rendering fails → log error; skip that recipient; continue with others

---

### Workflow 2: Manual Notification Composition and Send
**Trigger:** School Admin or Teacher navigates to Create Notification
**End States:** Notification Dispatched / Saved as Draft / Cancelled
**Actors:** School Admin or Teacher | System | Approver (optional)

**Steps:**
1. [Admin/Teacher] fills in notification form: title, type, priority, schedule, channel(s), target group(s), template selection
2. [System] validates input; returns errors if invalid
3. [System] checks: if type = Promotional AND estimated recipients > 100 → set status = Pending Approval (BR-NTF-009)
4. [Admin/Approver] approves Promotional notification (if required) → status = Approved
5. [System] for Immediate schedule → initiates dispatch pipeline (Workflow 1, steps 4–10)
6. [System] for Scheduled → saves with status = Scheduled; `notifications:process-due` dispatches at the right time
7. [System] for Recurring → saves recurring_pattern and expression; scheduler computes each occurrence

**Exception Paths:**
- Admin cancels before send → status = Cancelled; no dispatch
- Expiry datetime reached before processing → status = Expired; queue entries cancelled

---

### Workflow 3: Template Approval
**Trigger:** Author submits template for review
**End States:** Template Approved (ready for dispatch) / Rejected (returned to draft)
**Actors:** Author (Admin/Teacher) | Reviewer (School Admin or Prime Super Admin)

**Steps:**
1. [Author] creates template, fills subject/body/placeholders; saves as Draft
2. [Author] clicks "Submit for Approval" → status = Pending Review
3. [Reviewer] reviews template content and DLT compliance (if SMS)
4a. [Reviewer] approves → status = Approved; previous version (if same code) auto-archived
4b. [Reviewer] rejects with reason → status = Rejected; reason stored; Author notified
5. [Author] may edit Rejected template and resubmit

**Exception Paths:**
- System template submitted for edit → only Prime Super Admin may submit/approve
- Template used in active notification is archived → active notification continues using the version Approved at dispatch time

---

### Workflow 4: User Opt-Out
**Trigger:** User visits User Preferences and disables a channel or clicks unsubscribe link
**End States:** Opt-Out Recorded / Future Deliveries Blocked
**Actors:** User | System

**Steps:**
1. [User] disables channel or clicks unsubscribe → `is_opted_in = 0`, `opted_out_at = now()`
2. [System] immediately: cancels any Pending queue entries for that user + channel
3. [System] all future recipient resolution calls skip this user for this channel (BR-NTF-002)
4. [System] if user re-enables in preferences → `is_opted_in = 1`, `opted_in_at = now()`

**Exception Paths:**
- Admin cannot re-opt-in a user on their behalf; only the user may reverse opt-out

---

### Workflow 5: DLT SMS Compliance (India)
**Trigger:** SMS dispatch attempted for an Indian school tenant
**End States:** SMS Dispatched with DLT compliance / Blocked with compliance error
**Actors:** School Admin (configuration) | System | TRAI DLT Portal (external) | SMS Provider

**Pre-requisites (one-time setup):**
1. [Admin] registers on TRAI DLT portal as Principal Entity
2. [Admin] creates SMS templates on DLT portal (text must match NTF template body)
3. [DLT portal] returns numeric template ID
4. [Admin] enters DLT Template ID in the NTF template edit form; saves

**Dispatch:**
1. [System] resolves SMS channel for recipient
2. [System] checks: `ntf_templates.dlt_template_id IS NOT NULL` → else block with error
3. [System] constructs MSG91/Twilio request with `{template_id: dlt_id, sender: sender_id, mobile: phone, ...}`
4. [Provider] processes and returns `message_id`
5. [System] writes delivery log with provider_message_id, stage = Sent

---

### Workflow 6: Scheduled and Recurring Notification Execution
**Trigger:** Laravel scheduler runs `notifications:process-due` every minute
**End States:** Notification Dispatched / Skipped (no recipients) / Expired
**Actors:** System Scheduler | System

**Steps:**
1. [Scheduler] selects all Approved notifications with `schedule_type = SCHEDULED` and `scheduled_at <= NOW()`
2. [System] checks `expires_at` → if past: mark Expired; skip
3. [System] initiates dispatch pipeline (Workflow 1, steps 4–10)
4. [Scheduler] selects all Recurring notifications where next occurrence is due
5. [System] initiates dispatch pipeline for each recurring notification
6. [System] computes next occurrence from `recurring_expression` (cron); stores in schedule audit
7. [System] creates Schedule Audit record: execution_status, actual_execution_time, error_message
8. [System] increments `recurring_executed_count`; checks against `recurring_end_count`

---

## 7. Reporting & Analytics

### RPT-NTF-001 — Delivery Logs Report
**Purpose:** Full audit trail of all delivery attempts for a notification or time period
**Audience:** School Admin, Prime Support
**Frequency:** On demand
**Contents:** Notification title, channel, recipient name, delivery stage, provider message ID, delivered/read/clicked/bounced timestamps, error message, cost
**Filters:** Notification, Channel, Delivery Stage, Date Range, Recipient
**Export:** PDF / Excel / CSV
**Rules:** Append-only data; no modification of displayed records; aligned with BR-NTF-008

---

### RPT-NTF-002 — Notification Analytics Dashboard
**Purpose:** Summary delivery performance per notification or per period
**Audience:** School Admin
**Frequency:** Real-time (refreshed on view)
**Contents:** Total recipients, sent count, delivered count, failed count, read count, click count, bounce count, delivery success rate (%), average delivery duration (ms), estimated vs actual cost
**Filters:** Notification Type, Channel, Date Range, Priority
**Export:** PDF / Excel

---

### RPT-NTF-003 — Channel Performance Report
**Purpose:** Compare delivery performance and cost across channels
**Audience:** School Admin
**Frequency:** Monthly
**Contents:** Per channel: total dispatched, success rate, bounce rate, average delivery time, total cost, cost per successfully delivered message
**Filters:** Academic period, Channel, Date Range
**Export:** Excel / CSV

---

### RPT-NTF-004 — Schedule Audit History
**Purpose:** History of scheduled and recurring notification executions
**Audience:** School Admin
**Frequency:** On demand
**Contents:** Notification title, scheduled time, actual execution time, execution status (Completed/Skipped/Failed), error message, recipients resolved count
**Filters:** Notification, Status, Date Range
**Export:** Excel / CSV

---

## 8. Future Enhancements

| ENH ID | Enhancement | Basis | Promote to REQ when |
|--------|------------|-------|---------------------|
| ENH-NTF-001 | AI-Powered Message Content Optimisation | V1 requirement Phase 2 list | AI module available and approved |
| ENH-NTF-002 | Predictive Delivery Time Optimisation — ML model to choose optimal send time per recipient | V1 requirement Phase 2 list | Sufficient delivery log history (3+ months) |
| ENH-NTF-003 | Channel Adapter Pattern — typed `ChannelAdapter` interface replacing switch/case | Architecture recommendation | Next major refactor sprint |
| ENH-NTF-004 | Provider Webhook Integration — secured endpoints for MSG91 DND callbacks, AWS SES bounce SNS, FCM token refresh | V2 requirement Section 14.4 | P1 sprint completion |
| ENH-NTF-005 | Rate Limit Enforcement via Laravel RateLimiter — per-minute sliding window at queue worker level | V2 requirement Section 14.4 | After ProcessNotificationJob is implemented |
| ENH-NTF-006 | Event Code Registry Command — `php artisan notifications:validate-events` | V2 recommendation | After delivery pipeline is stable |
| ENH-NTF-007 | A/B Template Testing — version A to 50% of recipients, version B to the other 50%; auto-select winner by open rate | V1 requirement Phase 2 | Analytics module available |

---

## 9. Non-Functional Requirements

### 9.1 Performance
- IMMEDIATE priority notifications must enter the delivery pipeline within 30 seconds of the event being fired.
- NORMAL priority notifications must be dispatched within 2 minutes.
- Bulk batches up to 10,000 recipients must complete dispatch within 15 minutes with the default queue worker count.
- In-app bell count must refresh within 30 seconds of a new notification arriving.
- Delivery queue monitor must paginate a 10,000-item backlog without timeout.
- The `NotificationManageController::index()` tab view must load within 3 seconds; each sub-tab must load independently via AJAX.

### 9.2 Security
- Provider API credentials must be stored using Laravel's `encrypted` cast at the model level. Plaintext storage is a P0 violation (BR-NTF-011).
- All notification routes must use `tenant.notification.*` Gate prefixes (not `prime.*`); the wrong prefix bypasses tenant scoping (current BUG-NTF-003).
- Device tokens (FCM/APNS) must not appear in logs, API responses, or error messages in full.
- Webhook endpoints for provider callbacks must be outside the `auth` middleware (Razorpay webhook lesson — SEC-004 known pattern).
- Template body for in-app channel must be sanitized to prevent XSS.
- Email body HTML must be purified to strip dangerous tags while allowing formatting tags.
- Delivery log IP address and user agent are subject to the platform's data retention policy.

### 9.3 Usability
- Template placeholder syntax must be validated on save with a clear list of supported variables per event code.
- Cost estimate must appear before confirming a bulk notification.
- Quiet hours and opt-out must be clearly labeled in User Preferences with explanations of the effect.
- The notification inbox must display a helpful empty state: "No notifications yet. You'll see updates from your school here."
- Admin must be able to filter the delivery queue by Failed status and bulk-retry in one action.

---

## 10. Gap Analysis Readiness Index

### 10.1 Coverage Table

| REQ ID | Feature | Priority | DDL Entity Needed | Screen Needed | API Needed | Test Case Needed |
|--------|---------|----------|:-----------------:|:-------------:|:----------:|:----------------:|
| REQ-NTF-001 | Channel Configuration | P0 | Yes | Yes | No | Yes |
| REQ-NTF-002 | Channel Activation Toggle | P0 | No | Yes | No | Yes |
| REQ-NTF-003 | Provider Gateway Configuration | P0 | Yes | Yes | No | Yes |
| REQ-NTF-004 | Provider Test Connection | P1 | No | Yes | No | Yes |
| REQ-NTF-005 | DLT SMS Provider Setup | P0 | No | Yes | No | Yes |
| REQ-NTF-006 | Message Template Management | P0 | No | Yes | No | Yes |
| REQ-NTF-007 | Template Approval Workflow | P0 | No | Yes | No | Yes |
| REQ-NTF-008 | Template Placeholder Rendering | P0 | No | No | No | Yes |
| REQ-NTF-009 | Template Versioning | P1 | No | Yes | No | Yes |
| REQ-NTF-010 | Multi-Language Template Support | P2 | No | Yes | No | Yes |
| REQ-NTF-011 | DLT Template Compliance | P0 | Yes (alter) | Yes | No | Yes |
| REQ-NTF-012 | Manual Notification Composition | P0 | No | Yes | No | Yes |
| REQ-NTF-013 | Notification Scheduling | P1 | No | Yes | No | Yes |
| REQ-NTF-014 | Recurring Scheduling | P1 | No | Yes | No | Yes |
| REQ-NTF-015 | Bulk Promotional Approval | P1 | No | Yes | No | Yes |
| REQ-NTF-016 | Notification Expiry | P1 | No | No | No | Yes |
| REQ-NTF-017 | Event-Driven Trigger API | P0 | No | No | No | Yes |
| REQ-NTF-018 | Asynchronous Queued Dispatch | P0 | No | No | No | Yes |
| REQ-NTF-019 | Multi-Channel Dispatch Pipeline | P0 | No | No | No | Yes |
| REQ-NTF-020 | Email Delivery | P0 | No | No | No | Yes |
| REQ-NTF-021 | In-App Delivery | P0 | No | No | No | Yes |
| REQ-NTF-022 | SMS Delivery | P0 | No | No | No | Yes |
| REQ-NTF-023 | Push Notification Delivery | P1 | No | No | No | Yes |
| REQ-NTF-024 | WhatsApp Delivery | P1 | No | No | No | Yes |
| REQ-NTF-025 | Target Group Management | P0 | No | Yes | No | Yes |
| REQ-NTF-026 | Notification Target Assignment | P0 | No | Yes | No | Yes |
| REQ-NTF-027 | Recipient Resolution Pipeline | P0 | No | No | No | Yes |
| REQ-NTF-028 | User Channel Preferences | P0 | No | Yes | No | Yes |
| REQ-NTF-029 | Device Token Registration | P1 | No | No | Yes | Yes |
| REQ-NTF-030 | Delivery Queue Entry & Processing | P0 | No | Yes | No | Yes |
| REQ-NTF-031 | Delivery Retry Logic | P1 | No | No | No | Yes |
| REQ-NTF-032 | Admin Queue Monitor Actions | P1 | No | Yes | No | Yes |
| REQ-NTF-033 | Append-Only Delivery Audit Trail | P0 | No | Yes | No | Yes |
| REQ-NTF-034 | Read and Click Tracking | P1 | No | No | Yes | Yes |
| REQ-NTF-035 | Provider Webhook Callbacks | P1 | No | No | Yes | Yes |
| REQ-NTF-036 | Notification Bell Widget | P0 | No | Yes | Yes | Yes |
| REQ-NTF-037 | Notification Inbox List | P0 | No | Yes | No | Yes |
| REQ-NTF-038 | Mark Read / Mark All Read | P0 | No | Yes | Yes | Yes |
| REQ-NTF-039 | Thread Grouping | P1 | No | Yes | No | Yes |
| REQ-NTF-040 | Scheduled Notification Command | P1 | No | No | No | Yes |
| REQ-NTF-041 | Recurring Execution & Audit | P1 | No | No | No | Yes |
| REQ-NTF-042 | Schedule Audit Log View | P1 | No | Yes | No | Yes |

### 10.2 Artifact Count Summary

| Artifact | Count | P0 | P1 | P2 |
|---------|-------|----|----|-----|
| Functional Requirements (REQ-NTF-) | 42 | 24 | 17 | 1 |
| Business Rules (BR-NTF-) | 13 | 8 | 5 | 0 |
| Reports (RPT-NTF-) | 4 | 0 | 4 | 0 |
| Enhancements (ENH-NTF-) | 7 | — | — | — |

> P2 REQ = REQ-NTF-010 (multi-language template support). All others are P0 or P1.

---

# SECTION B — REQUIREMENTS TRACEABILITY MATRIX (RTM)

| REQ ID | Feature | Priority | BR Refs | Workflow | Report | Code Status | Gap Summary |
|--------|---------|----------|---------|----------|--------|-------------|-------------|
| REQ-NTF-001 | Channel Configuration | P0 | BR-007, BR-013 | WF-1 | — | Partial | Gate prefix broken (BUG-NTF-003) |
| REQ-NTF-002 | Channel Activation Toggle | P0 | — | — | — | Partial | Toggle exists; Gate prefix broken |
| REQ-NTF-003 | Provider Configuration | P0 | BR-011 | — | — | Partial | No encrypted cast on credentials (SEC-01) |
| REQ-NTF-004 | Provider Test Connection | P1 | — | — | — | Not Started | testConnection() route exists; method stub only |
| REQ-NTF-005 | DLT SMS Provider Setup | P0 | BR-010 | WF-5 | — | Not Started | Sender ID field not in schema |
| REQ-NTF-006 | Template Management | P0 | BR-004, BR-005 | WF-3 | — | Partial | Routes active; $table correctly `ntf_templates` |
| REQ-NTF-007 | Template Approval Workflow | P0 | BR-004, BR-005 | WF-3 | — | Partial | approve() exists; no reject-with-reason |
| REQ-NTF-008 | Placeholder Rendering | P0 | BR-005 | WF-1 | — | Partial | render() exists; relationships commented out |
| REQ-NTF-009 | Template Versioning | P1 | BR-005 | WF-3 | — | Partial | getNextVersion() exists; version selection at dispatch missing |
| REQ-NTF-010 | Multi-Language Templates | P2 | BR-005 | — | — | Partial | language_code column exists; selection logic missing |
| REQ-NTF-011 | DLT Template Compliance | P0 | BR-010 | WF-5 | — | Not Started | dlt_template_id column missing from ntf_templates |
| REQ-NTF-012 | Manual Notification Compose | P0 | BR-001, BR-009 | WF-2 | — | Partial | BUG-NTF-004: uses $request->field not validated() |
| REQ-NTF-013 | Notification Scheduling | P1 | BR-001 | WF-2, WF-6 | — | Partial | Schema exists; no process-due command |
| REQ-NTF-014 | Recurring Scheduling | P1 | BR-001 | WF-6 | — | Partial | Schema exists; no scheduler command |
| REQ-NTF-015 | Bulk Promotional Approval | P1 | BR-009 | WF-2 | — | Not Started | No approval gate in controller |
| REQ-NTF-016 | Notification Expiry | P1 | BR-012 | WF-6 | — | Not Started | expires_at column exists; no expiry check |
| REQ-NTF-017 | Event-Driven Trigger API | P0 | BR-006 | WF-1 | — | Partial | Event class complete; dispatch commented out (BUG-NTF-005) |
| REQ-NTF-018 | Async Queued Dispatch | P0 | BR-006 | WF-1 | — | Partial | Listener has ShouldQueue; ProcessNotificationJob missing (ARCH-01) |
| REQ-NTF-019 | Multi-Channel Pipeline | P0 | BR-005, BR-001 | WF-1 | — | Partial | NotificationService exists; delivery logging not implemented |
| REQ-NTF-020 | Email Delivery | P0 | BR-011 | WF-1 | — | Partial | sendEmail() call active; no delivery log write |
| REQ-NTF-021 | In-App Delivery | P0 | — | WF-1 | — | Working | InAppSystemNotification complete |
| REQ-NTF-022 | SMS Delivery | P0 | BR-010, BR-011 | WF-1, WF-5 | — | Not Started | switch/default stub only |
| REQ-NTF-023 | Push Delivery | P1 | — | WF-1 | — | Not Started | Device model exists; dispatch stub only |
| REQ-NTF-024 | WhatsApp Delivery | P1 | — | WF-1 | — | Not Started | Not implemented |
| REQ-NTF-025 | Target Group Management | P0 | — | WF-2 | — | Partial | Dynamic resolution not implemented |
| REQ-NTF-026 | Notification Target Assignment | P0 | — | WF-2 | — | Partial | NotificationTargetController exists; resolve() stub |
| REQ-NTF-027 | Recipient Resolution | P0 | BR-002, BR-003 | WF-1 | — | Not Started | RecipientResolutionService missing (ARCH-02) |
| REQ-NTF-028 | User Preferences | P0 | BR-002, BR-003 | — | — | Partial | Controller + views + routes present; opt-out not enforced in pipeline |
| REQ-NTF-029 | Device Token Registration | P1 | — | — | — | Not Started | UserDeviceController missing; API endpoint missing |
| REQ-NTF-030 | Delivery Queue Processing | P0 | BR-007 | WF-1 | — | Partial | Schema + controller exist; ProcessNotificationJob missing |
| REQ-NTF-031 | Delivery Retry Logic | P1 | BR-007, BR-012 | WF-1 | — | Not Started | Schema fields exist; retry logic not in code |
| REQ-NTF-032 | Admin Queue Monitor Actions | P1 | — | — | — | Partial | retry() and cancel() routes exist; no enforcement |
| REQ-NTF-033 | Delivery Audit Trail | P0 | BR-008 | WF-1 | RPT-001 | Partial | Model exists; service never writes to it |
| REQ-NTF-034 | Read/Click Tracking | P1 | — | — | RPT-002 | Not Started | No AJAX endpoints for read/click |
| REQ-NTF-035 | Provider Webhook Callbacks | P1 | BR-008 | — | — | Not Started | No webhook controller |
| REQ-NTF-036 | Bell Widget | P0 | — | — | — | Not Started | No bell widget or unread count endpoint |
| REQ-NTF-037 | Notification Inbox | P0 | — | — | — | Not Started | No inbox views in Notification module |
| REQ-NTF-038 | Mark Read / All Read | P0 | — | — | — | Not Started | No mark-read endpoints |
| REQ-NTF-039 | Thread Grouping | P1 | — | — | — | Partial | Schema + controller + views functional in isolation |
| REQ-NTF-040 | Scheduled Dispatch Command | P1 | BR-001, BR-012 | WF-6 | — | Not Started | notifications:process-due command missing |
| REQ-NTF-041 | Recurring Execution & Audit | P1 | BR-001 | WF-6 | RPT-004 | Not Started | ScheduleAuditController + views present; scheduler not wired |
| REQ-NTF-042 | Schedule Audit Log View | P1 | — | — | RPT-004 | Partial | Controller + views exist; no data populates it |

---

# SECTION C — BUSINESS RULES REGISTER + CONDITIONS + VALIDATION

## C.1 Business Rules Register

(Fully documented in FRD Section 4. Cross-referenced here for completeness.)

| BR ID | Rule Summary | REQ References |
|-------|-------------|----------------|
| BR-NTF-001 | Dispatch only Approved/Scheduled notifications | REQ-NTF-012, REQ-NTF-017, REQ-NTF-019, REQ-NTF-040 |
| BR-NTF-002 | Opt-out is absolute | REQ-NTF-027, REQ-NTF-028 |
| BR-NTF-003 | Quiet hours defer delivery | REQ-NTF-027, REQ-NTF-028 |
| BR-NTF-004 | System template protection | REQ-NTF-006, REQ-NTF-007 |
| BR-NTF-005 | Template must be Approved for dispatch | REQ-NTF-007, REQ-NTF-019 |
| BR-NTF-006 | Unknown event code → warning only | REQ-NTF-017, REQ-NTF-018 |
| BR-NTF-007 | Rate limit queuing not dropping | REQ-NTF-001, REQ-NTF-031 |
| BR-NTF-008 | Delivery log immutability | REQ-NTF-033 |
| BR-NTF-009 | Bulk promotional approval required | REQ-NTF-015 |
| BR-NTF-010 | DLT compliance for Indian SMS | REQ-NTF-005, REQ-NTF-011, REQ-NTF-022 |
| BR-NTF-011 | Provider credential encryption | REQ-NTF-003 |
| BR-NTF-012 | Notification expiry check | REQ-NTF-016, REQ-NTF-040 |
| BR-NTF-013 | No circular fallback chains | REQ-NTF-001 |

## C.2 Requirement Conditions Catalog

| BR ID | Entity / Field | Condition (business) | Type | On-Violation |
|-------|----------------|---------------------|------|-------------|
| BR-NTF-001 | Notification / status | Must be Approved or Scheduled | Workflow | Dispatch blocked; "Notification not approved" |
| BR-NTF-002 | User Preference / is_opted_in | Must = 1 for delivery to proceed | Permission | Recipient row not created for that channel |
| BR-NTF-003 | User Preference / quiet_hours | Current time NOT in quiet_hours_start–end window | Workflow | scheduled_at set to end-of-window |
| BR-NTF-004 | Template / is_system_template | If 1, actor must be Prime Super Admin | Permission | 403 Forbidden |
| BR-NTF-005 | Template / approval_status | Must = "APPROVED" | Validation | Channel skipped; warning logged |
| BR-NTF-006 | Notification / notification_event | Event code must match a Notification record | Workflow | Warning logged; silent return |
| BR-NTF-007 | Channel / rate limits | sent_in_window < rate_limit_per_minute | Validation | Delivery deferred to next window; not dropped |
| BR-NTF-008 | Delivery Log / (all fields) | No update or delete operations | Validation | 405 Method Not Allowed or 403 Forbidden |
| BR-NTF-009 | Notification / type + recipient count | PROMOTIONAL AND resolved_recipients > 100 | Workflow | Status = Pending Approval |
| BR-NTF-010 | Template / dlt_template_id (SMS) | Must be NOT NULL for SMS channel on Indian tenant | Validation | Delivery blocked; "DLT Template ID required" |
| BR-NTF-011 | Provider / api_key_encrypted | Must use Laravel encrypted cast | Validation | P0 security violation |
| BR-NTF-012 | Notification / expires_at | If NOT NULL, expires_at must be > NOW() at dispatch | Workflow | Status = Expired; queue entries = Cancelled |
| BR-NTF-013 | Channel / fallback_channel_id | No circular chain of fallback references | Validation | Save rejected; "Circular fallback not permitted" |

## C.3 Validation & Edge-Case Catalog

| Field / Rule | Valid Example | Invalid Example | Boundary | Empty/Null | Concurrency | Expected Behaviour |
|-------------|--------------|----------------|---------|-----------|-------------|-------------------|
| Channel rate_limit_per_minute | 200 | -1 or 0 | Max INT | NULL → default 100 | Two workers hit limit simultaneously | Only one proceeds; other defers |
| Template body `{{placeholder}}` | `Dear {{name}}` | `Dear {name}` (wrong syntax) | All placeholders replaced | NULL body → reject on save | — | Wrong syntax treated as literal text |
| Template approval_status | APPROVED → dispatch | DRAFT → blocked | PENDING → blocked | NULL → treat as DRAFT | Two admins approve simultaneously | First approval wins; second is idempotent |
| Provider api_key_encrypted | `ENC::base64...` (stored) | Plaintext `ABC123` | 512 chars max | NULL allowed (some providers use OAuth) | — | Plaintext triggers P0 violation log |
| Notification scheduled_at | Future datetime | Past datetime | Exactly now (within 1 min) | NULL → IMMEDIATE schedule type | — | Past datetime rejected |
| Quiet hours (start=22:00, end=07:00) | Current time 09:00 → no deferral | — | Boundary 22:00 exactly → defer | NULL → no quiet hours | — | End-of-window delivery at 07:00 |
| DLT Template ID | `1507161985783893622` (numeric string) | `ABC` (non-numeric) | 20-char max | NULL on SMS channel → block dispatch | — | Non-numeric format → validation error on save |
| Delivery Queue max_attempts | 3 | 0 (never retry) | Exactly at max_attempts → FAILED | NULL → default 3 | Two workers pick same locked entry | Second worker sees locked_by; skips |
| Fallback chain depth | A→B (2 hops) | A→B→A (circular) | 5-hop limit | NULL fallback → no fallback | — | Circular rejected on save |
| Opt-out override | is_opted_in=1 → deliver | is_opted_in=0 → block | Changed from 1 to 0 at dispatch time | NULL → treat as opted in | Opt-out during active batch | Pending queue entries for that user+channel → Cancelled |
| Resolved recipients (empty) | 40 students resolved | 0 students resolved | 1 student resolved | No targets defined → 0 resolved | — | Status = No Recipients; no queue entries |
| Bell unread count | 5 unread → shows 5 | — | 99+ unread → shows "99+" | 0 unread → bell shows 0 | Two devices open simultaneously | Both show same count; eventual consistency |

---

# SECTION D — PROCESS FLOWS + FSM CATALOG

## D.1 Process Flows

All six workflows are documented in FRD Section 6. Cross-reference:

| Workflow | Name | FRD Section |
|---------|------|-------------|
| WF-1 | Event-Driven Notification Dispatch | FRD §6.1 |
| WF-2 | Manual Notification Composition and Send | FRD §6.2 |
| WF-3 | Template Approval | FRD §6.3 |
| WF-4 | User Opt-Out | FRD §6.4 |
| WF-5 | DLT SMS Compliance | FRD §6.5 |
| WF-6 | Scheduled and Recurring Execution | FRD §6.6 |

## D.2 FSM Catalog

### FSM-1: Notification Status

| From State | Event / Action | Guard | To State | Side-Effects |
|-----------|---------------|-------|----------|-------------|
| (new) | Admin saves | — | DRAFT | No dispatch; editable |
| DRAFT | Admin submits; PROMOTIONAL + >100 recipients | BR-NTF-009 | PENDING_APPROVAL | Approval notification fired |
| DRAFT | Admin saves; not PROMOTIONAL or ≤100 recipients | — | APPROVED | Dispatch pipeline starts |
| PENDING_APPROVAL | Admin approves | — | APPROVED | Dispatch pipeline starts |
| PENDING_APPROVAL | Admin cancels | — | CANCELLED | No dispatch |
| APPROVED | schedule_type = SCHEDULED | scheduled_at > NOW() | SCHEDULED | Waits for scheduler command |
| APPROVED | schedule_type = IMMEDIATE | — | PROCESSING | Recipient resolution begins |
| SCHEDULED | notifications:process-due fires | scheduled_at <= NOW() | PROCESSING | Recipient resolution begins |
| SCHEDULED | expires_at reached | BR-NTF-012 | EXPIRED | Queue entries = Cancelled |
| PROCESSING | All channels delivered | — | COMPLETED | Counters updated |
| PROCESSING | Some channels failed | — | PARTIAL | Admin alert recommended |
| PROCESSING | All channels failed | — | FAILED | Admin alert fired |
| Any | Admin cancels | Before PROCESSING | CANCELLED | Queue entries = Cancelled |

**Terminal States:** EXPIRED, CANCELLED, COMPLETED, FAILED
**Illegal Transitions:** COMPLETED → any; EXPIRED → APPROVED; CANCELLED → APPROVED

---

### FSM-2: Message Template Approval Status

| From State | Event | Guard | To State | Side-Effects |
|-----------|-------|-------|----------|-------------|
| (new) | Admin creates | — | DRAFT | Not available for dispatch |
| DRAFT | Admin submits | Template body not empty | PENDING | Notification to reviewer |
| PENDING | Reviewer approves | — | APPROVED | Prior version (same code) → ARCHIVED |
| PENDING | Reviewer rejects with reason | Reason not empty | REJECTED | Reason stored; author notified |
| REJECTED | Author edits | — | DRAFT | Can be resubmitted |
| APPROVED | New version approved | — | ARCHIVED | Superseded |
| APPROVED | Admin archives manually | — | ARCHIVED | No longer dispatched |

**Terminal States:** ARCHIVED (de-facto; can be reactivated by cloning)

---

### FSM-3: Delivery Queue Entry Status

| From State | Event | Guard | To State | Side-Effects |
|-----------|-------|-------|----------|-------------|
| (new) | Resolved recipient created | — | PENDING | Entry created |
| PENDING | Worker picks up | locked_by = null | PROCESSING | locked_by + locked_at set |
| PROCESSING | Delivery succeeds | — | SENT | Delivery log = Sent; counters updated |
| PROCESSING | Delivery fails | attempt_count < max_attempts | RETRY | next_attempt_at computed; last_error stored |
| RETRY | next_attempt_at reached | — | PENDING | Recycled for next worker pick-up |
| PROCESSING | Delivery fails | attempt_count >= max_attempts | FAILED | Delivery log = Failed; Admin alert |
| PENDING | Admin cancels | — | CANCELLED | — |
| PENDING | Notification expires | expires_at < NOW() | CANCELLED | BR-NTF-012 |
| PENDING | Lock timeout (5 min) | locked_at + 5min < NOW() | PENDING | Worker releases lock; reclaimed |

**Terminal States:** SENT, FAILED, CANCELLED

---

### FSM-4: Delivery Log Stage Progression

| Stage | Meaning | Next Stage(s) | Trigger |
|-------|---------|--------------|---------|
| QUEUED | Entry in delivery queue | SENT, FAILED | Worker picks up |
| SENT | Dispatch API call succeeded | DELIVERED, BOUNCED | Provider webhook or timeout |
| DELIVERED | Provider confirmed delivery | READ, BOUNCED, COMPLAINT | Provider webhook |
| READ | User opened in-app notification | CLICKED | User action (AJAX) |
| CLICKED | User clicked CTA link | (terminal) | User action (AJAX) |
| BOUNCED | Email bounced / SMS failed delivery | (terminal) | Provider webhook |
| COMPLAINT | User marked as spam | (terminal) | Provider webhook |
| UNSUBSCRIBED | User unsubscribed via email link | (terminal) | Opt-out link click |

**Note:** Each stage transition creates a NEW log entry (append-only). The previous entry is never updated.

---

# SECTION E — DATA DICTIONARY + CROSS-MODULE DEPENDENCY MAP

## E.1 Data Dictionary (Business View)

### E.1.1 Delivery Channel (`ntf_channel_master`)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Channel Type Code | Short code identifying the medium | Text (20) | Yes | EMAIL, SMS, WHATSAPP, IN_APP, PUSH | No |
| Display Name | Human-readable channel name | Text (50) | Yes | Free text | No |
| Delivery Mode | Whether the channel sends one-at-a-time or in bulk | Choice | Yes | Immediate / Bulk / Transactional | No |
| Delivery Priority | Order of preference when multiple channels available | Number 1–10 | Yes | 1 = highest | No |
| Max Retries | Number of delivery attempts before marking Failed | Integer | Yes | Default 3 | No |
| Retry Delay (minutes) | Wait time between retry attempts | Integer | Yes | Default 5 | No |
| Rate Limit (per minute) | Maximum messages dispatched per minute | Integer | Yes | Default 100 | No |
| Daily Limit | Maximum messages per calendar day | Integer | Yes | Default 10,000 | No |
| Monthly Limit | Maximum messages per calendar month | Integer | Yes | Default 100,000 | No |
| Cost Per Message (Rs.) | Per-unit cost for budget tracking | Decimal | Yes | Default 0 | No |
| Fallback Channel | Alternative channel if this one fails | Reference | No | Another channel record | No |
| Is Active | Whether this channel is currently enabled | Boolean | Yes | Active / Inactive | No |

### E.1.2 Message Template (`ntf_templates`)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Template Code | Event code this template responds to | Text (50) | Yes | UPPER_SNAKE_CASE | No |
| Template Name | Descriptive display name | Text (100) | Yes | Free text | No |
| Delivery Channel | Which channel this template is for | Reference | Yes | Active channel | No |
| Version | Numeric version (same code can have multiple) | Integer | Yes | Starting at 1 | No |
| Email Subject | Subject line (email channel only) | Text (255) | Conditional | `{{placeholder}}` syntax | No |
| Message Body | Full message content with placeholders | Text (long) | Yes | `{{placeholder}}` syntax | No |
| Language | Language of this template | Code | Yes | Default: English (en) | No |
| Approval Status | Current workflow state | Choice | Yes | Draft / Pending / Approved / Rejected / Archived | No |
| DLT Template ID | TRAI-registered ID (SMS channel, India) | Text (50) | If SMS | Numeric string | No |
| Is System Template | Managed only by Prime Super Admin | Boolean | Yes | Yes / No | No |

### E.1.3 Notification (`ntf_notifications`)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| Notification UUID | Public-facing unique identifier | UUID | Yes | System-generated | No |
| Source Module | Module that created this notification | Text (50) | Yes | Module codes | No |
| Event Code | Event that triggered this notification | Text (50) | Yes | UPPER_SNAKE_CASE | No |
| Notification Type | Nature of the message | Choice | Yes | Transactional / Promotional / Alert / Reminder / Digest | No |
| Title | Human-readable notification title | Text (255) | Yes | Free text | No |
| Schedule Type | When to dispatch | Choice | Yes | Immediate / Scheduled / Recurring / Triggered | No |
| Scheduled Date/Time | When to send (Scheduled type) | Datetime | Conditional | Future datetime | No |
| Recurrence Pattern | Frequency for recurring type | Choice | Conditional | Hourly / Daily / Weekly / Monthly / Yearly / Custom | No |
| Expiry Date/Time | Do not dispatch after this time | Datetime | No | Future datetime | No |
| Status | Current lifecycle state | Reference | Yes | From status configuration master | No |
| Total Recipients | Count of resolved recipients | Integer | Calculated | Auto-computed | No |
| Sent / Failed / Delivered / Read / Click Count | Running delivery counters | Integer | Calculated | Auto-incremented | No |
| Estimated Cost (Rs.) | Pre-send budget estimate | Decimal | Calculated | Recipients × cost_per_unit | No |
| Actual Cost (Rs.) | Real cost after delivery | Decimal | Calculated | Sum from delivery logs | No |

### E.1.4 User Preference (`ntf_user_preferences`)

| Business Field | Meaning | Type | Required | Allowed Values | PII? |
|---------------|---------|------|----------|---------------|------|
| User | The user this preference applies to | Reference | Yes | sys_users | Yes |
| Channel | The channel this preference applies to | Reference | Yes | Active channel | No |
| Channel Enabled | Whether the channel is switched on | Boolean | Yes | Yes / No | No |
| Opted In | GDPR consent to receive on this channel | Boolean | Yes | Yes / No | Yes |
| Opted In Date | When the user gave consent | Datetime | If opted in | — | Yes |
| Opted Out Date | When the user withdrew consent | Datetime | If opted out | — | Yes |
| Quiet Hours Start | Start of delivery-free window | Time | No | HH:MM | No |
| Quiet Hours End | End of delivery-free window | Time | No | HH:MM | No |
| Quiet Hours Timezone | Timezone for quiet hours calculation | Text | If quiet hours set | IANA string | No |
| Daily Digest Mode | Batch all notifications into one daily message | Boolean | No | Yes / No | No |
| Priority Threshold | Minimum priority level to receive | Reference | No | Priority master | No |

---

## E.2 Cross-Module Dependency Map

### E.2.1 Inbound (NTF depends on these modules)

| Source Module | Data / Entity | Why NTF Needs It |
|-------------|-------------|-----------------|
| System Configuration | `sys_dropdown_table` | Priority values, status values, notification type values, target type values |
| System Users | `sys_users` | Resolving targets to individual user records; opt-out checks |
| System Media | `sys_media` | Email attachment references from `ntf_templates.media_id` |
| System Settings | `sys_settings` | Data retention policy; default quiet hours configuration |
| Laravel Queue | Infrastructure | `ShouldQueue` for all async processing |
| Laravel Mail | Infrastructure | Email delivery via configured SMTP/SES transport |
| Firebase FCM | External | Push notification delivery using device tokens |
| MSG91 / Twilio | External | SMS delivery with DLT compliance |
| Meta WhatsApp Cloud API | External | WhatsApp message delivery |

### E.2.2 Outbound (Modules that fire events to NTF)

| Firing Module | Event Codes | NTF Action |
|-------------|------------|-----------|
| StudentFee (FIN) | `FEE_DUE_REMINDER`, `PAYMENT_RECEIVED`, `FEE_RECEIPT_GENERATED` | Multi-channel dispatch to parent/student |
| LmsExam (EXM) | `EXAM_RESULT_PUBLISHED`, `EXAM_SCHEDULED`, `EXAM_REMINDER_24H` | Dispatch to students/parents |
| LmsHomework (HMW) | `HOMEWORK_ASSIGNED`, `HOMEWORK_DUE_REMINDER`, `HOMEWORK_GRADED` | Dispatch to students/parents |
| Attendance (ATT) | `ATTENDANCE_MARKED_ABSENT`, `ATTENDANCE_DAILY_SUMMARY` | Dispatch to parents |
| Admission (ADM) | `STUDENT_ADMITTED`, `ADMISSION_ENQUIRY_RECEIVED` | Dispatch to applicant/parent |
| Library (LIB) | `BOOK_OVERDUE`, `BOOK_RETURN_REMINDER` | Dispatch to member |
| Transport (TPT) | `VEHICLE_ARRIVAL_ALERT`, `ROUTE_CHANGE_NOTIFICATION` | Dispatch to parents |
| Communication (COM) | `CIRCULAR_PUBLISHED`, `ANNOUNCEMENT_POSTED` | NTF is COM's delivery engine |
| StudentProfile (STD) | `STUDENT_PROFILE_UPDATED`, `ID_CARD_GENERATED` | Admin alerts |
| System (SYS) | `OTP_VERIFICATION`, `PASSWORD_RESET`, `LOGIN_SUSPICIOUS_ALERT` | Security notifications (bypass opt-out) |
| Hostel (HST) | `HOSTEL_LEAVE_APPROVED`, `HST_ATTENDANCE_ABSENT` | Dispatch to parents |

### E.2.3 Integration Contract (Event API)

Standard pattern for any module to trigger a notification:
- Event Code: UPPER_SNAKE_CASE string (must be registered in ntf_notifications)
- Context: Flat key-value array of scalars matching `{{placeholders}}` in templates
- Call: `SystemNotificationTriggered::dispatch(event_code, context_array)`
- If the event code has no registered Notification record: warning logged; nothing dispatched; no exception thrown.

---

# SECTION F — NFR CATALOG + RISK REGISTER

## F.1 NFR Catalog

| NFR ID | Category | Requirement | Acceptance Threshold |
|--------|---------|-------------|---------------------|
| NFR-NTF-001 | Performance | IMMEDIATE priority notification enters pipeline within 30 seconds | <= 30 seconds from event fire to queue entry creation |
| NFR-NTF-002 | Performance | NORMAL priority notification dispatched within 2 minutes | <= 2 minutes |
| NFR-NTF-003 | Performance | Bulk batch of 10,000 recipients dispatched within 15 minutes | <= 15 min with default worker count |
| NFR-NTF-004 | Performance | In-app bell count refreshed within 30 seconds | <= 30 seconds via polling or WebSocket |
| NFR-NTF-005 | Performance | Queue monitor page for 10,000-item backlog loads without timeout | <= 3 second page load; paginated |
| NFR-NTF-006 | Security | Provider API credentials stored encrypted | `encrypted` cast on model; verified in test |
| NFR-NTF-007 | Security | All notification routes use `tenant.notification.*` Gate prefix | Zero `prime.*` prefixes in NTF controllers |
| NFR-NTF-008 | Security | Device tokens never appear in logs or API responses | Masked or absent in all log entries |
| NFR-NTF-009 | Security | Provider webhook endpoints outside auth middleware | Webhook returns 200 without Bearer token |
| NFR-NTF-010 | Security | In-app template body sanitized against XSS | htmlspecialchars() applied; `<script>` tag rendered as literal text |
| NFR-NTF-011 | Compliance | DLT Template ID enforced for all SMS on Indian tenants | Zero unregistered SMS delivered |
| NFR-NTF-012 | Compliance | Opt-out respected immediately and absolutely | Zero deliveries to opted-out users |
| NFR-NTF-013 | Compliance | Delivery log IP and user agent subject to retention policy | Configurable via sys_settings; purged per policy |
| NFR-NTF-014 | Reliability | Queue listener: 3 retries with 10-second backoff | Failed job in failed_jobs table after 3rd failure |
| NFR-NTF-015 | Reliability | Worker crash recovery: stale locks auto-released after 5 minutes | No stuck queue entries after 10-minute crash simulation |
| NFR-NTF-016 | Reliability | Single-recipient failure does not affect others in same batch | Other recipients delivered when one fails |
| NFR-NTF-017 | Scalability | Delivery queue design supports horizontal worker scaling | Multiple workers process concurrently without duplicate delivery |
| NFR-NTF-018 | Availability | Queue down → notifications safely queued; no data loss | All pending entries survive worker restart |
| NFR-NTF-019 | Usability | Cost estimate visible before sending a bulk SMS | Estimated cost shown in compose form before submit |
| NFR-NTF-020 | Usability | Empty inbox state shows friendly message | "No notifications yet" message visible |

## F.2 Risk Register

| Risk ID | Risk | Likelihood | Impact | Mitigation | Early Warning |
|---------|------|:---------:|:------:|-----------|--------------|
| RISK-NTF-001 | Gate prefix bug causes silent auth bypass for all tenant notification operations | High | High | Global find-replace `prime.` → `tenant.` | Any user can CRUD notifications without permission |
| RISK-NTF-002 | No `ProcessNotificationJob` exists — dispatch pipeline never executes | High | High | Create job as P0 sprint item | No notifications dispatched even when triggered |
| RISK-NTF-003 | Provider credentials stored without encryption — API keys exposed in DB dump | High | High | Add `encrypted` cast to ProviderMaster model immediately | DB inspection shows plaintext API keys |
| RISK-NTF-004 | `canBeProcessed()` missing from Notification model → PHP fatal error on process() | High | Medium | Add method to model | Any attempt to process a notification crashes |
| RISK-NTF-005 | DLT Template ID column missing from `ntf_templates` | Medium | High | Create DDL migration; add column + form field | SMS to Indian tenants bypasses DLT requirement |
| RISK-NTF-006 | RecipientResolutionService missing — target expansion not implemented | High | High | Create service as P1 sprint item | All CLASS/SECTION/GROUP targets resolve to 0 recipients |
| RISK-NTF-007 | Notification inbox (bell + inbox view) not built — in-app channel unusable | High | Medium | Build inbox UI as P1 sprint item | Users receive no visible in-app alerts |
| RISK-NTF-008 | 0 tests — critical bugs in dispatch pipeline go undetected | High | High | 14-test-class suite (per V2 req) | Regression in any dispatch fix goes unnoticed |
| RISK-NTF-009 | SMS/Push/WhatsApp dispatch stubs — three of five channels non-functional | High | Medium | Implement provider adapters per sprint | Parents/students unreachable via mobile channels |
| RISK-NTF-010 | No `notifications:process-due` command — scheduled/recurring notifications never fire | Medium | High | Create artisan command; register in scheduler | Fee reminders and recurring alerts never delivered |
| RISK-NTF-011 | `$request->field` usage bypasses FormRequest validation | High | Medium | Replace with `$request->validated()` | Invalid notification records in DB |
| RISK-NTF-012 | Service never writes to delivery log — audit trail empty for all deliveries | High | High | Add log write to dispatchToChannel() | No delivery evidence; impossible to diagnose issues |

---

# SECTION G — PRIORITIZATION + EFFORT ESTIMATION

## G.1 MoSCoW Prioritization

### Must Have (P0 — Core before any production use)

REQ-NTF-001, 002 — Channel config is prerequisite for all delivery
REQ-NTF-003 — Provider config is prerequisite for all external delivery
REQ-NTF-005 — DLT sender ID required for India
REQ-NTF-006, 007, 008 — Template system is the content source for all dispatch
REQ-NTF-011 — DLT compliance — legal requirement for Indian SMS
REQ-NTF-012 — Manual notification is the primary admin use case
REQ-NTF-017, 018, 019 — Event-driven dispatch is the entire value proposition
REQ-NTF-020, 021, 022 — Email, In-App, and SMS — the three launch channels
REQ-NTF-025, 026, 027 — Recipient targeting without these is useless
REQ-NTF-028 — Opt-out is a legal/GDPR requirement
REQ-NTF-030 — Delivery queue is the dispatch mechanism
REQ-NTF-033 — Delivery audit trail is a compliance requirement
REQ-NTF-036, 037, 038 — Inbox/bell is the only visible UX for in-app delivery

### Should Have (P1 — Complete before beta / general availability)

REQ-NTF-004 — Test connection saves admin debugging time
REQ-NTF-009, 010 — Template versioning/multilang needed for mature operation
REQ-NTF-013, 014 — Scheduling is key for fee reminders and recurring alerts
REQ-NTF-015 — Regulatory caution for promotional bulk messaging
REQ-NTF-016 — Expiry prevents stale messages
REQ-NTF-023, 024 — Push + WhatsApp — increasing parent preference in India
REQ-NTF-029 — Device registration enables push
REQ-NTF-031, 032 — Retry and admin queue actions needed for reliability
REQ-NTF-034, 035 — Read/click tracking + webhooks enable analytics
REQ-NTF-039 — Thread grouping useful for conversation-style notifications
REQ-NTF-040, 041, 042 — Scheduler + audit needed for recurring reminders

### Could Have (P2 — Nice to have after P1)

REQ-NTF-010 — Multi-language templates useful for multilingual schools but not day-one requirement

### Won't Have (this release)

ENH-NTF-001, 002, 007 — AI content optimisation, predictive timing, A/B testing — all require additional module dependencies

---

## G.2 Effort Estimation & Sprint Task Breakdown

### Sprint 0 — P0 Bug Fixes (before any new feature)

| # | Task | Type | Effort (h) |
|---|------|------|-----------|
| 1 | Global replace `prime.notification.*` → `tenant.notification.*` across 12 controllers and 1 policy | Backend | 2 |
| 2 | Replace `$request->field` with `$request->validated()` in NotificationManageController store()/update() | Backend | 2 |
| 3 | Add `canBeProcessed()` method to Notification model | Backend | 1 |
| 4 | Add `encrypted` cast for `api_key_encrypted` and `api_secret_encrypted` in ProviderMaster model | Backend | 1 |
| 5 | Migration: `dlt_template_id VARCHAR(50) NULL` to `ntf_templates` | Schema | 1 |
| 6 | Migration: `deleted_at` to `ntf_user_devices` | Schema | 0.5 |
| 7 | Fix FK naming: `sys_user` → `sys_users` in ntf_user_devices and ntf_resolved_recipients | Schema | 1 |
| **Sprint 0 Total** | | | **8.5 h** |

### Sprint 1 — P0 Dispatch Pipeline

| # | Task | Type | Effort (h) |
|---|------|------|-----------|
| 8 | Create `ProcessNotificationJob` with worker locking, retry logic, per-channel dispatch | Backend | 12 |
| 9 | Uncomment `ProcessNotificationJob::dispatch()` in `process()` method | Backend | 0.5 |
| 10 | Create `RecipientResolutionService` — expand targets, filter opt-out, apply quiet hours, create resolved_recipients | Backend | 8 |
| 11 | Implement delivery log writes in `NotificationService::dispatchToChannel()` | Backend | 4 |
| 12 | Implement counter increment on `ntf_notifications` (sent_count, failed_count, etc.) | Backend | 2 |
| 13 | Add Gate auth to `create()` and `edit()` in NotificationManageController | Backend | 1 |
| 14 | Fix `getRouteKeyName()` conflict in Notification model | Backend | 1 |
| 15 | Uncomment `resolvedRecipients()` and `logs()` relationships in Notification model | Backend | 0.5 |
| **Sprint 1 Total** | | | **29 h** |

### Sprint 2 — P0 Inbox + In-App

| # | Task | Type | Effort (h) |
|---|------|------|-----------|
| 16 | Build bell widget (unread count via AJAX, polling every 30s) in tenant layout header | Frontend | 4 |
| 17 | Build notification inbox view (list, pagination, unread/read state, deep-link) | Frontend | 8 |
| 18 | Build mark-as-read and mark-all-read AJAX endpoints | Backend | 3 |
| 19 | Build unread count API endpoint for bell | Backend | 1 |
| 20 | Add DLT Template ID field to template create/edit form | Frontend | 2 |
| **Sprint 2 Total** | | | **18 h** |

### Sprint 3 — P1 Features

| # | Task | Type | Effort (h) |
|---|------|------|-----------|
| 21 | Create `notifications:process-due` artisan command; register in scheduler | Backend | 3 |
| 22 | Implement recurring dispatch with next-occurrence computation from cron | Backend | 5 |
| 23 | Implement bulk promotional approval gate (>100 recipients → Pending Approval) | Backend | 3 |
| 24 | Implement notification expiry check in queue worker | Backend | 2 |
| 25 | Create `UserDeviceController` with API endpoint `POST /api/v1/notifications/devices` | Backend | 3 |
| 26 | Implement template version selection (highest approved in date range) at dispatch | Backend | 3 |
| 27 | Implement retry/cancel in DeliveryQueueController with actual DB updates | Backend | 3 |
| 28 | Implement SMS provider adapter (MSG91) with DLT template ID | Backend | 8 |
| 29 | Implement FCM push adapter using device tokens | Backend | 6 |
| 30 | Implement read/click tracking AJAX endpoints + delivery log updates | Backend | 4 |
| **Sprint 3 Total** | | | **40 h** |

### Sprint 4 — P1 Completion + Tests

| # | Task | Type | Effort (h) |
|---|------|------|-----------|
| 31 | WhatsApp adapter (Meta Cloud API) | Backend | 8 |
| 32 | Provider webhook controller (MSG91 DND callback, AWS SES bounce) | Backend | 6 |
| 33 | Enforce rate limit (Laravel RateLimiter) in queue worker | Backend | 4 |
| 34 | Write test suite: 14 test classes | Testing | 24 |
| 35 | Refactor NotificationManageController index() god-method to tabbed AJAX | Backend | 6 |
| 36 | Provider test connection implementation in ProviderMasterController | Backend | 3 |
| **Sprint 4 Total** | | | **51 h** |

### Summary

| Sprint | Focus | Effort |
|--------|-------|--------|
| Sprint 0 | P0 bug fixes + schema | 8.5 h |
| Sprint 1 | Core dispatch pipeline | 29 h |
| Sprint 2 | In-app inbox + UI | 18 h |
| Sprint 3 | P1 features + SMS/Push | 40 h |
| Sprint 4 | WhatsApp + webhooks + tests | 51 h |
| **Total** | | **~146 h** |

---

# SECTION H — USER STORIES + REPORTING SPEC

## H.1 User Stories (all P0 REQs + key P1 REQs)

---

**US-NTF-001** | Priority: P0 | REQ: REQ-NTF-001, REQ-NTF-002
As a School Admin, I want to configure and activate delivery channels so that my school can send notifications through Email, SMS, In-App, Push, and WhatsApp.

Acceptance Criteria:
- Admin creates an Email channel with rate limit 200/min → saved; appears in channel list as Active
- Admin deactivates SMS channel → next dispatch cycle skips SMS silently; activity log entry records actor and timestamp
- Admin attempts circular fallback (A → B → A) → system rejects "Circular fallback not permitted"
- Teacher attempts to create a channel → access denied (403)

DoD: Channel saved; activity logged; fallback validation tested; Teacher blocked.

---

**US-NTF-002** | Priority: P0 | REQ: REQ-NTF-003
As a School Admin, I want to configure external providers with encrypted credentials so that SMS and email can be sent securely.

Acceptance Criteria:
- Admin saves provider with API key → key stored encrypted; list view masks the key (****abc123)
- Direct database query → encrypted ciphertext visible, not plaintext

DoD: Encrypted cast confirmed; no plaintext in DB.

---

**US-NTF-003** | Priority: P0 | REQ: REQ-NTF-006, REQ-NTF-007, REQ-NTF-008
As a School Admin, I want to create and approve message templates so that notifications are consistent, on-brand, and compliant.

Acceptance Criteria:
- Admin creates template with `{{student_name}}` → saved as Draft
- Admin submits and approves → status = Approved; available for dispatch
- Template in Draft status → dispatch blocked; "Template not approved" logged
- Template with `{{student_name}}` dispatched with context `{student_name: "Rahul"}` → message says "Dear Rahul..."

DoD: Approval workflow end-to-end working; render test passes.

---

**US-NTF-004** | Priority: P0 | REQ: REQ-NTF-011, REQ-NTF-022
As a School Admin in India, I want to register DLT Template IDs on SMS templates so that our SMS messages comply with TRAI regulations.

Acceptance Criteria:
- SMS template with `dlt_template_id` set → MSG91 request includes template_id parameter; delivery log = Sent
- SMS template without DLT ID → dispatch blocked; "DLT Template ID required for SMS"; no external API call made

DoD: DLT ID passed in API request; blocking test passes.

---

**US-NTF-005** | Priority: P0 | REQ: REQ-NTF-012
As a School Admin, I want to compose and send ad-hoc notifications to specific classes so that I can reach the right people quickly.

Acceptance Criteria:
- Admin selects Type=Alert, Target=Class 5A, Channel=In-App → delivered to all Class 5A students within 30 seconds
- Teacher attempts to target "All School Parents" → access denied; scope limited to own classes
- Title field empty → 422 returned with "Title is required"; no record created

DoD: Scope enforcement tested; validation errors tested; delivery confirmed.

---

**US-NTF-006** | Priority: P0 | REQ: REQ-NTF-017, REQ-NTF-018, REQ-NTF-019
As a system-generated process from the StudentFee module, I want to trigger a notification when a fee is due so that parents are automatically reminded.

Acceptance Criteria:
- FEE_DUE_REMINDER registered with Email + In-App channels → StudentFee fires event → both channels dispatched; delivery logs created
- Unknown event code fired → warning logged; no exception; no orphan records; originating module not blocked
- First dispatch attempt fails → retried after 10 seconds; up to 3 total attempts

DoD: End-to-end event dispatch working; retry behavior tested.

---

**US-NTF-007** | Priority: P0 | REQ: REQ-NTF-027, REQ-NTF-028
As a Parent who has opted out of SMS, I want to be certain that I never receive SMS from the school system.

Acceptance Criteria:
- Parent A opted out of SMS → notification to "All Class 5 Parents" via SMS → parent A not in Resolved Recipients
- Parent B has quiet hours 22:00–07:00 → notification dispatched at 23:30 → delivery deferred to 07:00; not cancelled
- Parent C has pending SMS in queue → opts out → pending queue entry status = Cancelled

DoD: Opt-out exclusion tested; quiet hours deferral tested; cancellation tested.

---

**US-NTF-008** | Priority: P0 | REQ: REQ-NTF-033
As a School Admin, I want a complete, immutable delivery audit trail so that I can prove a notification was sent.

Acceptance Criteria:
- Email delivery succeeds → log entry with stage=Sent, delivered_at, duration_ms, provider_message_id
- Admin attempts to delete a delivery log record → blocked (403 or 405); entry remains
- Provider bounce webhook received → new log entry with stage=Bounced; bounced_at populated; failed_count incremented

DoD: Log writes confirmed; delete blocked; bounce webhook test passes.

---

**US-NTF-009** | Priority: P0 | REQ: REQ-NTF-036, REQ-NTF-037, REQ-NTF-038
As a Teacher, I want to see a bell icon showing my unread notifications and a full inbox so that I never miss important school alerts.

Acceptance Criteria:
- 0 unread → Admin sends in-app alert → bell count increments to 1 within 30 seconds
- User clicks one notification → read_at set; bell count decrements
- User clicks "Mark all as read" → all notifications marked; bell count = 0; completes within 2 seconds
- No notifications → inbox shows "No notifications yet. You'll see updates from your school here."

DoD: Bell count real-time update tested; mark read tested; empty state shown.

---

**US-NTF-010** | Priority: P1 | REQ: REQ-NTF-013
As an Accounts Manager, I want to set up a recurring fee reminder on the 5th of every month so that defaulters are automatically reminded.

Acceptance Criteria:
- Notification with schedule_type=RECURRING, pattern=MONTHLY, day=5 → fires on the 5th; Schedule Audit record created with status=Completed
- recurring_end_count = 6 → after 6 executions, no further dispatches; notification status = Completed

DoD: Scheduler command tested; audit record created per execution.

---

**US-NTF-011** | Priority: P1 | REQ: REQ-NTF-015
As a School Admin, I want bulk promotional notifications to require approval so that mass messaging is controlled.

Acceptance Criteria:
- Promotional to 200 parents → status = Pending Approval; no dispatch begins
- Second Admin approves → status = Approved; dispatch pipeline starts
- Promotional to 50 parents → no approval required; dispatches immediately

DoD: 100-recipient threshold tested; approval flow end-to-end tested.

---

**US-NTF-012** | Priority: P1 | REQ: REQ-NTF-030, REQ-NTF-031
As a School Admin, I want to monitor the delivery queue and retry failed messages so that transient failures do not prevent notifications from reaching recipients.

Acceptance Criteria:
- Queue entry with max_attempts=3 → first two attempts fail → status=Retry after each; third attempt made
- Third attempt also fails → status=Failed; last_error populated; delivery log written
- Admin clicks Retry on a Failed entry → attempt_count resets; status=Pending; dispatch retried
- Per-minute rate limit hit → delivery deferred to next window; status=Retry; not Failed

DoD: Retry logic tested; rate-limit deferral tested; admin retry tested.

---

## H.2 Reporting & Analytics Spec (detailed)

### RPT-NTF-001 — Delivery Logs Report (full spec)

| Property | Value |
|---------|-------|
| RPT ID | RPT-NTF-001 |
| Purpose | Complete, filterable audit log of every delivery attempt for compliance and troubleshooting |
| Primary Audience | School Admin, Prime Support |
| Data Source | `ntf_delivery_logs` joined to `ntf_notifications`, `ntf_channel_master`, `sys_users` |
| Columns | Notification Title, Event Code, Channel, Recipient Name, Delivery Stage, Provider Message ID, Delivered At, Read At, Clicked At, Bounced At, Error Message, Duration (ms), Cost (Rs.) |
| Filters | Notification, Channel, Delivery Stage, Date Range, Recipient Name |
| Default Sort | delivered_at DESC |
| Export | PDF (single notification), Excel/CSV (bulk export) |
| Access Control | School Admin only (own tenant data); Prime Super Admin (any tenant) |
| Business Rule | Displayed records are read-only per BR-NTF-008 |

### RPT-NTF-002 — Notification Analytics Dashboard (full spec)

| Property | Value |
|---------|-------|
| RPT ID | RPT-NTF-002 |
| Purpose | Real-time view of notification delivery performance |
| Data Source | `ntf_notifications` aggregate counters + `ntf_delivery_logs` |
| KPIs | Delivery Success Rate (%); Bounce Rate (%); Read Rate (%); Average Delivery Time (ms); Total Cost this Month (Rs.) |
| Visualization | Summary cards; bar chart by channel; trend line by week |
| Filters | Date Range, Channel, Notification Type |
| Export | PDF / Excel |
| Refresh | Real-time on page load |

### RPT-NTF-003 — Channel Performance Report (full spec)

| Property | Value |
|---------|-------|
| RPT ID | RPT-NTF-003 |
| Purpose | Compare cost and effectiveness across channels |
| Data Source | `ntf_delivery_logs` grouped by `channel_id` |
| Columns | Channel Name, Total Dispatched, Success Rate, Bounce Rate, Avg Delivery Time (ms), Total Cost (Rs.), Cost Per Successful Delivery (Rs.) |
| Filters | Academic Period, Date Range |
| Export | Excel / CSV |
| Cadence | Monthly summary; on-demand for custom periods |

### RPT-NTF-004 — Schedule Audit History (full spec)

| Property | Value |
|---------|-------|
| RPT ID | RPT-NTF-004 |
| Purpose | Track reliability of scheduled and recurring notification executions |
| Data Source | `ntf_schedule_audit` joined to `ntf_notifications` |
| Columns | Notification Title, Scheduled Time, Actual Execution Time, Execution Status, Recipients Resolved, Error Message |
| Filters | Notification, Status (Completed / Skipped / Failed), Date Range |
| Export | Excel / CSV |
| Key Use Case | Admin filters by "Failed" to find recurring notifications that are not firing |

### KPI Catalog

| KPI | Formula | Source | Target | Cadence |
|-----|---------|--------|--------|---------|
| Delivery Success Rate | sent_count / total_recipients × 100 | `ntf_notifications` | >= 95% per channel | Monthly |
| Bounce Rate | bounced_count / sent_count × 100 | `ntf_delivery_logs` | <= 2% for email | Monthly |
| Read Rate (In-App) | read_count / delivered_count × 100 | `ntf_notifications` | >= 60% | Monthly |
| Avg Delivery Latency | AVG(duration_ms) per channel | `ntf_delivery_logs` | Email <= 2000ms, SMS <= 1000ms | Weekly |
| Monthly Notification Cost | SUM(cost) from delivery logs | `ntf_delivery_logs` | Within school budget | Monthly |
| Failed Job Rate | COUNT(failed_jobs where queue='notifications') | `failed_jobs` | 0 per day | Daily |
| Scheduled Execution Success | completed / total_scheduled × 100 | `ntf_schedule_audit` | >= 99% | Daily |
