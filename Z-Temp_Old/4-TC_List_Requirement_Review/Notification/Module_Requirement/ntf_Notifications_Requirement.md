# Notifications — Business Requirements

## What This Screen Does

The Notifications screen is the primary workspace for creating, scheduling, dispatching, and monitoring all outbound communications from the Prime Gurukul platform. It provides a full lifecycle management interface — from drafting a notification through approval, processing, delivery tracking, and completion auditing. The screen also exposes trash management for soft-deleted records.

---

## When This Screen Is Used

- School administrators need to send a **one-time announcement** (holiday notice, event reminder) to all parents.
- System events (fee payment confirmation, exam result publication, attendance alert) **trigger automated notifications** via the `trigger()` method on `NotificationService`.
- A teacher needs to **schedule a recurring reminder** (weekly homework reminder every Monday at 8 AM).
- An admin needs to **review delivery statistics** (sent count, failed count, read count, cost) for a past notification.
- A moderator needs to **approve a promotional notification** created by a staff member before it is dispatched.
- An operator needs to **restore a mistakenly deleted notification** from the trash.

---

## Default Data Load

When the Notifications tab is active, the `index()` method on `NotificationManageController` loads:

| Data | Source | Details |
|------|--------|---------|
| Notifications list | `Notification` model | 10 per page, latest first, eager-loaded with `priority`, `confidentialityLevel`, `notificationStatus`, `tenant`, `creator`, `approver`, `template` |
| Filters | Query string | `search` (title/description), `status` (is_active), and tab-specific filters passed via request |

---

## Key Fields at a Glance

| Field | Type | Description |
|-------|------|-------------|
| `notification_uuid` | CHAR(36) | Public-facing unique identifier, generated via `Ramsey\Uuid` |
| `source_module` | VARCHAR(50) | Originating module name (e.g., "Fees", "Examination", "Attendance") |
| `source_record_id` | UNSIGNED INT | Record ID in the source module |
| `notification_event` | VARCHAR(50) | Event code (e.g., "fee.paid", "exam.published") |
| `notification_type` | ENUM | `TRANSACTIONAL`, `PROMOTIONAL`, `ALERT`, `REMINDER`, `DIGEST` |
| `title` | VARCHAR(255) | Notification subject/title |
| `description` | VARCHAR(512) | Plain-text summary or rich-text body |
| `template_id` | FK → `ntf_templates` | Optional template reference for rendering |
| `priority_id` | FK → `sys_dropdown_table` | Priority level (dropdown) |
| `confidentiality_level_id` | FK → `sys_dropdown_table` | Confidentiality classification (dropdown) |
| `schedule_type` | ENUM | `IMMEDIATE`, `SCHEDULED`, `RECURRING`, `TRIGGERED` |
| `scheduled_at` | DATETIME | When to send (null for IMMEDIATE/TRIGGERED) |
| `schedule_timezone` | VARCHAR(50) | Timezone for scheduled delivery (default `UTC`) |
| `recurring_pattern` | ENUM | `NONE`, `HOURLY`, `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`, `CUSTOM` |
| `recurring_expression` | VARCHAR(100) | Cron expression or RRULE for CUSTOM pattern |
| `recurring_executed_count` | INT | Counter of how many times recurring execution has run |
| `expires_at` | DATETIME | After this date, the notification will not be dispatched |
| `notification_status_id` | FK → `sys_dropdown_table` | Status: DRAFT, PENDING, APPROVED, SCHEDULED, PROCESSING, COMPLETED, PARTIAL, FAILED, CANCELLED, EXPIRED |
| `is_manual` | BOOLEAN | `true` if created manually by a user, `false` if system-triggered |
| `created_by` | FK → `users` | Creator reference |
| `approved_by` | FK → `users` | Approver reference (null until approved) |
| `processed_at` | DATETIME | Timestamp when processing began |
| `completed_at` | DATETIME | Timestamp when processing completed |
| `total_recipients` / `sent_count` / `failed_count` / `delivered_count` / `read_count` / `click_count` | INT | Aggregate delivery counters (calculated/denormalized) |
| `estimated_cost` / `actual_cost` | DECIMAL(12,4) | Cost tracking (sum of channel costs × recipient count) |

