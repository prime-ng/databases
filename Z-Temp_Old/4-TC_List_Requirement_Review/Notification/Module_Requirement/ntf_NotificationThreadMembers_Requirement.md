# Notification Thread Members — Business Requirements

## What This Screen Does
The Notification Thread Members screen manages the many-to-many association between notification threads and individual notifications. It acts as a membership/pivot table that assigns notifications to threads with a specific sequence order, enabling ordered conversation flows, digest grouping, and broadcast membership. Each record links exactly one notification to one thread, and the sequence_order determines the display order within that thread.

## When This Screen Is Used
- When adding a notification to an existing thread (conversation, digest, or broadcast)
- When removing a notification from a thread
- When reordering notifications within a thread (drag-and-drop or manual sequence update)
- When viewing which notifications belong to which thread
- When linking a new reply/child notification to its parent conversation thread
- When grouping multiple notifications into a digest thread in a specific order

## Default Data Load
On page load, the screen displays a paginated list of thread membership records for the current tenant. The list shows the thread subject, notification subject, sequence_order, created_at timestamp, and action buttons (View, Edit, Delete). Filters are available for thread_id and notification_id dropdowns, and a search box searches across thread subject, thread UUID, and notification subject.

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| thread_id | BIGINT FK | Links to the parent notification thread (ntf_notification_threads) |
| notification_id | BIGINT FK | Links to the notification (ntf_notifications) |
| sequence_order | INT (default 1) | Determines the display/sort order of this notification within the thread |
| created_at | TIMESTAMP | Record creation timestamp |

**Composite Unique:** `(thread_id, notification_id)` — a notification can only be added to a thread once.

## Business Rules and Conditions
- A notification can belong to multiple threads (BR-NTF-TM-01)
- A thread can have multiple notifications (BR-NTF-TM-02)
- The combination `(thread_id, notification_id)` must be unique — no duplicate membership (BR-NTF-TM-03)
- `sequence_order` is auto-calculated as `max(sequence_order) + 1` for the same thread if not manually provided on creation (BR-NTF-TM-04)
- When a member is deleted, the remaining members in the same thread are automatically resequenced from 1..N via `resequenceThread()` (BR-NTF-TM-05)
- Sequence numbers start at 1 and are contiguous after every resequence operation (BR-NTF-TM-06)
- The `updateSequence()` AJAX endpoint accepts bulk sequence updates and overwrites the `sequence_order` for each provided member ID (BR-NTF-TM-07)
- The table does **not** support SoftDeletes — member deletion is a hard delete (BR-NTF-TM-08)
- The table does **not** have an `is_active` or `is_enabled` column — membership is binary (BR-NTF-TM-09)
- No `updated_at` column — only `created_at` is tracked (BR-NTF-TM-10)

## Workflow Steps
1. Administrator navigates to Notification → Notification Management → Thread Members tab.
2. Views the list of existing thread memberships with search and filter options (by thread, by notification).
3. Clicks "Add Member" to link a notification to a thread.
4. Selects a thread (from active threads dropdown) and a notification (from active notifications dropdown).
5. Optionally enters a sequence_order value; if left empty, the system auto-assigns the next available number (max + 1).
6. Saves the record — the notification is now part of the thread.
7. To reorder, uses the "Update Sequence" button, which opens an inline editor or modal where sequence numbers can be changed for multiple members at once.
8. To remove a notification from a thread, clicks "Delete" — the record is hard-deleted and the remaining members are resequenced automatically.
9. Views individual membership details by clicking "View."

## Example Scenario
A school creates a BROADCAST thread titled "Exam Schedule 2026 — All Grades." Three notifications are sent as part of this thread:

1. **Notification A:** "Exam Schedule for Grade 10" (sequence_order = 1)
2. **Notification B:** "Exam Schedule for Grade 12" (sequence_order = 2)
3. **Notification C:** "Exam Instructions & Guidelines" (sequence_order = 3)

Later, the admin needs to add "Notification D: Grade 10 Timetable Change" to appear between A and B. The admin deletes member C (sequence 3), adds D (auto-assigned sequence 4), then uses the Update Sequence feature to reorder: A=1, D=2, B=3, C=4. After every delete, remaining members are automatically resequenced to eliminate gaps.

## Related Screens
- **Notification Threads:** The parent thread record that groups notifications together
- **Notifications:** The individual notification records that can be added to threads
- **Templates:** Templates used by notifications within a thread
- **Targets / Resolved Recipients:** Recipients resolved for notifications within the thread

---

## Requirements

### REQ-NTF-TM-01: Member Creation
Administrator must be able to create a thread membership record by selecting a thread and a notification, optionally providing a sequence order.

### REQ-NTF-TM-02: Auto-Sequence
If `sequence_order` is not provided on creation, the system must auto-calculate it as `max(sequence_order) + 1` for the given `thread_id`, starting at 1 for the first member.

### REQ-NTF-TM-03: Unique Membership
The combination `(thread_id, notification_id)` must be unique. The same notification cannot be added twice to the same thread. A duplicate attempt must return a validation error.

### REQ-NTF-TM-04: Bulk Sequence Update
The system must provide an AJAX endpoint (`updateSequence()`) that accepts an array of `{id, sequence_order}` pairs and updates the `sequence_order` for each member record. This enables drag-and-drop or manual reordering of notifications within a thread.

