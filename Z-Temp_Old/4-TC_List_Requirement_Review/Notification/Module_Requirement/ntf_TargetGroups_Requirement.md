# Target Groups — Business Requirements

## What This Screen Does
The Target Groups screen allows school administrators to create, manage, and maintain groups of recipients for notifications. Groups can be static (manually curated members) or dynamic (members resolved on-the-fly via database queries). This is the core audience-segmentation feature of the Notification module.

## When This Screen Is Used
- When an administrator wants to send a notification to a predefined audience (e.g., "All Class 10 Students", "All Maths Teachers")
- When creating reusable audience segments for recurring notifications
- When refreshing the membership count of dynamic groups before dispatch
- When reviewing or deactivating outdated target groups

## Default Data Load
On page load, the screen displays a paginated list of all target groups visible to the logged-in tenant. The list includes group name, group code, group type (STATIC/DYNAMIC), total_members count, last_refreshed_at timestamp, and is_active status. System-generated groups are flagged with a badge. Inactive groups are visually muted. The default sort is by created_at descending.

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| group_name | VARCHAR | Human-readable name of the group |
| group_code | VARCHAR | Unique-per-tenant identifier for API/internal reference |
| group_type | ENUM(STATIC,DYNAMIC) | Determines how members are resolved |
| description | TEXT | Optional context about the group's purpose |
| dynamic_query | TEXT/JSON | The query definition used only for DYNAMIC groups |
| total_members | INT | Computed count of current members |
| last_refreshed_at | DATETIME | Timestamp of the last member refresh |
| is_system_group | BOOLEAN | Whether this is a system-protected group |
| is_active | BOOLEAN | Toggle for enabling/disabling the group |

## Business Rules and Conditions
- System groups (`is_system_group = true`) cannot be deleted via the UI. The delete button is hidden, and any API call to delete returns a 422 error.
- Only DYNAMIC groups support the refreshMembers() action. Refreshing a STATIC group silently succeeds but does not modify members.
- `group_code` must be unique within a tenant. Duplicate group codes across tenants are allowed.
- A group must be active (`is_active = true`) before it can be assigned to a notification target.
- Soft-deleted groups are excluded from all selection lists. Restore is available via the trash route.
- The `total_members` field is a cached count; the authoritative count is computed on refresh or during dispatch.

## Workflow Steps
1. Administrator navigates to Notification → Notification Management → Target Groups.
2. Sees the list of existing groups with search and filter controls.
3. Clicks "Add Target Group" to open the creation form.
4. Fills in group_name, group_code, group_type, and optionally description and dynamic_query.
5. Saves — the system creates a new group with `total_members = 0` and `last_refreshed_at = null`.
6. For DYNAMIC groups, the admin clicks "Refresh Members" to compute and update total_members.
7. The group is now available for assignment in Notification Targets.
8. Admin can toggle `is_active` to temporarily disable the group without deleting it.

## Example Scenario
The school wants to send an exam schedule notification to "All Class 10 Science Stream Students." The admin creates a DYNAMIC target group named "Class 10 Science" with a dynamic query that selects students enrolled in Class 10 with Science stream. When the notification dispatch pipeline runs, it calls refreshMembers() and resolves the group to 85 students. The notification is then targeted to these 85 recipients.

## Related Screens
- **Targets (Notification Targets):** Uses target groups as the audience definition
- **Resolved Recipients:** Shows the individual members resolved from this group
- **Notification Master:** The parent notification that references this group
- **User Preferences:** Individual users may have opted out, overriding group membership

---

## Requirements

### REQ-TG-01: Group Creation
Administrator must be able to create a new target group by providing group_name (required, max 255), group_code (required, unique per tenant, max 100), group_type (required, enum: STATIC/DYNAMIC), and optionally description and dynamic_query.

### REQ-TG-02: Group Code Uniqueness
The system must enforce unique `group_code` per tenant at the database and application levels. A duplicate group code within the same tenant must be rejected with an appropriate error.

### REQ-TG-03: Dynamic Query Validation
When `group_type` is DYNAMIC, the `dynamic_query` field must be present and valid. The system should validate the query structure but is not required to execute it at save time.

