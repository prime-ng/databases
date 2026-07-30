# Templates (Notification Templates) — Business Requirements

## What This Screen Does
The Notification Templates screen manages reusable message templates that can be referenced by notifications. Each template is associated with a specific channel (Email, SMS, Push, WhatsApp, In-App) and follows an approval workflow (Draft → Pending → Approved/Rejected → Archived). Only Approved templates can be used in notification dispatch.

## When This Screen Is Used
- When creating a reusable notification template for a specific channel
- When managing template versions and creating new versions from existing ones
- When submitting templates for approval, approving, or rejecting them
- When duplicating templates for similar use cases
- When toggling template active/inactive status
- When viewing template history and rendering previews
- When managing soft-deleted templates (trash/restore/force delete)

## Default Data Load
On page load, the screen displays a paginated list of notification templates for the current tenant. The list shows template code, channel, content preview (subject + body), language, system/custom type, version, approval status, active status, and action buttons (View, Edit, Toggle, Delete, Duplicate, Create Version, Submit for Approval, Approve, Reject).

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| template_code | VARCHAR(100) UQ per tenant+version | Unique identifier for the template within a tenant and version |
| template_name | VARCHAR(255) | Display name for the template |
| channel_id | BIGINT FK | Links to the notification channel (ntf_channel_master) |
| template_version | INT | Version number of the template |
| subject | VARCHAR(255) | Email/notification subject line |
| body | TEXT | Main template body content (supports rich text) |
| alt_body | TEXT | Plain text alternative for non-HTML clients |
| placeholders | JSON | Array of placeholder variables available in the template |
| language_code | VARCHAR(10) | Language code (e.g., en, hi, gu) |
| media_id | BIGINT FK | Links to media attachment (sys_media) |
| is_system_template | BOOLEAN | Whether this is a system-managed template |
| approval_status | ENUM | DRAFT / PENDING / APPROVED / REJECTED / ARCHIVED |
| approved_by | BIGINT FK | User who approved the template |
| approved_at | DATETIME | Timestamp of approval |
| effective_from | DATETIME | Template effective start date |
| effective_to | DATETIME | Template effective end date |
| is_active | BOOLEAN | Toggle for enabling/disabling this template |

## Business Rules and Conditions
- Template code must be unique per tenant + template_version combination (BR-NTF-001)
- Only Approved templates can be used in notification dispatch (BR-NTF-005)
- System templates can only be managed by Prime Super Admin (BR-NTF-004)
- Templates with approval_status APPROVED or ARCHIVED cannot be edited (BR-NTF-003)
- `canBeEdited()` returns false if approval_status is APPROVED or ARCHIVED
- Approval workflow: Draft → Pending → Approved/Rejected → Archived
- Templates submitted for approval must be in DRAFT or REJECTED status
- Only PENDING templates can be approved or rejected
- `approve()` sets approved_by to current user and approved_at to current timestamp
- Template versioning: `createVersion()` replicates template with version+1, resets to DRAFT
- Duplicate creates a copy with a generated new template_code
- Soft deletes are supported with trash view, restore, and force delete
- Activity log entries are created for all state changes (create, update, trash, restore, approve, reject, version create)
- `effective_to` must be after `effective_from` when both are provided

## Workflow Steps
1. Administrator navigates to Notification → Notification Management → Templates tab.
2. Views the list of existing templates with search and filter options.
3. Clicks "Add Template" to create a new template.
4. Fills in template_code, template_name, channel_id, subject, body, and optional fields.
5. Saves the template — defaults to DRAFT approval_status.
6. Edits the template as needed (only if not APPROVED/ARCHIVED).
7. Submits the template for approval via submitForApproval() — status changes to PENDING.
8. Approver reviews and clicks Approve (sets approved_by + approved_at) or Reject (optionally with reason).
9. Creates new versions from existing templates when changes are needed.
10. Can toggle active/inactive status or soft-delete templates as needed.

## Example Scenario
The school admin creates an "Exam Schedule Notification" email template with code `EXAM_SCHEDULE_EN`. It is assigned to the EMAIL channel with placeholders `{{student_name}}`, `{{exam_date}}`, `{{subject}}`. The template is submitted for approval, approved by the school admin, and then used in an exam notification dispatch.

## Related Screens
- **Channels:** The parent channel definition for each template
- **Notifications:** Templates are referenced when creating notifications
- **Providers:** Providers handle delivery for the channel
- **Media:** Attachments can be linked to templates

---

## Requirements

### REQ-NTF-TPL-01: Template Creation
Administrator must be able to create a notification template with template_code, template_name, channel_id, body, and optional subject/alt_body/placeholders.

### REQ-NTF-TPL-02: Template Code Uniqueness
Template code must be unique per tenant_id + template_version combination. The system enforces this via validation.

### REQ-NTF-TPL-03: Approval Workflow
Templates must support a 5-state approval workflow: DRAFT → PENDING → APPROVED/REJECTED → ARCHIVED.

### REQ-NTF-TPL-04: Edit Restriction for Approved Templates
Templates with approval_status APPROVED or ARCHIVED cannot be edited. The `canBeEdited()` check must prevent update.

### REQ-NTF-TPL-05: Submit for Approval
Templates in DRAFT or REJECTED status can be submitted for approval, transitioning to PENDING.

### REQ-NTF-TPL-06: Approve Template
PENDING templates can be approved, setting approved_by and approved_at.

### REQ-NTF-TPL-07: Reject Template
PENDING templates can be rejected with an optional reason, transitioning to REJECTED.

### REQ-NTF-TPL-08: Template Versioning
Administrator must be able to create a new version of an existing template, incrementing version and resetting to DRAFT.

### REQ-NTF-TPL-09: Template Duplication
Administrator must be able to duplicate a template with a new auto-generated template_code.

