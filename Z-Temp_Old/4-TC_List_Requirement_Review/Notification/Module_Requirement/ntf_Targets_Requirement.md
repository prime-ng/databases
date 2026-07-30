# Targets (Notification Targets) — Business Requirements

## What This Screen Does
The Notification Targets screen defines which audience receives a given notification. It acts as the bridge between a notification master record and the target groups or direct recipients. Each target record links a notification to a target group or a directly specified entity (e.g., a specific user or role), along with optional conditions that further refine the audience.

## When This Screen Is Used
- When creating or editing a notification and configuring its delivery audience
- When assigning one or more target groups to a notification
- When specifying direct recipients by table reference (e.g., a particular class section)
- When previewing the estimated vs. actual recipient count before dispatch
- When troubleshooting why a notification reached fewer/more recipients than expected

## Default Data Load
On page load, the screen displays a paginated list of notification targets for the selected notification (filtered by notification_id). The list shows target type, linked group name, target condition summary, estimated_count, and actual_count. The resolveTargets button is available to recalculate actual_count.

## Key Fields at a Glance
| Field | Type | Purpose |
|-------|------|---------|
| notification_id | BIGINT FK | Links to the parent notification (ntf_notifications) |
| target_type_id | BIGINT FK | Type of target (from sys_dropdown_table) — e.g., Group, Role, Direct User |
| target_group_id | BIGINT FK | Links to a Target Group (ntf_target_groups) when targeting by group |
| target_table_name | VARCHAR | Database table name for direct entity resolution |
| target_selected_id | BIGINT | The specific record ID in the target table |
| target_condition | JSON | Additional filtering conditions/filters |
| estimated_count | INT | Estimated recipient count (pre-resolve) |
| actual_count | INT | Computed actual recipient count (post-resolve) |
| is_active | BOOLEAN | Toggle for enabling/disabling this target |

## Business Rules and Conditions
- A notification can have multiple targets. All targets are combined (union) to build the full recipient list.
- If `target_group_id` is set, the target resolves members from the linked target group.
- If `target_table_name` and `target_selected_id` are set, the target resolves a specific entity directly.
- `target_condition` (JSON) allows for additional runtime filters such as "only active students" or "only users who opted-in for SMS."
- `estimated_count` is set optimistically at creation; `actual_count` is computed via the `resolveTargets()` AJAX endpoint.
- A target must be active to participate in the dispatch pipeline.
- Soft-deleted targets are excluded from dispatch. Restoring a target does not retroactively trigger dispatch.

## Workflow Steps
1. Administrator opens the Notification form (create or edit).
2. Navigates to the "Targets" section within the form.
3. Clicks "Add Target" and selects a target type (Group / Direct Entity).
4. If Group: selects a target group from the dropdown (populated from active ntf_target_groups).
5. If Direct Entity: selects target_table_name and target_selected_id (e.g., table = "sys_classes", id = 5).
6. Optionally adds JSON target_condition to further refine.
7. Saves the target — `estimated_count` is auto-calculated if possible.
8. Clicks "Resolve Targets" to trigger the AJAX endpoint that computes `actual_count`.
9. The computed count appears in the list for confirmation before dispatch.

## Example Scenario
The school is creating an exam schedule notification for "Class 10." The admin adds two targets:
1. A group-based target linked to the "Class 10 All Students" target group.
2. A direct-entity target for "Class 10 Section A" (sys_classes.id = 45) with a condition `{"status": "active"}`.
After resolving, the system determines the union has 120 unique recipients. The notification is dispatched accordingly.

## Related Screens
- **Notification Master:** The parent notification record
- **Target Groups:** The groups that can be assigned as targets
- **Resolved Recipients:** The individual recipients resolved from this target
- **Delivery Log:** Shows the delivery status per recipient

---

## Requirements

### REQ-NT-01: Target Creation
Administrator must be able to create a notification target by providing notification_id, target_type_id, and either target_group_id or target_table_name + target_selected_id.

### REQ-NT-02: Target Condition
Administrator must be able to specify a JSON `target_condition` that filters the resolved audience at runtime. The condition must be valid JSON.

### REQ-NT-03: Count Estimation
The system should set `estimated_count` on save based on the target group's `total_members` or a best-guess count for direct entities.

### REQ-NT-04: Resolve Targets
The `resolveTargets()` AJAX endpoint must compute the `actual_count` by evaluating the target group, direct entity, and target_condition together. The result updates the `actual_count` field in the database.

### REQ-NT-05: Multiple Targets Per Notification
The system must support multiple targets per notification. The resolved recipients from all active targets are combined (unique union) to form the final recipient list.

