# User Preferences — Business Requirements

## What This Screen Does
The User Preferences screen manages individual user communication preferences within the notification system. Each user can configure per-channel settings (e.g., email, SMS, push, in-app) including opt-in/opt-out status, quiet hours, digest mode, and priority thresholds. This is the GDPR-compliance and user-level preference control center.

## When This Screen Is Used
- When a user wants to opt out of a specific notification channel (e.g., disable SMS notifications)
- When a user sets quiet hours to defer non-critical notifications during specific times
- When a user enables daily digest mode for non-urgent notifications
- When an administrator reviews or overrides a user's channel preferences
- When the dispatch pipeline checks whether a user is reachable on a given channel

## Default Data Load
On page load, the screen displays a paginated list of all user preference records. Filtering by user name, channel, and is_enabled status is available. Each row shows the user, channel, is_enabled toggle, is_opted_in status, quiet hours window, and digest preference.

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| user_id | BIGINT FK | The user these preferences belong to |
| channel_id | BIGINT FK | The notification channel (from ntf_channel_master) |
| is_enabled | BOOLEAN | Master enable/disable for this user+channel |
| is_opted_in | BOOLEAN | GDPR explicit consent flag |
| opted_in_at | DATETIME | Timestamp of when the user opted in |
| opted_out_at | DATETIME | Timestamp of the last opt-out |
| contact_value | VARCHAR | User's contact address for this channel (email, phone, device token) |
| quiet_hours_start | TIME | Start of quiet hours (HH:MM) |
| quiet_hours_end | TIME | End of quiet hours (HH:MM) |
| quiet_hours_timezone | VARCHAR | Timezone for quiet hours (e.g., Asia/Kolkata) |
| daily_digest | BOOLEAN | Whether the user wants a daily digest |
| digest_time | TIME | Scheduled time for the daily digest |
| priority_threshold_id | BIGINT FK | Minimum priority level to bypass quiet hours |
| is_active | BOOLEAN | Soft toggle for the preference record |

## Business Rules and Conditions
- **Unique per user+channel:** Each user can have only one preference record per channel (UNIQUE constraint on user_id, channel_id).
- **Opt-out is absolute override (BR-NTF-002):** If `is_opted_in = false`, the user must NOT receive any notifications on that channel regardless of other settings. This overrides all other preferences and group memberships.
- **Quiet hours defer delivery, not cancel (BR-NTF-003):** If the current time falls within `quiet_hours_start` to `quiet_hours_end`, notifications with priority below `priority_threshold_id` are deferred until quiet hours end. They are NOT dropped.
- **Daily digest:** If `daily_digest = true`, non-urgent notifications are batched and sent at `digest_time` instead of in real-time.
- **System-level opt-out:** Even if `is_enabled = true`, the system may still skip delivery if the channel master or provider is inactive.
- Soft-deleted preference records are treated as if the user has no preference (system defaults apply).

## Workflow Steps
1. User navigates to Settings → Notification Preferences.
2. Sees a list of available channels with their current preference status.
3. Toggles `is_enabled` on/off for each channel.
4. For opted-out channels, clicks "Opt In" to provide GDPR consent. The system records `opted_in_at`.
5. Optionally sets `quiet_hours_start`, `quiet_hours_end`, and `quiet_hours_timezone`.
6. Optionally enables `daily_digest` and sets `digest_time`.
7. Sets `priority_threshold_id` to determine which priority levels bypass quiet hours.
8. Saves — the system upserts the preference record per channel.
9. Administrator can view/edit any user's preferences via the admin interface.

## Example Scenario
Teacher Ravi wants to stop receiving SMS notifications after 8 PM. He sets quiet hours from 20:00 to 06:00 in Asia/Kolkata, sets priority_threshold to "High" so that only high-priority messages come through during quiet hours, and enables daily digest for medium-priority notifications at 07:00 AM. He also opts out of SMS marketing entirely by setting `is_opted_in = false` for the marketing channel. The dispatch pipeline honors all these settings.

## Related Screens
- **Notification Master:** The originating notification record
- **Resolved Recipients:** User preferences are checked when resolving recipients
- **Delivery Log:** Shows whether delivery was deferred or skipped due to preferences
- **Channel Master (ntf_channel_master):** Defines the available channels

---

## Requirements

### REQ-UP-01: Per-Channel Preference
Each user must have exactly one preference record per channel. The system must enforce a UNIQUE(tenant_id, user_id, channel_id) constraint.

### REQ-UP-02: GDPR Opt-In/Opt-Out
Users must be able to explicitly opt in or opt out of each channel. Opt-out must be an absolute override that prevents all notifications on that channel (BR-NTF-002).

### REQ-UP-03: Opt-In/Out Timestamps
When a user opts in, the system must record `opted_in_at`. When a user opts out (by unchecking is_opted_in), the system must record `opted_out_at`. Opting in again updates `opted_in_at` and clears `opted_out_at`.

### REQ-UP-04: Quiet Hours
Users must be able to set `quiet_hours_start`, `quiet_hours_end`, and `quiet_hours_timezone`. During quiet hours, notifications below `priority_threshold_id` are deferred, not cancelled (BR-NTF-003).