### REQ-NTF-TPL-10: Toggle Active Status
Administrator must be able to toggle is_active via AJAX to include/exclude from dispatch.

### REQ-NTF-TPL-11: Soft Delete and Restore
Template records must support soft delete, trash view, restore, and force delete.

### REQ-NTF-TPL-12: Search and Filter
The index view must support search by template_code/template_name/subject, and filter by channel_id, approval_status, language_code, is_active, and tenant_id.

### REQ-NTF-TPL-13: Placeholder Rendering
Templates must support placeholder rendering via `render(array $payload)` which replaces `{{key}}` and `{{ key }}` patterns.

### REQ-NTF-TPL-14: System Template Restriction
System templates (is_system_template = true) can only be managed by Prime Super Admin.

### REQ-NTF-TPL-15: Effective Date Range
Templates must support effective_from and effective_to date range. effective_to must be after effective_from.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All tenant.notification.* + tenant.template.view | All tenants |
| School Admin | tenant.notification.create, .update, .delete, .approve | Own tenant |
| School Admin | tenant.template.view | Own tenant (view) |
| Approver | tenant.notification.approve, .update | Own tenant (approve/reject) |
| Manager | tenant.template.view, tenant.notification.viewAny | Own tenant (read-only) |

---

## Logic Flow

### Create Flow
```
User submits form → validateTemplate() validation →
Check uniqueness: template_code + tenant_id + template_version →
Set tenant_id, created_by, default template_version=1 →
Set approval_status=DRAFT (default) →
Create record → Activity log: Created
```

### Approval Flow
```
Submit for Approval: DRAFT/REJECTED → PENDING →
Approve: PENDING → APPROVED (set approved_by, approved_at) →
Reject: PENDING → REJECTED (optional reason) →
Activity log: Submitted / Approved / Rejected
```

### Edit Flow
```
User opens edit → Check canBeEdited() →
If APPROVED or ARCHIVED → Redirect with error →
Else → Load form with existing data →
Submit → validateTemplate() → Update → Activity log: Updated
```

### Versioning Flow
```
User clicks "Create Version" →
Replicate existing template →
Increment template_version →
Reset approval_status to DRAFT →
Clear approved_by, approved_at →
Set created_by to current user →
Save → Activity log: Version Created
```

### Delete Flow
```
User clicks delete → Confirm dialog →
Set is_active = false → Apply SoftDeletes →
Activity log: Trashed
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| template_code | required, string, max:100, unique per tenant+version | The template code has already been taken. |
| template_name | required, string, max:255 | The template name field is required. |
| channel_id | required, integer, exists:ntf_channel_master,id | The channel field is required. |
| template_version | nullable, integer, min:1 | — |
| subject | nullable, string, max:255 | — |
| body | required, string | The template body field is required. |
| alt_body | nullable, string | — |
| placeholders | nullable, JSON | The placeholders must be valid JSON. |
| language_code | nullable, string, max:10 | — |
| media_id | nullable, integer, exists:sys_media,id | — |
| is_system_template | nullable, boolean | — |
| approval_status | nullable, in:DRAFT,PENDING,APPROVED,REJECTED,ARCHIVED | — |
| effective_from | nullable, date | — |
| effective_to | nullable, date, after:effective_from | The effective to date must be after effective from date. |
| is_active | nullable, boolean | — |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Missing template_code | The template code field is required. | 422 |
| Missing template_name | The template name field is required. | 422 |
| Missing channel_id | The channel field is required. | 422 |
| Missing body | The template body field is required. | 422 |
| Duplicate template_code | The template code has already been taken. | 422 |
| Invalid effective_to | The effective to date must be after effective from date. | 422 |
| Edit APPROVED template | Template cannot be edited in its current approval status | 302 (redirect) |
| Submit non-DRAFT/REJECTED | Template cannot be submitted for approval | 400 |
| Approve non-PENDING | Template is not pending approval | 400 |
| Reject non-PENDING | Template is not pending approval | 400 |
| Unauthorized access | You do not have permission to perform this action. | 403 |
| Template not found | Template not found | 404 |

---

## Success Scenarios

- **Create:** Notification template created successfully.
- **Update:** Notification template updated successfully.
- **Submit for Approval:** Template submitted for approval.
- **Approve:** Template approved successfully.
- **Reject:** Template rejected successfully.
- **Create Version:** New version created successfully.
- **Duplicate:** Template duplicated successfully.
- **Toggle Status:** Status updated successfully.
- **Delete (Soft):** Notification template deleted.
- **Restore:** Template restored successfully.
- **Force Delete:** Template permanently deleted.

## Failure Scenarios

- **Edit approved/archived template:** Template cannot be edited. Redirect with error message.
- **Duplicate code:** Validation error. No record saved.
- **Invalid date range:** effective_to before effective_from. Validation error.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back.
- **Template not found:** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_templates` | Table | Primary table for this feature |
| `ntf_channel_master` | Table | Channel reference (FK: channel_id) |
| `sys_media` | Table | Media attachment reference (FK: media_id) |
| `tenants` | Table | Multi-tenancy reference (FK: tenant_id) |
| `Modules\Notification\Models\NotificationTemplate` | Model | Primary model for this feature |
| `Modules\Notification\Models\ChannelMaster` | Model | Channel relationship |
| `Modules\Prime\Models\Media` | Model | Media relationship |
| `Modules\Notification\Http\Controllers\TemplateController` | Controller | CRUD + approval + versioning |
| `tenant.notification.*` | Permissions | viewAny, create, update, delete, approve, restore, forceDelete |
| `tenant.template.view` | Permission | View specific template |
| `SoftDeletes` | Trait | Laravel's built-in soft delete functionality |