### REQ-NTF-TM-05: Auto-Resequence on Delete
When a member is deleted, the system must automatically resequence the remaining members of the same thread to contiguous values starting at 1 (`resequenceThread()` private method).

### REQ-NTF-TM-06: Search and Filter
The index view must support search by thread subject, thread UUID, and notification subject, plus filter by `thread_id` and `notification_id` via dropdown selects.

### REQ-NTF-TM-07: Ordered Listing
The index view must display members ordered by `sequence_order` ascending by default.

### REQ-NTF-TM-08: Hard Delete
Deleting a thread member must perform a hard delete (no SoftDeletes support). The record is permanently removed from the database.

### REQ-NTF-TM-09: Notification Thread Relationship
The `NotificationThread` model must expose a `members()` hasMany relationship and a `notifications()` belongsToMany relationship through the `ntf_notification_thread_members` pivot table with `sequence_order` as the pivot value.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All `tenant.notification-thread-member.*` permissions | All tenants |
| School Admin | `tenant.notification-thread-member.viewAny`, `.create`, `.update`, `.delete` | Own tenant |
| Manager | `tenant.notification-thread-member.viewAny`, `.view` | Own tenant (read-only) |

---

## Logic Flow

### Create Flow
```
User submits form → NotificationThreadMemberRequest validation →
Validate thread_id exists in ntf_notification_threads →
Validate notification_id exists in ntf_notifications →
Validate (thread_id, notification_id) unique combination →
If sequence_order is empty:
  Get max(sequence_order) for thread_id → default to 0 →
  Set sequence_order = max + 1 →
Create record with validated data → Return success redirect
```

### Update Sequence Flow (AJAX)
```
User clicks "Update Sequence" →
Sends POST with JSON { members: [{id: X, sequence_order: N}, ...] } →
Validate each id exists in ntf_notification_thread_members →
Validate each sequence_order is integer ≥ 1 →
Loop: UPDATE sequence_order WHERE id = X →
Return JSON { success: true, message: "Sequence updated successfully" }
```

### Delete Flow
```
User clicks delete → Confirm dialog →
Find member by id (findOrFail) →
Hard delete the record →
Call resequenceThread(thread_id) →
  Fetch all remaining members for the thread ordered by sequence_order →
  Reassign sequence_order = 1, 2, 3... N for each member →
Save each member →
Return success redirect
```

### Show Flow
```
User clicks "View" on a member →
Find member by id with eager-loaded thread and notification →
Display read-only details including thread subject, notification subject, sequence_order, created_at
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| thread_id | required, integer, exists:ntf_notification_threads,id | Please select a valid notification thread. |
| notification_id | required, integer, exists:ntf_notifications,id | Please select a valid notification. |
| notification_id (unique) | unique:ntf_notification_thread_members,notification_id,NULL,id,thread_id,{thread_id} | This notification is already a member of this thread. |
| sequence_order | nullable, integer, min:1 | The sequence order must be at least 1. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Invalid thread_id | The selected thread does not exist. | 422 |
| Invalid notification_id | The selected notification does not exist. | 422 |
| Duplicate membership | This notification is already a member of this thread. | 422 |
| sequence_order less than 1 | The sequence order must be at least 1. | 422 |
| Invalid member ID in updateSequence | One or more member IDs are invalid. | 422 |
| Missing members array in updateSequence | The members field is required. | 422 |
| Unauthorized access | You do not have permission to perform this action. | 403 |
| Member not found | Thread member not found. | 404 |
| Database error | An unexpected error occurred. Please try again. | 500 |

---

## Success Scenarios

- **Create:** Thread member added successfully. Notification linked to thread at sequence position N.
- **Update:** Thread member updated successfully. Sequence order or association changed.
- **Update Sequence:** Sequence updated successfully. Notifications reordered within the thread.
- **Delete (Hard):** Thread member removed successfully. Remaining members resequenced automatically.
- **View:** Member details displayed with thread and notification information.

## Failure Scenarios

- **Duplicate membership:** The same notification is already in the thread. 422 validation error. No record created.
- **Invalid thread:** Selected thread does not exist or is not active. 422 error. No record created.
- **Invalid notification:** Selected notification does not exist. 422 error. No record created.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back (if applicable).
- **Member not found on show/edit/update/delete:** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_notification_thread_members` | Table | Primary table for this feature |
| `ntf_notification_threads` | Table | Parent thread (FK: thread_id, CASCADE on delete) |
| `ntf_notifications` | Table | Parent notification (FK: notification_id, CASCADE on delete) |
| `Modules\Notification\Models\NotificationThreadMember` | Model | Primary model for this feature |
| `Modules\Notification\Models\NotificationThread` | Model | Parent thread model (hasMany members, belongsToMany notifications) |
| `Modules\Notification\Models\Notification` | Model | Parent notification model (belongsToMany threads via pivot) |
| `Modules\Notification\Http\Controllers\NotificationThreadMemberController` | Controller | CRUD + updateSequence + resequenceThread |
| `Modules\Notification\Http\Requests\NotificationThreadMemberRequest` | Form Request | Validation rules for create/update |
| `tenant.notification-thread-member.*` | Permissions | viewAny, create, view, update, delete |
