

# Channels — Business Requirements

## What This Screen Does

The Channels screen manages the **delivery channel definitions** used by the Notification module. A channel represents a communication medium (Email, SMS, WhatsApp, In-App notification, or Push notification) along with its operational parameters: priority order, retry policy, rate limits, cost per unit, and optional fallback channel for automatic escalation on failure. Channels are the bridge between the abstract concept of "send a notification" and the concrete mechanism of "send via which route."

---

## When This Screen Is Used

- An administrator needs to **add a new SMS channel** for transactional alerts (fee reminders, exam results) using a specific provider endpoint.
- A school wants to **increase the daily email limit** from 10,000 to 25,000 during exam season.
- An admin needs to **configure fallback** — if Email fails, fall back to SMS; if SMS fails, fall back to WhatsApp.
- A channel reaches its monthly limit and needs to be **temporarily disabled** until the next billing cycle.
- An operator needs to **audit channel usage statistics** (how many notifications used this channel, which channels depend on it as fallback).
- A channel configuration has changed and the old channel needs to be **soft-deleted** and a new one created.

---

## Default Data Load

When the Channels tab is active, the `index()` method on `ChannelMasterController` loads:

| Data | Source | Details |
|------|--------|---------|
| Channels list | `ChannelMaster` model | 10 per page, latest first, paginated with query string |
| Search filter | Request `search` | Matches against `name` and `code` columns (LIKE) |
| Status filter | Request `status` | Filters by `is_active` boolean |

The `create()` and `edit()` methods additionally load:

| Data | Source | Details |
|------|--------|---------|
| Channel types | `ChannelMaster::CHANNEL_TYPES` | EMAIL, SMS, PUSH, WHATSAPP, IN_APP |
| Channel codes | `ChannelMaster::CHANNEL_CODES` | Same list as types |
| Fallback channels | `ChannelMaster::active()` | All active channels eligible as fallback targets (on edit: excludes the channel itself) |

---

## Key Fields at a Glance

| Field | Type | Description |
|-------|------|-------------|
| `code` | VARCHAR(20) | Machine key: `EMAIL`, `SMS`, `WHATSAPP`, `IN_APP`, `PUSH` — stored uppercase via mutator |
| `name` | VARCHAR(50) | Human-readable display name (e.g., "School Email", "Transactional SMS") |
| `description` | TEXT | Optional notes about this channel's purpose |
| `channel_type` | ENUM | `IMMEDIATE` — for real-time messages (OTP, alerts); `BULK` — for mass broadcasts (announcements); `TRANSACTIONAL` — for transaction-related messages (receipts, confirmations) — default `TRANSACTIONAL` |
| `priority_order` | TINYINT | 1 (highest) to 10 (lowest) — determines channel selection order when multiple channels are available; default `5` |
| `max_retry` | INT | Maximum number of retry attempts when delivery fails; default `3` |
| `retry_delay_minutes` | INT | Minutes to wait before each retry; default `5` |
| `rate_limit_per_minute` | INT | Maximum messages per minute through this channel; default `100` |
| `daily_limit` | INT | Maximum messages per calendar day; default `10000` |
| `monthly_limit` | INT | Maximum messages per calendar month; default `100000` |
| `cost_per_unit` | DECIMAL(10,4) | Cost in INR per single message unit; default `0.0000` |
| `fallback_channel_id` | FK → self | On delivery failure, automatically escalate to this channel (null = no fallback) |
| `is_active` | BOOLEAN | Soft on/off switch for the channel; default `true` |

---

## Business Rules and Conditions

