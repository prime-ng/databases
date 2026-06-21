# Department SLA — Requirements

## What It Does
Defines granular SLA and escalation rules that override the default category-level settings for specific departments, users, roles, or vendors. Allows rules like "Principal's complaints escalate in half the standard time."

## Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT PK | Auto-increment |
| `complaint_category_id` | BIGINT FK → `cmp_complaint_categories` | Required. The category this rule applies to. |
| `complaint_subcategory_id` | BIGINT FK → `cmp_complaint_categories` | Nullable. Further narrows to a specific sub-category. |
| `target_department_id` | BIGINT FK → `sch_departments` | Nullable. If set, rule applies only to this department. |
| `target_designation_id` | BIGINT FK → `sch_designation` | Nullable. |
| `target_role_id` | BIGINT FK → `sys_roles` | Nullable. |
| `target_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `target_user_id` | BIGINT FK → `sys_users` | Nullable. Rule applies to a specific user. |
| `target_vehicle_id` | BIGINT FK → `tpt_vehicle` | Nullable. |
| `target_vendor_id` | BIGINT FK → `vnd_vendors` | Nullable. |
| `dept_expected_resolution_hours` | INT | Required. Override resolution time in hours. |
| `dept_escalation_hours_l1` | INT | Required. Override escalation L1 hours. |
| `dept_escalation_hours_l2` | INT | Required. Must be greater than L1. |
| `dept_escalation_hours_l3` | INT | Required. Must be greater than L2. |
| `dept_escalation_hours_l4` | INT | Required. Must be greater than L3. |
| `dept_escalation_hours_l5` | INT | Required. Must be greater than L4. |
| `escalation_l1_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. Who gets notified at L1. |
| `escalation_l2_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l3_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l4_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `escalation_l5_entity_group_id` | BIGINT FK → `sch_entity_groups` | Nullable. |
| `is_active` | BOOLEAN | Default true. |

## Business Rules
- Same escalation chain validation as categories (L1 < L2 < L3 < L4 < L5)
- Targets are polymorphic — only one target field is typically set per rule
- The SLA rule with the most specific match takes priority when computing resolution dates

## CRUD Operations
Same CRUD pattern as categories with standard soft delete, restore, force delete, and toggle status operations.

**Create**
- Route: `GET /complaint/department-sla/create` → form
- Submit: `POST /complaint/department-sla` → validates → saves → redirects to master view

**List**
- Displayed as "SLA" tab panel in the master view at `/complaint/complaint-mgt`
- Shows table with category, target, resolution hours, escalation levels, status

**View**
- Route: `GET /complaint/department-sla/{id}`
- Shows full SLA rule details with relationships loaded

**Edit/Update**
- Route: `GET /complaint/department-sla/{id}/edit` → pre-filled form
- Submit: `PUT /complaint/department-sla/{id}` → validates → updates → logs activity → redirects

**Delete (Soft)**
- Route: `DELETE /complaint/department-sla/{id}`
- Triggered via SweetAlert2 confirmation popup
- Sets `is_active = false` before delete

**Restore**
- Route: `GET /complaint/department-sla/{id}/restore`
- Trash page: `GET /complaint/department-sla/trash/view`

**Force Delete**
- Route: `DELETE /complaint/department-sla/{id}/force-delete`

**Toggle Status**
- Route: `POST /complaint/department-sla/{id}/toggle-status`
- AJAX endpoint, returns JSON with new state

## Permissions

| Operation | Permission Key |
|---|---|
| View SLA tab | `tenant.department-sla.viewAny` |
| View SLA details | `tenant.department-sla.view` |
| Create SLA rule | `tenant.department-sla.create` |
| Update SLA rule | `tenant.department-sla.update` |
| Delete SLA rule | `tenant.department-sla.delete` |
| Restore SLA rule | `tenant.department-sla.restore` |
| Force delete SLA | `tenant.department-sla.forceDelete` |