### REQ-NT-06: Toggle Active Status
Administrator must be able to toggle `is_active` to include or exclude a target from the dispatch pipeline without deleting it.

### REQ-NT-07: Soft Delete and Restore
Target records must support soft delete, restore, and force delete. Deleted targets are excluded from dispatch.

### REQ-NT-08: Target List Filtered by Notification
The index view should filter targets by the current notification_id, with an option to view all targets across notifications for admin users.

---

## Who Can Access

| Role | Permission | Scope |
|------|-----------|-------|
| Super Admin | All tenant.notification-target.* permissions | All tenants |
| School Admin | tenant.notification-target.viewAny, .create, .update, .delete | Own tenant |
| School Admin | tenant.notification-target.restore, .forceDelete | Own tenant (trashed records) |
| Manager | tenant.notification-target.viewAny, .view | Own tenant (read-only) |

---

## Logic Flow

### Create Flow
```
User submits form → NotificationTargetRequest validation →
Validate target_group_id XOR (target_table_name + target_selected_id) →
Link to notification_id →
Set estimated_count from group total_members or default →
Store record → Return success
```

### Resolve Targets Flow
```
User clicks "Resolve Targets" → 
Find target by id → 
Check is_active → 
If target_group_id: fetch group members →
If direct entity: resolve from target_table_name/target_selected_id →
Apply target_condition JSON filters →
Count unique results → 
Update actual_count → 
Return resolved count
```

### Delete Flow
```
User clicks delete → Confirm dialog → 
Apply SoftDeletes → 
Mark is_active = false → 
Return success
```

---

## Validate Before Save

| Field | Rule | Message |
|-------|------|---------|
| notification_id | required, exists:ntf_notifications,id | Please select a valid notification. |
| target_type_id | required, exists:sys_dropdown_tables,id | Please select a valid target type. |
| target_group_id | required_without_all:target_table_name,target_selected_id, exists:ntf_target_groups,id | A target group or direct entity reference is required. |
| target_table_name | required_without:target_group_id, string | A target table name is required when no group is selected. |
| target_selected_id | required_without:target_group_id, integer | A target record ID is required when no group is selected. |
| target_condition | nullable, json | The target condition must be valid JSON. |

---

## Error Handling and Validation Messages

| Scenario | Error Message | HTTP Code |
|----------|---------------|-----------|
| Missing both group and entity | Either a target group or a direct entity reference must be provided. | 422 |
| Invalid notification_id | The selected notification does not exist. | 422 |
| Invalid target_group_id | The selected target group does not exist. | 422 |
| target_condition not valid JSON | The target condition must be valid JSON format. | 422 |
| Attempt to resolve deleted target | Notification target not found. | 404 |
| Inactive target cannot resolve | Cannot resolve targets for an inactive notification target. | 422 |
| Unauthorized access | You do not have permission to perform this action. | 403 |

---

## Success Scenarios

- **Create:** Notification target created successfully. estimated_count calculated.
- **Update:** Notification target updated successfully. Record re-evaluated on next resolve.
- **Resolve Targets:** Targets resolved successfully. actual_count updated to X.
- **Toggle Status:** Notification target status changed to active/inactive successfully.
- **Delete (Soft):** Notification target deleted successfully. Record moved to trash.
- **Restore:** Notification target restored successfully.

## Failure Scenarios

- **Invalid combination:** Both group and entity provided (or neither). 422 error. No record saved.
- **Inactive group selected:** Target group exists but is inactive. Warning shown but save allowed.
- **User lacks permission:** 403 Forbidden. No operation performed.
- **Database error:** 500 Internal Server Error. Transaction rolled back.
- **Target not found:** 404 Not Found. No operation performed.

## Dependencies module and tables

| Dependency | Type | Details |
|-----------|------|---------|
| `ntf_notification_targets` | Table | Primary table for this feature |
| `ntf_notifications` | Table | Parent notification (FK: notification_id) |
| `ntf_target_groups` | Table | Target group reference (FK: target_group_id) |
| `sys_dropdown_tables` | Table | Target type reference (FK: target_type_id) |
| `Modules\Notification\Models\Notification` | Model | Parent notification model |
| `Modules\Notification\Models\TargetGroup` | Model | Target group model |
| `Modules\Notification\Models\ResolvedRecipient` | Model | Children resolved from these targets |
| `tenant.notification-target.*` | Permissions | 7 permission keys for CRUD + restore + forceDelete |
| `SoftDeletes` | Trait | Laravel's built-in soft delete functionality |