1. **Code Uniqueness**: The channel `code` must be unique per tenant. The validation rule `\Illuminate\Validation\Rule::unique('ntf_channel_master')->where(fn($q) => $q->where('tenant_id', $tenantId))` enforces this with tenant-aware scoping.
2. **Self-Fallback Prohibited**: A channel cannot be its own fallback. The custom validation rule rejects `fallback_channel_id` equal to the channel's own `id`.
3. **Circular Fallback Protection**: When saving `fallback_channel_id`, the validation walks the fallback chain up to **5 hops depth**. If any channel in the chain points back to a previously visited channel (including the current one), validation fails with: "Circular fallback chain detected at depth N."
4. **Fallback on Delete**: Before soft-deleting a channel, the system checks if any other channel references it as `fallback_channel_id`. If yes, the delete is rejected with: "Cannot delete channel as it is used as fallback by other channels." This check is also enforced on force-delete (including across soft-deleted channels).
5. **Cost Tracking**: The `cost_per_unit` feeds into the notification's `estimated_cost` and `actual_cost` calculations during delivery logging.
6. **Rate Limit Enforcement at Dispatch**: The `NotificationService::isRateLimited()` method checks per-minute, daily, and monthly counts from `ntf_delivery_logs` against the channel's configured limits. If exceeded, dispatch is skipped and a warning is logged.
7. **Scope by Tenant**: Channel queries are scoped to the current tenant via `when(tenant(), fn($q) => $q->where('tenant_id', tenant()->id))` pattern, appearing explicitly in `create()`, `edit()`, and `trashed()`.
8. **Priority Ordering**: Channels with lower `priority_order` values are preferred during automatic channel selection for dispatch.

---

## Workflow Steps

### Creating a Channel
1. User navigates to Channels tab → clicks "Add Channel".
2. System gates on `tenant.channel-master.create`.
3. Form renders: channel types dropdown, channel codes dropdown, fallback channels list (active excluding self).
4. User selects code (e.g., EMAIL), enters name, description, channel type, and optionally configures limits, cost, and fallback.
5. On submit, `validateChannel()` runs:
   - Validates code uniqueness per tenant
   - Validates all numeric ranges (min/max)
   - Validates fallback: not self, no circular chain
6. System creates record with `tenant_id` from current tenant, uppercase `code`, and defaults for any omitted numeric fields.
7. Redirects to `notification.tab-index` with success.

### Editing a Channel
1. User clicks edit on a channel row.
2. System gates on `tenant.channel-master.update`.
3. Form pre-fills; fallback channels list excludes the channel being edited.
4. Same validation as create (with `$id` passed to ignore current record for unique check).
5. Updates and redirects.

### Viewing a Channel
1. User clicks view on a channel row.
2. System gates on `tenant.channel-master.view`.
3. Loads channel with `notificationChannels` (pivot records) and `channelsUsingAsFallback` (other channels that fall back to this one).
4. Displayed in a read-only detail view.

### Viewing Channel Statistics (AJAX)
1. User clicks "Statistics" on a channel row.
2. System gates on `tenant.channel-master.view`.
3. Returns JSON with: `total_notifications` (count of pivot records), `used_as_fallback_by` (count of channels referencing this as fallback), `daily_limit`, `monthly_limit`, `rate_limit`.

### Toggling Active Status (AJAX)
1. User toggles the active switch.
2. System gates on `tenant.channel-master.update`.
3. Validates `is_active` as required boolean.
4. Saves and returns JSON with new state.

### Soft Delete
1. User clicks delete on a channel.
2. System gates on `tenant.channel-master.delete`.
3. Checks if any active channel uses this as fallback. If yes, rejects with error.
4. Calls `$channel->delete()` (soft delete).
5. Activity log entry created.

### Restore
1. User goes to trash view, clicks restore.
2. System gates on `tenant.channel-master.restore`.
3. Calls `$channel->restore()`.
4. Redirects with success.

### Force Delete
1. User clicks permanent delete in trash view.
2. System gates on `tenant.channel-master.forceDelete`.
3. Checks if any channel (including soft-deleted) uses this as fallback. If yes, rejects.
4. Calls `$channel->forceDelete()` in try-catch. On failure, shows error.

---

## Example Scenario

**Use case**: School wants to send transactional SMS alerts (fee reminders) and has Twilio as the primary SMS provider with MSG91 as backup.

1. Admin creates Channel "Transactional SMS":
   - Code: `SMS`, Name: "Transactional SMS"
   - Channel Type: `TRANSACTIONAL`
   - Priority Order: `1`
   - Max Retry: `3`, Retry Delay: `5` minutes
   - Rate Limit: `100`/minute, Daily: `10000`, Monthly: `100000`
   - Cost Per Unit: `0.50` (₹0.50 per SMS)
   - Fallback: "WhatsApp Channel" (if SMS fails, send via WhatsApp)

2. Admin creates Channel "WhatsApp Channel":
   - Code: `WHATSAPP`, Name: "School WhatsApp"
   - ...different limits, cost per unit ₹1.00
   - Fallback: null (no further fallback)