---

## Business Rules and Conditions

1. **Status Lifecycle**: A notification progresses through statuses: `DRAFT` → (optional `PENDING` for approval) → `APPROVED` → `SCHEDULED` → `PROCESSING` → `COMPLETED` / `PARTIAL` / `FAILED` / `CANCELLED` / `EXPIRED`. Each transition is gated by business logic.
2. **Promotional Approval**: If `notification_type` is `PROMOTIONAL`, the system auto-assigns status `PENDING` on creation if no `approved_by` is set. Promotional notifications require explicit approval before they can be processed.
3. **Cannot Process Twice**: The `canBeProcessed()` method on the `Notification` model returns `false` if `processed_at` is already set or `is_active` is `false`. Only statuses `APPROVED` and `SCHEDULED` are eligible for processing.
4. **Recurring Execution Tracking**: Each recurring execution increments `recurring_executed_count`. Execution halts when `recurring_end_at` is reached or `recurring_end_count` executions have completed, or `expires_at` is past.
5. **Channel Cascade**: A notification can reference multiple channels via the `ntf_notification_channels` pivot. Each pivot entry can specify its own provider, schedule, and retry policy, overriding defaults from the channel master.
6. **Cost Defaults**: On creation, `estimated_cost` and `actual_cost` are initialized to `0.0000`. Costs are updated during delivery processing based on channel `cost_per_unit` and delivery log entries.
7. **Expiry Halt**: The `scopeReadyToDispatch()` excludes notifications where `expires_at` is set and is in the past.
8. **Manual Flag**: `is_manual` defaults to `true` for user-created notifications via `prepareForValidation()`.
9. **Soft Delete Cascade**: Soft-deleting a notification does **not** automatically soft-delete its channels, targets, or resolved recipients — those must be cleaned up explicitly or by separate disposal rules.

---

## Workflow Steps

### Creating a Notification
1. User clicks "Add Notification" in the Notifications tab.
2. System gates on `tenant.notification.create`.
3. Form loads: templates (active, limit 50), channels (active), providers (from `sys_dropdown_table` keyed by `ntf_notification_channels.provider_id.provider`), statuses (from `sys_dropdown_table` keyed by `ntf_notifications.notification_status_id.notification_status`).
4. User fills in title, description, selects type, priority, confidentiality, schedule, attaches channels with provider/status.
5. System generates UUID, zeros out all counters and costs, sets `created_by` to current user.
6. If `PROMOTIONAL` and no approver, status is set to `PENDING`.
7. System creates the notification record and associated `ntf_notification_channels` entries.
8. Activity log entry created.
9. Redirect to tab-index with success message.

### Editing a Notification
1. User clicks edit on an existing notification.
2. System gates on `tenant.notification.update`.
3. Form pre-fills with current data.
4. Channels are re-created (old entries deleted, new entries inserted) on save.
5. Activity log entry created.

### Processing a Notification
1. User clicks "Process" on an APPROVED or SCHEDULED notification.
2. System gates on `tenant.notification.process`.
3. System calls `canBeProcessed()` — if false, returns 400 with error message.
4. In a transaction: sets `processed_at = now()`, updates status to `PROCESSING`, dispatches `ProcessNotificationJob`.
5. Returns JSON success.

### Toggling Active Status
1. User toggles the active switch.
2. System gates on `tenant.notification.update`.
3. Validates `is_active` as required boolean.
4. Saves and returns JSON with new state.

### Updating Status (Manual Override)
1. User selects a new status from dropdown.
2. System gates on `tenant.notification.update`.
3. Validates `notification_status_id` exists in `sys_dropdown_table`.
4. Updates and returns JSON success.

