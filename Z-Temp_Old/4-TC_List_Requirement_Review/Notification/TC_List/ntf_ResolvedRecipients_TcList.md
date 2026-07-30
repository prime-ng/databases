# ntf_ResolvedRecipients_TcList

## Module: Notification → Notification Management → Resolved Recipients

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Resolved Recipients (read-only / derived — minimal TcList) |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /resolved-recipients` (index), `POST /resolved-recipients` (store), `GET /resolved-recipients/create` (create), `GET /resolved-recipients/{resolved_recipient}` (show), `GET /resolved-recipients/{resolved_recipient}/edit` (edit), `PUT /resolved-recipients/{resolved_recipient}` (update), `DELETE /resolved-recipients/{resolved_recipient}` (destroy), `POST /resolved-recipients/{resolved_recipient}/toggle-status` (toggleStatus), `POST /resolved-recipients/{resolved_recipient}/toggle-enabled` (toggleEnabled), `POST /resolved-recipients/{id}/mark-processed` (markAsProcessed), `POST /resolved-recipients/bulk/process` (bulkProcess), `GET /resolved-recipients/batch/{batchId}` (getByBatch), `GET /resolved-recipients/trash/view` (trashed), `GET /resolved-recipients/{id}/restore` (restore), `DELETE /resolved-recipients/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\ResolvedRecipientController` |
| Model(s) | `Modules\Notification\Models\ResolvedRecipient` (table: `ntf_resolved_recipients`) |
| Validation | `Modules\Notification\Http\Requests\ResolvedRecipientRequest` |
| Permissions | `tenant.notification.resolved-recipient.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.process` |
| Pagination | 15 records per page (`ResolvedRecipientController@index` line 281 — `$recipients = $recipientQuery->latest()->paginate(15)`) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` also sets `is_active=false` before `delete()` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Status Toggled, Processed |
| Notes | Read-only / derived — normally created by the notification pipeline. CRUD exists for admin override but processed recipients cannot be edited or deleted. |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification.resolved-recipient.viewAny` for index, `.create` for store, `.view` for show, `.update` for update/toggleStatus/toggleEnabled, `.delete` for destroy, `.restore` for restore/trashed, `.forceDelete` for forceDelete, `.process` for markAsProcessed/bulkProcess
- Seed data required: At least one `ntf_notifications`, `ntf_channel_master`, `ntf_templates`, `ntf_notification_targets`, `sys_users` record
- Test user must have `tenant.notification.resolved-recipient.*` permissions
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ResolvedRecipientController@index()`, the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Resolved Recipients | `index()` lines 221-281 | `ResolvedRecipient::with(['notification','channel','template','notificationTarget','user','userPreference','device'])` | search (user.name/email, recipient_address, batch_id), notification_id, channel_id, user_id, batch_id, is_processed, priority_min/max, date_from/to, status | 15/page |
| Templates | Side-loaded | `NotificationTemplate::with(['channel','creator','tenant'])` | search, channel_id, approval_status, language_code, status | 15/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','tenant','creator','approver','template'])->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |
| Targets | Side-loaded | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search, notification_id, target_type_id, has_group, status | 10/page |
| User Preferences | Side-loaded | `UserPreference::with(['user','channel','priorityThreshold'])` | search, user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status | 10/page |

---

## 4. Test Data Strategy

