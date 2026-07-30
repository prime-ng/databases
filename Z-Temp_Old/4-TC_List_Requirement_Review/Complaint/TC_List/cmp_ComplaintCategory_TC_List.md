# ComplaintCategory_TcList

## Module: Complaint Management → Categories

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_complaint_categories

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | parent_id | int unsigned | NULLABLE, FK → self (parent_id) |
| BC-DB-03 | name | varchar(100) | NOT NULL, UNIQUE (parent_id, name) |
| BC-DB-04 | code | varchar(30) | NULLABLE, UNIQUE |
| BC-DB-05 | description | varchar(512) | NULLABLE |
| BC-DB-06 | severity_level_id | int unsigned | NULLABLE, FK → sys_dropdown_table |
| BC-DB-07 | priority_score_id | int unsigned | NULLABLE, FK → sys_dropdown_table |
| BC-DB-08 | default_expected_resolution_hours | int unsigned | NOT NULL |
| BC-DB-09 | default_escalation_hours_l1 | int unsigned | NOT NULL |
| BC-DB-10 | default_escalation_hours_l2 | int unsigned | NOT NULL |
| BC-DB-11 | default_escalation_hours_l3 | int unsigned | NOT NULL |
| BC-DB-12 | default_escalation_hours_l4 | int unsigned | NOT NULL |
| BC-DB-13 | default_escalation_hours_l5 | int unsigned | NOT NULL |
| BC-DB-14 | default_escalation_l1_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-15 | default_escalation_l2_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-16 | default_escalation_l3_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-17 | default_escalation_l4_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-18 | default_escalation_l5_entity_group_id | int unsigned | NULLABLE, FK → sch_entity_groups |
| BC-DB-19 | is_medical_check_required | tinyint(1) | DEFAULT 0 |
| BC-DB-20 | is_active | tinyint(1) | DEFAULT 1 |
| BC-DB-21 | created_at/updated_at | timestamp | Auto-managed |

### DDL-Level Gaps

| Gap | Details |
|-----|---------|
| No deleted_at column | DDL has no soft-delete column but model uses SoftDeletes trait |
| No CHECK constraints | Escalation hour ordering (L5 > L4 > L3 > L2 > L1) enforced only at app layer |
| No FK on created_by | INT UNSIGNED with no FK to sys_users (if model has created_by) |

