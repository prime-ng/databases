# ntf_TargetGroups_TcList

## Module: Notification → Notification Management → Target Groups

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Target Groups |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /target-groups` (index), `POST /target-groups` (store), `GET /target-groups/create` (create), `GET /target-groups/{group}` (show), `GET /target-groups/{group}/edit` (edit), `PUT /target-groups/{group}` (update), `DELETE /target-groups/{group}` (destroy), `POST /target-groups/{group}/toggle-status` (toggleStatus), `POST /target-groups/{id}/refresh-members` (refreshMembers), `GET /target-groups/trash/view` (trashed), `GET /target-groups/{id}/restore` (restore), `DELETE /target-groups/{id}/force-delete` (forceDelete) |
| Controller | `Modules\Notification\Http\Controllers\TargetGroupController` |
| Model(s) | `Modules\Notification\Models\TargetGroup` (table: `ntf_target_groups`) |
| Validation | `Modules\Notification\Http\Requests\TargetGroupRequest` |
| Permissions | `tenant.target-group.viewAny`, `.create`, `.view`, `.update`, `.delete`, `.restore`, `.forceDelete` |
| Pagination | 10 records per page (`TargetGroupController@index` line 97 — `$groupQuery->latest()->paginate(10)`) |
| Soft Deletes | Yes (SoftDeletes trait); `destroy()` moves to trash, `restore()` restores, `forceDelete()` permanently deletes |
| Activity Log | Not explicitly logged in `TargetGroupController` (no `activityLog()` calls observed) |

---

## 2. Pre-conditions

- Required permissions: `tenant.target-group.viewAny` for index, `tenant.target-group.create` for store, `tenant.target-group.view` for show, `tenant.target-group.update` for update/toggleStatus/refreshMembers, `tenant.target-group.delete` for destroy, `tenant.target-group.restore` for restore/trashed, `tenant.target-group.forceDelete` for forceDelete
- Seed data required: At least one `sys_users` record for `created_by` FK
- Test user must have `tenant.target-group.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For DYNAMIC group tests: valid `dynamic_query` value must be provided
- For system-group tests: a group with `is_system_group=1` must exist

---

## 3. Default Data Load

When the page loads via `TargetGroupController@index()` (or via tab), the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Target Groups | `TargetGroupController@index()` lines 75-97 | `TargetGroup::with('creator')` | search (group_name, group_code, description), group_type, system (is_system_group), status (is_active) | 10/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','creator'])->latest()` | — | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with('channel')->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |

---

## 4. Test Data Strategy

