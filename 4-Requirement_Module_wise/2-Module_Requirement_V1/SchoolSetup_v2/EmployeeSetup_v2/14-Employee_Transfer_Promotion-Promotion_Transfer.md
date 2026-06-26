# Promotion & Transfer — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Transfer & Promotion sub-menu. Its primary purpose is to record and manage career lifecycle transitions for school employees, teachers, and administrative staff.

Whenever a staff member receives a promotion, demotion, department transfer, or relocates to another branch, the complete transition details are recorded on this screen. The system maintains a complete audit trail (career history) for every employee, tracking changes from their original designation and department to their new roles, along with the authorizing school orders.

---

## Common Use Cases

1. **Recording Teacher Promotions:** Updating designations (e.g., from Junior Teacher to Senior Teacher) and logging the promotion order in the employee's history.
2. **Logging Department Transfers:** Relocating staff between departments (e.g., transferring an employee from the Academic Department to the Library Administration).
3. **Probation Completion & Confirmation:** Upgrading an employee's status to "Confirmed" upon successful completion of their probation period and recording their official confirmation letter.
4. **Assigning Temporary Roles:** Tracking temporary assignments or additional duties (e.g., appointing an Acting HOD) by defining both start and end dates.
5. **Auditing Career Histories:** Reviewing chronological records of an employee's historical promotions, transfers, and the organizational reasons behind each change.

---

## Screen Fields & Input Rules

### Section A: Transition Details
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee Name | The employee undergoing the career transition | Required. Search and select from the active employee list. |
| Change Type | Type of transition | Required. Dropdown: Promotion / Demotion / Transfer / Role Change / Department Change / Designation Change / Confirmation / Probation Extended / Other. |
| Effective From Date | Start date for the career transition | Required. Date picker (e.g., 01-Jun-2026). |
| Effective To Date | End date for temporary roles | Optional. Date picker. If provided, must be greater than or equal to the *Effective From Date*. |
| Official Order Reference | Reference number of the official school order | Optional. Maximum 100 characters (e.g., ORDER/2026/104). |
| Upload Order Document | Scanned copy of the official authorization letter | Optional. PDF or image format upload. Max file size: 2MB. |
| Reason | Explanation for the transition | Optional. Detailed text description of the transition context. |

### Section B: Before & After Changes
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| From Department | Previous department of the employee | Auto-populated by the system based on the employee's current profile. Read-only. |
| To Department | New department assignment | Optional. Select from the active departments dropdown list. |
| From Designation | Previous designation of the employee | Auto-populated by the system based on the employee's current profile. Read-only. |
| To Designation | New designation assignment | Optional. Select from the active designations dropdown list. |
| From System Role | Previous system access role | Auto-populated by the system based on the employee's current profile. Read-only. |
| To System Role | New system access role | Optional. Select from the active system roles dropdown list. |

---

## Business Rules & Validation Policies

1. **Date Validation Rule:**
   - The *Effective To Date* must be greater than or equal to the *Effective From Date*. The system will block saving if the date inputs are out of order.

2. **Transition Log History Integrity:**
   - Historical transition logs cannot be permanently deleted. Instead, incorrect or cancelled entries are soft-deleted and moved to an archive.
   - If an entry is marked inactive (`is_active = false`), it is excluded from current active profile calculations but remains in the database for audit and tracking purposes.

3. **Authorizing User Track:**
   - The system automatically captures the user ID and timestamp (Approved By and Approved At) of the HR officer or Admin who approves and submits the career transition record.

---

## Screen Workflows & Operations

### 1. Recording a Career Transition (Create)
- The Admin clicks the "+ Record Transition" button.
- Searches and selects the employee. The system automatically loads their current Department, Designation, and Role.
- Selects the transition `Change Type` (e.g., Promotion).
- Sets the new designation, department, or system role.
- Selects the `Effective From Date` and inputs the reason.
- Uploads the signed authorization letter PDF and clicks Save.

### 2. Archiving and Restoring Transition Records
- If a career transition entry is invalid or cancelled, the Admin deletes it, moving it to the soft-deleted archive.
- HR can access the "View Trashed Timeline" screen to restore archived entries back to the active log.

---

## Real-World Example Scenario

**Junior Math Teacher Vikram Rathore** is promoted to the post of **Senior Teacher**:

1. The HR Manager opens the `Promotion & Transfer` screen and clicks "+ Record Transition".
2. Searches for employee `Vikram Rathore`. The system automatically displays: Current Department = `Academic`, Designation = `Junior Teacher`.
3. Fills in the transition details:
   - Change Type: `Promotion`.
   - To Designation: `Senior Teacher`.
   - Effective From Date: `01-Jul-2026`.
   - Official Order Reference: `SCH-2026-PROM-012`.
   - Reason: `Excellent academic results in Class 10 and 12 Board exams`.
4. HR scans and uploads the official promotion letter, then clicks Save.
5. **System Action:** On `01-Jul-2026`, the system automatically updates Vikram Rathore's main profile designation to "Senior Teacher", aligning his system permissions and payroll parameters to his new post.
