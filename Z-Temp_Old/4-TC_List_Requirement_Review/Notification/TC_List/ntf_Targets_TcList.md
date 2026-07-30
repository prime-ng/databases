# ntf_Targets_TcList

## Module: Notification → Notification Management → Notification Targets

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Notification Targets |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /notification-targets` (index), `POST /notification-targets` (store), `GET /notification-targets/create` (create), `GET /notification-targets/{notification_target}` (show), `GET /notification-targets/{notification_target}/edit` (edit), `PUT /notification-targets/{notification_target}` (update), `DELETE /notification-targets/{notification_target}` (destroy), `POST /notification-targets/{notification_target}/toggle-status` (toggleStatus), `POST /notification-targets/{id}/resolve` (resolveTargets), `GET /notification-targets/trash/view` (trashed), `GET /notification-targets/{id}/restore` (restore), `DELETE /notification-targets/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\NotificationTargetController` |
| Model(s) | `Modules\Notification\Models\NotificationTarget` (table: `ntf_notification_targets`) |
| Validation | `Modules\Notification\Http\Requests\NotificationTargetRequest` |
| Permissions | `tenant.notification-target.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | 10 records per page (`NotificationTargetController@index` line 133 — `$targetQuery->latest()->paginate(10)`) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` moves to trash |
| Activity Log | Not explicitly logged in `NotificationTargetController` (no `activityLog()` calls observed) |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification-target.viewAny` for index, `tenant.notification-target.create` for store, `tenant.notification-target.view` for show, `tenant.notification-target.update` for update/toggleStatus/resolveTargets, `tenant.notification-target.delete` for destroy, `tenant.notification-target.restore` for restore/trashed, `tenant.notification-target.forceDelete` for forceDelete
- Seed data required: At least one `ntf_notifications` record, `sys_dropdown_table` entry for `target_type_id`, optional `ntf_target_groups` record for `target_group_id`
- Test user must have `tenant.notification-target.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For resolveTargets test: a notification target with target_condition or target_table_name must exist

---

## 3. Default Data Load

When the page loads via `NotificationTargetController@index()` (or via tab), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Notification Targets | `NotificationTargetController@index()` lines 101-133 | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search (notification.subject, targetGroup.group_name), notification_id, target_type_id, has_group (yes/no), status (is_active) | 10/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','creator'])->latest()` | — | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with('channel')->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |

---

## 4. Test Data Strategy

