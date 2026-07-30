# ntf_NotificationThreadMembers_TcList

## Module: Notification → Notification Management → Notification Thread Members

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Notification |
| Tab Group | Notification Management |
| Feature | Notification Thread Members |
| URL(s) | `GET /notification-thread-members` (index), `POST /notification-thread-members` (store), `GET /notification-thread-members/create` (create), `GET /notification-thread-members/{notification_thread_member}` (show), `GET /notification-thread-members/{notification_thread_member}/edit` (edit), `PUT /notification-thread-members/{notification_thread_member}` (update), `DELETE /notification-thread-members/{notification_thread_member}` (destroy), `POST /notification-thread-members/update-sequence` (updateSequence) |
| Controller | `Modules\Notification\Http\Controllers\NotificationThreadMemberController` |
| Model(s) | `Modules\Notification\Models\NotificationThreadMember` (table: `ntf_notification_thread_members`) |
| Validation | `Modules\Notification\Http\Requests\NotificationThreadMemberRequest` |
| Permissions | `tenant.notification-thread-member.viewAny`, `.create`, `.view`, `.update`, `.delete` |
| Pagination | 10 records per page (`NotificationThreadMemberController@index` line 40 — `$members = $query->ordered()->paginate(10)`) |
| Soft Deletes | **NO soft deletes** — table has no `deleted_at` column; `$timestamps = false` in model |
| is_active | **NO is_active column** — this table does not have `is_active` |
| Activity Log | Not explicitly logged |
| Notes | Pivot-like table with `UNIQUE(thread_id, notification_id)`, auto-sequence on create, resequence on delete |

---

## 2. Pre-conditions

- Required permissions: `tenant.notification-thread-member.viewAny` for index, `.create` for store, `.view` for show, `.update` for edit/update/updateSequence, `.delete` for destroy
- Seed data required: At least one `ntf_notification_threads` record and one `ntf_notifications` record
- Test user must have `tenant.notification-thread-member.*` permissions (default admin user)
- Tenant context must be initialized
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- No soft deletes — records are hard-deleted on destroy

---

## 3. Default Data Load

When the page loads via `NotificationThreadMemberController@index()`, the following data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Thread Members | `NotificationThreadMemberController@index()` lines 19-44 | `NotificationThreadMember::with(['thread', 'notification'])->ordered()` | search (thread.subject/uuid, notification.subject), thread_id, notification_id | 10/page |

---

## 4. Test Data Strategy

- **No soft deletes**: `destroy()` permanently removes the record (`$member->delete()` = hard delete)
- **No is_active**: This table does NOT have `is_active` or `is_enabled` columns — test accordingly
- **UNIQUE constraint**: `UNIQUE(thread_id, notification_id)` — cannot add the same notification to a thread twice
- **Auto-sequence**: On create, if `sequence_order` is empty, it's set to `max(sequence_order) + 1` for the thread
- **Resequence on delete**: After deletion, `resequenceThread()` renumbers remaining members by sequence_order (1, 2, 3, ...)
- **updateSequence AJAX**: Batch update `sequence_order` for multiple members at once
- **Pre-test cleanup**: Delete created members after tests (hard delete)
- **Pagination**: Create 15 records to test 10-record pagination

---

## 5. Business Conditions

### 5.1 Database Schema — `ntf_notification_thread_members`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED PK | Auto-increment |
| BC-DB-02 | thread_id | BIGINT UNSIGNED | FK → ntf_notification_threads.id CASCADE, NOT NULL |
| BC-DB-03 | notification_id | BIGINT UNSIGNED | FK → ntf_notifications.id CASCADE, NOT NULL, UNIQUE(thread_id, notification_id) |
| BC-DB-04 | sequence_order | INT | NOT NULL DEFAULT 1 |
| BC-DB-05 | created_at | TIMESTAMP | NULLABLE (model has `$timestamps = false`) |

### 5.2 Validation Rules — `NotificationThreadMemberRequest` (Create/Update)

