# Complaint_TcList

## Module: Complaint Management → Manage Complaints

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_complaints

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | ticket_no | varchar(30) | NOT NULL, UNIQUE |
| BC-DB-03 | ticket_date | date | NOT NULL |
| BC-DB-04 | complainant_type_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-05 | complainant_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-06 | complainant_name | varchar(100) | NULLABLE |
| BC-DB-07 | complainant_contact | varchar(50) | NULLABLE |
| BC-DB-08 | target_user_type_id | int unsigned | NULLABLE, FK → sys_dropdown_table |
| BC-DB-09 | target_table_name | varchar(60) | NULLABLE (polymorphic) |
| BC-DB-10 | target_selected_id | int unsigned | NULLABLE (polymorphic) |
| BC-DB-11 | target_code | varchar(50) | NULLABLE |
| BC-DB-12 | target_name | varchar(100) | NULLABLE |
| BC-DB-13 | category_id | int unsigned | NOT NULL, FK → cmp_complaint_categories |
| BC-DB-14 | subcategory_id | int unsigned | NULLABLE, FK → cmp_complaint_categories |
| BC-DB-15 | severity_level_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-16 | priority_score_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-17 | title | varchar(200) | NOT NULL |
| BC-DB-18 | description | text | NULLABLE |
| BC-DB-19 | location_details | varchar(255) | NULLABLE |
| BC-DB-20 | incident_date | datetime | NULLABLE |
| BC-DB-21 | incident_time | time | NULLABLE |
| BC-DB-22 | status_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-23 | assigned_to_role_id | int unsigned | NULLABLE, FK → sys_roles |
| BC-DB-24 | assigned_to_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-25 | resolution_due_at | datetime | NULLABLE |
| BC-DB-26 | actual_resolved_at | datetime | NULLABLE |
| BC-DB-27 | resolved_by_role_id | int unsigned | NULLABLE, FK → sys_roles |
| BC-DB-28 | resolved_by_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-29 | resolution_summary | text | NULLABLE |
| BC-DB-30 | is_escalated | tinyint(1) | DEFAULT 0 |
| BC-DB-31 | current_escalation_level | tinyint unsigned | DEFAULT 0 |
| BC-DB-32 | source_id | int unsigned | NULLABLE, FK → sys_dropdown_table |
| BC-DB-33 | is_anonymous | tinyint(1) | DEFAULT 0 |
| BC-DB-34 | dept_specific_info | json | NULLABLE |
| BC-DB-35 | is_medical_check_required | tinyint(1) | DEFAULT 0 |
| BC-DB-36 | support_file | tinyint(1) | DEFAULT 0 |
| BC-DB-37 | created_by | int unsigned | NULLABLE |
| BC-DB-38 | created_at/updated_at | timestamp | Auto-managed |
| BC-DB-39 | deleted_at | timestamp | NULLABLE (soft delete) |

### 1.2 Validation Rules (controller store/update)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | title | required, max:200 |
| BC-VAL-02 | description | nullable |
| BC-VAL-03 | category_id | required, exists:cmp_complaint_categories,id |
| BC-VAL-04 | subcategory_id | nullable, exists:cmp_complaint_categories,id |
| BC-VAL-05 | severity_level_id | required, exists:sys_dropdown_table,id |
| BC-VAL-06 | priority_score_id | required, exists:sys_dropdown_table,id |
| BC-VAL-07 | complainant_type_id | required, exists:sys_dropdown_table,id |
| BC-VAL-08 | status_id | required (set to default OPEN on create) |
| BC-VAL-09 | assigned_to_role_id | nullable, exists:sys_roles,id |
| BC-VAL-10 | assigned_to_user_id | nullable, exists:sys_users,id |
| BC-VAL-11 | incident_date | nullable, date |
| BC-VAL-12 | incident_time | nullable |
| BC-VAL-13 | source_id | nullable, exists:sys_dropdown_table,id |
| BC-VAL-14 | is_anonymous | boolean |
| BC-VAL-15 | target_table_name | nullable, string |
| BC-VAL-16 | target_selected_id | nullable, integer |
| BC-VAL-17 | reopen_reason | required (on reopen) |

### 1.3 Authorization

| BC ID | Permission | Controller Method |
|-------|-----------|-------------------|
| BC-AUTH-01 | `tenant.complaint.viewAny` | `index()` |
| BC-AUTH-02 | `tenant.complaint.view` | `show()` |
| BC-AUTH-03 | `tenant.complaint.create` | `create()`, `store()` |
| BC-AUTH-04 | `tenant.complaint.update` | `edit()`, `update()`, `toggleStatus()`, `reopen()` |
| BC-AUTH-05 | `tenant.complaint.delete` | `destroy()` |
| BC-AUTH-06 | `tenant.complaint.restore` | `trashed()`, `restore()` |
| BC-AUTH-07 | `tenant.complaint.forceDelete` | `forceDelete()` |
| BC-AUTH-08 | `tenant.complaint.manage` | `manage()` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: auto ticket number | Generated as CMP-YYYY-{sequential} with DB lock |
| BC-BIZ-02 | Create: resolution_due_at | Computed from category expected_resolution_hours + ticket_date |
| BC-BIZ-03 | Create: image upload | Attachment via Spatie Media Library (complaint_img) |
| BC-BIZ-04 | Create: anonymous complaint | Hides complainant name/contact from non-admin users |
| BC-BIZ-05 | Create: target polymorphic | target_table_name + target_selected_id for flexible targeting |
| BC-BIZ-06 | Create: event + AI processing | Fires ComplaintSaved event → AI insights engine |
| BC-BIZ-07 | Update: status transition | Validates: Open→InProgress, InProgress→Resolved/Closed/Rejected |
| BC-BIZ-08 | Update: resolved requires fields | actual_resolved_at + resolution_summary required when Resolved |
| BC-BIZ-09 | Update: assignment change | Logs action on assignment change |
| BC-BIZ-10 | Reopen | Requires reopen_reason, changes status to In-Progress |
| BC-BIZ-11 | Show: loads all relations | category, subCategory, assigned user/role, actions, medical checks, AI insight |
| BC-BIZ-12 | Index: escalation display | Calculates and shows current escalation level |
| BC-BIZ-13 | Anonymous accessor | Hides name/contact when is_anonymous=true for non-privileged users |