### REQ-TG-04: System Group Protection
The system must prevent deletion of groups where `is_system_group = true`. The controller's destroy() method must check this flag and return a 422 error if deletion is attempted.

### REQ-TG-05: Membership Refresh
The `refreshMembers()` method must execute the dynamic query for DYNAMIC groups and update `total_members` and `last_refreshed_at`. For STATIC groups, the method returns early without modification.

### REQ-TG-06: Toggle Active Status
Administrator must be able to toggle `is_active` via a dedicated `toggleStatus()` route. Toggling updates the `is_active` column and returns the new status.

### REQ-TG-07: Soft Delete and Restore
The system must support soft deletes with dedicated restore and force-delete routes. Soft-deleted groups must be excluded from all active queries.

### REQ-TG-08: List with Search and Filters
The index view must support searching by group_name and group_code, and filtering by group_type and is_active status.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All tenant.*.target-group.* permissions | All tenants |
| School Admin | tenant.target-group.viewAny, .create, .update, .delete | Own tenant |
| School Admin | tenant.target-group.restore, .forceDelete | Own tenant (trashed records) |
| Manager | tenant.target-group.viewAny, .view | Own tenant (read-only) |
| Standard User | tenant.target-group.viewAny | Own tenant (read-only if granted) |

---

## Logic Flow

### Create Flow
```
User submits form → TargetGroupRequest validation → 
Check group_code uniqueness per tenant → 
Set created_by to auth user id → 
Store record → Return success response
```

### Refresh Members Flow
```
User clicks "Refresh Members" → 
Find group by id → Check is_active → 
Check group_type === DYNAMIC → 
Execute dynamic query → 
Count results → Update total_members → 
Set last_refreshed_at to now → 
Return updated count
```

### Delete Flow
```
User clicks delete → Confirm dialog → 
Check is_system_group (reject if true) → 
Apply SoftDeletes → 
Mark is_active = false → 
Return success
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| group_name | required, string, max:255 | The group name is required and cannot exceed 255 characters. |
| group_code | required, string, max:100, unique:ntf_target_groups,group_code,NULL,id,tenant_id,{tenant_id} | The group code is required, must be unique per school, and cannot exceed 100 characters. |
| group_type | required, in:STATIC,DYNAMIC | Please select a valid group type: STATIC or DYNAMIC. |
| dynamic_query | required_if:group_type,DYNAMIC | A dynamic query is required when the group type is DYNAMIC. |
| description | nullable, string, max:1000 | Description may not exceed 1000 characters. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| group_code already exists in tenant | The group code has already been taken in this school. | 422 |
| group_name exceeds 255 chars | The group name must not exceed 255 characters. | 422 |
| group_type invalid | The selected group type is invalid. | 422 |
| DYNAMIC group without query | A dynamic query is required for dynamic groups. | 422 |
| Attempt to delete system group | System target groups cannot be deleted. | 422 |
| Attempt to delete already-deleted group | Target group not found. | 404 |
| Attempt to refresh non-existent group | Target group not found. | 404 |
| Unauthorized access | You do not have permission to perform this action. | 403 |

---

## Success Scenarios

- **Create:** Target group created successfully. The group appears in the list with total_members = 0.
- **Update:** Target group updated successfully. Changed fields are reflected immediately.
- **Toggle Status:** Target group status changed to active/inactive successfully.
- **Refresh Members:** Members refreshed successfully. total_members updated to X.
- **Delete (Soft):** Target group deleted successfully. Record moved to trash.
- **Restore:** Target group restored successfully. Group returns to active list.
- **Force Delete:** Target group permanently deleted.

## Failure Scenarios

- **Duplicate group_code:** Creation/update fails with 422. Record not saved.
- **System group delete:** Delete returns 422. No change to the record.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back.
- **Group not found (any operation):** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_target_groups` | Table | Primary table for this feature |
| `Modules\Auth\Models\Tenant` | Model | Tenant resolution for multi-tenancy |
| `sys_users` | Table | Referenced by `created_by` (implied FK) |
| `Modules\Notification\Models\NotificationTarget` | Model | Consumed by NotificationTarget (FK: target_group_id) |
| `tenant.target-group.*` | Permissions | 7 permission keys for CRUD + restore + forceDelete |
| `SoftDeletes` | Trait | Laravel's built-in soft delete functionality |