| BC ID | Field | Rule(s) | Error Message |
|-------|-------|---------|---------------|
| BC-VAL-01 | thread_id | required, integer, exists:ntf_notification_threads,id | "The thread id field is required." |
| BC-VAL-02 | notification_id | required, integer, exists:ntf_notifications,id, unique:ntf_notification_thread_members per thread_id | "The notification has already been added to this thread." |
| BC-VAL-03 | sequence_order | nullable, integer, min:1 | — |

### 5.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.notification-thread-member.viewAny` | index — without → 403 |
| BC-AUTH-02 | `tenant.notification-thread-member.create` | create, store — without → 403 |
| BC-AUTH-03 | `tenant.notification-thread-member.view` | show — without → 403 |
| BC-AUTH-04 | `tenant.notification-thread-member.update` | edit, update, updateSequence — without → 403 |
| BC-AUTH-05 | `tenant.notification-thread-member.delete` | destroy — without → 403 |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page loads with thread members tab | Paginated grid at 10 records/page, ordered by sequence_order ASC, with thread and notification relationships loaded |
| BC-BIZ-02 | Search by thread subject/UUID | Filters where related thread.subject or thread.uuid contains search term |
| BC-BIZ-03 | Search by notification subject | Filters where related notification.subject contains search term |
| BC-BIZ-04 | Filter by thread_id | Exact match on thread_id |
| BC-BIZ-05 | Filter by notification_id | Exact match on notification_id |
| BC-BIZ-06 | Create member — auto-sequence | sequence_order set to max(sequence_order) + 1 for the thread |
| BC-BIZ-07 | Create member with explicit sequence_order | sequence_order saved as provided |
| BC-BIZ-08 | Duplicate (thread_id, notification_id) | Validation error: "The notification has already been added to this thread." |
| BC-BIZ-09 | Show member details | Show page renders with thread and notification |
| BC-BIZ-10 | Edit member | Edit form shows existing values |
| BC-BIZ-11 | Update member (change notification) | Member updated, duplicate check enforced |
| BC-BIZ-12 | Delete member — hard delete | Record permanently removed |
| BC-BIZ-13 | Delete member — auto-resequence | After delete, remaining members renumbered (1, 2, 3, ...) for that thread |
| BC-BIZ-14 | updateSequence AJAX — batch update | Multiple members' sequence_order updated in single request |
| BC-BIZ-15 | Empty state | Grid shows empty state |
| BC-BIZ-16 | Pagination — 10 per page | Page 1 shows up to 10 members |
| BC-BIZ-17 | Note: No is_active toggle | Table has no is_active column — toggleStatus route exists in web.php but may not function |
| BC-BIZ-18 | Note: No soft delete | Records are hard-deleted — no trash/restore/forceDelete |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | thread_id | ntf_notification_threads (id) | CASCADE |
| BC-REF-02 | notification_id | ntf_notifications (id) | CASCADE |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Thread Members page loads with UI elements | Page loads with search bar, filters, Add button, grid (10/page, ordered by sequence) | — | — | ⬜ |
| TC-P02 | Search by thread subject/UUID | Grid filtered to matching thread | — | — | ⬜ |
| TC-P03 | Search by notification subject | Grid filtered to matching notification | — | — | ⬜ |
| TC-P04 | Filter by thread_id | Grid shows members for selected thread | — | — | ⬜ |
| TC-P05 | Filter by notification_id | Grid shows members for selected notification | — | — | ⬜ |
| TC-P06 | Create member — auto-sequence | sequence_order auto-assigned (max+1) | — | — | ⬜ |
| TC-P07 | Create member with explicit sequence_order | sequence_order saved as provided | — | — | ⬜ |
| TC-P08 | Create multiple members for same thread | Each gets sequential sequence_order (1, 2, 3, ...) | — | — | ⬜ |
| TC-P09 | Show member details | Show page renders thread and notification info | — | — | ⬜ |
| TC-P10 | Edit and update member | Member updated, duplicate check enforced | — | — | ⬜ |
| TC-P11 | Delete member — hard delete | Record permanently removed from DB | — | — | ⬜ |
| TC-P12 | Delete member — resequence remaining | After delete, order becomes 1, 2, ... N (no gaps) | — | — | ⬜ |
| TC-P13 | updateSequence AJAX — batch reorder | Multiple members reordered in one request | — | — | ⬜ |
| TC-P14 | Empty state — no members | Grid shows empty state | — | — | ⬜ |
| TC-P15 | Pagination — first page 10 records | Page 1 shows up to 10 | — | — | ⬜ |
| TC-P16 | Pagination — second page | Page 2 shows records 11+ | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — missing `thread_id` | Validation error | — | — | ⬜ |
| TC-N02 | Required — missing `notification_id` | Validation error | — | — | ⬜ |
| TC-N03 | Invalid thread_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N04 | Invalid notification_id (non-existent) | Validation error on exists | — | — | ⬜ |
| TC-N05 | Duplicate (thread_id, notification_id) | "The notification has already been added to this thread." | — | — | ⬜ |
| TC-N06 | sequence_order < 1 | Validation error on min:1 | — | — | ⬜ |
| TC-N07 | View non-existent member (404) | 404 Not Found | — | — | ⬜ |
| TC-N08 | Edit non-existent member (404) | 404 Not Found | — | — | ⬜ |
| TC-N09 | Update non-existent member (404) | 404 Not Found | — | — | ⬜ |
| TC-N10 | Delete non-existent member (404) | 404 Not Found | — | — | ⬜ |
| TC-N11 | Unauthorized access without permission | 403 Forbidden | — | — | ⬜ |
| TC-N12 | updateSequence — missing members param | 422 validation error | — | — | ⬜ |
| TC-N13 | updateSequence — invalid member ID | 422 validation error on exists | — | — | ⬜ |
| TC-N14 | updateSequence — sequence_order < 1 | 422 validation error on min:1 | — | — | ⬜ |
| TC-N15 | Delete thread with members — CASCADE | All members deleted when parent thread deleted | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | Create member with thread — FK check | Thread relationship works | — | — | ⬜ |
| TC-D02 | Create member with notification — FK check | Notification relationship works | — | — | ⬜ |
| TC-D03 | Delete thread — members cascade deleted | Members removed when thread deleted | — | — | ⬜ |
| TC-D04 | Delete notification — members cascade deleted | Members removed when notification deleted | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-CR01 | `NotificationThreadMemberRequest` rules | All 3 field rules enforced as per section 5.2 | — | — | ◌ |
| TC-CR02 | Auto-sequence logic | `max(sequence_order) + 1` when sequence empty | — | — | ◌ |
| TC-CR03 | Resequence on delete | `resequenceThread()` renumbers by sequence_order | — | — | ◌ |
| TC-CR04 | updateSequence batch validation | Members array validation rules | — | — | ◌ |
| TC-CR05 | `$timestamps = false` model property | `created_at` not auto-managed | — | — | ◌ |
| TC-CR06 | No SoftDeletes — hard delete | `$member->delete()` permanently removes record | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Thread Members page loads
1. Login as admin user with `tenant.notification-thread-member.viewAny`
2. Navigate to `GET /notification-thread-members`
3. Verify page loads (200 OK) with search bar, thread_id filter, notification_id filter, "Add Member" button, grid ordered by sequence_order ASC

