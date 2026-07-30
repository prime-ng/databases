# Providers — Business Requirements

## What This Screen Does

The Providers screen manages the **third-party service endpoints** that actually deliver notifications through a channel. A provider is a concrete implementation of a channel — for example, Twilio is an SMS provider, AWS SES is an Email provider, Firebase Cloud Messaging is a Push provider, and Meta WhatsApp Business API is a WhatsApp provider. Each provider record stores the API connection details (endpoint URL, encrypted API key, encrypted API secret), sender identity (from-address), provider type for failover routing (PRIMARY / SECONDARY / BACKUP), and priority order within its channel.

---

## When This Screen Is Used

- The school IT administrator needs to **onboard a new SMS provider** (e.g., MSG91) after the current provider (Twilio) starts having reliability issues.
- An admin wants to **designate a backup email provider** (SendGrid) to activate if the primary (AWS SES) fails.
- API credentials need to be **updated** because a provider rotated their keys.
- A provider contract has ended and the provider needs to be **deactivated or removed**.
- An operator needs to **view which providers are configured** for each channel and their failover priority.
- A provider configuration has changed and the old record needs to be **soft-deleted** and a new one created.

---

## Default Data Load

When the Providers tab is active, the `index()` method on `ProviderMasterController` loads:

| Data | Source | Details |
|------|--------|---------|
| Providers list | `ProviderMaster` model with `channel` relation | 10 per page, latest first, paginated with query string |
| Channels dropdown | `ChannelMaster::active()->get()` | For filtering by channel |
| Provider types | `ProviderMaster::PROVIDER_TYPES` | PRIMARY, SECONDARY, BACKUP |
| Search filter | Request `search` | Matches against `provider_name` and `from_address` (LIKE) |
| Channel filter | Request `channel_id` | Exact match on `channel_id` |
| Provider type filter | Request `provider_type` | Exact match on `provider_type` |
| Status filter | Request `status` | Filters by `is_active` boolean |

The `create()` and `edit()` methods additionally load:

| Data | Source | Details |
|------|--------|---------|
| Channels | `ChannelMaster::active()->get()` | All active channels for the provider assignment |
| Provider types | `ProviderMaster::PROVIDER_TYPES` | PRIMARY, SECONDARY, BACKUP |

---

## Key Fields at a Glance

| Field | Type | Description |
|-------|------|-------------|
| `channel_id` | FK → `ntf_channel_master` | The channel this provider implements (e.g., SMS channel → Twilio provider) |
| `provider_name` | VARCHAR(50) | Display name (e.g., "Twilio India", "AWS SES Primary", "MSG91 Backup") |
| `provider_type` | ENUM | `PRIMARY` — default provider for the channel; `SECONDARY` — used when primary fails; `BACKUP` — used when all higher-priority providers fail |
| `api_endpoint` | VARCHAR(500) | Provider API base URL (nullable, validated as URL format) |
| `api_key_encrypted` | TEXT | API key stored with `SafeEncrypted` cast (encrypted at rest, transparently decrypted on read) |
| `api_secret_encrypted` | TEXT | API secret stored with `SafeEncrypted` cast |
| `from_address` | VARCHAR(255) | Sender identity: email from-address, SMS sender ID, WhatsApp phone number ID |
| `configuration` | JSON | Provider-specific configuration object (e.g., region, template IDs, webhook URL) |
| `priority` | TINYINT | 1 (highest) to 10 (lowest) — determines provider selection order within the channel; default `5` |
| `is_active` | BOOLEAN | Soft on/off switch; default `true` |

---

## Business Rules and Conditions

