# ntf_UserPreferences_TcList

## Module: Notification → Notification Management → User Preferences

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | User Preferences |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /user-preferences` (index), `POST /user-preferences` (store), `GET /user-preferences/create` (create), `GET /user-preferences/{user_preference}` (show), `GET /user-preferences/{user_preference}/edit` (edit), `PUT /user-preferences/{user_preference}` (update), `DELETE /user-preferences/{user_preference}` (destroy), `POST /user-preferences/{user_preference}/toggle-status` (toggleStatus), `POST /user-preferences/{user_preference}/toggle-enabled` (toggleEnabled), `GET /user-preferences/trash/view` (trashed), `GET /user-preferences/{id}/restore` (restore), `DELETE /user-preferences/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\UserPreferenceController` |
| Model(s) | `Modules\Notification\Models\UserPreference` (table: `ntf_user_preferences`) |
| Validation | `Modules\Notification\Http\Requests\UserPreferenceRequest` |
| Permissions | `tenant.user-preference.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | 10 records per page (`UserPreferenceController@index` line 213 — `$preferences = $prefQuery->latest()->paginate(10)`) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` moves to trash |
| Activity Log | Not explicitly logged in `UserPreferenceController` (no `activityLog()` calls observed) |

---

## 2. Pre-conditions

- Required permissions: `tenant.user-preference.viewAny` for index, `tenant.user-preference.create` for store, `tenant.user-preference.view` for show, `tenant.user-preference.update` for update/toggleStatus/toggleEnabled, `tenant.user-preference.delete` for destroy, `tenant.user-preference.restore` for restore/trashed, `tenant.user-preference.forceDelete` for forceDelete
- Seed data required: At least one `sys_users` record for `user_id`, one `ntf_channel_master` record for `channel_id`, optionally `sys_dropdown_table` entry for `priority_threshold_id`
- Test user must have `tenant.user-preference.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For opt-in/out tests: Understand the GDPR opt-in/out timestamp management logic

---

## 3. Default Data Load

When the page loads via `UserPreferenceController@index()` (or via tab), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| User Preferences | `UserPreferenceController@index()` lines 167-213 | `UserPreference::with(['user','channel','priorityThreshold'])` | search (user.name/email, channel.name/code), user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours (yes/no), status (is_active) | 10/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','tenant','creator','approver','template'])->latest()` | — | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with(['channel','creator','tenant'])->latest()` | search, channel_id, approval_status, language_code, tenant_id, status | 15/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |
| Targets | Side-loaded | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search, notification_id, target_type_id, has_group, status | 10/page |

---

## 4. Test Data Strategy

