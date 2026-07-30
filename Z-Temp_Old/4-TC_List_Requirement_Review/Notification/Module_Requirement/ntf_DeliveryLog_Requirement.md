# Delivery Log — Business Requirements

## What This Screen Does
The Delivery Log screen provides a read-only, append-only audit trail of every delivery attempt for every notification sent through the system. It captures the complete lifecycle of each message — from the moment it is queued, through sending, delivery, read receipts, and any failures such as bounces or complaints. This is the system's single source of truth for notification delivery status.

## When This Screen Is Used
- When monitoring the delivery progress of a dispatched notification in real-time
- When investigating why a specific user did not receive a notification
- When reviewing bounce rates, failure reasons, and delivery performance
- When auditing notification costs and provider response data
- When generating delivery statistics reports (delivered vs. failed vs. bounced vs. read)
- When troubleshooting provider integration issues via response_payload inspection

## Default Data Load
On page load, the screen displays a paginated list of delivery log records for the most recent 24-hour period, ordered by created_at descending. High-level stats cards at the top show aggregate counts: **Total Sent**, **Delivered**, **Failed**, **Bounced**, **Read**, and **Clicked**. Filters for notification_id, channel, delivery_stage, date range, and resolved_user_id are available.

## Key Fields at a Glance

| Field | Type | Purpose |
|-------|------|---------|
| notification_id | BIGINT FK | The parent notification |
| channel_id | BIGINT FK | Delivery channel used |
| resolved_recipient_id | BIGINT FK | The resolved recipient this log belongs to |
| resolved_user_id | BIGINT FK | The end-user who was the target |
| provider_id | BIGINT FK | The delivery provider used (from ntf_provider_master) |
| delivery_status_id | BIGINT FK | Status reference from sys_dropdown_table |
| delivery_stage | ENUM | Current stage: QUEUED / SENT / DELIVERED / READ / CLICKED / BOUNCED / COMPLAINT / UNSUBSCRIBED |
| provider_message_id | VARCHAR | Provider's unique message identifier |
| delivered_at | DATETIME | When the message was confirmed delivered |
| read_at | DATETIME | When the message was read by the user |
| clicked_at | DATETIME | When a link in the message was clicked |
| bounced_at | DATETIME | When the message bounced |
| complaint_at | DATETIME | When a spam complaint was filed |
| response_code | VARCHAR | Provider response status code |
| response_payload | JSON | Full provider response payload for debugging |
| error_message | TEXT | Human-readable error description |
| duration_ms | INT | Time taken for the delivery attempt in milliseconds |
| ip_address | VARCHAR | IP address of the sending server |
| user_agent | VARCHAR | User agent of the recipient's device (for read/click) |
| cost | DECIMAL | Cost of this individual message |

## Business Rules and Conditions
- **Append-only audit trail (BR-NTF-008):** Delivery log records are strictly append-only. No editing or deletion is permitted under any circumstances. No create/update/delete routes exist. The `created_at` timestamp is immutable.
- **No dedicated controller:** This feature uses the `NotificationDeliveryLog` model directly through an index view. No CRUD controller endpoints exist.
- **Read-only tab:** All routes on this screen are GET-only. There are no POST, PUT, PATCH, or DELETE endpoints.
- **Delivery stage state machine:** Records progress through stages in a forward-only direction: QUEUED → SENT → DELIVERED → READ/CLICKED. Bounce, complaint, or unsubscribed statuses are terminal states that may occur at any point after SENT.
- **Stage transitions are additive:** When a new stage is reached, the corresponding timestamp is set (e.g., `read_at` when READ stage is reached). Previous timestamps remain unchanged.
- **Stats cards:** The header displays aggregate counts for quick performance review. Cards show: Total Sent, Delivered, Failed, Bounced, Read, and Clicked — computed from the visible query scope.
- **Provider data preservation:** The full `response_payload` JSON from the provider is stored to enable debugging without relying on external provider dashboards.
- **Cost tracking:** Each delivery log records the `cost` incurred per message for billing and analytics purposes.