1. **Encrypted Credentials**: Both `api_key_encrypted` and `api_secret_encrypted` use the `SafeEncrypted` cast (`\App\Casts\SafeEncrypted::class`). Values are encrypted at rest in the database and automatically decrypted when accessed via Eloquent. The encryption is transparent to the application code.
2. **Provider-Channel Binding**: Each provider belongs to exactly one channel via the `channel_id` foreign key. The relationship is `ProviderMaster belongsTo ChannelMaster`.
3. **Provider Type Hierarchy**: The three provider types form a hierarchical failover: `PRIMARY` (tried first) → `SECONDARY` (tried if primary fails) → `BACKUP` (tried if all else fails). Within the same type, the `priority` field determines the order.
4. **Priority-Based Ordering**: The `scopeByPriority()` scope orders providers by `priority` ascending. Lower `priority` values are selected first for dispatch.
5. **Scope by Channel**: The `scopeByChannel($channelId)` scope returns all providers for a given channel, useful when a notification channel pivot needs to select the best provider.
6. **Active-Only Dispatch**: Only providers with `is_active = true` are considered during dispatch. The `scopeActive()` method provides this filter.
7. **Soft Deletes**: Providers follow the standard soft-delete pattern with `SoftDeletes`. The `trashed()`, `restore()`, `forceDelete()` methods are implemented.
8. **JSON Configuration**: The `configuration` column is cast to `array` in the model. This stores arbitrary provider-specific settings (e.g., AWS region, WhatsApp business account ID, Firebase server key, template registration IDs).
9. **No Cascade Delete on Channel**: If a channel is deleted (soft or force), providers referencing that channel are **not** automatically deleted or updated. The `channel_id` FK has no `ON DELETE CASCADE` — the provider becomes orphaned until manually cleaned up.
10. **Provider Selection at Dispatch**: When a notification is dispatched via a channel, the `NotificationService` uses the `provider_id` from the `ntf_notification_channels` pivot if specified. If not specified, it selects the active provider with the lowest `priority` and highest `provider_type` precedence (PRIMARY > SECONDARY > BACKUP).

---

## Workflow Steps

### Creating a Provider
1. User clicks "Add Provider" in the Providers tab.
2. System gates on `tenant.provider-master.create`.
3. Form loads: channels dropdown (active only), provider types dropdown.
4. User selects channel, enters provider name, selects type (PRIMARY/SECONDARY/BACKUP), optionally enters endpoint, API key, API secret, from-address, configuration JSON, and priority.
5. On submit, `ProviderMasterRequest` validates:
   - `channel_id`: required, exists in `ntf_channel_master`
   - `provider_name`: required, string, max:50
   - `provider_type`: required, in: PRIMARY/SECONDARY/BACKUP
   - `api_endpoint`: nullable, URL format, max:500
   - `api_key_encrypted`: nullable, string
   - `api_secret_encrypted`: nullable, string
   - `from_address`: nullable, string, max:255
   - `configuration`: nullable, array
   - `priority`: nullable, integer, min:1, max:10
   - `is_active`: nullable, boolean
6. System creates the provider record with the validated data.
7. Redirects to `notification.provider-master.index` with success.

### Editing a Provider
1. User clicks edit on a provider row.
2. System gates on `tenant.provider-master.update`.
3. Form pre-fills with current values.
4. Same validation as create (except authorization gate is `tenant.provider-master.update`).
5. Updates and redirects.

### Viewing a Provider
1. User clicks view on a provider row.
2. System gates on `tenant.provider-master.view`.
3. Loads provider with `channel` relation.
4. Displayed in a read-only detail view. API credentials are shown in their decrypted form (the `SafeEncrypted` cast handles transparent decryption).

### Toggling Active Status (AJAX)
1. User toggles the active switch.
2. System gates on `tenant.provider-master.update`.
3. Validates `is_active` as required boolean.
4. Saves and returns JSON with new state.

### Soft Delete
1. User clicks delete on a provider.
2. System gates on `tenant.provider-master.delete`.
3. Calls `$provider->delete()` (soft delete).
4. Redirects to index.

### Restore
1. User goes to trash view, clicks restore.
2. System gates on `tenant.provider-master.restore`.
3. Calls `$provider->restore()`.
4. Redirects to trash view with success.

### Force Delete
1. User clicks permanent delete in trash view.
2. System gates on `tenant.provider-master.forceDelete`.
3. Calls `$provider->forceDelete()`.
4. Redirects with success.

---

## Example Scenario

