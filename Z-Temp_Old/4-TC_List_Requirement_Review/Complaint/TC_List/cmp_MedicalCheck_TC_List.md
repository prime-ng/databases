# MedicalCheck_TcList

## Module: Complaint Management → Medical Checks

---

## 1. Business Conditions

### 1.1 Database Schema — cmp_medical_checks

| BC ID | Column | Type | Constraints |
|-------|--------|------|-------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment |
| BC-DB-02 | complaint_id | int unsigned | NOT NULL, FK → cmp_complaints |
| BC-DB-03 | check_type_id | int unsigned | NOT NULL, FK → sys_dropdown_table |
| BC-DB-04 | conducted_by | varchar(100) | NULLABLE |
| BC-DB-05 | conducted_at | datetime | NOT NULL |
| BC-DB-06 | result | varchar(20) | NOT NULL, FK → sys_dropdown_table |
| BC-DB-07 | reading_value | varchar(50) | NULLABLE |
| BC-DB-08 | remarks | text | NULLABLE |
| BC-DB-09 | evidence_uploded | tinyint(1) | DEFAULT 0 |
| BC-DB-10 | created_at | timestamp | Auto-managed |

### 1.2 Validation Rules (controller)

| BC ID | Field | Rule |
|-------|-------|------|
| BC-VAL-01 | complaint_id | required, exists:cmp_complaints,id |
| BC-VAL-02 | check_type_id | required, exists:sys_dropdown_table,id |
| BC-VAL-03 | conducted_by | nullable, string, max:100 |
| BC-VAL-04 | conducted_at | required, date |
| BC-VAL-05 | result | required, exists:sys_dropdown_table,id |
| BC-VAL-06 | reading_value | nullable, string, max:50 |
| BC-VAL-07 | remarks | nullable, string |
| BC-VAL-08 | evidence_uploaded | boolean |

### 1.3 Authorization

| BC ID | Permission |
|-------|-----------|
| BC-AUTH-01 | `tenant.medical-check.viewAny` |
| BC-AUTH-02 | `tenant.medical-check.view` |
| BC-AUTH-03 | `tenant.medical-check.create` |
| BC-AUTH-04 | `tenant.medical-check.update` |
| BC-AUTH-05 | `tenant.medical-check.delete` |
| BC-AUTH-06 | `tenant.medical-check.restore` |
| BC-AUTH-07 | `tenant.medical-check.forceDelete` |

### 1.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create: valid medical check | Stored with complaint, type, result, optional reading |
| BC-BIZ-02 | Evidence upload | Image via Spatie Media Library (medical_img) with conversions |
| BC-BIZ-03 | Result from dropdown | e.g., Positive, Negative, Inconclusive |
| BC-BIZ-04 | Check type from dropdown | e.g., AlcoholTest, DrugTest, FitnessCheck |
| BC-BIZ-05 | Soft delete lifecycle | Trash → restore → force delete |

---

## 2. Test Case List

### 2.1 Positive (8)

| TC ID | Description |
|-------|-------------|
| TC-P01 | List loads via complaint-mgt medical tab |
| TC-P02 | Create — full medical check with reading value |
| TC-P03 | Create — with evidence image upload |
| TC-P04 | Create — without reading_value |
| TC-P05 | Edit — update result/remarks |
| TC-P06 | Show — medical check detail |
| TC-P07 | Delete → trash → restore |
| TC-P08 | Filter by check type or result |

### 2.2 Negative (10)

| TC ID | Description |
|-------|-------------|
| TC-N01 | Create — required fields empty |
| TC-N02 | Create — invalid complaint_id |
| TC-N03 | Create — invalid check_type_id |
| TC-N04 | Create — invalid result |
| TC-N05 | Create — conducted_by max length 101 |
| TC-N06 | Create — reading_value max length 51 |
| TC-N07 | Permission denied (403) |
| TC-N08 | Guest redirect (401) |
| TC-N09 | Invalid ID (404) |
| TC-N10 | Empty trash page |

### 2.3 Dependency (1)

| TC ID | Description |
|-------|-------------|
| TC-D01 | FK — complaint deletion restricts or cascades medical checks |

### 2.4 SweetAlert Confirmation (8)

| TC ID | Description | V2 Test |
|-------|-------------|---------|
| TC-SW01 | Edit — SweetAlert confirm opens edit form | test_sweet_alert_edit_confirm |
| TC-SW02 | Soft Delete — SweetAlert confirm deletes medical check | test_sweet_alert_delete_confirm |
| TC-SW03 | Soft Delete — SweetAlert cancel aborts deletion | test_sweet_alert_delete_cancel |
| TC-SW04 | Force Delete — SweetAlert confirm permanent deletes | test_sweet_alert_force_delete_confirm |
| TC-SW05 | Force Delete — SweetAlert cancel aborts deletion | test_sweet_alert_force_delete_cancel |
| TC-SW06 | Restore — SweetAlert confirm restores medical check | test_sweet_alert_restore_confirm |
| TC-SW07 | Restore — SweetAlert cancel aborts restore | test_sweet_alert_restore_cancel |
| TC-SW08 | Toggle Status — SweetAlert confirm flips status | test_sweet_alert_toggle_confirm |

---

## 3. Coverage Summary

| Category | Total | Full | Gap | % |
|----------|-------|------|-----|---|
| Positive | 8 | 8 | 0 | 100% |
| Negative | 10 | 10 | 0 | 100% |
| Dependency | 1 | 0 | 1 | 0% |
| SweetAlert | 8 | 8 | 0 | 100% |
| **Total** | **27** | **26** | **1** | **96%** |
