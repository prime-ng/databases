# ntf_Channels_TcList

## Module: Notification → Notification Management → Channels

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Channels (Channel Master) |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /notification-channels` (index), `POST /notification-channels` (store), `GET /notification-channels/{channel}` (show), `GET /notification-channels/{channel}/edit` (edit), `PUT /notification-channels/{channel}` (update), `DELETE /notification-channels/{channel}` (destroy), `POST /notification-channels/{channel}/toggle-status` (toggleStatus), `GET /notification-channels/trash/view` (trashed), `GET /notification-channels/{id}/restore` (restore), `DELETE /notification-channels/{id}/force-delete` (forceDelete), `GET /notification-channels/{id}/statistics` (statistics) |
| Controller | `Modules\Notification\Http\Controllers\ChannelMasterController` |
| Model(s) | `Modules\Notification\Models\ChannelMaster` (table: `ntf_channel_master`) |
| Validation | Inline `validateChannel()` method in `ChannelMasterController` |
| Permissions | `tenant.channel-master.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | 10 records per page (`ChannelMasterController@index` line 50) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` checks fallback channel usage before delete |
| Activity Log | Events: Trashed, Restored, Deleted, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.channel-master.viewAny` for index, `tenant.channel-master.create` for store, `tenant.channel-master.update` for update/toggleStatus, `tenant.channel-master.delete` for destroy, `tenant.channel-master.restore` for restore/trashed, `tenant.channel-master.forceDelete` for forceDelete
- No seed data required — channels can be created fresh
- Test user must have `tenant.channel-master.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For delete-guard tests: At least one other channel using this channel as fallback

---

## 3. Default Data Load

When the page loads via `ChannelMasterController@index()` (or via tab), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Channels | `ChannelMasterController@index()` | `ChannelMaster::query()` | search (name/code), status (is_active) | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with('channel')->latest()` | — | 10/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','recurringInterval','creator'])->latest()` | — | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |

---

## 4. Test Data Strategy