3. If the SMS channel fails to deliver (Twilio down), the system automatically escalates to the WhatsApp channel for that notification.
4. The circular fallback check ensures WhatsApp cannot point back to SMS, preventing an infinite loop.
5. If the SMS channel's daily limit of 10,000 is hit, `NotificationService::isRateLimited()` skips dispatch via SMS and logs a warning. The fallback to WhatsApp still proceeds.

---

## Related Screens

| Screen | Relationship |
|--------|-------------|
| Providers | Each channel can have multiple providers (PRIMARY/SECONDARY/BACKUP) that implement the channel |
| Notifications | Each notification can select one or more channels for dispatch |
| Templates | Templates are scoped to a specific channel |
| User Preferences | Users configure per-channel preferences (enable/disable, quiet hours, opt-in) |
| Delivery Log | Each delivery log entry references the channel used |

---

## Requirements

| ID | Requirement Description | Priority | Status |
|----|------------------------|----------|--------|
| NTF-CHN-001 | System shall support five channel codes: EMAIL, SMS, WHATSAPP, IN_APP, PUSH | High | — |
| NTF-CHN-002 | System shall support three channel types: IMMEDIATE, BULK, TRANSACTIONAL | High | — |
| NTF-CHN-003 | System shall enforce tenant-unique channel codes | High | — |
| NTF-CHN-004 | System shall prevent a channel from being its own fallback | High | — |
| NTF-CHN-005 | System shall detect and reject circular fallback chains up to 5 hops depth | High | — |
| NTF-CHN-006 | System shall enforce configurable per-minute, daily, and monthly rate limits | High | — |
| NTF-CHN-007 | System shall track cost per message unit per channel | Medium | — |
| NTF-CHN-008 | System shall prevent deletion of a channel that is referenced as fallback by other channels | High | — |
| NTF-CHN-009 | System shall store channel code in uppercase | Medium | — |
| NTF-CHN-010 | System shall provide AJAX toggle for active/inactive status | Medium | — |
| NTF-CHN-011 | System shall expose channel usage statistics via AJAX | Low | — |
| NTF-CHN-012 | System shall support priority ordering (1–10) for channel selection during dispatch | High | — |
| NTF-CHN-013 | System shall soft-delete channels and provide trash view, restore, and force delete | High | — |
| NTF-CHN-014 | System shall enforce rate limit checks at dispatch time via `isRateLimited()` | High | — |
| NTF-CHN-015 | System shall support configurable retry policy (max_retry count and delay interval) | Medium | — |

---

## Who Can Access

| Action | Permission Gate | Typical Role |
|--------|----------------|-------------|
| View channels list | `tenant.channel-master.viewAny` | Admin, Manager |
| View single channel | `tenant.channel-master.view` | Admin, Manager |
| Create channel | `tenant.channel-master.create` | Admin |
| Update channel | `tenant.channel-master.update` | Admin |
| Delete (soft) channel | `tenant.channel-master.delete` | Admin |
| Restore channel | `tenant.channel-master.restore` | Admin |
| Force delete channel | `tenant.channel-master.forceDelete` | Super Admin |

---

## Logic Flow

```
ChannelMasterController
       ↓
  ┌────┼────┐
  │    │    │
index()  create()  store()
show()   edit()    update()
trashed()          destroy()
restore()          toggleStatus()
forceDelete()      statistics()
```

### Circular Fallback Validation Logic

```
validateChannel($request, $id):
  rules.fallback_channel_id = [
    nullable, integer, exists:ntf_channel_master,id,
    custom function($attribute, $value, $fail) use ($id):
      if $value == $id → fail("Channel cannot be its own fallback")
      visited = [$id, $value]
      next = $value
      depth = 0
      while depth < 5:
        next = DB::table('ntf_channel_master')
                 ->where('id', next)
                 ->value('fallback_channel_id')
        if !next → break (no loop, valid)
        if in_array(next, visited) → fail("Circular fallback chain detected at depth N")
        visited[] = next
        depth++
  ]
```

### Rate Limit Check Logic (NotificationService)