### 1.2 Validation Rules (ComplaintCategoryRequest)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | parent_id | nullable, exists:cmp_complaint_categories,id, not_in:self_id (edit) |
| BC-VAL-02 | name | required, string, max:100, unique (parent_id, name) |
| BC-VAL-03 | code | nullable, string, max:30, unique (global) |
| BC-VAL-04 | description | nullable, string, max:512 |
| BC-VAL-05 | severity_level_id | nullable, exists:sys_dropdown_table,id |
| BC-VAL-06 | priority_score_id | nullable, exists:sys_dropdown_table,id |
| BC-VAL-07 | default_expected_resolution_hours | required, integer, min:1 |
| BC-VAL-08 | default_escalation_hours_l1 | required, integer |
| BC-VAL-09 | default_escalation_hours_l2 | required, integer, gt:l1 |
| BC-VAL-10 | default_escalation_hours_l3 | required, integer, gt:l2 |
| BC-VAL-11 | default_escalation_hours_l4 | required, integer, gt:l3 |
| BC-VAL-12 | default_escalation_hours_l5 | required, integer, gt:l4 |
| BC-VAL-13 | default_escalation_l1..l5_entity_group_id | nullable, exists:sch_entity_groups,id |
| BC-VAL-14 | is_medical_check_required | boolean |
| BC-VAL-15 | is_active | boolean |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.complaint-category.viewAny` | `index()` |
| BC-AUTH-02 | `tenant.complaint-category.view` | `show()` |
| BC-AUTH-03 | `tenant.complaint-category.create` | `create()`, `store()` |
| BC-AUTH-04 | `tenant.complaint-category.update` | `edit()`, `update()`, `toggleStatus()` |
| BC-AUTH-05 | `tenant.complaint-category.delete` | `destroy()` |
| BC-AUTH-06 | `tenant.complaint-category.restore` | `trashed()`, `restore()` |
| BC-AUTH-07 | `tenant.complaint-category.forceDelete` | `forceDelete()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: parent_id = NULL → top-level category | Category created as parent (main category) |
| BC-BIZ-02 | Create: parent_id = value → sub-category | Category created as child of parent |
| BC-BIZ-03 | Create: escalation hours | L1-L5 must be strictly increasing; expected_resolution_hours must be < L1 |
| BC-BIZ-04 | Delete: soft delete | Sets is_active=false, then delete() → moved to trash |
| BC-BIZ-05 | Force delete: has children | Blocks with error: "Cannot delete category having subcategories." |
| BC-BIZ-06 | Force delete: no children | Permanently deleted from DB |
| BC-BIZ-07 | Restore: restores category | Sets is_active back to previous (no explicit set) |
| BC-BIZ-08 | Toggle status (AJAX) | POST with is_active boolean → flips → JSON response |
| BC-BIZ-09 | Show: load relations | Loads children, parent, severityLevel, priorityScore, l1-l5 groups |
| BC-BIZ-10 | Activity logging | Logs on create, update, delete, restore, force delete, toggle |
| BC-BIZ-11 | Index redirects to complaint-mgt tab | Redirect to `complaint.complaint-mgt.index?tab=category` |

### 1.5 Model Helpers & Relationships

| BC ID | Helper | Logic |
|-------|--------|-------|
| BC-MOD-01 | parent() | BelongsTo(self) — parent category |
| BC-MOD-02 | children() | HasMany(self) — child sub-categories |
| BC-MOD-03 | recursiveChildren() | HasMany(self, recursive) |
| BC-MOD-04 | severityLevel() | BelongsTo(Dropdown) — severity_level_id |
| BC-MOD-05 | priorityScore() | BelongsTo(Dropdown) — priority_score_id |
| BC-MOD-06 | complaints() | HasMany(Complaint) — category_id |
| BC-MOD-07 | subCategoryComplaints() | HasMany(Complaint) — subcategory_id |
| BC-MOD-08 | l1-l5 Group() | BelongsTo(EntityGroup) — escalation groups |

### 1.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete |
|-------|-----------|------------------|----------|
| BC-REF-01 | parent_id | cmp_complaint_categories (self) | — |
| BC-REF-02 | severity_level_id | sys_dropdown_table | — |
| BC-REF-03 | priority_score_id | sys_dropdown_table | — |
| BC-REF-04 | default_escalation_l*_entity_group_id | sch_entity_groups | — |

---

## 2. Test Case List

### 2.1 Positive (12)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-P01 | List loads via complaint-mgt category tab | test_index_page_loads |
| TC-P02 | Create — top-level category (no parent) | test_create_parent_category |
| TC-P03 | Create — sub-category with parent | test_create_sub_category |
| TC-P04 | Create — with code, severity, priority | test_create_with_all_fields |
| TC-P05 | Create — valid escalation hours (L1 < L2 < L3 < L4 < L5) | test_create_valid_escalation_hours |
| TC-P06 | Edit — update name, hours, groups | test_edit_update_fields |
| TC-P07 | Toggle active status (AJAX) | test_toggle_active_status |
| TC-P08 | Show — view category with all relations | test_show_category_details |
| TC-P09 | Delete → trash → restore | test_trash_restore |
| TC-P10 | Force delete (no children) | test_force_delete_no_children |
| TC-P11 | Search by name/code | test_search_categories |
| TC-P12 | Filter by is_active status | test_filter_by_status |

