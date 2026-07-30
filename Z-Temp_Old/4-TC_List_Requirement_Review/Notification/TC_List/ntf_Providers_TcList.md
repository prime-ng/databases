# ntf_Providers_TcList

## Module: Notification → Notification Management → Providers

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Providers (Provider Master) |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /provider-master` (index), `POST /provider-master` (store), `GET /provider-master/{provider}` (show), `GET /provider-master/{provider}/edit` (edit), `PUT /provider-master/{provider}` (update), `DELETE /provider-master/{provider}` (destroy), `POST /provider-master/{provider}/toggle-status` (toggleStatus), `GET /provider-master/trash/view` (trashed), `GET /provider-master/{id}/restore` (restore), `DELETE /provider-master/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\ProviderMasterController` |
| Model(s) | `Modules\Notification\Models\ProviderMaster` (table: `ntf_provider_master`) |
| Validation (Create/Update) | `Modules\Notification\Http\Requests\ProviderMasterRequest` |
| Permissions | `tenant.provider-master.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | 10 records per page (`ProviderMasterController@index` line 69) |
| Soft Deletes | Yes (SoftDeletes trait) |
| Activity Log | No explicit activityLog() calls in ProviderMasterController |

---

## 2. Pre-conditions

- Required permissions: `tenant.provider-master.viewAny` for index, `tenant.provider-master.create` for store, `tenant.provider-master.update` for update/toggleStatus, `tenant.provider-master.delete` for destroy, `tenant.provider-master.restore` for restore/trashed, `tenant.provider-master.forceDelete` for forceDelete
- Seed data required: At least one channel in `ntf_channel_master` (FK: channel_id)
- Test user must have `tenant.provider-master.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ProviderMasterController@index()`, the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Providers | `ProviderMasterController@index()` | `ProviderMaster::with('channel')` | search (provider_name/from_address), channel_id, provider_type, status | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with('channel')->latest()` | — | 10/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','creator'])->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |

---

## 4. Test Data Strategy

- **Channel dependency**: Each provider requires a valid channel_id — create test channels first
- **Provider types**: Test all provider_type values (PRIMARY, SECONDARY, BACKUP)
- **API credentials**: api_key_encrypted and api_secret_encrypted use `SafeEncrypted` cast — verify encryption on save and decryption on read
- **Configuration JSON**: configuration field is cast to array — test with valid JSON/array data
- **Priority**: Test priority values between 1-10
- **URL validation**: api_endpoint has `url` validation rule — test with valid and invalid URLs
- **Pre-test cleanup**: Delete created providers by provider_name before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **from_address**: Test email, phone number, and sender ID formats

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_provider_master`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id |
| BC-DB-03 | channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NOT NULL |
| BC-DB-04 | provider_name | VARCHAR(50) | NOT NULL |
| BC-DB-05 | provider_type | ENUM('PRIMARY','SECONDARY','BACKUP') | NOT NULL |
| BC-DB-06 | api_endpoint | VARCHAR(500) | NULLABLE, URL format |
| BC-DB-07 | api_key_encrypted | TEXT | NULLABLE, SafeEncrypted cast |
| BC-DB-08 | api_secret_encrypted | TEXT | NULLABLE, SafeEncrypted cast |
| BC-DB-09 | from_address | VARCHAR(255) | NULLABLE |
| BC-DB-10 | configuration | JSON | NULLABLE, cast to array |
| BC-DB-11 | priority | INT UNSIGNED | NULLABLE, MIN 1, MAX 10 |
| BC-DB-12 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-13 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-14 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-15 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `ProviderMasterRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | channel_id | required, integer, exists:ntf_channel_master,id | — |
| BC-VAL-02 | provider_name | required, string, max:50 | — |
| BC-VAL-03 | provider_type | required, in:PRIMARY,SECONDARY,BACKUP | — |
| BC-VAL-04 | api_endpoint | nullable, string, max:500, url | — |
| BC-VAL-05 | api_key_encrypted | nullable, string | — |
| BC-VAL-06 | api_secret_encrypted | nullable, string | — |
| BC-VAL-07 | from_address | nullable, string, max:255 | — |
| BC-VAL-08 | configuration | nullable, array | — |
| BC-VAL-09 | priority | nullable, integer, min:1, max:10 | — |
| BC-VAL-10 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.provider-master.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.provider-master.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.provider-master.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.provider-master.update` | edit, update, toggleStatus — without → 403 |
| BC-AUTH-05 | `tenant.provider-master.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.provider-master.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.provider-master.forceDelete` | forceDelete — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with providers tab | Paginated grid at 10 records/page, ordered by latest, with channel relation loaded |
| BC-BIZ-02 | Search by provider_name | Filters providers where provider_name contains search term |
| BC-BIZ-03 | Search by from_address | Filters providers where from_address contains search term |
| BC-BIZ-04 | Filter by channel_id | Filters providers by channel_id |
| BC-BIZ-05 | Filter by provider_type | Filters providers by provider_type (PRIMARY/SECONDARY/BACKUP) |
| BC-BIZ-06 | Filter by status | Filters providers by is_active (0 or 1) |
| BC-BIZ-07 | Create with all required fields | Provider created successfully |
| BC-BIZ-08 | Create with PRIMARY type | PRIMARY provider created |
| BC-BIZ-09 | Create with SECONDARY type | SECONDARY provider created |
| BC-BIZ-10 | Create with BACKUP type | BACKUP provider created |
| BC-BIZ-11 | API credentials encrypted on save | api_key_encrypted and api_secret_encrypted stored encrypted (SafeEncrypted cast) |
| BC-BIZ-12 | Configuration array saved as JSON | configuration stored as JSON, cast to array on read |
| BC-BIZ-13 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-14 | Soft delete provider | Provider moved to trash |
| BC-BIZ-15 | Restore trashed provider | Provider restored |
| BC-BIZ-16 | Force delete provider from trash | Provider permanently removed |
| BC-BIZ-17 | Empty providers grid | "No Providers Found" or equivalent empty state |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | channel_id | ntf_channel_master (id) | RESTRICT |
| BC-REF-03 | id (self) | ntf_notification_channels.provider_id | Child FK |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Providers page loads with all UI elements | Page loads with search bar, channel filter, provider type filter, status filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search providers by provider_name | Grid filtered to matching name only | — | — | ⬜ |
| TC-P03 | Search providers by from_address | Grid filtered to matching from_address | — | — | ⬜ |
| TC-P04 | Filter by channel_id | Grid shows only providers for selected channel | — | — | ⬜ |
| TC-P05 | Filter by provider_type=PRIMARY | Grid shows only PRIMARY providers | — | — | ⬜ |
| TC-P06 | Filter by provider_type=SECONDARY | Grid shows only SECONDARY providers | — | — | ⬜ |
| TC-P07 | Filter by provider_type=BACKUP | Grid shows only BACKUP providers | — | — | ⬜ |
| TC-P08 | Filter by active status | Grid shows only active providers | — | — | ⬜ |
| TC-P09 | Filter by inactive status | Grid shows only inactive providers | — | — | ⬜ |
| TC-P10 | Create provider with all required fields | Provider created with correct values | — | — | ⬜ |
| TC-P11 | Create provider with api_endpoint (valid URL) | api_endpoint saved | — | — | ⬜ |
| TC-P12 | Create provider with api_key_encrypted + api_secret_encrypted | Credentials stored encrypted | — | — | ⬜ |
| TC-P13 | Create provider with configuration array | configuration saved as JSON, cast to array on read | — | — | ⬜ |
| TC-P14 | Create provider with priority=1 | Priority set to 1 | — | — | ⬜ |
| TC-P15 | Create provider with priority=10 | Priority set to 10 | — | — | ⬜ |
| TC-P16 | Create provider with from_address | from_address saved | — | — | ⬜ |
| TC-P17 | Edit provider loads pre-filled data | Edit form shows all existing field values | — | — | ⬜ |
| TC-P18 | Update provider_name and provider_type | Name and type updated | — | — | ⬜ |
| TC-P19 | Update channel_id | Channel reference updated | — | — | ⬜ |
| TC-P20 | View provider show page | Show page renders with all fields and channel relationship | — | — | ⬜ |
| TC-P21 | Toggle status active to inactive | AJAX success, is_active flipped to false | — | — | ⬜ |
| TC-P22 | Toggle status inactive to active | AJAX success, is_active flipped to true | — | — | ⬜ |
| TC-P23 | Soft delete provider | Provider moved to trash | — | — | ⬜ |
| TC-P24 | View trashed providers | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P25 | Restore trashed provider | Provider restored | — | — | ⬜ |
| TC-P26 | Force delete provider from trash | Provider permanently removed | — | — | ⬜ |
| TC-P27 | Full lifecycle: create→edit→toggle→delete→trash→restore→forceDelete | All transitions succeed | — | — | ⬜ |
| TC-P28 | Pagination — first page shows 10 records | Page 1 shows up to 10 records | — | — | ⬜ |
| TC-P29 | Pagination — second page shows remaining records | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P30 | Empty state — no providers exist | Grid shows "No Providers Found" or equivalent | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `channel_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `provider_name` | Validation error | — | — | ⬜ |
| TC-N03 | Required — missing `provider_type` | Validation error | — | — | ⬜ |
| TC-N04 | Invalid channel_id (non-existent) | Validation error: exists | — | — | ⬜ |
| TC-N05 | Max length — provider_name > 50 chars | Validation error on provider_name.max | — | — | ⬜ |
| TC-N06 | Invalid provider_type | Validation error on in:PRIMARY,SECONDARY,BACKUP | — | — | ⬜ |
| TC-N07 | Invalid api_endpoint (not a URL) | Validation error on api_endpoint.url | — | — | ⬜ |
| TC-N08 | api_endpoint > 500 chars | Validation error on api_endpoint.max | — | — | ⬜ |
| TC-N09 | from_address > 255 chars | Validation error on from_address.max | — | — | ⬜ |
| TC-N10 | priority < 1 | Validation error on min:1 | — | — | ⬜ |
| TC-N11 | priority > 10 | Validation error on max:10 | — | — | ⬜ |
| TC-N12 | View non-existent provider (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Edit non-existent provider (404) | 404 Not Found | — | — | ⬜ |
| TC-N14 | Update non-existent provider (404) | 404 Not Found | — | — | ⬜ |
| TC-N15 | Delete non-existent provider (404) | 404 Not Found | — | — | ⬜ |
| TC-N16 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N17 | configuration not a valid array | Validation error on configuration.array (if passed as string) | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create provider with channel — verify channel relationship | Provider show page displays linked channel | — | — | ⬜ |
| TC-D02 | Delete channel used by provider — provider still exists | Provider.channel_id still set (FK restraint, channel may be soft-deleted) | — | — | ⬜ |
| TC-D03 | Create notification channel with provider — verify provider used in dispatch | Provider referenced in notification channels | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | Form Request — `ProviderMasterRequest` authorize() | POST checks tenant.provider-master.create; PUT/PATCH checks tenant.provider-master.update | — | — | ◌ |
| TC-CR02 | Form Request — `ProviderMasterRequest` rules() | All 10 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR03 | SafeEncrypted cast on api_key_encrypted and api_secret_encrypted | Values encrypted in DB, decrypted on read | — | — | ◌ |
| TC-CR04 | Configuration cast to array | JSON column stored as string in DB, returned as array by Eloquent | — | — | ◌ |
| TC-CR05 | Provider types constant | `ProviderMaster::PROVIDER_TYPES` returns ['PRIMARY','SECONDARY','BACKUP'] | — | — | ◌ |
| TC-CR06 | Scopes — active(), byChannel(), primary(), byPriority() | All scopes defined and functional | — | — | ◌ |
| TC-CR07 | Missing activityLog() calls | NOTE: ProviderMasterController does NOT call activityLog() — no audit trail for CRUD operations | — | — | ◌ |
| TC-CR08 | toggleStatus() validates is_active boolean | Request validated with `required|boolean` | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Providers page loads with all UI elements
1. Login as admin user with `tenant.provider-master.viewAny` permission
2. Navigate to `GET /provider-master` or via `GET /notification-mgt?tab=providers`
3. Verify page loads without errors (200 OK)
4. Verify search bar is displayed
5. Verify channel filter dropdown is displayed (populated from active channels)
6. Verify provider_type filter dropdown is displayed (PRIMARY/SECONDARY/BACKUP)
7. Verify status filter dropdown is displayed (All/Active/Inactive)
8. Verify "Add Provider" button is displayed
9. Verify providers grid/table is displayed with headers (Name, Channel, Type, Priority, From Address, Status, Actions)
10. Verify pagination controls are displayed

#### TC-P02: Search providers by provider_name
1. Ensure at least 2 providers exist with different names
2. Enter a search term matching one provider's name
3. Click Search
4. Verify grid shows only matching provider
5. Verify non-matching providers are not displayed

#### TC-P03: Search providers by from_address
1. Ensure at least 2 providers exist with different from_address values
2. Enter a search term matching one provider's from_address
3. Click Search
4. Verify grid shows only matching provider(s)

#### TC-P04: Filter by channel_id
1. Ensure providers exist for at least 2 different channels
2. Select a specific channel from channel filter
3. Verify grid shows only providers for that channel

#### TC-P05 through TC-P09: (Similar step pattern — follow TC ID description.)

#### TC-P10: Create provider with all required fields
1. Click "Add Provider"
2. Select a channel_id from dropdown
3. Enter provider_name="Test SMS Provider"
4. Select provider_type="PRIMARY"
5. Submit the form
6. Verify 302 redirect with success message
7. Verify provider appears in the grid

#### TC-P11: Create provider with valid api_endpoint
1. Click "Add Provider"
2. Fill required fields (channel_id, provider_name, provider_type)
3. Set api_endpoint = "https://api.smsprovider.com/v1/send"
4. Submit the form
5. Verify api_endpoint saved correctly

#### TC-P12: Create provider with API credentials
1. Click "Add Provider"
2. Fill required fields
3. Set api_key_encrypted = "test-api-key-12345"
4. Set api_secret_encrypted = "test-api-secret-67890"
5. Submit the form
6. Verify credentials saved (encrypted in DB)

#### TC-P13: Create provider with configuration
1. Click "Add Provider"
2. Fill required fields
3. Set configuration with valid JSON/array data (e.g., {"sender_id": "TESTSMS", "route": "transactional"})
4. Submit the form
5. Verify configuration saved as JSON, accessible as array on read

#### TC-P14: Create provider with priority=1
1. Click "Add Provider"
2. Fill required fields
3. Set priority = 1
4. Submit the form
5. Verify priority = 1

#### TC-P15 through TC-P30: (Similar step pattern — follow TC ID description.)

### 7.2 Negative TC Steps

#### TC-N01: Required — missing `channel_id`
1. Click "Add Provider"
2. Leave channel_id unselected
3. Fill remaining required fields
4. Submit the form
5. Verify 422 validation error for channel_id
6. Verify provider not created

#### TC-N02 through TC-N17: (Similar step pattern — follow TC ID description.)

### 7.3 Dependency TC Steps

#### TC-D01: Create provider with channel — verify relationship
1. Create a channel (e.g., code="SMS_CH", name="SMS Channel")
2. Create a provider with channel_id = created channel's id
3. View provider show page
4. Verify channel name/type displayed

#### TC-D02: Delete channel used by provider
1. Create a channel, create a provider referencing it
2. Delete the channel (soft delete)
3. View the provider
4. Verify channel_id is still set (FK not set to null on soft delete of parent)

#### TC-D03: Provider used in notification channel
1. Create a provider
2. Create a notification with channels array referencing the provider
3. Verify NotificationChannel record created with provider_id

### 7.4 Code Review TC Steps

#### TC-CR01: ProviderMasterRequest authorize()
1. Review `ProviderMasterRequest::authorize()` (line 9-15)
2. Verify POST method checks `tenant.provider-master.create`
3. Verify PUT/PATCH methods check `tenant.provider-master.update`
4. Verify no authorization on GET (authorization at controller level)

#### TC-CR02: ProviderMasterRequest rules()
1. Review `ProviderMasterRequest::rules()` (lines 17-33)
2. Verify all 10 rules are present
3. Verify channel_id has exists:ntf_channel_master,id
4. Verify provider_type has in:PRIMARY,SECONDARY,BACKUP
5. Verify api_endpoint has url validation
6. Verify priority has min:1 and max:10

#### TC-CR03: SafeEncrypted cast
1. Review `ProviderMaster::$casts` (lines 28-36)
2. Verify `api_key_encrypted` uses `\App\Casts\SafeEncrypted::class`
3. Verify `api_secret_encrypted` uses `\App\Casts\SafeEncrypted::class`
4. Verify encrypted values are not human-readable in database

#### TC-CR04: Configuration cast
1. Review `ProviderMaster::$casts` line 31
2. Verify `configuration` is cast to `array`
3. Verify stored as JSON in database, returned as array via Eloquent

#### TC-CR05: PROVIDER_TYPES constant
1. Review `ProviderMaster::PROVIDER_TYPES` (lines 38-42)
2. Verify it returns ['PRIMARY' => 'PRIMARY', 'SECONDARY' => 'SECONDARY', 'BACKUP' => 'BACKUP']

#### TC-CR06: Scopes
1. Review `ProviderMaster` scopes (lines 49-67)
2. Verify `scopeActive()` filters by is_active = true
3. Verify `scopeByChannel($channelId)` filters by channel_id
4. Verify `scopePrimary()` filters by provider_type = 'PRIMARY'
5. Verify `scopeByPriority()` orders by priority asc

#### TC-CR07: Missing activityLog() calls
1. Review entire `ProviderMasterController`
2. NOTE: No activityLog() calls found in any method (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete, toggleStatus)
3. Compare with ChannelMasterController which has activityLog() in destroy, restore, forceDelete, toggleStatus
4. This is a potential gap — no audit trail for provider CRUD operations

#### TC-CR08: toggleStatus() validation
1. Review `ProviderMasterController@toggleStatus()` (lines 204-218)
2. Verify `$request->validate(['is_active' => 'required|boolean'])`
3. Verify toggle returns JSON with success, is_active, message
