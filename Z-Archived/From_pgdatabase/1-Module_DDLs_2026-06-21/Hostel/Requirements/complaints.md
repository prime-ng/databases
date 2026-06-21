# Complaints — Requirements

## What It Does
Hostel-internal complaint register. Students and staff report issues (maintenance, electrical, plumbing, cleanliness, security, food) which are managed by wardens with SLA-based escalation.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `hostel_id` | BIGINT UNSIGNED FK → hst_hostels | Required. |
| `room_id` | BIGINT UNSIGNED FK → hst_rooms | Nullable. |
| `reported_by_student_id` | INT UNSIGNED FK → std_students | Nullable. |
| `reported_by_user_id` | INT UNSIGNED FK → sys_users | Nullable. |
| `category` | ENUM(maintenance, electrical, plumbing, cleanliness, security, food, other) | Required. |
| `subject` | VARCHAR(255) | Required. |
| `description` | TEXT | Required. |
| `priority` | ENUM(low, medium, high, urgent) | Default 'medium'. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `assigned_to` | INT UNSIGNED FK → sys_users | Nullable. |
| `acknowledged_at` | TIMESTAMP | Nullable. |
| `resolution_notes` | TEXT | Nullable. |
| `resolved_at` | TIMESTAMP | Nullable. |
| `sla_due_at` | TIMESTAMP | Nullable. |
| `is_escalated` | TINYINT(1) | Default 0. |
| `escalated_at` | TIMESTAMP | Nullable. |
| `satisfaction_score` | TINYINT UNSIGNED | Nullable. 1-5 from reporter. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Open → In Progress → Resolved / Escalated → Closed

**SLA Escalation**
- Default SLA: 48 hours from creation
- Unresolved past SLA → auto-escalated to Chief Warden
- SLA configurable per category

**Distinction from School Complaint Module**
- Hostel complaints (hst_complaints) are internal warden-managed
- School-wide Complaint module (cmp_*) handles formal parent/visitor complaints
- No automatic cross-linking

## CRUD Operations

**Create** — `GET /hostel/complaints/create` → form with category, priority, room | `POST /hostel/complaints` → validates → saves → redirects

**List** — `GET /hostel/complaints` → paginated table | Tab in Facility Mgmt | Columns: Subject, Category, Priority, Status, SLA Due, Actions | Filtered by status, category, priority

**View** — `GET /hostel/complaints/{id}` → full detail

**Assign** — `POST /hostel/complaints/{complaint}/assign` → sets `assigned_to` → redirects

**Resolve** — `POST /hostel/complaints/{complaint}/resolve` → sets resolution notes, resolved_at → redirects

**Escalate** — `POST /hostel/complaints/{complaint}/escalate` → sets `is_escalated`, `escalated_at` → redirects

**Edit** — `GET /hostel/complaints/{id}/edit` | `PUT` → updates

**Delete (Soft)** — `DELETE /hostel/complaints/{id}`

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-complaint.viewAny` |
| View details | `tenant.hostel-complaint.view` |
| Create | `tenant.hostel-complaint.create` |
| Edit/update | `tenant.hostel-complaint.update` |
| Assign | `tenant.hostel-complaint.assign` |
| Resolve | `tenant.hostel-complaint.resolve` |
| Escalate | `tenant.hostel-complaint.escalate` |
| Soft delete | `tenant.hostel-complaint.delete` |
| Restore | `tenant.hostel-complaint.restore` |
| Force delete | `tenant.hostel-complaint.forceDelete` |
