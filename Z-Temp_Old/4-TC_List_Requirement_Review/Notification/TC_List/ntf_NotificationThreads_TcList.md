# ntf_NotificationThreads_TcList

## Module: Notification → Notification Management → Notification Threads

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Notification Threads |
| URL(s) | `GET /notification-mgt` (tab-index), `GET /notification-threads` (index), `POST /notification-threads` (store), `GET /notification-threads/create` (create), `GET /notification-threads/{notification_thread}` (show), `GET /notification-threads/{notification_thread}/edit` (edit), `PUT /notification-threads/{notification_thread}` (update), `DELETE /notification-threads/{notification_thread}` (destroy), `POST /notification-threads/{notification_thread}/toggle-status` (toggleStatus), `POST /notification-threads/{id}/recalculate` (recalculateCounts) |
| Controller | `Modules\Notification\Http\Controllers\NotificationThreadController` |
| Model(s) | `Modules\Notification\Models\NotificationThread` (table: `ntf_notification_threads`) |
| Validation | `Modules\Notification\Http\Requests\NotificationThreadRequest` |
| Permissions | `tenant.notification-thread.viewAny`, `.create`, `.view`, `.update`, `.delete` |
| Pagination | 10 records per page (`NotificationThreadController@index` line 313 — `$query->latest()->paginate(10)`) |
| Soft Deletes | Yes (SoftDeletes trait) — Note: model does NOT explicitly use SoftDeletes in code; `destroy()` calls `$thread->delete()` but `is_active` cast exists |
| Activity Log | Not explicitly logged in `NotificationThreadController` |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification-thread.viewAny` for index, `.create` for store, `.view` for show, `.update` for update/toggleStatus/recalculateCounts, `.delete` for destroy
- Seed data required: At least one `ntf_notifications` record for `root_notification_id` (optional FK)
- Test user must have `tenant.notification-thread.*` permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For child-thread tests: At least one parent thread must exist

---

## 3. Default Data Load

When the page loads via `NotificationThreadController@index()`, the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Notification Threads | `NotificationThreadController@index()` lines 288-313 | `NotificationThread::with(['parentThread', 'rootNotification'])` | search (thread_subject, thread_uuid), thread_type, has_parent (yes/no), status (is_active) | 10/page |
| Templates | Side-loaded | `NotificationTemplate::with(['channel','creator','tenant'])->latest()` | search, channel_id, approval_status, language_code, status | 15/page |
| Notifications | Side-loaded | `Notification::with(['priority','confidentialityLevel','notificationStatus','tenant','creator','approver','template'])->latest()` | — | 10/page |
| Channels | Side-loaded | `ChannelMaster::query()` | search, status | 10/page |
| Providers | Side-loaded | `ProviderMaster::with('channel')` | search, channel_id, provider_type, status | 10/page |
| Target Groups | Side-loaded | `TargetGroup::with('creator')` | search, group_type, system, status | 10/page |
| Targets | Side-loaded | `NotificationTarget::with(['notification','targetType','targetGroup'])` | search, notification_id, target_type_id, has_group, status | 10/page |
| User Preferences | Side-loaded | `UserPreference::with(['user','channel','priorityThreshold'])` | search, user_id, channel_id, is_enabled, is_opted_in, daily_digest, has_quiet_hours, status | 10/page |
| Resolved Recipients | Side-loaded | `ResolvedRecipient::with(['notification','channel','template','notificationTarget','user','userPreference','device'])` | search, notification_id, channel_id, user_id, batch_id, is_processed, priority range, date range, status | 15/page |

---

## 4. Test Data Strategy

- **UUID generation**: `thread_uuid` is auto-generated via `Str::uuid()` on create — ensure UUID format
- **Thread types**: Test all `thread_type` values: CONVERSATION, DIGEST, BROADCAST
- **Self-referencing FK**: `parent_thread_id` references same table — test child/parent hierarchy
- **Cannot delete thread with children**: Controller checks `childThreads()->count() > 0` before delete
- **Cannot be own parent**: Validation rule prevents `parent_thread_id == id`
- **Pre-test cleanup**: Delete created threads before/after tests
- **Pagination**: Create 15 records to test 10-record pagination boundary
- **recalculateCounts**: AJAX endpoint that counts notifications + distinct resolved users

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_notification_threads`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | tenant_id | VARCHAR(255) | FK → tenants.id, NULLABLE |
| BC-DB-03 | thread_uuid | CHAR(36) | NOT NULL |
| BC-DB-04 | thread_type | ENUM('CONVERSATION','DIGEST','BROADCAST') | NOT NULL, DEFAULT 'BROADCAST' |
| BC-DB-05 | thread_subject | VARCHAR(255) | NULLABLE |
| BC-DB-06 | parent_thread_id | BIGINT UNSIGNED | FK → ntf_notification_threads.id (self), NULLABLE |
| BC-DB-07 | root_notification_id | BIGINT UNSIGNED | FK → ntf_notifications.id, NULLABLE |
| BC-DB-08 | total_notifications | INT | NOT NULL DEFAULT 0 |
| BC-DB-09 | participant_count | INT | NOT NULL DEFAULT 0 |
| BC-DB-10 | is_active | BOOLEAN | NOT NULL DEFAULT true |
| BC-DB-11 | created_at | TIMESTAMP | NULLABLE |
| BC-DB-12 | updated_at | TIMESTAMP | NULLABLE |
| BC-DB-13 | deleted_at | TIMESTAMP | NULLABLE (soft delete — note: SoftDeletes trait not explicitly used in model but column exists) |

