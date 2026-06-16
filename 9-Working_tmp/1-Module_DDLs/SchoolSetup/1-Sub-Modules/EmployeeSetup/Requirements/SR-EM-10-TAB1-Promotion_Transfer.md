# Technical Specification & Requirements: Employee Lifecycle (Promotion & Transfer)
## Document ID: SR-EM-10-TAB1
**Module:** SchoolSetup / EmployeeSetup  
**Version:** 5.0 (Final)  
**Date:** May 2026  
**Status:** Approved Specification  

---

## 1. Tab Overview: Promotion & Transfer (`role-history`)

The **Promotion & Transfer** tab provides a secure, consolidated log for tracking change events in an employee's professional timeline. These changes include promotions, lateral transfers, probation periods, and job role updates. It allows HR administrators to document transitions in roles, departments, and designations.

The primary system entity involved is:
* **Employee Role History** (`sch_employee_role_history`): Captures active or historic designation, role, and department changes.

---

## 2. Database Schema Details (`sch_employee_role_history`)

| Column Name | Data Type | Cast / Type | Default | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | Primary Key | *Auto-increment* | No | Unique identifier. |
| `employee_id` | `BIGINT` | Foreign Key | | No | Reference to target `sch_employees.id`. |
| `change_type` | `VARCHAR(50)` | `string` | | No | Type of transition: `Promotion`, `Demotion`, `Transfer`, `Role_Change`, `Department_Change`, `Designation_Change`, `Confirmation`, `Probation_Extended`, `Other`. |
| `from_role_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Prior role reference (`sys_roles.id`). |
| `to_role_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Target role reference (`sys_roles.id`). |
| `from_department_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Prior department (`sch_department.id`). |
| `to_department_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Target department (`sch_department.id`). |
| `from_designation_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Prior job designation (`sch_designation.id`). |
| `to_designation_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Target job designation (`sch_designation.id`). |
| `effective_from` | `DATE` | `date` | | No | Beginning date of the updated role status. |
| `effective_to` | `DATE` | `date` | `NULL` | Yes | End date (nullable, for temporary or trial roles). |
| `reason` | `TEXT` | `string` | `NULL` | Yes | Justification or comments on the decision. |
| `order_reference` | `VARCHAR(100)` | `string` | `NULL` | Yes | Official order reference or document number. |
| `approved_by` | `BIGINT` | Foreign Key | `NULL` | Yes | Approver reference (`sys_users.id`). |
| `approved_at` | `TIMESTAMP` | `datetime` | `NULL` | Yes | Date and time of final approval. |
| `order_media_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Attached official order scan or certificate media ID. |
| `is_active` | `TINYINT(1)` | `boolean` | `1` | No | Operational status (Active/Inactive). |
| `created_by` | `BIGINT` | Foreign Key | `NULL` | Yes | Reference to creator (`sys_users.id`). |
| `deleted_at` | `TIMESTAMP` | Soft Delete | `NULL` | Yes | Soft-delete timestamp. |

---

## 3. Business Logic & Validation Rules

### A. Form Validation (`EmployeeRoleHistoryController@store` / `@update`)
* **`employee_id`**: Required on create. Must exist in `sch_employees`.
* **`change_type`**: Required. Must be one of: `Promotion`, `Demotion`, `Transfer`, `Role_Change`, `Department_Change`, `Designation_Change`, `Confirmation`, `Probation_Extended`, `Other`.
* **`effective_from`**: Required valid date.
* **`effective_to`**: Optional date. Must be after or equal to `effective_from` if provided.
* **`from_role_id` / `to_role_id`**: Optional. Must exist in `sys_roles`.
* **`from_department_id` / `to_department_id`**: Optional. Must exist in `sch_department`.
* **`from_designation_id` / `to_designation_id`**: Optional. Must exist in `sch_designation`.
* **`order_reference`**: Optional string, maximum length 100.
* **`reason`**: Optional text/string.

### B. Soft Delete, Restore & Permanent Deletion
* **`destroy()`**: Transitions records to a trashed state. Does not execute an immediate hard-delete.
* **`restore()`**: Recovers trashed histories to active timeline tracking.
* **`forceDelete()`**: Permanently purges records.

### C. Status Toggle (`toggleStatus`)
* Endpoint allows administrators to quickly switch the operational active state (`is_active`) of the career log record.