**Use case**: School wants to configure Email notifications via AWS SES (primary) with SendGrid as backup.

1. Admin creates Channel "School Email" (type = TRANSACTIONAL) on the Channels tab.
2. Admin goes to Providers tab → clicks "Add Provider".
3. Creates Provider "AWS SES Primary":
   - Channel: "School Email"
   - Provider Name: "AWS SES Primary"
   - Provider Type: `PRIMARY`
   - Priority: `1`
   - API Endpoint: `https://email.us-east-1.amazonaws.com`
   - API Key: `AKIA...` (encrypted on save)
   - API Secret: `wJalr...` (encrypted on save)
   - From Address: `noreply@school.edu.in`
4. Creates Provider "SendGrid Backup":
   - Channel: "School Email"
   - Provider Name: "SendGrid Backup"
   - Provider Type: `SECONDARY`
   - Priority: `2`
   - API Endpoint: `https://api.sendgrid.com/v3/mail/send`
   - API Key: `SG....` (encrypted on save)
   - From Address: `noreply@school.edu.in`
5. When a notification is dispatched via the "School Email" channel:
   - System tries AWS SES first (PRIMARY, priority 1).
   - If AWS SES returns an error or times out, the system falls back to SendGrid (SECONDARY, priority 2).
6. If the school adds a third provider "Mailgun Backup" with type `BACKUP` and priority `3`, it will be tried only if both PRIMARY and SECONDARY fail.

---

## Related Screens

| Screen | Relationship |
|--------|-------------|
| Channels | Each provider belongs to a channel; channels aggregate providers |
| Notifications | The `ntf_notification_channels` pivot can select a specific provider for dispatch |
| Delivery Log | Each delivery log entry records which provider was used for the attempt |
| Templates | Templates can specify provider-specific configuration for rendering |

---

## Requirements

| ID | Requirement Description | Priority | Status |
|----|------------------------|----------|--------|
| NTF-PRV-001 | System shall support three provider types: PRIMARY, SECONDARY, BACKUP | High | — |
| NTF-PRV-002 | System shall enforce that each provider is associated with exactly one channel | High | — |
| NTF-PRV-003 | System shall encrypt API keys and secrets at rest using `SafeEncrypted` casting | High | — |
| NTF-PRV-004 | System shall support priority-based ordering (1–10) for provider selection within a channel | High | — |
| NTF-PRV-005 | System shall validate `api_endpoint` as a URL format when provided | Medium | — |
| NTF-PRV-006 | System shall store provider-specific configuration as JSON | Medium | — |
| NTF-PRV-007 | System shall provide AJAX toggle for active/inactive status | Medium | — |
| NTF-PRV-008 | System shall soft-delete providers and provide trash view, restore, and force delete | High | — |
| NTF-PRV-009 | System shall filter providers by channel, type, and active status in the listing | Medium | — |
| NTF-PRV-010 | System shall allow searching by provider name and from-address | Medium | — |
| NTF-PRV-011 | System shall select the highest-priority active provider during dispatch, falling back through the type hierarchy | High | — |
| NTF-PRV-012 | System shall support scoping by channel (`scopeByChannel`) for channel-specific queries | Low | — |

---

## Who Can Access

| Action | Permission Gate | Typical Role |
|--------|----------------|-------------|
| View providers list | `tenant.provider-master.viewAny` | Admin, Manager |
| View single provider | `tenant.provider-master.view` | Admin, Manager |
| Create provider | `tenant.provider-master.create` | Admin |
| Update provider | `tenant.provider-master.update` | Admin |
| Delete (soft) provider | `tenant.provider-master.delete` | Admin |
| Restore provider | `tenant.provider-master.restore` | Admin |
| Force delete provider | `tenant.provider-master.forceDelete` | Super Admin |

---

## Logic Flow

```
ProviderMasterController
       ↓
  ┌────┼────┐
  │    │    │
index()   create()   store()
show()    edit()     update()
trashed()            destroy()
restore()            toggleStatus()
forceDelete()
```

### Provider Selection at Dispatch Time

