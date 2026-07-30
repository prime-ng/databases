# Notification Threads — Business Requirements

## What This Screen Does
The Notification Threads screen groups related notifications into conversation threads, digests, or broadcast threads. Each thread links multiple notifications together under a common subject and UUID, allowing tracking of notification groupings, conversation flows, and participant engagement. Threads can be nested (parent-child) to represent hierarchical conversations.

## When This Screen Is Used
- When grouping related notifications into a conversational thread
- When creating digest summaries of multiple notifications
- When broadcasting a notification across multiple channels as a single logical thread
- When viewing the conversation history of a notification thread
- When recalculating notification counts and participant counts for a thread
- When managing parent-child thread relationships

## Default Data Load
On page load, the screen displays a paginated list of notification threads for the current tenant. The list shows thread UUID, thread type (CONVERSATION/DIGEST/BROADCAST), thread subject, parent thread (if any), root notification, total_notifications count, participant_count, active status, and action buttons (View, Edit, Toggle, Delete, Recalculate Counts).

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| thread_uuid | UUID | Unique identifier for the thread |
| thread_type | ENUM | CONVERSATION / DIGEST / BROADCAST |
| thread_subject | VARCHAR(255) | Subject line describing the thread |
| parent_thread_id | BIGINT FK (self) | Links to a parent notification thread (self-referencing) |
| root_notification_id | BIGINT FK | Links to the root notification (ntf_notifications) |
| total_notifications | INT (calculated) | Count of notifications in the thread |
| participant_count | INT (calculated) | Count of unique participants resolved from notifications |
| is_active | BOOLEAN | Toggle for enabling/disabling this thread |

## Business Rules and Conditions
- Thread type must be one of CONVERSATION, DIGEST, or BROADCAST (BR-NTF-THR-01)
- A thread cannot be deleted if it has child threads (BR-NTF-THR-02)
- Thread UUID is auto-generated on creation (BR-NTF-THR-03)
- `total_notifications` and `participant_count` are calculated fields, updated via `recalculateCounts()` (BR-NTF-THR-04)
- `recalculateCounts()` computes total_notifications from related notifications count and participant_count from distinct resolved_recipients.user_id (BR-NTF-THR-05)
- A thread cannot be its own parent (self-referencing guard in validation) (BR-NTF-THR-06)
- Threads can form a parent-child hierarchy for nested conversations (BR-NTF-THR-07)
- Soft deletes are supported with standard restore (BR-NTF-THR-08)
- Activity log entries are created for state changes when implemented

## Workflow Steps
1. Administrator navigates to Notification → Notification Management → Threads tab.
2. Views the list of existing threads with search and filter options.
3. Clicks "Add Thread" to create a new notification thread.
4. Selects thread_type, enters thread_subject, optionally selects parent_thread_id and root_notification_id.
5. Saves the thread — UUID is auto-generated.
6. Edits the thread as needed.
7. Uses "Recalculate Counts" to update total_notifications and participant_count.
8. Toggles active/inactive status or deletes threads as needed.

## Example Scenario
A school sends a broadcast notification about "Exam Schedule 2026" to all parents. The broadcast is grouped into a BROADCAST thread with UUID `550e8400-e29b-41d4-a716-446655440000`. As parents reply to the notification with queries, their replies create child CONVERSATION threads under the original broadcast. The admin can recalculate counts to see how many total notifications and participants are part of this thread tree.

## Related Screens
- **Notifications:** The individual notifications that belong to a thread
- **Thread Members:** The many-to-many relationship between threads and notifications
- **Resolved Recipients:** Used for participant count calculation
- **Templates:** Templates used by notifications within threads

---

## Requirements

### REQ-NTF-THR-01: Thread Creation
Administrator must be able to create a notification thread with thread_type, thread_subject, and optional parent_thread_id and root_notification_id.

### REQ-NTF-THR-02: Thread Types
Thread type must be restricted to CONVERSATION, DIGEST, or BROADCAST.

### REQ-NTF-THR-03: Auto-generate UUID
The thread_uuid must be auto-generated as a UUID v4 string on creation.

### REQ-NTF-THR-04: Parent-Child Hierarchy
Threads must support a self-referencing parent_thread_id to create nested thread hierarchies.