## Workflow Steps
1. Administrator dispatches a notification.
2. Dispatch pipeline creates a resolved_recipient record.
3. Immediately after, a delivery log record is created with `delivery_stage = QUEUED`.
4. The channel provider picks up the queue and attempts delivery. The log updates to `SENT` with `provider_message_id` and `response_code`.
5. Provider sends a delivery receipt webhook → system updates log to `DELIVERED` with `delivered_at`.
6. If the user opens the message, read tracking updates `READ` with `read_at`.
7. If the user clicks a link, click tracking updates `CLICKED` with `clicked_at`.
8. If delivery fails, status moves to `BOUNCED` with `error_message` and `bounced_at`.
9. Administrator views the delivery log to monitor progress and investigate any failures.
10. Stats cards auto-refresh to reflect the latest counts.

## Example Scenario
The school sends a fee reminder to 200 parents. As the dispatch runs:
- 200 delivery log records are created with `QUEUED` status.
- The email provider picks up the queue: 195 move to `SENT`, 5 fail with invalid email → `BOUNCED`.
- Provider webhooks arrive: 190 of the 195 sent are confirmed `DELIVERED`, 5 remain `SENT` (pending).
- Over the next 24 hours: 150 users read the email (`READ`), 45 click the payment link (`CLICKED`).
- The admin views the Delivery Log: stats show 200 Total Sent, 190 Delivered, 5 Bounced, 5 Pending, 150 Read, 45 Clicked.

## Related Screens
- **Notification Master:** The parent notification being tracked
- **Resolved Recipients:** The recipient record this log belongs to
- **Channel Master (ntf_channel_master):** The channel used for delivery
- **Provider Master (ntf_provider_master):** The provider that handled delivery
- **User Preferences:** Checked when investigating why a user was skipped

---

## Requirements

### REQ-DL-01: Append-Only Records
Delivery log records are strictly append-only. No update or delete operations are permitted at the database or application level. Only INSERT and SELECT operations are allowed (BR-NTF-008).

### REQ-DL-02: Automated Stage Creation
The dispatch pipeline must automatically create a delivery log record with `delivery_stage = QUEUED` immediately after creating a resolved recipient.

### REQ-DL-03: Stage Progression
The system must support forward-only progression through delivery stages: QUEUED → SENT → DELIVERED → READ / CLICKED, with BOUNCED / COMPLAINT / UNSUBSCRIBED as terminal failure states.

### REQ-DL-04: Provider Webhook Integration
The system must accept webhooks from delivery providers to update delivery_stage, provider_message_id, response_code, response_payload, and the appropriate timestamp fields.

### REQ-DL-05: Stats Dashboard
The index view must display aggregate stats cards showing counts for each delivery_stage: Total Sent, Delivered, Failed, Bounced, Read, and Clicked.

### REQ-DL-06: Date Range Filtering
The index view must support filtering by date range (created_at), notification_id, channel_id, delivery_stage, and resolved_user_id.

### REQ-DL-07: Provider Payload Preservation
The full provider `response_payload` JSON must be preserved for debugging and auditing. This field is never truncated or modified once set.

### REQ-DL-08: Cost Tracking
Each delivery log record must capture the `cost` of the individual message for billing and analytics. Cost may be zero if not applicable.

### REQ-DL-09: Duration Tracking
The system must record `duration_ms` for each delivery attempt to enable performance monitoring.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | View all delivery logs across all tenants | All tenants |
| School Admin | View delivery logs for own tenant's notifications | Own tenant |
| Manager | View delivery logs for own tenant (read-only) | Own tenant |
| Standard User | View delivery logs for notifications they created | Own records |

*Note: Since Delivery Log has no dedicated controller, access is governed by the policy on the parent Notification model. Only view-level permissions apply.*

---

## Logic Flow

### Delivery Log Creation Flow (Dispatch Pipeline)
```
Create resolved_recipient →
Insert delivery_log (delivery_stage = QUEUED) →
Set notification_id, channel_id, resolved_recipient_id →
Set resolved_user_id →
Set cost = 0.00 →
Flush
```

### Provider Webhook Processing Flow
```
Receive webhook from provider →
Match by provider_message_id →
Validate delivery_stage transition (forward-only) →
If transition is valid:
    Update delivery_stage →
    Set appropriate timestamp (delivered_at, read_at, bounced_at, etc.) →
    Set response_code, response_payload →
    Set error_message if applicable →
    Set duration_ms if available →
    Save
Else:
    Log and ignore webhook (stale/out-of-order update)
```