### 5.2 Validation Rules — `NotificationThreadRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | thread_type | required, in:CONVERSATION,DIGEST,BROADCAST | "The selected thread type is invalid." |
| BC-VAL-02 | thread_subject | nullable, string, max:255 | — |
| BC-VAL-03 | parent_thread_id | nullable, integer, exists:ntf_notification_threads,id, custom: not self | "Thread cannot be its own parent." |
| BC-VAL-04 | root_notification_id | nullable, integer, exists:ntf_notifications,id | — |
| BC-VAL-05 | total_notifications | nullable, integer, min:0 | — |
| BC-VAL-06 | participant_count | nullable, integer, min:0 | — |
| BC-VAL-07 | is_active | nullable, boolean | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification-thread.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.notification-thread.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.notification-thread.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification-thread.update` | edit, update, toggleStatus, recalculateCounts — without → 403 |
| BC-AUTH-05 | `tenant.notification-thread.delete` | destroy — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with notification threads tab | Paginated grid at 10 records/page, ordered by latest, with parentThread and rootNotification relationships loaded |
| BC-BIZ-02 | Search by thread_subject | Filters threads where thread_subject contains search term |
| BC-BIZ-03 | Search by thread_uuid | Filters threads where thread_uuid contains search term |
| BC-BIZ-04 | Filter by thread_type | Exact match on thread_type (CONVERSATION, DIGEST, BROADCAST) |
| BC-BIZ-05 | Filter has_parent = yes | Shows threads where parent_thread_id is NOT NULL |
| BC-BIZ-06 | Filter has_parent = no | Shows threads where parent_thread_id is NULL (root threads) |
| BC-BIZ-07 | Filter by status | Filters by is_active |
| BC-BIZ-08 | Create thread — all thread types | Thread created with correct type |
| BC-BIZ-09 | Create thread with parent_thread_id | Child thread linked to parent correctly |
| BC-BIZ-10 | Create thread without parent | Root thread (parent_thread_id = null) |
| BC-BIZ-11 | Create thread with root_notification_id | Root notification linked |
| BC-BIZ-12 | UUID auto-generated on create | `thread_uuid` set to `Str::uuid()` |
| BC-BIZ-13 | tenant_id set on create | `$data['tenant_id'] = tenant()->id ?? null` |
| BC-BIZ-14 | Edit thread | Edit form shows pre-filled data |
| BC-BIZ-15 | Update thread | Thread updated with new values |
| BC-BIZ-16 | Show thread with relationships | Parent thread, child threads, root notification, notifications loaded |
| BC-BIZ-17 | Toggle status active→inactive | AJAX toggles is_active |
| BC-BIZ-18 | recalculateCounts AJAX | Computes total_notifications (count) + participant_count (distinct user_id in resolved_recipients) via join, returns JSON |
| BC-BIZ-19 | Delete thread without children | Thread soft-deleted |
| BC-BIZ-20 | Delete thread with children blocked | Redirect with error "Cannot delete thread with child threads" |
| BC-BIZ-21 | Empty state | Grid shows empty state |
| BC-BIZ-22 | Pagination — 10 per page | Page 1 shows up to 10 threads |
| BC-BIZ-23 | Self-parent prevention | "Thread cannot be its own parent." validation error |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | tenant_id | tenants (id) | CASCADE |
| BC-REF-02 | parent_thread_id | ntf_notification_threads (id) | SET NULL |
| BC-REF-03 | root_notification_id | ntf_notifications (id) | SET NULL |
| BC-REF-04 | id (self) | ntf_notification_thread_members.thread_id | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Notification Threads page loads with UI elements | Page loads with search bar, thread_type filter, has_parent filter, status filter, Add button, grid | — | — | ⬜ |
| TC-P02 | Search by thread_subject | Grid filtered to matching subject | — | — | ⬜ |
| TC-P03 | Search by thread_uuid | Grid filtered to matching UUID | — | — | ⬜ |
| TC-P04 | Filter by thread_type = CONVERSATION | Grid shows only CONVERSATION threads | — | — | ⬜ |
| TC-P05 | Filter by thread_type = DIGEST | Grid shows only DIGEST threads | — | — | ⬜ |
| TC-P06 | Filter by thread_type = BROADCAST | Grid shows only BROADCAST threads | — | — | ⬜ |
| TC-P07 | Filter has_parent = yes | Grid shows only child threads | — | — | ⬜ |
| TC-P08 | Filter has_parent = no | Grid shows only root threads | — | — | ⬜ |
| TC-P09 | Filter by active status | Grid shows only active threads | — | — | ⬜ |
| TC-P10 | Filter by inactive status | Grid shows only inactive threads | — | — | ⬜ |
| TC-P11 | Create BROADCAST thread (no parent) | Root broadcast thread created | — | — | ⬜ |
| TC-P12 | Create CONVERSATION thread with parent | Child conversation thread linked to parent | — | — | ⬜ |
| TC-P13 | Create DIGEST thread with root_notification | Digest thread linked to root notification | — | — | ⬜ |
| TC-P14 | View thread show page | Show page renders with parent, children, root notification, notifications | — | — | ⬜ |
| TC-P15 | Edit thread loads pre-filled data | Edit form shows existing values | — | — | ⬜ |
| TC-P16 | Update thread subject | Thread subject updated | — | — | ⬜ |
| TC-P17 | Toggle status active to inactive | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P18 | Toggle status inactive to active | AJAX success, is_active flipped | — | — | ⬜ |
| TC-P19 | recalculateCounts AJAX | total_notifications and participant_count computed and returned | — | — | ⬜ |
| TC-P20 | Delete thread (no children) | Thread deleted, moved to trash | — | — | ⬜ |
| TC-P21 | Full lifecycle: create→edit→toggle→recalculate→delete | All transitions succeed | — | — | ⬜ |
| TC-P22 | Pagination — first page 10 records | Page 1 shows up to 10 | — | — | ⬜ |
| TC-P23 | Pagination — second page | Page 2 shows records 11+ | — | — | ⬜ |
| TC-P24 | Empty state — no threads | Grid shows empty state | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `thread_type` | Validation error | — | — | ⬜ |
| TC-N02 | Invalid thread_type value | Validation error on in:CONVERSATION,DIGEST,BROADCAST | — | — | ⬜ |
| TC-N03 | Self-parent (parent_thread_id == id) | "Thread cannot be its own parent." | — | — | ⬜ |
| TC-N04 | Non-existent parent_thread_id | Validation error on exists | — | — | ⬜ |
| TC-N05 | Non-existent root_notification_id | Validation error on exists | — | — | ⬜ |
| TC-N06 | Max length — thread_subject > 255 | Validation error on max:255 | — | — | ⬜ |
| TC-N07 | Delete thread with child threads | Redirect with error "Cannot delete thread with child threads" | — | — | ⬜ |
| TC-N08 | View non-existent thread (404) | 404 Not Found | — | — | ⬜ |
| TC-N09 | Edit non-existent thread (404) | 404 Not Found | — | — | ⬜ |
| TC-N10 | Update non-existent thread (404) | 404 Not Found | — | — | ⬜ |
| TC-N11 | Delete non-existent thread (404) | 404 Not Found | — | — | ⬜ |
| TC-N12 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N13 | recalculateCounts on non-existent thread | 404 Not Found | — | — | ⬜ |
| TC-N14 | toggleStatus missing is_active | 422 validation error | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create thread members referencing thread | Members linked correctly | — | — | ⬜ |
| TC-D02 | Delete parent thread with child threads — blocked | Cannot delete, child threads exist | — | — | ⬜ |
| TC-D03 | recalculateCounts updates counts from actual data | Counts reflect actual notifications and resolved users | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `NotificationThreadRequest` rules | All 7 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | Self-parent custom validation | `function ($attribute, $value, $fail) { if ($value == $this->route('id')) ... }` | — | — | ◌ |
| TC-CR03 | destroy() child thread check | `if ($thread->childThreads()->count() > 0)` guard | — | — | ◌ |
| TC-CR04 | recalculateCounts join query | `$thread->notifications()->join('ntf_resolved_recipients', ...)->distinct()->count(...)` | — | — | ◌ |
| TC-CR05 | UUID auto-generation on create | `$data['thread_uuid'] = (string) Str::uuid()` | — | — | ◌ |
| TC-CR06 | has_parent filter logic | `whereNotNull`/`whereNull` on parent_thread_id | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Notification Threads page loads
1. Login as admin user with `tenant.notification-thread.viewAny`
2. Navigate to `GET /notification-threads`
3. Verify page loads (200 OK) with search bar, thread_type filter (CONVERSATION/DIGEST/BROADCAST), has_parent filter (All/Yes/No), status filter, "Add Thread" button, grid

#### TC-P02: Search by thread_subject
1. Ensure threads with different subjects exist
2. Search for matching subject text
3. Verify grid filtered to matching threads

#### TC-P03: Search by thread_uuid
1. Search for a known thread_uuid (or partial)
2. Verify grid shows matching thread(s)

#### TC-P04 through TC-P09: Filter tests
1. Apply thread_type, has_parent, and status filters
2. Verify grid filtered correctly

#### TC-P10: Filter by inactive status
1. Ensure at least one active and one inactive thread
2. Select "Inactive" from status filter
3. Verify grid shows only inactive threads (is_active=0)

#### TC-P11: Create BROADCAST thread
1. Click "Add Notification Thread"
2. Set thread_type="BROADCAST", thread_subject="Weekly Announcements"
3. Leave parent_thread_id and root_notification_id empty
4. Submit
5. Verify 302 redirect with success message "Notification thread created successfully"
6. Verify thread appears in grid with type BROADCAST

#### TC-P12: Create CONVERSATION thread with parent
1. First create a parent BROADCAST thread
2. Click "Add Notification Thread"
3. Set thread_type="CONVERSATION", thread_subject="Reply to announcement"
4. Select parent thread from parent_thread_id dropdown
5. Submit
6. Verify child thread created with parent_thread_id set

#### TC-P13: Create DIGEST thread with root_notification
1. Ensure a notification exists
2. Create DIGEST thread with root_notification_id set
3. Verify root_notification relationship displayed in show page

#### TC-P14: View thread show page
1. Click View on a thread
2. Verify relationships: parentThread (if any), childThreads (if any), rootNotification (if any), notifications (through pivot)
3. Verify all fields displayed: thread_uuid, thread_type, thread_subject, total_notifications, participant_count

#### TC-P15: Edit loads pre-filled data
1. Edit a thread
2. Verify form shows current values
3. Verify parent_thread_id dropdown excludes current thread (prevents self-reference)

#### TC-P16: Update thread
1. Change thread_subject
2. Submit
3. Verify updated

#### TC-P17 through TC-P18: Toggle status
1. POST to `/notification-threads/{thread}/toggle-status` with `{"is_active": false}`
2. Verify JSON success
3. Toggle back to active

#### TC-P19: recalculateCounts
1. Ensure thread has notifications with resolved recipients
2. POST to `/notification-threads/{id}/recalculate`
3. Verify JSON response: `{"success": true, "total_notifications": N, "participant_count": M, "message": "Counts recalculated successfully"}`
4. Verify DB updated

#### TC-P20: Delete thread (no children)
1. Delete a thread that has no child threads
2. Verify soft delete

#### TC-P21: Full lifecycle
1. Create → verify
2. Edit → verify
3. Toggle status → verify
4. Recalculate counts → verify
5. Delete → verify

#### TC-P22 through TC-P24: Pagination and empty state
1. Standard tests

### 7.2 Negative TC Steps

#### TC-N01: Missing thread_type
1. Leave thread_type empty, submit
2. Verify 422 validation error

#### TC-N02: Invalid thread_type
1. Set thread_type="INVALID"
2. Verify validation error on in:CONVERSATION,DIGEST,BROADCAST

#### TC-N03: Self-parent prevention
1. Edit a thread
2. Set parent_thread_id to its own ID
3. Submit
4. Verify validation error: "Thread cannot be its own parent."

#### TC-N04: Non-existent parent_thread_id
1. Set parent_thread_id=99999
2. Verify exists validation error

#### TC-N05: Non-existent root_notification_id
1. Set root_notification_id=99999
2. Verify exists validation error

#### TC-N06: thread_subject > 255 chars
1. Enter long subject
2. Verify max:255 validation

#### TC-N07: Delete thread with children
1. Create parent thread with at least one child
2. Try to delete parent
3. Verify redirect with error "Cannot delete thread with child threads"

#### TC-N08 through TC-N14: 404, 403, validation
1. Standard error-condition tests

### 7.3 Dependency TC Steps

#### TC-D01: Create thread member
1. Create a thread
2. Add a notification as member via `POST /notification-thread-members`
3. Verify member linked to thread

#### TC-D02: Delete parent with children — blocked
1. Create parent → child hierarchy
2. Attempt parent delete
3. Verify blocked with error

#### TC-D03: recalculateCounts with real data
1. Create thread with 3 notification members, each with resolved recipients
2. Run recalculateCounts
3. Verify total_notifications = 3, participant_count = distinct resolved users count

### 7.4 Code Review TC Steps

#### TC-CR01: NotificationThreadRequest rules
1. Review `NotificationThreadRequest.php` rules()
2. Verify all 7 rule entries
3. Verify `in:CONVERSATION,DIGEST,BROADCAST` for thread_type
4. Verify custom self-parent closure validation

#### TC-CR02: Self-parent validation
1. Review lines 23-30 of NotificationThreadRequest
2. Verify `function ($attribute, $value, $fail) { if ($value && $value == $this->route('id')) ... }`

#### TC-CR03: destroy child check
1. Review destroy() lines 399-415
2. Verify `$thread->childThreads()->count() > 0` guard at line 406
3. Verify error message: "Cannot delete thread with child threads"

#### TC-CR04: recalculateCounts query
1. Review recalculateCounts() lines 433-453
2. Verify `$thread->notifications()->count()` for total_notifications
3. Verify join with `ntf_resolved_recipients` and `distinct()->count('user_id')` for participant_count

#### TC-CR05: UUID generation
1. Review store() line 359
2. Verify `$data['thread_uuid'] = (string) Str::uuid()`

#### TC-CR06: has_parent filter
1. Review index() lines 301-307
2. Verify `$request->has_parent == 'yes'` → `whereNotNull('parent_thread_id')`
3. Verify `$request->has_parent == 'no'` → `whereNull('parent_thread_id')`
