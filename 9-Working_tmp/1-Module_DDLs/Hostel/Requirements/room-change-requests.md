# Room Change Requests — Requirements

## What It Does
Formal workflow for students requesting a room change. Supports student-initiated or warden-initiated requests with approval workflow that auto-executes the transfer on approval.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `from_allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Required. Current allotment. |
| `requested_room_id` | BIGINT UNSIGNED FK → hst_rooms | Nullable. Preferred new room. |
| `reason` | TEXT | Required. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `approved_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `approved_at` | TIMESTAMP | Nullable. |
| `rejection_reason` | TEXT | Nullable. |
| `new_allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Nullable. Set on approval. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Pending → Approved → Transferred (new allotment created) → Rejected → Cancelled

**Business Rules**
- A student can have only one pending RCR at a time
- On approval: old allotment is vacated, new allotment is created automatically
- `new_allotment_id` links to the newly created allotment
- Availability is re-checked at time of approval

## CRUD Operations

**Create** — `GET /hostel/room-change-requests/create` → form | `POST /hostel/room-change-requests` → validates → saves → redirects

**List** — Tab in Allotments page | Columns: Student, From Room, Requested Room, Status, Actions | Search-enabled | Paginated 15 per page with `rcr_page` named page

**View** — `GET /hostel/room-change-requests/{id}` → full detail with audit trail

**Approve** — `POST /hostel/room-change-requests/{rcr}/approve` → vacates old allotment → creates new allotment → sets `new_allotment_id` → redirects

**Reject** — `POST /hostel/room-change-requests/{rcr}/reject` → records rejection reason → redirects

**Edit** — `GET /hostel/room-change-requests/{id}/edit` → only editable when pending

**Toggle Status** — `POST /hostel/room-change-requests/{rcr}/toggle-status` → AJAX JSON

**Delete (Soft)** — `DELETE /hostel/room-change-requests/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-rcr.viewAny` |
| View details | `tenant.hostel-rcr.view` |
| Create | `tenant.hostel-rcr.create` |
| Edit/update | `tenant.hostel-rcr.update` |
| Soft delete | `tenant.hostel-rcr.delete` |
| Restore | `tenant.hostel-rcr.restore` |
| Force delete | `tenant.hostel-rcr.forceDelete` |
| Approve | `tenant.hostel-rcr.approve` |
| Reject | `tenant.hostel-rcr.reject` |