#### TC-P02: Search by thread subject/UUID
1. Ensure members exist for threads with different subjects
2. Search for matching thread subject or UUID
3. Verify grid filtered

#### TC-P03: Search by notification subject
1. Search for matching notification subject
2. Verify grid filtered

#### TC-P04 through TC-P05: Filter by thread_id/notification_id
1. Apply filter by selecting specific thread or notification
2. Verify grid shows only matching members

#### TC-P06: Create member — auto-sequence
1. Click "Add Thread Member"
2. Select a thread and a notification
3. Leave sequence_order empty
4. Submit
5. Verify sequence_order auto-set to max+1 for this thread
6. Verify success message "Thread member added successfully"

#### TC-P07: Create member with explicit sequence_order
1. Set sequence_order=5 explicitly
2. Submit
3. Verify sequence_order saved as 5

#### TC-P08: Create multiple members for same thread
1. Create 3 members for the same thread (no sequence_order)
2. Verify they get sequence_order 1, 2, 3

#### TC-P09: Show member details
1. Click View on a member
2. Verify thread subject/UUID and notification subject displayed

#### TC-P10: Edit and update
1. Edit a member
2. Change notification
3. Submit
4. Verify updated

#### TC-P11: Delete member — hard delete
1. Delete a member
2. Verify record is permanently removed from `ntf_notification_thread_members`