```
NotificationService::process(Notification $notification):
  for each $notificationChannel in $notification->channels:
    if !$notificationChannel->is_active → skip
    $channel = $notificationChannel->channel
    if !$channel || !$channel->is_active → skip
    if isRateLimited($channel) → log warning, skip

    $provider = $notificationChannel->provider
      ?? ProviderMaster::active()
           ->byChannel($channel->id)
           ->byPriority()
           ->first()   // picks PRIMARY with lowest priority number

    dispatchToChannel($channel->code, ..., $provider?->id, ...)
```

### Provider Type Hierarchy (conceptual)

```
Provider Selection Order:
  1. PRIMARY providers (ordered by priority ascending)
  2. SECONDARY providers (if all PRIMARY fail)
  3. BACKUP providers (if all PRIMARY and SECONDARY fail)
```

---

## Validate Before Save

All validations are defined in `Modules\Notification\Http\Requests\ProviderMasterRequest`:

| Field | Validation Rule | Error Message |
|-------|----------------|---------------|
| `channel_id` | required, integer, exists:ntf_channel_master,id | — |
| `provider_name` | required, string, max:50 | — |
| `provider_type` | required, in: PRIMARY/SECONDARY/BACKUP | — |
| `api_endpoint` | nullable, string, max:500, url | — |
| `api_key_encrypted` | nullable, string | — |
| `api_secret_encrypted` | nullable, string | — |
| `from_address` | nullable, string, max:255 | — |
| `configuration` | nullable, array | — |
| `priority` | nullable, integer, min:1, max:10 | — |
| `is_active` | nullable, boolean | — |

---

## Error Handling and Validation Messages

| Scenario | HTTP Code | Response |
|----------|-----------|----------|
| Validation failure | 302 Redirect | Form errors in Blade session |
| Provider not found | 404 | `ModelNotFoundException` → 404 |
| Gate denied | 403 | Laravel authorization exception |
| Provider type invalid | 302 Redirect | Validation: "The selected provider type is invalid" |
| API endpoint not a valid URL | 302 Redirect | Validation: "The api endpoint field must be a valid URL" |

---

## Success Scenarios

1. **Create**: Redirect with `flash('success', 'Provider created successfully')`.
2. **Update**: Redirect with `flash('success', 'Provider updated successfully')`.
3. **Delete (soft)**: Redirect with `flash('success', 'Provider moved to trash')`.
4. **Restore**: Redirect with `flash('success', 'Provider restored successfully')`.
5. **Force Delete**: Redirect with `flash('success', 'Provider permanently deleted')`.
6. **Toggle Status**: JSON `{"success": true, "is_active": <bool>, "message": "Status updated successfully"}`.

---

## Failure Scenarios

1. **Deleted channel with active providers**: If a channel is soft-deleted, its providers remain but are orphaned — they will not be selected for dispatch because the parent channel filter will exclude them.
2. **Encryption key rotation**: If the application encryption key (`APP_KEY`) is changed, existing encrypted credentials become unreadable. The `SafeEncrypted` cast will fail to decrypt them, causing runtime errors during dispatch.
3. **All providers inactive**: If all providers for a channel are inactive, the channel becomes effectively unusable. Notifications scheduled via this channel will fail at dispatch with no provider to route through.

---

## Dependencies module and tables

### Primary Tables
- `ntf_provider_master` — Core provider records
- `ntf_channel_master` — Channel definitions (`channel_id` FK)
- `ntf_notification_channels` — Pivot that can specify a provider for a notification-channel pair
- `ntf_delivery_logs` — Delivery audit records that reference which provider was used
- `ntf_delivery_queue` — Queue items that reference the selected provider

### External Module Dependencies
- **Prime** (`\App\Casts\SafeEncrypted`) — Encryption cast for credential columns; depends on the application's `APP_KEY` cipher config
- **SchoolSetup** — No direct dependency; providers are infrastructure-level records scoped to tenant
- **Prime** (`Modules\Prime\Models\Tenant`) — Tenant scope isolation for multi-tenant provider definitions