```
isRateLimited(ChannelMaster $channel):
  if rate_limit_per_minute set:
    recent_count = DeliveryLog::where('channel_id', channel.id)
                              ->where('created_at', >=, now()->subMinute())
                              ->count()
    if recent_count >= rate_limit_per_minute → return true
  if daily_limit set:
    today_count = DeliveryLog::where('channel_id', channel.id)
                             ->whereDate('created_at', today())
                             ->count()
    if today_count >= daily_limit → return true
  if monthly_limit set:
    month_count = DeliveryLog::where('channel_id', channel.id)
                             ->whereMonth('created_at', now()->month)
                             ->whereYear('created_at', now()->year)
                             ->count()
    if month_count >= monthly_limit → return true
  return false
```

---

## Validate Before Save

| Field | Validation Rule | Error Message |
|-------|----------------|---------------|
| `code` | required, string, max:20, unique per tenant | — |
| `name` | required, string, max:50 | — |
| `description` | nullable, string, max:255 | — |
| `channel_type` | required, in: keys of `ChannelMaster::CHANNEL_TYPES` | — |
| `priority_order` | nullable, integer, min:1, max:10 | — |
| `max_retry` | nullable, integer, min:0, max:10 | — |
| `retry_delay_minutes` | nullable, integer, min:0, max:1440 | — |
| `rate_limit_per_minute` | nullable, integer, min:0, max:10000 | — |
| `daily_limit` | nullable, integer, min:0 | — |
| `monthly_limit` | nullable, integer, min:0 | — |
| `cost_per_unit` | nullable, numeric, min:0 | — |
| `fallback_channel_id` | nullable, integer, exists:ntf_channel_master,id, not self, no circular chain | "Channel cannot be its own fallback." / "Circular fallback chain detected at depth N." |
| `is_active` | nullable, boolean | — |

---

## Error Handling and Validation Messages

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Validation failure | 302 Redirect | Form errors in Blade session |
| Channel not found | 404 | ModelNotFoundException → 404 |
| Delete with active fallback references | 302 Redirect | Error: "Cannot delete channel as it is used as fallback by other channels" |
| Force delete with fallback references | 302 Redirect | Same error message |
| Force delete exception | 302 Redirect | Error: "Operation failed: <message>" |
| Gate denied | 403 | Laravel authorization exception |
| Circular fallback detected | 302 Redirect | Validation error with specific depth message |
| Self-fallback detected | 302 Redirect | "Channel cannot be its own fallback." |

---

## Success Scenarios

1. **Create**: Redirect with `flash('success', 'Channel created successfully')`.
2. **Update**: Redirect with `flash('success', 'Channel updated successfully')`.
3. **Delete (soft)**: Redirect with `flash('success', 'Channel moved to trash')`.
4. **Restore**: Redirect with `flash('success', 'Channel restored successfully')`.
5. **Force Delete**: Redirect with `flash('success', 'Channel permanently deleted')`.
6. **Toggle Status**: JSON `{"success": true, "is_active": <bool>, "message": "Status updated successfully"}`.
7. **Statistics**: JSON `{"success": true, "data": {"total_notifications": N, "used_as_fallback_by": N, "daily_limit": N, "monthly_limit": N, "rate_limit": N}}`.

---

## Failure Scenarios

1. **Delete blocked by fallback dependency**: If Channel A is the fallback for Channels B and C, attempting to delete A is rejected with an informative error.
2. **Circular chain on create/update**: If the fallback chain loops back to the same channel or creates a cycle (e.g., A→B→C→A), validation fails at the depth where the cycle is detected.
3. **Rate limited at dispatch**: The notification is still sent but via alternative channels or fallback; the channel logs a warning but no error is shown to the user.
4. **Code uniqueness violation**: Duplicate channel code per tenant is rejected at validation time.

---

## Dependencies module and tables

### Primary Tables
- `ntf_channel_master` — Core channel definitions (self-referencing FK on `fallback_channel_id`)
- `ntf_notification_channels` — Pivot table linking notifications to channels
- `ntf_provider_master` — Provider endpoints that implement this channel (`channel_id` FK)
- `ntf_templates` — Templates scoped to this channel (`channel_id` FK)
- `ntf_delivery_logs` — Delivery audit records used for rate limit counting
- `ntf_user_preferences` — User's per-channel preference settings

### External Module Dependencies
- **SchoolSetup** — No direct dependency; user context is passed through the controller for tenant scoping
- **Prime** (`Modules\Prime\Models\Tenant`) — Tenant scope isolation for multi-tenant channel definitions
