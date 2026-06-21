# Leave Passes — Requirements

## What It Does
Leave pass workflow for hostel students. Supports leave applications, warden/chief warden approval workflow, parent consent tracking, return confirmation, and auto-attendance marking for approved leave periods.

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `student_id` | INT UNSIGNED FK → std_students | Required. |
| `allotment_id` | BIGINT UNSIGNED FK → hst_allotments | Required. |
| `leave_type` | ENUM(home, emergency, medical, festival, vacation, other) | Required. |
| `from_date` | DATE | Required. |
| `to_date` | DATE | Required. |
| `destination` | VARCHAR(255) | Required. |
| `purpose` | VARCHAR(500) | Required. |
| `guardian_contact` | VARCHAR(20) | Nullable. |
| `guardian_name` | VARCHAR(150) | Nullable. |
| `guardian_relation` | VARCHAR(50) | Nullable. |
| `is_overnight` | TINYINT(1) | Default 1. |
| `applied_by` | INT UNSIGNED FK → sys_users | Required. |
| `approved_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `approved_at` | TIMESTAMP | Nullable. |
| `status` | INT UNSIGNED FK → hst_dynamic_status_masters | Default 1. |
| `rejection_reason` | TEXT | Nullable. |
| `actual_return_date` | DATE | Nullable. |
| `late_return_incident_id` | BIGINT UNSIGNED FK → hst_incidents | Nullable. Auto-created incident on late return. |
| `parent_notified` | TINYINT(1) | Default 0. |
| `parent_consent_received` | TINYINT(1) | Default 0. |
| `consent_media_id` | INT UNSIGNED FK → sys_media | Nullable. |
| `is_active` | TINYINT(1) | Default 1. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete marker. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

## Business Rules

**Lifecycle**
Draft → Pending → Approved → Returned / Rejected / Cancelled

**Approval Levels**
- Leave ≤ 3 days: Floor Warden approves
- Leave > 3 days: Chief Warden approves

**Business Rules**
- Approved leave auto-marks attendance as "On Leave" for the date range
- Late return (>1 day past `to_date`) auto-creates an incident
- Calendar view shows who is on leave on which dates
- Print route generates a printable leave pass for gate verification
- Guardian info is pulled from StudentProfile module

## CRUD Operations

**Create** — `GET /hostel/leave-passes/create` → form with student, dates, type | `POST /hostel/leave-passes` → validates → saves → redirects

**List** — `GET /hostel/leave-passes` → paginated table | Filters: Status, Date Range, Student | Tab in Daily Operations

**Calendar** — `GET /hostel/leave-passes/calendar` → calendar view of approved leaves

**View** — `GET /hostel/leave-passes/{id}` → full detail with dates, status, approval chain

**Approve** — `POST /hostel/leave-passes/{pass}/approve` → sets status to approved, `approved_by`, `approved_at` → redirects

**Reject** — `POST /hostel/leave-passes/{pass}/reject` → records rejection reason → redirects

**Mark Returned** — `POST /hostel/leave-passes/{pass}/return` → sets `actual_return_date` → redirects

**Cancel** — `POST /hostel/leave-passes/{pass}/cancel` → cancels an approved leave

**Print** — `GET /hostel/leave-passes/{pass}/print` → printable leave pass view

**Edit** — Only when in draft/pending status

**Delete (Soft)** — `DELETE /hostel/leave-passes/{id}`

**Get Guardian Info** — `GET /hostel/students/{student}/guardian-info` → AJAX returns guardian details from StudentProfile → JSON

## Permissions

| Operation | Permission Key |
|---|---|
| View list | `tenant.hostel-leave-pass.viewAny` |
| View details | `tenant.hostel-leave-pass.view` |
| Create | `tenant.hostel-leave-pass.create` |
| Edit/update | `tenant.hostel-leave-pass.update` |
| Approve | `tenant.hostel-leave-pass.approve` |
| Reject | `tenant.hostel-leave-pass.reject` |
| Soft delete | `tenant.hostel-leave-pass.delete` |
| Restore | `tenant.hostel-leave-pass.restore` |
| Force delete | `tenant.hostel-leave-pass.forceDelete` |
