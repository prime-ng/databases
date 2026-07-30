# ntf_DeliveryLog_TcList

## Module: Notification → Notification Management → Delivery Log

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Delivery Log (read-only / append-only — minimal TcList) |
| URL(s) | Delivery log is displayed inline within the `GET /notification-mgt` tab index view — no dedicated controller or CRUD routes |
| Controller | No dedicated controller; delivery log data loaded inline via `NotificationManageController@tabIndex()` or shared `loadDeliveryLog()` method |
| Model(s) | `Modules\Notification\Models\NotificationDeliveryLog` (table: `ntf_delivery_logs`) |
| Validation | N/A — append-only, no create/edit/delete forms |
| Permissions | Inherited from parent tenant context (viewAny on notification) |
| Pagination | 10 records per page (assumed from side-loaded data pattern) |
| Soft Deletes | **NO soft deletes** — `$fillable` does NOT include `deleted_at`, no `SoftDeletes` trait in model |
| is_active | **NO is_active column** — table is an append-only audit trail |
| Activity Log | N/A — the log itself IS the activity trail |
| Notes | **Read-only / append-only** — BR-NTF-008: No editing or deletion of delivery log records. Stats cards show Delivered, Failed, Bounced, Read counts. Filtered by search, notification_id, channel_id, delivery_status_id, date_from/to. |

---

## 2. Pre-conditions

- Required permissions: Inherited from tenant notification viewAny permission
- Seed data required: At least one `ntf_notifications`, `ntf_channel_master`, `sys_dropdown_table` (for delivery_status_id), `ntf_resolved_recipients`, `ntf_provider_master`, `sys_users` records
- Test user must have appropriate tenant notification permissions
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Delivery log records must exist for display — normally created by the delivery pipeline

---

## 3. Default Data Load

Delivery log data is loaded as part of the main tab-index view. The data is rendered inline within the notification management dashboard:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Delivery Log | Inline via shared loader | `NotificationDeliveryLog::with(['notification','channel','user','status'])` | search (user.name, error_message), notification_id, channel_id, delivery_status_id, date_from, date_to | 10/page |

---

## 4. Test Data Strategy