### Stats Card Computation
```
Query delivery_logs matching current filter scope →
Group by delivery_stage →
Count each stage →
Display cards: Delivered (DELIVERED), Failed (BOUNCED + COMPLAINT),
Bounced (BOUNCED), Read (READ), Clicked (CLICKED),
Total Sent (all records)
```

---

## Validate Before Save

Since delivery log records are append-only and created solely by the dispatch pipeline (not via manual forms), the following internal validations apply:

| Field | Rule | Enforcement |
|-------|------|-------------|
| notification_id | required, exists:ntf_notifications,id | Application layer |
| channel_id | required, exists:ntf_channel_master,id | Application layer |
| resolved_recipient_id | required, exists:ntf_resolved_recipients,id | Application layer |
| resolved_user_id | required, exists:sys_users,id | Application layer |
| provider_id | required, exists:ntf_provider_master,id | Application layer |
| delivery_stage | required, in:QUEUED,SENT,DELIVERED,READ,CLICKED,BOUNCED,COMPLAINT,UNSUBSCRIBED | Application + DB enum |
| delivery_stage transition | Must be forward-only (e.g., SENT → DELIVERED OK; DELIVERED → SENT invalid) | Application layer |
| response_payload | nullable, valid JSON | Application layer |
| cost | nullable, numeric, min:0 | Application layer |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Attempt to edit a delivery log | Delivery log records cannot be edited. | 405 Method Not Allowed |
| Attempt to delete a delivery log | Delivery log records cannot be deleted. | 405 Method Not Allowed |
| Invalid stage transition (backward) | Invalid delivery stage transition from {current_stage} to {requested_stage}. | 422 |
| Invalid provider_message_id format | The provider message ID format is invalid. | 422 |
| Unknown provider webhook | No delivery log found for provider_message_id: {id}. | 404 |
| Duplicate webhook (already at or beyond requested stage) | Webhook ignored — delivery already at stage: {current_stage}. | 200 (no-op) |
| Unauthorized access | You do not have permission to view delivery logs. | 403 |

---

## Success Scenarios

- **View List:** Delivery logs displayed with stats cards and pagination.
- **Filter:** Logs filtered successfully by date range, notification, channel, stage, or user.
- **Stage Progression:** Delivery log updated from QUEUED → SENT → DELIVERED with timestamps.
- **Webhook Processed:** Provider webhook handled and delivery_stage updated.
- **Bounce Recorded:** Bounce captured with error_message and bounced_at.
- **Read/Click Tracked:** read_at / clicked_at updated successfully.

## Failure Scenarios

- **Attempt to edit/delete:** 405 Method Not Allowed. No operation performed.
- **Invalid webhook payload:** Webhook received but provider_message_id not found. Logged for investigation.
- **Stale webhook:** Webhook arrives after already reaching a further stage. Ignored gracefully.
- **Provider down:** Webhooks delayed. Delivery stays at SENT until webhook arrives or timeout.
- **Database error:** 500 Internal Server Error. Append fails — notification may still be queued.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_delivery_logs` | Table | Primary table for this feature |
| `ntf_notifications` | Table | Parent notification (FK: notification_id) |
| `ntf_channel_master` | Table | Delivery channel (FK: channel_id) |
| `ntf_resolved_recipients` | Table | Source recipient (FK: resolved_recipient_id) |
| `sys_users` | Table | Target user (FK: resolved_user_id) |
| `ntf_provider_master` | Table | Provider used (FK: provider_id) |
| `sys_dropdown_tables` | Table | Delivery status reference (FK: delivery_status_id) |
| `ntf_user_devices` | Table | Target device (indirect — via resolved_recipient) |
| `Modules\Notification\Models\Notification` | Model | Parent notification |
| `Modules\Notification\Models\NotificationDeliveryLog` | Model | Primary model for this feature |
| `Modules\Notification\Models\ResolvedRecipient` | Model | Related recipient |
| `Modules\Notification\Policies\PrimeNotificationPolicy` | Policy | Access control (via parent notification) |
| Business Rules | BR-NTF-008 | Delivery log records are append-only — no editing or deletion |