#### TC-P12: Delete member — resequence
1. Create members with order 1, 2, 3 for a thread
2. Delete member with sequence_order=1
3. Verify remaining members renumbered to 1, 2 (no gap)

#### TC-P13: updateSequence batch AJAX
1. Ensure at least 2 members exist for a thread
2. POST to `/notification-thread-members/update-sequence` with:
   `{"members": [{"id": 1, "sequence_order": 3}, {"id": 2, "sequence_order": 1}]}`
3. Verify JSON success: `{"success": true, "message": "Sequence updated successfully"}`
4. Verify sequence_order values updated in DB

#### TC-P14: Empty state
1. Ensure no members exist
2. Verify grid shows empty state

#### TC-P15 through TC-P16: Pagination
1. Create 15 members
2. Verify page 1 = 10, page 2 = 5

### 7.2 Negative TC Steps

#### TC-N01: Missing thread_id
1. Submit without thread_id
2. Verify 422 validation error

#### TC-N02: Missing notification_id
1. Submit without notification_id
2. Verify 422 error

#### TC-N03: Invalid thread_id
1. Enter thread_id=99999
2. Verify exists validation error

#### TC-N04: Invalid notification_id
1. Enter notification_id=99999
2. Verify exists validation error

#### TC-N05: Duplicate (thread_id, notification_id)
1. Create a member for thread=1, notification=1
2. Try to create another member for same combination
3. Verify unique validation error: "The notification has already been added to this thread."

#### TC-N06: sequence_order < 1
1. Enter sequence_order=0
2. Verify min:1 validation error

#### TC-N07 through TC-N11: 404 and 403
1. Standard tests for non-existent records and unauthorized access

#### TC-N12 through TC-N14: updateSequence validation
1. Missing members param → 422
2. Invalid member ID → 422 exists
3. Sequence_order < 1 → 422 min:1

#### TC-N15: Delete thread with members
1. Create thread with members
2. Delete the thread
3. Verify all members for that thread are also deleted (CASCADE)

### 7.3 Dependency TC Steps

#### TC-D01: Thread FK
1. Create a thread
2. Create member referencing it
3. Verify thread relationship displayed

#### TC-D02: Notification FK
1. Create a notification
2. Create member referencing it
3. Verify notification relationship displayed

#### TC-D03: Delete thread — cascade
1. Create thread + members
2. Delete thread
3. Verify members deleted (CASCADE)

#### TC-D04: Delete notification — cascade
1. Create notification + member
2. Delete notification
3. Verify member deleted (CASCADE)

### 7.4 Code Review TC Steps

#### TC-CR01: NotificationThreadMemberRequest rules
1. Review `NotificationThreadMemberRequest.php` rules()
2. Verify 3 field rules: thread_id, notification_id, sequence_order
3. Verify unique constraint: `Rule::unique('ntf_notification_thread_members')->where('thread_id', $this->thread_id)->ignore($id)`

#### TC-CR02: Auto-sequence logic
1. Review store() lines 63-65
2. Verify `$maxSequence = NotificationThreadMember::where('thread_id', ...)->max('sequence_order') ?? 0`
3. Verify `$data['sequence_order'] = $maxSequence + 1`

#### TC-CR03: Resequence on delete
1. Review destroy() line 113: `$this->resequenceThread($member->thread_id);`
2. Review resequenceThread() lines 139-149
3. Verify it fetches all members ordered, then renumbers 1, 2, 3...

#### TC-CR04: updateSequence validation
1. Review updateSequence() lines 119-137
2. Verify `$request->validate(['members' => 'required|array', 'members.*.id' => 'required|integer|exists:ntf_notification_thread_members,id', 'members.*.sequence_order' => 'required|integer|min:1'])`

#### TC-CR05: $timestamps = false
1. Review model line 11: `public $timestamps = false;`
2. Verify `created_at` is NOT auto-managed by Eloquent

#### TC-CR06: No SoftDeletes
1. Review model — verify NO `SoftDeletes` trait
2. Verify model does NOT have `protected $dates = ['deleted_at']`
