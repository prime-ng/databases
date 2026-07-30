# ntf_Notifications_TcList

## Module: Notification → Notification Management → Notifications

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Notifications |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /notifications` (index), `POST /notifications` (store), `GET /notifications/{notification}` (show), `GET /notifications/{notification}/edit` (edit), `PUT /notifications/{notification}` (update), `DELETE /notifications/{notification}` (destroy), `POST /notifications/{id}/update-status` (updateStatus), `POST /notifications/{id}/process` (process), `GET /notifications/trash/view` (trashed), `GET /notifications/{id}/restore` (restore), `DELETE /notifications/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\NotificationManageController` |
| Model(s) | `Modules\Notification\Models\Notification` (table: `ntf_notifications`) |
| Validation (Create/Update) | `Modules\Notification\Http\Requests\NotificationRequest` |
| Permissions | `tenant.notification.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.process` |
| Pagination | 10 records per page (`NotificationManageController@index` line 63) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` sets `is_active=false` before `delete()` |
| Activity Log | Events: Created, Updated, Trashed, Restored, Deleted, Status Updated, Processing, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification.viewAny` for index, `tenant.notification.create` for store, `tenant.notification.update` for update/toggleStatus/updateStatus, `tenant.notification.delete` for destroy, `tenant.notification.restore` for restore/trashed, `tenant.notification.forceDelete` for forceDelete, `tenant.notification.process` for process
- Seed data required: At least one channel in `ntf_channel_master`, sys_dropdown_table entries for priority/confidentiality/status
- Test user must have `tenant.notification.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For process test: Template with `approval_status=APPROVED` must exist

---

## 3. Default Data Load

When the page loads via `NotificationManageController@index()` / `NotificationManageController@tabIndex()`, the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Notifications | `loadNotifications()` | `Notification::with(['priority','confidentialityLevel','notificationStatus','tenant','creator','approver','template'])->latest()` | search, channel_id, approval_status, language_code, status | 10/page |
| Templates | `loadTemplates()` | `NotificationTemplate::with('channel')->latest()` | search, status | 10/page |
| Channels | `loadChannels()` | `ChannelMaster::query()` | search, status | 10/page |
| Providers | `loadProviders()` | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | `loadTargetGroups()` | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |
| Targets | `loadTargets()` | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search, notification_id, target_type_id, has_group, status | 10/page |
| User Preferences | `loadPreferences()` | `UserPreference::with(['user','channel','priorityThreshold'])` | search, user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status | 10/page |
| Delivery Log | `loadDeliveryLog()` | `NotificationDeliveryLog::with(['notification','channel','user','status'])` | search, notification_id, channel_id, delivery_status_id, date_from, date_to | 10/page |

---

## 4. Test Data Strategy

