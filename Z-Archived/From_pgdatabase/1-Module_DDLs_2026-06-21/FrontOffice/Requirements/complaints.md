# Complaint Handling (Front Office Level) — Requirements

## What It Does
Lightweight complaint intake for the front desk. Captures complaints across categories (Academic, Facility, Staff Behavior, Fee, Safety, Transport, Food, Hygiene). Supports assignment, resolution, and escalation to the full CMP (Complaint) module when the issue requires formal tracking.

## Database Fields

### fof_complaints

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `complaint_number` | VARCHAR(30) | Required. Unique. Auto-generated: `FOF-CMP-YYYY-NNNNN`. |
| `complainant_name` | VARCHAR(100) | Required. |
| `complainant_contact` | VARCHAR(15) | Nullable. |
| `complaint_type` | ENUM('Academic','Facility','Staff_Behavior','Fee','Safety','Transportation','Food','Hygiene','Other') | Required. |
| `description` | TEXT | Required. |
| `urgency` | ENUM('Normal','Urgent','Critical') | Default 'Normal'. |
| `assigned_to_user_id` | INT UNSIGNED FK → `sys_users` | Nullable. Staff handling the complaint. |
| `status` | ENUM('Open','In_Progress','Resolved','Closed','Escalated') | Default 'Open'. |
| `resolution_notes` | TEXT | Nullable. |
| `resolved_at` | DATETIME | Nullable. |
| `resolved_by` | INT UNSIGNED FK → `sys_users` | Nullable. |
| `cmp_complaint_id` | INT UNSIGNED FK → `cmp_complaints` | Nullable. Set on escalation only. |

## Business Rules

**Lifecycle**
```
Open → In_Progress → Resolved → Closed
                  → Escalated (creates CMP complaint)
```

**Escalation to CMP Module**
- `PATCH /front-office/complaints/{complaint}/escalate`
- Creates a new CMP module complaint via the CMP module API
- Sets `cmp_complaint_id` to the new CMP complaint's ID
- Updates status to 'Escalated'
- The CMP module owns the full complaint lifecycle from that point

**Urgency Levels**
- Normal: standard handling
- Urgent: highlighted in list
- Critical: highlighted with red badge, escalated priority

## CRUD Operations

**Log Complaint**
- `POST /front-office/complaints` — validates complainant_name, complaint_type, description; generates FOF-CMP-YYYY-NNNNN

**View**
- `GET /front-office/complaints/{complaint}` — shows full detail with escalation link

**Resolve**
- `PATCH /front-office/complaints/{complaint}/resolve` — sets resolution_notes, resolved_at, resolved_by, status = 'Resolved'

**Escalate**
- `PATCH /front-office/complaints/{complaint}/escalate` — creates CMP complaint, links it, status = 'Escalated'

**List**
- Urgency colour-coding: Normal (blue), Urgent (amber), Critical (red)
- Filterable by status and urgency

## Permissions

| Operation | Permission Key |
|---|---|
| View complaints | `frontoffice.complaint.view` |
| Log complaint | `frontoffice.complaint.create` |