- **Code uniqueness**: `group_code` must be unique per tenant — suffix test data with timestamp or UUID (e.g., `GRP_TEACHERS_1712345678`)
- **Group types**: Test both `STATIC` and `DYNAMIC` group types
- **System groups**: `is_system_group=1` groups cannot be deleted — test the guard
- **Dynamic query**: `dynamic_query` required when `group_type=DYNAMIC`, not required for STATIC
- **Pre-test cleanup**: Delete created groups by `group_code` before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **refreshMembers**: Only DYNAMIC groups get `last_refreshed_at` updated (STATIC groups are not affected)
- **Created by**: `created_by` is set to `Auth::id()` on create

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_target_groups`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id, NULLABLE |
| BC-DB-03 | group_name | VARCHAR(100) | NOT NULL |
| BC-DB-04 | group_code | VARCHAR(50) | NOT NULL, UNIQUE(tenant_id, group_code) |
| BC-DB-05 | description | VARCHAR(255) | NULLABLE |
| BC-DB-06 | group_type | ENUM('STATIC','DYNAMIC') | NOT NULL, DEFAULT 'STATIC' |
| BC-DB-07 | dynamic_query | TEXT | NULLABLE, required_if:group_type,DYNAMIC |
| BC-DB-08 | total_members | INT | NOT NULL DEFAULT 0 |
| BC-DB-09 | last_refreshed_at | DATETIME | NULLABLE |
| BC-DB-10 | is_system_group | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-11 | created_by | INT | FK → sys_users.id, NULLABLE |
| BC-DB-12 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-13 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-14 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-15 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `TargetGroupRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | group_name | required, string, max:100 | "The group name field is required." |
| BC-VAL-02 | group_code | required, string, max:50, unique:ntf_target_groups per tenant (ignore current) | "The group code has already been taken." |
| BC-VAL-03 | description | nullable, string, max:255 | — |
| BC-VAL-04 | group_type | required, in:STATIC,DYNAMIC | "The selected group type is invalid." |
| BC-VAL-05 | dynamic_query | nullable, required_if:group_type,DYNAMIC, string | "The dynamic query field is required when group type is DYNAMIC." |
| BC-VAL-06 | total_members | nullable, integer, min:0 | — |
| BC-VAL-07 | last_refreshed_at | nullable, date | — |
| BC-VAL-08 | is_system_group | nullable, boolean | — |
| BC-VAL-09 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.target-group.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.target-group.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.target-group.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.target-group.update` | edit, update, toggleStatus, refreshMembers — without → 403 |
| BC-AUTH-05 | `tenant.target-group.delete` | destroy — without → 403 |
| BC-AUTH-06 | `tenant.target-group.restore` | trashed, restore — without → 403 |
| BC-AUTH-07 | `tenant.target-group.forceDelete` | forceDelete — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with target groups tab | Paginated grid at 10 records/page, ordered by latest, with creator relationship loaded |
| BC-BIZ-02 | Search by group_name | Filters groups where group_name contains search term |
| BC-BIZ-03 | Search by group_code | Filters groups where group_code contains search term |
| BC-BIZ-04 | Search by description | Filters groups where description contains search term |
| BC-BIZ-05 | Filter by group_type | Filters groups by group_type (STATIC or DYNAMIC) |
| BC-BIZ-06 | Filter by is_system_group | Filters groups where is_system_group = filter value (0 or 1) |
| BC-BIZ-07 | Filter by status | Filters groups by is_active (0 or 1) |
| BC-BIZ-08 | Group code uppercased on save | `strtoupper()` applied to group_code in store() and update() |
| BC-BIZ-09 | Create with STATIC type | `dynamic_query` can be null/empty |
| BC-BIZ-10 | Create with DYNAMIC type | `dynamic_query` is required, saved as-is |
| BC-BIZ-11 | tenant_id set on create | `$data['tenant_id'] = tenant()->id ?? null` |
| BC-BIZ-12 | created_by set on create | `$data['created_by'] = Auth::id()` |
| BC-BIZ-13 | Toggle status active→inactive | AJAX toggles is_active, returns JSON success |
| BC-BIZ-14 | Toggle status inactive→active | AJAX toggles is_active, returns JSON success |
| BC-BIZ-15 | refreshMembers on DYNAMIC group | Updates `last_refreshed_at` to now(), returns JSON success |
| BC-BIZ-16 | refreshMembers on STATIC group | Does NOT update `last_refreshed_at` — only for DYNAMIC groups (line 233 check) |
| BC-BIZ-17 | Soft delete group | Group moved to trash via `delete()`, shows in trashed() |
| BC-BIZ-18 | Restore trashed group | Group restored via `restore()`, redirected to trash index |
| BC-BIZ-19 | Force delete trashed group | Group permanently removed via `forceDelete()` |
| BC-BIZ-20 | Empty state — no groups | Grid shows "No Target Groups Found" or equivalent empty state |
| BC-BIZ-21 | Pagination — first page shows 10 records | Page 1 shows up to 10 groups |
| BC-BIZ-22 | Pagination — second page shows remaining records | Page 2 shows records 11+ |
| BC-BIZ-23 | Show page renders with creator relationship | `TargetGroup::with(['creator'])->findOrFail($id)` — creator data displayed |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | created_by | sys_users (id) | SET NULL |
| BC-REF-03 | id (self) | ntf_notification_targets.target_group_id | SET NULL |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Target Groups page loads with all UI elements | Page loads with search bar, group_type filter, system filter, status filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search target groups by group_name | Grid filtered to matching group_name only | — | — | ⬜ |
| TC-P03 | Search target groups by group_code | Grid filtered to matching group_code only | — | — | ⬜ |
| TC-P04 | Search target groups by description | Grid filtered to matching description only | — | — | ⬜ |
| TC-P05 | Filter by group_type = STATIC | Grid shows only STATIC groups | — | — | ⬜ |
| TC-P06 | Filter by group_type = DYNAMIC | Grid shows only DYNAMIC groups | — | — | ⬜ |
| TC-P07 | Filter by system group | Grid shows only system groups (is_system_group=1) | — | — | ⬜ |
| TC-P08 | Filter by custom group | Grid shows only custom groups (is_system_group=0) | — | — | ⬜ |
| TC-P09 | Filter by active status | Grid shows only active groups | — | — | ⬜ |
| TC-P10 | Filter by inactive status | Grid shows only inactive groups | — | — | ⬜ |
| TC-P11 | Create STATIC group with all required fields | Group created with correct values | — | — | ⬜ |
| TC-P12 | Create DYNAMIC group with dynamic_query | Group created with dynamic_query saved | — | — | ⬜ |
| TC-P13 | Group code auto-uppercased on create | Code stored in uppercase | — | — | ⬜ |
| TC-P14 | Edit group loads pre-filled data | Edit form shows all existing field values | — | — | ⬜ |
| TC-P15 | Update group name and description | Name and description updated | — | — | ⬜ |
| TC-P16 | View group show page | Show page renders with all fields and creator relationship | — | — | ⬜ |
| TC-P17 | Toggle status active to inactive | AJAX success, is_active flipped to false | — | — | ⬜ |
| TC-P18 | Toggle status inactive to active | AJAX success, is_active flipped to true | — | — | ⬜ |
| TC-P19 | refreshMembers on DYNAMIC group | `last_refreshed_at` updated to now | — | — | ⬜ |
| TC-P20 | refreshMembers on STATIC group (no-op) | `last_refreshed_at` unchanged, but JSON success returned | — | — | ⬜ |
| TC-P21 | Soft delete group | Group moved to trash | — | — | ⬜ |
| TC-P22 | View trashed groups | Trash page lists soft-deleted records | — | — | ⬜ |
| TC-P23 | Restore trashed group | Group restored | — | — | ⬜ |
| TC-P24 | Force delete group from trash | Group permanently removed | — | — | ⬜ |
| TC-P25 | Full lifecycle: create→edit→toggle→delete→trash→restore→forceDelete | All transitions succeed | — | — | ⬜ |
| TC-P26 | Pagination — first page shows 10 records | Page 1 shows up to 10 records | — | — | ⬜ |
| TC-P27 | Pagination — second page shows remaining records | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P28 | Empty state — no groups exist | Grid shows "No Target Groups Found" or equivalent | — | — | ⬜ |
| TC-P29 | Create group with total_members | total_members saved correctly | — | — | ⬜ |
| TC-P30 | Create group with full description (255 chars) | Description saved with full content | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `group_name` | Validation error: "The group name field is required." | — | — | ⬜ |
| TC-N02 | Required — missing `group_code` | Validation error: "The group code field is required." | — | — | ⬜ |
| TC-N03 | Required — missing `group_type` | Validation error: "The group type field is required." | — | — | ⬜ |
| TC-N04 | Duplicate group_code within tenant | "The group code has already been taken." | — | — | ⬜ |
| TC-N05 | Max length — group_name > 100 chars | Validation error on group_name.max | — | — | ⬜ |
| TC-N06 | Max length — group_code > 50 chars | Validation error on group_code.max | — | — | ⬜ |
| TC-N07 | Max length — description > 255 chars | Validation error on description.max | — | — | ⬜ |
| TC-N08 | Invalid group_type value | Validation error on group_type.in | — | — | ⬜ |
| TC-N09 | DYNAMIC group without dynamic_query | Validation error: "The dynamic query field is required when group type is DYNAMIC." | — | — | ⬜ |
| TC-N10 | total_members negative | Validation error on min:0 | — | — | ⬜ |
| TC-N11 | View non-existent group (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Edit non-existent group (404) | 404 Not Found | — | — | ⬜ |
| TC-N13 | Update non-existent group (404) | 404 Not Found | — | — | ⬜ |
| TC-N14 | Delete non-existent group (404) | 404 Not Found | — | — | ⬜ |
| TC-N15 | Duplicate group_code across tenants | Same code allowed in different tenants | — | — | ⬜ |
| TC-N16 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N17 | ToggleStatus with missing is_active param | Validation error: "The is active field is required." | — | — | ⬜ |
| TC-N18 | ToggleStatus with non-boolean is_active | Validation error: boolean required | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create notification target with target group | Target references group correctly | — | — | ⬜ |
| TC-D02 | Delete group referenced by notification target | target_group_id set to NULL (SET NULL) | — | — | ⬜ |
| TC-D03 | group_code unique per tenant — same code different tenant allowed | Second tenant can create same group_code | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `TargetGroupRequest` rules | All 9 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | Group code uppercased in store() and update() | `strtoupper()` applied before save | — | — | ◌ |
| TC-CR03 | refreshMembers only for DYNAMIC groups | `if ($group->group_type == 'DYNAMIC')` guard at line 233 | — | — | ◌ |
| TC-CR04 | `with('creator')` eager loaded in index, show | Creator relationship loaded to display created_by user | — | — | ◌ |
| TC-CR05 | tenant_id set on create | `$data['tenant_id'] = tenant()->id ?? null` at line 127 | — | — | ◌ |
| TC-CR06 | created_by set on create | `$data['created_by'] = Auth::id()` at line 126 | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Target Groups page loads with all UI elements
1. Login as admin user with `tenant.target-group.viewAny` permission
2. Navigate to `GET /target-groups` or via `GET /notification-mgt?tab=target-groups`
3. Verify page loads without errors (200 OK)
4. Verify search bar is displayed
5. Verify group_type filter dropdown is displayed (All/STATIC/DYNAMIC)
6. Verify system group filter dropdown is displayed (All/Yes/No)
7. Verify status filter dropdown is displayed (All/Active/Inactive)
8. Verify "Add Target Group" button is displayed
9. Verify groups grid/table is displayed with headers (Code, Name, Type, Members, System, Status, Actions)
10. Verify pagination controls are displayed

#### TC-P02: Search target groups by group_name
1. Ensure at least 2 groups exist with different names (e.g., "All Teachers", "All Students")
2. Enter a search term matching one group's name (e.g., "Teachers")
3. Click Search
4. Verify grid shows only matching group
5. Verify non-matching groups are not displayed

#### TC-P03: Search target groups by group_code
1. Ensure at least 2 groups exist with different codes (e.g., "GRP_TEACHERS", "GRP_STUDENTS")
2. Enter a search term matching one group's code (e.g., "TEACHERS")
3. Click Search
4. Verify grid shows only matching group(s)

#### TC-P04: Search target groups by description
1. Ensure at least 2 groups exist with different descriptions
2. Enter a search term matching one group's description
3. Click Search
4. Verify grid shows only matching group(s)

#### TC-P05: Filter by group_type = STATIC
1. Ensure at least one STATIC and one DYNAMIC group exist
2. Select "STATIC" from group_type filter dropdown
3. Click Search/Filter
4. Verify grid shows only STATIC groups

#### TC-P06: Filter by group_type = DYNAMIC
1. Ensure at least one STATIC and one DYNAMIC group exist
2. Select "DYNAMIC" from group_type filter dropdown
3. Click Search/Filter
4. Verify grid shows only DYNAMIC groups

#### TC-P07: Filter by system group
1. Ensure at least one system group (is_system_group=1) and one custom group exist
2. Select "Yes" from system filter dropdown
3. Click Search/Filter
4. Verify grid shows only system groups

#### TC-P08: Filter by custom group
1. Ensure at least one system group and one custom group exist
2. Select "No" from system filter dropdown
3. Click Search/Filter
4. Verify grid shows only custom groups

#### TC-P09: Filter by active status
1. Ensure at least one active and one inactive group exist
2. Select "Active" from status filter dropdown
3. Click Search/Filter
4. Verify grid shows only active groups (is_active=1)

#### TC-P10: Filter by inactive status
1. Ensure at least one active and one inactive group exist
2. Select "Inactive" from status filter dropdown
3. Click Search/Filter
4. Verify grid shows only inactive groups (is_active=0)

#### TC-P11: Create STATIC group with all required fields
1. Click "Add Target Group"
2. Fill group_name="All Teachers", group_code="GRP_TEACHERS", group_type="STATIC", description="Group containing all teachers"
3. Leave dynamic_query blank
4. Submit the form
5. Verify 302 redirect with success message "Target group created successfully"
6. Verify group appears in the grid with code "GRP_TEACHERS" (uppercased)

#### TC-P12: Create DYNAMIC group with dynamic_query
1. Click "Add Target Group"
2. Fill group_name="Active Students", group_code="GRP_ACTIVE_STUDENTS", group_type="DYNAMIC", description="Students with active status"
3. Fill dynamic_query with e.g., "SELECT id FROM sys_users WHERE is_active = 1 AND user_type = 'student'"
4. Submit the form
5. Verify 302 redirect with success message
6. Verify group appears in the grid with type "DYNAMIC"

#### TC-P13: Group code auto-uppercased
1. Create group with group_code="grp_test" (lowercase)
2. View the created group
3. Verify code displayed as "GRP_TEST" (uppercase)

#### TC-P14: Edit group loads pre-filled data
1. Create a group with specific values
2. Click Edit on the group
3. Verify edit form shows all existing field values pre-filled
4. Verify group_code is displayed (read-only or editable depending on UI)

#### TC-P15: Update group name and description
1. Edit a group
2. Change group_name and description
3. Submit the form
4. Verify 302 redirect with success message "Target group updated successfully"
5. Verify updated values appear in the grid

#### TC-P16: View group show page
1. Click on a group name/View action
2. Verify show page renders with all fields: group_code, group_name, group_type, description, dynamic_query, total_members, last_refreshed_at, is_system_group, is_active, creator name
3. Verify creator relationship is displayed

#### TC-P17: Toggle status active to inactive
1. Ensure a group exists with is_active=1
2. Click the toggle status button/icon
3. Verify AJAX POST to `/target-groups/{group}/toggle-status` with `{"is_active": false}`
4. Verify JSON response: `{"success": true, "is_active": false, "message": "Status updated successfully"}`
5. Verify grid reflects inactive status

#### TC-P18: Toggle status inactive to active
1. Ensure a group exists with is_active=0
2. Click the toggle status button/icon
3. Verify JSON response with `is_active: true`
4. Verify grid reflects active status

#### TC-P19: refreshMembers on DYNAMIC group
1. Create or find a DYNAMIC group
2. Click the refresh members button
3. Verify AJAX POST to `/target-groups/{id}/refresh-members`
4. Verify JSON response: `{"success": true, "message": "Member count refreshed successfully"}`
5. Verify `last_refreshed_at` is updated to current timestamp (in DB)

#### TC-P20: refreshMembers on STATIC group (no-op)
1. Create or find a STATIC group
2. Click the refresh members button
3. Verify AJAX POST to `/target-groups/{id}/refresh-members`
4. Verify JSON response: `{"success": true, "message": "Member count refreshed successfully"}`
5. Verify `last_refreshed_at` is NOT updated (remains null or unchanged)

#### TC-P21: Soft delete group
1. Identify a deletable group (non-system)
2. Click Delete
3. Verify group is soft-deleted
4. Verify success message "Target group moved to trash"

#### TC-P22: View trashed groups
1. Ensure at least one group is in trash
2. Navigate to `/target-groups/trash/view`
3. Verify trashed records are displayed with creator relationship
4. Verify pagination (10 per page)

#### TC-P23: Restore trashed group
1. Navigate to trash view
2. Click Restore on a trashed group
3. Verify POST request to `/target-groups/{id}/restore`
4. Verify redirect with success message "Target group restored successfully"
5. Verify group appears back in the main index

#### TC-P24: Force delete group from trash
1. Navigate to trash view
2. Click Force Delete on a trashed group
3. Verify DELETE request to `/target-groups/{id}/force-delete`
4. Verify redirect with success message "Target group permanently deleted"
5. Verify group no longer appears in trash

#### TC-P25: Full lifecycle
1. Create group → verify in grid
2. Edit group → verify updated
3. Toggle status active→inactive→active → verify toggles
4. Soft delete → verify in trash
5. Restore → verify in index
6. Soft delete again → verify in trash
7. Force delete → verify removed entirely

#### TC-P26: Pagination — first page
1. Create 15 target groups
2. Navigate to index page
3. Verify page 1 shows exactly 10 records
4. Verify pagination controls show page 1 as active and page 2 as available

#### TC-P27: Pagination — second page
1. With 15 groups created, click page 2
2. Verify page 2 shows remaining 5 records
3. Verify pagination URL includes `?page=2`

#### TC-P28: Empty state
1. Ensure no target groups exist (or delete all)
2. Navigate to index page
3. Verify empty state message is displayed (e.g., "No Target Groups Found")

#### TC-P29: Create group with total_members
1. Create group with total_members=500
2. Verify grid shows total_members=500

#### TC-P30: Create group with full description
1. Create group with description of exactly 255 characters
2. Verify description is saved and displayed correctly

### 7.2 Negative TC Steps

#### TC-N01: Required — missing `group_name`
1. Click "Add Target Group"
2. Fill all fields except group_name
3. Submit the form
4. Verify 422 validation error: "The group name field is required."
5. Verify group not created

#### TC-N02: Required — missing `group_code`
1. Click "Add Target Group"
2. Fill all fields except group_code
3. Submit the form
4. Verify 422 validation error: "The group code field is required."

#### TC-N03: Required — missing `group_type`
1. Click "Add Target Group"
2. Fill all fields except group_type
3. Submit the form
4. Verify 422 validation error: "The group type field is required."

#### TC-N04: Duplicate group_code within tenant
1. Create group with group_code="GRP_TEST"
2. Click "Add Target Group"
3. Enter group_code="GRP_TEST" again
4. Submit the form
5. Verify 422 validation error: "The group code has already been taken."

#### TC-N05: group_name > 100 chars
1. Enter group_name of 101 characters
2. Submit
3. Verify validation error on group_name.max

#### TC-N06: group_code > 50 chars
1. Enter group_code of 51 characters
2. Submit
3. Verify validation error on group_code.max

#### TC-N07: description > 255 chars
1. Enter description of 256 characters
2. Submit
3. Verify validation error on description.max

#### TC-N08: Invalid group_type value
1. Enter group_type="INVALID_TYPE"
2. Submit
3. Verify validation error on group_type.in

#### TC-N09: DYNAMIC group without dynamic_query
1. Select group_type="DYNAMIC"
2. Leave dynamic_query blank
3. Submit
4. Verify 422 validation error: "The dynamic query field is required when group type is DYNAMIC."

#### TC-N10: total_members negative
1. Enter total_members=-1
2. Submit
3. Verify validation error on min:0

#### TC-N11: View non-existent group
1. Navigate to `/target-groups/99999`
2. Verify 404 Not Found

#### TC-N12 through TC-N14: (Similar to N11 for edit/update/delete routes)

#### TC-N15: Duplicate group_code across tenants
1. In Tenant A, create group with code="GRP_SHARED"
2. In Tenant B, create group with same code="GRP_SHARED"
3. Verify Tenant B creation succeeds (unique per tenant)

#### TC-N16: Unauthorized access
1. Login as user without `tenant.target-group.viewAny`
2. Navigate to `/target-groups`
3. Verify 403 Forbidden

#### TC-N17: ToggleStatus missing is_active
1. POST to `/target-groups/{group}/toggle-status` without `is_active` parameter
2. Verify 422 validation error

#### TC-N18: ToggleStatus with non-boolean is_active
1. POST `is_active=string_value`
2. Verify 422 validation error on boolean

### 7.3 Dependency TC Steps

#### TC-D01: Create notification target with target group
1. Create a target group (STATIC, e.g., "Parents Group")
2. Create a notification target with target_group_id referencing this group
3. View notification target details
4. Verify target group relationship is displayed

#### TC-D02: Delete group referenced by notification target
1. Create a group and a notification target referencing it
2. Soft-delete the group
3. Verify notification target's target_group_id is set to NULL (SET NULL behavior)
4. Verify notification target still exists

#### TC-D03: group_code unique per tenant
1. In Tenant A, create group with code="GRP_UNIQUE"
2. In Tenant B, create group with same code="GRP_UNIQUE"
3. Verify both creations succeed — uniqueness is per-tenant composite

### 7.4 Code Review TC Steps

#### TC-CR01: TargetGroupRequest rules
1. Review `TargetGroupRequest.php` rules() method
2. Verify all 9 field rules are present as per section 5.2
3. Verify unique constraint uses `->where('tenant_id', $tenantId)` for per-tenant uniqueness
4. Verify `required_if:group_type,DYNAMIC` rule for dynamic_query

#### TC-CR02: Group code uppercased
1. Review `TargetGroupController@store()` line 128: `$data['group_code'] = strtoupper($data['group_code']);`
2. Review `TargetGroupController@update()` line 161: `$data['group_code'] = strtoupper($data['group_code']);`
3. Verify both store and update apply `strtoupper()` before save

#### TC-CR03: refreshMembers guard
1. Review `TargetGroupController@refreshMembers()` lines 227-241
2. Verify `if ($group->group_type == 'DYNAMIC')` guard at line 233
3. Verify `last_refreshed_at = now()` is only set inside this conditional
4. Verify STATIC groups always skip the `last_refreshed_at` update

#### TC-CR04: Eager loading
1. Review `TargetGroupController@index()` line 75: `$groupQuery = TargetGroup::with('creator');`
2. Review `show()` line 140: `TargetGroup::with(['creator'])->findOrFail($id);`
3. Verify `trashed()` line 184: `TargetGroup::onlyTrashed()->with('creator')->latest()->paginate(10)`
4. Verify creator is loaded in all views where it's displayed

#### TC-CR05: tenant_id assignment
1. Review store() line 127
2. Verify `$data['tenant_id'] = tenant()->id ?? null`
3. Note: tenant_id may be null for non-tenant contexts (central)

#### TC-CR06: created_by assignment
1. Review store() line 126
2. Verify `$data['created_by'] = Auth::id();`
3. Verify created_by is NOT changed on update() (only set during creation)