- **Code uniqueness**: Channel code must be unique per tenant — suffix test data with timestamp or UUID
- **Fallback chain test**: Create chained fallback channels to test circular fallback detection
- **Channel types**: Test all channel_type values (EMAIL, SMS, PUSH, WHATSAPP, IN_APP)
- **Rate limits**: Test boundary values for rate_limit_per_minute (0-10000), max_retry (0-10), priority_order (1-10)
- **Cost precision**: cost_per_unit uses DECIMAL(10,4) — test with 4 decimal places
- **Pre-test cleanup**: Delete created channels by code before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **Fallback dependency**: Create Channel A, Channel B with fallback_channel_id = A, Channel C with fallback_channel_id = B — test delete guard on A and B
- **Circular fallback**: Test A→B→C→A circular chain rejection (controller checks up to depth 5)

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_channel_master`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id |
| BC-DB-03 | code | VARCHAR(20) | NOT NULL, UQ per tenant |
| BC-DB-04 | name | VARCHAR(50) | NOT NULL |
| BC-DB-05 | description | VARCHAR(255) | NULLABLE |
| BC-DB-06 | channel_type | ENUM('EMAIL','SMS','PUSH','WHATSAPP','IN_APP') | NOT NULL |
| BC-DB-07 | priority_order | INT UNSIGNED | NOT NULL DEFAULT 5, MIN 1, MAX 10 |
| BC-DB-08 | max_retry | INT UNSIGNED | NOT NULL DEFAULT 3, MIN 0, MAX 10 |
| BC-DB-09 | retry_delay_minutes | INT UNSIGNED | NOT NULL DEFAULT 5, MIN 0, MAX 1440 |
| BC-DB-10 | rate_limit_per_minute | INT UNSIGNED | NOT NULL DEFAULT 100, MIN 0, MAX 10000 |
| BC-DB-11 | daily_limit | INT UNSIGNED | NOT NULL DEFAULT 10000, MIN 0 |
| BC-DB-12 | monthly_limit | INT UNSIGNED | NOT NULL DEFAULT 100000, MIN 0 |
| BC-DB-13 | cost_per_unit | DECIMAL(10,4) | NOT NULL DEFAULT 0.0000, MIN 0 |
| BC-DB-14 | fallback_channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NULLABLE, circular check enforced in code |
| BC-DB-15 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-16 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-17 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-18 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `validateChannel()` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | code | required, string, max:20, unique:ntf_channel_master per tenant (ignore current) | — (unique validation) |
| BC-VAL-02 | name | required, string, max:50 | — |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | channel_type | required, in:EMAIL,SMS,PUSH,WHATSAPP,IN_APP | — |
| BC-VAL-05 | priority_order | nullable, integer, min:1, max:10 | — |
| BC-VAL-06 | max_retry | nullable, integer, min:0, max:10 | — |
| BC-VAL-07 | retry_delay_minutes | nullable, integer, min:0, max:1440 | — |
| BC-VAL-08 | rate_limit_per_minute | nullable, integer, min:0, max:10000 | — |
| BC-VAL-09 | daily_limit | nullable, integer, min:0 | — |
| BC-VAL-10 | monthly_limit | nullable, integer, min:0 | — |
| BC-VAL-11 | cost_per_unit | nullable, numeric, min:0 | — |
| BC-VAL-12 | fallback_channel_id | nullable, integer, exists:ntf_channel_master,id, custom self-reference check, circular chain detection | "Channel cannot be its own fallback." / "Circular fallback chain detected at depth N." |
| BC-VAL-13 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.channel-master.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.channel-master.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.channel-master.view` | show, statistics — without → 403 |
| BC-AUTH-04 | `tenant.channel-master.update` | edit, update, toggleStatus — without → 403 |
| BC-AUTH-05 | `tenant.channel-master.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.channel-master.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.channel-master.forceDelete` | forceDelete — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with channels tab | Paginated grid at 10 records/page, ordered by latest |
| BC-BIZ-02 | Search by name | Filters channels where name contains search term |
| BC-BIZ-03 | Search by code | Filters channels where code contains search term |
| BC-BIZ-04 | Filter by status | Filters channels by is_active (0 or 1) |
| BC-BIZ-05 | Code auto-uppercased on save | `setCodeAttribute()` mutator converts code to uppercase |
| BC-BIZ-06 | Create with defaults | priority_order=5, max_retry=3, retry_delay_minutes=5, rate_limit=100, daily_limit=10000, monthly_limit=100000, cost_per_unit=0.0000 |
| BC-BIZ-07 | Create with fallback_channel_id | Fallback channel linked correctly |
| BC-BIZ-08 | Self-fallback prevention | "Channel cannot be its own fallback." validation error |
| BC-BIZ-09 | Circular fallback detection (depth 2: A→B→A) | "Circular fallback chain detected at depth 2." |
| BC-BIZ-10 | Circular fallback detection (depth 3: A→B→C→A) | "Circular fallback chain detected at depth 3." |
| BC-BIZ-11 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-12 | Delete channel with no fallback dependents | Channel soft-deleted, moved to trash |
| BC-BIZ-13 | Delete channel used as fallback | Error: "Cannot delete channel as it is used as fallback by other channels" |
| BC-BIZ-14 | Force delete channel with no fallback dependents | Channel permanently removed |
| BC-BIZ-15 | Force delete channel used as fallback | Error: "Cannot delete channel as it is used as fallback by other channels" |
| BC-BIZ-16 | Statistics endpoint | Returns JSON with total_notifications, used_as_fallback_by, daily_limit, monthly_limit, rate_limit |
| BC-BIZ-17 | Empty channels grid | "No Channels Found" or equivalent empty state |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | fallback_channel_id | ntf_channel_master (id) | SET NULL (self FK) |
| BC-REF-03 | id (self) | ntf_channel_master.fallback_channel_id | Child FK — checked in controller before delete |
| BC-REF-04 | id (self) | ntf_templates.channel_id | Child FK |
| BC-REF-05 | id (self) | ntf_provider_master.channel_id | Child FK |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Channels page loads with all UI elements | Page loads with search bar, status filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search channels by name | Grid filtered to matching name only | — | — | ⬜ |
| TC-P03 | Search channels by code | Grid filtered to matching code only | — | — | ⬜ |
| TC-P04 | Filter by active status | Grid shows only active channels | — | — | ⬜ |
| TC-P05 | Filter by inactive status | Grid shows only inactive channels | — | — | ⬜ |
| TC-P06 | Create channel — EMAIL type with all required fields | Channel created with correct values | — | — | ⬜ |
| TC-P07 | Create channel — SMS type | SMS channel created | — | — | ⬜ |
| TC-P08 | Create channel — PUSH type | PUSH channel created | — | — | ⬜ |
| TC-P09 | Create channel — WHATSAPP type | WHATSAPP channel created | — | — | ⬜ |
| TC-P10 | Create channel — IN_APP type | IN_APP channel created | — | — | ⬜ |
| TC-P11 | Create channel with fallback_channel_id | Fallback linked correctly | — | — | ⬜ |
| TC-P12 | Create channel with all optional fields | All optional fields saved | — | — | ⬜ |
| TC-P13 | Code auto-uppercased on create | Code stored in uppercase | — | — | ⬜ |
| TC-P14 | Edit channel loads pre-filled data | Edit form shows all existing field values | — | — | ⬜ |
| TC-P15 | Update channel name and description | Name and description updated | — | — | ⬜ |
| TC-P16 | Update fallback_channel_id | Fallback updated | — | — | ⬜ |
| TC-P17 | View channel show page | Show page renders with all fields and relationships | — | — | ⬜ |
| TC-P18 | View channel statistics | JSON with counts returned | — | — | ⬜ |
| TC-P19 | Toggle status active to inactive | AJAX success, is_active flipped to false | — | — | ⬜ |
| TC-P20 | Toggle status inactive to active | AJAX success, is_active flipped to true | — | — | ⬜ |
| TC-P21 | Soft delete channel (no fallback dependents) | Channel moved to trash | — | — | ⬜ |
| TC-P22 | View trashed channels | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P23 | Restore trashed channel | Channel restored | — | — | ⬜ |
| TC-P24 | Force delete channel from trash (no fallback dependents) | Channel permanently removed | — | — | ⬜ |
| TC-P25 | Full lifecycle: create→edit→toggle→delete→trash→restore→forceDelete | All transitions succeed | — | — | ⬜ |
| TC-P26 | Pagination — first page shows 10 records | Page 1 shows up to 10 records | — | — | ⬜ |
| TC-P27 | Pagination — second page shows remaining records | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P28 | Empty state — no channels exist | Grid shows "No Channels Found" or equivalent | — | — | ⬜ |
| TC-P29 | Create channel with custom priority_order=1 | Priority set to 1 | — | — | ⬜ |
| TC-P30 | Create channel with cost_per_unit=0.2500 | Cost saved with 4 decimal precision | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `code` | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Required — missing `name` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `channel_type` | Validation error | — | — | ⬜ |
| TC-N04 | Duplicate code within tenant | "The code has already been taken." | — | — | ⬜ |
| TC-N05 | Max length — code > 20 chars | Validation error on code.max | — | — | ⬜ |
| TC-N06 | Max length — name > 50 chars | Validation error on name.max | — | — | ⬜ |
| TC-N07 | Invalid channel_type | Validation error on channel_type.in | — | — | ⬜ |
| TC-N08 | priority_order < 1 | Validation error on min:1 | — | — | ⬜ |
| TC-N09 | priority_order > 10 | Validation error on max:10 | — | — | ⬜ |
| TC-N10 | max_retry < 0 | Validation error on min:0 | — | — | ⬜ |
| TC-N11 | max_retry > 10 | Validation error on max:10 | — | — | ⬜ |
| TC-N12 | retry_delay_minutes > 1440 | Validation error on max:1440 | — | — | ⬜ |
| TC-N13 | rate_limit_per_minute > 10000 | Validation error on max:10000 | — | — | ⬜ |
| TC-N14 | cost_per_unit negative | Validation error on min:0 | — | — | ⬜ |
| TC-N15 | Self-fallback (channel_id == fallback_channel_id) | "Channel cannot be its own fallback." | — | — | ⬜ |
| TC-N16 | Circular fallback A→B→A | "Circular fallback chain detected at depth 2." | — | — | ⬜ |
| TC-N17 | Circular fallback A→B→C→A | "Circular fallback chain detected at depth 3." | — | — | ⬜ |
| TC-N18 | Delete channel used as fallback by other channel | "Cannot delete channel as it is used as fallback by other channels" | — | — | ⬜ |
| TC-N19 | Force delete channel used as fallback | "Cannot delete channel as it is used as fallback by other channels" | — | — | ⬜ |
| TC-N20 | Invalid fallback_channel_id (non-existent) | Validation error: exists | — | — | ⬜ |
| TC-N21 | View non-existent channel (404) | 404 Not Found | — | — | ⬜ |
| TC-N22 | Edit non-existent channel (404) | 404 Not Found | — | — | ⬜ |
| TC-N23 | Update non-existent channel (404) | 404 Not Found | — | — | ⬜ |
| TC-N24 | Delete non-existent channel (404) | 404 Not Found | — | — | ⬜ |
| TC-N25 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create template with channel — verify relationship | Template references channel correctly | — | — | ⬜ |
| TC-D02 | Delete channel used by template — channel soft-deleted | Template channel_id still references original (FK not violated due to soft delete) | — | — | ⬜ |
| TC-D03 | Create provider with channel — verify relationship | Provider references channel correctly | — | — | ⬜ |
| TC-D04 | Channel A as fallback for B — delete guard on A | Cannot delete A while B references it as fallback | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | Inline `validateChannel()` method rules | All 13 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | Circular fallback detection algorithm | Traverses fallback chain up to depth 5, detects cycles | — | — | ◌ |
| TC-CR03 | Code uppercase mutator — `setCodeAttribute()` | Code always stored in uppercase regardless of input case | — | — | ◌ |
| TC-CR04 | Fallback check in destroy() — withTrashed() query | Checks both active and soft-deleted channels for fallback usage | — | — | ◌ |
| TC-CR05 | Fallback check in forceDelete() — withTrashed() query | forceDelete also checks withTrashed() for fallback usage | — | — | ◌ |
| TC-CR06 | Activity log on trash/restore/delete/toggle | activityLog() called with appropriate event names | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Channels page loads with all UI elements
1. Login as admin user with `tenant.channel-master.viewAny` permission
2. Navigate to `GET /notification-channels` or via `GET /notification-mgt?tab=channels`
3. Verify page loads without errors (200 OK)
4. Verify search bar is displayed
5. Verify status filter dropdown is displayed (All/Active/Inactive)
6. Verify "Add Channel" button is displayed
7. Verify channels grid/table is displayed with headers (Code, Name, Type, Priority, Status, Actions)
8. Verify pagination controls are displayed