- **Derived data**: Normally created by the pipeline, but CRUD available for admin overrides
- **Processed guard**: `is_processed=true` recipients cannot be edited (edit/update) or deleted (destroy) — returns error
- **Batch operations**: Test `batch_id` grouping and `getByBatch` retrieval
- **Priority range**: priority ranges 1-10, with min/max filter support
- **Date range**: Filter by `created_at` using `date_from` and `date_to`
- **Pre-test cleanup**: Delete created recipients by batch_id before/after tests
- **Pagination**: Test 15-record pagination

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_resolved_recipients`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | notification_id | BIGINT UNSIGNED | FK → ntf_notifications.id CASCADE, NOT NULL |
| BC-DB-03 | channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NOT NULL |
| BC-DB-04 | template_id | BIGINT UNSIGNED | FK → ntf_templates.id, NOT NULL |
| BC-DB-05 | notification_target_id | BIGINT UNSIGNED | FK → ntf_notification_targets.id, NOT NULL |
| BC-DB-06 | user_preference_id | BIGINT UNSIGNED | FK → ntf_user_preferences.id, NULLABLE |
| BC-DB-07 | resolved_user_id | BIGINT UNSIGNED | FK → sys_users.id, NOT NULL |
| BC-DB-08 | device_id | BIGINT UNSIGNED | FK → ntf_user_devices.id, NULLABLE |
| BC-DB-09 | recipient_address | VARCHAR(255) | NULLABLE |
| BC-DB-10 | personalized_subject | VARCHAR(500) | NULLABLE |
| BC-DB-11 | personalized_body | TEXT | NULLABLE |
| BC-DB-12 | personalization_data | JSON | NULLABLE |
| BC-DB-13 | priority | TINYINT | NOT NULL DEFAULT 5, MIN 1, MAX 10 |
| BC-DB-14 | batch_id | VARCHAR(36) | NULLABLE |
| BC-DB-15 | batch_sequence | INT | NULLABLE |
| BC-DB-16 | is_processed | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-17 | processed_at | DATETIME | NULLABLE |
| BC-DB-18 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-19 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-20 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-21 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `ResolvedRecipientRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | notification_id | required, integer, exists:ntf_notifications,id | "The notification field is required." |
| BC-VAL-02 | channel_id | required, integer, exists:ntf_channel_master,id | "The channel field is required." |
| BC-VAL-03 | template_id | required, integer, exists:ntf_templates,id | "The template field is required." |
| BC-VAL-04 | notification_target_id | required, integer, exists:ntf_notification_targets,id | "The notification target field is required." |
| BC-VAL-05 | user_preference_id | nullable, integer, exists:ntf_user_preferences,id | — |
| BC-VAL-06 | resolved_user_id | required, integer, exists:sys_users,id | "The user field is required." |
| BC-VAL-07 | device_id | nullable, integer, exists:ntf_user_devices,id | — |
| BC-VAL-08 | recipient_address | nullable, string, max:255 | — |
| BC-VAL-09 | personalized_subject | nullable, string, max:500 | — |
| BC-VAL-10 | personalized_body | nullable, string | — |
| BC-VAL-11 | personalization_data | nullable, array | — |
| BC-VAL-12 | priority | nullable, integer, min:1, max:10 | "Priority must be at least 1." / "Priority must not exceed 10." |
| BC-VAL-13 | batch_id | nullable, string, max:36 | — |
| BC-VAL-14 | batch_sequence | nullable, integer | — |
| BC-VAL-15 | is_processed | nullable, boolean | — |
| BC-VAL-16 | processed_at | nullable, date | — |
| BC-VAL-17 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification.resolved-recipient.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.notification.resolved-recipient.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.notification.resolved-recipient.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification.resolved-recipient.update` | edit, update, toggleStatus, toggleEnabled — without → 403 |
| BC-AUTH-05 | `tenant.notification.resolved-recipient.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.notification.resolved-recipient.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.notification.resolved-recipient.forceDelete` | forceDelete — without → 403 |
| BC-AUTH-08 | `tenant.notification.resolved-recipient.process` | markAsProcessed, bulkProcess — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with resolved recipients tab | Paginated grid at 15 records/page, ordered by latest, with all 7 relationships loaded |
| BC-BIZ-02 | Search by user name/email | Filters where related user name or email contains search term |
| BC-BIZ-03 | Search by recipient_address | Filters where recipient_address contains search term |
| BC-BIZ-04 | Search by batch_id | Filters where batch_id contains search term |
| BC-BIZ-05 | Filter by notification_id | Exact match on notification_id |
| BC-BIZ-06 | Filter by channel_id | Exact match on channel_id |
| BC-BIZ-07 | Filter by user_id (resolved_user_id) | Exact match on resolved_user_id |
| BC-BIZ-08 | Filter by batch_id (exact) | Exact match on batch_id |
| BC-BIZ-09 | Filter by is_processed | Filters by is_processed (0 or 1) |
| BC-BIZ-10 | Filter by priority range | priority_min (>=) and priority_max (<=) |
| BC-BIZ-11 | Filter by date range | date_from (>= created_at) and date_to (<= created_at) |
| BC-BIZ-12 | Filter by status | Filters by is_active |
| BC-BIZ-13 | Create recipient (admin override) | Recipient created with all FK relationships, notification.total_recipients incremented |
| BC-BIZ-14 | Create with auto-generated batch_id | batch_id generated as UUID when not provided |
| BC-BIZ-15 | Edit unprocessed recipient | Edit form loads, update succeeds |
| BC-BIZ-16 | Edit processed recipient blocked | Redirect with error "Processed recipients cannot be edited." |
| BC-BIZ-17 | Update unprocessed recipient | Update succeeds, activity logged |
| BC-BIZ-18 | Update processed recipient blocked | Redirect with error "Processed recipients cannot be updated." |
| BC-BIZ-19 | markAsProcessed on unprocessed recipient | is_processed=true, processed_at=now, notification.sent_count incremented |
| BC-BIZ-20 | markAsProcessed on already processed recipient | Error: "Recipient already processed." (400) |
| BC-BIZ-21 | bulkProcess multiple recipients | All unprocessed recipients in list marked as processed |
| BC-BIZ-22 | getByBatch returns recipients in batch | Paginated list of recipients for given batch_id |
| BC-BIZ-23 | Toggle status active→inactive | AJAX toggles is_active, activity logged |
| BC-BIZ-24 | Soft delete unprocessed recipient | is_active=false + soft delete, notification.total_recipients decremented |
| BC-BIZ-25 | Soft delete processed recipient blocked | Error: "Processed recipients cannot be deleted." (400) |
| BC-BIZ-26 | Restore recipient | Restored, notification.total_recipients incremented |
| BC-BIZ-27 | Force delete recipient | Related logs deleted first, then force delete |
| BC-BIZ-28 | Empty state | Grid shows empty state |
| BC-BIZ-29 | Pagination — 15 per page | Page 1 shows up to 15 |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | notification_id | ntf_notifications (id) | CASCADE |
| BC-REF-02 | channel_id | ntf_channel_master (id) | CASCADE |
| BC-REF-03 | template_id | ntf_templates (id) | CASCADE |
| BC-REF-04 | notification_target_id | ntf_notification_targets (id) | CASCADE |
| BC-REF-05 | user_preference_id | ntf_user_preferences (id) | SET NULL |
| BC-REF-06 | resolved_user_id | sys_users (id) | CASCADE |
| BC-REF-07 | device_id | ntf_user_devices (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases (Display & Filter)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Resolved Recipients page loads with UI elements | Page loads with search bar, filters, grid, pagination (15/page) | — | — | ⬜ |
| TC-P02 | Search by user name/email | Grid filtered to matching user | — | — | ⬜ |
| TC-P03 | Search by recipient_address | Grid filtered to matching address | — | — | ⬜ |
| TC-P04 | Search by batch_id | Grid filtered to matching batch | — | — | ⬜ |
| TC-P05 | Filter by notification_id | Grid shows recipients for selected notification | — | — | ⬜ |
| TC-P06 | Filter by channel_id | Grid shows recipients for selected channel | — | — | ⬜ |
| TC-P07 | Filter by user_id (resolved_user_id) | Grid shows recipients for selected user | — | — | ⬜ |
| TC-P08 | Filter by is_processed | Grid shows processed or unprocessed only | — | — | ⬜ |
| TC-P09 | Filter by priority range (min=3, max=7) | Grid shows recipients with priority 3-7 | — | — | ⬜ |
| TC-P10 | Filter by date range | Grid shows recipients within date range | — | — | ⬜ |
| TC-P11 | Filter by active status | Grid shows only active recipients | — | — | ⬜ |
| TC-P12 | Show recipient details | Show page renders with all 7 relationships | — | — | ⬜ |
| TC-P13 | View trashed recipients | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P14 | Pagination — first page 15 records | Page 1 shows up to 15 | — | — | ⬜ |
| TC-P15 | Pagination — second page | Page 2 shows records 16+ | — | — | ⬜ |
| TC-P16 | Empty state — no recipients | Grid shows empty state | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Edit processed recipient | Redirect: "Processed recipients cannot be edited." | — | — | ⬜ |
| TC-N02 | Update processed recipient | Redirect: "Processed recipients cannot be updated." | — | — | ⬜ |
| TC-N03 | Delete processed recipient | 400 error: "Processed recipients cannot be deleted." | — | — | ⬜ |
| TC-N04 | Required — missing notification_id | Validation error | — | — | ⬜ |
| TC-N05 | Required — missing channel_id | Validation error | — | — | ⬜ |
| TC-N06 | Required — missing template_id | Validation error | — | — | ⬜ |
| TC-N07 | Required — missing resolved_user_id | Validation error | — | — | ⬜ |
| TC-N08 | Unauthorized access | 403 Forbidden | — | — | ⬜ |
| TC-N09 | View non-existent | 404 Not Found | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Delete notification cascades to recipients | Recipients deleted when parent notification deleted | — | — | ⬜ |
| TC-D02 | markAsProcessed increments notification.sent_count | sent_count increases after processing | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | Processed guard in edit() and update() | `if ($recipient->is_processed)` check before editing | — | — | ◌ |
| TC-CR02 | Processed guard in destroy() | `if ($recipient->is_processed)` returns 400 JSON | — | — | ◌ |
| TC-CR03 | markAsProcessed sets timestamp | `is_processed=true, processed_at=now()` | — | — | ◌ |
| TC-CR04 | bulkProcess validates IDs array | `required|array`, `ids.*` integer exists | — | — | ◌ |
| TC-CR05 | forceDelete deletes related logs first | `$recipient->logs()->delete()` before forceDelete | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Page loads with UI elements
1. Login as admin user
2. Navigate to `GET /resolved-recipients`
3. Verify page loads (200 OK) with search bar, filters, grid, pagination (15/page)

#### TC-P02 through TC-P11: Filter tests
1. Ensure test recipient records exist
2. Apply each filter and verify grid data

#### TC-P12: Show recipient details
1. Click View on a recipient
2. Verify all relationships displayed: notification (subject), channel (name), template (name), notificationTarget, user, userPreference, device

#### TC-P13 through TC-P16: Trash, pagination, empty state
1. Standard tests as per other features

### 7.2 Negative TC Steps

#### TC-N01: Edit processed recipient
1. Create a recipient with is_processed=true
2. Navigate to edit URL
3. Verify redirect to index with error "Processed recipients cannot be edited."

#### TC-N02: Update processed recipient
1. PUT to processed recipient with changes
2. Verify redirect with error "Processed recipients cannot be updated."

#### TC-N03: Delete processed recipient
1. DELETE a processed recipient
2. Verify 400 JSON: "Processed recipients cannot be deleted."

#### TC-N04 through TC-N09: Validation, auth, 404
1. Standard validation, authorization, and 404 tests

### 7.3 Dependency TC Steps

#### TC-D01: Delete notification cascades
1. Create notification with recipient
2. Force delete notification
3. Verify recipient also deleted (CASCADE)

#### TC-D02: markAsProcessed increments sent_count
1. Create notification with recipient
2. Call markAsProcessed
3. Verify notification.sent_count incremented by 1

### 7.4 Code Review TC Steps

#### TC-CR01: Processed guard in edit/update
1. Review edit() lines 401-404: `if ($recipient->is_processed) { return redirect()->with('error', '...'); }`
2. Review update() lines 433-436: Same guard

#### TC-CR02: Processed guard in destroy
1. Review destroy() lines 477-481
2. Verify JSON 400 error response for processed recipients

#### TC-CR03: markAsProcessed method
1. Review `ResolvedRecipient::markAsProcessed()` (model lines 147-153)
2. Verify `is_processed = true`, `processed_at = now()`

#### TC-CR04: bulkProcess validation
1. Review bulkProcess() lines 639-661
2. Verify `$request->validate(['ids' => 'required|array', 'ids.*' => 'integer|exists:ntf_resolved_recipients,id'])`

#### TC-CR05: forceDelete cascade
1. Review forceDelete() lines 538-565
2. Verify `$recipient->logs()->delete()` called before `$recipient->forceDelete()`