### REQ-UP-05: Daily Digest
Users must be able to enable `daily_digest` with a scheduled `digest_time`. The dispatch pipeline must respect this and batch non-urgent notifications.

### REQ-UP-06: Priority Threshold
Users must be able to set `priority_threshold_id` to specify the minimum priority level that bypasses quiet hours. Notifications at or above this threshold are delivered immediately even during quiet hours.

### REQ-UP-07: Toggle Enabled
Administrator must be able to toggle `is_enabled` for any user's preference record via the `toggleEnabled()` route.

### REQ-UP-08: Soft Delete and Restore
Preference records must support soft delete, restore, and force delete. A deleted preference means system defaults apply.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All tenant.user-preference.* permissions | All tenants |
| School Admin | tenant.user-preference.viewAny, .create, .update, .delete | Own tenant (all users) |
| School Admin | tenant.user-preference.restore, .forceDelete | Own tenant (trashed records) |
| Individual User | tenant.user-preference.view (own), .update (own) | Own records only |
| Manager | tenant.user-preference.viewAny | Own tenant (read-only) |

---

## Logic Flow

### Create/Update Flow
```
User submits preferences → UserPreferenceRequest validation →
Check existing record for user_id + channel_id →
If exists: update; If not: create →
Record opted_in_at if is_opted_in changes to true →
Record opted_out_at if is_opted_in changes to false →
Save → Return success
```

### Quiet Hours Check Flow (Dispatch Pipeline)
```
Get current time in user's quiet_hours_timezone →
If current time between quiet_hours_start and quiet_hours_end:
    If notification priority >= priority_threshold_id:
        Deliver immediately
    Else:
        Defer until quiet_hours_end
Else:
    Deliver normally
```

### Digest Check Flow (Dispatch Pipeline)
```
If daily_digest = true AND notification priority < URGENT:
    Queue for digest batch
    Schedule delivery at digest_time
Else:
    Deliver immediately
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| user_id | required, exists:sys_users,id | Please select a valid user. |
| channel_id | required, exists:ntf_channel_master,id | Please select a valid notification channel. |
| user_id + channel_id | unique:ntf_user_preferences,user_id,channel_id | This user already has a preference set for this channel. |
| is_opted_in | boolean | The opt-in value must be true or false. |
| quiet_hours_start | nullable, date_format:H:i | Quiet hours start must be a valid time in HH:MM format. |
| quiet_hours_end | nullable, date_format:H:i | Quiet hours end must be a valid time in HH:MM format. |
| quiet_hours_timezone | nullable, timezone | The quiet hours timezone must be a valid timezone identifier. |
| daily_digest | boolean | The digest preference must be true or false. |
| digest_time | nullable, date_format:H:i, required_if:daily_digest,true | Digest time is required when daily digest is enabled. |
| priority_threshold_id | nullable, exists:sys_dropdown_tables,id | Please select a valid priority threshold. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Duplicate user+channel | This user already has a preference set for this channel. | 422 |
| Invalid user_id | The selected user does not exist. | 422 |
| Invalid channel_id | The selected notification channel does not exist. | 422 |
| Missing digest_time when digest enabled | Digest time is required when daily digest is enabled. | 422 |
| Invalid quiet hours timezone | The quiet hours timezone must be a valid timezone. | 422 |
| Attempt to delete record | Preference record deleted successfully. | 200 |
| Unauthorized access to other user's records | You do not have permission to modify this user's preferences. | 403 |

---

## Success Scenarios

- **Create/Update:** Notification preferences saved successfully. Settings take effect immediately.
- **Opt-In:** User opted in successfully. opted_in_at recorded.
- **Opt-Out:** User opted out successfully. System will block all notifications on this channel.
- **Toggle Enabled:** Preference status changed to enabled/disabled successfully.
- **Quiet Hours Set:** Quiet hours configured. Notifications will be deferred during the specified window.
- **Delete (Soft):** Preference record deleted. System defaults will apply.

## Failure Scenarios

- **Duplicate preference:** User already has a preference for this channel. Use update instead.
- **Invalid user or channel:** Reference does not exist. 422 error.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back.
- **Preference not found:** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_user_preferences` | Table | Primary table for this feature |
| `sys_users` | Table | User reference (FK: user_id) |
| `ntf_channel_master` | Table | Channel reference (FK: channel_id) |
| `sys_dropdown_tables` | Table | Priority threshold reference (FK: priority_threshold_id) |
| `ntf_resolved_recipients` | Table | Consumed during recipient resolution (checks preferences) |
| `ntf_delivery_logs` | Table | Deferral decisions logged here |
| `Modules\Auth\Models\User` | Model | User model |
| `Modules\Notification\Models\ChannelMaster` | Model | Channel master model |
| `tenant.user-preference.*` | Permissions | 7 permission keys for CRUD + restore + forceDelete |
| `SoftDeletes` | Trait | Laravel's built-in soft delete functionality |
| Business Rules | BR-NTF-002 | Opt-out is absolute override |
| Business Rules | BR-NTF-003 | Quiet hours defer, not cancel |