#### TC-P02: Search channels by name
1. Ensure at least 2 channels exist with different names
2. Enter a search term matching one channel's name
3. Click Search
4. Verify grid shows only matching channel
5. Verify non-matching channels are not displayed

#### TC-P03: Search channels by code
1. Ensure at least 2 channels exist with different codes
2. Enter a search term matching one channel's code
3. Click Search
4. Verify grid shows only matching channel(s)

#### TC-P04: Filter by active status
1. Ensure at least one active and one inactive channel exist
2. Select "Active" from status filter dropdown
3. Click Search/Filter
4. Verify grid shows only active channels (is_active=1)

#### TC-P05: Filter by inactive status
1. Ensure at least one active and one inactive channel exist
2. Select "Inactive" from status filter dropdown
3. Click Search/Filter
4. Verify grid shows only inactive channels (is_active=0)

#### TC-P06: Create channel — EMAIL type
1. Click "Add Channel"
2. Fill code="EMAIL_TEST", name="Test Email Channel", channel_type="EMAIL"
3. Set default values for optional fields
4. Submit the form
5. Verify 302 redirect with success message
6. Verify channel appears in the grid with code "EMAIL_TEST" (uppercased)

#### TC-P07 through TC-P10: (Similar to TC-P06, just with different channel_type values)

