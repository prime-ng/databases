# ComplaintAction_TcList

## Module: Complaint Management → Complaint Actions

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_complaint_actions

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | complaint_id | int unsigned | NOT NULL, FK → cmp_complaints |
| BC-DB-03 | action_type_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-04 | performed_by_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-05 | performed_by_role_id | int unsigned | NULLABLE, FK → sys_roles |
| BC-DB-06 | assigned_to_user_id | int unsigned | NULLABLE, FK → sys_users |
| BC-DB-07 | assigned_to_role_id | int unsigned | NULLABLE, FK → sys_roles |
| BC-DB-08 | notes | text | NULLABLE |
| BC-DB-09 | is_private_note | tinyint(1) | DEFAULT 0 |
| BC-DB-10 | action_timestamp | timestamp | — |
| BC-DB-11 | created_at/updated_at | timestamp | — |

### 1.2 Authorization

| BC ID | Permission |
|-------|-----------|
| BC-AUTH-01 | `tenant.complaint-action.view` |
| BC-AUTH-02 | `tenant.complaint-action.create` |
| BC-AUTH-03 | `tenant.complaint-action.update` |
| BC-AUTH-04 | `tenant.complaint-action.delete` |
| BC-AUTH-05 | `tenant.complaint-action.restore` |
| BC-AUTH-06 | `tenant.complaint-action.forceDelete` |

### 1.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Action logging via ComplaintController | Actions auto-logged on create, update status, assignment change, reopen, delete |
| BC-BIZ-02 | Private notes | is_private_note=true hides from non-admin users (scopeVisibleToUser) |
| BC-BIZ-03 | Action types from dropdown | Created, Assigned, StatusChange, Comment, Resolved, Reopened, etc. |
| BC-BIZ-04 | Soft delete lifecycle | Trash → restore → force delete |
| BC-BIZ-05 | Timeline view | Actions ordered by created_at, filterable by complaint/complaint type |

---

## 2. Test Case List

### 2.1 Positive (7)

| TC ID | Description |
|-------|-------------|
| TC-P01 | List loads via complaint-mgt actions tab with timeline |
| TC-P02 | Action auto-created on complaint creation |
| TC-P03 | Action auto-created on status change |
| TC-P04 | Action auto-created on assignment change |
| TC-P05 | Action auto-created on reopen |
| TC-P06 | Filter actions by complaint/complaint type |
| TC-P07 | Private notes hidden from non-admin users |

### 2.2 Negative (5)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Permission denied (403) |
| TC-N02 | Guest redirect (401) |
| TC-N03 | Invalid complaint_id |
| TC-N04 | Invalid action_type_id |
| TC-N05 | Empty actions list for new complaint |

### 2.3 Dependency (1)

| TC ID | Description |
|-------|-------------|
| TC-D01 | FK — complaint deletion cascades action deletion |

### 2.4 SweetAlert Confirmation (4)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-SW01 | Soft Delete — SweetAlert confirm deletes action | test_sweet_alert_delete_confirm |
| TC-SW02 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel |
| TC-SW03 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm |
| TC-SW04 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 7 | 7 | 0 | 100% |
| Negative | 5 | 5 | 0 | 100% |
| Dependency | 1 | 0 | 1 | 0% |
| SweetAlert | 4 | 4 | 0 | 100% |
| **Total** | **17** | **16** | **1** | **94%** |
