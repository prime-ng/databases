# Complaints (Core) — Requirements

## What It Does
The central ticket registry for all grievances. Supports:
- Auto-generated ticket numbers (`CMP-YYYY-000001` format)
- Polymorphic complainants (Student, Staff, Anonymous)
- Polymorphic targets (Department, Staff, Vehicle, Vendor, etc.)
- Category + subcategory classification
- Severity and priority auto-filled from subcategory
- Status workflow: Open → In Progress → Resolved / Rejected → Closed
- 5-level escalation tracking
- SLA-driven resolution deadlines
- Medical check linkage
- Image upload support via Spatie Media Library

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `ticket_no` | VARCHAR | Auto-generated: `CMP-YYYY-NNNNNN`. Lock-guarded to prevent duplicates. |
| `ticket_date` | DATE | Date of complaint registration. |
| `complainant_type_id` | BIGINT FK → `sys_dropdowns` | Required. Defines complainant category (Student/Staff/Anonymous). |
| `complainant_user_id` | BIGINT FK → `sys_users` | Nullable. Set when complainant is a system user. NULL for anonymous. |
| `complainant_name` | VARCHAR | Used when complainant is anonymous or not a system user. |
| `complainant_contact` | VARCHAR | Contact details of complainant. |
| `target_type_id` | BIGINT FK → `sys_dropdowns` | Defines target entity type (Department/Staff/Vehicle/etc.). |
| `target_id` | INTEGER | Unconstrained ID of the target entity (no FK for flexibility). |
| `target_name` | VARCHAR | Display name of the target. |
| `target_table_name` | VARCHAR | Table name for dynamic polymorphic resolution. |
| `category_id` | BIGINT FK → `cmp_complaint_categories` | Required. Primary category. |
| `subcategory_id` | BIGINT FK → `cmp_complaint_categories` | Nullable. Further classification. |
| `severity_level_id` | BIGINT FK → `sys_dropdowns` | Auto-filled via AJAX when subcategory is selected. |
| `priority_score_id` | BIGINT FK → `sys_dropdowns` | Auto-filled via AJAX when subcategory is selected. |
| `title` | VARCHAR | Required. Brief summary of the complaint. |
| `description` | TEXT | Detailed description. |
| `location_details` | VARCHAR | Where the incident occurred. |
| `incident_date` | DATETIME | When the incident happened. |
| `incident_time` | TIME | Time of the incident. |
| `status_id` | BIGINT FK → `sys_dropdowns` | Default: 124 (Open). Workflow: Open → In Progress → Resolved/Rejected/Closed. |
| `assigned_to_role_id` | BIGINT FK → `sys_roles` | Role assigned to handle this complaint. |
| `assigned_to_user_id` | BIGINT FK → `sys_users` | Specific user assigned. |
| `resolution_due_at` | DATETIME | Calculated from SLA: ticket_date + category/department resolution hours. |
| `actual_resolved_at` | DATETIME | Nullable. When the complaint was actually resolved. |
| `resolved_by_role_id` | BIGINT FK → `sys_roles` | Role of the resolver. |
| `resolved_by_user_id` | BIGINT FK → `sys_users` | User who resolved it. |
| `resolution_summary` | TEXT | Notes on how it was resolved. |
| `escalation_level` | INTEGER | Current escalation level (0-5). |
| `is_escalated` | BOOLEAN | True if past all escalation windows. |
| `source_id` | BIGINT FK → `sys_dropdowns` | How the complaint was submitted (Portal/Verbal/Email/etc.). |
| `is_anonymous` | BOOLEAN | Whether complainant identity is hidden. |
| `dept_specific_info` | JSON | Flexible storage for department-specific metadata. |
| `is_medical_check_required` | BOOLEAN | Whether a medical check is needed for this complaint. |
| `support_file` | BOOLEAN | Whether an image was uploaded. |
| `created_by` | BIGINT FK → `sys_users` | Who created the ticket. |

## Business Rules

**Complainant Type Logic**
- When complainant type is "Anonymous": complainant_name is required, complainant_user_id is disabled and set to null
- When complainant type is named (Student/Staff): complainant_user_id is required, complainant_name is disabled and set to null
- Switching between types dynamically enables/disables the respective fields via JavaScript

**Category → Subcategory AJAX Flow**
1. User selects a category from the dropdown
2. An AJAX call fetches subcategories for that category
3. The subcategory dropdown is populated with only child categories
4. If the category has no children, the subcategory dropdown is cleared

**Subcategory → Severity/Priority AJAX Flow**
1. After selecting a subcategory, another AJAX call fetches the subcategory's meta data
2. The hidden `severity_level_id` and `priority_score_id` fields are auto-filled
3. These fields are not manually editable — they come from the category definition

**Ticket Number Auto-Generation**
- Format: `CMP-YYYY-NNNNNN` (e.g., `CMP-2026-000001`)
- Year is locked to the ticket's year
- Sequence increments per year
- Lock-guarded to prevent duplicate ticket numbers under concurrent creation

**Status Workflow**
- Default on create: "Open" (status_id = 124)
- Allowed transitions: Open → In Progress → Resolved / Rejected → Closed
- Each status change is logged in `cmp_complaint_actions`

**Resolution Validation**
- `actual_resolved_at` must be on or after `resolution_due_at`
- At least one of `resolved_by_role_id` or `resolved_by_user_id` must be set when marking as resolved

**Escalation Calculation**
- Computed at runtime via Carbon diff on `ticket_date + category SLA hours`
- If current time > expected_resolution: escalation starts
- 5 levels defined by escalation_hours_l1 through l5
- "Breached" when past all escalation windows

## CRUD Operations

**Create**
- Route: `GET /complaint/complaints/create` → form with category dropdown, complainant type selector
- Submit: `POST /complaint/complaints` → validates (with inline validation) → creates with auto-generated ticket number → logs "Created" action → notifies super admins → redirects
- Success redirect: `/complaint/complaints` with success flash containing the ticket number
- Image upload: optional `complaint_img` via Spatie Media Library

**List**
- Route: `/complaint/complaint-mgt` → tabbed interface with "Manage Complaints" tab
- Shows table with search, status filter, date range filter
- Each row has actions for view, edit, update status

**View**
- Route: `GET /complaint/complaints/{id}`
- Shows full complaint details with all dropdown labels resolved
- Includes action timeline, medical checks, and AI insights

**Edit/Update**
- Route: `GET /complaint/complaints/{id}/edit` → pre-filled form
- Submit: `PUT /complaint/complaints/{id}`
- Change detection: logs "StatusChange", "Assigned", "Resolved" actions based on diffs
- Resolution date validation enforced

**Manage/Update Status**
- Route: `/complaint/complaint-mgt` → "Update Status" accordion per complaint
- Two panels: (1) read-only complaint details (2) form for assignment, status, resolution

## Permissions

| Operation | Permission Key |
|---|---|
| View complaints tab | `tenant.complaint.viewAny` |
| View complaint details | `tenant.complaint.view` |
| Create complaint | `tenant.complaint.create` |
| Update complaint | `tenant.complaint.update` |