### REQ-NTF-THR-05: Prevent Self-Parenting
A thread cannot be set as its own parent. Validation must guard against this.

### REQ-NTF-THR-06: Recalculate Counts
The `recalculateCounts()` endpoint must update total_notifications (count of related notifications) and participant_count (distinct user_id from ntf_resolved_recipients joined through notifications).

### REQ-NTF-THR-07: Delete Guard
A thread with child threads cannot be deleted — the system must return an error message.

### REQ-NTF-THR-08: Toggle Active Status
Administrator must be able to toggle is_active via AJAX to include/exclude from view.

### REQ-NTF-THR-09: Soft Delete
Thread records must support soft delete.

### REQ-NTF-THR-10: Search and Filter
The index view must support search by thread_subject/thread_uuid, filter by thread_type, has_parent (yes/no), and is_active.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All tenant.notification-thread.* | All tenants |
| School Admin | tenant.notification-thread.viewAny, .create, .update, .delete | Own tenant |
| Manager | tenant.notification-thread.viewAny, .view | Own tenant (read-only) |

---

## Logic Flow

### Create Flow
```
User submits form → NotificationThreadRequest validation →
Validate thread_type in [CONVERSATION, DIGEST, BROADCAST] →
Validate parent_thread_id != self →
Set tenant_id from current tenant →
Generate UUID v4 via Str::uuid() →
Create record → Return success
```

### Recalculate Counts Flow
```
User clicks "Recalculate Counts" →
Find thread by id →
Count notifications() → total_notifications →
JOIN ntf_notifications → ntf_resolved_recipients →
Count DISTINCT user_id → participant_count →
Save both values → Return JSON with new counts
```

### Delete Flow
```
User clicks delete → Check childThreads()->count() →
If > 0 → Return error "Cannot delete thread with child threads" →
Else → Apply SoftDeletes → Return success
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| thread_type | required, in:CONVERSATION,DIGEST,BROADCAST | The thread type field is required. |
| thread_subject | nullable, string, max:255 | — |
| parent_thread_id | nullable, integer, exists:ntf_notification_threads,id, custom self-reference check | Thread cannot be its own parent. |
| root_notification_id | nullable, integer, exists:ntf_notifications,id | — |
| total_notifications | nullable, integer, min:0 | — |
| participant_count | nullable, integer, min:0 | — |
| is_active | nullable, boolean | — |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Invalid thread_type | The selected thread type is invalid. | 422 |
| Self-parenting | Thread cannot be its own parent. | 422 |
| Invalid parent_thread_id | The selected parent thread does not exist. | 422 |
| Invalid root_notification_id | The selected root notification does not exist. | 422 |
| Delete thread with children | Cannot delete thread with child threads | 302 (redirect) |
| Unauthorized access | You do not have permission to perform this action. | 403 |
| Thread not found | Thread not found | 404 |

---

## Success Scenarios

- **Create:** Notification thread created successfully.
- **Update:** Notification thread updated successfully.
- **Recalculate Counts:** Counts recalculated successfully. total_notifications: X, participant_count: Y.
- **Toggle Status:** Status updated successfully.
- **Delete (Soft):** Notification thread deleted successfully.

## Failure Scenarios

- **Self-parenting:** Thread cannot be its own parent. Validation error.
- **Delete thread with children:** Error message. No delete performed.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back.
- **Thread not found:** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_notification_threads` | Table | Primary table for this feature |
| `ntf_notifications` | Table | Root notification reference (FK: root_notification_id) and notifications relation |
| `ntf_resolved_recipients` | Table | Used for participant_count calculation |
| `ntf_notification_thread_members` | Table | Pivot table linking threads to notifications |
| `Modules\Notification\Models\NotificationThread` | Model | Primary model for this feature |
| `Modules\Notification\Models\Notification` | Model | Root notification relationship |
| `Modules\Notification\Http\Controllers\NotificationThreadController` | Controller | CRUD + recalculateCounts + toggleStatus |
| `Modules\Notification\Http\Requests\NotificationThreadRequest` | Form Request | Validation rules |
| `tenant.notification-thread.*` | Permissions | viewAny, create, view, update, delete |
| `SoftDeletes` | Trait | Inherited via BaseModel (BaseModel uses SoftDeletes) |