### Soft Delete / Restore / Force Delete
1. **Delete**: Sets `is_active = false`, calls `$notification->delete()`, logs activity, redirects with "trashed" flash message.
2. **Trash view**: Shows only soft-deleted records via `onlyTrashed()` scope.
3. **Restore**: Calls `$notification->restore()`, logs activity, redirects with success.
4. **Force Delete**: Deletes associated `NotificationChannel` records, then force-deletes the notification. Wrapped in try-catch; on failure redirects with error.

---

## Example Scenario

**Use case**: School principal wants to send a Diwali holiday reminder to all parents.

1. Admin goes to Notifications tab → clicks "Add Notification".
2. Fills: Title = "Diwali Holiday — School Closed", Type = `REMINDER`, Priority = High, Schedule = `SCHEDULED` for 2 days before holiday at 10 AM IST, Channels = SMS + Email.
3. Attaches template "holiday-reminder-v1" (Email channel), fills description field.
4. Since type is `REMINDER` (not PROMOTIONAL), status is set to `APPROVED` directly.
5. Admin clicks "Process" → `notification_status_id` becomes `PROCESSING`, `ProcessNotificationJob` dispatched.
6. Job resolves targets (Target Group: "All Parents"), filters by user preferences (skips users in quiet hours), renders template with holiday date, dispatches via SMS (MSG91 provider) and Email (AWS SES provider).
7. Delivery log records SUCCESS/FAILED per recipient.
8. Admin views the notification detail page: `total_recipients = 1250`, `sent_count = 1248`, `failed_count = 2`, `estimated_cost = ₹624.00`, `actual_cost = ₹623.50`.

---

## Related Screens

| Screen | Relationship |
|--------|-------------|
| Channels | Notifications select delivery channels from Channel Master |
| Providers | Notifications select providers per channel for actual dispatch |
| Templates | Notifications can reference a template for content rendering |
| Targets | Targets define the recipient scope for a notification |
| Resolved Recipients | After target resolution, individual recipients are stored here |
| Delivery Log | Each notification has many delivery log entries tracking its dispatch |
| User Preferences | User preferences are evaluated during recipient resolution to filter out opted-out or quiet-hours users |
| Inbox | End-users view their notification history via the Inbox screen |

---

## Requirements

| ID | Requirement Description | Priority | Status |
|----|------------------------|----------|--------|
| NTF-NOT-001 | System shall support five notification types: TRANSACTIONAL, PROMOTIONAL, ALERT, REMINDER, DIGEST | High | — |
| NTF-NOT-002 | System shall generate a UUID v4 for every notification automatically | High | — |
| NTF-NOT-003 | System shall support four schedule types: IMMEDIATE, SCHEDULED, RECURRING, TRIGGERED | High | — |
| NTF-NOT-004 | System shall enforce promotional notification approval workflow (PENDING status until approved) | High | — |
| NTF-NOT-005 | System shall enforce that a notification can only be processed once (guarded by `processed_at` timestamp) | High | — |
| NTF-NOT-006 | System shall support recurring patterns: HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY, CUSTOM (cron/RRULE) | Medium | — |
| NTF-NOT-007 | System shall track execution count for recurring notifications and halt when `recurring_end_count` is reached | Medium | — |
| NTF-NOT-008 | System shall support expiry dates — notifications with `expires_at` in the past shall be excluded from dispatch | High | — |
| NTF-NOT-009 | System shall allow assignment of multiple channels per notification with per-channel provider, schedule, and retry configuration | High | — |
| NTF-NOT-010 | System shall initialize delivery counters (sent, failed, delivered, read, click) to zero on creation | High | — |
| NTF-NOT-011 | System shall calculate and track estimated and actual costs per notification | Medium | — |
| NTF-NOT-012 | System shall log every lifecycle event (create, update, process, toggle, delete, restore) via the activity log | High | — |
| NTF-NOT-013 | System shall provide soft delete with trash view, restore, and force delete capabilities | High | — |
| NTF-NOT-014 | System shall support toggling notification active status via AJAX | Medium | — |
| NTF-NOT-015 | System shall support manual status override via admin interface | Low | — |
| NTF-NOT-016 | System shall dispatch `ProcessNotificationJob` when processing is initiated | High | — |
| NTF-NOT-017 | System shall allow filtering by search (title/description) and active status in the listing | Medium | — |

