# Separation Approvals — Requirement Document

## Screen Purpose & Overview

This screen is part of the Leave Management sub-menu (Exit Clearance Operations Hub). The main purpose of this screen is to track and approve the department-wise clearance checklist for employees separating from the school (whether due to resignation, retirement, or termination).

Before an employee can receive their Full & Final (F&F) settlement and be formally relieved, they must obtain clearances (a "No Dues" certificate) from various school departments (such as IT, Library, Finance/Accounts, and Sports/Labs). Each department head sees checklist items relevant to their area on this screen and must verify them to either approve or hold clearance.

---

## Common Use Cases

1. **IT Assets Return Check:** The IT Head verifies that the employee has returned their assigned laptop, closed official email accounts, and had all portal access permissions deactivated.
2. **Library Books Check:** The Librarian checks for any unreturned library books or outstanding fines.
3. **Accounts & Fee Dues Check:** The Accounts department reconciles salary advances, employee loans, or outstanding petty cash balances.
4. **HOD Academic Clearance:** The Department Head verifies that the teacher has submitted final marksheet entries, student profiles, lesson plans, and handed over all school study materials.
5. **Final Exit Clearance Sign-off:** The HR Director signs off on the final exit clearance once all departments have marked their clearance as "Clear".

---

## Screen Fields & Input Rules

### Section A: Department Clearance Panel (Department Status Grid)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee Name | The employee whose clearance is being processed | Display field (linked to the resigned employee's profile). |
| Designation & Department | The job title and department of the employee | Display field. |
| Clearance Department | The department performing the clearance check | Auto-tagged by the system based on the logged-in user (IT / Library / Finance / Academic HOD). |
| Assets Returned Status | The return status of assigned physical assets | Required. Dropdown options: Returned / No Assets Assigned / Pending / Damaged. |
| Outstanding Dues (Rs) | Outstanding financial balance to be recovered | Optional (value in Rupees). Defaults to 0.00. |
| Dues Details | Explanatory description of outstanding dues | Optional. Text input (e.g., "Laptop screen damage charge" or "Lost library book fee"). |
| Clearance Status | Department-level clearance decision | Required. Toggle options: Clear (Approved) / Hold (Pending Dues). Defaults to 'Hold'. |
| Reviewer Remarks | Comments or notes from the department reviewer | Optional. Required if the Clearance Status is set to 'Hold'. |

---

## Business Rules & Validation Policies

1. **Blocker for Final Exit Completion:**
   - The final separation process in the main Lifecycle module cannot be marked as `Completed` by the HR Manager until the Clearance Status for all mapped departments (IT, Library, Accounts, and Academic HOD) is updated to `Clear`. The Full & Final settlement remains blocked until then.

2. **Dues Recovery Adjustment:**
   - If a department head enters an amount under "Outstanding Dues" and sets the status to `Clear`, the system automatically pushes this amount to the background database. HR and Accounts will subtract (recover) this amount from the employee's payout during the final settlement.

3. **Status Audit Trail:**
   - When a department head clicks "Clear" to approve, the system automatically captures their user login, date, and time under the "Approved By" and "Approved At" audit logs.

---

## Screen Workflows & Operations

### 1. Department Clearance Review (No Dues Approval)
- The Department Head (e.g., Librarian) logs in and opens the "Separation Approvals" screen.
- They click on the row representing the separating employee.
- After verifying records (e.g., confirming all books are returned), the head marks "Assets Returned Status" as `Returned`, toggles "Clearance Status" to `Clear`, and clicks Save.

### 2. Putting Clearance on Hold
- If there are outstanding returns (e.g., library books are still missing), the reviewer selects `Hold` for the "Clearance Status".
- They enter the specific details in the Remarks box (e.g., "2 books of Class 10 Math syllabus are pending for return").
- Upon saving, the HR Manager's dashboard shows an active alert indicating that the library clearance is pending.

---

## Real-World Example Scenario

**TGT Science Teacher Shalini Sen** is undergoing her exit clearance process:

1. The Librarian, IT Manager, and Academic HOD log into the `Separation Approvals` screen.
2. The **Librarian** confirms Shalini has returned all borrowed books and marks the library clearance as `Clear`.
3. The **IT Manager** checks that her laptop is returned and her official email access is disabled. They mark the IT clearance as `Clear`.
4. The **Academic HOD** notices that Shalini has not yet handed over the student grade logs. The HOD sets the Academic clearance to `Hold` and adds the remark: `Need Class 9 Chemistry practical grades file.`
5. The HR Manager sees that the final exit sign-off is blocked because the Academic clearance is still on `Hold`.
6. Shalini sends the practical grades file via email. The Academic HOD verifies the files and changes the clearance status to `Clear`.
7. Once all department statuses are `Clear`, the HR Manager approves the Full & Final settlement and issues the relieving letter.