- **Append-only (BR-NTF-008)**: No create/edit/delete operations — only read and filter testing
- **Stats cards**: Verify counts for Delivered, Failed, Bounced, Read states
- **Pre-seed**: Delivery log data must be pre-seeded for display tests — normally created by pipeline
- **Delivery stages**: Test all `delivery_stage` values: QUEUED, SENT, DELIVERED, READ, CLICKED, BOUNCED, COMPLAINT, UNSUBSCRIBED
- **Date range**: Test filtering with date_from and date_to
- **Pre-test cleanup**: Clean up pre-seeded log records after tests
- **Pagination**: Test 10-record pagination

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_delivery_logs`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | notification_id | BIGINT UNSIGNED | FK → ntf_notifications.id CASCADE, NOT NULL |
| BC-DB-03 | channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NOT NULL |
| BC-DB-04 | resolved_recipient_id | BIGINT UNSIGNED | FK → ntf_resolved_recipients.id, NULLABLE |
| BC-DB-05 | resolved_user_id | BIGINT UNSIGNED | FK → sys_users.id, NULLABLE |
| BC-DB-06 | provider_id | BIGINT UNSIGNED | FK → ntf_provider_master.id, NULLABLE |
| BC-DB-07 | delivery_status_id | BIGINT UNSIGNED | FK → sys_dropdown_table.id, NULLABLE |
| BC-DB-08 | delivery_stage | ENUM('QUEUED','SENT','DELIVERED','READ','CLICKED','BOUNCED','COMPLAINT','UNSUBSCRIBED') | NOT NULL, DEFAULT 'SENT' |
| BC-DB-09 | provider_message_id | VARCHAR(255) | NULLABLE |
| BC-DB-10 | delivered_at | DATETIME | NULLABLE |
| BC-DB-11 | read_at | DATETIME | NULLABLE |
| BC-DB-12 | clicked_at | DATETIME | NULLABLE |
| BC-DB-13 | bounced_at | DATETIME | NULLABLE |
| BC-DB-14 | complaint_at | DATETIME | NULLABLE |
| BC-DB-15 | response_code | VARCHAR(20) | NULLABLE |
| BC-DB-16 | response_payload | JSON | NULLABLE |
| BC-DB-17 | error_message | VARCHAR(512) | NULLABLE |
| BC-DB-18 | duration_ms | INT | NULLABLE |
| BC-DB-19 | ip_address | VARCHAR(45) | NULLABLE |
| BC-DB-20 | user_agent | VARCHAR(255) | NULLABLE |
| BC-DB-21 | cost | DECIMAL(12,4) | NULLABLE |
| BC-DB-22 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-23 | updated_at | TIMESTAMP | NULLABLE |

### 5.2 Validation Rules

N/A — No create/edit/update forms exist. The delivery log is an append-only audit trail created by the processing pipeline.

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification.viewAny` | View delivery log in tab-index — without → log section not visible |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Delivery log tab/section loads | Paginated grid at 10 records/page, ordered by latest, with notification/channel/user/status relationships loaded |
| BC-BIZ-02 | Search by user name | Filters where related user.name contains search term |
| BC-BIZ-03 | Search by error_message | Filters where error_message contains search term |
| BC-BIZ-04 | Filter by notification_id | Exact match on notification_id |
| BC-BIZ-05 | Filter by channel_id | Exact match on channel_id |
| BC-BIZ-06 | Filter by delivery_status_id | Exact match on status ID |
| BC-BIZ-07 | Filter by date_from | Filters where created_at >= date_from |
| BC-BIZ-08 | Filter by date_to | Filters where created_at <= date_to |
| BC-BIZ-09 | Stats cards displayed | Cards show: Delivered count, Failed count, Bounced count, Read count |
| BC-BIZ-10 | BR-NTF-008: Append-only — no edit/delete | No edit or delete buttons/actions available in the UI |
| BC-BIZ-11 | Empty state — no delivery logs | Grid shows empty state |
| BC-BIZ-12 | Pagination — 10 per page | Page 1 shows up to 10 records |
| BC-BIZ-13 | Show delivery_stage label | ENUM value displayed as human-readable status |
| BC-BIZ-14 | Timestamps show correct datetime for each stage | delivered_at, read_at, clicked_at, bounced_at, complaint_at displayed when applicable |
| BC-BIZ-15 | provider_message_id and response_code displayed | Provider reference data visible in grid |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | notification_id | ntf_notifications (id) | CASCADE |
| BC-REF-02 | channel_id | ntf_channel_master (id) | CASCADE |
| BC-REF-03 | resolved_recipient_id | ntf_resolved_recipients (id) | SET NULL |
| BC-REF-04 | resolved_user_id | sys_users (id) | SET NULL |
| BC-REF-05 | provider_id | ntf_provider_master (id) | SET NULL |
| BC-REF-06 | delivery_status_id | sys_dropdown_table (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases (Display & Filter)

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Delivery log section loads with all UI elements | Log section displays with search bar, filters, stats cards, grid, pagination | — | — | ⬜ |
| TC-P02 | Search by user name | Grid filtered to matching user's log entries | — | — | ⬜ |
| TC-P03 | Search by error_message | Grid filtered to matching error text | — | — | ⬜ |
| TC-P04 | Filter by notification_id | Grid shows logs for selected notification | — | — | ⬜ |
| TC-P05 | Filter by channel_id | Grid shows logs for selected channel | — | — | ⬜ |
| TC-P06 | Filter by delivery_status_id | Grid shows logs with selected delivery status | — | — | ⬜ |
| TC-P07 | Filter by date_from | Grid shows logs from specified date onward | — | — | ⬜ |
| TC-P08 | Filter by date_to | Grid shows logs up to specified date | — | — | ⬜ |
| TC-P09 | Stats cards show correct counts | Delivered, Failed, Bounced, Read counts match query result | — | — | ⬜ |
| TC-P10 | Delivery stage labels displayed correctly | All 8 stages (QUEUED, SENT, DELIVERED, READ, CLICKED, BOUNCED, COMPLAINT, UNSUBSCRIBED) shown as labels | — | — | ⬜ |
| TC-P11 | Show page or detail view (if applicable) | Log detail view shows all fields: stage timestamps, provider info, response data, cost, IP, user agent | — | — | ⬜ |
| TC-P12 | Pagination — first page 10 records | Page 1 shows up to 10 logs | — | — | ⬜ |
| TC-P13 | Pagination — second page | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P14 | Empty state — no delivery logs | Section shows empty state message | — | — | ⬜ |
| TC-P15 | BR-NTF-008: No edit/delete actions | Verify no edit or delete buttons exist in the UI | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | No direct create/edit/delete routes | 404 or method-not-allowed if attempting CRUD on delivery logs | — | — | ⬜ |
| TC-N02 | Unauthorized access without notification permission | Log section not visible or 403 | — | — | ⬜ |
| TC-N03 | Filter with non-existent delivery_status_id | No results returned (empty state) | — | — | ⬜ |
| TC-N04 | Invalid date range format | Filter ignored or validation error | — | — | ⬜ |
| TC-N05 | date_from after date_to | Filter returns no results | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Delete notification — logs cascade deleted | Log records removed when parent notification deleted (CASCADE) | — | — | ⬜ |
| TC-D02 | Log references resolved recipient and provider | Relationship data displayed | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | No SoftDeletes trait in model | Model does NOT use SoftDeletes — records are append-only | — | — | ◌ |
| TC-CR02 | No is_active on table | `$fillable` does NOT include `is_active` — not a soft-enable/disable table | — | — | ◌ |
| TC-CR03 | NotificationDeliveryLog model relationships | `belongsTo` relationships for notification, channel, resolvedRecipient, provider, user, status | — | — | ◌ |
| TC-CR04 | Stats card query logic | Verify how delivered/failed/bounced/read counts are computed (likely via `delivery_stage` enum grouping) | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Delivery log section loads
1. Login as admin user with notification viewAny permission
2. Navigate to `GET /notification-mgt` and select the delivery log tab/section
3. Verify section loads (200 OK)
4. Verify stats cards displayed: Delivered, Failed, Bounced, Read counts
5. Verify search bar displayed
6. Verify filters: notification_id, channel_id, delivery_status_id, date_from, date_to
7. Verify log grid displayed with columns: User, Channel, Stage, Status, Provider Msg ID, Timestamp
8. Verify pagination controls displayed (10 per page)

#### TC-P02: Search by user name
1. Ensure delivery logs exist for different users
2. Search for matching user name
3. Verify grid filtered to matching logs

#### TC-P03: Search by error_message
1. Ensure at least one log has an error_message
2. Search for text in that error_message
3. Verify grid shows matching log(s)

#### TC-P04 through TC-P08: Filter tests
1. Apply each filter and verify grid data
2. For date range: set date_from and date_to, verify logs within range

#### TC-P09: Stats cards
1. Note the counts from stats cards
2. Run equivalent query manually
3. Verify counts match

#### TC-P10: Delivery stage labels
1. Create or ensure logs with different delivery_stage values exist
2. Verify each log displays the correct stage label

#### TC-P11: Detail view (if expandable)
1. Click on a log entry to view details
2. Verify all fields: provider_message_id, delivered_at, read_at, clicked_at, bounced_at, complaint_at, response_code, response_payload, error_message, duration_ms, ip_address, user_agent, cost

#### TC-P12 through TC-P14: Pagination and empty state
1. Standard pagination and empty state tests
2. Note: default pagination is 10 per page

#### TC-P15: BR-NTF-008 — No edit/delete
1. Scan the delivery log UI section
2. Verify there are NO edit buttons, delete buttons, or "Add Log" buttons
3. Verify no CRUD route definitions exist for delivery logs

### 7.2 Negative TC Steps

#### TC-N01: No direct CRUD routes
1. Attempt to POST to any delivery-log-like route
2. Verify 404 or method-not-allowed error

#### TC-N02: Unauthorized access
1. Login as user without notification viewAny
2. Navigate to notification-mgt tab
3. Verify delivery log section not visible (or 403)

#### TC-N03: Non-existent delivery_status_id
1. Filter by non-existent delivery_status_id (e.g., 99999)
2. Verify empty results

#### TC-N04: Invalid date format
1. Enter invalid date format for date_from/date_to
2. Verify filter is ignored or returns validation error

#### TC-N05: date_from after date_to
1. Set date_from after date_to
2. Verify no results returned

### 7.3 Dependency TC Steps

#### TC-D01: Delete notification — CASCADE
1. Create notification with delivery logs
2. Force delete the notification
3. Verify delivery logs for that notification are also deleted (CASCADE)

#### TC-D02: Log relationships
1. View log entry
2. Verify notification subject, channel name, resolved recipient details, provider name, user name, status label are all displayed

### 7.4 Code Review TC Steps

#### TC-CR01: No SoftDeletes
1. Review `NotificationDeliveryLog` model
2. Verify NO `use SoftDeletes;` trait
3. Verify NO `protected $dates = ['deleted_at'];`
4. Verify NO `deleted_at` in `$fillable`

#### TC-CR02: No is_active
1. Review `NotificationDeliveryLog` model `$fillable` array
2. Verify `is_active` is NOT in the fillable list
3. Verify NO `is_active` cast

#### TC-CR03: Model relationships
1. Review model relationships
2. Verify `belongsTo(Notification::class, 'notification_id')`
3. Verify `belongsTo(ChannelMaster::class, 'channel_id')`
4. Verify `belongsTo(ResolvedRecipient::class, 'resolved_recipient_id')`
5. Verify `belongsTo(ProviderMaster::class, 'provider_id')`
6. Verify `belongsTo(User::class, 'resolved_user_id')`
7. Verify `belongsTo(SysDropdown::class, 'delivery_status_id')` (aliased as `status()`)

#### TC-CR04: Stats card query logic
1. Review controller code that computes stats counts
2. Verify it queries `ntf_delivery_logs` grouped by `delivery_stage`
3. Verify delivered count = count where delivery_stage = 'DELIVERED' or delivered_at IS NOT NULL
4. Verify failed count = count where delivery_stage = 'BOUNCED' or error_message IS NOT NULL
5. Verify bounced count = count where delivery_stage = 'BOUNCED'
6. Verify read count = count where read_at IS NOT NULL