---

## Who Can Access

| Action | Permission Gate | Typical Role |
|--------|----------------|-------------|
| View notifications list | `tenant.notification.viewAny` | Admin, Principal, Manager |
| View single notification | `tenant.notification.view` | Admin, Manager |
| Create notification | `tenant.notification.create` | Admin, Manager, Staff |
| Update notification | `tenant.notification.update` | Admin, Manager |
| Delete (soft) notification | `tenant.notification.delete` | Admin |
| Restore notification | `tenant.notification.restore` | Admin |
| Force delete notification | `tenant.notification.forceDelete` | Super Admin |
| Process notification | `tenant.notification.process` | Admin, Manager |
| Update notification status | `tenant.notification.update` | Admin |

---

## Logic Flow

```
User Action → Controller → Gate Authorization → Form Request Validation → Business Logic → Response
                     ↓
            NotificationManageController
                     ↓
       ┌─────────────┼─────────────┐
       │             │             │
   index()       create()      store()/update()
   / tabIndex()   / edit()       / process()
                   / show()      / destroy()
                                 / restore()
                                 / forceDelete()
                                 / toggleStatus()
                                 / updateStatus()
```

### Notification Processing Flow (process action):

```
start → Gate: tenant.notification.process
       → Notification::findOrFail($id)
       → canBeProcessed() check
         → false → return 400 JSON error
         → true  → DB::transaction:
                     1. Set processed_at = now()
                     2. Set notification_status_id = PROCESSING
                     3. Activity log entry
                     4. Dispatch ProcessNotificationJob($notification)
       → return 200 JSON success
```

### Recipient Resolution Pipeline (called by ProcessNotificationJob):

```
Notification → Targets → RecipientResolutionService::resolveForNotification()
       ↓
  For each target: resolve user/group/class/section → array of recipients
       ↓
  Filter by UserPreferences (canReceiveNow, quiet hours, opt-in)
       ↓
  Create ResolvedRecipient records per recipient per channel
       ↓
  Insert into DeliveryQueue
       ↓
  Dispatch via channel provider
       ↓
  Log to ntf_delivery_logs
       ↓
  Update Notification counters (sent_count, failed_count, etc.)
```

---

## Validate Before Save

| Field | Validation Rule | Error Message |
|-------|----------------|---------------|
| `source_module` | required, string, max:50 | — |
| `notification_type` | required, in: TRANSACTIONAL/PROMOTIONAL/ALERT/REMINDER/DIGEST | The selected notification type is invalid |
| `title` | required, string, max:255 | — |
| `template_id` | nullable, exists:ntf_templates,id | — |
| `priority_id` | required, exists:sys_dropdown_table,id | The priority field is required |
| `confidentiality_level_id` | required, exists:sys_dropdown_table,id | The confidentiality level field is required |
| `schedule_type` | required, in: IMMEDIATE/SCHEDULED/RECURRING/TRIGGERED | The selected schedule type is invalid |
| `scheduled_at` | required_if:schedule_type,SCHEDULED,RECURRING, date | The scheduled at field is required when schedule type is scheduled or recurring |
| `recurring_pattern` | required_if:schedule_type,RECURRING, in: NONE/HOURLY/DAILY/WEEKLY/MONTHLY/YEARLY/CUSTOM | The recurring pattern field is required when schedule type is recurring |
| `recurring_expression` | required_if:recurring_pattern,CUSTOM, string, max:100 | The recurring expression field is required when recurring pattern is custom |
| `expires_at` | nullable, date, after:scheduled_at | The expiry date must be after the scheduled date |
| `recurring_end_at` | nullable, date, after:scheduled_at | The recurring end date must be after the scheduled date |
| `notification_status_id` | required, exists:sys_dropdown_table,id | The notification status field is required |
| `channels.*.channel_id` | required, exists:ntf_channel_master,id | The channel field is required for each selected channel |
| `channels.*.status_id` | required, exists:sys_dropdown_table,id | The channel status field is required |
| `notification_uuid` | nullable, string, max:36, unique | — |