- **Unique constraint**: `UNIQUE(user_id, channel_id)` — each user can have only one preference per channel — test with duplicate combinations
- **Quiet hours**: Test quiet_hours_start/end with time format `H:i`, including overnight (start > end)
- **Opt-in/out timestamps**: `opted_in_at` set on create when `is_opted_in=true`; `opted_out_at` set on update when switching from opted_in to opted_out
- **Pre-test cleanup**: Delete created preferences before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **toggleEnabled**: Flips `is_enabled` boolean independently from `is_active`
- **Business rules**: BR-NTF-002 (opt-out absolute), BR-NTF-003 (quiet hours defer not cancel)

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_user_preferences`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | user_id | BIGINT UNSIGNED | FK → sys_users.id, NOT NULL |
| BC-DB-03 | channel_id | BIGINT UNSIGNED | FK → ntf_channel_master.id, NOT NULL, UNIQUE(user_id, channel_id) |
| BC-DB-04 | is_enabled | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-05 | is_opted_in | TINYINT(1) | NOT NULL DEFAULT 0 (GDPR) |
| BC-DB-06 | opted_in_at | DATETIME | NULLABLE |
| BC-DB-07 | opted_out_at | DATETIME | NULLABLE |
| BC-DB-08 | contact_value | VARCHAR(255) | NULLABLE |
| BC-DB-09 | quiet_hours_start | TIME | NULLABLE |
| BC-DB-10 | quiet_hours_end | TIME | NULLABLE |
| BC-DB-11 | quiet_hours_timezone | VARCHAR(50) | NOT NULL DEFAULT 'UTC' |
| BC-DB-12 | daily_digest | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-13 | digest_time | TIME | NULLABLE |
| BC-DB-14 | priority_threshold_id | INT | FK → sys_dropdown_table.id, NULLABLE |
| BC-DB-15 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-16 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-17 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-18 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `UserPreferenceRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | user_id | required, integer, exists:sys_users,id | "The user id field is required." |
| BC-VAL-02 | channel_id | required, integer, exists:ntf_channel_master,id, unique:ntf_user_preferences per (user_id, channel_id) | "The combination of user and channel already exists." |
| BC-VAL-03 | is_enabled | nullable, boolean | — |
| BC-VAL-04 | is_opted_in | nullable, boolean | — |
| BC-VAL-05 | contact_value | nullable, string, max:255 | — |
| BC-VAL-06 | quiet_hours_start | nullable, date_format:H:i | — |
| BC-VAL-07 | quiet_hours_end | nullable, date_format:H:i, after:quiet_hours_start | "The quiet hours end must be a time after quiet hours start." |
| BC-VAL-08 | quiet_hours_timezone | nullable, string, max:50 | — |
| BC-VAL-09 | daily_digest | nullable, boolean | — |
| BC-VAL-10 | digest_time | nullable, date_format:H:i | — |
| BC-VAL-11 | priority_threshold_id | nullable, integer, exists:sys_dropdown_table,id | — |
| BC-VAL-12 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.user-preference.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.user-preference.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.user-preference.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.user-preference.update` | edit, update, toggleStatus, toggleEnabled — without → 403 |
| BC-AUTH-05 | `tenant.user-preference.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.user-preference.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.user-preference.forceDelete` | forceDelete — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with user preferences tab | Paginated grid at 10 records/page, ordered by latest, with user/channel/priorityThreshold relationships loaded |
| BC-BIZ-02 | Search by user name or email | Filters preferences where related user.name or user.email contains search term |
| BC-BIZ-03 | Search by channel name or code | Filters preferences where related channel.name or channel.code contains search term |
| BC-BIZ-04 | Filter by user_id | Exact match on user_id |
| BC-BIZ-05 | Filter by channel_id | Exact match on channel_id |
| BC-BIZ-06 | Filter by is_enabled | Filters preferences by is_enabled (0 or 1) |
| BC-BIZ-07 | Filter by is_opted_in | Filters preferences by is_opted_in (0 or 1) |
| BC-BIZ-08 | Filter by daily_digest | Filters preferences by daily_digest (0 or 1) |
| BC-BIZ-09 | Filter has_quiet_hours = yes | Filters where quiet_hours_start is NOT NULL |
| BC-BIZ-10 | Filter has_quiet_hours = no | Filters where quiet_hours_start is NULL |
| BC-BIZ-11 | Filter by status | Filters by is_active (0 or 1) |
| BC-BIZ-12 | Create preference with is_opted_in=true | opted_in_at timestamp set to now() |
| BC-BIZ-13 | Create preference with is_opted_in=false | opted_in_at remains null |
| BC-BIZ-14 | Update preference — opt in from out | opted_in_at set, opted_out_at cleared |
| BC-BIZ-15 | Update preference — opt out from in | opted_out_at set, opted_in_at preserved |
| BC-BIZ-16 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-17 | Toggle enabled via toggleEnabled | AJAX flips is_enabled, returns JSON with "enabled"/"disabled" message |
| BC-BIZ-18 | BR-NTF-002: Opt-out absolute | When opted out, user should not receive notifications even if is_enabled=true |
| BC-BIZ-19 | BR-NTF-003: Quiet hours defer not cancel | Notifications during quiet hours are deferred (queued), not cancelled |
| BC-BIZ-20 | UNIQUE constraint on (user_id, channel_id) | Cannot create duplicate preference for same user+channel |
| BC-BIZ-21 | Soft delete | Preference moved to trash |
| BC-BIZ-22 | Restore from trash | Preference restored |
| BC-BIZ-23 | Force delete from trash | Permanently removed |
| BC-BIZ-24 | Empty state — no preferences | Grid shows empty state |
| BC-BIZ-25 | Pagination — first page 10 records | Page 1 shows up to 10 |
| BC-BIZ-26 | Pagination — second page | Page 2 shows remaining |
| BC-BIZ-27 | Show page with relationships | User, channel, priorityThreshold loaded and displayed |
| BC-BIZ-28 | quiet_hours_end must be after quiet_hours_start | Validation rule `after:quiet_hours_start` (Note: this fails for overnight quiet hours like 22:00→06:00 — workaround needed in code) |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | user_id | sys_users (id) | CASCADE |
| BC-REF-02 | channel_id | ntf_channel_master (id) | CASCADE |
| BC-REF-03 | priority_threshold_id | sys_dropdown_table (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | User Preferences page loads with UI elements | Page loads with search bar, filters, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by user name | Grid filtered to matching user | — | — | ⬜ |
| TC-P03 | Search by user email | Grid filtered to matching email | — | — | ⬜ |
| TC-P04 | Search by channel name | Grid filtered to matching channel | — | — | ⬜ |
| TC-P05 | Search by channel code | Grid filtered to matching channel code | — | — | ⬜ |
| TC-P06 | Filter by user_id | Grid shows preferences for selected user | — | — | ⬜ |
| TC-P07 | Filter by channel_id | Grid shows preferences for selected channel | — | — | ⬜ |
| TC-P08 | Filter by is_enabled | Grid filtered by enabled status | — | — | ⬜ |
| TC-P09 | Filter by is_opted_in | Grid filtered by opt-in status | — | — | ⬜ |
| TC-P10 | Filter by daily_digest | Grid filtered by daily digest setting | — | — | ⬜ |
| TC-P11 | Filter has_quiet_hours = yes | Grid shows only preferences with quiet hours set | — | — | ⬜ |
| TC-P12 | Filter has_quiet_hours = no | Grid shows only preferences without quiet hours | — | — | ⬜ |
| TC-P13 | Filter by active status | Grid shows only active preferences | — | — | ⬜ |
| TC-P14 | Filter by inactive status | Grid shows only inactive preferences | — | — | ⬜ |
| TC-P15 | Create preference — full data with opt-in | Preference created with opted_in_at timestamp | — | — | ⬜ |
| TC-P16 | Create preference — opt-out state | Preference created without opt-in timestamp | — | — | ⬜ |
| TC-P17 | Create preference with quiet hours | Quiet hours saved correctly | — | — | ⬜ |
| TC-P18 | Create preference with daily_digest and digest_time | Digest settings saved | — | — | ⬜ |
| TC-P19 | Create preference with priority_threshold_id | Priority threshold linked | — | — | ⬜ |
| TC-P20 | Edit preference loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P21 | Update preference — opt from false to true | opted_in_at set, opted_out_at cleared | — | — | ⬜ |
| TC-P22 | Update preference — opt from true to false | opted_out_at set | — | — | ⬜ |
| TC-P23 | View show page with relationships | User, channel, priorityThreshold displayed | — | — | ⬜ |
| TC-P24 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P25 | toggleEnabled — enable | AJAX flips is_enabled to true | — | — | ⬜ |
| TC-P26 | toggleEnabled — disable | AJAX flips is_enabled to false | — | — | ⬜ |
| TC-P27 | Soft delete preference | Preference moved to trash | — | — | ⬜ |
| TC-P28 | View trashed preferences | Trash page lists soft-deleted records with user and channel | — | — | ⬜ |
| TC-P29 | Restore trashed preference | Preference restored | — | — | ⬜ |
| TC-P30 | Force delete from trash | Permanently removed | — | — | ⬜ |
| TC-P31 | Full lifecycle: create→edit→toggle→delete→restore→forceDelete | All transitions succeed | — | — | ⬜ |
| TC-P32 | Pagination — first page 10 records | Page 1 shows up to 10 | — | — | ⬜ |
| TC-P33 | Pagination — second page | Page 2 shows 11+ | — | — | ⬜ |
| TC-P34 | Empty state — no preferences | Grid shows empty state | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `user_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `channel_id` | Validation error | — | — | ⬜ |
| TC-N03 | Invalid user_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N04 | Invalid channel_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N05 | Duplicate (user_id, channel_id) within same tenant | "The combination of user and channel already exists." | — | — | ⬜ |
| TC-N06 | Invalid quiet_hours_start format (not H:i) | Validation error on date_format | — | — | ⬜ |
| TC-N07 | quiet_hours_end before quiet_hours_start | Validation error on after | — | — | ⬜ |
| TC-N08 | Invalid digest_time format | Validation error on date_format | — | — | ⬜ |
| TC-N09 | contact_value > 255 chars | Validation error on max:255 | — | — | ⬜ |
| TC-N10 | Invalid priority_threshold_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N11 | View non-existent preference (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Edit non-existent preference (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Update non-existent preference (404) | 404 Not Found | — | — | ⬜ |
| TC-N14 | Delete non-existent preference (404) | 404 Not Found | — | — | ⬜ |
| TC-N15 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N16 | toggleStatus with missing is_active | 422 validation error | — | — | ⬜ |
| TC-N17 | toggleEnabled with missing is_enabled | 422 validation error | — | — | ⬜ |
| TC-N18 | quiet_hours_timezone > 50 chars | Validation error on max:50 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create preference for user — verify relationship | User relationship works | — | — | ⬜ |
| TC-D02 | Delete user with preferences — CASCADE | Preferences deleted when user deleted | — | — | ⬜ |
| TC-D03 | Create preference for channel — verify relationship | Channel relationship works | — | — | ⬜ |
| TC-D04 | Delete channel with preferences — CASCADE | Preferences deleted when channel deleted | — | — | ⬜ |
| TC-D05 | Create resolved recipient with user_preference_id | Preference referenced from resolved recipient | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `UserPreferenceRequest` rules | All 12 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | Opt-in timestamp on create | `opted_in_at = now()` set when `is_opted_in` is true | — | — | ◌ |
| TC-CR03 | Opt-in/out timestamp management on update | `opted_in_at` and `opted_out_at` managed correctly based on opt-in toggle | — | — | ◌ |
| TC-CR04 | toggleEnabled flips is_enabled | `$preference->is_enabled = $request->is_enabled` | — | — | ◌ |
| TC-CR05 | UNIQUE constraint handling | `Rule::unique('ntf_user_preferences')->where('user_id', ...)->ignore($id)` | — | — | ◌ |
| TC-CR06 | Search across related models | `whereHas('user')` + `orWhereHas('channel')` for search | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: User Preferences page loads
1. Login as admin user with `tenant.user-preference.viewAny` permission
2. Navigate to `GET /user-preferences`
3. Verify page loads (200 OK)
4. Verify search bar, filters (user, channel, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status), Add button, grid

#### TC-P02 through TC-P05: Search tests
1. Ensure preferences exist for different users and channels
2. Enter search terms matching user name, email, channel name, channel code
3. Verify grid filtered appropriately

#### TC-P06 through TC-P14: Filter tests
1. Apply each filter (user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status)
2. Verify grid shows only matching records

#### TC-P15: Create preference with opt-in
1. Click "Add User Preference"
2. Select user and channel
3. Set is_enabled=true, is_opted_in=true
4. Submit
5. Verify created with opted_in_at timestamp set
6. Verify success message "User preference created successfully"

#### TC-P16: Create preference opt-out state
1. Create preference with is_opted_in=false
2. Verify opted_in_at is null

#### TC-P17: Create with quiet hours
1. Set quiet_hours_start=22:00, quiet_hours_end=06:00, quiet_hours_timezone=Asia/Kolkata
2. Submit
3. Verify quiet hours saved correctly

#### TC-P18: Create with daily_digest
1. Set daily_digest=true, digest_time=08:00
2. Submit
3. Verify digest settings saved

#### TC-P19: Create with priority_threshold_id
1. Select a priority threshold from dropdown
2. Submit
3. Verify priority_threshold_id linked

#### TC-P20: Edit loads pre-filled data
1. Edit an existing preference
2. Verify all fields show current values

#### TC-P21: Opt from false to true on update
1. Preference with is_opted_in=false
2. Update to is_opted_in=true
3. Verify opted_in_at = now(), opted_out_at = null

#### TC-P22: Opt from true to false on update
1. Preference with is_opted_in=true
2. Update to is_opted_in=false
3. Verify opted_out_at = now()

#### TC-P23: Show page with relationships
1. Click View on a preference
2. Verify user name, channel name, priority threshold displayed

#### TC-P24: Toggle status
1. POST to `/user-preferences/{preference}/toggle-status` with `{"is_active": false}`
2. Verify JSON success, is_active flipped

#### TC-P25: toggleEnabled — enable
1. POST to `/user-preferences/{preference}/toggle-enabled` with `{"is_enabled": true}`
2. Verify JSON: `{"is_enabled": true, "message": "Channel enabled successfully"}`

#### TC-P26: toggleEnabled — disable
1. POST with `{"is_enabled": false}`
2. Verify JSON: `{"is_enabled": false, "message": "Channel disabled successfully"}`

#### TC-P27 through TC-P30: Soft delete, trash view, restore, force delete
1. Follow standard CRUD pattern as in other features

#### TC-P31: Full lifecycle
1. Create → verify
2. Edit → verify
3. Toggle status and enabled → verify
4. Soft delete → verify in trash
5. Restore → verify in index
6. Force delete → verify removed

#### TC-P32 through TC-P34: Pagination and empty state
1. Standard pagination and empty state tests

### 7.2 Negative TC Steps

#### TC-N01: Missing user_id
1. Leave user_id empty, submit
2. Verify 422 validation error

#### TC-N02: Missing channel_id
1. Leave channel_id empty, submit
2. Verify 422 validation error

#### TC-N03 through TC-N04: Invalid FK values
1. Enter non-existent user_id or channel_id
2. Verify 422 on exists validation

#### TC-N05: Duplicate (user_id, channel_id)
1. Create preference for user=1, channel=1
2. Try to create another preference for same user=1, channel=1
3. Verify 422 unique validation error

#### TC-N06: Invalid quiet_hours_start format
1. Enter quiet_hours_start="25:00"
2. Verify date_format:H:i validation error

#### TC-N07: quiet_hours_end before start
1. Set start=14:00, end=13:00
2. Verify `after:quiet_hours_start` validation error

#### TC-N08 through TC-N10: Other validation errors
1. Test as per rules table

#### TC-N11 through TC-N15: 404 and 403
1. Test non-existent records and unauthorized access

#### TC-N16 through TC-N18: AJAX validation
1. Test toggle endpoints with missing or invalid parameters

### 7.3 Dependency TC Steps

#### TC-D01: Create preference for user
1. Create a user
2. Create preference referencing that user
3. Show preference — verify user relationship displayed

#### TC-D02: Delete user with preferences
1. Create user with preferences
2. Delete user
3. Verify preferences also deleted (CASCADE)

#### TC-D03: Create preference for channel
1. Create a channel
2. Create preference referencing that channel
3. Verify channel relationship displayed

#### TC-D04: Delete channel with preferences
1. Create channel with preferences
2. Delete channel
3. Verify preferences also deleted (CASCADE)

#### TC-D05: Resolved recipient referencing preference
1. Create a preference
2. Create resolved recipient with user_preference_id
3. Verify relationship works

### 7.4 Code Review TC Steps

#### TC-CR01: UserPreferenceRequest rules
1. Review `UserPreferenceRequest.php` rules()
2. Verify all 12 field rules
3. Verify unique constraint: `Rule::unique('ntf_user_preferences')->where('user_id', $this->user_id)->ignore($id)`

#### TC-CR02: Opt-in timestamp on create
1. Review store() lines 256-259
2. Verify `if ($data['is_opted_in'] ?? false) { $data['opted_in_at'] = now(); }`

#### TC-CR03: Opt-in/out on update
1. Review update() lines 296-303
2. Verify opt-in transition: `$data['opted_in_at'] = now(); $data['opted_out_at'] = null;`
3. Verify opt-out transition: `$data['opted_out_at'] = now();`

#### TC-CR04: toggleEnabled
1. Review toggleEnabled() lines 369-383
2. Verify `$preference->is_enabled = $request->is_enabled; $preference->save();`
3. Verify JSON response includes enabled/disabled message

#### TC-CR05: UNIQUE constraint
1. Review UserPreferenceRequest.php line 28
2. Verify `Rule::unique('ntf_user_preferences')->where('user_id', $this->user_id)->ignore($id)`

#### TC-CR06: Cross-model search
1. Review index() lines 169-179
2. Verify `whereHas('user')` for name/email search
3. Verify `orWhereHas('channel')` for name/code search
