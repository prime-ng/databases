# DepartmentSla_TcList

## Module: Complaint Management → SLA

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_department_sla

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | complaint_category_id | int unsigned | NULLABLE, FK → cmp_complaint_categories |
| BC-DB-03 | complaint_subcategory_id | int unsigned | NULLABLE, FK → cmp_complaint_categories |
| BC-DB-04 | target_department_id | int unsigned | NULLABLE, FK → sch_departments |
| BC-DB-05 | target_designation_id | int unsigned | NULLABLE, FK → sch_designations |
| BC-DB-06 | target_role_id | int unsigned | NULLABLE, FK → sys_roles |
| BC-DB-07 | target_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-08 | target_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-09 | target_vehicle_id | int unsigned | NULLABLE, FK → tpt_vehicle |
| BC-DB-10 | target_vendor_id | int unsigned | NULLABLE, FK → vnd_vendors |
| BC-DB-11 | dept_expected_resolution_hours | int unsigned | NOT NULL |
| BC-DB-12 | dept_escalation_hours_l1 | int unsigned | NOT NULL |
| BC-DB-13 | dept_escalation_hours_l2 | int unsigned | NOT NULL |
| BC-DB-14 | dept_escalation_hours_l3 | int unsigned | NOT NULL |
| BC-DB-15 | dept_escalation_hours_l4 | int unsigned | NOT NULL |
| BC-DB-16 | dept_escalation_hours_l5 | int unsigned | NOT NULL |
| BC-DB-17 | escalation_l1_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-18 | escalation_l2_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-19 | escalation_l3_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-20 | escalation_l4_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-21 | escalation_l5_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-22 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-23 | created_at/updated_at | timestamp | Auto-managed |

### 1.2 Validation Rules (DepartmentSlaRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | complaint_category_id | required, exists, unique (composite with all targets) |
| BC-VAL-02 | complaint_subcategory_id | nullable, exists:cmp_complaint_categories,id |
| BC-VAL-03 | target_department_id | nullable, exists:sch_departments,id |
| BC-VAL-04 | target_designation_id | nullable, exists:sch_designations,id |
| BC-VAL-05 | target_role_id | nullable, exists:sys_roles,id |
| BC-VAL-06 | target_user_id | nullable, exists:sys_users,id |
| BC-VAL-07 | target_entity_group_id | nullable, exists:sch_entity_groups,id |
| BC-VAL-08 | target_vehicle_id | nullable, exists:tpt_vehicle,id |
| BC-VAL-09 | target_vendor_id | nullable, exists:vnd_vendors,id |
| BC-VAL-10 | dept_expected_resolution_hours | required, integer, min:1 |
| BC-VAL-11 | dept_escalation_hours_l1 | required, integer |
| BC-VAL-12 | dept_escalation_hours_l2 | required, integer, gt:l1 |
| BC-VAL-13 | dept_escalation_hours_l3 | required, integer, gt:l2 |
| BC-VAL-14 | dept_escalation_hours_l4 | required, integer, gt:l3 |
| BC-VAL-15 | dept_escalation_hours_l5 | required, integer, gt:l4 |
| BC-VAL-16 | escalation_l1..l5_entity_group_id | nullable, exists:sch_entity_groups,id |
| BC-VAL-17 | is_active | boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.department-sla.viewAny` | `index()`, `trashed()` |
| BC-AUTH-02 | `tenant.department-sla.view` | `show()` |
| BC-AUTH-03 | `tenant.department-sla.create` | `create()`, `store()` |
| BC-AUTH-04 | `tenant.department-sla.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-05 | `tenant.department-sla.delete` | `destroy()` |
| BC-AUTH-06 | `tenant.department-sla.restore` | `restore()` |
| BC-AUTH-07 | `tenant.department-sla.forceDelete` | `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: unique combo validation | Same category + subcategory + target combo cannot be duplicated |
| BC-BIZ-02 | Create: escalation hours | L1-L5 strictly increasing; expected < L1 |
| BC-BIZ-03 | Delete → trash → restore | Standard soft delete lifecycle |
| BC-BIZ-04 | Toggle status (AJAX) | POST → flips is_active → JSON response |
| BC-BIZ-05 | Index: loaded with relations | category, subCategory, targetRole, targetUser eager loaded |
| BC-BIZ-06 | 8 target assignment types | Department, Designation, Role, EntityGroup, User, Vehicle, Vendor — all optional |

---

## 2. Test Case List

### 2.1 Positive (10)

| TC ID | Description |
|-------|-------------|
| TC-P01 | List loads via complaint-mgt sla tab |
| TC-P02 | Create — with category + department target |
| TC-P03 | Create — with category + role target |
| TC-P04 | Create — with category + user target |
| TC-P05 | Create — with subcategory + vehicle/vendor target |
| TC-P06 | Edit — change target assignment |
| TC-P07 | Toggle active status (AJAX) |
| TC-P08 | Show SLA detail |
| TC-P09 | Delete → trash → restore |
| TC-P10 | Search/filter by category or target |

### 2.2 Negative (13)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Create — required fields empty |
| TC-N02 | Create — duplicate category+target combo |
| TC-N03 | Create — invalid category_id |
| TC-N04 | Create — invalid subcategory_id |
| TC-N05 | Create — invalid target (dept/role/user/vehicle/vendor) |
| TC-N06 | Create — escalation not strictly increasing |
| TC-N07 | Create — resolution_hours = 0 |
| TC-N08 | Create — escalation_l1 missing |
| TC-N09 | Edit — duplicate combo on update |
| TC-N10 | Permission denied (403) |
| TC-N11 | Guest redirect (401) |
| TC-N12 | Invalid ID (404) |
| TC-N13 | Empty trash page |

### 2.3 Dependency (2)

| TC ID | Description |
|-------|-------------|
| TC-D01 | FK — target entity deletion sets SLA reference to NULL |
| TC-D02 | FK — category deletion cascades/restricts SLA reference |

### 2.4 SweetAlert Confirmation (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | test_sweet_alert_edit_confirm |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes SLA | test_sweet_alert_delete_confirm |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel |
| TC-SW06 | Restore — SweetAlert confirm restores SLA | test_sweet_alert_restore_confirm |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | test_sweet_alert_restore_cancel |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | test_sweet_alert_toggle_confirm |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 10 | 10 | 0 | 100% |
| Negative | 13 | 13 | 0 | 100% |
| Dependency | 2 | 0 | 2 | 0% |
| SweetAlert | 8 | 8 | 0 | 100% |
| **Total** | **33** | **31** | **2** | **94%** |