---

## Error Handling and Validation Messages

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Validation failure | 302 Redirect back | Form errors displayed in Blade session |
| Notification not found | 404 | `ModelNotFoundException` → 404 page |
| Cannot process (already processed) | 400 | JSON: `{"success": false, "message": "This notification cannot be processed at this time."}` |
| Process exception | 500 | JSON: `{"success": false, "message": "Failed to process notification: <error>"}` |
| Force delete exception | 302 Redirect | `flash('operation_failed.notification')` error message |
| Gate denied | 403 | Laravel authorization exception → 403 page |
| Toggle status invalid | 422 | Validation error on `is_active` required boolean |

---

## Success Scenarios

1. **Create**: Redirect to `notification.tab-index` with `flash('success', 'Notification created successfully')`.
2. **Update**: Redirect to `notification.tab-index` with `flash('success', 'Notification updated successfully')`.
3. **Delete (soft)**: Redirect with `flash('success', 'Notification moved to trash')`.
4. **Restore**: Redirect to trash view with `flash('success', 'Notification restored.')`.
5. **Force Delete**: Redirect to trash view with `flash('success', 'Notification permanently deleted.')`.
6. **Process**: JSON `{"success": true, "message": "Notification processing started successfully."}`.
7. **Toggle Status**: JSON `{"success": true, "is_active": <bool>, "message": "Status updated successfully"}`.
8. **Update Status**: JSON `{"success": true, "message": "Notification status updated successfully."}`.

---

## Failure Scenarios

1. **Promotional without approval**: Notification created with status `PENDING`; it will not be processable until an admin approves it.
2. **Process on non-eligible status**: If a notification's status is not `APPROVED` or `SCHEDULED`, `canBeProcessed()` returns `false` and the UI displays an error.
3. **Process on already processed**: If `processed_at` is set, the API rejects with a 400 error.
4. **Rate limit during dispatch**: The `NotificationService::isRateLimited()` method skips dispatch for a channel and logs a warning — the notification may end up with `PARTIAL` status.
5. **Provider failure**: If a provider endpoint is down, the delivery log records the error and the notification's `failed_count` increments. If retries are exhausted, the delivery queue marks the item as permanently failed.
6. **Expired notification**: If a SCHEDULED or RECURRING notification's `expires_at` passes before processing, it is excluded from the ready-to-dispatch scope and never sent.
7. **Nonexistent template**: If `template_id` references a deleted template, the notification can still be created but template rendering will fail at dispatch time.

---

## Dependencies module and tables

### Primary Tables
- `ntf_notifications` — Core notification records
- `ntf_notification_channels` — Channel assignments per notification
- `ntf_notification_targets` — Target specifications
- `ntf_resolved_recipients` — Resolved individual recipients
- `ntf_delivery_logs` — Delivery attempt audit trail
- `ntf_templates` — Message templates (referenced via `template_id`)
- `ntf_channel_master` — Channel definitions (referenced via pivot)
- `ntf_provider_master` — Provider endpoints (referenced via pivot)
- `sys_dropdown_table` — Lookup values for priority, confidentiality, status, and channel status

### External Module Dependencies
- **SchoolSetup** (`Modules\SchoolSetup\Models\User`) — Creator and approver references
- **Prime** (`Modules\Prime\Models\Tenant`) — Tenant scope isolation