- **Notification dependency**: Each target must reference an existing notification via `notification_id` — create test notifications first
- **Target type dependency**: `target_type_id` references `sys_dropdown_table` — pre-seed required test types
- **Group linkage**: `target_group_id` is optional — test both with and without group association
- **has_group filter**: Test the `yes` (not null) and `no` (null) filter values
- **Target condition**: `target_condition` is a JSON array — test with complex condition structures
- **Pre-test cleanup**: Delete created targets before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **resolveTargets**: AJAX endpoint that computes `actual_count` based on conditions — test with mock conditions

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_notification_targets`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | notification_id | BIGINT UNSIGNED | FK → ntf_notifications.id, NOT NULL |
| BC-DB-03 | target_type_id | BIGINT UNSIGNED | FK → sys_dropdown_table.id, NOT NULL |
| BC-DB-04 | target_group_id | BIGINT UNSIGNED | FK → ntf_target_groups.id, NULLABLE |
| BC-DB-05 | target_table_name | VARCHAR(60) | NULLABLE |
| BC-DB-06 | target_selected_id | INT | NULLABLE |
| BC-DB-07 | target_condition | JSON | NULLABLE |
| BC-DB-08 | estimated_count | INT | NULLABLE, DEFAULT 0 |
| BC-DB-09 | actual_count | INT | NULLABLE, DEFAULT 0 |
| BC-DB-10 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-11 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-12 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-13 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `NotificationTargetRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | notification_id | required, integer, exists:ntf_notifications,id | "The notification field is required." |
| BC-VAL-02 | target_type_id | required, integer, exists:sys_dropdown_table,id | "The target type field is required." |
| BC-VAL-03 | target_group_id | nullable, integer, exists:ntf_target_groups,id | — |
| BC-VAL-04 | target_table_name | nullable, string, max:60 | — |
| BC-VAL-05 | target_selected_id | nullable, integer | — |
| BC-VAL-06 | target_condition | nullable, array | — |
| BC-VAL-07 | estimated_count | nullable, integer, min:0 | — |
| BC-VAL-08 | actual_count | nullable, integer, min:0 | — |
| BC-VAL-09 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification-target.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.notification-target.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.notification-target.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification-target.update` | edit, update, toggleStatus, resolveTargets — without → 403 |
| BC-AUTH-05 | `tenant.notification-target.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.notification-target.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.notification-target.forceDelete` | forceDelete — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with notification targets tab | Paginated grid at 10 records/page, ordered by latest, with notification/targetType/targetGroup relationships loaded |
| BC-BIZ-02 | Search by notification subject | Filters targets where related notification.subject contains search term |
| BC-BIZ-03 | Search by target group name | Filters targets where related targetGroup.group_name contains search term |
| BC-BIZ-04 | Filter by notification_id | Exact match on notification_id |
| BC-BIZ-05 | Filter by target_type_id | Exact match on target_type_id |
| BC-BIZ-06 | Filter has_group = yes | Filters targets where target_group_id is NOT NULL |
| BC-BIZ-07 | Filter has_group = no | Filters targets where target_group_id is NULL |
| BC-BIZ-08 | Filter by status | Filters targets by is_active (0 or 1) |
| BC-BIZ-09 | Create with target_group_id | Target linked to group correctly |
| BC-BIZ-10 | Create without target_group_id | target_group_id remains null |
| BC-BIZ-11 | Create with target_condition (JSON) | Condition saved as JSON array |
| BC-BIZ-12 | estimated_count auto-calculated if not provided | `calculateEstimatedCount()` called with default return 100 |
| BC-BIZ-13 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-14 | resolveTargets AJAX | Computes actual_count, saves to DB, returns JSON with actual_count |
| BC-BIZ-15 | Soft delete target | Target moved to trash via `delete()` |
| BC-BIZ-16 | Restore trashed target | Target restored via `restore()` |
| BC-BIZ-17 | Force delete target | Target permanently removed |
| BC-BIZ-18 | Empty state — no targets | Grid shows empty state message |
| BC-BIZ-19 | Pagination — first page 10 records | Page 1 shows up to 10 targets |
| BC-BIZ-20 | Pagination — second page | Page 2 shows remaining records |
| BC-BIZ-21 | Show page with all relationships | Notification, targetType, targetGroup loaded and displayed |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | notification_id | ntf_notifications (id) | CASCADE |
| BC-REF-02 | target_type_id | sys_dropdown_table (id) | RESTRICT |
| BC-REF-03 | target_group_id | ntf_target_groups (id) | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Notification Targets page loads with all UI elements | Page loads with search bar, filters, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by notification subject | Grid filtered to matching subject | — | — | ⬜ |
| TC-P03 | Search by target group name | Grid filtered to matching group name | — | — | ⬜ |
| TC-P04 | Filter by notification_id | Grid shows targets for selected notification | — | — | ⬜ |
| TC-P05 | Filter by target_type_id | Grid shows targets of selected type | — | — | ⬜ |
| TC-P06 | Filter has_group = yes | Grid shows only targets with group assigned | — | — | ⬜ |
| TC-P07 | Filter has_group = no | Grid shows only targets without group assigned | — | — | ⬜ |
| TC-P08 | Filter by active status | Grid shows only active targets | — | — | ⬜ |
| TC-P09 | Filter by inactive status | Grid shows only inactive targets | — | — | ⬜ |
| TC-P10 | Create target with notification, type, and group | Target created with all FK relationships | — | — | ⬜ |
| TC-P11 | Create target without target_group_id | target_group_id is null | — | — | ⬜ |
| TC-P12 | Create target with target_condition JSON | Condition saved correctly | — | — | ⬜ |
| TC-P13 | Create target with estimated_count | estimated_count saved as provided | — | — | ⬜ |
| TC-P14 | Create target without estimated_count | Auto-calculated (default 100) | — | — | ⬜ |
| TC-P15 | Edit target loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P16 | Update target — change notification and type | Relationships updated | — | — | ⬜ |
| TC-P17 | View target show page | Show page renders with all relationships | — | — | ⬜ |
| TC-P18 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P19 | Toggle status inactive to active | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P20 | resolveTargets AJAX — compute actual_count | actual_count computed and saved, JSON returned | — | — | ⬜ |
| TC-P21 | Soft delete target | Target moved to trash | — | — | ⬜ |
| TC-P22 | View trashed targets | Trash page lists soft-deleted records with relationships | — | — | ⬜ |
| TC-P23 | Restore trashed target | Target restored | — | — | ⬜ |
| TC-P24 | Force delete target from trash | Target permanently removed | — | — | ⬜ |
| TC-P25 | Full lifecycle: create→edit→toggle→resolve→delete→restore→forceDelete | All transitions succeed | — | — | ⬜ |
| TC-P26 | Pagination — first page shows 10 records | Page 1 shows up to 10 targets | — | — | ⬜ |
| TC-P27 | Pagination — second page | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P28 | Empty state — no targets | Grid shows empty state | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `notification_id` | Validation error: "The notification field is required." | — | — | ⬜ |
| TC-N02 | Required — missing `target_type_id` | Validation error | — | — | ⬜ |
| TC-N03 | Invalid notification_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N04 | Invalid target_type_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N05 | Invalid target_group_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N06 | Max length — target_table_name > 60 chars | Validation error on max:60 | — | — | ⬜ |
| TC-N07 | estimated_count negative | Validation error on min:0 | — | — | ⬜ |
| TC-N08 | actual_count negative | Validation error on min:0 | — | — | ⬜ |
| TC-N09 | View non-existent target (404) | 404 Not Found | — | — | ⬜ |
| TC-N10 | Edit non-existent target (404) | 404 Not Found | — | — | ⬜ |
| TC-N11 | Update non-existent target (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Delete non-existent target (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N14 | resolveTargets on non-existent target | 404 Not Found | — | — | ⬜ |
| TC-N15 | toggleStatus with missing is_active | 422 validation error | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create target referencing notification — verify relationship | Target notification relationship works | — | — | ⬜ |
| TC-D02 | Delete notification used by target — CASCADE | Target is deleted when notification is deleted | — | — | ⬜ |
| TC-D03 | Create target with target group — verify relationship | Target group relationship works | — | — | ⬜ |
| TC-D04 | Delete target group referenced by target | target_group_id set to NULL (SET NULL) | — | — | ⬜ |
| TC-D05 | Create resolved recipient referencing target | Target referenced from resolved recipient flow | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `NotificationTargetRequest` rules | All 9 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | estimated_count auto-calculation in store() | `calculateEstimatedCount()` called when estimated_count empty | — | — | ◌ |
| TC-CR03 | resolveTargets updates actual_count | `$target->actual_count = $actualCount; $target->save();` | — | — | ◌ |
| TC-CR04 | Eager loading in index with 3 relationships | `NotificationTarget::with(['notification','targetType','targetGroup'])` | — | — | ◌ |
| TC-CR05 | has_group filter logic | Uses `whereNotNull` / `whereNull` on target_group_id | — | — | ◌ |
| TC-CR06 | Search across related models | `whereHas('notification')` + `orWhereHas('targetGroup')` | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Notification Targets page loads with all UI elements
1. Login as admin user with `tenant.notification-target.viewAny` permission
2. Navigate to `GET /notification-targets` or via `GET /notification-mgt?tab=targets`
3. Verify page loads without errors (200 OK)
4. Verify search bar is displayed
5. Verify notification_id filter dropdown is displayed
6. Verify target_type_id filter dropdown is displayed
7. Verify has_group filter dropdown is displayed (All/Yes/No)
8. Verify status filter dropdown is displayed (All/Active/Inactive)
9. Verify "Add Notification Target" button is displayed
10. Verify targets grid is displayed with headers (Notification, Type, Group, Est. Count, Actual Count, Status, Actions)

#### TC-P02: Search by notification subject
1. Ensure at least 2 targets referencing notifications with different subjects
2. Enter a search term matching one notification's subject
3. Click Search
4. Verify grid shows only target(s) with matching notification subject

#### TC-P03: Search by target group name
1. Ensure at least 2 targets referencing groups with different names
2. Enter a search term matching one group's name
3. Click Search
4. Verify grid shows only target(s) with matching group name

#### TC-P04: Filter by notification_id
1. Ensure targets exist for at least 2 different notifications
2. Select a specific notification from the notification_id filter
3. Click Search/Filter
4. Verify grid shows only targets for the selected notification

#### TC-P05: Filter by target_type_id
1. Ensure targets exist with at least 2 different target types
2. Select a specific target_type from the filter
3. Click Search/Filter
4. Verify grid shows only targets of the selected type

#### TC-P06: Filter has_group = yes
1. Ensure at least one target with group and one without
2. Select "Yes" from has_group filter
3. Click Search/Filter
4. Verify grid shows only targets where target_group_id is NOT NULL

#### TC-P07: Filter has_group = no
1. Select "No" from has_group filter
2. Click Search/Filter
3. Verify grid shows only targets where target_group_id is NULL

#### TC-P08: Filter by active status
1. Ensure at least one active and one inactive target exist
2. Select "Active" from status filter
3. Verify grid shows only active targets

#### TC-P09: Filter by inactive status
1. Select "Inactive" from status filter
2. Verify grid shows only inactive targets

#### TC-P10: Create target with notification, type, and group
1. Ensure a notification and a target group exist
2. Click "Add Notification Target"
3. Select notification from dropdown
4. Select target_type from dropdown
5. Select target_group from dropdown (optional)
6. Submit the form
7. Verify 302 redirect with success message "Notification target created successfully"
8. Verify target appears in the grid

#### TC-P11: Create target without target_group_id
1. Click "Add Notification Target"
2. Fill notification_id, target_type_id
3. Leave target_group_id empty
4. Submit
5. Verify target created with target_group_id = null

#### TC-P12: Create target with target_condition JSON
1. Click "Add Notification Target"
2. Enter target_condition as `[{"field": "class", "operator": "=", "value": "10"}]`
3. Submit
4. Verify target_condition saved as JSON array

#### TC-P13: Create target with estimated_count
1. Enter estimated_count = 250
2. Submit
3. Verify estimated_count = 250 in the grid

#### TC-P14: Create target without estimated_count
1. Leave estimated_count blank
2. Submit
3. Verify estimated_count is auto-calculated (default 100 in controller)

#### TC-P15: Edit target loads pre-filled data
1. Create a target with specific values
2. Click Edit on the target
3. Verify form shows existing values pre-filled

#### TC-P16: Update target
1. Edit a target
2. Change notification and type
3. Submit
4. Verify 302 redirect with success message
5. Verify updated values in grid

#### TC-P17: View target show page
1. Click View on a target
2. Verify show page renders with notification, targetType, targetGroup relationships
3. Verify all fields displayed

#### TC-P18: Toggle status active to inactive
1. POST to `/notification-targets/{target}/toggle-status` with `{"is_active": false}`
2. Verify JSON response with is_active=false
3. Verify grid reflects inactive

#### TC-P19: Toggle status inactive to active
1. POST with `{"is_active": true}`
2. Verify JSON response with is_active=true
3. Verify grid reflects active

#### TC-P20: resolveTargets AJAX
1. Create a target with some target condition
2. POST to `/notification-targets/{id}/resolve`
3. Verify JSON response: `{"success": true, "actual_count": <computed_value>, "message": "Target resolved successfully"}`
4. Verify actual_count is updated in DB

#### TC-P21: Soft delete target
1. Click Delete on a target
2. Verify target soft-deleted
3. Verify success message "Notification target moved to trash"

#### TC-P22: View trashed targets
1. Navigate to `/notification-targets/trash/view`
2. Verify trashed records displayed with notification and targetGroup relationships
3. Verify pagination

#### TC-P23: Restore trashed target
1. From trash view, click Restore
2. Verify redirect with success message
3. Verify target back in index

#### TC-P24: Force delete target from trash
1. From trash view, click Force Delete
2. Verify target permanently removed
3. Verify success message "Notification target permanently deleted"

#### TC-P25: Full lifecycle
1. Create target → verify in grid
2. Edit → verify updated
3. Toggle status → verify toggled
4. Resolve targets → verify actual_count
5. Soft delete → verify in trash
6. Restore → verify in index
7. Soft delete → force delete → verify removed

#### TC-P26 through TC-P28: Pagination and empty state
1. Create 15+ targets for pagination tests
2. Delete all for empty state test
3. Follow standard pagination/empty state steps

### 7.2 Negative TC Steps

#### TC-N01: Missing notification_id
1. Click "Add Notification Target"
2. Leave notification_id empty
3. Submit
4. Verify 422 error: "The notification field is required."

#### TC-N02: Missing target_type_id
1. Leave target_type_id empty
2. Submit
3. Verify 422 validation error

#### TC-N03: Invalid notification_id
1. Enter notification_id = 99999 (non-existent)
2. Submit
3. Verify 422 error on exists validation

#### TC-N04: Invalid target_type_id
1. Enter invalid target_type_id
2. Submit
3. Verify 422 error on exists

#### TC-N05: Invalid target_group_id
1. Enter non-existent target_group_id
2. Submit
3. Verify 422 error on exists

#### TC-N06: target_table_name > 60 chars
1. Enter target_table_name of 61 characters
2. Submit
3. Verify validation error on max:60

#### TC-N07: estimated_count negative
1. Enter estimated_count = -1
2. Submit
3. Verify validation error on min:0

#### TC-N08: actual_count negative
1. Enter actual_count = -1
2. Submit
3. Verify validation error on min:0

#### TC-N09 through TC-N12: 404 on non-existent records
1. Navigate to /edit, /show, PUT, DELETE with id=99999
2. Verify 404 Not Found

#### TC-N13: Unauthorized access
1. Login as user without `tenant.notification-target.viewAny`
2. Navigate to `/notification-targets`
3. Verify 403 Forbidden

#### TC-N14: resolveTargets on non-existent target
1. POST to `/notification-targets/99999/resolve`
2. Verify 404 Not Found

#### TC-N15: toggleStatus missing is_active
1. POST to toggle-status without is_active parameter
2. Verify 422 validation error

### 7.3 Dependency TC Steps

#### TC-D01: Create target referencing notification
1. Create a notification
2. Create a target referencing it
3. View target — verify notification subject displayed

#### TC-D02: Delete notification used by target
1. Create notification and target
2. Delete notification (force delete)
3. Verify target also deleted (CASCADE)

#### TC-D03: Create target with target group
1. Create a target group
2. Create a target with target_group_id
3. View target — verify group name displayed

#### TC-D04: Delete target group referenced by target
1. Create group and target referencing it
2. Delete the group
3. Verify target's target_group_id = NULL (SET NULL)

#### TC-D05: Resolved recipient referencing target
1. Create target
2. Create resolved recipient with notification_target_id
3. Verify relationship works end-to-end

### 7.4 Code Review TC Steps

#### TC-CR01: NotificationTargetRequest rules
1. Review `NotificationTargetRequest.php` rules() method
2. Verify all 9 field rules present
3. Verify exists rules for notification_id, target_type_id, target_group_id

#### TC-CR02: estimated_count auto-calculation
1. Review store() lines 169-172
2. Verify `if (empty($data['estimated_count']))` check
3. Verify `$this->calculateEstimatedCount($data)` called with default return 100

#### TC-CR03: resolveTargets actual_count update
1. Review resolveTargets() lines 270-287
2. Verify `$target->actual_count = $actualCount` and `$target->save()`
3. Verify `resolveActualCount()` private method logic

#### TC-CR04: Eager loading in index
1. Review index() line 101
2. Verify `NotificationTarget::with(['notification', 'targetType', 'targetGroup'])`

#### TC-CR05: has_group filter
1. Review index() lines 121-127
2. Verify `$request->has_group == 'yes'` uses `whereNotNull`
3. Verify `$request->has_group == 'no'` uses `whereNull`

#### TC-CR06: Cross-model search
1. Review index() lines 103-110
2. Verify `whereHas('notification')` for subject search
3. Verify `orWhereHas('targetGroup')` for group name search