- **UUID uniqueness**: notification_uuid must be unique — auto-generated via `Uuid::uuid4()->toString()` on create
- **Status dropdown dependency**: notification_status_id references `sys_dropdown_table` with key `ntf_notifications.notification_status_id.notification_status` — pre-seed required test statuses
- **Priority & Confidentiality**: priority_id and confidentiality_level_id also reference `sys_dropdown_table` — pre-seed required values
- **Template dependency**: template_id references `ntf_templates` — create a test template with APPROVED status for process tests
- **Schedule types**: Test all schedule_type values (IMMEDIATE, SCHEDULED, RECURRING, TRIGGERED)
- **Recurring tests**: Use recurring_pattern values NONE, HOURLY, DAILY, WEEKLY, MONTHLY, YEARLY, CUSTOM
- **Notification types**: Test all notification_type values (TRANSACTIONAL, PROMOTIONAL, ALERT, REMINDER, DIGEST)
- **Pre-test cleanup**: Delete created notifications by notification_uuid before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_notifications`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id |
| BC-DB-03 | notification_uuid | VARCHAR(36) | UQ, NOT NULL |
| BC-DB-04 | source_module | VARCHAR(50) | NOT NULL |
| BC-DB-05 | source_record_id | BIGINT | NULLABLE |
| BC-DB-06 | notification_event | VARCHAR(50) | NOT NULL |
| BC-DB-07 | notification_type | ENUM('TRANSACTIONAL','PROMOTIONAL','ALERT','REMINDER','DIGEST') | NOT NULL |
| BC-DB-08 | title | VARCHAR(255) | NOT NULL |
| BC-DB-09 | description | VARCHAR(512) | NULLABLE |
| BC-DB-10 | template_id | BIGINT UNSIGNED | FK → ntf_templates.id, NULLABLE |
| BC-DB-11 | priority_id | BIGINT UNSIGNED | FK → sys_dropdown_table.id, NOT NULL |
| BC-DB-12 | confidentiality_level_id | BIGINT UNSIGNED | FK → sys_dropdown_table.id, NOT NULL |
| BC-DB-13 | schedule_type | ENUM('IMMEDIATE','SCHEDULED','RECURRING','TRIGGERED') | NOT NULL |
| BC-DB-14 | scheduled_at | DATETIME | NULLABLE |
| BC-DB-15 | schedule_timezone | VARCHAR(50) | NULLABLE, DEFAULT 'UTC' |
| BC-DB-16 | recurring_pattern | ENUM('NONE','HOURLY','DAILY','WEEKLY','MONTHLY','YEARLY','CUSTOM') | NULLABLE |
| BC-DB-17 | recurring_expression | VARCHAR(100) | NULLABLE |
| BC-DB-18 | recurring_end_at | DATETIME | NULLABLE, AFTER scheduled_at |
| BC-DB-19 | recurring_end_count | INT UNSIGNED | NULLABLE, MIN 1 |
| BC-DB-20 | recurring_executed_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-21 | expires_at | DATETIME | NULLABLE, AFTER scheduled_at |
| BC-DB-22 | total_recipients | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-23 | sent_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-24 | failed_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-25 | delivered_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-26 | read_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-27 | click_count | INT UNSIGNED | NOT NULL DEFAULT 0 |
| BC-DB-28 | estimated_cost | DECIMAL(10,4) | NOT NULL DEFAULT 0 |
| BC-DB-29 | actual_cost | DECIMAL(10,4) | NOT NULL DEFAULT 0 |
| BC-DB-30 | notification_status_id | BIGINT UNSIGNED | FK → sys_dropdown_table.id, NOT NULL |
| BC-DB-31 | is_manual | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-32 | created_by | BIGINT UNSIGNED | FK → users.id, NOT NULL |
| BC-DB-33 | approved_by | BIGINT UNSIGNED | FK → users.id, NULLABLE |
| BC-DB-34 | approved_at | DATETIME | NULLABLE |
| BC-DB-35 | processed_at | DATETIME | NULLABLE |
| BC-DB-36 | completed_at | DATETIME | NULLABLE |
| BC-DB-37 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-38 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-39 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-40 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `NotificationRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | tenant_id | required, integer | The tenant field is required. |
| BC-VAL-02 | notification_uuid | nullable, string, max:36, unique:ntf_notifications (ignore current) | — |
| BC-VAL-03 | source_module | required, string, max:50 | — |
| BC-VAL-04 | source_record_id | nullable, integer | — |
| BC-VAL-05 | notification_event | required, string, max:50 | — |
| BC-VAL-06 | notification_type | required, in:TRANSACTIONAL,PROMOTIONAL,ALERT,REMINDER,DIGEST | The selected notification type is invalid. |
| BC-VAL-07 | title | required, string, max:255 | — |
| BC-VAL-08 | description | nullable, string, max:512 | — |
| BC-VAL-09 | template_id | nullable, integer, exists:ntf_templates,id | — |
| BC-VAL-10 | priority_id | required, integer, exists:sys_dropdown_table,id | The priority field is required. |
| BC-VAL-11 | confidentiality_level_id | required, integer, exists:sys_dropdown_table,id | The confidentiality level field is required. |
| BC-VAL-12 | schedule_type | required, in:IMMEDIATE,SCHEDULED,RECURRING,TRIGGERED | The selected schedule type is invalid. |
| BC-VAL-13 | scheduled_at | nullable, required_if:schedule_type,SCHEDULED,RECURRING, date | The scheduled at field is required when schedule type is scheduled or recurring. |
| BC-VAL-14 | schedule_timezone | nullable, string, max:50 | — |
| BC-VAL-15 | recurring_pattern | nullable, required_if:schedule_type,RECURRING, in:NONE,HOURLY,DAILY,WEEKLY,MONTHLY,YEARLY,CUSTOM | The recurring pattern field is required when schedule type is recurring. |
| BC-VAL-16 | recurring_expression | nullable, required_if:recurring_pattern,CUSTOM, string, max:100 | The recurring expression field is required when recurring pattern is custom. |
| BC-VAL-17 | recurring_end_at | nullable, date, after:scheduled_at | The recurring end date must be after the scheduled date. |
| BC-VAL-18 | recurring_end_count | nullable, integer, min:1 | — |
| BC-VAL-19 | expires_at | nullable, date, after:scheduled_at | The expiry date must be after the scheduled date. |
| BC-VAL-20 | notification_status_id | required, integer, exists:sys_dropdown_table,id | The notification status field is required. |
| BC-VAL-21 | is_manual | nullable, boolean | — |
| BC-VAL-22 | is_active | nullable, boolean | — |
| BC-VAL-23 | channels | nullable, array | — |
| BC-VAL-24 | channels.*.channel_id | required, integer, exists:ntf_channel_master,id | The channel field is required for each selected channel. |
| BC-VAL-25 | channels.*.provider_id | nullable, integer, exists:ntf_provider_master,id | — |
| BC-VAL-26 | channels.*.status_id | required, integer, exists:sys_dropdown_table,id | The channel status field is required. |
| BC-VAL-27 | channels.*.scheduled_at | nullable, date | — |
| BC-VAL-28 | channels.*.max_retry | nullable, integer, min:0 | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification.viewAny` | index, tabIndex — without → 403 |
| BC-AUTH-02 | `tenant.notification.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.notification.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification.update` | edit, update, toggleStatus, updateStatus — without → 403 |
| BC-AUTH-05 | `tenant.notification.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.notification.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.notification.forceDelete` | forceDelete — without → 403 |
| BC-AUTH-08 | `tenant.notification.process` | process — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with tab-index | All 8 sub-lists (notifications, templates, channels, providers, groups, targets, preferences, delivery log) loaded with pagination |
| BC-BIZ-02 | Create with schedule_type=IMMEDIATE | Notification created without scheduled_at requirement |
| BC-BIZ-03 | Create with schedule_type=SCHEDULED | scheduled_at is required |
| BC-BIZ-04 | Create with schedule_type=RECURRING | scheduled_at + recurring_pattern required |
| BC-BIZ-05 | Create with notification_type=PROMOTIONAL | Auto-set to PENDING status if not approved |
| BC-BIZ-06 | UUID auto-generation | notification_uuid generated via Uuid::uuid4() if not provided |
| BC-BIZ-07 | Initialize counter fields | total_recipients, sent_count, failed_count, etc. all set to 0 |
| BC-BIZ-08 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-09 | Soft delete | is_active set to false, then soft deleted |
| BC-BIZ-10 | Process notification via process() | processed_at set, status updated to PROCESSING, job dispatched |
| BC-BIZ-11 | Process already processed notification | "This notification cannot be processed at this time." — 400 |
| BC-BIZ-12 | Update notification status | notification_status_id updated via updateStatus() AJAX |
| BC-BIZ-13 | Create with channels array | Each channel record created in ntf_notification_channels |
| BC-BIZ-14 | Update replaces channels | Existing channels deleted, new channels created |
| BC-BIZ-15 | Recurring end_count | recurring_end_count can be set for finite recurring |
| BC-BIZ-16 | Empty notifications grid | "No Notifications Found" or equivalent empty state |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | template_id | ntf_templates (id) | SET NULL |
| BC-REF-03 | priority_id | sys_dropdown_table (id) | RESTRICT |
| BC-REF-04 | confidentiality_level_id | sys_dropdown_table (id) | RESTRICT |
| BC-REF-05 | notification_status_id | sys_dropdown_table (id) | RESTRICT |
| BC-REF-06 | created_by | users (id) | RESTRICT |
| BC-REF-07 | approved_by | users (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Notifications page loads with all UI elements | Page loads with search bar, filters, tabs, Add button, grid | — | — | ⬜ |
| TC-P02 | Search notifications by title | Grid filtered to matching title only | — | — | ⬜ |
| TC-P03 | Create notification with all required fields (IMMEDIATE) | Notification created with correct values | — | — | ⬜ |
| TC-P04 | Create notification with SCHEDULED type | scheduled_at required and saved correctly | — | — | ⬜ |
| TC-P05 | Create notification with RECURRING type and DAILY pattern | scheduled_at + recurring_pattern saved | — | — | ⬜ |
| TC-P06 | Create notification with CUSTOM recurring expression | recurring_expression saved | — | — | ⬜ |
| TC-P07 | Create notification with channels array | Channel records created in ntf_notification_channels | — | — | ⬜ |
| TC-P08 | Create PROMOTIONAL notification (auto PENDING) | Status set to PENDING if not approved | — | — | ⬜ |
| TC-P09 | Edit notification loads pre-filled data | Edit form shows all existing field values | — | — | ⬜ |
| TC-P10 | Update notification title and description | Title and description updated | — | — | ⬜ |
| TC-P11 | View notification show page | Show page renders with all fields and relationships | — | — | ⬜ |
| TC-P12 | Toggle status active to inactive | AJAX success, is_active flipped to false | — | — | ⬜ |
| TC-P13 | Toggle status inactive to active | AJAX success, is_active flipped to true | — | — | ⬜ |
| TC-P14 | Update notification status via updateStatus() | notification_status_id updated | — | — | ⬜ |
| TC-P15 | Soft delete notification | Notification moved to trash | — | — | ⬜ |
| TC-P16 | View trashed notifications | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P17 | Restore trashed notification | Notification restored | — | — | ⬜ |
| TC-P18 | Force delete notification from trash | Notification permanently removed | — | — | ⬜ |
| TC-P19 | Process notification (APPROVED status) | processed_at set, job dispatched | — | — | ⬜ |
| TC-P20 | Create notification with all optional fields | All optional fields (description, expires_at, etc.) saved | — | — | ⬜ |
| TC-P21 | Pagination — first page shows 10 records | Page 1 shows up to 10 records | — | — | ⬜ |
| TC-P22 | Pagination — second page shows remaining records | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P23 | Empty state — no notifications exist | Grid shows "No Notifications Found" or equivalent | — | — | ⬜ |
| TC-P24 | UUID auto-generation on create | notification_uuid populated with valid UUID | — | — | ⬜ |
| TC-P25 | Full lifecycle: create→edit→toggle→updateStatus→process→delete→trash→restore | All transitions succeed | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `title` | Validation error: "The title field is required." | — | — | ⬜ |
| TC-N02 | Required — missing `source_module` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `notification_event` | Validation error | — | — | ⬜ |
| TC-N04 | Required — missing `notification_type` | Validation error | — | — | ⬜ |
| TC-N05 | Required — missing `priority_id` | Validation error: "The priority field is required." | — | — | ⬜ |
| TC-N06 | Required — missing `confidentiality_level_id` | Validation error | — | — | ⬜ |
| TC-N07 | Required — missing `schedule_type` | Validation error | — | — | ⬜ |
| TC-N08 | Required — missing `notification_status_id` | Validation error | — | — | ⬜ |
| TC-N09 | Invalid notification_type | Validation error on in rule | — | — | ⬜ |
| TC-N10 | Invalid schedule_type | Validation error on in rule | — | — | ⬜ |
| TC-N11 | Missing scheduled_at when SCHEDULED | Validation error: required_if | — | — | ⬜ |
| TC-N12 | Missing recurring_pattern when RECURRING | Validation error: required_if | — | — | ⬜ |
| TC-N13 | Missing recurring_expression when CUSTOM pattern | Validation error: required_if | — | — | ⬜ |
| TC-N14 | expires_at before scheduled_at | Validation error: after | — | — | ⬜ |
| TC-N15 | recurring_end_at before scheduled_at | Validation error: after | — | — | ⬜ |
| TC-N16 | Invalid template_id (non-existent) | Validation error: exists | — | — | ⬜ |
| TC-N17 | Invalid priority_id (non-existent) | Validation error: exists | — | — | ⬜ |
| TC-N18 | Invalid channel_id in channels array | Validation error: exists | — | — | ⬜ |
| TC-N19 | channels.*.channel_id missing | Validation error: channels.*.channel_id required | — | — | ⬜ |
| TC-N20 | channels.*.status_id missing | Validation error: channels.*.status_id required | — | — | ⬜ |
| TC-N21 | Process non-processable notification (already processed) | 400: "This notification cannot be processed at this time." | — | — | ⬜ |
| TC-N22 | View non-existent notification (404) | 404 Not Found | — | — | ⬜ |
| TC-N23 | Edit non-existent notification (404) | 404 Not Found | — | — | ⬜ |
| TC-N24 | Update non-existent notification (404) | 404 Not Found | — | — | ⬜ |
| TC-N25 | Delete non-existent notification (404) | 404 Not Found | — | — | ⬜ |
| TC-N26 | Title exceeds 255 chars | Validation error on title.max | — | — | ⬜ |
| TC-N27 | Invalid recurring_end_count (negative) | Validation error on min:1 | — | — | ⬜ |
| TC-N28 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create notification with template — verify template relationship | Template shown in notification details | — | — | ⬜ |
| TC-D02 | Delete template used in notification — template_id set to NULL | Template set to NULL (SET NULL) | — | — | ⬜ |
| TC-D03 | Create notification with channels — verify channel relationships | NotificationChannels created and linked | — | — | ⬜ |
| TC-D04 | Process notification — verify NotificationDeliveryLog entries | Delivery log entries created after processing | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | Status checks — `canBeProcessed()` logic | Returns false if processed_at is set or is_active is false; checks notification_status_id for APPROVED/SCHEDULED | — | — | ◌ |
| TC-CR02 | Process job dispatch — `ProcessNotificationJob` | Job dispatched with the notification model | — | — | ◌ |
| TC-CR03 | UUID generation — `Uuid::uuid4()` | Unique UUID generated on create if not provided | — | — | ◌ |
| TC-CR04 | Transactional safety — store() uses DB::transaction | Rollback on failure, only commit on complete success | — | — | ◌ |
| TC-CR05 | PROMOTIONAL auto-PENDING logic | If notification_type=PROMOTIONAL and not approved, status set to PENDING | — | — | ◌ |
| TC-CR06 | Channel replacement on update | Old NotificationChannel records deleted, new ones created | — | — | ◌ |
| TC-CR07 | Counter fields initialized to 0 | All counter fields set to 0 on creation | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Notifications page loads with all UI elements
1. Login as admin user with `tenant.notification.viewAny` permission
2. Navigate to `GET /notification-mgt` or `GET /notifications`
3. Verify page loads without errors (200 OK)
4. Verify search bar is displayed
5. Verify tab navigation is displayed (Notifications, Templates, Channels, etc.)
6. Verify "Add Notification" button is displayed
7. Verify notifications grid/table is displayed with headers
8. Verify pagination controls are displayed

#### TC-P02: Search notifications by title
1. Ensure at least 2 notifications exist with different titles
2. Enter a search term matching one notification's title
3. Click Search
4. Verify grid shows only matching notification
5. Verify non-matching notifications are not displayed

#### TC-P03: Create notification with all required fields (IMMEDIATE)
1. Click "Add Notification"
2. Fill all required fields: title, source_module, notification_event, notification_type, priority_id, confidentiality_level_id, schedule_type=IMMEDIATE, notification_status_id
3. Submit the form
4. Verify 302 redirect to index page with success message
5. Verify notification appears in the grid

#### TC-P04: Create notification with SCHEDULED type
1. Click "Add Notification"
2. Fill required fields with schedule_type=SCHEDULED
3. Provide a valid scheduled_at datetime
4. Submit the form
5. Verify notification created with scheduled_at saved

#### TC-P05: Create notification with RECURRING type and DAILY pattern
1. Click "Add Notification"
2. Fill required fields with schedule_type=RECURRING
3. Provide scheduled_at and recurring_pattern=DAILY
4. Submit the form
5. Verify recurring notification created

#### TC-P06: Create notification with CUSTOM recurring expression
1. Click "Add Notification"
2. Fill required fields with schedule_type=RECURRING
3. Set recurring_pattern=CUSTOM
4. Provide recurring_expression (e.g., "FREQ=WEEKLY;BYDAY=MO,WE,FR")
5. Submit the form
6. Verify recurring_expression saved

#### TC-P07: Create notification with channels array
1. Click "Add Notification"
2. Fill required fields
3. Add at least one channel entry with channel_id, provider_id, status_id, max_retry
4. Submit the form
5. Verify notification created
6. Verify NotificationChannel records created in ntf_notification_channels

#### TC-P08: Create PROMOTIONAL notification (auto PENDING)
1. Click "Add Notification"
2. Set notification_type=PROMOTIONAL
3. Do not set approved_by
4. Submit the form
5. Verify notification created with notification_status_id mapped to PENDING status key

#### TC-P09 through TC-P25: (Similar step pattern for each positive case — follow the TC ID description to construct specific steps.)

### 7.2 Negative TC Steps

#### TC-N01: Required — missing `title`
1. Click "Add Notification"
2. Fill all fields except title
3. Submit the form
4. Verify 422 validation error: "The title field is required."
5. Verify notification not created

#### TC-N02 through TC-N28: (Similar step pattern — follow the TC ID description to construct specific steps.)

### 7.3 Dependency TC Steps

#### TC-D01: Create notification with template
1. Create an approved template first
2. Create a notification with template_id = the created template's id
3. View the notification show page
4. Verify template details are displayed in the notification

#### TC-D02: Delete template used in notification
1. Create a notification with a template_id
2. Delete the template (soft delete)
3. View the notification
4. Verify template_id is NULL (SET NULL referential action)

#### TC-D03: Create notification with channels
1. Create a notification with channels array containing 2 channel entries
2. Verify NotificationChannel records created (2 records)
3. View notification show page
4. Verify channel details displayed

#### TC-D04: Process notification
1. Create a notification with APPROVED status
2. Ensure canBeProcessed() returns true
3. Call process endpoint
4. Verify processed_at is set
5. Verify notification_status_id changed to PROCESSING

### 7.4 Code Review TC Steps

#### TC-CR01: canBeProcessed() logic
1. Create notification with processed_at=null, is_active=true, APPROVED status → returns true
2. Create notification with processed_at=now → returns false
3. Create notification with is_active=false → returns false
4. Create notification with PENDING status → returns false

#### TC-CR02: Process job dispatch
1. Review `NotificationManageController@process()` line 613
2. Verify `ProcessNotificationJob::dispatch($notification)` is called within transaction
3. Ensure job class exists at `Modules\Notification\Jobs\ProcessNotificationJob`

#### TC-CR03: UUID generation
1. Review `NotificationManageController@store()` line 334
2. Verify `Uuid::uuid4()->toString()` generates valid UUID v4

#### TC-CR04: Transactional safety
1. Review store() and update() methods
2. Verify DB::transaction() wraps all create/update operations
3. Ensure on failure, no partial data is persisted

#### TC-CR05: PROMOTIONAL auto-PENDING
1. Review `NotificationManageController@store()` lines 352-366
2. Verify when notification_type=PROMOTIONAL and no approved_by, status set to PENDING
3. Verify sys_dropdown_table lookup uses key `ntf_notifications.notification_status_id.notification_status` and dropdown_key `PENDING`

#### TC-CR06: Channel replacement on update
1. Review `NotificationManageController@update()` line 432
2. Verify `NotificationChannel::where('notification_id', $notification->id)->delete()` is called before recreating channels
3. Ensure old records are deleted (not soft-deleted where possible)

#### TC-CR07: Counter fields initialized to 0
1. Review `NotificationManageController@store()` lines 336-348
2. Verify total_recipients=0, sent_count=0, failed_count=0, delivered_count=0, read_count=0, click_count=0, estimated_cost=0, actual_cost=0, recurring_executed_count=0