### 2.2 Negative (18)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-N01 | Create — required name empty | test_validation_required_name |
| TC-N02 | Create — duplicate name under same parent | test_validation_duplicate_name_same_parent |
| TC-N03 | Create — duplicate code (global) | test_validation_duplicate_code |
| TC-N04 | Create — name max length 101 | test_validation_name_max_length |
| TC-N05 | Create — description max length 513 | test_validation_description_max_length |
| TC-N06 | Create — invalid parent_id | test_validation_invalid_parent |
| TC-N07 | Create — expected_resolution_hours = 0 | test_validation_resolution_hours_min |
| TC-N08 | Create — L1 = L2 (not strictly increasing) | test_validation_escalation_not_strict |
| TC-N09 | Create — L2 < L1 (descending) | test_validation_escalation_descending |
| TC-N10 | Create — L5 missing | test_validation_all_levels_required |
| TC-N11 | Create — code max length 31 | test_validation_code_max_length |
| TC-N12 | Create — invalid entity_group_id | test_validation_invalid_group |
| TC-N13 | Edit — self parent assignment (not_in:id) | test_edit_self_as_parent |
| TC-N14 | Edit — duplicate name under same parent | test_edit_duplicate_name |
| TC-N15 | Force delete — category with children | test_cannot_force_delete_with_children |
| TC-N16 | Permission denied (403) | test_permission_denied_403 |
| TC-N17 | Guest redirect | test_guest_redirect_to_login |
| TC-N18 | Invalid ID (404) all operations | test_invalid_id_404 |

### 2.3 Dependency (3)

| TC ID | Description | Status |
|-------|-------------|--------|
| TC-D01 | FK — cannot delete parent if children exist (app-level block) | ⏸️ |
| TC-D02 | FK — severity/priority dropdown change affects categories | ⏸️ |
| TC-D03 | FK — referenced by complaints (category_id) | ⏸️ |

### 2.4 SweetAlert Confirmation (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | test_sweet_alert_edit_confirm |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes category | test_sweet_alert_delete_confirm |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel |
| TC-SW06 | Restore — SweetAlert confirm restores category | test_sweet_alert_restore_confirm |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | test_sweet_alert_restore_cancel |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | test_sweet_alert_toggle_confirm |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 12 | 12 | 0 | 100% |
| Negative | 18 | 18 | 0 | 100% |
| Dependency | 3 | 0 | 3 | 0% |
| SweetAlert | 8 | 8 | 0 | 100% |
| **Total** | **41** | **38** | **3** | **93%** |

---

## 4. Route Reference

| Method | URI | Name |
|--------|-----|------|
| GET | /complaint/complaint-categories | complaint.complaint-categories.index |
| GET | /complaint/complaint-categories/create | complaint.complaint-categories.create |
| POST | /complaint/complaint-categories | complaint.complaint-categories.store |
| GET | /complaint/complaint-categories/{id} | complaint.complaint-categories.show |
| GET | /complaint/complaint-categories/{id}/edit | complaint.complaint-categories.edit |
| PUT | /complaint/complaint-categories/{id} | complaint.complaint-categories.update |
| DELETE | /complaint/complaint-categories/{id} | complaint.complaint-categories.destroy |
| GET | /complaint/complaint-categories/trash/view | complaint.complaint-categories.trashed |
| GET | /complaint/complaint-categories/{id}/restore | complaint.complaint-categories.restore |
| DELETE | /complaint/complaint-categories/{id}/force-delete | complaint.complaint-categories.forceDelete |
| POST | /complaint/complaint-categories/{id}/toggle-status | complaint.complaint-categories.toggleStatus |

---

## 5. Development Issues

| ID | Issue | Severity |
|----|-------|----------|
| DEV-01 | DDL missing `deleted_at` column — soft delete will fail | **Critical** |
| DEV-02 | Expected resolution hours validation (must be < L1) only at app layer | Medium |
| DEV-03 | No system protection flag — all categories deletable even if seeded | Medium |