### 1.5 Model Helpers & Relationships

| BC ID | Helper | Type |
|-------|--------|------|
| BC-MOD-01 | category() | BelongsTo(ComplaintCategory) |
| BC-MOD-02 | subcategory() | BelongsTo(ComplaintCategory) |
| BC-MOD-03 | severity() | BelongsTo(Dropdown) |
| BC-MOD-04 | priorityScore() | BelongsTo(Dropdown) |
| BC-MOD-05 | status() | BelongsTo(Dropdown) |
| BC-MOD-06 | assignedUser() | BelongsTo(User) |
| BC-MOD-07 | assignedRole() | BelongsTo(Role) |
| BC-MOD-08 | resolvedByUser/Role() | BelongsTo(User/Role) |
| BC-MOD-09 | actions() | HasMany(ComplaintAction) |
| BC-MOD-10 | medicalChecks() | HasMany(MedicalCheck) |
| BC-MOD-11 | aiInsight() | HasOne(AiInsight) |
| BC-MOD-12 | targetable() | MorphTo |
| BC-MOD-13 | scopeOpen/escalated/assignedToUser/assignedToRole | Query scopes |

---

## 2. Test Case List

### 2.1 Positive (16)

| TC ID | Description |
|-------|-------------|
| TC-P01 | List loads via complaint-mgt manage-complaints tab |
| TC-P02 | Create — full complaint with all fields |
| TC-P03 | Create — anonymous complaint |
| TC-P04 | Create — with image upload via media library |
| TC-P05 | Create — auto ticket number generation (CMP-YYYY-XXXX) |
| TC-P06 | Create — resolution_due_at auto-calculation |
| TC-P07 | Create — with target (department/student/staff) |
| TC-P08 | Edit — update title, description, category |
| TC-P09 | Edit — status transition Open → In-Progress |
| TC-P10 | Edit — status transition In-Progress → Resolved (with fields) |
| TC-P11 | Edit — assignment (role/user) change |
| TC-P12 | Show — detail page with all relations |
| TC-P13 | Reopen — resolved complaint |
| TC-P14 | Manage page — dedicated management view |
| TC-P15 | Delete → trash → restore |
| TC-P16 | Filter by status/category/severity/date range |

### 2.2 Negative (18)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Create — required fields empty (title, category, severity, etc.) |
| TC-N02 | Create — invalid category_id |
| TC-N03 | Create — invalid severity/priority |
| TC-N04 | Create — invalid complainant_type |
| TC-N05 | Create — title max length 201 |
| TC-N06 | Create — duplicate ticket number (concurrency) |
| TC-N07 | Update — invalid status transition (Open → Resolved) |
| TC-N08 | Update — Resolved without actual_resolved_at |
| TC-N09 | Update — Resolved without resolution_summary |
| TC-N10 | Update — Closed → In-Progress (invalid transition) |
| TC-N11 | Reopen — without reopen_reason |
| TC-N12 | Reopen — complaint not resolved |
| TC-N13 | Anonymous — non-admin sees "Anonymous"/"Hidden" |
| TC-N14 | Delete — unauthorized role |
| TC-N15 | Permission denied (403) |
| TC-N16 | Guest redirect (401) |
| TC-N17 | Invalid ID (404) |
| TC-N18 | Empty trashed list |

### 2.3 Dependency (3)

| TC ID | Description |
|-------|-------------|
| TC-D01 | FK — category/subcategory deletion blocks if complaints exist |
| TC-D02 | Event — ComplaintSaved triggers AI insight processing |
| TC-D03 | Escalation — cron updates escalation_level based on SLA hours |

### 2.4 SweetAlert Confirmation (10)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | test_sweet_alert_edit_confirm |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes complaint | test_sweet_alert_delete_confirm |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel |
| TC-SW06 | Restore — SweetAlert confirm restores complaint | test_sweet_alert_restore_confirm |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | test_sweet_alert_restore_cancel |
| TC-SW08 | Reopen — SweetAlert confirm reopens complaint | test_sweet_alert_reopen_confirm |
| TC-SW09 | Reopen — SweetAlert cancel aborts reopen | test_sweet_alert_reopen_cancel |
| TC-SW10 | Toggle Status — SweetAlert confirm flips status | test_sweet_alert_toggle_confirm |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 16 | 16 | 0 | 100% |
| Negative | 18 | 18 | 0 | 100% |
| Dependency | 3 | 0 | 3 | 0% |
| SweetAlert | 10 | 10 | 0 | 100% |
| **Total** | **47** | **44** | **3** | **94%** |