#### TC-P11: Create channel with fallback
1. Create Channel A first (e.g., code="PRIMARY_SMS")
2. Click "Add Channel" to create Channel B
3. Set fallback_channel_id to Channel A's id
4. Submit the form
5. Verify Channel B created with fallback_channel_id = Channel A's id

#### TC-P12: Create channel with all optional fields
1. Fill all fields: code, name, description, channel_type, priority_order=3, max_retry=5, retry_delay_minutes=10, rate_limit_per_minute=500, daily_limit=50000, monthly_limit=500000, cost_per_unit=0.0500, fallback_channel_id=(valid)
2. Submit the form
3. Verify all values saved correctly

#### TC-P13: Code auto-uppercased
1. Create channel with code="test_email" (lowercase)
2. View the created channel
3. Verify code displayed as "TEST_EMAIL" (uppercase)

#### TC-P14 through TC-P30: (Similar step pattern — follow TC ID description.)

### 7.2 Negative TC Steps

#### TC-N01: Required — missing `code`
1. Click "Add Channel"
2. Fill all fields except code
3. Submit the form
4. Verify 422 validation error for code
5. Verify channel not created

#### TC-N02 through TC-N25: (Similar step pattern — follow TC ID description.)

### 7.3 Dependency TC Steps

#### TC-D01: Create template with channel
1. Create channel with code="EMAIL_DEP"
2. Create a notification template with channel_id = created channel's id
3. View template details
4. Verify channel relationship is displayed

#### TC-D02: Delete channel used by template
1. Create channel, create template referencing it
2. Soft-delete the channel
3. Verify template channel_id still references original (no FK violation)
4. Note: template.channel_id remains set (no CASCADE)

#### TC-D03: Create provider with channel
1. Create channel
2. Create a provider with channel_id = created channel's id
3. View provider details
4. Verify channel relationship displayed

#### TC-D04: Channel A as fallback for B — delete guard
1. Create Channel A (code="PRIMARY")
2. Create Channel B (code="SECONDARY") with fallback_channel_id = A's id
3. Try to delete Channel A
4. Verify error message: "Cannot delete channel as it is used as fallback by other channels"

### 7.4 Code Review TC Steps

#### TC-CR01: Inline validateChannel() rules
1. Review `ChannelMasterController@validateChannel()` (lines 382-448)
2. Verify all 13 field rules are present
3. Verify tenant_id is handled via hidden field in create form

#### TC-CR02: Circular fallback detection
1. Review validateChannel() lines 420-441
2. Verify it uses a `$visited` array to detect cycles
3. Verify depth limit of 5 iterations
4. Test: A→B→C→A should fail at depth 3 with message "Circular fallback chain detected at depth 3."

#### TC-CR03: Code uppercase mutator
1. Review `ChannelMaster::setCodeAttribute()` (line 122-125)
2. Verify `$this->attributes['code'] = strtoupper($value)`

#### TC-CR04: Fallback check in destroy()
1. Review `ChannelMasterController@destroy()` lines 240-246
2. Verify `ChannelMaster::where('fallback_channel_id', $channel->id)->exists()` check before delete

#### TC-CR05: Fallback check in forceDelete()
1. Review `ChannelMasterController@forceDelete()` lines 304-312
2. Verify `ChannelMaster::withTrashed()->where('fallback_channel_id', $channel->id)->exists()` check
3. NOTE: forceDelete uses withTrashed() while destroy does not — destroy only checks active records

#### TC-CR06: Activity log
1. Review destroy() line 250: `activityLog($channel, 'Trashed', ...)`
2. Review restore() line 285: `activityLog($channel, 'Restored', ...)`
3. Review forceDelete() line 317: `activityLog($channel, 'Deleted', ...)`
4. Review toggleStatus() line 345: `activityLog($channel, 'Toggled', ...)`
